import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../domain/album.dart';
import 'album_provider.dart';
import 'widgets/sticker_tile.dart';

/// Aba Repetidas: figurinhas com cópias extras, disponíveis para troca.
class SparesPage extends StatelessWidget {
  const SparesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AlbumProvider, LoadStatus>((p) => p.status);
    final spares = context.select<AlbumProvider, List<StickerEntry>>(
      (p) => p.spareEntries,
    );
    final totalCopies = context.select<AlbumProvider, int>(
      (p) => p.stats.spareCopies,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repetidas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$totalCopies ${totalCopies == 1 ? 'cópia' : 'cópias'} para troca',
            ),
          ),
        ),
      ),
      body: status == LoadStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : spares.isEmpty
          ? const EmptyState(
              icon: Icons.swap_horiz,
              message: 'Você ainda não tem figurinhas repetidas.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: spares.length,
              itemBuilder: (_, i) => StickerTile(
                key: ValueKey(spares[i].sticker.id),
                sticker: spares[i].sticker,
              ),
            ),
    );
  }
}
