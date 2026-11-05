-- Extracao incremental: clientes (pessoas fisicas e lojas/revendas)
-- Considera alteracoes no cliente, na pessoa, na loja ou no endereco.
SELECT id_cliente, nome_cliente, tipo_cliente, cidade, estado_provincia, pais, data_modificacao
FROM (
    SELECT DISTINCT ON (c.customerid)
        c.customerid                                              AS id_cliente,
        COALESCE(s.name, p.firstname || ' ' || p.lastname,
                 'Cliente ' || c.customerid)                      AS nome_cliente,
        CASE WHEN c.storeid IS NOT NULL THEN 'Revenda (loja)'
             ELSE 'Pessoa fisica' END                             AS tipo_cliente,
        a.city                                                    AS cidade,
        sp.name                                                   AS estado_provincia,
        cr.name                                                   AS pais,
        GREATEST(c.modifieddate, p.modifieddate, s.modifieddate, a.modifieddate) AS data_modificacao
    FROM sales.customer c
    LEFT JOIN person.person p                  ON p.businessentityid = c.personid
    LEFT JOIN sales.store s                    ON s.businessentityid = c.storeid
    LEFT JOIN person.businessentityaddress bea ON bea.businessentityid = COALESCE(c.storeid, c.personid)
    LEFT JOIN person.address a                 ON a.addressid = bea.addressid
    LEFT JOIN person.stateprovince sp          ON sp.stateprovinceid = a.stateprovinceid
    LEFT JOIN person.countryregion cr          ON cr.countryregioncode = sp.countryregioncode
    ORDER BY c.customerid, bea.addresstypeid
) x
WHERE data_modificacao > %(watermark)s
