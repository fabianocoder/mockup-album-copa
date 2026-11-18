class Album {
  const Album({
    required this.id,
    required this.name,
    required this.catalogVersion,
    required this.isDemo,
  });

  final String id;
  final String name;
  final int catalogVersion;
  final bool isDemo;
}

class Section {
  const Section({
    required this.id,
    required this.key,
    required this.name,
    required this.sortIndex,
  });

  final int id;

  /// Chave estável definida pelo catálogo (ex.: prefixo dos códigos).
  final String key;
  final String name;
  final int sortIndex;
}

class Sticker {
  const Sticker({
    required this.id,
    required this.code,
    required this.sectionId,
    required this.sortIndex,
  });

  final int id;
  final String code;
  final int sectionId;
  final int sortIndex;
}

/// Figurinha + quantidade possuída. Faltante/repetida são sempre derivadas
/// da quantidade; nada disso é persistido.
class StickerEntry {
  const StickerEntry({required this.sticker, required this.quantity})
    : assert(quantity >= 0);

  /// Limite superior aceito para a quantidade de cópias de uma figurinha.
  static const maxQuantity = 99;

  final Sticker sticker;
  final int quantity;

  bool get isOwned => quantity > 0;
  bool get isMissing => quantity == 0;

  /// Cópias além da primeira, disponíveis para troca.
  int get spares => quantity > 1 ? quantity - 1 : 0;
  bool get hasSpares => spares > 0;

  StickerEntry withQuantity(int quantity) =>
      StickerEntry(sticker: sticker, quantity: quantity);
}
