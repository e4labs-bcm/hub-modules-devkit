# Database Setup Guide - Hub Modules DevKit

**Última atualização**: 14/11/2025

Este guia explica como configurar o PostgreSQL para desenvolvimento local com o Hub Modules DevKit.

---

## 📋 Pré-requisitos

- **PostgreSQL 16+** instalado
- **Node.js 18+** instalado
- **Git** instalado
- Acesso de superusuário (para criar databases)

---

## 🚀 Quick Start

### Opção 1: Scripts Automatizados (Recomendado)

Escolha o script apropriado para seu sistema operacional:

#### macOS
```bash
cd hub-modules-devkit
bash scripts/setup-mac.sh
```

#### Linux (Ubuntu/Debian/Fedora/Arch)
```bash
cd hub-modules-devkit
bash scripts/setup-linux.sh
```

#### Windows (PowerShell como Administrador)
```powershell
cd hub-modules-devkit
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\setup-windows.ps1
```

**O que os scripts fazem:**
1. ✅ Instalam PostgreSQL 16 (se não instalado)
2. ✅ Iniciam o serviço PostgreSQL
3. ✅ Criam database `hub_app_dev`
4. ✅ Criam usuário `hub_app_user` (Mac/Linux) ou usam `postgres` (Windows)
5. ✅ Aplicam seeds de desenvolvimento (opcional)
6. ✅ Criam arquivo `.env.local` com connection string
7. ✅ Testam a conexão

---

### Opção 2: Setup Manual

Se preferir configurar manualmente:

#### 1. Instalar PostgreSQL

**macOS** (Homebrew):
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install postgresql-16 postgresql-contrib-16
sudo systemctl start postgresql
```

**Fedora/RHEL**:
```bash
sudo dnf install postgresql16-server postgresql16-contrib
sudo postgresql-setup --initdb
sudo systemctl start postgresql
```

**Windows** (Chocolatey):
```powershell
choco install postgresql16 -y
# Ou baixe o instalador: https://www.postgresql.org/download/windows/
```

#### 2. Criar Database e Usuário

**macOS/Linux**:
```bash
# Criar usuário
createuser hub_app_user

# Criar database
createdb -O hub_app_user hub_app_dev

# Ou via psql:
psql postgres
CREATE USER hub_app_user WITH PASSWORD 'dev123';
CREATE DATABASE hub_app_dev OWNER hub_app_user;
GRANT ALL PRIVILEGES ON DATABASE hub_app_dev TO hub_app_user;
\q
```

**Windows**:
```powershell
# Via psql (senha padrão: postgres)
psql -U postgres
CREATE USER hub_app_user WITH PASSWORD 'dev123';
CREATE DATABASE hub_app_dev OWNER hub_app_user;
GRANT ALL PRIVILEGES ON DATABASE hub_app_dev TO hub_app_user;
\q
```

#### 3. Aplicar Seeds (Dados de Desenvolvimento)

**Ordem correta**:
```bash
cd hub-modules-devkit

# 1. Schema base (se tiver exportado do staging)
psql -U hub_app_user -d hub_app_dev -f seeds/01-schema-base.sql

# 2. Tenants de desenvolvimento (3 empresas)
psql -U hub_app_user -d hub_app_dev -f seeds/02-dev-tenants.sql

# 3. Usuários de desenvolvimento (9 users, 3 por tenant)
psql -U hub_app_user -d hub_app_dev -f seeds/03-dev-users.sql

# 4. Módulo Financeiro (categorias + transações)
psql -U hub_app_user -d hub_app_dev -f seeds/04-dev-financeiro.sql
```

**Windows** (ajuste o usuário):
```powershell
psql -U postgres -d hub_app_dev -f seeds/02-dev-tenants.sql
psql -U postgres -d hub_app_dev -f seeds/03-dev-users.sql
psql -U postgres -d hub_app_dev -f seeds/04-dev-financeiro.sql
```

#### 4. Configurar Variáveis de Ambiente

Crie `.env.local` na raiz do DevKit:

```bash
# Connection string para PostgreSQL local
DATABASE_URL="postgresql://hub_app_user:dev123@localhost:5432/hub_app_dev"
```

**Windows** (se usando usuário postgres):
```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/hub_app_dev"
```

#### 5. Testar Conexão

```bash
# Via psql
psql -U hub_app_user -d hub_app_dev -c "SELECT version();"

# Via Node.js (se tiver Prisma configurado)
npx prisma db pull
```

---

## 📊 Dados de Desenvolvimento (Seeds)

### O que está incluído?

#### 1. **02-dev-tenants.sql** - 3 Empresas
- **Startup Tech LTDA** (ID: `11111111-...`)
- **Comércio PME S/A** (ID: `22222222-...`)
- **Corporação Nacional** (ID: `33333333-...`)

#### 2. **03-dev-users.sql** - 9 Usuários (3 por empresa)
- 1 admin + 2 users por tenant
- **Senha padrão**: `dev123` (bcrypt hash)
- Vinculados com Auth.js accounts (Google OAuth)

#### 3. **04-dev-financeiro.sql** - Módulo Financeiro
- **7 categorias**: 3 receitas + 4 despesas
- **15 transações**: últimos 3 meses
- **Saldo**: ~R$ 17.950,00
- **Tenant**: Startup Tech LTDA

### Como usar os seeds?

```bash
# Aplicar todos os seeds de uma vez
bash scripts/apply-all-seeds.sh

# Ou aplicar individualmente (ordem importa!)
psql -U hub_app_user -d hub_app_dev -f seeds/02-dev-tenants.sql
psql -U hub_app_user -d hub_app_dev -f seeds/03-dev-users.sql
psql -U hub_app_user -d hub_app_dev -f seeds/04-dev-financeiro.sql
```

### Resetar seeds (limpar e reaplicar)

```bash
# Limpar tudo
psql -U hub_app_user -d hub_app_dev -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Reaplicar seeds
bash scripts/apply-all-seeds.sh
```

---

## 🔧 Troubleshooting

### Problema: "psql: command not found"

**Solução macOS**:
```bash
# Adicionar ao PATH (ajuste versão se necessário)
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Solução Linux**:
```bash
# PostgreSQL geralmente já está no PATH
# Se não estiver:
export PATH="/usr/lib/postgresql/16/bin:$PATH"
```

**Solução Windows**:
```powershell
# Adicionar ao PATH do sistema:
# C:\Program Files\PostgreSQL\16\bin
# Ou via script:
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\PostgreSQL\16\bin", "Machine")
```

---

### Problema: "FATAL: role 'hub_app_user' does not exist"

**Solução**:
```bash
# Criar usuário
createuser hub_app_user

# Ou via psql
psql postgres -c "CREATE USER hub_app_user WITH PASSWORD 'dev123';"
```

---

### Problema: "FATAL: database 'hub_app_dev' does not exist"

**Solução**:
```bash
# Criar database
createdb -O hub_app_user hub_app_dev

# Ou via psql
psql postgres -c "CREATE DATABASE hub_app_dev OWNER hub_app_user;"
```

---

### Problema: "connection refused" (PostgreSQL não está rodando)

**Solução macOS**:
```bash
# Iniciar serviço
brew services start postgresql@16

# Verificar status
brew services list
```

**Solução Linux**:
```bash
# Iniciar serviço
sudo systemctl start postgresql

# Verificar status
sudo systemctl status postgresql
```

**Solução Windows**:
```powershell
# Iniciar serviço
Start-Service postgresql-x64-16

# Verificar status
Get-Service postgresql-x64-16
```

---

### Problema: "password authentication failed"

**Solução macOS/Linux**:
```bash
# Editar pg_hba.conf (ajuste caminho conforme instalação)
# macOS:
sudo nano /opt/homebrew/var/postgresql@16/pg_hba.conf

# Linux:
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Mudar de "peer" para "md5" ou "trust":
# local   all   all   trust
# host    all   all   127.0.0.1/32   md5

# Reiniciar PostgreSQL
brew services restart postgresql@16  # macOS
sudo systemctl restart postgresql    # Linux
```

---

### Problema: Seeds falham com "permission denied"

**Solução**:
```bash
# Garantir que usuário tem permissões
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE hub_app_dev TO hub_app_user;"
psql -U hub_app_user -d hub_app_dev -c "GRANT ALL ON SCHEMA public TO hub_app_user;"
```

---

## 🎯 Best Practices

### Desenvolvimento Local

1. **Use seeds** - Não desenvolva com banco vazio
2. **Multi-tenancy** - Sempre teste com múltiplos tenants (seeds têm 3)
3. **Backup antes de migrations** - `pg_dump hub_app_dev > backup.sql`
4. **Não use produção** - Nunca aponte para banco de produção localmente

### Connection Strings

```bash
# ✅ CORRETO - Desenvolvimento
DATABASE_URL="postgresql://hub_app_user:dev123@localhost:5432/hub_app_dev"

# ❌ ERRADO - Produção (NUNCA faça isso!)
DATABASE_URL="postgresql://user:pass@production-db.com:5432/hub_app_prod"
```

### Migrations

```bash
# Sempre crie migrations, nunca altere schema manualmente
hubapp-devkit migration create "add user avatar field"

# Teste migrations em dev antes de aplicar em staging/prod
```

---

## 📚 Referências

- **PostgreSQL Docs**: https://www.postgresql.org/docs/16/
- **Setup Scripts**: `scripts/setup-*.sh`
- **Seeds**: `seeds/README.md`
- **Migrations**: `docs/MIGRATIONS.md`
- **Troubleshooting Hub.app**: `hub-app-nextjs/CLAUDE.md`

---

**Criado por**: Agatha Fiuza + Claude Code
**Filosofia**: "Make it right, make it work, make it fast"
**Versão**: 1.0.0
**Última Atualização**: 14/11/2025
