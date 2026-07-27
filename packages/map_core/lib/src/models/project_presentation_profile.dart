// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_presentation_profile.freezed.dart';
part 'project_presentation_profile.g.dart';

/// Stable sections exposed by the no-code Personalization Hub.
enum ProjectPresentationCategory {
  branding,
  intro,
  typography,
  theme,
}

enum ProjectPresentationDiagnosticSeverity {
  warning,
  error,
}

@freezed
class ProjectPresentationDiagnostic with _$ProjectPresentationDiagnostic {
  const factory ProjectPresentationDiagnostic({
    required String code,
    required ProjectPresentationCategory category,
    required ProjectPresentationDiagnosticSeverity severity,
    required String path,
    required String message,
  }) = _ProjectPresentationDiagnostic;
}

@Freezed(fromJson: true, toJson: true)
class ProjectBrandingProfile with _$ProjectBrandingProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectBrandingProfile({
    @JsonKey(includeIfNull: false) String? iconPath,
    @JsonKey(includeIfNull: false) String? coverPath,
    @JsonKey(includeIfNull: false) String? heroPath,
    @JsonKey(includeIfNull: false) String? accentColor,
    @JsonKey(includeIfNull: false) String? titleMusicPath,
    @Default('standard') String layoutVariant,
  }) = _ProjectBrandingProfile;

  factory ProjectBrandingProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectBrandingProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class ProjectPresentationProfile with _$ProjectPresentationProfile {
  const ProjectPresentationProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationProfile({
    @Default(ProjectPresentationProfile.supportedSchemaVersion)
    int schemaVersion,
    @Default(ProjectBrandingProfile()) ProjectBrandingProfile branding,
  }) = _ProjectPresentationProfile;

  factory ProjectPresentationProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresentationProfileFromJson(json);

  static const int supportedSchemaVersion = 1;

  Set<ProjectPresentationCategory> get configuredCategories =>
      <ProjectPresentationCategory>{
        if (_hasBranding(branding)) ProjectPresentationCategory.branding,
      };
}

const Set<String> supportedProjectTitleLayoutVariants = <String>{
  'standard',
  'centered',
  'cinematic',
};

List<ProjectPresentationDiagnostic> validateProjectPresentationProfile(
  ProjectPresentationProfile profile,
) {
  final diagnostics = <ProjectPresentationDiagnostic>[];
  if (profile.schemaVersion !=
      ProjectPresentationProfile.supportedSchemaVersion) {
    diagnostics.add(
      const ProjectPresentationDiagnostic(
        code: 'presentationVersionUnsupported',
        category: ProjectPresentationCategory.branding,
        severity: ProjectPresentationDiagnosticSeverity.error,
        path: r'$.presentation.schemaVersion',
        message: 'This presentation profile version is not supported.',
      ),
    );
  }

  final branding = profile.branding;
  for (final asset in <({String field, String? value})>[
    (field: 'iconPath', value: branding.iconPath),
    (field: 'coverPath', value: branding.coverPath),
    (field: 'heroPath', value: branding.heroPath),
    (field: 'titleMusicPath', value: branding.titleMusicPath),
  ]) {
    final value = asset.value;
    if (value != null && !_isSafeProjectRelativePath(value)) {
      diagnostics.add(
        ProjectPresentationDiagnostic(
          code: 'presentationAssetPathUnsafe',
          category: ProjectPresentationCategory.branding,
          severity: ProjectPresentationDiagnosticSeverity.error,
          path: r'$.presentation.branding.' + asset.field,
          message: 'Choose a file located inside the project.',
        ),
      );
    }
  }

  final accent = branding.accentColor;
  if (accent != null &&
      !RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(accent)) {
    diagnostics.add(
      const ProjectPresentationDiagnostic(
        code: 'presentationAccentColorInvalid',
        category: ProjectPresentationCategory.branding,
        severity: ProjectPresentationDiagnosticSeverity.error,
        path: r'$.presentation.branding.accentColor',
        message: 'Use a hexadecimal color such as #6750A4.',
      ),
    );
  }

  if (!supportedProjectTitleLayoutVariants
      .contains(branding.layoutVariant)) {
    diagnostics.add(
      const ProjectPresentationDiagnostic(
        code: 'presentationLayoutUnsupported',
        category: ProjectPresentationCategory.branding,
        severity: ProjectPresentationDiagnosticSeverity.error,
        path: r'$.presentation.branding.layoutVariant',
        message: 'Choose a supported title layout.',
      ),
    );
  }
  return List<ProjectPresentationDiagnostic>.unmodifiable(diagnostics);
}

bool _hasBranding(ProjectBrandingProfile branding) =>
    branding.iconPath != null ||
    branding.coverPath != null ||
    branding.heroPath != null ||
    branding.accentColor != null ||
    branding.titleMusicPath != null ||
    branding.layoutVariant != 'standard';

bool _isSafeProjectRelativePath(String source) {
  final value = source.trim();
  if (value.isEmpty ||
      value.startsWith('/') ||
      value.startsWith(r'\') ||
      value.contains(r'\')) {
    return false;
  }
  return !value.split('/').any((segment) => segment == '..' || segment.isEmpty);
}
