import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../domain/sticker_filter.dart';
import 'album_provider.dart';
import 'widgets/sticker_tile.dart';

/// Aba Álbum: busca, filtros e lista de figurinhas agrupada por seção.
class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AlbumProvider, LoadStatus>((p) => p.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Álbum')),
      body: switch (status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => EmptyState(
          icon: Icons.error_outline,
          message: 'Não foi possível carregar o álbum.',
          actionLabel: 'Tentar novamente',
          onAction: () => context.read<AlbumProvider>().load(),
        ),
        LoadStatus.ready => const _AlbumContent(),
      },
    );
  }
}

class _AlbumContent extends StatelessWidget {
  const _AlbumContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SearchField(),
        const _FilterChips(),
        const Expanded(child: _StickerList()),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar código (ex.: FA-01)',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          isDense: true,
        ),
        textInputAction: TextInputAction.search,
        onChanged: context.read<AlbumProvider>().setQuery,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AlbumProvider>();
    final filter = context.select<AlbumProvider, StickerFilter>(
      (p) => p.filter,
    );
    final sections = provider.sections;

    return Column(
      children: [
        _ChipRow(
          children: [
            for (final s in StickerStatus.values)
              ChoiceChip(
                label: Text(s.label),
                selected: filter.status == s,
                onSelected: (_) => provider.setStatus(s),
              ),
          ],
        ),
        _ChipRow(
          children: [
            ChoiceChip(
              label: const Text('Todas as seções'),
              selected: filter.sectionId == null,
              onSelected: (_) => provider.setSection(null),
            ),
            for (final s in sections)
              ChoiceChip(
                label: Text(s.name),
                selected: filter.sectionId == s.id,
                onSelected: (_) => provider.setSection(s.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

class _StickerList extends StatelessWidget {
  const _StickerList();

  @override
  Widget build(BuildContext context) {
    final items = context.select<AlbumProvider, List<AlbumListItem>>(
      (p) => p.visibleItems,
    );
    final provider = context.read<AlbumProvider>();

    if (items.isEmpty) {
      return provider.filter.isActive
          ? EmptyState(
              icon: Icons.search_off,
              message: 'Nenhuma figurinha encontrada com esses filtros.',
              actionLabel: 'Limpar filtros',
              onAction: provider.clearFilters,
            )
          : const EmptyState(
              icon: Icons.collections_bookmark_outlined,
              message: 'Este álbum ainda não tem figurinhas.',
            );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      itemBuilder: (_, i) => switch (items[i]) {
        SectionHeaderItem h => _SectionHeader(item: h),
        StickerListItem s => StickerTile(
          key: ValueKey(s.entry.sticker.id),
          sticker: s.entry.sticker,
        ),
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.item});

  final SectionHeaderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(item.section.name, style: theme.textTheme.titleLarge),
            ),
            Text(
              '${item.owned}/${item.total}',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
