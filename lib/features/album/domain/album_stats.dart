import 'album.dart';

/// Indicadores da coleção, sempre calculados a partir do inventário.
class AlbumStats {
  const AlbumStats({
    required this.total,
    required this.owned,
    required this.spareCopies,
  });

  factory AlbumStats.fromEntries(Iterable<StickerEntry> entries) {
    var total = 0;
    var owned = 0;
    var spares = 0;
    for (final e in entries) {
      total++;
      if (e.isOwned) owned++;
      spares += e.spares;
    }
    return AlbumStats(total: total, owned: owned, spareCopies: spares);
  }

  final int total;

  /// Figurinhas diferentes adquiridas.
  final int owned;

  /// Total de cópias repetidas disponíveis para troca.
  final int spareCopies;

  int get missing => total - owned;

  /// 0–100. Álbum vazio resulta em 0.
  double get completionPercent => total == 0 ? 0 : owned / total * 100;
}
