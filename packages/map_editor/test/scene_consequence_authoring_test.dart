import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';

void main() {
  for (final primaryFormId in ['bronze', '']) {
    test(
      'catalog gift provider gets the actual primary form from its species document $primaryFormId',
      () async {
        final source = PokemonSpeciesFile.fromJson({
          'schemaVersion': currentPokemonDataSchemaVersion,
          'id': 'clockbird',
          'forms': {
            'formId': primaryFormId,
            'otherForms': ['sunny'],
          },
        });
        final projected = PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: const PokemonSpeciesIndexEntry(
            id: 'clockbird',
            nationalDex: 1,
            primaryName: 'Clockbird',
            types: ['steel'],
            relativePath: 'species/clockbird.json',
            formIds: ['sunny', 'bronze'],
          ),
          species: source,
        );
        final container = ProviderContainer(
          overrides: [
            pokedexEntryLoaderProvider.overrideWithValue(
              (_) async => [projected],
            ),
            sceneItemDefinitionLoaderProvider.overrideWithValue(
              (_) async => [],
            ),
          ],
        );
        addTearDown(container.dispose);
        final catalogs = await container.read(
          sceneConsequenceCatalogsProvider('/project').future,
        );
        final option = catalogs.species.options.single;
        expect(option.primaryFormId, primaryFormId);
        expect(option.formIds, ['sunny', 'bronze']);
        expect(
          option.catalogGiftFormIds,
          primaryFormId.isEmpty ? isEmpty : [primaryFormId],
        );
      final pickerOptions = buildScenePokemonFormPickerOptions(catalogs.species.options);
      expect(pickerOptions.map((option) => option.id), ['sunny', 'bronze']);
      expect(pickerOptions.where((option) => option.isPrimarySpeciesForm).map((option) => option.id), primaryFormId.isEmpty ? isEmpty : [primaryFormId]);
      },
    );
  }

  test('story step consequence catalog keeps human labels and stable IDs', () {
    final catalogs = const SceneConsequenceCatalogs.unavailable()
        .withStorySteps([
          NarrativeStoryStepPickerOption(
            stepId: 'step_leave_port',
            humanLabel: 'Quitter le port',
            description: 'Objectif de départ.',
            sourceScenarioId: 'story_main',
            sourceScenarioLabel: 'Histoire principale',
            sourceKind: NarrativeStoryStepPickerSource.stepStudio,
            order: 0,
            linkedCutsceneIds: const <String>[],
            expectedOutcomeIds: const <String>[],
            emittedOutcomeIds: const <String>[],
            debugTechnicalLabel: 'story_main:chapter_port:step_leave_port',
          ),
        ]);

    expect(catalogs.storySteps.isReady, isTrue);
    expect(catalogs.storySteps.options.single.id, 'step_leave_port');
    expect(catalogs.storySteps.options.single.label, 'Quitter le port');
  });
}
