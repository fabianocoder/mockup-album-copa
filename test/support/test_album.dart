import 'package:figurinhas_copa/core/database/app_database.dart';
import 'package:figurinhas_copa/features/album/data/sqlite_album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/catalog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const testCatalog = CatalogData(
  albumId: 'a1',
  name: 'Álbum teste',
  version: 1,
  isDemo: true,
  sections: [
    CatalogSection(key: 'AA', name: 'Seção A', codes: ['AA-01', 'AA-02']),
    CatalogSection(key: 'BB', name: 'Seção B', codes: ['BB-01', 'BB-02']),
  ],
);

/// Repositório SQLite em memória (FFI) com o [testCatalog] importado.
Future<AlbumRepository> createSqliteTestRepository() async {
  sqfliteFfiInit();
  final db = await AppDatabase.open(
    inMemoryDatabasePath,
    factory: databaseFactoryFfi,
    singleInstance: false,
  );
  final repo = SqliteAlbumRepository(db);
  await repo.importCatalog(testCatalog);
  return repo;
}
