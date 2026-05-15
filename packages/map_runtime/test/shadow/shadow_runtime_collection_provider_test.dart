import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeCollectionController', () {
    test('starts empty and provides null by default', () {
      final controller = ShadowRuntimeCollectionController();

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('provides the initial collection without changing it', () {
      final collection = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(renderPass: ShadowRenderPass.actorContact),
        ],
      );
      final controller = ShadowRuntimeCollectionController(collection);

      expect(controller.current, same(collection));
      expect(controller.provide(), same(collection));
      expect(controller.provide()!.actorContact, hasLength(1));
    });

    test('replace updates current and provide', () {
      final first = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: 'FF0000'),
        ],
      );
      final second = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: '00FF00'),
        ],
      );
      final controller = ShadowRuntimeCollectionController(first);

      controller.replace(second);

      expect(controller.current, same(second));
      expect(controller.provide(), same(second));
    });

    test('replace can change collection between two provider calls', () {
      final first = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: 'FF0000'),
        ],
      );
      final second = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: '00FF00'),
        ],
      );
      final controller = ShadowRuntimeCollectionController(first);

      final before = controller.provide();
      controller.replace(second);
      final after = controller.provide();

      expect(before, same(first));
      expect(after, same(second));
    });

    test('replace null clears the collection', () {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(),
          ],
        ),
      );

      controller.replace(null);

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('clear removes the current collection', () {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(),
          ],
        ),
      );

      controller.clear();

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('does not sort cull deduplicate or remove opacity zero instructions',
        () {
      final zeroOpacity = _shadow(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 1,
        opacity: 0,
      );
      final firstGround = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
      );
      final duplicateGround = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
      );
      final collection = ShadowRuntimeInstructionCollection(
        instructions: [
          zeroOpacity,
          firstGround,
          duplicateGround,
        ],
      );
      final controller = ShadowRuntimeCollectionController(collection);

      final provided = controller.provide();

      expect(provided, same(collection));
      expect(
          provided!.instructions, [zeroOpacity, firstGround, duplicateGround]);
      expect(provided.actorContact, [zeroOpacity]);
      expect(provided.groundStatic, [firstGround, duplicateGround]);
    });
  });
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  String colorHexRgb = '000000',
  double worldLeft = 4,
  double opacity = 1,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}
