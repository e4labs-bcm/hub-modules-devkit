#!/bin/bash

# ============================================================================
# Setup PostgreSQL para Mac (Homebrew)
# Instala e configura PostgreSQL para desenvolvimento local
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
# Banner
# ============================================================================

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Hub.app DevKit - PostgreSQL Setup (Mac)             ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. Verificar Homebrew
# ============================================================================

print_step "1. Verificando Homebrew..."

if ! command -v brew &> /dev/null; then
  print_warning "Homebrew não encontrado. Instalando..."
  echo ""
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Verificar se instalou
  if ! command -v brew &> /dev/null; then
    print_error "Falha ao instalar Homebrew"
    echo "Visite: https://brew.sh"
    exit 1
  fi

  print_success "Homebrew instalado!"
else
  print_success "Homebrew já instalado ($(brew --version | head -n1))"
fi

echo ""

# ============================================================================
# 2. Instalar PostgreSQL
# ============================================================================

print_step "2. Instalando PostgreSQL..."

if command -v psql &> /dev/null; then
  CURRENT_VERSION=$(psql --version | awk '{print $3}')
  print_success "PostgreSQL já instalado (versão $CURRENT_VERSION)"
else
  brew install postgresql@16

  # Adicionar ao PATH
  if [[ -f ~/.zshrc ]]; then
    echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
  fi

  if [[ -f ~/.bash_profile ]]; then
    echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile
  fi

  print_success "PostgreSQL 16 instalado!"
fi

echo ""

# ============================================================================
# 3. Iniciar PostgreSQL
# ============================================================================

print_step "3. Iniciando PostgreSQL..."

# Verificar se já está rodando
if brew services list | grep postgresql@16 | grep started > /dev/null; then
  print_success "PostgreSQL já está rodando"
else
  brew services start postgresql@16
  sleep 3  # Aguardar inicialização
  print_success "PostgreSQL iniciado!"
fi

echo ""

# ============================================================================
# 4. Criar banco de dados
# ============================================================================

print_step "4. Criando banco de dados..."

DB_NAME="hub_app_dev"
DB_USER="${USER}"

# Verificar se banco já existe
if psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  print_warning "Banco '$DB_NAME' já existe"
  read -p "Deseja recriar (todos os dados serão perdidos)? (y/n): " RECREATE

  if [[ "$RECREATE" == "y" ]]; then
    print_step "Removendo banco existente..."
    dropdb "$DB_NAME"
    createdb "$DB_NAME"
    print_success "Banco recriado!"
  else
    print_warning "Mantendo banco existente"
  fi
else
  createdb "$DB_NAME"
  print_success "Banco '$DB_NAME' criado!"
fi

echo ""

# ============================================================================
# 5. Testar conexão
# ============================================================================

print_step "5. Testando conexão..."

if psql -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
  print_success "Conexão OK!"
  PSQL_VERSION=$(psql -d "$DB_NAME" -t -c "SELECT version();" | head -n1 | awk '{print $2}')
  echo "   Versão: PostgreSQL $PSQL_VERSION"
else
  print_error "Falha na conexão"
  exit 1
fi

echo ""

# ============================================================================
# 6. Criar arquivo .env.local
# ============================================================================

print_step "6. Criando .env.local..."

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DEVKIT_DIR/.env.local"

if [[ -f "$ENV_FILE" ]]; then
  print_warning "Arquivo .env.local já existe"
else
  cat > "$ENV_FILE" << EOF
# PostgreSQL Development Database
DATABASE_URL="postgresql://${USER}:@localhost:5432/${DB_NAME}?schema=public"

# Hub.app Config (opcional)
HUB_APP_PATH="${HOME}/Documents/Claude/hub-app-nextjs"
EOF

  print_success ".env.local criado!"
fi

echo ""

# ============================================================================
# 7. Aplicar seeds (opcional)
# ============================================================================

print_step "7. Aplicar seeds de desenvolvimento?"
echo ""
echo "   Seeds disponíveis:"
echo "   - 01-schema-base.sql (DDL do Hub.app)"
echo "   - 02-dev-tenants.sql (3 empresas)"
echo "   - 03-dev-users.sql (9 usuários)"
echo "   - 04-dev-financeiro.sql (dados de exemplo)"
echo ""
read -p "Deseja aplicar os seeds? (y/n): " APPLY_SEEDS

if [[ "$APPLY_SEEDS" == "y" ]]; then
  SEEDS_DIR="$DEVKIT_DIR/seeds"

  # Verificar se schema base existe
  if [[ ! -f "$SEEDS_DIR/01-schema-base.sql" ]]; then
    print_warning "Schema base não encontrado. Execute primeiro:"
    echo "   bash scripts/update-schema-from-staging.sh"
    echo ""
  else
    print_step "Aplicando seeds..."

    # Aplicar seeds na ordem
    for seed_file in "$SEEDS_DIR"/0*.sql; do
      if [[ -f "$seed_file" ]]; then
        SEED_NAME=$(basename "$seed_file")
        print_step "  Aplicando $SEED_NAME..."
        psql -d "$DB_NAME" -f "$seed_file" > /dev/null 2>&1
        print_success "  $SEED_NAME aplicado!"
      fi
    done

    echo ""
    print_success "Seeds aplicados com sucesso!"
  fi
else
  print_warning "Seeds não aplicados. Execute manualmente depois se necessário:"
  echo "   psql -d $DB_NAME -f seeds/01-schema-base.sql"
fi

echo ""

# ============================================================================
# Finalização
# ============================================================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✓ Setup concluído com sucesso!                      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Informações da instalação:"
echo "  Database:     $DB_NAME"
echo "  Host:         localhost:5432"
echo "  User:         $USER"
echo "  Connection:   postgresql://${USER}:@localhost:5432/${DB_NAME}"
echo ""
echo "Próximos passos:"
echo "  1. Testar conexão:"
echo "     psql -d $DB_NAME"
echo ""
echo "  2. Ver tabelas criadas:"
echo "     psql -d $DB_NAME -c \"\\dt\""
echo ""
echo "  3. Contar registros:"
echo "     psql -d $DB_NAME -c \"SELECT COUNT(*) FROM perfis;\""
echo ""
echo "Para parar o PostgreSQL:"
echo "  brew services stop postgresql@16"
echo ""
