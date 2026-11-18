import 'dart:convert';

import '../../../core/errors/app_exception.dart';

/// Catálogo de um álbum, já validado.
class CatalogData {
  const CatalogData({
    required this.albumId,
    required this.name,
    required this.version,
    required this.isDemo,
    required this.sections,
  });

  final String albumId;
  final String name;
  final int version;
  final bool isDemo;
  final List<CatalogSection> sections;
}

class CatalogSection {
  const CatalogSection({
    required this.key,
    required this.name,
    required this.codes,
  });

  final String key;
  final String name;
  final List<String> codes;
}

/// Converte e valida o JSON do catálogo. Formato:
/// ```json
/// {
///   "album": {"id": "...", "name": "...", "catalogVersion": 1, "isDemo": true},
///   "sections": [{"key": "AB", "name": "...", "stickers": ["AB-01", "AB-02"]}]
/// }
/// ```
/// Códigos: maiúsculas, dígitos e hífen (1–16 caracteres), únicos no álbum.
abstract final class CatalogParser {
  static final _codePattern = RegExp(r'^[A-Z0-9-]{1,16}$');

  static CatalogData parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw CatalogFormatException(['JSON inválido: ${e.message}']);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CatalogFormatException([
        'A raiz do catálogo deve ser um objeto.',
      ]);
    }

    final problems = <String>[];
    final album = decoded['album'];
    var albumId = '';
    var name = '';
    var version = 0;
    var isDemo = false;
    if (album is! Map<String, dynamic>) {
      problems.add('Campo "album" ausente ou inválido.');
    } else {
      albumId = _string(album['id']);
      name = _string(album['name']);
      final v = album['catalogVersion'];
      version = v is int ? v : 0;
      isDemo = album['isDemo'] == true;
      if (albumId.isEmpty || albumId.contains('|')) {
        problems.add('album.id é obrigatório e não pode conter "|".');
      }
      if (name.isEmpty) problems.add('album.name é obrigatório.');
      if (version < 1) {
        problems.add('album.catalogVersion deve ser um inteiro >= 1.');
      }
    }

    final sections = <CatalogSection>[];
    final rawSections = decoded['sections'];
    if (rawSections is! List || rawSections.isEmpty) {
      problems.add('"sections" deve ser uma lista não vazia.');
    } else {
      final keys = <String>{};
      final codes = <String>{};
      for (var i = 0; i < rawSections.length; i++) {
        final raw = rawSections[i];
        if (raw is! Map<String, dynamic>) {
          problems.add('sections[$i] inválida.');
          continue;
        }
        final key = _string(raw['key']);
        final sectionName = _string(raw['name']);
        if (key.isEmpty || sectionName.isEmpty) {
          problems.add('sections[$i] precisa de "key" e "name".');
        } else if (!keys.add(key)) {
          problems.add('Seção duplicada: $key.');
        }
        final rawCodes = raw['stickers'];
        if (rawCodes is! List || rawCodes.isEmpty) {
          problems.add('Seção "$key" sem figurinhas.');
          continue;
        }
        final sectionCodes = <String>[];
        for (final c in rawCodes) {
          final code = c is String ? c : '';
          if (!_codePattern.hasMatch(code)) {
            problems.add('Código inválido na seção "$key": "$c".');
          } else if (!codes.add(code)) {
            problems.add('Código duplicado: $code.');
          } else {
            sectionCodes.add(code);
          }
        }
        sections.add(
          CatalogSection(key: key, name: sectionName, codes: sectionCodes),
        );
      }
    }

    if (problems.isNotEmpty) throw CatalogFormatException(problems);
    return CatalogData(
      albumId: albumId,
      name: name,
      version: version,
      isDemo: isDemo,
      sections: sections,
    );
  }

  static String _string(Object? v) => v is String ? v.trim() : '';
}
