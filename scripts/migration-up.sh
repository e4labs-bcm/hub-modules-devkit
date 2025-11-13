#!/bin/bash

# ============================================================================
# Migration Up Script
# Aplica migrations pendentes ao banco de dados
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
echo "║  Migration Up - Aplicar Migrations Pendentes         ║"
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
  exit 1
fi

print_success "Conectado a $DB_NAME"
echo ""

# ============================================================================
# Verificar tabela schema_migrations
# ============================================================================

print_step "Verificando tabela de controle..."

TABLE_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT EXISTS (SELECT FROM pg_tables WHERE tablename = 'schema_migrations');" | tr -d ' ')

if [ "$TABLE_EXISTS" != "t" ]; then
  print_warning "Tabela schema_migrations não existe. Criando..."

  BOOTSTRAP_FILE="$MIGRATIONS_DIR/000_create_migrations_table.sql"

  if [ ! -f "$BOOTSTRAP_FILE" ]; then
    print_error "Arquivo de bootstrap não encontrado: $BOOTSTRAP_FILE"
    exit 1
  fi

  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$BOOTSTRAP_FILE" > /dev/null 2>&1
  print_success "Tabela schema_migrations criada!"
  echo ""
fi

# ============================================================================
# Listar migrations pendentes
# ============================================================================

print_step "Escaneando migrations pendentes..."

MIGRATION_FILES=$(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | grep -v "000_create_migrations_table.sql" | sort || true)

if [ -z "$MIGRATION_FILES" ]; then
  print_success "Nenhuma migration pendente!"
  echo ""
  exit 0
fi

PENDING_MIGRATIONS=""

while IFS= read -r migration_file; do
  FILENAME=$(basename "$migration_file")
  VERSION=$(echo "$FILENAME" | sed -E 's/^([0-9]{3})_.*/\1/')

  # Verificar se já foi aplicada
  IS_APPLIED=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
    "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '$VERSION');" | tr -d ' ')

  if [ "$IS_APPLIED" != "t" ]; then
    PENDING_MIGRATIONS="${PENDING_MIGRATIONS}${migration_file}\n"
  fi
done <<< "$MIGRATION_FILES"

if [ -z "$PENDING_MIGRATIONS" ]; then
  print_success "Nenhuma migration pendente!"
  echo ""
  exit 0
fi

PENDING_COUNT=$(echo -e "$PENDING_MIGRATIONS" | grep -v '^$' | wc -l | tr -d ' ')
print_warning "$PENDING_COUNT migration(s) pendente(s)"
echo ""

# ============================================================================
# Listar migrations que serão aplicadas
# ============================================================================

echo "Migrations que serão aplicadas:"
echo ""

echo -e "$PENDING_MIGRATIONS" | grep -v '^$' | while read migration_file; do
  FILENAME=$(basename "$migration_file")
  echo "  • $FILENAME"
done

echo ""

# ============================================================================
# Confirmar execução
# ============================================================================

read -p "Deseja aplicar estas migrations? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
  print_warning "Operação cancelada pelo usuário"
  exit 0
fi

echo ""

# ============================================================================
# Aplicar migrations
# ============================================================================

print_step "Aplicando migrations..."
echo ""

APPLIED_COUNT=0
FAILED_COUNT=0

echo -e "$PENDING_MIGRATIONS" | grep -v '^$' | while read migration_file; do
  FILENAME=$(basename "$migration_file")
  VERSION=$(echo "$FILENAME" | sed -E 's/^([0-9]{3})_.*/\1/')
  DESCRIPTION=$(echo "$FILENAME" | sed -E 's/^[0-9]{3}_(.*)\.sql$/\1/' | tr '_' ' ')

  print_step "Aplicando $FILENAME..."

  # Calcular MD5 checksum
  if command -v md5sum > /dev/null 2>&1; then
    CHECKSUM=$(md5sum "$migration_file" | awk '{print $1}')
  else
    # macOS usa md5 ao invés de md5sum
    CHECKSUM=$(md5 -q "$migration_file")
  fi

  # Medir tempo de execução
  START_TIME=$(date +%s%3N)

  # Aplicar migration
  if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file" > /dev/null 2>&1; then
    END_TIME=$(date +%s%3N)
    EXEC_TIME=$((END_TIME - START_TIME))

    # Registrar na tabela schema_migrations
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
      "INSERT INTO schema_migrations (version, applied_by, description, checksum, execution_time_ms)
       VALUES ('$VERSION', CURRENT_USER, '$DESCRIPTION', '$CHECKSUM', $EXEC_TIME)
       ON CONFLICT (version) DO NOTHING;" > /dev/null 2>&1

    print_success "$FILENAME aplicada! (${EXEC_TIME}ms)"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
  else
    print_error "$FILENAME FALHOU!"
    FAILED_COUNT=$((FAILED_COUNT + 1))

    # Se alguma migration falhar, parar execução
    echo ""
    print_error "Migration falhou. Execução interrompida."
    echo ""
    echo "Para investigar o erro:"
    echo "  psql -d $DB_NAME -f $migration_file"
    echo ""
    exit 1
  fi
done

# Verificar resultado final
FINAL_APPLIED=$(echo "$APPLIED_COUNT" | tail -n1)
FINAL_FAILED=$(echo "$FAILED_COUNT" | tail -n1)

echo ""

# ============================================================================
# Finalização
# ============================================================================

if [ "$FINAL_FAILED" -gt 0 ]; then
  print_error "$FINAL_FAILED migration(s) falharam!"
  echo ""
  exit 1
else
  print_success "Todas as migrations foram aplicadas com sucesso!"
  echo ""
  echo "Migrations aplicadas: $PENDING_COUNT"
  echo ""
  echo "Ver status completo:"
  echo "  bash scripts/migration-status.sh"
  echo ""
fi
