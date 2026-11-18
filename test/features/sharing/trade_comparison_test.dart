import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/sharing/domain/missing_list_codec.dart';
import 'package:figurinhas_copa/features/sharing/domain/trade_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

import 'missing_list_codec_test.dart' show album, entriesOf;

MissingList theirsMissing(List<int> theirQuantities, {Album? from}) =>
    MissingListCodec.decode(
      MissingListCodec.encode(from ?? album, entriesOf(theirQuantities)),
    );

QrErrorKind? incompatibility(
  Album local,
  List<StickerEntry> entries,
  MissingList theirs,
) {
  try {
    compareTrade(theirs, local, entries);
  } on QrFormatException catch (e) {
    return e.kind;
  }
  return null;
}

void main() {
  test('oferece só o que a outra pessoa precisa E eu tenho repetido', () {
    // Eu:      X-1=3 (2 rep), X-2=0, X-3=1 (sem rep), X-4=2 (1 rep), X-5=5 (4 rep)
    final mine = entriesOf([3, 0, 1, 2, 5]);
    // Ela:     precisa de X-1, X-2, X-3, X-4; já tem X-5.
    final theirs = theirsMissing([0, 0, 0, 0, 1]);

    final result = compareTrade(theirs, album, mine);

    expect(result.theirMissing.map((s) => s.code), [
      'X-1',
      'X-2',
      'X-3',
      'X-4',
    ]);
    expect(result.offerable.map((e) => e.sticker.code), ['X-1', 'X-4']);
    expect(result.offerableCount, 2);
    expect(result.offerable.map((e) => e.spares), [2, 1]);
  });

  test('sem repetidas coincidentes não há nada para oferecer', () {
    final result = compareTrade(
      theirsMissing([0, 1, 1]),
      album,
      entriesOf([1, 5, 1]),
    );
    expect(result.theirMissing, hasLength(1));
    expect(result.offerable, isEmpty);
  });

  test('não altera o inventário local', () {
    final mine = entriesOf([3, 0]);
    compareTrade(theirsMissing([0, 0]), album, mine);
    expect(mine.map((e) => e.quantity), [3, 0]);
  });

  group('compatibilidade', () {
    final mine = entriesOf([1, 1, 1]);

    test('compatível: mesmo álbum, versão e total', () {
      expect(incompatibility(album, mine, theirsMissing([0, 0, 0])), isNull);
    });

    test('álbum diferente', () {
      const other = Album(
        id: 'outro',
        name: 'O',
        catalogVersion: 3,
        isDemo: false,
      );
      expect(
        incompatibility(album, mine, theirsMissing([0, 0, 0], from: other)),
        QrErrorKind.incompatible,
      );
    });

    test('versão de catálogo diferente', () {
      const newer = Album(
        id: 'copa-demo',
        name: 'C',
        catalogVersion: 4,
        isDemo: true,
      );
      expect(
        incompatibility(album, mine, theirsMissing([0, 0, 0], from: newer)),
        QrErrorKind.incompatible,
      );
    });

    test('total de figurinhas diferente', () {
      expect(
        incompatibility(album, mine, theirsMissing([0, 0])),
        QrErrorKind.incompatible,
      );
    });
  });
}
