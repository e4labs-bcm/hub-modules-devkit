# 🤖 Guia de Desenvolvimento com Claude Code

Melhores práticas para desenvolver módulos Hub.app usando Claude Code (CLI/IDE).

---

## 📋 Configuração Inicial

### 1. CLAUDE.md no Módulo

Sempre crie um `CLAUDE.md` na raiz do seu módulo para manter contexto:

```markdown
# CLAUDE.md - Módulo [NOME]

**Status**: 🟡 Em desenvolvimento
**Última Atualização**: [DATA]

## Objetivo

[Descreva o propósito do módulo]

## Arquitetura

- Frontend: React + TypeScript + Vite
- Backend: Next.js API Routes + Prisma
- Database: PostgreSQL (multi-tenant)
- Auth: JWT via Hub.app

## Sessão Atual

### Tarefas Pendentes
- [ ] ...

### Bugs Conhecidos
- ...

### Decisões Arquiteturais
1. ...
```

### 2. Sistema de Sessões

Use o [claude-sessions-manager](https://github.com/e4labs-bcm/claude-sessions-manager) para recuperar contexto:

```bash
# Instalar
bash <(curl -s https://raw.githubusercontent.com/e4labs-bcm/claude-sessions-manager/main/install.sh)

# Listar sessões anteriores
claude-sessions

# Ver sessão específica
claude-view <sessionId>

# Buscar por palavra-chave
claude-search "módulo financeiro"
```

### 3. Checkpoints Frequentes

Use o sistema de checkpoints do hub-app-nextjs:

```bash
# Salvar checkpoint
bash ~/Documents/Claude/hub-app-nextjs/save-checkpoint.sh "Implementado CRUD de tarefas"

# Restaurar após crash
bash ~/Documents/Claude/hub-app-nextjs/restore-context.sh
```

---

## 🎯 Workflow Recomendado

### Início da Sessão

```bash
# 1. Verificar última sessão
claude-sessions | head -5

# 2. Ver contexto se necessário
claude-view <last-session-id>

# 3. Ler CLAUDE.md do módulo
cat packages/mod-[nome]/CLAUDE.md

# 4. Iniciar servidores
cd ~/Documents/Claude/hub-app-nextjs
npm run dev &  # Hub App (bg)

cd packages/mod-[nome]
npm run dev    # Módulo (fg)
```

### Durante Desenvolvimento

```bash
# A cada feature/bugfix significativo
bash save-checkpoint.sh "Feature: Lista de tarefas com filtros"

# A cada 30-60min ou antes de pausa
git add . && git commit -m "WIP: checkpoint automático"

# Atualizar CLAUDE.md frequentemente
# (Claude pode fazer isso por você!)
```

### Fim da Sessão

```bash
# 1. Commit final
git add .
git commit -m "feat(tarefas): Implementado CRUD completo"

# 2. Atualizar CLAUDE.md
# - Status atual
# - Próximos passos
# - Bugs conhecidos

# 3. Checkpoint final
bash save-checkpoint.sh "Sessão completa - CRUD funcionando"
```

---

## 💡 Comandos Úteis para Claude

### Criação de Módulo

**Você diz:**
```
Crie um novo módulo chamado "Tarefas" com ícone ListTodo
```

**Claude executa:**
```bash
cd ~/Documents/Claude/hub-modules-devkit
./scripts/create-module.sh tarefas "Tarefas" ListTodo

cd ~/Documents/Claude/hub-app-nextjs
./scripts/install-module.sh tarefas "Tarefas" ListTodo
```

### Leitura de Contexto

**Você diz:**
```
Mostre onde paramos na última sessão
```

**Claude executa:**
```bash
claude-sessions | head -5
cat packages/mod-tarefas/CLAUDE.md
git log --oneline | head -10
```

### Debug de Problemas

**Você diz:**
```
O módulo não está carregando no Hub, me ajude a debugar
```

**Claude verifica:**
1. ✅ Módulo registrado? `SELECT * FROM modulos_instalados WHERE nome = 'Tarefas'`
2. ✅ API routes existem? `ls src/app/api/modules/tarefas`
3. ✅ Prisma model? `grep "tarefas_items" prisma/schema.prisma`
4. ✅ Módulo rodando? `lsof -i :5173`
5. ✅ Hub rodando? `lsof -i :3000`
6. ✅ Console logs? (pede para verificar DevTools)

---

## 🧩 Agentes Especializados

### Task Tool - Explore Agent

Use para pesquisas no código:

**Você diz:**
```
Como funciona a autenticação JWT nas API routes?
```

**Claude usa:**
```
Task(subagent_type="Explore", prompt="Find and explain JWT authentication in API routes")
```

### Task Tool - Bug Fixer Agent

Use para resolver bugs complexos:

**Você diz:**
```
API está retornando 500, ajude a resolver
```

**Claude usa:**
```
Task(subagent_type="general-purpose", prompt="Debug 500 error in API routes - check logs, JWT validation, Prisma queries")
```

---

## 📝 Prompts Efetivos

### ✅ Bons Prompts

**Específicos e contextualizados:**

```
"Adicione um filtro de status na listagem de tarefas.
O status pode ser: 'pendente', 'em_andamento', 'concluida'.
Use um Select do Radix UI e atualize a API para aceitar
o parâmetro ?status=pendente"
```

```
"O módulo não está recebendo o apiToken via postMessage.
Verifique hubContext.ts e compare com o mod-financeiro
que está funcionando."
```

### ❌ Prompts Vagos

```
"Melhore o módulo"
```

```
"Tem um bug"
```

```
"Não funciona"
```

---

## 🔍 Debug Eficiente

### Problemas Comuns

#### 1. Módulo não carrega (tela branca)

**Claude deve verificar:**

```typescript
// 1. Console logs
// Deve aparecer:
📨 [tarefas] Mensagem recebida: ...
📡 Configurando API adapter...
✅ API adapter configurado!

// 2. Manifest correto?
cat packages/mod-tarefas/manifest.json

// 3. Módulo rodando?
lsof -i :5173
```

#### 2. API retorna 401

**Claude deve verificar:**

```typescript
// 1. Token está sendo enviado?
// Em apiAdapter.ts:
console.log('Token:', _apiConfig?.token?.substring(0, 20));

// 2. Middleware correto?
// Em route.ts:
const { tenantId, userId } = await authenticateModule(req);

// 3. Token expirado?
const payload = JSON.parse(atob(token.split('.')[1]));
console.log('Expira em:', new Date(payload.exp * 1000));
```

#### 3. Dados de outro tenant aparecem

**Claude deve verificar:**

```typescript
// ❌ ERRADO - sem tenant_id
const items = await prisma.tarefas_items.findMany();

// ✅ CORRETO - com tenant_id
const items = await prisma.tarefas_items.findMany({
  where: { tenant_id: tenantId }  // do JWT!
});
```

---

## 📚 Padrões de Código

### API Routes (Template)

```typescript
import { NextRequest } from 'next/server';
import { authenticateModule } from '@/lib/module-auth';
import { prisma } from '@/lib/prisma';
import { apiResponse, apiError } from '@/lib/api-response';

export async function GET(req: NextRequest) {
  try {
    // 1. Autenticar e extrair tenantId
    const { tenantId } = await authenticateModule(req);

    // 2. Parsear query params
    const searchParams = req.nextUrl.searchParams;
    const status = searchParams.get('status');

    // 3. Query com tenant_id (SEMPRE!)
    const items = await prisma.tarefas_items.findMany({
      where: {
        tenant_id: tenantId,  // 🔒 Multi-tenancy
        ...(status && { status }),
      },
      orderBy: { created_at: 'desc' },
    });

    // 4. Retornar com helper
    return apiResponse(items);
  } catch (error: any) {
    return apiError(error.message, 500);
  }
}
```

### Componente React (Template)

```typescript
import { useEffect, useState } from 'react';
import { moduleAPI } from '../../adapter/apiAdapter';
import { toast } from 'sonner';

export function ItemsList() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadItems();
  }, []);

  async function loadItems() {
    try {
      setLoading(true);
      const result = await moduleAPI.getItems();
      setItems(result.data);
    } catch (error) {
      toast.error('Erro ao carregar items');
      console.error(error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return <div>Carregando...</div>;
  }

  return (
    <div>
      {items.map(item => (
        <div key={item.id}>{item.name}</div>
      ))}
    </div>
  );
}
```

---

## 🎓 Aprendizado Progressivo

### Nível 1: Hello World
- Criar módulo básico
- Exibir "Hello World"
- Receber postMessage do Hub

### Nível 2: CRUD Simples
- Lista de items
- Criar item
- Editar item
- Deletar item

### Nível 3: Features Avançadas
- Filtros e busca
- Paginação
- Validação de formulários (zod)
- Loading states e error handling

### Nível 4: Real-time e UX
- Server-Sent Events (SSE)
- Notificações toast
- Drag & drop
- Keyboard shortcuts

### Nível 5: Produção
- Testes (Vitest)
- CI/CD (GitHub Actions)
- Monitoring (Sentry)
- Performance (lazy load, memoization)

---

## 🚨 Avisos Importantes

### ⚠️ NUNCA confie em dados do body para tenant_id

```typescript
// ❌ PERIGO! Qualquer usuário pode passar outro tenant_id
const body = await req.json();
const items = await prisma.items.findMany({
  where: { tenant_id: body.tenantId }  // ⚠️ NÃO FAZER ISSO!
});

// ✅ SEMPRE extrair do JWT
const { tenantId } = await authenticateModule(req);
const items = await prisma.items.findMany({
  where: { tenant_id: tenantId }  // ✅ Seguro!
});
```

### ⚠️ SEMPRE validar JWT

```typescript
// ❌ Endpoint sem autenticação
export async function GET(req: NextRequest) {
  const items = await prisma.items.findMany();  // ⚠️ Todos os dados!
  return Response.json(items);
}

// ✅ Endpoint protegido
export async function GET(req: NextRequest) {
  const { tenantId } = await authenticateModule(req);  // ✅ Valida token
  const items = await prisma.items.findMany({
    where: { tenant_id: tenantId }
  });
  return apiResponse(items);
}
```

### ⚠️ SEMPRE fazer cleanup em useEffect

```typescript
// ❌ Memory leak
useEffect(() => {
  window.addEventListener('message', handler);
  // ⚠️ Sem cleanup!
}, []);

// ✅ Com cleanup
useEffect(() => {
  window.addEventListener('message', handler);
  return () => {
    window.removeEventListener('message', handler);  // ✅ Limpa!
  };
}, []);
```

---

## 📊 Checklist de Qualidade

Antes de considerar o módulo "pronto":

### Backend
- [ ] Todas as API routes validam JWT (`authenticateModule`)
- [ ] Todas as queries filtram por `tenant_id`
- [ ] Campos `created_by` preenchidos (LGPD)
- [ ] Tratamento de erros (try/catch)
- [ ] CORS configurado (OPTIONS)
- [ ] Migrations aplicadas
- [ ] Prisma schema atualizado

### Frontend
- [ ] Recebe postMessage corretamente
- [ ] Configura apiAdapter com token
- [ ] Loading states em todas as operações
- [ ] Error handling com toast
- [ ] Validação de formulários
- [ ] Responsivo (mobile-friendly)
- [ ] useEffect com cleanup

### Documentação
- [ ] CLAUDE.md atualizado
- [ ] README com instruções
- [ ] Comentários em código complexo
- [ ] Tipos TypeScript completos

### Deploy
- [ ] Build sem erros (`npm run build`)
- [ ] Testes passando (se houver)
- [ ] URL de produção no manifest.json
- [ ] Módulo funcionando em produção

---

## 🎯 Exemplo: Sessão Completa

**Usuário:** "Crie um módulo de tarefas com CRUD completo"

**Claude:**

```bash
# 1. Criar módulo
./scripts/create-module.sh tarefas "Tarefas" ListTodo

# 2. Instalar no Hub
cd ../hub-app-nextjs
./scripts/install-module.sh tarefas "Tarefas" ListTodo

# 3. Checkpoint inicial
bash save-checkpoint.sh "Módulo tarefas criado"
```

**Claude (continua):**

```typescript
// 4. Editar App.tsx para adicionar lista de tarefas
// 5. Criar componentes (TaskList, TaskForm, TaskItem)
// 6. Implementar CRUD (create, read, update, delete)
// 7. Adicionar validação (react-hook-form + zod)
// 8. Testar no browser
```

**Claude (finaliza):**

```bash
# 9. Commit
git add .
git commit -m "feat(tarefas): CRUD completo implementado"

# 10. Checkpoint final
bash save-checkpoint.sh "CRUD de tarefas funcionando - pronto para testes"

# 11. Atualizar CLAUDE.md
# (Claude faz isso automaticamente)
```

---

## 💬 Frases Mágicas

Use estes prompts para aproveitar melhor o Claude Code:

### Planejamento
- "Planeje a implementação de [feature] antes de começar"
- "Crie um TODO list para implementar [módulo]"
- "Quais são os passos necessários para [tarefa]?"

### Pesquisa
- "Como o mod-financeiro implementa [feature]?"
- "Busque exemplos de [pattern] no hub-app-nextjs"
- "Explique a arquitetura de [componente]"

### Implementação
- "Implemente [feature] seguindo o padrão do mod-financeiro"
- "Adicione [funcionalidade] com validação e error handling"
- "Crie API route para [operação] com multi-tenancy"

### Debug
- "Debug o erro [mensagem de erro]"
- "Por que [comportamento inesperado]?"
- "Compare com mod-financeiro para entender o problema"

### Documentação
- "Atualize CLAUDE.md com o progresso atual"
- "Documente as decisões arquiteturais tomadas"
- "Crie README explicando como usar o módulo"

---

**Desenvolvido para:** Hub.app Modules DevKit v1.0.0
**Última Atualização:** 12 de Novembro de 2025

**Dica:** Mantenha este guia aberto enquanto desenvolve! 📖
