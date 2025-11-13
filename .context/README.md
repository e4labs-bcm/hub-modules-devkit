# .context - Hub Modules DevKit

## 📋 Overview

Esta pasta contém **contexto para AI assistants** e **documentação técnica** para trabalhar com o Hub Modules DevKit seguindo padrões de **qualidade máxima**.

**Filosofia**: Código production-ready, não protótipos. Qualidade > Velocidade.

---

## 📁 Estrutura

```
.context/
├── README.md               ← Você está aqui
├── agents/                 ← Playbooks para AI assistants
│   ├── README.md          ← Overview dos agents
│   ├── module-creator.md  ← Como criar módulos perfeitamente
│   ├── api-developer.md   ← Como criar API routes seguras
│   └── feature-developer.md ← Como adicionar features sem quebrar
├── docs/                   ← Documentação técnica e padrões
│   ├── README.md          ← Overview da documentação
│   └── module-patterns.md ← Padrões de código e arquitetura
└── examples/               ← Exemplos práticos (futuro)
```

---

## 🤖 Para AI Assistants (Claude, ChatGPT, etc.)

### Quando Você For Trabalhar no DevKit

**1. Leia Primeiro (15-20 minutos)**:
```markdown
1. /CLAUDE.md (raiz) - Status do projeto
2. /.context/agents/README.md - Filosofia e princípios
3. /.context/agents/<task-specific>.md - Playbook da tarefa
4. /.context/docs/module-patterns.md - Padrões técnicos
```

**2. Durante Execução**:
- ✅ Siga TODOS os padrões documentados
- ✅ Prefira qualidade a velocidade
- ✅ Teste tudo antes de considerar "pronto"
- ✅ Documente decisões importantes

**3. Checklist Final**:
- [ ] TypeScript compila sem erros
- [ ] Zero `any` no código
- [ ] Testes manuais executados
- [ ] Multi-tenancy verificado
- [ ] Documentação atualizada

---

## 👨‍💻 Para Desenvolvedores Humanos

### Quick Start

```bash
# 1. Entenda o projeto
cat CLAUDE.md

# 2. Leia padrões de módulos
cat .context/docs/module-patterns.md

# 3. Escolha agent relevante
cat .context/agents/module-creator.md  # Para criar módulo
cat .context/agents/api-developer.md   # Para API routes
cat .context/agents/feature-developer.md # Para adicionar features

# 4. Siga o playbook + padrões
# 5. Lucro!
```

### Workflow Recomendado

```markdown
1. **Planejamento** (10-15min)
   - Leia playbook relevante
   - Entenda padrões a seguir
   - Identifique possíveis desafios

2. **Execução** (1-2h)
   - Siga passo-a-passo do playbook
   - Consulte padrões quando necessário
   - Use exemplos como referência

3. **Validação** (20-30min)
   - Execute checklist de qualidade
   - Teste end-to-end
   - Verifique multi-tenancy

4. **Documentação** (10min)
   - Atualize README se necessário
   - Adicione comentários em código complexo
```

---

## 📚 Conteúdo Detalhado

### Agents (/.context/agents/)

**Playbooks práticos para tarefas específicas**:

- **module-creator.md**: Como criar módulos novos perfeitamente
  - Estrutura completa
  - Customização de templates
  - Validação e testes
  - Instalação no Hub.app

- **api-developer.md**: Como criar API Routes seguras
  - Autenticação JWT
  - Multi-tenancy
  - Validação de inputs
  - Performance e caching

- **feature-developer.md**: Como adicionar features
  - Database-first approach
  - Integração sem breaking changes
  - Testing patterns
  - Refatoração quando necessário

### Docs (/.context/docs/)

**Documentação técnica e decisões arquiteturais**:

- **module-patterns.md**: Padrões de código
  - Arquitetura de módulos
  - TypeScript patterns
  - Custom hooks patterns
  - SQL best practices
  - UI/UX quality standards

---

## 🎯 Princípios Fundamentais

### 1. **Qualidade Acima de Tudo**

```markdown
❌ "Crie rápido, vamos refatorar depois"
✅ "Crie corretamente da primeira vez"

Por quê?
- Refatoração custa 10x mais
- Bugs em produção custam 100x mais
- Código ruim gera débito técnico infinito
```

### 2. **Zero Tolerância para `any`**

```typescript
// ❌ NUNCA
function process(data: any) { ... }

// ✅ SEMPRE
interface Data {
  id: string;
  name: string;
}

function process(data: unknown): Data {
  if (!isValidData(data)) {
    throw new Error('Invalid data');
  }
  return data;
}
```

### 3. **Segurança Não Negociável**

```typescript
// ✅ SEMPRE faça:
const { tenantId, userId } = await authenticateModule(req);

// ✅ SEMPRE filtre por tenant:
where: { tenant_id: tenantId }

// ✅ SEMPRE valide inputs:
if (!name || name.trim().length === 0) {
  return apiError('Invalid input', 400);
}
```

### 4. **UI/UX de Qualidade**

```typescript
// ✅ SEMPRE tenha:
- Loading states (skeleton, spinners)
- Empty states (mensagens úteis)
- Error states (mensagens claras)
- Responsivo (desktop + mobile)
```

### 5. **Documentação é Código**

```markdown
Documentação desatualizada = Código quebrado

✅ Atualize documentação junto com código
✅ Documente "por quê", não "o quê"
✅ Use exemplos reais, não pseudocódigo
```

---

## ⚠️ Antipadrões Comuns

### 1. **Pressa**

```markdown
Sintomas:
- "Vou fazer rápido e corrigir depois"
- Pular testes
- Copiar código sem entender

Consequência:
- Bugs em produção
- Débito técnico
- Refatoração cara

Solução:
- Siga o playbook completamente
- Teste antes de "pronto"
- Entenda antes de copiar
```

### 2. **Ignorar Multi-Tenancy**

```typescript
// ❌ PERIGO: Vaza dados entre tenants!
const items = await prisma.items.findMany();

// ✅ CORRETO: Sempre filtra por tenant
const items = await prisma.items.findMany({
  where: { tenant_id: tenantId },  // From JWT!
});
```

### 3. **Falta de Validação**

```typescript
// ❌ PERIGO: Aceita qualquer entrada
const item = await prisma.items.create({
  data: body,  // Body não validado!
});

// ✅ CORRETO: Valida primeiro
if (!body.name || body.name.trim().length === 0) {
  return apiError('Name is required', 400);
}

const sanitized = {
  name: body.name.trim(),
  description: body.description?.trim() || null,
};
```

---

## 📊 Quality Checklist

### Para Código Novo

- [ ] **TypeScript**: Zero `any`, interfaces completas
- [ ] **Segurança**: JWT auth + tenant isolation + input validation
- [ ] **Performance**: Queries com índices + paginação
- [ ] **UI/UX**: Loading + Empty + Error states
- [ ] **Testado**: CRUD completo + multi-tenancy + edge cases
- [ ] **Documentado**: README + comments em código complexo

### Para Features Novas

- [ ] **Impacto**: Entendi o que muda (DB, API, UI)
- [ ] **Database**: Migration criada e aplicada
- [ ] **API**: Endpoints atualizados/criados
- [ ] **UI**: Componentes atualizados
- [ ] **Integração**: Testado end-to-end
- [ ] **Sem Breaking**: Features antigas ainda funcionam

---

## 🚀 Como Começar

### Se Você é Novo no Projeto

```bash
# Dia 1: Leitura (2-3 horas)
1. Leia CLAUDE.md (30min)
2. Leia .context/agents/README.md (20min)
3. Leia .context/docs/module-patterns.md (60min)
4. Explore código de mod-financeiro (60min)

# Dia 2: Prática (4-6 horas)
1. Crie módulo de teste (2-3h)
2. Adicione feature ao módulo (1-2h)
3. Revise com senior dev (1h)

# Dia 3+: Produtivo
1. Comece a trabalhar em módulos reais
2. Consulte documentação quando necessário
```

### Se Você é AI Assistant

```markdown
1. Leia TODA a documentação antes de começar
2. Priorize qualidade absoluta sobre velocidade
3. Siga TODOS os padrões sem exceções
4. Em dúvida, pergunte ao usuário antes de criar código
5. Teste tudo antes de considerar "pronto"
```

---

## 📞 Getting Help

### Hierarquia de Suporte

1. **Self-Service** (80%)
   - Leia a documentação
   - Consulte playbooks
   - Veja exemplos em código existente

2. **Consulta Interna** (15%)
   - Pergunte no time
   - Busque issues no GitHub
   - Revise código de referência

3. **Escalar** (5%)
   - Problema arquitetural complexo
   - Decisão que afeta todos os módulos
   - Bug crítico de segurança

---

## 🎯 Objetivo Final

Criar módulos Hub.app que sejam:

✅ **Confiáveis**: Funcionam sempre, sem surpresas
✅ **Seguros**: Multi-tenancy perfeito, validações rigorosas
✅ **Performáticos**: <1s para 90% das operações
✅ **Manuteníveis**: Qualquer dev entende e modifica
✅ **Testados**: Bugs são exceção, não regra
✅ **Documentados**: Onboarding em <30 minutos

**Resumo**: Production-ready modules, not prototypes.

---

## 📝 Manutenção desta Pasta

### Quando Atualizar

```markdown
Atualize quando:
- ✅ Padrão importante muda
- ✅ Novo playbook é necessário
- ✅ Bug crítico vira antipadrão documentado
- ✅ Nova melhor prática é estabelecida

NÃO atualize para:
- ❌ Mudanças triviais
- ❌ Experimentos não validados
- ❌ Preferências pessoais não consensuadas
```

### Como Contribuir

```bash
# 1. Adicionar novo agent
touch .context/agents/new-agent.md
# Siga estrutura: Role, Context, Responsibilities, Patterns, Pitfalls

# 2. Adicionar nova documentação
touch .context/docs/new-pattern.md
# Siga estrutura: Overview, Patterns, Antipatterns, Examples, Checklist

# 3. Atualizar README relevante

# 4. Commit
git add .context/
git commit -m "docs: add <name> <type>"
```

---

**Created by**: Agatha Fiuza + Claude Code
**Philosophy**: "Make it work, make it right, make it fast - in that order."
**Last Updated**: Nov 13, 2025
**Version**: 1.0.0
