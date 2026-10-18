import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/encounter_table_persistence_gateway.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test('Editor gateway persists two independent project transition catalogues with CAS', () async {
    for (final id in ['aurora', 'clockwork']) {
      final root = await Directory.systemTemp.createTemp('editor-transition-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final project = ProjectManifest(name: id, maps: [], tilesets: []);
      await file.writeAsString(jsonEncode(project.toJson()));
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(fileReader: reader, queries: queries, projectRoots: reader);
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final gateway = CanonicalEncounterTablePersistenceGateway(mutations: mutations, queries: queries);
      final definition = BattleTransitionDefinition.fromJson({
        'id': id, 'label': 'Entry $id', 'usages': ['wild', 'trainer'],
        'phases': [
          {'kind': 'flash', 'durationSeconds': 0.2, 'factor': 2},
          {'kind': 'fadeToBlack', 'durationSeconds': 0.4},
          {'kind': 'holdBlack', 'durationSeconds': 0.1},
        ],
      });
      final updated = await gateway.updateBattleTransitionDefaults(
          projectRootPath: root.path, expectedProject: project,
          definitions: [definition], wildTransitionId: id, trainerTransitionId: id);
      expect(updated.battleTransitions!.definitions.single, definition);
      final saved = ProjectManifest.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      expect(saved, updated);
      final bytes = await file.readAsBytes();
      await expectLater(gateway.updateBattleTransitionDefaults(
          projectRootPath: root.path, expectedProject: project,
          wildTransitionId: ''), throwsA(anything));
      expect(await file.readAsBytes(), bytes);
    }
  });
}
