# Migrations Guide - Hub Modules DevKit

**Última atualização**: 14/11/2025

Sistema de migrations tipo Git para versionamento de schema do PostgreSQL. Permite criar, aplicar e fazer rollback de mudanças no banco de dados de forma controlada e rastreável.

---

## 📋 Conceitos

### O que são Migrations?

Migrations são **arquivos SQL versionados** que descrevem mudanças incrementais no schema do banco de dados. Cada migration tem:

- **Versão** - Número sequencial (001, 002, 003...)
- **Descrição** - O que a migration faz
- **UP** - Como aplicar a mudança
- **DOWN** - Como reverter a mudança
- **Metadata** - Timestamp, checksum, tempo de execução

### Por que usar Migrations?

✅ **Versionamento** - Schema evolui junto com código (Git)
✅ **Reprodutível** - Mesmo schema em dev, staging e prod
✅ **Rastreável** - Quem aplicou, quando, quanto tempo levou
✅ **Reversível** - Rollback seguro com validação
✅ **Time** - Evita conflitos entre desenvolvedores

---

## 🚀 Quick Start

### Criar Migration

```bash
# Criar nova migration
bash scripts/migration-create.sh "add user avatar field"

# Arquivo gerado: migrations/001_add_user_avatar_field.sql
```

### Ver Status

```bash
# Ver quais migrations foram aplicadas
bash scripts/migration-status.sh

# Saída:
# ✓ 001_create_users_table.sql (aplicada em 2025-11-13 10:30:00)
# ✓ 002_add_user_email.sql (aplicada em 2025-11-13 11:15:00)
# ✗ 003_add_user_avatar_field.sql (pendente)
```

### Aplicar Migrations Pendentes

```bash
# Aplicar todas as pendentes
bash scripts/migration-up.sh

# Ou aplicar específica (requer edição do script)
# bash scripts/migration-up.sh 003
```

### Fazer Rollback

```bash
# Reverter última migration
bash scripts/migration-down.sh 003

# ⚠️ ATENÇÃO: Pode causar PERDA DE DADOS!
# Confirmação explícita requerida
```

---

## 📂 Estrutura de Arquivos

```
hub-modules-devkit/
├── migrations/
│   ├── 000_create_migrations_table.sql  # Sistema de controle
│   ├── 001_add_user_avatar.sql          # Sua migration
│   ├── 002_add_posts_table.sql
│   └── 003_add_comments_table.sql
└── scripts/
    ├── migration-create.sh              # Criar migration
    ├── migration-status.sh              # Ver status
    ├── migration-up.sh                  # Aplicar
    └── migration-down.sh                # Rollback
```

---

## ✍️ Anatomia de uma Migration

### Template Gerado

```sql
-- ============================================================
-- Migration: 001_add_user_avatar_field
-- Description: Adiciona campo avatar aos usuários
-- Version: 001
-- Created: 2025-11-14 00:30:00 UTC
-- ============================================================

-- ============================================================
-- UP - Aplica as mudanças
-- ============================================================

-- ADICIONE SEU SQL AQUI
-- Exemplo:
-- ALTER TABLE users ADD COLUMN avatar_url TEXT;
-- CREATE INDEX idx_users_avatar ON users(avatar_url);


-- ============================================================
-- DOWN - Reverte as mudanças (para rollback)
-- ============================================================

-- ADICIONE SEU SQL DE ROLLBACK AQUI
-- Exemplo:
-- DROP INDEX IF EXISTS idx_users_avatar;
-- ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;


-- ============================================================
-- Metadata (não modificar)
-- ============================================================
-- Checksum: [será calculado ao aplicar]
-- Applied: [será preenchido ao aplicar]
-- Execution time: [será medido ao aplicar]
```

### Preenchendo a Migration

```sql
-- ============================================================
-- UP - Aplica as mudanças
-- ============================================================

ALTER TABLE users ADD COLUMN avatar_url TEXT;
CREATE INDEX idx_users_avatar ON users(avatar_url);

COMMENT ON COLUMN users.avatar_url IS 'URL do avatar do usuário';

-- ============================================================
-- DOWN - Reverte as mudanças (para rollback)
-- ============================================================

DROP INDEX IF EXISTS idx_users_avatar;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
```

---

## 📝 Boas Práticas

### Nomenclatura

✅ **CORRETO**:
```bash
bash scripts/migration-create.sh "add user avatar field"
# Gera: 001_add_user_avatar_field.sql

bash scripts/migration-create.sh "create posts table"
# Gera: 002_create_posts_table.sql
```

❌ **EVITAR**:
```bash
# Muito genérico
bash scripts/migration-create.sh "update"

# Muito longo
bash scripts/migration-create.sh "adicionar campo avatar url no perfil dos usuarios para permitir upload de imagens"

# Com caracteres especiais
bash scripts/migration-create.sh "add user's avatar (optional)"
```

### UP e DOWN Simétricos

✅ **CORRETO** - UP e DOWN são opostos:
```sql
-- UP
ALTER TABLE users ADD COLUMN age INTEGER;

-- DOWN
ALTER TABLE users DROP COLUMN age;
```

❌ **ERRADO** - DOWN não reverte completamente:
```sql
-- UP
ALTER TABLE users ADD COLUMN age INTEGER DEFAULT 18;
CREATE INDEX idx_users_age ON users(age);

-- DOWN
ALTER TABLE users DROP COLUMN age;
-- ❌ Faltou: DROP INDEX idx_users_age;
```

### Dados vs Schema

✅ **Schema** - Ideal para migrations:
```sql
CREATE TABLE posts (...);
ALTER TABLE users ADD COLUMN ...;
CREATE INDEX ...;
```

❌ **Dados** - Evitar em migrations (use seeds):
```sql
-- ❌ NÃO faça isso em migrations
INSERT INTO users VALUES (...);
UPDATE settings SET value = 'foo';
```

**Exceções** (aceitáveis em migrations):
- Migração de dados (transformação, não inserção)
- Valores padrão obrigatórios
- Dados de sistema (não de negócio)

### Testes Antes de Aplicar

```bash
# 1. Criar migration
bash scripts/migration-create.sh "add avatar field"

# 2. Editar e preencher
vim migrations/001_add_avatar_field.sql

# 3. Testar UP em dev local
psql -U hub_app_user -d hub_app_dev -f migrations/001_add_avatar_field.sql

# 4. Verificar que funcionou
psql -U hub_app_user -d hub_app_dev -c "\d users"

# 5. Testar DOWN (rollback)
psql -U hub_app_user -d hub_app_dev -c "
  DROP INDEX IF EXISTS idx_users_avatar;
  ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
"

# 6. Se tudo OK, aplicar via migration-up.sh
bash scripts/migration-up.sh
```

### Multi-Tenancy

✅ **Sempre considere RLS**:
```sql
-- UP
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY posts_tenant_isolation ON posts
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Index para performance
CREATE INDEX idx_posts_tenant ON posts(tenant_id);
```

---

## 🔧 Comandos Detalhados

### migration-create.sh

**Uso**:
```bash
bash scripts/migration-create.sh "description here"
```

**O que faz**:
1. Determina próximo número (001, 002, 003...)
2. Sanitiza descrição (espaços → underscores)
3. Gera arquivo `migrations/NNN_description.sql`
4. Preenche template com metadata
5. Abre no editor (se $EDITOR configurado)

**Saída**:
```
✓ Migration criada: migrations/003_add_avatar_field.sql
→ Edite o arquivo e adicione o SQL nas seções UP e DOWN
→ Quando pronto, execute: bash scripts/migration-up.sh
```

---

### migration-status.sh

**Uso**:
```bash
bash scripts/migration-status.sh
```

**O que faz**:
1. Conecta ao banco via DATABASE_URL
2. Consulta tabela `schema_migrations`
3. Compara com arquivos em `migrations/`
4. Mostra tabela formatada

**Saída**:
```
╔════════════════════════════════════════════════════════╗
║  Schema Migrations Status                              ║
╚════════════════════════════════════════════════════════╝

✓ 001_create_users_table.sql
  Aplicada em: 2025-11-13 10:30:00 UTC
  Por: agatha
  Tempo: 45ms

✓ 002_add_user_email.sql
  Aplicada em: 2025-11-13 11:15:00 UTC
  Por: agatha
  Tempo: 12ms

✗ 003_add_avatar_field.sql
  Status: PENDENTE
  Ação: Execute 'bash scripts/migration-up.sh'

═══════════════════════════════════════════════════════
Última migration aplicada: 002 (2025-11-13 11:15:00)
Migrations pendentes: 1
```

---

### migration-up.sh

**Uso**:
```bash
bash scripts/migration-up.sh
```

**O que faz**:
1. Conecta ao banco via DATABASE_URL
2. Cria tabela `schema_migrations` se não existir
3. Lista migrations pendentes
4. Para cada pendente:
   - Extrai seção UP
   - Calcula checksum MD5
   - Mede tempo de execução
   - Aplica SQL
   - Registra em `schema_migrations`
5. Para se alguma migration falhar

**Saída**:
```
╔════════════════════════════════════════════════════════╗
║  Applying Migrations                                   ║
╚════════════════════════════════════════════════════════╝

Migrations pendentes: 1

  003_add_avatar_field.sql

Deseja aplicar? (y/n): y

⏳ Aplicando 003_add_avatar_field.sql...
✓ Aplicada com sucesso (32ms)

╔════════════════════════════════════════════════════════╗
║  Resumo                                                ║
╚════════════════════════════════════════════════════════╝

✓ 1 migration aplicada
✗ 0 falhas
⏱  Tempo total: 32ms
```

---

### migration-down.sh

**Uso**:
```bash
bash scripts/migration-down.sh 003
```

**O que faz**:
1. Valida que migration existe
2. Extrai seção DOWN
3. **AVISO DE SEGURANÇA** - Pode perder dados
4. Pede confirmação explícita (digite "ROLLBACK")
5. Executa SQL da seção DOWN
6. Remove registro de `schema_migrations`

**Saída**:
```
╔════════════════════════════════════════════════════════╗
║  ⚠️  ROLLBACK MIGRATION                                ║
╚════════════════════════════════════════════════════════╝

Migration: 003_add_avatar_field.sql

⚠️  ATENÇÃO: Rollback pode causar PERDA DE DADOS!

Preview do SQL que será executado:
─────────────────────────────────────────────────────────
DROP INDEX IF EXISTS idx_users_avatar;
ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
─────────────────────────────────────────────────────────

Para confirmar, digite "ROLLBACK" (maiúsculas): ROLLBACK

⏳ Executando rollback...
✓ Rollback concluído (15ms)
✓ Registro removido de schema_migrations
```

---

## ⚠️ Troubleshooting

### Problema: "DATABASE_URL not set"

**Solução**:
```bash
# Criar .env.local
echo 'DATABASE_URL="postgresql://hub_app_user:dev123@localhost:5432/hub_app_dev"' > .env.local

# Ou exportar temporariamente
export DATABASE_URL="postgresql://hub_app_user:dev123@localhost:5432/hub_app_dev"
```

---

### Problema: Migration já aplicada (checksum mismatch)

**Causa**: Arquivo de migration foi editado após aplicação

**Solução**:
```bash
# Opção 1: Reverter edição (se foi erro)
git checkout migrations/003_add_avatar_field.sql

# Opção 2: Criar nova migration (se mudança intencional)
bash scripts/migration-create.sh "update avatar field"
```

---

### Problema: Migration falhou no meio

**Solução**:
```bash
# 1. Verificar estado do banco
psql -U hub_app_user -d hub_app_dev -c "\d users"

# 2. Se parcialmente aplicada, limpar manualmente
psql -U hub_app_user -d hub_app_dev
DROP INDEX IF EXISTS idx_users_avatar;  -- Limpar o que foi aplicado
\q

# 3. Corrigir migration
vim migrations/003_add_avatar_field.sql

# 4. Tentar novamente
bash scripts/migration-up.sh
```

---

### Problema: Ordem de migrations incorreta

**Causa**: Múltiplos desenvolvedores criaram migrations simultaneamente

**Solução**:
```bash
# Renumerar migrations (cuidado!)
cd migrations/
mv 003_add_avatar.sql 004_add_avatar.sql
mv 004_add_posts.sql 003_add_posts.sql

# Ou criar merge migration
bash scripts/migration-create.sh "merge avatar and posts"
```

---

## 🎯 Workflows Comuns

### Workflow 1: Nova Tabela

```bash
# 1. Criar migration
bash scripts/migration-create.sh "create posts table"

# 2. Editar
vim migrations/003_create_posts_table.sql
```

```sql
-- UP
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_tenant ON posts(tenant_id);
CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_published ON posts(published);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY posts_tenant_isolation ON posts
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- DOWN
DROP POLICY IF EXISTS posts_tenant_isolation ON posts;
DROP TABLE IF EXISTS posts CASCADE;
```

```bash
# 3. Aplicar
bash scripts/migration-up.sh
```

---

### Workflow 2: Adicionar Campo

```bash
# 1. Criar migration
bash scripts/migration-create.sh "add user bio field"

# 2. Editar
vim migrations/004_add_user_bio_field.sql
```

```sql
-- UP
ALTER TABLE users ADD COLUMN bio TEXT;
COMMENT ON COLUMN users.bio IS 'Biografia do usuário';

-- DOWN
ALTER TABLE users DROP COLUMN IF EXISTS bio;
```

```bash
# 3. Aplicar
bash scripts/migration-up.sh
```

---

### Workflow 3: Renomear Campo (com dados)

```bash
# 1. Criar migration
bash scripts/migration-create.sh "rename user name to full name"

# 2. Editar
vim migrations/005_rename_user_name.sql
```

```sql
-- UP
ALTER TABLE users RENAME COLUMN name TO full_name;

-- DOWN
ALTER TABLE users RENAME COLUMN full_name TO name;
```

```bash
# 3. Aplicar
bash scripts/migration-up.sh
```

---

## 📚 Referências

- **PostgreSQL DDL**: https://www.postgresql.org/docs/16/ddl.html
- **Row Level Security**: https://www.postgresql.org/docs/16/ddl-rowsecurity.html
- **Migration Scripts**: `scripts/migration-*.sh`
- **Setup Guide**: `docs/DATABASE_SETUP.md`

---

**Criado por**: Agatha Fiuza + Claude Code
**Filosofia**: "Make it right, make it work, make it fast"
**Versão**: 1.0.0
**Última Atualização**: 14/11/2025
