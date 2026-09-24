import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/pokemon_moves_projection.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_move_emblem.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/theme/studio_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show GamePackageExportProfile, GamePackageExportProfileStore;
import 'package:map_core/map_core.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';

void main() {
  const catalog = PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(description: ''),
    entries: [
      {
        'id': 'growl',
        'name': 'Growl',
        'source': 'golden_item_system',
        'type': 'normal',
        'category': 'status',
      },
      {
        'id': 'custom-growl',
        'name': 'My Growl',
        'names': {'fr': 'Mon Cri'},
        'source': 'project_custom',
        'type': 'grass',
        'category': 'special',
        'power': 100,
      },
    ],
  );

  test(
    'project locale selects official and authored names without changing IDs',
    () {
      final french = projectPokemonMoves(catalog, 'moves.json', 'fr-FR');
      final english = projectPokemonMoves(catalog, 'moves.json', 'en');
      expect(french.entries.first.id, 'custom-growl');
      expect(french.entries.first.name, 'Mon Cri');
      expect(french.entries.first.userCreated, isTrue);
      expect(french.entries.last.id, 'growl');
      expect(french.entries.last.name, 'Rugissement');
      expect(french.entries.last.userCreated, isFalse);
      expect(english.entries.first.name, 'Growl');
      expect(english.entries.last.name, 'My Growl');
    },
  );

  testWidgets(
    'type, category, power and personal origin have distinct emblems',
    (tester) async {
      final entries = projectPokemonMoves(catalog, 'moves.json', 'fr').entries;
      const low = PokemonMoveSummary(
        id: 'weak-water',
        name: 'Eau faible',
        type: 'water',
        category: 'physical',
        power: 20,
      );
      const high = PokemonMoveSummary(
        id: 'strong-water',
        name: 'Eau forte',
        type: 'water',
        category: 'physical',
        power: 120,
      );
      const special = PokemonMoveSummary(
        id: 'special-water',
        name: 'Eau spéciale',
        type: 'water',
        category: 'special',
        power: 120,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Row(
              children: [
                for (final move in [entries.first, low, high, special])
                  PokemonMoveEmblem(key: ValueKey(move.id), move: move),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('weak-water')),
          matching: find.byIcon(Icons.sports_martial_arts),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('special-water')),
          matching: find.byIcon(Icons.auto_awesome),
        ),
        findsOneWidget,
      );
      expect(pokemonMoveTypeIcon('grass'), isNot(pokemonMoveTypeIcon('water')));
      expect(
        pokemonMoveCategoryIcon('physical'),
        isNot(pokemonMoveCategoryIcon('special')),
      );
      expect(
        StudioPokemonTypeColors.forType('grass', Colors.black),
        isNot(StudioPokemonTypeColors.forType('water', Colors.black)),
      );
      final lowGradient = _gradient(tester, 'weak-water');
      final highGradient = _gradient(tester, 'strong-water');
      expect(lowGradient.colors.last, isNot(highGradient.colors.last));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the real Pokémon workspace uses the game export locale', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: _prepareFrenchMoves,
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    final page = tester.widget<PokemonWorkspacePage>(
      find.byType(PokemonWorkspacePage),
    );
    final names = {
      for (final move in page.controller!.index!.moves.entries)
        move.id: move.name,
    };
    expect(find.byKey(const ValueKey('move-growl')), findsOneWidget);
    expect(find.text('Rugissement'), findsOneWidget);
    expect(names['leech-seed'], 'Vampigraine');
    expect(names['protect'], 'Abri');
    expect(names['tackle'], 'Charge');
    expect(find.text('Growl'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

LinearGradient _gradient(WidgetTester tester, String id) {
  final decoration = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (decoration.decoration as BoxDecoration).gradient! as LinearGradient;
}

Future<void> _prepareFrenchMoves(M3StoryFixture source) async {
  final moves = File(
    '${source.directory.path}/data/pokemon/catalogs/moves.json',
  );
  await moves.parent.create(recursive: true);
  await File(
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json',
  ).copy(moves.path);
  await GamePackageExportProfileStore(projectRoot: source.directory).save(
    GamePackageExportProfile(
      gameId: 'pokemon.move.locale.test',
      gameVersion: '1.0.0',
      title: 'Test des attaques',
      authorName: 'Test',
      defaultLocale: 'fr',
      supportedLocales: ['fr', 'en'],
    ),
  );
}
