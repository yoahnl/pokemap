import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_pokedex.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final style in ProjectPauseMenuStyle.values) {
    for (final keyboard in [false, true]) {
      testWidgets(
          'direct $style pokedex preserves back depth with keyboard $keyboard',
          (tester) async {
        final snapshot = ValueNotifier(_snapshot());
        addTearDown(snapshot.dispose);
        final actions = <RuntimePlayerAction>[];
        await _pump(tester, snapshot, actions: actions, style: style);
        await _tap(tester, 'pokedex-entry-eevee');
        expect(
            find.byKey(const ValueKey('pokedex-detail-eevee')), findsOneWidget);
        snapshot.value = _snapshot(revision: 2);
        await tester.pumpAndSettle();
        if (keyboard) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        } else {
          await _tap(tester, _returnKey(style));
        }
        expect(actions, isEmpty);
        expect(
            find.byKey(const ValueKey('pokedex-entry-eevee')), findsOneWidget);
        final row = tester.widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('pokedex-entry-eevee')));
        expect(row.selected, isTrue);
        expect(row.focusNode!.hasFocus, isTrue);
        if (keyboard) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        } else {
          await _tap(tester, _returnKey(style));
        }
        expect(actions, [RuntimePlayerAction.returnToPauseRoot]);
        expect(snapshot.value.pauseSection, RuntimePlayerPauseSection.root);
        expect(find.byType(RuntimePlayerPokedex), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('direct $style header updates public pokedex counters',
        (tester) async {
      final snapshot = ValueNotifier(_snapshot());
      addTearDown(snapshot.dispose);
      await _pump(tester, snapshot, style: style);
      expect(find.byKey(const ValueKey('pokedex-progress')).hitTestable(),
          findsOneWidget);
      expect(find.text('Vus 2 · Capturés 1 / 3'), findsOneWidget);
      snapshot.value = _snapshot(revision: 2, eeveeCaught: true);
      await tester.pumpAndSettle();
      expect(find.text('Vus 2 · Capturés 2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('direct $style profile uses typed data and returns to root',
        (tester) async {
      final snapshot =
          ValueNotifier(_snapshot(section: RuntimePlayerPauseSection.profile));
      addTearDown(snapshot.dispose);
      final actions = <RuntimePlayerAction>[];
      await _pump(tester, snapshot, actions: actions, style: style);
      expect(find.byKey(const ValueKey('runtime-player-detail-profile')),
          findsOneWidget);
      expect(find.text('Camille'), findsWidgets);
      expect(find.text('Port des brumes'), findsWidgets);
      await _tap(tester, _returnKey(style));
      expect(actions, [RuntimePlayerAction.returnToPauseRoot]);
      expect(snapshot.value.pauseSection, RuntimePlayerPauseSection.root);
      expect(find.byKey(const ValueKey('runtime-player-detail-profile')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('direct router clears its local browsing for a new session',
      (tester) async {
    final snapshot = ValueNotifier(_snapshot());
    addTearDown(snapshot.dispose);
    await _pump(tester, snapshot);
    final field = find.byKey(const ValueKey('pokedex-search'));
    await tester.enterText(field, 'évo');
    await tester.pumpAndSettle();
    await _tap(tester, 'pokedex-entry-eevee');
    snapshot.value = _snapshot(phase: RuntimePlayerPhase.title);
    await tester.pumpAndSettle();
    snapshot.value = _snapshot(revision: 3);
    await tester.pumpAndSettle();
    final search =
        tester.widget<TextField>(find.byKey(const ValueKey('pokedex-search')));
    expect(search.controller!.text, isEmpty);
    final first = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')));
    expect(first.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('borrowed navigation remains usable after the router disposes',
      (tester) async {
    final snapshot = ValueNotifier(_snapshot());
    addTearDown(snapshot.dispose);
    final navigation = RuntimePlayerPokedexNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, snapshot, navigation: navigation);
    await _tap(tester, 'pokedex-entry-eevee');
    expect(navigation.selectedEntryId, 'eevee');
    expect(navigation.back(), isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    var notifications = 0;
    navigation.addListener(() => notifications++);
    navigation.clearForNewSession();
    expect(notifications, 1);
    expect(navigation.selectedEntryId, isNull);
    expect(navigation.back(), isFalse);
    expect(tester.takeException(), isNull);
  });
}

String _returnKey(ProjectPauseMenuStyle style) =>
    style == ProjectPauseMenuStyle.nightIllustrated
        ? 'pause-frame-return-surface'
        : 'runtime-pause-detail-return';

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key), skipOffstage: false);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

RuntimePlayerSnapshot _snapshot({
  int revision = 1,
  RuntimePlayerPhase phase = RuntimePlayerPhase.paused,
  RuntimePlayerPauseSection section = RuntimePlayerPauseSection.pokedex,
  bool eeveeCaught = false,
}) =>
    RuntimePlayerSnapshot(
        revision: revision,
        phase: phase,
        gameTitle: 'Voyage',
        pauseSection: phase == RuntimePlayerPhase.title ? null : section,
        actions: const [
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
          RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openPokedex),
          RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openProfile),
          RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.returnToPauseRoot),
        ],
        pauseDetails: {
          RuntimePlayerPauseSection.pokedex: RuntimePlayerPauseDetailSnapshot(
              section: RuntimePlayerPauseSection.pokedex,
              title: 'Pokédex',
              entries: [
                RuntimePlayerDetailEntrySnapshot(
                    id: 'bulbasaur',
                    title: 'Bulbizarre',
                    pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                        nationalDex: 1,
                        knowledge: RuntimePlayerPokedexKnowledge.caught)),
                RuntimePlayerDetailEntrySnapshot(
                    id: 'eevee',
                    title: 'Évoli',
                    pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                        nationalDex: 133,
                        knowledge: eeveeCaught
                            ? RuntimePlayerPokedexKnowledge.caught
                            : RuntimePlayerPokedexKnowledge.seen)),
                RuntimePlayerDetailEntrySnapshot(
                    id: 'mew',
                    title: '???',
                    pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
                        nationalDex: 151,
                        knowledge: RuntimePlayerPokedexKnowledge.unknown)),
              ]),
          RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
              section: RuntimePlayerPauseSection.profile,
              title: 'Profil',
              profile: RuntimePlayerProfileSnapshot(
                  playerName: 'Camille',
                  currentMapId: 'port',
                  locationName: 'Port des brumes',
                  money: 1234)),
        });

Future<void> _pump(
    WidgetTester tester, ValueNotifier<RuntimePlayerSnapshot> snapshot,
    {List<RuntimePlayerAction>? actions,
    ProjectPauseMenuStyle style = ProjectPauseMenuStyle.nightIllustrated,
    RuntimePlayerPokedexNavigation? navigation}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    theme: PokeMapPlayerTheme.dark(),
    home: Scaffold(
        body: ValueListenableBuilder<RuntimePlayerSnapshot>(
            valueListenable: snapshot,
            builder: (context, value, _) => RuntimePlayerSurfaceRouter(
                snapshot: value,
                titlePresentation:
                    const RuntimePlayerTitlePresentation(author: 'Studio'),
                pausePresentation: PlayerPausePresentation(style: style),
                pokedexNavigation: navigation,
                gameSceneBuilder: (_) => const SizedBox.expand(),
                onAction: (action) async {
                  actions?.add(action);
                  if (action == RuntimePlayerAction.returnToPauseRoot) {
                    snapshot.value = value.next(
                        pauseSection: RuntimePlayerPauseSection.root);
                  }
                  return const RuntimePlayerCommandResult(
                      status: RuntimePlayerCommandStatus.accepted);
                }))),
  ));
  await tester.pumpAndSettle();
}
