import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Prepara o [databaseFactory] usado pelo sqflite na web.
///
/// O plugin sqflite não tem implementação para web; troca o databaseFactory
/// pelo backend FFI Web, que roda o SQLite via WASM e persiste os dados no
/// IndexedDB do navegador. Requer os binários gerados em `web/` por
/// `dart run sqflite_common_ffi_web:setup` (ver README).
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
