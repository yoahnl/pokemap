part of '../avelune_converter_core.dart';

sealed class SourcePresentationNode extends SourceEventNode {
  const SourcePresentationNode._(super.span,
      {required this.rawDataRef, required this.profileHash});
  final SourcePreservedData rawDataRef;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson();
  Map<String, Object?> get attestation => {
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'profileHash': profileHash.value,
        'waitForCompletion': false,
        'scope': 'map',
        'scopeAdaptation': 'aveluneMapPresentationResetOnTransfer',
        'fullSourceParity': false,
      };
}

final class SourceAudioControlNode extends SourcePresentationNode {
  const SourceAudioControlNode._(super.span,
      {required this.operation,
      required this.channel,
      this.name,
      this.volume,
      this.durationMs,
      required super.rawDataRef,
      required super.profileHash})
      : super._();
  final String operation, channel;
  final String? name;
  final int? volume, durationMs;
  @override
  Map<String, Object?> toJson() => {
        ...attestation,
        'kind': 'audioControl',
        'operation': operation,
        'channel': channel,
        if (name != null) 'name': name,
        if (volume != null) 'volume': volume,
        if (durationMs != null) 'durationMs': durationMs,
      };
}

final class SourcePictureNode extends SourcePresentationNode {
  const SourcePictureNode._(super.span,
      {required this.operation,
      required this.slot,
      this.name,
      this.origin,
      this.x,
      this.y,
      this.scaleX,
      this.scaleY,
      this.opacity,
      this.durationMs = 0,
      required super.rawDataRef,
      required super.profileHash})
      : super._();
  final String operation;
  final int slot, durationMs;
  final String? name;
  final int? origin, x, y, opacity;
  final double? scaleX, scaleY;
  @override
  Map<String, Object?> toJson() => {
        ...attestation,
        'kind': 'picture',
        'operation': operation,
        'slot': slot,
        if (name != null) 'name': name,
        if (origin != null) 'origin': origin,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (scaleX != null) 'scaleX': scaleX,
        if (scaleY != null) 'scaleY': scaleY,
        if (opacity != null) 'opacity': opacity,
        'durationMs': durationMs,
        'referenceWidth': 512,
        'referenceHeight': 384,
      };
}

final class SourceScreenEffectNode extends SourcePresentationNode {
  const SourceScreenEffectNode._(super.span,
      {required this.effect,
      required this.durationMs,
      this.red,
      this.green,
      this.blue,
      this.alpha,
      this.power,
      this.speed,
      required super.rawDataRef,
      required super.profileHash})
      : super._();
  final String effect;
  final int durationMs;
  final double? red, green, blue, alpha;
  final int? power, speed;
  @override
  Map<String, Object?> toJson() => {
        ...attestation,
        'kind': effect,
        'durationMs': durationMs,
        if (effect == 'flash') 'rgba': [red, green, blue, alpha],
        if (effect == 'shake') ...{
          'power': power,
          'speed': speed,
          'nativePresentationAdaptation': 'aveluneReferenceShake',
          'sourceTemporalParity': false,
        },
      };
}

final class SourceMapFogNode extends SourcePresentationNode {
  SourceMapFogNode._(super.span,
      {required this.name,
      required List<int> parameters,
      required super.rawDataRef,
      required super.profileHash})
      : parameters = List.unmodifiable(parameters),
        super._();
  final String name;
  final List<int> parameters;
  @override
  Map<String, Object?> toJson() => {
        ...attestation,
        'kind': 'mapFog',
        'name': name,
        'parameters': parameters,
        'targetQualification': 'sourceMapFogUnsupported',
      };
}

Iterable<SourceEventNode> sourcePresentationProgramNodes(
    SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    yield node;
    switch (node) {
      case SourceConditionalNode():
        yield* sourcePresentationProgramNodes(node.whenTrue);
        yield* sourcePresentationProgramNodes(node.whenFalse);
      case SourceCommonEventCallNode():
        yield* sourcePresentationProgramNodes(node.body);
      case SourceChoiceNode():
        for (final branch in node.branches) {
          yield* sourcePresentationProgramNodes(branch.body);
        }
        if (node.cancelBranch != null) {
          yield* sourcePresentationProgramNodes(node.cancelBranch!);
        }
      case SourceTextNode():
        if (node.followingChoice != null) {
          yield* sourcePresentationProgramNodes(SourceEventBlock(
              nodes: [node.followingChoice!], span: node.span));
        }
      default:
        break;
    }
  }
}
