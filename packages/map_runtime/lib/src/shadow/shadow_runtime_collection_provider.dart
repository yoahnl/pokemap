import 'shadow_runtime_instruction_collection.dart';

typedef ShadowRuntimeInstructionCollectionProvider
    = ShadowRuntimeInstructionCollection? Function();

final class ShadowRuntimeCollectionController {
  ShadowRuntimeCollectionController([
    ShadowRuntimeInstructionCollection? initialCollection,
  ]) : _current = initialCollection;

  ShadowRuntimeInstructionCollection? _current;

  ShadowRuntimeInstructionCollection? get current => _current;

  ShadowRuntimeInstructionCollection? provide() => _current;

  void replace(ShadowRuntimeInstructionCollection? collection) {
    _current = collection;
  }

  void clear() {
    _current = null;
  }
}
