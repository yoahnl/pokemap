import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/personalization_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (!cache.path.endsWith('${Platform.pathSeparator}cache')) {
      if (cache.parent.path == cache.path) {
        throw StateError('Flutter font cache not found');
      }
      cache = cache.parent;
    }
    final bytes = await File(
      '${cache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  });

  const sizes = [
    Size(390, 844),
    Size(844, 390),
    Size(800, 600),
    Size(1280, 720),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  for (final size in sizes) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('keeps Return reachable at $size and text $scale',
          (tester) async {
        await _pump(
            tester, size, PlayerMenuPrimitivesGallery(textScale: scale));
        expect(tester.takeException(), isNull);
        final titleBounds = tester.getRect(
          find.text('Tous les menus et les états de votre aventure'),
        );
        final bodyBounds = tester.getRect(find.text('Choisir, puis agir'));
        expect(titleBounds.bottom, lessThanOrEqualTo(bodyBounds.top));
        final back = _row('gallery-return');
        expect(back, findsOneWidget);
        final bounds = tester.getRect(back);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
        expect(bounds.height, greaterThanOrEqualTo(48));
        expect(back.hitTestable(), findsOneWidget);
        await tester.tap(back);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('frame respects safe insets with large text', (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const PlayerMenuPrimitivesGallery(textScale: 2),
      insets: const EdgeInsets.only(top: 44, bottom: 34),
    );
    expect(tester.takeException(), isNull);
    final back = tester.getRect(_row('gallery-return'));
    expect(back.bottom, lessThanOrEqualTo(810));
    final title = tester.getRect(
      find.text('Tous les menus et les états de votre aventure'),
    );
    expect(title.top, greaterThanOrEqualTo(44));
    expect(title.bottom,
        lessThanOrEqualTo(tester.getRect(find.text('Choisir, puis agir')).top));
    expect(_row('gallery-return').hitTestable(), findsOneWidget);
  });

  testWidgets('gallery selection is local and unavailable actions do nothing',
      (tester) async {
    await _pump(tester, const Size(1440, 900),
        const PlayerMenuPrimitivesGallery(reducedMotion: true));
    await tester.tap(_row('gallery-normal'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.widget<PlayerMenuSelectableRow>(_row('gallery-normal')).selected,
        isTrue);
    await tester.ensureVisible(_row('gallery-disabled'));
    await tester.tap(_row('gallery-disabled'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.widget<PlayerMenuSelectableRow>(_row('gallery-normal')).selected,
        isTrue);
    expect(find.text('Une cible compatible est nécessaire.'), findsOneWidget);
    await tester.ensureVisible(_row('gallery-busy'));
    await tester.tap(_row('gallery-busy'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester.widget<PlayerMenuSelectableRow>(_row('gallery-normal')).selected,
        isTrue);
    await tester.tap(_row('gallery-return'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(_row('gallery-selected'))
            .selected,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  const captures = [
    (
      name: 'night_1440x900',
      size: Size(1440, 900),
      scene: PlayerMenuPrimitivesGallery(),
    ),
    (
      name: 'opaque_light_1440x900',
      size: Size(1440, 900),
      scene: PlayerMenuPrimitivesGallery(
        opaque: true,
        backdrop: PlayerMenuGalleryBackdrop.light,
      ),
    ),
    (
      name: 'contrast_1440x900',
      size: Size(1440, 900),
      scene: PlayerMenuPrimitivesGallery(
        highContrast: true,
        backdrop: PlayerMenuGalleryBackdrop.contrast,
      ),
    ),
    (
      name: 'landscape_844x390',
      size: Size(844, 390),
      scene: PlayerMenuPrimitivesGallery(reducedMotion: true),
    ),
    (
      name: 'portrait_text2_390x844',
      size: Size(390, 844),
      scene: PlayerMenuPrimitivesGallery(textScale: 2, reducedMotion: true),
    ),
    (
      name: 'compact_text15_800x600',
      size: Size(800, 600),
      scene: PlayerMenuPrimitivesGallery(textScale: 1.5),
    ),
  ];

  for (final capture in captures) {
    testWidgets('renders menu primitives ${capture.name}', (tester) async {
      await _pump(tester, capture.size, capture.scene);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('menu-gallery-capture')),
        matchesGoldenFile('goldens/menu_primitives/${capture.name}.png'),
      );
    });
  }

  testWidgets('renders every feedback state after scrolling', (tester) async {
    await _pump(tester, const Size(1440, 900),
        const PlayerMenuPrimitivesGallery(reducedMotion: true));
    await tester.ensureVisible(find.text('Aperçu sans sauvegarde'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Aucun élément').hitTestable(), findsOneWidget);
    expect(find.text('Ressource indisponible').hitTestable(), findsOneWidget);
    expect(find.text('Aperçu sans sauvegarde').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('menu-gallery-capture')),
      matchesGoldenFile('goldens/menu_primitives/feedback_1440x900.png'),
    );
  });
}

Finder _row(String id) => find.byWidgetPredicate(
      (widget) => widget is PlayerMenuSelectableRow && widget.id == id,
    );

Future<void> _pump(
  WidgetTester tester,
  Size size,
  PlayerMenuPrimitivesGallery scene, {
  EdgeInsets insets = EdgeInsets.zero,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RepaintBoundary(
      key: const ValueKey('menu-gallery-capture'),
      child: MediaQuery(
        data: MediaQueryData(size: size, padding: insets),
        child: scene,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 400));
}
