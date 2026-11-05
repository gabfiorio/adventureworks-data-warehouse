-- =====================================================================
-- 03 - Fato Vendas
--   Grao: 1 linha por item de pedido de venda (Sales.SalesOrderDetail).
--   Imposto e frete vem do cabecalho do pedido e sao rateados por item
--   proporcionalmente ao valor liquido, para poderem ser somados sem
--   dupla contagem.
-- =====================================================================
CREATE TABLE IF NOT EXISTS dw.fato_vendas (
    chave_venda             BIGSERIAL PRIMARY KEY,
    -- chaves estrangeiras (dimensoes)
    chave_data_pedido       INTEGER NOT NULL REFERENCES dw.dim_data (chave_data),
    chave_data_envio        INTEGER          REFERENCES dw.dim_data (chave_data),
    chave_data_vencimento   INTEGER NOT NULL REFERENCES dw.dim_data (chave_data),
    chave_cliente           INTEGER NOT NULL REFERENCES dw.dim_cliente (chave_cliente),
    chave_produto           INTEGER NOT NULL REFERENCES dw.dim_produto (chave_produto),
    chave_vendedor          INTEGER NOT NULL REFERENCES dw.dim_vendedor (chave_vendedor),
    chave_territorio        INTEGER NOT NULL REFERENCES dw.dim_territorio (chave_territorio),
    chave_promocao          INTEGER NOT NULL REFERENCES dw.dim_promocao (chave_promocao),
    chave_metodo_envio      INTEGER NOT NULL REFERENCES dw.dim_metodo_envio (chave_metodo_envio),
    -- dimensoes degeneradas
    id_detalhe_pedido       INTEGER NOT NULL UNIQUE,     -- chave de negocio do item
    numero_pedido           VARCHAR(20) NOT NULL,
    canal_venda             VARCHAR(20) NOT NULL,        -- Online / Revenda
    -- medidas
    quantidade              INTEGER       NOT NULL,
    preco_unitario          NUMERIC(14,4) NOT NULL,
    desconto_unitario_pct   NUMERIC(6,4)  NOT NULL DEFAULT 0,
    valor_bruto             NUMERIC(16,4) NOT NULL,      -- quantidade x preco
    valor_desconto          NUMERIC(16,4) NOT NULL,
    valor_liquido           NUMERIC(16,4) NOT NULL,      -- bruto - desconto
    custo_total             NUMERIC(16,4) NOT NULL,      -- quantidade x custo vigente
    valor_imposto           NUMERIC(16,4) NOT NULL DEFAULT 0,
    valor_frete             NUMERIC(16,4) NOT NULL DEFAULT 0,
    dias_para_envio         INTEGER,
    -- auditoria
    data_modificacao_origem TIMESTAMP NOT NULL,
    data_carga              TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_fato_vendas_data      ON dw.fato_vendas (chave_data_pedido);
CREATE INDEX IF NOT EXISTS ix_fato_vendas_cliente   ON dw.fato_vendas (chave_cliente);
CREATE INDEX IF NOT EXISTS ix_fato_vendas_produto   ON dw.fato_vendas (chave_produto);
CREATE INDEX IF NOT EXISTS ix_fato_vendas_vendedor  ON dw.fato_vendas (chave_vendedor);
CREATE INDEX IF NOT EXISTS ix_fato_vendas_territorio ON dw.fato_vendas (chave_territorio);
