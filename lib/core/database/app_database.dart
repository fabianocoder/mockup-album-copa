import 'package:sqflite/sqflite.dart';

/// Abertura do banco e migrações versionadas.
///
/// Para evoluir o esquema: acrescente uma função ao final de [_migrations].
/// A versão do banco é o tamanho da lista.
abstract final class AppDatabase {
  static final List<Future<void> Function(DatabaseExecutor db)> _migrations = [
    _v1,
  ];

  /// Abre (criando/migrando se preciso). [factory] e [singleInstance] existem
  /// para os testes: injetam o backend FFI e isolam bancos em memória (o
  /// sqflite reaproveita a instância de um mesmo caminho por padrão).
  static Future<Database> open(
    String path, {
    DatabaseFactory? factory,
    bool singleInstance = true,
  }) {
    return (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        singleInstance: singleInstance,
        version: _migrations.length,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from; v < to; v++) {
      await _migrations[v](db);
    }
  }

  static Future<void> _v1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        catalog_version INTEGER NOT NULL,
        is_demo INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
        key TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_index INTEGER NOT NULL,
        UNIQUE (album_id, key)
      )''');
    await db.execute('''
      CREATE TABLE stickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
        section_id INTEGER NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
        code TEXT NOT NULL,
        sort_index INTEGER NOT NULL,
        UNIQUE (album_id, code)
      )''');
    await db.execute(
      'CREATE INDEX idx_stickers_album_sort ON stickers(album_id, sort_index)',
    );
    await db.execute(
      'CREATE INDEX idx_stickers_section ON stickers(section_id)',
    );
    // Só existe linha para figurinhas possuídas (quantity > 0): faltante é
    // ausência de linha e repetida é quantity - 1, sempre derivada.
    await db.execute('''
      CREATE TABLE inventory (
        sticker_id INTEGER PRIMARY KEY
          REFERENCES stickers(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL CHECK (quantity > 0)
      )''');
  }
}
