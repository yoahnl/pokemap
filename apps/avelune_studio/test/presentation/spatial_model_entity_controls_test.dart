import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_entity_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('manual binding UI persists through the real catalog controller without foreign map reads', (tester) async {
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('r29-studio-binding-')))!;
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final base = spatialEnvironmentMap();
    final instance = SpatialModelInstance(id: 'manual-tree', modelId: 'oak',
        position: Model3dVector3(x: 2.5, y: 0, z: 3.5));
    final map = base.copyWith(entities: [const MapEntity(id: 'object', name: 'Objet lié',
        kind: MapEntityKind.custom, pos: GridPos(x: 1, y: 1))],
        spatialScene: base.spatialScene!.copyWith(instances: [instance]),
        layers: [MapLayer.environment(id: 'forest', name: 'Forest',
            content: EnvironmentLayerContent(targetsSpatialTerrain: true, areas: [
              EnvironmentArea(id: 'trees', name: 'Trees', presetId: 'woodland', seed: 1,
                  mask: EnvironmentAreaMask(width: 12, height: 10, cells: List.filled(120, false)),
                  generatedPlacementIds: [instance.id], manualPlacementIds: [instance.id])]))]);
    final project = spatialEnvironmentProject().copyWith(maps: [
      const ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
      for (var i = 0; i < 80; i++) ProjectMapEntry(id: 'foreign-$i', name: 'Foreign',
          relativePath: 'maps/foreign-$i.json')]);
    final session = ProjectSession(sessionId: root.path, name: project.name,
        directoryPath: root.path, storage: ProjectSessionStorage.workingCatalog);
    final reader = _BindingReader();
    late MapWorkspaceController controller;
    await tester.runAsync(() async {
      controller = MapWorkspaceController(session, LocalMapWorkspaceAdapter(reader: reader));
      addTearDown(controller.dispose);
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(store: store, projectId: 'manual-binding', project: project);
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/a.json').writeAsString(jsonEncode(map.toJson()));
      for (var i = 0; i < 80; i++) {
        await File('${root.path}/maps/foreign-$i.json').writeAsString('foreign map must remain unread');
      }
      final history = File('${root.path}/.pokemap/authoring/history.jsonl');
      await history.parent.create(recursive: true);
      await history.writeAsString('foreign history must remain unread\n' * 81);
      await controller.initialize();
      expect(controller.error, isNull);
    });
    final document = controller.active!;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
        builder: (context, refresh) => SpatialModelEntityControls(document: document,
            project: controller.project!, instance: document.current.spatialScene!.instances.single,
            onChanged: () => refresh(() {}))))));
    reader.paths.clear();
    final select = tester.widget<DropdownButtonFormField<String>>(find.descendant(
        of: find.byKey(const ValueKey('spatial-model-entity-binding')),
        matching: find.byType(DropdownButtonFormField<String>)));
    select.onChanged!('object');
    expect(document.current.entities.single.pos, const GridPos(x: 2, y: 3));
    expect(document.undoCount, 1);
    await tester.runAsync(() async {
      expect(await controller.save(document), isTrue, reason: document.error);
      expect(reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/a.json' ||
          path.endsWith('.glb') || path.endsWith('history.jsonl')), isEmpty);
      final saved = MapData.fromJson(jsonDecode(await File('${root.path}/maps/a.json').readAsString()));
      expect(saved.spatialScene!.instances.single.entityId, 'object');
      expect(saved.entities.single.pos, const GridPos(x: 2, y: 3));
      final reopened = MapWorkspaceController(session, LocalMapWorkspaceAdapter(reader: reader));
      try {
        await reopened.initialize();
        expect(reopened.active!.saved, saved);
      } finally {
        reopened.dispose();
      }
    });
    expect(tester.takeException(), isNull);
  });
  for (final manual in [false, true]) {
    testWidgets('Environment binding is guided only for a stable manual owner manual=$manual',
        (tester) async {
      final base = spatialEnvironmentMap();
      final instance = SpatialModelInstance(id: 'manual-tree', modelId: 'oak',
          position: Model3dVector3(x: 2.5, y: 0, z: 3.5));
      final map = base.copyWith(
          entities: [MapEntity(id: 'object', name: 'Objet lié',
              kind: MapEntityKind.custom, pos: const GridPos(x: 1, y: 1))],
          spatialScene: base.spatialScene!.copyWith(instances: [instance]),
          layers: [MapLayer.environment(id: 'forest', name: 'Forest',
              content: EnvironmentLayerContent(targetsSpatialTerrain: true,
                  areas: [EnvironmentArea(id: 'trees', name: 'Trees',
                      presetId: 'woodland', seed: 1,
                      mask: EnvironmentAreaMask(width: 12, height: 10,
                          cells: List.filled(120, false)),
                      generatedPlacementIds: [instance.id],
                      manualPlacementIds: manual ? [instance.id] : [])]))]);
      final document = EditableMapDocument(MapWorkspaceDocument(
          map: map, mapId: map.id, revision: 'manual-owner'));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
          builder: (context, refresh) => SpatialModelEntityControls(
              document: document, project: spatialEnvironmentProject(),
              instance: document.current.spatialScene!.instances.single,
              onChanged: () => refresh(() {}))))));
      final binding = find.byKey(const ValueKey('spatial-model-entity-binding'));
      expect(binding, manual ? findsOneWidget : findsNothing);
      expect(find.byKey(const ValueKey('spatial-model-field-obstacle')), findsNothing);
      if (!manual) return;
      await tester.tap(find.descendant(of: binding,
          matching: find.byType(DropdownButtonFormField<String>)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Objet lié').last);
      await tester.pumpAndSettle();
      expect(document.current.spatialScene!.instances.single.entityId, 'object');
      expect(document.current.entities.single.pos, const GridPos(x: 2, y: 3));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(document.current.spatialScene!.instances.single.entityId, 'object');
      expect(MapData.fromJson(document.current.toJson()), document.current);
    });
  }
  for (final choice in {
    'Coupe': FieldObstacleKind.cutTree,
    'Éclate-Roc': FieldObstacleKind.rockSmashRock,
    'Force · rocher à pousser': FieldObstacleKind.strengthBoulder,
  }.entries) {
    testWidgets(
      '${choice.key} guided 3D obstacle creates a bound entity with reset policy and one undo',
      (tester) async {
        final original = spatialEnvironmentMap();
        final instance = SpatialModelInstance(
          id: 'oak-1',
          modelId: 'oak',
          position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
          blocksMovement: true,
        );
        final map = original.copyWith(
          spatialScene: original.spatialScene!.copyWith(instances: [instance]),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'initial'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, refresh) => SpatialModelEntityControls(
                  document: document,
                  project: spatialEnvironmentProject(),
                  instance: document.current.spatialScene!.instances.single,
                  onChanged: () => refresh(() {}),
                ),
              ),
            ),
          ),
        );
        final obstacle = find.byKey(
          const ValueKey('spatial-model-field-obstacle'),
        );
        expect(obstacle, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: obstacle,
            matching: find.byType(DropdownButtonFormField<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.key).last);
        await tester.pumpAndSettle();
        expect(
          document.current.entities.single.fieldObstacle!.kind,
          choice.value,
        );
        expect(
          isValidSpatialFieldObstacle(
            document.current,
            document.current.entities.single,
          ),
          isTrue,
        );
        expect(document.undoCount, 1);
        final reset = find.byKey(
          const ValueKey('spatial-model-field-obstacle-reset'),
        );
        await tester.tap(
          find.descendant(
            of: reset,
            matching: find.byType(DropdownButtonFormField<String>),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Conservé dans la sauvegarde').last);
        await tester.pumpAndSettle();
        expect(
          document.current.entities.single.fieldObstacle!.resetPolicy,
          FieldObstacleResetPolicy.persistent,
        );
        document.restore(redo: false);
        document.restore(redo: false);
        expect(document.current, map);
      },
    );
  }
  testWidgets('guided object binding uses map entities and supports undo', (
    tester,
  ) async {
    final instance = SpatialModelInstance(
      id: 'orb',
      modelId: 'oak',
      position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
    );
    final original = spatialEnvironmentMap();
    final map = original.copyWith(
      spatialScene: original.spatialScene!.copyWith(instances: [instance]),
      entities: [
        MapEntity(
          id: 'item',
          name: 'Objet à ramasser',
          kind: MapEntityKind.item,
          pos: const GridPos(x: 1, y: 1),
          item: const MapEntityItemData(gameItemId: 'resource'),
        ),
        MapEntity(
          id: 'repeat',
          name: 'Objet répétable',
          kind: MapEntityKind.item,
          pos: const GridPos(x: 2, y: 1),
          item: const MapEntityItemData(
            gameItemId: 'resource',
            pickupMode: ItemPickupMode.always,
          ),
        ),
        MapEntity(
          id: 'npc',
          name: 'Habitant',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 3, y: 1),
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'binding'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => SpatialModelEntityControls(
              document: document,
              project: spatialEnvironmentProject(),
              instance: document.current.spatialScene!.instances.single,
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    final picker = tester.widget<StudioSelect>(
      find.byKey(const ValueKey('spatial-model-entity-binding')),
    );
    expect(picker.options, {
      '': 'Aucun · décor simple',
      'item': 'Objet à ramasser',
    });
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('spatial-model-entity-binding')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objet à ramasser').last);
    await tester.pumpAndSettle();
    expect(document.current.spatialScene!.instances.single.entityId, 'item');
    expect(document.current.entities.first.pos, const GridPos(x: 4, y: 3));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current.spatialScene!.instances.single.entityId, isNull);
    expect(document.current.entities.first.pos, const GridPos(x: 1, y: 1));
  });
}

final class _BindingReader implements ProjectFileReader, ProjectResourceStreamReader, ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource({required String projectRoot, required String relativePath}) =>
      delegate.probeResource(projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<String> canonicalizeDirectory(String path) => delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
  @override
  Stream<List<int>> openRead({required String projectRoot, required String relativePath}) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
