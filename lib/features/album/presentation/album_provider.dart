import 'package:flutter/foundation.dart';

import '../domain/album.dart';
import '../domain/album_repository.dart';
import '../domain/album_stats.dart';
import '../domain/sticker_filter.dart';

enum LoadStatus { loading, ready, error }

/// Estado do álbum ativo: figurinhas, quantidades, filtros e indicadores.
///
/// As alterações de quantidade são otimistas: a interface atualiza na hora e
/// a gravação é desfeita se falhar.
class AlbumProvider extends ChangeNotifier {
  AlbumProvider(this._repository);

  final AlbumRepository _repository;

  LoadStatus _status = LoadStatus.loading;
  Album? _album;
  List<Section> _sections = const [];
  List<StickerEntry> _entries = const [];
  Map<int, int> _indexById = const {};
  StickerFilter _filter = const StickerFilter();

  AlbumStats _stats = AlbumStats.fromEntries(const []);
  List<AlbumListItem> _items = const [];
  List<StickerEntry> _spares = const [];
  bool _disposed = false;

  LoadStatus get status => _status;
  Album? get album => _album;
  List<Section> get sections => _sections;

  /// Todas as figurinhas do álbum (sem filtro), em ordem do catálogo.
  List<StickerEntry> get entries => _entries;
  StickerFilter get filter => _filter;
  AlbumStats get stats => _stats;

  /// Lista achatada (cabeçalhos + figurinhas) já filtrada.
  List<AlbumListItem> get visibleItems => _items;

  /// Figurinhas com repetidas, em ordem do catálogo (aba Repetidas).
  List<StickerEntry> get spareEntries => _spares;

  int quantityOf(int stickerId) {
    final i = _indexById[stickerId];
    return i == null ? 0 : _entries[i].quantity;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _notify();
    try {
      final albums = await _repository.getAlbums();
      if (albums.isEmpty) {
        _album = null;
        _sections = const [];
        _setEntries(const []);
      } else {
        // MVP: um álbum ativo. Múltiplos álbuns exigirão um seletor.
        _album = albums.first;
        _sections = await _repository.getSections(_album!.id);
        _setEntries(await _repository.getEntries(_album!.id));
      }
      _status = LoadStatus.ready;
    } catch (_) {
      _status = LoadStatus.error;
    }
    _notify();
  }

  void setQuery(String query) => _applyFilter(_filter.copyWith(query: query));

  void setStatus(StickerStatus status) =>
      _applyFilter(_filter.copyWith(status: status));

  void setSection(int? sectionId) =>
      _applyFilter(_filter.copyWith(sectionId: () => sectionId));

  void clearFilters() => _applyFilter(const StickerFilter());

  Future<bool> increment(int stickerId) =>
      setQuantity(stickerId, quantityOf(stickerId) + 1);

  Future<bool> decrement(int stickerId) =>
      setQuantity(stickerId, quantityOf(stickerId) - 1);

  /// Define a quantidade (limitada a 0..[StickerEntry.maxQuantity]).
  /// Retorna `false` se a gravação falhou (e a alteração foi desfeita).
  Future<bool> setQuantity(int stickerId, int quantity) async {
    final i = _indexById[stickerId];
    if (i == null) return false;
    final previous = _entries[i].quantity;
    final next = quantity.clamp(0, StickerEntry.maxQuantity);
    if (next == previous) return true;

    _replaceQuantity(i, next);
    _notify();
    try {
      await _repository.setQuantity(stickerId, next);
      return true;
    } catch (_) {
      _replaceQuantity(i, previous);
      _notify();
      return false;
    }
  }

  void _replaceQuantity(int index, int quantity) {
    _entries = List.of(_entries)
      ..[index] = _entries[index].withQuantity(quantity);
    _recompute();
  }

  void _applyFilter(StickerFilter filter) {
    _filter = filter;
    _items = buildListItems(_sections, _entries, _filter);
    _notify();
  }

  void _setEntries(List<StickerEntry> entries) {
    _entries = entries;
    _indexById = {
      for (var i = 0; i < entries.length; i++) entries[i].sticker.id: i,
    };
    _recompute();
  }

  void _recompute() {
    _stats = AlbumStats.fromEntries(_entries);
    _spares = _entries.where((e) => e.hasSpares).toList();
    _items = buildListItems(_sections, _entries, _filter);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
