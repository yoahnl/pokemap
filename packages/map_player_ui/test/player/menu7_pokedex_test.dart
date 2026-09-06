import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_pokedex.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  testWidgets('reference geometry reserves the list and illustration areas',
      (tester) async {
    await _pump(tester, _detail(_entries()));
    final body = tester
        .getRect(find.byKey(const ValueKey('runtime-player-detail-pokedex')));
    final column =
        tester.getRect(find.byKey(const ValueKey('pokedex-list-column')));
    final search =
        tester.getRect(find.byKey(const ValueKey('pokedex-search-panel')));
    final filters =
        tester.getRect(find.byKey(const ValueKey('pokedex-filters')));
    final list = tester.getRect(find.byKey(const ValueKey('pokedex-list')));
    final detail =
        tester.getRect(find.byKey(const ValueKey('pokedex-detail-species.1')));
    final row =
        tester.getRect(find.byKey(const ValueKey('pokedex-entry-species.1')));
    expect(body.size, const Size(1296, 644));
    expect(column.width, 448);
    expect(search.height, 48);
    expect(filters.height, 44);
    expect(filters.top - search.bottom, 12);
    expect(list.top - filters.bottom, 16);
    expect(list.height, 524);
    expect(detail.width, 824);
    expect(detail.left - column.right, 24);
    expect(row.height, 64);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('pokedex-number-species.1')))
            .width,
        56);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('pokedex-image-species.1-row'))),
        const Size(48, 48));
    expect(
        tester.getSize(
            find.byKey(const ValueKey('pokedex-image-species.1-detail'))),
        const Size(300, 280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown entries cannot expose a hidden title or identity',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
        tester,
        _detail([
          _entry(151,
              title: 'Mew secret',
              knowledge: RuntimePlayerPokedexKnowledge.unknown),
        ]));
    expect(find.text('Mew secret'), findsNothing);
    expect(find.text('???'), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('pokedex-unknown-species.151-detail')),
        findsOneWidget);
    expect(find.byType(PlayerMenuBadge), findsNothing);
    final row = tester
        .getSemantics(find.byKey(const ValueKey('pokedex-entry-species.151')));
    expect(row.label, '???');
    expect(row.value, '151, Inconnu');
    await _search(tester, 'mew');
    expect(find.byKey(const ValueKey('pokedex-no-results')), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-search-clear')).hitTestable(),
        findsOneWidget);
    await _search(tester, '151');
    expect(find.byKey(const ValueKey('pokedex-entry-species.151')),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('search folds accents and case and matches public dex numbers',
      (tester) async {
    await _pump(tester, _detail(_entries()));
    for (final query in ['eVÓ', 'évo', 'E\u0301VO', '133', '#133']) {
      await _search(tester, query);
      expect(find.byKey(const ValueKey('pokedex-entry-species.133')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('pokedex-entry-species.1')), findsNothing);
    }
    await _search(tester, '001');
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.1')), findsOneWidget);
    await _search(tester, 'species.1');
    expect(find.byKey(const ValueKey('pokedex-no-results')), findsOneWidget);
  });

  testWidgets('local filters distinguish seen caught and unknown',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    await _pump(tester, _detail(_entries()), navigation: nav);
    await _tap(tester, 'pokedex-filter-seen');
    expect(nav.filter, RuntimePlayerPokedexFilter.seen);
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-entry-species.133')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.151')), findsNothing);
    await _tap(tester, 'pokedex-filter-caught');
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.133')), findsNothing);
    await _tap(tester, 'pokedex-filter-all');
    expect(find.byKey(const ValueKey('pokedex-entry-species.151')),
        findsOneWidget);
  });

  testWidgets('search retains public knowledge and localized type matching',
      (tester) async {
    await _pump(tester, _detail(_entries()));
    await _search(tester, 'CAPTURÉ');
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.133')), findsNothing);
    await _search(tester, 'plante');
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pokedex-entry-species.151')), findsNothing);
    await _search(tester, 'inconnu');
    expect(find.byKey(const ValueKey('pokedex-entry-species.151')),
        findsOneWidget);
  });

  testWidgets('clear restores selection and remount retains local browsing',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    final detail = _detail(_entries());
    await _pump(tester, detail, navigation: nav);
    await _tap(tester, 'pokedex-entry-species.133');
    await _search(tester, 'absent');
    expect(nav.selectedEntryId, 'species.133');
    await _tap(tester, 'pokedex-search-clear');
    expect(find.byKey(const ValueKey('pokedex-detail-species.133')),
        findsOneWidget);
    await _tap(tester, 'pokedex-filter-seen');
    await _search(tester, 'evo');
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, detail, navigation: nav);
    expect(nav.filter, RuntimePlayerPokedexFilter.seen);
    expect(nav.query, 'evo');
    expect(nav.selectedEntryId, 'species.133');
    expect(
        tester
            .widget<TextField>(find.byType(TextField, skipOffstage: false))
            .controller!
            .text,
        'evo');
    nav.clearForNewSession();
    await tester.pumpAndSettle();
    expect(nav.query, isEmpty);
    expect(nav.filter, RuntimePlayerPokedexFilter.all);
    expect(nav.selectedEntryId, 'species.1');
  });

  testWidgets('deep list browsing survives compact detail and menu remount',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    final detail = _detail(List.generate(
        120, (index) => _entry(index + 1, title: 'Espèce ${index + 1}')));
    const size = Size(390, 844);
    await _pump(tester, detail, navigation: nav, size: size);
    final list = find.byKey(const ValueKey('pokedex-list'));
    final selected = find.byKey(const ValueKey('pokedex-entry-species.90'));
    await tester.scrollUntilVisible(selected, 360,
        scrollable:
            find.descendant(of: list, matching: find.byType(Scrollable)),
        maxScrolls: 30);
    await tester.pumpAndSettle();
    final offset = tester.widget<ListView>(list).controller!.offset;
    expect(offset, greaterThan(1000));
    await _tap(tester, 'pokedex-entry-species.90');
    expect(find.byKey(const ValueKey('pokedex-detail-species.90')),
        findsOneWidget);
    expect(nav.back(), isTrue);
    await tester.pumpAndSettle();
    expect(selected.hitTestable(), findsOneWidget);
    expect(nav.selectedEntryId, 'species.90');
    expect(
        tester.widget<ListView>(list).controller!.offset, closeTo(offset, 1));
    expect(tester.widget<PlayerMenuSelectableRow>(selected).focusNode!.hasFocus,
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, detail, navigation: nav, size: size);
    expect(selected.hitTestable(), findsOneWidget);
    expect(nav.selectedEntryId, 'species.90');
    expect(
        tester.widget<ListView>(list).controller!.offset, closeTo(offset, 1));
    expect(tester.widget<PlayerMenuSelectableRow>(selected).focusNode!.hasFocus,
        isTrue);
    nav.clearForNewSession();
    await tester.pumpAndSettle();
    expect(nav.selectedEntryId, 'species.1');
    expect(tester.widget<ListView>(list).controller!.offset, 0);
    expect(find.byKey(const ValueKey('pokedex-entry-species.1')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snapshot replacement repairs stale selection and public status',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    await _pump(tester, _detail(_entries()), navigation: nav);
    await _tap(tester, 'pokedex-entry-species.133');
    await _pump(
        tester,
        _detail([
          _entry(1, title: 'Bulbizarre'),
          _entry(151,
              title: 'Mew', knowledge: RuntimePlayerPokedexKnowledge.caught),
        ]),
        navigation: nav);
    expect(nav.selectedEntryId, 'species.151');
    expect(find.byKey(const ValueKey('pokedex-detail-species.151')),
        findsOneWidget);
    expect(find.text('#151 · Capturé'), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-unknown-species.151-detail')),
        findsNothing);
  });

  testWidgets('empty catalog and filtered empty state remain distinct',
      (tester) async {
    await _pump(tester, _detail([]));
    expect(find.byKey(const ValueKey('pokedex-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-no-results')), findsNothing);
    await _pump(
        tester,
        _detail([
          _entry(151, knowledge: RuntimePlayerPokedexKnowledge.unknown),
        ]));
    await _tap(tester, 'pokedex-filter-caught');
    expect(find.byKey(const ValueKey('pokedex-no-results')), findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-filter-all')).hitTestable(),
        findsOneWidget);
  });

  testWidgets(
      'missing media keeps truthful placeholders and public description',
      (tester) async {
    await _pump(
        tester,
        _detail([
          _entry(1,
              description: 'La description publiée par le projet.',
              media: const RuntimePokemonSummaryMediaSnapshot(
                  thumbnail: RuntimePokemonLocalImageSnapshot(
                      absoluteFilePath: '/tmp/pokedex-missing-thumbnail.png',
                      sampling: ProjectMenuImageSampling.pixelArt),
                  illustration: RuntimePokemonLocalImageSnapshot(
                      absoluteFilePath: '/tmp/pokedex-missing-illustration.png',
                      sampling: ProjectMenuImageSampling.smooth))),
        ]));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pokedex-image-missing-species.1-row')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('pokedex-image-missing-species.1-detail')),
        findsOneWidget);
    expect(find.text('La description publiée par le projet.'), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images.map((image) => image.fit), everyElement(BoxFit.contain));
    expect(images.map((image) => image.filterQuality),
        containsAll([FilterQuality.none, FilterQuality.medium]));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1440, 900),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('list detail and return remain readable at $size text $scale',
          (tester) async {
        final nav = RuntimePlayerPokedexNavigation();
        addTearDown(nav.dispose);
        await _pump(
            tester,
            _detail([
              _entry(1,
                  title: 'Bulbizarre au nom particulièrement long',
                  description: List.filled(20,
                          'Une description publique longue reste accessible en faisant défiler la fiche.')
                      .join(' ')),
            ]),
            navigation: nav,
            size: size,
            scale: scale);
        expect(
            tester
                .widget<TextField>(find.byType(TextField, skipOffstage: false))
                .focusNode!
                .hasFocus,
            isFalse);
        expect(tester.takeException(), isNull);
        await _tap(tester, 'pokedex-entry-species.1');
        expect(find.byKey(const ValueKey('pokedex-detail-species.1')),
            findsOneWidget);
        if (size.width == 844) {
          final image = tester.getRect(
              find.byKey(const ValueKey('pokedex-image-species.1-detail')));
          final panel = tester
              .getRect(find.byKey(const ValueKey('pokedex-detail-species.1')));
          expect(image.top, greaterThanOrEqualTo(panel.top));
          expect(image.bottom, lessThanOrEqualTo(panel.bottom));
        }
        final scroller = tester.widget<SingleChildScrollView>(
            find.byKey(const ValueKey('pokedex-description-species.1')));
        expect(scroller.controller!.position.maxScrollExtent, greaterThan(0));
        await tester.drag(
            find.byKey(const ValueKey('pokedex-description-species.1')),
            const Offset(0, -180));
        await tester.pumpAndSettle();
        expect(scroller.controller!.offset, greaterThan(0));
        expect(tester.takeException(), isNull);
        final compact = size.width < 1000 || scale == 2;
        expect(nav.back(), compact);
        await tester.pumpAndSettle();
        expect(nav.back(), isFalse);
        expect(find.byKey(const ValueKey('pokedex-entry-species.1')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('compact detail accepts controller scroll and internal return',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    await _pump(
        tester,
        _detail([
          _entry(1, description: List.filled(40, 'Description.').join(' '))
        ]),
        navigation: nav,
        size: const Size(390, 844));
    await _tap(tester, 'pokedex-entry-species.1');
    Actions.invoke(
        tester.element(
            find.byKey(const ValueKey('pokedex-description-species.1'))),
        const RuntimePlayerLogicalIntent(PlayerInputAction.down,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('pokedex-description-species.1')));
    expect(scroll.controller!.offset, greaterThan(0));
    expect(nav.back(), isTrue);
    await tester.pumpAndSettle();
    final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('pokedex-entry-species.1')));
    expect(row.focusNode!.hasFocus, isTrue);
  });

  testWidgets('keyboard browsing and controller confirm keep the back depth',
      (tester) async {
    final nav = RuntimePlayerPokedexNavigation();
    addTearDown(nav.dispose);
    await _pump(tester, _detail(_entries()),
        navigation: nav, size: const Size(390, 844));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(nav.selectedEntryId, 'species.133');
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pokedex-detail-species.133')),
        findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pokedex-entry-species.133')),
        findsOneWidget);
    expect(nav.back(), isFalse);
    expect(nav.selectedEntryId, 'species.133');
  });

  testWidgets('captures reference and compact layouts when requested',
      (tester) async {
    const directory = String.fromEnvironment('MENU7_POKEDEX_CAPTURE_DIR');
    for (final size in [
      const Size(1440, 900),
      const Size(844, 390),
      const Size(390, 844),
    ]) {
      await _pump(tester, _detail(_captureEntries()), size: size);
      for (var attempt = 0; attempt < 8; attempt++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
      }
      await _capture(tester, directory, size, 'list');
      if (size.width < 1000) {
        await _tap(tester, 'pokedex-entry-species.1');
        await _capture(tester, directory, size, 'detail');
      }
    }
  }, skip: const String.fromEnvironment('MENU7_POKEDEX_CAPTURE_DIR').isEmpty);
}

RuntimePlayerDetailEntrySnapshot _entry(int number,
        {String? title,
        RuntimePlayerPokedexKnowledge knowledge =
            RuntimePlayerPokedexKnowledge.seen,
        String? description,
        RuntimePokemonSummaryMediaSnapshot media =
            const RuntimePokemonSummaryMediaSnapshot()}) =>
    RuntimePlayerDetailEntrySnapshot(
        id: 'species.$number',
        title: title ?? 'Pokémon $number',
        pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            nationalDex: number,
            knowledge: knowledge,
            identity: knowledge == RuntimePlayerPokedexKnowledge.unknown
                ? null
                : RuntimePokemonMediaIdentity(speciesId: 'species.$number'),
            typeIds: knowledge == RuntimePlayerPokedexKnowledge.unknown
                ? const []
                : switch (number) {
                    1 => const ['GRASS', 'POISON'],
                    4 => const ['FIRE'],
                    25 => const ['ELECTRIC'],
                    133 => const ['NORMAL'],
                    _ => const [],
                  },
            media: media,
            description: description));

List<RuntimePlayerDetailEntrySnapshot> _entries() => [
      _entry(1,
          title: 'Bulbizarre',
          knowledge: RuntimePlayerPokedexKnowledge.caught,
          description:
              'Depuis sa naissance, il porte une graine sur son dos. Elle grandit avec lui.'),
      _entry(133, title: 'Évoli'),
      _entry(151,
          title: 'Nom caché', knowledge: RuntimePlayerPokedexKnowledge.unknown),
    ];

List<RuntimePlayerDetailEntrySnapshot> _captureEntries() {
  const directory = String.fromEnvironment('MENU7_POKEDEX_MEDIA_DIR');
  RuntimePokemonSummaryMediaSnapshot media(String species) {
    if (directory.isEmpty) return const RuntimePokemonSummaryMediaSnapshot();
    final thumbnailDirectory =
        Directory('$directory/assets/pokemon/menu/$species/base');
    final thumbnail = thumbnailDirectory.existsSync()
        ? thumbnailDirectory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.png'))
            .firstOrNull
        : null;
    return RuntimePokemonSummaryMediaSnapshot(
        thumbnail: thumbnail == null
            ? null
            : RuntimePokemonLocalImageSnapshot(
                absoluteFilePath: thumbnail.path,
                sampling: ProjectMenuImageSampling.pixelArt),
        illustration: RuntimePokemonLocalImageSnapshot(
            absoluteFilePath:
                '$directory/assets/pokemon/portraits/$species.png',
            sampling: ProjectMenuImageSampling.smooth));
  }

  return [
    _entry(1,
        title: 'Bulbizarre',
        knowledge: RuntimePlayerPokedexKnowledge.caught,
        description:
            'Depuis sa naissance, il porte une graine sur son dos. Elle grandit avec lui.',
        media: media('bulbasaur')),
    _entry(2, knowledge: RuntimePlayerPokedexKnowledge.unknown),
    _entry(3, knowledge: RuntimePlayerPokedexKnowledge.unknown),
    _entry(4, title: 'Salamèche', media: media('charmander')),
    _entry(5, knowledge: RuntimePlayerPokedexKnowledge.unknown),
    _entry(6, knowledge: RuntimePlayerPokedexKnowledge.unknown),
    _entry(7, knowledge: RuntimePlayerPokedexKnowledge.unknown),
    _entry(25, title: 'Pikachu', media: media('pikachu')),
    _entry(133, title: 'Évoli'),
  ];
}

RuntimePlayerPauseDetailSnapshot _detail(
        List<RuntimePlayerDetailEntrySnapshot> entries) =>
    RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
        entries: entries);

Future<void> _search(WidgetTester tester, String value) async {
  final field =
      find.byKey(const ValueKey('pokedex-search'), skipOffstage: false);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key), skipOffstage: false);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(
    WidgetTester tester, String directory, Size size, String state) async {
  await tester.pump(const Duration(milliseconds: 300));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('pokedex-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
            '$directory/menu7-pokedex-${size.width.toInt()}x${size.height.toInt()}-$state.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _pump(WidgetTester tester, RuntimePlayerPauseDetailSnapshot detail,
    {Size size = const Size(1440, 900),
    double scale = 1,
    RuntimePlayerPokedexNavigation? navigation}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final nav = navigation ?? RuntimePlayerPokedexNavigation();
  if (navigation == null) addTearDown(nav.dispose);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.pokedex,
        child: Scaffold(
            body: RepaintBoundary(
                key: const ValueKey('pokedex-capture'),
                child: RuntimePlayerPauseShell(
                    gameTitle: 'Le train de 17h42',
                    pauseSection: RuntimePlayerPauseSection.pokedex,
                    actions: {
                      for (final action in PlayerPauseAction.values)
                        action: PlayerActionAvailability.enabled,
                    },
                    onSelected: (_) {},
                    onBackToRoot: nav.back,
                    presentation: const PlayerPausePresentation(
                        style: ProjectPauseMenuStyle.nightIllustrated),
                    detailHeaderSecondary: Text(
                        '${detail.entries.where((entry) => entry.pokedexEntry?.knowledge != RuntimePlayerPokedexKnowledge.unknown).length} vus · ${detail.entries.where((entry) => entry.pokedexEntry?.knowledge == RuntimePlayerPokedexKnowledge.caught).length} capturé'),
                    detailOwnsScroll: true,
                    detail: RuntimePlayerPokedex(
                        detail: detail, navigation: nav))))),
  ));
  await tester.pumpAndSettle();
}
