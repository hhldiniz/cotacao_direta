{{flutter_js}}
{{flutter_build_config}}

// Este arquivo substitui o flutter_bootstrap.js que o Flutter geraria sozinho.
// Ele existe por um motivo só: registrar o service worker do app
// (`web/service_worker.js`) no lugar do que o Flutter aposentou na versão 3.44
// — o `flutter_service_worker.js` que ele ainda gera hoje apenas se
// desregistra e não guarda mais nada em cache.
//
// Por isso o load() vai sem `serviceWorkerSettings`: pedir o registro do
// service worker do Flutter aqui só desfaria o nosso.
_flutter.loader.load();

(function () {
  if (!('serviceWorker' in navigator)) return;

  // O `flutter run -d chrome` serve este mesmo arquivo, mas compila com o
  // dartdevc, e não com o dart2js dos builds. É o que separa desenvolvimento
  // de app publicado — e durante o desenvolvimento o service worker não pode
  // entrar: ele guardaria em cache o que o servidor de desenvolvimento acabou
  // de gerar, e o hot restart passaria a mostrar código velho.
  var builds = (window._flutter && _flutter.buildConfig && _flutter.buildConfig.builds) || [];
  var emDesenvolvimento = builds.some(function (build) {
    return build.compileTarget === 'dartdevc';
  });

  // Endereços montados a partir do baseURI para o app continuar funcionando
  // publicado num subcaminho (é o caso do GitHub Pages, em /cotacao_direta/).
  // O escopo é a pasta do app, e não a raiz do domínio.
  var serviceWorkerUrl = new URL('service_worker.js', document.baseURI);
  var scope = new URL('./', document.baseURI);

  if (emDesenvolvimento) {
    // Um service worker registrado por um build anterior servido no mesmo
    // endereço continuaria valendo aqui, com o mesmo efeito de código velho.
    navigator.serviceWorker.getRegistration(scope).then(function (registration) {
      if (registration) registration.unregister();
    });
    return;
  }

  // O registro vai aqui, e não num ouvinte do `load`, de propósito: o service
  // worker assume o controle da página assim que ativa, e só o que for baixado
  // depois disso passa por ele. Registrando cedo, o CanvasKit, as fontes e os
  // binários do SQLite — que são o grosso do peso — já entram em cache na
  // primeira visita, em vez de exigirem uma segunda para o app abrir sem rede.
  // O custo é uma requisição de poucos KB junto do carregamento do app.
  navigator.serviceWorker.register(serviceWorkerUrl, { scope: scope }).catch(function (error) {
    // Sem service worker o app ainda funciona; só perde o uso sem rede.
    console.warn('Falha ao registrar o service worker:', error);
  });
})();
