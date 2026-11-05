-- Carga SCD1: territorios
INSERT INTO dw.dim_territorio (id_territorio, nome_territorio, pais, grupo_territorio)
SELECT id_territorio, nome_territorio, pais, grupo_territorio
FROM stg.territorio
ON CONFLICT (id_territorio) DO UPDATE SET
    nome_territorio  = EXCLUDED.nome_territorio,
    pais             = EXCLUDED.pais,
    grupo_territorio = EXCLUDED.grupo_territorio,
    data_atualizacao = now();
