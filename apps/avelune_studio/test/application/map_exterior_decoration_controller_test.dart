import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';

import '../support/spatial_environment_fixture.dart';

import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'opening an absent exterior document admits its map without mutation',
    () async {
      final port = _Port();
      final controller = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        MapData(
          id: 'shore',
          name: 'Shore',
          size: const GridSize(width: 256, height: 256),
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(width: 256, depth: 256),
        ),
        port,
      );
      addTearDown(controller.dispose);
      expect(port.loads, 1);
    },
  );
  test(
    'logical target isolates native edits and undo from playable data',
    () async {
      final port = _Port();
      final map = spatialEnvironmentMap();
      final controller = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        map,
        port,
      );
      addTearDown(controller.dispose);
      controller.setEditingExterior(true);
      expect(controller.selectAt(0, 0), isFalse);
      expect(controller.selectAt(-1, 2), isTrue);
      final child = controller.editingDocument!;
      final scene = child.current.spatialScene!;
      child.commit(
        child.current.copyWith(
          spatialScene: scene.copyWith(
            heightLevels: List.filled(scene.width * scene.depth, 2),
          ),
        ),
      );
      expect(identical(controller.map, map), isTrue);
      expect(map.spatialScene!.heightLevels.first, 0);
      expect(controller.current!.sectors.single.scene.heightLevels.first, 2);
      controller.undo();
      expect(controller.editingDocument, isNull);
      controller.redo();
      expect(controller.current!.sectors.single.scene.heightLevels.first, 2);
      expect(await controller.save(), isTrue);
      expect(port.sectorWrites, 1);
      expect(controller.dirty, isFalse);
      final reopened = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        map,
        port,
      );
      addTearDown(reopened.dispose);
      expect(reopened.current!.sectors.single.scene.heightLevels.first, 2);
    },
  );
  test(
    'complete Environment trees use native commands on the exterior draft',
    () async {
      final controller = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        spatialEnvironmentMap(),
        _Port(),
      );
      addTearDown(controller.dispose);
      controller.setEditingExterior(true);
      controller.selectAt(-4, 2);
      final commands = EnvironmentEditingCommands(
        controller.editingDocument!,
        spatialEnvironmentProject(),
      );
      final session = commands.create(
        spatialEnvironmentProject().environmentPresets.single,
      );
      commands.paint(session, [const GridPos(x: 3, y: 3)], erase: false);
      commands.preview(session);
      commands.apply(session);
      final sector = controller.current!.sectors.single;
      expect(
        sector.layers.whereType<EnvironmentLayer>().single.content.areas,
        isNotEmpty,
      );
      expect(sector.scene.instances, isNotEmpty);
      expect(controller.map.spatialScene!.instances, isEmpty);
    },
  );
  test('neighbor footprints and shrinking occupied margins refuse destructive edits', () async {
    final controller = await MapExteriorDecorationController.open(
      const ProjectSession(
        sessionId: 'session',
        name: 'test',
        directoryPath: '/test',
      ),
      spatialEnvironmentMap(),
      _Port(),
    );
    addTearDown(controller.dispose);
    controller.setEditingExterior(true);
    expect(
      controller.selectAt(
        -4,
        2,
        neighborBounds: [
          ExteriorDecorationRect(x: -10, z: 0, width: 10, depth: 10),
        ],
      ),
      isFalse,
    );
    controller.selectAt(-4, 2);
    final child = controller.editingDocument!;
    child.commit(
      child.current.copyWith(
        spatialScene: child.current.spatialScene!.copyWith(
          generateCliffs: true,
        ),
      ),
    );
    expect(
      controller.configureMargins(west: 0, east: 16, north: 16, south: 16),
      isFalse,
    );
    expect(controller.current!.west, 16);
    expect(controller.error, isNotNull);
  });
  test(
    'a save keeps later edits dirty and reports persistence failures',
    () async {
      final port = _Port();
      final controller = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        spatialEnvironmentMap(),
        port,
      );
      addTearDown(controller.dispose);
      controller.setEditingExterior(true);
      expect(await controller.save(), isTrue);
      controller.selectAt(-4, 2);
      var child = controller.editingDocument!;
      child.commit(
        child.current.copyWith(
          spatialScene: child.current.spatialScene!.copyWith(
            generateCliffs: true,
          ),
        ),
      );
      port.pending = Completer<void>();
      final saving = controller.save();
      child.commit(
        child.current.copyWith(
          spatialScene: child.current.spatialScene!.copyWith(
            heightLevels: List.filled(
              child.current.size.width * child.current.size.height,
              1,
            ),
          ),
        ),
      );
      port.pending!.complete();
      expect(await saving, isTrue);
      expect(controller.dirty, isTrue);
      port.failure = StateError('Conflit');
      expect(await controller.save(), isFalse);
      expect(controller.error, contains('Conflit'));
      expect(controller.dirty, isTrue);
    },
  );
  test('undoing the initial durable definition clears it through the canonical port', () async {
    final port = _Port();
    final controller = await MapExteriorDecorationController.open(
      const ProjectSession(
        sessionId: 'session',
        name: 'test',
        directoryPath: '/test',
      ),
      spatialEnvironmentMap(),
      port,
    );
    addTearDown(controller.dispose);
    controller.setEditingExterior(true);
    expect(await controller.save(), isTrue);
    controller.undo();
    expect(controller.current, isNull);
    expect(await controller.save(), isTrue);
    expect(port.value, isNull);
    expect(controller.dirty, isFalse);
  });
  test(
    'one continuous exterior gesture groups sectors and persists one batch',
    () async {
      final port = _Port();
      final controller = await MapExteriorDecorationController.open(
        const ProjectSession(
          sessionId: 'session',
          name: 'test',
          directoryPath: '/test',
        ),
        spatialEnvironmentMap(),
        port,
      );
      addTearDown(controller.dispose);
      controller.setEditingExterior(true);
      controller.beginGesture();
      for (final x in [-8, 13]) {
        expect(controller.selectAt(x, 2), isTrue);
        final child = controller.editingDocument!;
        child.commit(
          child.current.copyWith(
            spatialScene: child.current.spatialScene!.copyWith(
              generateCliffs: true,
            ),
          ),
        );
      }
      expect(await controller.save(), isFalse);
      controller.endGesture();
      expect(controller.current!.sectors, hasLength(2));
      controller.undo();
      expect(controller.current!.sectors, isEmpty);
      controller.redo();
      expect(controller.current!.sectors, hasLength(2));
      expect(await controller.save(), isTrue);
      expect(port.batchWrites, 1);
      expect(port.sectorWrites, 2);
      controller.beginGesture();
      controller.selectAt(-8, 2);
      final child = controller.editingDocument!;
      child.commit(
        child.current.copyWith(
          spatialScene: child.current.spatialScene!.copyWith(
            generateCliffs: false,
          ),
        ),
      );
      controller.cancelGesture();
      expect(controller.dirty, isFalse);
    },
  );
}

final class _Port implements MapExteriorDecorationPort {
  int loads = 0, revision = 0, sectorWrites = 0, batchWrites = 0;
  MapExteriorDecoration? value;
  Completer<void>? pending;
  Object? failure;
  MapExteriorDecoration withSectors(
    MapExteriorDecoration header,
    Iterable<ExteriorDecorationSector> sectors,
  ) => MapExteriorDecoration(
    mapId: header.mapId,
    playableWidth: header.playableWidth,
    playableDepth: header.playableDepth,
    west: header.west,
    east: header.east,
    north: header.north,
    south: header.south,
    sectors: sectors,
  );
  Future<MapExteriorDecorationWrite> result() async {
    if (failure != null) throw failure!;
    await pending?.future;
    revision++;
    return MapExteriorDecorationWrite(
      revision: 'revision_$revision',
      receiptId: 'receipt_$revision',
    );
  }

  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async {
    loads++;
    return MapExteriorDecorationState(
      decoration: value,
      revision: 'revision_$revision',
    );
  }

  @override
  Future<MapExteriorDecorationWrite> configureExteriorDecoration(
    ProjectSession session,
    String mapId,
    MapExteriorDecoration? definition,
    String expectedRevision,
  ) async {
    final response = await result();
    value = definition == null
        ? null
        : withSectors(definition, value?.sectors ?? const []);
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    ExteriorDecorationSector sector,
    String expectedRevision,
  ) async {
    final response = await result();
    sectorWrites++;
    value = withSectors(
      value!,
      {
        for (final item in value!.sectors) item.id: item,
        sector.id: sector,
      }.values,
    );
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> removeExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    String sectorId,
    String expectedRevision,
  ) async {
    final response = await result();
    value = withSectors(value!, value!.sectors.where((v) => v.id != sectorId));
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSectors(
    ProjectSession session,
    String mapId,
    List<ExteriorDecorationSector> sectors,
    List<String> removeSectorIds,
    String expectedRevision,
  ) async {
    final response = await result();
    batchWrites++;
    sectorWrites += sectors.length;
    value = withSectors(
      value!,
      {
        for (final item in value!.sectors)
          if (!removeSectorIds.contains(item.id)) item.id: item,
        for (final item in sectors) item.id: item,
      }.values,
    );
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
