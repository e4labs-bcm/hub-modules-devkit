# Update Guide - Hub Modules DevKit

**Última atualização**: 14/11/2025

Guia completo sobre como atualizar o Hub Modules DevKit para novas versões, fazer rollback quando necessário, e entender o sistema de versionamento.

---

## 🚀 Quick Start

### Verificar Atualizações

```bash
hubapp-devkit check-updates
```

### Atualizar para Versão Mais Recente

```bash
hubapp-devkit update
```

### Fazer Rollback

```bash
hubapp-devkit rollback
```

---

## 📦 Sistema de Versionamento

### Semântico (MAJOR.MINOR.PATCH)

O DevKit segue **Semantic Versioning 2.0.0**:

- **MAJOR** (`2.0.0`) - Breaking changes (incompatível com versão anterior)
- **MINOR** (`1.1.0`) - Novas features (compatível com versão anterior)
- **PATCH** (`1.0.1`) - Bug fixes (compatível com versão anterior)

### Exemplos

**Patch** (0.1.0 → 0.1.1):
- Correção de bug em migration script
- Typo em documentação
- Performance improvement sem mudança de API

**Minor** (0.1.0 → 0.2.0):
- Novo comando `hubapp-devkit validate`
- Novo template field opcional
- Nova feature no CLI sem quebrar comandos existentes

**Major** (0.9.0 → 1.0.0):
- Mudança na estrutura de comandos CLI
- Remoção de comandos deprecated
- Mudança na estrutura de templates gerados
- Mudança nos requisitos de versão do Hub.app

---

## 🔄 Fluxo de Atualização

### Passo 1: Verificar Atualizações

```bash
$ hubapp-devkit check-updates

🔍 Verificando atualizações...

📦 Nova versão disponível!

  Atual:  v0.1.0
  Latest: v0.2.0

  Tipo: MINOR (New Features)

  Changelog:
  - ✨ Novo comando `validate` para validar módulos
  - ✨ Suporte a templates customizáveis
  - 🐛 Corrigido bug em migration-status.sh

Para atualizar: hubapp-devkit update
Para mais detalhes: https://github.com/e4labs-bcm/hub-modules-devkit/releases/tag/v0.2.0
```

### Passo 2: Fazer Backup (Opcional mas Recomendado)

```bash
# Commit mudanças locais
git add .
git commit -m "WIP: antes de atualizar DevKit"

# Ou fazer stash
git stash
```

### Passo 3: Atualizar

```bash
$ hubapp-devkit update

🔍 Verificando atualizações...

📦 Nova versão disponível: v0.2.0 (atual: v0.1.0)

Mudanças nesta versão:
─────────────────────────────────────────────
## [0.2.0] - 2025-11-20

### ✨ Features
- Novo comando `hubapp-devkit validate`
- Suporte a templates customizáveis
- Auto-complete para Bash/Zsh

### 🐛 Bug Fixes
- Corrigido bug em migration-status.sh
- Corrigido encoding em Windows
─────────────────────────────────────────────

? Deseja atualizar? (y/N) y

⏳ Atualizando...

remote: Enumerating objects: 45, done.
remote: Counting objects: 100% (45/45), done.
Receiving objects: 100% (45/45), done.
Updating files: 100% (12/12), done.

📦 Reinstalando dependências...

up to date, audited 70 packages in 2s

✅ DevKit atualizado para v0.2.0!

💡 Dica: Se algo quebrar, execute: hubapp-devkit rollback
```

---

## ⚠️ Breaking Changes

### Como Identificar

Breaking changes são indicados por:
- ✅ Mudança de MAJOR version (1.0.0 → 2.0.0)
- ✅ Tag `⚠️  BREAKING CHANGES` no changelog
- ✅ Seção "Migration Guide" no changelog

### Exemplo de Breaking Change

```bash
$ hubapp-devkit update

📦 Nova versão disponível: v2.0.0 (atual: v1.5.0)

⚠️  BREAKING CHANGES detectadas!

Mudanças nesta versão:
─────────────────────────────────────────────
## [2.0.0] - Breaking Changes

### ⚠️ Breaking Changes
- Comando `create` agora requer flag `--type`
- Estrutura de diretórios mudou: `app/components/` → `app/src/components/`
- Removido comando deprecated `init` (use `create`)

### 🔄 Migration Guide

#### Comando create
# ANTES (v1.x)
hubapp-devkit create tasks "Tasks" ListTodo

# DEPOIS (v2.x)
hubapp-devkit create tasks "Tasks" ListTodo --type=crud

#### Estrutura de arquivos
# Mover componentes manualmente:
cd packages/mod-meu-modulo
mv app/components/* app/src/components/
rmdir app/components

### ✨ Features
- Suporte a campos customizados
- Validação automática de schema
─────────────────────────────────────────────

? Deseja atualizar? (y/N)
```

### Checklist Antes de Atualizar (Breaking Change)

- [ ] Ler changelog completo
- [ ] Ler migration guide
- [ ] Fazer backup (commit ou stash)
- [ ] Garantir que não há módulos em desenvolvimento crítico
- [ ] Reservar tempo para ajustar código (se necessário)
- [ ] Testar em ambiente de dev antes de prod

---

## 🔙 Rollback

### Quando Fazer Rollback?

- ❌ Atualização quebrou algo
- ❌ Nova versão tem bug crítico
- ❌ Incompatibilidade inesperada com Hub.app
- ❌ Precisa voltar temporariamente para versão estável

### Fluxo de Rollback

```bash
$ hubapp-devkit rollback

🕐 Versão atual: v0.2.0
   Branch: main

📦 Versões disponíveis:

? Escolha a versão para fazer rollback:
❯ v0.1.0 (2025-11-13) - Release inicial
  v0.0.9 (2025-11-10) - Beta release

⚠️  ATENÇÃO:
   Você será movido para "detached HEAD" (versão fixa).
   Para voltar à versão mais recente: git checkout main
   Para atualizar novamente: hubapp-devkit update

? Confirma rollback para v0.1.0? (y/N) y

⏳ Fazendo rollback...

HEAD is now at a1b2c3d Release v0.1.0

📦 Reinstalando dependências...

removed 5 packages, changed 3 packages in 1s

✅ Rollback concluído! Você está em v0.1.0

💡 Para voltar ao latest: hubapp-devkit update
💡 Para voltar ao branch main: git checkout main
```

### Após Rollback

```bash
# Verificar versão
hubapp-devkit --version
# v0.1.0

# Se quiser voltar para latest
hubapp-devkit update

# Se quiser continuar em v0.1.0
# Nada a fazer, você está em detached HEAD (versão fixa)
```

---

## 🔔 Auto-check de Atualizações

### Como Funciona?

O DevKit verifica atualizações automaticamente **1x por dia** quando você usa qualquer comando.

```bash
$ hubapp-devkit create tasks "Tasks" ListTodo

✅ Módulo 'tasks' criado com sucesso!

ℹ️  Nova versão disponível. Execute: hubapp-devkit update
```

### Características

- ✅ **Não bloqueante** - Não atrasa execução do comando
- ✅ **Cache 24h** - Só verifica 1x por dia
- ✅ **Fail silently** - Se offline, não mostra erro
- ✅ **Discreto** - Apenas notificação no final

### Desabilitar Auto-check (Não Recomendado)

```bash
# Remover cache (força check no próximo comando)
rm .update-check-cache

# Ou editar cli.js e comentar seção auto-check
vim cli.js
# Comentar linhas 130-144
```

---

## 📚 CHANGELOG

### Onde Encontrar?

```bash
# Local
cat CHANGELOG.md

# GitHub (todas as releases)
open https://github.com/e4labs-bcm/hub-modules-devkit/releases

# Específica
open https://github.com/e4labs-bcm/hub-modules-devkit/releases/tag/v0.2.0
```

### Formato

Seguimos **Keep a Changelog**:

```markdown
## [0.2.0] - 2025-11-20

### ✨ Features (Added)
- Novo comando X
- Novo template Y

### 🔄 Changed
- Melhorado performance de Z

### ⚠️ Deprecated
- Comando W será removido em v1.0.0

### ❌ Removed
- Removido comando deprecated K

### 🐛 Fixed
- Corrigido bug L
- Corrigido crash M

### 🔒 Security
- Atualizado dependência N para corrigir CVE-XXXX
```

---

## ⚠️ Troubleshooting

### Problema: "git pull failed"

**Causa**: Mudanças locais não commitadas

**Solução**:
```bash
# Ver o que mudou
git status

# Opção 1: Commit
git add .
git commit -m "WIP: mudanças locais"
hubapp-devkit update

# Opção 2: Stash
git stash
hubapp-devkit update
git stash pop

# Opção 3: Descartar
git reset --hard HEAD
hubapp-devkit update
```

---

### Problema: "npm install failed"

**Causa**: package-lock.json conflitando

**Solução**:
```bash
# Remover lock e node_modules
rm package-lock.json
rm -rf node_modules/

# Reinstalar
npm install

# Tentar update novamente
hubapp-devkit update
```

---

### Problema: Rollback não lista versões

**Causa**: Repositório sem tags (releases)

**Solução**:
```bash
# Baixar tags do remote
git fetch --tags

# Tentar novamente
hubapp-devkit rollback
```

---

### Problema: "não foi possível verificar atualizações"

**Causa**: Sem internet ou rate limit GitHub

**Solução**:
```bash
# Verificar internet
ping github.com

# Verificar rate limit
curl https://api.github.com/rate_limit

# Aguardar e tentar novamente
hubapp-devkit check-updates
```

---

## 🎯 Best Practices

### 1. Sempre Verificar Antes de Atualizar

```bash
# ❌ NÃO faça blind update
hubapp-devkit update -y

# ✅ Sempre leia changelog primeiro
hubapp-devkit check-updates
# Ler changelog...
hubapp-devkit update
```

### 2. Testar em Dev Antes de Prod

```bash
# Dev machine
hubapp-devkit update
# Testar módulos...

# Se tudo OK, atualizar produção
ssh prod
hubapp-devkit update
```

### 3. Commit Antes de Atualizar

```bash
git add .
git commit -m "WIP: antes de atualizar DevKit para v0.2.0"
hubapp-devkit update
```

### 4. Ler Migration Guides Completamente

Para breaking changes, **sempre** leia o migration guide antes de atualizar.

---

## 📊 Compatibilidade Hub.app ↔ DevKit

| DevKit | Hub.app Min | Hub.app Max | Notas |
|--------|-------------|-------------|-------|
| 0.1.x  | 0.1.0       | 0.x.x       | Initial release |
| 0.2.x  | 0.1.0       | 0.x.x       | Backward compatible |
| 1.0.x  | 1.0.0       | 1.x.x       | Breaking changes |

Para detalhes completos, veja `docs/COMPATIBILITY_MATRIX.md`.

---

**Criado por**: Agatha Fiuza + Claude Code
**Filosofia**: "Make it right, make it work, make it fast"
**Versão**: 1.0.0
**Última Atualização**: 14/11/2025
