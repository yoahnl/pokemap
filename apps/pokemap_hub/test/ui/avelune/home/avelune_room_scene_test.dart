import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/design_system/assets/avelune_material_catalog.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_console.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_room_scene.dart';
import 'package:pokemap_hub/presentation/shared/artwork/appearance_asset_path.dart';

void main() {
  testWidgets('background and furniture finish remain independent',
      (tester) async {
    await _pumpHome(
      tester,
      appearance: const AveluneAppearancePreferences(
        backgroundId: 'amber',
        furnitureId: 'walnut',
      ),
    );
    final amberPath = _assetPath(tester, 'avelune-room-background-layer');
    final walnutPath = _assetPath(tester, 'avelune-room-furniture-layer');
    final walnutRect = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-furniture-layer')),
    );

    await _pumpHome(
      tester,
      appearance: const AveluneAppearancePreferences(
        backgroundId: 'linen',
        furnitureId: 'ivory',
      ),
    );
    final linenPath = _assetPath(tester, 'avelune-room-background-layer');
    final ivoryPath = _assetPath(tester, 'avelune-room-furniture-layer');
    final ivoryRect = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-furniture-layer')),
    );

    expect(amberPath, AveluneMaterialCatalog.background('amber').path);
    expect(linenPath, AveluneMaterialCatalog.background('linen').path);
    expect(walnutPath, AveluneMaterialCatalog.furnitureFinish('walnut').path);
    expect(ivoryPath, AveluneMaterialCatalog.furnitureFinish('ivory').path);
    expect(amberPath, isNot(linenPath));
    expect(walnutPath, isNot(ivoryPath));
    expect(walnutRect, ivoryRect);
  });

  testWidgets('all six furniture finishes share exact physical anchors',
      (tester) async {
    final rects = <Rect>[];
    for (final option in AveluneAppearanceCatalog.furniture) {
      await _pumpHome(
        tester,
        appearance: AveluneAppearancePreferences(furnitureId: option.id),
      );
      rects.add(
        tester.getRect(
          find.byKey(const ValueKey<String>('avelune-room-furniture-layer')),
        ),
      );
      expect(
        _assetPath(tester, 'avelune-room-furniture-layer'),
        appearanceAssetPath(option),
      );
    }
    expect(rects.toSet(), hasLength(1));

    final console = tester.getRect(find.byType(AveluneConsole));
    final support = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-furniture-support-anchor')),
    );
    // The support line is the console's foot line, not the bottom of its layout
    // box: the art keeps transparent padding below the feet.
    final footline =
        console.top + (console.height * kAveluneConsoleFootlineFraction);
    expect(support.center.dy, closeTo(footline, 2));

    final shelfBaseline = tester
        .getRect(
          find.byKey(
            const ValueKey<String>('avelune-furniture-shelf-baseline'),
          ),
        )
        .center
        .dy;
    final shelfCartridges = find.byWidgetPredicate(
      (widget) =>
          widget is AveluneCartridge &&
          widget.displaySize == AveluneCartridgeDisplaySize.shelf,
    );
    // The cartridges stand back from the board's front lip rather than on it, so
    // a sliver of board shows in front of them and they read as inside the
    // recess. They must still agree with each other to the pixel.
    final scene = tester.widget<AveluneRoomScene>(
      find.byType(AveluneRoomScene),
    );
    final lift = AveluneRoomSceneLayout.resolve(scene.geometry)
        .shelfCartridgeLift;
    for (final element in shelfCartridges.evaluate()) {
      final rect = tester.getRect(
        find.byElementPredicate((candidate) => candidate == element),
      );
      expect(rect.bottom, closeTo(shelfBaseline - lift, 1));
    }
  });

  testWidgets('empty room keeps console and canonical add slot',
      (tester) async {
    await _pumpHome(tester, viewData: _emptyViewData());

    expect(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
      findsNothing,
    );
    expect(find.byType(AveluneConsole), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
      findsOneWidget,
    );
    expect(find.byType(AveluneCartridge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait home contains only the horizontal shelf scrollable',
      (tester) async {
    const viewports = <(Size, EdgeInsets)>[
      (Size(320, 568), EdgeInsets.only(top: 20)),
      (Size(375, 667), EdgeInsets.only(top: 20)),
      (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
      (Size(430, 932), EdgeInsets.only(top: 47, bottom: 34)),
      (Size(360, 800), EdgeInsets.only(top: 24, bottom: 24)),
      (Size(427, 952), EdgeInsets.only(top: 32, bottom: 24)),
    ];

    for (final (size, safeArea) in viewports) {
      await _pumpHome(tester, size: size, safeArea: safeArea);

      final scrollables = tester.widgetList<Scrollable>(
        find.byType(Scrollable),
      );
      expect(scrollables, isNotEmpty);
      expect(
        scrollables.every(
          (scrollable) =>
              scrollable.axisDirection == AxisDirection.left ||
              scrollable.axisDirection == AxisDirection.right,
        ),
        isTrue,
      );
      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  test('room layout aligns furniture top and shelf board to home geometry', () {
    final geometry = AveluneHomeGeometry.resolve(
      viewportSize: const Size(390, 844),
      safeArea: const EdgeInsets.only(top: 47, bottom: 34),
    );
    final room = AveluneRoomSceneLayout.resolve(geometry);

    expect(
      room.furnitureSupportY,
      closeTo(
        geometry.consoleRect.top +
            (geometry.consoleRect.height * kAveluneConsoleFootlineFraction),
        0.01,
      ),
      reason: 'Seating the credenza on consoleRect.bottom left the console '
          'hovering by a tenth of its height.',
    );
    expect(
      room.furnitureShelfBaselineY,
      closeTo(geometry.anchors.shelfBaseline.dy, 0.01),
    );
    expect(room.furnitureRect.width, greaterThan(geometry.contentRect.width));
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  EdgeInsets safeArea = const EdgeInsets.only(top: 47, bottom: 34),
  AveluneAppearancePreferences appearance =
      const AveluneAppearancePreferences(),
  AveluneHomeViewData? viewData,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: safeArea),
        child: AveluneHomeScreen(
          viewData: viewData ?? _viewData(),
          appearance: appearance,
          onGameSelected: (_) {},
          onAddGame: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _assetPath(WidgetTester tester, String key) {
  final image = tester.widget<Image>(find.byKey(ValueKey<String>(key)));
  return (image.image as AssetImage).assetName;
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
  final games = List<AveluneGameViewData>.generate(10, _game);
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

AveluneGameViewData _game(int index) => AveluneGameViewData(
      id: 'games.room.$index',
      title: 'Jeu $index',
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: const AveluneArtworkViewData(
        kind: AveluneArtworkKind.fallback,
      ),
      shellColor:
          index.isEven ? const Color(0xFF633C88) : const Color(0xFF126E78),
      validity: AveluneGameValidity.available,
      primaryAction: AvelunePrimaryAction.play,
      isSelected: index == 0,
      lastSaveAt: null,
      playTimeSeconds: 0,
    );
