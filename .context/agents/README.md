# Agents Playbooks - Hub Modules DevKit

## 📋 Overview

Esta pasta contém **playbooks** (manuais) para AI assistants trabalharem no Hub Modules DevKit com **qualidade máxima**.

**Filosofia**: Devagar e sempre. Preferimos código **perfeito, testado e documentado** a código rápido e bugado.

---

## 🤖 Agents Disponíveis

| Agent | Quando Usar | Foco Principal |
|-------|-------------|----------------|
| **[module-creator](./module-creator.md)** | Criar novos módulos do zero | Arquitetura correta, código limpo, documentação completa |
| **[api-developer](./api-developer.md)** | Criar/manter API Routes | Segurança multi-tenant, performance, validação rigorosa |
| **[feature-developer](./feature-developer.md)** | Adicionar features a módulos existentes | Integração sem quebrar, testes, refatoração se necessário |

---

## 🎯 Princípios Fundamentais

### 1. **Qualidade > Velocidade**

```markdown
❌ ERRADO: "Crie o módulo rápido, vamos corrigir depois"
✅ CORRETO: "Crie o módulo perfeito. Revise tipos, validações, segurança e testes"
```

### 2. **Segurança Sempre**

Toda operação **DEVE**:
- ✅ Autenticar usuário (JWT)
- ✅ Isolar por tenant (multi-tenancy)
- ✅ Validar entradas
- ✅ Sanitizar outputs

### 3. **TypeScript Rigoroso**

```typescript
// ❌ NUNCA:
function process(data: any) { ... }
const result: any = ...;

// ✅ SEMPRE:
interface UserData {
  id: string;
  email: string;
}

function process(data: unknown): UserData {
  if (!isValidUserData(data)) {
    throw new Error('Invalid data');
  }
  return data;
}
```

### 4. **Testes e Validação**

Antes de considerar "pronto":
- ✅ TypeScript compila sem erros
- ✅ API testada com JWT real
- ✅ UI testada em desktop e mobile
- ✅ Multi-tenancy verificado (dados isolados)
- ✅ Performance aceitável (<1s para queries simples)
- ✅ Documentação atualizada

### 5. **Código Legível**

```typescript
// ❌ EVITE:
const x = await prisma.items.findMany({where:{t:id},take:50});

// ✅ PREFIRA:
const items = await prisma.items.findMany({
  where: { tenant_id: tenantId },
  take: 50,
  skip: offset,
  orderBy: { created_at: 'desc' },
});
```

---

## 🔄 Workflow Ideal

### Para Criar Novo Módulo

```markdown
1. **Planejamento** (10-15min)
   - Entender requisitos completos
   - Definir campos necessários
   - Mapear relacionamentos
   - Identificar validações

2. **Criação Base** (5min)
   - hubapp-devkit create <slug> "<Title>" <Icon>
   - Verificar estrutura gerada

3. **Customização** (30-60min)
   - Adicionar campos específicos em types/
   - Criar migration SQL completa
   - Atualizar componentes UI
   - Adicionar validações

4. **API Routes** (20-30min)
   - Instalar no Hub.app (hubapp-devkit install)
   - Adicionar endpoints customizados se necessário
   - Testar com JWT real
   - Verificar multi-tenancy

5. **Testes** (20-30min)
   - Testar CRUD completo
   - Testar filtros e paginação
   - Testar responsividade mobile
   - Testar isolamento de tenants

6. **Documentação** (10-15min)
   - Atualizar README.md do módulo
   - Documentar campos customizados
   - Documentar endpoints adicionais

7. **Revisão Final** (10-15min)
   - Revisar código (sem any, sem console.log)
   - Revisar SQL (índices, constraints)
   - Revisar UI/UX (acessibilidade, erros)

TOTAL: **~2-3 horas para módulo production-ready**
```

### Para Adicionar Feature

```markdown
1. **Análise de Impacto** (15-20min)
   - O que precisa mudar? (DB, API, UI)
   - Afeta outros módulos?
   - Tem breaking changes?

2. **Database First** (10-15min)
   - Escrever migration SQL
   - Aplicar e testar
   - Atualizar Prisma schema

3. **API Second** (20-30min)
   - Atualizar routes existentes
   - Adicionar novos endpoints se necessário
   - Testar com Postman/curl

4. **UI Third** (30-45min)
   - Atualizar tipos TypeScript
   - Atualizar componentes
   - Adicionar validações

5. **Integração** (20-30min)
   - Testar fluxo completo
   - Verificar edge cases
   - Testar performance

6. **Documentação** (10min)
   - Atualizar README
   - Comentar código complexo

TOTAL: **~2 horas para feature production-ready**
```

---

## 📚 Como Usar os Agents

### Opção 1: Leitura Manual

```markdown
1. Abra o agent relevante (module-creator.md, etc.)
2. Leia todo o conteúdo (15-20 minutos)
3. Siga os padrões e evite os antipadrões
4. Use os comandos fornecidos
```

### Opção 2: Contexto para AI

```markdown
Se você é um AI assistant:

1. Leia o agent playbook COMPLETO antes de começar
2. Siga TODOS os padrões listados
3. EVITE TODOS os antipadrões listados
4. Em caso de dúvida, prefira qualidade a velocidade
5. Sempre teste antes de considerar "pronto"
```

---

## ⚠️ Antipadrões Comuns

### 1. Pressa (Maior Inimigo da Qualidade)

```markdown
❌ "Vou criar rápido e corrigir depois"
✅ "Vou criar correto da primeira vez"

Por quê? Refatoração custa 10x mais que fazer certo logo.
```

### 2. Pular Testes

```markdown
❌ "Código compila, deve estar funcionando"
✅ "Vou testar CRUD completo com dados reais"

Por quê? Bugs em produção custam 100x mais que testes locais.
```

### 3. Copiar e Colar Sem Entender

```markdown
❌ "Copiei esse código de outro módulo"
✅ "Entendi o pattern e adaptei para este caso"

Por quê? Código copiado sem entender gera bugs sutis.
```

### 4. Ignorar Multi-Tenancy

```markdown
❌ "Funciona no meu teste local"
✅ "Testei com 2 tenants diferentes e dados estão isolados"

Por quê? Vazamento de dados entre tenants é CRÍTICO.
```

### 5. `any` no TypeScript

```markdown
❌ "Coloquei any porque não sei o tipo"
✅ "Criei interface específica ou usei unknown + type guard"

Por quê? any = 0 segurança de tipos = bugs runtime.
```

---

## 📊 Checklist de Qualidade

### Para Código Novo

- [ ] **TypeScript Rigoroso**
  - [ ] Zero `any` (use `unknown` + type guards)
  - [ ] Todas interfaces documentadas
  - [ ] Nomes descritivos (não `data`, `temp`, `x`)

- [ ] **Segurança**
  - [ ] JWT validado em todas rotas
  - [ ] tenant_id em todas queries
  - [ ] Inputs validados (tipo, tamanho, formato)
  - [ ] Sem SQL injection (queries parametrizadas)

- [ ] **Performance**
  - [ ] Queries usam índices
  - [ ] Paginação implementada
  - [ ] Cálculos caros em useMemo
  - [ ] Componentes pesados em React.memo

- [ ] **UX/UI**
  - [ ] Loading states (skeleton, spinners)
  - [ ] Error states (mensagens úteis)
  - [ ] Empty states (instruções claras)
  - [ ] Responsivo (desktop + mobile)

- [ ] **Testado**
  - [ ] CRUD completo testado
  - [ ] Multi-tenancy testado (2+ tenants)
  - [ ] Edge cases testados (lista vazia, etc.)
  - [ ] Performance aceitável (<1s queries)

- [ ] **Documentado**
  - [ ] README atualizado
  - [ ] Comentários em código complexo
  - [ ] API endpoints documentados
  - [ ] Tipos exportados e documentados

---

## 🎓 Filosofia: Craftsmanship Over Speed

### O Que Valorizamos

```markdown
1. Código que outro dev entende em 5 minutos
2. Código que funciona em 1 ano sem manutenção
3. Código que escala para 100k usuários
4. Código que passa code review rigoroso
```

### O Que Não Valorizamos

```markdown
1. "Funciona na minha máquina"
2. "Vou refatorar depois" (spoiler: nunca refatora)
3. "É só um hotfix rápido" (vira dívida técnica)
4. "O usuário não vai notar" (vai notar)
```

---

## 📞 Getting Help

### Hierarquia de Suporte

1. **Self-Service** (80% dos casos)
   - Leia o agent playbook relevante
   - Consulte exemplos em .context/examples/
   - Leia CLAUDE.md para arquitetura geral

2. **Documentação** (15% dos casos)
   - docs/ para padrões gerais
   - README.md de cada módulo
   - Código de módulos existentes (mod-financeiro é referência)

3. **Ask Senior Dev** (5% dos casos)
   - Decisões arquiteturais
   - Breaking changes
   - Problema que você não entende após 1h investigando

---

## 🚀 Objetivo Final

Criar módulos Hub.app que sejam:

- ✅ **Confiáveis**: Funcionam sempre, sem surpresas
- ✅ **Seguros**: Multi-tenancy perfeito, validações rigorosas
- ✅ **Performáticos**: <1s para 90% das operações
- ✅ **Manuteníveis**: Qualquer dev entende e modifica
- ✅ **Testados**: Bugs são exceção, não regra
- ✅ **Documentados**: Onboarding em <30 minutos

**Resumo**: Módulos production-ready, não protótipos.

---

**Created by**: Agatha Fiuza + Claude Code
**Philosophy**: "Make it right, make it work, make it fast - in that order."
**Last Updated**: Nov 13, 2025
**Version**: 1.0.0
