#!/bin/bash

# ============================================================================
# Hub.app Module Creator
# Cria um novo módulo a partir do template DevKit
# ============================================================================

set -e  # Exit on error

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para printar com cor
print_step() {
  echo -e "${BLUE}==>${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

# ============================================================================
# Validações e Inputs
# ============================================================================

if [ $# -lt 2 ]; then
  echo "Uso: $0 <nome-modulo> <\"Título do Módulo\"> [icone]"
  echo ""
  echo "Exemplos:"
  echo "  $0 tarefas \"Tarefas\" ListTodo"
  echo "  $0 inventario \"Inventário\" Package"
  echo "  $0 crm \"CRM\" Users"
  echo ""
  echo "Ícones disponíveis: https://lucide.dev/icons"
  exit 1
fi

MODULE_SLUG="$1"         # Ex: tarefas
MODULE_TITLE="$2"        # Ex: "Tarefas"
MODULE_ICON="${3:-Package}"  # Ex: ListTodo (default: Package)

# Sanitizar slug para SQL (hífens → underscores)
# PostgreSQL não aceita hífens em nomes de tabelas
MODULE_SLUG_SQL=$(echo "$MODULE_SLUG" | tr '-' '_')  # Ex: teste-template → teste_template

# Validar nome do módulo (apenas lowercase, números e hífens)
if [[ ! "$MODULE_SLUG" =~ ^[a-z0-9-]+$ ]]; then
  print_error "Nome do módulo inválido. Use apenas letras minúsculas, números e hífens."
  exit 1
fi

# Detectar diretório do Hub.app
DEVKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HUB_DIR="${HUB_ROOT:-$HOME/Documents/Claude/hub-app-nextjs}"

if [ ! -d "$HUB_DIR" ]; then
  print_warning "Diretório do Hub não encontrado: $HUB_DIR"
  read -p "Digite o caminho completo do hub-app-nextjs: " HUB_DIR
fi

if [ ! -d "$HUB_DIR" ]; then
  print_error "Diretório do Hub inválido: $HUB_DIR"
  exit 1
fi

MODULE_DIR="$HUB_DIR/packages/mod-$MODULE_SLUG"

# Verificar se módulo já existe
if [ -d "$MODULE_DIR" ]; then
  print_error "Módulo já existe: $MODULE_DIR"
  exit 1
fi

print_step "Criando módulo: $MODULE_TITLE ($MODULE_SLUG)"
echo ""

# ============================================================================
# Criar estrutura do módulo
# ============================================================================

print_step "1. Criando estrutura de diretórios..."

mkdir -p "$MODULE_DIR"/{adapter,app/src/{components,types,utils},migrations,docs}

print_success "Diretórios criados"

# ============================================================================
# Copiar templates e substituir placeholders
# ============================================================================

print_step "2. Copiando templates..."

# Função para copiar e substituir
copy_and_replace() {
  local src="$1"
  local dst="$2"

  cat "$src" | \
    sed "s/MODULE_NAME/$MODULE_SLUG/g" | \
    sed "s/MODULE_TITLE/$MODULE_TITLE/g" | \
    sed "s/MODULE_ICON/$MODULE_ICON/g" \
    > "$dst"
}

# Copiar templates
copy_and_replace "$DEVKIT_DIR/template/hubContext.ts" "$MODULE_DIR/app/src/hubContext.ts"
copy_and_replace "$DEVKIT_DIR/template/apiAdapter.ts" "$MODULE_DIR/adapter/apiAdapter.ts"
copy_and_replace "$DEVKIT_DIR/template/manifest.json" "$MODULE_DIR/manifest.json"
copy_and_replace "$DEVKIT_DIR/template/package.json" "$MODULE_DIR/package.json"

# Ajustar package.json com nome correto
sed -i.bak "s/@hubapp\/mod-MODULE_NAME/@hubapp\/mod-$MODULE_SLUG/g" "$MODULE_DIR/package.json"
rm "$MODULE_DIR/package.json.bak"

print_success "Templates copiados e configurados"

# ============================================================================
# Criar arquivos básicos
# ============================================================================

print_step "3. Criando arquivos básicos..."

# main.tsx
cat > "$MODULE_DIR/app/src/main.tsx" << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { registerHubContextListener } from './hubContext';

// Registrar listener para receber configuração do Hub
registerHubContextListener();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# App.tsx
cat > "$MODULE_DIR/app/src/App.tsx" << EOF
import { useEffect, useState } from 'react';
import { Toaster } from 'sonner';
import { getHubContext } from './hubContext';

function App() {
  const [context, setContext] = useState(getHubContext());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Aguardar configuração do Hub
    const timeout = setTimeout(() => {
      const ctx = getHubContext();
      if (ctx) {
        setContext(ctx);
        setLoading(false);
      }
    }, 1000);

    return () => clearTimeout(timeout);
  }, []);

  if (loading || !context) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600">Carregando módulo...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Toaster position="top-right" />

      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <h1 className="text-2xl font-bold text-gray-900">$MODULE_TITLE</h1>
          <p className="text-sm text-gray-500">Tenant: {context.tenantId}</p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-medium mb-4">Bem-vindo ao $MODULE_TITLE!</h2>
          <p className="text-gray-600">
            Seu módulo foi criado com sucesso. Agora você pode começar a desenvolver.
          </p>

          <div className="mt-4 p-4 bg-blue-50 rounded">
            <h3 className="font-medium text-blue-900">Próximos passos:</h3>
            <ol className="mt-2 space-y-1 text-sm text-blue-800">
              <li>1. Edite este componente (app/src/App.tsx)</li>
              <li>2. Crie suas API routes no Hub (/api/modules/$MODULE_SLUG)</li>
              <li>3. Adicione suas tabelas no Prisma schema</li>
              <li>4. Teste com: npm run dev</li>
            </ol>
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;
EOF

# index.css
cat > "$MODULE_DIR/app/src/index.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
  }
}
EOF

# index.html
cat > "$MODULE_DIR/app/index.html" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$MODULE_TITLE - Hub.app</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# vite.config.ts
cat > "$MODULE_DIR/app/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    host: true,
  },
  build: {
    outDir: '../dist',
    emptyOutDir: true,
  },
});
EOF

# tailwind.config.js
cat > "$MODULE_DIR/app/tailwind.config.js" << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# tsconfig.json
cat > "$MODULE_DIR/app/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# types/index.ts
cat > "$MODULE_DIR/app/src/types/index.ts" << 'EOF'
/**
 * Tipos TypeScript para o módulo
 */

export type Item = {
  id: string;
  tenant_id: string;
  created_by?: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
};

// Adicione mais tipos conforme necessário
EOF

print_success "Arquivos básicos criados"

# ============================================================================
# Criar migration SQL de exemplo
# ============================================================================

print_step "4. Criando migration SQL de exemplo..."

cat > "$MODULE_DIR/migrations/$(date +%Y%m%d)_${MODULE_SLUG}.sql" << EOF
-- Migration para módulo $MODULE_TITLE
-- Data: $(date +%Y-%m-%d)

-- Tabela principal
CREATE TABLE IF NOT EXISTS ${MODULE_SLUG_SQL}_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  created_by UUID,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_${MODULE_SLUG_SQL}_items_tenant
  ON ${MODULE_SLUG_SQL}_items(tenant_id);

CREATE INDEX IF NOT EXISTS idx_${MODULE_SLUG_SQL}_items_created_by
  ON ${MODULE_SLUG_SQL}_items(created_by);

-- Trigger para real-time (opcional)
CREATE OR REPLACE FUNCTION notify_${MODULE_SLUG_SQL}_change()
RETURNS TRIGGER AS \$\$
BEGIN
  PERFORM pg_notify(
    '${MODULE_SLUG}_changes',
    json_build_object(
      'operation', TG_OP,
      'record', row_to_json(NEW),
      'tenant_id', NEW.tenant_id
    )::text
  );
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER ${MODULE_SLUG_SQL}_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON ${MODULE_SLUG_SQL}_items
  FOR EACH ROW EXECUTE FUNCTION notify_${MODULE_SLUG_SQL}_change();

-- RLS (Row Level Security) - Opcional
-- ALTER TABLE ${MODULE_SLUG_SQL}_items ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY ${MODULE_SLUG_SQL}_tenant_isolation ON ${MODULE_SLUG_SQL}_items
--   USING (tenant_id = current_setting('app.current_tenant')::uuid);

COMMENT ON TABLE ${MODULE_SLUG_SQL}_items IS 'Tabela principal do módulo $MODULE_TITLE';
EOF

print_success "Migration SQL criada"

# ============================================================================
# Criar README do módulo
# ============================================================================

print_step "5. Criando documentação..."

cat > "$MODULE_DIR/README.md" << EOF
# $MODULE_TITLE

Módulo do Hub.app criado com DevKit.

## Estrutura

\`\`\`
mod-$MODULE_SLUG/
├── adapter/
│   └── apiAdapter.ts          # Cliente API
├── app/
│   ├── src/
│   │   ├── App.tsx            # Componente principal
│   │   ├── main.tsx           # Entry point
│   │   ├── hubContext.ts      # Integração Hub
│   │   ├── components/        # Componentes React
│   │   ├── types/             # TypeScript types
│   │   └── utils/             # Utilitários
│   ├── vite.config.ts
│   └── index.html
├── migrations/
│   └── YYYYMMDD_${MODULE_SLUG}.sql
├── manifest.json              # Metadados do módulo
└── package.json
\`\`\`

## Desenvolvimento

\`\`\`bash
# Instalar dependências
npm install

# Dev server
npm run dev  # http://localhost:5173

# Build
npm run build

# Preview
npm run preview
\`\`\`

## Instalação no Hub.app

1. **Aplicar migration:**
   \`\`\`bash
   psql -U hub_app_user -h HOST -p PORT -d hub_app_staging \\
     -f migrations/$(date +%Y%m%d)_${MODULE_SLUG}.sql
   \`\`\`

2. **Registrar módulo no banco:**
   \`\`\`bash
   cd $HUB_DIR
   npm run module:install -- $MODULE_SLUG "$MODULE_TITLE" $MODULE_ICON
   \`\`\`

3. **Criar API routes:**
   \`\`\`bash
   mkdir -p src/app/api/modules/$MODULE_SLUG
   # Copiar template de route.ts
   \`\`\`

4. **Atualizar Prisma schema:**
   \`\`\`prisma
   model ${MODULE_SLUG}_items {
     id         String   @id @default(uuid()) @db.Uuid
     tenant_id  String   @db.Uuid
     created_by String?  @db.Uuid
     name       String   @db.VarChar(255)
     description String? @db.Text
     created_at DateTime @default(now()) @db.Timestamptz(6)
     updated_at DateTime @default(now()) @db.Timestamptz(6)

     @@index([tenant_id])
     @@map("${MODULE_SLUG}_items")
   }
   \`\`\`

5. **Regenerar Prisma Client:**
   \`\`\`bash
   npx prisma generate
   \`\`\`

## Próximos Passos

- [ ] Implementar componentes React
- [ ] Criar API routes no Hub
- [ ] Adicionar testes
- [ ] Documentar funcionalidades
- [ ] Deploy em produção

## Referências

- [Hub.app DevKit](../../../hub-modules-devkit)
- [Documentação completa](../../../hub-modules-devkit/docs)
EOF

print_success "README criado"

# ============================================================================
# Instalar dependências
# ============================================================================

print_step "6. Instalando dependências..."

cd "$MODULE_DIR"
npm install --silent

print_success "Dependências instaladas"

# ============================================================================
# Resumo
# ============================================================================

echo ""
print_success "Módulo $MODULE_TITLE criado com sucesso!"
echo ""
echo -e "${BLUE}Localização:${NC} $MODULE_DIR"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. cd packages/mod-$MODULE_SLUG"
echo "  2. npm run dev"
echo "  3. Abrir http://localhost:5173"
echo ""
echo -e "${BLUE}Para instalar no Hub.app:${NC}"
echo "  1. Aplicar migration: psql ... -f migrations/*.sql"
echo "  2. Registrar módulo: npm run module:install $MODULE_SLUG"
echo "  3. Criar API routes: mkdir -p src/app/api/modules/$MODULE_SLUG"
echo ""
echo -e "${YELLOW}Documentação completa:${NC} $MODULE_DIR/README.md"
echo ""
