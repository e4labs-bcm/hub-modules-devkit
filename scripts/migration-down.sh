#!/bin/bash

# ============================================================================
# Migration Down Script
# Faz rollback de uma migration específica (PERIGOSO - pode perder dados!)
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
  print_error "Versão da migration é obrigatória!"
  echo ""
  echo "Uso:"
  echo "  bash scripts/migration-down.sh <versão>"
  echo ""
  echo "Exemplos:"
  echo "  bash scripts/migration-down.sh 001"
  echo "  bash scripts/migration-down.sh 005"
  echo ""
  echo "ATENÇÃO: Esta operação pode causar PERDA DE DADOS!"
  echo ""
  exit 1
fi

VERSION="$1"

# Normalizar versão para 3 dígitos
VERSION=$(printf "%03d" $((10#$VERSION)))

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
echo "║  Migration Down - Rollback de Migration              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# Verificar conexão
# ============================================================================

print_step "Conectando ao banco de dados..."

if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
  print_error "Não foi possível conectar ao banco de dados"
  exit 1
fi

print_success "Conectado a $DB_NAME"
echo ""

# ============================================================================
# Encontrar arquivo de migration
# ============================================================================

print_step "Procurando migration $VERSION..."

MIGRATION_FILE=$(ls "$MIGRATIONS_DIR/${VERSION}_"*.sql 2>/dev/null | head -n1 || true)

if [ -z "$MIGRATION_FILE" ]; then
  print_error "Migration $VERSION não encontrada!"
  echo ""
  echo "Migrations disponíveis:"
  ls "$MIGRATIONS_DIR"/*.sql | while read f; do
    echo "  • $(basename "$f")"
  done
  echo ""
  exit 1
fi

FILENAME=$(basename "$MIGRATION_FILE")
print_success "Encontrada: $FILENAME"
echo ""

# ============================================================================
# Verificar se migration está aplicada
# ============================================================================

print_step "Verificando se migration está aplicada..."

IS_APPLIED=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '$VERSION');" | tr -d ' ')

if [ "$IS_APPLIED" != "t" ]; then
  print_warning "Migration $VERSION não está aplicada no banco!"
  echo ""
  echo "Ver migrations aplicadas:"
  echo "  bash scripts/migration-status.sh"
  echo ""
  exit 1
fi

print_success "Migration aplicada - pode fazer rollback"
echo ""

# ============================================================================
# Buscar informações da migration
# ============================================================================

MIGRATION_INFO=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
  "SELECT description, applied_at, applied_by
   FROM schema_migrations
   WHERE version = '$VERSION';" | sed 's/|/;/g')

DESCRIPTION=$(echo "$MIGRATION_INFO" | awk -F ';' '{print $1}' | tr -d ' ')
APPLIED_AT=$(echo "$MIGRATION_INFO" | awk -F ';' '{print $2}' | tr -d ' ')
APPLIED_BY=$(echo "$MIGRATION_INFO" | awk -F ';' '{print $3}' | tr -d ' ')

echo "Detalhes da migration:"
echo "  Versão:      $VERSION"
echo "  Descrição:   $DESCRIPTION"
echo "  Aplicada em: $APPLIED_AT"
echo "  Aplicada por: $APPLIED_BY"
echo ""

# ============================================================================
# Avisos de segurança
# ============================================================================

print_warning "⚠️  ATENÇÃO - OPERAÇÃO DESTRUTIVA!"
echo ""
echo "Esta operação fará rollback da migration $VERSION."
echo ""
echo "Isso pode:"
echo "  • Deletar tabelas e dados"
echo "  • Remover colunas e índices"
echo "  • Causar perda IRREVERSÍVEL de dados"
echo ""
print_warning "SEMPRE faça backup antes de fazer rollback!"
echo ""

# ============================================================================
# Mostrar comandos SQL que serão executados
# ============================================================================

print_step "Comandos SQL que serão executados:"
echo ""

# Extrair seção DOWN do arquivo
DOWN_SECTION=$(sed -n '/^-- DOWN:/,/^-- /p' "$MIGRATION_FILE" | grep -v '^--' | grep -v '^$' || true)

if [ -z "$DOWN_SECTION" ]; then
  print_error "Seção DOWN não encontrada no arquivo de migration!"
  echo ""
  echo "Este arquivo não tem comandos de rollback definidos."
  echo "Você precisará fazer o rollback manualmente."
  echo ""
  echo "Arquivo: $MIGRATION_FILE"
  echo ""
  exit 1
fi

echo "$DOWN_SECTION"
echo ""

# ============================================================================
# Confirmar execução
# ============================================================================

print_warning "Esta operação NÃO pode ser desfeita!"
echo ""
read -p "Digite 'ROLLBACK' para confirmar: " CONFIRM

if [ "$CONFIRM" != "ROLLBACK" ]; then
  print_warning "Operação cancelada"
  exit 0
fi

echo ""

# ============================================================================
# Executar rollback
# ============================================================================

print_step "Executando rollback..."

# Criar arquivo temporário com comandos DOWN
TEMP_DOWN_FILE=$(mktemp)
echo "$DOWN_SECTION" > "$TEMP_DOWN_FILE"

# Executar comandos DOWN
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$TEMP_DOWN_FILE" > /dev/null 2>&1; then
  print_success "Comandos SQL executados com sucesso"
else
  print_error "Erro ao executar comandos SQL!"
  rm "$TEMP_DOWN_FILE"
  exit 1
fi

rm "$TEMP_DOWN_FILE"

# ============================================================================
# Remover registro da tabela schema_migrations
# ============================================================================

print_step "Removendo registro da tabela de controle..."

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
  "DELETE FROM schema_migrations WHERE version = '$VERSION';" > /dev/null 2>&1

print_success "Registro removido"
echo ""

# ============================================================================
# Finalização
# ============================================================================

print_success "Rollback concluído com sucesso!"
echo ""
echo "Migration $VERSION foi revertida."
echo ""
echo "Próximos passos:"
echo "  • Ver status: bash scripts/migration-status.sh"
echo "  • Reaplicar migration: bash scripts/migration-up.sh"
echo ""
