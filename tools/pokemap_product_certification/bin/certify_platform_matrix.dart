import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/platform_certification_aggregate_receipt.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_platform_matrix.dart '
      '--repository-root <path> --platform-support <path> '
      '--platform-evidence <path> --plugin-lock <path> '
      '--app-pubspec <path> --output <path>',
    );
    return;
  }
  try {
    final options = _parseArguments(arguments);
    final repository = Directory(p.absolute(options['repository-root']!));
    final status = await _git(repository, const <String>[
      'status',
      '--porcelain=v1',
      '--untracked-files=all',
    ]);
    if (status.isNotEmpty) {
      throw StateError('CIN-028 certification requires a clean tree.');
    }
    final releaseCommit = await _git(repository, const <String>[
      'rev-parse',
      'HEAD',
    ]);
    final treeListing = await _git(repository, const <String>[
      'ls-tree',
      '-r',
      '--full-tree',
      'HEAD',
    ]);
    final platformSupportFile = await _repositoryInput(
      repository,
      options['platform-support']!,
    );
    final platformEvidenceFile = await _repositoryInput(
      repository,
      options['platform-evidence']!,
    );
    final pluginLockFile = await _repositoryInput(
      repository,
      options['plugin-lock']!,
    );
    final appPubspecFile = await _repositoryInput(
      repository,
      options['app-pubspec']!,
    );
    final platformSupport = _readJsonMap(platformSupportFile);
    final platformEvidence = _readJsonMap(platformEvidenceFile);
    await _validateSourceCommits(repository, platformEvidence);
    final receipt = PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: platformSupport,
      platformEvidence: platformEvidence,
      provenance: <String, Object?>{
        'releaseCommit': releaseCommit,
        'treeState': 'clean',
        'treeFingerprint': _sha256(utf8.encode(treeListing)),
        'platformSupportSha256': _sha256(
          await platformSupportFile.readAsBytes(),
        ),
        'pluginLockSha256': _sha256(await pluginLockFile.readAsBytes()),
        'bundleVersion': _bundleVersion(await appPubspecFile.readAsString()),
        'pluginVersions': _pluginVersions(await pluginLockFile.readAsString()),
      },
    );
    final output = File(p.absolute(options['output']!));
    await output.parent.create(recursive: true);
    final temporary = File('${output.path}.tmp-$pid');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(receipt.toJson())}\n',
      flush: true,
    );
    if (await output.exists()) await output.delete();
    await temporary.rename(output.path);
    stdout.writeln(jsonEncode(receipt.toJson()));
    if (!receipt.passed) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  const names = <String>{
    'repository-root',
    'platform-support',
    'platform-evidence',
    'plugin-lock',
    'app-pubspec',
    'output',
  };
  final parsed = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('CIN-028 CLI arguments are incomplete.');
    }
    final name = arguments[index].substring(2);
    if (!names.contains(name) || parsed.containsKey(name)) {
      throw FormatException('Unsupported CIN-028 option: --$name.');
    }
    parsed[name] = arguments[index + 1];
  }
  if (parsed.keys.toSet().length != names.length) {
    throw const FormatException('CIN-028 CLI requires every option.');
  }
  return parsed;
}

Map<String, Object?> _readJsonMap(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('${file.path} must contain a JSON object.');
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

Future<File> _repositoryInput(Directory repository, String path) async {
  final repositoryPath = await repository.resolveSymbolicLinks();
  final inputPath = await File(p.absolute(path)).resolveSymbolicLinks();
  if (!p.isWithin(repositoryPath, inputPath)) {
    throw StateError('CIN-028 inputs must be inside the repository.');
  }
  final relativePath = p.relative(inputPath, from: repositoryPath);
  await _git(repository, <String>[
    'ls-files',
    '--error-unmatch',
    '--',
    relativePath,
  ]);
  return File(inputPath);
}

Future<void> _validateSourceCommits(
  Directory repository,
  Map<String, Object?> platformEvidence,
) async {
  final platforms = platformEvidence['platforms'];
  if (platforms is! List<Object?>) {
    throw const FormatException(r'$.platforms must be an array.');
  }
  final commits = <String>{};
  for (final entry in platforms) {
    if (entry is! Map || entry['sourceCommit'] is! String) {
      throw const FormatException(
        r'$.platforms[].sourceCommit must be a string.',
      );
    }
    commits.add(entry['sourceCommit']! as String);
  }
  for (final commit in commits) {
    await _git(repository, <String>['cat-file', '-e', '$commit^{commit}']);
  }
}

Map<String, Object?> _pluginVersions(String lock) {
  const relevant = <String>{
    'audioplayers',
    'audioplayers_android',
    'audioplayers_darwin',
    'audioplayers_linux',
    'audioplayers_web',
    'audioplayers_windows',
    'video_player',
    'video_player_android',
    'video_player_avfoundation',
    'video_player_web',
  };
  final versions = <String, Object?>{};
  String? currentPackage;
  for (final line in const LineSplitter().convert(lock)) {
    final packageMatch = RegExp(r'^  ([a-zA-Z0-9_]+):$').firstMatch(line);
    if (packageMatch != null) {
      final name = packageMatch.group(1)!;
      currentPackage = relevant.contains(name) ? name : null;
      continue;
    }
    if (currentPackage == null) continue;
    final versionMatch = RegExp(
      r'^    version: "?([^"\s]+)"?$',
    ).firstMatch(line);
    if (versionMatch != null) {
      versions[currentPackage] = versionMatch.group(1)!;
      currentPackage = null;
    }
  }
  return <String, Object?>{
    for (final name in versions.keys.toList()..sort()) name: versions[name],
  };
}

String _bundleVersion(String pubspec) {
  for (final line in const LineSplitter().convert(pubspec)) {
    final match = RegExp(r'^version:\s*([^\s#]+)').firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  throw const FormatException('App pubspec has no top-level version.');
}

Future<String> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run('git', <String>[
    '-C',
    repository.path,
    ...arguments,
  ]);
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString().trim());
  }
  return result.stdout.toString().trim();
}

String _sha256(List<int> bytes) => sha256.convert(bytes).toString();
