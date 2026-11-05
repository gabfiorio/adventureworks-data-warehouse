# Data Warehouse AdventureWorks com Apache Airflow (ETL incremental)

Continuação do Produto 1 (modelo estrela de Vendas do AdventureWorks), agora com o ETL
orquestrado no **Apache Airflow 3.3.1**, carga **incremental** por marca d'água e
Data Warehouse em **PostgreSQL 16**. Tudo sobe com `docker compose`, sem SQL Server e sem `.bak`.

## Arquitetura

```
 aw-oltp (Postgres, porta 5433)        Airflow 3.3.1 (porta 8080)          aw-dw (Postgres, porta 5434)
 AdventureWorks OLTP, 68 tabelas  -->  DAG aw_dw_02_etl_incremental  -->  stg.*  ->  dw.* (estrela)
                                        - lê ctrl.marca_dagua              ctrl.marca_dagua / ctrl.log_etl
                                        - extrai só o delta                dw.vw_kpi01..10 (KPIs)
```

## Estrutura

```
├── docker-compose.yml          # Airflow + Postgres metadados + aw-oltp + aw-dw
├── .env.example                # copiar para .env
├── oltp/
│   ├── 01_adventureworks_oltp.sql.gz   # dump do AdventureWorks OLTP (restaurado automaticamente)
│   └── 02_ajustar_sequences.sql        # acerta as sequences após a restauração
├── dags/
│   ├── aw_dw_01_setup.py               # DAG 1: cria schemas, dimensões, fato e views de KPI
│   ├── aw_dw_02_etl_incremental.py     # DAG 2: ETL incremental
│   └── sql/
│       ├── setup/    # DDL (00 controle/staging, 01 dim_data, 02 dimensões, 03 fato, 04 KPIs)
│       ├── extract/  # consultas de extração no OLTP com filtro de marca d'água
│       └── load/     # upsert das dimensões (SCD1) e da fato
├── sql/
│   ├── kpis.sql                    # consulta os 10 KPIs + log da ETL
│   └── simular_alteracoes_oltp.sql # gera inserções/alterações na origem p/ demonstrar o incremental
├── diagrams/star_schema.puml|.png  # modelo estrela (PlantUML)
└── docs/
    ├── relatorio_tecnico.docx      # relatório acadêmico
    └── prints/                     # prints dos fluxos no Airflow
```

## Como executar

Pré-requisito: Docker Desktop (≈ 6 GB de RAM livres).

```bash
cp .env.example .env
docker compose up airflow-init
docker compose up -d
```

Na primeira subida o `aw-oltp` restaura o AdventureWorks (1–2 min). Acompanhe com
`docker compose ps` até `aw-oltp` ficar `healthy`.

1. Abra http://localhost:8080 (usuário `admin`, senha `admin`).
2. Ative (toggle) e execute a DAG **`aw_dw_01_setup`** – cria toda a estrutura do DW.
3. Ative e execute a DAG **`aw_dw_02_etl_incremental`** – primeira execução = carga completa
   (~141 mil linhas, sendo 121.317 itens de venda).
4. Execute de novo a `aw_dw_02_etl_incremental` – deve processar **0 linhas**.
5. Simule movimento na origem e execute a DAG mais uma vez:

```bash
docker compose exec aw-oltp psql -U postgres -d adventureworks -f /sql/simular_alteracoes_oltp.sql
```

   Resultado esperado: `vendas` = 13 linhas (12 itens de um pedido novo + 1 item alterado),
   `produto` = 1, `cliente` = 1, demais = 0.

6. Consulte os KPIs e o log de controle:

```bash
docker compose exec aw-dw psql -U postgres -d adventureworks_dw -f /sql/kpis.sql
```

Para conectar no DBeaver: DW em `localhost:5434`, banco `adventureworks_dw`, usuário `postgres`,
senha `aw_local_password` (OLTP em `localhost:5433`, banco `adventureworks`).

## Como a carga incremental funciona

| Etapa | O que faz |
|---|---|
| Marca d'água | `ctrl.marca_dagua` guarda, por tabela, a maior `modifieddate` já carregada (inicial: 1900-01-01). |
| Extração | Cada `extrair_<tabela>` executa `dags/sql/extract/<tabela>.sql` com `WHERE data_modificacao > marca`. Em vendas, o item entra se o item **ou** o cabeçalho do pedido mudou. |
| Staging | `stg.<tabela>` é truncada e recebe só o delta da execução. |
| Dimensões | Upsert SCD Tipo 1 (`INSERT ... ON CONFLICT (id) DO UPDATE`). |
| Fato | Lookup das chaves substitutas (ausente → membro `-1`) e upsert por `id_detalhe_pedido`. |
| Validação | `validar_reconciliacao` compara nº de itens e receita origem × DW; se divergir, a DAG falha. |
| Avanço | `atualizar_marcas_dagua` só roda após a validação; grava a nova marca e o log em `ctrl.log_etl`. Se algo falhar antes, o mesmo delta é reprocessado (o upsert torna isso seguro). |

Limitações conhecidas: exclusões físicas na origem não são detectadas (a reconciliação acusaria);
dimensões são SCD1 (sem histórico de atributos).

## Os 10 KPIs (views no schema `dw`)

| # | View | Indicador |
|---|---|---|
| 1 | `vw_kpi01_receita_mensal` | Receita líquida e nº de pedidos por mês |
| 2 | `vw_kpi02_ticket_medio` | Ticket médio por ano e canal |
| 3 | `vw_kpi03_margem_categoria` | Margem bruta % por categoria |
| 4 | `vw_kpi04_crescimento_mensal` | Crescimento da receita mês a mês (%) |
| 5 | `vw_kpi05_receita_territorio` | Receita e participação % por território |
| 6 | `vw_kpi06_top10_produtos` | Top 10 produtos por receita |
| 7 | `vw_kpi07_desempenho_vendedor` | Receita, pedidos, ticket e ranking por vendedor |
| 8 | `vw_kpi08_taxa_desconto` | Taxa média de desconto sobre o valor bruto |
| 9 | `vw_kpi09_participacao_canal` | Participação % Online × Revenda na receita |
| 10 | `vw_kpi10_taxa_recompra` | % de clientes com 2+ pedidos no ano |

## Origem dos dados

`oltp/01_adventureworks_oltp.sql.gz` foi gerado a partir dos CSVs oficiais do
AdventureWorks 2014 OLTP (Microsoft/sql-server-samples) convertidos para PostgreSQL pelo projeto
[lorint/AdventureWorks-for-Postgres](https://github.com/lorint/AdventureWorks-for-Postgres)
(que desloca as datas: pedidos de 30/05/2022 a 29/06/2025).

## Comandos úteis

```bash
docker compose ps
docker compose logs -f airflow-scheduler
docker compose down          # para
docker compose down -v       # para e apaga os bancos (recomeça do zero)
```
