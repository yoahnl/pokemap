import 'package:map_core/map_core.dart';

enum ElementShadowReadStatus {
  notConfigured,
  disabled,
  active,
  missingProfile,
  profileNone,
}

enum ElementShadowDiagnosticSeverity {
  warning,
  error,
}

final class ShadowProfileOptionReadModel {
  const ShadowProfileOptionReadModel({
    required this.id,
    required this.name,
    required this.mode,
    required this.renderPass,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String name;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double opacity;
  final String colorHexRgb;

  bool get isNoneMode => mode == ShadowCasterMode.none;

  String get label => name.trim().isEmpty ? id : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowProfileOptionReadModel &&
          other.id == id &&
          other.name == name &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mode,
        renderPass,
        opacity,
        colorHexRgb,
      );
}

final class ElementShadowDiagnosticReadModel {
  const ElementShadowDiagnosticReadModel({
    required this.severity,
    required this.code,
    required this.message,
  });

  final ElementShadowDiagnosticSeverity severity;
  final String code;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementShadowDiagnosticReadModel &&
          other.severity == severity &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(severity, code, message);
}

final class ElementShadowReadModel {
  ElementShadowReadModel({
    required this.elementId,
    required this.status,
    required this.hasShadowConfig,
    required this.castsShadow,
    required this.shadowProfileId,
    required this.shadowProfileName,
    required this.profileExists,
    required this.resolved,
    required List<ElementShadowDiagnosticReadModel> diagnostics,
    required List<ShadowProfileOptionReadModel> profileOptions,
    this.offsetXOverride,
    this.offsetYOverride,
    this.scaleXOverride,
    this.scaleYOverride,
    this.opacityOverride,
  })  : diagnostics =
            List<ElementShadowDiagnosticReadModel>.unmodifiable(diagnostics),
        profileOptions =
            List<ShadowProfileOptionReadModel>.unmodifiable(profileOptions);

  final String elementId;
  final ElementShadowReadStatus status;
  final bool hasShadowConfig;
  final bool castsShadow;
  final String? shadowProfileId;
  final String? shadowProfileName;
  final bool profileExists;
  final ResolvedShadowConfig? resolved;
  final List<ElementShadowDiagnosticReadModel> diagnostics;
  final List<ShadowProfileOptionReadModel> profileOptions;
  final double? offsetXOverride;
  final double? offsetYOverride;
  final double? scaleXOverride;
  final double? scaleYOverride;
  final double? opacityOverride;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementShadowReadModel &&
          other.elementId == elementId &&
          other.status == status &&
          other.hasShadowConfig == hasShadowConfig &&
          other.castsShadow == castsShadow &&
          other.shadowProfileId == shadowProfileId &&
          other.shadowProfileName == shadowProfileName &&
          other.profileExists == profileExists &&
          other.resolved == resolved &&
          _listEquals(other.diagnostics, diagnostics) &&
          _listEquals(other.profileOptions, profileOptions) &&
          other.offsetXOverride == offsetXOverride &&
          other.offsetYOverride == offsetYOverride &&
          other.scaleXOverride == scaleXOverride &&
          other.scaleYOverride == scaleYOverride &&
          other.opacityOverride == opacityOverride;

  @override
  int get hashCode => Object.hash(
        elementId,
        status,
        hasShadowConfig,
        castsShadow,
        shadowProfileId,
        shadowProfileName,
        profileExists,
        resolved,
        Object.hashAll(diagnostics),
        Object.hashAll(profileOptions),
        offsetXOverride,
        offsetYOverride,
        scaleXOverride,
        scaleYOverride,
        opacityOverride,
      );
}

List<ShadowProfileOptionReadModel> buildShadowProfileOptions(
  ProjectShadowCatalog catalog,
) {
  return List<ShadowProfileOptionReadModel>.unmodifiable(
    catalog.profiles.map(
      (profile) => ShadowProfileOptionReadModel(
        id: profile.id,
        name: profile.name,
        mode: profile.mode,
        renderPass: profile.renderPass,
        opacity: profile.opacity,
        colorHexRgb: profile.colorHexRgb,
      ),
    ),
  );
}

List<ShadowProfileOptionReadModel> buildShadowProfileOptionsForManifest(
  ProjectManifest manifest,
) {
  return buildShadowProfileOptions(manifest.shadowCatalog);
}

ElementShadowReadModel buildElementShadowReadModel({
  required ProjectManifest manifest,
  required ProjectElementEntry element,
}) {
  final catalog = manifest.shadowCatalog;
  final profileOptions = buildShadowProfileOptions(catalog);
  final shadow = element.shadow;

  if (shadow == null) {
    return ElementShadowReadModel(
      elementId: element.id,
      status: ElementShadowReadStatus.notConfigured,
      hasShadowConfig: false,
      castsShadow: false,
      shadowProfileId: null,
      shadowProfileName: null,
      profileExists: false,
      resolved: null,
      diagnostics: const [],
      profileOptions: profileOptions,
    );
  }

  final profileId = shadow.shadowProfileId;
  final profile = profileId == null ? null : catalog.profileById(profileId);
  final profileExists = profile != null;

  if (!shadow.castsShadow) {
    return ElementShadowReadModel(
      elementId: element.id,
      status: ElementShadowReadStatus.disabled,
      hasShadowConfig: true,
      castsShadow: false,
      shadowProfileId: profileId,
      shadowProfileName: profile?.name,
      profileExists: profileExists,
      resolved: null,
      diagnostics: const [],
      profileOptions: profileOptions,
      offsetXOverride: shadow.offsetX,
      offsetYOverride: shadow.offsetY,
      scaleXOverride: shadow.scaleX,
      scaleYOverride: shadow.scaleY,
      opacityOverride: shadow.opacity,
    );
  }

  final resolution = resolveShadowConfig(
    catalog: catalog,
    elementShadow: shadow,
  );
  final diagnostics = _readDiagnosticsFromResolution(resolution);
  final status = _statusForActiveShadow(
    resolution: resolution,
    diagnostics: diagnostics,
    profile: profile,
  );

  return ElementShadowReadModel(
    elementId: element.id,
    status: status,
    hasShadowConfig: true,
    castsShadow: true,
    shadowProfileId: profileId,
    shadowProfileName: profile?.name,
    profileExists: profileExists,
    resolved:
        status == ElementShadowReadStatus.active ? resolution.resolved : null,
    diagnostics: diagnostics,
    profileOptions: profileOptions,
    offsetXOverride: shadow.offsetX,
    offsetYOverride: shadow.offsetY,
    scaleXOverride: shadow.scaleX,
    scaleYOverride: shadow.scaleY,
    opacityOverride: shadow.opacity,
  );
}

List<ElementShadowReadModel> buildElementShadowReadModels(
  ProjectManifest manifest,
) {
  return List<ElementShadowReadModel>.unmodifiable(
    manifest.elements.map(
      (element) => buildElementShadowReadModel(
        manifest: manifest,
        element: element,
      ),
    ),
  );
}

ElementShadowReadStatus _statusForActiveShadow({
  required ShadowConfigResolution resolution,
  required List<ElementShadowDiagnosticReadModel> diagnostics,
  required ProjectShadowProfile? profile,
}) {
  if (diagnostics.any(
    (diagnostic) => diagnostic.code == 'missingShadowProfile',
  )) {
    return ElementShadowReadStatus.missingProfile;
  }
  if (resolution.resolved != null) {
    return ElementShadowReadStatus.active;
  }
  if (profile?.mode == ShadowCasterMode.none) {
    return ElementShadowReadStatus.profileNone;
  }
  return ElementShadowReadStatus.notConfigured;
}

List<ElementShadowDiagnosticReadModel> _readDiagnosticsFromResolution(
  ShadowConfigResolution resolution,
) {
  return List<ElementShadowDiagnosticReadModel>.unmodifiable(
    resolution.diagnostics.map(_readDiagnosticFromResolution),
  );
}

ElementShadowDiagnosticReadModel _readDiagnosticFromResolution(
  ShadowConfigResolutionDiagnostic diagnostic,
) {
  switch (diagnostic.kind) {
    case ShadowConfigResolutionDiagnosticKind.missingShadowProfile:
      return ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: diagnostic.message,
      );
    case ShadowConfigResolutionDiagnosticKind.customOverrideWithoutBaseProfile:
      return ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.warning,
        code: 'customOverrideWithoutBaseProfile',
        message: diagnostic.message,
      );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
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
