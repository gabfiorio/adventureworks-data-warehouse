-- =====================================================================
-- Simulacao de movimento no OLTP para demonstrar a carga INCREMENTAL.
-- Executar no banco de ORIGEM (adventureworks), depois disparar a DAG
-- aw_dw_02_etl_incremental e conferir ctrl.log_etl no DW.
--
--   docker compose exec aw-oltp psql -U postgres -d adventureworks -f /sql/simular_alteracoes_oltp.sql
--
-- Resultado esperado na proxima execucao da ETL:
--   vendas  : itens do pedido novo + 1 item alterado (nao as 121 mil linhas)
--   produto : 1 linha (preco alterado)
--   cliente : 1 linha (nome alterado)
--   demais  : 0 linhas
-- =====================================================================
BEGIN;

-- 1) NOVO pedido: copia o pedido 43659 com data de hoje
WITH novo AS (
    INSERT INTO sales.salesorderheader (
        revisionnumber, orderdate, duedate, shipdate, status, onlineorderflag,
        purchaseordernumber, accountnumber, customerid, salespersonid, territoryid,
        billtoaddressid, shiptoaddressid, shipmethodid, creditcardid,
        creditcardapprovalcode, currencyrateid, subtotal, taxamt, freight, totaldue,
        comment, modifieddate)
    SELECT revisionnumber, current_date, current_date + 12, current_date + 7, status, onlineorderflag,
           purchaseordernumber, accountnumber, customerid, salespersonid, territoryid,
           billtoaddressid, shiptoaddressid, shipmethodid, creditcardid,
           creditcardapprovalcode, currencyrateid, subtotal, taxamt, freight, totaldue,
           'Pedido simulado para teste de carga incremental', now()
    FROM sales.salesorderheader
    WHERE salesorderid = 43659
    RETURNING salesorderid
)
INSERT INTO sales.salesorderdetail (salesorderid, carriertrackingnumber, orderqty, productid,
                                    specialofferid, unitprice, unitpricediscount, modifieddate)
SELECT novo.salesorderid, d.carriertrackingnumber, d.orderqty, d.productid,
       d.specialofferid, d.unitprice, d.unitpricediscount, now()
FROM sales.salesorderdetail d, novo
WHERE d.salesorderid = 43659;

-- 2) ALTERACAO em item existente: quantidade do primeiro item do pedido 43660
UPDATE sales.salesorderdetail
SET orderqty = orderqty + 1, modifieddate = now()
WHERE salesorderdetailid = (SELECT MIN(salesorderdetailid) FROM sales.salesorderdetail WHERE salesorderid = 43660);

-- 3) ALTERACAO de cadastro: preco de tabela de um produto (SCD1 sobrescreve)
UPDATE production.product
SET listprice = ROUND(listprice * 1.05, 2), modifieddate = now()
WHERE productid = 776;

-- 4) ALTERACAO de cadastro: nome de um cliente pessoa fisica
UPDATE person.person
SET lastname = lastname || ' Silva', modifieddate = now()
WHERE businessentityid = (SELECT personid FROM sales.customer WHERE customerid = 11000);

COMMIT;
