# CLAUDE.md - Hub Modules DevKit

**Projeto**: Kit de desenvolvimento para criar módulos do Hub.app
**Status**: 🚧 **Em Implementação - Fases 1-2 Completas (15% concluído)**
**Repositório**: https://github.com/e4labs-bcm/hub-modules-devkit
**Última Atualização**: 13/11/2025 - 11:00 UTC

---

## 🎯 **Objetivo do Projeto**

Criar um DevKit completo que permita desenvolvedores criarem módulos Hub.app **100% funcionais** em **8 minutos** (vs 18-27 horas manual), com:

- ✅ CRUD completo funcionando (não mockado)
- ✅ API Routes criadas automaticamente
- ✅ Banco de dados configurado
- ✅ Sincronização automática com Hub.app
- ✅ Sistema de atualização completo

---

## 📋 **Status de Implementação**

### **Fase 1: Bugs Críticos** ✅ COMPLETA (30min)

**Commitado**: `b194d01` - 13/11/2025

#### **Bug #1: Nome de tabela com hífens** ✅
- **Problema**: `CREATE TABLE teste-template_items` (SQL inválido)
- **Solução**: Variável `MODULE_SLUG_SQL` converte hífens → underscores
- **Resultado**: `teste_template_items` ✅

#### **Bug #2: API Routes usavam nome incorreto** ✅
- **Problema**: `prisma.teste-template_items` (Prisma error)
- **Solução**: `sed` agora substitui por `MODULE_SLUG_SQL`
- **Resultado**: `prisma.teste_template_items` ✅

#### **Bug #3: Prisma Schema incorreto** ✅
- **Problema**: `model teste-template_items` (Prisma error)
- **Solução**: Model usa `MODULE_SLUG_SQL`
- **Resultado**: `model teste_template_items` ✅

---

### **Fase 2: Scripts de Setup Nativos** ✅ COMPLETA (1h20min - 90%)

**Commitado**: `9693f89` - 13/11/2025

**Objetivo**: Automatizar instalação de PostgreSQL em Mac/Linux/Windows

**Scripts criados**:
- [x] `scripts/update-schema-from-staging.sh` - Exporta DDL do staging ✅
  - Exporta schema via pg_dump (só DDL, sem dados)
  - Adiciona metadata e estatísticas
  - Backup automático do arquivo anterior
  - Commit automático no Git

- [x] `scripts/setup-mac.sh` - Homebrew + PostgreSQL ✅
  - Instala PostgreSQL 16 via Homebrew
  - Cria banco `hub_app_dev`
  - Aplica seeds automaticamente (opcional)
  - Cria `.env.local` com connection string
  - Testa conexão

- [ ] `scripts/setup-linux.sh` - apt/dnf + PostgreSQL (pendente)
- [ ] `scripts/setup-windows.sh` - WSL/Installer (pendente)
- [ ] `scripts/setup-database.js` - Node.js cross-platform (pendente)

**Seeds criados**:
- [x] `seeds/02-dev-tenants.sql` - 3 tenants de exemplo ✅
  - Startup Tech LTDA (11111111-...)
  - Comércio PME S/A (22222222-...)
  - Corporação Nacional (33333333-...)

- [x] `seeds/03-dev-users.sql` - 9 usuários (3 por tenant) ✅
  - 1 admin + 2 users por empresa
  - Senha padrão: `dev123` (bcrypt hash)
  - IDs fixos para facilitar testes
  - Vinculados com Auth.js accounts

- [x] `seeds/04-dev-financeiro.sql` - Dados do módulo Financeiro ✅
  - 7 categorias (3 receitas + 4 despesas)
  - 15 transações (últimos 3 meses)
  - Saldo: ~R$ 17.950,00
  - Tenant 1 (Startup)

- [ ] `seeds/01-schema-base.sql` - DDL do Hub.app (requer senha staging)
  - Script pronto (`update-schema-from-staging.sh`)
  - Aguardando execução manual (precisa senha do banco)

**Documentação criada**:
- [x] `seeds/README.md` - Guia completo de uso dos seeds ✅
- [x] `seeds/.gitignore` - Não versionar backups ✅

**Como usar agora** (Mac):
```bash
# Setup completo
bash scripts/setup-mac.sh

# Ou manual
createdb hub_app_dev
psql -d hub_app_dev -f seeds/02-dev-tenants.sql
psql -d hub_app_dev -f seeds/03-dev-users.sql
psql -d hub_app_dev -f seeds/04-dev-financeiro.sql
```

---

### **Fase 3: Sistema de Migrations** ⏸️ Pendente (1h)

**Objetivo**: Sistema tipo Git para versionamento de schema

**Comandos a implementar**:
- [ ] `migration-create.sh <name>` - Criar migration numerada
- [ ] `migration-status.sh` - Listar pendentes vs aplicadas
- [ ] `migration-up.sh [version]` - Aplicar migrations
- [ ] `migration-down.sh <version>` - Reverter migration
- [ ] `migration-to.sh <version>` - Ir para versão específica

**Tabela de controle**:
```sql
CREATE TABLE schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  applied_by VARCHAR(255),
  checksum VARCHAR(64)
);
```

---

### **Fase 4: App.tsx Funcional** ⏸️ Pendente (2h30min) 🔴 CRÍTICO

**Objetivo**: Template com CRUD **REAL** (não mockado)

**Problema atual**: Template gera apenas:
```tsx
// App.tsx atual (66 linhas) - MOCKUP
return (
  <div>
    <h1>Teste Template</h1>
    <p>Bem-vindo! Agora você pode começar a desenvolver.</p>
  </div>
);
```

**Meta**: Gerar template funcional (500+ linhas):
```tsx
// App.tsx funcional
- ItemList.tsx (listagem com paginação)
- ItemForm.tsx (criar/editar)
- useItems.ts (CRUD hooks)
- LoadingSpinner, EmptyState, ErrorBanner
- Integração com apiAdapter.ts
```

**Referência**: `packages/mod-financeiro/app/src/App.tsx` (1066 linhas)

---

### **Fase 5: Converter para Node.js** ⏸️ Pendente (2h)

**Objetivo**: Reescrever scripts Bash → Node.js (cross-platform)

**Conversões necessárias**:
- [ ] `scripts/create-module.sh` → `lib/create-module.js`
- [ ] `scripts/install-module.sh` → `lib/install-module.js`
- [ ] `scripts/setup-database.sh` → `lib/setup-database.js`

**CLI Entry Point** (`cli.js`):
```javascript
#!/usr/bin/env node
const { program } = require('commander');

program
  .command('create <slug> <title> <icon>')
  .action(require('./lib/create-module'));

program
  .command('install <slug>')
  .action(require('./lib/install-module'));

program.parse();
```

---

### **Fase 6: Context para Claude** ⏸️ Pendente (1h)

**Objetivo**: Documentação para Claude Code usar DevKit automaticamente

**Arquivos a criar**:
- [ ] `.context/agents/module-creator.md` - Como criar módulos
- [ ] `.context/agents/api-developer.md` - Como criar APIs
- [ ] `.context/agents/feature-developer.md` - Como adicionar features
- [ ] `.context/docs/module-patterns.md` - Padrões de módulos
- [ ] `.context/docs/api-patterns.md` - Padrões de API

**Exemplo de agent**:
```markdown
# .context/agents/module-creator.md

Quando o usuário pedir para criar um módulo:

1. Execute: npx @hub/devkit create <slug> "<title>" <icon>
2. Execute: npx @hub/devkit install <slug>
3. Execute: cd packages/mod-<slug> && npm run dev

Se houver PRD:
- Analise o PRD
- Use padrões de .context/docs/
- Customize componentes conforme PRD
```

---

### **Fase 7: Sincronização Hub↔DevKit** ⏸️ Pendente (2h) 🔴 CRÍTICO

**Objetivo**: Manter DevKit sempre compatível com Hub.app

**Comandos a implementar**:
- [ ] `hub-devkit sync-schema` - Atualiza schema SQL
- [ ] `hub-devkit sync-templates` - Atualiza API templates
- [ ] `hub-devkit sync-prisma` - Atualiza Prisma schema
- [ ] `hub-devkit check-compat` - Verifica compatibilidade
- [ ] `hub-devkit sync-all` - Executa todos acima

**Versionamento Acoplado**:

**Hub.app package.json**:
```json
{
  "version": "2.5.0",
  "devkit": {
    "min_version": "1.4.0",
    "max_version": "1.x.x"
  }
}
```

**DevKit package.json**:
```json
{
  "version": "1.4.0",
  "hubApp": {
    "min_version": "2.0.0",
    "max_version": "2.x.x"
  }
}
```

**Auto-check** em todo comando:
```javascript
// cli.js (antes de qualquer comando)
checkCompatibility().then(compatible => {
  if (!compatible) {
    console.log('⚠️  Executando sincronização automática...');
    await syncSchema();
    await syncTemplates();
  }
});
```

---

### **Fase 8: Sistema de Atualização** ⏸️ Pendente (1h30min)

**Objetivo**: Atualizar DevKit facilmente sem perder compatibilidade

**Comandos a implementar**:
- [ ] `hub-devkit update` - Atualiza para versão mais recente
- [ ] `hub-devkit rollback` - Volta para versão anterior
- [ ] `hub-devkit check-updates` - Verifica atualizações
- [ ] Auto-check background (1x/dia, cache 24h)

**Fluxo de update com breaking changes**:
```
$ hub-devkit update

⚠️  BREAKING CHANGES detectadas!

Mudanças nesta versão:
  ✨ Suporte para campos customizados
  ⚠️  API de criação mudou (--type obrigatório)
  🐛 Corrigido bug de nomes de tabela

Migration Guide:
  # ANTES (v1.x)
  hub-devkit create tasks "Tasks" ListTodo

  # DEPOIS (v2.x)
  hub-devkit create tasks "Tasks" ListTodo --type=crud

Deseja atualizar? (y/n):
```

---

### **Fase 9: Documentação** ⏸️ Pendente (1h)

**Documentos a criar**:
- [ ] `docs/DATABASE_SETUP.md` - Como configurar PostgreSQL
- [ ] `docs/MIGRATIONS.md` - Sistema de migrations
- [ ] `docs/DEPLOYMENT.md` - Deploy em produção
- [ ] `docs/UPDATE_GUIDE.md` - Como atualizar DevKit
- [ ] `docs/SYNC_GUIDE.md` - Sincronização com Hub.app
- [ ] `docs/COMPATIBILITY_MATRIX.md` - Matriz de versões
- [ ] Atualizar `README.md` (quick start)
- [ ] Atualizar `QUICK_START.md` (tutorial completo)

---

## 📊 **Progresso Total**

| Fase | Tempo | Status | Progresso |
|------|-------|--------|-----------|
| 1. Bugs críticos | 30min | ✅ | 100% |
| 2. Scripts setup | 1h30min | ✅ | 90% |
| 3. Migrations | 1h | ⏸️ | 0% |
| 4. App.tsx funcional | 2h30min | ⏸️ | 0% |
| 5. Node.js CLI | 2h | ⏸️ | 0% |
| 6. Context Claude | 1h | ⏸️ | 0% |
| 7. Sincronização | 2h | ⏸️ | 0% |
| 8. Atualização | 1h30min | ⏸️ | 0% |
| 9. Documentação | 1h | ⏸️ | 0% |
| **TOTAL** | **13h30min** | | **~15%** |

---

## 🏗️ **Arquitetura Final Planejada**

### **Distribuição**
- ✅ **Git Privado** + `npm link` (NÃO publicar no NPM público)
- ✅ **Comando global**: `hub-devkit`
- ✅ **Justificativa**: Seguro (não expõe Hub.app) + Grátis + Cross-platform

### **Estrutura de Diretórios**
```
hub-modules-devkit/
├── cli.js                    # Entry point
├── lib/
│   ├── create-module.js      # Node.js (não Bash)
│   ├── install-module.js
│   ├── setup-database.js
│   ├── sync-schema.js        # Fase 7
│   ├── check-compatibility.js
│   ├── update.js             # Fase 8
│   └── rollback.js
├── scripts/
│   ├── create-module.sh      # ✅ Corrigido (Fase 1)
│   ├── install-module.sh     # ✅ Corrigido (Fase 1)
│   └── migration-*.sh        # Fase 3
├── templates/
│   ├── App.functional.tsx    # Fase 4 (500+ linhas)
│   ├── ItemList.tsx
│   ├── ItemForm.tsx
│   └── api-route.template.ts
├── seeds/
│   ├── 01-schema-base.sql    # Fase 2
│   ├── 02-dev-tenants.sql
│   └── 03-dev-users.sql
├── .context/                 # Fase 6
│   ├── agents/
│   └── docs/
├── docs/
│   ├── DEVKIT_PLANNING.md    # ✅ Completo (1100 linhas)
│   ├── UPDATE_SYSTEM.md      # ✅ Completo (500 linhas)
│   └── SYNC_STRATEGY.md      # ✅ Completo (650 linhas)
└── package.json
```

---

## 🚀 **Como Usar (Estado Atual)**

### **Setup Desenvolvedor**
```bash
# 1. Clone
git clone git@github.com:e4labs-bcm/hub-modules-devkit.git
cd hub-modules-devkit

# 2. Instalar dependências
npm install

# 3. Criar link global (opcional)
npm link

# 4. Usar
bash scripts/create-module.sh meu-modulo "Meu Módulo" Package
```

### **Criar Módulo (Scripts Bash atuais)**
```bash
cd /path/to/hub-modules-devkit

# Criar estrutura
bash scripts/create-module.sh tarefas "Tarefas" ListTodo

# Instalar no Hub.app (dentro do diretório hub-app-nextjs)
cd /path/to/hub-app-nextjs
bash /path/to/hub-modules-devkit/scripts/install-module.sh tarefas "Tarefas" ListTodo
```

---

## ⚠️ **Limitações Conhecidas (Estado Atual)**

1. **App.tsx é mockup** - Não tem CRUD funcional
2. **Sem setup de database** - Desenvolvedor precisa configurar manualmente
3. **Scripts Bash apenas** - Não funciona nativamente no Windows
4. **Sem sincronização** - DevKit pode ficar desatualizado com Hub.app
5. **Sem sistema de atualização** - Precisa git pull manual

---

## 📚 **Documentação Completa**

### **Planejamento** (já criado)
- ✅ `docs/DEVKIT_PLANNING.md` - Planejamento completo (1100 linhas)
- ✅ `docs/UPDATE_SYSTEM.md` - Sistema de atualização (500 linhas)
- ✅ `docs/SYNC_STRATEGY.md` - Sincronização Hub↔DevKit (650 linhas)

### **Guias de Uso** (já existentes)
- ✅ `README.md` - Visão geral e quick start
- ✅ `QUICK_START.md` - Tutorial completo
- ✅ `INSTALL.md` - Instalação detalhada
- ✅ `SUMMARY.md` - Resumo do projeto
- ✅ `CONTRIBUTING.md` - Como contribuir

### **A Criar** (Fase 9)
- [ ] `docs/DATABASE_SETUP.md`
- [ ] `docs/MIGRATIONS.md`
- [ ] `docs/DEPLOYMENT.md`
- [ ] `docs/SYNC_GUIDE.md`
- [ ] `docs/COMPATIBILITY_MATRIX.md`

---

## 🔧 **Decisões Arquiteturais Importantes**

### **1. Distribuição: Git + npm link (NÃO NPM público)**
**Decisão**: Não publicar no NPM público por segurança
**Razão**: Evitar expor arquitetura do Hub.app
**Alternativa rejeitada**: NPM private ($7/mês por usuário)

### **2. Cross-platform: Node.js puro (NÃO Bash)**
**Decisão**: Reescrever todos scripts em Node.js
**Razão**: Funcionar em Mac, Linux e Windows
**Status**: Pendente (Fase 5)

### **3. Schema: Export manual do staging**
**Decisão**: Script `sync-schema` sob demanda
**Razão**: Controle total, evita automação perigosa
**Comando**: `hub-devkit sync-schema`

### **4. CI/CD: Minimalista**
**Decisão**: Só validação de sintaxe (não automação de migrations)
**Razão**: Migrations são muito sensíveis para automatizar
**Podemos adicionar**: Quando DevKit estiver maduro

### **5. Seeds: 3 tenants, 9 users, Financeiro**
**Decisão**: Dados realistas mas leves
**Razão**: Testa multi-tenancy sem ser pesado
**Estrutura**:
- Tenant A, B, C (3 empresas)
- 1 admin + 2 users por tenant (9 total)
- Módulo Financeiro pré-instalado (exemplo completo)

---

## 🎯 **Próximas Ações Recomendadas**

### **Ordem de Prioridade**:

**🔴 Alta Prioridade** (essencial para produção):
1. **Fase 4** - App.tsx funcional (CRUD real)
2. **Fase 7** - Sincronização Hub↔DevKit
3. **Fase 2** - Scripts de setup nativos

**🟡 Média Prioridade** (melhora experiência):
4. **Fase 5** - Converter para Node.js
5. **Fase 8** - Sistema de atualização
6. **Fase 3** - Sistema de migrations

**🟢 Baixa Prioridade** (pode esperar):
7. **Fase 6** - Context para Claude
8. **Fase 9** - Documentação adicional

---

## 🧪 **Testes Pendentes**

### **End-to-End (após Fase 1)**
- [ ] Criar módulo com hífen: `teste-bugfix`
- [ ] Verificar SQL gerado (underscore correto)
- [ ] Instalar no Hub.app
- [ ] Verificar API routes criadas
- [ ] Verificar Prisma schema atualizado
- [ ] Testar compilação do Next.js

### **Compatibilidade (após Fase 7)**
- [ ] Hub.app v2.0 + DevKit v1.0
- [ ] Hub.app v2.5 + DevKit v1.0 (deve avisar desatualizado)
- [ ] Hub.app v2.5 + DevKit v1.4 (deve funcionar)

---

## 📞 **Contato & Links**

- **Repositório**: https://github.com/e4labs-bcm/hub-modules-devkit
- **Hub.app (main)**: https://github.com/e4labs-bcm/hub-app-nextjs
- **Issues**: https://github.com/e4labs-bcm/hub-modules-devkit/issues

---

## 🔄 **Histórico de Commits Importantes**

- `9693f89` - feat: Scripts de Setup Nativos (Fase 2 - 90%) ✅ (13/11/2025)
- `a8ec27f` - docs: Criar CLAUDE.md completo do projeto (13/11/2025)
- `b194d01` - fix: Corrigir 3 bugs críticos (Fase 1) ✅ (13/11/2025)
- `3d0b8fd` - docs: Sistema de sincronização Hub↔DevKit (13/11/2025)
- `f5dcdbf` - docs: Sistema de atualização completo (13/11/2025)
- `c7b45ff` - docs: Planejamento finalizado (13/11/2025)

---

**Última Atualização**: 13/11/2025 - 11:00 UTC
**Próxima Fase**: Fase 3 (Migrations) ou Fase 4 (App.tsx Funcional - CRÍTICO)
**Progresso**: 15% completo (Fases 1-2 / 9)
