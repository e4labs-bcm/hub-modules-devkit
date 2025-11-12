# 📦 Instalação do Hub.app Modules DevKit

Guia para instalar e configurar o DevKit no seu ambiente.

---

## ⚡ Instalação Rápida (1 minuto)

```bash
# 1. Clone ou baixe o DevKit
cd ~/Documents/Claude
git clone https://github.com/SEU-USER/hub-modules-devkit.git
# OU extraia hub-modules-devkit.tar.gz

# 2. Tornar scripts executáveis
cd hub-modules-devkit
chmod +x scripts/*.sh

# 3. (Opcional) Criar alias
echo 'alias create-module="~/Documents/Claude/hub-modules-devkit/scripts/create-module.sh"' >> ~/.zshrc
source ~/.zshrc
```

**Pronto!** Agora você pode criar módulos com:

```bash
create-module tarefas "Tarefas" ListTodo
```

---

## 📋 Pré-requisitos

### Obrigatórios

- ✅ **Node.js 18+** - Runtime JavaScript
  ```bash
  node --version  # deve ser >= 18.0.0
  ```

- ✅ **npm 9+** - Package manager
  ```bash
  npm --version  # deve ser >= 9.0.0
  ```

- ✅ **Git** - Controle de versão
  ```bash
  git --version
  ```

- ✅ **Hub.app Next.js** - Backend do Hub
  ```bash
  # Deve existir em:
  ~/Documents/Claude/hub-app-nextjs
  ```

- ✅ **PostgreSQL** - Banco de dados
  ```bash
  # Verificar conexão:
  psql $DATABASE_URL -c "SELECT version();"
  ```

### Recomendados

- 📝 **Claude Code CLI** - Para desenvolver com Claude
  ```bash
  # Verificar instalação:
  which claude
  ```

- 📝 **psql** - Cliente PostgreSQL (para migrations)
  ```bash
  # macOS:
  brew install postgresql

  # Ubuntu/Debian:
  sudo apt install postgresql-client
  ```

- 📝 **jq** - Parser JSON (para scripts)
  ```bash
  # macOS:
  brew install jq

  # Ubuntu/Debian:
  sudo apt install jq
  ```

---

## 🔧 Configuração

### 1. Variáveis de Ambiente

Adicione ao `~/.zshrc` ou `~/.bashrc`:

```bash
# Hub.app Modules DevKit
export HUB_ROOT="$HOME/Documents/Claude/hub-app-nextjs"
export DEVKIT_ROOT="$HOME/Documents/Claude/hub-modules-devkit"

# Aliases úteis
alias create-module='$DEVKIT_ROOT/scripts/create-module.sh'
alias install-module='cd $HUB_ROOT && $DEVKIT_ROOT/scripts/install-module.sh'
alias hub-dev='cd $HUB_ROOT && npm run dev'
```

Recarregar:

```bash
source ~/.zshrc  # ou ~/.bashrc
```

### 2. Verificar Hub.app

```bash
cd $HUB_ROOT
npm install  # se necessário
npm run dev  # deve abrir em localhost:3000
```

### 3. Verificar Conexão PostgreSQL

```bash
# Deve estar em .env.local do Hub
cat $HUB_ROOT/.env.local | grep DATABASE_URL

# Testar conexão
cd $HUB_ROOT
npx prisma db pull  # deve conectar sem erros
```

---

## 📁 Estrutura do DevKit

```
hub-modules-devkit/
├── README.md                    # Documentação principal
├── INSTALL.md                   # Este arquivo
├── QUICK_START.md               # Guia rápido (5min)
│
├── scripts/
│   ├── create-module.sh         # Cria novo módulo
│   └── install-module.sh        # Instala no Hub
│
├── template/
│   ├── hubContext.ts            # Template integração Hub
│   ├── apiAdapter.ts            # Template cliente API
│   ├── manifest.json            # Template manifest
│   └── package.json             # Template package.json
│
├── docs/
│   ├── CLAUDE_CODE_GUIDE.md     # Guia Claude Code
│   ├── API_ROUTES_TEMPLATE.md   # Exemplos API routes
│   └── BEST_PRACTICES.md        # Melhores práticas
│
└── examples/
    └── (módulos de exemplo)
```

---

## ✅ Teste de Instalação

Execute este teste para verificar se tudo está funcionando:

```bash
# 1. Criar módulo de teste
create-module teste-install "Teste Install" Package

# 2. Verificar estrutura
ls -la $HUB_ROOT/packages/mod-teste-install

# 3. Instalar no Hub
cd $HUB_ROOT
./scripts/install-module.sh teste-install "Teste Install" Package

# 4. Verificar instalação
psql $DATABASE_URL -c "SELECT * FROM modulos_instalados WHERE nome = 'Teste Install';"

# 5. Dev server
cd packages/mod-teste-install
npm run dev
# Deve abrir em: http://localhost:5173

# 6. Limpeza (opcional)
cd $HUB_ROOT
rm -rf packages/mod-teste-install
psql $DATABASE_URL -c "DELETE FROM modulos_instalados WHERE nome = 'Teste Install';"
```

**Se tudo funcionou:** ✅ DevKit instalado corretamente!

---

## 🚀 Primeiro Módulo

Agora que o DevKit está instalado, crie seu primeiro módulo:

```bash
# 1. Criar módulo
create-module tarefas "Tarefas" ListTodo

# 2. Instalar no Hub
cd $HUB_ROOT
./scripts/install-module.sh tarefas "Tarefas" ListTodo

# 3. Desenvolver
cd packages/mod-tarefas
npm run dev

# Terminal 2 - Hub
cd $HUB_ROOT
npm run dev

# 4. Abrir navegador
open http://localhost:3000
# Login → Clicar em "Tarefas"
```

---

## 🐛 Troubleshooting

### Erro: "Diretório do Hub não encontrado"

```bash
# Verificar se Hub existe
ls -la ~/Documents/Claude/hub-app-nextjs

# Se não existir, clonar ou ajustar path:
export HUB_ROOT="/caminho/correto/hub-app-nextjs"
```

### Erro: "psql: command not found"

```bash
# Instalar cliente PostgreSQL
# macOS:
brew install postgresql

# Ubuntu:
sudo apt install postgresql-client

# Ou aplicar migrations manualmente via PgAdmin/DBeaver
```

### Erro: "MODULE_NAME não substituído"

```bash
# Verificar se sed funciona corretamente
echo "MODULE_NAME" | sed "s/MODULE_NAME/tarefas/g"
# Deve exibir: tarefas

# Se não funcionar, sed pode estar diferente (BSD vs GNU)
# Editar create-module.sh e ajustar comando sed
```

### Erro: "Permission denied"

```bash
# Tornar scripts executáveis
chmod +x ~/Documents/Claude/hub-modules-devkit/scripts/*.sh
```

### Módulo criado mas npm install falha

```bash
# Limpar cache npm
npm cache clean --force

# Deletar node_modules e reinstalar
rm -rf node_modules package-lock.json
npm install
```

---

## 📚 Próximos Passos

Após instalar o DevKit:

1. **Ler documentação**
   - [README.md](./README.md) - Arquitetura completa
   - [QUICK_START.md](./QUICK_START.md) - Guia rápido (5min)
   - [CLAUDE_CODE_GUIDE.md](./docs/CLAUDE_CODE_GUIDE.md) - Desenvolver com Claude

2. **Criar primeiro módulo**
   - Seguir QUICK_START.md
   - Testar integração com Hub
   - Implementar CRUD simples

3. **Estudar exemplos**
   - Ver `examples/` (se houver)
   - Analisar `mod-financeiro` (referência completa)

4. **Personalizar templates**
   - Editar `template/` conforme suas necessidades
   - Adicionar componentes UI padrão
   - Criar seus próprios snippets

---

## 🔄 Atualização

Para atualizar o DevKit:

```bash
cd ~/Documents/Claude/hub-modules-devkit
git pull origin main  # se for repo git

# OU baixar nova versão:
# hub-modules-devkit-v1.1.0.tar.gz
```

**Nota:** Suas customizações em `template/` serão preservadas se você não sobrescrever os arquivos.

---

## 🗑️ Desinstalação

Para remover o DevKit:

```bash
# 1. Remover diretório
rm -rf ~/Documents/Claude/hub-modules-devkit

# 2. Remover aliases do ~/.zshrc
# Editar manualmente e remover linhas:
# alias create-module=...
# export DEVKIT_ROOT=...

# 3. Recarregar shell
source ~/.zshrc
```

**Nota:** Seus módulos criados em `hub-app-nextjs/packages/` **NÃO** serão afetados.

---

## 💡 Dicas de Produtividade

### VSCode Tasks

Adicione ao `.vscode/tasks.json` do Hub:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Create Module",
      "type": "shell",
      "command": "${env:DEVKIT_ROOT}/scripts/create-module.sh",
      "args": [
        "${input:moduleName}",
        "${input:moduleTitle}",
        "${input:moduleIcon}"
      ],
      "problemMatcher": []
    },
    {
      "label": "Install Module",
      "type": "shell",
      "command": "./scripts/install-module.sh",
      "args": [
        "${input:moduleName}",
        "${input:moduleTitle}",
        "${input:moduleIcon}"
      ],
      "problemMatcher": []
    }
  ],
  "inputs": [
    {
      "id": "moduleName",
      "type": "promptString",
      "description": "Module slug (ex: tarefas)"
    },
    {
      "id": "moduleTitle",
      "type": "promptString",
      "description": "Module title (ex: Tarefas)"
    },
    {
      "id": "moduleIcon",
      "type": "promptString",
      "description": "Lucide icon (ex: ListTodo)",
      "default": "Package"
    }
  ]
}
```

Uso: `Cmd+Shift+P` → `Tasks: Run Task` → `Create Module`

### Alfred Workflow (macOS)

Crie workflow com keyword `create-module`:

```bash
tell application "Terminal"
    do script "cd ~/Documents/Claude/hub-modules-devkit && ./scripts/create-module.sh {query}"
end tell
```

---

## 📞 Suporte

- **Issues:** GitHub Issues (se disponível)
- **Documentação:** [README.md](./README.md)
- **Exemplos:** `examples/` e `hub-app-nextjs/packages/mod-financeiro`

---

**Versão:** 1.0.0
**Última Atualização:** 12 de Novembro de 2025

**Status:** ✅ Pronto para uso em produção
