import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/album.dart';
import '../album_provider.dart';
import 'quantity_dialog.dart';

/// Linha de uma figurinha com controles de quantidade.
///
/// Observa apenas a quantidade da própria figurinha (`context.select`),
/// então alterar uma linha não reconstrói as demais.
class StickerTile extends StatelessWidget {
  const StickerTile({super.key, required this.sticker});

  final Sticker sticker;

  @override
  Widget build(BuildContext context) {
    final quantity = context.select<AlbumProvider, int>(
      (p) => p.quantityOf(sticker.id),
    );
    final scheme = Theme.of(context).colorScheme;
    final spares = quantity > 1 ? quantity - 1 : 0;

    final (statusText, background) = switch (quantity) {
      0 => ('Faltante', null),
      1 => ('Adquirida', scheme.primaryContainer),
      _ => (
        '$spares ${spares == 1 ? 'repetida' : 'repetidas'}',
        scheme.tertiaryContainer,
      ),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sticker.code,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remover uma cópia de ${sticker.code}',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: quantity == 0
                  ? null
                  : () => _run(context, (p) => p.decrement(sticker.id)),
            ),
            Semantics(
              button: true,
              label:
                  'Quantidade de ${sticker.code}: $quantity. Toque para editar',
              child: InkWell(
                key: ValueKey('quantity-${sticker.code}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _edit(context, quantity),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Adicionar uma cópia de ${sticker.code}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: quantity >= StickerEntry.maxQuantity
                  ? null
                  : () => _run(context, (p) => p.increment(sticker.id)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, int current) async {
    final value = await showQuantityDialog(
      context,
      code: sticker.code,
      current: current,
    );
    if (value != null && context.mounted) {
      await _run(context, (p) => p.setQuantity(sticker.id, value));
    }
  }

  Future<void> _run(
    BuildContext context,
    Future<bool> Function(AlbumProvider) action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action(context.read<AlbumProvider>());
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a alteração.')),
        );
    }
  }
}
