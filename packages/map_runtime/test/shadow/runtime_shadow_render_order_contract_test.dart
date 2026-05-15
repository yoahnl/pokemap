import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/shadow_runtime_render_order_contract.dart';

void main() {
  group('runtime shadow render order contract', () {
    test('covers every slot exactly once', () {
      expect(
        runtimeShadowRenderOrder.toSet(),
        RuntimeShadowRenderOrderSlot.values.toSet(),
      );
      expect(
        runtimeShadowRenderOrder.length,
        RuntimeShadowRenderOrderSlot.values.length,
      );
    });

    test('places static placed element shadows after ground layers', () {
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.baseTerrain,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.groundPaths,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.surfaceLayers,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
    });

    test('places static shadows below sprites actors occlusion and debug', () {
      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.placedElementSprites,
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(
          runtimeShadowSlotIsBefore(
            RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future static shadows must render before $upperSlot',
        );
      }
    });

    test('places dynamic actor contact shadows below actors and occlusion', () {
      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(
          runtimeShadowSlotIsBefore(
            RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future dynamic shadows must render before $upperSlot',
        );
      }
    });

    test('keeps occlusion debug and HUD above all future shadows', () {
      for (final shadowSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      ]) {
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.debugOverlays,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.hudUi,
            shadowSlot,
          ),
          isTrue,
        );
      }
    });
  });
}
