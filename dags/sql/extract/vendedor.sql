-- Extracao incremental: vendedores (funcionarios com cadastro de vendas)
SELECT id_vendedor, nome_vendedor, cargo, cota_vendas, comissao_pct, data_modificacao
FROM (
    SELECT
        sp.businessentityid                      AS id_vendedor,
        pe.firstname || ' ' || pe.lastname       AS nome_vendedor,
        e.jobtitle                               AS cargo,
        sp.salesquota                            AS cota_vendas,
        sp.commissionpct                         AS comissao_pct,
        GREATEST(sp.modifieddate, e.modifieddate, pe.modifieddate) AS data_modificacao
    FROM sales.salesperson sp
    JOIN humanresources.employee e ON e.businessentityid = sp.businessentityid
    JOIN person.person pe          ON pe.businessentityid = sp.businessentityid
) x
WHERE data_modificacao > %(watermark)s
