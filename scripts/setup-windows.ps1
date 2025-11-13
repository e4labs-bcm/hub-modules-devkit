# ============================================================================
# Setup PostgreSQL para Windows
# Instala e configura PostgreSQL para desenvolvimento local
# ============================================================================

# Requer execução como Administrador para instalar pacotes

# Cores para output
function Write-Step { Write-Host "==>" -ForegroundColor Blue -NoNewline; Write-Host " $args" }
function Write-Success { Write-Host "✓" -ForegroundColor Green -NoNewline; Write-Host " $args" }
function Write-Error { Write-Host "✗" -ForegroundColor Red -NoNewline; Write-Host " $args" }
function Write-Warning { Write-Host "!" -ForegroundColor Yellow -NoNewline; Write-Host " $args" }

# ============================================================================
# Banner
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗"
Write-Host "║  Hub.app DevKit - PostgreSQL Setup (Windows)          ║"
Write-Host "╚═══════════════════════════════════════════════════════╝"
Write-Host ""

# ============================================================================
# Verificar execução como Administrador
# ============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Este script requer privilégios de Administrador!"
    Write-Host ""
    Write-Host "Execute o PowerShell como Administrador e rode novamente:"
    Write-Host "  Right-click PowerShell -> 'Run as Administrator'"
    Write-Host ""
    exit 1
}

# ============================================================================
# 1. Verificar/Instalar Chocolatey ou winget
# ============================================================================

Write-Step "1. Verificando gerenciador de pacotes..."

$hasWinget = Get-Command winget -ErrorAction SilentlyContinue
$hasChoco = Get-Command choco -ErrorAction SilentlyContinue

if ($hasWinget) {
    Write-Success "winget encontrado"
    $packageManager = "winget"
} elseif ($hasChoco) {
    Write-Success "Chocolatey encontrado"
    $packageManager = "choco"
} else {
    Write-Warning "Nenhum gerenciador de pacotes encontrado. Instalando Chocolatey..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    $hasChoco = Get-Command choco -ErrorAction SilentlyContinue
    if ($hasChoco) {
        Write-Success "Chocolatey instalado!"
        $packageManager = "choco"
    } else {
        Write-Error "Falha ao instalar Chocolatey"
        exit 1
    }
}

Write-Host ""

# ============================================================================
# 2. Instalar PostgreSQL
# ============================================================================

Write-Step "2. Instalando PostgreSQL..."

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlCommand) {
    $currentVersion = (psql --version) -replace '.*\s+(\d+\.\d+).*','$1'
    Write-Success "PostgreSQL já instalado (versão $currentVersion)"
} else {
    if ($packageManager -eq "winget") {
        Write-Step "Instalando via winget..."
        winget install --id PostgreSQL.PostgreSQL --exact --silent --accept-source-agreements --accept-package-agreements
    } else {
        Write-Step "Instalando via Chocolatey..."
        choco install postgresql16 -y
    }

    # Adicionar PostgreSQL ao PATH
    $pgPath = "C:\Program Files\PostgreSQL\16\bin"
    if (Test-Path $pgPath) {
        $env:Path += ";$pgPath"
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
        Write-Success "PostgreSQL 16 instalado!"
    } else {
        Write-Error "PostgreSQL instalado mas não encontrado em $pgPath"
        Write-Host "Adicione manualmente ao PATH e reinicie o terminal"
        exit 1
    }
}

Write-Host ""

# ============================================================================
# 3. Iniciar serviço PostgreSQL
# ============================================================================

Write-Step "3. Iniciando serviço PostgreSQL..."

$service = Get-Service -Name postgresql* -ErrorAction SilentlyContinue | Select-Object -First 1

if ($service) {
    if ($service.Status -eq "Running") {
        Write-Success "PostgreSQL já está rodando"
    } else {
        Start-Service $service.Name
        Write-Success "PostgreSQL iniciado!"
    }
} else {
    Write-Warning "Serviço PostgreSQL não encontrado"
    Write-Host "Verifique a instalação manualmente"
}

Write-Host ""

# ============================================================================
# 4. Criar banco de dados
# ============================================================================

Write-Step "4. Criando banco de dados..."

$dbName = "hub_app_dev"
$currentUser = $env:USERNAME

# Verificar se banco já existe
$dbExists = & psql -U postgres -lqt 2>$null | Select-String -Pattern "\s$dbName\s"

if ($dbExists) {
    Write-Warning "Banco '$dbName' já existe"
    $recreate = Read-Host "Deseja recriar (todos os dados serão perdidos)? (y/n)"

    if ($recreate -eq "y") {
        Write-Step "Removendo banco existente..."
        & psql -U postgres -c "DROP DATABASE $dbName;" 2>$null
        & psql -U postgres -c "CREATE DATABASE $dbName;" 2>$null
        Write-Success "Banco recriado!"
    } else {
        Write-Warning "Mantendo banco existente"
    }
} else {
    & psql -U postgres -c "CREATE DATABASE $dbName;" 2>$null
    Write-Success "Banco '$dbName' criado!"
}

Write-Host ""

# ============================================================================
# 5. Testar conexão
# ============================================================================

Write-Step "5. Testando conexão..."

$testConnection = & psql -U postgres -d $dbName -c "SELECT version();" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Success "Conexão OK!"
    $version = ($testConnection | Select-String "PostgreSQL") -replace '.*PostgreSQL\s+(\d+\.\d+).*','$1'
    Write-Host "   Versão: PostgreSQL $version"
} else {
    Write-Error "Falha na conexão"
    Write-Host "Verifique se PostgreSQL está rodando e tente novamente"
    exit 1
}

Write-Host ""

# ============================================================================
# 6. Criar arquivo .env.local
# ============================================================================

Write-Step "6. Criando .env.local..."

$devkitDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$envFile = Join-Path $devkitDir ".env.local"

if (Test-Path $envFile) {
    Write-Warning "Arquivo .env.local já existe"
} else {
    @"
# PostgreSQL Development Database
DATABASE_URL="postgresql://postgres:@localhost:5432/${dbName}?schema=public"

# Hub.app Config (opcional)
HUB_APP_PATH="C:\Users\${currentUser}\hub-app-nextjs"
"@ | Out-File -FilePath $envFile -Encoding UTF8

    Write-Success ".env.local criado!"
}

Write-Host ""

# ============================================================================
# 7. Aplicar seeds (opcional)
# ============================================================================

Write-Step "7. Aplicar seeds de desenvolvimento?"
Write-Host ""
Write-Host "   Seeds disponíveis:"
Write-Host "   - 01-schema-base.sql (DDL do Hub.app)"
Write-Host "   - 02-dev-tenants.sql (3 empresas)"
Write-Host "   - 03-dev-users.sql (9 usuários)"
Write-Host "   - 04-dev-financeiro.sql (dados de exemplo)"
Write-Host ""

$applySeeds = Read-Host "Deseja aplicar os seeds? (y/n)"

if ($applySeeds -eq "y") {
    $seedsDir = Join-Path $devkitDir "seeds"

    # Verificar se schema base existe
    $schemaBase = Join-Path $seedsDir "01-schema-base.sql"

    if (-not (Test-Path $schemaBase)) {
        Write-Warning "Schema base não encontrado. Execute primeiro:"
        Write-Host "   bash scripts/update-schema-from-staging.sh"
        Write-Host ""
    } else {
        Write-Step "Aplicando seeds..."

        # Aplicar seeds na ordem
        Get-ChildItem -Path $seedsDir -Filter "0*.sql" | Sort-Object Name | ForEach-Object {
            $seedName = $_.Name
            Write-Step "  Aplicando $seedName..."
            & psql -U postgres -d $dbName -f $_.FullName 2>$null | Out-Null
            Write-Success "  $seedName aplicado!"
        }

        Write-Host ""
        Write-Success "Seeds aplicados com sucesso!"
    }
} else {
    Write-Warning "Seeds não aplicados. Execute manualmente depois se necessário:"
    Write-Host "   psql -U postgres -d $dbName -f seeds\01-schema-base.sql"
}

Write-Host ""

# ============================================================================
# Finalização
# ============================================================================

Write-Host "╔═══════════════════════════════════════════════════════╗"
Write-Host "║  ✓ Setup concluído com sucesso!                      ║"
Write-Host "╚═══════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "Informações da instalação:"
Write-Host "  Database:     $dbName"
Write-Host "  Host:         localhost:5432"
Write-Host "  User:         postgres"
Write-Host "  Connection:   postgresql://postgres:@localhost:5432/${dbName}"
Write-Host ""
Write-Host "Próximos passos:"
Write-Host "  1. Testar conexão:"
Write-Host "     psql -U postgres -d $dbName"
Write-Host ""
Write-Host "  2. Ver tabelas criadas:"
Write-Host "     psql -U postgres -d $dbName -c `"\dt`""
Write-Host ""
Write-Host "  3. Contar registros:"
Write-Host "     psql -U postgres -d $dbName -c `"SELECT COUNT(*) FROM perfis;`""
Write-Host ""
Write-Host "Para parar o PostgreSQL:"
Write-Host "  Stop-Service postgresql-x64-16"
Write-Host ""
Write-Host "Para verificar status:"
Write-Host "  Get-Service postgresql-x64-16"
Write-Host ""
