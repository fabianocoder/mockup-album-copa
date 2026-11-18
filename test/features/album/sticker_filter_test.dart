import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/album/domain/sticker_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _sections = [
  Section(id: 1, key: 'AA', name: 'A', sortIndex: 0),
  Section(id: 2, key: 'BB', name: 'B', sortIndex: 1),
];

StickerEntry _e(int id, String code, int section, int q) => StickerEntry(
  sticker: Sticker(id: id, code: code, sectionId: section, sortIndex: id),
  quantity: q,
);

final _entries = [
  _e(1, 'AA-01', 1, 0),
  _e(2, 'AA-02', 1, 1),
  _e(3, 'BB-01', 2, 3),
  _e(4, 'BB-02', 2, 0),
];

List<String> _codes(StickerFilter f) => buildListItems(
  _sections,
  _entries,
  f,
).whereType<StickerListItem>().map((i) => i.entry.sticker.code).toList();

void main() {
  test('sem filtro lista tudo, com cabeçalho por seção', () {
    final items = buildListItems(_sections, _entries, const StickerFilter());
    expect(items, hasLength(6));
    expect(items.first, isA<SectionHeaderItem>());
    final header = items.first as SectionHeaderItem;
    expect((header.owned, header.total), (1, 2));
  });

  test('filtra por situação', () {
    expect(_codes(const StickerFilter(status: StickerStatus.missing)), [
      'AA-01',
      'BB-02',
    ]);
    expect(_codes(const StickerFilter(status: StickerStatus.owned)), [
      'AA-02',
      'BB-01',
    ]);
    expect(_codes(const StickerFilter(status: StickerStatus.repeated)), [
      'BB-01',
    ]);
  });

  test('busca ignora caixa e hífen', () {
    expect(_codes(const StickerFilter(query: 'bb01')), ['BB-01']);
    expect(_codes(const StickerFilter(query: ' aa-0 ')), ['AA-01', 'AA-02']);
  });

  test('filtra por seção e combina filtros', () {
    expect(_codes(const StickerFilter(sectionId: 2)), ['BB-01', 'BB-02']);
    expect(
      _codes(const StickerFilter(sectionId: 2, status: StickerStatus.missing)),
      ['BB-02'],
    );
  });

  test('omite seções sem resultados e cabeçalho mostra totais sem filtro', () {
    final items = buildListItems(
      _sections,
      _entries,
      const StickerFilter(status: StickerStatus.repeated),
    );
    expect(items, hasLength(2));
    final header = items.first as SectionHeaderItem;
    expect(header.section.id, 2);
    expect((header.owned, header.total), (1, 2));
  });

  test('isActive reflete filtros aplicados', () {
    expect(const StickerFilter().isActive, isFalse);
    expect(const StickerFilter(query: '  ').isActive, isFalse);
    expect(const StickerFilter(sectionId: 1).isActive, isTrue);
  });
}
