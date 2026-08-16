import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/src/cinematic_v2_final_certification_receipt.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_cinematic_v2.dart '
      '--repository-root <path> --evidence <path> --output <path>',
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
      throw StateError('CIN-008 certification requires a clean tree.');
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
    final evidenceFile = await _repositoryInput(
      repository,
      options['evidence']!,
    );
    final input = _readJsonMap(evidenceFile);
    _expectKeys(input, const <String>{
      'schemaVersion',
      'dependencies',
      'evidence',
    });
    if (input['schemaVersion'] != 1) {
      throw const FormatException(r'$.schemaVersion must be 1.');
    }
    final dependencies = _maps(
      input['dependencies'],
      r'$.dependencies',
    ).map(CinematicV2FinalDependency.fromJson).toList(growable: false);
    final evidence = _maps(
      input['evidence'],
      r'$.evidence',
    ).map(CinematicV2FinalEvidence.fromJson).toList(growable: false);
    await _validateSourceCommits(repository, releaseCommit, <String>{
      ...dependencies.map((entry) => entry.sourceCommit),
      ...evidence.map((entry) => entry.sourceCommit),
    });
    await _validateResultDigests(repository, evidence);
    final receipt = CinematicV2FinalCertificationReceipt(
      releaseCommit: releaseCommit,
      treeFingerprint: sha256.convert(utf8.encode(treeListing)).toString(),
      evidenceSha256: sha256
          .convert(await evidenceFile.readAsBytes())
          .toString(),
      dependencies: dependencies,
      evidence: evidence,
    );
    final output = File(p.absolute(options['output']!));
    if (p.equals(output.path, evidenceFile.path)) {
      throw StateError('CIN-008 output must not overwrite its evidence input.');
    }
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
  const names = <String>{'repository-root', 'evidence', 'output'};
  final parsed = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
      throw const FormatException('CIN-008 CLI arguments are incomplete.');
    }
    final name = arguments[index].substring(2);
    if (!names.contains(name) || parsed.containsKey(name)) {
      throw FormatException('Unsupported CIN-008 option: --$name.');
    }
    parsed[name] = arguments[index + 1];
  }
  if (parsed.keys.toSet().length != names.length) {
    throw const FormatException('CIN-008 CLI requires every option.');
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
    throw StateError('CIN-008 evidence must be inside the repository.');
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
  String releaseCommit,
  Set<String> sourceCommits,
) async {
  for (final commit in sourceCommits) {
    await _git(repository, <String>['cat-file', '-e', '$commit^{commit}']);
    final ancestor = await Process.run('git', <String>[
      '-C',
      repository.path,
      'merge-base',
      '--is-ancestor',
      commit,
      releaseCommit,
    ]);
    if (ancestor.exitCode != 0) {
      throw StateError(
        'CIN-008 source commit $commit is outside the certified history.',
      );
    }
  }
}

Future<void> _validateResultDigests(
  Directory repository,
  List<CinematicV2FinalEvidence> evidence,
) async {
  for (final entry in evidence) {
    if (entry.status == CinematicV2FinalEvidenceStatus.blocked) continue;
    final result = await Process.run('git', <String>[
      '-C',
      repository.path,
      'cat-file',
      'commit',
      entry.sourceCommit,
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError(
        'CIN-008 cannot read evidence commit ${entry.sourceCommit}.',
      );
    }
    final digest = sha256.convert(result.stdout! as List<int>).toString();
    if (entry.resultSha256 != digest) {
      throw FormatException(
        'CIN-008 result digest is inconsistent for ${entry.id.name}.',
      );
    }
  }
}

List<Map<String, Object?>> _maps(Object? value, String path) {
  if (value is! List<Object?>) {
    throw FormatException('$path must be an array.');
  }
  return value.indexed
      .map((entry) {
        final item = entry.$2;
        if (item is! Map) {
          throw FormatException('$path[${entry.$1}] must be an object.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

void _expectKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.keys.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw const FormatException(
      r'$ has unexpected or missing evidence input keys.',
    );
  }
}

Future<String> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run('git', <String>[
    '-C',
    repository.path,
    ...arguments,
  ]);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed: '
      '${result.stderr.toString().trim()}',
    );
  }
  return result.stdout.toString().trim();
}
