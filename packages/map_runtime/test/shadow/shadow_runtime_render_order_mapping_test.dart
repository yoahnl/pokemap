import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/shadow_runtime_render_order_contract.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('runtime shadow render order mapping', () {
    test('maps groundStatic to the static placed element shadow slot', () {
      expect(
        runtimeShadowRenderSlotForPass(ShadowRenderPass.groundStatic),
        RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
      );
    });

    test('maps actorContact to the dynamic actor contact shadow slot', () {
      expect(
        runtimeShadowRenderSlotForPass(ShadowRenderPass.actorContact),
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      );
    });

    test('maps an instruction through its render pass', () {
      final instruction = ShadowRuntimeRenderInstruction(
        shape: ShadowRuntimeShapeKind.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 0,
        worldTop: 0,
        width: 16,
        height: 8,
        opacity: 0.35,
      );

      expect(
        runtimeShadowRenderSlotForInstruction(instruction),
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      );
    });

    test(
        'keeps static shadows after ground and before sprites actors occlusion',
        () {
      const staticSlot =
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows;

      for (final lowerSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.baseTerrain,
        RuntimeShadowRenderOrderSlot.groundPaths,
        RuntimeShadowRenderOrderSlot.surfaceLayers,
      ]) {
        expect(runtimeShadowSlotIsBefore(lowerSlot, staticSlot), isTrue);
      }

      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.placedElementSprites,
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(runtimeShadowSlotIsBefore(staticSlot, upperSlot), isTrue);
      }
    });

    test('keeps dynamic actor shadows below actors occlusion debug and HUD',
        () {
      const dynamicSlot =
          RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows;

      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(runtimeShadowSlotIsBefore(dynamicSlot, upperSlot), isTrue);
      }
    });
  });
}
