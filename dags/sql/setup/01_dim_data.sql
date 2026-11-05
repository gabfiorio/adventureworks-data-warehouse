-- =====================================================================
-- 01 - Dimensao Data (gerada, nao vem da origem)
--   Ano fiscal AdventureWorks: inicia em 1o de julho.
-- =====================================================================
CREATE TABLE IF NOT EXISTS dw.dim_data (
    chave_data        INTEGER PRIMARY KEY,         -- formato AAAAMMDD
    data_completa     DATE        NOT NULL UNIQUE,
    dia               SMALLINT    NOT NULL,
    dia_semana        SMALLINT    NOT NULL,        -- 1 = domingo ... 7 = sabado
    nome_dia_semana   VARCHAR(15) NOT NULL,
    mes               SMALLINT    NOT NULL,
    nome_mes          VARCHAR(15) NOT NULL,
    ano_mes           CHAR(7)     NOT NULL,        -- AAAA-MM
    trimestre         SMALLINT    NOT NULL,
    semestre          SMALLINT    NOT NULL,
    ano               SMALLINT    NOT NULL,
    fim_de_semana     BOOLEAN     NOT NULL,
    ano_fiscal        SMALLINT    NOT NULL,
    trimestre_fiscal  SMALLINT    NOT NULL
);

INSERT INTO dw.dim_data
SELECT
    to_char(d, 'YYYYMMDD')::INTEGER,
    d::DATE,
    EXTRACT(DAY FROM d),
    EXTRACT(DOW FROM d) + 1,
    (ARRAY['Domingo','Segunda','Terca','Quarta','Quinta','Sexta','Sabado'])[EXTRACT(DOW FROM d) + 1],
    EXTRACT(MONTH FROM d),
    (ARRAY['Janeiro','Fevereiro','Marco','Abril','Maio','Junho','Julho',
           'Agosto','Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)],
    to_char(d, 'YYYY-MM'),
    EXTRACT(QUARTER FROM d),
    CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END,
    EXTRACT(YEAR FROM d),
    EXTRACT(DOW FROM d) IN (0, 6),
    EXTRACT(YEAR FROM d) + CASE WHEN EXTRACT(MONTH FROM d) >= 7 THEN 1 ELSE 0 END,
    ((EXTRACT(MONTH FROM d)::INT + 5) % 12) / 3 + 1
FROM generate_series('2020-01-01'::DATE, '2030-12-31'::DATE, INTERVAL '1 day') AS d
ON CONFLICT (chave_data) DO NOTHING;
