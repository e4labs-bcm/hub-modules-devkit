#!/bin/bash

# ============================================================================
# Check Compatibility Script
# Verifica compatibilidade entre Hub.app e DevKit
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
  HUB_APP_PATH="$(cd "$DEVKIT_DIR/../hub-app-nextjs" && pwd 2>/dev/null || echo "")"
fi

if [ -n "$1" ]; then
  HUB_APP_PATH="$1"
fi

# ============================================================================
# Banner
# ============================================================================

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Compatibility Check - Hub.app ↔ DevKit               ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# Verificar se Hub.app está disponível
# ============================================================================

if [ -z "$HUB_APP_PATH" ] || [ ! -d "$HUB_APP_PATH" ]; then
  print_warning "Hub.app não encontrado - apenas verificação local"
  echo ""
  HUB_AVAILABLE=false
else
  print_success "Hub.app encontrado: $HUB_APP_PATH"
  HUB_AVAILABLE=true
fi

echo ""

# ============================================================================
# Ler versões
# ============================================================================

print_step "1. Verificando versões..."

DEVKIT_VERSION=$(grep '"version"' "$DEVKIT_DIR/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
MIN_HUB_VERSION=$(grep '"min_version"' "$DEVKIT_DIR/package.json" | sed 's/.*"min_version": "\(.*\)".*/\1/')
MAX_HUB_VERSION=$(grep '"max_version"' "$DEVKIT_DIR/package.json" | sed 's/.*"max_version": "\(.*\)".*/\1/')
RECOMMENDED_VERSION=$(grep '"recommended_version"' "$DEVKIT_DIR/package.json" | sed 's/.*"recommended_version": "\(.*\)".*/\1/')
LAST_SYNCED=$(grep '"last_synced"' "$DEVKIT_DIR/package.json" | sed 's/.*"last_synced": "\(.*\)".*/\1/')

echo "  DevKit versão:   $DEVKIT_VERSION"
echo "  Hub.app aceito:  $MIN_HUB_VERSION - $MAX_HUB_VERSION"
echo "  Recomendado:     $RECOMMENDED_VERSION"
echo "  Última sync:     $LAST_SYNCED"

if [ "$HUB_AVAILABLE" = true ]; then
  HUB_VERSION=$(grep '"version"' "$HUB_APP_PATH/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
  echo "  Hub.app versão:  $HUB_VERSION"
fi

echo ""

# ============================================================================
# Verificar compatibilidade de versão
# ============================================================================

if [ "$HUB_AVAILABLE" = true ]; then
  print_step "2. Verificando compatibilidade de versão..."

  # Extrair major version
  HUB_MAJOR=$(echo "$HUB_VERSION" | cut -d. -f1)
  MIN_MAJOR=$(echo "$MIN_HUB_VERSION" | cut -d. -f1)
  MAX_MAJOR=$(echo "$MAX_HUB_VERSION" | cut -d. -f1 | sed 's/x/9999/')

  if [ "$HUB_MAJOR" -lt "$MIN_MAJOR" ]; then
    print_error "Hub.app muito antigo! (mínimo: $MIN_HUB_VERSION)"
    echo "  Atualize o Hub.app ou use uma versão mais antiga do DevKit"
    EXIT_CODE=1
  elif [ "$HUB_MAJOR" -gt "$MAX_MAJOR" ] && [ "$MAX_MAJOR" != "9999" ]; then
    print_error "Hub.app muito novo! (máximo: $MAX_HUB_VERSION)"
    echo "  Atualize o DevKit: bash scripts/sync-schema.sh"
    EXIT_CODE=1
  elif [ "$HUB_VERSION" != "$RECOMMENDED_VERSION" ]; then
    print_warning "Versão compatível mas não recomendada"
    echo "  Recomendado: $RECOMMENDED_VERSION"
    echo "  Atual:       $HUB_VERSION"
    echo "  Sugestão: Execute 'npm run sync:all' para sincronizar"
    EXIT_CODE=0
  else
    print_success "Versão perfeitamente compatível!"
    EXIT_CODE=0
  fi

  echo ""
fi

# ============================================================================
# Verificar última sincronização
# ============================================================================

print_step "3. Verificando última sincronização..."

# Calcular dias desde última sync
if [ -n "$LAST_SYNCED" ] && [ "$LAST_SYNCED" != "null" ]; then
  SYNC_DATE=$(date -d "$LAST_SYNCED" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_SYNCED" +%s 2>/dev/null || echo "0")
  CURRENT_DATE=$(date +%s)
  DAYS_SINCE_SYNC=$(( (CURRENT_DATE - SYNC_DATE) / 86400 ))

  if [ "$DAYS_SINCE_SYNC" -gt 30 ]; then
    print_warning "Última sincronização há $DAYS_SINCE_SYNC dias!"
    echo "  Recomendado sincronizar: npm run sync:all"
  elif [ "$DAYS_SINCE_SYNC" -gt 7 ]; then
    print_warning "Última sincronização há $DAYS_SINCE_SYNC dias"
    echo "  Considere sincronizar em breve"
  else
    print_success "Sincronizado recentemente ($DAYS_SINCE_SYNC dias atrás)"
  fi
else
  print_warning "Nenhuma sincronização registrada"
  echo "  Execute: npm run sync:all"
fi

echo ""

# ============================================================================
# Verificar arquivos de referência
# ============================================================================

print_step "4. Verificando arquivos de referência..."

REFERENCE_FILES=(
  "docs/reference/hub-schema.prisma"
)

MISSING_FILES=0

for file in "${REFERENCE_FILES[@]}"; do
  if [ ! -f "$DEVKIT_DIR/$file" ]; then
    print_warning "Arquivo ausente: $file"
    MISSING_FILES=$((MISSING_FILES + 1))
  else
    print_success "$(basename "$file")"
  fi
done

if [ "$MISSING_FILES" -gt 0 ]; then
  echo ""
  print_warning "$MISSING_FILES arquivo(s) de referência ausente(s)"
  echo "  Execute: npm run sync:schema"
fi

echo ""

# ============================================================================
# Resumo e Recomendações
# ============================================================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Resumo da Verificação                                ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

if [ "${EXIT_CODE:-0}" -eq 0 ] && [ "$MISSING_FILES" -eq 0 ]; then
  print_success "DevKit compatível e atualizado!"
  echo ""
  echo "✅ Tudo certo para criar módulos"
else
  print_warning "Ações recomendadas:"
  echo ""
  if [ "${EXIT_CODE:-0}" -ne 0 ]; then
    echo "  1. Resolver incompatibilidade de versão"
  fi
  if [ "$MISSING_FILES" -gt 0 ]; then
    echo "  2. Sincronizar arquivos: npm run sync:all"
  fi
  if [ "$DAYS_SINCE_SYNC" -gt 7 ] 2>/dev/null; then
    echo "  3. Sincronizar regularmente (recomendado semanal)"
  fi
fi

echo ""

exit ${EXIT_CODE:-0}
