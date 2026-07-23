import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/bundled_runtime_project.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    if (!Platform.isMacOS) {
      throw UnsupportedError('The Selbrume package is macOS-only.');
    }
    final hostRoot = Directory.current.absolute;
    final projectRoot = Directory(options.projectRoot);
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    if (!await projectFile.exists()) {
      throw ArgumentError.value(
        projectRoot.path,
        '--project',
        'does not contain project.json',
      );
    }

    if (!options.skipBuild) {
      await _run(
        'flutter',
        <String>['build', 'macos', '--${options.mode}'],
        workingDirectory: hostRoot.path,
      );
    }

    final appBundle = Directory(
      options.appBundlePath ??
          p.join(
            hostRoot.path,
            'build',
            'macos',
            'Build',
            'Products',
            _configurationDirectory(options.mode),
            'PokeMap Selbrume.app',
          ),
    );
    if (!await appBundle.exists()) {
      throw StateError('Built application is missing: ${appBundle.path}');
    }
    final executable = File(
      p.join(
        appBundle.path,
        'Contents',
        'MacOS',
        'PokeMap Selbrume',
      ),
    );
    if (!await executable.exists()) {
      throw StateError('Built executable is missing: ${executable.path}');
    }

    final resources = Directory(
      p.join(appBundle.path, 'Contents', 'Resources'),
    );
    await resources.create(recursive: true);
    final bundledProjectRoot = Directory(
      p.join(resources.path, BundledRuntimeProject.projectDirectoryName),
    );
    await _copyProjectTree(
      source: projectRoot,
      destination: bundledProjectRoot,
    );
    final verification = await verifyBundledRuntimeProject(
      p.join(
        bundledProjectRoot.path,
        BundledRuntimeProject.projectFileName,
      ),
    );
    final repositoryRoot = Directory(
      p.normalize(p.join(hostRoot.path, '..', '..')),
    );
    final releaseCandidateCommit = await _gitHead(repositoryRoot);
    final projectTreeHash =
        await const ProjectTreeDigest().compute(projectRoot);
    final applicationArchitectures = await _binaryArchitectures(executable);
    await _writeJson(
      File(p.join(resources.path, 'pokemap_release_manifest.json')),
      <String, Object?>{
        'schemaVersion': 1,
        'releaseCandidateCommit': releaseCandidateCommit,
        'projectTreeHashSha256': projectTreeHash,
        'projectDirectory': BundledRuntimeProject.projectDirectoryName,
        'projectName': verification.projectName,
        'startMapId': verification.startMapId,
        'mapCount': verification.mapCount,
        'newGameSaveReloadPassed': verification.newGameSaveReloadPassed,
        'applicationArchitectures': applicationArchitectures,
      },
    );

    await _run(
      '/usr/bin/codesign',
      <String>['--force', '--deep', '--sign', '-', appBundle.path],
      workingDirectory: hostRoot.path,
    );
    await _run(
      '/usr/bin/codesign',
      <String>['--verify', '--deep', '--strict', '--verbose=2', appBundle.path],
      workingDirectory: hostRoot.path,
    );

    final outputDirectory = Directory(options.outputDirectory);
    await outputDirectory.create(recursive: true);
    final archive = File(
      p.join(outputDirectory.path, 'selbrume-macos.zip'),
    );
    if (await archive.exists()) await archive.delete();
    await _run(
      '/usr/bin/ditto',
      <String>[
        '-c',
        '-k',
        '--keepParent',
        appBundle.path,
        archive.path,
      ],
      workingDirectory: hostRoot.path,
    );
    final archiveHash =
        (await sha256.bind(archive.openRead()).first).toString();
    final archiveBytes = await archive.length();
    await File(p.join(outputDirectory.path, 'selbrume-macos.sha256'))
        .writeAsString('$archiveHash  ${p.basename(archive.path)}\n');
    await _writeJson(
      File(
        p.join(outputDirectory.path, 'selbrume-macos.manifest.json'),
      ),
      <String, Object?>{
        'schemaVersion': 1,
        'releaseCandidateCommit': releaseCandidateCommit,
        'projectTreeHashSha256': projectTreeHash,
        'packageSha256': archiveHash,
        'packageBytes': archiveBytes,
        'packageFile': p.basename(archive.path),
        'applicationName': p.basename(appBundle.path),
        'applicationArchitectures': applicationArchitectures,
        'signature': 'adhoc',
        'codesignVerified': true,
        'newGameSaveReloadPassed': verification.newGameSaveReloadPassed,
      },
    );
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'archive': archive.path,
        'sha256': archiveHash,
        'bytes': archiveBytes,
        'releaseCandidateCommit': releaseCandidateCommit,
        'projectTreeHashSha256': projectTreeHash,
        'applicationArchitectures': applicationArchitectures,
      }),
    );
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Selbrume macOS packaging failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _copyProjectTree({
  required Directory source,
  required Directory destination,
}) async {
  if (await destination.exists()) {
    await destination.delete(recursive: true);
  }
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    final relativePath = p.relative(entity.path, from: source.path);
    final portablePath = p.posix.normalize(relativePath.replaceAll(r'\', '/'));
    if (_excludedProjectPath(portablePath)) continue;
    final targetPath = p.join(destination.path, relativePath);
    if (entity is Directory) {
      await Directory(targetPath).create(recursive: true);
    } else if (entity is File) {
      final target = File(targetPath);
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    } else if (entity is Link) {
      throw StateError(
        'Bundled project must not contain symbolic links: $portablePath',
      );
    }
  }
}

bool _excludedProjectPath(String relativePath) {
  final segments = p.posix.split(relativePath);
  return segments.contains('.DS_Store') ||
      segments.firstOrNull == 'build' ||
      segments.firstOrNull == 'saves' ||
      relativePath == '.pokemap-project-local.lock' ||
      relativePath.startsWith('.pokemap/validation/');
}

Future<String> _gitHead(Directory repositoryRoot) async {
  final result = await Process.run(
    'git',
    const <String>['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot.path,
  );
  if (result.exitCode != 0) {
    throw StateError('Unable to resolve release candidate commit.');
  }
  return (result.stdout as String).trim();
}

Future<List<String>> _binaryArchitectures(File executable) async {
  final result = await Process.run(
    '/usr/bin/lipo',
    <String>['-archs', executable.path],
  );
  if (result.exitCode != 0) {
    throw StateError('Unable to inspect packaged application architectures.');
  }
  final architectures = (result.stdout as String)
      .trim()
      .split(RegExp(r'\s+'))
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (architectures.isEmpty) {
    throw StateError('Packaged application declares no architecture.');
  }
  return architectures;
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  stdout.writeln(
    'package: $executable ${arguments.map(_shellWord).join(' ')}',
  );
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  await Future.wait<void>(<Future<void>>[
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  final processExitCode = await process.exitCode;
  if (processExitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Command failed with exit code $processExitCode.',
      processExitCode,
    );
  }
}

Future<void> _writeJson(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    flush: true,
  );
}

String _configurationDirectory(String mode) => switch (mode) {
      'release' => 'Release',
      'debug' => 'Debug',
      _ => throw ArgumentError.value(mode, 'mode'),
    };

String _shellWord(String value) =>
    RegExp(r'^[A-Za-z0-9_./:=+-]+$').hasMatch(value)
        ? value
        : "'${value.replaceAll("'", "'\"'\"'")}'";

final class _Options {
  const _Options({
    required this.projectRoot,
    required this.outputDirectory,
    required this.mode,
    required this.skipBuild,
    required this.appBundlePath,
  });

  final String projectRoot;
  final String outputDirectory;
  final String mode;
  final bool skipBuild;
  final String? appBundlePath;

  static _Options parse(List<String> arguments) {
    var projectRoot = p.join('..', '..', 'selbrume');
    var outputDirectory = p.join('build', 'mvp-release');
    var mode = 'release';
    var skipBuild = false;
    String? appBundlePath;
    for (var index = 0; index < arguments.length; index += 1) {
      switch (arguments[index]) {
        case '--project':
          projectRoot = _value(arguments, ++index, '--project');
        case '--output':
          outputDirectory = _value(arguments, ++index, '--output');
        case '--release':
          mode = 'release';
        case '--debug':
          mode = 'debug';
        case '--skip-build':
          skipBuild = true;
        case '--app':
          appBundlePath = _value(arguments, ++index, '--app');
        default:
          throw ArgumentError('Unknown argument: ${arguments[index]}');
      }
    }
    return _Options(
      projectRoot: p.normalize(p.absolute(projectRoot)),
      outputDirectory: p.normalize(p.absolute(outputDirectory)),
      mode: mode,
      skipBuild: skipBuild,
      appBundlePath:
          appBundlePath == null ? null : p.normalize(p.absolute(appBundlePath)),
    );
  }
}

String _value(List<String> arguments, int index, String option) {
  if (index >= arguments.length) {
    throw ArgumentError('Missing value for $option');
  }
  return arguments[index];
}
