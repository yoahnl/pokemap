import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent shadow renderer integration', () {
    test('renders without shadow provider as existing no-op behavior',
        () async {
      final component = await _componentWithSurface();

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('treats a null shadow collection as a no-op', () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => null,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('treats an empty shadow collection as a no-op', () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('renders groundStatic and actorContact shadows after surfaces',
        () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(
              renderPass: ShadowRenderPass.groundStatic,
              colorHexRgb: 'FF0000',
            ),
            _shadow(
              renderPass: ShadowRenderPass.actorContact,
              colorHexRgb: '00FF00',
            ),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 255, 0, 255));
    });

    test('renders shadows before tile and placed element sprites', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('renders shadows before project element entities', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: [surfaceTestElement()],
          map: surfaceTestMap(
            layers: [surfaceTestLayer()],
            entities: const [
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'entity-prop',
                ),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'entity': await runtimeTilesetImage([const Color(0xFF800080)]),
        },
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(128, 0, 128, 255));
    });

    test('calls the shadow collection provider once per render', () async {
      var calls = 0;
      final component = await _componentWithSurface(
        shadowCollectionProvider: () {
          calls += 1;
          return ShadowRuntimeInstructionCollection(
            instructions: [
              _shadow(
                renderPass: ShadowRenderPass.groundStatic,
                colorHexRgb: 'FF0000',
              ),
              _shadow(
                renderPass: ShadowRenderPass.actorContact,
                colorHexRgb: '00FF00',
              ),
            ],
          );
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(0, 255, 0, 255));
    });

    test('uses a fresh provider collection on each render', () async {
      var calls = 0;
      final component = await _componentWithSurface(
        shadowCollectionProvider: () {
          calls += 1;
          return ShadowRuntimeInstructionCollection(
            instructions: [
              _shadow(
                renderPass: ShadowRenderPass.groundStatic,
                colorHexRgb: calls == 1 ? 'FF0000' : '00FF00',
              ),
            ],
          );
        },
      );

      final firstImage = await renderSurfaceTestComponent(component);
      final secondImage = await renderSurfaceTestComponent(component);

      expect(await pixelAt(firstImage, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(secondImage, 16, 16), rgba(0, 255, 0, 255));
      expect(calls, 2);
    });

    test('does not render shadows in the foreground pass', () async {
      final component = await _componentWithSurface(
        renderPass: MapLayerRenderPass.foreground,
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });
  });
}

Future<MapLayersComponent> _componentWithSurface({
  MapLayerRenderPass renderPass = MapLayerRenderPass.background,
  ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider,
}) async {
  return MapLayersComponent(
    bundle: surfaceTestBundle(
      map: surfaceTestMap(layers: [surfaceTestLayer()]),
    ),
    tileImagesByTilesetId: {
      'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
    },
    renderPass: renderPass,
    shadowCollectionProvider: shadowCollectionProvider,
  );
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}
