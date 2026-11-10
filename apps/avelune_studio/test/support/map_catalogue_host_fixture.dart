import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';

import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'project_creation_workspace_fixture.dart';
import 'real_test_io.dart';
import 'synthetic_template_fixture.dart';

class MapCatalogueHostFixture {
  MapCatalogueHostFixture(this.tester, this.parent, this.host);
  final WidgetTester tester;
  final Directory parent;
  final ProjectCreationWorkspaceFixture host;
  late final library = WorkspaceMapLibraryCommands(
    project: () => host.maps.project!,
    submit: ({groups, required assignments}) => organizeWorkspaceMaps(
      host.maps,
      groups: groups,
      assignments: assignments,
    ),
  );
  MapEditingViewportSession get view => host.viewport!.nativeView;

  static Future<MapCatalogueHostFixture> open(
    WidgetTester tester, {
    bool empty = false,
    Size size = const Size(1536, 1024),
    double textScale = 1,
    GlobalKey? captureKey,
  }) async {
    final parent = (await tester.runAsync(() async {
      final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await root.create(recursive: true);
      return root.createTemp('map-catalogue-fixture-');
    }))!;
    final host = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/fixture.avelunegame'),
    );
    addTearDown(() async {
      await host.dispose();
      await tester.runAsync(() async {
        if (await parent.exists()) await parent.delete(recursive: true);
      });
    });
    await host.mount(
      size: size,
      textScale: textScale,
      captureKey: captureKey,
      creationPort: workspaceProjectCreation,
    );
    if (empty) {
      final creator = await host.beginCreation(name: 'Projet vide UwU');
      await RealTestIo.run(tester, () async {
        expect(creator.next(), isTrue);
        creator.setTemplate(ProjectCreationTemplate.empty);
        expect(creator.next(), isTrue);
        creator.change(() => creator.tileSize = 16);
        expect(creator.next(), isTrue);
        await creator.loadPreview();
        await creator.chooseParent(() async => parent.path);
      });
      expect(await host.performCreation(), isTrue, reason: creator.error);
    } else {
      await host.create(
        32,
        name: 'Synthetic workspace',
        templateId: 'workspace',
      );
    }
    await host.pump();
    return MapCatalogueHostFixture(tester, parent, host);
  }

  WorkspaceMapCreation beginMapCreation({String? groupId}) =>
      WorkspaceMapCreation(host.maps, groupId: groupId);

  Future<ProjectMapEntry> createMap(String name, {String? groupId}) async {
    final operation = beginMapCreation(groupId: groupId)..name = name;
    expect(await RealTestIo.run(tester, operation.submit), isNull);
    await host.pump();
    final entry = host.maps.project!.maps.singleWhere(
      (entry) => entry.id == operation.id,
    );
    expect(host.maps.active!.base.mapId, entry.id);
    return entry;
  }

  Future<void> saveActive() async {
    final document = host.maps.active!;
    expect(
      await RealTestIo.run(tester, () => host.maps.save(document)),
      isTrue,
      reason: document.error,
    );
    await host.pump();
  }

  Future<bool> saveTarget(String id, {bool confirm = true}) async =>
      (await RealTestIo.run(
        tester,
        () => saveMapLifecycleTarget(
          controller: host.maps,
          entry: host.maps.project!.maps.singleWhere((entry) => entry.id == id),
          isActive: () => !host.maps.isDisposed,
          confirmSave: () async => confirm,
        ),
      ))!;

  Future<String?> renameMap(
    String id,
    String name, {
    bool confirmSave = true,
  }) async {
    if (!await saveTarget(id, confirm: confirmSave)) {
      return 'Target save was cancelled or refused.';
    }
    final operation = WorkspaceMapRename(
      host.maps,
      host.maps.project!.maps.singleWhere((entry) => entry.id == id),
    )..name = name;
    final problem = await RealTestIo.run(tester, operation.submit);
    await host.pump();
    return problem;
  }

  Future<ProjectMapGroup> createFolder(String name, {String? parentId}) async {
    expect(
      await RealTestIo.run(
        tester,
        () => library.createFolder(name, parentId: parentId),
      ),
      isNull,
    );
    await host.pump();
    return host.maps.project!.groups.singleWhere(
      (group) => group.id == library.lastCreatedGroupId,
    );
  }

  Future<String?> organize({
    List<ProjectMapGroup>? groups,
    required List<Map<String, Object?>> assignments,
  }) async {
    final result = await RealTestIo.run(
      tester,
      () => organizeWorkspaceMaps(
        host.maps,
        groups: groups,
        assignments: assignments,
      ),
    );
    await host.pump();
    return result;
  }

  Future<String?> moveMap(String id, String? groupId) => organize(
    assignments: [
      {'mapId': id, 'groupId': groupId},
    ],
  );

  Future<String?> updateFolder(ProjectMapGroup replacement) async {
    final problem = await RealTestIo.run(
      tester,
      () => library.updateFolder(replacement),
    );
    await host.pump();
    return problem;
  }

  Future<String?> deleteFolder(String id) async {
    final problem = await RealTestIo.run(
      tester,
      () => library.deleteFolder(id),
    );
    await host.pump();
    return problem;
  }

  Future<MapCatalogPreparation?> prepareLifecycle(
    String id,
    String action,
    Map<String, Object?> parameters, {
    bool confirmSave = true,
  }) async {
    MapCatalogPreparation? prepared;
    await RealTestIo.run(
      tester,
      () => runMapLifecycleOperation(
        controller: host.maps,
        entry: host.maps.project!.maps.singleWhere((entry) => entry.id == id),
        isActive: () => !host.maps.isDisposed,
        confirmSave: () async => confirmSave,
        operation: () async {
          prepared = await host.maps.prepareCatalog(action, parameters);
        },
      ),
    );
    await host.pump();
    return prepared;
  }

  Future<MapCatalogPreparation?> prepareDuplicate(
    String id, {
    bool confirmSave = true,
  }) {
    final entry = host.maps.project!.maps.singleWhere(
      (entry) => entry.id == id,
    );
    return prepareLifecycle(id, 'map.duplicate', {
      'sourceMapId': id,
      'name': '${entry.name} — copie',
      'groupId': entry.groupId,
    }, confirmSave: confirmSave);
  }

  Future<MapCatalogPreparation?> prepareResize(
    String id,
    GridSize size, {
    bool confirmSave = true,
  }) => prepareLifecycle(id, 'map.resize_apply', {
    'mapId': id,
    'width': size.width,
    'height': size.height,
  }, confirmSave: confirmSave);
  Future<MapCatalogPreparation?> prepareDeletion(
    String id, {
    bool confirmSave = true,
  }) => prepareLifecycle(id, 'map.delete_apply', {
    'mapId': id,
  }, confirmSave: confirmSave);

  Future<ProjectMapEntry> duplicateMap(
    String id,
    String name, {
    String? groupId,
  }) async {
    final prepared = await prepareDuplicate(id);
    final operation = WorkspaceMapDuplicate(host.maps, prepared!);
    expect(
      await RealTestIo.run(
        tester,
        () => operation.submit(
          name: name,
          groupId:
              groupId ??
              host.maps.project!.maps
                  .singleWhere((entry) => entry.id == id)
                  .groupId,
        ),
      ),
      isNull,
    );
    await host.pump();
    return host.maps.project!.maps.singleWhere(
      (entry) => entry.id == operation.createdId,
    );
  }

  Future<MapCatalogResult> apply(
    MapCatalogPreparation preparation, {
    bool confirmDestructive = false,
  }) async {
    final operation = WorkspaceMapPreparedMutation(host.maps, preparation);
    final result = (await RealTestIo.run(
      tester,
      () => operation.apply(confirmDestructive: confirmDestructive),
    ))!;
    await host.pump();
    return result;
  }

  Future<({ProjectManifest project, Map<String, MapData> maps})>
  reopen() async => (await tester.runAsync(() async {
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(
      host.session.state.project!.directoryPath,
    );
    try {
      final adapter = LocalMapWorkspaceAdapter();
      final project = await adapter.loadProject(session);
      final maps = <String, MapData>{};
      for (final entry in project.maps) {
        maps[entry.id] = (await adapter.loadMap(session, entry)).map;
      }
      return (project: project, maps: maps);
    } finally {
      await sessions.close(session);
    }
  }))!;

  Future<void> paintCollision({GridPos? cell}) async {
    view.tool = StudioMapTool.collisionPaint;
    host.maps.notify();
    await host.pump();
    final target =
        cell ??
        GridPos(
          x: host.maps.active!.current.size.width ~/ 2,
          y: host.maps.active!.current.size.height ~/ 2,
        );
    await host.viewport!.tapCell(target.x, target.y);
    await host.pump();
  }

  Future<void> preserveNativeFixture() async {
    final parent = Platform.environment['AVELUNE_UWU_NATIVE_PARENT'];
    if (parent == null) return;
    final path = (await tester.runAsync(() async {
      final root = Directory(host.session.state.project!.directoryPath);
      final target = await Directory(parent).createTemp('uwu-native-');
      await for (final source in root.list(
        recursive: true,
        followLinks: false,
      )) {
        final destination =
            '${target.path}${source.path.substring(root.path.length)}';
        if (source is Directory) {
          await Directory(destination).create(recursive: true);
        } else if (source is File) {
          await File(destination).parent.create(recursive: true);
          await source.copy(destination);
        }
      }
      return target.path;
    }))!;
    debugPrint('UWU_NATIVE_FIXTURE=$path');
  }
}
