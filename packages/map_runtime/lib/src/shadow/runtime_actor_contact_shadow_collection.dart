import 'package:map_core/map_core.dart';

import 'actor_contact_shadow_runtime_resolver.dart';
import 'shadow_runtime_instruction_collection.dart';

const ResolvedShadowConfig kDefaultRuntimeActorContactShadowConfig =
    ResolvedShadowConfig(
  shadowProfileId: 'runtime_actor_contact_default',
  mode: ShadowCasterMode.contactBlob,
  renderPass: ShadowRenderPass.actorContact,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 0.35,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
);

final class RuntimeActorContactShadowSource {
  RuntimeActorContactShadowSource({
    required this.id,
    required this.footWorldX,
    required this.footWorldY,
    required this.visualWidth,
    required this.visualHeight,
    this.isVisible = true,
  }) {
    _validateFinite(footWorldX, 'footWorldX');
    _validateFinite(footWorldY, 'footWorldY');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
  }

  final String id;
  final double footWorldX;
  final double footWorldY;
  final double visualWidth;
  final double visualHeight;
  final bool isVisible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeActorContactShadowSource &&
          other.id == id &&
          other.footWorldX == footWorldX &&
          other.footWorldY == footWorldY &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.isVisible == isVisible;

  @override
  int get hashCode => Object.hash(
        id,
        footWorldX,
        footWorldY,
        visualWidth,
        visualHeight,
        isVisible,
      );
}

ShadowRuntimeInstructionCollection buildRuntimeActorContactShadowCollection({
  required Iterable<RuntimeActorContactShadowSource> sources,
  ResolvedShadowConfig resolvedConfig = kDefaultRuntimeActorContactShadowConfig,
}) {
  final inputs = <ActorContactShadowRuntimeInput>[];
  for (final source in sources) {
    if (!source.isVisible) {
      continue;
    }
    inputs.add(
      ActorContactShadowRuntimeInput(
        resolvedConfig: resolvedConfig,
        metrics: ActorContactShadowRuntimeMetrics(
          footWorldX: source.footWorldX,
          footWorldY: source.footWorldY,
          visualWidth: source.visualWidth,
          visualHeight: source.visualHeight,
        ),
      ),
    );
  }
  return ShadowRuntimeInstructionCollection(
    instructions: resolveActorContactShadowRuntimeInstructions(inputs),
  );
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'RuntimeActorContactShadowSource.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'RuntimeActorContactShadowSource.$name must be greater than 0',
    );
  }
}
