-- =====================================================================
-- 02 - Dimensoes (SCD Tipo 1: alteracao sobrescreve o valor anterior)
--   Cada dimensao tem chave substituta (SERIAL) + chave de negocio (UNIQUE).
--   Membro -1 = "Desconhecido / Nao se aplica" para evitar FK nula na fato.
-- =====================================================================
CREATE TABLE IF NOT EXISTS dw.dim_cliente (
    chave_cliente     SERIAL PRIMARY KEY,
    id_cliente        INTEGER NOT NULL UNIQUE,
    nome_cliente      VARCHAR(150),
    tipo_cliente      VARCHAR(30),
    cidade            VARCHAR(100),
    estado_provincia  VARCHAR(100),
    pais              VARCHAR(100),
    data_atualizacao  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.dim_produto (
    chave_produto     SERIAL PRIMARY KEY,
    id_produto        INTEGER NOT NULL UNIQUE,
    nome_produto      VARCHAR(150),
    numero_produto    VARCHAR(30),
    cor               VARCHAR(30),
    tamanho           VARCHAR(10),
    subcategoria      VARCHAR(100),
    categoria         VARCHAR(100),
    linha_produto     VARCHAR(20),
    custo_padrao      NUMERIC(12,4),
    preco_tabela      NUMERIC(12,4),
    data_atualizacao  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.dim_vendedor (
    chave_vendedor    SERIAL PRIMARY KEY,
    id_vendedor       INTEGER NOT NULL UNIQUE,
    nome_vendedor     VARCHAR(150),
    cargo             VARCHAR(100),
    cota_vendas       NUMERIC(14,2),
    comissao_pct      NUMERIC(6,4),
    data_atualizacao  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.dim_territorio (
    chave_territorio  SERIAL PRIMARY KEY,
    id_territorio     INTEGER NOT NULL UNIQUE,
    nome_territorio   VARCHAR(100),
    pais              VARCHAR(100),
    grupo_territorio  VARCHAR(50),
    data_atualizacao  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.dim_promocao (
    chave_promocao       SERIAL PRIMARY KEY,
    id_promocao          INTEGER NOT NULL UNIQUE,
    descricao            VARCHAR(255),
    percentual_desconto  NUMERIC(6,4),
    tipo_promocao        VARCHAR(50),
    categoria_promocao   VARCHAR(50),
    data_inicio          DATE,
    data_fim             DATE,
    data_atualizacao     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dw.dim_metodo_envio (
    chave_metodo_envio  SERIAL PRIMARY KEY,
    id_metodo_envio     INTEGER NOT NULL UNIQUE,
    nome_metodo_envio   VARCHAR(100),
    taxa_base           NUMERIC(10,2),
    taxa_por_kg         NUMERIC(10,2),
    data_atualizacao    TIMESTAMP NOT NULL DEFAULT now()
);

-- Membros "desconhecido" (chave -1)
INSERT INTO dw.dim_cliente (chave_cliente, id_cliente, nome_cliente, tipo_cliente)
VALUES (-1, -1, 'Desconhecido', 'N/A') ON CONFLICT DO NOTHING;
INSERT INTO dw.dim_produto (chave_produto, id_produto, nome_produto, categoria)
VALUES (-1, -1, 'Desconhecido', 'N/A') ON CONFLICT DO NOTHING;
INSERT INTO dw.dim_vendedor (chave_vendedor, id_vendedor, nome_vendedor, cargo)
VALUES (-1, -1, 'Sem vendedor (venda online)', 'N/A') ON CONFLICT DO NOTHING;
INSERT INTO dw.dim_territorio (chave_territorio, id_territorio, nome_territorio, grupo_territorio)
VALUES (-1, -1, 'Desconhecido', 'N/A') ON CONFLICT DO NOTHING;
INSERT INTO dw.dim_promocao (chave_promocao, id_promocao, descricao, percentual_desconto)
VALUES (-1, -1, 'Desconhecida', 0) ON CONFLICT DO NOTHING;
INSERT INTO dw.dim_metodo_envio (chave_metodo_envio, id_metodo_envio, nome_metodo_envio)
VALUES (-1, -1, 'Desconhecido') ON CONFLICT DO NOTHING;
