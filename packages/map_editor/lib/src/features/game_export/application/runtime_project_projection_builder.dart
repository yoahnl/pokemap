import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'game_package_export_profile.dart';

final class RuntimeProjectProjection {
  RuntimeProjectProjection({
    required this.project,
    required this.presentation,
    required Map<String, List<int>> payloadFiles,
    required this.compiledDialogueCount,
    required this.scrubbedSecretFieldCount,
    this.iconPackagePath,
    this.coverPackagePath,
    this.heroPackagePath,
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
        typographyRoles = Map.unmodifiable(typographyRoles);

  final ProjectManifest project;
  final ProjectPresentationProfile presentation;
  final Map<String, List<int>> payloadFiles;
  final int compiledDialogueCount;
  final int scrubbedSecretFieldCount;
  final String? iconPackagePath;
  final String? coverPackagePath;
  final String? heroPackagePath;
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
    final dialogueSources = <String>{};
    final compiledEntries = <ProjectDialogueEntry>[];
    final compiledPaths = <String>{};
    for (final entry in authorProject.dialogues) {
      final sourcePath = _normalizeRelative(entry.relativePath);
      dialogueSources.add(sourcePath);
      final sourceFile = await _resolveAuthorFile(
        projectRoot,
        sourcePath,
      );
      final extension = p.extension(sourcePath).toLowerCase();
      final RuntimeDialogueDocument document;
      if (extension == '.yarn') {
        try {
          document = const YarnDialogueCompiler().compile(
            utf8.decode(
              await budget.readFile(
                sourceFile,
                logicalPath: sourcePath,
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
            await budget.readFile(
              sourceFile,
              logicalPath: sourcePath,
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
      if (type != FileSystemEntityType.file ||
          relative == 'project.json' ||
          dialogueSources.contains(relative) ||
          _isExcludedAuthoringPath(relative)) {
        continue;
      }
      final extension = p.extension(relative).toLowerCase();
      if (!_isRuntimeProjectFile(relative, extension)) continue;
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

    final iconPackagePath = await _addPresentationAsset(
      payload,
      projectRoot,
      presentation.branding.iconPath,
      'icon',
      budget,
    );
    final coverPackagePath = await _addPresentationAsset(
      payload,
      projectRoot,
      presentation.branding.coverPath,
      'cover',
      budget,
    );
    final heroPackagePath = await _addPresentationAsset(
      payload,
      projectRoot,
      presentation.branding.heroPath,
      'hero',
      budget,
    );
    await _addLegalFile(
      payload,
      projectRoot,
      profile.licensePath,
      'LICENSE.txt',
      budget,
    );
    await _addLegalFile(
      payload,
      projectRoot,
      profile.creditsPath,
      'CREDITS.txt',
      budget,
    );
    final titleMusicPath = presentation.branding.titleMusicPath;
    final titleMusicPackagePath = titleMusicPath == null
        ? null
        : _normalizePackagePath('project/$titleMusicPath');
    if (titleMusicPackagePath != null &&
        (!_audioExtensions.contains(
              p.extension(titleMusicPath!).toLowerCase(),
            ) ||
            !titleMusicPackagePath.startsWith('project/assets/') ||
            !payload.containsKey(titleMusicPackagePath))) {
      throw GamePackageExportException(
        code: 'invalidTitleMusic',
        path: titleMusicPath,
        message: 'Title music must reference an exported audio asset.',
      );
    }
    final intro = presentation.intro;
    final introMedia = intro == null
        ? null
        : await _addResponsiveVideo(
            payload,
            projectRoot,
            intro.media,
            packageRoot: 'presentation/intro',
            budget: budget,
          );
    final titlePromptMedia = presentation.titleMotion?.promptLoop == null
        ? null
        : await _addResponsiveVideo(
            payload,
            projectRoot,
            presentation.titleMotion!.promptLoop!,
            packageRoot: 'presentation/title/prompt',
            budget: budget,
          );
    final titleMenuMedia = presentation.titleMotion?.menuLoop == null
        ? null
        : await _addResponsiveVideo(
            payload,
            projectRoot,
            presentation.titleMotion!.menuLoop!,
            packageRoot: 'presentation/title/menu',
            budget: budget,
          );
    final typographyRoles = <ProjectTypographyRole, RuntimeProjectedFontRole>{};
    final typography = presentation.typography;
    if (typography != null) {
      for (final role in ProjectTypographyRole.values) {
        final roleProfile = switch (role) {
          ProjectTypographyRole.display => typography.display,
          ProjectTypographyRole.body => typography.body,
          ProjectTypographyRole.dialogue => typography.dialogue,
          ProjectTypographyRole.numbers => typography.numbers,
        };
        typographyRoles[role] = await _addTypographyRole(
          payload,
          projectRoot,
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
      compiledDialogueCount: compiledEntries.length,
      scrubbedSecretFieldCount: scrubbedSecretFieldCount,
      iconPackagePath: iconPackagePath,
      coverPackagePath: coverPackagePath,
      heroPackagePath: heroPackagePath,
      titleMusicPackagePath: titleMusicPackagePath,
      introMedia: introMedia,
      titlePromptMedia: titlePromptMedia,
      titleMenuMedia: titleMenuMedia,
      typographyRoles: typographyRoles,
    );
  }

  Future<RuntimeProjectedResponsiveVideo> _addResponsiveVideo(
    Map<String, List<int>> payload,
    Directory root,
    ProjectResponsiveVideoProfile media, {
    required String packageRoot,
    required _ProjectionBudget budget,
  }) async =>
      RuntimeProjectedResponsiveVideo(
        landscape: await _addVideoVariant(
          payload,
          root,
          media.landscape,
          packageRoot: '$packageRoot/landscape',
          budget: budget,
        ),
        portrait: media.portrait == null
            ? null
            : await _addVideoVariant(
                payload,
                root,
                media.portrait!,
                packageRoot: '$packageRoot/portrait',
                budget: budget,
              ),
      );

  Future<RuntimeProjectedVideoVariant> _addVideoVariant(
    Map<String, List<int>> payload,
    Directory root,
    ProjectVideoVariantProfile variant, {
    required String packageRoot,
    required _ProjectionBudget budget,
  }) async {
    final file = await _resolveAuthorFile(root, variant.videoPath);
    final bytes = await budget.readFile(
      file,
      logicalPath: variant.videoPath,
    );
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
      root,
      variant.posterPath,
      posterRole,
      budget,
    );
    final captionsPackagePath = variant.captionsPath == null
        ? null
        : await _addIntroCaptions(
            payload,
            root,
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
    Directory root,
    String relativePath, {
    required String packagePath,
    required _ProjectionBudget budget,
  }) async {
    final file = await _resolveAuthorFile(root, relativePath);
    final bytes = await budget.readFile(
      file,
      logicalPath: relativePath,
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
    Directory root,
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
    final fontFile = await _resolveAuthorFile(root, fontPath);
    final fontBytes = await budget.readFile(fontFile, logicalPath: fontPath);
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
    final licenseFile = await _resolveAuthorFile(root, licensePath);
    final licenseBytes = await budget.readFile(
      licenseFile,
      logicalPath: licensePath,
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

  Future<File> _resolveAuthorFile(
    Directory root,
    String relativePath,
  ) async {
    final normalized = _normalizeRelative(relativePath);
    final file = File(p.joinAll(<String>[
      root.path,
      ...normalized.split('/'),
    ]));
    final absolute = p.normalize(p.absolute(file.path));
    final absoluteRoot = p.normalize(p.absolute(root.path));
    if (absolute != absoluteRoot && !p.isWithin(absoluteRoot, absolute)) {
      throw GamePackageExportException(
        code: 'authoringPathEscapesRoot',
        path: relativePath,
        message: 'Authoring path escapes the project root.',
      );
    }
    await _requireRegularFile(file, logicalPath: relativePath);
    return file;
  }

  Future<String?> _addPresentationAsset(
    Map<String, List<int>> payload,
    Directory root,
    String? relativePath,
    String role,
    _ProjectionBudget budget,
  ) async {
    if (relativePath == null) return null;
    final file = await _resolveAuthorFile(root, relativePath);
    final extension = p.extension(relativePath).toLowerCase();
    if (!_presentationExtensions.contains(extension)) {
      throw GamePackageExportException(
        code: 'invalidBrandingAsset',
        path: relativePath,
        message: '$role must use an allowlisted image or audio format.',
      );
    }
    final packagePath = 'presentation/$role$extension';
    budget.addPayload(
      payload,
      packagePath,
      await budget.readFile(file, logicalPath: relativePath),
    );
    return packagePath;
  }

  Future<void> _addLegalFile(
    Map<String, List<int>> payload,
    Directory root,
    String? relativePath,
    String targetName,
    _ProjectionBudget budget,
  ) async {
    if (relativePath == null) return;
    final file = await _resolveAuthorFile(root, relativePath);
    final bytes = await budget.readFile(
      file,
      logicalPath: relativePath,
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

  static bool _isRuntimeProjectFile(String path, String extension) {
    if (_isPokeMapStoreBlob(path)) return true;
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
}
