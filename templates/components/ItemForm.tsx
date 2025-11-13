// ============================================================================
// ItemForm Component - MODULE_TITLE
// Formulário para criar/editar items
// ============================================================================

import { useState, useEffect } from 'react';
import type { Item, CreateItemInput, UpdateItemInput } from '../types';
import { X } from 'lucide-react';

interface ItemFormProps {
  item?: Item | null;  // Se null/undefined = modo criar, se Item = modo editar
  onSubmit: (data: CreateItemInput | UpdateItemInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

/**
 * Formulário para criar ou editar um item
 *
 * - Se `item` é null/undefined: modo CRIAR
 * - Se `item` é um objeto: modo EDITAR
 */
export function ItemForm({ item, onSubmit, onCancel, loading = false }: ItemFormProps) {
  const isEditMode = Boolean(item);

  const [formData, setFormData] = useState({
    nome: item?.nome || '',
    descricao: item?.descricao || '',
    ativo: item?.ativo ?? true,

    // ADICIONE SEUS CAMPOS PERSONALIZADOS AQUI
    // Exemplo:
    // prioridade: item?.prioridade || 'media',
    // responsavel_id: item?.responsavel_id || '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  // Atualizar form quando item mudar (modo editar)
  useEffect(() => {
    if (item) {
      setFormData({
        nome: item.nome,
        descricao: item.descricao || '',
        ativo: item.ativo,
        // ADICIONE SEUS CAMPOS PERSONALIZADOS AQUI
      });
    }
  }, [item]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.nome.trim()) {
      newErrors.nome = 'Nome é obrigatório';
    }

    if (formData.nome.length > 255) {
      newErrors.nome = 'Nome deve ter no máximo 255 caracteres';
    }

    // ADICIONE SUAS VALIDAÇÕES PERSONALIZADAS AQUI
    // Exemplo:
    // if (!formData.responsavel_id) {
    //   newErrors.responsavel_id = 'Responsável é obrigatório';
    // }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    try {
      await onSubmit(formData);
      // Limpar form após sucesso (apenas no modo criar)
      if (!isEditMode) {
        setFormData({
          nome: '',
          descricao: '',
          ativo: true,
        });
      }
    } catch (error) {
      console.error('Erro ao salvar item:', error);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <h2 className="text-lg font-semibold text-gray-900">
            {isEditMode ? 'Editar Item' : 'Novo Item'}
          </h2>
          <button
            onClick={onCancel}
            className="text-gray-400 hover:text-gray-600"
            disabled={loading}
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Nome */}
          <div>
            <label htmlFor="nome" className="block text-sm font-medium text-gray-700 mb-1">
              Nome *
            </label>
            <input
              type="text"
              id="nome"
              value={formData.nome}
              onChange={(e) => setFormData(prev => ({ ...prev, nome: e.target.value }))}
              className={`w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 ${
                errors.nome ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="Digite o nome do item"
              disabled={loading}
              autoFocus
            />
            {errors.nome && (
              <p className="mt-1 text-sm text-red-600">{errors.nome}</p>
            )}
          </div>

          {/* Descrição */}
          <div>
            <label htmlFor="descricao" className="block text-sm font-medium text-gray-700 mb-1">
              Descrição
            </label>
            <textarea
              id="descricao"
              value={formData.descricao}
              onChange={(e) => setFormData(prev => ({ ...prev, descricao: e.target.value }))}
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Digite uma descrição (opcional)"
              disabled={loading}
            />
          </div>

          {/* Ativo */}
          <div className="flex items-center">
            <input
              type="checkbox"
              id="ativo"
              checked={formData.ativo}
              onChange={(e) => setFormData(prev => ({ ...prev, ativo: e.target.checked }))}
              className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              disabled={loading}
            />
            <label htmlFor="ativo" className="ml-2 block text-sm text-gray-700">
              Item ativo
            </label>
          </div>

          {/* ADICIONE SEUS CAMPOS PERSONALIZADOS AQUI */}
          {/*
          Exemplo de campo select:

          <div>
            <label htmlFor="prioridade" className="block text-sm font-medium text-gray-700 mb-1">
              Prioridade
            </label>
            <select
              id="prioridade"
              value={formData.prioridade}
              onChange={(e) => setFormData(prev => ({ ...prev, prioridade: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              disabled={loading}
            >
              <option value="baixa">Baixa</option>
              <option value="media">Média</option>
              <option value="alta">Alta</option>
            </select>
          </div>
          */}

          {/* Botões */}
          <div className="flex justify-end space-x-3 pt-4 border-t">
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={loading}
            >
              {loading ? (
                <span className="flex items-center">
                  <div className="h-4 w-4 mr-2 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                  Salvando...
                </span>
              ) : (
                <span>{isEditMode ? 'Salvar Alterações' : 'Criar Item'}</span>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
