# Documentation - Hub Modules DevKit

## 📋 Overview

Esta pasta contém **documentação técnica** sobre padrões, arquitetura e melhores práticas para criar módulos Hub.app de **qualidade production-ready**.

---

## 📚 Documentos Disponíveis

| Documento | Descrição | Quando Ler |
|-----------|-----------|------------|
| **[module-patterns](./module-patterns.md)** | Padrões de código, arquitetura, TypeScript, SQL | Antes de criar qualquer módulo |

---

## 🎯 Filosofia da Documentação

### Foco em Qualidade

Esta documentação **NÃO** é sobre "fazer rápido". É sobre **fazer certo**.

```markdown
❌ "Como criar 10 módulos em 1 hora"
✅ "Como criar 1 módulo production-ready em 2-3 horas"
```

### Padrões, Não Tutoriais

Documentamos **padrões e decisões arquiteturais**, não passo-a-passo básico.

```markdown
Para tutoriais passo-a-passo:
- README.md (raiz do projeto)
- .context/agents/ (playbooks práticos)

Para entender "por quê fazemos assim":
- .context/docs/ (arquitetura e decisões)
```

---

## 📖 Como Usar Esta Documentação

### Para Desenvolvedores Novos

```markdown
1. Leia CLAUDE.md (raiz do projeto)
   - Entenda status e histórico

2. Leia module-patterns.md
   - Entenda arquitetura padrão
   - Veja exemplos de código de qualidade

3. Leia agents playbooks (.context/agents/)
   - Siga workflows práticos
   - Use como checklist

4. Crie seu primeiro módulo
   - Consulte documentação quando necessário
```

### Para AI Assistants

```markdown
1. Leia TODA a documentação antes de começar
2. Priorize qualidade sobre velocidade
3. Siga TODOS os padrões documentados
4. Em dúvida, pergunte antes de criar código
```

---

## ⚠️ O Que Não Fazer

### Antipadrão 1: Pular Leitura da Documentação

```markdown
❌ "Vou criar baseado em outro módulo que vi"
✅ "Vou ler os padrões e aplicar corretamente"

Por quê? Você pode copiar bugs ou antipadrões.
```

### Antipadrão 2: Adaptar Padrões Sem Entender

```markdown
❌ "Vou mudar esse padrão porque prefiro assim"
✅ "Vou entender POR QUÊ o padrão existe antes de mudar"

Por quê? Padrões existem por razões (segurança, performance, etc).
```

### Antipadrão 3: Criar Documentação Duplicada

```markdown
❌ Criar README com mesma informação da documentação
✅ README = Quick Start, Docs = Padrões e Arquitetura

Por quê? Manutenção em 2 lugares = inconsistências.
```

---

## 🔄 Manutenção da Documentação

### Quando Atualizar

```markdown
Atualize a documentação quando:
- ✅ Padrão arquitetural muda
- ✅ Decisão técnica importante é tomada
- ✅ Bug crítico é descoberto (adicione ao "Antipadrões")
- ✅ Nova melhor prática é estabelecida

NÃO atualize para:
- ❌ Mudanças triviais de código
- ❌ Bugfixes específicos de um módulo
- ❌ Experimentos não validados
```

### Como Atualizar

```markdown
1. Edite o arquivo relevante
2. Atualize "Last Updated" no footer
3. Adicione nota no topo se mudança foi breaking
4. Commit: docs: update <file> - <reason>
```

---

## 📊 Hierarquia de Informação

```
CLAUDE.md (raiz)
├── Status geral do projeto
├── Histórico de fases
└── Referência rápida

.context/docs/
├── Arquitetura e decisões técnicas
├── Padrões de código
└── "Por quê fazemos assim"

.context/agents/
├── Workflows práticos
├── Checklists
└── "Como fazer passo-a-passo"

README.md (módulos)
├── Setup rápido
├── Como rodar
└── Troubleshooting
```

---

## 🎓 Princípios de Boa Documentação

### 1. Específico, Não Genérico

```markdown
❌ "Use boas práticas de TypeScript"
✅ "Zero `any`, use `unknown` + type guards (exemplo: [link])"
```

### 2. Com Exemplos Reais

```markdown
❌ "Valide inputs"
✅ "Valide inputs assim:
     if (!name || name.trim().length === 0) {
       return apiError('Name is required', 400);
     }"
```

### 3. Explique o "Por Quê"

```markdown
❌ "Use updateMany em vez de update"
✅ "Use updateMany para respeitar multi-tenancy:
     updateMany + WHERE tenant_id garante que só
     atualize itens do próprio tenant, mesmo se RLS falhar."
```

### 4. Evolução, Não Revolução

```markdown
Não reescreva documentação do zero.
Adicione, refine, melhore incrementalmente.
```

---

## 🚀 Contribuindo

### Adicionando Nova Documentação

```bash
# 1. Crie arquivo em .context/docs/
touch .context/docs/new-topic.md

# 2. Siga template:
# - Overview
# - Padrões
# - Antipadrões
# - Exemplos
# - Checklist

# 3. Atualize este README.md (tabela de documentos)

# 4. Commit
git add .context/docs/
git commit -m "docs: add new-topic documentation"
```

### Melhorando Documentação Existente

```bash
# 1. Edite arquivo
vim .context/docs/module-patterns.md

# 2. Atualize "Last Updated"

# 3. Commit com descrição clara
git commit -m "docs: add error handling patterns to module-patterns.md"
```

---

## 📞 Getting Help

### Hierarquia

1. **Self-Service** (80%)
   - Leia a documentação relevante
   - Consulte exemplos de código
   - Leia agents playbooks

2. **Consulta Interna** (15%)
   - Pergunte no time dev
   - Busque em issues do GitHub
   - Consulte código de referência (mod-financeiro)

3. **Escalar** (5%)
   - Problema arquitetural complexo
   - Decisão que afeta todos os módulos
   - Bug crítico de segurança

---

## ✅ Documentation Quality Checklist

Documentação de qualidade tem:

- [ ] **Clareza**: Qualquer dev entende em 10 minutos
- [ ] **Exemplos**: Código real, não pseudocódigo
- [ ] **Justificativa**: Explica "por quê", não só "como"
- [ ] **Atualizada**: Last Updated < 3 meses
- [ ] **Específica**: Zero ambiguidade ou vagueza
- [ ] **Revisada**: Pelo menos 1 dev revisou
- [ ] **Testada**: Exemplos foram testados e funcionam

---

## 🎯 Objetivo Final

Criar documentação que:

- ✅ Acelera onboarding de novos devs (30min → entende arquitetura)
- ✅ Reduz bugs (padrões previnem problemas comuns)
- ✅ Mantém consistência (todos os módulos seguem mesma estrutura)
- ✅ Facilita manutenção (decisões arquiteturais documentadas)
- ✅ Escala com o projeto (fácil adicionar novos padrões)

**Resumo**: Documentação é investimento, não custo.

---

**Created by**: Agatha Fiuza + Claude Code
**Philosophy**: "Document decisions, not code"
**Last Updated**: Nov 13, 2025
**Version**: 1.0.0
