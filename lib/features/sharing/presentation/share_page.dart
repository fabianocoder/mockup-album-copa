import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../album/presentation/album_provider.dart';
import '../domain/share_text.dart';
import 'my_qr_page.dart';
import 'qr_scanner_page.dart';
import 'text_sharer.dart';
import 'trade_result_page.dart';

/// Aba Compartilhar: listas por texto e troca por QR Code.
class SharePage extends StatelessWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AlbumProvider, bool>(
      (p) => p.status == LoadStatus.ready && p.album != null,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhar')),
      body: ready
          ? const _ShareContent()
          : const EmptyState(
              icon: Icons.qr_code_2,
              message: 'O álbum ainda não está disponível.',
            ),
    );
  }
}

class _ShareContent extends StatelessWidget {
  const _ShareContent();

  @override
  Widget build(BuildContext context) {
    final stats = context.select((AlbumProvider p) => p.stats);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Enviar lista por texto',
          subtitle: 'WhatsApp, Telegram, e-mail ou qualquer app instalado no aparelho.',
          children: [
            _ActionTile(
              icon: Icons.list_alt,
              title: 'Compartilhar faltantes',
              subtitle: '${stats.missing} figurinhas',
              onTap: () => _shareText(context, missing: true),
            ),
            _ActionTile(
              icon: Icons.swap_horiz,
              title: 'Compartilhar repetidas',
              subtitle: '${stats.spareCopies} cópias para troca',
              onTap: () => _shareText(context, missing: false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Trocar por QR Code',
          subtitle: 'Funciona sem internet. Nada é alterado na sua coleção ao ler o QR Code de outra pessoa.',
          children: [
            _ActionTile(
              icon: Icons.qr_code_2,
              title: 'Mostrar meu QR Code',
              subtitle: 'Minhas faltantes, para a outra pessoa ler',
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const MyQrPage())),
            ),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              title: 'Ler QR Code de outra pessoa',
              subtitle: _cameraSupported
                  ? 'Ver o que posso oferecer em uma troca'
                  : 'Indisponível neste sistema (sem leitura por câmera)',
              onTap: _cameraSupported
                  ? () => _scan(context)
                  : () => _showCameraUnavailable(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareText(BuildContext context, {required bool missing}) async {
    final provider = context.read<AlbumProvider>();
    final album = provider.album!;
    final text = missing
        ? ShareText.missing(album, provider.entries)
        : ShareText.spares(album, provider.entries);
    final sharer = context.read<TextSharer>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sharer.share(text, subject: album.name);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar.')),
        );
    }
  }

  /// `mobile_scanner` só tem câmera em Android, iOS e macOS.
  static bool get _cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  void _showCameraUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'A leitura por câmera não está disponível neste sistema. '
            'Use o app no celular para ler QR Codes.',
          ),
        ),
      );
  }

  Future<void> _scan(BuildContext context) async {
    final navigator = Navigator.of(context);
    // A câmera (e sua permissão) só é acionada ao abrir esta página.
    final raw = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (raw == null || !context.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => TradeResultPage(rawContent: raw)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        minVerticalPadding: 12,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
