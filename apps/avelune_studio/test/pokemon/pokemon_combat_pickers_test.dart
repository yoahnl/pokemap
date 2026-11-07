import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_species_picker.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PokemonSpeciesSummary _species(
  String id,
  String name,
  int dex,
  List<String> types, {
  bool enabled = true,
}) => PokemonSpeciesSummary(
  id: id,
  name: name,
  nationalDex: dex,
  generation: 1,
  types: types,
  formIds: const [],
  mediaRelativePath: '',
  enabled: enabled,
  relativePath: 'data/pokemon/$id.json',
);

final _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    _species('pikachu', 'Pikachu', 25, ['electric']),
    _species('onix', 'Onix', 95, ['rock', 'ground']),
    _species('missingno', 'MissingNo', 0, const [], enabled: false),
  ],
  moves: const PokemonMovesCatalogView(
    relativePath: 'data/moves.json',
    entries: [
      PokemonMoveSummary(
        id: 'thunderbolt',
        name: 'Tonnerre',
        type: 'electric',
        category: 'special',
        power: 90,
        accuracy: '100',
      ),
      PokemonMoveSummary(
        id: 'growl',
        name: 'Rugissement',
        type: 'normal',
        category: 'status',
        accuracy: '100',
      ),
      PokemonMoveSummary(
        id: 'rock-throw',
        name: 'Jet-Pierres',
        type: 'rock',
        category: 'physical',
        power: 50,
        accuracy: '90',
      ),
    ],
  ),
  types: const [],
  items: const {},
);

void main() {
  Future<List<String?>> open(
    WidgetTester tester,
    Future<String?> Function(BuildContext context) choose,
  ) async {
    final chosen = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => chosen.add(await choose(context)),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    return chosen;
  }

  test('species and moves describe themselves with useful details', () {
    expect(
      combatSpeciesDetails(_index.entries[1]),
      'n° 095 · Roche / Sol · Génération 1',
    );
    expect(
      combatMoveDetails(_index.moves.entries.first),
      'Électrik · Spéciale · Puissance 90 · Précision 100',
    );
    expect(
      combatMoveDetails(_index.moves.entries[1]),
      'Normal · Statut · Sans puissance · Précision 100',
    );
  });

  testWidgets('a species is searched by type and chosen with its details', (
    tester,
  ) async {
    final chosen = await open(
      tester,
      (context) => chooseCombatSpecies(context, _index),
    );
    expect(find.text('2 sur 2'), findsOneWidget);
    expect(find.text('MissingNo'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('combat-choice-search')),
      'roche',
    );
    await tester.pump();
    expect(find.text('1 sur 2'), findsOneWidget);
    expect(find.text('n° 095 · Roche / Sol · Génération 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('combat-choice-onix')));
    await tester.pumpAndSettle();
    expect(chosen, ['onix']);
  });

  testWidgets('a move already known is not offered again', (tester) async {
    final chosen = await open(
      tester,
      (context) =>
          chooseCombatMove(context, _index, exclude: const ['thunderbolt']),
    );
    expect(find.text('2 sur 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('combat-choice-thunderbolt')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const ValueKey('combat-choice-search')),
      'physique',
    );
    await tester.pump();
    expect(find.text('Jet-Pierres'), findsOneWidget);
    expect(find.text('Rugissement'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('combat-choice-rock-throw')));
    await tester.pumpAndSettle();
    expect(chosen, ['rock-throw']);
  });

  testWidgets('cancelling a choice changes nothing', (tester) async {
    final chosen = await open(
      tester,
      (context) => chooseCombatMove(context, _index),
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(chosen, [null]);
  });
}
