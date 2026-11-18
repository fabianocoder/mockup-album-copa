import 'package:figurinhas_copa/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPercent usa vírgula e omite casa decimal zero', () {
    expect(formatPercent(0), '0%');
    expect(formatPercent(100), '100%');
    expect(formatPercent(12.5), '12,5%');
    expect(formatPercent(33.333333), '33,3%');
    expect(formatPercent(99.96), '100%');
  });
}
