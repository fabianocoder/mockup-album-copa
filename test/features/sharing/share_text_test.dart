import 'package:figurinhas_copa/features/sharing/domain/share_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'missing_list_codec_test.dart' show album, entriesOf;

void main() {
  test('lista de faltantes segue o formato esperado', () {
    final text = ShareText.missing(album, entriesOf([0, 2, 0, 0]));
    expect(
      text,
      'Copa Demo — Figurinhas faltantes\n\n'
      'X-1, X-3, X-4\n\n'
      'Total: 3 figurinhas faltantes.',
    );
  });

  test('singular e álbum completo', () {
    expect(
      ShareText.missing(album, entriesOf([0, 1])),
      endsWith('Total: 1 figurinha faltante.'),
    );
    expect(
      ShareText.missing(album, entriesOf([1, 1])),
      contains('Álbum completo'),
    );
  });

  test('lista de repetidas mostra cópias disponíveis (quantidade - 1)', () {
    final text = ShareText.spares(album, entriesOf([4, 1, 2, 0]));
    expect(
      text,
      'Copa Demo — Figurinhas repetidas\n\n'
      'X-1 — 3 cópias disponíveis\n'
      'X-3 — 1 cópia disponível\n\n'
      'Total: 2 figurinhas, 4 cópias.',
    );
  });

  test('sem repetidas', () {
    expect(
      ShareText.spares(album, entriesOf([1, 0])),
      contains('Nenhuma figurinha repetida.'),
    );
  });

  test('respeita a ordem do catálogo mesmo com entradas embaralhadas', () {
    final shuffled = entriesOf([0, 0, 0]).reversed.toList();
    expect(ShareText.missing(album, shuffled), contains('X-1, X-2, X-3'));
  });

  test('usa StickerEntry sem mutar a lista recebida', () {
    final input = entriesOf([0, 1]).reversed.toList();
    final before = input.map((e) => e.sticker.code).toList();
    ShareText.missing(album, input);
    expect(input.map((e) => e.sticker.code), before);
  });
}
