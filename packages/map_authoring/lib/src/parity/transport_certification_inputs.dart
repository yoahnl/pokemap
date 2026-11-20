import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../contracts/artifact_ref.dart';
import '../ports/artifact_store.dart' show maximumAuthoringArtifactBytesV1;
import 'full_authoring_parity.dart';
import 'transport_certification_scenario.dart';

final class AuthoringTransportEvidenceInputs {
  AuthoringTransportEvidenceInputs._({
    required this.sourceRevision,
    required this.sourceDigest,
    required Map<String, String> fixtureDigests,
    required Map<String, List<ContentArtifactRef>> fixtureArtifacts,
    required Map<AuthoringTransport, String> executorDigests,
  })  : fixtureDigests = Map.unmodifiable(fixtureDigests),
        fixtureArtifacts = Map.unmodifiable(fixtureArtifacts),
        executorDigests = Map.unmodifiable(executorDigests);

  final String sourceRevision;
  final String sourceDigest;
  final Map<String, String> fixtureDigests;
  final Map<String, List<ContentArtifactRef>> fixtureArtifacts;
  final Map<AuthoringTransport, String> executorDigests;

  static Future<AuthoringTransportEvidenceInputs> capture({
    required Directory repository,
    required Directory fixtures,
    required String sourceRevision,
    required List<AuthoringTransportScenario> scenarios,
    required String dart,
  }) async {
    if (!RegExp(r'^([0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(sourceRevision)) {
      throw const FormatException('The evidence requires a full Git revision.');
    }
    final gitMetadata =
        await FileSystemEntity.type(p.join(repository.path, '.git'));
    if (gitMetadata != FileSystemEntityType.notFound) {
      final git = await Process.run('git', ['rev-parse', 'HEAD'],
          workingDirectory: repository.path);
      if (git.exitCode != 0 || git.stdout.toString().trim() != sourceRevision) {
        throw const FormatException(
            'The source revision differs from the checkout.');
      }
    }

    final source = <String, Object?>{};
    for (final name in _sourceTrees) {
      source[name] = await _treeDigest(
        Directory(p.join(repository.path, name)),
      );
    }
    for (final name in _sourceFiles) {
      final file = File(p.join(repository.path, name));
      if (await file.exists()) source[name] = await _fileDigest(file);
    }
    final sourceDigest = transportEvidenceDigest(source);
    final mcpBuild =
        Directory(p.join(repository.path, 'tools/pokemap_mcp/dist/src'));
    final bridge =
        File(p.join(mcpBuild.path, 'transport_certification_bridge.js'));
    final server = File(p.join(mcpBuild.path, 'index.js'));
    if (!await bridge.exists() || !await server.exists()) {
      throw StateError(
          'Build the MCP tools in the selected source copy first.');
    }
    final buildDigest = await _treeDigest(mcpBuild);
    final dartExecutor = await _executor(dart);
    final nodeExecutor = await _executor('node');
    final fixtureDigests = <String, String>{};
    final fixtureArtifacts = <String, List<ContentArtifactRef>>{};
    for (final scenario in scenarios) {
      final project = await resolveAuthoringFixture(fixtures, scenario);
      fixtureDigests[scenario.id] = await authoringFixtureDigest(project);
      for (final (index, step) in scenario.steps.indexed) {
        if (step.artifacts.isNotEmpty) {
          fixtureArtifacts['${scenario.id}/$index'] = List.unmodifiable([
            for (final artifact in step.artifacts)
              (await resolveAuthoringArtifact(project, artifact)).reference,
          ]);
        }
      }
    }
    return AuthoringTransportEvidenceInputs._(
      sourceRevision: sourceRevision,
      sourceDigest: sourceDigest,
      fixtureDigests: fixtureDigests,
      fixtureArtifacts: fixtureArtifacts,
      executorDigests: {
        for (final transport in AuthoringTransport.values)
          transport: transportEvidenceDigest({
            'transport': transport.name,
            'source': sourceDigest,
            'dart': dartExecutor,
            if (transport == AuthoringTransport.mcp) ...{
              'node': nodeExecutor,
              'build': buildDigest,
            },
          }),
      },
    );
  }

  Map<String, Object?> toJson() => {
        'sourceRevision': sourceRevision,
        'sourceDigest': sourceDigest,
        'fixtureDigests': fixtureDigests,
        'fixtureArtifacts': {
          for (final entry in fixtureArtifacts.entries)
            entry.key: [for (final artifact in entry.value) artifact.toJson()],
        },
        'executorDigests': {
          for (final entry in executorDigests.entries)
            entry.key.name: entry.value,
        },
      };
}

Future<Directory> resolveAuthoringFixture(
  Directory fixtures,
  AuthoringTransportScenario scenario,
) async {
  final parent = await fixtures.resolveSymbolicLinks();
  final project = Directory(p.join(parent, scenario.projectRoot));
  final resolved = await project.resolveSymbolicLinks();
  if (!p.isWithin(parent, resolved) ||
      resolved != project.path ||
      !await File(p.join(resolved, 'project.json')).exists()) {
    throw FormatException('Unsafe authoring fixture location: ${scenario.id}.');
  }
  return Directory(resolved);
}

Future<String> authoringFixtureDigest(Directory directory) =>
    _treeDigest(directory);

Future<({File file, ContentArtifactRef reference})> resolveAuthoringArtifact(
  Directory project,
  AuthoringTransportArtifact artifact,
) async {
  final file = File(p.join(project.path, artifact.path));
  if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file ||
      await file.resolveSymbolicLinks() != file.path ||
      await file.length() > maximumAuthoringArtifactBytesV1) {
    throw FormatException(
        'Expected a bounded regular artifact: ${artifact.path}.');
  }
  return (
    file: file,
    reference: ContentArtifactRef.fromBytes(
      await file.readAsBytes(),
      mediaType: artifact.mediaType,
    ),
  );
}

Future<void> copyAuthoringFixture(Directory source, Directory target) async {
  await target.create();
  await for (final entity in source.list(followLinks: false)) {
    final path = p.join(target.path, p.basename(entity.path));
    if (entity is Directory) {
      await copyAuthoringFixture(entity, Directory(path));
    } else if (entity is File) {
      await entity.copy(path);
    } else {
      throw FormatException(
          'Unsupported authoring fixture entry: ${entity.path}.');
    }
  }
}

Future<String> _treeDigest(Directory root) async {
  if (await FileSystemEntity.type(root.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw FormatException(
        'Evidence root must be a physical directory: ${root.path}.');
  }
  final entries = <String, String>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final path = p.relative(entity.path, from: root.path);
    if (entity is File) {
      entries[path] = await _fileDigest(entity);
    } else if (entity is Directory) {
      entries['$path/'] = 'directory';
    } else {
      throw FormatException(
          'Evidence tree contains a symbolic link: ${entity.path}.');
    }
  }
  return transportEvidenceDigest(entries);
}

Future<String> _fileDigest(File file) async =>
    'sha256:${await sha256.bind(file.openRead()).first}';

Future<Map<String, String>> _executor(String executable) async {
  final searchPath = Platform.environment['PATH'] ?? '';
  final candidates = p.basename(executable) != executable
      ? [executable]
      : [
          for (final root in searchPath.split(Platform.isWindows ? ';' : ':'))
            if (root.isNotEmpty) p.join(root, executable),
        ];
  for (final path in candidates) {
    final file = File(path);
    if (!await file.exists()) continue;
    final result = await Process.run(path, const ['--version']);
    if (result.exitCode != 0) continue;
    final versions = '${result.stdout}\n${result.stderr}'
        .split('\n')
        .map((line) => line.trim())
        .where((line) =>
            line.startsWith('Dart SDK version: ') ||
            RegExp(r'^v[0-9]+\.[0-9]+\.[0-9]+(?:[+.-][0-9A-Za-z.-]+)?$')
                .hasMatch(line))
        .toSet();
    if (versions.length != 1) continue;
    return {
      'version': versions.single,
      'digest': await _fileDigest(file),
    };
  }
  throw StateError('Could not identify executor $executable.');
}

const _sourceTrees = [
  'packages/map_authoring/bin',
  'packages/map_authoring/lib',
  'packages/map_authoring/assets',
  'packages/map_core/lib',
  'packages/map_story/lib',
  'packages/map_gameplay/lib',
  'packages/map_distribution/lib',
  'packages/map_editor/lib',
  'tools/pokemap_product_certification/bin',
  'tools/pokemap_product_certification/lib',
  'tools/pokemap_mcp/src',
];

const _sourceFiles = [
  'packages/map_authoring/pubspec.yaml',
  'packages/map_authoring/pubspec.lock',
  'packages/map_editor/pubspec.yaml',
  'tools/pokemap_product_certification/pubspec.yaml',
  'tools/pokemap_product_certification/pubspec.lock',
  'tools/pokemap_mcp/package.json',
  'tools/pokemap_mcp/package-lock.json',
  'tools/pokemap_mcp/tsconfig.json',
];
