import 'album.dart';
import 'catalog.dart';

/// Contrato de persistência de álbuns e inventário.
///
/// O restante do app depende apenas desta interface; trocar de banco (ou
/// acrescentar sincronização) significa escrever outra implementação.
abstract interface class AlbumRepository {
  /// Importa o catálogo de forma atômica.
  ///
  /// - Álbum novo: cria tudo.
  /// - Versão maior que a armazenada: atualiza preservando o inventário das
  ///   figurinhas que continuam existindo; removidas saem (com seu inventário).
  /// - Mesma versão ou menor: não faz nada.
  Future<void> importCatalog(CatalogData catalog);

  Future<List<Album>> getAlbums();

  /// Seções do álbum, em ordem do catálogo.
  Future<List<Section>> getSections(String albumId);

  /// Todas as figurinhas do álbum, em ordem do catálogo, com quantidade
  /// (0 quando não possuída).
  Future<List<StickerEntry>> getEntries(String albumId);

  /// Define a quantidade e persiste na hora. Lança [RangeError] fora de
  /// 0..[StickerEntry.maxQuantity] e falha se a figurinha não existir.
  Future<void> setQuantity(int stickerId, int quantity);
}
