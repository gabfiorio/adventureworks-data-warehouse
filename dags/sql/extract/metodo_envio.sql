-- Extracao incremental: metodos de envio
SELECT
    shipmethodid   AS id_metodo_envio,
    name           AS nome_metodo_envio,
    shipbase       AS taxa_base,
    shiprate       AS taxa_por_kg,
    modifieddate   AS data_modificacao
FROM purchasing.shipmethod
WHERE modifieddate > %(watermark)s
