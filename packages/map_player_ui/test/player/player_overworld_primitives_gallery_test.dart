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
        throw StateError('Flutter cache absent');
      }
      cache = cache.parent;
    }
    final icons = await File(
            '${cache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytes();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(icons))))
        .load();
  });

  const captures = [
    (
      name: 'idle_landscape',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.idle)
    ),
    (
      name: 'interaction_dark',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(actionLabel: 'Parler')
    ),
    (
      name: 'interaction_light',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          actionLabel: 'Lire', backdrop: PlayerOverworldGalleryBackdrop.light)
    ),
    (
      name: 'interaction_busy',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          actionLabel: 'Ramasser',
          backdrop: PlayerOverworldGalleryBackdrop.busy)
    ),
    (
      name: 'movement',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.movement,
          backdrop: PlayerOverworldGalleryBackdrop.busy)
    ),
    (
      name: 'running',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.running,
          backdrop: PlayerOverworldGalleryBackdrop.busy)
    ),
    (
      name: 'controller',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.hardware,
          actionLabel: 'Interagir',
          glyph: '×')
    ),
    (
      name: 'keyboard',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.hardware,
          actionLabel: 'Interagir',
          glyph: 'Z')
    ),
    (
      name: 'unknown_controller_portrait',
      size: Size(390, 844),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.hardware,
          actionLabel: 'Lire le panneau de la gare',
          glyph: 'Bouton ouest',
          textScale: 2),
    ),
    (
      name: 'unknown_controller_landscape_text2',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.hardware,
          actionLabel:
              'Examiner attentivement cette mystérieuse inscription',
          glyph: 'Bouton ouest',
          textScale: 2),
    ),
    (
      name: 'pressed',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.pressed, actionLabel: 'Entrer')
    ),
    (
      name: 'focus',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.focused, actionLabel: 'Interagir')
    ),
    (
      name: 'disabled',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          state: PlayerOverworldGalleryState.disabled, actionLabel: 'Interagir')
    ),
    (
      name: 'portrait_text2',
      size: Size(390, 844),
      scene: PlayerOverworldPrimitivesGallery(
          actionLabel: 'Lire le panneau de la gare', textScale: 2)
    ),
    (
      name: 'landscape_text2_opaque',
      size: Size(844, 390),
      scene: PlayerOverworldPrimitivesGallery(
          actionLabel: 'Lire le panneau de la gare',
          textScale: 2,
          opaque: true,
          reducedMotion: true,
          backdrop: PlayerOverworldGalleryBackdrop.light)
    ),
    (
      name: 'contrast',
      size: Size(390, 844),
      scene: PlayerOverworldPrimitivesGallery(
          highContrast: true,
          opaque: true,
          reducedMotion: true,
          backdrop: PlayerOverworldGalleryBackdrop.busy)
    ),
  ];

  for (final capture in captures) {
    testWidgets('overworld primitives capture ${capture.name}', (tester) async {
      await _pump(tester, capture.size, capture.scene);
      expect(tester.takeException(), isNull);
      await expectLater(
          find.byKey(const ValueKey('overworld-capture')),
          matchesGoldenFile(
              'goldens/overworld_primitives/${capture.name}.png'));
    });
  }

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('gallery preserves safe targets with long text at $size',
        (tester) async {
      final calls = <String>[];
      await _pump(
          tester,
          size,
          PlayerOverworldPrimitivesGallery(
            actionLabel: 'Lire le panneau de la gare',
            textScale: 2,
            onInvoked: calls.add,
          ));
      final menu = find.byKey(const ValueKey('overworld-gallery-menu'));
      final action = find.byKey(const ValueKey('overworld-gallery-action'));
      final menuRect = tester.getRect(menu);
      final actionRect = tester.getRect(action);
      expect(menuRect.bottom, lessThanOrEqualTo(size.height - 34));
      expect(actionRect.top, greaterThanOrEqualTo(44));
      expect(actionRect.overlaps(menuRect), isFalse);
      expect(actionRect.height, greaterThanOrEqualTo(48));
      expect(find.text('Lire le panneau de la gare'), findsOneWidget);
      await tester.tap(action);
      await tester.tap(menu);
      expect(calls, ['interaction', 'menu']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('idle gallery has Menu only and hidden gallery has no controls',
      (tester) async {
    await _pump(
        tester,
        const Size(844, 390),
        const PlayerOverworldPrimitivesGallery(
            state: PlayerOverworldGalleryState.idle));
    expect(find.byType(PlayerOverworldJoystickVisual), findsNothing);
    expect(find.text('Interagir'), findsNothing);
    expect(find.byKey(const ValueKey('overworld-gallery-menu')).hitTestable(),
        findsOneWidget);
    await _pump(
        tester,
        const Size(844, 390),
        const PlayerOverworldPrimitivesGallery(
            state: PlayerOverworldGalleryState.hidden));
    expect(find.byKey(const ValueKey('overworld-gallery-menu')).hitTestable(),
        findsNothing);
    expect(find.byKey(const ValueKey('overworld-gallery-action')).hitTestable(),
        findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, Size size, Widget scene) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RepaintBoundary(
      key: const ValueKey('overworld-capture'),
      child: MediaQuery(
        data: MediaQueryData(
            size: size, padding: const EdgeInsets.fromLTRB(24, 44, 24, 34)),
        child: scene,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 400));
}
