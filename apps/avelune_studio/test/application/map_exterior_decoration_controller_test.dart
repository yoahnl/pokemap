import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';

import '../support/spatial_environment_fixture.dart';

import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_exterior_decoration_controller_port.dart';

void main() {
  test(
    'opening an absent exterior document admits its map without mutation',
    () async {
      final port = ExteriorDecorationPort();
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
      final port = ExteriorDecorationPort();
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
        ExteriorDecorationPort(),
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
      ExteriorDecorationPort(),
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
      final port = ExteriorDecorationPort();
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
    final port = ExteriorDecorationPort();
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
      final port = ExteriorDecorationPort();
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
