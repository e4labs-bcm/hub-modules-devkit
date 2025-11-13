# Compatibility Matrix - Hub.app ↔ DevKit

**Última atualização**: 14/11/2025

Matriz de compatibilidade entre versões do Hub.app e Hub Modules DevKit.

---

## 📊 Versões Atuais

| Componente | Versão Atual | Status |
|------------|--------------|--------|
| Hub.app    | 0.1.0        | ✅ Stable |
| DevKit     | 0.1.0        | ✅ Stable |

---

## 🔄 Matriz de Compatibilidade

### DevKit 0.1.x

| DevKit | Hub.app Min | Hub.app Max | Status | Notas |
|--------|-------------|-------------|--------|-------|
| 0.1.0  | 0.1.0       | 0.x.x       | ✅ Stable | Initial release |

**Funcionalidades**:
- ✅ Criação de módulos CRUD básicos
- ✅ Sistema de migrations
- ✅ Sincronização de schema
- ✅ Sistema de atualização

**Limitações**:
- ⚠️ Templates não customizáveis via CLI
- ⚠️ Sem suporte a campos relacionais (foreign keys)

---

### DevKit 0.2.x (Planejado)

| DevKit | Hub.app Min | Hub.app Max | Status | Notas |
|--------|-------------|-------------|--------|-------|
| 0.2.0  | 0.1.0       | 0.x.x       | 🔜 Planned | Backward compatible |

**Novas Funcionalidades** (planejadas):
- ✨ Templates customizáveis via flags
- ✨ Comando `validate` para validar módulos
- ✨ Auto-complete para Bash/Zsh

**Breaking Changes**: Nenhum (minor version)

---

### DevKit 1.0.x (Planejado)

| DevKit | Hub.app Min | Hub.app Max | Status | Notas |
|--------|-------------|-------------|--------|-------|
| 1.0.0  | 1.0.0       | 1.x.x       | 🔜 Planned | ⚠️ Breaking changes |

**Breaking Changes** (planejados):
- ⚠️ Mudança na estrutura de templates
- ⚠️ Comando `create` requer flag `--type`
- ⚠️ Removido comando deprecated `init`

**Migration Guide**: TBD quando lançado

---

## 🔍 Como Verificar Compatibilidade

### Via CLI

```bash
# Verificar versão local
hubapp-devkit --version

# Verificar compatibilidade com Hub.app
npm run check:compat
```

### Via package.json

```json
{
  "hubApp": {
    "min_version": "0.1.0",
    "max_version": "0.x.x",
    "recommended_version": "0.1.0"
  }
}
```

---

## ⚠️ Avisos de Incompatibilidade

### Exemplo 1: DevKit Muito Antigo

```
❌ INCOMPATÍVEL!

DevKit versão:  0.1.0
Hub.app versão: 1.5.0

DevKit aceita:  Hub.app 0.1.0 - 0.x.x
Hub.app é:      1.5.0 (MAJOR incompatível)

Ação Recomendada:
  hubapp-devkit update
```

### Exemplo 2: Hub.app Muito Antigo

```
⚠️  WARNING!

DevKit versão:  1.2.0
Hub.app versão: 0.8.0

DevKit requer:  Hub.app 1.0.0+
Hub.app é:      0.8.0 (abaixo do mínimo)

Ação Recomendada:
  cd /path/to/hub-app-nextjs
  git pull origin main
  npm install
```

---

## 📋 Dependency Matrix

### Node.js

| DevKit | Node Min | Node Recommended |
|--------|----------|------------------|
| 0.1.x  | 18.0.0   | 20.x             |
| 1.0.x  | 18.0.0   | 22.x (planejado) |

### PostgreSQL

| DevKit | PostgreSQL Min | PostgreSQL Recommended |
|--------|----------------|------------------------|
| 0.1.x  | 14.0           | 16.x                   |
| 1.0.x  | 16.0           | 16.x                   |

### Prisma

| DevKit | Prisma Min | Prisma Max |
|--------|------------|------------|
| 0.1.x  | 5.0.0      | 6.x.x      |
| 1.0.x  | 6.0.0      | 7.x.x      |

---

## 🔄 Upgrade Paths

### De 0.1.x para 0.2.x

✅ **Sem breaking changes** - Upgrade direto:
```bash
hubapp-devkit update
```

### De 0.1.x para 1.0.x

⚠️ **Breaking changes** - Seguir migration guide:
```bash
# 1. Ler changelog
hubapp-devkit check-updates

# 2. Fazer backup
git add . && git commit -m "pre-v1.0 backup"

# 3. Atualizar
hubapp-devkit update

# 4. Seguir migration guide (será exibido)

# 5. Se falhar, rollback
hubapp-devkit rollback
```

---

## 📊 Release Timeline (Planejado)

| Versão | Data (Estimada) | Status | Tipo |
|--------|-----------------|--------|------|
| 0.1.0  | 2025-11-13      | ✅ Released | Initial |
| 0.2.0  | 2025-12-01      | 🔜 Planned | Minor |
| 1.0.0  | 2026-Q1         | 🔜 Planned | Major |

---

## 📚 Referências

- **CHANGELOG**: `CHANGELOG.md`
- **Update Guide**: `docs/UPDATE_GUIDE.md`
- **Sync Guide**: `docs/SYNC_GUIDE.md`

---

**Criado por**: Agatha Fiuza + Claude Code
**Versão**: 1.0.0
**Última Atualização**: 14/11/2025
