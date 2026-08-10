// ignore_for_file: invalid_annotation_target

import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_presentation_layout_profile.dart';
import 'project_presentation_surface_role.dart';
import 'project_presentation_window_profile.dart';

part 'project_presentation_profile.freezed.dart';
part 'project_presentation_profile.g.dart';

/// Stable sections exposed by the no-code Personalization Hub.
enum ProjectPresentationCategory { branding, intro, typography, theme, layouts }

enum ProjectPresentationDiagnosticSeverity { warning, error }

enum ProjectTypographyRole { display, body, dialogue, numbers, combat }

@freezed
abstract class ProjectPresentationDiagnostic
    with _$ProjectPresentationDiagnostic {
  const factory ProjectPresentationDiagnostic({
    required String code,
    required ProjectPresentationCategory category,
    required ProjectPresentationDiagnosticSeverity severity,
    required String path,
    required String message,
  }) = _ProjectPresentationDiagnostic;
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectBrandingProfile with _$ProjectBrandingProfile {
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
abstract class ProjectVideoVariantProfile with _$ProjectVideoVariantProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectVideoVariantProfile({
    required String videoPath,
    required String posterPath,
    @JsonKey(includeIfNull: false) String? captionsPath,
    required int durationMilliseconds,
    required int width,
    required int height,
    required int bitrateKbps,
    required int sizeBytes,
    required String videoCodec,
    @Default('none') String audioCodec,
    @Default(0.5) double focalX,
    @Default(0.5) double focalY,
  }) = _ProjectVideoVariantProfile;

  factory ProjectVideoVariantProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectVideoVariantProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectResponsiveVideoProfile
    with _$ProjectResponsiveVideoProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectResponsiveVideoProfile({
    required ProjectVideoVariantProfile landscape,
    @JsonKey(includeIfNull: false) ProjectVideoVariantProfile? portrait,
  }) = _ProjectResponsiveVideoProfile;

  factory ProjectResponsiveVideoProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectResponsiveVideoProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectIntroVideoProfile with _$ProjectIntroVideoProfile {
  const ProjectIntroVideoProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectIntroVideoProfile({
    required ProjectResponsiveVideoProfile media,
    @Default('poster') String reducedMotionBehavior,
    @Default(true) bool allowReplay,
  }) = _ProjectIntroVideoProfile;

  factory ProjectIntroVideoProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectIntroVideoProfileFromJson(json);

  /// Source-migration helper for callers that still construct one landscape
  /// intro variant with the V1 flat fields.
  static ProjectIntroVideoProfile fromLandscape({
    required String videoPath,
    String? posterPath,
    String? captionsPath,
    required int durationMilliseconds,
    required int width,
    required int height,
    required int bitrateKbps,
    required int sizeBytes,
    required String videoCodec,
    String audioCodec = 'none',
    double focalX = 0.5,
    double focalY = 0.5,
    String reducedMotionBehavior = 'poster',
    bool allowReplay = true,
  }) => ProjectIntroVideoProfile(
    media: ProjectResponsiveVideoProfile(
      landscape: ProjectVideoVariantProfile(
        videoPath: videoPath,
        posterPath: posterPath ?? '',
        captionsPath: captionsPath,
        durationMilliseconds: durationMilliseconds,
        width: width,
        height: height,
        bitrateKbps: bitrateKbps,
        sizeBytes: sizeBytes,
        videoCodec: videoCodec,
        audioCodec: audioCodec,
        focalX: focalX,
        focalY: focalY,
      ),
    ),
    reducedMotionBehavior: reducedMotionBehavior,
    allowReplay: allowReplay,
  );

  /// Landscape compatibility projection for pre-V2 consumers.
  ProjectVideoVariantProfile get landscape => media.landscape;
  String get videoPath => landscape.videoPath;
  String get posterPath => landscape.posterPath;
  String? get captionsPath => landscape.captionsPath;
  int get durationMilliseconds => landscape.durationMilliseconds;
  int get width => landscape.width;
  int get height => landscape.height;
  int get bitrateKbps => landscape.bitrateKbps;
  int get sizeBytes => landscape.sizeBytes;
  String get videoCodec => landscape.videoCodec;
  String get audioCodec => landscape.audioCodec;
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectTitleMotionProfile with _$ProjectTitleMotionProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTitleMotionProfile({
    @JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? promptLoop,
    @JsonKey(includeIfNull: false) ProjectResponsiveVideoProfile? menuLoop,
  }) = _ProjectTitleMotionProfile;

  factory ProjectTitleMotionProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectTitleMotionProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectTypographyRoleProfile
    with _$ProjectTypographyRoleProfile {
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
abstract class ProjectTypographyProfile with _$ProjectTypographyProfile {
  const ProjectTypographyProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectTypographyProfile({
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile display,
    @Default(ProjectTypographyRoleProfile()) ProjectTypographyRoleProfile body,
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile dialogue,
    @Default(ProjectTypographyRoleProfile())
    ProjectTypographyRoleProfile numbers,
    @JsonKey(includeIfNull: false) ProjectTypographyRoleProfile? combat,
  }) = _ProjectTypographyProfile;

  factory ProjectTypographyProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectTypographyProfileFromJson(json);

  ProjectTypographyRoleProfile resolve(ProjectTypographyRole role) =>
      switch (role) {
        ProjectTypographyRole.display => display,
        ProjectTypographyRole.body => body,
        ProjectTypographyRole.dialogue => dialogue,
        ProjectTypographyRole.numbers => numbers,
        ProjectTypographyRole.combat => combat ?? body,
      };
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectSemanticThemeProfile with _$ProjectSemanticThemeProfile {
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
abstract class ProjectMenuLabelsProfile with _$ProjectMenuLabelsProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectMenuLabelsProfile({
    @JsonKey(includeIfNull: false) String? pauseTitle,
    @JsonKey(includeIfNull: false) String? resume,
    @JsonKey(includeIfNull: false) String? party,
    @JsonKey(includeIfNull: false) String? bag,
    @JsonKey(includeIfNull: false) String? pokedex,
    @JsonKey(includeIfNull: false) String? map,
    @JsonKey(includeIfNull: false) String? save,
    @JsonKey(includeIfNull: false) String? options,
    @JsonKey(includeIfNull: false) String? returnToTitle,
  }) = _ProjectMenuLabelsProfile;

  factory ProjectMenuLabelsProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectMenuLabelsProfileFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
abstract class ProjectPresentationProfile with _$ProjectPresentationProfile {
  const ProjectPresentationProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectPresentationProfile({
    @Default(ProjectPresentationProfile.supportedSchemaVersion)
    int schemaVersion,
    @Default(ProjectBrandingProfile()) ProjectBrandingProfile branding,
    @JsonKey(includeIfNull: false) ProjectIntroVideoProfile? intro,
    @JsonKey(includeIfNull: false) ProjectTitleMotionProfile? titleMotion,
    @JsonKey(includeIfNull: false) ProjectTypographyProfile? typography,
    @JsonKey(includeIfNull: false) ProjectSemanticThemeProfile? theme,
    @JsonKey(includeIfNull: false) ProjectMenuLabelsProfile? menuLabels,
    @JsonKey(includeIfNull: false) ProjectPresentationWindowsProfile? windows,
    @JsonKey(includeIfNull: false) ProjectPresentationLayoutsProfile? layouts,
  }) = _ProjectPresentationProfile;

  factory ProjectPresentationProfile.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresentationProfileFromJson(
        _migrateProjectPresentationProfileJson(json),
      );

  static const int supportedSchemaVersion = 5;

  ProjectPresentationWindowsProfile get effectiveWindows =>
      windows ?? legacyProjectPresentationWindows;

  Set<ProjectPresentationCategory> get configuredCategories =>
      <ProjectPresentationCategory>{
        if (_hasBranding(branding) || titleMotion != null)
          ProjectPresentationCategory.branding,
        if (intro != null) ProjectPresentationCategory.intro,
        if (typography != null) ProjectPresentationCategory.typography,
        if (theme != null || menuLabels != null || windows != null)
          ProjectPresentationCategory.theme,
        if (layouts != null) ProjectPresentationCategory.layouts,
      };
}

const int projectIntroVideoMaxDurationMilliseconds = 120000;
const int projectIntroVideoMaxWidth = 1920;
const int projectIntroVideoMaxHeight = 1080;
const int projectIntroVideoMaxBitrateKbps = 12000;
const int projectIntroVideoMaxSizeBytes = 100 * 1024 * 1024;
const int projectIntroResponsiveMaxSizeBytes = 160 * 1024 * 1024;
const int projectTitleLoopMaxDurationMilliseconds = 15000;
const int projectTitleLoopMaxSizeBytes = 24 * 1024 * 1024;
const int projectTitleMotionMaxSizeBytes = 96 * 1024 * 1024;
const int projectPresentationMediaMaxSizeBytes = 220 * 1024 * 1024;

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
const int projectMenuLabelMaxLength = 32;

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
  _validateTitleMotion(profile.titleMotion, diagnostics);
  _validateCombinedPresentationMediaBudget(profile, diagnostics);
  _validateTypography(profile.typography, diagnostics);
  if (profile.theme case final theme?) {
    diagnostics.addAll(validateProjectSemanticTheme(theme));
  }
  _validateMenuLabels(profile.menuLabels, diagnostics);
  _validateWindows(
    profile.windows,
    profile.theme ?? safeProjectSemanticTheme,
    diagnostics,
  );
  _validateLayouts(profile.layouts, diagnostics);
  return List<ProjectPresentationDiagnostic>.unmodifiable(diagnostics);
}

void _validateLayouts(
  ProjectPresentationLayoutsProfile? layouts,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (layouts == null) return;
  for (final entry
      in <
        ({
          String field,
          ProjectPresentationSurfaceRole role,
          ProjectResponsiveSurfaceLayoutProfile profile,
        })
      >[
        (
          field: 'title',
          role: ProjectPresentationSurfaceRole.title,
          profile: layouts.title,
        ),
        (
          field: 'pauseMenu',
          role: ProjectPresentationSurfaceRole.pauseMenu,
          profile: layouts.pauseMenu,
        ),
        (
          field: 'dialogue',
          role: ProjectPresentationSurfaceRole.dialogue,
          profile: layouts.dialogue,
        ),
        if (layouts.battle case final battle?)
          (
            field: 'battle',
            role: ProjectPresentationSurfaceRole.battleHud,
            profile: battle,
          ),
      ]) {
    final variants = <ProjectSurfaceLayoutVariant>[
      entry.profile.compact,
      entry.profile.regular,
      entry.profile.expanded,
    ];
    for (var index = 0; index < variants.length; index++) {
      final variant = variants[index];
      final expectedBreakpoint = ProjectPresentationBreakpoint.values[index];
      final path =
          '\$.presentation.layouts.${entry.field}.${expectedBreakpoint.name}';
      if (variant.breakpoint != expectedBreakpoint) {
        _presentationError(
          diagnostics,
          'presentationLayoutBreakpointMismatch',
          ProjectPresentationCategory.layouts,
          '$path.breakpoint',
          'The layout variant must match its responsive size.',
        );
      }
      if (!projectPresentationLayoutSlotsFor(
        entry.role,
        expectedBreakpoint,
      ).contains(variant.slot)) {
        _presentationError(
          diagnostics,
          'presentationLayoutSlotUnsupported',
          ProjectPresentationCategory.layouts,
          '$path.slot',
          'Choose a position supported by this surface and size.',
        );
      }
      final secondary = variant.visibleSecondaryElements;
      if (secondary.toSet().length != secondary.length) {
        _presentationError(
          diagnostics,
          'presentationLayoutSecondaryElementDuplicate',
          ProjectPresentationCategory.layouts,
          '$path.visibleSecondaryElements',
          'Each secondary element may appear only once.',
        );
      }
      final supported = projectPresentationSecondaryElementsFor(entry.role);
      if (secondary.any((element) => !supported.contains(element))) {
        _presentationError(
          diagnostics,
          'presentationLayoutSecondaryElementUnsupported',
          ProjectPresentationCategory.layouts,
          '$path.visibleSecondaryElements',
          'Only secondary elements from this surface may be shown.',
        );
      }
    }
  }
}

void _validateWindows(
  ProjectPresentationWindowsProfile? windows,
  ProjectSemanticThemeProfile theme,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (windows == null) return;
  final ids = <String>{};
  if (windows.styles.isEmpty || windows.styles.length > 16) {
    _presentationError(
      diagnostics,
      'windowStyleCountOutOfRange',
      ProjectPresentationCategory.theme,
      r'$.presentation.windows.styles',
      'Configure between one and sixteen window styles.',
    );
  }
  for (var index = 0; index < windows.styles.length; index++) {
    final style = windows.styles[index];
    final path = '\$.presentation.windows.styles[$index]';
    if (!RegExp(r'^[a-z][a-z0-9-]{0,31}$').hasMatch(style.id)) {
      _presentationError(
        diagnostics,
        'windowStyleIdInvalid',
        ProjectPresentationCategory.theme,
        '$path.id',
        'Window style identifiers must use lowercase letters and dashes.',
      );
    }
    if (!ids.add(style.id)) {
      _presentationError(
        diagnostics,
        'windowStyleIdDuplicate',
        ProjectPresentationCategory.theme,
        '$path.id',
        'Window style identifiers must be unique.',
      );
    }
    if (!supportedProjectWindowFillTokens.contains(style.fillToken)) {
      _presentationError(
        diagnostics,
        'windowFillTokenUnsupported',
        ProjectPresentationCategory.theme,
        '$path.fillToken',
        'Choose a semantic surface token.',
      );
    }
    if (!supportedProjectWindowBorderTokens.contains(style.borderToken)) {
      _presentationError(
        diagnostics,
        'windowBorderTokenUnsupported',
        ProjectPresentationCategory.theme,
        '$path.borderToken',
        'Choose a semantic border token.',
      );
    }
    if (style.borderWidth > 0 &&
        supportedProjectWindowFillTokens.contains(style.fillToken) &&
        supportedProjectWindowBorderTokens.contains(style.borderToken)) {
      final fill = _parseOpaqueProjectColor(
        _projectThemeToken(theme, style.fillToken),
      );
      final border = _parseOpaqueProjectColor(
        _projectThemeToken(theme, style.borderToken),
      );
      if (fill != null &&
          border != null &&
          _contrastRatio(border, fill) < projectSemanticNonTextContrastRatio) {
        _presentationError(
          diagnostics,
          'windowContrastInsufficient',
          ProjectPresentationCategory.theme,
          '$path.borderToken',
          'Window borders must remain distinct from their surface.',
        );
      }
    }
    _validateWindowRange(
      diagnostics,
      value: style.borderWidth,
      minimum: projectWindowMinBorderWidth,
      maximum: projectWindowMaxBorderWidth,
      code: 'windowBorderWidthOutOfRange',
      path: '$path.borderWidth',
      message: 'Border width is outside the supported range.',
    );
    _validateWindowRange(
      diagnostics,
      value: style.cornerRadius,
      minimum: projectWindowMinCornerRadius,
      maximum: projectWindowMaxCornerRadius,
      code: 'windowCornerRadiusOutOfRange',
      path: '$path.cornerRadius',
      message: 'Corner radius is outside the supported range.',
    );
    _validateWindowRange(
      diagnostics,
      value: style.contentPadding,
      minimum: projectWindowMinContentPadding,
      maximum: projectWindowMaxContentPadding,
      code: 'windowContentPaddingOutOfRange',
      path: '$path.contentPadding',
      message: 'Content padding is outside the supported range.',
    );
    _validateWindowRange(
      diagnostics,
      value: style.shadowElevation,
      minimum: projectWindowMinShadowElevation,
      maximum: projectWindowMaxShadowElevation,
      code: 'windowShadowElevationOutOfRange',
      path: '$path.shadowElevation',
      message: 'Shadow elevation is outside the supported range.',
    );
  }
  _validateWindowRange(
    diagnostics,
    value: windows.pauseBackdropOpacity,
    minimum: projectWindowMinBackdropOpacity,
    maximum: projectWindowMaxBackdropOpacity,
    code: 'windowBackdropOpacityOutOfRange',
    path: r'$.presentation.windows.pauseBackdropOpacity',
    message: 'Pause backdrop opacity is outside the supported range.',
  );
  for (final reference in <({String field, String id})>[
    (field: 'defaultStyleId', id: windows.defaultStyleId),
    (field: 'pauseMenuStyleId', id: windows.pauseMenuStyleId),
    (field: 'dialogueStyleId', id: windows.dialogueStyleId),
    if (windows.battleStyleId case final battleStyleId?)
      (field: 'battleStyleId', id: battleStyleId),
  ]) {
    if (ids.contains(reference.id)) continue;
    _presentationError(
      diagnostics,
      'windowStyleReferenceMissing',
      ProjectPresentationCategory.theme,
      '\$.presentation.windows.${reference.field}',
      'Choose a window style that exists in this profile.',
    );
  }
}

String _projectThemeToken(ProjectSemanticThemeProfile theme, String token) =>
    switch (token) {
      'surface' => theme.surface,
      'surfaceElevated' => theme.surfaceElevated,
      'titleSurface' => theme.titleSurface,
      'dialogueSurface' => theme.dialogueSurface,
      'menuSurface' => theme.menuSurface,
      'overworldHudSurface' => theme.overworldHudSurface,
      'battleHudSurface' => theme.battleHudSurface,
      'outline' => theme.outline,
      'primary' => theme.primary,
      'success' => theme.success,
      'warning' => theme.warning,
      'danger' => theme.danger,
      _ => throw ArgumentError.value(token, 'token'),
    };

void _validateWindowRange(
  List<ProjectPresentationDiagnostic> diagnostics, {
  required num value,
  required num minimum,
  required num maximum,
  required String code,
  required String path,
  required String message,
}) {
  if (value.isFinite && value >= minimum && value <= maximum) return;
  _presentationError(
    diagnostics,
    code,
    ProjectPresentationCategory.theme,
    path,
    message,
  );
}

void _validateMenuLabels(
  ProjectMenuLabelsProfile? labels,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (labels == null) return;
  final values = <String, String?>{
    'pauseTitle': labels.pauseTitle,
    'resume': labels.resume,
    'party': labels.party,
    'bag': labels.bag,
    'pokedex': labels.pokedex,
    'map': labels.map,
    'save': labels.save,
    'options': labels.options,
    'returnToTitle': labels.returnToTitle,
  };
  final controlCharacters = RegExp(r'[\u0000-\u001F\u007F]');
  for (final entry in values.entries) {
    final value = entry.value;
    if (value == null) continue;
    final path = '\$.presentation.menuLabels.${entry.key}';
    if (value.trim().isEmpty) {
      _presentationError(
        diagnostics,
        'menuLabelEmpty',
        ProjectPresentationCategory.theme,
        path,
        'Menu labels must not be empty.',
      );
    }
    if (value.runes.length > projectMenuLabelMaxLength) {
      _presentationError(
        diagnostics,
        'menuLabelTooLong',
        ProjectPresentationCategory.theme,
        path,
        'Menu labels must use at most $projectMenuLabelMaxLength characters.',
      );
    }
    if (controlCharacters.hasMatch(value)) {
      _presentationError(
        diagnostics,
        'menuLabelContainsControlCharacters',
        ProjectPresentationCategory.theme,
        path,
        'Menu labels must remain on one readable line.',
      );
    }
  }
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

  final contrastPairs =
      <({String foreground, String background, double minimum})>[
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
  if (!const <String>{'poster', 'skip'}.contains(intro.reducedMotionBehavior)) {
    _presentationError(
      diagnostics,
      'introReducedMotionBehaviorUnsupported',
      ProjectPresentationCategory.intro,
      r'$.presentation.intro.reducedMotionBehavior',
      'Reduced motion must show the poster or skip the intro.',
    );
  }
  final variants = _responsiveVariants(intro.media);
  for (final entry in variants) {
    _validateVideoVariant(
      entry.variant,
      path: r'$.presentation.intro.media.' + entry.orientation,
      category: ProjectPresentationCategory.intro,
      isPortraitSlot: entry.orientation == 'portrait',
      maxDurationMilliseconds: projectIntroVideoMaxDurationMilliseconds,
      maxSizeBytes: projectIntroVideoMaxSizeBytes,
      durationCode: 'introDurationExceeded',
      sizeCode: 'introSizeExceeded',
      audioAllowed: const <String>{'aac', 'none'},
      diagnostics: diagnostics,
    );
    if (entry.variant.audioCodec != 'none' &&
        entry.variant.captionsPath == null) {
      diagnostics.add(
        ProjectPresentationDiagnostic(
          code: 'introCaptionsRecommended',
          category: ProjectPresentationCategory.intro,
          severity: ProjectPresentationDiagnosticSeverity.warning,
          path:
              r'$.presentation.intro.media.' +
              entry.orientation +
              '.captionsPath',
          message: 'Add WebVTT captions for spoken or meaningful audio.',
        ),
      );
    }
  }
  final combinedSize = variants.fold<int>(
    0,
    (sum, entry) => sum + entry.variant.sizeBytes,
  );
  if (combinedSize > projectIntroResponsiveMaxSizeBytes) {
    _presentationError(
      diagnostics,
      'introCombinedSizeExceeded',
      ProjectPresentationCategory.intro,
      r'$.presentation.intro.media',
      'Landscape and portrait intro videos must total at most 160 MiB.',
    );
  }
}

void _validateTitleMotion(
  ProjectTitleMotionProfile? motion,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  if (motion == null) return;
  for (final loop in <({String name, ProjectResponsiveVideoProfile? media})>[
    (name: 'promptLoop', media: motion.promptLoop),
    (name: 'menuLoop', media: motion.menuLoop),
  ]) {
    final media = loop.media;
    if (media == null) continue;
    for (final entry in _responsiveVariants(media)) {
      _validateVideoVariant(
        entry.variant,
        path:
            r'$.presentation.titleMotion.' +
            loop.name +
            '.${entry.orientation}',
        category: ProjectPresentationCategory.branding,
        isPortraitSlot: entry.orientation == 'portrait',
        maxDurationMilliseconds: projectTitleLoopMaxDurationMilliseconds,
        maxSizeBytes: projectTitleLoopMaxSizeBytes,
        durationCode: 'titleLoopDurationExceeded',
        sizeCode: 'titleLoopSizeExceeded',
        audioAllowed: const <String>{'none'},
        diagnostics: diagnostics,
      );
    }
  }
  final combinedSize = _titleMotionVariants(
    motion,
  ).fold<int>(0, (sum, variant) => sum + variant.sizeBytes);
  if (combinedSize > projectTitleMotionMaxSizeBytes) {
    _presentationError(
      diagnostics,
      'titleMotionCombinedSizeExceeded',
      ProjectPresentationCategory.branding,
      r'$.presentation.titleMotion',
      'All title and menu loops must total at most 96 MiB.',
    );
  }
}

void _validateCombinedPresentationMediaBudget(
  ProjectPresentationProfile profile,
  List<ProjectPresentationDiagnostic> diagnostics,
) {
  final introBytes = profile.intro == null
      ? 0
      : _responsiveVariants(
          profile.intro!.media,
        ).fold<int>(0, (sum, entry) => sum + entry.variant.sizeBytes);
  final titleBytes = profile.titleMotion == null
      ? 0
      : _titleMotionVariants(
          profile.titleMotion!,
        ).fold<int>(0, (sum, variant) => sum + variant.sizeBytes);
  if (introBytes + titleBytes > projectPresentationMediaMaxSizeBytes) {
    _presentationError(
      diagnostics,
      'presentationCombinedSizeExceeded',
      ProjectPresentationCategory.branding,
      r'$.presentation',
      'Presentation videos must total at most 220 MiB.',
    );
  }
}

void _validateVideoVariant(
  ProjectVideoVariantProfile variant, {
  required String path,
  required ProjectPresentationCategory category,
  required bool isPortraitSlot,
  required int maxDurationMilliseconds,
  required int maxSizeBytes,
  required String durationCode,
  required String sizeCode,
  required Set<String> audioAllowed,
  required List<ProjectPresentationDiagnostic> diagnostics,
}) {
  final isIntro = category == ProjectPresentationCategory.intro;
  void error(String code, String field, String message) =>
      _presentationError(diagnostics, code, category, '$path.$field', message);

  for (final asset in <({String field, String? value})>[
    (field: 'videoPath', value: variant.videoPath),
    (field: 'posterPath', value: variant.posterPath),
    (field: 'captionsPath', value: variant.captionsPath),
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
  if (isIntro && variant.posterPath.trim().isEmpty) {
    error(
      'introPosterRequired',
      'posterPath',
      'Choose a poster image so the intro always has a safe fallback.',
    );
  }
  if (!variant.videoPath.toLowerCase().endsWith('.mp4')) {
    error(
      isIntro
          ? 'introContainerUnsupported'
          : 'presentationVideoContainerUnsupported',
      'videoPath',
      'Presentation videos must use the cross-platform MP4 container.',
    );
  }
  final posterPath = variant.posterPath.toLowerCase();
  if (!const <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  ].any(posterPath.endsWith)) {
    error(
      isIntro
          ? 'introPosterFormatUnsupported'
          : 'presentationPosterFormatUnsupported',
      'posterPath',
      'Poster images must use PNG, JPEG, or WebP.',
    );
  }
  final captionsPath = variant.captionsPath?.toLowerCase();
  if (captionsPath != null && !captionsPath.endsWith('.vtt')) {
    error(
      isIntro
          ? 'introCaptionsFormatUnsupported'
          : 'presentationCaptionsFormatUnsupported',
      'captionsPath',
      'Captions must use WebVTT.',
    );
  }
  if (variant.durationMilliseconds <= 0 ||
      variant.durationMilliseconds > maxDurationMilliseconds) {
    error(
      durationCode,
      'durationMilliseconds',
      'The video duration exceeds the allowed presentation budget.',
    );
  }
  final longestEdge = math.max(variant.width, variant.height);
  final shortestEdge = math.min(variant.width, variant.height);
  if (variant.width <= 0 ||
      variant.height <= 0 ||
      longestEdge > projectIntroVideoMaxWidth ||
      shortestEdge > projectIntroVideoMaxHeight) {
    error(
      isIntro ? 'introResolutionExceeded' : 'presentationResolutionExceeded',
      'width',
      'Video resolution must not exceed 1920 px on its longest edge and '
          '1080 px on its shortest edge.',
    );
  }
  if ((!isPortraitSlot && variant.height > variant.width) ||
      (isPortraitSlot && variant.height <= variant.width)) {
    error(
      isPortraitSlot
          ? 'presentationPortraitOrientationRequired'
          : 'presentationLandscapeOrientationRequired',
      'width',
      'The video dimensions must match the authored orientation slot.',
    );
  }
  if (variant.bitrateKbps <= 0 ||
      variant.bitrateKbps > projectIntroVideoMaxBitrateKbps) {
    error(
      isIntro ? 'introBitrateExceeded' : 'presentationBitrateExceeded',
      'bitrateKbps',
      'Video bitrate must not exceed 12,000 kbps.',
    );
  }
  if (variant.sizeBytes <= 0 || variant.sizeBytes > maxSizeBytes) {
    error(
      sizeCode,
      'sizeBytes',
      'The video size exceeds the allowed presentation budget.',
    );
  }
  if (variant.videoCodec != 'h264') {
    error(
      isIntro
          ? 'introVideoCodecUnsupported'
          : 'presentationVideoCodecUnsupported',
      'videoCodec',
      'Presentation videos must use H.264.',
    );
  }
  if (!audioAllowed.contains(variant.audioCodec)) {
    error(
      audioAllowed.length == 1
          ? 'titleLoopAudioForbidden'
          : 'introAudioCodecUnsupported',
      'audioCodec',
      audioAllowed.length == 1
          ? 'Title and menu loops must not contain audio.'
          : 'Intro audio must use AAC or be omitted.',
    );
  }
  if (!variant.focalX.isFinite ||
      !variant.focalY.isFinite ||
      variant.focalX < 0 ||
      variant.focalX > 1 ||
      variant.focalY < 0 ||
      variant.focalY > 1) {
    error(
      'presentationFocalPointInvalid',
      'focalX',
      'Focal points must stay between 0 and 1.',
    );
  }
}

Iterable<({String orientation, ProjectVideoVariantProfile variant})>
_responsiveVariants(ProjectResponsiveVideoProfile media) sync* {
  yield (orientation: 'landscape', variant: media.landscape);
  if (media.portrait case final portrait?) {
    yield (orientation: 'portrait', variant: portrait);
  }
}

Iterable<ProjectVideoVariantProfile> _titleMotionVariants(
  ProjectTitleMotionProfile motion,
) sync* {
  for (final media in <ProjectResponsiveVideoProfile?>[
    motion.promptLoop,
    motion.menuLoop,
  ]) {
    if (media == null) continue;
    for (final entry in _responsiveVariants(media)) {
      yield entry.variant;
    }
  }
}

void _presentationError(
  List<ProjectPresentationDiagnostic> diagnostics,
  String code,
  ProjectPresentationCategory category,
  String path,
  String message,
) {
  diagnostics.add(
    ProjectPresentationDiagnostic(
      code: code,
      category: category,
      severity: ProjectPresentationDiagnosticSeverity.error,
      path: path,
      message: message,
    ),
  );
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
    'combat': ?typography.combat,
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

Map<String, dynamic> _migrateProjectPresentationProfileJson(
  Map<String, dynamic> source,
) {
  final schemaVersion = source['schemaVersion'] ?? 1;
  if (schemaVersion is int &&
      schemaVersion < 3 &&
      source.containsKey('windows')) {
    throw const FormatException(
      'Presentation windows require schema version 3.',
    );
  }
  if (schemaVersion is int &&
      schemaVersion < 4 &&
      source.containsKey('layouts')) {
    throw const FormatException(
      'Presentation layouts require schema version 4.',
    );
  }
  if (schemaVersion is int && schemaVersion < 5) {
    final windows = source['windows'];
    final layouts = source['layouts'];
    final typography = source['typography'];
    if ((windows is Map && windows.containsKey('battleStyleId')) ||
        (layouts is Map && layouts.containsKey('battle')) ||
        (typography is Map && typography.containsKey('combat'))) {
      throw const FormatException(
        'Combat presentation requires schema version 5.',
      );
    }
  }
  if (schemaVersion == 2 || schemaVersion == 3 || schemaVersion == 4) {
    return Map<String, dynamic>.from(source)
      ..['schemaVersion'] = ProjectPresentationProfile.supportedSchemaVersion;
  }
  if (schemaVersion != 1) return Map<String, dynamic>.from(source);

  final migrated = Map<String, dynamic>.from(source)
    ..['schemaVersion'] = ProjectPresentationProfile.supportedSchemaVersion;
  final rawIntro = source['intro'];
  if (rawIntro is! Map) return migrated;

  final intro = Map<String, dynamic>.from(rawIntro);
  final reducedMotionBehavior = intro.remove('reducedMotionBehavior');
  final allowReplay = intro.remove('allowReplay');
  // V1 allowed a missing poster at decode time and rejected it in validation.
  // Preserve that readable-but-invalid behavior with an empty V2 path so a
  // project is never made undecodable by migration.
  intro['posterPath'] ??= '';
  intro['focalX'] = 0.5;
  intro['focalY'] = 0.5;
  migrated['intro'] = <String, Object?>{
    'media': <String, Object?>{'landscape': intro},
    if (reducedMotionBehavior != null)
      'reducedMotionBehavior': reducedMotionBehavior,
    if (allowReplay != null) 'allowReplay': allowReplay,
  };
  return migrated;
}

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
