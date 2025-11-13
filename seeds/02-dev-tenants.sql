-- ============================================================================
-- Seeds: Development Tenants
-- ============================================================================
--
-- 3 tenants de exemplo para desenvolvimento local
-- Perfis diferentes: pequena, média e grande empresa
--
-- ============================================================================

-- Tenant 1: Empresa Pequena (Startup)
INSERT INTO tenants (id, nome, tipo, created_at) VALUES
('11111111-1111-1111-1111-111111111111', 'Startup Tech LTDA', 'empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- Tenant 2: Empresa Média (PME)
INSERT INTO tenants (id, nome, tipo, created_at) VALUES
('22222222-2222-2222-2222-222222222222', 'Comércio PME S/A', 'empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- Tenant 3: Empresa Grande (Corporação)
INSERT INTO tenants (id, nome, tipo, created_at) VALUES
('33333333-3333-3333-3333-333333333333', 'Corporação Nacional', 'empresa', NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Verificação
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✓ 3 tenants criados:';
  RAISE NOTICE '  - Tenant 1: Startup Tech LTDA (11111111-...)';
  RAISE NOTICE '  - Tenant 2: Comércio PME S/A (22222222-...)';
  RAISE NOTICE '  - Tenant 3: Corporação Nacional (33333333-...)';
END $$;
