import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent project-element entity render pass', () {
    test('keeps default entities in the background pass', () {
      const entity = MapEntity(
        id: 'pokeball',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(elementId: 'pokeball'),
      );

      expect(
        shouldRenderProjectElementEntityInForegroundPass(
          entity,
          renderPass: MapLayerRenderPass.background,
        ),
        isTrue,
      );
      expect(
        shouldRenderProjectElementEntityInForegroundPass(
          entity,
          renderPass: MapLayerRenderPass.foreground,
        ),
        isFalse,
      );
    });

    test('moves flagged props to the foreground pass', () {
      const entity = MapEntity(
        id: 'pokeball_top',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(
          elementId: 'pokeball',
          renderInForeground: true,
        ),
      );

      expect(
        shouldRenderProjectElementEntityInForegroundPass(
          entity,
          renderPass: MapLayerRenderPass.background,
        ),
        isFalse,
      );
      expect(
        shouldRenderProjectElementEntityInForegroundPass(
          entity,
          renderPass: MapLayerRenderPass.foreground,
        ),
        isTrue,
      );
    });

    test('never renders an authored hidden item visual', () {
      const entity = MapEntity(
        id: 'hidden-tonic',
        kind: MapEntityKind.item,
        pos: GridPos(x: 0, y: 0),
        item: MapEntityItemData(
          gameItemId: 'tonic',
          visibility: MapEntityItemVisibility.hidden,
        ),
        editorVisual: MapEntityEditorVisual(elementId: 'pokeball'),
      );

      expect(shouldRenderMapEntityVisual(entity), isFalse);
    });

    test('does not paint a non-NPC entity rejected by world presence',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: const MapData(
            id: 'world-presence-render',
            name: 'World presence render',
            size: GridSize(width: 1, height: 1),
            entities: <MapEntity>[
              MapEntity(
                id: 'fog-prop',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(elementId: 'fog'),
              ),
            ],
          ),
          elements: const <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'fog',
              name: 'Fog',
              tilesetId: 'entity',
              categoryId: 'world-state',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
        tileImagesByTilesetId: {
          'entity': await runtimeTilesetImage(
            const <Color>[Color(0xFF6B82A8)],
          ),
        },
        mapEntityPresencePredicate: (_, entity) => entity.id != 'fog-prop',
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });
  });

  group('MapLayersComponent explicit foreground tile markers', () {
    for (final layerId in <String>[
      'l_tile_overhead',
      'l_tile_occlusion',
    ]) {
      test('routes $layerId exclusively through the foreground pass', () async {
        final background = await _renderTileLayerPass(
          layerId: layerId,
          renderPass: MapLayerRenderPass.background,
        );
        final foreground = await _renderTileLayerPass(
          layerId: layerId,
          renderPass: MapLayerRenderPass.foreground,
        );

        expect(await pixelAt(background, 16, 16), rgba(0, 0, 0, 0));
        expect(await pixelAt(foreground, 16, 16), rgba(40, 90, 180, 255));
      });
    }

    test('keeps an ordinary tile layer in the background pass', () async {
      final background = await _renderTileLayerPass(
        layerId: 'l_tile_furniture',
        renderPass: MapLayerRenderPass.background,
      );
      final foreground = await _renderTileLayerPass(
        layerId: 'l_tile_furniture',
        renderPass: MapLayerRenderPass.foreground,
      );

      expect(await pixelAt(background, 16, 16), rgba(40, 90, 180, 255));
      expect(await pixelAt(foreground, 16, 16), rgba(0, 0, 0, 0));
    });
  });
}

Future<ui.Image> _renderTileLayerPass({
  required String layerId,
  required MapLayerRenderPass renderPass,
}) async {
  final component = MapLayersComponent(
    bundle: surfaceTestBundle(
      map: MapData(
        id: 'foreground-marker-test',
        name: 'Foreground marker test',
        size: const GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: layerId,
            name: layerId,
            palette: const <TileLayerPaletteEntry>[
              TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0),
            ],
            cells: const <int>[1],
          ),
        ],
      ),
    ),
    tileImagesByTilesetId: {
      'base': await runtimeTilesetImage(
        const <Color>[Color(0xFF285AB4)],
      ),
    },
    renderPass: renderPass,
  );
  return renderSurfaceTestComponent(component);
}
