import 'dart:convert';
import 'dart:io';

import 'package:figurinhas_copa/core/errors/app_exception.dart';
import 'package:figurinhas_copa/features/album/domain/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

String _catalog({
  Object? version = 1,
  List<Object?>? sections,
  String albumId = 'x',
}) => jsonEncode({
  'album': {'id': albumId, 'name': 'Teste', 'catalogVersion': version},
  'sections':
      sections ??
      [
        {
          'key': 'AA',
          'name': 'A',
          'stickers': ['AA-01', 'AA-02'],
        },
      ],
});

List<String> _problems(String json) {
  try {
    CatalogParser.parse(json);
  } on CatalogFormatException catch (e) {
    return e.problems;
  }
  fail('Deveria ter lançado CatalogFormatException');
}

void main() {
  test('aceita catálogo válido', () {
    final c = CatalogParser.parse(_catalog());
    expect(c.albumId, 'x');
    expect(c.version, 1);
    expect(c.sections.single.codes, ['AA-01', 'AA-02']);
  });

  test(
    'o catálogo de demonstração do projeto é válido e marcado como demo',
    () {
      final c = CatalogParser.parse(
        File('assets/catalogs/demo_copa_2026.json').readAsStringSync(),
      );
      expect(c.isDemo, isTrue);
      expect(c.sections.expand((s) => s.codes).length, 968);
      // Especiais + 48 seleções da Copa 2026.
      expect(c.sections, hasLength(49));
      expect(c.version, 2);
    },
  );

  test('rejeita JSON inválido', () {
    expect(_problems('{oops'), isNotEmpty);
  });

  test('rejeita código duplicado, mesmo entre seções', () {
    final problems = _problems(
      _catalog(
        sections: [
          {
            'key': 'AA',
            'name': 'A',
            'stickers': ['AA-01'],
          },
          {
            'key': 'BB',
            'name': 'B',
            'stickers': ['AA-01'],
          },
        ],
      ),
    );
    expect(problems.single, contains('duplicado'));
  });

  test('rejeita seção duplicada, código mal formado e versão inválida', () {
    final problems = _problems(
      _catalog(
        version: 0,
        sections: [
          {
            'key': 'AA',
            'name': 'A',
            'stickers': ['aa-01', 'A|B'],
          },
          {
            'key': 'AA',
            'name': 'B',
            'stickers': ['BB-01'],
          },
        ],
      ),
    );
    expect(problems, hasLength(4));
  });

  test('rejeita álbum sem seções', () {
    expect(_problems(_catalog(sections: [])), isNotEmpty);
  });
}
