import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../album/domain/album.dart';
import '../../album/domain/album_stats.dart';
import '../../album/presentation/album_provider.dart';

/// Aba Início: progresso e resumo da coleção.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AlbumProvider, LoadStatus>((p) => p.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: switch (status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => EmptyState(
          icon: Icons.error_outline,
          message: 'Não foi possível carregar o álbum.',
          actionLabel: 'Tentar novamente',
          onAction: () => context.read<AlbumProvider>().load(),
        ),
        LoadStatus.ready => const _DashboardContent(),
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final album = context.select<AlbumProvider, Album?>((p) => p.album);
    final stats = context.select<AlbumProvider, AlbumStats>((p) => p.stats);

    if (album == null || stats.total == 0) {
      return const EmptyState(
        icon: Icons.collections_bookmark_outlined,
        message: 'Nenhum álbum disponível.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(album.name, style: Theme.of(context).textTheme.titleLarge),
        if (album.isDemo)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Catálogo de demonstração (numeração não oficial)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        _ProgressCard(stats: stats),
        const SizedBox(height: 16),
        _StatGrid(stats: stats),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats});

  final AlbumStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = formatPercent(stats.completionPercent);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Semantics(
          container: true,
          label:
              'Álbum $percent completo, ${stats.owned} de ${stats.total} figurinhas',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conclusão', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  percent,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: stats.completionPercent / 100,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.owned} de ${stats.total} figurinhas',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final AlbumStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        label: 'Total do álbum',
        value: stats.total,
        icon: Icons.collections_bookmark_outlined,
      ),
      _StatTile(
        label: 'Adquiridas',
        value: stats.owned,
        icon: Icons.check_circle_outline,
      ),
      _StatTile(
        label: 'Faltantes',
        value: stats.missing,
        icon: Icons.radio_button_unchecked,
      ),
      _StatTile(
        label: 'Repetidas p/ troca',
        value: stats.spareCopies,
        icon: Icons.swap_horiz,
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 12),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text('$value', style: theme.textTheme.headlineMedium),
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
