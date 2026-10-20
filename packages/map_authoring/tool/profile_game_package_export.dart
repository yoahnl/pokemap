import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/distribution/game_package_export_profile.dart';
import 'package:map_authoring/src/domains/distribution/game_package_export_service.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

const _maximumSourceBytes = 600 * 1024 * 1024;
const _maximumSourceFiles = 10000;
const _maximumWorkspaceEntries = 100000;

const _usage = 'dart run tool/profile_game_package_export.dart '
    '--project-root <immutable-snapshot> --profile <profile.json> '
    '--output <new.avelunegame> --receipt <new.json> '
    '[--mode publication|localTest] [--max-source-bytes <bytes>] '
    '[--audit-source-root <read-only-original>]';

Future<void> main(List<String> arguments) async {
  exitCode = await runProfileGamePackageExport(arguments);
}

Future<int> runProfileGamePackageExport(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--help') {
    stdout.writeln(_usage);
    return 0;
  }
  final Map<String, String> options;
  try {
    options = _readOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n$_usage');
    return 64;
  }

  final elapsed = Stopwatch()..start();
  final stages = <String, int>{};
  final report = <String, dynamic>{
    'receiptVersion': 1,
    'status': 'failed',
    'stage': 'preflight',
    'mode': options['mode'] ?? 'publication',
    'pid': pid,
    'dartVersion': Platform.version.split('\n').first,
    'limits': {
      'maximumSourceBytes': int.parse(
          options['max-source-bytes'] ?? _maximumSourceBytes.toString()),
      'maximumSourceFiles': _maximumSourceFiles,
      'maximumWorkspaceEntries': _maximumWorkspaceEntries,
      'packagePolicy': 'unchangedProductionDefaults',
    },
  };
  File? receipt;
  Directory? sourceRoot;
  var result = 1;

  Future<T> stage<T>(String name, Future<T> Function() action) async {
    report['stage'] = name;
    final timer = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stages[name] = timer.elapsedMicroseconds;
    }
  }

  try {
    final source = await _regularDirectory(options['project-root']!);
    sourceRoot = source;
    final audit = options['audit-source-root'] == null
        ? null
        : await _regularDirectory(options['audit-source-root']!);
    final proposedReceipt = await _destination(options['receipt']!);
    _outsideSources(proposedReceipt, source, audit);
    if (await FileSystemEntity.type(proposedReceipt.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw _ProbeFailure('receiptExists', proposedReceipt.path);
    }
    receipt = proposedReceipt;
    final output = await _destination(options['output']!);
    _outsideSources(output, source, audit);
    if (output.path == receipt.path) {
      throw _ProbeFailure('destinationCollision', output.path);
    }
    if (await FileSystemEntity.type(output.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw _ProbeFailure('destinationExists', output.path);
    }
    if (!output.path.toLowerCase().endsWith('.avelunegame')) {
      throw _ProbeFailure('invalidExportDestination', output.path);
    }
    report['projectRoot'] = source.path;
    report['output'] = output.path;
    final mode = GamePackageExportMode.fromJson(report['mode']);
    final profile = await stage('profile', () async {
      final file = File(options['profile']!);
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          await file.length() > 1024 * 1024) {
        throw _ProbeFailure('invalidProfileFile', file.path);
      }
      final bytes = await file.readAsBytes();
      report['profileSha256'] = sha256.convert(bytes).toString();
      return GamePackageExportProfile.decodeUtf8(bytes);
    });
    if (audit != null) {
      report['collectorAudit'] =
          await stage('collectorAudit', () => _collectorAudit(audit));
    }
    final before = await stage(
        'sourceInventory',
        () => _inventory(source,
            maximumBytes: report['limits']['maximumSourceBytes'] as int));
    report['source'] = before;
    const service = CanonicalGamePackageExportService();
    final artifact = await stage('build',
        () => service.build(projectRoot: source, profile: profile, mode: mode));
    report['exportInspection'] = artifact.inspection.receipt.toJson();
    report['certification'] = {
      'isExportable': artifact.certification.isExportable,
      'isCertified': artifact.certification.isCertified,
      'compiledDialogueCount': artifact.compiledDialogueCount,
      'scrubbedSecretFieldCount': artifact.scrubbedSecretFieldCount,
    };
    await stage(
        'write',
        () => service.writeArtifactToFile(
            artifact: artifact, outputFile: output));
    report['inspection'] = await stage('fileInspection', () async {
      final file = await _FileSource.open(output);
      try {
        final inspection = const GamePackageInspector().inspectSourceSync(file);
        if (inspection.receipt.packageSha256 !=
                artifact.inspection.receipt.packageSha256 ||
            inspection.receipt.treeSha256 !=
                artifact.inspection.receipt.treeSha256) {
          throw _ProbeFailure('writtenPackageMismatch', output.path);
        }
        return inspection.receipt.toJson();
      } finally {
        await file.close();
      }
    });
    report['stage'] = 'complete';
    report['status'] = 'succeeded';
    result = 0;
  } on Object catch (error) {
    report['error'] = switch (error) {
      GamePackageExportException() => {
          'code': error.code,
          'path': error.path,
          'message': error.message,
          if (error.gameplayReadinessReport != null)
            'diagnosticCodes': error.gameplayReadinessReport!.diagnostics
                .map((diagnostic) => diagnostic.code)
                .toSet()
                .toList()
              ..sort(),
        },
      GamePackageFormatException() => {
          'code': error.code,
          'path': error.path,
          'message': error.message,
        },
      _ProbeFailure() => {'code': error.code, 'path': error.path},
      _ => {'code': error.runtimeType.toString(), 'message': '$error'},
    };
  } finally {
    final source = sourceRoot;
    if (source != null && report['source'] != null) {
      final originalStage = report['stage'];
      Map<String, Object?>? verificationError;
      try {
        final after = await stage(
            'verifySource',
            () => _inventory(source,
                maximumBytes: report['limits']['maximumSourceBytes'] as int));
        final unchanged =
            report['source']['inventorySha256'] == after['inventorySha256'];
        report['source']['unchangedAfterExport'] = unchanged;
        if (!unchanged) {
          verificationError = {'code': 'sourceChanged', 'path': source.path};
        }
      } on Object catch (error) {
        report['source']['unchangedAfterExport'] = null;
        verificationError = {
          'code': error is _ProbeFailure
              ? error.code
              : error.runtimeType.toString(),
          'path': source.path,
        };
      }
      report['stage'] = originalStage;
      if (verificationError != null) {
        report['sourceVerificationError'] = verificationError;
        if (result == 0) {
          report['stage'] = 'verifySource';
          report['status'] = 'failed';
          report['error'] = verificationError;
          result = 1;
        }
      }
    }
    elapsed.stop();
    report['measurement'] = {
      'elapsedMicroseconds': elapsed.elapsedMicroseconds,
      'exportMicroseconds': (stages['build'] ?? 0) + (stages['write'] ?? 0),
      'stageMicroseconds': stages,
      'currentRssBytes': ProcessInfo.currentRss,
      'maxRssBytes': ProcessInfo.maxRss,
      'rssScope': 'currentProcessLifetime',
    };
    if (receipt != null) {
      await receipt.parent.create(recursive: true);
      await receipt.writeAsString('${jsonEncode(report)}\n', flush: true);
    }
    stdout.writeln(jsonEncode({
      'status': report['status'],
      'stage': report['stage'],
      'receipt': receipt?.path,
      'errorCode': report['error']?['code'],
      'elapsedMicroseconds': elapsed.elapsedMicroseconds,
      'maxRssBytes': ProcessInfo.maxRss,
    }));
  }
  return result;
}

Map<String, String> _readOptions(List<String> arguments) {
  const names = {
    'project-root',
    'profile',
    'output',
    'receipt',
    'mode',
    'max-source-bytes',
    'audit-source-root',
  };
  final options = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final argument = arguments[index];
    if (!argument.startsWith('--') || index + 1 >= arguments.length) {
      throw const FormatException('Expected named options and values.');
    }
    final name = argument.substring(2);
    if (!names.contains(name) || options.containsKey(name)) {
      throw FormatException('Unknown or repeated option: $argument');
    }
    options[name] = arguments[index + 1];
  }
  for (final required in ['project-root', 'profile', 'output', 'receipt']) {
    if (options[required]?.isNotEmpty != true) {
      throw FormatException('Missing --$required.');
    }
  }
  final budget = int.tryParse(
      options['max-source-bytes'] ?? _maximumSourceBytes.toString());
  if (budget == null || budget < 1 || budget > _maximumSourceBytes) {
    throw const FormatException('Source budget must be within 1..629145600.');
  }
  return options;
}

Future<Directory> _regularDirectory(String path) async {
  if (await FileSystemEntity.type(path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw _ProbeFailure('invalidSourceDirectory', path);
  }
  return Directory(await Directory(path).resolveSymbolicLinks());
}

Future<File> _destination(String path) async {
  var parent = p.dirname(p.normalize(p.absolute(path)));
  final remaining = <String>[p.basename(path)];
  while (await FileSystemEntity.type(parent) == FileSystemEntityType.notFound) {
    remaining.insert(0, p.basename(parent));
    parent = p.dirname(parent);
  }
  final canonical = await Directory(parent).resolveSymbolicLinks();
  return File(p.joinAll([canonical, ...remaining]));
}

void _outsideSources(File file, Directory source, Directory? audit) {
  for (final root in [source, if (audit != null) audit]) {
    if (p.equals(file.path, root.path) || p.isWithin(root.path, file.path)) {
      throw _ProbeFailure('destinationInsideSource', file.path);
    }
  }
}

Future<Map<String, dynamic>> _inventory(Directory root,
    {required int maximumBytes}) async {
  final files = <(String, int, String)>[];
  var totalBytes = 0;
  var visited = 0;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (++visited > _maximumWorkspaceEntries) {
      throw _ProbeFailure('sourceEntryBudgetExceeded', root.path);
    }
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw _ProbeFailure('symlinkRejected', entity.path);
    }
    if (type != FileSystemEntityType.file) continue;
    final file = File(entity.path);
    final size = await file.length();
    totalBytes += size;
    if (totalBytes > maximumBytes || files.length >= _maximumSourceFiles) {
      throw _ProbeFailure('sourceBudgetExceeded', entity.path);
    }
    final digest = (await sha256.bind(file.openRead(0, size)).first).toString();
    if (await file.length() != size) {
      throw _ProbeFailure('sourceChanged', file.path);
    }
    files.add((
      p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
      size,
      digest
    ));
  }
  files.sort((left, right) => left.$1.compareTo(right.$1));
  return {
    'fileCount': files.length,
    'totalBytes': totalBytes,
    'inventoryAlgorithm': 'sha256-json-sorted-path-size-sha256-tuples',
    'inventorySha256': sha256
        .convert(utf8.encode(jsonEncode([
          for (final file in files) [file.$1, file.$2, file.$3]
        ])))
        .toString(),
    'projectSha256':
        files.where((file) => file.$1 == 'project.json').firstOrNull?.$3,
    'unchangedAfterExport': null,
  };
}

Future<Map<String, Object?>> _collectorAudit(Directory root) async {
  var visited = 0;
  var count = 0;
  var bytes = 0;
  var symlinks = 0;
  final byRoot = <String, Map<String, int>>{};
  final hasCatalog =
      await File(p.join(root.path, 'assets', '.pokemap-assets.json')).exists();
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (++visited > _maximumWorkspaceEntries) {
      throw _ProbeFailure('auditEntryBudgetExceeded', root.path);
    }
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.link) symlinks++;
    if (type != FileSystemEntityType.file) continue;
    final relative =
        p.relative(entity.path, from: root.path).replaceAll(r'\', '/');
    if (!_collectorCandidate(relative, hasCatalog: hasCatalog)) continue;
    final size = await File(entity.path).length();
    count++;
    bytes += size;
    final bucket = byRoot.putIfAbsent(
        relative.split('/').first, () => {'fileCount': 0, 'bytes': 0});
    bucket['fileCount'] = bucket['fileCount']! + 1;
    bucket['bytes'] = bucket['bytes']! + size;
  }
  return {
    'sourceRoot': root.path,
    'measurement': 'physicalCandidateMetadataNotProjectedPayload',
    'policySource': 'RuntimeProjectProjectionBuilder recursive file selection',
    'projectionAdjustmentsNotApplied': [
      'compiledDialogueReplacement',
      'presentationSourceExclusions',
      'portableAssetClosure',
      'generatedRuntimeResources',
    ],
    'canonicalAssetCatalogFilePresent': hasCatalog,
    'rawBlobSelectionAssumption': 'presentCatalogHasCanonicalRecords',
    'contentRead': false,
    'visitedEntries': visited,
    'candidateFileCount': count,
    'candidatePhysicalBytes': bytes,
    'symlinkCount': symlinks,
    'byRoot': Map.fromEntries(byRoot.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))),
  };
}

bool _collectorCandidate(String path, {required bool hasCatalog}) {
  final segments = path.toLowerCase().split('/');
  final basename = segments.last;
  final blob = segments.length == 3 &&
      segments[0] == 'assets' &&
      segments[1] == '.pokemap-store' &&
      RegExp(r'^[0-9a-f]{64}\.blob$').hasMatch(basename);
  if (blob) return !hasCatalog;
  if (path == 'project.json' ||
      segments.first == 'catalog' ||
      segments.first == 'exports' ||
      segments.any((segment) => segment.startsWith('.')) ||
      segments.any(const {
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
      }.contains) ||
      (segments.length == 1 &&
          (basename.startsWith('project.') ||
              basename == 'walkthrough.json' ||
              basename == 'runtime_host_launch_save.json')) ||
      ['.lock', '.log', '.tmp', '.bak', '~'].any(basename.endsWith)) {
    return false;
  }
  final extension = p.extension(path).toLowerCase();
  if (extension == '.json') return path.split('/').first != 'assets';
  return const {'assets', 'data'}.contains(path.split('/').first) &&
      const {
        '.png',
        '.jpg',
        '.jpeg',
        '.webp',
        '.ogg',
        '.wav',
        '.mp3',
        '.flac',
        '.m4a',
        '.ttf',
        '.otf',
        '.woff2',
        '.glb',
      }.contains(extension);
}

final class _ProbeFailure implements Exception {
  const _ProbeFailure(this.code, this.path);
  final String code;
  final String path;
}

final class _FileSource implements RandomAccessPackageSource {
  _FileSource(this._handle, this.length);
  final RandomAccessFile _handle;
  @override
  final int length;

  static Future<_FileSource> open(File file) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw _ProbeFailure('invalidPackageFile', file.path);
    }
    final handle = await file.open();
    return _FileSource(handle, await handle.length());
  }

  @override
  Uint8List readAtSync(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > this.length) {
      throw RangeError('Package read exceeds file.');
    }
    _handle.setPositionSync(offset);
    final bytes = _handle.readSync(length);
    if (bytes.length != length) {
      throw const FileSystemException('Package changed during inspection.');
    }
    return bytes;
  }

  Future<void> close() => _handle.close();
}
