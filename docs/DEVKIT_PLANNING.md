# Hub.app Modules DevKit - Planejamento e Decisões de Arquitetura

**Data**: 12 de Novembro de 2025
**Status**: Em Planejamento
**Objetivo**: Criar DevKit que permita criação de módulos Hub.app completos e funcionais em 8 minutos (vs 18-27 horas manual)

---

## 📋 Índice

1. [Contexto e Motivação](#contexto-e-motivação)
2. [Problema Atual](#problema-atual)
3. [Discussões e Decisões Arquiteturais](#discussões-e-decisões-arquiteturais)
4. [Arquitetura Final](#arquitetura-final)
5. [Fluxo de Uso com Claude Code](#fluxo-de-uso-com-claude-code)
6. [Plano de Implementação](#plano-de-implementação)
7. [Questões Pendentes](#questões-pendentes)

---

## 🎯 Contexto e Motivação

### Situação Atual
- DevKit foi criado com estrutura básica (scripts bash, templates, documentação)
- Publicado no GitHub: https://github.com/e4labs-bcm/hub-modules-devkit
- Teste inicial realizado: módulo `mod-teste-template` criado com sucesso
- **Problema descoberto**: Módulo criado vem com **dados mockados**, não funcional

### O Que Queremos Alcançar
> "O que eu acho mais difícil é receber o módulo cru de frontend com dados mockados e depois passar muito tempo para fazer tudo funcionar" - Usuário

**Meta**: Módulo gerado deve vir **100% funcional** com:
- ✅ CRUD completo (Create, Read, Update, Delete)
- ✅ Dados **REAIS** (não mockados)
- ✅ API Routes criadas automaticamente
- ✅ Banco de dados configurado
- ✅ Pronto para customização (não para desenvolver do zero)

---

## 🚨 Problema Atual

### Bugs Identificados

#### 1. Migration SQL com Nome de Tabela Inválido
```sql
-- ERRADO (create-module.sh linha ~351):
CREATE TABLE teste-template_items (...)
-- Hífens são inválidos no PostgreSQL

-- CORRETO:
CREATE TABLE teste_template_items (...)
```

**Impacto**: Migration falha, `install-module.sh` para com erro, nada funciona.

#### 2. API Routes Não São Criadas
- Código existe em `install-module.sh` (linhas 191-389)
- Mas **nunca executa** (provavelmente por causa do Bug #1)
- Resultado: Desenvolvedor precisa criar API routes manualmente (4-6 horas)

#### 3. Prisma Schema Não É Atualizado
- Script não adiciona novo modelo ao `prisma/schema.prisma`
- TypeScript types não são gerados
- API routes não podem compilar

#### 4. Frontend Template É Apenas Mockup
```tsx
// App.tsx atual (66 linhas):
return (
  <div>
    <h1>Teste Template</h1>
    <p>Bem-vindo! Agora você pode começar a desenvolver.</p>
    {/* Nada funciona, tudo estático */}
  </div>
);
```

**Comparação**: `mod-financeiro` tem 1066 linhas com CRUD completo, real-time, error handling.

### Análise de Tempo

| Tarefa | Tempo Atual (Manual) | Tempo Prometido (DevKit) | Gap |
|--------|---------------------|--------------------------|-----|
| Estrutura do módulo | 1-2 horas | ✅ 2 minutos (automatizado) | - |
| Migration SQL | 1-2 horas | ❌ Criado mas com bugs | Bug #1 |
| API Routes | 4-6 horas | ❌ Não criadas | Bug #2 |
| Prisma Schema | 1-2 horas | ❌ Não atualizado | Bug #3 |
| Frontend CRUD | 6-10 horas | ❌ Apenas mockup | Bug #4 |
| **TOTAL** | **18-27 horas** | **~18 horas** (ainda manual!) | 😞 |

**Conclusão**: DevKit promete "95% de economia de tempo" mas só entrega ~10% porque apenas a estrutura é automatizada.

---

## 💬 Discussões e Decisões Arquiteturais

### Discussão 1: Dados Mockados vs Reais

**Pergunta Inicial**: "Vamos usar dados mockados?"

**Resposta**: **NÃO!** Dados **REAIS** desde o início.

**Decisão**:
- Frontend usa `apiAdapter.ts` (já existe) que faz fetch real
- API routes retornam dados do PostgreSQL via Prisma
- Zero mocks, zero dados falsos
- Desenvolvedor vê CRUD funcionando ao abrir `localhost:5173`

---

### Discussão 2: Backend Junto ou Separado?

**Pergunta**: "Terá o backend junto?"

**Resposta**: **SIM!** Backend (API routes) criado **AUTOMATICAMENTE** pelo `install-module.sh`.

**Decisão**:
- Script cria automaticamente:
  - `src/app/api/modules/{slug}/items/route.ts` (GET, POST)
  - `src/app/api/modules/{slug}/items/[id]/route.ts` (GET, PUT, DELETE)
- Código gerado inclui:
  - ✅ JWT authentication (via `authenticateModule()`)
  - ✅ Multi-tenancy (filtra por `tenant_id`)
  - ✅ Auditoria LGPD (`created_by` preenchido automaticamente)
  - ✅ Error handling
  - ✅ CORS configurado

**Código Exemplo Gerado**:
```typescript
// Auto-gerado por install-module.sh
export async function GET(req: NextRequest) {
  const { tenantId } = await authenticateModule(req);

  const items = await prisma.tasksItems.findMany({
    where: { tenant_id: tenantId }
  });

  return apiResponse(items);
}
```

---

### Discussão 3: Onde Fica o Banco de Dados?

**Pergunta**: "Onde vai ficar o banco de dados? Como será migrado para o DB oficial do hub.app?"

**Arquitetura de 3 Ambientes Decidida**:

```
┌─────────────────────────────────────────────────────────┐
│  AMBIENTE 1: DESENVOLVIMENTO (Local)                    │
├─────────────────────────────────────────────────────────┤
│  DATABASE_URL="postgresql://localhost:5432/hub_app_dev"│
│  - Cada desenvolvedor tem SEU banco                     │
│  - Isolamento total (seguro)                            │
│  - Pode quebrar à vontade (não afeta ninguém)           │
└─────────────────────────────────────────────────────────┘
                       ↓ git push
┌─────────────────────────────────────────────────────────┐
│  AMBIENTE 2: STAGING (VPS Hostinger)                    │
├─────────────────────────────────────────────────────────┤
│  DATABASE_URL="...@82.25.77.179:5433/hub_app_staging"  │
│  - CI/CD aplica migrations automaticamente              │
│  - QA valida funcionalidades                            │
│  - Cliente faz homologação                              │
└─────────────────────────────────────────────────────────┘
                       ↓ aprovação
┌─────────────────────────────────────────────────────────┐
│  AMBIENTE 3: PRODUÇÃO (Servidor Prod)                   │
├─────────────────────────────────────────────────────────┤
│  DATABASE_URL="...@prod-server:5432/hub_app_production"│
│  - Migrations com BACKUP obrigatório                    │
│  - Aprovação manual necessária                          │
│  - Rollback disponível                                  │
└─────────────────────────────────────────────────────────┘
```

**Como Migrations Funcionam (Sistema "tipo Git")**:
```bash
migrations/
├── 001_initial_schema.sql           # Estado inicial
├── 002_add_financeiro_module.sql    # +3 tabelas
├── 003_add_tasks_module.sql         # +1 tabela
└── 004_add_priority_to_tasks.sql    # ALTER TABLE

# Comandos (tipo Git):
./scripts/migration-status.sh       # Como "git log"
./scripts/migration-up.sh 004       # Como "git apply"
./scripts/migration-down.sh 004     # Como "git revert"
./scripts/migration-to.sh 002       # Como "git reset --hard"
```

**Rastreamento**:
```sql
-- Tabela de controle (como .git/HEAD):
CREATE TABLE schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  applied_by VARCHAR(255),
  checksum VARCHAR(64)
);
```

---

### Discussão 4: PostgreSQL Local - Docker vs Nativo?

**Opções Avaliadas**:

| Opção | Setup | Performance | Memória | Portabilidade |
|-------|-------|-------------|---------|---------------|
| A) Tudo Nativo | 30 min | ⚡⚡⚡⚡⚡ | ~2GB | ⭐⭐ |
| B) Só DB Docker | 5 min | ⚡⚡⚡⚡ | ~2.5GB | ⭐⭐⭐⭐ |
| C) Tudo Docker | 2 min | ⚡⚡⚡ | ~5GB | ⭐⭐⭐⭐⭐ |

**Decisão**: **Opção A+ (Tudo Nativo com Scripts de Setup)**

**Justificativa**:
- Máxima performance (hub.app + módulos fora do Docker)
- Hot reload instantâneo (Next.js + Vite)
- Menos memória (~2GB vs ~5GB)
- Scripts de setup automatizam instalação (fácil como Docker)
- Docker disponível como **OPCIONAL** (para quem preferir)

**Estrutura Decidida**:
```bash
hub-modules-devkit/
├── scripts/
│   ├── setup-mac.sh           # Instala PostgreSQL nativo (Mac)
│   ├── setup-linux.sh         # Instala PostgreSQL nativo (Linux)
│   └── setup-windows.sh       # Instala PostgreSQL nativo (Windows)
├── seeds/
│   ├── 01-schema-base.sql     # Dump do staging (todas tabelas)
│   ├── 02-dev-tenants.sql     # 3 tenants de exemplo
│   ├── 03-dev-users.sql       # Usuários de teste
│   └── 04-dev-modules.sql     # Módulos pré-instalados
└── docker/                    # OPCIONAL
    └── docker-compose.yml     # Para quem não quer instalar PostgreSQL
```

**Sistema de Seeds Híbrido**:
```bash
# 1. Schema base gerado automaticamente do staging:
./scripts/update-schema-from-staging.sh
# Faz pg_dump do 82.25.77.179:5433
# Salva em seeds/01-schema-base.sql
# Commita no Git

# 2. Dados de dev curados manualmente:
# seeds/02-dev-tenants.sql - Tenants de exemplo
# seeds/03-dev-users.sql - Usuários de teste
```

---

### Discussão 5: Como Funciona com Claude Code?

**Pergunta**: "O devkit será rodado por dentro do claudecode"

**Resposta**: **SIM!** Claude Code é o "motor" que usa o DevKit.

**Fluxo Real Definido**:

```
1. Desenvolvedor inicia Claude Code
   ↓
2. Dev: "Vamos criar módulo CRM"
   ↓
3. Dev fornece PRD (ou Claude busca PRD existente)
   ↓
4. Claude Code lê:
   - .context/agents/module-creator.md
   - .context/docs/module-structure.md
   - templates/
   ↓
5. Claude GERA automaticamente:
   ✅ Estrutura de diretórios
   ✅ Migration SQL (tabelas, indexes)
   ✅ App.tsx com CRUD completo
   ✅ Componentes React (3-5 telas)
   ✅ API Routes (CRUD endpoints)
   ✅ Atualiza Prisma schema
   ✅ Types TypeScript
   ↓
6. Claude EXECUTA scripts auxiliares:
   - Aplica migration no banco
   - Regenera Prisma Client
   - Instala dependências
   ↓
7. Claude testa compilação e inicia dev server
   ↓
8. Módulo funcionando em http://localhost:5173
```

**Exemplo de Agent Context**:
```markdown
# .context/agents/module-creator.md

Quando o usuário pedir para criar um módulo:

1. Execute: `npx @hub/devkit create <slug> "<title>" <icon>`
   - Isso cria: packages/mod-<slug>/
   - Com estrutura completa e App.tsx funcional

2. Execute: `npx @hub/devkit install <slug>`
   - Aplica migration no banco
   - Cria API routes
   - Atualiza Prisma schema

3. Execute: `cd packages/mod-<slug> && npm run dev`

Se o usuário fornecer PRD detalhado:
- Use padrões de .context/docs/ para gerar componentes customizados
- Siga estrutura de templates/ mas adapte ao PRD
```

---

### Discussão 6: Distribuição do DevKit

**Opções Avaliadas**:

#### Opção 1: Repositório Git
```bash
git clone https://github.com/e4labs-bcm/hub-modules-devkit.git
git pull origin main  # Atualizar
```
✅ Simples
❌ Sem versionamento semântico
❌ Atualização manual

#### Opção 2: NPM Package ⭐ **RECOMENDADA**
```bash
npm install -g @hub/devkit
npx @hub/devkit create tasks "Tasks" ListTodo
npm update -g @hub/devkit  # Atualizar
```
✅ Versionamento semântico (v1.0.0, v2.0.0)
✅ CLI cross-platform (Mac/Windows/Linux)
✅ Atualização via npm
✅ Padrão da indústria

#### Opção 3: Bundled no Hub.app
```bash
hub-app-nextjs/scripts/create-module.sh
```
✅ Já vem junto
❌ Mistura concerns
❌ Difícil reutilizar

#### Opção 4: Híbrido
Repo Git + NPM Package
✅ Melhor dos dois mundos
❌ Mais complexo

**Decisão Pendente**: Inclinação para **Opção 2 (NPM Package)** mas aguardando confirmação final.

**Justificativa para NPM**:
- Claude Code pode executar: `npx @hub/devkit create ...`
- Funciona igual em Mac/Windows/Linux (Node.js é cross-platform)
- Versionamento claro (breaking changes explícitos)
- Profissional (padrão como create-react-app, prisma, etc.)

**Estrutura NPM**:
```
@hub/devkit/
├── package.json
├── cli.js                    # CLI entry point
├── lib/
│   ├── create-module.js      # Lógica de criação
│   ├── install-module.js     # Lógica de instalação
│   └── setup-database.js     # Setup de banco
├── templates/
│   ├── App.functional.tsx
│   └── ...
└── .context/
    ├── agents/
    │   └── module-creator.md
    └── docs/
        └── patterns.md
```

---

## 🏗️ Arquitetura Final

### Visão Geral

```
┌─────────────────────────────────────────────────────────┐
│  @hub/devkit (NPM Package)                              │
├─────────────────────────────────────────────────────────┤
│  - CLI cross-platform (Node.js)                         │
│  - Templates funcionais (App.tsx com CRUD real)         │
│  - Scripts de setup (Mac/Linux/Windows)                 │
│  - .context/ (agents para Claude Code)                  │
│  - Migrations system (tipo Git)                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Desenvolvedor                                          │
├─────────────────────────────────────────────────────────┤
│  1. npm install -g @hub/devkit                          │
│  2. Inicia Claude Code                                  │
│  3. "Crie módulo CRM com PRD X"                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Claude Code                                            │
├─────────────────────────────────────────────────────────┤
│  1. Lê .context/agents/module-creator.md                │
│  2. Executa: npx @hub/devkit create crm "CRM" Users     │
│  3. Executa: npx @hub/devkit install crm                │
│  4. Customiza baseado no PRD                            │
│  5. Inicia: cd packages/mod-crm && npm run dev          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Resultado                                              │
├─────────────────────────────────────────────────────────┤
│  ✅ packages/mod-crm/ com estrutura completa           │
│  ✅ App.tsx com CRUD funcional (não mockado!)          │
│  ✅ API Routes criadas e funcionando                   │
│  ✅ Migration aplicada no PostgreSQL local             │
│  ✅ Prisma schema atualizado                           │
│  ✅ http://localhost:5173 rodando                      │
│  ✅ Pronto para customização (não para criar do zero!) │
└─────────────────────────────────────────────────────────┘
```

### Componentes Principais

#### 1. CLI (@hub/devkit)
- `npx @hub/devkit create <slug> <title> <icon>` - Cria módulo
- `npx @hub/devkit install <slug>` - Instala no Hub.app
- `npx @hub/devkit setup` - Setup de banco de dados
- `npx @hub/devkit migrate <command>` - Gerencia migrations
- `npx @hub/devkit update` - Atualiza DevKit

#### 2. Templates
- `App.functional.tsx` (500+ linhas) - CRUD completo
- `ItemList.tsx` - Componente de listagem
- `ItemForm.tsx` - Formulário de criação/edição
- `LoadingSpinner.tsx`, `EmptyState.tsx`, `ErrorBanner.tsx`
- `useItems.ts` - Hook de gerenciamento de estado
- `migration.sql.template` - Template de migration

#### 3. Scripts de Setup
- `setup-mac.sh` - Instala PostgreSQL no Mac (Homebrew)
- `setup-linux.sh` - Instala PostgreSQL no Linux (apt/dnf)
- `setup-windows.sh` - Instala PostgreSQL no Windows (WSL/Installer)
- `update-schema-from-staging.sh` - Atualiza schema do staging

#### 4. Sistema de Migrations
- `migration-create.sh <name>` - Cria migration numerada
- `migration-status.sh` - Lista migrations (aplicadas vs pendentes)
- `migration-up.sh [version]` - Aplica migrations
- `migration-down.sh <version>` - Reverte migration
- `migration-to.sh <version>` - Vai para versão específica

#### 5. Context para Claude Code
- `.context/agents/module-creator.md` - Como criar módulos
- `.context/agents/api-developer.md` - Como criar/modificar APIs
- `.context/agents/feature-developer.md` - Como adicionar features
- `.context/docs/module-patterns.md` - Padrões de módulos
- `.context/docs/api-patterns.md` - Padrões de API

---

## 🎬 Fluxo de Uso com Claude Code

### Cenário 1: Criar Módulo Simples (8 minutos)

```
👤 Dev: "Crie um módulo de Tasks para gerenciar tarefas"

🤖 Claude Code:
1. Lê .context/agents/module-creator.md
2. Executa: npx @hub/devkit create tasks "Tasks" ListTodo
   ✅ Cria packages/mod-tasks/
   ✅ App.tsx com CRUD (500 linhas)
   ✅ Migration SQL criada

3. Executa: npx @hub/devkit install tasks
   ✅ Aplica migration no PostgreSQL local
   ✅ Cria API routes em src/app/api/modules/tasks/
   ✅ Atualiza prisma/schema.prisma
   ✅ Roda npx prisma generate

4. Executa: cd packages/mod-tasks && npm install && npm run dev
   ✅ http://localhost:5173 rodando

5. Informa: "Módulo Tasks criado! Acesse http://localhost:5173"

⏱️ Tempo: 8 minutos
```

### Cenário 2: Criar Módulo com PRD Complexo (30-60 minutos)

```
👤 Dev: "Crie módulo CRM baseado neste PRD: [anexa PRD de 10 páginas]"

🤖 Claude Code:
1. Lê e analisa PRD
2. Identifica:
   - 5 tabelas necessárias (contatos, empresas, deals, atividades, notas)
   - 3 telas principais (Dashboard, Lista de Contatos, Detalhes)
   - Funcionalidades especiais (filtros avançados, busca, tags)

3. Cria estrutura base:
   npx @hub/devkit create crm "CRM" Users

4. Customiza baseado no PRD:
   - Gera migration complexa (5 tabelas relacionadas)
   - Cria componentes adicionais (Dashboard.tsx, ContactDetail.tsx)
   - Adiciona hooks customizados (useContacts, useDeals)
   - Cria API routes adicionais (search, filters, export)

5. Instala e testa:
   npx @hub/devkit install crm
   npm run dev

6. Informa: "Módulo CRM criado com todas as funcionalidades do PRD!"

⏱️ Tempo: 30-60 minutos (vs 18-27 horas manual)
```

### Cenário 3: Adicionar Feature a Módulo Existente (5-10 minutos)

```
👤 Dev: "Adicione campo 'priority' (baixa/média/alta) nas tasks"

🤖 Claude Code:
1. Lê .context/agents/feature-developer.md
2. Identifica arquivos a modificar:
   - migrations/YYYYMMDD_tasks.sql
   - prisma/schema.prisma
   - app/src/types/index.ts
   - app/src/components/ItemForm.tsx
   - app/src/components/ItemList.tsx

3. Cria migration:
   npx @hub/devkit migrate create add_priority_to_tasks
   # Edita migration gerada com ALTER TABLE

4. Aplica mudanças:
   - Migration: ALTER TABLE tasks_items ADD COLUMN priority VARCHAR(20)
   - Prisma: priority String? @db.VarChar(20)
   - Types: priority?: 'baixa' | 'media' | 'alta'
   - Form: <Select> com opções
   - List: <Badge color={priority}>

5. Executa:
   npx @hub/devkit migrate up
   npx prisma generate

6. Informa: "Campo priority adicionado com sucesso!"

⏱️ Tempo: 5-10 minutos (vs 2 horas manual)
```

---

## 📅 Plano de Implementação

### Fase 1: Corrigir Bugs Críticos (30 min)

**1.1 Fix Table Naming**
- Arquivo: `scripts/create-module.sh`
- Adicionar função `sanitize_table_name()`:
  ```bash
  sanitize_table_name() {
    echo "$1" | tr '-' '_'
  }
  TABLE_NAME=$(sanitize_table_name "$MODULE_SLUG")
  ```
- Aplicar em todas gerações de SQL

**1.2 Fix API Routes Creation**
- Arquivo: `scripts/install-module.sh`
- Garantir que código das linhas 191-389 REALMENTE executa
- Adicionar logs: `echo "Criando API routes..."`
- Validar criação: `ls -la src/app/api/modules/$MODULE_SLUG/`

**1.3 Fix Prisma Schema Update**
- Adicionar função `update_prisma_schema()` em `install-module.sh`
- Gerar modelo com nome CamelCase
- Adicionar relações (tenant, creator)
- Executar `npx prisma generate`

---

### Fase 2: Scripts de Setup Nativos (1h 30min)

**2.1 Script setup-mac.sh**
```bash
#!/bin/bash
# Detecta PostgreSQL
if command -v psql &> /dev/null; then
  echo "PostgreSQL já instalado"
else
  brew install postgresql@16
  brew services start postgresql@16
fi

# Cria database
createdb hub_app_dev

# Aplica seeds
psql hub_app_dev < seeds/01-schema-base.sql
psql hub_app_dev < seeds/02-dev-tenants.sql
psql hub_app_dev < seeds/03-dev-users.sql

# Cria .env.local
echo "DATABASE_URL=\"postgresql://postgres:postgres@localhost:5432/hub_app_dev\"" > .env.local

# Testa conexão
psql hub_app_dev -c "SELECT COUNT(*) FROM tenants;"
```

**2.2 Script setup-linux.sh** (similar ao Mac, mas com apt/dnf)

**2.3 Script setup-windows.sh** (instruções para WSL ou Windows Installer)

**2.4 Seeds SQL**
- `seeds/01-schema-base.sql` - Gerar com `pg_dump` do staging
- `seeds/02-dev-tenants.sql` - 3 tenants curados manualmente
- `seeds/03-dev-users.sql` - 5 usuários de teste
- `seeds/04-dev-modules.sql` - Módulos pré-instalados

**2.5 Script update-schema-from-staging.sh**
```bash
#!/bin/bash
pg_dump -h 82.25.77.179 -p 5433 -U hub_app_user \
  --schema-only \
  -f seeds/01-schema-base.sql \
  hub_app_staging

# Adiciona header
sed -i '1i-- Schema Base - Exported from Staging' seeds/01-schema-base.sql
sed -i "2i-- Date: $(date)" seeds/01-schema-base.sql

git add seeds/01-schema-base.sql
git commit -m "chore: update schema from staging $(date +%Y-%m-%d)"
```

---

### Fase 3: Sistema de Migrations (1h)

**3.1 Tabela de Controle**
```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  applied_by VARCHAR(255),
  checksum VARCHAR(64),
  description TEXT
);
```

**3.2 Scripts de Migration**
- `migration-create.sh <name>`
- `migration-status.sh`
- `migration-up.sh [version]`
- `migration-down.sh <version>`
- `migration-to.sh <version>`

---

### Fase 4: App.tsx Funcional (2h 30min)

**4.1 Criar template/App.functional.tsx (500 linhas)**
```tsx
import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { moduleAPI } from '../../adapter/apiAdapter';

interface Item {
  id: string;
  name: string;
  description?: string;
  status: string;
  created_at: string;
  updated_at: string;
}

function App() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load items
  useEffect(() => {
    loadItems();
  }, []);

  const loadItems = async () => {
    try {
      setLoading(true);
      const data = await moduleAPI.getItems();
      setItems(data);
    } catch (err) {
      setError(err.message);
      toast.error('Erro ao carregar itens');
    } finally {
      setLoading(false);
    }
  };

  const createItem = async (data) => {
    try {
      const newItem = await moduleAPI.createItem(data);
      setItems([...items, newItem]);
      toast.success('Item criado!');
    } catch (err) {
      toast.error('Erro ao criar item');
    }
  };

  // ... updateItem, deleteItem

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      {loading && <LoadingSpinner />}
      {error && <ErrorBanner error={error} />}
      {!loading && items.length === 0 && <EmptyState />}
      {!loading && items.length > 0 && (
        <>
          <ItemForm onSubmit={createItem} />
          <ItemList items={items} onEdit={updateItem} onDelete={deleteItem} />
        </>
      )}
    </div>
  );
}
```

**4.2 Componentes Reutilizáveis**
- `ItemList.tsx` (150 linhas)
- `ItemForm.tsx` (200 linhas)
- `LoadingSpinner.tsx` (50 linhas)
- `EmptyState.tsx` (50 linhas)
- `ErrorBanner.tsx` (50 linhas)

**4.3 Hooks**
- `useItems.ts` - Gerencia CRUD
- `useForm.ts` - Gerencia formulários

---

### Fase 5: Converter para NPM Package (2h)

**5.1 Estrutura NPM**
```
@hub/devkit/
├── package.json
├── cli.js
├── lib/
│   ├── create-module.js
│   ├── install-module.js
│   └── setup-database.js
├── templates/
├── .context/
└── scripts/
```

**5.2 package.json**
```json
{
  "name": "@hub/devkit",
  "version": "1.0.0",
  "bin": {
    "hub-devkit": "./cli.js"
  },
  "files": [
    "lib/",
    "templates/",
    ".context/",
    "scripts/",
    "seeds/"
  ],
  "dependencies": {
    "commander": "^11.0.0",
    "chalk": "^5.0.0",
    "ora": "^7.0.0"
  }
}
```

**5.3 CLI Interface**
```javascript
#!/usr/bin/env node
const { program } = require('commander');

program
  .command('create <slug> <title> <icon>')
  .description('Create a new Hub.app module')
  .action(require('./lib/create-module'));

program
  .command('install <slug>')
  .description('Install module in Hub.app')
  .action(require('./lib/install-module'));

program
  .command('setup')
  .description('Setup local database')
  .action(require('./lib/setup-database'));

program.parse();
```

---

### Fase 6: Context para Claude Code (1h)

**6.1 Criar .context/agents/module-creator.md**
```markdown
# Module Creator Agent

Quando o usuário pedir para criar um módulo:

1. Verifique se @hub/devkit está instalado:
   ```bash
   npx @hub/devkit --version
   ```

2. Crie o módulo:
   ```bash
   npx @hub/devkit create <slug> "<title>" <icon>
   ```

3. Instale no Hub.app:
   ```bash
   npx @hub/devkit install <slug>
   ```

4. Inicie o módulo:
   ```bash
   cd packages/mod-<slug>
   npm install
   npm run dev
   ```

5. Informe ao usuário que o módulo está rodando em http://localhost:5173

Se houver PRD:
- Analise o PRD e identifique tabelas/telas necessárias
- Use o módulo base gerado como ponto de partida
- Customize componentes e API routes conforme PRD
```

**6.2 Criar .context/agents/api-developer.md**
**6.3 Criar .context/agents/feature-developer.md**
**6.4 Criar .context/docs/module-patterns.md**
**6.5 Criar .context/docs/api-patterns.md**

---

### Fase 7: Sistema de Atualização Completo (1h 30min)

**7.1 Comando `hub-devkit update`**
```javascript
// lib/update.js
async function update() {
  // 1. Fetch latest release from GitHub API
  // 2. Compare com versão atual (package.json)
  // 3. Se breaking change (major version), mostrar CHANGELOG
  // 4. Pedir confirmação
  // 5. Executar git pull origin main
  // 6. Mostrar resumo do que mudou
}
```

**7.2 Comando `hub-devkit rollback`**
```javascript
// lib/rollback.js
async function rollback() {
  // 1. Listar últimas 5 versões (git tag)
  // 2. Mostrar versão atual
  // 3. Deixar escolher qual voltar
  // 4. git checkout <version>
  // 5. Avisar que está em "detached HEAD"
}
```

**7.3 Comando `hub-devkit check-updates`**
```javascript
// lib/check-updates.js
async function checkUpdates() {
  // 1. Fetch GitHub API
  // 2. Comparar versões (semver)
  // 3. Mostrar: patch (bugfix), minor (feature), major (breaking)
  // 4. Sugerir: "Execute 'hub-devkit update'"
}
```

**7.4 Auto-check em todo comando**
```javascript
// cli.js (no início de TODOS os comandos)
const { autoCheckUpdates } = require('./lib/check-updates');

// Executa em background (não bloqueia)
autoCheckUpdates().then(hasUpdate => {
  if (hasUpdate) {
    console.log('\nℹ️  Nova versão disponível. Execute: hub-devkit update\n');
  }
});
```

**7.5 CHANGELOG.md tracking**
```markdown
# CHANGELOG.md

## [Unreleased]

## [2.0.0] - 2025-11-20 ⚠️ BREAKING
### Breaking Changes
- Mudança na API de criação

### Migration Guide
```bash
# v1.x
hub-devkit create tasks "Tasks" ListTodo

# v2.x
hub-devkit create tasks "Tasks" ListTodo --type=crud
```

## [1.1.0] - 2025-11-15
### Features
- Suporte para campos customizados

## [1.0.0] - 2025-11-13
### Initial Release
```

**7.6 package.json com version tracking**
```json
{
  "name": "hub-modules-devkit",
  "version": "1.0.0",
  "repository": {
    "type": "git",
    "url": "git@github.com:e4labs-bcm/hub-modules-devkit.git"
  }
}
```

---

### Fase 8: Documentação (1h)

**8.1 DATABASE_SETUP.md**
**8.2 MIGRATIONS.md**
**8.3 DEPLOYMENT.md**
**8.4 UPDATE_GUIDE.md** (novo!)
**8.5 Atualizar README.md**
**8.6 Atualizar QUICK_START.md**

---

## ⏱️ Resumo de Tempo

| Fase | Descrição | Tempo Estimado |
|------|-----------|----------------|
| 1 | Corrigir bugs críticos | 30 min |
| 2 | Scripts de setup nativos | 1h 30min |
| 3 | Sistema de migrations | 1h |
| 4 | App.tsx funcional | 2h 30min |
| 5 | Converter para Node.js | 2h |
| 6 | Context para Claude | 1h |
| 7 | Sistema de atualização | 1h 30min |
| 8 | Documentação | 1h |
| **TOTAL** | | **~11h 30min** |

---

## ✅ Questões Pendentes - RESOLVIDAS

### 1. Distribuição NPM ✅
- [x] **Decisão**: Git Repo Privado + `npm link` (NÃO publicar no NPM)
- [x] **Nome**: `hub-modules-devkit` (package.json local)
- [x] **Comando global**: `hub-devkit` (via npm link)
- [x] **Justificativa**:
  - ✅ Seguro (código privado no GitHub)
  - ✅ Grátis (sem custos de NPM private)
  - ✅ Não expõe arquitetura do Hub.app
  - ✅ Claude Code pode executar facilmente

**Setup do Desenvolvedor:**
```bash
git clone git@github.com:e4labs-bcm/hub-modules-devkit.git
cd hub-modules-devkit
npm install
npm link  # Cria comando global 'hub-devkit'
```

### 2. Cross-Platform ✅
- [x] **Decisão**: Reescrever scripts em **Node.js puro** (não Bash)
- [x] **Justificativa**:
  - ✅ Funciona em Mac, Linux, Windows (sem WSL)
  - ✅ Único código para todas plataformas
  - ✅ Menos manutenção
  - ✅ Já vai usar Node.js para CLI mesmo

**Conversão necessária:**
- `scripts/create-module.sh` → `lib/create-module.js`
- `scripts/install-module.sh` → `lib/install-module.js`
- `scripts/setup-database.sh` → `lib/setup-database.js`

### 3. Schema Inicial ✅
- [x] **Decisão**: Exportar schema completo do staging
- [x] **Método**: Script manual `update-schema-from-staging.sh`
- [x] **Frequência**: Sob demanda (quando necessário)
- [x] **Conteúdo**: DDL completo (incluir tabelas de teste)

**Comando:**
```bash
./scripts/update-schema-from-staging.sh
# Faz pg_dump de 82.25.77.179:5433
# Salva em seeds/01-schema-base.sql
# Commita automaticamente no Git
```

### 4. CI/CD ✅
- [x] **Decisão**: Minimalista (sem automação de migrations)
- [x] **O que NÃO fazer** (muito arriscado):
  - ❌ Automatizar migrations no staging
  - ❌ Testes E2E automatizados (fazer manual primeiro)
- [x] **O que fazer** (útil e seguro):
  - ✅ GitHub Actions para validação de sintaxe
  - ✅ Lint check (ESLint)
  - ✅ Type check (TypeScript)

**Pode adicionar depois**: Quando DevKit estiver maduro e estável.

### 5. Dados de Seed ✅
- [x] **Tenants**: 3 empresas de exemplo (Empresa A, B, C)
- [x] **Usuários**: 1 admin + 2 users por tenant (9 usuários total)
- [x] **Módulos pré-instalados**: Financeiro apenas (exemplo completo)
- [x] **Justificativa**:
  - 3 tenants = testa multi-tenancy realista
  - 9 usuários = testa permissões diferentes
  - Só Financeiro = não muito pesado, mas funcional

**Estrutura de Seeds:**
```
seeds/
├── 01-schema-base.sql      # DDL completo do staging
├── 02-dev-tenants.sql      # 3 empresas
├── 03-dev-users.sql        # 9 usuários (3 por tenant)
└── 04-dev-financeiro.sql   # Dados de exemplo do módulo
```

---

## 🎯 Decisões Finais - Resumo Executivo

| Aspecto | Decisão | Justificativa |
|---------|---------|---------------|
| **Distribuição** | Git Privado + npm link | Seguro, grátis, não expõe código |
| **Comando Global** | `hub-devkit` | Fácil de usar e memorizar |
| **Cross-Platform** | Node.js puro (não Bash) | Funciona Mac/Windows/Linux |
| **Schema Inicial** | Export manual do staging | Sob demanda, controle total |
| **CI/CD** | Minimalista (só lint/type) | Migrations manuais (segurança) |
| **Seeds Dev** | 3 tenants, 9 users, Financeiro | Realista mas leve |
| **Publicar NPM?** | ❌ NÃO | Risco de segurança |

### Workflow Implementado

```bash
# Setup (uma vez):
git clone git@github.com:e4labs-bcm/hub-modules-devkit.git
cd hub-modules-devkit
npm install
npm link

# Uso:
hub-devkit create tasks "Tasks" ListTodo
hub-devkit install tasks

# Atualização:
cd hub-modules-devkit && git pull
```

---

## 📝 Notas Finais

### Principais Aprendizados

1. **Dados mockados são inaceitáveis** - Módulo deve vir funcional com CRUD real
2. **Claude Code é o motor** - DevKit é o "combustível" (templates + context)
3. **Cross-platform via Node.js** - Bash scripts limitam a Windows
4. **NPM Package é padrão da indústria** - Versionamento + distribuição
5. **3 ambientes são essenciais** - Dev local, Staging, Produção
6. **Migrations como Git** - Versionamento de schema é crucial

### Riscos Identificados

1. **Complexidade do NPM Package** - Primeira vez fazendo isso?
2. **Windows support** - Pode ter surpresas com PostgreSQL setup
3. **Schema drift** - Dev local pode ficar desatualizado com staging
4. **Breaking changes** - Atualizar DevKit pode quebrar módulos antigos

### Próximos Passos

1. ✅ **Validar decisão final**: Git Repo + npm link (DECIDIDO)
2. ✅ **Confirmar nome**: `hub-modules-devkit` (DECIDIDO)
3. ⏭️ **Iniciar Fase 1**: Corrigir bugs críticos (30 min) ← **PRÓXIMO**
4. ⏭️ **Converter para Node.js**: Reescrever scripts Bash → Node.js
5. ⏭️ **Testar end-to-end**: Criar módulo completo e validar funcionamento

---

**Última Atualização**: 13 de Novembro de 2025
**Status**: ✅ **PLANEJAMENTO COMPLETO - PRONTO PARA IMPLEMENTAÇÃO**
