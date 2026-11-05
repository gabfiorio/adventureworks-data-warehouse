-- Extracao incremental: territorios de venda
SELECT
    t.territoryid          AS id_territorio,
    t.name                 AS nome_territorio,
    cr.name                AS pais,
    t."group"              AS grupo_territorio,
    t.modifieddate         AS data_modificacao
FROM sales.salesterritory t
LEFT JOIN person.countryregion cr ON cr.countryregioncode = t.countryregioncode
WHERE t.modifieddate > %(watermark)s
