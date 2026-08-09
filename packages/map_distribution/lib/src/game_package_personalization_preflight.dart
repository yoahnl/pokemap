import 'canonical_json.dart';
import 'game_package_format_exception.dart';
import 'game_package_inspection.dart';
import 'game_package_inspector.dart';
import 'game_package_manifest.dart';

enum GamePackagePersonalizationCategory {
  branding,
  intro,
  titleMotion,
  typography,
  theme,
}

/// Immutable proof that an inspected package satisfies the presentation
/// packaging contract.
///
/// The package inspector remains the authority for ZIP structure, media
/// signatures, and payload digests. This receipt binds those verified hashes
/// to every presentation asset consumed later by the Hub.
final class GamePackagePersonalizationPreflightReceipt {
  GamePackagePersonalizationPreflightReceipt({
    this.receiptVersion = 1,
    required this.gameId,
    required this.gameVersion,
    required this.treeSha256,
    required this.packageSha256,
    required this.presentationSha256,
    required List<GamePackagePersonalizationCategory> configuredCategories,
    required Map<String, String> assetSha256,
    required this.videoCodec,
    required this.audioCodec,
  })  : configuredCategories = List.unmodifiable(configuredCategories),
        assetSha256 = Map.unmodifiable(assetSha256);

  final int receiptVersion;
  final String gameId;
  final String gameVersion;
  final String treeSha256;
  final String packageSha256;
  final String? presentationSha256;
  final List<GamePackagePersonalizationCategory> configuredCategories;
  final Map<String, String> assetSha256;
  final String? videoCodec;
  final String? audioCodec;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptVersion': receiptVersion,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'treeSha256': treeSha256,
        'packageSha256': packageSha256,
        if (presentationSha256 != null)
          'presentationSha256': presentationSha256,
        'configuredCategories': configuredCategories
            .map((category) => category.name)
            .toList(growable: false),
        'assetSha256': assetSha256,
        if (videoCodec != null) 'videoCodec': videoCodec,
        if (audioCodec != null) 'audioCodec': audioCodec,
      };
}

/// Converts a successful package inspection into personalization evidence.
///
/// This is intentionally run after [GamePackageInspector]: a caller cannot
/// certify a presentation from authoring paths or unverified package bytes.
final class GamePackagePersonalizationPreflight {
  const GamePackagePersonalizationPreflight();

  GamePackagePersonalizationPreflightReceipt certify(
    GamePackageInspectionResult inspection,
  ) {
    final manifest = inspection.manifest;
    final receipt = inspection.receipt;
    if (receipt.gameId != manifest.gameId ||
        receipt.gameVersion != manifest.gameVersion.toString() ||
        receipt.treeSha256 != manifest.content.treeSha256 ||
        !_isSha256(receipt.manifestSha256) ||
        !_isSha256(receipt.packageSha256) ||
        !_isSha256(receipt.treeSha256)) {
      _fail(
        'presentationHashMismatch',
        r'$.content.treeSha256',
        'The inspection receipt no longer matches the packaged manifest.',
      );
    }

    final payloadPaths = inspection.payloadPaths.toSet();
    final inventory = <String, GamePackageFileEntry>{
      for (final entry in manifest.content.files) entry.path: entry,
    };
    final assetHashes = <String, String>{};

    void certifyAsset(String? path, String manifestPath) {
      if (path == null) return;
      final entry = inventory[path];
      if (!payloadPaths.contains(path) ||
          entry == null ||
          !_isSha256(entry.sha256)) {
        _fail(
          'presentationAssetMissing',
          manifestPath,
          'A presentation asset is absent from the verified inventory.',
        );
      }
      assetHashes[path] = entry.sha256;
    }

    final presentation = manifest.presentation;
    final categories = <GamePackagePersonalizationCategory>[];
    if (presentation != null && _hasBranding(presentation.branding)) {
      categories.add(GamePackagePersonalizationCategory.branding);
      certifyAsset(
        presentation.branding.icon,
        r'$.presentation.branding.icon',
      );
      certifyAsset(
        presentation.branding.cover,
        r'$.presentation.branding.cover',
      );
      certifyAsset(
        presentation.branding.hero,
        r'$.presentation.branding.hero',
      );
      certifyAsset(
        presentation.branding.titleMusic,
        r'$.presentation.branding.titleMusic',
      );
    }

    final intro = presentation?.intro;
    if (intro != null) {
      categories.add(GamePackagePersonalizationCategory.intro);
      _certifyVideoMedia(
        intro.responsiveMedia,
        path: r'$.presentation.intro.media',
        titleLoop: false,
        certifyAsset: certifyAsset,
      );
    }

    final titleMotion = presentation?.titleMotion;
    if (titleMotion != null) {
      categories.add(GamePackagePersonalizationCategory.titleMotion);
      if (titleMotion.promptLoop case final prompt?) {
        _certifyVideoMedia(
          prompt,
          path: r'$.presentation.titleMotion.promptLoop',
          titleLoop: true,
          certifyAsset: certifyAsset,
        );
      }
      if (titleMotion.menuLoop case final menu?) {
        _certifyVideoMedia(
          menu,
          path: r'$.presentation.titleMotion.menuLoop',
          titleLoop: true,
          certifyAsset: certifyAsset,
        );
      }
    }

    final typography = presentation?.typography;
    if (typography != null) {
      categories.add(GamePackagePersonalizationCategory.typography);
      final roles = <String, GamePackageFontRole>{
        'display': typography.display,
        'body': typography.body,
        'dialogue': typography.dialogue,
        'numbers': typography.numbers,
      };
      for (final roleEntry in roles.entries) {
        final role = roleEntry.value;
        final embedsCustomFont =
            role.font != null || role.family != null || role.license != null;
        if (!embedsCustomFont) continue;
        if (role.license == null || role.license!.trim().isEmpty) {
          _fail(
            'presentationLicenseMissing',
            r'$.presentation.typography.'
                '${roleEntry.key}.license',
            'Every embedded font requires a packaged redistribution license.',
          );
        }
        if (role.font == null ||
            role.font!.trim().isEmpty ||
            role.family == null ||
            role.family!.trim().isEmpty) {
          _fail(
            'presentationTypographyIncomplete',
            '\$.presentation.typography.${roleEntry.key}',
            'Embedded typography requires a font file and family name.',
          );
        }
        certifyAsset(
          role.font,
          '\$.presentation.typography.${roleEntry.key}.font',
        );
        certifyAsset(
          role.license,
          '\$.presentation.typography.${roleEntry.key}.license',
        );
      }
    }

    if (presentation?.theme != null || presentation?.windows != null) {
      categories.add(GamePackagePersonalizationCategory.theme);
    }

    return GamePackagePersonalizationPreflightReceipt(
      gameId: manifest.gameId,
      gameVersion: manifest.gameVersion.toString(),
      treeSha256: manifest.content.treeSha256,
      packageSha256: receipt.packageSha256,
      presentationSha256: presentation == null
          ? null
          : CanonicalJson.sha256Hex(presentation.toJson()),
      configuredCategories: categories,
      assetSha256: assetHashes,
      videoCodec: intro?.landscape.videoCodec,
      audioCodec: intro?.landscape.audioCodec,
    );
  }

  void _certifyVideoMedia(
    GamePackageResponsiveVideo media, {
    required String path,
    required bool titleLoop,
    required void Function(String? path, String manifestPath) certifyAsset,
  }) {
    final variants = <String, GamePackageVideoVariant>{
      'landscape': media.landscape,
      if (media.portrait != null) 'portrait': media.portrait!,
    };
    for (final entry in variants.entries) {
      final variant = entry.value;
      final variantPath = '$path.${entry.key}';
      if (!variant.video.toLowerCase().endsWith('.mp4') ||
          variant.videoCodec != 'h264' ||
          (titleLoop
              ? variant.audioCodec != 'none'
              : !const <String>{'aac', 'none'}.contains(variant.audioCodec))) {
        _fail(
          'presentationMediaUnsupported',
          variantPath,
          'The playback contract is outside the supported codec matrix.',
        );
      }
      certifyAsset(variant.video, '$variantPath.video');
      certifyAsset(variant.poster, '$variantPath.poster');
      certifyAsset(variant.captions, '$variantPath.captions');
    }
  }

  bool _hasBranding(GamePackageBranding branding) =>
      branding.icon != null ||
      branding.cover != null ||
      branding.hero != null ||
      branding.accentColor != null ||
      branding.titleMusic != null ||
      branding.layoutVariant != null;

  bool _isSha256(String value) => _sha256.hasMatch(value);

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _sha256 = RegExp(r'^[a-f0-9]{64}$');
}
