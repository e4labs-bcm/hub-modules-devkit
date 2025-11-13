#!/bin/bash

# ============================================================================
# Migration Create Script
# Cria nova migration numerada automaticamente (tipo Git para banco de dados)
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }

# ============================================================================
# Validar argumentos
# ============================================================================

if [ -z "$1" ]; then
  print_error "Descrição da migration é obrigatória!"
  echo ""
  echo "Uso:"
  echo "  bash scripts/migration-create.sh \"descrição da migration\""
  echo ""
  echo "Exemplos:"
  echo "  bash scripts/migration-create.sh \"add user avatar field\""
  echo "  bash scripts/migration-create.sh \"create payments table\""
  exit 1
fi

DESCRIPTION="$1"

# ============================================================================
# Configuração
# ============================================================================

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS_DIR="$DEVKIT_DIR/migrations"

# Criar diretório migrations se não existir
mkdir -p "$MIGRATIONS_DIR"

# ============================================================================
# Calcular próximo número de versão
# ============================================================================

print_step "Calculando próximo número de versão..."

# Encontrar maior número existente
LAST_MIGRATION=$(ls "$MIGRATIONS_DIR" | grep -E '^[0-9]{3}_.*\.sql$' | sort | tail -n1)

if [ -z "$LAST_MIGRATION" ]; then
  # Primeira migration (após 000_create_migrations_table.sql)
  NEXT_VERSION="001"
else
  # Extrair número da última migration e incrementar
  LAST_NUMBER=$(echo "$LAST_MIGRATION" | sed -E 's/^([0-9]{3})_.*/\1/')
  NEXT_NUMBER=$((10#$LAST_NUMBER + 1))
  NEXT_VERSION=$(printf "%03d" $NEXT_NUMBER)
fi

print_success "Próxima versão: $NEXT_VERSION"

# ============================================================================
# Gerar nome do arquivo
# ============================================================================

# Sanitizar descrição para nome de arquivo
# - Converter para lowercase
# - Substituir espaços por underscores
# - Remover caracteres especiais
FILE_NAME=$(echo "$DESCRIPTION" | \
  tr '[:upper:]' '[:lower:]' | \
  tr ' ' '_' | \
  sed 's/[^a-z0-9_]//g')

MIGRATION_FILE="${NEXT_VERSION}_${FILE_NAME}.sql"
MIGRATION_PATH="$MIGRATIONS_DIR/$MIGRATION_FILE"

print_step "Criando migration: $MIGRATION_FILE"

# ============================================================================
# Criar arquivo de migration
# ============================================================================

cat > "$MIGRATION_PATH" << 'EOF'
-- ============================================================================
-- Migration: VERSION - DESCRIPTION
-- Created: TIMESTAMP
-- ============================================================================

-- ----------------------------------------------------------------------------
-- UP: Apply Migration
-- ----------------------------------------------------------------------------

-- Adicione seus comandos SQL aqui
-- Exemplo:
-- CREATE TABLE example (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
--   name VARCHAR(255) NOT NULL,
--   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--   updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );
--
-- CREATE INDEX idx_example_tenant ON example(tenant_id);
--
-- COMMENT ON TABLE example IS 'Descrição da tabela';

-- ----------------------------------------------------------------------------
-- Verification
-- ----------------------------------------------------------------------------

DO $$
BEGIN
  RAISE NOTICE '✓ Migration VERSION applied successfully!';
  RAISE NOTICE '  Description: DESCRIPTION';
END $$;

-- ----------------------------------------------------------------------------
-- DOWN: Rollback Migration (para migration-down.sh)
-- ----------------------------------------------------------------------------
-- Para fazer rollback desta migration, execute:
-- DROP TABLE IF EXISTS example CASCADE;
-- DELETE FROM schema_migrations WHERE version = 'VERSION';

EOF

# ============================================================================
# Substituir placeholders
# ============================================================================

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# macOS usa sed -i '' (BSD sed)
# Linux usa sed -i (GNU sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/VERSION/$NEXT_VERSION/g" "$MIGRATION_PATH"
  sed -i '' "s/DESCRIPTION/$DESCRIPTION/g" "$MIGRATION_PATH"
  sed -i '' "s/TIMESTAMP/$TIMESTAMP/g" "$MIGRATION_PATH"
else
  sed -i "s/VERSION/$NEXT_VERSION/g" "$MIGRATION_PATH"
  sed -i "s/DESCRIPTION/$DESCRIPTION/g" "$MIGRATION_PATH"
  sed -i "s/TIMESTAMP/$TIMESTAMP/g" "$MIGRATION_PATH"
fi

# ============================================================================
# Finalização
# ============================================================================

print_success "Migration criada com sucesso!"
echo ""
echo "Arquivo: $MIGRATION_PATH"
echo ""
echo "Próximos passos:"
echo "  1. Editar o arquivo e adicionar seus comandos SQL"
echo "  2. Testar localmente: psql -d hub_app_dev -f $MIGRATION_PATH"
echo "  3. Ver status: bash scripts/migration-status.sh"
echo "  4. Aplicar: bash scripts/migration-up.sh"
echo ""
