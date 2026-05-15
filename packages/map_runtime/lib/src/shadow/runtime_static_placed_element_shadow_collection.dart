import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'static_placed_element_shadow_runtime_resolver.dart';

final class RuntimeStaticPlacedElementShadowSource {
  RuntimeStaticPlacedElementShadowSource({
    required this.id,
    required this.elementId,
    required this.elementShadow,
    this.placedOverride,
    required this.metrics,
    this.isVisible = true,
  }) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(elementId, 'elementId');
  }

  final String id;
  final String elementId;
  final ProjectElementShadowConfig? elementShadow;
  final MapPlacedElementShadowOverride? placedOverride;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final bool isVisible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeStaticPlacedElementShadowSource &&
          other.id == id &&
          other.elementId == elementId &&
          other.elementShadow == elementShadow &&
          other.placedOverride == placedOverride &&
          other.metrics == metrics &&
          other.isVisible == isVisible;

  @override
  int get hashCode => Object.hash(
        id,
        elementId,
        elementShadow,
        placedOverride,
        metrics,
        isVisible,
      );
}

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollection({
  required ProjectShadowCatalog catalog,
  required Iterable<RuntimeStaticPlacedElementShadowSource> sources,
}) {
  final inputs = <StaticPlacedElementShadowRuntimeInput>[];
  for (final source in sources) {
    if (!source.isVisible) {
      continue;
    }
    final resolution = resolveShadowConfig(
      catalog: catalog,
      elementShadow: source.elementShadow,
      placedOverride: source.placedOverride,
    );
    final resolved = resolution.resolved;
    if (resolved == null) {
      continue;
    }
    inputs.add(
      StaticPlacedElementShadowRuntimeInput(
        resolvedConfig: resolved,
        metrics: source.metrics,
      ),
    );
  }
  return ShadowRuntimeInstructionCollection(
    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
  );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException(
      'RuntimeStaticPlacedElementShadowSource.$name must not be blank',
    );
  }
}
