import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

import 'game_package_export_profile.dart';
import 'runtime_project_projection_builder.dart';

typedef GamePackageAtomicFileWriter = Future<void> Function({
  required File outputFile,
  required List<int> packageBytes,
  required String packageSha256,
});

final class GamePackageExportWriteFailure implements Exception {
  const GamePackageExportWriteFailure({
    required this.atomicError,
    required this.directError,
  });

  final Object atomicError;
  final Object directError;

  @override
  String toString() => 'Atomic sibling write failed: $atomicError '
      'Direct selected-file write failed: $directError';
}

final class GamePackageExportCertification {
  GamePackageExportCertification({
    required List<String> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final List<String> diagnostics;

  bool get isCertified => diagnostics.isEmpty;
}

final class GamePackageExportArtifact {
  GamePackageExportArtifact({
    required List<int> packageBytes,
    required this.manifest,
    required this.inspection,
    required this.personalizationPreflight,
    required this.certification,
    required this.suggestedFileName,
    required this.compiledDialogueCount,
    required this.scrubbedSecretFieldCount,
  }) : packageBytes = List.unmodifiable(packageBytes);

  final List<int> packageBytes;
  final GamePackageManifest manifest;
  final GamePackageInspectionResult inspection;
  final GamePackagePersonalizationPreflightReceipt personalizationPreflight;
  final GamePackageExportCertification certification;
  final String suggestedFileName;
  final int compiledDialogueCount;
  final int scrubbedSecretFieldCount;

  String get packageSha256 => sha256.convert(packageBytes).toString();
}

final class GamePackageExportService {
  const GamePackageExportService({
    this.projectionBuilder = const RuntimeProjectProjectionBuilder(),
    this.packageBuilder = const GamePackageBuilder(),
    this.atomicFileWriter,
  });

  final RuntimeProjectProjectionBuilder projectionBuilder;
  final GamePackageBuilder packageBuilder;
  final GamePackageAtomicFileWriter? atomicFileWriter;

  Future<GamePackageExportArtifact> build({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
  }) async {
    try {
      final projection = await projectionBuilder.build(
        projectRoot: projectRoot,
        profile: profile,
      );
      final requiredCapabilities = <String>{
        ...profile.requiredCapabilities,
        if (projection.project.maps.isNotEmpty) 'map@1',
      }.toList(growable: false)
        ..sort();
      final emptyContent = GamePackageContent(
        fileCount: 0,
        totalBytes: 0,
        treeSha256: '0' * 64,
        files: const <GamePackageFileEntry>[],
      );
      final manifest = GamePackageManifest(
        packageFormat: 1,
        gameId: profile.gameId,
        gameVersion: profile.parsedGameVersion,
        title: profile.title.trim(),
        description: profile.description?.trim(),
        author: GamePackageParty(
          name: profile.authorName.trim(),
          url: _uri(profile.authorUrl),
        ),
        publisher: profile.publisherName == null
            ? null
            : GamePackageParty(
                name: profile.publisherName!.trim(),
                url: _uri(profile.publisherUrl),
              ),
        compatibility: GamePackageCompatibility(
          minHubVersion: Version.parse('0.1.0'),
          runtimeApiExpression: '>=1.0.0 <2.0.0',
          projectFormat: projection.project.version.name,
          saveFormat: 1,
          compatibilityId: 'main',
          requiredCapabilities: requiredCapabilities,
        ),
        locales: GamePackageLocales(
          defaultLocale: profile.defaultLocale,
          supported: profile.supportedLocales,
        ),
        presentation: GamePackagePresentation(
          schemaVersion: projection.presentation.schemaVersion,
          branding: GamePackageBranding(
            icon: projection.iconPackagePath,
            cover: projection.coverPackagePath,
            hero: projection.heroPackagePath,
            accentColor: projection.presentation.branding.accentColor,
            titleMusic: projection.titleMusicPackagePath,
            layoutVariant: projection.presentation.branding.layoutVariant,
          ),
          intro: projection.presentation.intro == null
              ? null
              : GamePackageIntroVideo(
                  video: projection.introVideoPackagePath!,
                  poster: projection.introPosterPackagePath!,
                  captions: projection.introCaptionsPackagePath,
                  durationMilliseconds:
                      projection.presentation.intro!.durationMilliseconds,
                  width: projection.presentation.intro!.width,
                  height: projection.presentation.intro!.height,
                  bitrateKbps: projection.presentation.intro!.bitrateKbps,
                  sizeBytes: projection.presentation.intro!.sizeBytes,
                  videoCodec: projection.presentation.intro!.videoCodec,
                  audioCodec: projection.presentation.intro!.audioCodec,
                  reducedMotionBehavior:
                      projection.presentation.intro!.reducedMotionBehavior,
                  allowReplay: projection.presentation.intro!.allowReplay,
                ),
          typography: projection.presentation.typography == null
              ? null
              : GamePackageTypography(
                  display: _packageFontRole(
                    projection,
                    ProjectTypographyRole.display,
                  ),
                  body: _packageFontRole(
                    projection,
                    ProjectTypographyRole.body,
                  ),
                  dialogue: _packageFontRole(
                    projection,
                    ProjectTypographyRole.dialogue,
                  ),
                  numbers: _packageFontRole(
                    projection,
                    ProjectTypographyRole.numbers,
                  ),
                ),
          theme: projection.presentation.theme == null
              ? null
              : _packageSemanticTheme(projection.presentation.theme!),
        ),
        content: emptyContent,
      );
      final built = packageBuilder.build(
        manifest: manifest,
        payloadFiles: projection.payloadFiles,
      );
      final inspector = GamePackageInspector(
        hostCompatibility: GamePackageHostCompatibility(
          hubVersion: Version.parse('1.2.0'),
          runtimeApiVersion: Version.parse('1.4.0'),
          capabilities: const <String>{
            'dialogue.choices@1',
            'map@1',
            'overworld.menu@1',
            'world.shop@1',
          },
          supportedProjectFormats: <String>{
            projection.project.version.name,
          },
          currentProjectFormat: projection.project.version.name,
          supportedSaveFormats: const <int>{1},
        ),
      );
      final inspection = inspector.inspect(built.packageBytes);
      final personalizationPreflight =
          const GamePackagePersonalizationPreflight().certify(inspection);
      final diagnostics = <String>[
        if (inspection.manifest.gameId != profile.gameId)
          'Exported game identity changed during packaging.',
        if (inspection.manifest.gameVersion != profile.parsedGameVersion)
          'Exported game version changed during packaging.',
        if (inspection.manifest.content.treeSha256 !=
            built.manifest.content.treeSha256)
          'Reopened package tree hash differs from the built manifest.',
        if (inspection.compatibility?.decision !=
            GamePackageCompatibilityDecision.accept)
          'Exported package is not compatible with the generic Hub contract.',
      ];
      final certification =
          GamePackageExportCertification(diagnostics: diagnostics);
      if (!certification.isCertified) {
        throw GamePackageExportException(
          code: 'exportCertificationFailed',
          message: diagnostics.join(' '),
        );
      }
      return GamePackageExportArtifact(
        packageBytes: built.packageBytes,
        manifest: built.manifest,
        inspection: inspection,
        personalizationPreflight: personalizationPreflight,
        certification: certification,
        suggestedFileName: _suggestedFileName(
          profile.title,
          profile.gameVersion,
        ),
        compiledDialogueCount: projection.compiledDialogueCount,
        scrubbedSecretFieldCount: projection.scrubbedSecretFieldCount,
      );
    } on GamePackageExportException {
      rethrow;
    } on GamePackageFormatException catch (error) {
      throw GamePackageExportException(
        code: error.code,
        path: error.path,
        message: error.message,
        cause: error,
      );
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'gameExportFailed',
        message: 'The game package could not be built and certified.',
        cause: error,
      );
    }
  }

  Future<GamePackageExportArtifact> exportToFile({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
    required File outputFile,
  }) async {
    if (!outputFile.path.toLowerCase().endsWith('.pokemapgame')) {
      throw GamePackageExportException(
        code: 'invalidExportDestination',
        path: outputFile.path,
        message: 'Export destination must use the .pokemapgame extension.',
      );
    }
    final artifact = await build(projectRoot: projectRoot, profile: profile);
    try {
      await outputFile.parent.create(recursive: true);
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'exportWriteFailed',
        path: outputFile.path,
        message: 'The export destination cannot be prepared.',
        cause: error,
      );
    }
    final atomicWriter = atomicFileWriter ?? _writeAtomically;
    try {
      await atomicWriter(
        outputFile: outputFile,
        packageBytes: artifact.packageBytes,
        packageSha256: artifact.packageSha256,
      );
      return artifact;
    } on FileSystemException catch (atomicError) {
      // NSSavePanel grants a sandboxed macOS application access to the exact
      // selected file, but not necessarily to sibling `.tmp` or `.backup`
      // files. Keep the crash-atomic path as the default, then fall back to a
      // flushed, digest-verified write to the explicitly selected file.
      try {
        await _writeDirectlyToSelectedFile(
          outputFile: outputFile,
          packageBytes: artifact.packageBytes,
          packageSha256: artifact.packageSha256,
        );
        return artifact;
      } on Object catch (directError) {
        throw GamePackageExportException(
          code: 'exportWriteFailed',
          path: outputFile.path,
          message: 'The certified package could not be written.',
          cause: GamePackageExportWriteFailure(
            atomicError: atomicError,
            directError: directError,
          ),
        );
      }
    } on GamePackageExportException {
      rethrow;
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'exportWriteFailed',
        path: outputFile.path,
        message: 'The certified package could not be written atomically.',
        cause: error,
      );
    }
  }

  static Future<void> _writeAtomically({
    required File outputFile,
    required List<int> packageBytes,
    required String packageSha256,
  }) async {
    final token = '${DateTime.now().microsecondsSinceEpoch}-$pid';
    final temporary = File('${outputFile.path}.$token.tmp');
    final backup = File('${outputFile.path}.backup');
    var backedUp = false;
    try {
      await temporary.writeAsBytes(packageBytes, flush: true);
      final writtenBytes = await temporary.readAsBytes();
      if (sha256.convert(writtenBytes).toString() != packageSha256) {
        throw const GamePackageExportException(
          code: 'exportWriteVerificationFailed',
          message: 'Written package digest differs from the certified bytes.',
        );
      }
      if (await outputFile.exists()) {
        if (await backup.exists()) await backup.delete();
        await outputFile.rename(backup.path);
        backedUp = true;
      }
      await temporary.rename(outputFile.path);
      if (backedUp && await backup.exists()) await backup.delete();
    } on Object {
      try {
        if (!await outputFile.exists() && backedUp && await backup.exists()) {
          await backup.rename(outputFile.path);
        }
      } on Object {
        // Preserve the original filesystem error. The backup remains beside
        // the destination for manual recovery if automatic restoration fails.
      }
      try {
        if (await temporary.exists()) await temporary.delete();
      } on Object {
        // Best-effort staging cleanup must not hide the original failure.
      }
      rethrow;
    }
  }

  static Future<void> _writeDirectlyToSelectedFile({
    required File outputFile,
    required List<int> packageBytes,
    required String packageSha256,
  }) async {
    List<int>? previousBytes;
    if (await outputFile.exists()) {
      previousBytes = await outputFile.readAsBytes();
    }
    try {
      await outputFile.writeAsBytes(packageBytes, flush: true);
      final writtenBytes = await outputFile.readAsBytes();
      if (sha256.convert(writtenBytes).toString() != packageSha256) {
        throw const GamePackageExportException(
          code: 'exportWriteVerificationFailed',
          message: 'Written package digest differs from the certified bytes.',
        );
      }
    } on Object {
      try {
        if (previousBytes != null) {
          await outputFile.writeAsBytes(previousBytes, flush: true);
        } else if (await outputFile.exists()) {
          await outputFile.delete();
        }
      } on Object {
        // Preserve the write error; restoration is a best-effort safeguard for
        // a destination selected by the user.
      }
      rethrow;
    }
  }

  static Uri? _uri(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    return Uri.parse(source.trim());
  }

  static GamePackageFontRole _packageFontRole(
    RuntimeProjectProjection projection,
    ProjectTypographyRole role,
  ) {
    final projected = projection.typographyRoles[role]!;
    return GamePackageFontRole(
      font: projected.fontPackagePath,
      family: projected.profile.family,
      license: projected.licensePackagePath,
      fallbackFamilies: projected.profile.fallbackFamilies,
    );
  }

  static GamePackageSemanticTheme _packageSemanticTheme(
    ProjectSemanticThemeProfile theme,
  ) =>
      GamePackageSemanticTheme(
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
      );

  static String _suggestedFileName(String title, String version) {
    var slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) slug = 'pokemap-game';
    return '$slug-$version.pokemapgame';
  }
}
