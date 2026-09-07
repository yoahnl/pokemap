import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_party_pokemon_detail.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';

const _sizes = [
  Size(1440, 900),
  Size(1280, 720),
  Size(800, 600),
  Size(844, 390),
  Size(390, 844),
  Size(1920, 1080),
];
const _sections = [
  RuntimePlayerPauseSection.root,
  RuntimePlayerPauseSection.party,
  RuntimePlayerPauseSection.bag,
  RuntimePlayerPauseSection.map,
  RuntimePlayerPauseSection.pokedex,
  RuntimePlayerPauseSection.profile,
  RuntimePlayerPauseSection.options,
];
const _accepted =
    RuntimePlayerCommandResult(status: RuntimePlayerCommandStatus.accepted);
const _safeInsets = EdgeInsets.fromLTRB(24, 30, 24, 20);
late Directory _media;

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
    _media = await Directory.systemTemp.createTemp('menu11-ui-fixture-');
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 800, 400),
        Paint()..color = const Color(0xff253d47));
    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${_media.path}/map.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
  tearDownAll(() => _media.delete(recursive: true));

  for (final source in [PlayerInputSource.touch, PlayerInputSource.keyboard]) {
    testWidgets(
        'MENU mobile touch scroll keeps Options after ${source.name} rebuild',
        (tester) async {
      final harness = _Harness(RuntimePlayerPauseSection.root);
      RuntimePlayerSnapshot snapshot(int revision, PlayerInputSource input) =>
          RuntimePlayerSnapshot(
            revision: revision,
            phase: harness.snapshot.phase,
            gameTitle: harness.snapshot.gameTitle,
            pauseSection: RuntimePlayerPauseSection.root,
            actions: harness.snapshot.actions,
            preferences: harness.snapshot.preferences,
            pauseDetails: harness.snapshot.pauseDetails,
            logicalSelectionId: 'pause.party',
            activeInputSource: input,
          );
      final snapshots = ValueNotifier(snapshot(1, source));
      addTearDown(snapshots.dispose);
      await _pump(tester, harness,
          size: const Size(390, 844), phoneInsets: true, snapshots: snapshots);
      final navigation =
          find.byKey(const ValueKey('runtime-pause-navigation-scroll'));
      final scroll =
          tester.widget<SingleChildScrollView>(navigation).controller!;
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      final options = find.byKey(const ValueKey('pause.options'));
      expect(tester.getRect(options).bottom,
          greaterThan(tester.getRect(navigation).bottom));
      await tester.timedDrag(
          navigation, const Offset(0, -300), const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final afterDrag = scroll.offset;
      expect(afterDrag, greaterThan(0));
      snapshots.value = snapshot(2, PlayerInputSource.touch);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      _expectReachable(tester, options, const Size(390, 844),
          const EdgeInsets.only(top: 59, bottom: 34));
      expect(tester.getRect(options).bottom,
          lessThanOrEqualTo(tester.getRect(navigation).bottom));
      expect(scroll.offset, closeTo(afterDrag, .1));
      await tester.tap(options);
      await tester.pumpAndSettle();
      expect(harness.actions, [RuntimePlayerAction.openOptions]);
      _expectNoErrors(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

  for (final source in [PlayerInputSource.touch, PlayerInputSource.keyboard]) {
    testWidgets('MENU mobile root respects the current ${source.name} input',
        (tester) async {
      await _pump(tester, _Harness(RuntimePlayerPauseSection.root),
          size: const Size(390, 844),
          phoneInsets: true,
          activeInputSource: source);
      expect(find.byType(PlayerMenuKeyHint),
          source == PlayerInputSource.touch ? findsNothing : findsOneWidget);
      _expectNoErrors(tester);
    });
  }

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    final insets = size.width < size.height
        ? const EdgeInsets.only(top: 59, bottom: 34)
        : const EdgeInsets.fromLTRB(59, 0, 59, 21);
    for (final section in _sections) {
      testWidgets(
          'MENU mobile ${section.name} ${size.width.toInt()}x${size.height.toInt()} keeps footer actions visible',
          (tester) async {
        await _pump(tester, _Harness(section), size: size, insets: insets);
        _expectNoErrors(tester);
        _expectControlTargets(tester);
        final footer = find.byType(PlayerMenuFooter);
        final actions = find.descendant(
            of: footer,
            matching: find.byWidgetPredicate((widget) =>
                widget is PlayerMenuSelectableRow && widget.onPressed != null));
        expect(actions, findsWidgets);
        for (final element in actions.evaluate()) {
          _expectReachable(
              tester,
              find.byElementPredicate((candidate) => candidate == element),
              size,
              insets);
        }
        final content =
            find.byKey(ValueKey('runtime-player-detail-${section.name}'));
        if (content.evaluate().isNotEmpty) {
          expect(tester.getSize(content).height, greaterThan(96));
        }
      },
          variant: const TargetPlatformVariant(
              {TargetPlatform.iOS, TargetPlatform.android}));
    }
  }

  for (final section in [
    RuntimePlayerPauseSection.party,
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.pokedex,
  ]) {
    testWidgets('MENU mobile ${section.name} detail survives both rotations',
        (tester) async {
      final harness = _Harness(section);
      await _pump(tester, harness,
          size: const Size(390, 844), phoneInsets: true);
      final entry = switch (section) {
        RuntimePlayerPauseSection.party => 'party-member-member0',
        RuntimePlayerPauseSection.bag => 'bag-item-item0',
        RuntimePlayerPauseSection.pokedex => 'pokedex-entry-species.1',
        _ => throw StateError('Unsupported rotation fixture'),
      };
      await _tap(tester, entry);
      final detail = switch (section) {
        RuntimePlayerPauseSection.party =>
          find.byType(PlayerPartyPokemonDetail),
        RuntimePlayerPauseSection.bag =>
          find.byKey(const ValueKey('bag-detail-item0')),
        RuntimePlayerPauseSection.pokedex =>
          find.byKey(const ValueKey('pokedex-detail-species.1')),
        _ => throw StateError('Unsupported rotation fixture'),
      };
      for (final size in [const Size(844, 390), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(detail, findsOneWidget);
        _expectNoErrors(tester);
        final back = find.byKey(const ValueKey('pause-frame-return-surface'));
        _expectReachable(tester, back, size, _phoneInsets(size));
      }
      await _tap(tester, 'pause-frame-return-surface');
      expect(harness.actions, isEmpty);
      expect(find.byKey(ValueKey(entry)), findsOneWidget);
      _expectNoErrors(tester);
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.android}));
  }

  for (final size in _sizes) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final accessible in [false, true]) {
        final configuration =
            '${size.width.toInt()}x${size.height.toInt()} DPR1 text$scale '
            '${accessible ? 'insets reduced opaque' : 'standard'}';
        for (final section in _sections) {
          testWidgets('MENU11 ${section.name} $configuration', (tester) async {
            final harness = _Harness(section);
            await _pump(tester, harness,
                size: size, scale: scale, accessible: accessible);
            _expectNoErrors(tester);
            _expectControlTargets(tester);
            _expectTitle(tester, section, size,
                accessible ? _safeInsets : EdgeInsets.zero);
            if (accessible) {
              final context = tester.element(find.byType(PlayerMenuFrame));
              expect(context.playerMenuTheme.reducedMotion, isTrue);
              expect(context.playerMenuTheme.opaque, isTrue);
              expect(find.byType(BackdropFilter), findsNothing);
            }
            final back =
                find.byKey(const ValueKey('pause-frame-return-surface'));
            await tester.ensureVisible(back);
            await tester.pumpAndSettle();
            _expectReachable(
                tester, back, size, accessible ? _safeInsets : EdgeInsets.zero);
            await tester.tap(back);
            await tester.pumpAndSettle();
            expect(harness.actions, [
              section == RuntimePlayerPauseSection.root
                  ? RuntimePlayerAction.resume
                  : RuntimePlayerAction.returnToPauseRoot
            ]);
            _expectNoErrors(tester);
          });
        }
        for (final exit in [false, true]) {
          testWidgets('MENU11 ${exit ? 'exit' : 'save'} $configuration',
              (tester) async {
            final harness = _Harness(exit
                ? RuntimePlayerPauseSection.options
                : RuntimePlayerPauseSection.root);
            await _pump(tester, harness,
                size: size, scale: scale, accessible: accessible);
            if (exit &&
                find
                    .byKey(const ValueKey('options-category-picker'))
                    .evaluate()
                    .isNotEmpty) {
              await _tap(tester, 'options-category-picker');
            }
            await _tap(tester, exit ? 'options-return-title' : 'pause.save');
            expect(
                find.byKey(ValueKey(
                    exit ? 'runtime-exit-dialog' : 'runtime-save-dialog')),
                findsOneWidget);
            _expectNoErrors(tester);
            final back = find.byKey(
                ValueKey(exit ? 'runtime-exit-stay' : 'runtime-save-cancel'));
            await tester.ensureVisible(back);
            await tester.pumpAndSettle();
            _expectReachable(
                tester, back, size, accessible ? _safeInsets : EdgeInsets.zero);
            await tester.tap(back);
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsNothing);
            expect(harness.actions, isEmpty);
            _expectNoErrors(tester);
          });
        }
      }
    }
  }

  testWidgets('MENU11 Pokédex filter targets are at least 48 logical pixels',
      (tester) async {
    await _pump(tester, _Harness(RuntimePlayerPauseSection.pokedex));
    final filters = find.byWidgetPredicate((widget) =>
        widget is PlayerMenuSelectableRow &&
        widget.id.startsWith('pokedex-filter-'));
    expect(filters, findsNWidgets(3));
    for (final filter in filters.evaluate()) {
      final finder = find.byElementPredicate((element) => element == filter);
      _expectReachable(tester, finder, _sizes.first, EdgeInsets.zero);
    }
  });

  for (final id in [
    'runtime-player-reduced-motion-toggle',
    'runtime-player-high-contrast-toggle',
  ]) {
    testWidgets('MENU11 macOS $id has a 48 pixel interactive target',
        (tester) async {
      final harness = _Harness(RuntimePlayerPauseSection.options);
      await _pump(tester, harness);
      await _tap(tester, 'options-category-accessibility');
      final control = find.byKey(ValueKey(id));
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(control)).platform, TargetPlatform.macOS);
      expect(Theme.of(tester.element(control)).materialTapTargetSize,
          MaterialTapTargetSize.shrinkWrap);
      expect(tester.widget<Switch>(control).value, isFalse);
      final bounds = tester.getRect(control);

      await tester.tapAt(bounds.center - const Offset(0, 23));
      await tester.pumpAndSettle();
      expect(harness.preferenceChanges, hasLength(1),
          reason: 'The upper edge of a 48 pixel target must activate $id; '
              'actual Switch bounds: $bounds');
      expect(tester.widget<Switch>(control).value, isTrue);
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, greaterThanOrEqualTo(48));

      await tester.tapAt(tester.getCenter(control) + const Offset(0, 23));
      await tester.pumpAndSettle();
      expect(harness.preferenceChanges, hasLength(2));
      expect(tester.widget<Switch>(control).value, isFalse);
      _expectNoErrors(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  for (final section in [
    RuntimePlayerPauseSection.party,
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.pokedex,
    RuntimePlayerPauseSection.profile,
    RuntimePlayerPauseSection.map,
  ]) {
    testWidgets('MENU11 ${section.name} empty data does not invent content',
        (tester) async {
      final harness = _Harness(section, empty: true);
      await _pump(tester, harness,
          size: const Size(390, 844), scale: 2, accessible: true);
      _expectNoErrors(tester);
      switch (section) {
        case RuntimePlayerPauseSection.party:
          expect(
              find.byWidgetPredicate((widget) =>
                  widget is PlayerMenuSelectableRow &&
                  widget.id.startsWith('party-member-')),
              findsNothing);
        case RuntimePlayerPauseSection.bag:
          expect(find.byKey(const ValueKey('bag-detail-item0')), findsNothing);
        case RuntimePlayerPauseSection.pokedex:
          expect(find.byKey(const ValueKey('pokedex-entry-species.1')),
              findsNothing);
        case RuntimePlayerPauseSection.profile:
          expect(find.byKey(const ValueKey('profile-earned-badges')),
              findsNothing);
          expect(find.text('private_map_id'), findsNothing);
        case RuntimePlayerPauseSection.map:
          expect(find.byKey(const ValueKey('region-row-town0')), findsNothing);
          expect(find.byKey(const ValueKey('region-pin-town0')), findsNothing);
        default:
          fail('Unsupported empty data case');
      }
      await _tap(tester, 'pause-frame-return-surface');
      expect(harness.actions, [RuntimePlayerAction.returnToPauseRoot]);
    });
  }

  testWidgets(
      'MENU11 portrait bag preserves selection and scroll on local back',
      (tester) async {
    final harness = _Harness(RuntimePlayerPauseSection.bag);
    await _pump(tester, harness, size: const Size(390, 844));
    final target = find.byKey(const ValueKey('bag-item-item14'));
    await tester.scrollUntilVisible(target, 300,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('bag-list-medicine')),
            matching: find.byType(Scrollable)));
    await tester.pumpAndSettle();
    final scroll = Scrollable.of(tester.element(target)).position;
    final offset = scroll.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-detail-item14')), findsOneWidget);
    await _tap(tester, 'pause-frame-return-surface');
    expect(harness.actions, isEmpty);
    final restored = tester.state<ScrollableState>(find.descendant(
        of: find.byKey(const ValueKey('bag-list-medicine')),
        matching: find.byType(Scrollable)));
    expect(restored.position.pixels, closeTo(offset, .01));
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.widget<PlayerMenuSelectableRow>(target).selected, isTrue);
    _expectNoErrors(tester);
  });

  testWidgets(
      'MENU11 portrait Pokédex search stays above the simulated keyboard',
      (tester) async {
    await _pump(tester, _Harness(RuntimePlayerPauseSection.pokedex),
        size: const Size(390, 844), keyboardInset: 300);
    final search = find.byKey(const ValueKey('pokedex-search'));
    await tester.ensureVisible(search);
    await tester.enterText(search, 'Aucune espèce correspondante');
    await tester.pumpAndSettle();
    expect(tester.getRect(search).bottom, lessThanOrEqualTo(544));
    expect(find.byKey(const ValueKey('pokedex-entry-species.1')), findsNothing);
    _expectNoErrors(tester);
  });

  testWidgets('MENU11 newly mounted bag starts at its selected first item',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    late StateSetter rebuild;
    var visible = true;
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: PlayerMenuThemeScope(
          child: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return visible
            ? RuntimePlayerBag(
                detail: _detail(RuntimePlayerPauseSection.bag, empty: false))
            : const SizedBox.shrink();
      }))),
    ));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
        of: find.byKey(const ValueKey('bag-list-medicine')),
        matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('bag-item-item14')), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0));
    rebuild(() => visible = false);
    await tester.pumpAndSettle();
    rebuild(() => visible = true);
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    expect(find.byKey(const ValueKey('bag-item-item0')).hitTestable(),
        findsOneWidget);
    _expectNoErrors(tester);
  });
}

void _expectNoErrors(WidgetTester tester) {
  final errors = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error!);
  }
  expect(errors, isEmpty);
}

void _expectControlTargets(WidgetTester tester) {
  final controls = find.byWidgetPredicate((widget) =>
      widget is PlayerMenuSelectableRow && widget.onPressed != null ||
      widget is PlayerActionButton && widget.onPressed != null);
  for (final element in controls.evaluate()) {
    final finder = find.byElementPredicate((candidate) => candidate == element);
    if (finder.hitTestable().evaluate().isEmpty) continue;
    final bounds = tester.getSize(finder);
    expect(bounds.width, greaterThanOrEqualTo(48),
        reason: '${element.widget.key} width');
    expect(bounds.height, greaterThanOrEqualTo(48),
        reason: '${element.widget.key} height');
  }
}

void _expectTitle(WidgetTester tester, RuntimePlayerPauseSection section,
    Size size, EdgeInsets insets) {
  final title = section == RuntimePlayerPauseSection.root
      ? find.byKey(const ValueKey('pause-root-menu-title'))
      : find.descendant(
          of: find.byType(PlayerMenuHeader),
          matching: find.text(_title(section)));
  expect(title, findsOneWidget);
  final bounds = tester.getRect(title);
  expect(bounds.top, greaterThanOrEqualTo(insets.top));
  expect(bounds.bottom, lessThanOrEqualTo(size.height - insets.bottom));
  final paragraph = tester.renderObject<RenderParagraph>(title);
  expect(paragraph.didExceedMaxLines, isFalse);
}

void _expectReachable(
    WidgetTester tester, Finder finder, Size size, EdgeInsets insets) {
  expect(finder.hitTestable(), findsOneWidget);
  final bounds = tester.getRect(finder);
  expect(bounds.width, greaterThanOrEqualTo(48), reason: '$finder width');
  expect(bounds.height, greaterThanOrEqualTo(48), reason: '$finder height');
  expect(bounds.left, greaterThanOrEqualTo(insets.left));
  expect(bounds.top, greaterThanOrEqualTo(insets.top));
  expect(bounds.right, lessThanOrEqualTo(size.width - insets.right));
  expect(bounds.bottom, lessThanOrEqualTo(size.height - insets.bottom));
  for (final paragraph in find
      .descendant(of: finder, matching: find.byType(RichText))
      .evaluate()) {
    expect(
        (paragraph.renderObject! as RenderParagraph).didExceedMaxLines, isFalse,
        reason: '$finder critical label must remain complete');
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

EdgeInsets _phoneInsets(Size size) => size.width < size.height
    ? const EdgeInsets.only(top: 59, bottom: 34)
    : const EdgeInsets.fromLTRB(59, 0, 59, 21);

Future<void> _pump(WidgetTester tester, _Harness harness,
    {Size size = const Size(1440, 900),
    double scale = 1,
    bool accessible = false,
    EdgeInsets? insets,
    bool phoneInsets = false,
    PlayerInputSource? activeInputSource,
    ValueNotifier<RuntimePlayerSnapshot>? snapshots,
    double keyboardInset = 0}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  addTearDown(harness.dispose);
  await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(), home: const SizedBox.shrink()));
  await tester.runAsync(() => precacheImage(
      FileImage(File('${_media.path}/map.png')),
      tester.element(find.byType(MaterialApp))));
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    theme: PokeMapPlayerTheme.dark(),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        padding: phoneInsets
            ? _phoneInsets(MediaQuery.sizeOf(context))
            : insets ?? (accessible ? _safeInsets : EdgeInsets.zero),
        viewPadding: phoneInsets
            ? _phoneInsets(MediaQuery.sizeOf(context))
            : insets ?? (accessible ? _safeInsets : EdgeInsets.zero),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
        disableAnimations: accessible,
      ),
      child: PlayerMenuEffectsScope(
        effects: accessible
            ? RuntimePlayerMenuEffects.opaque
            : RuntimePlayerMenuEffects.full,
        child: child!,
      ),
    ),
    home: Scaffold(body: Builder(builder: (context) {
      Widget router(RuntimePlayerSnapshot snapshot) =>
          RuntimePlayerSurfaceRouter(
            snapshot: snapshot,
            titlePresentation:
                const RuntimePlayerTitlePresentation(author: 'MENU11'),
            pausePresentation: const PlayerPausePresentation(
                style: ProjectPauseMenuStyle.nightIllustrated),
            partyNavigation: harness.party,
            bagNavigation: harness.bag,
            hardwareGamepadEnabled: false,
            activeInputSource: activeInputSource,
            gameSceneBuilder: (_) => const SizedBox.expand(),
            onAction: (action) async {
              harness.actions.add(action);
              return _accepted;
            },
            onPauseCommand: (_) {},
            onPreferencesChanged: harness.preferenceChanges.add,
            onReturnToTitle: (_) async => _accepted,
          );
      return snapshots == null
          ? router(harness.snapshot)
          : ValueListenableBuilder<RuntimePlayerSnapshot>(
              valueListenable: snapshots,
              builder: (context, snapshot, _) => router(snapshot));
    })),
  ));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _Harness {
  _Harness(RuntimePlayerPauseSection section, {bool empty = false})
      : snapshot = RuntimePlayerSnapshot(
          revision: 1,
          phase: RuntimePlayerPhase.paused,
          gameTitle: 'Le train de 17h42',
          pauseSection: section,
          activeSaveAddress: const RuntimePlayerSaveAddress(
              gameId: 'menu11.fixture', profileId: 'player', slotId: 'slot-1'),
          preferences: const PlayerPreferencesSnapshot(
              locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
          actions: [
            for (final action in RuntimePlayerAction.values)
              if (action != RuntimePlayerAction.openQuests)
                RuntimePlayerActionAvailability.enabled(action)
          ],
          pauseDetails: {
            for (final detailSection in _sections)
              if (detailSection != RuntimePlayerPauseSection.root &&
                  detailSection != RuntimePlayerPauseSection.options)
                detailSection: _detail(detailSection, empty: empty),
          },
        );

  final RuntimePlayerSnapshot snapshot;
  final actions = <RuntimePlayerAction>[];
  final preferenceChanges = <PlayerPreferencesSnapshot>[];
  final party = RuntimePlayerPartyNavigation();
  final bag = RuntimePlayerBagNavigation();

  void dispose() {
    party.dispose();
    bag.dispose();
  }
}

String _title(RuntimePlayerPauseSection section) => switch (section) {
      RuntimePlayerPauseSection.root => 'Menu',
      RuntimePlayerPauseSection.party => 'Équipe',
      RuntimePlayerPauseSection.bag => 'Sac',
      RuntimePlayerPauseSection.pokedex => 'Pokédex',
      RuntimePlayerPauseSection.map => 'Carte',
      RuntimePlayerPauseSection.profile => 'Profil',
      RuntimePlayerPauseSection.options => 'Options',
      _ => throw ArgumentError.value(section),
    };

RuntimePlayerPauseDetailSnapshot _detail(RuntimePlayerPauseSection section,
        {required bool empty}) =>
    RuntimePlayerPauseDetailSnapshot(
      section: section,
      title: _title(section),
      entries: empty
          ? []
          : switch (section) {
              RuntimePlayerPauseSection.party => List.generate(6, (i) {
                  final summary = RuntimePokemonSummarySnapshot(
                    targetId: 'pokemon.$i',
                    individualId: 'member$i',
                    speciesLabel: 'Bulbizarre',
                    nickname: i == 0
                        ? 'Compagnon au surnom particulièrement long'
                        : 'Compagnon $i',
                    level: 17,
                    currentHp: i == 0 ? 0 : 24,
                    maxHp: 38,
                    natureLabel: 'Modeste',
                    abilityLabel: 'Engrais',
                    friendship: 80,
                    typeIds: const ['grass', 'poison'],
                    moves: List.generate(
                        4,
                        (move) => RuntimePokemonMoveSummarySnapshot(
                            moveId: 'move$move',
                            label: 'Capacité $move',
                            typeId: 'normal',
                            currentPp: move,
                            maxPp: 20)),
                  );
                  return RuntimePlayerDetailEntrySnapshot(
                      id: summary.targetId,
                      title: summary.displayLabel,
                      pokemonSummary: summary);
                }),
              RuntimePlayerPauseSection.bag => List.generate(
                  18,
                  (i) => RuntimePlayerDetailEntrySnapshot(
                      id: 'bag.item$i',
                      title: 'Potion $i',
                      bagItem: RuntimePlayerBagItemSnapshot(
                          itemId: 'item$i',
                          quantity: 1,
                          sortOrder: i,
                          pocketId: 'medicine',
                          description:
                              'Restaure les PV du Pokémon sélectionné. ' * 12),
                      bagAction: RuntimePlayerBagItemActionSnapshot(
                          itemTargetId: 'item$i',
                          targetKind: RuntimePlayerBagUseTargetKind.partyMember,
                          usability: ItemUsabilityState.usable,
                          isEnabled: true))),
              RuntimePlayerPauseSection.pokedex => List.generate(
                  18,
                  (i) => RuntimePlayerDetailEntrySnapshot(
                      id: 'species.${i + 1}',
                      title: 'Espèce ${i + 1}',
                      pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                          nationalDex: i + 1,
                          knowledge: RuntimePlayerPokedexKnowledge.caught,
                          typeIds: const ['grass'],
                          description: 'Description publique. ' * 16))),
              _ => [],
            },
      bagMoney: section == RuntimePlayerPauseSection.bag ? 3200 : null,
      bagPockets: section == RuntimePlayerPauseSection.bag
          ? const [
              RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
              RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
              RuntimePlayerBagPocketSnapshot(id: 'key', label: 'Objets clés'),
            ]
          : const [],
      profile: section == RuntimePlayerPauseSection.profile
          ? RuntimePlayerProfileSnapshot(
              playerName: 'Yoahn',
              currentMapId: 'private_map_id',
              money: 3200,
              locationName: empty ? null : 'Village d’Hanazuki',
              playtimeSeconds: empty ? null : 97740,
              pokedex: empty
                  ? null
                  : const RuntimePlayerPokedexProgressSnapshot(
                      seen: 132, caught: 71, total: 151))
          : null,
      regionalMap: section == RuntimePlayerPauseSection.map
          ? RuntimePlayerRegionMapSnapshot(regions: [
              RuntimePlayerRegionSnapshot(
                  id: 'region',
                  label: 'Hanazuki',
                  imageFilePath: empty ? null : '${_media.path}/map.png',
                  points: empty
                      ? []
                      : List.generate(
                          18,
                          (i) => RuntimePlayerMapPointSnapshot(
                              id: 'town$i',
                              label: 'Lieu $i',
                              status: i == 0
                                  ? RuntimePlayerMapPointStatus.current
                                  : RuntimePlayerMapPointStatus.discovered,
                              u: (i % 6 + 1) / 7,
                              v: (i ~/ 6 + 1) / 4,
                              description: 'Description du lieu $i. ' * 12))),
            ])
          : null,
    );
