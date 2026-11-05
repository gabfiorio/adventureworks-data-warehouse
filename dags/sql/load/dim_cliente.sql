-- Carga SCD1: insere clientes novos e sobrescreve os alterados
INSERT INTO dw.dim_cliente (id_cliente, nome_cliente, tipo_cliente, cidade, estado_provincia, pais)
SELECT id_cliente, nome_cliente, tipo_cliente, cidade, estado_provincia, pais
FROM stg.cliente
ON CONFLICT (id_cliente) DO UPDATE SET
    nome_cliente     = EXCLUDED.nome_cliente,
    tipo_cliente     = EXCLUDED.tipo_cliente,
    cidade           = EXCLUDED.cidade,
    estado_provincia = EXCLUDED.estado_provincia,
    pais             = EXCLUDED.pais,
    data_atualizacao = now();
