# cotacao_direta

[![CI](https://github.com/hhldiniz/cotacao_direta/actions/workflows/ci.yml/badge.svg)](https://github.com/hhldiniz/cotacao_direta/actions/workflows/ci.yml)

A new Flutter project.

## Testes

```sh
flutter pub get
flutter test
```

Os testes são unitários e não precisam de emulador nem de rede:

- `test/model/` e `test/util/` — modelos, utilitários e traduções;
- `test/dao/` e `test/util/database_test.dart` — DAOs e esquema do banco,
  rodando sobre um SQLite real em memória (`sqflite_common_ffi`);
- `test/repository/` — repositórios, com DAOs falsos (`test/helpers/fakes.dart`)
  e um cliente HTTP simulado (`MockClient`).

Testes que tocam o banco devem chamar `useInMemoryDatabase()`
(`test/helpers/database_test_helper.dart`) para receber um banco novo a cada
caso.

O CI (`.github/workflows/ci.yml`) roda a análise e os testes a cada push na
`master` e em todo pull request, além de compilar o APK de debug, o app Linux
e o app Web. A versão do Flutter está fixada no workflow. O APK de release,
assinado, sai do `.github/workflows/build-apk.yml`, disparado à mão — ver
[Assinatura do release](#assinatura-do-release-android).

## Plataformas

O app roda em Android, Linux desktop e Web (`flutter run -d chrome` ou
`flutter build web`). Na web ele é instalável como PWA — ver a seção
[Web como PWA](#web-como-pwa-instalável-no-aparelho).

Persistência local (sqflite) usa um backend diferente por plataforma,
selecionado em tempo de execução por `lib/util/database.dart`:

- Android: implementação nativa do plugin `sqflite`;
- Linux: `sqflite_common_ffi`, sobre o SQLite do sistema;
- Web: `sqflite_common_ffi_web`, que roda o SQLite via WASM e persiste no
  IndexedDB do navegador. Os binários que essa implementação usa
  (`web/sqflite_sw.js` e `web/sqlite3.wasm`) já ficam versionados no
  repositório; só é preciso gerá-los de novo, com
  `dart run sqflite_common_ffi_web:setup --force`, se a versão do pacote
  mudar.

## Web como PWA (instalável no aparelho)

A versão web é um *progressive web app*: dá para instalar o Cotação Direta no
celular ou no desktop e abrir pelo ícone, em janela própria, sem a barra do
navegador. O que sustenta isso:

- `web/manifest.json` — nome, ícones (inclusive os *maskable*, que o Android
  recorta na forma do sistema), `start_url`/`scope` relativos (`./`, para o app
  continuar funcionando publicado num subcaminho como
  `/cotacao_direta/`), `display: standalone` e as cores da janela;
- `web/index.html` — a `viewport` (sem ela o navegador não considera a página
  adequada a celular, e não oferece a instalação), a `theme-color` e as metas do
  Safari do iOS;
- `web/service_worker.js` — o service worker do app, que guarda os arquivos em
  cache e o faz abrir mesmo sem rede; as cotações já vistas continuam vindo do
  banco local;
- `web/flutter_bootstrap.js` — versão própria do arquivo que o Flutter geraria
  sozinho, só para registrar o service worker acima.

O service worker é escrito à mão porque o Flutter 3.44 aposentou o dele: o
`flutter_service_worker.js` ainda é gerado, mas hoje só se desregistra e não
guarda mais nada em cache, e a opção `--pwa-strategy` deixou de existir. Sem um
no lugar, o app perderia o funcionamento sem rede. As regras dele:

- navegação e código do app (`main.dart.js`, o carregador, os metadados): a rede
  primeiro, com o cache como reserva — quem está online sempre roda a versão
  publicada mais recente;
- o resto do mesmo domínio (CanvasKit, fontes, bandeiras, o SQLite em WASM):
  responde do cache na hora e atualiza em segundo plano;
- outros domínios, como a API de cotações: passam direto, sem cache.

O `CACHE_NAME` no topo do arquivo só precisa mudar quando essas regras mudarem;
arquivo novo publicado já é tratado pelas regras acima.

A publicação usa `--no-web-resources-cdn` para o CanvasKit ser servido junto do
site, e não pelo CDN do Google: vindo de outro domínio ele ficaria fora do
alcance do service worker, e o app não abriria sem rede.

O `id` do manifest está fixado em `/cotacao_direta/`, o mesmo caminho do
`--base-href` usado na publicação no GitHub Pages
(`.github/workflows/deploy-pages.yml`): é ele que dá identidade estável ao app
instalado. Se o caminho de publicação mudar, os dois precisam mudar juntos.

Dentro do app, a opção **Instalar aplicativo** aparece no topo das
configurações. Ela é a leitura, do lado Flutter, do que o navegador decidiu:

- `web/index.html` ouve o evento `beforeinstallprompt` e guarda o pedido de
  instalação num objeto global. A escuta precisa começar aí, e não no Dart,
  porque o navegador dispara o evento antes de o Flutter terminar de carregar;
- `lib/util/pwa_install_service.dart` expõe esse estado ao app, com a mesma
  troca de implementação por plataforma usada no resto do projeto
  (`_io.dart` / `_web.dart`). Fora da web a resposta é sempre
  `PwaInstallStatus.unsupported`, e a opção não aparece;
- `lib/view/widgets/pwa_install_card.dart` é o cartão em si. No Safari do iOS,
  que não oferece o pedido de instalação a quem faz a página, ele troca o botão
  por uma explicação do caminho pelo menu de compartilhar.

A oferta de instalação do próprio navegador continua valendo: o evento é
guardado sem `preventDefault()`, então a faixa do Android e o ícone na barra de
endereço do desktop seguem aparecendo normalmente.

O navegador só aceita instalar um site servido por HTTPS (ou por `localhost`).
Para conferir localmente:

```sh
flutter build web --release
dart run dhttpd --path build/web --port 8080   # ou qualquer servidor estático
```

e abrir `http://localhost:8080`. O `flutter run -d chrome` serve o mesmo
`web/flutter_bootstrap.js`, mas ele não registra o service worker quando
percebe que está no servidor de desenvolvimento (que compila com o dartdevc, e
não com o dart2js dos builds): em desenvolvimento o cache só atrapalharia, com
o hot restart mostrando código velho. Para testar o comportamento sem rede,
então, é preciso o build.

## Idioma da interface

O app tem textos em português, inglês e espanhol, e sempre seguiu o idioma do
aparelho. A aba **Opções** agora permite fixar um deles, para quem usa o
aparelho em um idioma e prefere o app em outro.

O espanhol são duas traduções, uma para cada norma: a da Espanha (`es-ES`) e a
da América Latina (`es-419`, o código que o CLDR usa para a região). O
vocabulário muda o bastante entre elas — "ajustes" e "móvil" de um lado,
"configuración" e "celular" do outro — para não caber em um texto só. Por isso
um idioma é identificado pela etiqueta inteira, e não só pelo código do idioma.

A lista oferecida é exatamente a da build: `AppLocales.supported`, em
`lib/util/localizations.dart`, é a mesma fonte que alimenta o
`supportedLocales` do `MaterialApp`, o `isSupported` do delegate de traduções
e o seletor da tela de opções — acrescentar um idioma ao mapa de textos e a
essa lista basta para ele aparecer nas três pontas.

Quem não fixa idioma nenhum é atendido pelo `localeListResolutionCallback` do
`MaterialApp`: a resolução padrão do Flutter, sem país correspondente, daria a
primeira variante de espanhol da lista para todo mundo — a da Espanha também
para quem está no México. `AppLocales.resolve` decide pela região do aparelho:
sem região, ou em um país que segue a norma europeia, vale a tradução da
Espanha; o resto fica com a latino-americana.

A região também vai junto na hora de formatar números, e não só de escolher os
textos: o espanhol da América Latina separa os decimais com ponto ("12.3%"), o
da Espanha com vírgula ("12,3 %"). Por isso a tela de IA passa o locale inteiro
(`es_419`) ao `InsightEngine`, em vez de só o código do idioma.

A escolha é gravada na tabela `Configurations` (coluna `languageCode`, migração
8→9), com a etiqueta do idioma em caixa baixa (`pt`, `es-419`) — a forma
canônica é remontada na leitura, por `AppLocales.tagFor`. Coluna vazia — o
padrão, e o que os bancos já existentes recebem na migração — significa "seguir
o aparelho", que é o comportamento anterior. Quem precisa do valor é o
`MaterialApp` na raiz da árvore, acima dos blocs, então ele chega lá pelo
`AppLocaleController` (`lib/util/app_locale_controller.dart`), um
`ValueNotifier<Locale?>` de escopo do app: a tela de opções o atualiza junto
com a gravação e o app inteiro é reconstruído no idioma novo na hora. Uma
etiqueta que a build não conhece — por exemplo ao instalar por cima de uma
versão com mais traduções — é tratada como "seguir o aparelho", em vez de
deixar a interface sem textos.

## IA local: insights e projeções

A aba **IA** analisa um ativo (moeda ou criptomoeda) e mostra um resumo de
mercado, uma projeção com faixa de confiança e observações em texto. Tudo é
calculado no próprio aparelho: não há modelo para baixar, plugin nativo,
chamada a serviço de IA nem envio de dados para fora. A única requisição de
rede é a busca de cotações que o app já fazia.

O modelo tem duas peças, que se cobrem:

- uma **rede neural** de uma camada escondida (perceptron multicamada) escrita
  em Dart puro (`lib/ai/neural/neural_network.dart`), treinada na hora com o
  histórico do próprio ativo. Ela recebe uma janela de log-retornos recentes
  mais quatro indicadores derivados (momento, IFR, distância da média em
  desvios padrão e aceleração da volatilidade) e prevê o retorno do dia
  seguinte; a projeção de vários dias sai da aplicação repetida dessa previsão;
- uma **deriva estatística**, a média exponencial dos log-retornos, amortecida
  ao longo do horizonte para não extrapolar uma tendência em linha reta.

O peso de cada peça na projeção final não é arbitrário. Um trecho do fim da
série é separado do treino e nele a rede é comparada com o passeio aleatório
("amanhã é igual a hoje"); o peso da rede é proporcional à vantagem obtida e
tem teto de 60%. Quando a rede não supera o passeio aleatório — o caso comum,
já que preço de ativo é quase um passeio aleatório —, o peso vai a zero e a
projeção passa a ser a base estatística. Esse número aparece na tela, em
"Vantagem sobre o passeio aleatório", para a projeção ser lida pelo que ela é.

A faixa de confiança vem do modelo de caminhada aleatória em log-preço: o
desvio acumulado cresce com `sigma * sqrt(dias)` e o multiplicador é o quantil
da normal para o nível pedido (80% por padrão).

O treino é semeado com um valor fixo, então a mesma série produz sempre a mesma
projeção. Uma análise completa (indicadores, treino e projeção) leva de 5 a 20
ms sobre 90 a 360 pontos numa máquina de desenvolvimento, e algumas dezenas de
milissegundos em celular — daí rodar na própria isolate da interface, sem
precisar de isolate separado (o que também mantém o recurso funcionando na
web).

Onde fica o código:

- `lib/ai/math/` — estatística e indicadores técnicos (Dart puro);
- `lib/ai/neural/` — a rede neural e o treino;
- `lib/ai/local_financial_model.dart` — características, projeção e faixa de
  confiança;
- `lib/ai/insight_engine.dart` — quais observações fazer e com que tom (o texto
  em si vem das traduções, em `lib/util/localizations.dart`);
- `lib/ai/financial_ai_service.dart` — porta de entrada usada pelo bloc;
- `lib/blocs/ai_insights_bloc.dart` e
  `lib/view/pages/main_menu_items/ai_insights_page.dart` — estado e tela.

Limites, ditos com todas as letras: são estimativas estatísticas sobre cotações
passadas, e a tela traz esse aviso — não é recomendação de investimento. O
motor já trabalha com ações (`AssetKind.stock`, com limiares de volatilidade
próprios), mas a fonte de cotações usada pelo app (AwesomeAPI) só serve moeda
fiduciária e criptomoeda; basta alimentar um `AssetSeries` com preços de ação
para analisar uma.

## Ícone do app (Android)

O ícone é a mesma marca da PWA — "R$" em branco sobre o azul `#02609A`, o
`theme_color` do `web/manifest.json` —, agora desenhada em Roboto Bold, a fonte
do app. As imagens de origem ficam em `assets/launcher/`, em 1024x1024:

- `icon.png` — a marca inteira, com o fundo azul e os cantos arredondados. Vira
  o ícone legado (`mipmap-*/ic_launcher.png`), que é o que os aparelhos
  anteriores ao Android 8 usam;
- `icon_foreground.png` — só o "R$" em branco, sobre fundo transparente. É a
  camada de frente do ícone adaptativo, que o Android 8+ recorta na forma do
  lançador (círculo, *squircle*, etc.). O `mipmap-anydpi-v26/ic_launcher.xml`
  aplica um `inset` de 16% nela, o que mantém a marca dentro da zona segura de
  72dp do canvas de 108dp;
- a camada monocromática — o ícone temático do Android 13+, que segue a cor do
  papel de parede — usa a mesma arte da camada de frente, então também sai do
  `icon_foreground.png`. O `ic_launcher_monochrome` gerado a partir dela é
  ainda o ícone pequeno das notificações dos alertas de câmbio: ali o sistema
  recorta pelo canal alfa, e o ícone colorido viraria só um quadrado branco.

A cor de fundo do ícone adaptativo é um recurso de cor
(`values/colors.xml`, `ic_launcher_background`), não uma imagem.

Os arquivos gerados estão versionados em `android/app/src/main/res/`, então o
build não depende de rodar gerador nenhum. Depois de mexer nas imagens de
origem, refaça os ícones com:

```bash
dart run flutter_launcher_icons
```

A configuração fica na chave `flutter_launcher_icons` do `pubspec.yaml`.

## Assinatura do release (Android)

O Android não instala APK sem assinatura, e o build de release precisa de um
certificado. O projeto usa um **certificado auto assinado**: serve para
instalar e distribuir o APK por fora da loja, mas não vale para publicar na
Play Store, que exige uma chave de upload cadastrada.

Quem lê as credenciais é o `android/app/build.gradle`, a partir de
`android/key.properties`:

```properties
storeFile=release.keystore   # caminho relativo a android/
storePassword=...
keyAlias=cotacao_direta
keyPassword=...
```

Sem esse arquivo o release continua compilando, assinado com a chave de debug,
para que `flutter run --release` funcione sem configuração. Com ele presente, o
APK sai assinado com o certificado do projeto. Nem a keystore nem o
`key.properties` entram no repositório (ver `.gitignore`): são chave privada e
senha.

### Gerar o certificado

```sh
tool/generate_keystore.sh
```

O script cria `android/release.keystore` (RSA de 4096 bits, validade de 10000
dias) e escreve o `android/key.properties` correspondente, sorteando uma senha.
Dá para escolher apelido, senha, validade e titular por variáveis de ambiente —
as opções estão comentadas no começo do arquivo. Ele se recusa a sobrescrever
uma keystore existente, a não ser com `FORCE=1`.

Depois disso, `flutter build apk --release` já sai assinado.

### Assinar no CI

O workflow **Build APK** (Actions > Build APK > Run workflow) compila o release
e publica o `.apk` como artefato. Ele monta o `key.properties` a partir destes
secrets do repositório (Settings > Secrets and variables > Actions):

| Secret | Conteúdo |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | a keystore em base64: `base64 -w0 android/release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | a senha da keystore |
| `ANDROID_KEY_ALIAS` | o apelido da chave (padrão: `cotacao_direta`) |
| `ANDROID_KEY_PASSWORD` | a senha da chave (em geral, a mesma da keystore) |

Sem os secrets cadastrados o workflow não falha: ele chama o
`tool/generate_keystore.sh` e assina com um certificado descartável, criado
naquela execução. O APK instala e roda, mas cada build sai com um certificado
diferente, e o Android só aceita atualizar um app instalado se a assinatura
for a mesma. Para ter um APK que atualiza o anterior, cadastre os secrets.

O último passo do workflow roda o `apksigner verify --print-certs` e mostra a
impressão digital do certificado que assinou o APK — é por ela que se confere
qual chave foi usada.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
