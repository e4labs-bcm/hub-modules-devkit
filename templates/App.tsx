// ============================================================================
// App.tsx - MODULE_TITLE
// Componente principal do módulo
// ============================================================================

import { useState, useEffect } from 'react';
import { Toaster } from 'sonner';
import { Plus, RefreshCw, Search } from 'lucide-react';
import { getHubContext, onHubContext } from './hubContext';
import { useItems } from './hooks/useItems';
import { ItemList } from './components/ItemList';
import { ItemForm } from './components/ItemForm';
import type { Item, CreateItemInput, UpdateItemInput } from './types';

function App() {
  const [context, setContext] = useState(getHubContext());
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingItem, setEditingItem] = useState<Item | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  // Configurar API quando receber contexto do Hub
  const [apiConfig, setApiConfig] = useState<{ apiUrl?: string; apiToken?: string }>({});

  // Hook para gerenciar items
  const {
    items,
    status,
    pagination,
    loadItems,
    createItem,
    updateItem,
    deleteItem,
    refreshItems
  } = useItems({
    apiUrl: apiConfig.apiUrl,
    apiToken: apiConfig.apiToken,
    autoLoad: true
  });

  // Escutar postMessage do Hub para receber apiUrl e apiToken
  useEffect(() => {
    const cleanup = onHubContext((data) => {
      console.log('[MODULE_SLUG] Contexto recebido do Hub:', {
        tenantId: data.tenantId,
        userId: data.userId,
        hasApiUrl: Boolean(data.apiUrl),
        hasApiToken: Boolean(data.apiToken)
      });

      setContext(data);
      setLoading(false);

      // Configurar API
      if (data.apiUrl && data.apiToken) {
        setApiConfig({
          apiUrl: data.apiUrl,
          apiToken: data.apiToken
        });
      }
    });

    // Fallback timeout
    const timeout = setTimeout(() => {
      const ctx = getHubContext();
      if (ctx) {
        setContext(ctx);
      }
      setLoading(false);
    }, 2000);

    return () => {
      cleanup();
      clearTimeout(timeout);
    };
  }, []);

  // Handlers
  const handleCreateItem = async (data: CreateItemInput) => {
    const created = await createItem(data);
    if (created) {
      setShowForm(false);
    }
  };

  const handleUpdateItem = async (data: UpdateItemInput) => {
    if (!editingItem) return;

    const updated = await updateItem(editingItem.id, data);
    if (updated) {
      setEditingItem(null);
      setShowForm(false);
    }
  };

  const handleEditClick = (item: Item) => {
    setEditingItem(item);
    setShowForm(true);
  };

  const handleFormCancel = () => {
    setShowForm(false);
    setEditingItem(null);
  };

  const handleToggleAtivo = async (id: string, ativo: boolean) => {
    await updateItem(id, { ativo });
  };

  const handleSearch = () => {
    loadItems({ search: searchQuery });
  };

  // Loading inicial
  if (loading || !context) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="text-center">
          <div className="animate-spin h-12 w-12 border-4 border-indigo-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600 font-medium">Carregando módulo...</p>
          <p className="text-gray-400 text-sm mt-1">MODULE_TITLE</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Toaster position="top-right" />

      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-4 flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">MODULE_TITLE</h1>
              <p className="text-sm text-gray-500 mt-0.5">
                {pagination.total} {pagination.total === 1 ? 'item' : 'items'}
              </p>
            </div>

            <div className="flex items-center space-x-3">
              {/* Botão Refresh */}
              <button
                onClick={refreshItems}
                disabled={status === 'loading'}
                className="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                title="Recarregar"
              >
                <RefreshCw className={`h-4 w-4 ${status === 'loading' ? 'animate-spin' : ''}`} />
              </button>

              {/* Botão Novo Item */}
              <button
                onClick={() => setShowForm(true)}
                className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <Plus className="h-4 w-4 mr-2" />
                Novo Item
              </button>
            </div>
          </div>

          {/* Search Bar */}
          <div className="pb-4">
            <div className="max-w-lg">
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Search className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                  placeholder="Buscar por nome ou descrição..."
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Debug Info (remover em produção) */}
        {process.env.NODE_ENV === 'development' && (
          <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg text-sm">
            <details>
              <summary className="font-medium text-blue-900 cursor-pointer">
                Debug Info (Desenvolvimento)
              </summary>
              <div className="mt-2 space-y-1 text-blue-800">
                <p><strong>Tenant ID:</strong> {context.tenantId}</p>
                <p><strong>User ID:</strong> {context.userId}</p>
                <p><strong>API URL:</strong> {apiConfig.apiUrl || 'Não configurado'}</p>
                <p><strong>API Token:</strong> {apiConfig.apiToken ? 'Configurado ✓' : 'Não configurado'}</p>
                <p><strong>Status:</strong> {status}</p>
                <p><strong>Items carregados:</strong> {items.length}</p>
              </div>
            </details>
          </div>
        )}

        {/* Lista de Items */}
        <ItemList
          items={items}
          loading={status === 'loading'}
          onEdit={handleEditClick}
          onDelete={deleteItem}
          onToggleAtivo={handleToggleAtivo}
        />
      </main>

      {/* Formulário Modal */}
      {showForm && (
        <ItemForm
          item={editingItem}
          onSubmit={editingItem ? handleUpdateItem : handleCreateItem}
          onCancel={handleFormCancel}
          loading={status === 'loading'}
        />
      )}
    </div>
  );
}

export default App;
