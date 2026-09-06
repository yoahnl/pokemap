// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_presentation_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectBrandingProfile _$ProjectBrandingProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectBrandingProfile(
  iconPath: json['iconPath'] as String?,
  coverPath: json['coverPath'] as String?,
  heroPath: json['heroPath'] as String?,
  accentColor: json['accentColor'] as String?,
  titleMusicPath: json['titleMusicPath'] as String?,
  layoutVariant: json['layoutVariant'] as String? ?? 'standard',
);

Map<String, dynamic> _$ProjectBrandingProfileToJson(
  _ProjectBrandingProfile instance,
) => <String, dynamic>{
  'iconPath': ?instance.iconPath,
  'coverPath': ?instance.coverPath,
  'heroPath': ?instance.heroPath,
  'accentColor': ?instance.accentColor,
  'titleMusicPath': ?instance.titleMusicPath,
  'layoutVariant': instance.layoutVariant,
};

_ProjectVideoVariantProfile _$ProjectVideoVariantProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectVideoVariantProfile(
  videoPath: json['videoPath'] as String,
  posterPath: json['posterPath'] as String,
  captionsPath: json['captionsPath'] as String?,
  durationMilliseconds: (json['durationMilliseconds'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  bitrateKbps: (json['bitrateKbps'] as num).toInt(),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  videoCodec: json['videoCodec'] as String,
  audioCodec: json['audioCodec'] as String? ?? 'none',
  focalX: (json['focalX'] as num?)?.toDouble() ?? 0.5,
  focalY: (json['focalY'] as num?)?.toDouble() ?? 0.5,
);

Map<String, dynamic> _$ProjectVideoVariantProfileToJson(
  _ProjectVideoVariantProfile instance,
) => <String, dynamic>{
  'videoPath': instance.videoPath,
  'posterPath': instance.posterPath,
  'captionsPath': ?instance.captionsPath,
  'durationMilliseconds': instance.durationMilliseconds,
  'width': instance.width,
  'height': instance.height,
  'bitrateKbps': instance.bitrateKbps,
  'sizeBytes': instance.sizeBytes,
  'videoCodec': instance.videoCodec,
  'audioCodec': instance.audioCodec,
  'focalX': instance.focalX,
  'focalY': instance.focalY,
};

_ProjectResponsiveVideoProfile _$ProjectResponsiveVideoProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectResponsiveVideoProfile(
  landscape: ProjectVideoVariantProfile.fromJson(
    json['landscape'] as Map<String, dynamic>,
  ),
  portrait: json['portrait'] == null
      ? null
      : ProjectVideoVariantProfile.fromJson(
          json['portrait'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectResponsiveVideoProfileToJson(
  _ProjectResponsiveVideoProfile instance,
) => <String, dynamic>{
  'landscape': instance.landscape.toJson(),
  'portrait': ?instance.portrait?.toJson(),
};

_ProjectIntroVideoProfile _$ProjectIntroVideoProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectIntroVideoProfile(
  media: ProjectResponsiveVideoProfile.fromJson(
    json['media'] as Map<String, dynamic>,
  ),
  reducedMotionBehavior: json['reducedMotionBehavior'] as String? ?? 'poster',
  allowReplay: json['allowReplay'] as bool? ?? true,
);

Map<String, dynamic> _$ProjectIntroVideoProfileToJson(
  _ProjectIntroVideoProfile instance,
) => <String, dynamic>{
  'media': instance.media.toJson(),
  'reducedMotionBehavior': instance.reducedMotionBehavior,
  'allowReplay': instance.allowReplay,
};

_ProjectTitleActionProfile _$ProjectTitleActionProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTitleActionProfile(
  id: $enumDecode(_$ProjectTitleActionIdEnumMap, json['id']),
  label: json['label'] as String?,
  icon: $enumDecodeNullable(_$ProjectTitleActionIconEnumMap, json['icon']),
  visible: json['visible'] as bool? ?? true,
);

Map<String, dynamic> _$ProjectTitleActionProfileToJson(
  _ProjectTitleActionProfile instance,
) => <String, dynamic>{
  'id': _$ProjectTitleActionIdEnumMap[instance.id]!,
  'label': ?instance.label,
  'icon': ?_$ProjectTitleActionIconEnumMap[instance.icon],
  'visible': instance.visible,
};

const _$ProjectTitleActionIdEnumMap = {
  ProjectTitleActionId.continueGame: 'continueGame',
  ProjectTitleActionId.newGame: 'newGame',
  ProjectTitleActionId.load: 'load',
  ProjectTitleActionId.options: 'options',
  ProjectTitleActionId.creditsAbout: 'creditsAbout',
  ProjectTitleActionId.returnToHub: 'returnToHub',
};

const _$ProjectTitleActionIconEnumMap = {
  ProjectTitleActionIcon.play: 'play',
  ProjectTitleActionIcon.sparkles: 'sparkles',
  ProjectTitleActionIcon.folder: 'folder',
  ProjectTitleActionIcon.settings: 'settings',
  ProjectTitleActionIcon.info: 'info',
  ProjectTitleActionIcon.home: 'home',
};

_ProjectPauseCompositionVariantProfile
_$ProjectPauseCompositionVariantProfileFromJson(Map<String, dynamic> json) =>
    _ProjectPauseCompositionVariantProfile(
      entrySize:
          $enumDecodeNullable(
            _$ProjectPauseEntrySizeEnumMap,
            json['entrySize'],
          ) ??
          ProjectPauseEntrySize.regular,
      entrySpacing:
          $enumDecodeNullable(
            _$ProjectPauseEntrySpacingEnumMap,
            json['entrySpacing'],
          ) ??
          ProjectPauseEntrySpacing.regular,
      showTitle: json['showTitle'] as bool? ?? true,
      showHint: json['showHint'] as bool? ?? true,
      showRootDetailPanel: json['showRootDetailPanel'] as bool? ?? true,
    );

Map<String, dynamic> _$ProjectPauseCompositionVariantProfileToJson(
  _ProjectPauseCompositionVariantProfile instance,
) => <String, dynamic>{
  'entrySize': _$ProjectPauseEntrySizeEnumMap[instance.entrySize]!,
  'entrySpacing': _$ProjectPauseEntrySpacingEnumMap[instance.entrySpacing]!,
  'showTitle': instance.showTitle,
  'showHint': instance.showHint,
  'showRootDetailPanel': instance.showRootDetailPanel,
};

const _$ProjectPauseEntrySizeEnumMap = {
  ProjectPauseEntrySize.compact: 'compact',
  ProjectPauseEntrySize.regular: 'regular',
  ProjectPauseEntrySize.large: 'large',
};

const _$ProjectPauseEntrySpacingEnumMap = {
  ProjectPauseEntrySpacing.tight: 'tight',
  ProjectPauseEntrySpacing.regular: 'regular',
  ProjectPauseEntrySpacing.airy: 'airy',
};

_ProjectResponsivePauseCompositionProfile
_$ProjectResponsivePauseCompositionProfileFromJson(Map<String, dynamic> json) =>
    _ProjectResponsivePauseCompositionProfile(
      compactPortrait: json['compactPortrait'] == null
          ? const ProjectPauseCompositionVariantProfile()
          : ProjectPauseCompositionVariantProfile.fromJson(
              json['compactPortrait'] as Map<String, dynamic>,
            ),
      compactLandscape: json['compactLandscape'] == null
          ? const ProjectPauseCompositionVariantProfile()
          : ProjectPauseCompositionVariantProfile.fromJson(
              json['compactLandscape'] as Map<String, dynamic>,
            ),
      expanded: json['expanded'] == null
          ? const ProjectPauseCompositionVariantProfile()
          : ProjectPauseCompositionVariantProfile.fromJson(
              json['expanded'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProjectResponsivePauseCompositionProfileToJson(
  _ProjectResponsivePauseCompositionProfile instance,
) => <String, dynamic>{
  'compactPortrait': instance.compactPortrait.toJson(),
  'compactLandscape': instance.compactLandscape.toJson(),
  'expanded': instance.expanded.toJson(),
};

_ProjectPauseActionProfile _$ProjectPauseActionProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPauseActionProfile(
  id: $enumDecode(_$ProjectPauseActionIdEnumMap, json['id']),
  label: json['label'] as String?,
  icon: $enumDecodeNullable(_$ProjectPauseActionIconEnumMap, json['icon']),
  visible: json['visible'] as bool? ?? true,
);

Map<String, dynamic> _$ProjectPauseActionProfileToJson(
  _ProjectPauseActionProfile instance,
) => <String, dynamic>{
  'id': _$ProjectPauseActionIdEnumMap[instance.id]!,
  'label': ?instance.label,
  'icon': ?_$ProjectPauseActionIconEnumMap[instance.icon],
  'visible': instance.visible,
};

const _$ProjectPauseActionIdEnumMap = {
  ProjectPauseActionId.resume: 'resume',
  ProjectPauseActionId.party: 'party',
  ProjectPauseActionId.bag: 'bag',
  ProjectPauseActionId.pokedex: 'pokedex',
  ProjectPauseActionId.quests: 'quests',
  ProjectPauseActionId.map: 'map',
  ProjectPauseActionId.profile: 'profile',
  ProjectPauseActionId.save: 'save',
  ProjectPauseActionId.options: 'options',
  ProjectPauseActionId.returnToTitle: 'returnToTitle',
};

const _$ProjectPauseActionIconEnumMap = {
  ProjectPauseActionIcon.play: 'play',
  ProjectPauseActionIcon.party: 'party',
  ProjectPauseActionIcon.bag: 'bag',
  ProjectPauseActionIcon.book: 'book',
  ProjectPauseActionIcon.person: 'person',
  ProjectPauseActionIcon.map: 'map',
  ProjectPauseActionIcon.save: 'save',
  ProjectPauseActionIcon.settings: 'settings',
  ProjectPauseActionIcon.exit: 'exit',
};

_ProjectPauseBackgroundProfile _$ProjectPauseBackgroundProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPauseBackgroundProfile(
  imagePath: json['imagePath'] as String,
  focalX: (json['focalX'] as num?)?.toDouble() ?? 0.5,
  focalY: (json['focalY'] as num?)?.toDouble() ?? 0.5,
  sampling:
      $enumDecodeNullable(
        _$ProjectMenuImageSamplingEnumMap,
        json['sampling'],
      ) ??
      ProjectMenuImageSampling.smooth,
);

Map<String, dynamic> _$ProjectPauseBackgroundProfileToJson(
  _ProjectPauseBackgroundProfile instance,
) => <String, dynamic>{
  'imagePath': instance.imagePath,
  'focalX': instance.focalX,
  'focalY': instance.focalY,
  'sampling': _$ProjectMenuImageSamplingEnumMap[instance.sampling]!,
};

const _$ProjectMenuImageSamplingEnumMap = {
  ProjectMenuImageSampling.smooth: 'smooth',
  ProjectMenuImageSampling.pixelArt: 'pixelArt',
};

_ProjectPausePresentationProfile _$ProjectPausePresentationProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPausePresentationProfile(
  style: $enumDecodeNullable(_$ProjectPauseMenuStyleEnumMap, json['style']),
  background: json['background'] == null
      ? null
      : ProjectPauseBackgroundProfile.fromJson(
          json['background'] as Map<String, dynamic>,
        ),
  title: json['title'] as String?,
  hint: json['hint'] as String?,
  actions: (json['actions'] as List<dynamic>?)
      ?.map(
        (e) => ProjectPauseActionProfile.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  composition: json['composition'] == null
      ? null
      : ProjectResponsivePauseCompositionProfile.fromJson(
          json['composition'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectPausePresentationProfileToJson(
  _ProjectPausePresentationProfile instance,
) => <String, dynamic>{
  'style': ?_$ProjectPauseMenuStyleEnumMap[instance.style],
  'background': ?instance.background?.toJson(),
  'title': ?instance.title,
  'hint': ?instance.hint,
  'actions': ?instance.actions?.map((e) => e.toJson()).toList(),
  'composition': ?instance.composition?.toJson(),
};

const _$ProjectPauseMenuStyleEnumMap = {
  ProjectPauseMenuStyle.standard: 'standard',
  ProjectPauseMenuStyle.nightIllustrated: 'nightIllustrated',
};

_ProjectTitlePresentationProfile _$ProjectTitlePresentationProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTitlePresentationProfile(
  title: json['title'] as String?,
  subtitle: json['subtitle'] as String?,
  prompt: json['prompt'] as String?,
  actions: (json['actions'] as List<dynamic>?)
      ?.map(
        (e) => ProjectTitleActionProfile.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$ProjectTitlePresentationProfileToJson(
  _ProjectTitlePresentationProfile instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'subtitle': ?instance.subtitle,
  'prompt': ?instance.prompt,
  'actions': ?instance.actions?.map((e) => e.toJson()).toList(),
};

_ProjectTitleMotionProfile _$ProjectTitleMotionProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTitleMotionProfile(
  promptLoop: json['promptLoop'] == null
      ? null
      : ProjectResponsiveVideoProfile.fromJson(
          json['promptLoop'] as Map<String, dynamic>,
        ),
  menuLoop: json['menuLoop'] == null
      ? null
      : ProjectResponsiveVideoProfile.fromJson(
          json['menuLoop'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTitleMotionProfileToJson(
  _ProjectTitleMotionProfile instance,
) => <String, dynamic>{
  'promptLoop': ?instance.promptLoop?.toJson(),
  'menuLoop': ?instance.menuLoop?.toJson(),
};

_ProjectTypographyRoleProfile _$ProjectTypographyRoleProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTypographyRoleProfile(
  fontPath: json['fontPath'] as String?,
  family: json['family'] as String?,
  licensePath: json['licensePath'] as String?,
  redistributable: json['redistributable'] as bool? ?? false,
  fallbackFamilies:
      (json['fallbackFamilies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>['sans-serif'],
  glyphCoverage:
      (json['glyphCoverage'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  metrics: json['metrics'] == null
      ? null
      : ProjectTypographyMetricsProfile.fromJson(
          json['metrics'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTypographyRoleProfileToJson(
  _ProjectTypographyRoleProfile instance,
) => <String, dynamic>{
  'fontPath': ?instance.fontPath,
  'family': ?instance.family,
  'licensePath': ?instance.licensePath,
  'redistributable': instance.redistributable,
  'fallbackFamilies': instance.fallbackFamilies,
  'glyphCoverage': instance.glyphCoverage,
  'metrics': ?instance.metrics?.toJson(),
};

_ProjectTypographyProfile _$ProjectTypographyProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectTypographyProfile(
  display: json['display'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['display'] as Map<String, dynamic>,
        ),
  body: json['body'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['body'] as Map<String, dynamic>,
        ),
  dialogue: json['dialogue'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['dialogue'] as Map<String, dynamic>,
        ),
  numbers: json['numbers'] == null
      ? const ProjectTypographyRoleProfile()
      : ProjectTypographyRoleProfile.fromJson(
          json['numbers'] as Map<String, dynamic>,
        ),
  combat: json['combat'] == null
      ? null
      : ProjectTypographyRoleProfile.fromJson(
          json['combat'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectTypographyProfileToJson(
  _ProjectTypographyProfile instance,
) => <String, dynamic>{
  'display': instance.display.toJson(),
  'body': instance.body.toJson(),
  'dialogue': instance.dialogue.toJson(),
  'numbers': instance.numbers.toJson(),
  'combat': ?instance.combat?.toJson(),
};

_ProjectSemanticThemeProfile _$ProjectSemanticThemeProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectSemanticThemeProfile(
  primary: json['primary'] as String,
  onPrimary: json['onPrimary'] as String,
  background: json['background'] as String,
  surface: json['surface'] as String,
  surfaceElevated: json['surfaceElevated'] as String,
  textPrimary: json['textPrimary'] as String,
  textSecondary: json['textSecondary'] as String,
  outline: json['outline'] as String,
  success: json['success'] as String,
  warning: json['warning'] as String,
  danger: json['danger'] as String,
  titleSurface: json['titleSurface'] as String,
  dialogueSurface: json['dialogueSurface'] as String,
  menuSurface: json['menuSurface'] as String,
  overworldHudSurface: json['overworldHudSurface'] as String,
  battleHudSurface: json['battleHudSurface'] as String,
);

Map<String, dynamic> _$ProjectSemanticThemeProfileToJson(
  _ProjectSemanticThemeProfile instance,
) => <String, dynamic>{
  'primary': instance.primary,
  'onPrimary': instance.onPrimary,
  'background': instance.background,
  'surface': instance.surface,
  'surfaceElevated': instance.surfaceElevated,
  'textPrimary': instance.textPrimary,
  'textSecondary': instance.textSecondary,
  'outline': instance.outline,
  'success': instance.success,
  'warning': instance.warning,
  'danger': instance.danger,
  'titleSurface': instance.titleSurface,
  'dialogueSurface': instance.dialogueSurface,
  'menuSurface': instance.menuSurface,
  'overworldHudSurface': instance.overworldHudSurface,
  'battleHudSurface': instance.battleHudSurface,
};

_ProjectMenuLabelsProfile _$ProjectMenuLabelsProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectMenuLabelsProfile(
  pauseTitle: json['pauseTitle'] as String?,
  resume: json['resume'] as String?,
  party: json['party'] as String?,
  bag: json['bag'] as String?,
  pokedex: json['pokedex'] as String?,
  map: json['map'] as String?,
  quests: json['quests'] as String?,
  profile: json['profile'] as String?,
  save: json['save'] as String?,
  options: json['options'] as String?,
  returnToTitle: json['returnToTitle'] as String?,
);

Map<String, dynamic> _$ProjectMenuLabelsProfileToJson(
  _ProjectMenuLabelsProfile instance,
) => <String, dynamic>{
  'pauseTitle': ?instance.pauseTitle,
  'resume': ?instance.resume,
  'party': ?instance.party,
  'bag': ?instance.bag,
  'pokedex': ?instance.pokedex,
  'map': ?instance.map,
  'quests': ?instance.quests,
  'profile': ?instance.profile,
  'save': ?instance.save,
  'options': ?instance.options,
  'returnToTitle': ?instance.returnToTitle,
};

_ProjectPresentationProfile _$ProjectPresentationProfileFromJson(
  Map<String, dynamic> json,
) => _ProjectPresentationProfile(
  schemaVersion:
      (json['schemaVersion'] as num?)?.toInt() ??
      ProjectPresentationProfile.supportedSchemaVersion,
  branding: json['branding'] == null
      ? const ProjectBrandingProfile()
      : ProjectBrandingProfile.fromJson(
          json['branding'] as Map<String, dynamic>,
        ),
  title: json['title'] == null
      ? null
      : ProjectTitlePresentationProfile.fromJson(
          json['title'] as Map<String, dynamic>,
        ),
  intro: json['intro'] == null
      ? null
      : ProjectIntroVideoProfile.fromJson(
          json['intro'] as Map<String, dynamic>,
        ),
  titleMotion: json['titleMotion'] == null
      ? null
      : ProjectTitleMotionProfile.fromJson(
          json['titleMotion'] as Map<String, dynamic>,
        ),
  typography: json['typography'] == null
      ? null
      : ProjectTypographyProfile.fromJson(
          json['typography'] as Map<String, dynamic>,
        ),
  theme: json['theme'] == null
      ? null
      : ProjectSemanticThemeProfile.fromJson(
          json['theme'] as Map<String, dynamic>,
        ),
  surfacePalettes: json['surfacePalettes'] == null
      ? null
      : ProjectPresentationSurfacePalettesProfile.fromJson(
          json['surfacePalettes'] as Map<String, dynamic>,
        ),
  pause: json['pause'] == null
      ? null
      : ProjectPausePresentationProfile.fromJson(
          json['pause'] as Map<String, dynamic>,
        ),
  dialogue: json['dialogue'] == null
      ? null
      : ProjectDialoguePresentationProfile.fromJson(
          json['dialogue'] as Map<String, dynamic>,
        ),
  battle: json['battle'] == null
      ? null
      : ProjectBattlePresentationProfile.fromJson(
          json['battle'] as Map<String, dynamic>,
        ),
  menuLabels: json['menuLabels'] == null
      ? null
      : ProjectMenuLabelsProfile.fromJson(
          json['menuLabels'] as Map<String, dynamic>,
        ),
  windows: json['windows'] == null
      ? null
      : ProjectPresentationWindowsProfile.fromJson(
          json['windows'] as Map<String, dynamic>,
        ),
  layouts: json['layouts'] == null
      ? null
      : ProjectPresentationLayoutsProfile.fromJson(
          json['layouts'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectPresentationProfileToJson(
  _ProjectPresentationProfile instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'branding': instance.branding.toJson(),
  'title': ?instance.title?.toJson(),
  'intro': ?instance.intro?.toJson(),
  'titleMotion': ?instance.titleMotion?.toJson(),
  'typography': ?instance.typography?.toJson(),
  'theme': ?instance.theme?.toJson(),
  'surfacePalettes': ?instance.surfacePalettes?.toJson(),
  'pause': ?instance.pause?.toJson(),
  'dialogue': ?instance.dialogue?.toJson(),
  'battle': ?instance.battle?.toJson(),
  'menuLabels': ?instance.menuLabels?.toJson(),
  'windows': ?instance.windows?.toJson(),
  'layouts': ?instance.layouts?.toJson(),
};
