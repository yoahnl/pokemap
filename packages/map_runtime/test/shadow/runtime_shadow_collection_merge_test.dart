import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_shadow_collection_merge.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('mergeShadowRuntimeInstructionCollections', () {
    test('merges empty collections into an empty collection', () {
      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(),
        ShadowRuntimeInstructionCollection(),
      ]);

      expect(merged, ShadowRuntimeInstructionCollection());
    });

    test('preserves collection order and instruction order without sorting',
        () {
      final firstStatic = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );
      final actor = _shadow(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 10,
      );
      final secondStatic = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 20,
      );

      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [firstStatic]),
        ShadowRuntimeInstructionCollection(instructions: [actor, secondStatic]),
      ]);

      expect(merged.instructions, [firstStatic, actor, secondStatic]);
      expect(merged.groundStatic, [firstStatic, secondStatic]);
      expect(merged.actorContact, [actor]);
    });

    test('does not deduplicate and retains opacity zero instructions', () {
      final duplicate = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0,
      );

      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [duplicate]),
        ShadowRuntimeInstructionCollection(instructions: [duplicate]),
      ]);

      expect(merged.instructions, [duplicate, duplicate]);
      expect(merged.groundStatic, [duplicate, duplicate]);
    });

    test('exposes immutable lists through the collection contract', () {
      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [_shadow()]),
      ]);

      expect(
        () => merged.instructions.add(_shadow()),
        throwsUnsupportedError,
      );
    });
  });
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double opacity = 1,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: 0,
    width: 16,
    height: 8,
    opacity: opacity,
  );
}
