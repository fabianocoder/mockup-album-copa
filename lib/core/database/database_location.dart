import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Escolhe o backend SQLite da plataforma e devolve o caminho do arquivo.
///
/// - Android/iOS: plugin nativo do sqflite.
/// - Linux/Windows: SQLite via FFI (sqflite não tem backend nativo ali), com
///   o banco no diretório de dados do usuário (não no diretório atual).
Future<String> prepareDatabasePath(String fileName) async {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = p.join(_desktopDataDir(), 'figurinhas_copa');
    await Directory(dir).create(recursive: true);
    return p.join(dir, fileName);
  }
  return p.join(await getDatabasesPath(), fileName);
}

String _desktopDataDir() {
  final env = Platform.environment;
  if (Platform.isWindows) {
    return env['APPDATA'] ?? env['USERPROFILE'] ?? '.';
  }
  return env['XDG_DATA_HOME'] ?? p.join(env['HOME'] ?? '.', '.local', 'share');
}
