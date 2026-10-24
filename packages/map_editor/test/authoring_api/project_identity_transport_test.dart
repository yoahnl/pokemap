import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor canonical transport renames and undoes a project with CAS',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'editor-project-identity-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final project = ProjectManifest(
        name: 'Adventure',
        maps: [],
        tilesets: [],
      );
      await file.writeAsString(jsonEncode(project.toJson()));
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final revision = await mutations.readRevision(root.path);
      final before = await file.readAsBytes();
      final plan = await mutations.plan(
        root.path,
        actionId: 'project.rename',
        parameters: {'name': 'Étoile — 冒険'},
        idempotencyKey: 'editor-rename',
        expectedRevision: revision,
      );
      expect(await file.readAsBytes(), before);
      final result = await mutations.apply(
        plan,
        operationId: 'editor-rename-apply',
      );
      expect(
        jsonDecode(await file.readAsString()),
        project.copyWith(name: 'Étoile — 冒険').toJson(),
      );
      await expectLater(
        mutations.plan(
          root.path,
          actionId: 'project.rename',
          parameters: {'name': 'Outdated'},
          idempotencyKey: 'editor-stale',
          expectedRevision: revision,
        ),
        throwsA(anything),
      );
      await mutations.undo(
        root.path,
        entryId: result.receipt.receiptId,
        idempotencyKey: 'editor-rename-undo',
      );
      expect(jsonDecode(await file.readAsString()), project.toJson());
    },
  );
}
