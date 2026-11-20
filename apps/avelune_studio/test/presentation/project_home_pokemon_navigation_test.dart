import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_design_system/avelune_design_system.dart';

import '../support/controlled_project_session_port.dart';
import 'map_builder_shell_harness.dart';

void main() {
  testWidgets('the project can be reopened directly from the home screen', (
    tester,
  ) async {
    await openShell(tester);
    await tester.tap(find.byKey(const ValueKey('studio-rail-home')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('studio-project-home-close')));
    await settle(tester);
    await tester.tap(
      find.byKey(ValueKey(('studio-home-recent', exampleA.directoryPath))),
    );
    await tester.pump();

    expect(picked, 1);
    expect(sessions.requests, [exampleA.directoryPath, exampleA.directoryPath]);
    sessions.pending.last.complete(exampleA);
    await settle(tester);
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
  });

  testWidgets('the Pokémon rail loads the project catalogue on first opening', (
    tester,
  ) async {
    final pokemon = _PokemonPort(enabled: true);
    await openShell(tester, pokemon: pokemon);
    expect(pokemon.loads, 0);

    await tester.tap(find.byKey(const ValueKey('studio-rail-pokemon')));
    await settle(tester);
    expect(
      find.byKey(const ValueKey('studio-project-pokemon')),
      findsOneWidget,
    );
    expect(find.text('Bulbizarre'), findsOneWidget);
    await tester.tap(find.text('Bulbizarre'));
    await settle(tester);
    expect(find.text('#1 · Génération 1'), findsOneWidget);
    expect(find.text('PLANTE · POISON'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
    await settle(tester);
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    expect(sessions.released, isEmpty);

    await tester.tap(find.byKey(const ValueKey('studio-rail-pokemon')));
    await settle(tester);
    expect(pokemon.loads, 1);
    expect(find.text('#1 · Génération 1'), findsOneWidget);
  });

  testWidgets('a project with Pokémon disabled still has a Pokémon page', (
    tester,
  ) async {
    await openShell(tester, pokemon: _PokemonPort(enabled: false));
    await tester.tap(find.byKey(const ValueKey('studio-rail-pokemon')));
    await settle(tester);
    expect(find.text('Pokémon est désactivé dans ce projet.'), findsOneWidget);
    expect(find.text('Importer une espèce'), findsNothing);
  });

  testWidgets(
    'species import requires confirmation and retains existing data',
    (tester) async {
      final pokemon = _PokemonPort(enabled: true);
      await openShell(tester, pokemon: pokemon);
      await tester.tap(find.byKey(const ValueKey('studio-rail-pokemon')));
      await settle(tester);
      await tester.tap(find.text('Importer une espèce'));
      await tester.pumpAndSettle();
      final search = find.widgetWithText(
        StudioSearchField,
        'Nom ou numéro du Pokédex',
      );
      await tester.enterText(
        find.descendant(of: search, matching: find.byType(TextField)),
        'bulb',
      );
      await tester.pump();
      await tester.tap(find.text('Rechercher'));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Bulbizarre'),
        ),
      );
      await settle(tester);
      expect(pokemon.appliedPolicy, isNull);
      expect(
        find.text('Les documents déjà présents seront conservés.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirmer l’import'));
      await settle(tester);
      expect(pokemon.appliedPolicy, PokemonExternalConflictPolicy.skipExisting);
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      expect(pokemon.loads, 2);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}

class _PokemonPort implements PokemonWorkspacePort {
  _PokemonPort({required this.enabled});

  final bool enabled;
  var loads = 0;
  PokemonExternalConflictPolicy? appliedPolicy;

  @override
  Future<PokemonExternalSearch> searchExternal(String query) async =>
      const PokemonExternalSearch(
        suggestions: [
          PokemonExternalSuggestion(
            id: 'bulbasaur',
            name: 'Bulbizarre',
            nationalDex: 1,
            generation: 1,
          ),
        ],
      );

  @override
  Future<PokemonExternalImportPreview> previewExternal(
    String speciesId,
  ) async => PokemonExternalImportPreview(
    speciesId: speciesId,
    name: 'Bulbizarre',
    projectRevision: 'revision',
    inventorySignature: 'inventory',
    documents: const [
      PokemonExternalDocument(
        family: PokemonDocumentFamily.species,
        relativePath: 'bulbasaur.json',
        beforeBytes: [123, 125],
        document: {'id': 'bulbasaur'},
      ),
    ],
    warnings: const [],
  );

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) async {
    appliedPolicy = policy;
    return PokemonExternalImportResult(
      speciesId: preview.speciesId,
      created: 0,
      overwritten: 0,
      skipped: 1,
      warnings: const [],
    );
  }

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async {
    loads++;
    return PokemonWorkspaceIndex(
      enabled: enabled,
      entries: enabled
          ? const [
              PokemonSpeciesSummary(
                id: 'bulbasaur',
                name: 'Bulbizarre',
                nationalDex: 1,
                generation: 1,
                types: ['grass', 'poison'],
                formIds: [],
                mediaRelativePath: '',
                enabled: true,
                relativePath: 'bulbasaur.json',
              ),
            ]
          : const [],
      moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
      types: const [],
      items: const {},
    );
  }

  @override
  Future<Never?> loadThumbnail(PokemonSpeciesSummary entry) async => null;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
