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
      expect(find.text('Charge'), findsOneWidget);
      expect(find.text('PP 30/35'), findsOneWidget);
      expect(find.text('Capturé'), findsOneWidget);
      expect(find.text('Route Hanazuki'), findsOneWidget);
      expect(find.text('49'), findsWidgets);
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
    currentHp: 20,
    maxHp: 48,
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
