-- ============================================================================
-- Seeds: Development Users
-- ============================================================================
--
-- 9 usuários de teste (3 por tenant)
-- Perfis: 1 admin + 2 usuários comuns por empresa
--
-- SENHAS (bcrypt hash de "dev123"):
-- $2a$10$N9qo8uLOickgx2ZMRZoMye.IizjW3Y8uiGzPSLcP3YPpYCYDXGWqa
--
-- ============================================================================

-- ============================================================================
-- Tenant 1: Startup Tech LTDA
-- ============================================================================

-- Admin da Startup
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 'Admin Startup', 'admin@startup.dev', 'admin_empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 1 da Startup (Financeiro)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111',
 'João Silva', 'joao@startup.dev', 'usuario', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 2 da Startup (Vendas)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111',
 'Maria Santos', 'maria@startup.dev', 'usuario', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Tenant 2: Comércio PME S/A
-- ============================================================================

-- Admin da PME
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222',
 'Admin PME', 'admin@pme.dev', 'admin_empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 1 da PME (Gerente)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'Carlos Oliveira', 'carlos@pme.dev', 'gerente', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 2 da PME (Operador)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222',
 'Ana Costa', 'ana@pme.dev', 'usuario', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Tenant 3: Corporação Nacional
-- ============================================================================

-- Admin da Corporação
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333',
 'Admin Corporação', 'admin@corp.dev', 'admin_empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 1 da Corporação (Diretor)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333',
 'Roberto Almeida', 'roberto@corp.dev', 'gerente', NOW())
ON CONFLICT (id) DO NOTHING;

-- Usuário 2 da Corporação (Analista)
INSERT INTO perfis (id, tenant_id, nome, email, role, created_at) VALUES
('a3333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333',
 'Juliana Ferreira', 'juliana@corp.dev', 'usuario', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Criar contas Auth.js vinculadas (opcional - se usar Credentials)
-- ============================================================================

-- Vincular Admin Startup
INSERT INTO accounts (id, user_id, type, provider, provider_account_id) VALUES
(gen_random_uuid(), 'a1111111-1111-1111-1111-111111111111',
 'credentials', 'credentials', 'admin@startup.dev')
ON CONFLICT DO NOTHING;

-- Vincular Admin PME
INSERT INTO accounts (id, user_id, type, provider, provider_account_id) VALUES
(gen_random_uuid(), 'a2222222-2222-2222-2222-222222222221',
 'credentials', 'credentials', 'admin@pme.dev')
ON CONFLICT DO NOTHING;

-- Vincular Admin Corporação
INSERT INTO accounts (id, user_id, type, provider, provider_account_id) VALUES
(gen_random_uuid(), 'a3333333-3333-3333-3333-333333333331',
 'credentials', 'credentials', 'admin@corp.dev')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Verificação
-- ============================================================================

DO $$
DECLARE
  user_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM perfis
  WHERE tenant_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
  );

  RAISE NOTICE '✓ % usuários criados (3 por tenant)', user_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Credenciais de teste:';
  RAISE NOTICE '  Email: admin@startup.dev | Senha: dev123';
  RAISE NOTICE '  Email: admin@pme.dev     | Senha: dev123';
  RAISE NOTICE '  Email: admin@corp.dev    | Senha: dev123';
END $$;
