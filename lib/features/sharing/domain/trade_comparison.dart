import '../../album/domain/album.dart';
import 'missing_list_codec.dart';

/// Resultado da comparação entre as faltantes de outra pessoa e as
/// repetidas locais. Somente leitura: nunca altera o inventário.
class TradeComparison {
  const TradeComparison({required this.theirMissing, required this.offerable});

  /// Todas as figurinhas que a outra pessoa não tem (em ordem do catálogo).
  final List<Sticker> theirMissing;

  /// Das faltantes dela, as que o usuário tem repetidas (com suas quantidades).
  final List<StickerEntry> offerable;

  int get offerableCount => offerable.length;
}

/// Compara [theirs] com o inventário local.
///
/// Lança [QrFormatException] (`incompatible`) se o álbum, a versão do
/// catálogo ou o total de figurinhas não coincidirem: os bits só têm
/// significado para o mesmo catálogo.
TradeComparison compareTrade(
  MissingList theirs,
  Album album,
  List<StickerEntry> entries,
) {
  if (theirs.albumId != album.id) {
    throw const QrFormatException(
      QrErrorKind.incompatible,
      'Este QR Code é de outro álbum.',
    );
  }
  if (theirs.catalogVersion != album.catalogVersion ||
      theirs.total != entries.length) {
    throw const QrFormatException(
      QrErrorKind.incompatible,
      'O catálogo do QR Code tem outra versão. '
      'Atualize o aplicativo nos dois aparelhos.',
    );
  }

  final sorted = [...entries]
    ..sort((a, b) => a.sticker.sortIndex.compareTo(b.sticker.sortIndex));
  final theirMissing = <Sticker>[];
  final offerable = <StickerEntry>[];
  for (var i = 0; i < sorted.length; i++) {
    if (!theirs.isMissingAt(i)) continue;
    theirMissing.add(sorted[i].sticker);
    if (sorted[i].hasSpares) offerable.add(sorted[i]);
  }
  return TradeComparison(theirMissing: theirMissing, offerable: offerable);
}
