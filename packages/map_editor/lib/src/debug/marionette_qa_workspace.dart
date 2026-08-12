import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class MarionetteQaWorkspace {
  const MarionetteQaWorkspace._({
    required this.sourceProjectPath,
    required this.projectRootPath,
    required this.sourceFingerprint,
    required this.copyFingerprint,
  });

  static const workspaceDirectoryName = 'PokeMapMarionetteQA';

  final String sourceProjectPath;
  final String projectRootPath;
  final String sourceFingerprint;
  final String copyFingerprint;

  static MarionetteQaWorkspace prepare({
    required String sourceProjectPath,
    required String documentsRootPath,
    required String runId,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(runId)) {
      throw ArgumentError.value(runId, 'runId', 'Unsafe QA run identifier.');
    }
    final source = _canonicalDirectory(sourceProjectPath, 'sourceProjectPath');
    _validateProjectRoot(source.path);
    final documents = _canonicalDirectory(
      documentsRootPath,
      'documentsRootPath',
    );
    final destination = Directory(
      p.join(documents.path, workspaceDirectoryName, runId),
    );
    if (destination.existsSync()) {
      throw StateError('QA workspace already exists: ${destination.path}');
    }

    final sourceFingerprint = fingerprint(source.path);
    destination.createSync(recursive: true);
    try {
      _copyDirectory(source, destination);
      _validateProjectRoot(destination.path);
      final copyFingerprint = fingerprint(destination.path);
      final sourceFingerprintAfterCopy = fingerprint(source.path);
      if (copyFingerprint != sourceFingerprint ||
          sourceFingerprintAfterCopy != sourceFingerprint) {
        throw StateError('Disposable project copy failed integrity checks.');
      }
      return MarionetteQaWorkspace._(
        sourceProjectPath: source.path,
        projectRootPath: destination.path,
        sourceFingerprint: sourceFingerprint,
        copyFingerprint: copyFingerprint,
      );
    } catch (_) {
      if (destination.existsSync()) {
        destination.deleteSync(recursive: true);
      }
      rethrow;
    }
  }

  static String fingerprint(String projectRootPath) {
    final root = _canonicalDirectory(projectRootPath, 'projectRootPath');
    final entries = root.listSync(recursive: true, followLinks: false)
      ..sort((left, right) => left.path.compareTo(right.path));
    final bytes = BytesBuilder(copy: false);
    for (final entry in entries) {
      final type = FileSystemEntity.typeSync(entry.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw StateError('QA projects cannot contain links: ${entry.path}');
      }
      if (type != FileSystemEntityType.file) {
        continue;
      }
      final relativePath = p.relative(entry.path, from: root.path);
      bytes
        ..add(utf8.encode(relativePath))
        ..addByte(0)
        ..add(File(entry.path).readAsBytesSync())
        ..addByte(0);
    }
    return sha256.convert(bytes.takeBytes()).toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'sourceProjectPath': sourceProjectPath,
    'projectRootPath': projectRootPath,
    'sourceFingerprint': sourceFingerprint,
    'copyFingerprint': copyFingerprint,
  };

  static Directory _canonicalDirectory(String path, String argumentName) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, argumentName, 'Directory is required.');
    }
    final requested = p.normalize(p.absolute(trimmed));
    if (Link(requested).existsSync()) {
      throw StateError('Directory cannot be a symbolic link: $requested');
    }
    final directory = Directory(requested);
    if (!directory.existsSync()) {
      throw StateError('Directory does not exist: $requested');
    }
    final resolved = p.normalize(directory.resolveSymbolicLinksSync());
    return Directory(resolved);
  }

  static void _copyDirectory(Directory source, Directory destination) {
    final entries = source.listSync(recursive: true, followLinks: false)
      ..sort((left, right) => left.path.compareTo(right.path));
    for (final entry in entries) {
      final relativePath = p.relative(entry.path, from: source.path);
      final destinationPath = p.join(destination.path, relativePath);
      final type = FileSystemEntity.typeSync(entry.path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.directory:
          Directory(destinationPath).createSync(recursive: true);
        case FileSystemEntityType.file:
          File(destinationPath).parent.createSync(recursive: true);
          File(entry.path).copySync(destinationPath);
        case FileSystemEntityType.link:
          throw StateError('QA projects cannot contain links: ${entry.path}');
        case FileSystemEntityType.notFound:
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
          throw StateError('Unsupported QA project entry: ${entry.path}');
      }
    }
  }

  static void _validateProjectRoot(String projectRootPath) {
    final manifestFile = File(p.join(projectRootPath, 'project.json'));
    if (!manifestFile.existsSync()) {
      throw StateError('Project manifest does not exist: ${manifestFile.path}');
    }
    final decoded = jsonDecode(manifestFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project manifest must be a JSON object.');
    }
    ProjectManifest.fromJson(decoded);
  }
}

final class MarionetteQaLaunchPlan {
  const MarionetteQaLaunchPlan({
    required this.packageRootPath,
    required this.projectRootPath,
  });

  final String packageRootPath;
  final String projectRootPath;

  static const projectPathDefine = 'MARIONETTE_PROJECT_PATH';

  String get executable => 'flutter';

  String get workingDirectory => p.normalize(p.absolute(packageRootPath));

  List<String> get arguments => <String>[
    'run',
    '-t',
    'dev/marionette_main.dart',
    '-d',
    'macos',
    '--debug',
    '--dart-define=$projectPathDefine='
        '${p.normalize(p.absolute(projectRootPath))}',
  ];
}
