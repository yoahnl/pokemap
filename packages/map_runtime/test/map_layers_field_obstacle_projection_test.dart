import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final foreground in [false, true]) {
    for (final initiallyCleared in [false, true]) {
      test(
        'typed projection paints real pixels foreground $foreground initiallyCleared $initiallyCleared',
        () async {
          final authored = MapData(
            id: 'route',
            name: 'Route',
            size: const GridSize(width: 3, height: 1),
            entities: [
              MapEntity(
                id: 'ordinary',
                kind: MapEntityKind.custom,
                pos: const GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'tree',
                  renderInForeground: foreground,
                ),
              ),
              MapEntity(
                id: 'tree',
                kind: MapEntityKind.custom,
                pos: const GridPos(x: 1, y: 0),
                fieldObstacle: const MapEntityFieldObstacleData(),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'tree',
                  renderInForeground: foreground,
                ),
              ),
            ],
          );
          final current = initiallyCleared
              ? authored.copyWith(entities: [authored.entities.first])
              : authored;
          final component = MapLayersComponent(
            renderPass: foreground
                ? MapLayerRenderPass.foreground
                : MapLayerRenderPass.background,
            fieldObstacleAuthoringMap: authored,
            bundle: surfaceTestBundle(
              map: current,
              elements: const [
                ProjectElementEntry(
                  id: 'tree',
                  name: 'Tree',
                  tilesetId: 'entity',
                  categoryId: 'nature',
                  frames: [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                  ],
                ),
              ],
            ),
            tileImagesByTilesetId: {
              'entity': await runtimeTilesetImage(const [Color(0xFF22AA44)]),
            },
          );
          final before = await _render(component);
          expect(
            await pixelAt(before, 48, 16),
            initiallyCleared ? rgba(0, 0, 0, 0) : rgba(34, 170, 68, 255),
          );
          before.dispose();
          final instances = MapInstanceWorldState(
            instancesByMapId: {
              'route': MapInstanceRuntimeState(
                instanceId: 'route-1',
                clearedFieldObstacleIds: {'tree', 'ordinary'},
              ),
            },
          );
          component.applyFieldObstacleProjection(
            instances: instances,
            instance: instances.instanceRef('route')!,
          );
          final after = await _render(component);
          expect(await pixelAt(after, 48, 16), rgba(0, 0, 0, 0));
          expect(await pixelAt(after, 16, 16), rgba(34, 170, 68, 255));
          expect(
            component.bundle.map.entities,
            hasLength(initiallyCleared ? 1 : 2),
          );
          expect(authored.entities, hasLength(2));
          after.dispose();
          final reset = MapInstanceWorldState(
            instancesByMapId: {
              'route': MapInstanceRuntimeState(instanceId: 'route-2'),
            },
          );
          component.applyFieldObstacleProjection(
            instances: reset,
            instance: reset.instanceRef('route')!,
          );
          final restored = await _render(component);
          expect(await pixelAt(restored, 48, 16), rgba(34, 170, 68, 255));
          expect(await pixelAt(restored, 16, 16), rgba(34, 170, 68, 255));
          restored.dispose();
        },
      );
    }
  }
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(96, 32);
}
