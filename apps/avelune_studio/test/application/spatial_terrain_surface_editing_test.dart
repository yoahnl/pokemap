import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  MapData source() => MapData(
    id: 'a',
    name: 'Terrain',
    version: ProjectVersion.v9,
    size: const GridSize(width: 8, height: 6),
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 6,
      levelHeight: .25,
      heightLevels: List.filled(48, 4),
      instances: [
        SpatialModelInstance(
          id: 'tree',
          modelId: 'oak',
          position: Model3dVector3(x: 2.5, y: 1.25, z: 1.5),
        ),
      ],
    ),
  );

  for (final direction in SpatialRampDirection.values) {
    test(
      'rectangular surfaces honor $direction, fractional blocks and local footprints',
      () {
        final before = source();
        final stroke = SpatialTerrainStroke(
          source: before,
          mode: SpatialTerrainMode.relief,
          level: 0,
          erase: false,
          origin: const GridPos(x: 1, y: 1),
          surfaceBrush: SpatialTerrainSurfaceBrush(
            lowLevel: 4,
            highLevel: 8,
            direction: direction,
          ),
        );
        stroke.paint(const GridPos(x: 3, y: 2));
        expect(stroke.cells, hasLength(6));
        final result = stroke.commit();
        final surface = result.spatialScene!.terrainSurfaces.surfaces.single;
        final alongX =
            direction == SpatialRampDirection.east ||
            direction == SpatialRampDirection.west;
        final negative =
            direction == SpatialRampDirection.north ||
            direction == SpatialRampDirection.west;
        final startHeight = alongX
            ? surface.heightAt(1, 1.5)
            : surface.heightAt(2.5, 1);
        final endHeight = alongX
            ? surface.heightAt(4, 1.5)
            : surface.heightAt(2.5, 3);
        expect(startHeight, negative ? 2 : 1);
        expect(endHeight, negative ? 1 : 2);
        expect(surface.contains(2.5, 1.5), isTrue);
        expect(
          result.spatialScene!.heightLevels,
          before.spatialScene!.heightLevels,
        );
        expect(
          result.spatialScene!.navigation,
          before.spatialScene!.navigation,
        );
        expect(
          result.spatialScene!.instances.single.position.y -
              result.spatialScene!.worldHeightAt(2.5, 1.5),
          closeTo(.25, 1e-12),
        );
        expect(before.spatialScene!.terrainSurfaces.surfaces, isEmpty);
      },
    );
  }

  test(
    'surface drawing and erasing can preserve the placed scenery height',
    () {
      final before = source();
      final stroke = SpatialTerrainStroke(
        source: before,
        mode: SpatialTerrainMode.relief,
        level: 0,
        erase: false,
        origin: const GridPos(x: 2, y: 1),
        reanchorInstances: false,
        surfaceBrush: const SpatialTerrainSurfaceBrush(
          lowLevel: 8,
          highLevel: 8,
          direction: SpatialRampDirection.north,
        ),
      );
      final raised = stroke.commit();
      expect(raised.spatialScene!.worldHeightAt(2.5, 1.5), 2);
      expect(raised.spatialScene!.instances, before.spatialScene!.instances);
      final erased = SpatialTerrainStroke(
        source: raised,
        mode: SpatialTerrainMode.relief,
        level: 0,
        erase: true,
        origin: const GridPos(x: 2, y: 1),
        reanchorInstances: false,
        surfaceBrush: const SpatialTerrainSurfaceBrush(
          lowLevel: 0,
          highLevel: 0,
          direction: SpatialRampDirection.north,
        ),
      ).commit();
      expect(erased, before);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: raised, mapId: 'a', revision: 'r'),
      );
      final commands = SpatialTerrainSurfaceEditingCommands(document);
      final surface = raised.spatialScene!.terrainSurfaces.surfaces.single;
      final preview = commands.preview(
        surface.copyWith(height: 3),
        reanchorInstances: false,
      );
      expect(document.current, raised);
      commands.apply(preview);
      expect(
        document.current.spatialScene!.instances,
        before.spatialScene!.instances,
      );
      commands.delete(surface.id, reanchorInstances: false);
      expect(document.current, before);
    },
  );

  test(
    'surface preview rejects stale maps and an active save without publishing',
    () {
      final original = source();
      final surface =
          const SpatialTerrainSurfaceBrush(
            lowLevel: 4,
            highLevel: 8,
            direction: SpatialRampDirection.north,
          ).rectangle(
            id: 'slope',
            scene: original.spatialScene!,
            start: const GridPos(x: 1, y: 1),
            end: const GridPos(x: 3, y: 2),
          );
      final map = const SpatialMapOperations().upsertTerrainSurfaces(original, [
        surface,
      ]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r'),
      );
      final commands = SpatialTerrainSurfaceEditingCommands(document);
      final preview = commands.preview(surface.copyWith(height: 3));
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      document.commit(map.copyWith(name: 'Renamed'));
      final renamed = document.current;
      expect(() => commands.apply(preview), throwsStateError);
      expect(document.current, same(renamed));
      document.saving = true;
      expect(() => commands.preview(surface), throwsStateError);
      expect(() => commands.delete(surface.id), throwsStateError);
    },
  );

  test('erasing a part removes the whole native surface and is independent of ramps', () {
    final original = source();
    final brush = const SpatialTerrainSurfaceBrush(
      lowLevel: 4,
      highLevel: 8,
      direction: SpatialRampDirection.east,
    );
    final surface = brush.rectangle(
      id: 'slope',
      scene: original.spatialScene!,
      start: const GridPos(x: 1, y: 1),
      end: const GridPos(x: 3, y: 2),
    );
    final painted = const SpatialMapOperations().upsertTerrainSurfaces(
      original,
      [surface],
    );
    final erased = SpatialTerrainStroke(
      source: painted,
      mode: SpatialTerrainMode.relief,
      level: 0,
      erase: true,
      origin: const GridPos(x: 2, y: 1),
      surfaceBrush: brush,
    ).commit();
    expect(erased, original);
  });

  test(
    'invalid heights never publish a preview and flat surfaces remain drawable',
    () {
      final map = source();
      expect(
        () => SpatialTerrainSurfaceBrush.parse(
          lowLevel: 'NaN',
          highLevel: '2',
          direction: SpatialRampDirection.north,
        ),
        throwsStateError,
      );
      for (final (low, high) in [
        (-1.0, 2.0),
        (3.0, 2.0),
        (0.0, double.infinity),
      ]) {
        final stroke = SpatialTerrainStroke(
          source: map,
          mode: SpatialTerrainMode.relief,
          level: 0,
          erase: false,
          origin: const GridPos(x: 1, y: 1),
          surfaceBrush: SpatialTerrainSurfaceBrush(
            lowLevel: low,
            highLevel: high,
            direction: SpatialRampDirection.north,
          ),
        );
        expect(stroke.preview, same(map));
        expect(stroke.error, isNotNull);
        expect(() => stroke.commit(), throwsStateError);
      }
      final flat = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.relief,
        level: 0,
        erase: false,
        origin: const GridPos(x: 1, y: 1),
        surfaceBrush: SpatialTerrainSurfaceBrush.parse(
          lowLevel: '4,5',
          highLevel: '4,5',
          direction: SpatialRampDirection.north,
        ),
      ).commit();
      expect(flat.spatialScene!.worldHeightAt(1.5, 1.5), 1.125);
    },
  );
}
