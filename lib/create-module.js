#!/usr/bin/env node

/**
 * Hub.app Module Creator (Node.js version)
 * Cria um novo módulo a partir do template DevKit
 * Cross-platform: Windows, macOS, Linux
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const chalk = require('chalk');

// ============================================================================
// Funções de Output com Cores
// ============================================================================

const print = {
  step: (msg) => console.log(chalk.blue('==>'), msg),
  success: (msg) => console.log(chalk.green('✓'), msg),
  error: (msg) => console.log(chalk.red('✗'), msg),
  warning: (msg) => console.log(chalk.yellow('!'), msg),
};

// ============================================================================
// Validações e Inputs
// ============================================================================

function validateArgs(args) {
  if (args.length < 2) {
    console.log('Uso: create-module <nome-modulo> <"Título do Módulo"> [icone]');
    console.log('');
    console.log('Exemplos:');
    console.log('  create-module tarefas "Tarefas" ListTodo');
    console.log('  create-module inventario "Inventário" Package');
    console.log('  create-module crm "CRM" Users');
    console.log('');
    console.log('Ícones disponíveis: https://lucide.dev/icons');
    process.exit(1);
  }

  const moduleSlug = args[0];
  const moduleTitle = args[1];
  const moduleIcon = args[2] || 'Package';

  // Validar nome do módulo (apenas lowercase, números e hífens)
  if (!/^[a-z0-9-]+$/.test(moduleSlug)) {
    print.error('Nome do módulo inválido. Use apenas letras minúsculas, números e hífens.');
    process.exit(1);
  }

  return { moduleSlug, moduleTitle, moduleIcon };
}

// ============================================================================
// Funções Auxiliares
// ============================================================================

/**
 * Substitui placeholders no conteúdo de um arquivo
 */
function replacePlaceholders(content, replacements) {
  let result = content;
  for (const [key, value] of Object.entries(replacements)) {
    result = result.replace(new RegExp(key, 'g'), value);
  }
  return result;
}

/**
 * Copia arquivo e substitui placeholders
 */
function copyAndReplace(srcPath, dstPath, replacements) {
  const content = fs.readFileSync(srcPath, 'utf8');
  const replaced = replacePlaceholders(content, replacements);
  fs.writeFileSync(dstPath, replaced, 'utf8');
}

/**
 * Cria diretório recursivamente se não existir
 */
function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

/**
 * Detecta diretório do Hub.app
 */
function detectHubDir() {
  const defaultPath = path.join(process.env.HOME || process.env.USERPROFILE, 'Documents', 'Claude', 'hub-app-nextjs');

  if (fs.existsSync(defaultPath)) {
    return defaultPath;
  }

  print.warning(`Diretório do Hub não encontrado: ${defaultPath}`);
  print.error('Configure a variável de ambiente HUB_ROOT ou ajuste o caminho padrão');
  process.exit(1);
}

// ============================================================================
// Função Principal
// ============================================================================

async function createModule(args) {
  const { moduleSlug, moduleTitle, moduleIcon } = validateArgs(args);

  // Sanitizar slug para SQL (hífens → underscores)
  const moduleSlugSql = moduleSlug.replace(/-/g, '_');

  // Detectar diretórios
  const devkitDir = path.resolve(__dirname, '..');
  const hubDir = process.env.HUB_ROOT || detectHubDir();
  const moduleDir = path.join(hubDir, 'packages', `mod-${moduleSlug}`);

  // Verificar se módulo já existe
  if (fs.existsSync(moduleDir)) {
    print.error(`Módulo já existe: ${moduleDir}`);
    process.exit(1);
  }

  print.step(`Criando módulo: ${moduleTitle} (${moduleSlug})`);
  console.log('');

  // Objeto com todas as substituições
  const replacements = {
    MODULE_NAME: moduleSlug,
    MODULE_SLUG: moduleSlug,
    MODULE_SLUG_SQL: moduleSlugSql,
    MODULE_TITLE: moduleTitle,
    MODULE_ICON: moduleIcon,
  };

  // ============================================================================
  // 1. Criar estrutura de diretórios
  // ============================================================================

  print.step('1. Criando estrutura de diretórios...');

  const dirs = [
    moduleDir,
    path.join(moduleDir, 'adapter'),
    path.join(moduleDir, 'app', 'src', 'components'),
    path.join(moduleDir, 'app', 'src', 'types'),
    path.join(moduleDir, 'app', 'src', 'hooks'),
    path.join(moduleDir, 'app', 'src', 'utils'),
    path.join(moduleDir, 'migrations'),
    path.join(moduleDir, 'docs'),
  ];

  dirs.forEach(ensureDir);
  print.success('Diretórios criados');

  // ============================================================================
  // 2. Copiar templates
  // ============================================================================

  print.step('2. Copiando templates...');

  // Templates básicos
  const basicTemplates = [
    ['template/hubContext.ts', 'app/src/hubContext.ts'],
    ['template/apiAdapter.ts', 'adapter/apiAdapter.ts'],
    ['template/manifest.json', 'manifest.json'],
    ['template/package.json', 'package.json'],
  ];

  basicTemplates.forEach(([src, dst]) => {
    copyAndReplace(
      path.join(devkitDir, src),
      path.join(moduleDir, dst),
      replacements
    );
  });

  // Templates funcionais (CRUD completo)
  const functionalTemplates = [
    ['templates/types/index.ts', 'app/src/types/index.ts'],
    ['templates/hooks/useItems.ts', 'app/src/hooks/useItems.ts'],
    ['templates/components/ItemList.tsx', 'app/src/components/ItemList.tsx'],
    ['templates/components/ItemForm.tsx', 'app/src/components/ItemForm.tsx'],
    ['templates/App.tsx', 'app/src/App.tsx'],
  ];

  functionalTemplates.forEach(([src, dst]) => {
    copyAndReplace(
      path.join(devkitDir, src),
      path.join(moduleDir, dst),
      replacements
    );
  });

  print.success('Templates copiados e configurados');

  // ============================================================================
  // 3. Criar arquivos básicos
  // ============================================================================

  print.step('3. Criando arquivos básicos...');

  // main.tsx
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'src', 'main.tsx'),
    `import React from 'react';
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
`
  );

  // index.css
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'src', 'index.css'),
    `@tailwind base;
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
`
  );

  // index.html
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'index.html'),
    `<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${moduleTitle} - Hub.app</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
`
  );

  // vite.config.ts
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'vite.config.ts'),
    `import { defineConfig } from 'vite';
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
`
  );

  // tailwind.config.js
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'tailwind.config.js'),
    `/** @type {import('tailwindcss').Config} */
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
`
  );

  // tsconfig.json
  fs.writeFileSync(
    path.join(moduleDir, 'app', 'tsconfig.json'),
    `{
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
`
  );

  print.success('Arquivos básicos criados');

  // ============================================================================
  // 4. Criar migration SQL
  // ============================================================================

  print.step('4. Criando migration SQL de exemplo...');

  const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const migrationFile = path.join(moduleDir, 'migrations', `${today}_${moduleSlug}.sql`);

  fs.writeFileSync(
    migrationFile,
    `-- Migration para módulo ${moduleTitle}
-- Data: ${new Date().toISOString().slice(0, 10)}

-- Tabela principal
CREATE TABLE IF NOT EXISTS ${moduleSlugSql}_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  created_by UUID,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_${moduleSlugSql}_items_tenant
  ON ${moduleSlugSql}_items(tenant_id);

CREATE INDEX IF NOT EXISTS idx_${moduleSlugSql}_items_created_by
  ON ${moduleSlugSql}_items(created_by);

-- Trigger para real-time (opcional)
CREATE OR REPLACE FUNCTION notify_${moduleSlugSql}_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    '${moduleSlug}_changes',
    json_build_object(
      'operation', TG_OP,
      'record', row_to_json(NEW),
      'tenant_id', NEW.tenant_id
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ${moduleSlugSql}_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON ${moduleSlugSql}_items
  FOR EACH ROW EXECUTE FUNCTION notify_${moduleSlugSql}_change();

-- RLS (Row Level Security) - Opcional
-- ALTER TABLE ${moduleSlugSql}_items ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY ${moduleSlugSql}_tenant_isolation ON ${moduleSlugSql}_items
--   USING (tenant_id = current_setting('app.current_tenant')::uuid);

COMMENT ON TABLE ${moduleSlugSql}_items IS 'Tabela principal do módulo ${moduleTitle}';
`
  );

  print.success('Migration SQL criada');

  // ============================================================================
  // 5. Criar README
  // ============================================================================

  print.step('5. Criando documentação...');

  fs.writeFileSync(
    path.join(moduleDir, 'README.md'),
    `# ${moduleTitle}

Módulo do Hub.app criado com DevKit.

## Estrutura

\`\`\`
mod-${moduleSlug}/
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
│   └── ${today}_${moduleSlug}.sql
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
     -f migrations/${today}_${moduleSlug}.sql
   \`\`\`

2. **Registrar módulo no banco:**
   \`\`\`bash
   cd ${hubDir}
   npm run module:install -- ${moduleSlug} "${moduleTitle}" ${moduleIcon}
   \`\`\`

3. **Criar API routes:**
   \`\`\`bash
   mkdir -p src/app/api/modules/${moduleSlug}
   # Copiar template de route.ts
   \`\`\`

4. **Atualizar Prisma schema:**
   \`\`\`prisma
   model ${moduleSlug}_items {
     id         String   @id @default(uuid()) @db.Uuid
     tenant_id  String   @db.Uuid
     created_by String?  @db.Uuid
     name       String   @db.VarChar(255)
     description String? @db.Text
     created_at DateTime @default(now()) @db.Timestamptz(6)
     updated_at DateTime @default(now()) @db.Timestamptz(6)

     @@index([tenant_id])
     @@map("${moduleSlug}_items")
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
`
  );

  print.success('README criado');

  // ============================================================================
  // 6. Instalar dependências
  // ============================================================================

  print.step('6. Instalando dependências...');

  try {
    execSync('npm install', {
      cwd: moduleDir,
      stdio: 'inherit',
    });
    print.success('Dependências instaladas');
  } catch (error) {
    print.warning('Erro ao instalar dependências. Execute manualmente: npm install');
  }

  // ============================================================================
  // Resumo
  // ============================================================================

  console.log('');
  print.success(`Módulo ${moduleTitle} criado com sucesso!`);
  console.log('');
  console.log(chalk.blue('Localização:'), moduleDir);
  console.log('');
  console.log(chalk.blue('Próximos passos:'));
  console.log(`  1. cd packages/mod-${moduleSlug}`);
  console.log('  2. npm run dev');
  console.log('  3. Abrir http://localhost:5173');
  console.log('');
  console.log(chalk.blue('Para instalar no Hub.app:'));
  console.log(`  1. Aplicar migration: psql ... -f migrations/${today}_${moduleSlug}.sql`);
  console.log(`  2. Registrar módulo: npm run module:install ${moduleSlug}`);
  console.log(`  3. Criar API routes: mkdir -p src/app/api/modules/${moduleSlug}`);
  console.log('');
  console.log(chalk.yellow('Documentação completa:'), `${moduleDir}/README.md`);
  console.log('');
}

// ============================================================================
// Exports
// ============================================================================

module.exports = createModule;

// Se executado diretamente (não via CLI)
if (require.main === module) {
  createModule(process.argv.slice(2)).catch((error) => {
    print.error(`Erro: ${error.message}`);
    process.exit(1);
  });
}
