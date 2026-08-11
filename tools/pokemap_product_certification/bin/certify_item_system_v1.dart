import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/certify_item_system_v1.dart '
      '[--repository-root <path>] [--project-root <path>] '
      '[--mcp-root <path>] [--output <path>] '
      '[--transport-receipts-out <path>] [--skip-mcp-build]',
    );
    return;
  }
  Directory? temporaryOutputDirectory;
  try {
    final options = _parseArguments(arguments);
    final repositoryRoot = Directory(
      p.normalize(
        p.absolute(
          options['repository-root'] ?? _findRepositoryRoot(Directory.current),
        ),
      ),
    );
    final projectRoot = Directory(
      _resolvedPath(
        repositoryRoot,
        options['project-root'] ??
            'examples/playable_runtime_host/golden_item_system',
      ),
    );
    final mcpRoot = Directory(
      _resolvedPath(repositoryRoot, options['mcp-root'] ?? 'tools/pokemap_mcp'),
    );
    if (!options.containsKey('skip-mcp-build')) {
      await _buildMcp(mcpRoot);
    }
    final requestedOutput = options['output'];
    final requestedReceipts = options['transport-receipts-out'];
    temporaryOutputDirectory = await Directory.systemTemp.createTemp(
      'pokemap-item-certification-',
    );
    final outputPath = requestedOutput == null
        ? p.join(temporaryOutputDirectory.path, 'certification.json')
        : _resolvedPath(repositoryRoot, requestedOutput);
    final receiptPath = requestedReceipts == null
        ? p.join(temporaryOutputDirectory.path, 'transport-receipts.json')
        : _resolvedPath(repositoryRoot, requestedReceipts);
    await _runFlutterWorker(
      certificationPackageRoot: Directory.current,
      repositoryRoot: repositoryRoot,
      projectRoot: projectRoot,
      mcpRoot: mcpRoot,
      outputPath: outputPath,
      receiptPath: receiptPath,
    );
    if (requestedOutput == null) {
      stdout.write(await File(outputPath).readAsString());
    }
  } on Object catch (error) {
    stderr.writeln('Item System V1 certification failed: $error');
    exitCode = 1;
  } finally {
    if (temporaryOutputDirectory != null &&
        await temporaryOutputDirectory.exists()) {
      await temporaryOutputDirectory.delete(recursive: true);
    }
  }
}

Map<String, String?> _parseArguments(List<String> arguments) {
  const valueOptions = <String>{
    'repository-root',
    'project-root',
    'mcp-root',
    'output',
    'transport-receipts-out',
  };
  const flags = <String>{'skip-mcp-build'};
  final parsed = <String, String?>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (!argument.startsWith('--')) {
      throw FormatException('Unexpected argument: $argument.');
    }
    final name = argument.substring(2);
    if (flags.contains(name)) {
      if (parsed.containsKey(name)) {
        throw FormatException('Duplicate option: --$name.');
      }
      parsed[name] = null;
      continue;
    }
    if (!valueOptions.contains(name) || index + 1 >= arguments.length) {
      throw FormatException('Unknown or incomplete option: --$name.');
    }
    if (parsed.containsKey(name)) {
      throw FormatException('Duplicate option: --$name.');
    }
    parsed[name] = arguments[index += 1];
  }
  return parsed;
}

String _findRepositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File(p.join(current.path, '.git')).existsSync() ||
        Directory(p.join(current.path, '.git')).existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Unable to locate the repository root.');
    }
    current = parent;
  }
}

String _resolvedPath(Directory repositoryRoot, String value) {
  return p.normalize(
    p.isAbsolute(value) ? value : p.join(repositoryRoot.path, value),
  );
}

Future<void> _buildMcp(Directory mcpRoot) async {
  final result = await Process.run('npm', const <String>[
    'run',
    'build',
  ], workingDirectory: mcpRoot.path);
  if (result.exitCode != 0) {
    throw StateError('MCP build failed: ${result.stderr}');
  }
}

Future<void> _runFlutterWorker({
  required Directory certificationPackageRoot,
  required Directory repositoryRoot,
  required Directory projectRoot,
  required Directory mcpRoot,
  required String outputPath,
  required String receiptPath,
}) async {
  final result = await Process.run('flutter', <String>[
    'test',
    'test/support/item_system_certification_worker_test.dart',
    '--plain-name',
    'writes executable Item System V1 certification artifacts',
    '--dart-define=POKEMAP_REPOSITORY_ROOT=${repositoryRoot.path}',
    '--dart-define=POKEMAP_ITEM_PROJECT_ROOT=${projectRoot.path}',
    '--dart-define=POKEMAP_MCP_ROOT=${mcpRoot.path}',
    '--dart-define=POKEMAP_ITEM_CERTIFICATION_OUTPUT=$outputPath',
    '--dart-define=POKEMAP_ITEM_TRANSPORT_RECEIPTS_OUTPUT=$receiptPath',
  ], workingDirectory: certificationPackageRoot.path);
  if (result.exitCode != 0) {
    throw StateError(
      'Certification worker failed:\n${result.stdout}\n${result.stderr}',
    );
  }
}
