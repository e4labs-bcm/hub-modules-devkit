#!/bin/bash

# ============================================================================
# Setup PostgreSQL para Linux (Ubuntu/Debian/Fedora/RHEL)
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
echo "║  Hub.app DevKit - PostgreSQL Setup (Linux)            ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# Detectar distribuição Linux
# ============================================================================

print_step "1. Detectando distribuição Linux..."

if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
  VERSION=$VERSION_ID
  print_success "Distribuição: $NAME $VERSION"
else
  print_error "Não foi possível detectar a distribuição Linux"
  exit 1
fi

echo ""

# ============================================================================
# Instalar PostgreSQL
# ============================================================================

print_step "2. Instalando PostgreSQL..."

if command -v psql &> /dev/null; then
  CURRENT_VERSION=$(psql --version | awk '{print $3}')
  print_success "PostgreSQL já instalado (versão $CURRENT_VERSION)"
else
  case "$DISTRO" in
    ubuntu|debian|pop|linuxmint)
      print_step "Instalando via apt (Debian/Ubuntu)..."

      # Adicionar repositório oficial PostgreSQL
      sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

      sudo apt update
      sudo apt install -y postgresql-16 postgresql-contrib-16

      # Iniciar serviço
      sudo systemctl start postgresql
      sudo systemctl enable postgresql

      print_success "PostgreSQL 16 instalado via apt!"
      ;;

    fedora|rhel|centos|rocky|almalinux)
      print_step "Instalando via dnf/yum (Fedora/RHEL)..."

      # Adicionar repositório oficial PostgreSQL
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-$(rpm -E %fedora)-x86_64/pgdg-fedora-repo-latest.noarch.rpm 2>/dev/null || \
      sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %rhel)-x86_64/pgdg-redhat-repo-latest.noarch.rpm

      # Desabilitar módulo PostgreSQL builtin (se existir)
      sudo dnf -qy module disable postgresql 2>/dev/null || true

      sudo dnf install -y postgresql16-server postgresql16-contrib

      # Inicializar database cluster
      sudo /usr/pgsql-16/bin/postgresql-16-setup initdb

      # Iniciar serviço
      sudo systemctl start postgresql-16
      sudo systemctl enable postgresql-16

      print_success "PostgreSQL 16 instalado via dnf/yum!"
      ;;

    arch|manjaro)
      print_step "Instalando via pacman (Arch)..."

      sudo pacman -Sy --noconfirm postgresql

      # Inicializar database cluster
      sudo -u postgres initdb -D /var/lib/postgres/data

      # Iniciar serviço
      sudo systemctl start postgresql
      sudo systemctl enable postgresql

      print_success "PostgreSQL instalado via pacman!"
      ;;

    *)
      print_error "Distribuição não suportada: $DISTRO"
      echo ""
      echo "Instale PostgreSQL manualmente:"
      echo "  https://www.postgresql.org/download/linux/"
      exit 1
      ;;
  esac
fi

echo ""

# ============================================================================
# Configurar usuário PostgreSQL
# ============================================================================

print_step "3. Configurando usuário PostgreSQL..."

# Criar usuário com mesmo nome do usuário Linux (sem senha para local)
CURRENT_USER=$(whoami)

sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = '$CURRENT_USER'" | grep -q 1 || \
sudo -u postgres createuser -s "$CURRENT_USER"

print_success "Usuário '$CURRENT_USER' configurado"

echo ""

# ============================================================================
# Criar banco de dados
# ============================================================================

print_step "4. Criando banco de dados..."

DB_NAME="hub_app_dev"

# Verificar se banco já existe
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  print_warning "Banco '$DB_NAME' já existe"
  read -p "Deseja recriar (todos os dados serão perdidos)? (y/n): " RECREATE

  if [[ "$RECREATE" == "y" ]]; then
    print_step "Removendo banco existente..."
    sudo -u postgres dropdb "$DB_NAME"
    sudo -u postgres createdb -O "$CURRENT_USER" "$DB_NAME"
    print_success "Banco recriado!"
  else
    print_warning "Mantendo banco existente"
  fi
else
  sudo -u postgres createdb -O "$CURRENT_USER" "$DB_NAME"
  print_success "Banco '$DB_NAME' criado!"
fi

echo ""

# ============================================================================
# Testar conexão
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
# Criar arquivo .env.local
# ============================================================================

print_step "6. Criando .env.local..."

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DEVKIT_DIR/.env.local"

if [[ -f "$ENV_FILE" ]]; then
  print_warning "Arquivo .env.local já existe"
else
  cat > "$ENV_FILE" << EOF
# PostgreSQL Development Database
DATABASE_URL="postgresql://${CURRENT_USER}:@localhost:5432/${DB_NAME}?schema=public"

# Hub.app Config (opcional)
HUB_APP_PATH="${HOME}/hub-app-nextjs"
EOF

  print_success ".env.local criado!"
fi

echo ""

# ============================================================================
# Aplicar seeds (opcional)
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
echo "  User:         $CURRENT_USER"
echo "  Connection:   postgresql://${CURRENT_USER}:@localhost:5432/${DB_NAME}"
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
echo "  sudo systemctl stop postgresql"
echo ""
echo "Para verificar status:"
echo "  sudo systemctl status postgresql"
echo ""
