import 'package:share_plus/share_plus.dart';

/// Abre o menu nativo de compartilhamento. Abstraído para permitir testes
/// sem plugin de plataforma.
abstract interface class TextSharer {
  Future<void> share(String text, {String? subject});
}

class SharePlusTextSharer implements TextSharer {
  const SharePlusTextSharer();

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}
