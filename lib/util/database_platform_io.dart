import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Prepara o [databaseFactory] usado pelo sqflite fora da web.
///
/// O plugin sqflite não tem implementação para desktop Linux; troca o
/// databaseFactory pelo backend FFI, que usa o SQLite nativo do sistema.
void configureDatabaseFactory() {
  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
