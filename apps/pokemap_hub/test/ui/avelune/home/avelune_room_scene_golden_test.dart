import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/appearance/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/src/ui/avelune/assets/avelune_material_catalog.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_cartridge.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_theme.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_screen.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_view_data.dart';

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
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        ),
        home: const RepaintBoundary(
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
    expect(find.byType(AveluneCartridge), findsNWidgets(10));
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-room-golden-root')),
      matchesGoldenFile(
        '../../goldens/avelune/phase3_room_walnut_ivory_796x844.png',
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
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        ),
        home: RepaintBoundary(
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
              onNewGame: (_) {},
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
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    _markSubtreeNeedsPaint(
      tester.renderObject(
        find.byKey(const ValueKey<String>('avelune-insertion-golden-root')),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-insertion-golden-root')),
      matchesGoldenFile(
        '../../goldens/avelune/phase4_insertion_latched_390x844.png',
      ),
    );
  });
}

class _Room extends StatelessWidget {
  const _Room({required this.furnitureId});

  final String furnitureId;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 390,
        height: 844,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: AveluneHomeScreen(
            viewData: _viewData(),
            appearance: AveluneAppearancePreferences(
              backgroundId: 'amber',
              furnitureId: furnitureId,
            ),
          ),
        ),
      );
}

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
    reducedMotion: true,
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
      primaryAction: AvelunePrimaryAction.play,
      isSelected: selected,
      lastSaveAt: null,
      playTimeSeconds: 0,
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
  final textLoader = FontLoader('AveluneGoldenSans')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait(<Future<void>>[textLoader.load(), iconLoader.load()]);
}
