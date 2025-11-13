# Seeds - Dados de Desenvolvimento

Seeds SQL para popular banco de dados PostgreSQL local com dados de teste.

---

## 📋 Arquivos Disponíveis

| Arquivo | Descrição | Dependências |
|---------|-----------|--------------|
| `01-schema-base.sql` | **DDL completo** do Hub.app (tabelas, índices, functions) | Nenhuma |
| `02-dev-tenants.sql` | **3 tenants** de exemplo (Startup, PME, Corporação) | 01 |
| `03-dev-users.sql` | **9 usuários** (3 por tenant: 1 admin + 2 users) | 01, 02 |
| `04-dev-financeiro.sql` | **Dados do módulo Financeiro** (categorias + transações) | 01, 02, 03 |

---

## 🚀 Como Usar

### **Opção 1: Script Automatizado (Mac)**

```bash
# Setup completo (PostgreSQL + seeds)
bash scripts/setup-mac.sh
# Escolher "y" quando perguntar sobre seeds
```

### **Opção 2: Manual (qualquer OS)**

```bash
# 1. Criar banco (se não existir)
createdb hub_app_dev

# 2. Aplicar seeds na ordem
psql -d hub_app_dev -f seeds/01-schema-base.sql
psql -d hub_app_dev -f seeds/02-dev-tenants.sql
psql -d hub_app_dev -f seeds/03-dev-users.sql
psql -d hub_app_dev -f seeds/04-dev-financeiro.sql
```

### **Opção 3: Script único (concatenar)**

```bash
# Aplicar todos de uma vez
cat seeds/0*.sql | psql -d hub_app_dev
```

---

## 📊 Dados Criados

### **Tenants (3)**

| ID | Nome | Tipo |
|----|------|------|
| `11111111-1111-...` | Startup Tech LTDA | Pequena empresa |
| `22222222-2222-...` | Comércio PME S/A | Média empresa |
| `33333333-3333-...` | Corporação Nacional | Grande empresa |

### **Usuários (9 total - 3 por tenant)**

#### Tenant 1: Startup Tech LTDA
| Email | Nome | Role | Senha |
|-------|------|------|-------|
| admin@startup.dev | Admin Startup | admin_empresa | dev123 |
| joao@startup.dev | João Silva | usuario | dev123 |
| maria@startup.dev | Maria Santos | usuario | dev123 |

#### Tenant 2: Comércio PME S/A
| Email | Nome | Role | Senha |
|-------|------|------|-------|
| admin@pme.dev | Admin PME | admin_empresa | dev123 |
| carlos@pme.dev | Carlos Oliveira | gerente | dev123 |
| ana@pme.dev | Ana Costa | usuario | dev123 |

#### Tenant 3: Corporação Nacional
| Email | Nome | Role | Senha |
|-------|------|------|-------|
| admin@corp.dev | Admin Corporação | admin_empresa | dev123 |
| roberto@corp.dev | Roberto Almeida | gerente | dev123 |
| juliana@corp.dev | Juliana Ferreira | usuario | dev123 |

### **Módulo Financeiro (Tenant 1)**

- **7 categorias** (3 receitas + 4 despesas)
- **15 transações** (6 receitas + 9 despesas)
- **Período**: Últimos 3 meses
- **Saldo total**: ~R$ 17.950,00

---

## 🔄 Atualizar Schema Base

O arquivo `01-schema-base.sql` deve ser atualizado quando o Hub.app evoluir:

```bash
# Exportar schema mais recente do STAGING
bash scripts/update-schema-from-staging.sh

# Reaplicar no banco local
psql -d hub_app_dev -f seeds/01-schema-base.sql
```

---

## 🧹 Reset Completo

Para limpar e recomeçar do zero:

```bash
# Opção 1: Recriar banco
dropdb hub_app_dev
createdb hub_app_dev
cat seeds/0*.sql | psql -d hub_app_dev

# Opção 2: Limpar tabelas (mantém banco)
psql -d hub_app_dev -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
cat seeds/0*.sql | psql -d hub_app_dev
```

---

## ⚠️ Notas Importantes

1. **Senhas**: Todos os usuários usam senha `dev123` (bcrypt hash já incluso)
2. **IDs fixos**: Tenants e usuários têm UUIDs fixos (fácil para testes)
3. **Multi-tenancy**: Cada tenant vê apenas seus próprios dados
4. **Módulo Financeiro**: Só aplicável se migrations do módulo foram executadas
5. **Schema base**: Gerado automaticamente do staging (não editar manualmente)

---

## 🆘 Troubleshooting

### Erro: "relation does not exist"
```bash
# Aplicar schema base primeiro
psql -d hub_app_dev -f seeds/01-schema-base.sql
```

### Erro: "duplicate key value violates unique constraint"
```bash
# Seeds já foram aplicados. Para reaplicar:
dropdb hub_app_dev
createdb hub_app_dev
# Aplicar novamente
```

### Módulo Financeiro não tem dados
```bash
# Verificar se tabelas existem
psql -d hub_app_dev -c "\dt categorias_financeiras"

# Se não existir, aplicar migrations do módulo primeiro
cd packages/mod-financeiro
# Executar migrations...
```

---

## 📚 Ver Também

- `scripts/setup-mac.sh` - Setup automatizado para Mac
- `scripts/update-schema-from-staging.sh` - Atualizar schema do staging
- `CLAUDE.md` - Documentação completa do projeto

---

**Última Atualização**: 13/11/2025
