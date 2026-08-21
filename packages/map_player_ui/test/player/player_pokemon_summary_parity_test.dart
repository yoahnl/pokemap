import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('BETA-PTY-001 Party and PC render one shared sheet', () {
    testWidgets('the same summary renders identical text on both surfaces',
        (tester) async {
      final summary = _summary();

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: summary,
        surfaceRole: ProjectPresentationSurfaceRole.party,
      )));
      final fromParty = _visibleText(tester);

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: summary,
        surfaceRole: ProjectPresentationSurfaceRole.pokedex,
      )));
      final fromPc = _visibleText(tester);

      expect(
        fromParty,
        fromPc,
        reason: 'the surface role themes the panel, never the content',
      );
    });

    testWidgets('the sheet shows the localized species, never the raw id',
        (tester) async {
      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(),
      )));

      expect(find.text('Bulbizarre'), findsWidgets);
      expect(find.text('bulbasaur'), findsNothing);
      expect(find.text('Bulbasaur'), findsNothing);
    });

    testWidgets('every canonical field reaches the screen', (tester) async {
      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(),
      )));

      expect(find.text('Niv. 12'), findsOneWidget);
      expect(find.text('20/48'), findsWidgets);
      expect(find.text('Hardy'), findsOneWidget);
      expect(find.text('Overgrow'), findsOneWidget);
      expect(find.text('Mâle'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Baie Oran'), findsOneWidget);
      expect(find.text('70/255'), findsOneWidget);
      // The move type used to be carried by the snapshot and dropped on the
      // floor while this very test claimed every canonical field reached the
      // screen, so the type now travels with the move label.
      expect(find.text('Charge · Normal'), findsOneWidget);
      expect(find.text('PP 30/35'), findsOneWidget);
      expect(find.text('Capturé'), findsOneWidget);
      expect(find.text('Route Hanazuki'), findsOneWidget);
      expect(find.text('Tall Grass'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('Poke Ball'), findsOneWidget);
      expect(find.text('49'), findsWidgets);
    });

    testWidgets('the HP gauge carries the same threshold as the battle HUD',
        (tester) async {
      Color gaugeColorFor({required int currentHp, required int maxHp}) {
        return tester
                .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .color ??
            const Color(0x00000000);
      }

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(currentHp: 44, maxHp: 48),
      )));
      final healthy = gaugeColorFor(currentHp: 44, maxHp: 48);

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(currentHp: 20, maxHp: 48),
      )));
      final warning = gaugeColorFor(currentHp: 20, maxHp: 48);

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(currentHp: 4, maxHp: 48),
      )));
      final danger = gaugeColorFor(currentHp: 4, maxHp: 48);

      expect(
        <Color>{healthy, warning, danger},
        hasLength(3),
        reason: 'a Pokémon at 20/48 must not look as healthy as one at 44/48, '
            'and one at 4/48 must not look like either',
      );
      expect(playerHpToneFor(44 / 48), PlayerHpTone.healthy);
      expect(playerHpToneFor(20 / 48), PlayerHpTone.warning);
      expect(playerHpToneFor(4 / 48), PlayerHpTone.danger);
    });

    testWidgets('the gauge track never reads as a full bar', (tester) async {
      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(currentHp: 20, maxHp: 48),
      )));
      final gauge = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(
        gauge.backgroundColor,
        isNotNull,
        reason: 'without an explicit neutral track the theme painted a '
            'saturated green behind the fill, so a damaged Pokémon looked '
            'untouched',
      );
      expect(gauge.value, closeTo(20 / 48, 0.0001));
    });

    testWidgets('a move without PP tracking shows a dash, never zero',
        (tester) async {
      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(
          moves: <RuntimePokemonMoveSummarySnapshot>[
            const RuntimePokemonMoveSummarySnapshot(
              moveId: 'tackle',
              label: 'Charge',
            ),
          ],
        ),
      )));

      expect(find.text('—'), findsOneWidget);
      expect(find.text('PP 0/0'), findsNothing);
    });

    testWidgets('a summary without stats hides the stats block entirely',
        (tester) async {
      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(stats: null),
      )));

      expect(find.text('Statistiques'), findsNothing);
      expect(find.text('Capacités'), findsOneWidget);
    });

    testWidgets('the sheet survives a narrow portrait viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(PlayerPokemonSummarySheet(
        summary: _summary(),
      )));

      expect(tester.takeException(), isNull);
      expect(find.text('Bulbizarre'), findsWidgets);
    });
  });
}

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Set<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .where((value) => value.isNotEmpty)
    .toSet();

RuntimePokemonSummarySnapshot _summary({
  int currentHp = 20,
  int maxHp = 48,
  RuntimePokemonStatsSummarySnapshot? stats =
      const RuntimePokemonStatsSummarySnapshot(
    attack: 49,
    defense: 49,
    specialAttack: 65,
    specialDefense: 65,
    speed: 45,
  ),
  List<RuntimePokemonMoveSummarySnapshot> moves =
      const <RuntimePokemonMoveSummarySnapshot>[
    RuntimePokemonMoveSummarySnapshot(
      moveId: 'tackle',
      label: 'Charge',
      typeLabel: 'Normal',
      currentPp: 30,
      maxPp: 35,
    ),
  ],
}) {
  return RuntimePokemonSummarySnapshot(
    targetId: 'pokemon.indiv-1',
    individualId: 'indiv-1',
    speciesLabel: 'Bulbizarre',
    nickname: '',
    level: 12,
    experience: 120,
    currentHp: currentHp,
    maxHp: maxHp,
    stats: stats,
    natureLabel: 'Hardy',
    abilityLabel: 'Overgrow',
    genderLabel: 'Mâle',
    heldItemLabel: 'Baie Oran',
    friendship: 70,
    moves: moves,
    provenance: const RuntimePokemonProvenanceSummarySnapshot(
      originLabel: 'Capturé',
      metMapLabel: 'Route Hanazuki',
      metSourceLabel: 'Tall Grass',
      metLevel: 5,
      ballLabel: 'Poke Ball',
    ),
  );
}
