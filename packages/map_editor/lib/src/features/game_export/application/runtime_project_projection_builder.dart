import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'game_package_export_profile.dart';

final class RuntimeProjectProjection {
  RuntimeProjectProjection({
    required this.project,
    required Map<String, List<int>> payloadFiles,
    required this.compiledDialogueCount,
    required this.scrubbedSecretFieldCount,
    this.iconPackagePath,
    this.coverPackagePath,
    this.heroPackagePath,
    this.titleMusicPackagePath,
  }) : payloadFiles = Map.unmodifiable(
          payloadFiles.map(
            (path, bytes) => MapEntry(path, List<int>.unmodifiable(bytes)),
          ),
        );

  final ProjectManifest project;
  final Map<String, List<int>> payloadFiles;
  final int compiledDialogueCount;
  final int scrubbedSecretFieldCount;
  final String? iconPackagePath;
  final String? coverPackagePath;
  final String? heroPackagePath;
  final String? titleMusicPackagePath;
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
      final packagePath = 'project/$relative';
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
      profile.iconPath,
      'icon',
      budget,
    );
    final coverPackagePath = await _addPresentationAsset(
      payload,
      projectRoot,
      profile.coverPath,
      'cover',
      budget,
    );
    final heroPackagePath = await _addPresentationAsset(
      payload,
      projectRoot,
      profile.heroPath,
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
    final titleMusicPackagePath = profile.titleMusicPath == null
        ? null
        : 'project/${profile.titleMusicPath}';
    if (titleMusicPackagePath != null &&
        (!titleMusicPackagePath.startsWith('project/assets/') ||
            !payload.containsKey(titleMusicPackagePath))) {
      throw GamePackageExportException(
        code: 'invalidTitleMusic',
        path: profile.titleMusicPath,
        message: 'Title music must reference an exported project asset.',
      );
    }

    return RuntimeProjectProjection(
      project: projectedProject,
      payloadFiles: payload,
      compiledDialogueCount: compiledEntries.length,
      scrubbedSecretFieldCount: scrubbedSecretFieldCount,
      iconPackagePath: iconPackagePath,
      coverPackagePath: coverPackagePath,
      heroPackagePath: heroPackagePath,
      titleMusicPackagePath: titleMusicPackagePath,
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

  List<int> _encodeRuntimeJson(Object? value) => utf8.encode(jsonEncode(value));

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

  static bool _isRuntimeProjectFile(String path, String extension) {
    if (extension == '.json') return true;
    final firstSegment = path.split('/').first;
    return (firstSegment == 'assets' || firstSegment == 'data') &&
        _projectMediaExtensions.contains(extension);
  }

  static bool _isExcludedAuthoringPath(String path) {
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
    '.ogg',
    '.wav',
    '.mp3',
    '.flac',
    '.m4a',
    '.ttf',
    '.otf',
    '.woff2',
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
