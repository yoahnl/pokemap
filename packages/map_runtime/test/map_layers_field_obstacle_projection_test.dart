import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  test('render projection uses live NPC positions without altering its authored bundle', () {
    final authored = MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 6, height: 4),
      entities: const [
        MapEntity(
          id: 'rock',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1),
          fieldObstacle: MapEntityFieldObstacleData(
            kind: FieldObstacleKind.strengthBoulder,
          ),
        ),
        MapEntity(
          id: 'walker',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 1),
          npc: MapEntityNpcData(displayName: 'Walker'),
        ),
      ],
    );
    final live = authored.copyWith(
      entities: [
        authored.entities.first,
        authored.entities.last.copyWith(pos: const GridPos(x: 4, y: 2)),
      ],
    );
    final instances = MapInstanceWorldState(
      instancesByMapId: {
        'route': MapInstanceRuntimeState(
          instanceId: 'route-1',
          strengthActive: true,
          fieldObstaclePositions: const {'rock': GridPos(x: 3, y: 1)},
        ),
      },
    );
    final component = MapLayersComponent(
      bundle: surfaceTestBundle(map: authored),
      fieldObstacleAuthoringMap: authored,
      tileImagesByTilesetId: const {},
    );
    expect(
      () => component.applyFieldObstacleProjection(
        instances: instances,
        instance: instances.instanceRef('route')!,
        movingPlatformWorldState: const MovingPlatformWorldState.empty(),
        runtimeMap: live,
      ),
      returnsNormally,
    );
    expect(component.bundle.map, authored);
    expect(authored.entities.last.pos, const GridPos(x: 3, y: 1));
  });

  for (final foreground in [false, true]) {
    test(
      'Strength paints source, intermediate and target pixels in pass $foreground',
      () async {
        final authored = MapData(
          id: 'route',
          name: 'Route',
          size: const GridSize(width: 4, height: 1),
          entities: [
            MapEntity(
              id: 'rock',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 1, y: 0),
              fieldObstacle: const MapEntityFieldObstacleData(
                kind: FieldObstacleKind.strengthBoulder,
              ),
              editorVisual: MapEntityEditorVisual(
                elementId: 'tree',
                renderInForeground: foreground,
              ),
            ),
          ],
        );
        final component = MapLayersComponent(
          renderPass: foreground
              ? MapLayerRenderPass.foreground
              : MapLayerRenderPass.background,
          fieldObstacleAuthoringMap: authored,
          bundle: surfaceTestBundle(
            map: authored,
            elements: const [
              ProjectElementEntry(
                id: 'tree',
                name: 'Rock',
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
        var instances = MapInstanceWorldState(
          instancesByMapId: {
            'route': MapInstanceRuntimeState(instanceId: 'r1'),
          },
        );
        final scope = instances.instanceRef('route')!;
        instances = instances.moveFieldObstacle(
          scope,
          'rock',
          const GridPos(x: 2, y: 0),
        );
        component.applyFieldObstacleProjection(
          instances: instances,
          runtimeMap: authored,
          movingPlatformWorldState: const MovingPlatformWorldState.empty(),
          instance: scope,
        );
        component.animateFieldObstaclePush(
          entityId: 'rock',
          from: const GridPos(x: 1, y: 0),
          to: const GridPos(x: 2, y: 0),
          durationSeconds: .25,
        );
        final before = await _render(component);
        expect(await pixelAt(before, 48, 16), rgba(34, 170, 68, 255));
        expect(await pixelAt(before, 80, 16), rgba(0, 0, 0, 0));
        before.dispose();
        component.update(.125);
        final middle = await _render(component);
        expect(await pixelAt(middle, 40, 16), rgba(0, 0, 0, 0));
        expect(await pixelAt(middle, 64, 16), rgba(34, 170, 68, 255));
        middle.dispose();
        component.update(.125);
        final after = await _render(component);
        expect(await pixelAt(after, 48, 16), rgba(0, 0, 0, 0));
        expect(await pixelAt(after, 80, 16), rgba(34, 170, 68, 255));
        after.dispose();
        expect(authored.entities.single.pos, const GridPos(x: 1, y: 0));
      },
    );
  }

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
                clearedFieldObstacleIds: {'tree'},
              ),
            },
          );
          component.applyFieldObstacleProjection(
            instances: instances,
            runtimeMap: authored,
            movingPlatformWorldState: const MovingPlatformWorldState.empty(),
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
            runtimeMap: authored,
            movingPlatformWorldState: const MovingPlatformWorldState.empty(),
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
