@Tags(['visual'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  testWidgets('canonical Avelune cartridge material visual gate',
      (tester) async {
    tester.view.physicalSize = const Size(900, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        ),
        home: const RepaintBoundary(
          key: ValueKey<String>('avelune-cartridge-gate'),
          child: _CartridgeGate(),
        ),
      ),
    );
    final context = tester.element(find.byType(_CartridgeGate));
    await tester.runAsync(
      () {
        final artwork = AssetImage(AveluneMaterialCatalog.fallbackArtwork.path);
        return Future.wait<void>(<Future<void>>[
          ...AveluneMaterialCatalog.cartridgeLayers.map(
            (asset) => precacheImage(AssetImage(asset.path), context),
          ),
          precacheImage(
            ResizeImage.resizeIfNeeded(
              kAveluneCartridgeHeroArtworkCacheWidth,
              kAveluneCartridgeHeroArtworkCacheHeight,
              artwork,
            ),
            context,
          ),
          precacheImage(
            ResizeImage.resizeIfNeeded(
              kAveluneCartridgeShelfArtworkCacheWidth,
              kAveluneCartridgeShelfArtworkCacheHeight,
              artwork,
            ),
            context,
          ),
        ]);
      },
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AveluneCartridge), findsNWidgets(8));
    for (final element in find.byType(AveluneCartridge).evaluate()) {
      final finder = find.byElementPredicate((value) => value == element);
      final size = tester.getSize(finder);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    }
    for (final renderImage in tester.renderObjectList<RenderImage>(
      find.byKey(const ValueKey<String>('avelune-cartridge-artwork')),
    )) {
      expect(renderImage.image, isNotNull);
    }
    _markSubtreeNeedsPaint(
      tester.renderObject(
        find.byKey(const ValueKey<String>('avelune-cartridge-gate')),
      ),
    );
    await tester.pump();

    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.hero-hero',
      path: 'phase3_cartridge_hero_violet_168x240.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.violet-shelf',
      path: 'phase3_cartridge_shelf_violet_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.teal-shelf',
      path: 'phase3_cartridge_shelf_teal_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.graphite-shelf',
      path: 'phase3_cartridge_shelf_graphite_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.fallback-shelf',
      path: 'phase3_cartridge_shelf_fallback_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.long-shelf',
      path: 'phase3_cartridge_shelf_long_title_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-games.gate.invalid-shelf',
      path: 'phase3_cartridge_shelf_invalid_110x157.png',
    );
    await _expectCartridgeGolden(
      key: 'avelune-cartridge-boundary-avelune.add-game-shelf',
      path: 'phase3_cartridge_shelf_add_game_110x157.png',
    );
  });
}

Future<void> _expectCartridgeGolden({
  required String key,
  required String path,
}) =>
    expectLater(
      find.byKey(ValueKey<String>(key)),
      matchesGoldenFile('../../../goldens/avelune/$path'),
    );

void _markSubtreeNeedsPaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_markSubtreeNeedsPaint);
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final textLoader = FontLoader('AveluneGoldenSans')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait(<Future<void>>[textLoader.load(), iconLoader.load()]);
}

class _CartridgeGate extends StatelessWidget {
  const _CartridgeGate();

  static const artwork = AssetImage(
    'assets/avelune/artwork/fallback_moonlit_path.webp',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: context.aveluneColors.canvas,
        child: Padding(
          padding: const EdgeInsets.all(AveluneSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'CANONICAL CARTRIDGE MATERIAL',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AveluneSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const SizedBox(
                    width: 168,
                    child: AveluneCartridge(
                      key: ValueKey<String>('gate-hero'),
                      gameId: 'games.gate.hero',
                      title: 'Selbrume',
                      subtitle: 'Les brumes de Selbrume',
                      artwork: artwork,
                      shellColor: Color(0xFF633C88),
                      selected: true,
                      displaySize: AveluneCartridgeDisplaySize.hero,
                    ),
                  ),
                  const SizedBox(width: AveluneSpacing.xl),
                  const _ShelfCartridge(
                    gameId: 'games.gate.violet',
                    title: 'Selbrume',
                    shellColor: Color(0xFF633C88),
                  ),
                  const SizedBox(width: AveluneSpacing.lg),
                  const _ShelfCartridge(
                    gameId: 'games.gate.teal',
                    title: 'Le Train de 17h42',
                    shellColor: Color(0xFF126E78),
                  ),
                  const SizedBox(width: AveluneSpacing.lg),
                  const _ShelfCartridge(
                    gameId: 'games.gate.graphite',
                    title: 'Démo technique',
                    shellColor: Color(0xFF3B3B43),
                  ),
                ],
              ),
              const SizedBox(height: AveluneSpacing.xl),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ShelfCartridge(
                    gameId: 'games.gate.fallback',
                    title: 'Sans illustration',
                    artwork: null,
                  ),
                  SizedBox(width: AveluneSpacing.lg),
                  _ShelfCartridge(
                    gameId: 'games.gate.long',
                    title: 'Une aventure au nom excessivement long',
                  ),
                  SizedBox(width: AveluneSpacing.lg),
                  _ShelfCartridge(
                    gameId: 'games.gate.invalid',
                    title: 'Jeu indisponible',
                    invalid: true,
                  ),
                  SizedBox(width: AveluneSpacing.lg),
                  SizedBox(
                    width: 110,
                    child: AveluneCartridge.addGame(
                      displaySize: AveluneCartridgeDisplaySize.shelf,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfCartridge extends StatelessWidget {
  const _ShelfCartridge({
    required this.gameId,
    required this.title,
    this.artwork = _CartridgeGate.artwork,
    this.shellColor,
    this.invalid = false,
  });

  final String gameId;
  final String title;
  final ImageProvider<Object>? artwork;
  final Color? shellColor;
  final bool invalid;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        child: AveluneCartridge(
          gameId: gameId,
          title: title,
          artwork: artwork,
          shellColor: shellColor,
          invalid: invalid,
          displaySize: AveluneCartridgeDisplaySize.shelf,
        ),
      );
}
