# Figurinhas Copa

Projeto modelo feito em Flutter para registrar as figurinhas já existentes.

Gerenciador offline de álbuns de figurinhas (MVP focado na Copa do Mundo 2026).
Flutter + Provider + SQLite. O catálogo incluído tem as 48 seleções reais da Copa 2026, mas a **numeração das figurinhas é ilustrativa** (não é a oficial da Panini).

## Executar
```bash
flutter pub get
flutter run
```

## Qualidade
```bash
dart format .
flutter analyze
flutter test
```

## Status
- [x] Etapa 1 — Fundação (tema M3 claro/escuro, navegação com 4 abas)
- [x] Etapa 2 — Modelo e persistência (SQLite, importador de catálogo JSON, catálogo demo fictício)
- [x] Etapa 3 — Gerenciamento de figurinhas (lista por seção, busca, filtros, quantidades, aba Repetidas)
- [x] Etapa 4 — Dashboard (indicadores, percentual e barra de progresso)
- [x] Etapa 5 — Compartilhamento (texto, QR Code, leitura e comparação de troca)
- [ ] Etapa 6 — Validação e builds

## Catálogo
Álbuns vêm de JSON em `assets/catalogs/` (ver `CatalogParser` em
`lib/features/album/domain/catalog.dart`). O catálogo incluído (v2) usa as 48 seleções (código FIFA de 3 letras, 20 figurinhas cada) + 8 especiais, com numeração **não oficial**.
Reimportar com `catalogVersion` maior atualiza o álbum preservando o inventário.

## Compartilhamento
- **Texto:** faltantes e repetidas via menu nativo (`share_plus`).
- **QR Code (offline):** `FIG1|<albumId>|<catalogVersion>|<total>|<bitmap base64url>|<crc32>`.
  Um bit por figurinha (ordem do catálogo; 1 = faltante) e CRC-32 de integridade.
  ~190 caracteres para 1000 figurinhas. Acima de 1800 caracteres a interface
  sugere o compartilhamento por texto.
- **Leitura:** só compara com as repetidas locais; **nunca altera** a coleção.
  QR de outro álbum/versão de catálogo ou corrompido é rejeitado com mensagem.
- **Câmera:** pedida apenas ao abrir "Ler QR Code". Android: permissão `CAMERA`
  vem do plugin; iOS: `NSCameraUsageDescription` em `ios/Runner/Info.plist`.
