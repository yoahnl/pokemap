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
    canvas.drawRect(const Rect.fromLTWH(0, 0, 800, 400),
        Paint()..color = const Color(0xff253d47));
    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    _image = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });

  testWidgets(
      'wide layout uses the reference split and pins use the contained image',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(), navigation: navigation);
    final canvas =
        tester.getRect(find.byKey(const ValueKey('region-map-canvas')));
    final sidebar =
        tester.getRect(find.byKey(const ValueKey('region-map-sidebar')));
    final pin =
        tester.getRect(find.byKey(const ValueKey('region-pin-hanazuki')));
    expect(sidebar.width, 384);
    expect(canvas.width, 888);
    expect(sidebar.left - canvas.right, 24);
    expect(pin.size, const Size(48, 48));
    expect(pin.center.dx, closeTo(canvas.left + canvas.width * .25, .01));
    expect(pin.center.dy, closeTo(canvas.center.dy, .01));
    expect(navigation.selectedPointId, 'hanazuki');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown details cannot leak labels images or descriptions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _detail());
    await tester.tap(find.byKey(const ValueKey('region-row-secret')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tsukikage'), findsNothing);
    expect(find.textContaining('Code secret'), findsNothing);
    expect(find.text('???'), findsNWidgets(2));
    final row =
        tester.getSemantics(find.byKey(const ValueKey('region-row-secret')));
    expect(row.label, '???');
    expect(row.value, 'Non découvert');
    expect(find.byType(Image), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('zoom is bounded and selection survives closing then reopening',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(), navigation: navigation);
    await tester.tap(find.byKey(const ValueKey('region-row-aohara')));
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

  testWidgets('overlapping pins open a choice and local back closes it',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(overlap: true), navigation: navigation);
    await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('region-pin-hanazuki'))));
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
    expect(find.textContaining('Carte régionale indisponible'), findsOneWidget);
    expect(find.byKey(const ValueKey('region-row-hanazuki')), findsOneWidget);
    expect(
        find
            .byKey(const ValueKey('region-map-zoom-in'))
            .evaluate()
            .single
            .widget,
        isA<PlayerActionButton>()
            .having((button) => button.onPressed, 'disabled', isNull));
    await tester.tap(find.byKey(const ValueKey('region-row-aohara')));
    await tester.pumpAndSettle();
    await _pump(tester, _detail(image: false, removeAohara: true),
        navigation: navigation);
    expect(navigation.selectedPointId, isNull);
    expect(find.textContaining('Lieu indisponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact and large text remain scrollable without overflow',
      (tester) async {
    for (final size in [
      const Size(360, 640),
      const Size(800, 360),
      const Size(1296, 644)
    ]) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _detail(), size: size, textScale: 2);
      await tester.ensureVisible(find.byKey(const ValueKey('region-map-info')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size at 200 %');
    }
  });

  testWidgets('local info closes before leaving the map with remapped back',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(),
        navigation: navigation, controlProfile: _remapped());
    await tester.tap(find.byKey(const ValueKey('region-map-info')));
    await tester.pumpAndSettle();
    expect(find.text('Retour à la carte'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Region info back');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    expect(find.text('Retour à la carte'), findsNothing);
    expect(navigation.back(), isFalse);
  });

  testWidgets('missing illustration remains readable with compact large text',
      (tester) async {
    await _pump(tester, _detail(image: false),
        size: const Size(360, 640), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('region-map-info')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('local info preserves the scrolled location list',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(extraPoints: 20), navigation: navigation);
    await tester
        .ensureVisible(find.byKey(const ValueKey('region-row-extra-15')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('region-row-extra-15')));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(
            find.byKey(const PageStorageKey('region-map-list')))
        .controller!;
    final before = scroll.offset;
    expect(before, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('region-map-info')));
    await tester.pumpAndSettle();
    expect(navigation.back(), isTrue);
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(before, .01));
    expect(navigation.selectedPointId, 'extra-15');
  });

  testWidgets('local info preserves compact scrolling', (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(),
        navigation: navigation, size: const Size(360, 640));
    await tester.ensureVisible(find.byKey(const ValueKey('region-map-info')));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(
            find.byKey(const PageStorageKey('region-map-scroll')))
        .controller!;
    final before = scroll.offset;
    expect(before, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('region-map-info')));
    await tester.pumpAndSettle();
    expect(navigation.back(), isTrue);
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(before, .01));
  });

  testWidgets('new session uses the new current location with stable IDs',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(), navigation: navigation);
    expect(navigation.selectedPointId, 'hanazuki');
    navigation.clearForNewSession();
    await _pump(tester, _detail(currentAohara: true), navigation: navigation);
    expect(navigation.selectedPointId, 'aohara');
  });

  testWidgets('changing region resets scroll restored on reopening',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation()..listOffset = 500;
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(secondRegion: true, extraPoints: 20),
        navigation: navigation);
    final list = find.byKey(const PageStorageKey('region-map-list'));
    expect(tester.widget<SingleChildScrollView>(list).controller!.offset, 500);
    await tester.tap(find.byKey(const ValueKey('region-map-region')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('region-choice-second')));
    await tester.pumpAndSettle();
    expect(tester.widget<SingleChildScrollView>(list).controller!.offset, 0);
  });

  testWidgets('region choice respects configured movement confirm and cancel',
      (tester) async {
    final navigation = RuntimePlayerRegionMapNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, _detail(secondRegion: true),
        navigation: navigation, controlProfile: _remapped());
    await tester.tap(find.byKey(const ValueKey('region-map-region')));
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'Region choice back');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<PlayerActionButton>()
            ?.key,
        const ValueKey('region-choice-train'),
        reason: FocusManager.instance.primaryFocus.toString());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<PlayerActionButton>()
            ?.key,
        const ValueKey('region-choice-second'));
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

  testWidgets('compact overlapping choice is revealed above the fold',
      (tester) async {
    await _pump(tester, _detail(overlap: true), size: const Size(800, 360));
    await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('region-pin-hanazuki'))));
    await tester.pumpAndSettle();
    final choice = tester.getRect(find.text('Plusieurs lieux à cet endroit'));
    expect(choice.top, greaterThanOrEqualTo(0));
    expect(choice.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
}

PlayerControlProfile _remapped() => PlayerControlProfile.standard
    .rebind(
        device: PlayerControlDevice.keyboard,
        control: RuntimeInputControl.secondary,
        inputId: 'keyQ')
    .profile
    .rebind(
        device: PlayerControlDevice.keyboard,
        control: RuntimeInputControl.primary,
        inputId: 'keyX')
    .profile
    .rebind(
        device: PlayerControlDevice.keyboard,
        control: RuntimeInputControl.down,
        inputId: 'keyS')
    .profile;

RuntimePlayerPauseDetailSnapshot _detail(
        {bool image = true,
        bool overlap = false,
        bool removeAohara = false,
        int extraPoints = 0,
        bool currentAohara = false,
        bool secondRegion = false}) =>
    RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.map,
        title: 'Carte',
        regionalMap: RuntimePlayerRegionMapSnapshot(regions: [
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
                  description: 'Le départ du train.'),
              if (!removeAohara)
                RuntimePlayerMapPointSnapshot(
                    id: 'aohara',
                    label: 'Aohara',
                    status: currentAohara
                        ? RuntimePlayerMapPointStatus.current
                        : RuntimePlayerMapPointStatus.discovered,
                    u: overlap ? .25 : .75,
                    v: .5,
                    description: 'Les rizières.'),
              const RuntimePlayerMapPointSnapshot(
                  id: 'secret',
                  label: 'Tsukikage secret',
                  status: RuntimePlayerMapPointStatus.unknown,
                  u: .8,
                  v: .2,
                  description: 'Code secret interdit',
                  thumbnailFilePath: 'secret.png'),
              for (var i = 0; i < extraPoints; i++)
                RuntimePlayerMapPointSnapshot(
                    id: 'extra-$i',
                    label: 'Lieu $i',
                    status: RuntimePlayerMapPointStatus.discovered),
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
                      status: RuntimePlayerMapPointStatus.discovered),
                  for (var i = 0; i < extraPoints; i++)
                    RuntimePlayerMapPointSnapshot(
                        id: 'second-$i',
                        label: 'Autre lieu $i',
                        status: RuntimePlayerMapPointStatus.discovered)
                ])
        ]));

Future<void> _pump(WidgetTester tester, RuntimePlayerPauseDetailSnapshot detail,
    {RuntimePlayerRegionMapNavigation? navigation,
    Size size = const Size(1296, 644),
    double textScale = 1,
    PlayerControlProfile? controlProfile}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    theme: PokeMapPlayerTheme.dark(),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!),
    home: Scaffold(
        body: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.map,
            child: RuntimePlayerRegionMap(
                detail: detail,
                navigation: navigation,
                controlProfile: controlProfile,
                imageProvider: (_) => MemoryImage(_image)))),
  ));
  await tester.runAsync(
      () async => await Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pumpAndSettle();
}
