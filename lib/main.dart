import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_location.dart';
import 'features/album/data/sqlite_album_repository.dart';
import 'features/album/domain/album_repository.dart';
import 'features/album/domain/catalog.dart';
import 'features/album/presentation/album_provider.dart';
import 'features/sharing/presentation/text_sharer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open(await prepareDatabasePath('figurinhas.db'));
  final AlbumRepository repository = SqliteAlbumRepository(db);
  // Catálogo ilustrativo (numeração não oficial). Idempotente: só atualiza se
  // a versão do asset for maior que a armazenada.
  final catalog = CatalogParser.parse(
    await rootBundle.loadString('assets/catalogs/demo_copa_2026.json'),
  );
  await repository.importCatalog(catalog);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AlbumProvider(repository)..load(),
        ),
        Provider<TextSharer>.value(value: const SharePlusTextSharer()),
      ],
      child: const App(),
    ),
  );
}
