import 'package:figurinhas_copa/core/utils/crc32.dart';
import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/sharing/domain/missing_list_codec.dart';
import 'package:flutter_test/flutter_test.dart';

const album = Album(
  id: 'copa-demo',
  name: 'Copa Demo',
  catalogVersion: 3,
  isDemo: true,
);

List<StickerEntry> entriesOf(List<int> quantities) => [
  for (var i = 0; i < quantities.length; i++)
    StickerEntry(
      sticker: Sticker(
        id: i + 1,
        code: 'X-${i + 1}',
        sectionId: 1,
        sortIndex: i,
      ),
      quantity: quantities[i],
    ),
];

QrErrorKind kindOf(String raw) {
  try {
    MissingListCodec.decode(raw);
  } on QrFormatException catch (e) {
    return e.kind;
  }
  fail('Deveria ter lançado QrFormatException');
}

/// Recalcula o CRC para testar a validação estrutural isoladamente.
String withValidCrc(String body) =>
    '$body|${Crc32.of(body.codeUnits).toRadixString(16).padLeft(8, '0')}';

void main() {
  test('CRC-32 confere com o vetor de teste padrão', () {
    expect(Crc32.of('123456789'.codeUnits), 0xCBF43926);
  });

  test('ida e volta preserva álbum, versão, total e faltantes', () {
    final entries = entriesOf([0, 1, 0, 3, 0, 0, 0, 0, 0, 2]);
    final raw = MissingListCodec.encode(album, entries);
    final decoded = MissingListCodec.decode(raw);

    expect(decoded.albumId, 'copa-demo');
    expect(decoded.catalogVersion, 3);
    expect(decoded.total, 10);
    expect(decoded.missingCount, 7);
    expect(
      [for (var i = 0; i < 10; i++) decoded.isMissingAt(i)],
      [
        true, false, true, false, true, true, true, true, true, false, //
      ],
    );
  });

  test('independe da ordem em que as entradas são fornecidas', () {
    final entries = entriesOf([0, 1, 0]);
    expect(
      MissingListCodec.encode(album, entries.reversed.toList()),
      MissingListCodec.encode(album, entries),
    );
  });

  test('álbum completo e álbum vazio de figurinhas fazem ida e volta', () {
    expect(
      MissingListCodec.decode(
        MissingListCodec.encode(album, entriesOf([1, 2, 3])),
      ).missingCount,
      0,
    );
    expect(
      MissingListCodec.decode(MissingListCodec.encode(album, [])).total,
      0,
    );
  });

  test('álbum de 1000 figurinhas cabe com folga em um QR Code', () {
    final raw = MissingListCodec.encode(album, entriesOf(List.filled(1000, 0)));
    expect(raw.length, lessThan(250));
    expect(raw.length, lessThan(MissingListCodec.maxQrPayloadLength));
    expect(MissingListCodec.decode(raw).missingCount, 1000);
  });

  test('conteúdo é ASCII compacto e identifica formato, álbum e versão', () {
    final raw = MissingListCodec.encode(album, entriesOf([0, 1]));
    expect(raw, startsWith('FIG1|copa-demo|3|2|'));
    expect(raw.codeUnits.every((c) => c < 128), isTrue);
  });

  group('rejeita conteúdo inválido', () {
    final good = MissingListCodec.encode(album, entriesOf([0, 1, 0, 1]));

    test('texto qualquer ou URL', () {
      expect(kindOf('https://exemplo.com'), QrErrorKind.notRecognized);
      expect(kindOf(''), QrErrorKind.notRecognized);
    });

    test('versão de formato desconhecida', () {
      expect(
        kindOf(good.replaceFirst('FIG1', 'FIG2')),
        QrErrorKind.unsupportedFormat,
      );
    });

    test('conteúdo adulterado quebra o CRC', () {
      expect(kindOf(good.replaceFirst('|3|', '|4|')), QrErrorKind.corrupted);
      expect(kindOf(good.substring(0, good.length - 1)), QrErrorKind.corrupted);
    });

    test('campos faltando', () {
      expect(kindOf('FIG1|copa-demo|3'), QrErrorKind.malformed);
    });

    test('bitmap com tamanho incompatível com o total', () {
      expect(
        kindOf(withValidCrc('FIG1|copa-demo|3|20|AA')),
        QrErrorKind.malformed,
      );
    });

    test('bits sobrando além do total', () {
      // total 2 usa só 2 bits; 0xFF tem bits extras ligados.
      expect(
        kindOf(withValidCrc('FIG1|copa-demo|3|2|_w')),
        QrErrorKind.malformed,
      );
    });

    test('base64 inválido e números inválidos', () {
      expect(
        kindOf(withValidCrc('FIG1|copa-demo|3|8|!!!')),
        QrErrorKind.malformed,
      );
      expect(
        kindOf(withValidCrc('FIG1|copa-demo|x|8|AA')),
        QrErrorKind.malformed,
      );
      expect(
        kindOf(withValidCrc('FIG1|copa-demo|0|8|AA')),
        QrErrorKind.malformed,
      );
    });
  });
}
