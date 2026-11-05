-- Carga SCD1: metodos de envio
INSERT INTO dw.dim_metodo_envio (id_metodo_envio, nome_metodo_envio, taxa_base, taxa_por_kg)
SELECT id_metodo_envio, nome_metodo_envio, taxa_base, taxa_por_kg
FROM stg.metodo_envio
ON CONFLICT (id_metodo_envio) DO UPDATE SET
    nome_metodo_envio = EXCLUDED.nome_metodo_envio,
    taxa_base         = EXCLUDED.taxa_base,
    taxa_por_kg       = EXCLUDED.taxa_por_kg,
    data_atualizacao  = now();
