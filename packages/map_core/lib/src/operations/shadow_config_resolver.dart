import '../models/shadow.dart';
import '../models/shadow_catalog.dart';

bool _diagnosticsEqualInOrder(
  List<ShadowConfigResolutionDiagnostic> a,
  List<ShadowConfigResolutionDiagnostic> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

bool _hasNumericCustomFields(MapPlacedElementShadowOverride override) {
  return override.offsetX != null ||
      override.offsetY != null ||
      override.scaleX != null ||
      override.scaleY != null ||
      override.opacity != null;
}

/// Fully merged V0 shadow values ready for a later editor or runtime adapter.
///
/// This is not persisted and does not describe a render instruction.
final class ResolvedShadowConfig {
  const ResolvedShadowConfig({
    required this.shadowProfileId,
    required this.mode,
    required this.renderPass,
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.opacity,
    required this.colorHexRgb,
    required this.softnessMode,
  });

  final String shadowProfileId;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedShadowConfig &&
          other.shadowProfileId == shadowProfileId &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        shadowProfileId,
        mode,
        renderPass,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

/// Non-throwing result of V0 shadow config resolution.
final class ShadowConfigResolution {
  ShadowConfigResolution({
    required this.resolved,
    required List<ShadowConfigResolutionDiagnostic> diagnostics,
  }) : diagnostics =
            List<ShadowConfigResolutionDiagnostic>.unmodifiable(diagnostics);

  final ResolvedShadowConfig? resolved;
  final List<ShadowConfigResolutionDiagnostic> diagnostics;

  bool get hasShadow => resolved != null;

  bool get isNone => resolved == null;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowConfigResolution &&
          other.resolved == resolved &&
          _diagnosticsEqualInOrder(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        resolved,
        Object.hashAll(diagnostics),
      );
}

enum ShadowConfigResolutionDiagnosticKind {
  missingShadowProfile,
  customOverrideWithoutBaseProfile,
}

final class ShadowConfigResolutionDiagnostic {
  const ShadowConfigResolutionDiagnostic({
    required this.kind,
    required this.shadowProfileId,
    required this.message,
  });

  final ShadowConfigResolutionDiagnosticKind kind;
  final String? shadowProfileId;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowConfigResolutionDiagnostic &&
          other.kind == kind &&
          other.shadowProfileId == shadowProfileId &&
          other.message == message;

  @override
  int get hashCode => Object.hash(
        kind,
        shadowProfileId,
        message,
      );
}

/// Resolves V0 shadow authoring data without touching maps, collision,
/// occlusion, gameplay, editor state, or runtime rendering.
ShadowConfigResolution resolveShadowConfig({
  required ProjectShadowCatalog catalog,
  required ProjectElementShadowConfig? elementShadow,
  MapPlacedElementShadowOverride? placedOverride,
}) {
  final overrideMode = placedOverride?.mode ?? ShadowOverrideMode.inherit;
  if (overrideMode == ShadowOverrideMode.disabled) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  final elementShadowActive =
      elementShadow != null && elementShadow.castsShadow;
  final isCustomOverride = overrideMode == ShadowOverrideMode.custom;
  final customProfileId =
      isCustomOverride ? placedOverride!.shadowProfileId : null;
  final profileId = customProfileId ??
      (elementShadowActive ? elementShadow.shadowProfileId : null);

  if (profileId == null) {
    if (isCustomOverride && _hasNumericCustomFields(placedOverride!)) {
      return ShadowConfigResolution(
        resolved: null,
        diagnostics: const [
          ShadowConfigResolutionDiagnostic(
            kind: ShadowConfigResolutionDiagnosticKind
                .customOverrideWithoutBaseProfile,
            shadowProfileId: null,
            message:
                'custom shadow override cannot adjust numeric fields without a base shadow profile.',
          ),
        ],
      );
    }

    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  final profile = catalog.profileById(profileId);
  if (profile == null) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: [
        ShadowConfigResolutionDiagnostic(
          kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
          shadowProfileId: profileId,
          message: 'Missing shadow profile "$profileId".',
        ),
      ],
    );
  }

  if (profile.mode == ShadowCasterMode.none) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  var offsetX = profile.offsetX;
  var offsetY = profile.offsetY;
  var scaleX = profile.scaleX;
  var scaleY = profile.scaleY;
  var opacity = profile.opacity;

  if (elementShadowActive) {
    offsetX = elementShadow.offsetX ?? offsetX;
    offsetY = elementShadow.offsetY ?? offsetY;
    scaleX = elementShadow.scaleX ?? scaleX;
    scaleY = elementShadow.scaleY ?? scaleY;
    opacity = elementShadow.opacity ?? opacity;
  }

  if (isCustomOverride) {
    final customOverride = placedOverride!;
    offsetX = customOverride.offsetX ?? offsetX;
    offsetY = customOverride.offsetY ?? offsetY;
    scaleX = customOverride.scaleX ?? scaleX;
    scaleY = customOverride.scaleY ?? scaleY;
    opacity = customOverride.opacity ?? opacity;
  }

  return ShadowConfigResolution(
    resolved: ResolvedShadowConfig(
      shadowProfileId: profile.id,
      mode: profile.mode,
      renderPass: profile.renderPass,
      offsetX: offsetX,
      offsetY: offsetY,
      scaleX: scaleX,
      scaleY: scaleY,
      opacity: opacity,
      colorHexRgb: profile.colorHexRgb,
      softnessMode: profile.softnessMode,
    ),
    diagnostics: const [],
  );
}
