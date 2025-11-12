export type HubAppInitPayload = {
  tenantId?: string;
  userId?: string;
  email?: string;
  moduleName?: string;
  apiUrl?: string;      // URL base da API do Hub
  apiToken?: string;    // Token JWT para autenticação
};

type HubAppInitMessage = {
  type: 'hubapp:init';
  payload: HubAppInitPayload;
};

let ctx: HubAppInitPayload | undefined;
const listeners = new Set<(payload: HubAppInitPayload) => void>();

/**
 * Registra listener para receber configuração do Hub via postMessage
 * Deve ser chamado no início da aplicação (main.tsx)
 */
export function registerHubContextListener() {
  if (typeof window === 'undefined') return;

  console.log('🎯 [MODULE_NAME] Listener registrado! Aguardando mensagens...');

  const handler = (e: MessageEvent) => {
    console.log('📨 [MODULE_NAME] Mensagem recebida:', e.data);
    const data = e.data as HubAppInitMessage;

    if (data && data.type === 'hubapp:init' && data.payload) {
      ctx = data.payload;

      // Configurar API adapter se apiUrl e apiToken foram enviados
      if (data.payload.apiUrl && data.payload.apiToken) {
        console.info('[MODULE_NAME] 📡 Configurando API adapter...');
        import('../adapter/apiAdapter').then(adapter => {
          adapter.storeApiConfig(data.payload.apiUrl!, data.payload.apiToken!);
          console.info('[MODULE_NAME] ✅ API adapter configurado!');

          // Disparar evento indicando que a API está pronta
          try {
            window.dispatchEvent(new CustomEvent('MODULE_NAME:env-ready'));
          } catch {}
        }).catch(err => {
          console.error('[MODULE_NAME] ❌ Erro ao configurar API adapter:', err);
        });
      }

      // Notificar listeners
      listeners.forEach((fn) => {
        try { fn(data.payload); } catch {}
      });

      console.info('[MODULE_NAME] Hub.App context:', data.payload);
    }
  };

  window.addEventListener('message', handler);
}

/**
 * Retorna o contexto atual do Hub (se já recebido)
 */
export function getHubContext(): HubAppInitPayload | undefined {
  return ctx;
}

/**
 * Registra callback para ser notificado quando contexto for recebido
 * Retorna função para remover o listener
 */
export function onHubContext(cb: (payload: HubAppInitPayload) => void) {
  listeners.add(cb);
  return () => listeners.delete(cb);
}
