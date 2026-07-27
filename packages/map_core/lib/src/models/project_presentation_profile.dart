// ignore_for_file: invalid_annotation_target

import 'dart:math' as math;

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

enum ProjectTypographyRole { display, body, dialogue, numbers }

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
class ProjectIntroVideoProfile with _$ProjectIntroVideoProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectIntroVideoProfile({
    required String videoPath,
    @JsonKey(includeIfNull: false) String? posterPath,
    @JsonKey(includeIfNull: false) String? captionsPath,
    required int durationMilliseconds,
    required int width,
    required int height,
    required int bitrateKbps,
    required int sizeBytes,
    required String videoCodec,
    @Default('none') String audioCodec,
    @Default('poster') String reducedMotionBehavior,
    @Default(true) bool allowReplay,
  }) = _ProjectIntroVideoProfile;

  factory ProjectIntroVideoProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectIntroVideoProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class ProjectTypographyRoleProfile with _$ProjectTypographyRoleProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTypographyRoleProfile({
    @JsonKey(includeIfNull: false) String? fontPath,
    @JsonKey(includeIfNull: false) String? family,
    @JsonKey(includeIfNull: false) String? licensePath,
    @Default(false) bool redistributable,
    @Default(<String>['sans-serif']) List<String> fallbackFamilies,
    @Default(<String>[]) List<String> glyphCoverage,
  }) = _ProjectTypographyRoleProfile;

  factory ProjectTypographyRoleProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectTypographyRoleProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class ProjectTypographyProfile with _$ProjectTypographyProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTypographyProfile({
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile display,
    @Default(ProjectTypographyRoleProfile()) ProjectTypographyRoleProfile body,
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile dialogue,
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile numbers,
  }) = _ProjectTypographyProfile;

  factory ProjectTypographyProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectTypographyProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class ProjectSemanticThemeProfile with _$ProjectSemanticThemeProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSemanticThemeProfile({
    required String primary,
    required String onPrimary,
    required String background,
    required String surface,
    required String surfaceElevated,
    required String textPrimary,
    required String textSecondary,
    required String outline,
    required String success,
    required String warning,
    required String danger,
    required String titleSurface,
    required String dialogueSurface,
    required String menuSurface,
    required String overworldHudSurface,
    required String battleHudSurface,
  }) = _ProjectSemanticThemeProfile;

  factory ProjectSemanticThemeProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectSemanticThemeProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class ProjectPresentationProfile with _$ProjectPresentationProfile {
  const ProjectPresentationProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationProfile({
    @Default(ProjectPresentationProfile.supportedSchemaVersion)
    int schemaVersion,
    @Default(ProjectBrandingProfile()) ProjectBrandingProfile branding,
    @JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro,
    @JsonKey(includeIfNull: false) ProjectTypographyProfile? typography,
    @JsonKey(includeIfNull: false) ProjectSemanticThemeProfile? theme,
  }) = _ProjectPresentationProfile;

  factory ProjectPresentationProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresentationProfileFromJson(json);

  static const int supportedSchemaVersion = 1;

  Set<ProjectPresentationCategory> get configuredCategories =>
      <ProjectPresentationCategory>{
        if (_hasBranding(branding)) ProjectPresentationCategory.branding,
        if (intro != null) ProjectPresentationCategory.intro,
        if (typography != null) ProjectPresentationCategory.typography,
        if (theme != null) ProjectPresentationCategory.theme,
      };
}

const int projectIntroVideoMaxDurationMilliseconds = 120000;
const int projectIntroVideoMaxWidth = 1920;
const int projectIntroVideoMaxHeight = 1080;
const int projectIntroVideoMaxBitrateKbps = 12000;
const int projectIntroVideoMaxSizeBytes = 100 * 1024 * 1024;

const Set<String> supportedProjectTitleLayoutVariants = <String>{
  'standard',
  'centered',
  'cinematic',
};

const Set<String> requiredProjectFontGlyphCoverage = <String>{
  'latin',
  'latinExtended',
  'digits',
  'punctuation',
};

const double projectSemanticTextContrastRatio = 4.5;
const double projectSemanticNonTextContrastRatio = 3;

const ProjectSemanticThemeProfile safeProjectSemanticTheme =
    ProjectSemanticThemeProfile(
  primary: '#003A44',
  onPrimary: '#FFFFFF',
  background: '#F4F7FB',
  surface: '#FFFFFF',
  surfaceElevated: '#EAF0F8',
  textPrimary: '#101827',
  textSecondary: '#526176',
  outline: '#65758B',
  success: '#16794B',
  warning: '#8A5100',
  danger: '#B4233C',
  titleSurface: '#D9F4F6',
  dialogueSurface: '#FFFFFF',
  menuSurface: '#EAF0F8',
  overworldHudSurface: '#FFFFFF',
  battleHudSurface: '#FFFFFF',
);

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

  if (!supportedProjectTitleLayoutVariants.contains(branding.layoutVariant)) {
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
  _validateIntroVideo(profile.intro, diagnostics);
  _validateTypography(profile.typography, diagnostics);
  if (profile.theme case final theme?) {
    diagnostics.addAll(validateProjectSemanticTheme(theme));
  }
  return List<ProjectPresentationDiagnostic>.unmodifiable(diagnostics);
}

List<ProjectPresentationDiagnostic> validateProjectSemanticTheme(
  ProjectSemanticThemeProfile theme,
) {
  final diagnostics = <ProjectPresentationDiagnostic>[];
  final colors = <String, String>{
    'primary': theme.primary,
    'onPrimary': theme.onPrimary,
    'background': theme.background,
    'surface': theme.surface,
    'surfaceElevated': theme.surfaceElevated,
    'textPrimary': theme.textPrimary,
    'textSecondary': theme.textSecondary,
    'outline': theme.outline,
    'success': theme.success,
    'warning': theme.warning,
    'danger': theme.danger,
    'titleSurface': theme.titleSurface,
    'dialogueSurface': theme.dialogueSurface,
    'menuSurface': theme.menuSurface,
    'overworldHudSurface': theme.overworldHudSurface,
    'battleHudSurface': theme.battleHudSurface,
  };
  final parsed = <String, ({double red, double green, double blue})>{};
  for (final entry in colors.entries) {
    final color = _parseOpaqueProjectColor(entry.value);
    if (color == null) {
      diagnostics.add(
        ProjectPresentationDiagnostic(
          code: 'themeColorInvalid',
          category: ProjectPresentationCategory.theme,
          severity: ProjectPresentationDiagnosticSeverity.error,
          path: '\$.presentation.theme.${entry.key}',
          message: 'Use an opaque hexadecimal color such as #086D7A.',
        ),
      );
    } else {
      parsed[entry.key] = color;
    }
  }

  final contrastPairs = <({
    String foreground,
    String background,
    double minimum,
  })>[
    (
      foreground: 'onPrimary',
      background: 'primary',
      minimum: projectSemanticTextContrastRatio,
    ),
    for (final background in <String>[
      'background',
      'surface',
      'surfaceElevated',
      'titleSurface',
      'dialogueSurface',
      'menuSurface',
      'overworldHudSurface',
      'battleHudSurface',
    ])
      (
        foreground: 'textPrimary',
        background: background,
        minimum: projectSemanticTextContrastRatio,
      ),
    for (final background in <String>[
      'background',
      'surface',
      'surfaceElevated',
    ])
      (
        foreground: 'textSecondary',
        background: background,
        minimum: projectSemanticTextContrastRatio,
      ),
    for (final foreground in <String>[
      'outline',
      'success',
      'warning',
      'danger',
    ])
      (
        foreground: foreground,
        background: 'surface',
        minimum: projectSemanticNonTextContrastRatio,
      ),
  ];
  for (final pair in contrastPairs) {
    final foreground = parsed[pair.foreground];
    final background = parsed[pair.background];
    if (foreground == null || background == null) continue;
    final ratio = _contrastRatio(foreground, background);
    if (ratio >= pair.minimum) continue;
    diagnostics.add(
      ProjectPresentationDiagnostic(
        code: 'themeContrastInsufficient',
        category: ProjectPresentationCategory.theme,
        severity: ProjectPresentationDiagnosticSeverity.error,
        path: '\$.presentation.theme.${pair.foreground}On${pair.background}',
        message:
            'Contrast must be at least ${pair.minimum.toStringAsFixed(1)}:1 '
            '(current ${ratio.toStringAsFixed(2)}:1).',
      ),
    );
  }
  return List<ProjectPresentationDiagnostic>.unmodifiable(diagnostics);
}

({double red, double green, double blue})? _parseOpaqueProjectColor(
  String source,
) {
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(source)) return null;
  return (
    red: int.parse(source.substring(1, 3), radix: 16) / 255,
    green: int.parse(source.substring(3, 5), radix: 16) / 255,
    blue: int.parse(source.substring(5, 7), radix: 16) / 255,
  );
}

double _contrastRatio(
  ({double red, double green, double blue}) foreground,
  ({double red, double green, double blue}) background,
) {
  final foregroundLuminance = _relativeLuminance(foreground);
  final backgroundLuminance = _relativeLuminance(background);
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(({double red, double green, double blue}) color) =>
    0.2126 * _linearColorComponent(color.red) +
    0.7152 * _linearColorComponent(color.green) +
    0.0722 * _linearColorComponent(color.blue);

double _linearColorComponent(double component) => component <= 0.04045
    ? component / 12.92
    : math.pow((component + 0.055) / 1.055, 2.4).toDouble();

void _validateIntroVideo(
  ProjectIntroVideoProfile? intro,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (intro == null) return;
  void error(String code, String field, String message) {
    diagnostics.add(
      ProjectPresentationDiagnostic(
        code: code,
        category: ProjectPresentationCategory.intro,
        severity: ProjectPresentationDiagnosticSeverity.error,
        path: r'$.presentation.intro.' + field,
        message: message,
      ),
    );
  }

  for (final asset in <({String field, String? value})>[
    (field: 'videoPath', value: intro.videoPath),
    (field: 'posterPath', value: intro.posterPath),
    (field: 'captionsPath', value: intro.captionsPath),
  ]) {
    final value = asset.value;
    if (value != null && !_isSafeProjectRelativePath(value)) {
      error(
        'presentationAssetPathUnsafe',
        asset.field,
        'Choose a file located inside the project.',
      );
    }
  }
  if (intro.posterPath == null) {
    error(
      'introPosterRequired',
      'posterPath',
      'Choose a poster image so the intro always has a safe fallback.',
    );
  }
  if (!intro.videoPath.toLowerCase().endsWith('.mp4')) {
    error(
      'introContainerUnsupported',
      'videoPath',
      'Intro videos must use the cross-platform MP4 container.',
    );
  }
  final posterPath = intro.posterPath?.toLowerCase();
  if (posterPath != null &&
      !const <String>['.png', '.jpg', '.jpeg', '.webp']
          .any(posterPath.endsWith)) {
    error(
      'introPosterFormatUnsupported',
      'posterPath',
      'Poster images must use PNG, JPEG, or WebP.',
    );
  }
  final captionsPath = intro.captionsPath?.toLowerCase();
  if (captionsPath != null && !captionsPath.endsWith('.vtt')) {
    error(
      'introCaptionsFormatUnsupported',
      'captionsPath',
      'Captions must use WebVTT.',
    );
  }
  if (intro.durationMilliseconds <= 0 ||
      intro.durationMilliseconds > projectIntroVideoMaxDurationMilliseconds) {
    error(
      'introDurationExceeded',
      'durationMilliseconds',
      'Intro duration must be between 1 ms and 120 seconds.',
    );
  }
  if (intro.width <= 0 ||
      intro.height <= 0 ||
      intro.width > projectIntroVideoMaxWidth ||
      intro.height > projectIntroVideoMaxHeight) {
    error(
      'introResolutionExceeded',
      'width',
      'Intro resolution must not exceed 1920 × 1080.',
    );
  }
  if (intro.bitrateKbps <= 0 ||
      intro.bitrateKbps > projectIntroVideoMaxBitrateKbps) {
    error(
      'introBitrateExceeded',
      'bitrateKbps',
      'Intro bitrate must not exceed 12,000 kbps.',
    );
  }
  if (intro.sizeBytes <= 0 || intro.sizeBytes > projectIntroVideoMaxSizeBytes) {
    error(
      'introSizeExceeded',
      'sizeBytes',
      'Intro video must not exceed 100 MiB.',
    );
  }
  if (intro.videoCodec != 'h264') {
    error(
      'introVideoCodecUnsupported',
      'videoCodec',
      'Intro video must use H.264.',
    );
  }
  if (!const <String>{'aac', 'none'}.contains(intro.audioCodec)) {
    error(
      'introAudioCodecUnsupported',
      'audioCodec',
      'Intro audio must use AAC or be omitted.',
    );
  }
  if (!const <String>{'poster', 'skip'}.contains(intro.reducedMotionBehavior)) {
    error(
      'introReducedMotionBehaviorUnsupported',
      'reducedMotionBehavior',
      'Reduced motion must show the poster or skip the intro.',
    );
  }
  if (intro.audioCodec != 'none' && intro.captionsPath == null) {
    diagnostics.add(
      const ProjectPresentationDiagnostic(
        code: 'introCaptionsRecommended',
        category: ProjectPresentationCategory.intro,
        severity: ProjectPresentationDiagnosticSeverity.warning,
        path: r'$.presentation.intro.captionsPath',
        message: 'Add WebVTT captions for spoken or meaningful audio.',
      ),
    );
  }
}

void _validateTypography(
  ProjectTypographyProfile? typography,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (typography == null) return;
  final roles = <String, ProjectTypographyRoleProfile>{
    'display': typography.display,
    'body': typography.body,
    'dialogue': typography.dialogue,
    'numbers': typography.numbers,
  };
  for (final entry in roles.entries) {
    final roleName = entry.key;
    final role = entry.value;
    void error(String code, String field, String message) {
      diagnostics.add(
        ProjectPresentationDiagnostic(
          code: code,
          category: ProjectPresentationCategory.typography,
          severity: ProjectPresentationDiagnosticSeverity.error,
          path: '\$.presentation.typography.$roleName.$field',
          message: message,
        ),
      );
    }

    if (role.fallbackFamilies.isEmpty ||
        role.fallbackFamilies.any((family) => family.trim().isEmpty)) {
      error(
        'typographyFallbackRequired',
        'fallbackFamilies',
        'Choose at least one explicit system fallback.',
      );
    }
    final fontPath = role.fontPath;
    if (fontPath == null) continue;
    if (!_isSafeProjectRelativePath(fontPath)) {
      error(
        'presentationAssetPathUnsafe',
        'fontPath',
        'Choose a font located inside the project.',
      );
    }
    if (!const <String>['.ttf', '.otf'].any(fontPath.toLowerCase().endsWith)) {
      error(
        'typographyFormatUnsupported',
        'fontPath',
        'Embedded fonts must use TTF or OTF.',
      );
    }
    if (role.family == null || role.family!.trim().isEmpty) {
      error(
        'typographyFamilyRequired',
        'family',
        'The embedded font family name is required.',
      );
    }
    final licensePath = role.licensePath;
    if (licensePath == null || licensePath.trim().isEmpty) {
      error(
        'typographyLicenseRequired',
        'licensePath',
        'Attach the redistribution license before export.',
      );
    } else if (!_isSafeProjectRelativePath(licensePath)) {
      error(
        'presentationAssetPathUnsafe',
        'licensePath',
        'Choose a license located inside the project.',
      );
    }
    if (!role.redistributable) {
      error(
        'typographyRedistributionRequired',
        'redistributable',
        'Confirm that this font may be redistributed with the game.',
      );
    }
    if (!role.glyphCoverage.toSet().containsAll(
          requiredProjectFontGlyphCoverage,
        )) {
      error(
        'typographyGlyphCoverageIncomplete',
        'glyphCoverage',
        'The font must cover Latin, extended Latin, digits, and punctuation.',
      );
    }
  }
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
