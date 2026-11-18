/// Catálogo JSON malformado ou inconsistente. Carrega todos os problemas
/// encontrados, para que o autor do catálogo corrija tudo de uma vez.
class CatalogFormatException implements Exception {
  const CatalogFormatException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'CatalogFormatException: ${problems.join('; ')}';
}
