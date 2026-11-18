import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/album/domain/album_stats.dart';
import 'package:flutter_test/flutter_test.dart';

StickerEntry _entry(int id, int quantity) => StickerEntry(
  sticker: Sticker(id: id, code: 'X-$id', sectionId: 1, sortIndex: id),
  quantity: quantity,
);

void main() {
  group('StickerEntry', () {
    test('quantidade 0 é faltante', () {
      final e = _entry(1, 0);
      expect(e.isMissing, isTrue);
      expect(e.isOwned, isFalse);
      expect(e.spares, 0);
    });

    test('quantidade 1 é adquirida sem repetidas', () {
      final e = _entry(1, 1);
      expect(e.isOwned, isTrue);
      expect(e.hasSpares, isFalse);
    });

    test('quantidade 3 tem duas repetidas', () {
      expect(_entry(1, 3).spares, 2);
    });

    test('não aceita quantidade negativa', () {
      expect(() => _entry(1, -1), throwsA(isA<AssertionError>()));
    });
  });

  group('AlbumStats', () {
    test('calcula totais, faltantes, repetidas e percentual', () {
      final stats = AlbumStats.fromEntries([
        _entry(1, 0),
        _entry(2, 1),
        _entry(3, 3),
        _entry(4, 2),
      ]);
      expect(stats.total, 4);
      expect(stats.owned, 3);
      expect(stats.missing, 1);
      expect(stats.spareCopies, 3);
      expect(stats.completionPercent, 75);
    });

    test('álbum vazio tem 0% sem dividir por zero', () {
      final stats = AlbumStats.fromEntries(const []);
      expect(stats.completionPercent, 0);
      expect(stats.missing, 0);
    });

    test('repetidas não contam como figurinhas diferentes', () {
      final stats = AlbumStats.fromEntries([_entry(1, 5), _entry(2, 0)]);
      expect(stats.owned, 1);
      expect(stats.completionPercent, 50);
    });
  });
}
