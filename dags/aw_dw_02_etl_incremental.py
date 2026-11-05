"""
DAG 02 - ETL incremental AdventureWorks (OLTP) -> Data Warehouse (Star Schema).

Estrategia incremental (marca d'agua / watermark):
  1. Para cada tabela, le em ctrl.marca_dagua a ultima data de modificacao ja carregada.
  2. Extrai da origem SOMENTE linhas com data_modificacao > marca d'agua (novas ou alteradas).
  3. Grava o delta na staging (stg.*), que e esvaziada a cada execucao.
  4. Carrega dimensoes (SCD1 / upsert) e a fato (upsert por id do item).
  5. Valida a reconciliacao origem x DW.
  6. So entao avanca a marca d'agua. Se algo falhar antes, a proxima execucao
     reprocessa o mesmo delta (os upserts tornam o reprocessamento seguro).

Fluxo:
    inicio -> extrair_<tabela> -> carregar_dim_<tabela> --\
           -> extrair_vendas ------------------------------> carregar_fato_vendas
           -> validar_reconciliacao -> atualizar_marcas_dagua -> fim
"""
from datetime import datetime
from pathlib import Path

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.sdk import dag, get_current_context, task

OLTP_CONN = "aw_oltp"
DW_CONN = "aw_dw"
SQL_DIR = Path(__file__).parent / "sql"

# tabela de staging/dimensao -> arquivo de extracao
DIMENSOES = ["cliente", "produto", "vendedor", "territorio", "promocao", "metodo_envio"]


def _extrair(tabela: str) -> dict:
    """Extrai o delta de uma tabela da origem e grava em stg.<tabela>."""
    dw = PostgresHook(postgres_conn_id=DW_CONN)
    oltp = PostgresHook(postgres_conn_id=OLTP_CONN)

    marca = dw.get_first(
        "SELECT ultima_extracao_em FROM ctrl.marca_dagua WHERE tabela = %s", parameters=(tabela,)
    )[0]

    consulta = (SQL_DIR / "extract" / f"{tabela}.sql").read_text(encoding="utf-8")
    with oltp.get_conn() as conn_oltp, conn_oltp.cursor() as cur:
        cur.execute(consulta, {"watermark": marca})
        colunas = [c[0] for c in cur.description]
        linhas = cur.fetchall()

    # staging guarda apenas o delta desta execucao
    dw.run(f"TRUNCATE stg.{tabela}", autocommit=True)
    if linhas:
        dw.insert_rows(
            table=f"stg.{tabela}",
            rows=linhas,
            target_fields=colunas,
            commit_every=5000,
            executemany=True,
            fast_executemany=True,
        )

    idx = colunas.index("data_modificacao")
    nova_marca = max((l[idx] for l in linhas), default=marca)
    print(f"[{tabela}] marca d'agua anterior={marca} | linhas extraidas={len(linhas)} | nova marca={nova_marca}")
    return {
        "tabela": tabela,
        "linhas": len(linhas),
        "marca_anterior": marca.isoformat(),
        "marca_nova": nova_marca.isoformat(),
    }


@dag(
    dag_id="aw_dw_02_etl_incremental",
    description="ETL incremental AdventureWorks -> DW (Star Schema) com marca d'agua",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,  # evita duas execucoes concorrentes usando a mesma staging
    template_searchpath=[str(SQL_DIR)],
    tags=["adventureworks", "dw", "etl", "incremental"],
)
def aw_dw_02_etl_incremental():
    inicio = EmptyOperator(task_id="inicio")
    fim = EmptyOperator(task_id="fim")

    resultados = []
    cargas_dim = []

    # ---------- Dimensoes: extrair -> carregar ----------
    for tabela in DIMENSOES:
        extrair = task(task_id=f"extrair_{tabela}")(_extrair)(tabela)
        carregar = SQLExecuteQueryOperator(
            task_id=f"carregar_dim_{tabela}",
            conn_id=DW_CONN,
            sql=f"load/dim_{tabela}.sql",
        )
        inicio >> extrair >> carregar
        resultados.append(extrair)
        cargas_dim.append(carregar)

    # ---------- Fato ----------
    extrair_vendas = task(task_id="extrair_vendas")(_extrair)("vendas")
    inicio >> extrair_vendas
    resultados.append(extrair_vendas)

    carregar_fato = SQLExecuteQueryOperator(
        task_id="carregar_fato_vendas",
        conn_id=DW_CONN,
        sql="load/fato_vendas.sql",
    )
    [*cargas_dim, extrair_vendas] >> carregar_fato

    # ---------- Validacao ----------
    @task
    def validar_reconciliacao():
        """Compara quantidade de itens e receita entre a origem e o DW."""
        oltp = PostgresHook(postgres_conn_id=OLTP_CONN)
        dw = PostgresHook(postgres_conn_id=DW_CONN)
        qtd_o, rec_o = oltp.get_first(
            "SELECT COUNT(*), ROUND(SUM(orderqty * unitprice * (1 - unitpricediscount)), 2) "
            "FROM sales.salesorderdetail"
        )
        qtd_d, rec_d, orfaos = dw.get_first(
            "SELECT COUNT(*), ROUND(SUM(valor_liquido), 2), "
            "COUNT(*) FILTER (WHERE chave_cliente = -1 OR chave_produto = -1) FROM dw.fato_vendas"
        )
        print(f"Origem: {qtd_o} itens / {rec_o} | DW: {qtd_d} itens / {rec_d} | orfaos: {orfaos}")
        if qtd_o != qtd_d or abs((rec_o or 0) - (rec_d or 0)) > 1 or orfaos:
            raise ValueError("Reconciliacao falhou: origem e DW divergem. Marca d'agua NAO sera avancada.")
        return {"itens": qtd_d, "receita": float(rec_d or 0)}

    # ---------- Marca d'agua (so depois de tudo validado) ----------
    @task
    def atualizar_marcas_dagua(resultados: list):
        dw = PostgresHook(postgres_conn_id=DW_CONN)
        run_id = get_current_context()["run_id"]
        with dw.get_conn() as conn, conn.cursor() as cur:
            for r in resultados:
                cur.execute(
                    "UPDATE ctrl.marca_dagua SET ultima_extracao_em = %s, atualizado_em = now() "
                    "WHERE tabela = %s",
                    (r["marca_nova"], r["tabela"]),
                )
                cur.execute(
                    "INSERT INTO ctrl.log_etl (dag_run_id, tabela, marca_anterior, marca_nova, linhas_extraidas) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (run_id, r["tabela"], r["marca_anterior"], r["marca_nova"], r["linhas"]),
                )
            conn.commit()
        total = sum(r["linhas"] for r in resultados)
        print(f"Marcas d'agua atualizadas. Total de linhas processadas nesta execucao: {total}")

    validar = validar_reconciliacao()
    carregar_fato >> validar >> atualizar_marcas_dagua(resultados) >> fim


aw_dw_02_etl_incremental()
