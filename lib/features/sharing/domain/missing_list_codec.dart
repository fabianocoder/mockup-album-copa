import 'dart:convert';
import 'dart:typed_data';

import '../../../core/utils/crc32.dart';
import '../../album/domain/album.dart';

/// Motivo pelo qual um QR Code não pôde ser aceito.
enum QrErrorKind {
  /// Não é um QR de figurinhas faltantes deste aplicativo.
  notRecognized,

  /// Estrutura inválida (campos ausentes, bitmap com tamanho errado...).
  malformed,

  /// Falha na verificação de integridade (CRC).
  corrupted,

  /// Versão do formato não suportada por este aplicativo.
  unsupportedFormat,

  /// Álbum ou versão do catálogo diferente do álbum local.
  incompatible,
}

class QrFormatException implements Exception {
  const QrFormatException(this.kind, this.message);

  final QrErrorKind kind;
  final String message;

  @override
  String toString() => 'QrFormatException($kind): $message';
}

/// Lista de figurinhas faltantes de um álbum, em formato compacto.
///
/// Um bit por figurinha, na ordem do catálogo (`sortIndex`): 1 = faltante.
class MissingList {
  MissingList({
    required this.albumId,
    required this.catalogVersion,
    required this.total,
    required this.bits,
  });

  final String albumId;
  final int catalogVersion;
  final int total;
  final Uint8List bits;

  bool isMissingAt(int index) => (bits[index >> 3] >> (index & 7)) & 1 == 1;

  int get missingCount {
    var n = 0;
    for (var i = 0; i < total; i++) {
      if (isMissingAt(i)) n++;
    }
    return n;
  }
}

/// Serialização da [MissingList] para QR Code.
///
/// Formato (texto ASCII, sem rede nem servidor):
/// `FIG1|<albumId>|<catalogVersion>|<total>|<bitmap base64url>|<crc32 hex>`
///
/// O CRC-32 cobre tudo antes do último `|`. Para álbuns de ~1000
/// figurinhas o conteúdo tem cerca de 190 caracteres.
abstract final class MissingListCodec {
  static const _prefix = 'FIG1';

  /// Acima disso o QR fica denso demais para leitura confiável; a interface
  /// oferece o compartilhamento por texto como alternativa.
  static const maxQrPayloadLength = 1800;

  /// Codifica as figurinhas faltantes de [entries] (qualquer ordem).
  static String encode(Album album, List<StickerEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => a.sticker.sortIndex.compareTo(b.sticker.sortIndex));
    final bits = Uint8List((sorted.length + 7) >> 3);
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].isMissing) bits[i >> 3] |= 1 << (i & 7);
    }
    final body =
        '$_prefix|${album.id}|${album.catalogVersion}|${sorted.length}|'
        '${_b64(bits)}';
    return '$body|${_crcHex(body)}';
  }

  /// Decodifica e valida a integridade. Lança [QrFormatException].
  static MissingList decode(String raw) {
    final text = raw.trim();
    if (!text.startsWith('FIG')) {
      throw const QrFormatException(
        QrErrorKind.notRecognized,
        'Este QR Code não é de figurinhas.',
      );
    }
    final parts = text.split('|');
    if (parts.first != _prefix) {
      throw const QrFormatException(
        QrErrorKind.unsupportedFormat,
        'Formato de QR Code não suportado. Atualize o aplicativo.',
      );
    }
    if (parts.length != 6) {
      throw const QrFormatException(
        QrErrorKind.malformed,
        'QR Code incompleto ou inválido.',
      );
    }

    final body = parts.sublist(0, 5).join('|');
    if (_crcHex(body) != parts[5].toLowerCase()) {
      throw const QrFormatException(
        QrErrorKind.corrupted,
        'QR Code corrompido. Tente ler novamente.',
      );
    }

    final version = int.tryParse(parts[2]);
    final total = int.tryParse(parts[3]);
    final bits = _fromB64(parts[4]);
    if (parts[1].isEmpty ||
        version == null ||
        version < 1 ||
        total == null ||
        total < 0 ||
        bits == null ||
        bits.length != (total + 7) >> 3 ||
        _hasStrayBits(bits, total)) {
      throw const QrFormatException(
        QrErrorKind.malformed,
        'QR Code incompleto ou inválido.',
      );
    }
    return MissingList(
      albumId: parts[1],
      catalogVersion: version,
      total: total,
      bits: bits,
    );
  }

  /// Bits além de [total] no último byte devem ser zero.
  static bool _hasStrayBits(Uint8List bits, int total) {
    final rest = total & 7;
    return rest != 0 && bits.isNotEmpty && (bits.last >> rest) != 0;
  }

  static String _crcHex(String body) =>
      Crc32.of(utf8.encode(body)).toRadixString(16).padLeft(8, '0');

  static String _b64(Uint8List bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List? _fromB64(String s) {
    try {
      return base64Url.decode(base64Url.normalize(s));
    } on FormatException {
      return null;
    }
  }
}
