import 'package:cotacao_direta/util/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Faz o sqflite rodar sobre o SQLite nativo (em memória) durante os testes.
///
/// Os testes de DAO exercitam o SQL de verdade: cada teste recebe um banco
/// novo, criado pelo mesmo `onCreate` usado em produção, e o singleton
/// [AppDatabase] é descartado no fim para não vazar estado entre testes.
void useInMemoryDatabase() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.reset();
    AppDatabase.databasePathOverride = inMemoryDatabasePath;
  });

  tearDown(() async {
    await AppDatabase.reset();
    AppDatabase.databasePathOverride = null;
  });
}
