-- Extracao incremental: itens de pedido de venda (grao da fato)
-- Um item entra no delta se ele OU o cabecalho do pedido foi alterado.
-- Custo unitario: custo vigente na data do pedido (historico de custos);
-- se nao houver historico, usa o custo padrao atual do produto.
-- Imposto e frete do cabecalho sao rateados pelo valor liquido do item.
SELECT
    d.salesorderdetailid                       AS id_detalhe_pedido,
    h.salesorderid                             AS id_pedido,
    'SO' || h.salesorderid                     AS numero_pedido,
    CASE WHEN h.onlineorderflag THEN 'Online' ELSE 'Revenda' END AS canal_venda,
    h.orderdate::date                          AS data_pedido,
    h.shipdate::date                           AS data_envio,
    h.duedate::date                            AS data_vencimento,
    h.customerid                               AS id_cliente,
    d.productid                                AS id_produto,
    h.salespersonid                            AS id_vendedor,
    h.territoryid                              AS id_territorio,
    d.specialofferid                           AS id_promocao,
    h.shipmethodid                             AS id_metodo_envio,
    d.orderqty                                 AS quantidade,
    d.unitprice                                AS preco_unitario,
    d.unitpricediscount                        AS desconto_unitario_pct,
    COALESCE(ch.standardcost, p.standardcost)  AS custo_unitario,
    h.taxamt  * (d.orderqty * d.unitprice * (1 - d.unitpricediscount)) / NULLIF(h.subtotal, 0) AS valor_imposto,
    h.freight * (d.orderqty * d.unitprice * (1 - d.unitpricediscount)) / NULLIF(h.subtotal, 0) AS valor_frete,
    GREATEST(d.modifieddate, h.modifieddate)   AS data_modificacao
FROM sales.salesorderdetail d
JOIN sales.salesorderheader h ON h.salesorderid = d.salesorderid
JOIN production.product p     ON p.productid = d.productid
LEFT JOIN LATERAL (
    SELECT pch.standardcost
    FROM production.productcosthistory pch
    WHERE pch.productid = d.productid
      AND h.orderdate >= pch.startdate
      AND (pch.enddate IS NULL OR h.orderdate <= pch.enddate)
    ORDER BY pch.startdate DESC
    LIMIT 1
) ch ON TRUE
WHERE d.modifieddate > %(watermark)s
   OR h.modifieddate > %(watermark)s
