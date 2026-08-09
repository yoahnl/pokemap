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
  HubRuntimeStartupAdapter({
    required this.manifest,
    required this.assets,
  }) : _mediaTypes = <String, String>{
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
    final intro = presentation?.intro;
    final titleMotion = presentation?.titleMotion;
    final typography = presentation?.typography;
    final theme = presentation?.theme;
    final menuLabels = presentation?.menuLabels;
    final windows = presentation?.windows;
    if (branding == null &&
        intro == null &&
        titleMotion == null &&
        typography == null &&
        theme == null &&
        menuLabels == null &&
        windows == null) {
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
      intro: intro == null
          ? null
          : ProjectIntroVideoProfile(
              media: _projectMedia(intro.responsiveMedia),
              reducedMotionBehavior: intro.reducedMotionBehavior,
              allowReplay: intro.allowReplay,
            ),
      titleMotion: titleMotion == null
          ? null
          : ProjectTitleMotionProfile(
              promptLoop: titleMotion.promptLoop == null
                  ? null
                  : _projectMedia(titleMotion.promptLoop!),
              menuLoop: titleMotion.menuLoop == null
                  ? null
                  : _projectMedia(titleMotion.menuLoop!),
            ),
      typography: typography == null
          ? null
          : ProjectTypographyProfile(
              display: _projectFontRole(typography.display),
              body: _projectFontRole(typography.body),
              dialogue: _projectFontRole(typography.dialogue),
              numbers: _projectFontRole(typography.numbers),
            ),
      theme: theme == null
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
      menuLabels: menuLabels == null
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
      windows: windows == null
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
                  ),
              ],
              defaultStyleId: windows.defaultStyleId,
              pauseMenuStyleId: windows.pauseMenuStyleId,
              dialogueStyleId: windows.dialogueStyleId,
              pauseBackdropOpacity: windows.pauseBackdropOpacity,
            ),
    );
  }

  ProjectTypographyRoleProfile _projectFontRole(GamePackageFontRole role) =>
      ProjectTypographyRoleProfile(
        fontPath: role.font,
        family: role.family,
        licensePath: role.license,
        fallbackFamilies: role.fallbackFamilies,
      );

  ProjectResponsiveVideoProfile _projectMedia(
    GamePackageResponsiveVideo media,
  ) =>
      ProjectResponsiveVideoProfile(
        landscape: _projectVariant(media.landscape),
        portrait:
            media.portrait == null ? null : _projectVariant(media.portrait!),
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
      _resolve(projectRelativePath,
          fallbackMediaType: 'application/octet-stream');

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
