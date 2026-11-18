import 'package:figurinhas_copa/app/app.dart';
import 'package:figurinhas_copa/features/album/presentation/album_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/in_memory_album_repository.dart';
import '../../support/test_album.dart';

void main() {
  late InMemoryAlbumRepository repo;
  late AlbumProvider provider;

  Future<SemanticsHandle> pumpApp(WidgetTester tester) async {
    // Habilita a árvore de semântica para os finders de acessibilidade.
    final semantics = tester.ensureSemantics();
    repo = InMemoryAlbumRepository();
    await repo.importCatalog(testCatalog);
    provider = AlbumProvider(repo);
    await provider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const App()),
    );
    return semantics;
  }

  Future<int> idOf(String code) async =>
      (await repo.getEntries('a1'))
          .firstWhere((e) => e.sticker.code == code)
          .sticker
          .id;

  testWidgets('mostra indicadores iniciais com álbum zerado', (tester) async {
    final semantics = await pumpApp(tester);

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 de 4 figurinhas'), findsOneWidget);
    expect(find.bySemanticsLabel('Total do álbum: 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Faltantes: 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Repetidas p/ troca: 0'), findsOneWidget);
    expect(find.textContaining('não oficial'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0);
    semantics.dispose();
  });

  testWidgets('atualiza automaticamente após mudanças de quantidade', (
    tester,
  ) async {
    final semantics = await pumpApp(tester);

    final a = await idOf('AA-01');
    await provider.setQuantity(a, 3);
    await provider.setQuantity(await idOf('BB-02'), 1);
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2 de 4 figurinhas'), findsOneWidget);
    expect(find.bySemanticsLabel('Adquiridas: 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Faltantes: 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Repetidas p/ troca: 2'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.5);
    semantics.dispose();
  });

  testWidgets('repetidas não aumentam o percentual de conclusão', (
    tester,
  ) async {
    final semantics = await pumpApp(tester);
    await provider.setQuantity(await idOf('AA-01'), 10);
    await tester.pump();
    expect(find.text('25%'), findsOneWidget);
    expect(find.bySemanticsLabel('Repetidas p/ troca: 9'), findsOneWidget);
    semantics.dispose();
  });
}
