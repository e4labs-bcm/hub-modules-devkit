# 🚀 Hub.app Modules DevKit

**Kit de desenvolvimento para criar módulos do Hub.app**

Versão: 1.0.0
Atualizado: 12 de Novembro de 2025

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Quick Start](#-quick-start)
- [Estrutura de um Módulo](#-estrutura-de-um-módulo)
- [Integração com Hub.app](#-integração-com-hubapp)
- [API Routes](#-api-routes)
- [Desenvolvimento Local](#-desenvolvimento-local)
- [Deploy](#-deploy)
- [Exemplos](#-exemplos)
- [Melhores Práticas](#-melhores-práticas)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Visão Geral

O **Hub.app Modules DevKit** é um template starter para criar módulos independentes que se integram perfeitamente ao Hub.app.

### O que é um Módulo Hub.app?

Um módulo é uma **aplicação React autônoma** que roda dentro do Hub.app via iframe e se comunica com o backend via API Routes autenticadas com JWT.

### Por que usar este DevKit?

✅ **Arquitetura padronizada** - Todos os módulos seguem o mesmo padrão
✅ **Multi-tenant por padrão** - Isolamento automático por tenant
✅ **Autenticação JWT** - Segurança integrada
✅ **TypeScript** - Type-safe em todo o código
✅ **UI Consistente** - Design system compartilhado (Radix UI + Tailwind)
✅ **Real-time Ready** - Suporte a SSE (Server-Sent Events)
✅ **Deploy Simples** - Build estático hospedável em qualquer CDN

---

## 🏗️ Arquitetura

### Fluxo de Dados

```
┌─────────────────────────────────────────────────┐
│  Hub App (Next.js 16)                           │
│  - Gerencia autenticação (Auth.js)              │
│  - Gera JWT token                               │
│  - Carrega módulos via iframe                   │
└─────────────────────────────────────────────────┘
                     │
                     │ postMessage
                     │ { tenantId, userId, apiUrl, apiToken }
                     ▼
┌─────────────────────────────────────────────────┐
│  Módulo (React + Vite - iframe)                 │
│  - Recebe configuração via postMessage          │
│  - Configura apiAdapter com JWT token           │
│  - Faz requests autenticados                    │
└─────────────────────────────────────────────────┘
                     │
                     │ HTTP + Bearer token
                     ▼
┌─────────────────────────────────────────────────┐
│  API Routes (/api/modules/[nome]/*)             │
│  - Valida JWT token                             │
│  - Extrai tenantId do token                     │
│  - Executa queries com Prisma                   │
│  - Retorna dados filtrados por tenant           │
└─────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  PostgreSQL                                     │
│  - Todas as tabelas têm tenant_id               │
│  - Triggers para real-time (NOTIFY/LISTEN)      │
└─────────────────────────────────────────────────┘
```

### Componentes Principais

1. **hubContext.ts** - Recebe configuração do Hub via postMessage
2. **apiAdapter.ts** - Cliente HTTP com autenticação JWT
3. **manifest.json** - Metadados do módulo (ícone, tipo, URL)
4. **API Routes** - Backend no Hub.app (Next.js)
5. **Prisma Schema** - Models do banco de dados

---

## ⚡ Quick Start

### 1. Clone o Template

```bash
cd ~/Documents/Claude/hub-modules-devkit
./scripts/create-module.sh meu-modulo "Meu Módulo" "BarChart"
```

### 2. Estrutura Criada

```
packages/mod-meu-modulo/
├── manifest.json              # Configuração do módulo
├── package.json               # Dependências
├── adapter/
│   └── apiAdapter.ts          # Cliente API
├── app/
│   ├── src/
│   │   ├── main.tsx           # Entry point
│   │   ├── App.tsx            # Componente principal
│   │   ├── hubContext.ts      # Integração Hub
│   │   └── types/
│   │       └── index.ts       # TypeScript types
│   └── vite.config.ts         # Configuração Vite
└── migrations/
    └── create_tables.sql      # Schema inicial
```

### 3. Instalar Dependências

```bash
cd packages/mod-meu-modulo
npm install
```

### 4. Criar API Routes no Hub

```bash
cd /path/to/hub-app-nextjs
mkdir -p src/app/api/modules/meu-modulo
# Copiar template de route.ts (ver docs/api-routes-template.md)
```

### 5. Desenvolver

```bash
npm run dev  # http://localhost:5173
```

### 6. Build e Deploy

```bash
npm run build
# Upload da pasta dist/ para CDN (Vercel, Netlify, etc.)
```

---

## 📦 Estrutura de um Módulo

### manifest.json

Define metadados do módulo para o Hub.app:

```json
{
  "icon": "DollarSign",           // Ícone Lucide React
  "type": "iframe",                // Tipo de carregamento
  "url": "https://modulo.meuhub.app/",  // URL de produção
  "overlay": false,                // Abrir em modal?
  "global": false,                 // Disponível sem login?
  "version": "1.0.0"
}
```

### package.json

Dependências recomendadas:

```json
{
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "@radix-ui/react-*": "^1.x",   // UI components
    "tailwind-merge": "*",
    "class-variance-authority": "*",
    "lucide-react": "*"
  },
  "devDependencies": {
    "typescript": "^5.9.2",
    "vite": "6.3.5",
    "@vitejs/plugin-react-swc": "^3.10.2"
  }
}
```

### hubContext.ts

Integração com o Hub.app:

```typescript
export type HubAppInitPayload = {
  tenantId?: string;
  userId?: string;
  email?: string;
  moduleName?: string;
  apiUrl?: string;      // URL base da API
  apiToken?: string;    // JWT token
};

export function registerHubContextListener() {
  window.addEventListener('message', (e) => {
    if (e.data?.type === 'hubapp:init') {
      // Configurar apiAdapter
      storeApiConfig(e.data.payload.apiUrl, e.data.payload.apiToken);
    }
  });
}
```

### apiAdapter.ts

Cliente HTTP autenticado:

```typescript
let _apiConfig: { baseUrl: string; token: string } | null = null;

export function storeApiConfig(baseUrl: string, token: string) {
  _apiConfig = { baseUrl, token };
}

async function fetchApi(path: string, options = {}) {
  const response = await fetch(`${_apiConfig.baseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${_apiConfig.token}`,
      ...options.headers,
    },
  });
  return response.json();
}

export const meuModuloAPI = {
  async getData() {
    return fetchApi('/api/modules/meu-modulo/data');
  },
  async createItem(data) {
    return fetchApi('/api/modules/meu-modulo/data', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },
};
```

---

## 🔗 Integração com Hub.app

### 1. Registrar Módulo no Hub

Adicionar entrada na tabela `modulos_instalados`:

```sql
INSERT INTO modulos_instalados (id, tenant_id, nome, ativo, manifest)
VALUES (
  gen_random_uuid(),
  'seu-tenant-id',
  'Meu Módulo',
  true,
  '{
    "icon": "BarChart",
    "type": "iframe",
    "url": "https://modulo.meuhub.app/",
    "version": "1.0.0"
  }'::jsonb
);
```

### 2. Criar API Routes

Arquivo: `src/app/api/modules/meu-modulo/data/route.ts`

```typescript
import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const { tenantId, userId } = await authenticateModule(req);

  const data = await prisma.minha_tabela.findMany({
    where: { tenant_id: tenantId },
  });

  return Response.json({ success: true, data });
}

export async function POST(req: NextRequest) {
  const { tenantId, userId } = await authenticateModule(req);
  const body = await req.json();

  const item = await prisma.minha_tabela.create({
    data: {
      ...body,
      tenant_id: tenantId,
      created_by: userId,
    },
  });

  return Response.json({ success: true, data: item }, { status: 201 });
}
```

### 3. Adicionar Prisma Models

Arquivo: `prisma/schema.prisma`

```prisma
model minha_tabela {
  id         String   @id @default(uuid()) @db.Uuid
  tenant_id  String   @db.Uuid
  created_by String?  @db.Uuid
  nome       String   @db.VarChar(255)
  created_at DateTime @default(now()) @db.Timestamptz(6)
  updated_at DateTime @default(now()) @db.Timestamptz(6)

  // Relações
  perfis     perfis?  @relation(fields: [created_by], references: [id])

  @@index([tenant_id])
  @@map("minha_tabela")
}
```

---

## 🛠️ Desenvolvimento Local

### Testar Integração com Hub.app

#### Terminal 1 - Hub App

```bash
cd /path/to/hub-app-nextjs
npm run dev  # http://localhost:3000
```

#### Terminal 2 - Seu Módulo

```bash
cd packages/mod-meu-modulo
npm run dev  # http://localhost:5173
```

#### Atualizar manifest temporário

Enquanto desenvolve, use URL local no manifest:

```json
{
  "url": "http://localhost:5173/"
}
```

#### Testar no Browser

1. Abrir http://localhost:3000
2. Login no Hub.app
3. Clicar no seu módulo
4. Abrir DevTools (F12)
5. Verificar postMessage:

```javascript
// Console > Network > WS
// Procurar mensagem:
{
  type: 'hubapp:init',
  payload: {
    tenantId: '...',
    userId: '...',
    apiUrl: 'http://localhost:3000',
    apiToken: 'eyJhbGc...'
  }
}
```

6. Testar API calls:

```javascript
// Console
fetch('http://localhost:3000/api/modules/meu-modulo/data', {
  headers: {
    'Authorization': 'Bearer SEU_TOKEN_AQUI'
  }
}).then(r => r.json()).then(console.log);
```

---

## 🚀 Deploy

### 1. Build de Produção

```bash
npm run build
# Gera pasta dist/ com assets estáticos
```

### 2. Deploy em CDN

#### Opção A: Vercel

```bash
npm install -g vercel
vercel --prod
# URL: https://meu-modulo.vercel.app
```

#### Opção B: Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=dist
# URL: https://meu-modulo.netlify.app
```

#### Opção C: Hostinger / VPS

```bash
rsync -avz dist/ user@servidor:/var/www/modulo/
# URL: https://modulo.meuhub.app
```

### 3. Atualizar Manifest no Banco

```sql
UPDATE modulos_instalados
SET manifest = jsonb_set(
  manifest,
  '{url}',
  '"https://meu-modulo.vercel.app/"'
)
WHERE nome = 'Meu Módulo';
```

---

## 📚 Exemplos

Veja a pasta `/examples` para módulos completos:

- **mod-financeiro** - Gestão financeira (CRUD completo)
- **mod-tarefas** - Lista de tarefas (exemplo simples)
- **mod-dashboard** - Dashboard analítico (gráficos)

---

## ✅ Melhores Práticas

### Segurança

- ✅ **NUNCA** confie em tenantId/userId do body - sempre extrair do JWT
- ✅ **SEMPRE** validar JWT nas API routes (`authenticateModule`)
- ✅ **SEMPRE** filtrar queries por `tenant_id`
- ✅ Usar `created_by` para auditoria LGPD

### Performance

- ✅ Usar `useMemo` para cálculos complexos
- ✅ Lazy load bibliotecas pesadas (jsPDF, recharts)
- ✅ Virtualizar listas longas (react-virtual)
- ✅ Debounce em buscas (300ms)

### Code Quality

- ✅ Evitar `any` - criar tipos corretos
- ✅ Usar `logger.ts` ao invés de `console.log`
- ✅ Adicionar `try/catch` em todas as API calls
- ✅ Limpar useEffect (`return () => cleanup()`)

### UX

- ✅ Loading states em todas as operações
- ✅ Toast notifications (sonner)
- ✅ Validação de formulários (react-hook-form + zod)
- ✅ Mobile-friendly (Tailwind responsive)

### Desenvolvimento com Claude Code

- ✅ Manter `CLAUDE.md` atualizado no módulo
- ✅ Documentar decisões arquiteturais
- ✅ Criar checkpoints a cada feature (`save-checkpoint.sh`)
- ✅ Usar agents especializados (Explore, Plan, Bug Fixer)

---

## 🐛 Troubleshooting

### Módulo não carrega no Hub

**Sintoma:** Tela branca no iframe
**Causa:** CORS ou URL incorreta
**Solução:**

```javascript
// Verificar no console:
// 1. CORS headers
// 2. Erro de network
// 3. postMessage recebida
```

### API retorna 401 Unauthorized

**Sintoma:** Todas as requests retornam 401
**Causa:** JWT token inválido ou expirado
**Solução:**

```typescript
// Verificar no apiAdapter:
console.log('Token:', _apiConfig?.token?.substring(0, 20));

// Verificar expiração:
const payload = JSON.parse(atob(_apiConfig.token.split('.')[1]));
console.log('Expira em:', new Date(payload.exp * 1000));
```

### Dados de outro tenant aparecem

**Sintoma:** Multi-tenancy não funciona
**Causa:** Query não filtra por tenant_id
**Solução:**

```typescript
// ❌ ERRADO
const data = await prisma.tabela.findMany();

// ✅ CORRETO
const data = await prisma.tabela.findMany({
  where: { tenant_id: tenantId }  // tenantId do JWT!
});
```

### Memory leak ao trocar de módulo

**Sintoma:** Memória aumenta ao navegar
**Causa:** useEffect sem cleanup
**Solução:**

```typescript
useEffect(() => {
  const handler = () => { /* ... */ };
  window.addEventListener('message', handler);

  // ✅ SEMPRE fazer cleanup
  return () => {
    window.removeEventListener('message', handler);
  };
}, [deps]);
```

---

## 📞 Suporte

- **Documentação completa:** `/docs`
- **Exemplos de código:** `/examples`
- **Templates:** `/template`
- **Scripts úteis:** `/scripts`

---

**Versão:** 1.0.0
**Última Atualização:** 12 de Novembro de 2025
**Baseado em:** mod-financeiro v1.0.0 (95% funcional)

**Status:** ✅ Pronto para uso
