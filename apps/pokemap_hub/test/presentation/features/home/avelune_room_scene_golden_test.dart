import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/design_system/assets/avelune_material_catalog.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  testWidgets('walnut and ivory room scene visual gate', (tester) async {
    tester.view.physicalSize = const Size(796, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
    await tester.runAsync(_primeGoldenFileImages);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
        ),
        home: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Roboto'),
          child: const RepaintBoundary(
            key: ValueKey<String>('avelune-room-golden-root'),
            child: ColoredBox(
              color: Colors.black,
              child: Row(
                children: <Widget>[
                  _Room(furnitureId: 'walnut'),
                  SizedBox(width: 16),
                  _Room(furnitureId: 'ivory'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(AveluneHomeScreen).first);
    await tester.runAsync(() async {
      await Future.wait<void>(<Future<void>>[
        precacheImage(
          const AssetImage('assets/avelune/room/backgrounds/amber.webp'),
          context,
        ),
        precacheImage(
          const AssetImage(
            'assets/avelune/room/furniture/credenza_walnut.webp',
          ),
          context,
        ),
        precacheImage(
          const AssetImage(
            'assets/avelune/room/furniture/credenza_ivory.webp',
          ),
          context,
        ),
        ...AveluneMaterialCatalog.consoleLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
        ...AveluneMaterialCatalog.cartridgeLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
      ]);
    });
    await tester.pumpAndSettle();
    _markSubtreeNeedsPaint(
      tester.renderObject(
        find.byKey(const ValueKey<String>('avelune-room-golden-root')),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AveluneHomeScreen), findsNWidgets(2));
    expect(find.byType(AveluneCartridge), findsNWidgets(8));
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-room-golden-root')),
      matchesGoldenFile(
        '../../../goldens/avelune/phase3_room_walnut_ivory_796x844.png',
      ),
    );
  });

  testWidgets('empty iPhone room keeps the physical composition',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());

    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
        ),
        home: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Roboto'),
          child: const RepaintBoundary(
            key: ValueKey<String>('avelune-empty-room-golden-root'),
            child: _Room(
              furnitureId: 'walnut',
              empty: true,
            ),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(AveluneHomeScreen));
    await tester.runAsync(() async {
      await Future.wait<void>(<Future<void>>[
        precacheImage(
          const AssetImage('assets/avelune/room/backgrounds/amber.webp'),
          context,
        ),
        ...AveluneMaterialCatalog.consoleLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
        ...AveluneMaterialCatalog.cartridgeLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
      ]);
    });
    await tester.pumpAndSettle();
    _markSubtreeNeedsPaint(
      tester.renderObject(
        find.byKey(
          const ValueKey<String>('avelune-empty-room-golden-root'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('avelune-room-hero-add-cartridge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
      findsNothing,
    );
    await expectLater(
      find.byKey(
        const ValueKey<String>('avelune-empty-room-golden-root'),
      ),
      matchesGoldenFile(
        '../../../goldens/avelune/empty_home_iphone_393x852.png',
      ),
    );
  });

  testWidgets('latched cartridge insertion visual gate', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
    await tester.runAsync(_primeGoldenFileImages);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
        ),
        home: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'Roboto'),
          child: RepaintBoundary(
            key: const ValueKey<String>('avelune-insertion-golden-root'),
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: AveluneHomeScreen(
                viewData: _viewData(),
                appearance: const AveluneAppearancePreferences(
                  backgroundId: 'amber',
                  furnitureId: 'walnut',
                ),
                onContinue: (_) {},
                onNewGame: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(AveluneHomeScreen));
    await tester.runAsync(() async {
      await Future.wait<void>(<Future<void>>[
        precacheImage(
          const AssetImage('assets/avelune/room/backgrounds/amber.webp'),
          context,
        ),
        precacheImage(
          const AssetImage(
            'assets/avelune/room/furniture/credenza_walnut.webp',
          ),
          context,
        ),
        ...AveluneMaterialCatalog.consoleLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
        ...AveluneMaterialCatalog.cartridgeLayers.map(
          (asset) => precacheImage(AssetImage(asset.path), context),
        ),
      ]);
    });
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );
    await tester.pump();
    await tester.pump();
    // Driven off the tokens: the sequence was re-paced so the console's LED
    // colours can be read, and fixed pumps stopped short of the latch, which
    // silently captured the resting pose instead.
    const motion = AveluneMotionTokens.standard;
    await tester.pump(motion.insertionAlign);
    await tester.pump();
    await tester.pump(motion.insertionDescend);
    await tester.pump();
    // Far enough into the latch for the connectors to disappear, but short of
    // the launch so the console still shows its latched colour.
    await tester.pump(motion.insertionLatch - const Duration(milliseconds: 1));
    _markSubtreeNeedsPaint(
      tester.renderObject(
        find.byKey(const ValueKey<String>('avelune-insertion-golden-root')),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Guard the moment being captured: this gate silently recorded the resting
    // pose once the pacing changed.
    expect(
      tester.widget<AveluneConsole>(find.byType(AveluneConsole)).state,
      AveluneConsoleState.latched,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-cartridge-insertion-overlay')),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-insertion-golden-root')),
      matchesGoldenFile(
        '../../../goldens/avelune/phase4_insertion_latched_390x844.png',
      ),
    );

    // Let the sequence finish: leaving it mid-flight trips the pending-timer
    // invariant when the tree is torn down.
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(motion.insertionLaunchDelay);
    await tester.pump();
  });
}

class _Room extends StatelessWidget {
  const _Room({required this.furnitureId, this.empty = false});

  final String furnitureId;
  final bool empty;

  @override
  Widget build(BuildContext context) => Localizations.override(
        context: context,
        locale: const Locale('fr'),
        child: SizedBox(
          width: 390,
          height: 844,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AveluneHomeScreen(
                  viewData: empty ? _emptyViewData() : _viewData(),
                  appearance: AveluneAppearancePreferences(
                    backgroundId: 'amber',
                    furnitureId: furnitureId,
                  ),
                  referenceTime: DateTime.utc(2026, 8, 4, 12),
                  onAddGame: () {},
                  onContinue: (_) {},
                  onNewGame: (_) {},
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AveluneBottomNavigation(
                    selectedItem: AveluneNavigationItem.home,
                    onItemSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

AveluneHomeViewData _emptyViewData() => AveluneHomeViewData(
      status: AveluneHomeStatus.empty,
      games: const <AveluneGameViewData>[],
      selectedGameId: null,
      recentActivity: const <AveluneRecentActivityViewData>[],
      import: const AveluneImportViewData.idle(canStart: true),
      safeErrorMessage: null,
      reducedMotion: true,
    );

AveluneHomeViewData _viewData() {
  final games = <AveluneGameViewData>[
    _game(
      'games.selbrume',
      'Selbrume',
      const Color(0xFF633C88),
      'test/fixtures/avelune/covers/selbrume.webp',
      true,
    ),
    _game(
      'games.train',
      'Le Train de 17h42',
      const Color(0xFF126E78),
      'test/fixtures/avelune/covers/train.webp',
      false,
    ),
    _game(
      'games.demo',
      'Démo technique',
      const Color(0xFF3B3B43),
      'test/fixtures/avelune/covers/demo.webp',
      false,
    ),
  ];
  return AveluneHomeViewData(
    status: AveluneHomeStatus.ready,
    games: games,
    selectedGameId: games.first.id,
    recentActivity: const <AveluneRecentActivityViewData>[],
    import: const AveluneImportViewData.idle(canStart: true),
    safeErrorMessage: null,
    // Standard motion: this gate exists to capture the real latched pose, and
    // under reduced motion the sequence collapses to a single frame.
    reducedMotion: false,
  );
}

AveluneGameViewData _game(
  String id,
  String title,
  Color shellColor,
  String artworkPath,
  bool selected,
) =>
    AveluneGameViewData(
      id: id,
      title: title,
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: AveluneArtworkViewData(
        kind: AveluneArtworkKind.cover,
        path: artworkPath,
      ),
      shellColor: shellColor,
      validity: AveluneGameValidity.available,
      primaryAction: selected
          ? AvelunePrimaryAction.continueGame
          : AvelunePrimaryAction.play,
      isSelected: selected,
      lastSaveAt: selected ? DateTime.utc(2026, 8, 4, 10) : null,
      playTimeSeconds: selected ? 3720 : 0,
    );

void _markSubtreeNeedsPaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_markSubtreeNeedsPaint);
}

Future<void> _primeGoldenFileImages() async {
  for (final path in <String>[
    'test/fixtures/avelune/covers/selbrume.webp',
    'test/fixtures/avelune/covers/train.webp',
    'test/fixtures/avelune/covers/demo.webp',
  ]) {
    final fileProvider = FileImage(File(path));
    final bytes = await File(path).readAsBytes();
    final providers = <(ImageProvider<Object>, int?, int?)>[
      (fileProvider, null, null),
      (
        ResizeImage.resizeIfNeeded(
          kAveluneCartridgeHeroArtworkCacheWidth,
          kAveluneCartridgeHeroArtworkCacheHeight,
          fileProvider,
        ),
        kAveluneCartridgeHeroArtworkCacheWidth,
        kAveluneCartridgeHeroArtworkCacheHeight,
      ),
      (
        ResizeImage.resizeIfNeeded(
          kAveluneCartridgeShelfArtworkCacheWidth,
          kAveluneCartridgeShelfArtworkCacheHeight,
          fileProvider,
        ),
        kAveluneCartridgeShelfArtworkCacheWidth,
        kAveluneCartridgeShelfArtworkCacheHeight,
      ),
    ];
    for (final (provider, width, height) in providers) {
      final cache = PaintingBinding.instance.imageCache;
      final key = await provider.obtainKey(ImageConfiguration.empty);
      if (cache.containsKey(key)) continue;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
        targetHeight: height,
      );
      final frame = await codec.getNextFrame();
      final cachedImage = frame.image.clone();
      frame.image.dispose();
      codec.dispose();
      cache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(
          Future<ImageInfo>.value(ImageInfo(image: cachedImage)),
        ),
      );
    }
  }
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final textLoader = FontLoader('Roboto')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  final editorialLoader = FontLoader('AveluneEditorial')
    ..addFont(
      rootBundle.load(
        'assets/avelune/fonts/CormorantGaramond-Variable.ttf',
      ),
    );
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  final cupertinoLoader = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(
      rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    );
  await Future.wait(<Future<void>>[
    textLoader.load(),
    editorialLoader.load(),
    iconLoader.load(),
    cupertinoLoader.load(),
  ]);
}
