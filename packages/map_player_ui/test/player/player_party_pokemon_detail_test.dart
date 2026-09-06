import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_party_pokemon_detail.dart';
import 'package:map_player_ui/src/player/player_pokemon_image.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('desktop detail preserves snapshot data in the reference height',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = _summary();

    await tester.pumpWidget(_host(summary, width: 840));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PlayerPartyPokemonDetail)).height, 644);
    expect(
        tester.getSize(find.byType(PlayerPokemonImage)), const Size(320, 272));
    expect(find.text('Pistache'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsOneWidget);
    expect(find.text('Niv. 12'), findsOneWidget);
    expect(find.text('Mâle'), findsOneWidget);
    expect(find.text('PLANTE'), findsOneWidget);
    expect(find.text('POISON'), findsOneWidget);
    expect(find.text('20/48'), findsOneWidget);
    for (final value in ['49', '50', '65', '66', '45']) {
      expect(find.text(value), findsOneWidget);
    }
    expect(find.text('Engrais'), findsOneWidget);
    expect(find.text('Baie Oran'), findsOneWidget);
    expect(find.text('Charge'), findsOneWidget);
    expect(find.text('Rugissement'), findsOneWidget);
    expect(find.text('PP 3/35'), findsOneWidget);
    expect(find.text('PP 18/40'), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      expect(find.byKey(ValueKey('party-detail-move-slot-$index')),
          findsOneWidget);
    }
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('large text stacks long content without constrained height',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(
      _summary(
        nickname: 'Pistache le grand voyageur des montagnes',
        ability: 'Un talent dont la description prend plusieurs lignes',
      ),
      width: 336,
      textScale: 2,
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PlayerPartyPokemonDetail)).height,
        greaterThan(644));
    final imageBottom =
        tester.getBottomLeft(find.byType(PlayerPokemonImage)).dy;
    final nameTop = tester
        .getTopLeft(find.text('Pistache le grand voyageur des montagnes'))
        .dy;
    expect(nameTop, greaterThan(imageBottom));
    await tester
        .ensureVisible(find.byKey(const ValueKey('party-detail-move-slot-3')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fainted and missing data remain truthful', (tester) async {
    await tester.pumpWidget(_host(
      _summary(
        hp: 0,
        stats: null,
        moves: const [
          RuntimePokemonMoveSummarySnapshot(moveId: 'tackle', label: 'Charge'),
        ],
      ),
      width: 760,
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('KO'), findsOneWidget);
    expect(find.text('0/48'), findsOneWidget);
    expect(find.text('PP 0/0'), findsNothing);
    expect(find.text('Charge'), findsOneWidget);
    expect(find.text('tackle'), findsNothing);
    expect(find.text('—'), findsNWidgets(9));
    expect(find.byKey(const ValueKey('pokemon-image-missing-party.one')),
        findsOneWidget);
  });
}

Widget _host(RuntimePokemonSummarySnapshot summary,
        {required double width, double textScale = 1}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: PlayerMenuThemeScope(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: PlayerPartyPokemonDetail(summary: summary),
                ),
              ),
            ),
          ),
        ),
      ),
    );

RuntimePokemonSummarySnapshot _summary({
  String nickname = 'Pistache',
  String ability = 'Engrais',
  int hp = 20,
  RuntimePokemonStatsSummarySnapshot? stats =
      const RuntimePokemonStatsSummarySnapshot(
    attack: 49,
    defense: 50,
    specialAttack: 65,
    specialDefense: 66,
    speed: 45,
  ),
  List<RuntimePokemonMoveSummarySnapshot> moves = const [
    RuntimePokemonMoveSummarySnapshot(
      moveId: 'tackle',
      label: 'Charge',
      typeId: 'normal',
      currentPp: 3,
      maxPp: 35,
    ),
    RuntimePokemonMoveSummarySnapshot(
      moveId: 'growl',
      label: 'Rugissement',
      typeId: 'normal',
      currentPp: 18,
      maxPp: 40,
    ),
  ],
}) =>
    RuntimePokemonSummarySnapshot(
      targetId: 'party.one',
      individualId: 'one',
      speciesLabel: 'Bulbizarre',
      nickname: nickname,
      level: 12,
      currentHp: hp,
      maxHp: 48,
      natureLabel: 'Hardi',
      abilityLabel: ability,
      friendship: 70,
      genderLabel: 'Mâle',
      heldItemLabel: 'Baie Oran',
      typeIds: const ['grass', 'poison'],
      stats: stats,
      moves: moves,
    );
