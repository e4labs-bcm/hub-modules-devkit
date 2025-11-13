-- ============================================================================
-- Seeds: Development Data - Módulo Financeiro
-- ============================================================================
--
-- Dados de exemplo para módulo Financeiro (se instalado)
-- - Categorias padrão (receitas e despesas)
-- - Transações de exemplo (últimos 3 meses)
--
-- ============================================================================

-- Verificar se tabelas do módulo financeiro existem
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'categorias_financeiras') THEN
    RAISE NOTICE '⚠️  Tabela categorias_financeiras não existe. Pulando seeds do módulo financeiro.';
    RAISE NOTICE '   Execute as migrations do módulo financeiro primeiro.';
    RETURN;
  END IF;
END $$;

-- ============================================================================
-- Categorias Financeiras (Tenant 1: Startup)
-- ============================================================================

-- Receitas
INSERT INTO categorias_financeiras (id, tenant_id, nome, tipo, cor, icone, created_at) VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Vendas', 'receita', '#10B981', 'ShoppingCart', NOW()),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Serviços', 'receita', '#3B82F6', 'Briefcase', NOW()),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Investimentos', 'receita', '#8B5CF6', 'TrendingUp', NOW())
ON CONFLICT DO NOTHING;

-- Despesas
INSERT INTO categorias_financeiras (id, tenant_id, nome, tipo, cor, icone, created_at) VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Salários', 'despesa', '#EF4444', 'Users', NOW()),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Fornecedores', 'despesa', '#F59E0B', 'Package', NOW()),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Marketing', 'despesa', '#EC4899', 'Megaphone', NOW()),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'Infraestrutura', 'despesa', '#6366F1', 'Server', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Transações de Exemplo (Tenant 1: Startup) - Últimos 3 meses
-- ============================================================================

-- Receitas (últimos 3 meses)
WITH vendas_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Vendas' LIMIT 1
),
servicos_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Serviços' LIMIT 1
)
INSERT INTO transacoes_financeiras (
  id, tenant_id, created_by, categoria_id, descricao, valor, data, tipo, status, created_at
) VALUES
-- Mês atual
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM vendas_cat), 'Venda de produto X', 5000.00, CURRENT_DATE - INTERVAL '5 days', 'receita', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM servicos_cat), 'Consultoria cliente ABC', 3500.00, CURRENT_DATE - INTERVAL '10 days', 'receita', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 (SELECT id FROM vendas_cat), 'Venda de produto Y', 2800.00, CURRENT_DATE - INTERVAL '15 days', 'receita', 'confirmado', NOW()),

-- Mês anterior
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM vendas_cat), 'Vendas mensais', 8500.00, CURRENT_DATE - INTERVAL '35 days', 'receita', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 (SELECT id FROM servicos_cat), 'Projeto especial', 12000.00, CURRENT_DATE - INTERVAL '40 days', 'receita', 'confirmado', NOW()),

-- Dois meses atrás
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM vendas_cat), 'Vendas Q3', 15000.00, CURRENT_DATE - INTERVAL '70 days', 'receita', 'confirmado', NOW())
ON CONFLICT DO NOTHING;

-- Despesas (últimos 3 meses)
WITH salarios_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Salários' LIMIT 1
),
fornecedores_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Fornecedores' LIMIT 1
),
marketing_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Marketing' LIMIT 1
),
infra_cat AS (
  SELECT id FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND nome = 'Infraestrutura' LIMIT 1
)
INSERT INTO transacoes_financeiras (
  id, tenant_id, created_by, categoria_id, descricao, valor, data, tipo, status, created_at
) VALUES
-- Mês atual
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM salarios_cat), 'Folha de pagamento Nov', 18000.00, CURRENT_DATE - INTERVAL '2 days', 'despesa', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 (SELECT id FROM fornecedores_cat), 'Fornecedor materiais', 4500.00, CURRENT_DATE - INTERVAL '7 days', 'despesa', 'pendente', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113',
 (SELECT id FROM marketing_cat), 'Campanha Google Ads', 2000.00, CURRENT_DATE - INTERVAL '12 days', 'despesa', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM infra_cat), 'AWS + Vercel', 850.00, CURRENT_DATE - INTERVAL '18 days', 'despesa', 'confirmado', NOW()),

-- Mês anterior
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM salarios_cat), 'Folha de pagamento Out', 18000.00, CURRENT_DATE - INTERVAL '33 days', 'despesa', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 (SELECT id FROM fornecedores_cat), 'Fornecedor serviços', 3200.00, CURRENT_DATE - INTERVAL '45 days', 'despesa', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111113',
 (SELECT id FROM marketing_cat), 'Evento networking', 1500.00, CURRENT_DATE - INTERVAL '50 days', 'despesa', 'confirmado', NOW()),

-- Dois meses atrás
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111',
 (SELECT id FROM salarios_cat), 'Folha de pagamento Set', 18000.00, CURRENT_DATE - INTERVAL '63 days', 'despesa', 'confirmado', NOW()),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111112',
 (SELECT id FROM infra_cat), 'Upgrade servidores', 5000.00, CURRENT_DATE - INTERVAL '75 days', 'despesa', 'confirmado', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Verificação e Estatísticas
-- ============================================================================

DO $$
DECLARE
  cat_count INTEGER;
  trans_count INTEGER;
  receitas_total NUMERIC;
  despesas_total NUMERIC;
BEGIN
  -- Contar categorias
  SELECT COUNT(*) INTO cat_count FROM categorias_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111';

  -- Contar transações
  SELECT COUNT(*) INTO trans_count FROM transacoes_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111';

  -- Totais
  SELECT COALESCE(SUM(valor), 0) INTO receitas_total
  FROM transacoes_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND tipo = 'receita';

  SELECT COALESCE(SUM(valor), 0) INTO despesas_total
  FROM transacoes_financeiras
  WHERE tenant_id = '11111111-1111-1111-1111-111111111111'
  AND tipo = 'despesa';

  RAISE NOTICE '';
  RAISE NOTICE '✓ Módulo Financeiro - Seeds aplicados:';
  RAISE NOTICE '  - Categorias: %', cat_count;
  RAISE NOTICE '  - Transações: %', trans_count;
  RAISE NOTICE '  - Receitas:   R$ %', TO_CHAR(receitas_total, 'FM999,999,990.00');
  RAISE NOTICE '  - Despesas:   R$ %', TO_CHAR(despesas_total, 'FM999,999,990.00');
  RAISE NOTICE '  - Saldo:      R$ %', TO_CHAR(receitas_total - despesas_total, 'FM999,999,990.00');
  RAISE NOTICE '';
  RAISE NOTICE 'Tenant de teste: Startup Tech LTDA';
END $$;
