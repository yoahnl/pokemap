import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor transport publishes and undoes complete creation batches',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'editor-create-batch-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final projectFile = File('${directory.path}/project.json');
      final mapFile = File('${directory.path}/maps/route.json');
      await mapFile.parent.create(recursive: true);
      final map = MapData.fromJson({
        'id': 'route',
        'name': 'Route',
      'version': 'v8',
        'size': {'width': 8, 'height': 8},
        'layers': <Object>[],
      });
      final project = ProjectManifest(
        name: 'Creation batches',
        maps: [
          const ProjectMapEntry(
            id: 'route',
            name: 'Route',
            relativePath: 'maps/route.json',
          ),
        ],
        tilesets: [],
      );
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      final initialProject = await projectFile.readAsBytes();
      final initialMap = await mapFile.readAsBytes();
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final facts = [
        NarrativeFactDefinition(
          id: 'fact_first',
          label: 'First',
          defaultValue: false,
        ),
        NarrativeFactDefinition(
          id: 'fact_second',
          label: 'Second',
          defaultValue: true,
        ),
      ];
      final revision = await mutations.readRevision(directory.path);
      final factPlan = await mutations.plan(
        directory.path,
        actionId: 'fact.create_batch',
        parameters: {'facts': facts.map((value) => value.toJson()).toList()},
        idempotencyKey: 'editor-facts',
        expectedRevision: revision,
      );
      expect(await projectFile.readAsBytes(), initialProject);
      final factResult = await mutations.apply(
        factPlan,
        operationId: 'editor-facts-apply',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
        ).facts,
        facts,
      );
      final entities = [
        MapEntity.fromJson({
          'id': 'first',
          'name': 'First',
          'kind': 'npc',
          'pos': {'x': 1, 'y': 1},
        }),
        MapEntity.fromJson({
          'id': 'second',
          'name': 'Second',
          'kind': 'npc',
          'pos': {'x': 2, 'y': 1},
        }),
      ];
      final entityParameters = {
        'mapId': map.id,
        'entities': entities.map((value) => value.toJson()).toList(),
      };
      final entityPlan = await mutations.plan(
        directory.path,
        actionId: 'entity.create_batch',
        parameters: entityParameters,
        idempotencyKey: 'editor-entities',
        expectedRevision: await mutations.readRevision(directory.path),
      );
      expect(await mapFile.readAsBytes(), initialMap);
      final entityResult = await mutations.apply(
        entityPlan,
        operationId: 'editor-entities-apply',
      );
      final savedMap = await mapFile.readAsBytes();
      final savedProject = await projectFile.readAsBytes();
      expect(
        MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        ).entities.map((value) => value.id),
        ['first', 'second'],
      );
      await expectLater(
        mutations.plan(
          directory.path,
          actionId: 'entity.create_batch',
          parameters: {
            'mapId': map.id,
            'entities': [entities.first.toJson(), entities.first.toJson()],
          },
          idempotencyKey: 'editor-invalid-entities',
          expectedRevision: await mutations.readRevision(directory.path),
        ),
        throwsA(anything),
      );
      await expectLater(
        mutations.plan(
          directory.path,
          actionId: 'fact.create_batch',
          parameters: {
            'facts': [facts.first.toJson()],
          },
          idempotencyKey: 'editor-existing-fact',
          expectedRevision: await mutations.readRevision(directory.path),
        ),
        throwsA(anything),
      );
      expect(await mapFile.readAsBytes(), savedMap);
      expect(await projectFile.readAsBytes(), savedProject);
      final history = (await File(
        '${directory.path}/.pokemap/authoring/history.jsonl',
      ).readAsLines()).where((value) => value.isNotEmpty).toList();
      expect(history, hasLength(2));
      await mutations.undo(
        directory.path,
        entryId: entityResult.receipt.receiptId,
        idempotencyKey: 'editor-entities-undo',
      );
      expect(await mapFile.readAsBytes(), initialMap);
      await mutations.undo(
        directory.path,
        entryId: factResult.receipt.receiptId,
        idempotencyKey: 'editor-facts-undo',
      );
      expect(await projectFile.readAsBytes(), initialProject);
    },
  );
}
