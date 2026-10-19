import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor async queries calculated trainer stats through its frozen session',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'editor-trainer-stats-',
      );
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Trainer preview',
            maps: [],
            tilesets: [],
            pokemon: ProjectPokemonConfig(
              enabled: true,
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
            trainers: [
              ProjectTrainerEntry(
                id: 'alpha',
                name: 'Alpha',
                trainerClass: 'Trainer',
                team: [
                  ProjectTrainerPokemonEntry(
                    speciesId: 'test_species',
                    level: 50,
                  ),
                ],
              ),
            ],
          ).toJson(),
        ),
      );
      final species = File(
        '${root.path}/data/pokemon/species/test_species.json',
      );
      await species.parent.create(recursive: true);
      await species.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'id': 'test_species',
          'baseStats': {
            'hp': 100,
            'atk': 100,
            'def': 100,
            'spa': 100,
            'spd': 100,
            'spe': 100,
            'bst': 600,
          },
        }),
      );
      final adapter = AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      );
      final session = await adapter.open(root.path);
      addTearDown(session.close);
      final request = AuthoringQueryRequest(
        resourceKind: 'trainerPokemonStats',
        operation: AuthoringQueryOperation.get,
        ids: const ['alpha:0'],
        view: AuthoringQueryView.detail,
        fieldMask: const ['id', 'trainerId', 'stats.hp'],
      );
      final page = await session.queryAsync(request);
      expect(page['snapshotRevision'], session.snapshotRevision);
      expect(page['items'], [
        {
          'id': 'alpha:0',
          'trainerId': 'alpha',
          'stats': {'hp': 167},
        },
      ]);
      expect(adapter.diagnostics.activeOperations, 0);
      expect(
        () => session.query(request),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.async_required',
          ),
        ),
      );
      await session.close();
      await expectLater(session.queryAsync(request), throwsStateError);
    },
  );
}
