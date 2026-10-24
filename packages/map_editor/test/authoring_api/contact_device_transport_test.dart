import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor canonical transport configures and undoes a contact device with CAS',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'editor-contact-device-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final project = ProjectManifest(
        name: 'Adventure',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: [],
        tilesets: [],
        facts: [NarrativeFactDefinition(id: 'owned', label: 'Device')],
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
        actionId: 'contact_device.configure',
        parameters: {
          'configuration': {
            'id': 'device',
            'label': 'Carnet',
            'acquiredFactId': 'owned',
            'emptyMessage': 'Aucun contact.',
            'contacts': [],
          },
        },
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
        project
            .copyWith(
              contactDevice: ProjectContactDeviceConfig(
                id: 'device',
                label: 'Carnet',
                acquiredFactId: 'owned',
                emptyMessage: 'Aucun contact.',
                contacts: [],
              ),
            )
            .toJson(),
      );
      await expectLater(
        mutations.plan(
          root.path,
          actionId: 'contact_device.configure',
          parameters: {'configuration': null},
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
