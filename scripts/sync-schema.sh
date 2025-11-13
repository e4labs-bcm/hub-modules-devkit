#!/bin/bash

# ============================================================================
# Sync Schema Script
# Sincroniza schema do Hub.app para o DevKit
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
# Configuração
# ============================================================================

DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Tentar detectar Hub.app automaticamente
if [ -z "$HUB_APP_PATH" ]; then
  # Assumir que Hub está no mesmo nível do DevKit
  HUB_APP_PATH="$(cd "$DEVKIT_DIR/../hub-app-nextjs" && pwd 2>/dev/null || echo "")"
fi

if [ -z "$HUB_APP_PATH" ] || [ ! -d "$HUB_APP_PATH" ]; then
  print_error "Caminho do Hub.app não encontrado!"
  echo ""
  echo "Opções:"
  echo "  1. Definir variável de ambiente:"
  echo "     export HUB_APP_PATH='/path/to/hub-app-nextjs'"
  echo ""
  echo "  2. Passar como argumento:"
  echo "     bash scripts/sync-schema.sh /path/to/hub-app-nextjs"
  echo ""
  exit 1
fi

# Se passado como argumento, usar ele
if [ -n "$1" ]; then
  HUB_APP_PATH="$1"
fi

if [ ! -d "$HUB_APP_PATH" ]; then
  print_error "Diretório do Hub.app inválido: $HUB_APP_PATH"
  exit 1
fi

# ============================================================================
# Banner
# ============================================================================

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Sync Schema - Hub.app → DevKit                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Hub.app:  $HUB_APP_PATH"
echo "DevKit:   $DEVKIT_DIR"
echo ""

# ============================================================================
# Verificar versões
# ============================================================================

print_step "1. Verificando compatibilidade de versões..."

HUB_VERSION=$(grep '"version"' "$HUB_APP_PATH/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
DEVKIT_VERSION=$(grep '"version"' "$DEVKIT_DIR/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')

echo "  Hub.app versão:  $HUB_VERSION"
echo "  DevKit versão:   $DEVKIT_VERSION"

# Avisar se versões diferentes (não bloquear)
if [ "$HUB_VERSION" != "$DEVKIT_VERSION" ]; then
  print_warning "Versões diferentes - recomendado atualizar DevKit para $HUB_VERSION"
else
  print_success "Versões compatíveis"
fi

echo ""

# ============================================================================
# Sincronizar Prisma Schema
# ============================================================================

print_step "2. Sincronizando Prisma schema..."

if [ ! -f "$HUB_APP_PATH/prisma/schema.prisma" ]; then
  print_error "Prisma schema não encontrado no Hub.app"
  exit 1
fi

# Criar diretório docs/reference se não existir
mkdir -p "$DEVKIT_DIR/docs/reference"

# Copiar schema para docs/reference (referência)
cp "$HUB_APP_PATH/prisma/schema.prisma" "$DEVKIT_DIR/docs/reference/hub-schema.prisma"

# Adicionar header com metadata
cat > "$DEVKIT_DIR/docs/reference/hub-schema.prisma.tmp" << EOF
// ============================================================================
// Hub.app Prisma Schema (Reference)
// Sincronizado em: $(date '+%Y-%m-%d %H:%M:%S')
// Hub.app versão: $HUB_VERSION
// ============================================================================
//
// ATENÇÃO: Este arquivo é uma REFERÊNCIA do schema do Hub.app.
// NÃO modifique diretamente - ele será sobrescrito na próxima sincronização.
//
// Para adicionar tabelas do seu módulo, use migrations no diretório migrations/
//
// ============================================================================

EOF

cat "$DEVKIT_DIR/docs/reference/hub-schema.prisma" >> "$DEVKIT_DIR/docs/reference/hub-schema.prisma.tmp"
mv "$DEVKIT_DIR/docs/reference/hub-schema.prisma.tmp" "$DEVKIT_DIR/docs/reference/hub-schema.prisma"

print_success "Prisma schema sincronizado ($(wc -l < "$DEVKIT_DIR/docs/reference/hub-schema.prisma") linhas)"

# ============================================================================
# Sincronizar Templates Base
# ============================================================================

print_step "3. Verificando templates base..."

TEMPLATES_TO_CHECK=(
  "hubContext.ts"
  "apiAdapter.ts"
  "manifest.json"
)

OUTDATED_TEMPLATES=()

for template in "${TEMPLATES_TO_CHECK[@]}"; do
  HUB_FILE="$HUB_APP_PATH/packages/mod-financeiro/app/src/$template"
  DEVKIT_FILE="$DEVKIT_DIR/template/$template"

  # Se arquivo não existe no Hub, pular
  if [ ! -f "$HUB_FILE" ]; then
    continue
  fi

  # Se arquivo não existe no DevKit, marcar como desatualizado
  if [ ! -f "$DEVKIT_FILE" ]; then
    OUTDATED_TEMPLATES+=("$template")
    continue
  fi

  # Comparar checksums (ignorar comentários de data)
  HUB_MD5=$(grep -v "Sincronizado em:" "$HUB_FILE" 2>/dev/null | md5 -q 2>/dev/null || md5sum "$HUB_FILE" 2>/dev/null | awk '{print $1}')
  DEVKIT_MD5=$(grep -v "Sincronizado em:" "$DEVKIT_FILE" 2>/dev/null | md5 -q 2>/dev/null || md5sum "$DEVKIT_FILE" 2>/dev/null | awk '{print $1}')

  if [ "$HUB_MD5" != "$DEVKIT_MD5" ]; then
    OUTDATED_TEMPLATES+=("$template")
  fi
done

if [ ${#OUTDATED_TEMPLATES[@]} -eq 0 ]; then
  print_success "Todos os templates estão atualizados"
else
  print_warning "${#OUTDATED_TEMPLATES[@]} template(s) desatualizado(s): ${OUTDATED_TEMPLATES[*]}"
  echo "  Execute: bash scripts/sync-templates.sh"
fi

echo ""

# ============================================================================
# Atualizar metadata do DevKit
# ============================================================================

print_step "4. Atualizando metadata do DevKit..."

# Atualizar last_synced no package.json
SYNC_DATE=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# macOS usa sed -i '' (BSD sed)
# Linux usa sed -i (GNU sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/\"last_synced\": \".*\"/\"last_synced\": \"$SYNC_DATE\"/" "$DEVKIT_DIR/package.json"
else
  sed -i "s/\"last_synced\": \".*\"/\"last_synced\": \"$SYNC_DATE\"/" "$DEVKIT_DIR/package.json"
fi

print_success "Metadata atualizada (last_synced: $SYNC_DATE)"

echo ""

# ============================================================================
# Finalização
# ============================================================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✓ Sincronização concluída com sucesso!              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Arquivos sincronizados:"
echo "  • Prisma schema (docs/reference/hub-schema.prisma)"
echo "  • Metadata atualizada (package.json)"
echo ""
echo "Próximos passos:"
echo "  • Verificar templates: bash scripts/sync-templates.sh"
echo "  • Verificar compatibilidade: npm run check:compat"
echo ""
