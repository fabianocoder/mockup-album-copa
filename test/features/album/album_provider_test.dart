import 'package:figurinhas_copa/features/album/domain/album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/catalog.dart';
import 'package:figurinhas_copa/features/album/domain/sticker_filter.dart';
import 'package:figurinhas_copa/features/album/presentation/album_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_album_repository.dart';
import '../../support/test_album.dart';

void main() {
  late AlbumRepository repo;
  late AlbumProvider provider;

  Future<int> idOf(String code) async =>
      (await repo.getEntries('a1'))
          .firstWhere((e) => e.sticker.code == code)
          .sticker
          .id;

  setUp(() async {
    // O provider depende só do contrato: roda aqui sem SQLite.
    repo = InMemoryAlbumRepository();
    await repo.importCatalog(testCatalog);
    provider = AlbumProvider(repo);
    await provider.load();
  });

  tearDown(() => provider.dispose());

  test('load popula estado e indicadores iniciais', () {
    expect(provider.status, LoadStatus.ready);
    expect(provider.stats.total, 4);
    expect(provider.stats.missing, 4);
    expect(provider.stats.completionPercent, 0);
    expect(provider.spareEntries, isEmpty);
  });

  test('increment atualiza indicadores e persiste', () async {
    final id = await idOf('AA-01');
    await provider.increment(id);
    await provider.increment(id);
    await provider.increment(id);

    expect(provider.quantityOf(id), 3);
    expect(provider.stats.owned, 1);
    expect(provider.stats.spareCopies, 2);
    expect(provider.spareEntries.single.sticker.code, 'AA-01');
    expect((await repo.getEntries('a1')).first.quantity, 3);
  });

  test('decrement não deixa a quantidade ficar negativa', () async {
    final id = await idOf('AA-01');
    await provider.decrement(id);
    expect(provider.quantityOf(id), 0);

    await provider.increment(id);
    await provider.decrement(id);
    await provider.decrement(id);
    expect(provider.quantityOf(id), 0);
    expect(provider.stats.owned, 0);
  });

  test('setQuantity limita ao máximo e ignora valores negativos', () async {
    final id = await idOf('AA-01');
    await provider.setQuantity(id, 5000);
    expect(provider.quantityOf(id), 99);
    await provider.setQuantity(id, -4);
    expect(provider.quantityOf(id), 0);
  });

  test('notifica listeners nas mudanças e não notifica sem mudança', () async {
    final id = await idOf('AA-01');
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.decrement(id); // já é 0: nada muda
    expect(notifications, 0);

    await provider.increment(id);
    expect(notifications, 1);
  });

  test('filtros atualizam a lista visível', () async {
    await provider.increment(await idOf('BB-01'));
    await provider.increment(await idOf('BB-01'));

    provider.setStatus(StickerStatus.repeated);
    expect(
      provider.visibleItems.whereType<StickerListItem>().map(
        (i) => i.entry.sticker.code,
      ),
      ['BB-01'],
    );

    provider.clearFilters();
    provider.setQuery('aa-02');
    expect(provider.visibleItems.whereType<StickerListItem>(), hasLength(1));
  });

  test('desfaz a alteração e retorna false quando a gravação falha', () async {
    final id = await idOf('AA-01');
    // Remove a figurinha do banco para a gravação violar a chave estrangeira.
    await repo.importCatalog(
      const CatalogData(
        albumId: 'a1',
        name: 'Álbum teste',
        version: 2,
        isDemo: true,
        sections: [
          CatalogSection(key: 'ZZ', name: 'Z', codes: ['ZZ-01']),
        ],
      ),
    );
    final ok = await provider.increment(id);
    expect(ok, isFalse);
    expect(provider.quantityOf(id), 0);
  });
}
