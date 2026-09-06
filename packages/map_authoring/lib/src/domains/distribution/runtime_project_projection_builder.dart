import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as image;

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../../contracts/artifact_ref.dart';
import '../assets/asset_store.dart';
import '../assets/project_media_store.dart';
import 'game_package_export_profile.dart';

final class RuntimeProjectProjection {
  RuntimeProjectProjection({
    required this.project,
    required this.presentation,
    required Map<String, List<int>> payloadFiles,
    required Set<String> payloadDirectories,
    required this.compiledDialogueCount,
    required this.scrubbedSecretFieldCount,
    this.iconPackagePath,
    this.coverPackagePath,
    this.heroPackagePath,
    this.menuBackgroundPackagePath,
    this.titleMusicPackagePath,
    this.introMedia,
    this.titlePromptMedia,
    this.titleMenuMedia,
    Map<ProjectTypographyRole, RuntimeProjectedFontRole> typographyRoles =
        const <ProjectTypographyRole, RuntimeProjectedFontRole>{},
  })  : payloadFiles = Map.unmodifiable(
          payloadFiles.map(
            (path, bytes) => MapEntry(path, List<int>.unmodifiable(bytes)),
          ),
        ),
        payloadDirectories = Set.unmodifiable(
          payloadDirectories.toList(growable: false)..sort(),
        ),
        typographyRoles = Map.unmodifiable(typographyRoles);

  final ProjectManifest project;
  final ProjectPresentationProfile presentation;
  final Map<String, List<int>> payloadFiles;
  final Set<String> payloadDirectories;
  final int compiledDialogueCount;
  final int scrubbedSecretFieldCount;
  final String? iconPackagePath;
  final String? coverPackagePath;
  final String? heroPackagePath;
  final String? menuBackgroundPackagePath;
  final String? titleMusicPackagePath;
  final RuntimeProjectedResponsiveVideo? introMedia;
  final RuntimeProjectedResponsiveVideo? titlePromptMedia;
  final RuntimeProjectedResponsiveVideo? titleMenuMedia;
  final Map<ProjectTypographyRole, RuntimeProjectedFontRole> typographyRoles;

  String? get introVideoPackagePath => introMedia?.landscape.videoPackagePath;
  String? get introPosterPackagePath => introMedia?.landscape.posterPackagePath;
  String? get introCaptionsPackagePath =>
      introMedia?.landscape.captionsPackagePath;
}

final class RuntimeProjectedVideoVariant {
  const RuntimeProjectedVideoVariant({
    required this.profile,
    required this.videoPackagePath,
    required this.posterPackagePath,
    this.captionsPackagePath,
  });

  final ProjectVideoVariantProfile profile;
  final String videoPackagePath;
  final String posterPackagePath;
  final String? captionsPackagePath;
}

final class RuntimeProjectedResponsiveVideo {
  const RuntimeProjectedResponsiveVideo({
    required this.landscape,
    this.portrait,
  });

  final RuntimeProjectedVideoVariant landscape;
  final RuntimeProjectedVideoVariant? portrait;
}

final class RuntimeProjectedFontRole {
  const RuntimeProjectedFontRole({
    required this.profile,
    required this.fontPackagePath,
    required this.licensePackagePath,
  });

  final ProjectTypographyRoleProfile profile;
  final String? fontPackagePath;
  final String? licensePackagePath;
}

final class _PresentationPackageProjection {
  const _PresentationPackageProjection({
    required this.catalog,
    required this.receipt,
    required this.excludedSourceAssetIds,
    required this.excludedLogicalPaths,
  });

  final ProjectMediaCatalog catalog;
  final PresentationMediaPublicationReceipt receipt;
  final Set<String> excludedSourceAssetIds;
  final Set<String> excludedLogicalPaths;
}

final class RuntimeProjectProjectionBuilder {
  const RuntimeProjectProjectionBuilder({
    this.maxWorkspaceEntries = 100000,
    this.maxPayloadEntries = 20000,
    this.maxFileBytes = 268435456,
    this.maxJsonSourceBytes = 33554432,
    this.maxTotalPayloadBytes = 1073741824,
  });

  final int maxWorkspaceEntries;
  final int maxPayloadEntries;
  final int maxFileBytes;
  final int maxJsonSourceBytes;
  final int maxTotalPayloadBytes;

  Future<RuntimeProjectProjection> build({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
  }) async {
    await _requireDirectory(projectRoot);
    final budget = _ProjectionBudget(
      maxWorkspaceEntries: maxWorkspaceEntries,
      maxPayloadEntries: maxPayloadEntries,
      maxFileBytes: maxFileBytes,
      maxJsonSourceBytes: maxJsonSourceBytes,
      maxTotalPayloadBytes: maxTotalPayloadBytes,
    );
    final authorFiles = await _AuthorProjectFileResolver.load(
      projectRoot,
      budget,
    );
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    await _requireRegularFile(projectFile, logicalPath: 'project.json');

    var scrubbedSecretFieldCount = 0;
    final authorProjectJson = _decodeJsonObject(
      await budget.readFile(
        projectFile,
        logicalPath: 'project.json',
        jsonLike: true,
      ),
      'project.json',
    );
    final projectScrub = _scrubJson(authorProjectJson);
    scrubbedSecretFieldCount += projectScrub.removedSecretFields;
    final authorProject = ProjectManifest.fromJson(
      (projectScrub.value as Map).cast<String, dynamic>(),
    );
    final presentation = authorProject.presentation ??
        ProjectPresentationProfile(
          branding: ProjectBrandingProfile(
            iconPath: profile.iconPath,
            coverPath: profile.coverPath,
            heroPath: profile.heroPath,
            accentColor: profile.accentColor,
            titleMusicPath: profile.titleMusicPath,
            layoutVariant: profile.layoutVariant ?? 'standard',
          ),
        );
    final presentationDiagnostics =
        validateProjectPresentationProfile(presentation);
    final blockingPresentationDiagnostic = presentationDiagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity ==
              ProjectPresentationDiagnosticSeverity.error,
        )
        .firstOrNull;
    if (blockingPresentationDiagnostic != null) {
      throw GamePackageExportException(
        code: blockingPresentationDiagnostic.code,
        path: blockingPresentationDiagnostic.path,
        message: blockingPresentationDiagnostic.message,
      );
    }

    final payload = <String, List<int>>{};
    final payloadDirectories = <String>{};
    final dialogueSources = <String>{};
    final compiledEntries = <ProjectDialogueEntry>[];
    final compiledPaths = <String>{};
    for (final entry in authorProject.dialogues) {
      final sourcePath = _normalizeRelative(entry.relativePath);
      dialogueSources.add(sourcePath);
      final extension = p.extension(sourcePath).toLowerCase();
      final RuntimeDialogueDocument document;
      if (extension == '.yarn') {
        try {
          document = const YarnDialogueCompiler().compile(
            utf8.decode(
              await authorFiles.read(
                sourcePath,
                budget,
                jsonLike: true,
              ),
              allowMalformed: false,
            ),
          );
        } on Object catch (error) {
          throw GamePackageExportException(
            code: 'dialogueCompilationFailed',
            path: sourcePath,
            message: 'Dialogue "${entry.name}" could not be compiled.',
            cause: error,
          );
        }
      } else if (extension == '.json') {
        try {
          document = const RuntimeDialogueDocumentCodec().decodeUtf8(
            await authorFiles.read(
              sourcePath,
              budget,
              jsonLike: true,
            ),
          );
        } on Object catch (error) {
          throw GamePackageExportException(
            code: 'invalidCompiledDialogue',
            path: sourcePath,
            message: 'Dialogue "${entry.name}" is not runtime data v1.',
            cause: error,
          );
        }
      } else {
        throw GamePackageExportException(
          code: 'unsupportedDialogueSource',
          path: sourcePath,
          message: 'Dialogue sources must be Yarn or runtime JSON.',
        );
      }
      final runtimeRelativePath =
          'dialogues/${_safeDialogueFileName(entry.id)}.json';
      if (!compiledPaths.add(runtimeRelativePath)) {
        throw GamePackageExportException(
          code: 'dialoguePathCollision',
          path: runtimeRelativePath,
          message: 'Two dialogue IDs resolve to the same runtime filename.',
        );
      }
      budget.addPayload(
        payload,
        'project/$runtimeRelativePath',
        const RuntimeDialogueDocumentCodec().encodeUtf8(document),
      );
      compiledEntries.add(entry.copyWith(relativePath: runtimeRelativePath));
    }

    final projectedProject = authorProject.copyWith(
      dialogues: compiledEntries,
      settings: authorProject.settings.copyWith(mistralApiKey: null),
      presentation: presentation,
    );

    final presentationPackage = await _preparePresentationPackage(
      authorProject,
      authorFiles,
      budget,
    );

    await _addPortableAssetClosure(
      payload,
      authorFiles,
      budget,
      excludedAssetIds:
          presentationPackage?.excludedSourceAssetIds ?? const <String>{},
    );

    await for (final entity
        in projectRoot.list(recursive: true, followLinks: false)) {
      budget.visitWorkspaceEntry();
      final type = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      final relative = _normalizeRelative(
        p.relative(entity.path, from: projectRoot.path),
      );
      if (type == FileSystemEntityType.link) {
        throw GamePackageExportException(
          code: 'symlinkRejected',
          path: relative,
          message: 'Author workspaces containing symlinks cannot be exported.',
        );
      }
      if (type == FileSystemEntityType.directory &&
          !_isExcludedAuthoringPath(relative)) {
        payloadDirectories.add(
          _normalizePackagePath('project/$relative'),
        );
        continue;
      }
      if (type != FileSystemEntityType.file ||
          relative == 'project.json' ||
          dialogueSources.contains(relative) ||
          (presentationPackage?.excludedLogicalPaths.contains(relative) ??
              false) ||
          _isExcludedAuthoringPath(relative)) {
        continue;
      }
      final extension = p.extension(relative).toLowerCase();
      if (!_isRuntimeProjectFile(
        relative,
        extension,
        hasCanonicalAssetCatalog: authorFiles.catalog.records.isNotEmpty,
      )) {
        continue;
      }
      final bytes = await budget.readFile(
        File(entity.path),
        logicalPath: relative,
        jsonLike: extension == '.json',
      );
      final packagePath = _normalizePackagePath('project/$relative');
      if (extension == '.json') {
        final decoded = _decodeJson(bytes, relative);
        final scrubbed = _scrubJson(decoded);
        scrubbedSecretFieldCount += scrubbed.removedSecretFields;
        final rewritten = _rewriteLegacyDialogueReferences(scrubbed.value);
        budget.addPayload(
          payload,
          packagePath,
          _encodeRuntimeJson(rewritten),
        );
      } else {
        budget.addPayload(payload, packagePath, bytes);
      }
    }

    budget.addPayload(
      payload,
      'project/project.json',
      _encodeRuntimeJson(projectedProject.toJson()),
    );
    if (presentationPackage != null) {
      budget
        ..addPayload(
          payload,
          'project/$projectMediaCatalogStorageKey',
          encodeProjectMediaCatalogBytes(presentationPackage.catalog),
        )
        ..addPayload(
          payload,
          'presentation/cinematics/publication.json',
          _encodeRuntimeJson(presentationPackage.receipt.toJson()),
        );
    }

    final menuBackgroundPackagePath = await _addPresentationAsset(
        payload,
        authorFiles,
        presentation.pause?.background?.imagePath,
        'menu-background',
        budget);
    final iconPackagePath = await _addPresentationAsset(
      payload,
      authorFiles,
      presentation.branding.iconPath,
      'icon',
      budget,
    );
    final coverPackagePath = await _addPresentationAsset(
      payload,
      authorFiles,
      presentation.branding.coverPath,
      'cover',
      budget,
    );
    final heroPackagePath = await _addPresentationAsset(
      payload,
      authorFiles,
      presentation.branding.heroPath,
      'hero',
      budget,
    );
    await _addLegalFile(
      payload,
      authorFiles,
      profile.licensePath,
      'LICENSE.txt',
      budget,
    );
    await _addLegalFile(
      payload,
      authorFiles,
      profile.creditsPath,
      'CREDITS.txt',
      budget,
    );
    final titleMusicPath = presentation.branding.titleMusicPath;
    final titleMusicPackagePath = titleMusicPath == null
        ? null
        : _normalizePackagePath('project/$titleMusicPath');
    if (titleMusicPackagePath != null) {
      if (!_audioExtensions.contains(
            p.extension(titleMusicPath!).toLowerCase(),
          ) ||
          !titleMusicPackagePath.startsWith('project/assets/')) {
        throw GamePackageExportException(
          code: 'invalidTitleMusic',
          path: titleMusicPath,
          message: 'Title music must reference an exported audio asset.',
        );
      }
      budget.replacePayload(
        payload,
        titleMusicPackagePath,
        await authorFiles.read(titleMusicPath, budget),
      );
    }
    final intro = presentation.intro;
    final introMedia = intro == null
        ? null
        : await _addResponsiveVideo(
            payload,
            authorFiles,
            intro.media,
            packageRoot: 'presentation/intro',
            budget: budget,
          );
    final titlePromptMedia = presentation.titleMotion?.promptLoop == null
        ? null
        : await _addResponsiveVideo(
            payload,
            authorFiles,
            presentation.titleMotion!.promptLoop!,
            packageRoot: 'presentation/title/prompt',
            budget: budget,
          );
    final titleMenuMedia = presentation.titleMotion?.menuLoop == null
        ? null
        : await _addResponsiveVideo(
            payload,
            authorFiles,
            presentation.titleMotion!.menuLoop!,
            packageRoot: 'presentation/title/menu',
            budget: budget,
          );
    final typographyRoles = <ProjectTypographyRole, RuntimeProjectedFontRole>{};
    final typography = presentation.typography;
    if (typography != null) {
      for (final role in ProjectTypographyRole.values) {
        if (role == ProjectTypographyRole.combat && typography.combat == null) {
          continue;
        }
        final roleProfile = switch (role) {
          ProjectTypographyRole.display => typography.display,
          ProjectTypographyRole.body => typography.body,
          ProjectTypographyRole.dialogue => typography.dialogue,
          ProjectTypographyRole.numbers => typography.numbers,
          ProjectTypographyRole.combat => typography.combat!,
        };
        typographyRoles[role] = await _addTypographyRole(
          payload,
          authorFiles,
          role,
          roleProfile,
          budget,
        );
      }
    }

    return RuntimeProjectProjection(
      project: projectedProject,
      presentation: presentation,
      payloadFiles: payload,
      payloadDirectories: payloadDirectories,
      compiledDialogueCount: compiledEntries.length,
      scrubbedSecretFieldCount: scrubbedSecretFieldCount,
      iconPackagePath: iconPackagePath,
      coverPackagePath: coverPackagePath,
      heroPackagePath: heroPackagePath,
      menuBackgroundPackagePath: menuBackgroundPackagePath,
      titleMusicPackagePath: titleMusicPackagePath,
      introMedia: introMedia,
      titlePromptMedia: titlePromptMedia,
      titleMenuMedia: titleMenuMedia,
      typographyRoles: typographyRoles,
    );
  }

  Future<void> _addPortableAssetClosure(Map<String, List<int>> payload,
      _AuthorProjectFileResolver authorFiles, _ProjectionBudget budget,
      {Set<String> excludedAssetIds = const <String>{}}) async {
    final records = authorFiles.catalog.records
        .where((record) => !excludedAssetIds.contains(record.id))
        .toList();
    if (records.isEmpty && authorFiles.catalog.records.isEmpty) return;
    budget.addPayload(
      payload,
      _normalizePackagePath('project/$assetCatalogStorageKey'),
      _encodeRuntimeJson(AssetCatalog(records: records).toJson()),
    );
    final packagedArtifacts = <String>{};
    for (final record in records) {
      final storagePath = assetBlobStorageKey(record.artifact);
      if (!packagedArtifacts.add(storagePath)) continue;
      budget.addPayload(
        payload,
        _normalizePackagePath('project/$storagePath'),
        await authorFiles.read(record.logicalPath, budget),
      );
    }
  }

  Future<_PresentationPackageProjection?> _preparePresentationPackage(
    ProjectManifest project,
    _AuthorProjectFileResolver authorFiles,
    _ProjectionBudget budget,
  ) async {
    final storedCatalog = await authorFiles.readProjectMediaCatalog(budget);
    if (storedCatalog == null && project.presentationCinematics.isEmpty) {
      return null;
    }
    final sourceCatalog = storedCatalog ?? ProjectMediaCatalog();
    final receipt = const PresentationMediaPublicationPreflight().inspect(
      catalog: sourceCatalog,
      cinematics: project.presentationCinematics,
    );
    if (!receipt.canPublish) {
      final diagnostic = receipt.diagnostics.first;
      throw GamePackageExportException(
        code: diagnostic.code,
        path: diagnostic.path,
        message: diagnostic.message,
      );
    }
    final packagedMediaIds = receipt.media.map((media) => media.id).toSet();
    final packagedSourceAssetIds = <String>{};
    for (final media in receipt.media) {
      final record = authorFiles.catalog.find(media.sourceAssetId);
      if (record == null) {
        throw GamePackageExportException(
          code: 'presentationMediaSourceMissing',
          path: 'media[${media.id}].sourceAssetId',
          message:
              'Presentation media source is missing from the asset catalog.',
        );
      }
      final metadata = media.technicalMetadata!;
      if (record.artifact.byteLength != metadata.sizeBytes ||
          record.artifact.mediaType != metadata.mediaType) {
        throw GamePackageExportException(
          code: 'presentationMediaSourceMetadataMismatch',
          path: 'media[${media.id}].technicalMetadata',
          message: 'Presentation media metadata does not match its source.',
        );
      }
      packagedSourceAssetIds.add(media.sourceAssetId);
    }
    final presentationSourceAssetIds =
        sourceCatalog.entries.map((media) => media.sourceAssetId).toSet();
    final excludedSourceAssetIds =
        presentationSourceAssetIds.difference(packagedSourceAssetIds);
    final excludedLogicalPaths = authorFiles.catalog.records
        .where((record) => excludedSourceAssetIds.contains(record.id))
        .map((record) => record.logicalPath)
        .toSet();
    return _PresentationPackageProjection(
      catalog: ProjectMediaCatalog(
        entries: sourceCatalog.entries
            .where((media) => packagedMediaIds.contains(media.id)),
      ),
      receipt: receipt,
      excludedSourceAssetIds: excludedSourceAssetIds,
      excludedLogicalPaths: excludedLogicalPaths,
    );
  }

  Future<RuntimeProjectedResponsiveVideo> _addResponsiveVideo(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    ProjectResponsiveVideoProfile media, {
    required String packageRoot,
    required _ProjectionBudget budget,
  }) async =>
      RuntimeProjectedResponsiveVideo(
        landscape: await _addVideoVariant(
          payload,
          authorFiles,
          media.landscape,
          packageRoot: '$packageRoot/landscape',
          budget: budget,
        ),
        portrait: media.portrait == null
            ? null
            : await _addVideoVariant(
                payload,
                authorFiles,
                media.portrait!,
                packageRoot: '$packageRoot/portrait',
                budget: budget,
              ),
      );

  Future<RuntimeProjectedVideoVariant> _addVideoVariant(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    ProjectVideoVariantProfile variant, {
    required String packageRoot,
    required _ProjectionBudget budget,
  }) async {
    final bytes = await authorFiles.read(variant.videoPath, budget);
    final signature = latin1.decode(bytes, allowInvalid: true);
    if (!variant.videoPath.toLowerCase().endsWith('.mp4') ||
        bytes.length != variant.sizeBytes ||
        !signature.contains('ftyp') ||
        !(signature.contains('avc1') || signature.contains('avc3')) ||
        (variant.audioCodec == 'aac' && !signature.contains('mp4a'))) {
      throw GamePackageExportException(
        code: 'invalidIntroVideo',
        path: variant.videoPath,
        message: 'Presentation video bytes do not match the declared metadata.',
      );
    }
    final videoPackagePath = '$packageRoot/video.mp4';
    budget.addPayload(payload, videoPackagePath, bytes);
    final posterRole =
        '${packageRoot.substring('presentation/'.length)}/poster';
    final posterPackagePath = await _addPresentationAsset(
      payload,
      authorFiles,
      variant.posterPath,
      posterRole,
      budget,
    );
    final captionsPackagePath = variant.captionsPath == null
        ? null
        : await _addIntroCaptions(
            payload,
            authorFiles,
            variant.captionsPath!,
            packagePath: '$packageRoot/captions.vtt',
            budget: budget,
          );
    return RuntimeProjectedVideoVariant(
      profile: variant,
      videoPackagePath: videoPackagePath,
      posterPackagePath: posterPackagePath!,
      captionsPackagePath: captionsPackagePath,
    );
  }

  Future<String> _addIntroCaptions(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    String relativePath, {
    required String packagePath,
    required _ProjectionBudget budget,
  }) async {
    final bytes = await authorFiles.read(
      relativePath,
      budget,
      jsonLike: true,
    );
    late final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw GamePackageExportException(
        code: 'invalidIntroCaptions',
        path: relativePath,
        message: 'Intro captions must be valid UTF-8 WebVTT.',
        cause: error,
      );
    }
    if (!relativePath.toLowerCase().endsWith('.vtt') ||
        !source.startsWith('WEBVTT')) {
      throw GamePackageExportException(
        code: 'invalidIntroCaptions',
        path: relativePath,
        message: 'Intro captions must be valid WebVTT.',
      );
    }
    budget.addPayload(payload, packagePath, bytes);
    return packagePath;
  }

  Future<RuntimeProjectedFontRole> _addTypographyRole(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    ProjectTypographyRole role,
    ProjectTypographyRoleProfile profile,
    _ProjectionBudget budget,
  ) async {
    final fontPath = profile.fontPath;
    if (fontPath == null) {
      return RuntimeProjectedFontRole(
        profile: profile,
        fontPackagePath: null,
        licensePackagePath: null,
      );
    }
    final licensePath = profile.licensePath!;
    final fontBytes = await authorFiles.read(fontPath, budget);
    final extension = p.extension(fontPath).toLowerCase();
    final isTtf = extension == '.ttf' &&
        fontBytes.length >= 4 &&
        (fontBytes[0] == 0 &&
                fontBytes[1] == 1 &&
                fontBytes[2] == 0 &&
                fontBytes[3] == 0 ||
            ascii.decode(fontBytes.sublist(0, 4), allowInvalid: true) ==
                'true');
    final isOtf = extension == '.otf' &&
        fontBytes.length >= 4 &&
        ascii.decode(fontBytes.sublist(0, 4), allowInvalid: true) == 'OTTO';
    if (!isTtf && !isOtf) {
      throw GamePackageExportException(
        code: 'invalidTypographyFont',
        path: fontPath,
        message: 'Typography font bytes do not match TTF or OTF.',
      );
    }
    final licenseBytes = await authorFiles.read(
      licensePath,
      budget,
      jsonLike: true,
    );
    try {
      if (utf8.decode(licenseBytes, allowMalformed: false).trim().isEmpty) {
        throw const FormatException();
      }
    } on FormatException {
      throw GamePackageExportException(
        code: 'invalidTypographyLicense',
        path: licensePath,
        message: 'Typography license must contain strict UTF-8 text.',
      );
    }
    final roleName = role.name;
    final fontPackagePath = 'presentation/fonts/$roleName$extension';
    final licensePackagePath = 'presentation/fonts/$roleName-license.txt';
    budget
      ..addPayload(payload, fontPackagePath, fontBytes)
      ..addPayload(payload, licensePackagePath, licenseBytes);
    return RuntimeProjectedFontRole(
      profile: profile,
      fontPackagePath: fontPackagePath,
      licensePackagePath: licensePackagePath,
    );
  }

  Future<void> _requireDirectory(Directory directory) async {
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.directory) {
      throw GamePackageExportException(
        code: 'invalidProjectRoot',
        path: directory.path,
        message: 'Project root must be a regular directory.',
      );
    }
  }

  Future<void> _requireRegularFile(
    File file, {
    required String logicalPath,
  }) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw GamePackageExportException(
        code: 'missingProjectFile',
        path: logicalPath,
        message: 'Required authoring file is missing or unsafe.',
      );
    }
  }

  Future<String?> _addPresentationAsset(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    String? relativePath,
    String role,
    _ProjectionBudget budget,
  ) async {
    if (relativePath == null) return null;
    final extension = p.extension(relativePath).toLowerCase();
    if (!_presentationExtensions.contains(extension)) {
      throw GamePackageExportException(
        code: 'invalidBrandingAsset',
        path: relativePath,
        message: '$role must use an allowlisted image or audio format.',
      );
    }
    final bytes = await authorFiles.read(relativePath, budget);
    if (role == 'menu-background') {
      image.Image? decoded;
      try {
        decoded = image.decodeImage(Uint8List.fromList(bytes));
      } on Object {
        decoded = null;
      }
      if (decoded == null || decoded.width > 4096 || decoded.height > 4096) {
        throw GamePackageExportException(
            code: 'invalidMenuBackground',
            path: relativePath,
            message:
                'The menu background must be a decodable image up to 4096 pixels per side.');
      }
    }
    final packagePath = 'presentation/$role$extension';
    budget.addPayload(payload, packagePath, bytes);
    return packagePath;
  }

  Future<void> _addLegalFile(
    Map<String, List<int>> payload,
    _AuthorProjectFileResolver authorFiles,
    String? relativePath,
    String targetName,
    _ProjectionBudget budget,
  ) async {
    if (relativePath == null) return;
    final bytes = await authorFiles.read(
      relativePath,
      budget,
      jsonLike: true,
    );
    try {
      utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw GamePackageExportException(
        code: 'invalidLegalText',
        path: relativePath,
        message: 'Legal files must use strict UTF-8.',
        cause: error,
      );
    }
    budget.addPayload(payload, 'legal/$targetName', bytes);
  }

  Map<String, dynamic> _decodeJsonObject(
    List<int> bytes,
    String logicalPath,
  ) {
    final value = _decodeJson(bytes, logicalPath);
    if (value is! Map<String, dynamic>) {
      throw GamePackageExportException(
        code: 'invalidProjectManifest',
        path: logicalPath,
        message: 'Project manifest must be a JSON object.',
      );
    }
    return value;
  }

  Object? _decodeJson(List<int> bytes, String logicalPath) {
    try {
      return jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'invalidProjectJson',
        path: logicalPath,
        message: 'Runtime JSON source is malformed.',
        cause: error,
      );
    }
  }

  List<int> _encodeRuntimeJson(Object? value) =>
      utf8.encode(jsonEncode(_normalizeJsonStrings(value)));

  Object? _normalizeJsonStrings(Object? value) {
    if (value is String) return PackagePathPolicy.normalizeNfc(value);
    if (value is List) {
      return value.map(_normalizeJsonStrings).toList(growable: false);
    }
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key as String: _normalizeJsonStrings(entry.value),
      };
    }
    return value;
  }

  _JsonScrubResult _scrubJson(Object? value) {
    if (value is List) {
      var removed = 0;
      final result = <Object?>[];
      for (final child in value) {
        final scrubbed = _scrubJson(child);
        removed += scrubbed.removedSecretFields;
        result.add(scrubbed.value);
      }
      return _JsonScrubResult(result, removed);
    }
    if (value is Map) {
      var removed = 0;
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const GamePackageExportException(
            code: 'invalidProjectJson',
            message: 'Runtime JSON object keys must be strings.',
          );
        }
        final key = entry.key as String;
        if (entry.value case final String text
            when _isAuthorTimeRemoteReference(key, text)) {
          continue;
        }
        if (_secretKeys.contains(_normalizeKey(key))) {
          removed++;
          continue;
        }
        final scrubbed = _scrubJson(entry.value);
        removed += scrubbed.removedSecretFields;
        result[key] = scrubbed.value;
      }
      return _JsonScrubResult(result, removed);
    }
    return _JsonScrubResult(value, 0);
  }

  Object? _rewriteLegacyDialogueReferences(Object? value) {
    if (value is List) {
      return value
          .map(_rewriteLegacyDialogueReferences)
          .toList(growable: false);
    }
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) continue;
        final key = entry.key as String;
        final child = entry.value;
        if (key == 'scriptPathRelative' &&
            child is String &&
            child.toLowerCase().endsWith('.yarn')) {
          result[key] = '';
        } else {
          result[key] = _rewriteLegacyDialogueReferences(child);
        }
      }
      return result;
    }
    return value;
  }

  static String _safeDialogueFileName(String dialogueId) {
    final safe = dialogueId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safe.isEmpty || safe == '.' || safe == '..') {
      throw GamePackageExportException(
        code: 'invalidDialogueId',
        path: dialogueId,
        message: 'Dialogue ID cannot form a safe runtime filename.',
      );
    }
    return safe;
  }

  static String _normalizeRelative(String value) {
    final source = value.trim().replaceAll(r'\', '/');
    final normalized = p.posix.normalize(source);
    if (source.isEmpty ||
        p.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw GamePackageExportException(
        code: 'unsafeAuthoringPath',
        path: value,
        message: 'Project paths must stay relative to the author workspace.',
      );
    }
    return normalized;
  }

  static String _normalizePackagePath(String value) =>
      PackagePathPolicy.normalizeNfc(value);

  static bool _isPokeMapStoreBlob(String path) {
    final segments = path.toLowerCase().split('/');
    if (segments.length != 3 ||
        segments[0] != 'assets' ||
        segments[1] != '.pokemap-store') {
      return false;
    }
    return RegExp(r'^[0-9a-f]{64}\.blob$').hasMatch(segments[2]);
  }

  static bool _isRuntimeProjectFile(
    String path,
    String extension, {
    required bool hasCanonicalAssetCatalog,
  }) {
    if (_isPokeMapStoreBlob(path)) return !hasCanonicalAssetCatalog;
    final firstSegment = path.split('/').first;
    if (extension == '.json') {
      // `assets/` is the media tree. The runtime only ever resolves it through
      // media paths declared in project.json and the maps, so JSON found there
      // is art-pipeline metadata: atlas provenance sidecars, import manifests
      // and deferred specs. Those carry author-workspace relative paths that
      // legitimately escape the package, so shipping them made the project
      // unexportable for a reason no author could act on.
      return firstSegment != 'assets';
    }
    return (firstSegment == 'assets' || firstSegment == 'data') &&
        _projectMediaExtensions.contains(extension);
  }

  static bool _isExcludedAuthoringPath(String path) {
    if (_isPokeMapStoreBlob(path)) return false;
    final segments = path.toLowerCase().split('/');
    final basename = segments.last;
    if (segments.any((segment) => segment.startsWith('.')) ||
        _excludedSegments.any(segments.contains)) {
      return true;
    }
    if (segments.length == 1 &&
        (basename.startsWith('project.') ||
            basename == 'walkthrough.json' ||
            basename == 'runtime_host_launch_save.json')) {
      return true;
    }
    return basename.endsWith('.lock') ||
        basename.endsWith('.log') ||
        basename.endsWith('.tmp') ||
        basename.endsWith('.bak') ||
        basename.endsWith('~');
  }

  static String _normalizeKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static bool _isAuthorTimeRemoteReference(String key, String value) {
    final normalizedKey = _normalizeKey(key);
    if (!normalizedKey.contains('url') &&
        !normalizedKey.contains('uri') &&
        normalizedKey != 'source' &&
        !normalizedKey.endsWith('source')) {
      return false;
    }
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.hasScheme;
  }

  static const Set<String> _secretKeys = <String>{
    'mistralapikey',
    'apikey',
    'accesstoken',
    'clientsecret',
    'privatekey',
    'password',
  };
  static const Set<String> _excludedSegments = <String>{
    'backups',
    'build',
    'cache',
    'caches',
    'debug',
    'diagnostics',
    'fixtures',
    'logs',
    'saves',
    'seeds',
    'temp',
    'test',
    'tests',
    'tmp',
  };
  static const Set<String> _presentationExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };
  static const Set<String> _projectMediaExtensions = <String>{
    ..._presentationExtensions,
    ..._audioExtensions,
    '.ttf',
    '.otf',
    '.woff2',
  };
  static const Set<String> _audioExtensions = <String>{
    '.ogg',
    '.wav',
    '.mp3',
    '.flac',
    '.m4a',
  };
}

final class _JsonScrubResult {
  const _JsonScrubResult(this.value, this.removedSecretFields);

  final Object? value;
  final int removedSecretFields;
}

final class _AuthorProjectFileResolver {
  const _AuthorProjectFileResolver(this.root, this.catalog);

  static Future<_AuthorProjectFileResolver> load(
    Directory root,
    _ProjectionBudget budget,
  ) async {
    final catalogFile = File(
      p.joinAll(<String>[
        root.path,
        ...assetCatalogStorageKey.split('/'),
      ]),
    );
    final type = await FileSystemEntity.type(
      catalogFile.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      return _AuthorProjectFileResolver(root, AssetCatalog());
    }
    if (type != FileSystemEntityType.file) {
      throw const GamePackageExportException(
        code: 'invalidAssetCatalog',
        path: assetCatalogStorageKey,
        message: 'The canonical asset catalog is missing or unsafe.',
      );
    }
    final bytes = await budget.readFile(
      catalogFile,
      logicalPath: assetCatalogStorageKey,
      jsonLike: true,
    );
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (decoded is! Map) throw const FormatException();
      return _AuthorProjectFileResolver(
        root,
        AssetCatalog.fromJson(Map<String, dynamic>.from(decoded)),
      );
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'invalidAssetCatalog',
        path: assetCatalogStorageKey,
        message: 'The canonical asset catalog is malformed.',
        cause: error,
      );
    }
  }

  final Directory root;
  final AssetCatalog catalog;

  Future<ProjectMediaCatalog?> readProjectMediaCatalog(
    _ProjectionBudget budget,
  ) async {
    final file = _fileWithinRoot(
      projectMediaCatalogStorageKey,
      logicalPath: projectMediaCatalogStorageKey,
    );
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const GamePackageExportException(
        code: 'invalidPresentationMediaCatalog',
        path: projectMediaCatalogStorageKey,
        message: 'The Presentation media catalog is missing or unsafe.',
      );
    }
    final bytes = await budget.readFile(
      file,
      logicalPath: projectMediaCatalogStorageKey,
      jsonLike: true,
    );
    try {
      return decodeProjectMediaCatalogBytes(bytes);
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'invalidPresentationMediaCatalog',
        path: projectMediaCatalogStorageKey,
        message: 'The Presentation media catalog is malformed.',
        cause: error,
      );
    }
  }

  Future<List<int>> read(
    String relativePath,
    _ProjectionBudget budget, {
    bool jsonLike = false,
  }) async {
    final normalized = RuntimeProjectProjectionBuilder._normalizeRelative(
      relativePath,
    );
    final record = catalog.findByLogicalPath(normalized);
    final storagePath =
        record == null ? normalized : assetBlobStorageKey(record.artifact);
    final file = _fileWithinRoot(storagePath, logicalPath: relativePath);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw GamePackageExportException(
        code: 'missingProjectFile',
        path: relativePath,
        message: 'Required authoring file is missing or unsafe.',
      );
    }
    final bytes = await budget.readFile(
      file,
      logicalPath: relativePath,
      jsonLike: jsonLike,
    );
    final expected = record?.artifact;
    if (expected != null) {
      final actual = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: expected.mediaType,
      );
      if (actual.digest != expected.digest ||
          actual.byteLength != expected.byteLength) {
        throw GamePackageExportException(
          code: 'assetBlobIntegrityMismatch',
          path: relativePath,
          message: 'The canonical asset blob does not match its catalog entry.',
        );
      }
    }
    return bytes;
  }

  File _fileWithinRoot(String storagePath, {required String logicalPath}) {
    final file = File(p.joinAll(<String>[
      root.path,
      ...storagePath.split('/'),
    ]));
    final absolute = p.normalize(p.absolute(file.path));
    final absoluteRoot = p.normalize(p.absolute(root.path));
    if (absolute != absoluteRoot && !p.isWithin(absoluteRoot, absolute)) {
      throw GamePackageExportException(
        code: 'authoringPathEscapesRoot',
        path: logicalPath,
        message: 'Authoring path escapes the project root.',
      );
    }
    return file;
  }
}

final class _ProjectionBudget {
  _ProjectionBudget({
    required this.maxWorkspaceEntries,
    required this.maxPayloadEntries,
    required this.maxFileBytes,
    required this.maxJsonSourceBytes,
    required this.maxTotalPayloadBytes,
  });

  final int maxWorkspaceEntries;
  final int maxPayloadEntries;
  final int maxFileBytes;
  final int maxJsonSourceBytes;
  final int maxTotalPayloadBytes;

  var _workspaceEntries = 0;
  var _totalPayloadBytes = 0;

  void visitWorkspaceEntry() {
    _workspaceEntries++;
    if (_workspaceEntries > maxWorkspaceEntries) {
      throw const GamePackageExportException(
        code: 'workspaceEntryQuotaExceeded',
        message: 'Author workspace contains too many filesystem entries.',
      );
    }
  }

  Future<List<int>> readFile(
    File file, {
    required String logicalPath,
    bool jsonLike = false,
  }) async {
    final size = await file.length();
    final limit = jsonLike ? maxJsonSourceBytes : maxFileBytes;
    if (size > limit) {
      throw GamePackageExportException(
        code: 'authoringFileTooLarge',
        path: logicalPath,
        message: 'Authoring file exceeds the export quota.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length != size || bytes.length > limit) {
      throw GamePackageExportException(
        code: 'authoringSourceChanged',
        path: logicalPath,
        message: 'Authoring file changed while it was being exported.',
      );
    }
    return bytes;
  }

  void addPayload(
    Map<String, List<int>> payload,
    String path,
    List<int> bytes,
  ) {
    if (payload.containsKey(path)) {
      throw GamePackageExportException(
        code: 'projectionPathCollision',
        path: path,
        message: 'Two authoring files resolve to the same package path.',
      );
    }
    if (payload.length >= maxPayloadEntries || bytes.length > maxFileBytes) {
      throw GamePackageExportException(
        code: 'projectionQuotaExceeded',
        path: path,
        message: 'Runtime projection exceeds the package quota.',
      );
    }
    _totalPayloadBytes += bytes.length;
    if (_totalPayloadBytes > maxTotalPayloadBytes) {
      throw const GamePackageExportException(
        code: 'projectionQuotaExceeded',
        message: 'Runtime projection exceeds the total package quota.',
      );
    }
    payload[path] = bytes;
  }

  void replacePayload(
    Map<String, List<int>> payload,
    String path,
    List<int> bytes,
  ) {
    final previous = payload.remove(path);
    if (previous != null) _totalPayloadBytes -= previous.length;
    addPayload(payload, path, bytes);
  }
}
