"""
DAG 01 - Cria a estrutura do Data Warehouse AdventureWorks no PostgreSQL.

Executar UMA vez (ou sempre que quiser recriar views). Todos os scripts sao
idempotentes (IF NOT EXISTS / ON CONFLICT / CREATE OR REPLACE): rodar de novo
nao apaga dados ja carregados.

Fluxo:
    criar_schemas_controle -> [criar_dim_data, criar_dimensoes] -> criar_fato_vendas -> criar_views_kpis
"""
from datetime import datetime
from pathlib import Path

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.sdk import dag

DW_CONN = "aw_dw"


@dag(
    dag_id="aw_dw_01_setup",
    description="Cria schemas stg/dw/ctrl, dimensoes, fato e views dos KPIs",
    schedule="@once",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    template_searchpath=[str(Path(__file__).parent / "sql")],
    tags=["adventureworks", "dw", "setup"],
)
def aw_dw_01_setup():
    criar_schemas_controle = SQLExecuteQueryOperator(
        task_id="criar_schemas_controle",
        conn_id=DW_CONN,
        sql="setup/00_schemas_controle.sql",
    )
    criar_dim_data = SQLExecuteQueryOperator(
        task_id="criar_dim_data",
        conn_id=DW_CONN,
        sql="setup/01_dim_data.sql",
    )
    criar_dimensoes = SQLExecuteQueryOperator(
        task_id="criar_dimensoes",
        conn_id=DW_CONN,
        sql="setup/02_dimensoes.sql",
    )
    criar_fato_vendas = SQLExecuteQueryOperator(
        task_id="criar_fato_vendas",
        conn_id=DW_CONN,
        sql="setup/03_fato_vendas.sql",
    )
    criar_views_kpis = SQLExecuteQueryOperator(
        task_id="criar_views_kpis",
        conn_id=DW_CONN,
        sql="setup/04_views_kpis.sql",
    )

    criar_schemas_controle >> [criar_dim_data, criar_dimensoes] >> criar_fato_vendas >> criar_views_kpis


aw_dw_01_setup()
