import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../album/presentation/album_provider.dart';
import '../domain/missing_list_codec.dart';

/// Mostra o QR Code com as figurinhas faltantes do usuário.
class MyQrPage extends StatelessWidget {
  const MyQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlbumProvider>();
    final album = provider.album;
    final missing = provider.stats.missing;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu QR Code')),
      body: album == null
          ? const EmptyState(
              icon: Icons.qr_code_2,
              message: 'O álbum ainda não está disponível.',
            )
          : _body(context, provider, missing),
    );
  }

  Widget _body(BuildContext context, AlbumProvider provider, int missing) {
    if (missing == 0) {
      return const EmptyState(
        icon: Icons.celebration_outlined,
        message: 'Você não tem figurinhas faltando. Álbum completo!',
      );
    }
    final payload = MissingListCodec.encode(provider.album!, provider.entries);
    if (payload.length > MissingListCodec.maxQrPayloadLength) {
      return const EmptyState(
        icon: Icons.qr_code_2,
        message:
            'A lista é grande demais para um QR Code legível. '
            'Use "Compartilhar faltantes" por texto.',
      );
    }

    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth - 64).clamp(200.0, 360.0);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                // Fundo branco fixo: o leitor exige contraste, inclusive no
                // tema escuro.
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  key: ValueKey(payload),
                  data: payload,
                  size: side,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  semanticsLabel:
                      'QR Code com $missing figurinhas faltantes de ${provider.album!.name}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$missing ${missing == 1 ? 'figurinha faltante' : 'figurinhas faltantes'}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Peça para a outra pessoa abrir Compartilhar › Ler QR Code. '
              'Aumente o brilho da tela se a leitura falhar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}
