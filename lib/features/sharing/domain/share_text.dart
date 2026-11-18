import '../../album/domain/album.dart';

/// Monta as mensagens de texto compartilháveis (WhatsApp, e-mail etc.).
abstract final class ShareText {
  static String missing(Album album, List<StickerEntry> entries) {
    final codes = [
      for (final e in _ordered(entries))
        if (e.isMissing) e.sticker.code,
    ];
    final title = '${album.name} — Figurinhas faltantes';
    if (codes.isEmpty) {
      return '$title\n\nNenhuma figurinha faltando. Álbum completo!';
    }
    final label = codes.length == 1
        ? 'figurinha faltante'
        : 'figurinhas faltantes';
    return '$title\n\n${codes.join(', ')}\n\nTotal: ${codes.length} $label.';
  }

  static String spares(Album album, List<StickerEntry> entries) {
    final spares = _ordered(entries).where((e) => e.hasSpares).toList();
    final title = '${album.name} — Figurinhas repetidas';
    if (spares.isEmpty) return '$title\n\nNenhuma figurinha repetida.';
    final lines = [
      for (final e in spares)
        '${e.sticker.code} — ${e.spares} '
            '${e.spares == 1 ? 'cópia disponível' : 'cópias disponíveis'}',
    ];
    final copies = spares.fold<int>(0, (sum, e) => sum + e.spares);
    return '$title\n\n${lines.join('\n')}\n\n'
        'Total: ${spares.length} ${spares.length == 1 ? 'figurinha' : 'figurinhas'}, '
        '$copies ${copies == 1 ? 'cópia' : 'cópias'}.';
  }

  static List<StickerEntry> _ordered(List<StickerEntry> entries) =>
      [...entries]
        ..sort((a, b) => a.sticker.sortIndex.compareTo(b.sticker.sortIndex));
}
