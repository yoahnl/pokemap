import 'dart:io';

import 'package:avelune_studio/features/project_session/data/local_project_history_maintenance_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_history_maintenance.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('Studio maintenance keeps current data and refuses an obsolete preview', () async {
    final qa = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ??
          '${Platform.environment['HOME']}/Library/Caches/AveluneQA/studio-project-lifecycle',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('maintenance-studio-adapter-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'studio-maintenance',
      project: ProjectManifest(
        name: 'Studio maintenance',
        maps: const [
          ProjectMapEntry(
            id: 'missing',
            name: 'Missing',
            relativePath: 'maps/missing.json',
          ),
        ],
        tilesets: const [],
      ),
    );
    final session = ProjectSession(
      sessionId: 'studio-session',
      name: 'Studio maintenance',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final adapter = LocalProjectHistoryMaintenanceAdapter();
    final proposed = await adapter.preview(session);
    final editing = await CatalogEditingSession.open(
      store: store,
      projectId: 'studio-maintenance',
      actorId: 'local_cli',
      incrementalHistory: true,
    );
    try {
      await editing.apply(
        await editing.planPatch(
          upserts: [
            CatalogDefinitionUnit(
              key: CatalogDefinitionKey(
                CatalogDefinitionKind.tileset,
                'selected',
              ),
              payload: {'name': 'Saved'},
            ),
          ],
          idempotencyKey: 'save',
        ),
      );
    } finally {
      await editing.close();
    }
    final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
      adapter.apply(session, proposed),
      throwsA(isA<ProjectHistoryMaintenanceFailure>()),
    );
    final current = await adapter.preview(session);
    expect(current.retainedOperations, 1);
    final result = await adapter.apply(session, current);
    expect(result.deletedObjects, greaterThanOrEqualTo(0));
    expect(await File('${root.path}/catalog/HEAD.json').readAsBytes(), head);
    expect(await File('${root.path}/maps/missing.json').exists(), isFalse);
  });
}
