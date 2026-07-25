import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

import 'game_package_export_profile.dart';
import 'runtime_project_projection_builder.dart';

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
    required this.certification,
    required this.suggestedFileName,
    required this.compiledDialogueCount,
    required this.scrubbedSecretFieldCount,
  }) : packageBytes = List.unmodifiable(packageBytes);

  final List<int> packageBytes;
  final GamePackageManifest manifest;
  final GamePackageInspectionResult inspection;
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
  });

  final RuntimeProjectProjectionBuilder projectionBuilder;
  final GamePackageBuilder packageBuilder;

  Future<GamePackageExportArtifact> build({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
  }) async {
    try {
      final projection = await projectionBuilder.build(
        projectRoot: projectRoot,
        profile: profile,
      );
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
          requiredCapabilities: profile.requiredCapabilities,
        ),
        locales: GamePackageLocales(
          defaultLocale: profile.defaultLocale,
          supported: profile.supportedLocales,
        ),
        branding: GamePackageBranding(
          icon: projection.iconPackagePath,
          cover: projection.coverPackagePath,
          hero: projection.heroPackagePath,
          accentColor: profile.accentColor,
          titleMusic: projection.titleMusicPackagePath,
          layoutVariant: profile.layoutVariant,
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
    await outputFile.parent.create(recursive: true);
    final token = '${DateTime.now().microsecondsSinceEpoch}-$pid';
    final temporary = File('${outputFile.path}.$token.tmp');
    final backup = File('${outputFile.path}.backup');
    var backedUp = false;
    try {
      await temporary.writeAsBytes(artifact.packageBytes, flush: true);
      final writtenBytes = await temporary.readAsBytes();
      if (sha256.convert(writtenBytes).toString() != artifact.packageSha256) {
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
      return artifact;
    } on Object catch (error) {
      if (!await outputFile.exists() && backedUp && await backup.exists()) {
        await backup.rename(outputFile.path);
      }
      if (await temporary.exists()) await temporary.delete();
      if (error is GamePackageExportException) rethrow;
      throw GamePackageExportException(
        code: 'exportWriteFailed',
        path: outputFile.path,
        message: 'The certified package could not be written atomically.',
        cause: error,
      );
    }
  }

  static Uri? _uri(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    return Uri.parse(source.trim());
  }

  static String _suggestedFileName(String title, String version) {
    var slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) slug = 'pokemap-game';
    return '$slug-$version.pokemapgame';
  }
}
