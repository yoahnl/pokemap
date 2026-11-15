import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../scenes/scene_focus_catalog_fixture.dart';
import 'interrupted_save_fixture.dart';

SceneAsset _renamed(String name) =>
    SceneAsset(id: focusGate.id, name: name, graph: focusGate.graph);

void main() {
  test('opening applies an interrupted save before maps load', () async {
    final root = (await openSceneFocusCatalog(unrelated: 0)).directoryPath;
    await leaveInterruptedSceneSave(
      root,
      _renamed('Porte reprise'),
      operationId: 'interrupted_open',
    );

    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(root);
    addTearDown(() => sessions.close(session));

    expect(session.storage, ProjectSessionStorage.workingCatalog);
    final project = await LocalMapWorkspaceAdapter().loadProject(session);
    expect(project.maps.map((map) => map.id), containsAll(['town', 'cave']));
    expect(
      project.scenes.singleWhere((scene) => scene.id == focusGate.id).name,
      'Porte reprise',
    );
    expect(
      await Directory('$root/.pokemap/authoring/transactions/interrupted_open')
          .exists(),
      isFalse,
    );
  });

  test(
    'a resume that cannot write blocks opening, then succeeds on retry',
    () async {
      final root = (await openSceneFocusCatalog(unrelated: 0)).directoryPath;
      await leaveInterruptedSceneSave(
        root,
        _renamed('Porte bloquée'),
        operationId: 'interrupted_blocked',
      );
      final head = File('$root/catalog/HEAD.json');
      final headBefore = await head.readAsBytes();
      await setCatalogWritable(root, writable: false);

      final sessions = LocalProjectSessionAdapter();
      await expectLater(
        sessions.open(root),
        throwsA(
          isA<ProjectOpenFailure>().having(
            (failure) => failure.problem,
            'problem',
            ProjectOpenProblem.recoveryFailed,
          ),
        ),
      );
      expect(await head.readAsBytes(), headBefore);

      await setCatalogWritable(root, writable: true);
      final session = await sessions.open(root);
      addTearDown(() => sessions.close(session));
      final project = await LocalMapWorkspaceAdapter().loadProject(session);
      expect(
        project.scenes.singleWhere((scene) => scene.id == focusGate.id).name,
        'Porte bloquée',
      );
    },
  );
}
