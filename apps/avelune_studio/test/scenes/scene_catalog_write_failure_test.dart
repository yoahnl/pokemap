import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/catalog_write_failure.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../project_session/interrupted_save_fixture.dart';
import 'scene_focus_catalog_fixture.dart';

SceneAsset _renamed(SceneAsset scene, String name) =>
    SceneAsset(id: scene.id, name: name, graph: scene.graph);

void main() {
  test(
    'a save refused by a read-only catalog is readable and retryable',
    () async {
      final session = await openSceneFocusCatalog(unrelated: 0);
      final root = session.directoryPath;
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(session);
      final scenes = LocalSceneAdapter(session: session, mapAdapter: maps);
      final first = _renamed(focusGate, 'Porte une');
      await scenes.publishScene(base: focusGate, current: first);
      final head = File('$root/catalog/HEAD.json');
      final headBefore = await head.readAsBytes();
      final second = _renamed(focusGate, 'Porte deux');

      await setCatalogWritable(root, writable: false);
      Object? failure;
      try {
        await scenes.publishScene(base: first, current: second);
      } on Object catch (error) {
        failure = error;
      }
      expect(failure, isA<SceneFailure>());
      expect((failure! as SceneFailure).message, catalogNotWritableMessage);
      expect('$failure', isNot(contains('Exception')));
      expect(await head.readAsBytes(), headBefore);
      expect(
        Directory('$root/.pokemap/authoring/transactions')
            .listSync()
            .whereType<Directory>(),
        isEmpty,
      );

      await setCatalogWritable(root, writable: true);
      final saved = await scenes.publishScene(base: first, current: second);
      expect(saved.scene.name, 'Porte deux');
      final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
      expect(
        reopened.scenes.singleWhere((scene) => scene.id == focusGate.id).name,
        'Porte deux',
      );
    },
  );

  test('a pending earlier save is reported without raw codes', () async {
    final session = await openSceneFocusCatalog(unrelated: 0);
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadProject(session);
    await leaveInterruptedSceneSave(
      session.directoryPath,
      _renamed(focusGate, 'Porte inachevée'),
      operationId: 'interrupted_scene',
    );
    Object? failure;
    try {
      await LocalSceneAdapter(
        session: session,
        mapAdapter: maps,
      ).publishScene(base: focusGate, current: _renamed(focusGate, 'Autre'));
    } on Object catch (error) {
      failure = error;
    }
    expect(failure, isA<SceneFailure>());
    expect((failure! as SceneFailure).message, catalogUnfinishedSaveMessage);
  });
}
