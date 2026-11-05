-- Extracao incremental: ofertas especiais / promocoes
SELECT
    specialofferid     AS id_promocao,
    description        AS descricao,
    discountpct        AS percentual_desconto,
    type               AS tipo_promocao,
    category           AS categoria_promocao,
    startdate::date    AS data_inicio,
    enddate::date      AS data_fim,
    modifieddate       AS data_modificacao
FROM sales.specialoffer
WHERE modifieddate > %(watermark)s
