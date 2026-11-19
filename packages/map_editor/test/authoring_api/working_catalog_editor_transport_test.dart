import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'the editor partitions an existing project and edits its catalog after reopening',
    () async {
      final root = await Directory.systemTemp.createTemp('editor-partition-');
      addTearDown(() => root.delete(recursive: true));
      final manifest = File('${root.path}/project.json');
      const project = ProjectManifest(
        name: 'Johto',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'trees',
            name: 'Trees',
            relativePath: 'assets/trees.png',
          ),
        ],
      );
      await manifest.writeAsString(jsonEncode(project.toJson()));
      final before = await manifest.readAsBytes();
      const reader = EditorProjectFileReader();
      final path = await reader.canonicalizeDirectory(root.path);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final edits = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(edits.closeAll);
      await queries.retainOnly(path);
      await edits.retainOnly(path);
      final partition = await edits.plan(
        path,
        actionId: 'project.catalog.partition',
        parameters: {},
        idempotencyKey: 'partition',
      );
      expect(partition.preview['requiresReopen'], isTrue);
      expect(await manifest.readAsBytes(), before);
      final result = await edits.apply(partition, operationId: 'partition');
      expect(result.receipt.actionId, 'project.catalog.partition');
      await edits.closeProject(path);
      await queries.closeProject(path);
      final descriptor = await manifest.readAsBytes();
      expect(descriptor, isNot(before));
      final head = File('${root.path}/catalog/HEAD.json');
      final beforeEdit = await head.readAsBytes();
      final update = await edits.plan(
        path,
        actionId: 'catalog.definition.update',
        parameters: {
          'resourceKind': 'tileset',
          'id': 'trees',
          'name': 'Arbres',
        },
        idempotencyKey: 'label',
      );
      expect(await head.readAsBytes(), beforeEdit);
      final saved = await edits.apply(update, operationId: 'label');
      expect(saved.receipt.actionId, 'catalog.definition.update');
      expect(saved.snapshotRevision, isNotNull);
      final afterEdit = await head.readAsBytes();
      expect(afterEdit, isNot(beforeEdit));
      await expectLater(
        edits.plan(
          path,
          actionId: 'catalog.definition.update',
          parameters: {
            'resourceKind': 'tileset',
            'id': 'trees',
            'name': 'Ancien',
          },
          expectedRevision: update.snapshotRevision,
          idempotencyKey: 'stale-label',
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (e) => e.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(await head.readAsBytes(), afterEdit);
      expect(await manifest.readAsBytes(), descriptor);
      await edits.closeProject(path);
      await queries.closeProject(path);
      final reopened = await queries.open(path);
      final tiles = await reopened.queryAsync(
        AuthoringQueryRequest(
          resourceKind: 'tileset',
          operation: AuthoringQueryOperation.get,
          ids: ['trees'],
        ),
      );
      final item = (tiles['items'] as List).single as Map;
      expect(item['name'], 'Arbres');
      expect(item['id'], 'trees');
    },
  );
}
