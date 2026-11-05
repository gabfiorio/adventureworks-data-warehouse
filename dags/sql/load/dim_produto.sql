-- Carga SCD1: produtos
INSERT INTO dw.dim_produto (id_produto, nome_produto, numero_produto, cor, tamanho,
                            subcategoria, categoria, linha_produto, custo_padrao, preco_tabela)
SELECT id_produto, nome_produto, numero_produto, cor, tamanho,
       subcategoria, categoria, linha_produto, custo_padrao, preco_tabela
FROM stg.produto
ON CONFLICT (id_produto) DO UPDATE SET
    nome_produto     = EXCLUDED.nome_produto,
    numero_produto   = EXCLUDED.numero_produto,
    cor              = EXCLUDED.cor,
    tamanho          = EXCLUDED.tamanho,
    subcategoria     = EXCLUDED.subcategoria,
    categoria        = EXCLUDED.categoria,
    linha_produto    = EXCLUDED.linha_produto,
    custo_padrao     = EXCLUDED.custo_padrao,
    preco_tabela     = EXCLUDED.preco_tabela,
    data_atualizacao = now();
