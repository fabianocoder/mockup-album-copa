import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/album/domain/album_repository.dart';
import 'package:figurinhas_copa/features/album/domain/catalog.dart';

/// Implementação em memória do [AlbumRepository], para testes sem banco.
/// Também serve de prova de que o contrato independe do SQLite.
class InMemoryAlbumRepository implements AlbumRepository {
  final _albums = <String, Album>{};
  final _sections = <String, List<Section>>{};
  final _stickers = <String, List<Sticker>>{};
  final _quantities = <int, int>{};
  var _nextId = 1;

  @override
  Future<void> importCatalog(CatalogData catalog) async {
    final stored = _albums[catalog.albumId];
    if (stored != null && stored.catalogVersion >= catalog.version) return;

    _albums[catalog.albumId] = Album(
      id: catalog.albumId,
      name: catalog.name,
      catalogVersion: catalog.version,
      isDemo: catalog.isDemo,
    );

    final oldSections = {
      for (final s in _sections[catalog.albumId] ?? const <Section>[])
        s.key: s.id,
    };
    final sections = <Section>[
      for (var i = 0; i < catalog.sections.length; i++)
        Section(
          id: oldSections[catalog.sections[i].key] ?? _nextId++,
          key: catalog.sections[i].key,
          name: catalog.sections[i].name,
          sortIndex: i,
        ),
    ];
    _sections[catalog.albumId] = sections;

    final oldStickers = {
      for (final s in _stickers[catalog.albumId] ?? const <Sticker>[])
        s.code: s.id,
    };
    final stickers = <Sticker>[];
    var order = 0;
    for (var i = 0; i < catalog.sections.length; i++) {
      for (final code in catalog.sections[i].codes) {
        stickers.add(
          Sticker(
            id: oldStickers[code] ?? _nextId++,
            code: code,
            sectionId: sections[i].id,
            sortIndex: order++,
          ),
        );
      }
    }
    final keptIds = stickers.map((s) => s.id).toSet();
    _quantities.removeWhere((id, _) => !keptIds.contains(id));
    _stickers[catalog.albumId] = stickers;
  }

  @override
  Future<List<Album>> getAlbums() async =>
      _albums.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<List<Section>> getSections(String albumId) async =>
      List.of(_sections[albumId] ?? const []);

  @override
  Future<List<StickerEntry>> getEntries(String albumId) async => [
    for (final s in _stickers[albumId] ?? const <Sticker>[])
      StickerEntry(sticker: s, quantity: _quantities[s.id] ?? 0),
  ];

  @override
  Future<void> setQuantity(int stickerId, int quantity) async {
    if (quantity < 0 || quantity > StickerEntry.maxQuantity) {
      throw RangeError.range(quantity, 0, StickerEntry.maxQuantity, 'quantity');
    }
    if (!_stickers.values.any((l) => l.any((s) => s.id == stickerId))) {
      throw StateError('Figurinha inexistente: $stickerId');
    }
    if (quantity == 0) {
      _quantities.remove(stickerId);
    } else {
      _quantities[stickerId] = quantity;
    }
  }
}
