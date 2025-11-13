#!/usr/bin/env node

/**
 * Hub.app Module Installer (Node.js version)
 * Instala um módulo no Hub.app (registra no banco + cria API routes)
 * Cross-platform: Windows, macOS, Linux
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const chalk = require('chalk');

// ============================================================================
// Funções de Output
// ============================================================================

const print = {
  step: (msg) => console.log(chalk.blue('==>'), msg),
  success: (msg) => console.log(chalk.green('✓'), msg),
  error: (msg) => console.log(chalk.red('✗'), msg),
  warning: (msg) => console.log(chalk.yellow('!'), msg),
};

// ============================================================================
// Validações
// ============================================================================

function validateArgs(args) {
  if (args.length < 3) {
    console.log('Uso: install-module <slug> <titulo> <icone> [tenant-id]');
    console.log('');
    console.log('Exemplo:');
    console.log('  install-module tarefas "Tarefas" ListTodo a01b75e2-233b-40c2-801b-0e4a7e2a4055');
    console.log('');
    process.exit(1);
  }

  const moduleSlug = args[0];
  const moduleTitle = args[1];
  const moduleIcon = args[2];
  const tenantId = args[3] || null;

  return { moduleSlug, moduleTitle, moduleIcon, tenantId };
}

// ============================================================================
// Funções Auxiliares
// ============================================================================

/**
 * Lê arquivo .env.local e retorna objeto com variáveis
 */
function loadEnvFile(hubDir) {
  const envPath = path.join(hubDir, '.env.local');

  if (!fs.existsSync(envPath)) {
    print.error('Arquivo .env.local não encontrado');
    process.exit(1);
  }

  const envContent = fs.readFileSync(envPath, 'utf8');
  const envVars = {};

  envContent.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const [key, ...valueParts] = trimmed.split('=');
      if (key) {
        envVars[key.trim()] = valueParts.join('=').replace(/^["']|["']$/g, '').trim();
      }
    }
  });

  return envVars;
}

/**
 * Extrai componentes da DATABASE_URL
 */
function parseDatabaseUrl(databaseUrl) {
  // postgresql://user:password@host:port/dbname?schema=public
  const regex = /postgresql:\/\/([^:]+):([^@]*)@([^:]+):(\d+)\/([^?]+)/;
  const match = databaseUrl.match(regex);

  if (!match) {
    print.error('DATABASE_URL inválida');
    process.exit(1);
  }

  return {
    user: match[1],
    password: match[2],
    host: match[3],
    port: match[4],
    database: match[5],
  };
}

/**
 * Executa comando psql
 */
function executePsql(dbConfig, sqlCommand) {
  try {
    const env = { ...process.env };
    if (dbConfig.password) {
      env.PGPASSWORD = dbConfig.password;
    }

    const result = execSync(
      `psql -U ${dbConfig.user} -h ${dbConfig.host} -p ${dbConfig.port} -d ${dbConfig.database} -c "${sqlCommand.replace(/"/g, '\\"')}"`,
      {
        env,
        encoding: 'utf8',
        stdio: 'pipe',
      }
    );

    return result;
  } catch (error) {
    throw new Error(`Erro ao executar psql: ${error.message}`);
  }
}

/**
 * Aplica migration SQL de arquivo
 */
function applyMigrationFile(dbConfig, migrationFile) {
  try {
    const env = { ...process.env };
    if (dbConfig.password) {
      env.PGPASSWORD = dbConfig.password;
    }

    const result = execSync(
      `psql -U ${dbConfig.user} -h ${dbConfig.host} -p ${dbConfig.port} -d ${dbConfig.database} -f "${migrationFile}"`,
      {
        env,
        encoding: 'utf8',
        stdio: 'pipe',
      }
    );

    return result;
  } catch (error) {
    throw new Error(`Erro ao aplicar migration: ${error.message}`);
  }
}

// ============================================================================
// Função Principal
// ============================================================================

async function installModule(args) {
  const { moduleSlug, moduleTitle, moduleIcon, tenantId } = validateArgs(args);

  // Sanitizar slug para SQL
  const moduleSlugSql = moduleSlug.replace(/-/g, '_');

  // Detectar diretório do Hub
  const hubDir = process.cwd();

  // Verificar se estamos no Hub.app
  const packageJsonPath = path.join(hubDir, 'package.json');
  if (!fs.existsSync(packageJsonPath)) {
    print.error('Execute este comando dentro do diretório hub-app-nextjs');
    process.exit(1);
  }

  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  if (!packageJson.name || !packageJson.name.includes('hub-app')) {
    print.error('Este não parece ser o diretório hub-app-nextjs');
    process.exit(1);
  }

  const moduleDir = path.join(hubDir, 'packages', `mod-${moduleSlug}`);

  if (!fs.existsSync(moduleDir)) {
    print.error(`Módulo não encontrado: ${moduleDir}`);
    print.warning('Use create-module primeiro para criar o módulo');
    process.exit(1);
  }

  // Carregar .env.local
  const envVars = loadEnvFile(hubDir);

  if (!envVars.DATABASE_URL) {
    print.error('DATABASE_URL não encontrada em .env.local');
    process.exit(1);
  }

  const dbConfig = parseDatabaseUrl(envVars.DATABASE_URL);

  print.step(`Instalando módulo: ${moduleTitle} (${moduleSlug})`);
  console.log('');

  // ============================================================================
  // 1. Aplicar Migration SQL
  // ============================================================================

  print.step('1. Aplicando migration SQL...');

  const migrationsDir = path.join(moduleDir, 'migrations');
  const migrationFiles = fs.existsSync(migrationsDir)
    ? fs.readdirSync(migrationsDir).filter((f) => f.endsWith('.sql'))
    : [];

  if (migrationFiles.length === 0) {
    print.warning(`Nenhuma migration encontrada em ${migrationsDir}`);
  } else {
    const migrationFile = path.join(migrationsDir, migrationFiles[0]);
    print.warning(`Aplicando migration: ${migrationFiles[0]}`);
    print.warning(`Database: ${dbConfig.database} @ ${dbConfig.host}:${dbConfig.port}`);

    try {
      applyMigrationFile(dbConfig, migrationFile);
      print.success('Migration aplicada');
    } catch (error) {
      print.error(error.message);
      print.warning('Aplique manualmente se necessário');
    }
  }

  // ============================================================================
  // 2. Registrar módulo no banco
  // ============================================================================

  print.step('2. Registrando módulo no banco de dados...');

  // Ler manifest.json
  const manifestPath = path.join(moduleDir, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

  const moduleUrl = manifest.url || 'http://localhost:5173/';
  const moduleVersion = manifest.version || '1.0.0';

  if (!manifest.url) {
    print.warning(`URL não encontrada no manifest, usando: ${moduleUrl}`);
  }

  // Script SQL para registrar módulo
  const sqlScript = `
DO $$
DECLARE
  v_tenant_id UUID := ${tenantId ? `'${tenantId}'::UUID` : 'NULL'};
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
  WHERE tenant_id = v_tenant_id AND nome = '${moduleTitle}';

  IF v_module_id IS NOT NULL THEN
    RAISE NOTICE 'Módulo já instalado para tenant %', v_tenant_id;
  ELSE
    -- Inserir módulo
    INSERT INTO modulos_instalados (id, tenant_id, nome, ativo, manifest)
    VALUES (
      gen_random_uuid(),
      v_tenant_id,
      '${moduleTitle}',
      true,
      '{
        "icon": "${moduleIcon}",
        "type": "iframe",
        "url": "${moduleUrl}",
        "overlay": false,
        "global": false,
        "version": "${moduleVersion}"
      }'::jsonb
    )
    RETURNING id INTO v_module_id;

    RAISE NOTICE 'Módulo instalado com sucesso! ID: %', v_module_id;
    RAISE NOTICE 'Tenant: %', v_tenant_id;
  END IF;
END
$$;
`;

  try {
    const result = executePsql(dbConfig, sqlScript);
    const notices = result.match(/NOTICE:.*$/gm);
    if (notices) {
      notices.forEach((notice) => console.log(chalk.dim(notice)));
    }
    print.success('Módulo registrado no banco');
  } catch (error) {
    print.error(error.message);
    process.exit(1);
  }

  // ============================================================================
  // 3. Criar API Routes
  // ============================================================================

  print.step('3. Criando API routes...');

  const apiDir = path.join(hubDir, 'src', 'app', 'api', 'modules', moduleSlug);

  if (fs.existsSync(apiDir)) {
    print.warning(`API routes já existem em: ${apiDir}`);
  } else {
    // Criar diretórios
    const itemsDir = path.join(apiDir, 'items');
    const itemByIdDir = path.join(itemsDir, '[id]');

    [apiDir, itemsDir, itemByIdDir].forEach((dir) => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });

    // route.ts para /items (GET, POST)
    const itemsRouteContent = `import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';
import { apiResponse, apiError } from '@/lib/api-response';

/**
 * GET /api/modules/${moduleSlug}/items
 * Lista items do tenant
 */
export async function GET(req: NextRequest) {
  try {
    const { tenantId } = await authenticateModule(req);

    const searchParams = req.nextUrl.searchParams;
    const limit = parseInt(searchParams.get('limit') || '50');
    const offset = parseInt(searchParams.get('offset') || '0');

    const items = await prisma.${moduleSlugSql}_items.findMany({
      where: { tenant_id: tenantId },
      take: limit,
      skip: offset,
      orderBy: { created_at: 'desc' },
    });

    const total = await prisma.${moduleSlugSql}_items.count({
      where: { tenant_id: tenantId },
    });

    return apiResponse(items, { limit, offset, total });
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}

/**
 * POST /api/modules/${moduleSlug}/items
 * Cria novo item
 */
export async function POST(req: NextRequest) {
  try {
    const { tenantId, userId } = await authenticateModule(req);
    const body = await req.json();

    const item = await prisma.${moduleSlugSql}_items.create({
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
`;

    fs.writeFileSync(path.join(itemsDir, 'route.ts'), itemsRouteContent);

    // route.ts para /items/[id] (GET, PUT, DELETE)
    const itemByIdRouteContent = `import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';
import { apiResponse, apiError } from '@/lib/api-response';

/**
 * GET /api/modules/${moduleSlug}/items/:id
 * Busca item por ID
 */
export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { tenantId } = await authenticateModule(req);
    const { id } = params;

    const item = await prisma.${moduleSlugSql}_items.findFirst({
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
 * PUT /api/modules/${moduleSlug}/items/:id
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

    const item = await prisma.${moduleSlugSql}_items.updateMany({
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
 * DELETE /api/modules/${moduleSlug}/items/:id
 * Deleta item
 */
export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { tenantId } = await authenticateModule(req);
    const { id } = params;

    const item = await prisma.${moduleSlugSql}_items.deleteMany({
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
`;

    fs.writeFileSync(path.join(itemByIdDir, 'route.ts'), itemByIdRouteContent);

    print.success(`API routes criadas em: ${apiDir}`);
  }

  // ============================================================================
  // 4. Atualizar Prisma Schema
  // ============================================================================

  print.step('4. Atualizando Prisma schema...');

  const prismaSchemaPath = path.join(hubDir, 'prisma', 'schema.prisma');
  const prismaSchema = fs.readFileSync(prismaSchemaPath, 'utf8');

  // Verificar se model já existe
  if (prismaSchema.includes(`model ${moduleSlugSql}_items`)) {
    print.warning(`Model ${moduleSlugSql}_items já existe no schema`);
  } else {
    const prismaModel = `

// ============================================================================
// Módulo: ${moduleTitle}
// ============================================================================

model ${moduleSlugSql}_items {
  id         String   @id @default(uuid()) @db.Uuid
  tenant_id  String   @db.Uuid
  created_by String?  @db.Uuid
  name       String   @db.VarChar(255)
  description String? @db.Text
  created_at DateTime @default(now()) @db.Timestamptz(6)
  updated_at DateTime @default(now()) @db.Timestamptz(6)

  // Relações
  perfis     perfis?  @relation(fields: [created_by], references: [id], name: "${moduleSlugSql}_items_created_by")

  @@index([tenant_id])
  @@index([created_by])
  @@map("${moduleSlugSql}_items")
}
`;

    fs.appendFileSync(prismaSchemaPath, prismaModel);
    print.success('Prisma schema atualizado');
  }

  // ============================================================================
  // 5. Regenerar Prisma Client
  // ============================================================================

  print.step('5. Regenerando Prisma Client...');

  try {
    execSync('npx prisma generate', {
      cwd: hubDir,
      stdio: 'inherit',
    });
    print.success('Prisma Client regenerado');
  } catch (error) {
    print.error('Erro ao regenerar Prisma Client');
    process.exit(1);
  }

  // ============================================================================
  // Resumo
  // ============================================================================

  console.log('');
  print.success(`Módulo ${moduleTitle} instalado com sucesso!`);
  console.log('');
  console.log(chalk.blue('Resumo:'));
  console.log('  ✓ Migration aplicada');
  console.log('  ✓ Módulo registrado no banco');
  console.log(`  ✓ API routes criadas em: src/app/api/modules/${moduleSlug}`);
  console.log('  ✓ Prisma schema atualizado');
  console.log('  ✓ Prisma Client regenerado');
  console.log('');
  console.log(chalk.blue('Próximos passos:'));
  console.log(`  1. cd packages/mod-${moduleSlug} && npm run dev`);
  console.log('  2. Reiniciar Next.js: npm run dev');
  console.log('  3. Abrir http://localhost:3000 e testar módulo');
  console.log('');
  console.log(chalk.yellow('Nota:'), 'Para deploy em produção, atualize a URL no manifest.json');
  console.log('');
}

// ============================================================================
// Exports
// ============================================================================

module.exports = installModule;

// Se executado diretamente
if (require.main === module) {
  installModule(process.argv.slice(2)).catch((error) => {
    print.error(`Erro: ${error.message}`);
    process.exit(1);
  });
}
