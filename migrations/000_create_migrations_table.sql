-- ============================================================================
-- Migration Control Table
-- Gerencia versões aplicadas do schema (tipo Git para banco de dados)
-- ============================================================================

-- Tabela de controle de migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  applied_by VARCHAR(255),
  description TEXT,
  checksum VARCHAR(64),
  execution_time_ms INTEGER
);

-- Índice para busca por data
CREATE INDEX IF NOT EXISTS idx_schema_migrations_applied_at
  ON schema_migrations(applied_at DESC);

-- Comentário
COMMENT ON TABLE schema_migrations IS
  'Controle de versões do schema (migrations aplicadas)';

COMMENT ON COLUMN schema_migrations.version IS
  'Versão da migration (ex: 001, 002, 003)';

COMMENT ON COLUMN schema_migrations.checksum IS
  'MD5 hash do arquivo SQL para detectar alterações';

-- Inserir registro desta migration (000 = bootstrap)
INSERT INTO schema_migrations (version, applied_by, description)
VALUES ('000', CURRENT_USER, 'Create migrations control table')
ON CONFLICT (version) DO NOTHING;

-- Verificação
DO $$
DECLARE
  count_migrations INTEGER;
BEGIN
  SELECT COUNT(*) INTO count_migrations FROM schema_migrations;
  RAISE NOTICE '✓ Tabela schema_migrations criada!';
  RAISE NOTICE '  Migrations aplicadas: %', count_migrations;
END $$;
