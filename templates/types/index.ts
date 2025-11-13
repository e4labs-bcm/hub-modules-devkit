// ============================================================================
// Types - MODULE_TITLE
// Tipos TypeScript para o módulo
// ============================================================================

/**
 * Item do módulo MODULE_TITLE
 * Campos padrão: id, tenant_id, nome, descricao, ativo, created_at, updated_at
 *
 * CUSTOMIZE AQUI: Adicione campos específicos do seu módulo
 */
export interface Item {
  id: string;
  tenant_id: string;
  nome: string;
  descricao?: string | null;
  ativo: boolean;
  created_at: Date | string;
  updated_at: Date | string;

  // ADICIONE SEUS CAMPOS PERSONALIZADOS AQUI
  // Exemplo:
  // prioridade?: 'baixa' | 'media' | 'alta';
  // responsavel_id?: string;
  // data_vencimento?: Date | string;
}

/**
 * Dados para criar um novo item (sem id, tenant_id, timestamps)
 */
export type CreateItemInput = Omit<Item, 'id' | 'tenant_id' | 'created_at' | 'updated_at'>;

/**
 * Dados para atualizar um item (todos opcionais exceto o que você quer mudar)
 */
export type UpdateItemInput = Partial<Omit<Item, 'id' | 'tenant_id' | 'created_at'>>;

/**
 * Filtros para listagem de items
 */
export interface ItemFilters {
  ativo?: boolean;
  search?: string;  // Busca por nome ou descrição
  page?: number;
  limit?: number;

  // ADICIONE SEUS FILTROS PERSONALIZADOS AQUI
  // Exemplo:
  // prioridade?: 'baixa' | 'media' | 'alta';
  // responsavel_id?: string;
}

/**
 * Resposta paginada da API
 */
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

/**
 * Status de requisição
 */
export type RequestStatus = 'idle' | 'loading' | 'success' | 'error';
