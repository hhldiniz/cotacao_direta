'use strict';

// Service worker do app.
//
// Até o Flutter 3.43 o próprio framework gerava um (`flutter_service_worker.js`)
// e o registrava pelo `flutter_bootstrap.js`. Na 3.44 esse service worker foi
// aposentado: o arquivo continua sendo gerado, mas só se desregistra e não
// guarda mais nada em cache. Sem um no lugar dele, o app perde o
// funcionamento sem rede — que é metade do que faz dele um PWA. Este é o
// substituto, registrado por `web/flutter_bootstrap.js`.
//
// Estratégia:
//
// - navegação e código do app (o bundle, o carregador, os metadados): a rede
//   primeiro, com o cache como reserva. Assim quem está online sempre roda a
//   versão publicada mais recente, e quem está sem rede ainda abre o app;
// - todo o resto do mesmo domínio (CanvasKit, fontes, ícones, o SQLite em
//   WASM): responde do cache na hora e busca uma versão nova em segundo plano
//   (*stale-while-revalidate*). São arquivos grandes e que quase não mudam.
//
// Requisições para outros domínios — a API de cotações, por exemplo — passam
// direto, sem cache: cotação velha servida como se fosse atual seria pior do
// que não responder. O que o app já baixou fica no banco local dele.

// Trocar a versão apaga os caches antigos. Só precisa mudar quando a
// estratégia acima mudar: arquivo novo publicado é assunto das regras acima,
// não do nome do cache.
const CACHE_NAME = 'cotacao-direta-v1';

/// Endereços em que a versão publicada tem de ganhar da guardada.
const NETWORK_FIRST_PATHS = [
  'flutter_bootstrap.js',
  'main.dart.js',
  'flutter.js',
  'index.html',
  'manifest.json',
  'version.json',
];

// O escopo do service worker é a pasta em que ele está, que é a raiz do app
// (`/` no servidor local, `/cotacao_direta/` no GitHub Pages).
const SCOPE = new URL('./', self.location.href);

/// O mínimo para o app abrir. Entra em cache já na instalação, e não só quando
/// for pedido, porque parte disso é baixada antes de o service worker assumir
/// o controle da página na primeira visita. O resto (CanvasKit, fontes,
/// bandeiras, o SQLite em WASM) entra pela regra de busca, conforme é usado.
const APP_SHELL = ['', 'flutter_bootstrap.js', 'main.dart.js', 'flutter.js', 'manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // Um a um, e não com addAll: lá, um único arquivo que falhe derruba a
      // instalação inteira e o app fica sem service worker nenhum.
      await Promise.all(
        APP_SHELL.map((path) =>
          cache
            .add(new Request(new URL(path, SCOPE), { cache: 'reload' }))
            .catch((error) => console.warn('Falha ao pré-carregar', path, error))
        )
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Apaga tanto os caches de versões anteriores deste service worker
      // quanto os que sobraram do service worker antigo do Flutter.
      const names = await caches.keys();
      await Promise.all(
        names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))
      );
      // Assume o controle das abas já abertas, sem esperar um recarregamento.
      await self.clients.claim();
    })()
  );
});

function isNetworkFirst(request, url) {
  if (request.mode === 'navigate') return true;
  return NETWORK_FIRST_PATHS.some((path) => url.pathname === SCOPE.pathname + path);
}

/// Guarda a resposta no cache. Só respostas completas e bem-sucedidas: guardar
/// um 404 ou um 206 faria o app abrir quebrado da próxima vez.
async function cacheResponse(request, response) {
  if (!response || !response.ok || response.status !== 200) return;
  const cache = await caches.open(CACHE_NAME);
  await cache.put(request, response.clone());
}

async function networkFirst(request) {
  try {
    const response = await fetch(request);
    await cacheResponse(request, response);
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) return cached;
    // Numa navegação, qualquer endereço dentro do app tem de cair no app
    // shell: é ele que sabe montar a tela pedida.
    if (request.mode === 'navigate') {
      const shell = await caches.match(SCOPE);
      if (shell) return shell;
    }
    throw error;
  }
}

async function staleWhileRevalidate(request) {
  const cached = await caches.match(request);
  const network = fetch(request)
    .then(async (response) => {
      await cacheResponse(request, response);
      return response;
    })
    .catch((error) => {
      // Sem rede e sem cache não há o que devolver; com cache, o erro só
      // significa que a atualização em segundo plano fica para a próxima.
      if (!cached) throw error;
      return cached;
    });
  return cached || network;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Fora do escopo do app (a API de cotações, o CDN do CanvasKit) o service
  // worker não se mete: deixa o navegador buscar como buscaria sem ele.
  if (url.origin !== self.location.origin) return;
  if (!url.pathname.startsWith(SCOPE.pathname)) return;

  event.respondWith(
    isNetworkFirst(request, url) ? networkFirst(request) : staleWhileRevalidate(request)
  );
});
