# Estratégia de Sincronização: Hub.app ↔ DevKit

**Problema**: DevKit e Hub.app evoluem independentemente e podem ficar incompatíveis.

**Solução**: Sistema de versionamento acoplado com atualizações automáticas de schema.

---

## 🎯 Objetivo

Garantir que módulos criados com DevKit **sempre funcionem** no Hub.app, mesmo com atualizações frequentes.

---

## 📋 Camadas de Sincronização

### 1. **Schema do Banco de Dados**

#### **Problema:**
- Hub.app adiciona tabela `notificacoes`
- DevKit não tem essa tabela nos seeds
- Desenvolvedor cria módulo que tenta relacionar com `notificacoes`
- Erro: "table notificacoes does not exist"

#### **Solução: Schema Sync Automático**

**Implementação:**

```bash
# 1. Hub.app mantém schema versionado
hub-app-nextjs/
├── prisma/
│   └── schema.prisma  # Schema atual (v50)
└── migrations/
    ├── 001_initial.sql
    ├── 050_add_notifications.sql  # ← Nova migration
    └── manifest.json  # {"version": 50, "date": "2025-11-15"}
```

```bash
# 2. DevKit puxa schema automaticamente
hub-modules-devkit/
├── seeds/
│   ├── 01-schema-base.sql  # ← Auto-gerado do Hub.app
│   └── .schema-version     # {"hub_version": 50, "synced_at": "2025-11-15"}
└── scripts/
    └── sync-schema.js      # ← Script automático
```

**Comando: `hub-devkit sync-schema`**

```javascript
// scripts/sync-schema.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

async function syncSchema() {
  // 1. Detecta localização do Hub.app
  const hubAppPath = findHubAppRepo();

  if (!hubAppPath) {
    console.log('⚠️  Hub.app não encontrado. Sincronização manual necessária.');
    console.log('💡 Clone: git clone hub-app-nextjs ao lado do devkit');
    return;
  }

  // 2. Lê versão do Hub.app
  const hubManifest = require(`${hubAppPath}/migrations/manifest.json`);
  const hubVersion = hubManifest.version;

  // 3. Lê versão local do DevKit
  const devkitVersionFile = path.join(__dirname, '../seeds/.schema-version');
  let devkitVersion = 0;

  if (fs.existsSync(devkitVersionFile)) {
    devkitVersion = JSON.parse(fs.readFileSync(devkitVersionFile, 'utf-8')).hub_version;
  }

  // 4. Verifica se precisa atualizar
  if (hubVersion === devkitVersion) {
    console.log(`✅ Schema já sincronizado (v${hubVersion})`);
    return;
  }

  console.log(`🔄 Sincronizando schema: v${devkitVersion} → v${hubVersion}`);

  // 5. Gera novo schema a partir do Prisma
  const schemaPath = path.join(__dirname, '../seeds/01-schema-base.sql');

  execSync(`cd ${hubAppPath} && npx prisma migrate diff \
    --from-empty \
    --to-schema-datamodel prisma/schema.prisma \
    --script > ${schemaPath}`,
    { stdio: 'inherit' }
  );

  // 6. Adiciona header
  const header = `-- Schema Base - Hub.app v${hubVersion}
-- Gerado automaticamente em ${new Date().toISOString()}
-- NÃO EDITAR MANUALMENTE - Use 'hub-devkit sync-schema'

`;
  const schemaContent = fs.readFileSync(schemaPath, 'utf-8');
  fs.writeFileSync(schemaPath, header + schemaContent);

  // 7. Atualiza versão local
  fs.writeFileSync(devkitVersionFile, JSON.stringify({
    hub_version: hubVersion,
    synced_at: new Date().toISOString(),
    hub_commit: execSync('git rev-parse HEAD', { cwd: hubAppPath, encoding: 'utf-8' }).trim()
  }, null, 2));

  console.log(`✅ Schema sincronizado! (v${hubVersion})`);
  console.log(`💡 Execute 'hub-devkit setup-database' para aplicar no PostgreSQL local`);
}

function findHubAppRepo() {
  // Busca hub-app-nextjs em locais comuns:
  const possiblePaths = [
    '../hub-app-nextjs',  // Lado a lado
    '../../hub-app-nextjs',
    process.env.HUB_APP_PATH
  ];

  for (const p of possiblePaths) {
    if (p && fs.existsSync(path.join(p, 'prisma/schema.prisma'))) {
      return path.resolve(p);
    }
  }

  return null;
}

module.exports = { syncSchema };
```

**Uso:**
```bash
# Desenvolvedor roda periodicamente (ou CLI avisa)
hub-devkit sync-schema
# 🔄 Sincronizando schema: v45 → v50
# ✅ Schema sincronizado!

# Aplicar no banco local
hub-devkit setup-database --reset
```

---

### 2. **API Routes Patterns**

#### **Problema:**
- Hub.app muda padrão de autenticação JWT
- DevKit gera API routes com padrão antigo
- Módulos não funcionam

#### **Solução: Templates Versionados**

**Implementação:**

```bash
hub-app-nextjs/
└── templates/
    ├── api-route.v2.ts     # ← Template oficial do Hub.app
    ├── middleware.v2.ts
    └── manifest.json       # {"api_version": 2}

hub-modules-devkit/
└── templates/
    ├── api-route.template.ts  # ← Copiado do Hub.app
    └── .api-version           # {"version": 2, "synced_at": "..."}
```

**Comando: `hub-devkit sync-templates`**

```javascript
// scripts/sync-templates.js
async function syncTemplates() {
  const hubAppPath = findHubAppRepo();

  // Copia templates do Hub.app para DevKit
  const templates = [
    'api-route.v2.ts',
    'middleware.v2.ts',
    'prisma-client.ts'
  ];

  for (const template of templates) {
    fs.copyFileSync(
      `${hubAppPath}/templates/${template}`,
      `${__dirname}/../templates/${template}`
    );
  }

  console.log('✅ Templates sincronizados!');
}
```

---

### 3. **Prisma Schema**

#### **Problema:**
- Desenvolvedor quer relacionar módulo com tabela nova do Hub.app
- DevKit não tem model no Prisma

#### **Solução: Prisma Schema Compartilhado**

**Implementação:**

```bash
hub-app-nextjs/
└── prisma/
    └── schema.prisma  # Fonte única da verdade

hub-modules-devkit/
└── prisma/
    └── schema.prisma  # ← Symlink ou cópia do Hub.app
```

**Opção A: Symlink (Recomendado para desenvolvimento)**
```bash
cd hub-modules-devkit/prisma
rm schema.prisma
ln -s ../../hub-app-nextjs/prisma/schema.prisma schema.prisma
# Agora sempre está sincronizado!
```

**Opção B: Cópia Automática**
```javascript
// scripts/sync-prisma.js
function syncPrisma() {
  const hubSchemaPath = `${hubAppPath}/prisma/schema.prisma`;
  const devkitSchemaPath = `${__dirname}/../prisma/schema.prisma`;

  fs.copyFileSync(hubSchemaPath, devkitSchemaPath);
  console.log('✅ Prisma schema sincronizado!');
}
```

---

## 🔔 Sistema de Compatibilidade

### **Versionamento Acoplado**

**Hub.app package.json:**
```json
{
  "name": "hub-app-nextjs",
  "version": "2.5.0",
  "devkit": {
    "min_version": "1.2.0",  // DevKit mínimo compatível
    "max_version": "1.x.x"   // Qualquer 1.x funciona
  }
}
```

**DevKit package.json:**
```json
{
  "name": "hub-modules-devkit",
  "version": "1.3.0",
  "hubApp": {
    "min_version": "2.0.0",  // Hub.app mínimo compatível
    "max_version": "2.x.x"
  }
}
```

**Validação Automática:**
```javascript
// lib/check-compatibility.js
async function checkCompatibility() {
  const hubAppPath = findHubAppRepo();

  if (!hubAppPath) {
    console.log('⚠️  Hub.app não encontrado. Instale ao lado do DevKit.');
    return false;
  }

  const hubVersion = require(`${hubAppPath}/package.json`).version;
  const devkitVersion = require('../package.json').version;

  const hubRequires = require(`${hubAppPath}/package.json`).devkit;
  const devkitRequires = require('../package.json').hubApp;

  // Valida se versões são compatíveis
  if (!semver.satisfies(devkitVersion, hubRequires.min_version)) {
    console.log(`❌ DevKit incompatível!`);
    console.log(`   Hub.app v${hubVersion} requer DevKit >= ${hubRequires.min_version}`);
    console.log(`   Você está usando DevKit v${devkitVersion}`);
    console.log(`💡 Execute: hub-devkit update`);
    return false;
  }

  if (!semver.satisfies(hubVersion, devkitRequires.min_version)) {
    console.log(`❌ Hub.app incompatível!`);
    console.log(`   DevKit v${devkitVersion} requer Hub.app >= ${devkitRequires.min_version}`);
    console.log(`   Você está usando Hub.app v${hubVersion}`);
    console.log(`💡 Execute: cd hub-app-nextjs && git pull`);
    return false;
  }

  console.log(`✅ Versões compatíveis!`);
  console.log(`   Hub.app: v${hubVersion}`);
  console.log(`   DevKit:  v${devkitVersion}`);
  return true;
}

// Executado automaticamente em TODOS os comandos do DevKit
```

---

## 🚀 Workflow Completo de Sincronização

### **Setup Inicial (uma vez):**

```bash
# 1. Clone Hub.app e DevKit lado a lado
~/Documents/Claude/
├── hub-app-nextjs/      # Repositório do Hub.app
└── hub-modules-devkit/  # Repositório do DevKit

# 2. Setup do DevKit
cd hub-modules-devkit
npm install
npm link

# 3. Sincroniza pela primeira vez
hub-devkit sync-schema    # Puxa schema do Hub.app
hub-devkit sync-templates # Puxa templates de API routes
hub-devkit sync-prisma    # Puxa Prisma schema

# 4. Setup do banco de dados local
hub-devkit setup-database
```

---

### **Workflow Semanal (Desenvolvedor):**

```bash
# 1. Atualiza Hub.app
cd hub-app-nextjs
git pull origin main

# 2. DevKit detecta automaticamente incompatibilidade
cd ../hub-modules-devkit
hub-devkit create tasks "Tasks" ListTodo

⚠️  Hub.app foi atualizado!
    Hub.app: v2.5.0 (era v2.4.0)
    DevKit:  v1.3.0 (desatualizado)

💡 Sincronizando automaticamente...
   🔄 Schema: v45 → v48 (3 migrations novas)
   🔄 Templates: API routes v2 → v3
   ✅ Sincronização completa!

# 3. Aplica mudanças no banco local
hub-devkit setup-database --apply-changes
# Aplicando 3 migrations: 046, 047, 048
# ✅ Banco atualizado!

# 4. Agora pode criar módulo
hub-devkit create tasks "Tasks" ListTodo
# ✅ Módulo criado com compatibilidade v2.5.0!
```

---

### **Workflow Mensal (Mantenedor - Você):**

```bash
# 1. Hub.app tem mudanças importantes
cd hub-app-nextjs
git log --oneline -10
# fa686ed feat: adicionar sistema de notificações
# fe92c91 feat: migrar autenticação para JWT v2
# 669b6f0 feat: adicionar suporte a webhooks

# 2. Atualiza versionamento acoplado
vim package.json
# "devkit": { "min_version": "1.4.0" }  # ← JWT v2 requer DevKit 1.4+

# 3. Atualiza DevKit com suporte às mudanças
cd ../hub-modules-devkit

# 3.1. Sincroniza schema/templates
hub-devkit sync-schema
hub-devkit sync-templates

# 3.2. Adapta templates se necessário
vim templates/api-route.template.ts
# Ajusta para usar JWT v2

# 3.3. Testa criação de módulo
hub-devkit create teste-jwt "Teste JWT" Shield
npm run test

# 3.4. Bumpa versão do DevKit
npm version minor  # 1.3.0 → 1.4.0
git push origin main --tags

# 3.5. Cria GitHub Release
gh release create v1.4.0 --notes "Compatível com Hub.app v2.5.0 (JWT v2)"
```

---

## 📊 Matriz de Compatibilidade

| Hub.app | DevKit | Compatível? | Notas |
|---------|--------|-------------|-------|
| v2.0.x  | v1.0.x | ✅ Sim | Release inicial |
| v2.1.x  | v1.0.x | ✅ Sim | Backward compatible |
| v2.2.x  | v1.1.x | ✅ Sim | Novas features |
| v2.5.x  | v1.3.x | ⚠️ Parcial | JWT v1 deprecated |
| v2.5.x  | v1.4.x | ✅ Sim | JWT v2 suportado |
| v3.0.x  | v1.x.x | ❌ Não | Breaking changes |
| v3.0.x  | v2.0.x | ✅ Sim | DevKit reescrito |

---

## 🔧 Comandos Adicionados ao DevKit

```bash
# Sincronização
hub-devkit sync-schema      # Atualiza schema SQL dos seeds
hub-devkit sync-templates   # Atualiza templates de API routes
hub-devkit sync-prisma      # Atualiza Prisma schema
hub-devkit sync-all         # Executa todos acima

# Verificação
hub-devkit check-compat     # Verifica compatibilidade com Hub.app
hub-devkit diff-schema      # Mostra diferenças de schema
hub-devkit diff-templates   # Mostra diferenças de templates

# Diagnóstico
hub-devkit doctor           # Verifica toda a configuração
```

---

## 🧪 Testes de Compatibilidade

### **CI/CD do DevKit:**

```yaml
# .github/workflows/compatibility.yml
name: Compatibility Test

on: [push, pull_request]

jobs:
  test-with-hub-app:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        hub-version: ['2.0.0', '2.5.0', 'main']

    steps:
      - uses: actions/checkout@v3
        name: Checkout DevKit

      - uses: actions/checkout@v3
        name: Checkout Hub.app
        with:
          repository: e4labs-bcm/hub-app-nextjs
          ref: ${{ matrix.hub-version }}
          path: hub-app-nextjs

      - name: Test Compatibility
        run: |
          npm install
          npm link
          hub-devkit sync-all
          hub-devkit create test-module "Test" Shield
          cd packages/mod-test-module
          npm install
          npm run build

      - name: Report
        run: |
          hub-devkit check-compat
```

---

## 📝 CHANGELOG Tracking (Hub.app → DevKit)

**Hub.app CHANGELOG.md:**
```markdown
## [2.5.0] - 2025-11-20

### ⚠️ Impacto no DevKit
- Migração JWT v1 → v2 requer DevKit >= v1.4.0
- Nova tabela `notificacoes` disponível para módulos
- Campo `avatar_url` adicionado em `perfis`

### Migrations
- 046_add_notifications.sql
- 047_add_avatar_to_profiles.sql
- 048_update_jwt_tokens.sql
```

**DevKit CHANGELOG.md:**
```markdown
## [1.4.0] - 2025-11-20

### ✨ Compatibilidade
- Suporte a Hub.app v2.5.0
- JWT v2 implementado nos templates
- Schema atualizado (migrations 046-048)

### ⚠️ Breaking
- Requer Hub.app >= v2.5.0 (JWT v2)
```

---

## 🎯 Resumo da Estratégia

| Aspecto | Solução | Automático? | Frequência |
|---------|---------|-------------|------------|
| **Schema SQL** | `sync-schema` | ✅ Sim (detecta) | Semanal |
| **API Templates** | `sync-templates` | ✅ Sim (detecta) | Mensal |
| **Prisma Schema** | Symlink ou sync | ✅ Sim (sempre) | Real-time |
| **Compatibilidade** | Versionamento acoplado | ✅ Sim (valida) | Todo comando |
| **Breaking Changes** | CHANGELOG + CI/CD | ❌ Manual | Releases |

---

## 🚨 Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Hub.app breaking sem avisar DevKit | 🔴 Alto | Versionamento acoplado + CI/CD |
| Desenvolvedor esquece de sync | 🟡 Médio | Auto-check em comandos |
| Schema drift gradual | 🟡 Médio | `hub-devkit doctor` semanal |
| Módulos antigos param de funcionar | 🟡 Médio | Matriz de compatibilidade |

---

## 📚 Documentação Adicional Necessária

1. **SYNC_GUIDE.md** - Guia de sincronização para desenvolvedores
2. **COMPATIBILITY_MATRIX.md** - Matriz de versões compatíveis
3. **MIGRATION_GUIDE.md** - Como migrar entre versões incompatíveis

---

**Criado em**: 13/11/2025
**Status**: Planejado (será implementado junto com Fase 7-8)
**Prioridade**: 🔴 Alta (crítico para produção)
