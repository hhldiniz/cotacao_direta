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
e o app Web. A versão do Flutter está fixada no workflow.

## Plataformas

O app roda em Android, Linux desktop e Web (`flutter run -d chrome` ou
`flutter build web`).

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
