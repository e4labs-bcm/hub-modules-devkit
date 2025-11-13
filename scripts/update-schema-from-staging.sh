#!/bin/bash

# ============================================================================
# Update Schema from Staging
# Exporta o schema DDL do Hub.app STAGING para seeds locais
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
# Configurações
# ============================================================================

STAGING_HOST="${STAGING_HOST:-82.25.77.179}"
STAGING_PORT="${STAGING_PORT:-5433}"
STAGING_DB="${STAGING_DB:-hub_app_staging}"
STAGING_USER="${STAGING_USER:-hub_app_user}"

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEEDS_DIR="$DEVKIT_DIR/seeds"
OUTPUT_FILE="$SEEDS_DIR/01-schema-base.sql"

# ============================================================================
# Validações
# ============================================================================

print_step "Exportando schema do STAGING..."
echo ""
echo "  Host:     $STAGING_HOST:$STAGING_PORT"
echo "  Database: $STAGING_DB"
echo "  User:     $STAGING_USER"
echo ""

# Verificar se pg_dump existe
if ! command -v pg_dump &> /dev/null; then
  print_error "pg_dump não encontrado. Instale PostgreSQL client:"
  echo ""
  echo "  Mac:    brew install postgresql"
  echo "  Linux:  sudo apt install postgresql-client"
  echo ""
  exit 1
fi

# Criar diretório seeds se não existir
mkdir -p "$SEEDS_DIR"

# ============================================================================
# Backup do arquivo antigo (se existir)
# ============================================================================

if [ -f "$OUTPUT_FILE" ]; then
  BACKUP_FILE="$OUTPUT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
  print_step "Fazendo backup do schema antigo..."
  cp "$OUTPUT_FILE" "$BACKUP_FILE"
  print_success "Backup salvo em: $BACKUP_FILE"
  echo ""
fi

# ============================================================================
# Exportar schema (DDL only, sem dados)
# ============================================================================

print_step "Exportando schema (DDL only)..."

# Solicitar senha se não estiver em variável de ambiente
if [ -z "$PGPASSWORD" ]; then
  echo ""
  print_warning "Digite a senha do PostgreSQL STAGING:"
  read -s STAGING_PASSWORD
  export PGPASSWORD="$STAGING_PASSWORD"
  echo ""
fi

# Fazer dump do schema (--schema-only = só DDL, sem INSERT)
pg_dump \
  --host="$STAGING_HOST" \
  --port="$STAGING_PORT" \
  --username="$STAGING_USER" \
  --dbname="$STAGING_DB" \
  --schema-only \
  --no-owner \
  --no-privileges \
  --no-tablespaces \
  --file="$OUTPUT_FILE"

# Verificar se export foi bem sucedido
if [ $? -eq 0 ]; then
  print_success "Schema exportado com sucesso!"
else
  print_error "Erro ao exportar schema"
  exit 1
fi

# ============================================================================
# Adicionar header com metadata
# ============================================================================

print_step "Adicionando metadata ao arquivo..."

TEMP_FILE="$OUTPUT_FILE.tmp"

cat > "$TEMP_FILE" << EOF
-- ============================================================================
-- Hub.app Schema Base - Exportado do STAGING
-- ============================================================================
--
-- Database: $STAGING_DB
-- Host:     $STAGING_HOST:$STAGING_PORT
-- Exported: $(date '+%Y-%m-%d %H:%M:%S %Z')
-- By:       update-schema-from-staging.sh
--
-- IMPORTANTE:
--   - Este arquivo contém APENAS o schema (DDL)
--   - NÃO contém dados (sem INSERT statements)
--   - É gerado automaticamente - NÃO EDITAR MANUALMENTE
--   - Para atualizar: execute este script novamente
--
-- ============================================================================

EOF

# Adicionar conteúdo original após o header
cat "$OUTPUT_FILE" >> "$TEMP_FILE"

# Substituir arquivo original
mv "$TEMP_FILE" "$OUTPUT_FILE"

print_success "Metadata adicionada"

# ============================================================================
# Estatísticas do schema
# ============================================================================

print_step "Estatísticas do schema exportado:"
echo ""

# Contar tabelas
TABLES_COUNT=$(grep -c "CREATE TABLE" "$OUTPUT_FILE" || true)
echo "  Tabelas:  $TABLES_COUNT"

# Contar índices
INDEXES_COUNT=$(grep -c "CREATE.*INDEX" "$OUTPUT_FILE" || true)
echo "  Índices:  $INDEXES_COUNT"

# Contar functions
FUNCTIONS_COUNT=$(grep -c "CREATE.*FUNCTION" "$OUTPUT_FILE" || true)
echo "  Funções:  $FUNCTIONS_COUNT"

# Tamanho do arquivo
FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
echo "  Tamanho:  $FILE_SIZE"

echo ""

# ============================================================================
# Commit automático no Git (opcional)
# ============================================================================

print_step "Commit automático no Git..."

cd "$DEVKIT_DIR"

if git rev-parse --git-dir > /dev/null 2>&1; then
  git add "$OUTPUT_FILE"

  if git diff --cached --quiet; then
    print_warning "Nenhuma mudança no schema (já estava atualizado)"
  else
    git commit -m "chore: Update schema from staging ($(date +%Y-%m-%d))

Exported from: $STAGING_HOST:$STAGING_PORT/$STAGING_DB
Tables: $TABLES_COUNT | Indexes: $INDEXES_COUNT | Functions: $FUNCTIONS_COUNT
Size: $FILE_SIZE

Auto-generated by: scripts/update-schema-from-staging.sh"

    print_success "Schema commitado no Git!"
    echo ""
    print_warning "Execute 'git push' para enviar ao GitHub"
  fi
else
  print_warning "Não é um repositório Git. Pulando commit..."
fi

# ============================================================================
# Finalização
# ============================================================================

echo ""
print_success "Schema exportado com sucesso!"
echo ""
echo "  Arquivo: $OUTPUT_FILE"
echo "  Tabelas: $TABLES_COUNT"
echo ""
echo "Próximos passos:"
echo "  1. Revisar o schema exportado"
echo "  2. Aplicar no banco local: bash scripts/setup-database.js"
echo "  3. Fazer git push (se necessário)"
echo ""
