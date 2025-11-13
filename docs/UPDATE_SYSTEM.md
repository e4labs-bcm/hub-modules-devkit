# Sistema de Atualização do DevKit

**Status**: Planejado (será implementado na Fase 7)
**Complexidade**: Média
**Dependências**: Git, GitHub API, Node.js fs

---

## 🎯 Objetivo

Fornecer sistema completo de atualização do DevKit com:
- ✅ Verificação automática de updates
- ✅ Atualização com confirmação e preview
- ✅ Rollback para versões anteriores
- ✅ Notificações não invasivas
- ✅ Suporte a breaking changes

---

## 📦 Comandos Disponíveis

### 1. `hub-devkit update`

Atualiza o DevKit para a versão mais recente.

**Fluxo:**
```
$ hub-devkit update

🔍 Verificando atualizações...
📦 Nova versão disponível: v2.0.0 (atual: v1.1.0)

⚠️  BREAKING CHANGES detectadas!

Mudanças nesta versão:
─────────────────────────────────────────────
✨ Features:
  - Suporte para campos customizados
  - Validação automática de schema SQL

⚠️  Breaking Changes:
  - Comando 'create' agora requer flag --type
  - Migration SQL agora é auto-gerada

🐛 Bug Fixes:
  - Corrigido nome de tabelas com hífens

📖 Guia de Migração:
  # ANTES (v1.x)
  hub-devkit create tasks "Tasks" ListTodo

  # DEPOIS (v2.x)
  hub-devkit create tasks "Tasks" ListTodo --type=crud

─────────────────────────────────────────────

Deseja atualizar? (y/n): y

⏳ Atualizando...
✅ DevKit atualizado para v2.0.0!

💡 Dica: Se algo quebrar, execute: hub-devkit rollback
```

**Implementação:**
```javascript
// lib/update.js
const { Octokit } = require('@octokit/rest');
const semver = require('semver');
const chalk = require('chalk');
const inquirer = require('inquirer');
const { execSync } = require('child_process');

async function update() {
  const currentVersion = require('../package.json').version;

  // 1. Fetch latest release
  const octokit = new Octokit();
  const { data: release } = await octokit.repos.getLatestRelease({
    owner: 'e4labs-bcm',
    repo: 'hub-modules-devkit'
  });

  const latestVersion = release.tag_name.replace('v', '');

  // 2. Compare versions
  if (semver.eq(currentVersion, latestVersion)) {
    console.log(chalk.green('✅ Você já está na versão mais recente!'));
    return;
  }

  // 3. Check if breaking change
  const isBreaking = semver.major(latestVersion) > semver.major(currentVersion);

  if (isBreaking) {
    console.log(chalk.yellow('\n⚠️  BREAKING CHANGES detectadas!\n'));
  }

  // 4. Show changelog
  console.log(chalk.cyan('Mudanças nesta versão:'));
  console.log('─'.repeat(60));
  console.log(release.body);
  console.log('─'.repeat(60));

  // 5. Ask confirmation
  const { confirm } = await inquirer.prompt([{
    type: 'confirm',
    name: 'confirm',
    message: 'Deseja atualizar?',
    default: true
  }]);

  if (!confirm) {
    console.log('❌ Atualização cancelada.');
    return;
  }

  // 6. Git pull
  try {
    console.log(chalk.blue('\n⏳ Atualizando...'));
    execSync('git pull origin main', { stdio: 'inherit' });
    console.log(chalk.green(`\n✅ DevKit atualizado para v${latestVersion}!`));
    console.log(chalk.gray('\n💡 Dica: Se algo quebrar, execute: hub-devkit rollback'));
  } catch (error) {
    console.error(chalk.red('❌ Erro ao atualizar:'), error.message);
    process.exit(1);
  }
}

module.exports = { update };
```

---

### 2. `hub-devkit rollback`

Volta para uma versão anterior específica.

**Fluxo:**
```
$ hub-devkit rollback

🕐 Versão atual: v2.0.0

📦 Versões disponíveis:
  1. v1.1.0 (2025-11-15) - Última estável antes da v2.0
  2. v1.0.0 (2025-11-13) - Release inicial
  3. v0.9.0 (2025-11-10) - Beta

Escolha a versão (1-3): 1

⚠️  Você será movido para "detached HEAD" (versão fixa)
    Para voltar para a versão mais recente: git checkout main

Confirma rollback para v1.1.0? (y/n): y

⏳ Fazendo rollback...
✅ Rollback concluído! Você está em v1.1.0

💡 Para voltar ao latest: hub-devkit update
```

**Implementação:**
```javascript
// lib/rollback.js
const { execSync } = require('child_process');
const chalk = require('chalk');
const inquirer = require('inquirer');

async function rollback() {
  // 1. Get current version
  const currentBranch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf-8' }).trim();
  const currentVersion = require('../package.json').version;

  console.log(chalk.blue(`🕐 Versão atual: v${currentVersion}`));

  // 2. List available versions (git tags)
  const tagsOutput = execSync('git tag -l --sort=-v:refname', { encoding: 'utf-8' });
  const tags = tagsOutput.trim().split('\n').slice(0, 5); // Últimas 5

  if (tags.length === 0) {
    console.log(chalk.red('❌ Nenhuma versão anterior encontrada.'));
    return;
  }

  // 3. Get tag dates
  const choices = tags.map((tag, index) => {
    const date = execSync(`git log -1 --format=%ai ${tag}`, { encoding: 'utf-8' }).trim().split(' ')[0];
    const message = execSync(`git tag -l --format="%(contents:subject)" ${tag}`, { encoding: 'utf-8' }).trim();
    return {
      name: `${tag} (${date}) - ${message}`,
      value: tag,
      short: tag
    };
  });

  console.log(chalk.cyan('\n📦 Versões disponíveis:'));

  // 4. Ask which version
  const { selectedVersion } = await inquirer.prompt([{
    type: 'list',
    name: 'selectedVersion',
    message: 'Escolha a versão:',
    choices
  }]);

  // 5. Warning about detached HEAD
  console.log(chalk.yellow('\n⚠️  Você será movido para "detached HEAD" (versão fixa)'));
  console.log(chalk.gray('    Para voltar para a versão mais recente: git checkout main\n'));

  // 6. Confirm
  const { confirm } = await inquirer.prompt([{
    type: 'confirm',
    name: 'confirm',
    message: `Confirma rollback para ${selectedVersion}?`,
    default: false
  }]);

  if (!confirm) {
    console.log('❌ Rollback cancelado.');
    return;
  }

  // 7. Checkout
  try {
    console.log(chalk.blue('\n⏳ Fazendo rollback...'));
    execSync(`git checkout ${selectedVersion}`, { stdio: 'inherit' });
    console.log(chalk.green(`\n✅ Rollback concluído! Você está em ${selectedVersion}`));
    console.log(chalk.gray('\n💡 Para voltar ao latest: hub-devkit update'));
  } catch (error) {
    console.error(chalk.red('❌ Erro ao fazer rollback:'), error.message);
    process.exit(1);
  }
}

module.exports = { rollback };
```

---

### 3. `hub-devkit check-updates`

Verifica se há atualizações disponíveis (sem instalar).

**Fluxo:**
```
$ hub-devkit check-updates

🔍 Verificando atualizações...

📦 Nova versão disponível!

  Atual:  v1.1.0
  Latest: v2.0.0

  Tipo: MAJOR (Breaking Changes)

  Changelog:
  - ✨ Suporte para campos customizados
  - ⚠️  API de criação foi alterada
  - 🐛 Corrigido bug de nomes de tabela

Para atualizar: hub-devkit update
Para mais detalhes: https://github.com/e4labs-bcm/hub-modules-devkit/releases/tag/v2.0.0
```

**Implementação:**
```javascript
// lib/check-updates.js
const { Octokit } = require('@octokit/rest');
const semver = require('semver');
const chalk = require('chalk');

async function checkUpdates(silent = false) {
  const currentVersion = require('../package.json').version;

  try {
    const octokit = new Octokit();
    const { data: release } = await octokit.repos.getLatestRelease({
      owner: 'e4labs-bcm',
      repo: 'hub-modules-devkit'
    });

    const latestVersion = release.tag_name.replace('v', '');

    if (semver.eq(currentVersion, latestVersion)) {
      if (!silent) {
        console.log(chalk.green('✅ Você já está na versão mais recente!'));
      }
      return false;
    }

    if (!silent) {
      console.log(chalk.cyan('\n📦 Nova versão disponível!\n'));
      console.log(`  Atual:  v${currentVersion}`);
      console.log(`  Latest: v${latestVersion}\n`);

      // Determine update type
      const diff = semver.diff(currentVersion, latestVersion);
      const typeLabel = {
        major: chalk.red('MAJOR (Breaking Changes)'),
        minor: chalk.yellow('MINOR (New Features)'),
        patch: chalk.green('PATCH (Bug Fixes)')
      }[diff];

      console.log(`  Tipo: ${typeLabel}\n`);

      // Show brief changelog (first 3 lines)
      const briefChangelog = release.body.split('\n').slice(0, 3).join('\n');
      console.log('  Changelog:');
      console.log(`  ${briefChangelog}\n`);

      console.log(chalk.blue('Para atualizar: hub-devkit update'));
      console.log(chalk.gray(`Para mais detalhes: ${release.html_url}`));
    }

    return true;
  } catch (error) {
    // Fail silently (offline, rate limit, etc)
    if (!silent) {
      console.log(chalk.gray('⚠️  Não foi possível verificar atualizações (offline?)'));
    }
    return false;
  }
}

// Auto-check (non-blocking, silent)
async function autoCheckUpdates() {
  // Cache check (only once per day)
  const cacheFile = require('path').join(__dirname, '../.update-check-cache');
  const fs = require('fs');

  if (fs.existsSync(cacheFile)) {
    const lastCheck = parseInt(fs.readFileSync(cacheFile, 'utf-8'));
    const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);

    if (lastCheck > oneDayAgo) {
      return false; // Already checked today
    }
  }

  const hasUpdate = await checkUpdates(true);

  // Update cache
  fs.writeFileSync(cacheFile, Date.now().toString());

  return hasUpdate;
}

module.exports = { checkUpdates, autoCheckUpdates };
```

---

### 4. Auto-check (Background)

Executa automaticamente ao rodar **qualquer comando** do DevKit.

**Comportamento:**
- ✅ Não bloqueia execução do comando
- ✅ Cache de 24 horas (só checa 1x por dia)
- ✅ Notificação discreta no final
- ✅ Fail silently se offline

**Exemplo:**
```
$ hub-devkit create tasks "Tasks" ListTodo

✅ Módulo 'tasks' criado com sucesso!
📁 Localização: packages/mod-tasks/

ℹ️  Nova versão v2.0.0 disponível. Execute: hub-devkit update
```

**Implementação:**
```javascript
// cli.js
#!/usr/bin/env node

const { program } = require('commander');
const { autoCheckUpdates } = require('./lib/check-updates');
const chalk = require('chalk');

// Auto-check for updates (non-blocking)
setImmediate(async () => {
  const hasUpdate = await autoCheckUpdates();
  if (hasUpdate) {
    console.log(chalk.blue('\nℹ️  Nova versão disponível. Execute: hub-devkit update\n'));
  }
});

// Regular commands
program
  .command('create <slug> <title> <icon>')
  .action(require('./lib/create-module'));

program
  .command('update')
  .description('Atualizar DevKit para versão mais recente')
  .action(require('./lib/update').update);

program
  .command('rollback')
  .description('Voltar para versão anterior')
  .action(require('./lib/rollback').rollback);

program
  .command('check-updates')
  .description('Verificar se há atualizações disponíveis')
  .action(() => require('./lib/check-updates').checkUpdates(false));

program.parse();
```

---

## 📋 CHANGELOG.md Format

```markdown
# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]

## [2.0.0] - 2025-11-20 ⚠️ BREAKING CHANGES

### ⚠️ Breaking Changes
- Comando `create` agora requer flag `--type` obrigatória
- Migration SQL agora é gerada automaticamente (não manual)
- Estrutura de diretórios mudou: `app/components/` → `app/src/components/`

### 🔄 Migration Guide

#### Criação de Módulos
```bash
# ❌ ANTES (v1.x)
hub-devkit create tasks "Tasks" ListTodo

# ✅ DEPOIS (v2.x)
hub-devkit create tasks "Tasks" ListTodo --type=crud
```

#### Estrutura de Arquivos
```bash
# Mover componentes:
mv app/components/* app/src/components/
```

### ✨ Features
- Suporte para campos customizados em módulos
- Validação automática de schema SQL
- Geração automática de tipos TypeScript

### 🐛 Bug Fixes
- Corrigido nome de tabelas com hífens (tasks-items → tasks_items)
- Corrigido API routes não sendo criadas
- Corrigido Prisma schema não sendo atualizado

### 📚 Documentation
- Adicionado guia completo de atualização
- Melhorado README com exemplos práticos

## [1.1.0] - 2025-11-15

### ✨ Features
- Comando `hub-devkit check-updates` para verificar atualizações
- Sistema de rollback para versões anteriores
- Auto-check de updates ao executar comandos

### 🐛 Bug Fixes
- Corrigido instalação em Windows (WSL)

## [1.0.0] - 2025-11-13

### 🎉 Initial Release
- Comando `create` para criar módulos
- Comando `install` para instalar no Hub.app
- Templates funcionais com CRUD completo
- Sistema de migrations
- Documentação completa
```

---

## 🔧 Dependências Necessárias

```json
{
  "dependencies": {
    "@octokit/rest": "^20.0.0",
    "semver": "^7.5.4",
    "inquirer": "^9.2.0",
    "chalk": "^5.3.0",
    "ora": "^7.0.0"
  }
}
```

---

## 🧪 Testes

### Cenários de Teste

1. **Update disponível (patch)**
   - Current: v1.0.0
   - Latest: v1.0.1
   - Espera: Notificação verde, atualização sem warnings

2. **Update disponível (minor)**
   - Current: v1.0.0
   - Latest: v1.1.0
   - Espera: Notificação amarela, changelog de features

3. **Update disponível (major) ⚠️**
   - Current: v1.1.0
   - Latest: v2.0.0
   - Espera: Warning de breaking changes, migration guide

4. **Rollback para versão antiga**
   - Current: v2.0.0
   - Rollback: v1.1.0
   - Espera: Detached HEAD warning, sucesso

5. **Check-updates offline**
   - Sem internet
   - Espera: Fail silently, não quebra comando

---

## 📊 Métricas

- **Frequência de check**: 1x por dia (cache)
- **Timeout de API**: 5 segundos
- **Retry**: 0 (fail silently)
- **Rate limit**: GitHub API (60 req/hora sem auth, 5000 com auth)

---

## 🚀 Implementação Futura (v3.0)

- [ ] Backup automático antes de update
- [ ] Diff visual de mudanças
- [ ] Suporte a canais (stable, beta, nightly)
- [ ] Update de módulos criados (não só DevKit)
- [ ] Notificações por email/Slack

---

**Criado em**: 13/11/2025
**Status**: Planejado (Fase 7)
