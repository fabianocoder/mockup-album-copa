import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../album/presentation/album_provider.dart';
import '../domain/missing_list_codec.dart';
import '../domain/trade_comparison.dart';

/// Resultado da leitura de um QR Code: faltantes da outra pessoa e o que o
/// usuário pode oferecer. Somente leitura — nunca altera a coleção.
class TradeResultPage extends StatelessWidget {
  const TradeResultPage({super.key, required this.rawContent});

  final String rawContent;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlbumProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Troca')),
      body: _body(context, provider),
    );
  }

  Widget _body(BuildContext context, AlbumProvider provider) {
    final album = provider.album;
    if (album == null) {
      return const EmptyState(
        icon: Icons.error_outline,
        message: 'O álbum ainda não está disponível.',
      );
    }
    final TradeComparison result;
    try {
      result = compareTrade(
        MissingListCodec.decode(rawContent),
        album,
        provider.entries,
      );
    } on QrFormatException catch (e) {
      return EmptyState(
        icon: switch (e.kind) {
          QrErrorKind.incompatible => Icons.sync_problem,
          QrErrorKind.corrupted => Icons.broken_image_outlined,
          _ => Icons.qr_code_scanner,
        },
        message: e.message,
        actionLabel: 'Voltar',
        onAction: () => Navigator.of(context).pop(),
      );
    }
    return _Result(result: result);
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result});

  final TradeComparison result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = result.offerableCount;
    final offerCodes = {for (final e in result.offerable) e.sticker.code};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$offer',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  offer == 1
                      ? 'figurinha sua pode ajudar nesta troca'
                      : 'figurinhas suas podem ajudar nesta troca',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ela precisa de ${result.theirMissing.length} '
                  '${result.theirMissing.length == 1 ? 'figurinha' : 'figurinhas'}. '
                  'Sua coleção não foi alterada.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Você pode oferecer', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (result.offerable.isEmpty)
          const Text('Nenhuma das suas repetidas serve para esta pessoa.')
        else
          for (final e in result.offerable)
            Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(e.sticker.code),
                subtitle: Text(
                  '${e.spares} ${e.spares == 1 ? 'cópia disponível' : 'cópias disponíveis'}',
                ),
              ),
            ),
        const SizedBox(height: 16),
        Text('Faltantes da outra pessoa', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (result.theirMissing.isEmpty)
          const Text('Ela não tem figurinhas faltando.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in result.theirMissing)
                Semantics(
                  label: offerCodes.contains(s.code)
                      ? '${s.code}, você tem repetida'
                      : s.code,
                  child: ExcludeSemantics(
                    child: Chip(
                      label: Text(s.code),
                      avatar: offerCodes.contains(s.code)
                          ? const Icon(Icons.check, size: 18)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
