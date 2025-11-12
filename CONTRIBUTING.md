# Contribuindo para o Hub.app Modules DevKit

Obrigado por considerar contribuir com o DevKit! 🎉

## 📋 Como Contribuir

### 1. Reportar Bugs

Se você encontrou um bug, por favor:

1. Verifique se o bug já foi reportado nas [Issues](https://github.com/e4labs-bcm/hub-modules-devkit/issues)
2. Se não, crie uma nova issue com:
   - Título claro e descritivo
   - Passos para reproduzir o bug
   - Comportamento esperado vs atual
   - Screenshots (se aplicável)
   - Informações do ambiente (OS, Node version, etc.)

### 2. Sugerir Melhorias

Ideias são bem-vindas! Para sugerir uma melhoria:

1. Abra uma issue com tag `enhancement`
2. Descreva claramente a melhoria proposta
3. Explique por que seria útil
4. Inclua exemplos de uso (se aplicável)

### 3. Contribuir com Código

#### Setup do Ambiente

```bash
# Clone o repositório
git clone https://github.com/e4labs-bcm/hub-modules-devkit.git
cd hub-modules-devkit

# Testar scripts
./scripts/create-module.sh teste "Teste" Package
```

#### Processo de Contribuição

1. **Fork** o repositório
2. **Clone** seu fork localmente
3. **Crie uma branch** para sua feature/fix:
   ```bash
   git checkout -b feature/minha-feature
   # ou
   git checkout -b fix/meu-bugfix
   ```
4. **Faça suas alterações** seguindo as convenções
5. **Teste** suas alterações
6. **Commit** com mensagens claras:
   ```bash
   git commit -m "feat: adicionar suporte a múltiplos ícones"
   git commit -m "fix: corrigir erro em create-module.sh"
   git commit -m "docs: atualizar QUICK_START.md"
   ```
7. **Push** para seu fork:
   ```bash
   git push origin feature/minha-feature
   ```
8. **Abra um Pull Request** no repositório principal

#### Convenções de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `style:` - Formatação (não afeta código)
- `refactor:` - Refatoração de código
- `test:` - Adicionar/modificar testes
- `chore:` - Manutenção (build, CI, etc.)

**Exemplos:**
```
feat: adicionar template para API routes com GraphQL
fix: corrigir substituição de placeholders no Windows
docs: adicionar exemplos de módulos complexos
refactor: simplificar lógica de install-module.sh
```

### 4. Melhorar Documentação

Documentação é crucial! Você pode:

- Corrigir typos
- Melhorar clareza
- Adicionar exemplos
- Traduzir para outros idiomas
- Criar tutoriais em vídeo

Arquivos de documentação:
- `README.md` - Documentação principal
- `INSTALL.md` - Instalação
- `QUICK_START.md` - Guia rápido
- `docs/CLAUDE_CODE_GUIDE.md` - Guia Claude Code
- `SUMMARY.md` - Resumo executivo

### 5. Criar Exemplos

Exemplos práticos ajudam muito! Considere criar:

- Módulo de exemplo completo (`examples/mod-exemplo/`)
- Vídeo tutorial
- Blog post
- Workshop/apresentação

## 🧪 Testando Alterações

### Testar Scripts

```bash
# Criar módulo de teste
./scripts/create-module.sh teste-contrib "Teste Contrib" Package

# Verificar estrutura criada
ls -la ~/Documents/Claude/hub-app-nextjs/packages/mod-teste-contrib

# Instalar no Hub (requer Hub.app rodando)
cd ~/Documents/Claude/hub-app-nextjs
./scripts/install-module.sh teste-contrib "Teste Contrib" Package

# Limpar
rm -rf packages/mod-teste-contrib
psql $DATABASE_URL -c "DELETE FROM modulos_instalados WHERE nome = 'Teste Contrib';"
```

### Testar Templates

```bash
# Verificar substituição de placeholders
grep -r "MODULE_NAME" template/
# Não deve retornar nada se já substituído

# Verificar sintaxe TypeScript
cd template
npx tsc --noEmit hubContext.ts
npx tsc --noEmit apiAdapter.ts
```

## 📝 Checklist do Pull Request

Antes de abrir seu PR, verifique:

- [ ] Código testado localmente
- [ ] Scripts executam sem erros
- [ ] Documentação atualizada (se aplicável)
- [ ] Commits seguem convenção
- [ ] Branch atualizada com `main`
- [ ] Sem conflitos com `main`
- [ ] Descrição clara do PR

## 🎯 Áreas que Precisam de Ajuda

Estas áreas sempre aceitam contribuições:

### Alta Prioridade

- [ ] **Exemplos completos** - Criar módulos de exemplo (tarefas, inventário, CRM)
- [ ] **Testes automatizados** - Scripts bash + template validation
- [ ] **Windows support** - Testar/ajustar scripts para Windows/WSL
- [ ] **CI/CD** - GitHub Actions para validar PRs

### Média Prioridade

- [ ] **CLI interativo** - Interface com inquirer.js
- [ ] **Templates adicionais** - GraphQL, tRPC, etc.
- [ ] **Componentes UI** - Design system reutilizável
- [ ] **Internacionalização** - i18n no template

### Baixa Prioridade

- [ ] **Tutoriais em vídeo**
- [ ] **Blog posts**
- [ ] **Tradução docs** (inglês, espanhol)
- [ ] **VSCode extension**

## 🤝 Código de Conduta

- Seja respeitoso e construtivo
- Aceite feedback de forma positiva
- Foque no que é melhor para a comunidade
- Demonstre empatia com outros colaboradores

## 💬 Canais de Comunicação

- **Issues:** Discussões técnicas e bugs
- **Pull Requests:** Revisão de código
- **Email:** labs@bemcomum.org

## 📚 Recursos Úteis

- [Hub.app Docs](https://docs.meuhub.app) (quando disponível)
- [Next.js Docs](https://nextjs.org/docs)
- [Prisma Docs](https://www.prisma.io/docs)
- [React Docs](https://react.dev)
- [Vite Docs](https://vitejs.dev)

## 🏆 Reconhecimento

Todos os contribuidores serão listados no README.md!

---

**Obrigado por contribuir!** Seu trabalho ajuda a comunidade inteira. 🚀

**Dúvidas?** Abra uma issue ou envie email para labs@bemcomum.org
