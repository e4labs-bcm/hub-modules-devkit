# Sync Guide - Hub.app ↔ DevKit

**Última atualização**: 14/11/2025

Guia sobre sincronização entre Hub.app e DevKit para manter compatibilidade e schemas atualizados.

---

## 🎯 Objetivo

Garantir que o **DevKit** esteja sempre compatível com o **Hub.app**, evitando:
- ❌ Módulos gerados incompatíveis
- ❌ Schemas desatualizados
- ❌ API routes quebradas
- ❌ Breaking changes sem aviso

---

## 🔄 Tipos de Sincronização

### 1. Schema Sync (Prisma Schema)

**O que é**: Copiar `schema.prisma` do Hub.app para DevKit como referência.

**Por quê**: Módulos precisam conhecer o schema do Hub para criar relações corretas.

**Como fazer**:
```bash
# Automático (detecta Hub.app)
npm run sync:schema

# Manual (especificar caminho)
bash scripts/sync-schema.sh /path/to/hub-app-nextjs
```

**Resultado**:
- ✅ Cria `docs/reference/hub-schema.prisma` com schema do Hub
- ✅ Atualiza `last_synced` em `package.json`
- ✅ Avisa se templates estão desatualizados

---

### 2. Version Check

**O que é**: Verificar se DevKit é compatível com versão do Hub.app.

**Como fazer**:
```bash
npm run check:compat

# Ou
bash scripts/check-compat.sh /path/to/hub-app-nextjs
```

**Saída**:
```
✓ Hub.app encontrado: /Users/.../hub-app-nextjs

==> Verificando versões...
  DevKit versão:   0.1.0
  Hub.app versão:  0.1.0
  Compatível:      SIM ✓

==> Última sincronização...
  Sincronizado em: 2025-11-13T19:02:36Z
  Há:              1 dia atrás
  Status:          ✓ OK

==> Arquivos de referência...
  ✓ hub-schema.prisma

╔════════════════════════════════════════╗
║  Resumo                                ║
╚════════════════════════════════════════╝

✅ DevKit compatível e atualizado!
```

---

## 📊 Versionamento Acoplado

### Hub.app vs DevKit

```json
{
  "hubApp": {
    "min_version": "0.1.0",
    "max_version": "0.x.x",
    "recommended_version": "0.1.0",
    "last_synced": "2025-11-13T19:02:36Z"
  }
}
```

**Regras**:
- ✅ **DevKit 0.1.x** funciona com **Hub.app 0.1.0 - 0.x.x**
- ⚠️ **DevKit 1.0.x** requer **Hub.app 1.0.0+** (breaking change)
- ❌ **DevKit 0.1.x** NÃO funciona com **Hub.app 1.0.0+**

---

## 🛠️ Workflows Comuns

### Workflow 1: Sincronizar Após Pull do Hub.app

```bash
# 1. Atualizar Hub.app
cd /path/to/hub-app-nextjs
git pull origin main

# 2. Sincronizar DevKit
cd /path/to/hub-modules-devkit
npm run sync:schema

# 3. Verificar compatibilidade
npm run check:compat
```

---

### Workflow 2: Criar Módulo com Schema Atualizado

```bash
# 1. Sincronizar primeiro
npm run sync:schema

# 2. Criar módulo
hubapp-devkit create tasks "Tasks" ListTodo

# 3. O módulo terá acesso ao schema atualizado
```

---

### Workflow 3: Verificar Desatualização (>7 dias)

```bash
npm run check:compat

# Se desatualizado:
# ⚠️  Última sincronização há 8 dias
#     Execute: npm run sync:schema
```

---

## ⚠️ Troubleshooting

### Problema: "Hub.app not found"

**Solução**:
```bash
# Especificar caminho manualmente
bash scripts/sync-schema.sh /path/to/hub-app-nextjs
```

---

### Problema: Versão incompatível

```
❌ INCOMPATÍVEL!
   DevKit: 0.1.0
   Hub.app: 1.5.0
   Ação: Atualize DevKit para 1.0.0+
```

**Solução**:
```bash
hubapp-devkit update
```

---

## 📚 Referências

- **Compatibilidade**: `docs/COMPATIBILITY_MATRIX.md`
- **Update Guide**: `docs/UPDATE_GUIDE.md`

---

**Criado por**: Agatha Fiuza + Claude Code
**Versão**: 1.0.0
**Última Atualização**: 14/11/2025
