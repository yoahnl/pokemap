import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_example_project.dart';

void main() {
  test('opening an on-disk project preserves an unsaved active map and original bytes', () async {
    final root = await Directory.systemTemp.createTemp('home-real-project-');
    final session = ProjectSessionController(LocalProjectSessionAdapter());
    final opener = ProjectSessionOpenController(
      session: session,
      chooseDirectory: () async => root.path,
    );
    MapWorkspaceController? workspace;
    addTearDown(() async {
      opener.dispose();
      workspace?.dispose();
      await session.dispose();
      await root.delete(recursive: true);
    });
    await writeExampleProject(root);
    expect(await opener.open(browse: true), isTrue);
    final project = session.state.project!;
    expect(project.directoryPath, await root.resolveSymbolicLinks());
    workspace = MapWorkspaceController(project, LocalMapWorkspaceAdapter());
    await workspace.initialize();
    expect(workspace.error, isNull);
    final document = workspace.active!;
    final mapPath = workspace.project!.maps
        .firstWhere((entry) => entry.id == document.base.mapId)
        .relativePath;
    final original = await File('${root.path}/$mapPath').readAsBytes();
    document.commit(document.current.copyWith(name: 'Carte non enregistrée'));
    final draft = document.current;
    expect(document.dirty, isTrue);
    await workspace.initialize();
    await workspace.activate(
      workspace.project!.maps.firstWhere(
        (entry) => entry.id == document.base.mapId,
      ),
    );
    expect(workspace.active, same(document));
    expect(document.current, same(draft));
    expect(document.current.name, 'Carte non enregistrée');
    expect(await File('${root.path}/$mapPath').readAsBytes(), original);
    workspace.restore(redo: false);
    expect(document.current, document.base.map);
    expect(await File('${root.path}/$mapPath').readAsBytes(), original);
  });
}
