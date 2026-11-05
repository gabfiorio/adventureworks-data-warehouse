-- Extracao incremental: produtos com subcategoria e categoria (desnormalizado)
SELECT id_produto, nome_produto, numero_produto, cor, tamanho, subcategoria, categoria,
       linha_produto, custo_padrao, preco_tabela, data_modificacao
FROM (
    SELECT
        p.productid                         AS id_produto,
        p.name                              AS nome_produto,
        p.productnumber                     AS numero_produto,
        COALESCE(p.color, 'N/A')            AS cor,
        COALESCE(p.size, 'N/A')             AS tamanho,
        COALESCE(psc.name, 'Sem subcategoria') AS subcategoria,
        COALESCE(pc.name, 'Sem categoria')  AS categoria,
        CASE TRIM(p.productline) WHEN 'R' THEN 'Estrada' WHEN 'M' THEN 'Montanha'
                                 WHEN 'T' THEN 'Touring' WHEN 'S' THEN 'Padrao'
                                 ELSE 'N/A' END AS linha_produto,
        p.standardcost                      AS custo_padrao,
        p.listprice                         AS preco_tabela,
        GREATEST(p.modifieddate, psc.modifieddate, pc.modifieddate) AS data_modificacao
    FROM production.product p
    LEFT JOIN production.productsubcategory psc ON psc.productsubcategoryid = p.productsubcategoryid
    LEFT JOIN production.productcategory pc     ON pc.productcategoryid = psc.productcategoryid
) x
WHERE data_modificacao > %(watermark)s
