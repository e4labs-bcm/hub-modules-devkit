# Module Patterns - Hub.app DevKit

## 📋 Overview

Este documento define os padrões de qualidade para módulos Hub.app criados com o DevKit. Foco total em **código production-ready**, não protótipos.

---

## 🏗️ Arquitetura de Módulos

### Estrutura Padrão

```
packages/mod-<slug>/
├── adapter/
│   └── apiAdapter.ts           # API client (fetch wrapper)
├── app/
│   ├── index.html              # HTML entry point
│   ├── vite.config.ts          # Vite configuration
│   ├── tailwind.config.js      # Tailwind CSS config
│   ├── tsconfig.json           # TypeScript config
│   └── src/
│       ├── main.tsx            # React entry point
│       ├── App.tsx             # Main app component (230 lines)
│       ├── hubContext.ts       # Hub integration (postMessage)
│       ├── index.css           # Global CSS (Tailwind)
│       ├── types/
│       │   └── index.ts        # TypeScript interfaces (70 lines)
│       ├── hooks/
│       │   └── useItems.ts     # CRUD hook (270 lines)
│       ├── components/
│       │   ├── ItemList.tsx    # List view (240 lines)
│       │   └── ItemForm.tsx    # Form modal (230 lines)
│       └── utils/              # Helper functions (custom)
├── migrations/
│   └── YYYYMMDD_<slug>.sql     # Database schema
├── manifest.json               # Module metadata
├── package.json                # Dependencies
└── README.md                   # Module documentation
```

---

## 🎯 Quality Standards

### 1. TypeScript (Zero Tolerance for `any`)

#### ✅ **Boas Práticas**

```typescript
// types/index.ts - Interfaces completas
export interface Item {
  id: string;
  tenant_id: string;
  created_by?: string;
  name: string;
  description?: string | null;
  status?: 'pending' | 'in_progress' | 'done' | 'cancelled';
  priority?: 'low' | 'medium' | 'high';
  created_at: Date | string;
  updated_at: Date | string;
}

// Input/Output types derivados
export type CreateItemInput = Omit<
  Item,
  'id' | 'tenant_id' | 'created_at' | 'updated_at'
>;

export type UpdateItemInput = Partial<
  Omit<Item, 'id' | 'tenant_id' | 'created_at'>
>;

// Filters com optional fields
export interface ItemFilters {
  search?: string;
  status?: string;
  priority?: string;
  from_date?: string;
  to_date?: string;
}

// Response types
export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    limit: number;
    offset: number;
    total: number;
  };
}

export type RequestStatus = 'idle' | 'loading' | 'success' | 'error';
```

#### ❌ **Antipadrões**

```typescript
// NUNCA faça isso:
function process(data: any) { ... }
const result: any = await fetch(...);
const items: any[] = [];

// Use unknown + type guards:
function isItem(data: unknown): data is Item {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'name' in data
  );
}

function process(data: unknown): Item {
  if (!isItem(data)) {
    throw new Error('Invalid item data');
  }
  return data;
}
```

---

### 2. Custom Hooks (Separation of Concerns)

#### useItems.ts - Estado e Lógica de Negócio

```typescript
import { useState, useCallback, useEffect } from 'react';
import { Item, CreateItemInput, UpdateItemInput, ItemFilters } from '../types';

interface UseItemsOptions {
  apiUrl?: string;
  apiToken?: string;
  autoLoad?: boolean;
}

export function useItems(options: UseItemsOptions = {}) {
  const { apiUrl, apiToken, autoLoad = true } = options;

  // Estado
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Carregar items
  const loadItems = useCallback(async (filters: ItemFilters = {}) => {
    if (!apiUrl || !apiToken) return;

    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams();
      if (filters.search) params.set('search', filters.search);
      if (filters.status) params.set('status', filters.status);
      if (filters.priority) params.set('priority', filters.priority);

      const response = await fetch(`${apiUrl}/api/modules/items?${params}`, {
        headers: { Authorization: `Bearer ${apiToken}` },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const result = await response.json();
      setItems(result.data || []);
    } catch (err: any) {
      setError(err.message);
      console.error('Error loading items:', err);
    } finally {
      setLoading(false);
    }
  }, [apiUrl, apiToken]);

  // Criar item
  const createItem = useCallback(async (data: CreateItemInput) => {
    if (!apiUrl || !apiToken) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/items`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiToken}`,
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || `HTTP ${response.status}`);
      }

      const newItem: Item = await response.json();

      // Atualização otimista
      setItems((prev) => [newItem, ...prev]);

      return newItem;
    } catch (err: any) {
      setError(err.message);
      console.error('Error creating item:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [apiUrl, apiToken]);

  // Atualizar item
  const updateItem = useCallback(async (id: string, data: UpdateItemInput) => {
    if (!apiUrl || !apiToken) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/items/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiToken}`,
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      // Atualização otimista
      setItems((prev) =>
        prev.map((item) =>
          item.id === id ? { ...item, ...data, updated_at: new Date() } : item
        )
      );
    } catch (err: any) {
      setError(err.message);
      console.error('Error updating item:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [apiUrl, apiToken]);

  // Deletar item
  const deleteItem = useCallback(async (id: string) => {
    if (!apiUrl || !apiToken) return;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/api/modules/items/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${apiToken}` },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      // Atualização otimista
      setItems((prev) => prev.filter((item) => item.id !== id));
    } catch (err: any) {
      setError(err.message);
      console.error('Error deleting item:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [apiUrl, apiToken]);

  // Recarregar
  const refreshItems = useCallback(
    (filters?: ItemFilters) => loadItems(filters),
    [loadItems]
  );

  // Auto-load
  useEffect(() => {
    if (autoLoad && apiUrl && apiToken) {
      loadItems();
    }
  }, [autoLoad, apiUrl, apiToken, loadItems]);

  return {
    items,
    loading,
    error,
    loadItems,
    createItem,
    updateItem,
    deleteItem,
    refreshItems,
  };
}
```

---

### 3. Components (UI/UX de Qualidade)

#### ItemList.tsx - Desktop + Mobile

```typescript
import React, { useState } from 'react';
import { Pencil, Trash2, Loader2 } from 'lucide-react';
import { Item } from '../types';

interface ItemListProps {
  items: Item[];
  loading: boolean;
  onEdit: (item: Item) => void;
  onDelete: (id: string) => void;
}

export function ItemList({ items, loading, onEdit, onDelete }: ItemListProps) {
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const handleDelete = async (id: string) => {
    if (!confirm('Tem certeza que deseja deletar este item?')) return;

    setDeletingId(id);
    try {
      await onDelete(id);
    } finally {
      setDeletingId(null);
    }
  };

  // Loading state
  if (loading && items.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
      </div>
    );
  }

  // Empty state
  if (items.length === 0) {
    return (
      <div className="text-center py-12 text-gray-500">
        <p className="text-lg font-medium">Nenhum item encontrado</p>
        <p className="text-sm mt-2">Clique em "Novo Item" para criar o primeiro</p>
      </div>
    );
  }

  return (
    <>
      {/* Desktop: Table */}
      <div className="hidden md:block overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Nome
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Descrição
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Status
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                Ações
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {items.map((item) => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm font-medium text-gray-900">
                  {item.name}
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  {item.description || '-'}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`px-2 py-1 rounded text-xs ${
                      item.status === 'done'
                        ? 'bg-green-100 text-green-800'
                        : item.status === 'in_progress'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {item.status || 'pending'}
                  </span>
                </td>
                <td className="px-4 py-3 text-right space-x-2">
                  <button
                    onClick={() => onEdit(item)}
                    className="text-blue-600 hover:text-blue-800"
                    title="Editar"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(item.id)}
                    disabled={deletingId === item.id}
                    className="text-red-600 hover:text-red-800 disabled:opacity-50"
                    title="Deletar"
                  >
                    {deletingId === item.id ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Trash2 className="h-4 w-4" />
                    )}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile: Cards */}
      <div className="md:hidden space-y-4">
        {items.map((item) => (
          <div key={item.id} className="bg-white rounded-lg shadow p-4">
            <div className="flex justify-between items-start mb-2">
              <h3 className="font-medium text-gray-900">{item.name}</h3>
              <div className="flex space-x-2">
                <button
                  onClick={() => onEdit(item)}
                  className="text-blue-600"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                <button
                  onClick={() => handleDelete(item.id)}
                  disabled={deletingId === item.id}
                  className="text-red-600 disabled:opacity-50"
                >
                  {deletingId === item.id ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Trash2 className="h-4 w-4" />
                  )}
                </button>
              </div>
            </div>
            {item.description && (
              <p className="text-sm text-gray-600 mb-2">{item.description}</p>
            )}
            {item.status && (
              <span
                className={`inline-block px-2 py-1 rounded text-xs ${
                  item.status === 'done'
                    ? 'bg-green-100 text-green-800'
                    : item.status === 'in_progress'
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-gray-100 text-gray-800'
                }`}
              >
                {item.status}
              </span>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
```

---

### 4. Database Migrations (Qualidade SQL)

```sql
-- migrations/YYYYMMDD_module.sql

-- ============================================================================
-- Módulo: <Nome do Módulo>
-- Descrição: <O que esta migration faz>
-- Data: YYYY-MM-DD
-- ============================================================================

-- Criar tabela principal
CREATE TABLE IF NOT EXISTS module_items (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-tenancy
  tenant_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,

  -- Audit fields
  created_by UUID REFERENCES perfis(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Business fields
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  priority VARCHAR(20) DEFAULT 'low',
  due_date TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT status_check CHECK (status IN ('pending', 'in_progress', 'done', 'cancelled')),
  CONSTRAINT priority_check CHECK (priority IN ('low', 'medium', 'high'))
);

-- Índices para performance
CREATE INDEX idx_module_items_tenant ON module_items(tenant_id);
CREATE INDEX idx_module_items_created_by ON module_items(created_by);
CREATE INDEX idx_module_items_status ON module_items(status);
CREATE INDEX idx_module_items_priority ON module_items(priority);
CREATE INDEX idx_module_items_due_date ON module_items(due_date) WHERE due_date IS NOT NULL;

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_module_items_updated_at
  BEFORE UPDATE ON module_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para notificações real-time (opcional)
CREATE OR REPLACE FUNCTION notify_module_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    'module_changes',
    json_build_object(
      'operation', TG_OP,
      'record', row_to_json(NEW),
      'tenant_id', NEW.tenant_id
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER module_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON module_items
  FOR EACH ROW EXECUTE FUNCTION notify_module_change();

-- Comentários (documentação no banco)
COMMENT ON TABLE module_items IS 'Tabela principal do módulo <Nome>';
COMMENT ON COLUMN module_items.tenant_id IS 'ID da empresa (multi-tenancy)';
COMMENT ON COLUMN module_items.created_by IS 'Usuário que criou (auditoria)';
COMMENT ON COLUMN module_items.status IS 'Status: pending, in_progress, done, cancelled';
COMMENT ON COLUMN module_items.priority IS 'Prioridade: low, medium, high';

-- ============================================================================
-- Fim da migration
-- ============================================================================
```

---

## 📚 Best Practices

### 1. Error Handling

```typescript
// ✅ SEMPRE trate erros
try {
  const response = await fetch(url);

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || `HTTP ${response.status}`);
  }

  const data = await response.json();
  return data;
} catch (error: any) {
  console.error('[Context] Error:', error);
  // Show user-friendly message
  toast.error('Erro ao carregar dados. Tente novamente.');
  throw error;
}
```

### 2. Loading States

```typescript
// ✅ SEMPRE mostre loading
const [loading, setLoading] = useState(false);

if (loading) {
  return <LoadingSkeleton />;
}

// OU inline
<button disabled={loading}>
  {loading ? <Loader2 className="animate-spin" /> : 'Salvar'}
</button>
```

### 3. Empty States

```typescript
// ✅ SEMPRE mostre empty states úteis
if (items.length === 0) {
  return (
    <div className="text-center py-12">
      <p className="text-lg">Nenhum item encontrado</p>
      <p className="text-sm text-gray-500 mt-2">
        Clique em "Novo Item" para começar
      </p>
    </div>
  );
}
```

### 4. Performance

```typescript
// ✅ Memoize cálculos pesados
const stats = useMemo(() => {
  return {
    total: items.length,
    done: items.filter((i) => i.status === 'done').length,
    pending: items.filter((i) => i.status === 'pending').length,
  };
}, [items]);

// ✅ Memoize componentes pesados
const ItemCard = React.memo(({ item }: { item: Item }) => {
  // ...
});
```

---

## ✅ Quality Checklist

- [ ] **TypeScript**: Zero `any`, interfaces completas
- [ ] **Hooks**: Lógica separada da UI
- [ ] **Components**: Desktop + Mobile responsive
- [ ] **Loading States**: Skeleton, spinners
- [ ] **Empty States**: Mensagens úteis
- [ ] **Error Handling**: Try-catch + user messages
- [ ] **Migrations**: Índices, constraints, comentários
- [ ] **Performance**: Memoization onde necessário
- [ ] **Accessibility**: Labels, ARIA, keyboard navigation
- [ ] **Testing**: CRUD testado end-to-end

---

**Created by**: Agatha Fiuza + Claude Code
**Philosophy**: "Quality first, speed second"
**Last Updated**: Nov 13, 2025
**Version**: 1.0.0
