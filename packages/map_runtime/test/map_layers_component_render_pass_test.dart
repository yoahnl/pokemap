import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

void main() {
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
  });
}
