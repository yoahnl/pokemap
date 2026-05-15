import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_render_order_contract.dart';

void main() {
  group('editor shadow render order contract', () {
    test('covers every slot exactly once', () {
      expect(
        editorShadowRenderOrder.toSet(),
        EditorShadowRenderOrderSlot.values.toSet(),
      );
      expect(
        editorShadowRenderOrder.length,
        EditorShadowRenderOrderSlot.values.length,
      );
    });

    test('places static shadows after ground layers', () {
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.baseTerrain,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.groundPaths,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.surfacePreview,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
    });

    test('places static shadows below sprites foreground and debug overlays',
        () {
      for (final upperSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.placedElementsBackground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
        EditorShadowRenderOrderSlot.placedElementsForeground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
        EditorShadowRenderOrderSlot.foregroundOcclusion,
        EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
        EditorShadowRenderOrderSlot.flutterUi,
      ]) {
        expect(
          editorShadowSlotIsBefore(
            EditorShadowRenderOrderSlot.futureStaticElementShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future static shadows must render before $upperSlot',
        );
      }
    });

    test('places dynamic actor shadows below actors and occlusion', () {
      for (final upperSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
        EditorShadowRenderOrderSlot.placedElementsForeground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
        EditorShadowRenderOrderSlot.foregroundOcclusion,
        EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
        EditorShadowRenderOrderSlot.flutterUi,
      ]) {
        expect(
          editorShadowSlotIsBefore(
            EditorShadowRenderOrderSlot.futureDynamicActorShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future dynamic shadows must render before $upperSlot',
        );
      }
    });

    test('keeps debug overlays and Flutter UI above all future shadows', () {
      for (final shadowSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.futureStaticElementShadows,
        EditorShadowRenderOrderSlot.futureDynamicActorShadows,
      ]) {
        expect(
          editorShadowSlotIsAfter(
            EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          editorShadowSlotIsAfter(
            EditorShadowRenderOrderSlot.flutterUi,
            shadowSlot,
          ),
          isTrue,
        );
      }
    });
  });
}
