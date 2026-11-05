-- Carga SCD1: vendedores
INSERT INTO dw.dim_vendedor (id_vendedor, nome_vendedor, cargo, cota_vendas, comissao_pct)
SELECT id_vendedor, nome_vendedor, cargo, cota_vendas, comissao_pct
FROM stg.vendedor
ON CONFLICT (id_vendedor) DO UPDATE SET
    nome_vendedor    = EXCLUDED.nome_vendedor,
    cargo            = EXCLUDED.cargo,
    cota_vendas      = EXCLUDED.cota_vendas,
    comissao_pct     = EXCLUDED.comissao_pct,
    data_atualizacao = now();
