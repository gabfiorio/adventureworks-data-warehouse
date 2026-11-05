-- =====================================================================
-- 04 - Os 10 indicadores (KPIs) implementados como VIEWS em SQL
--   Consulta: SELECT * FROM dw.vw_kpi01_receita_mensal;  (etc.)
--   Receita = valor_liquido (apos desconto, sem imposto e frete).
-- =====================================================================

-- KPI 01 - Receita liquida mensal e numero de pedidos
CREATE OR REPLACE VIEW dw.vw_kpi01_receita_mensal AS
SELECT d.ano, d.mes, d.ano_mes,
       ROUND(SUM(f.valor_liquido), 2)   AS receita_liquida,
       COUNT(DISTINCT f.numero_pedido)  AS qtd_pedidos
FROM dw.fato_vendas f
JOIN dw.dim_data d ON d.chave_data = f.chave_data_pedido
GROUP BY d.ano, d.mes, d.ano_mes;

-- KPI 02 - Ticket medio por pedido, por ano e canal de venda
CREATE OR REPLACE VIEW dw.vw_kpi02_ticket_medio AS
SELECT d.ano, f.canal_venda,
       COUNT(DISTINCT f.numero_pedido)                                     AS qtd_pedidos,
       ROUND(SUM(f.valor_liquido) / COUNT(DISTINCT f.numero_pedido), 2)    AS ticket_medio
FROM dw.fato_vendas f
JOIN dw.dim_data d ON d.chave_data = f.chave_data_pedido
GROUP BY d.ano, f.canal_venda;

-- KPI 03 - Margem bruta (%) por categoria de produto
CREATE OR REPLACE VIEW dw.vw_kpi03_margem_categoria AS
SELECT p.categoria,
       ROUND(SUM(f.valor_liquido), 2)                       AS receita_liquida,
       ROUND(SUM(f.custo_total), 2)                         AS custo_total,
       ROUND(SUM(f.valor_liquido - f.custo_total), 2)       AS lucro_bruto,
       ROUND(100 * SUM(f.valor_liquido - f.custo_total)
                 / NULLIF(SUM(f.valor_liquido), 0), 2)      AS margem_bruta_pct
FROM dw.fato_vendas f
JOIN dw.dim_produto p ON p.chave_produto = f.chave_produto
GROUP BY p.categoria;

-- KPI 04 - Crescimento da receita mes contra mes anterior (MoM %)
CREATE OR REPLACE VIEW dw.vw_kpi04_crescimento_mensal AS
SELECT ano_mes, receita_liquida,
       ROUND(100 * (receita_liquida - LAG(receita_liquida) OVER (ORDER BY ano_mes))
                 / NULLIF(LAG(receita_liquida) OVER (ORDER BY ano_mes), 0), 2) AS crescimento_pct
FROM dw.vw_kpi01_receita_mensal;

-- KPI 05 - Receita e participacao (%) por territorio
CREATE OR REPLACE VIEW dw.vw_kpi05_receita_territorio AS
SELECT t.grupo_territorio, t.nome_territorio,
       ROUND(SUM(f.valor_liquido), 2)                                   AS receita_liquida,
       ROUND(100 * SUM(f.valor_liquido) / SUM(SUM(f.valor_liquido)) OVER (), 2) AS participacao_pct
FROM dw.fato_vendas f
JOIN dw.dim_territorio t ON t.chave_territorio = f.chave_territorio
GROUP BY t.grupo_territorio, t.nome_territorio;

-- KPI 06 - Top 10 produtos por receita
CREATE OR REPLACE VIEW dw.vw_kpi06_top10_produtos AS
SELECT p.nome_produto, p.categoria,
       SUM(f.quantidade)               AS qtd_vendida,
       ROUND(SUM(f.valor_liquido), 2)  AS receita_liquida
FROM dw.fato_vendas f
JOIN dw.dim_produto p ON p.chave_produto = f.chave_produto
GROUP BY p.nome_produto, p.categoria
ORDER BY receita_liquida DESC
LIMIT 10;

-- KPI 07 - Desempenho por vendedor (receita, pedidos, ticket, ranking)
CREATE OR REPLACE VIEW dw.vw_kpi07_desempenho_vendedor AS
SELECT v.nome_vendedor,
       ROUND(SUM(f.valor_liquido), 2)                                    AS receita_liquida,
       COUNT(DISTINCT f.numero_pedido)                                   AS qtd_pedidos,
       ROUND(SUM(f.valor_liquido) / COUNT(DISTINCT f.numero_pedido), 2)  AS ticket_medio,
       RANK() OVER (ORDER BY SUM(f.valor_liquido) DESC)                  AS ranking
FROM dw.fato_vendas f
JOIN dw.dim_vendedor v ON v.chave_vendedor = f.chave_vendedor
WHERE v.chave_vendedor <> -1
GROUP BY v.nome_vendedor;

-- KPI 08 - Taxa media de desconto concedido (% sobre o valor bruto), por ano
CREATE OR REPLACE VIEW dw.vw_kpi08_taxa_desconto AS
SELECT d.ano,
       ROUND(SUM(f.valor_desconto), 2)                                     AS valor_desconto,
       ROUND(100 * SUM(f.valor_desconto) / NULLIF(SUM(f.valor_bruto), 0), 2) AS taxa_desconto_pct
FROM dw.fato_vendas f
JOIN dw.dim_data d ON d.chave_data = f.chave_data_pedido
GROUP BY d.ano;

-- KPI 09 - Participacao (%) de cada canal de venda (Online x Revenda) na receita, por ano
CREATE OR REPLACE VIEW dw.vw_kpi09_participacao_canal AS
SELECT d.ano, f.canal_venda,
       ROUND(SUM(f.valor_liquido), 2)                                      AS receita_liquida,
       ROUND(100 * SUM(f.valor_liquido)
                 / SUM(SUM(f.valor_liquido)) OVER (PARTITION BY d.ano), 2) AS participacao_pct
FROM dw.fato_vendas f
JOIN dw.dim_data d ON d.chave_data = f.chave_data_pedido
GROUP BY d.ano, f.canal_venda;

-- KPI 10 - Taxa de recompra: % de clientes do ano com 2 ou mais pedidos
CREATE OR REPLACE VIEW dw.vw_kpi10_taxa_recompra AS
WITH pedidos_cliente AS (
    SELECT d.ano, f.chave_cliente, COUNT(DISTINCT f.numero_pedido) AS pedidos
    FROM dw.fato_vendas f
    JOIN dw.dim_data d ON d.chave_data = f.chave_data_pedido
    GROUP BY d.ano, f.chave_cliente
)
SELECT ano,
       COUNT(*)                                          AS clientes_ativos,
       COUNT(*) FILTER (WHERE pedidos >= 2)              AS clientes_recorrentes,
       ROUND(100.0 * COUNT(*) FILTER (WHERE pedidos >= 2) / COUNT(*), 2) AS taxa_recompra_pct
FROM pedidos_cliente
GROUP BY ano;
