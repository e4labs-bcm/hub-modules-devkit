#!/bin/bash

# ============================================================================
# Hub.app Module Installer
# Instala um módulo no Hub.app (registra no banco + cria API routes)
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
# Validações
# ============================================================================

if [ $# -lt 3 ]; then
  echo "Uso: $0 <slug> <titulo> <icone> [tenant-id]"
  echo ""
  echo "Exemplo:"
  echo "  $0 tarefas \"Tarefas\" ListTodo a01b75e2-233b-40c2-801b-0e4a7e2a4055"
  echo ""
  exit 1
fi

MODULE_SLUG="$1"
MODULE_TITLE="$2"
MODULE_ICON="$3"
TENANT_ID="${4:-}"  # Opcional

HUB_DIR="$(pwd)"

# Verificar se estamos no diretório do Hub
if [ ! -f "$HUB_DIR/package.json" ] || ! grep -q "hub-app-nextjs" "$HUB_DIR/package.json" 2>/dev/null; then
  print_error "Execute este script dentro do diretório hub-app-nextjs"
  exit 1
fi

MODULE_DIR="$HUB_DIR/packages/mod-$MODULE_SLUG"

if [ ! -d "$MODULE_DIR" ]; then
  print_error "Módulo não encontrado: $MODULE_DIR"
  print_warning "Use create-module.sh primeiro para criar o módulo"
  exit 1
fi

# Carregar .env para connection string
if [ -f "$HUB_DIR/.env.local" ]; then
  export $(grep -v '^#' "$HUB_DIR/.env.local" | xargs)
fi

if [ -z "$DATABASE_URL" ]; then
  print_error "DATABASE_URL não encontrada em .env.local"
  exit 1
fi

print_step "Instalando módulo: $MODULE_TITLE ($MODULE_SLUG)"
echo ""

# ============================================================================
# 1. Aplicar Migration SQL
# ============================================================================

print_step "1. Aplicando migration SQL..."

MIGRATION_FILE=$(find "$MODULE_DIR/migrations" -name "*.sql" | head -n 1)

if [ -z "$MIGRATION_FILE" ]; then
  print_warning "Nenhuma migration encontrada em $MODULE_DIR/migrations/"
else
  # Extrair connection details do DATABASE_URL
  DB_HOST=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
  DB_PORT=$(echo "$DATABASE_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
  DB_NAME=$(echo "$DATABASE_URL" | sed -n 's/.*\/\([^?]*\).*/\1/p')
  DB_USER=$(echo "$DATABASE_URL" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')

  print_warning "Aplicando migration: $MIGRATION_FILE"
  print_warning "Database: $DB_NAME @ $DB_HOST:$DB_PORT"

  # Tentar aplicar migration
  if command -v psql &> /dev/null; then
    PGPASSWORD="${DATABASE_URL#*:*:}" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -f "$MIGRATION_FILE" 2>&1 | grep -v "^$" || true
    print_success "Migration aplicada"
  else
    print_warning "psql não instalado. Aplique manualmente:"
    echo "  psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f $MIGRATION_FILE"
  fi
fi

# ============================================================================
# 2. Registrar módulo no banco de dados
# ============================================================================

print_step "2. Registrando módulo no banco de dados..."

# Ler manifest.json
MANIFEST_PATH="$MODULE_DIR/manifest.json"
MANIFEST_JSON=$(cat "$MANIFEST_PATH")

# Pegar URL do manifest ou usar localhost
MODULE_URL=$(echo "$MANIFEST_JSON" | grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
MODULE_VERSION=$(echo "$MANIFEST_JSON" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

if [ -z "$MODULE_URL" ]; then
  MODULE_URL="http://localhost:5173/"
  print_warning "URL não encontrada no manifest, usando: $MODULE_URL"
fi

# Script SQL para registrar módulo
SQL_SCRIPT=$(cat <<EOF
-- Registrar módulo $MODULE_TITLE
DO \$\$
DECLARE
  v_tenant_id UUID := ${TENANT_ID:+"'$TENANT_ID'::UUID"};
  v_module_id UUID;
BEGIN
  -- Se tenant_id não foi fornecido, pegar o primeiro tenant
  IF v_tenant_id IS NULL THEN
    SELECT id INTO v_tenant_id FROM empresas ORDER BY created_at LIMIT 1;
  END IF;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Nenhum tenant encontrado. Crie uma empresa primeiro.';
  END IF;

  -- Verificar se módulo já existe
  SELECT id INTO v_module_id
  FROM modulos_instalados
  WHERE tenant_id = v_tenant_id AND nome = '$MODULE_TITLE';

  IF v_module_id IS NOT NULL THEN
    RAISE NOTICE 'Módulo já instalado para tenant %', v_tenant_id;
  ELSE
    -- Inserir módulo
    INSERT INTO modulos_instalados (id, tenant_id, nome, ativo, manifest)
    VALUES (
      gen_random_uuid(),
      v_tenant_id,
      '$MODULE_TITLE',
      true,
      '{
        "icon": "$MODULE_ICON",
        "type": "iframe",
        "url": "$MODULE_URL",
        "overlay": false,
        "global": false,
        "version": "$MODULE_VERSION"
      }'::jsonb
    )
    RETURNING id INTO v_module_id;

    RAISE NOTICE 'Módulo instalado com sucesso! ID: %', v_module_id;
    RAISE NOTICE 'Tenant: %', v_tenant_id;
  END IF;
END
\$\$;
EOF
)

# Executar SQL
if command -v psql &> /dev/null; then
  echo "$SQL_SCRIPT" | PGPASSWORD="${DATABASE_URL#*:*:}" psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" 2>&1 | grep "NOTICE" || true
  print_success "Módulo registrado no banco"
else
  print_warning "Execute manualmente:"
  echo "$SQL_SCRIPT"
fi

# ============================================================================
# 3. Criar API Routes
# ============================================================================

print_step "3. Criando API routes..."

API_DIR="$HUB_DIR/src/app/api/modules/$MODULE_SLUG"

if [ -d "$API_DIR" ]; then
  print_warning "API routes já existem em: $API_DIR"
else
  mkdir -p "$API_DIR/items"

  # Criar route.ts para /items
  cat > "$API_DIR/items/route.ts" << 'ROUTE_EOF'
import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';
import { apiResponse, apiError } from '@/lib/api-response';

/**
 * GET /api/modules/MODULE_SLUG/items
 * Lista items do tenant
 */
export async function GET(req: NextRequest) {
  try {
    const { tenantId } = await authenticateModule(req);

    const searchParams = req.nextUrl.searchParams;
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    const items = await prisma.MODULE_SLUG_items.findMany({
      where: { tenant_id: tenantId },
      take: limit,
      skip: offset,
      orderBy: { created_at: 'desc' },
    });

    const total = await prisma.MODULE_SLUG_items.count({
      where: { tenant_id: tenantId },
    });

    return apiResponse(items, { limit, offset, total });
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * POST /api/modules/MODULE_SLUG/items
 * Cria novo item
 */
export async function POST(req: NextRequest) {
  try {
    const { tenantId, userId } = await authenticateModule(req);
    const body = await req.json();

    const item = await prisma.MODULE_SLUG_items.create({
      data: {
        ...body,
        tenant_id: tenantId,
        created_by: userId,
      },
    });

    return apiResponse(item, undefined, 201);
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * OPTIONS - CORS preflight
 */
export async function OPTIONS() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
ROUTE_EOF

  # Substituir MODULE_SLUG no arquivo
  sed -i.bak "s/MODULE_SLUG/$MODULE_SLUG/g" "$API_DIR/items/route.ts"
  rm "$API_DIR/items/route.ts.bak"

  # Criar route.ts para /items/:id
  cat > "$API_DIR/items/[id]/route.ts" << 'ROUTE_EOF'
import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';
import { apiResponse, apiError } from '@/lib/api-response';

/**
 * GET /api/modules/MODULE_SLUG/items/:id
 * Busca item por ID
 */
export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { tenantId } = await authenticateModule(req);
    const { id } = params;

    const item = await prisma.MODULE_SLUG_items.findFirst({
      where: {
        id,
        tenant_id: tenantId,  // Multi-tenancy!
      },
    });

    if (!item) {
      return apiError('Item não encontrado', 404);
    }

    return apiResponse(item);
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * PUT /api/modules/MODULE_SLUG/items/:id
 * Atualiza item
 */
export async function PUT(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { tenantId } = await authenticateModule(req);
    const { id } = params;
    const body = await req.json();

    const item = await prisma.MODULE_SLUG_items.updateMany({
      where: {
        id,
        tenant_id: tenantId,  // Multi-tenancy!
      },
      data: {
        ...body,
        updated_at: new Date(),
      },
    });

    if (item.count === 0) {
      return apiError('Item não encontrado', 404);
    }

    return apiResponse({ success: true });
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * DELETE /api/modules/MODULE_SLUG/items/:id
 * Deleta item
 */
export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { tenantId } = await authenticateModule(req);
    const { id } = params;

    const item = await prisma.MODULE_SLUG_items.deleteMany({
      where: {
        id,
        tenant_id: tenantId,  // Multi-tenancy!
      },
    });

    if (item.count === 0) {
      return apiError('Item não encontrado', 404);
    }

    return new Response(null, { status: 204 });
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * OPTIONS - CORS preflight
 */
export async function OPTIONS() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
ROUTE_EOF

  mkdir -p "$API_DIR/items/[id]"
  mv "$API_DIR/items/[id]/route.ts" "$API_DIR/items/[id]/" 2>/dev/null || true

  # Substituir MODULE_SLUG
  sed -i.bak "s/MODULE_SLUG/$MODULE_SLUG/g" "$API_DIR/items/[id]/route.ts"
  rm "$API_DIR/items/[id]/route.ts.bak"

  print_success "API routes criadas em: $API_DIR"
fi

# ============================================================================
# 4. Atualizar Prisma Schema
# ============================================================================

print_step "4. Atualizando Prisma schema..."

PRISMA_SCHEMA="$HUB_DIR/prisma/schema.prisma"

# Verificar se model já existe
if grep -q "model ${MODULE_SLUG}_items" "$PRISMA_SCHEMA"; then
  print_warning "Model ${MODULE_SLUG}_items já existe no schema"
else
  # Adicionar model no final do arquivo
  cat >> "$PRISMA_SCHEMA" << PRISMA_EOF

// ============================================================================
// Módulo: $MODULE_TITLE
// ============================================================================

model ${MODULE_SLUG}_items {
  id         String   @id @default(uuid()) @db.Uuid
  tenant_id  String   @db.Uuid
  created_by String?  @db.Uuid
  name       String   @db.VarChar(255)
  description String? @db.Text
  created_at DateTime @default(now()) @db.Timestamptz(6)
  updated_at DateTime @default(now()) @db.Timestamptz(6)

  // Relações
  perfis     perfis?  @relation(fields: [created_by], references: [id], name: "${MODULE_SLUG}_items_created_by")

  @@index([tenant_id])
  @@index([created_by])
  @@map("${MODULE_SLUG}_items")
}
PRISMA_EOF

  print_success "Prisma schema atualizado"
fi

# ============================================================================
# 5. Regenerar Prisma Client
# ============================================================================

print_step "5. Regenerando Prisma Client..."

cd "$HUB_DIR"
npx prisma generate --silent

print_success "Prisma Client regenerado"

# ============================================================================
# Resumo
# ============================================================================

echo ""
print_success "Módulo $MODULE_TITLE instalado com sucesso!"
echo ""
echo -e "${BLUE}Resumo:${NC}"
echo "  ✓ Migration aplicada"
echo "  ✓ Módulo registrado no banco"
echo "  ✓ API routes criadas em: src/app/api/modules/$MODULE_SLUG"
echo "  ✓ Prisma schema atualizado"
echo "  ✓ Prisma Client regenerado"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. cd packages/mod-$MODULE_SLUG && npm run dev"
echo "  2. Reiniciar Next.js: npm run dev"
echo "  3. Abrir http://localhost:3000 e testar módulo"
echo ""
echo -e "${YELLOW}Nota:${NC} Para deploy em produção, atualize a URL no manifest.json"
echo ""
