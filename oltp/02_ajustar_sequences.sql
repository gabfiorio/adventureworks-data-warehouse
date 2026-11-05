-- Executado automaticamente pelo container aw-oltp logo apos a restauracao.
-- Os dados do AdventureWorks foram importados com IDs explicitos, entao as
-- sequences ficaram em 1. Este script as posiciona apos o maior ID de cada
-- tabela, para que novos registros (ex.: pedidos simulados) recebam IDs validos.
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT ns.nspname AS esquema, s.relname AS seq, t.relname AS tabela, a.attname AS coluna
        FROM pg_class s
        JOIN pg_namespace ns ON ns.oid = s.relnamespace
        JOIN pg_depend d     ON d.objid = s.oid AND d.deptype IN ('a', 'i')
        JOIN pg_class t      ON t.oid = d.refobjid
        JOIN pg_namespace nt ON nt.oid = t.relnamespace
        JOIN pg_attribute a  ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
        WHERE s.relkind = 'S' AND nt.nspname = ns.nspname
    LOOP
        EXECUTE format(
            'SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I.%I), 0) + 1, false)',
            r.esquema || '.' || r.seq, r.coluna, r.esquema, r.tabela);
    END LOOP;
END $$;
