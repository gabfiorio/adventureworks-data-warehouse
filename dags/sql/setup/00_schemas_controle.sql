-- =====================================================================
-- 00 - Schemas e tabelas de controle da ETL
--   stg  : area de staging (recebe apenas o delta de cada execucao)
--   dw   : modelo dimensional (Star Schema)
--   ctrl : metadados da ETL incremental (marca d'agua e log)
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS ctrl;

-- Marca d'agua (watermark): maior data de modificacao ja carregada por tabela
CREATE TABLE IF NOT EXISTS ctrl.marca_dagua (
    tabela              VARCHAR(50) PRIMARY KEY,
    ultima_extracao_em  TIMESTAMP   NOT NULL DEFAULT '1900-01-01',
    atualizado_em       TIMESTAMP   NOT NULL DEFAULT now()
);

INSERT INTO ctrl.marca_dagua (tabela) VALUES
    ('cliente'), ('produto'), ('vendedor'), ('territorio'),
    ('promocao'), ('metodo_envio'), ('vendas')
ON CONFLICT (tabela) DO NOTHING;

-- Log de cada execucao: quantas linhas cada tabela trouxe da origem
CREATE TABLE IF NOT EXISTS ctrl.log_etl (
    id_log            SERIAL PRIMARY KEY,
    dag_run_id        VARCHAR(250),
    tabela            VARCHAR(50) NOT NULL,
    marca_anterior    TIMESTAMP,
    marca_nova        TIMESTAMP,
    linhas_extraidas  INTEGER     NOT NULL,
    executado_em      TIMESTAMP   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Staging: mesma estrutura das consultas de extracao (sem chaves)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stg.cliente (
    id_cliente INTEGER, nome_cliente VARCHAR(150), tipo_cliente VARCHAR(30),
    cidade VARCHAR(100), estado_provincia VARCHAR(100), pais VARCHAR(100),
    data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.produto (
    id_produto INTEGER, nome_produto VARCHAR(150), numero_produto VARCHAR(30),
    cor VARCHAR(30), tamanho VARCHAR(10), subcategoria VARCHAR(100), categoria VARCHAR(100),
    linha_produto VARCHAR(20), custo_padrao NUMERIC(12,4), preco_tabela NUMERIC(12,4),
    data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.vendedor (
    id_vendedor INTEGER, nome_vendedor VARCHAR(150), cargo VARCHAR(100),
    cota_vendas NUMERIC(14,2), comissao_pct NUMERIC(6,4), data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.territorio (
    id_territorio INTEGER, nome_territorio VARCHAR(100), pais VARCHAR(100),
    grupo_territorio VARCHAR(50), data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.promocao (
    id_promocao INTEGER, descricao VARCHAR(255), percentual_desconto NUMERIC(6,4),
    tipo_promocao VARCHAR(50), categoria_promocao VARCHAR(50),
    data_inicio DATE, data_fim DATE, data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.metodo_envio (
    id_metodo_envio INTEGER, nome_metodo_envio VARCHAR(100),
    taxa_base NUMERIC(10,2), taxa_por_kg NUMERIC(10,2), data_modificacao TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stg.vendas (
    id_detalhe_pedido INTEGER, id_pedido INTEGER, numero_pedido VARCHAR(20),
    canal_venda VARCHAR(20), data_pedido DATE, data_envio DATE, data_vencimento DATE,
    id_cliente INTEGER, id_produto INTEGER, id_vendedor INTEGER, id_territorio INTEGER,
    id_promocao INTEGER, id_metodo_envio INTEGER,
    quantidade INTEGER, preco_unitario NUMERIC(14,4), desconto_unitario_pct NUMERIC(6,4),
    custo_unitario NUMERIC(14,4), valor_imposto NUMERIC(14,4), valor_frete NUMERIC(14,4),
    data_modificacao TIMESTAMP
);
