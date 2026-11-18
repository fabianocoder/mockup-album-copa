import 'package:figurinhas_copa/app/app.dart';
import 'package:figurinhas_copa/features/album/domain/album_repository.dart';
import 'package:figurinhas_copa/features/album/presentation/album_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/test_album.dart';

void main() {
  late AlbumRepository repo;
  late AlbumProvider provider;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.runAsync(() async {
      repo = await createSqliteTestRepository();
      provider = AlbumProvider(repo);
      await provider.load();
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const App()),
    );
    await tester.tap(find.text('Álbum').last);
    await tester.pumpAndSettle();
  }

  /// Aguarda a gravação assíncrona (I/O real) terminar.
  Future<void> settleWrites(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('exibe as quatro abas', (tester) async {
    await pumpApp(tester);
    for (final label in ['Início', 'Álbum', 'Repetidas', 'Compartilhar']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('lista seções e figurinhas do álbum', (tester) async {
    await pumpApp(tester);
    // Um no chip de seção e outro no cabeçalho da lista.
    expect(find.text('Seção A'), findsNWidgets(2));
    expect(find.text('AA-01'), findsOneWidget);
    expect(find.text('BB-02'), findsOneWidget);
    expect(find.text('0/2'), findsNWidgets(2));
  });

  testWidgets('adicionar cópia atualiza a interface e persiste', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Adicionar uma cópia de AA-01'));
    await tester.tap(find.byTooltip('Adicionar uma cópia de AA-01'));
    await settleWrites(tester);

    expect(find.text('1 repetida'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    final entries = (await tester.runAsync(() => repo.getEntries('a1')))!;
    expect(entries.first.quantity, 2);
  });

  testWidgets('remover está desabilitado em zero', (tester) async {
    await pumpApp(tester);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_circle_outline).first,
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('filtro Faltam esconde figurinhas adquiridas', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Adicionar uma cópia de AA-01'));
    await settleWrites(tester);

    await tester.tap(find.text('Faltam'));
    await tester.pumpAndSettle();

    expect(find.text('AA-01'), findsNothing);
    expect(find.text('AA-02'), findsOneWidget);
  });

  testWidgets('busca por código e estado vazio com limpar filtros', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'bb02');
    await tester.pumpAndSettle();
    expect(find.text('BB-02'), findsOneWidget);
    expect(find.text('AA-01'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma figurinha encontrada com esses filtros.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('AA-01'), findsOneWidget);
  });

  testWidgets('informar quantidade diretamente pelo diálogo', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('quantity-AA-02')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '4');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await settleWrites(tester);

    expect(find.text('3 repetidas'), findsOneWidget);

    // A aba Repetidas reflete a mudança.
    await tester.tap(find.text('Repetidas').last);
    await tester.pumpAndSettle();
    expect(find.text('3 cópias para troca'), findsOneWidget);
  });
}
