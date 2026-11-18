import 'package:figurinhas_copa/app/app.dart';
import 'package:figurinhas_copa/features/album/domain/album.dart';
import 'package:figurinhas_copa/features/album/presentation/album_provider.dart';
import 'package:figurinhas_copa/features/sharing/domain/missing_list_codec.dart';
import 'package:figurinhas_copa/features/sharing/presentation/text_sharer.dart';
import 'package:figurinhas_copa/features/sharing/presentation/trade_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../support/in_memory_album_repository.dart';
import '../../support/test_album.dart';

class FakeSharer implements TextSharer {
  final shared = <String>[];
  bool fail = false;

  @override
  Future<void> share(String text, {String? subject}) async {
    if (fail) throw StateError('sem app de compartilhamento');
    shared.add(text);
  }
}

void main() {
  late InMemoryAlbumRepository repo;
  late AlbumProvider provider;
  late FakeSharer sharer;

  /// Catálogo de teste: AA-01, AA-02, BB-01, BB-02.
  /// Eu tenho AA-01 x3 (2 repetidas) e BB-02 x1.
  Future<void> setUpData() async {
    repo = InMemoryAlbumRepository();
    await repo.importCatalog(testCatalog);
    provider = AlbumProvider(repo);
    await provider.load();
    await provider.setQuantity(provider.entries[0].sticker.id, 3);
    await provider.setQuantity(provider.entries[3].sticker.id, 1);
    sharer = FakeSharer();
  }

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      Provider<TextSharer>.value(value: sharer),
    ],
    child: child,
  );

  Future<void> openShareTab(WidgetTester tester) async {
    await setUpData();
    await tester.pumpWidget(wrap(const App()));
    await tester.tap(find.text('Compartilhar').last);
    await tester.pumpAndSettle();
  }

  /// QR de outra pessoa: mesmo catálogo, com as quantidades indicadas.
  String otherPersonQr(List<int> quantities, {Album? album}) {
    final entries = [
      for (var i = 0; i < provider.entries.length; i++)
        provider.entries[i].withQuantity(quantities[i]),
    ];
    return MissingListCodec.encode(album ?? provider.album!, entries);
  }

  Future<void> pumpTrade(WidgetTester tester, String raw) async {
    await setUpData();
    await tester.pumpWidget(
      wrap(MaterialApp(home: TradeResultPage(rawContent: raw))),
    );
  }

  group('texto', () {
    testWidgets('compartilha a lista de faltantes pelo menu nativo', (
      tester,
    ) async {
      await openShareTab(tester);
      await tester.tap(find.text('Compartilhar faltantes'));
      await tester.pumpAndSettle();

      expect(sharer.shared.single, contains('AA-02, BB-01'));
      expect(sharer.shared.single, contains('Total: 2 figurinhas faltantes.'));
    });

    testWidgets('compartilha repetidas com quantidades', (tester) async {
      await openShareTab(tester);
      await tester.tap(find.text('Compartilhar repetidas'));
      await tester.pumpAndSettle();

      expect(sharer.shared.single, contains('AA-01 — 2 cópias disponíveis'));
    });

    testWidgets('avisa quando o compartilhamento falha', (tester) async {
      await openShareTab(tester);
      sharer.fail = true;
      await tester.tap(find.text('Compartilhar faltantes'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível compartilhar.'), findsOneWidget);
    });
  });

  group('QR Code', () {
    testWidgets('mostra o QR com o conteúdo codificado das faltantes', (
      tester,
    ) async {
      await openShareTab(tester);
      await tester.tap(find.text('Mostrar meu QR Code'));
      await tester.pumpAndSettle();

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      final payload = MissingListCodec.encode(
        provider.album!,
        provider.entries,
      );
      expect(qr.key, ValueKey(payload));
      final decoded = MissingListCodec.decode(payload);
      expect(decoded.missingCount, 2);
      expect(find.text('2 figurinhas faltantes'), findsOneWidget);
    });

    testWidgets('álbum completo não gera QR', (tester) async {
      await openShareTab(tester);
      for (final e in provider.entries) {
        await provider.setQuantity(e.sticker.id, 1);
      }
      await tester.tap(find.text('Mostrar meu QR Code'));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsNothing);
      expect(find.textContaining('Álbum completo'), findsOneWidget);
    });
  });

  group('resultado da troca', () {
    testWidgets('lista o que posso oferecer e as faltantes dela', (
      tester,
    ) async {
      // Ela tem BB-01 e BB-02; precisa de AA-01 e AA-02.
      await pumpTrade(tester, '');
      final raw = otherPersonQr([0, 0, 1, 1]);
      await tester.pumpWidget(
        wrap(MaterialApp(home: TradeResultPage(rawContent: raw))),
      );

      expect(find.text('1'), findsOneWidget); // só AA-01 é meu repetido
      expect(find.text('AA-01'), findsNWidgets(2)); // oferta + chip
      expect(find.text('2 cópias disponíveis'), findsOneWidget);
      expect(find.text('AA-02'), findsOneWidget); // só no chip
      expect(
        find.textContaining('Sua coleção não foi alterada'),
        findsOneWidget,
      );
    });

    testWidgets('não altera quantidades nem o banco', (tester) async {
      await pumpTrade(tester, '');
      final raw = otherPersonQr([0, 0, 0, 0]);
      final stored = await repo.getEntries('a1');
      await tester.pumpWidget(
        wrap(MaterialApp(home: TradeResultPage(rawContent: raw))),
      );

      expect(provider.entries.map((e) => e.quantity), [3, 0, 0, 1]);
      expect(
        (await repo.getEntries('a1')).map((e) => e.quantity),
        stored.map((e) => e.quantity),
      );
    });

    testWidgets('QR de outro tipo é rejeitado', (tester) async {
      await pumpTrade(tester, 'https://exemplo.com');
      expect(find.text('Este QR Code não é de figurinhas.'), findsOneWidget);
    });

    testWidgets('QR corrompido é rejeitado', (tester) async {
      await pumpTrade(tester, '');
      final good = otherPersonQr([0, 0, 0, 0]);
      final bad = good.replaceFirst('|4|', '|5|');
      await tester.pumpWidget(
        wrap(MaterialApp(home: TradeResultPage(rawContent: bad))),
      );
      expect(find.textContaining('corrompido'), findsOneWidget);
    });

    testWidgets('catálogo de outra versão é incompatível', (tester) async {
      await pumpTrade(tester, '');
      const newer = Album(
        id: 'a1',
        name: 'Álbum teste',
        catalogVersion: 9,
        isDemo: true,
      );
      final raw = otherPersonQr([0, 0, 0, 0], album: newer);
      await tester.pumpWidget(
        wrap(MaterialApp(home: TradeResultPage(rawContent: raw))),
      );
      expect(find.textContaining('outra versão'), findsOneWidget);
    });

    testWidgets('álbum diferente é incompatível', (tester) async {
      await pumpTrade(tester, '');
      const other = Album(
        id: 'outro',
        name: 'Outro',
        catalogVersion: 1,
        isDemo: false,
      );
      final raw = otherPersonQr([0, 0, 0, 0], album: other);
      await tester.pumpWidget(
        wrap(MaterialApp(home: TradeResultPage(rawContent: raw))),
      );
      expect(find.text('Este QR Code é de outro álbum.'), findsOneWidget);
    });
  });
}
