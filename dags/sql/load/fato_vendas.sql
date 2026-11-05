-- Carga da fato: troca chaves de negocio por chaves substitutas (lookup nas
-- dimensoes), calcula medidas derivadas e faz UPSERT pelo id do item.
-- Itens novos sao inseridos; itens ja existentes que mudaram sao atualizados.
INSERT INTO dw.fato_vendas (
    chave_data_pedido, chave_data_envio, chave_data_vencimento,
    chave_cliente, chave_produto, chave_vendedor, chave_territorio,
    chave_promocao, chave_metodo_envio,
    id_detalhe_pedido, numero_pedido, canal_venda,
    quantidade, preco_unitario, desconto_unitario_pct,
    valor_bruto, valor_desconto, valor_liquido, custo_total,
    valor_imposto, valor_frete, dias_para_envio,
    data_modificacao_origem
)
SELECT
    to_char(s.data_pedido, 'YYYYMMDD')::INTEGER,
    to_char(s.data_envio, 'YYYYMMDD')::INTEGER,
    to_char(s.data_vencimento, 'YYYYMMDD')::INTEGER,
    COALESCE(dc.chave_cliente, -1),
    COALESCE(dp.chave_produto, -1),
    COALESCE(dv.chave_vendedor, -1),
    COALESCE(dt.chave_territorio, -1),
    COALESCE(dpr.chave_promocao, -1),
    COALESCE(dm.chave_metodo_envio, -1),
    s.id_detalhe_pedido,
    s.numero_pedido,
    s.canal_venda,
    s.quantidade,
    s.preco_unitario,
    s.desconto_unitario_pct,
    s.quantidade * s.preco_unitario,
    s.quantidade * s.preco_unitario * s.desconto_unitario_pct,
    s.quantidade * s.preco_unitario * (1 - s.desconto_unitario_pct),
    s.quantidade * s.custo_unitario,
    COALESCE(s.valor_imposto, 0),
    COALESCE(s.valor_frete, 0),
    s.data_envio - s.data_pedido,
    s.data_modificacao
FROM stg.vendas s
LEFT JOIN dw.dim_cliente      dc  ON dc.id_cliente      = s.id_cliente
LEFT JOIN dw.dim_produto      dp  ON dp.id_produto      = s.id_produto
LEFT JOIN dw.dim_vendedor     dv  ON dv.id_vendedor     = s.id_vendedor
LEFT JOIN dw.dim_territorio   dt  ON dt.id_territorio   = s.id_territorio
LEFT JOIN dw.dim_promocao     dpr ON dpr.id_promocao    = s.id_promocao
LEFT JOIN dw.dim_metodo_envio dm  ON dm.id_metodo_envio = s.id_metodo_envio
ON CONFLICT (id_detalhe_pedido) DO UPDATE SET
    chave_data_pedido       = EXCLUDED.chave_data_pedido,
    chave_data_envio        = EXCLUDED.chave_data_envio,
    chave_data_vencimento   = EXCLUDED.chave_data_vencimento,
    chave_cliente           = EXCLUDED.chave_cliente,
    chave_produto           = EXCLUDED.chave_produto,
    chave_vendedor          = EXCLUDED.chave_vendedor,
    chave_territorio        = EXCLUDED.chave_territorio,
    chave_promocao          = EXCLUDED.chave_promocao,
    chave_metodo_envio      = EXCLUDED.chave_metodo_envio,
    canal_venda             = EXCLUDED.canal_venda,
    quantidade              = EXCLUDED.quantidade,
    preco_unitario          = EXCLUDED.preco_unitario,
    desconto_unitario_pct   = EXCLUDED.desconto_unitario_pct,
    valor_bruto             = EXCLUDED.valor_bruto,
    valor_desconto          = EXCLUDED.valor_desconto,
    valor_liquido           = EXCLUDED.valor_liquido,
    custo_total             = EXCLUDED.custo_total,
    valor_imposto           = EXCLUDED.valor_imposto,
    valor_frete             = EXCLUDED.valor_frete,
    dias_para_envio         = EXCLUDED.dias_para_envio,
    data_modificacao_origem = EXCLUDED.data_modificacao_origem,
    data_carga              = now();
