-- Carga SCD1: promocoes
INSERT INTO dw.dim_promocao (id_promocao, descricao, percentual_desconto, tipo_promocao,
                             categoria_promocao, data_inicio, data_fim)
SELECT id_promocao, descricao, percentual_desconto, tipo_promocao,
       categoria_promocao, data_inicio, data_fim
FROM stg.promocao
ON CONFLICT (id_promocao) DO UPDATE SET
    descricao           = EXCLUDED.descricao,
    percentual_desconto = EXCLUDED.percentual_desconto,
    tipo_promocao       = EXCLUDED.tipo_promocao,
    categoria_promocao  = EXCLUDED.categoria_promocao,
    data_inicio         = EXCLUDED.data_inicio,
    data_fim            = EXCLUDED.data_fim,
    data_atualizacao    = now();
