// ============================================================================
// useItems Hook - MODULE_TITLE
// Hook personalizado para gerenciar operações CRUD
// ============================================================================

import { useState, useEffect, useCallback } from 'react';
import { toast } from 'sonner';
import type {
  Item,
  CreateItemInput,
  UpdateItemInput,
  ItemFilters,
  PaginatedResponse,
  RequestStatus
} from '../types';

interface UseItemsOptions {
  apiUrl?: string;
  apiToken?: string;
  autoLoad?: boolean;
}

interface UseItemsReturn {
  items: Item[];
  status: RequestStatus;
  error: string | null;
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };

  // CRUD operations
  loadItems: (filters?: ItemFilters) => Promise<void>;
  createItem: (data: CreateItemInput) => Promise<Item | null>;
  updateItem: (id: string, data: UpdateItemInput) => Promise<Item | null>;
  deleteItem: (id: string) => Promise<boolean>;
  refreshItems: () => Promise<void>;
}

/**
 * Hook para gerenciar items do módulo MODULE_TITLE
 *
 * @example
 * const { items, loadItems, createItem, updateItem, deleteItem } = useItems({
 *   apiUrl: 'http://localhost:3000',
 *   apiToken: 'Bearer xyz...',
 *   autoLoad: true
 * });
 */
export function useItems(options: UseItemsOptions = {}): UseItemsReturn {
  const { apiUrl, apiToken, autoLoad = true } = options;

  const [items, setItems] = useState<Item[]>([]);
  const [status, setStatus] = useState<RequestStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  const [currentFilters, setCurrentFilters] = useState<ItemFilters>({});
  const [pagination, setPagination] = useState({
    total: 0,
    page: 1,
    limit: 50,
    totalPages: 0
  });

  /**
   * Carrega items da API com filtros opcionais
   */
  const loadItems = useCallback(async (filters: ItemFilters = {}) => {
    if (!apiUrl || !apiToken) {
      console.warn('[useItems] API não configurada ainda');
      return;
    }

    setStatus('loading');
    setError(null);
    setCurrentFilters(filters);

    try {
      // Construir query params
      const params = new URLSearchParams();
      if (filters.ativo !== undefined) params.append('ativo', String(filters.ativo));
      if (filters.search) params.append('search', filters.search);
      if (filters.page) params.append('page', String(filters.page));
      if (filters.limit) params.append('limit', String(filters.limit));

      // ADICIONE SEUS FILTROS PERSONALIZADOS AQUI
      // Exemplo:
      // if (filters.prioridade) params.append('prioridade', filters.prioridade);

      const url = `${apiUrl}/api/modules/MODULE_SLUG/items${params.toString() ? '?' + params.toString() : ''}`;

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': apiToken,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Erro ao carregar items: ${response.statusText}`);
      }

      const result: PaginatedResponse<Item> = await response.json();

      setItems(result.data);
      setPagination(result.pagination);
      setStatus('success');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Erro desconhecido';
      setError(message);
      setStatus('error');
      toast.error('Erro ao carregar items', {
        description: message
      });
    }
  }, [apiUrl, apiToken]);

  /**
   * Cria um novo item
   */
  const createItem = useCallback(async (data: CreateItemInput): Promise<Item | null> => {
    if (!apiUrl || !apiToken) {
      toast.error('API não configurada');
      return null;
    }

    setStatus('loading');
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/MODULE_SLUG/items`, {
        method: 'POST',
        headers: {
          'Authorization': apiToken,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        throw new Error(`Erro ao criar item: ${response.statusText}`);
      }

      const newItem: Item = await response.json();

      // Adicionar ao estado local (otimista)
      setItems(prev => [newItem, ...prev]);
      setPagination(prev => ({ ...prev, total: prev.total + 1 }));

      setStatus('success');
      toast.success('Item criado com sucesso!');

      return newItem;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Erro desconhecido';
      setError(message);
      setStatus('error');
      toast.error('Erro ao criar item', {
        description: message
      });
      return null;
    }
  }, [apiUrl, apiToken]);

  /**
   * Atualiza um item existente
   */
  const updateItem = useCallback(async (id: string, data: UpdateItemInput): Promise<Item | null> => {
    if (!apiUrl || !apiToken) {
      toast.error('API não configurada');
      return null;
    }

    setStatus('loading');
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/MODULE_SLUG/items/${id}`, {
        method: 'PUT',
        headers: {
          'Authorization': apiToken,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        throw new Error(`Erro ao atualizar item: ${response.statusText}`);
      }

      const updatedItem: Item = await response.json();

      // Atualizar no estado local
      setItems(prev => prev.map(item => item.id === id ? updatedItem : item));

      setStatus('success');
      toast.success('Item atualizado com sucesso!');

      return updatedItem;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Erro desconhecido';
      setError(message);
      setStatus('error');
      toast.error('Erro ao atualizar item', {
        description: message
      });
      return null;
    }
  }, [apiUrl, apiToken]);

  /**
   * Deleta um item
   */
  const deleteItem = useCallback(async (id: string): Promise<boolean> => {
    if (!apiUrl || !apiToken) {
      toast.error('API não configurada');
      return false;
    }

    setStatus('loading');
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/MODULE_SLUG/items/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': apiToken
        }
      });

      if (!response.ok) {
        throw new Error(`Erro ao deletar item: ${response.statusText}`);
      }

      // Remover do estado local
      setItems(prev => prev.filter(item => item.id !== id));
      setPagination(prev => ({ ...prev, total: prev.total - 1 }));

      setStatus('success');
      toast.success('Item deletado com sucesso!');

      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Erro desconhecido';
      setError(message);
      setStatus('error');
      toast.error('Erro ao deletar item', {
        description: message
      });
      return false;
    }
  }, [apiUrl, apiToken]);

  /**
   * Recarrega items com filtros atuais
   */
  const refreshItems = useCallback(async () => {
    await loadItems(currentFilters);
  }, [loadItems, currentFilters]);

  // Auto-carregar items na montagem se autoLoad = true
  useEffect(() => {
    if (autoLoad && apiUrl && apiToken) {
      loadItems();
    }
  }, [autoLoad, apiUrl, apiToken, loadItems]);

  return {
    items,
    status,
    error,
    pagination,
    loadItems,
    createItem,
    updateItem,
    deleteItem,
    refreshItems
  };
}
