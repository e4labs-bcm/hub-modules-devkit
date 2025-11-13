# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [Unreleased]

### 🚀 Em Desenvolvimento

- [ ] Sistema de templates customizáveis
- [ ] Suporte a campos relacionais (foreign keys)
- [ ] Geração automática de testes unitários
- [ ] CLI interativo (modo wizard)

---

## [0.1.0] - 2025-11-13

### 🎉 Release Inicial

#### ✨ Features

- **Sistema de Criação de Módulos**
  - Comando `hubapp-devkit create` para criar módulos completos
  - Templates funcionais com CRUD completo (não mockado)
  - Suporte a TypeScript rigoroso (zero `any`)
  - Multi-tenancy por padrão (RLS + tenant isolation)

- **Sistema de Instalação**
  - Comando `hubapp-devkit install` para instalar módulos no Hub.app
  - Criação automática de migrations SQL
  - Registro automático no banco de dados
  - Criação automática de API routes
  - Atualização automática do Prisma schema

- **Sistema de Migrations**
  - Controle de versão estilo Git
  - Comandos: create, status, up, down
  - Tracking completo (checksums, timestamps, usuário)
  - Rollback seguro com confirmação

- **Sistema de Sincronização**
  - Sincronização Hub.app ↔ DevKit
  - Verificação de compatibilidade de versões
  - Detecção automática de desatualização

- **Sistema de Atualização** ⭐ NOVO!
  - Comando `hubapp-devkit update` - Atualiza para versão mais recente
  - Comando `hubapp-devkit rollback` - Volta para versão anterior
  - Comando `hubapp-devkit check-updates` - Verifica atualizações
  - Auto-check em background (1x por dia, cache 24h)
  - Detecção de breaking changes
  - Changelog completo antes de atualizar

- **Scripts de Setup Multi-plataforma**
  - macOS: Homebrew + PostgreSQL 16
  - Linux: apt/dnf/pacman + PostgreSQL 16
  - Windows: winget/Chocolatey + PostgreSQL 16
  - Seeds de desenvolvimento (3 tenants, 9 users, módulo Financeiro)

- **Contexto para AI Assistants**
  - Playbooks detalhados (.context/agents/)
  - Padrões de código production-ready (.context/docs/)
  - Filosofia: "Make it right, make it work, make it fast"

#### 📚 Documentation

- README.md completo com quick start
- QUICK_START.md com tutorial passo-a-passo
- INSTALL.md com instruções de instalação
- CONTRIBUTING.md com guia de contribuição
- docs/SETUP_GUIDE.md para setup multi-plataforma
- docs/DEVKIT_PLANNING.md com planejamento completo
- docs/UPDATE_SYSTEM.md com sistema de atualização
- docs/SYNC_STRATEGY.md com estratégia de sincronização
- .context/ com contexto completo para AI assistants

#### 🔧 Technical Stack

- Node.js 18+ (cross-platform)
- Commander.js (CLI framework)
- Chalk (terminal colors)
- Inquirer (prompts interativos)
- @octokit/rest (GitHub API)
- Semver (versionamento semântico)
- PostgreSQL 16 (database)
- Prisma ORM (database access)

#### ⚠️ Limitações Conhecidas

- Templates ainda não são 100% customizáveis via CLI
- Suporte a campos relacionais (foreign keys) pendente
- Testes unitários não são gerados automaticamente
- Modo wizard (interativo) não implementado

#### 🎯 Filosofia

**"Make it right, make it work, make it fast - in that order."**

- Qualidade > Velocidade
- Zero tolerância para `any` no TypeScript
- Segurança multi-tenant não negociável
- UI/UX de qualidade (loading, empty, error states)
- Documentação = Código (atualize junto)

---

## Notas de Versionamento

### Versionamento Semântico (MAJOR.MINOR.PATCH)

- **MAJOR**: Breaking changes (incompatível com versão anterior)
- **MINOR**: Novas features (compatível com versão anterior)
- **PATCH**: Bug fixes (compatível com versão anterior)

### Quando haverá Breaking Changes?

- Mudanças na estrutura de comandos CLI
- Mudanças na estrutura de templates gerados
- Mudanças no schema do banco de dados (migrations)
- Mudanças nos requisitos de versão do Hub.app

### Como atualizar com Breaking Changes?

1. Execute `hubapp-devkit check-updates` para ver o changelog
2. Leia o **Migration Guide** na seção de breaking changes
3. Execute `hubapp-devkit update` e confirme
4. Se algo quebrar, execute `hubapp-devkit rollback`

---

**Última atualização**: 13/11/2025
**Repositório**: https://github.com/e4labs-bcm/hub-modules-devkit
**Licença**: MIT
