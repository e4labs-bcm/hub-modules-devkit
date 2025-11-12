/**
 * API Adapter para Módulos Hub.app
 *
 * Cliente HTTP autenticado com JWT para comunicação com API Routes do Hub
 */

// Configuração da API (recebida do Hub via postMessage)
let _apiConfig: {
  baseUrl: string;
  token: string;
} | null = null;

/**
 * Armazena configuração da API recebida do Hub
 */
export function storeApiConfig(baseUrl: string, token: string) {
  console.log('[MODULE_NAME] 📡 Configurando API adapter:', {
    baseUrl,
    tokenLength: token.length,
    tokenStart: token.substring(0, 20) + '...',
  });

  _apiConfig = { baseUrl, token };
  console.log('[MODULE_NAME] ✅ API adapter configurado');
}

/**
 * Verifica se a API está configurada
 */
export function isApiConfigured(): boolean {
  return _apiConfig !== null && !!_apiConfig.baseUrl && !!_apiConfig.token;
}

/**
 * Reseta a configuração da API
 */
export function resetApiConfig() {
  _apiConfig = null;
}

/**
 * Helper interno para fazer requisições à API
 */
async function fetchApi<T = any>(
  path: string,
  options: RequestInit = {}
): Promise<{ data: T; pagination?: { limit: number; offset: number; total: number } }> {
  if (!_apiConfig) {
    throw new Error('[MODULE_NAME] API não configurada. Hub ainda não enviou credenciais.');
  }

  const url = `${_apiConfig.baseUrl}${path}`;

  console.log(`[MODULE_NAME] 📤 ${options.method || 'GET'} ${path}`);

  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${_apiConfig.token}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      console.error(`[MODULE_NAME] ❌ API Error ${response.status}:`, error);
      throw new Error(error.error || `HTTP ${response.status}`);
    }

    const result = await response.json();
    console.log(`[MODULE_NAME] ✅ ${options.method || 'GET'} ${path} - Success`);

    return result;
  } catch (error) {
    console.error(`[MODULE_NAME] ❌ Request failed:`, error);
    throw error;
  }
}

/**
 * API Client para seu módulo
 *
 * Substitua MODULE_NAME pelo nome do seu módulo
 * Exemplo: financeiroAPI, taskAPI, inventoryAPI
 */
export const moduleAPI = {
  // ==================== EXEMPLO: ITEMS ====================

  /**
   * Lista items
   */
  async getItems(params?: {
    limit?: number;
    offset?: number;
    // Adicione filtros específicos do seu módulo
  }) {
    const query = new URLSearchParams(
      Object.entries(params || {})
        .filter(([_, v]) => v !== undefined)
        .map(([k, v]) => [k, String(v)])
    ).toString();

    const path = `/api/modules/MODULE_NAME/items${query ? '?' + query : ''}`;
    return fetchApi(path);
  },

  /**
   * Busca um item por ID
   */
  async getItem(id: string) {
    return fetchApi(`/api/modules/MODULE_NAME/items/${id}`);
  },

  /**
   * Cria novo item
   */
  async createItem(data: {
    // Defina os campos do seu item
    name: string;
    description?: string;
  }) {
    return fetchApi('/api/modules/MODULE_NAME/items', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  /**
   * Atualiza item existente
   */
  async updateItem(id: string, data: Partial<{
    name: string;
    description: string;
  }>) {
    return fetchApi(`/api/modules/MODULE_NAME/items/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  /**
   * Deleta item
   */
  async deleteItem(id: string) {
    return fetchApi(`/api/modules/MODULE_NAME/items/${id}`, {
      method: 'DELETE',
    });
  },

  // ==================== ADICIONE MAIS ENDPOINTS ====================

  /**
   * Exemplo: Buscar resumo/estatísticas
   */
  async getSummary(params?: {
    startDate?: string;
    endDate?: string;
  }) {
    const query = new URLSearchParams(
      Object.entries(params || {})
        .filter(([_, v]) => v !== undefined)
        .map(([k, v]) => [k, String(v)])
    ).toString();

    const path = `/api/modules/MODULE_NAME/summary${query ? '?' + query : ''}`;
    return fetchApi(path);
  },
};
