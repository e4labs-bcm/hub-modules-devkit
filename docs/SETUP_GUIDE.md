# Setup Guide - Hub.app DevKit

Guia completo de instalação do PostgreSQL para desenvolvimento local em **macOS**, **Linux** e **Windows**.

---

## 🎯 **Objetivo**

Instalar e configurar PostgreSQL local para desenvolver módulos do Hub.app usando o DevKit.

---

## 📋 **O Que Será Instalado**

- **PostgreSQL 16** - Banco de dados relacional
- **Banco hub_app_dev** - Database local para testes
- **Seeds opcionais** - Dados de exemplo (3 tenants, 9 usuários, módulo financeiro)
- **Arquivo .env.local** - Configuração com connection string

---

## 🍎 **macOS**

### **Requisitos**:
- macOS 10.15+ (Catalina ou superior)
- Homebrew (será instalado automaticamente se ausente)

### **Instalação Automática**:

```bash
# No diretório do DevKit
bash scripts/setup-mac.sh
```

### **O Que o Script Faz**:
1. ✅ Verifica/instala Homebrew
2. ✅ Instala PostgreSQL 16 via Homebrew
3. ✅ Inicia serviço PostgreSQL
4. ✅ Cria banco `hub_app_dev`
5. ✅ Cria arquivo `.env.local`
6. ✅ Aplica seeds (opcional - você escolhe)

### **Comandos Úteis (macOS)**:

```bash
# Iniciar PostgreSQL
brew services start postgresql@16

# Parar PostgreSQL
brew services stop postgresql@16

# Verificar status
brew services list | grep postgresql

# Conectar ao banco
psql -d hub_app_dev

# Ver tabelas
psql -d hub_app_dev -c "\dt"
```

---

## 🐧 **Linux**

### **Distribuições Suportadas**:
- ✅ Ubuntu 20.04+, Debian 11+, Pop!_OS, Linux Mint
- ✅ Fedora 36+, RHEL 8+, Rocky Linux, AlmaLinux
- ✅ Arch Linux, Manjaro

### **Instalação Automática**:

```bash
# No diretório do DevKit
bash scripts/setup-linux.sh
```

### **O Que o Script Faz**:
1. ✅ Detecta distribuição Linux (Ubuntu/Fedora/Arch/etc)
2. ✅ Adiciona repositório oficial PostgreSQL
3. ✅ Instala PostgreSQL 16 via apt/dnf/pacman
4. ✅ Configura e inicia serviço
5. ✅ Cria usuário PostgreSQL (sem senha para local)
6. ✅ Cria banco `hub_app_dev`
7. ✅ Cria arquivo `.env.local`
8. ✅ Aplica seeds (opcional - você escolhe)

### **Comandos Úteis (Linux)**:

```bash
# Iniciar PostgreSQL
sudo systemctl start postgresql

# Parar PostgreSQL
sudo systemctl stop postgresql

# Verificar status
sudo systemctl status postgresql

# Habilitar auto-start no boot
sudo systemctl enable postgresql

# Conectar ao banco
psql -d hub_app_dev

# Ver tabelas
psql -d hub_app_dev -c "\dt"
```

---

## 🪟 **Windows**

### **Requisitos**:
- Windows 10+ (64-bit)
- PowerShell 5.1+ (incluso no Windows)
- **Executar PowerShell como Administrador**

### **Instalação Automática**:

```powershell
# 1. Abrir PowerShell como Administrador
# (Right-click PowerShell -> "Run as Administrator")

# 2. Permitir execução de scripts (primeira vez)
Set-ExecutionPolicy Bypass -Scope Process -Force

# 3. Navegar ao diretório do DevKit
cd C:\path\to\hub-modules-devkit

# 4. Executar script
.\scripts\setup-windows.ps1
```

### **O Que o Script Faz**:
1. ✅ Verifica/instala gerenciador de pacotes (winget ou Chocolatey)
2. ✅ Instala PostgreSQL 16
3. ✅ Configura PATH automaticamente
4. ✅ Inicia serviço PostgreSQL
5. ✅ Cria banco `hub_app_dev`
6. ✅ Cria arquivo `.env.local`
7. ✅ Aplica seeds (opcional - você escolhe)

### **Comandos Úteis (Windows PowerShell)**:

```powershell
# Iniciar PostgreSQL
Start-Service postgresql-x64-16

# Parar PostgreSQL
Stop-Service postgresql-x64-16

# Verificar status
Get-Service postgresql-x64-16

# Conectar ao banco
psql -U postgres -d hub_app_dev

# Ver tabelas
psql -U postgres -d hub_app_dev -c "\dt"
```

---

## 📦 **Seeds (Dados de Teste)**

Os scripts oferecem aplicar seeds automaticamente. Se você escolher **não aplicar** durante o setup, pode aplicar manualmente depois:

### **Seeds Disponíveis**:

| Arquivo | Descrição | Dependências |
|---------|-----------|--------------|
| `02-dev-tenants.sql` | 3 empresas de exemplo | Nenhuma |
| `03-dev-users.sql` | 9 usuários (3 por empresa) | 02 |
| `04-dev-financeiro.sql` | Dados do módulo Financeiro | 02, 03 |

**Nota**: O arquivo `01-schema-base.sql` precisa ser gerado do staging primeiro:
```bash
bash scripts/update-schema-from-staging.sh
```

### **Aplicar Seeds Manualmente**:

```bash
# macOS/Linux
psql -d hub_app_dev -f seeds/02-dev-tenants.sql
psql -d hub_app_dev -f seeds/03-dev-users.sql
psql -d hub_app_dev -f seeds/04-dev-financeiro.sql

# Windows
psql -U postgres -d hub_app_dev -f seeds\02-dev-tenants.sql
psql -U postgres -d hub_app_dev -f seeds\03-dev-users.sql
psql -U postgres -d hub_app_dev -f seeds\04-dev-financeiro.sql
```

### **Dados Criados pelos Seeds**:

**Tenants (3)**:
- Startup Tech LTDA (ID: `11111111-1111-...`)
- Comércio PME S/A (ID: `22222222-2222-...`)
- Corporação Nacional (ID: `33333333-3333-...`)

**Usuários (9 total - 3 por tenant)**:
- Email: `admin@startup.dev`, Senha: `dev123` (admin)
- Email: `joao@startup.dev`, Senha: `dev123` (usuário)
- Email: `maria@startup.dev`, Senha: `dev123` (usuário)
- ...e mais 6 usuários nas outras empresas

**Módulo Financeiro (Tenant 1)**:
- 7 categorias (3 receitas + 4 despesas)
- 15 transações (últimos 3 meses)
- Saldo total: ~R$ 17.950,00

---

## 🔧 **Troubleshooting**

### **Problema: "command not found: psql"**

**macOS/Linux**:
```bash
# Verificar se PostgreSQL está no PATH
echo $PATH | grep postgres

# Se não estiver, adicionar ao PATH
# macOS:
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Linux (Ubuntu):
export PATH="/usr/lib/postgresql/16/bin:$PATH"
```

**Windows**:
```powershell
# Verificar PATH
$env:Path

# Adicionar manualmente (se necessário)
$env:Path += ";C:\Program Files\PostgreSQL\16\bin"
```

---

### **Problema: "connection to server failed"**

**Solução**: Verificar se PostgreSQL está rodando:

```bash
# macOS
brew services list | grep postgresql

# Linux
sudo systemctl status postgresql

# Windows
Get-Service postgresql-x64-16
```

Se não estiver rodando, iniciar o serviço (veja comandos úteis acima).

---

### **Problema: "database already exists" ou "port 5432 already in use"**

**Causa**: PostgreSQL já estava instalado ou outro processo está usando a porta.

**Solução**:
1. Parar o serviço PostgreSQL existente
2. Reexecutar o script e escolher "recriar" quando perguntar

Ou:
```bash
# Remover banco existente e recriar
dropdb hub_app_dev
createdb hub_app_dev
```

---

### **Problema: Seeds falhando com "relation does not exist"**

**Causa**: Schema base não foi aplicado antes dos seeds.

**Solução**:
1. Obter schema base do staging:
   ```bash
   bash scripts/update-schema-from-staging.sh
   ```
2. Aplicar schema base:
   ```bash
   psql -d hub_app_dev -f seeds/01-schema-base.sql
   ```
3. Reaplicar seeds na ordem (02, 03, 04)

---

## ✅ **Verificação Final**

Após o setup, verifique se tudo está funcionando:

```bash
# 1. Conectar ao banco
psql -d hub_app_dev

# 2. No prompt do psql, executar:
\dt              # Listar tabelas
SELECT COUNT(*) FROM perfis;  # Contar usuários (se seeds aplicados)
\q               # Sair

# 3. Verificar .env.local
cat .env.local   # macOS/Linux
type .env.local  # Windows

# Deve conter algo como:
# DATABASE_URL="postgresql://user:@localhost:5432/hub_app_dev?schema=public"
```

---

## 🚀 **Próximos Passos**

Agora que o PostgreSQL está configurado, você pode:

1. **Criar um módulo**:
   ```bash
   bash scripts/create-module.sh tarefas "Tarefas" ListTodo
   ```

2. **Instalar no Hub.app**:
   ```bash
   bash scripts/install-module.sh tarefas
   ```

3. **Desenvolver**:
   ```bash
   cd packages/mod-tarefas
   npm install
   npm run dev
   ```

---

## 📚 **Documentação Adicional**

- **Seeds**: `seeds/README.md`
- **Migrations**: `migrations/` (quando criadas)
- **CLAUDE.md**: Documentação completa do projeto

---

**Última Atualização**: 13/11/2025
