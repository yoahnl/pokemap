import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

late Uint8List _image;

void main() {
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 800, 400),
      Paint()..color = const Color(0xff253d47),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    _image = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });

  testWidgets('map uses bounded content pages', (tester) async {
    await _pump(tester, _detail());
    final surface = find.byKey(const ValueKey('runtime-player-detail-map'));
    final scrollers = find
        .descendant(of: surface, matching: find.byType(Scrollable))
        .evaluate()
        .where(
          (element) =>
              element.findAncestorWidgetOfExactType<EditableText>() == null,
        );
    expect(scrollers, isEmpty);
  });

  testWidgets(
    'wide layout uses the reference split and pins use the covering image',
    (tester) async {
      final navigation = RuntimePlayerRegionMapNavigation();
      addTearDown(navigation.dispose);
      await _pump(tester, _detail(), navigation: navigation);
      final canvas = tester.getRect(
        find.byKey(const ValueKey('region-map-canvas')),
      );
      final sidebar = tester.getRect(
        find.byKey(const ValueKey('region-map-sidebar')),
      );
      final pin = tester.getRect(
        find.byKey(const ValueKey('region-pin-hanazuki')),
      );
      expect(sidebar.width, 212);
      expect(canvas.width, 1068);
      expect(canvas.left - sidebar.right, 16);
      expect(find.byKey(const PageStorageKey('region-map-list')), findsNothing);
      expect(pin.size, const Size(48, 48));
      final imageWidth = canvas.height * 2 > canvas.width
          ? canvas.height * 2
          : canvas.width;
      expect(pin.center.dx, closeTo(canvas.center.dx - imageWidth * .25, .01));
      expect(pin.center.dy, closeTo(canvas.center.dy, .01));
      expect(navigation.selectedPointId, 'hanazuki');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('companion uses the narrow left sidebar and no permanent list', (
    tester,
  ) async {
    await _pump(tester, _detail(), size: const Size(496, 432), companion: true);
    final sidebar = tester.getRect(
      find.byKey(const ValueKey('region-map-sidebar')),
    );
    final map = tester.getRect(
      find.byKey(const ValueKey('region-map-canvas-panel')),
    );
    expect(sidebar.width, 164);
    expect(map.left - sidebar.right, 8);
    expect(find.byKey(const PageStorageKey('region-map-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait orders the region, 268px map and inline details', (
    tester,
  ) async {
    await _pump(tester, _detail(), size: const Size(390, 844));
    final region = tester.getRect(
      find.byKey(const ValueKey('region-map-region')),
    );
    final map = tester.getRect(find.byKey(const ValueKey('region-map-canvas')));
    final detail = tester.getRect(
      find.byKey(const ValueKey('region-map-sidebar')),
    );
    expect(map.height, 268);
    expect(map.top, greaterThan(region.bottom));
    expect(detail.top, greaterThan(map.bottom));
    expect(find.byKey(const PageStorageKey('region-map-list')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'optional locations retain unlocated points and restore focus on close',
    (tester) async {
      final navigation = RuntimePlayerRegionMapNavigation();
      addTearDown(navigation.dispose);
      await _pump(tester, _detail(extraPoints: 1), navigation: navigation);
      await _revealMap(
        tester,
        find.byKey(const ValueKey('region-row-extra-0')),
      );
      await tester.tap(find.byKey(const ValueKey('region-row-extra-0')));
      await tester.pumpAndSettle();
      expect(navigation.selectedPointId, 'extra-0');
      expect(find.text('Position non renseignée.'), findsOneWidget);
      expect(find.byKey(const PageStorageKey('region-map-list')), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Map locations');
      await _openLocations(tester);
      expect(navigation.back(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(const PageStorageKey('region-map-list')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cropped points remain reachable through optional locations', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(
      tester,
      _detail(),
      navigation: navigation,
      size: const Size(496, 432),
      companion: true,
    );
    final canvas = tester.getRect(
      find.byKey(const ValueKey('region-map-canvas')),
    );
    final pin = find.byKey(const ValueKey('region-pin-hanazuki'));
    expect(tester.getCenter(pin).dx, lessThan(canvas.left));
    await _openLocations(tester);
    await tester.tap(find.byKey(const ValueKey('region-row-hanazuki')));
    await tester.pumpAndSettle();
    expect(navigation.selectedPointId, 'hanazuki');
    expect(canvas.contains(tester.getCenter(pin)), isTrue);
    await tester.tapAt(tester.getCenter(pin));
    await tester.pumpAndSettle();
    expect(navigation.selectedPointId, 'hanazuki');
    expect(tester.takeException(), isNull);
  });

  testWidgets('short map detail keeps title and description on one page', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _detail(), size: const Size(844, 390));
    final detail = find.byKey(const ValueKey('region-detail-hanazuki'));
    expect(find.text('Hanazuki'), findsOneWidget);
    expect(find.text('Le départ du train.'), findsOneWidget);
    expect(
      find.descendant(
        of: detail,
        matching: find.byKey(const ValueKey('player-page-next')),
      ),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.text('Hanazuki')).getSemanticsData().label,
      contains('Hanazuki, Vous êtes ici'),
    );
    expect(tester.widget<Text>(find.text('Hanazuki')).style?.fontSize, 17);
    expect(
      tester.widget<Text>(find.text('Le départ du train.')).style?.fontSize,
      13,
    );
    semantics.dispose();
  });

  testWidgets('long map descriptions stay paginated at double text size', (
    tester,
  ) async {
    final description = List.generate(80, (index) => 'Étape$index').join(' ');
    await _pump(
      tester,
      _detail(description: description),
      size: const Size(800, 360),
      textScale: 2,
    );
    final detail = find.byKey(const ValueKey('region-detail-hanazuki'));
    final seen = <String>{};
    for (var page = 0; page < 80; page++) {
      for (final text in tester.widgetList<Text>(
        find.descendant(of: detail, matching: find.byType(Text)),
      )) {
        final value = text.data ?? '';
        if (value.contains('Étape')) seen.add(value);
      }
      final next = find.descendant(
        of: detail,
        matching: find.byKey(const ValueKey('player-page-next')),
      );
      if (next.evaluate().isEmpty ||
          tester.widget<IconButton>(next).onPressed == null) {
        break;
      }
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(seen.join(' '), description);
    expect(seen.length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown details cannot leak labels images or descriptions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _detail());
    await _openLocations(tester);
    await tester.tap(find.byKey(const ValueKey('region-row-secret')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tsukikage'), findsNothing);
    expect(find.textContaining('Code secret'), findsNothing);
    expect(find.text('???'), findsOneWidget);
    await _openLocations(tester);
    final row = tester.getSemantics(
      find.byKey(const ValueKey('region-row-secret')),
    );
    expect(row.label, '???');
    expect(row.value, 'Non découvert');
    expect(find.byType(Image), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('zoom is bounded and selection survives closing then reopening', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(), navigation: navigation);
    await _openLocations(tester);
    await tester.tap(find.byKey(const ValueKey('region-row-aohara')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const ValueKey('region-map-zoom-in')));
      await tester.pump();
    }
    expect(navigation.scale, 3);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, _detail(), navigation: navigation);
    expect(navigation.selectedPointId, 'aohara');
    expect(find.text('300 %'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('region-map-recenter')));
    await tester.pumpAndSettle();
    expect(navigation.scale, 1);
    expect(navigation.center, const Offset(.5, .5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlapping pins open a choice and local back closes it', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(overlap: true), navigation: navigation);
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('region-pin-hanazuki'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plusieurs lieux à cet endroit'), findsOneWidget);
    expect(navigation.back(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Plusieurs lieux à cet endroit'), findsNothing);
    expect(navigation.back(), isFalse);
  });

  testWidgets(
    'missing map keeps a useful list and deleted selection is invalidated',
    (tester) async {
      final navigation = RuntimePlayerRegionMapNavigation();
      addTearDown(navigation.dispose);
      await _pump(tester, _detail(image: false), navigation: navigation);
      expect(
        find.textContaining('Carte régionale indisponible'),
        findsOneWidget,
      );
      await _openLocations(tester);
      expect(find.byKey(const ValueKey('region-row-hanazuki')), findsOneWidget);
      expect(
        find
            .byKey(const ValueKey('region-map-zoom-in'))
            .evaluate()
            .single
            .widget,
        isA<PlayerActionButton>().having(
          (button) => button.onPressed,
          'disabled',
          isNull,
        ),
      );
      await _openLocations(tester);
      await tester.tap(find.byKey(const ValueKey('region-row-aohara')));
      await tester.pumpAndSettle();
      await _pump(
        tester,
        _detail(image: false, removeAohara: true),
        navigation: navigation,
      );
      expect(navigation.selectedPointId, isNull);
      expect(find.textContaining('Lieu indisponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('map remains bounded at $size text $scale', (tester) async {
        await _pump(tester, _detail(), size: size, textScale: scale);
        final surface = find.byKey(const ValueKey('runtime-player-detail-map'));
        expect(
          find.descendant(of: surface, matching: find.byType(Scrollable)),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('region-map-info')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('location selection updates information on the same map', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(
      tester,
      _detail(),
      navigation: navigation,
      controlProfile: _remapped(),
    );
    await _revealMap(tester, find.byKey(const ValueKey('region-row-aohara')));
    await _openLocations(tester);
    await tester.tap(find.byKey(const ValueKey('region-row-aohara')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('region-detail-aohara')), findsOneWidget);
    expect(find.text('Retour à la carte'), findsNothing);
    expect(find.byKey(const ValueKey('region-map-info')), findsNothing);
    expect(navigation.back(), isFalse);
  });

  testWidgets('missing illustration remains bounded with compact large text', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(image: false),
      size: const Size(360, 640),
      textScale: 2,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deep location page and selection survive remount', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    final detail = _detail(extraPoints: 20);
    await _pump(tester, detail, navigation: navigation);
    final selected = find.byKey(const ValueKey('region-row-extra-15'));
    await _revealMap(tester, selected);
    await tester.tap(selected);
    await tester.pumpAndSettle();
    expect(navigation.selectedPointId, 'extra-15');
    final page = navigation.listPage;
    expect(page, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, detail, navigation: navigation);
    await _openLocations(tester);
    expect(selected.hitTestable(), findsOneWidget);
    expect(navigation.selectedPointId, 'extra-15');
    expect(navigation.listPage, page);
  });

  testWidgets('new session uses the new current location with stable IDs', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(), navigation: navigation);
    expect(navigation.selectedPointId, 'hanazuki');
    navigation.clearForNewSession();
    await _pump(tester, _detail(currentAohara: true), navigation: navigation);
    expect(navigation.selectedPointId, 'aohara');
  });

  testWidgets('changing region resets the restored location page', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(
      tester,
      _detail(secondRegion: true, extraPoints: 20),
      navigation: navigation,
    );
    await tester.tap(find.byKey(const ValueKey('region-map-region')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('region-choice-second')));
    await tester.pumpAndSettle();
    expect(navigation.listPage, 0);
    expect(navigation.regionId, 'second');
  });

  testWidgets('region choice respects configured movement confirm and cancel', (
    tester,
  ) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(
      tester,
      _detail(secondRegion: true),
      navigation: navigation,
      controlProfile: _remapped(),
    );
    await tester.tap(find.byKey(const ValueKey('region-map-region')));
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Region choice back',
    );
    expect(
      tester
          .widget<PlayerActionButton>(
            find.byKey(const ValueKey('region-choice-train')),
          )
          .focusNode!
          .canRequestFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<PlayerActionButton>()
          ?.key,
      const ValueKey('region-choice-train'),
      reason: FocusManager.instance.primaryFocus.toString(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<PlayerActionButton>()
          ?.key,
      const ValueKey('region-choice-second'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pumpAndSettle();
    expect(navigation.regionId, 'second');
    expect(navigation.selectedPointId, 'other');
    await tester.tap(find.byKey(const ValueKey('region-map-region')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('region-choice-train')), findsNothing);
    expect(navigation.regionId, 'second');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact overlapping choice is revealed above the fold', (
    tester,
  ) async {
    await _pump(tester, _detail(overlap: true), size: const Size(800, 360));
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('region-pin-hanazuki'))),
    );
    await tester.pumpAndSettle();
    await _revealMap(tester, find.text('Plusieurs lieux à cet endroit'));
    final choice = tester.getRect(find.text('Plusieurs lieux à cet endroit'));
    expect(choice.top, greaterThanOrEqualTo(0));
    expect(choice.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openLocations(WidgetTester tester) async {
  if (find
      .byKey(const PageStorageKey('region-map-list'))
      .evaluate()
      .isNotEmpty) {
    return;
  }
  await tester.tap(find.byKey(const ValueKey('region-map-locations')));
  await tester.pumpAndSettle();
}

Future<void> _revealMap(WidgetTester tester, Finder target) async {
  await _openLocations(tester);
  final list = find.byKey(const PageStorageKey('region-map-list'));
  for (var page = 0; target.evaluate().isEmpty && page < 80; page++) {
    final next = find.descendant(
      of: list,
      matching: find.byKey(const ValueKey('player-page-next')),
    );
    if (next.evaluate().isEmpty ||
        tester.widget<IconButton>(next).onPressed == null) {
      break;
    }
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
}

PlayerControlProfile _remapped() => PlayerControlProfile.standard
    .rebind(
      device: PlayerControlDevice.keyboard,
      control: RuntimeInputControl.secondary,
      inputId: 'keyQ',
    )
    .profile
    .rebind(
      device: PlayerControlDevice.keyboard,
      control: RuntimeInputControl.primary,
      inputId: 'keyX',
    )
    .profile
    .rebind(
      device: PlayerControlDevice.keyboard,
      control: RuntimeInputControl.down,
      inputId: 'keyS',
    )
    .profile;

RuntimePlayerPauseDetailSnapshot _detail({
  bool image = true,
  bool overlap = false,
  bool removeAohara = false,
  int extraPoints = 0,
  bool currentAohara = false,
  bool secondRegion = false,
  String description = 'Le départ du train.',
}) => RuntimePlayerPauseDetailSnapshot(
  section: RuntimePlayerPauseSection.map,
  title: 'Carte',
  regionalMap: RuntimePlayerRegionMapSnapshot(
    regions: [
      RuntimePlayerRegionSnapshot(
        id: 'train',
        label: 'Le train de 17h42',
        imageFilePath: image ? 'map.png' : null,
        points: [
          RuntimePlayerMapPointSnapshot(
            id: 'hanazuki',
            label: 'Hanazuki',
            status: currentAohara
                ? RuntimePlayerMapPointStatus.discovered
                : RuntimePlayerMapPointStatus.current,
            u: .25,
            v: .5,
            description: description,
          ),
          if (!removeAohara)
            RuntimePlayerMapPointSnapshot(
              id: 'aohara',
              label: 'Aohara',
              status: currentAohara
                  ? RuntimePlayerMapPointStatus.current
                  : RuntimePlayerMapPointStatus.discovered,
              u: overlap ? .25 : .75,
              v: .5,
              description: 'Les rizières.',
            ),
          const RuntimePlayerMapPointSnapshot(
            id: 'secret',
            label: 'Tsukikage secret',
            status: RuntimePlayerMapPointStatus.unknown,
            u: .8,
            v: .2,
            description: 'Code secret interdit',
            thumbnailFilePath: 'secret.png',
          ),
          for (var i = 0; i < extraPoints; i++)
            RuntimePlayerMapPointSnapshot(
              id: 'extra-$i',
              label: 'Lieu $i',
              status: RuntimePlayerMapPointStatus.discovered,
            ),
        ],
      ),
      if (secondRegion)
        RuntimePlayerRegionSnapshot(
          id: 'second',
          label: 'Autre région',
          points: [
            const RuntimePlayerMapPointSnapshot(
              id: 'other',
              label: 'Autre lieu',
              status: RuntimePlayerMapPointStatus.discovered,
            ),
            for (var i = 0; i < extraPoints; i++)
              RuntimePlayerMapPointSnapshot(
                id: 'second-$i',
                label: 'Autre lieu $i',
                status: RuntimePlayerMapPointStatus.discovered,
              ),
          ],
        ),
    ],
  ),
);

Future<void> _pump(
  WidgetTester tester,
  RuntimePlayerPauseDetailSnapshot detail, {
  RuntimePlayerRegionMapNavigation? navigation,
  Size size = const Size(1296, 644),
  double textScale = 1,
  PlayerControlProfile? controlProfile,
  bool companion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      theme: PokeMapPlayerTheme.dark(),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: PlayerMenuThemeScope(
          role: ProjectPresentationSurfaceRole.map,
          child: Builder(
            builder: (context) {
              final map = RuntimePlayerRegionMap(
                detail: detail,
                navigation: navigation,
                controlProfile: controlProfile,
                imageProvider: (_) => MemoryImage(_image),
              );
              return companion ? PlayerCompanionScope(child: map) : map;
            },
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      MemoryImage(_image),
      tester.element(find.byType(RuntimePlayerRegionMap)),
    ),
  );
  await tester.pumpAndSettle();
}
