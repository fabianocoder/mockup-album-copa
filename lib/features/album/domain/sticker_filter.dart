import 'album.dart';

enum StickerStatus {
  all('Todas'),
  missing('Faltam'),
  owned('Tenho'),
  repeated('Repetidas');

  const StickerStatus(this.label);
  final String label;

  bool matches(StickerEntry e) => switch (this) {
    StickerStatus.all => true,
    StickerStatus.missing => e.isMissing,
    StickerStatus.owned => e.isOwned,
    StickerStatus.repeated => e.hasSpares,
  };
}

/// Filtro combinado de busca por código, situação e seção.
class StickerFilter {
  const StickerFilter({
    this.query = '',
    this.status = StickerStatus.all,
    this.sectionId,
  });

  final String query;
  final StickerStatus status;
  final int? sectionId;

  bool get isActive =>
      query.trim().isNotEmpty ||
      status != StickerStatus.all ||
      sectionId != null;

  StickerFilter copyWith({
    String? query,
    StickerStatus? status,
    int? Function()? sectionId,
  }) => StickerFilter(
    query: query ?? this.query,
    status: status ?? this.status,
    sectionId: sectionId != null ? sectionId() : this.sectionId,
  );

  bool matches(StickerEntry e) {
    if (sectionId != null && e.sticker.sectionId != sectionId) return false;
    if (!status.matches(e)) return false;
    final q = _normalize(query);
    return q.isEmpty || _normalize(e.sticker.code).contains(q);
  }

  /// Ignora caixa, espaços e hífens: "fa01" encontra "FA-01".
  static String _normalize(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
}

sealed class AlbumListItem {
  const AlbumListItem();
}

class SectionHeaderItem extends AlbumListItem {
  const SectionHeaderItem({
    required this.section,
    required this.owned,
    required this.total,
  });

  final Section section;

  /// Contagens da seção inteira, independentes do filtro.
  final int owned;
  final int total;
}

class StickerListItem extends AlbumListItem {
  const StickerListItem(this.entry);
  final StickerEntry entry;
}

/// Monta a lista achatada (cabeçalho de seção + figurinhas) aplicando
/// [filter]. Seções sem figurinhas visíveis são omitidas.
List<AlbumListItem> buildListItems(
  List<Section> sections,
  List<StickerEntry> entries,
  StickerFilter filter,
) {
  final bySection = <int, List<StickerEntry>>{};
  for (final e in entries) {
    (bySection[e.sticker.sectionId] ??= []).add(e);
  }

  final items = <AlbumListItem>[];
  for (final section in sections) {
    final all = bySection[section.id] ?? const <StickerEntry>[];
    final visible = all.where(filter.matches).toList();
    if (visible.isEmpty) continue;
    items.add(
      SectionHeaderItem(
        section: section,
        owned: all.where((e) => e.isOwned).length,
        total: all.length,
      ),
    );
    items.addAll(visible.map(StickerListItem.new));
  }
  return items;
}
