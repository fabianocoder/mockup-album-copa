/// Formata percentual em pt-BR: `0%`, `12,5%`, `100%` (no máximo 1 casa).
String formatPercent(double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.truncateToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1).replaceAll('.', ',');
  return '$text%';
}
