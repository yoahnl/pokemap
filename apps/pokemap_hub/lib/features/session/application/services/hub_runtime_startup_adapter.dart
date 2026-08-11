import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/session/domain/repositories/package_asset_port.dart';

/// Adapts one already verified installed package to the host-neutral startup
/// contracts. Package path validation remains owned by [PackageAssetPort]; the
/// runtime only receives opaque asset ids and resolved file URIs.
final class HubRuntimeStartupAdapter
    implements RuntimeStartupPreparationPort, RuntimePresentationAssetResolver {
  HubRuntimeStartupAdapter({required this.manifest, required this.assets})
    : _mediaTypes = <String, String>{
        for (final entry in manifest.content.files)
          if (entry.mediaType case final mediaType?) entry.path: mediaType,
      };

  final GamePackageManifest manifest;
  final PackageAssetPort assets;
  final Map<String, String> _mediaTypes;
  final Map<String, RuntimeResolvedAsset> _resolved =
      <String, RuntimeResolvedAsset>{};

  /// Installation verification has already prepared the manifest and identity
  /// before this adapter is created. Repeating it here would create a second,
  /// competing launch authority inside presentation code.
  @override
  Future<void> prepareManifestAndIdentity() async {}

  @override
  Future<ProjectPresentationProfile?> loadPresentationProfile() async {
    final branding = manifest.branding;
    final presentation = manifest.presentation;
    final title = presentation?.title;
    final intro = presentation?.intro;
    final titleMotion = presentation?.titleMotion;
    final typography = presentation?.typography;
    final theme = presentation?.theme;
    final surfacePalettes = presentation?.surfacePalettes;
    final pause = presentation?.pause;
    final dialogue = presentation?.dialogue;
    final menuLabels = presentation?.menuLabels;
    final windows = presentation?.windows;
    final layouts = presentation?.layouts;
    if (branding == null &&
        intro == null &&
        title == null &&
        titleMotion == null &&
        typography == null &&
        theme == null &&
        surfacePalettes == null &&
        pause == null &&
        dialogue == null &&
        menuLabels == null &&
        windows == null &&
        layouts == null) {
      return null;
    }
    return ProjectPresentationProfile(
      schemaVersion: ProjectPresentationProfile.supportedSchemaVersion,
      branding: ProjectBrandingProfile(
        iconPath: branding?.icon,
        coverPath: branding?.cover,
        heroPath: branding?.hero ?? branding?.cover,
        accentColor: branding?.accentColor,
        titleMusicPath: branding?.titleMusic,
        layoutVariant: branding?.layoutVariant ?? 'standard',
      ),
      title:
          title == null
              ? null
              : ProjectTitlePresentationProfile(
                title: title.title,
                subtitle: title.subtitle,
                prompt: title.prompt,
                actions: title.actions
                    ?.map(
                      (action) => ProjectTitleActionProfile(
                        id: ProjectTitleActionId.values.byName(action.id),
                        label: action.label,
                        icon:
                            action.icon == null
                                ? null
                                : ProjectTitleActionIcon.values.byName(
                                  action.icon!,
                                ),
                        visible: action.visible,
                      ),
                    )
                    .toList(growable: false),
              ),
      intro:
          intro == null
              ? null
              : ProjectIntroVideoProfile(
                media: _projectMedia(intro.responsiveMedia),
                reducedMotionBehavior: intro.reducedMotionBehavior,
                allowReplay: intro.allowReplay,
              ),
      titleMotion:
          titleMotion == null
              ? null
              : ProjectTitleMotionProfile(
                promptLoop:
                    titleMotion.promptLoop == null
                        ? null
                        : _projectMedia(titleMotion.promptLoop!),
                menuLoop:
                    titleMotion.menuLoop == null
                        ? null
                        : _projectMedia(titleMotion.menuLoop!),
              ),
      typography:
          typography == null
              ? null
              : ProjectTypographyProfile(
                display: _projectFontRole(typography.display),
                body: _projectFontRole(typography.body),
                dialogue: _projectFontRole(typography.dialogue),
                combat:
                    typography.combat == null
                        ? null
                        : _projectFontRole(typography.combat!),
                numbers: _projectFontRole(typography.numbers),
              ),
      theme:
          theme == null
              ? null
              : ProjectSemanticThemeProfile(
                primary: theme.primary,
                onPrimary: theme.onPrimary,
                background: theme.background,
                surface: theme.surface,
                surfaceElevated: theme.surfaceElevated,
                textPrimary: theme.textPrimary,
                textSecondary: theme.textSecondary,
                outline: theme.outline,
                success: theme.success,
                warning: theme.warning,
                danger: theme.danger,
                titleSurface: theme.titleSurface,
                dialogueSurface: theme.dialogueSurface,
                menuSurface: theme.menuSurface,
                overworldHudSurface: theme.overworldHudSurface,
                battleHudSurface: theme.battleHudSurface,
              ),
      surfacePalettes:
          surfacePalettes == null
              ? null
              : ProjectPresentationSurfacePalettesProfile(
                title: _projectSurfacePalette(surfacePalettes.title),
                pauseMenu: _projectSurfacePalette(surfacePalettes.pauseMenu),
                dialogue: _projectSurfacePalette(surfacePalettes.dialogue),
                battle: _projectSurfacePalette(surfacePalettes.battle),
              ),
      pause:
          pause == null
              ? null
              : ProjectPausePresentationProfile(
                title: pause.title,
                hint: pause.hint,
                actions: pause.actions
                    ?.map(
                      (action) => ProjectPauseActionProfile(
                        id: ProjectPauseActionId.values.byName(action.id),
                        label: action.label,
                        icon:
                            action.icon == null
                                ? null
                                : ProjectPauseActionIcon.values.byName(
                                  action.icon!,
                                ),
                        visible: action.visible,
                      ),
                    )
                    .toList(growable: false),
                composition:
                    pause.composition == null
                        ? null
                        : _projectPauseComposition(pause.composition!),
              ),
      dialogue:
          dialogue == null
              ? null
              : ProjectDialoguePresentationProfile(
                placement: ProjectDialoguePlacement.values.byName(
                  dialogue.placement,
                ),
                maxWidthFactor: dialogue.maxWidthFactor,
                margin: dialogue.margin,
                contentPadding: dialogue.contentPadding,
                shape: ProjectWindowShape.values.byName(dialogue.shape),
                cornerRadius: dialogue.cornerRadius,
                borderWidth: dialogue.borderWidth,
                fillOpacity: dialogue.fillOpacity,
                surfaceColor: dialogue.surfaceColor,
                borderColor: dialogue.borderColor,
                textColor: dialogue.textColor,
                portraitSide: ProjectDialoguePortraitSide.values.byName(
                  dialogue.portraitSide,
                ),
                portraitSize: dialogue.portraitSize,
                portraitShape: ProjectDialoguePortraitShape.values.byName(
                  dialogue.portraitShape,
                ),
                portraitFrameWidth: dialogue.portraitFrameWidth,
                portraitFrameColor: dialogue.portraitFrameColor,
                nameplateStyle: ProjectDialogueNameplateStyle.values.byName(
                  dialogue.nameplateStyle,
                ),
                nameplateBorderWidth: dialogue.nameplateBorderWidth,
                nameplateSurfaceColor: dialogue.nameplateSurfaceColor,
                nameplateBorderColor: dialogue.nameplateBorderColor,
                nameplateTextColor: dialogue.nameplateTextColor,
              ),
      menuLabels:
          menuLabels == null
              ? null
              : ProjectMenuLabelsProfile(
                pauseTitle: menuLabels.pauseTitle,
                resume: menuLabels.resume,
                party: menuLabels.party,
                bag: menuLabels.bag,
                pokedex: menuLabels.pokedex,
                map: menuLabels.map,
                save: menuLabels.save,
                options: menuLabels.options,
                returnToTitle: menuLabels.returnToTitle,
              ),
      windows:
          windows == null
              ? null
              : ProjectPresentationWindowsProfile(
                styles: <ProjectWindowStyleProfile>[
                  for (final style in windows.styles)
                    ProjectWindowStyleProfile(
                      id: style.id,
                      fillToken: style.fillToken,
                      borderToken: style.borderToken,
                      borderWidth: style.borderWidth,
                      cornerRadius: style.cornerRadius,
                      contentPadding: style.contentPadding,
                      shadowElevation: style.shadowElevation,
                      shape: ProjectWindowShape.values.byName(style.shape),
                      fillOpacity: style.fillOpacity,
                    ),
                ],
                defaultStyleId: windows.defaultStyleId,
                pauseMenuStyleId: windows.pauseMenuStyleId,
                dialogueStyleId: windows.dialogueStyleId,
                battleStyleId: windows.battleStyleId,
                pauseBackdropOpacity: windows.pauseBackdropOpacity,
              ),
      layouts: layouts == null ? null : _projectLayouts(layouts),
    );
  }

  ProjectPresentationLayoutsProfile _projectLayouts(
    GamePackagePresentationLayouts source,
  ) {
    ProjectSurfaceLayoutVariant variant(
      GamePackageSurfaceLayoutVariant value,
    ) => ProjectSurfaceLayoutVariant(
      breakpoint: ProjectPresentationBreakpoint.values.byName(value.breakpoint),
      slot: ProjectPresentationLayoutSlot.values.byName(value.slot),
      width: ProjectPresentationContentWidth.values.byName(value.width),
      spacing: ProjectPresentationSpacing.values.byName(value.spacing),
      screenMargin: ProjectPresentationScreenMargin.values.byName(
        value.screenMargin,
      ),
      visibleSecondaryElements: value.visibleSecondaryElements
          .map(ProjectPresentationSecondaryElement.values.byName)
          .toList(growable: false),
    );
    ProjectResponsiveSurfaceLayoutProfile responsive(
      GamePackageResponsiveSurfaceLayout value,
    ) => ProjectResponsiveSurfaceLayoutProfile(
      compact: variant(value.compact),
      regular: variant(value.regular),
      expanded: variant(value.expanded),
    );
    return ProjectPresentationLayoutsProfile(
      title: responsive(source.title),
      pauseMenu: responsive(source.pauseMenu),
      dialogue: responsive(source.dialogue),
      battle: source.battle == null ? null : responsive(source.battle!),
    );
  }

  ProjectResponsivePauseCompositionProfile _projectPauseComposition(
    GamePackageResponsivePauseComposition source,
  ) => ProjectResponsivePauseCompositionProfile(
    compactPortrait: _projectPauseCompositionVariant(source.compactPortrait),
    compactLandscape: _projectPauseCompositionVariant(source.compactLandscape),
    expanded: _projectPauseCompositionVariant(source.expanded),
  );

  ProjectPauseCompositionVariantProfile _projectPauseCompositionVariant(
    GamePackagePauseCompositionVariant source,
  ) => ProjectPauseCompositionVariantProfile(
    entrySize: ProjectPauseEntrySize.values.byName(source.entrySize),
    entrySpacing: ProjectPauseEntrySpacing.values.byName(source.entrySpacing),
    showTitle: source.showTitle,
    showHint: source.showHint,
    showRootDetailPanel: source.showRootDetailPanel,
  );

  ProjectTypographyRoleProfile _projectFontRole(GamePackageFontRole role) =>
      ProjectTypographyRoleProfile(
        fontPath: role.font,
        family: role.family,
        licensePath: role.license,
        fallbackFamilies: role.fallbackFamilies,
        metrics:
            role.metrics == null
                ? null
                : ProjectTypographyMetricsProfile(
                  sizeScale: role.metrics!.sizeScale,
                  weight: role.metrics!.weight,
                  lineHeight: role.metrics!.lineHeight,
                  letterSpacing: role.metrics!.letterSpacing,
                ),
      );

  ProjectSurfacePaletteProfile? _projectSurfacePalette(
    GamePackageSurfacePalette? source,
  ) =>
      source == null
          ? null
          : ProjectSurfacePaletteProfile(
            background: source.background,
            surface: source.surface,
            border: source.border,
            text: source.text,
            accent: source.accent,
            selection: source.selection,
          );

  ProjectResponsiveVideoProfile _projectMedia(
    GamePackageResponsiveVideo media,
  ) => ProjectResponsiveVideoProfile(
    landscape: _projectVariant(media.landscape),
    portrait: media.portrait == null ? null : _projectVariant(media.portrait!),
  );

  ProjectVideoVariantProfile _projectVariant(GamePackageVideoVariant variant) =>
      ProjectVideoVariantProfile(
        videoPath: variant.video,
        posterPath: variant.poster,
        captionsPath: variant.captions,
        durationMilliseconds: variant.durationMilliseconds,
        width: variant.width,
        height: variant.height,
        bitrateKbps: variant.bitrateKbps,
        sizeBytes: variant.sizeBytes,
        videoCodec: variant.videoCodec,
        audioCodec: variant.audioCodec,
        focalX: variant.focalX,
        focalY: variant.focalY,
      );

  @override
  Future<RuntimeResolvedAsset?> resolveImage(String projectRelativePath) =>
      _resolve(projectRelativePath, fallbackMediaType: 'image/*');

  @override
  Future<RuntimeResolvedAsset?> resolveMedia(String projectRelativePath) =>
      _resolve(
        projectRelativePath,
        fallbackMediaType: 'application/octet-stream',
      );

  @override
  Future<bool> exists(String projectRelativePath) async =>
      await _resolve(projectRelativePath) != null;

  /// Concrete locations never enter [RuntimeStartupSnapshot]. The Hub may use
  /// this cache after preparation to hand an ImageProvider or video URI to the
  /// generic Flutter shell.
  RuntimeResolvedAsset? resolvedAsset(String assetId) => _resolved[assetId];

  Future<String> loadText(String assetId) async =>
      (await assets.resolveFile(assetId)).readAsString();

  Future<RuntimeResolvedAsset?> _resolve(
    String assetId, {
    String fallbackMediaType = 'application/octet-stream',
  }) async {
    final cached = _resolved[assetId];
    if (cached != null) return cached;
    try {
      final File file = await assets.resolveFile(assetId);
      final resolved = RuntimeResolvedAsset(
        assetId: assetId,
        resolvedUri: file.uri,
        mediaType: _mediaTypes[assetId] ?? fallbackMediaType,
      );
      _resolved[assetId] = resolved;
      return resolved;
    } on Object {
      // Presentation media is optional. The startup coordinator turns this
      // null into a safe diagnostic while preserving a launchable game.
      return null;
    }
  }
}
