import 'package:sqflite/sqflite.dart';

import '../domain/album.dart';
import '../domain/album_repository.dart';
import '../domain/catalog.dart';

/// Implementação do [AlbumRepository] sobre SQLite (sqflite).
/// É o único lugar da feature que conhece SQL.
class SqliteAlbumRepository implements AlbumRepository {
  SqliteAlbumRepository(this._db);

  final Database _db;

  @override
  Future<void> importCatalog(CatalogData catalog) {
    return _db.transaction((txn) async {
      final existing = await txn.query(
        'albums',
        columns: ['catalog_version'],
        where: 'id = ?',
        whereArgs: [catalog.albumId],
      );
      if (existing.isNotEmpty &&
          (existing.first['catalog_version']! as int) >= catalog.version) {
        return;
      }

      // Não usar REPLACE: apagaria o álbum e, por cascata, o inventário.
      final values = {
        'name': catalog.name,
        'catalog_version': catalog.version,
        'is_demo': catalog.isDemo ? 1 : 0,
      };
      if (existing.isEmpty) {
        await txn.insert('albums', {'id': catalog.albumId, ...values});
      } else {
        await txn.update(
          'albums',
          values,
          where: 'id = ?',
          whereArgs: [catalog.albumId],
        );
      }

      final sectionIds = await _syncSections(txn, catalog);
      await _syncStickers(txn, catalog, sectionIds);
    });
  }

  Future<Map<String, int>> _syncSections(
    Transaction txn,
    CatalogData catalog,
  ) async {
    final rows = await txn.query(
      'sections',
      columns: ['id', 'key'],
      where: 'album_id = ?',
      whereArgs: [catalog.albumId],
    );
    final ids = {for (final r in rows) r['key']! as String: r['id']! as int};

    final newKeys = catalog.sections.map((s) => s.key).toSet();
    for (final entry in ids.entries) {
      if (!newKeys.contains(entry.key)) {
        await txn.delete('sections', where: 'id = ?', whereArgs: [entry.value]);
      }
    }

    for (var i = 0; i < catalog.sections.length; i++) {
      final s = catalog.sections[i];
      final id = ids[s.key];
      if (id == null) {
        ids[s.key] = await txn.insert('sections', {
          'album_id': catalog.albumId,
          'key': s.key,
          'name': s.name,
          'sort_index': i,
        });
      } else {
        await txn.update(
          'sections',
          {'name': s.name, 'sort_index': i},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    return ids;
  }

  Future<void> _syncStickers(
    Transaction txn,
    CatalogData catalog,
    Map<String, int> sectionIds,
  ) async {
    final rows = await txn.query(
      'stickers',
      columns: ['id', 'code'],
      where: 'album_id = ?',
      whereArgs: [catalog.albumId],
    );
    final ids = {for (final r in rows) r['code']! as String: r['id']! as int};
    final newCodes = {for (final s in catalog.sections) ...s.codes};

    final batch = txn.batch();
    for (final entry in ids.entries) {
      if (!newCodes.contains(entry.key)) {
        batch.delete('stickers', where: 'id = ?', whereArgs: [entry.value]);
      }
    }
    var order = 0;
    for (final section in catalog.sections) {
      for (final code in section.codes) {
        final id = ids[code];
        final values = {
          'section_id': sectionIds[section.key],
          'sort_index': order++,
        };
        if (id == null) {
          batch.insert('stickers', {
            'album_id': catalog.albumId,
            'code': code,
            ...values,
          });
        } else {
          batch.update('stickers', values, where: 'id = ?', whereArgs: [id]);
        }
      }
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Album>> getAlbums() async {
    final rows = await _db.query('albums', orderBy: 'name');
    return [
      for (final r in rows)
        Album(
          id: r['id']! as String,
          name: r['name']! as String,
          catalogVersion: r['catalog_version']! as int,
          isDemo: (r['is_demo']! as int) == 1,
        ),
    ];
  }

  @override
  Future<List<Section>> getSections(String albumId) async {
    final rows = await _db.query(
      'sections',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'sort_index',
    );
    return [
      for (final r in rows)
        Section(
          id: r['id']! as int,
          key: r['key']! as String,
          name: r['name']! as String,
          sortIndex: r['sort_index']! as int,
        ),
    ];
  }

  @override
  Future<List<StickerEntry>> getEntries(String albumId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.id, s.code, s.section_id, s.sort_index,
             COALESCE(i.quantity, 0) AS quantity
      FROM stickers s
      LEFT JOIN inventory i ON i.sticker_id = s.id
      WHERE s.album_id = ?
      ORDER BY s.sort_index
      ''',
      [albumId],
    );
    return [
      for (final r in rows)
        StickerEntry(
          sticker: Sticker(
            id: r['id']! as int,
            code: r['code']! as String,
            sectionId: r['section_id']! as int,
            sortIndex: r['sort_index']! as int,
          ),
          quantity: r['quantity']! as int,
        ),
    ];
  }

  @override
  Future<void> setQuantity(int stickerId, int quantity) async {
    if (quantity < 0 || quantity > StickerEntry.maxQuantity) {
      throw RangeError.range(quantity, 0, StickerEntry.maxQuantity, 'quantity');
    }
    if (quantity == 0) {
      await _db.delete(
        'inventory',
        where: 'sticker_id = ?',
        whereArgs: [stickerId],
      );
    } else {
      await _db.insert('inventory', {
        'sticker_id': stickerId,
        'quantity': quantity,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
