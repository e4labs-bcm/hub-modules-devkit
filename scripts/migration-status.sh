#!/bin/bash

# ============================================================================
# Migration Status Script
# Mostra status de todas as migrations (aplicadas e pendentes)
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_pending() { echo -e "${GRAY}○${NC} $1"; }

# ============================================================================
# Configuração
# ============================================================================

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS_DIR="$DEVKIT_DIR/migrations"

# Carregar .env.local se existir
if [ -f "$DEVKIT_DIR/.env.local" ]; then
  source "$DEVKIT_DIR/.env.local"
fi

# Database URL (fallback para localhost)
DB_URL="${DATABASE_URL:-postgresql://$(whoami):@localhost:5432/hub_app_dev?schema=public}"

# Extrair componentes da URL
DB_HOST=$(echo "$DB_URL" | sed -E 's#.*://[^:]*:?[^@]*@([^:/]+).*#\1#')
DB_PORT=$(echo "$DB_URL" | sed -E 's#.*://[^:]*:?[^@]*@[^:]+:([0-9]+).*#\1#')
DB_NAME=$(echo "$DB_URL" | sed -E 's#.*/([^?]+).*#\1#')
DB_USER=$(echo "$DB_URL" | sed -E 's#.*://([^:]+).*#\1#')

# ============================================================================
# Banner
# ============================================================================

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Migration Status - Hub.app DevKit                    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# Verificar conexão
# ============================================================================

print_step "Conectando ao banco de dados..."

if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
  print_error "Não foi possível conectar ao banco de dados"
  echo ""
  echo "Database: $DB_NAME"
  echo "Host:     $DB_HOST:$DB_PORT"
  echo "User:     $DB_USER"
  echo ""
  echo "Verifique se:"
  echo "  - PostgreSQL está rodando"
  echo "  - DATABASE_URL está correto em .env.local"
  echo "  - O banco de dados existe: createdb $DB_NAME"
  exit 1
fi

print_success "Conectado!"
echo ""

# ============================================================================
# Verificar tabela schema_migrations
# ============================================================================

print_step "Verificando tabela de controle..."

TABLE_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT EXISTS (SELECT FROM pg_tables WHERE tablename = 'schema_migrations');" | tr -d ' ')

if [ "$TABLE_EXISTS" != "t" ]; then
  print_warning "Tabela schema_migrations não existe!"
  echo ""
  echo "Execute primeiro:"
  echo "  psql -d $DB_NAME -f migrations/000_create_migrations_table.sql"
  echo ""
  exit 1
fi

print_success "Tabela schema_migrations existe"
echo ""

# ============================================================================
# Listar migrations do sistema de arquivos
# ============================================================================

print_step "Escaneando migrations..."

MIGRATION_FILES=$(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort || true)

if [ -z "$MIGRATION_FILES" ]; then
  print_warning "Nenhuma migration encontrada em $MIGRATIONS_DIR"
  exit 0
fi

TOTAL_FILES=$(echo "$MIGRATION_FILES" | wc -l | tr -d ' ')
print_success "$TOTAL_FILES migration(s) encontrada(s)"
echo ""

# ============================================================================
# Verificar status de cada migration
# ============================================================================

echo "┌────────┬─────────────────────────────────────┬──────────┬────────────────────┐"
echo "│ Status │ Migration                           │ Applied  │ By                 │"
echo "├────────┼─────────────────────────────────────┼──────────┼────────────────────┤"

APPLIED_COUNT=0
PENDING_COUNT=0

while IFS= read -r migration_file; do
  FILENAME=$(basename "$migration_file")
  VERSION=$(echo "$FILENAME" | sed -E 's/^([0-9]{3})_.*/\1/')

  # Buscar no banco se foi aplicada
  MIGRATION_INFO=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
    "SELECT
       applied_at::DATE,
       COALESCE(applied_by, ''),
       COALESCE(execution_time_ms::TEXT, '')
     FROM schema_migrations
     WHERE version = '$VERSION';" 2>/dev/null || echo "")

  if [ -n "$MIGRATION_INFO" ] && [ "$MIGRATION_INFO" != " | | " ]; then
    # Migration aplicada
    APPLIED_DATE=$(echo "$MIGRATION_INFO" | awk -F '|' '{print $1}' | tr -d ' ')
    APPLIED_BY=$(echo "$MIGRATION_INFO" | awk -F '|' '{print $2}' | tr -d ' ')
    EXEC_TIME=$(echo "$MIGRATION_INFO" | awk -F '|' '{print $3}' | tr -d ' ')

    # Truncar nome se muito longo
    DISPLAY_NAME=$(echo "$FILENAME" | cut -c 1-35)
    if [ ${#FILENAME} -gt 35 ]; then
      DISPLAY_NAME="${DISPLAY_NAME}..."
    fi

    # Truncar applied_by
    if [ ${#APPLIED_BY} -gt 18 ]; then
      APPLIED_BY="${APPLIED_BY:0:15}..."
    fi

    printf "│ ${GREEN}%-6s${NC} │ %-35s │ %-8s │ %-18s │\n" "✓ OK" "$DISPLAY_NAME" "$APPLIED_DATE" "$APPLIED_BY"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
  else
    # Migration pendente
    DISPLAY_NAME=$(echo "$FILENAME" | cut -c 1-35)
    if [ ${#FILENAME} -gt 35 ]; then
      DISPLAY_NAME="${DISPLAY_NAME}..."
    fi

    printf "│ ${GRAY}%-6s${NC} │ %-35s │ %-8s │ %-18s │\n" "○ PEND" "$DISPLAY_NAME" "-" "-"
    PENDING_COUNT=$((PENDING_COUNT + 1))
  fi
done <<< "$MIGRATION_FILES"

echo "└────────┴─────────────────────────────────────┴──────────┴────────────────────┘"
echo ""

# ============================================================================
# Resumo
# ============================================================================

echo "Resumo:"
echo "  ✓ Aplicadas: $APPLIED_COUNT"
echo "  ○ Pendentes: $PENDING_COUNT"
echo "  • Total:     $TOTAL_FILES"
echo ""

if [ $PENDING_COUNT -gt 0 ]; then
  print_warning "$PENDING_COUNT migration(s) pendente(s)"
  echo ""
  echo "Para aplicar migrations pendentes:"
  echo "  bash scripts/migration-up.sh"
  echo ""
fi

# ============================================================================
# Última migration aplicada
# ============================================================================

LAST_APPLIED=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT version, description, applied_at
   FROM schema_migrations
   ORDER BY applied_at DESC
   LIMIT 1;" 2>/dev/null || echo "")

if [ -n "$LAST_APPLIED" ] && [ "$LAST_APPLIED" != " | | " ]; then
  echo "Última migration aplicada:"
  LAST_VERSION=$(echo "$LAST_APPLIED" | awk -F '|' '{print $1}' | tr -d ' ')
  LAST_DESC=$(echo "$LAST_APPLIED" | awk -F '|' '{print $2}' | tr -d ' ')
  LAST_DATE=$(echo "$LAST_APPLIED" | awk -F '|' '{print $3}' | tr -d ' ')

  echo "  Versão:      $LAST_VERSION"
  echo "  Descrição:   $LAST_DESC"
  echo "  Data:        $LAST_DATE"
  echo ""
fi
