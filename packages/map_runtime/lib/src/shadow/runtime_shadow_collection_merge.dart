import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeInstructionCollection mergeShadowRuntimeInstructionCollections(
  Iterable<ShadowRuntimeInstructionCollection> collections,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final collection in collections) {
    instructions.addAll(collection.instructions);
  }
  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
