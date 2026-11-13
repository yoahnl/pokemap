import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;

void main() {
  late Directory directory;
  late ProjectSession session;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_decor_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Parcours de décors',
      directoryPath: directory.path,
    );
  });
  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<MapWorkspaceController> openWorkspace() async {
    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    await workspace.initialize();
    await workspace.activate(
      workspace.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
    return workspace;
  }

  test('decors placed, moved, duplicated and removed survive a disk save and cold reopen', () async {
    final workspace = await openWorkspace();
    addTearDown(workspace.dispose);
    final document = workspace.active!;
    final project = workspace.project!;
    final commands = MapEditingCommands(document, project);
    ProjectElementEntry element(String id) =>
        project.elements.singleWhere((entry) => entry.id == id);

    final authored = document.current.placedElements
        .singleWhere((placed) => placed.id == 'jardin-rocher')
        .copyWith(
          pixelOffset: const PixelOffset(x: 3, y: 2),
          quarterTurns: 1,
          applyCollision: false,
          opacity: .5,
          properties: const {
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
            'note': 'garder',
          },
        );
    document.commit(
      upsertMapPlacedElement(document.current, instance: authored),
    );

    final placed = commands.place(
      element('caisse'),
      const GridPos(x: 2, y: 2),
    )!;
    commands.move(placed, const GridPos(x: 3, y: 2));
    final copy = commands.clone(authored.id)!;
    final duplicated = document.current.placedElements.singleWhere(
      (instance) => instance.id == copy,
    );
    expect(
      duplicated,
      authored.copyWith(id: copy, visualOrder: duplicated.visualOrder),
    );
    document.selectedId = placed;
    commands.deleteSelected();
    expect(
      document.current.placedElements.map((instance) => instance.id),
      isNot(contains(placed)),
    );

    final beforeRefusal = document.current;
    expect(
      commands.place(element('arbre'), const GridPos(x: 23, y: 15)),
      isNull,
    );
    expect(document.error, isNotNull);
    expect(document.current, same(beforeRefusal));
    document.error = null;

    expect(await workspace.save(document), isTrue, reason: workspace.error);
    final reopened = await openWorkspace();
    addTearDown(reopened.dispose);
    final restored = reopened.active!.current;
    expect(restored.placedElements, document.current.placedElements);
    expect(
      restored.placedElements.map((instance) => instance.id),
      isNot(contains(placed)),
    );
    expect(
      restored.placedElements.singleWhere((instance) => instance.id == copy),
      duplicated,
    );
  });
}
