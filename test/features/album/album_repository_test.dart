import 'dart:io';

import 'package:figurinhas_copa/core/database/app_database.dart';
import 'package:figurinhas_copa/features/album/data/sqlite_album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/album/domain/album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/in_memory_album_repository.dart';

CatalogData _catalog({int version = 1, List<CatalogSection>? sections}) =>
    CatalogData(
      albumId: 'a1',
      name: 'Álbum teste',
      version: version,
      isDemo: true,
      sections:
          sections ??
          const [
            CatalogSection(key: 'AA', name: 'A', codes: ['AA-01', 'AA-02']),
            CatalogSection(key: 'BB', name: 'B', codes: ['BB-01']),
          ],
    );

/// Comportamento que toda implementação de [AlbumRepository] deve cumprir.
void _repositoryContract(Future<AlbumRepository> Function() create) {
  late AlbumRepository repo;

  setUp(() async {
    repo = await create();
    await repo.importCatalog(_catalog());
  });

  Future<Map<String, int>> quantities() async => {
    for (final e in await repo.getEntries('a1')) e.sticker.code: e.quantity,
  };

  Future<int> idOf(String code) async =>
      (await repo.getEntries('a1'))
          .firstWhere((e) => e.sticker.code == code)
          .sticker
          .id;

  test(
    'importa álbum, seções e figurinhas em ordem, todas faltantes',
    () async {
      final albums = await repo.getAlbums();
      expect(albums.single.isDemo, isTrue);
      expect((await repo.getSections('a1')).map((s) => s.key), ['AA', 'BB']);
      expect(await quantities(), {'AA-01': 0, 'AA-02': 0, 'BB-01': 0});
      final entries = await repo.getEntries('a1');
      expect(entries.map((e) => e.sticker.code), ['AA-01', 'AA-02', 'BB-01']);
      expect(entries.every((e) => e.isMissing), isTrue);
    },
  );

  test('setQuantity persiste, atualiza e volta a faltante com 0', () async {
    final id = await idOf('AA-02');
    await repo.setQuantity(id, 3);
    expect((await quantities())['AA-02'], 3);
    await repo.setQuantity(id, 1);
    expect((await quantities())['AA-02'], 1);
    await repo.setQuantity(id, 0);
    expect((await quantities())['AA-02'], 0);
  });

  test('impede quantidade negativa ou acima do limite', () async {
    final id = await idOf('AA-01');
    expect(() => repo.setQuantity(id, -1), throwsRangeError);
    expect(
      () => repo.setQuantity(id, StickerEntry.maxQuantity + 1),
      throwsRangeError,
    );
    expect((await quantities())['AA-01'], 0);
  });

  test('falha ao definir quantidade de figurinha inexistente', () async {
    await expectLater(repo.setQuantity(999999, 1), throwsA(anything));
  });

  test('reimportar a mesma versão ou menor não altera nada', () async {
    await repo.setQuantity(await idOf('AA-01'), 2);
    await repo.importCatalog(
      _catalog(
        sections: const [
          CatalogSection(key: 'ZZ', name: 'Z', codes: ['ZZ-01']),
        ],
      ),
    );
    expect((await quantities())['AA-01'], 2);
    expect(await quantities(), isNot(contains('ZZ-01')));
  });

  test(
    'versão maior preserva inventário e remove figurinhas excluídas',
    () async {
      await repo.setQuantity(await idOf('AA-01'), 2);
      await repo.setQuantity(await idOf('BB-01'), 4);

      await repo.importCatalog(
        _catalog(
          version: 2,
          sections: const [
            CatalogSection(
              key: 'AA',
              name: 'A novo',
              codes: ['AA-01', 'AA-03'],
            ),
          ],
        ),
      );

      expect(await quantities(), {'AA-01': 2, 'AA-03': 0});
      expect((await repo.getSections('a1')).single.name, 'A novo');
      expect((await repo.getAlbums()).single.catalogVersion, 2);
    },
  );
}

void main() {
  sqfliteFfiInit();

  group('contrato — SQLite', () {
    _repositoryContract(() async {
      final db = await AppDatabase.open(
        inMemoryDatabasePath,
        factory: databaseFactoryFfi,
        singleInstance: false,
      );
      return SqliteAlbumRepository(db);
    });
  });

  group('contrato — em memória', () {
    _repositoryContract(() async => InMemoryAlbumRepository());
  });

  test('SQLite: dados persistem após fechar e reabrir o banco', () async {
    final dir = Directory.systemTemp.createTempSync('figurinhas_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/test.db';

    var db = await AppDatabase.open(path, factory: databaseFactoryFfi);
    var r = SqliteAlbumRepository(db);
    await r.importCatalog(_catalog());
    final entries = await r.getEntries('a1');
    await r.setQuantity(entries.first.sticker.id, 3);
    await db.close();

    db = await AppDatabase.open(path, factory: databaseFactoryFfi);
    r = SqliteAlbumRepository(db);
    await r.importCatalog(_catalog()); // idempotente
    final reopened = await r.getEntries('a1');
    expect(reopened.first.quantity, 3);
    expect(reopened, hasLength(3));
    await db.close();
  });
}
