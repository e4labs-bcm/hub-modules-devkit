# 🚀 Quick Start - Hub.app Modules DevKit

Guia rápido para criar e instalar um novo módulo em **5 minutos**.

---

## ⚡ Criação Rápida (3 comandos)

### 1. Criar módulo

```bash
cd ~/Documents/Claude/hub-modules-devkit
./scripts/create-module.sh tarefas "Tarefas" ListTodo
```

**Resultado:**
- ✅ Estrutura completa criada em `hub-app-nextjs/packages/mod-tarefas`
- ✅ Dependências instaladas (React, TypeScript, Vite, Radix UI)
- ✅ Templates configurados (hubContext, apiAdapter, manifest)
- ✅ Migration SQL criada
- ✅ README documentado

### 2. Instalar no Hub

```bash
cd ~/Documents/Claude/hub-app-nextjs
./scripts/install-module.sh tarefas "Tarefas" ListTodo
```

**Resultado:**
- ✅ Migration SQL aplicada no banco
- ✅ Módulo registrado na tabela `modulos_instalados`
- ✅ API routes criadas em `src/app/api/modules/tarefas`
- ✅ Prisma schema atualizado
- ✅ Prisma Client regenerado

### 3. Testar

```bash
# Terminal 1 - Hub App
cd ~/Documents/Claude/hub-app-nextjs
npm run dev  # http://localhost:3000

# Terminal 2 - Módulo
cd packages/mod-tarefas
npm run dev  # http://localhost:5173
```

**Abrir:** http://localhost:3000 → Login → Clicar em "Tarefas"

---

## 📋 Comandos Disponíveis

### create-module.sh

Cria estrutura completa de um novo módulo.

```bash
./scripts/create-module.sh <slug> "<Título>" [Ícone]
```

**Parâmetros:**
- `slug` - Nome do módulo (lowercase, hífens) - Ex: `tarefas`, `inventario`
- `Título` - Nome exibido no Hub - Ex: `"Tarefas"`, `"Inventário"`
- `Ícone` - Ícone Lucide (opcional) - Ex: `ListTodo`, `Package`

**Exemplos:**

```bash
# Módulo de tarefas
./scripts/create-module.sh tarefas "Tarefas" ListTodo

# Módulo de inventário
./scripts/create-module.sh inventario "Inventário" Package

# Módulo de CRM
./scripts/create-module.sh crm "CRM" Users

# Módulo de vendas
./scripts/create-module.sh vendas "Vendas" ShoppingCart
```

**Ícones disponíveis:** https://lucide.dev/icons

---

### install-module.sh

Instala módulo no Hub.app (registro + API routes + Prisma).

```bash
cd ~/Documents/Claude/hub-app-nextjs
./scripts/install-module.sh <slug> "<Título>" <Ícone> [tenant-id]
```

**Parâmetros:**
- `slug` - Nome do módulo (mesmo do create-module)
- `Título` - Nome exibido
- `Ícone` - Ícone Lucide
- `tenant-id` - UUID do tenant (opcional, usa o primeiro se omitido)

**Exemplos:**

```bash
# Instalar para o primeiro tenant
./scripts/install-module.sh tarefas "Tarefas" ListTodo

# Instalar para tenant específico
./scripts/install-module.sh tarefas "Tarefas" ListTodo a01b75e2-233b-40c2-801b-0e4a7e2a4055
```

**O que faz:**
1. ✅ Aplica migration SQL (`psql`)
2. ✅ Registra na tabela `modulos_instalados`
3. ✅ Cria API routes em `src/app/api/modules/<slug>/`
4. ✅ Adiciona model no `prisma/schema.prisma`
5. ✅ Regenera Prisma Client (`npx prisma generate`)

---

## 📁 Estrutura Criada

```
hub-app-nextjs/packages/mod-tarefas/
├── adapter/
│   └── apiAdapter.ts              # Cliente HTTP + JWT
│
├── app/
│   ├── index.html                 # HTML entry point
│   ├── vite.config.ts             # Configuração Vite
│   ├── tailwind.config.js         # Tailwind CSS
│   ├── tsconfig.json              # TypeScript config
│   │
│   └── src/
│       ├── main.tsx               # Entry point React
│       ├── App.tsx                # Componente principal
│       ├── hubContext.ts          # Integração Hub (postMessage)
│       ├── index.css              # Tailwind imports
│       │
│       ├── components/            # Componentes React
│       ├── types/                 # TypeScript types
│       │   └── index.ts
│       └── utils/                 # Utilitários
│
├── migrations/
│   └── 20251112_tarefas.sql       # SQL migration
│
├── docs/                          # Documentação
│
├── manifest.json                  # Metadados do módulo
├── package.json                   # Dependências
└── README.md                      # Documentação
```

---

## 🛠️ Desenvolvimento

### Dev Server (Hot Reload)

```bash
cd packages/mod-tarefas
npm run dev
```

Abre em: http://localhost:5173

### Build para Produção

```bash
npm run build
```

Gera pasta `dist/` com assets estáticos.

### Preview do Build

```bash
npm run preview
```

Testa build em: http://localhost:4173

---

## 🔗 Integração com Hub.app

### Como funciona o fluxo?

```
┌─────────────────────────────────────────┐
│  Hub App (localhost:3000)               │
│  1. Usuário clica no módulo             │
│  2. Hub gera JWT token                  │
│  3. Abre iframe com URL do módulo       │
└─────────────────────────────────────────┘
               │
               │ postMessage
               │ { tenantId, userId, apiUrl, apiToken }
               ▼
┌─────────────────────────────────────────┐
│  Módulo (localhost:5173 - iframe)       │
│  4. hubContext recebe postMessage       │
│  5. Configura apiAdapter com JWT        │
│  6. Componente renderiza                │
└─────────────────────────────────────────┘
               │
               │ fetch() + Bearer token
               ▼
┌─────────────────────────────────────────┐
│  API Routes (/api/modules/tarefas/*)    │
│  7. Valida JWT (authenticateModule)     │
│  8. Extrai tenantId do token            │
│  9. Query Prisma com tenant_id          │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  PostgreSQL                             │
│  10. Retorna dados do tenant            │
└─────────────────────────────────────────┘
```

### Testando a integração

**1. Verificar postMessage (DevTools Console):**

```javascript
// Deve aparecer no console do módulo:
📨 [tarefas] Mensagem recebida: { type: 'hubapp:init', payload: {...} }
📡 Configurando API adapter...
✅ API adapter configurado!
```

**2. Testar API manualmente:**

```javascript
// No console do módulo:
fetch('http://localhost:3000/api/modules/tarefas/items', {
  headers: {
    'Authorization': 'Bearer ' + localStorage.getItem('apiToken')
  }
}).then(r => r.json()).then(console.log);
```

**3. Verificar multi-tenancy:**

```sql
-- No PostgreSQL:
SELECT * FROM tarefas_items WHERE tenant_id = 'seu-tenant-id';
```

---

## 🚀 Deploy em Produção

### 1. Build do módulo

```bash
cd packages/mod-tarefas
npm run build
```

### 2. Deploy em CDN

**Opção A: Vercel**

```bash
npm install -g vercel
vercel --prod
# URL: https://tarefas.vercel.app
```

**Opção B: Netlify**

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=dist
# URL: https://tarefas.netlify.app
```

**Opção C: Hostinger / VPS**

```bash
rsync -avz dist/ user@servidor:/var/www/tarefas/
# URL: https://tarefas.meuhub.app
```

### 3. Atualizar URL no banco

```sql
UPDATE modulos_instalados
SET manifest = jsonb_set(
  manifest,
  '{url}',
  '"https://tarefas.vercel.app/"'
)
WHERE nome = 'Tarefas';
```

Ou simplesmente editar `manifest.json` antes do deploy:

```json
{
  "url": "https://tarefas.vercel.app/"
}
```

---

## 🐛 Troubleshooting

### Módulo não aparece no Hub

**Causa:** Não foi registrado no banco

**Solução:**

```bash
cd ~/Documents/Claude/hub-app-nextjs
./scripts/install-module.sh tarefas "Tarefas" ListTodo
```

### API retorna 401 Unauthorized

**Causa:** Token JWT inválido ou não enviado

**Solução:** Verificar logs no console:

```javascript
// Deve aparecer:
✅ [tarefas] API adapter configurado!
```

Se não aparecer, o postMessage não foi recebido.

### Tela branca no iframe

**Causa:** CORS ou URL incorreta

**Solução:**

1. Verificar manifest.json → URL correta?
2. Módulo está rodando? (`npm run dev`)
3. CORS configurado nos OPTIONS? (já está no template)

### Dados de outro tenant aparecem

**Causa:** Query não filtra por tenant_id

**Solução:** SEMPRE filtrar por tenantId do JWT:

```typescript
// ❌ ERRADO
const items = await prisma.tarefas_items.findMany();

// ✅ CORRETO
const items = await prisma.tarefas_items.findMany({
  where: { tenant_id: tenantId }  // tenantId vem do JWT!
});
```

---

## 📚 Próximos Passos

Agora que seu módulo está rodando:

1. **Customizar UI** - Edite `App.tsx` e adicione componentes
2. **Adicionar endpoints** - Crie mais rotas em `/api/modules/tarefas`
3. **Criar tabelas** - Adicione mais models no Prisma schema
4. **Adicionar features** - Real-time (SSE), filtros, busca, etc.

### Documentação Completa

- [README principal](./README.md) - Arquitetura detalhada
- [Best Practices](./docs/BEST_PRACTICES.md) - Padrões recomendados
- [API Routes Template](./docs/API_ROUTES_TEMPLATE.md) - Exemplos de rotas
- [Claude Code Guide](./docs/CLAUDE_CODE_GUIDE.md) - Trabalhando com Claude

---

## 💡 Dicas Úteis

### Alias úteis (adicionar no ~/.zshrc)

```bash
alias create-module='~/Documents/Claude/hub-modules-devkit/scripts/create-module.sh'
alias install-module='cd ~/Documents/Claude/hub-app-nextjs && ./scripts/install-module.sh'
```

Uso:

```bash
create-module tarefas "Tarefas" ListTodo
install-module tarefas "Tarefas" ListTodo
```

### Variáveis de ambiente

```bash
# .zshrc ou .bashrc
export HUB_ROOT="~/Documents/Claude/hub-app-nextjs"
export DEVKIT_ROOT="~/Documents/Claude/hub-modules-devkit"
```

### Template VSCode (tasks.json)

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Create Module",
      "type": "shell",
      "command": "${env:DEVKIT_ROOT}/scripts/create-module.sh ${input:moduleName} \"${input:moduleTitle}\" ${input:moduleIcon}",
      "problemMatcher": []
    }
  ],
  "inputs": [
    { "id": "moduleName", "type": "promptString", "description": "Module slug" },
    { "id": "moduleTitle", "type": "promptString", "description": "Module title" },
    { "id": "moduleIcon", "type": "promptString", "description": "Lucide icon", "default": "Package" }
  ]
}
```

---

**Pronto!** Em menos de 5 minutos você tem um módulo completo rodando no Hub.app! 🎉

**Última atualização:** 12 de Novembro de 2025
