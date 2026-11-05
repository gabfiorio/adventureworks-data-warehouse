-- =====================================================================
-- Consulta dos 10 KPIs no Data Warehouse (banco adventureworks_dw).
-- As formulas estao nas views criadas pela DAG aw_dw_01_setup
-- (dags/sql/setup/04_views_kpis.sql).
--   docker compose exec aw-dw psql -U postgres -d adventureworks_dw -f /sql/kpis.sql
-- =====================================================================
\echo '== KPI 01 - Receita liquida mensal'
SELECT * FROM dw.vw_kpi01_receita_mensal ORDER BY ano_mes;
\echo '== KPI 02 - Ticket medio por ano e canal'
SELECT * FROM dw.vw_kpi02_ticket_medio ORDER BY ano, canal_venda;
\echo '== KPI 03 - Margem bruta por categoria'
SELECT * FROM dw.vw_kpi03_margem_categoria ORDER BY margem_bruta_pct DESC;
\echo '== KPI 04 - Crescimento mensal (MoM)'
SELECT * FROM dw.vw_kpi04_crescimento_mensal ORDER BY ano_mes;
\echo '== KPI 05 - Receita por territorio'
SELECT * FROM dw.vw_kpi05_receita_territorio ORDER BY receita_liquida DESC;
\echo '== KPI 06 - Top 10 produtos'
SELECT * FROM dw.vw_kpi06_top10_produtos;
\echo '== KPI 07 - Desempenho por vendedor'
SELECT * FROM dw.vw_kpi07_desempenho_vendedor ORDER BY ranking;
\echo '== KPI 08 - Taxa de desconto'
SELECT * FROM dw.vw_kpi08_taxa_desconto ORDER BY ano;
\echo '== KPI 09 - Participacao por canal'
SELECT * FROM dw.vw_kpi09_participacao_canal ORDER BY ano, canal_venda;
\echo '== KPI 10 - Taxa de recompra'
SELECT * FROM dw.vw_kpi10_taxa_recompra ORDER BY ano;

\echo '== Controle da ETL incremental (ultimas execucoes)'
SELECT dag_run_id, tabela, linhas_extraidas, marca_anterior, marca_nova
FROM ctrl.log_etl ORDER BY id_log DESC LIMIT 14;
