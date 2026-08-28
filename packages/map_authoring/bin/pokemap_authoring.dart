import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

import 'src/tiled_image_collection_cli_png_codec.dart';

Future<void> main(List<String> arguments) async {
  late final _CliOptions options;
  try {
    options = _CliOptions.parse(arguments);
  } on _CliUsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage);
    exitCode = AuthoringCliExitCodes.usage;
    return;
  }

  const fileReader = LocalProjectFileReader();
  late final WorkspacePolicy policy;
  try {
    policy = await WorkspacePolicy.create(
      allowedRootPaths: options.allowedRoots,
      fileReader: fileReader,
    );
  } on WorkspaceAccessException catch (error) {
    stderr.writeln(
      'Unable to initialize the allowed roots (${error.code}).',
    );
    exitCode = AuthoringCliExitCodes.config;
    return;
  } on Object {
    stderr.writeln('Unable to initialize the authoring workspace.');
    exitCode = AuthoringCliExitCodes.software;
    return;
  }

  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(
    handles: handles,
    fingerprintCache: ProjectSnapshotFingerprintCache(),
    snapshotCache: ProjectSnapshotCache(),
  );
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: fileReader,
      handles: handles,
    ),
    snapshotLoader: snapshots,
  );
  final artifacts = LocalArtifactStore(
    allowedSourceRoots: [
      ...options.allowedRoots,
      ...options.artifactRoots,
    ],
    maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
  );
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
    artifactStore: artifacts,
    tiledImageCollectionRasterCodec:
        const CliPngTiledImageCollectionRasterCodec(),
  );
  GamePackageExportApiPort? gameExport;
  if (options.exportRoots.isNotEmpty) {
    try {
      gameExport = await LocalGamePackageExportApi.create(
        allowedProjectRoots: options.allowedRoots,
        allowedExportRoots: options.exportRoots,
      );
    } on Object {
      stderr.writeln('Unable to initialize the configured export roots.');
      exitCode = AuthoringCliExitCodes.config;
      return;
    }
  }
  final worker = JsonlWorker(
    api: api,
    mutations: mutations,
    projectBootstrap: ProjectPokemonRulesetBootstrapService(
      policy: policy,
      fileReader: fileReader,
      writer: const LocalProjectManifestBootstrapWriter(),
    ),
    gameExport: gameExport,
    commandTimeout: options.commandTimeout,
    gameExportTimeout: options.gameExportTimeout,
    maxInputBytes: options.maxInputBytes,
  );

  try {
    final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      stdout.writeln(await worker.processLine(line));
      await stdout.flush();
    }
    exitCode = AuthoringCliExitCodes.success;
  } on Object {
    stderr.writeln('The JSONL input stream failed unexpectedly.');
    exitCode = AuthoringCliExitCodes.ioError;
  }
}

const String _usage = 'Usage: pokemap_authoring --root <allowed-root> '
    '[--root <allowed-root> ...] [--export-root <allowed-output-root> ...] '
    '[--artifact-root <allowed-artifact-root> ...] '
    '[--timeout-ms <positive-int>] '
    '[--export-timeout-ms <positive-int>] '
    '[--max-input-bytes <positive-int>]';

final class _CliOptions {
  const _CliOptions({
    required this.allowedRoots,
    required this.artifactRoots,
    required this.exportRoots,
    required this.commandTimeout,
    required this.gameExportTimeout,
    required this.maxInputBytes,
  });

  factory _CliOptions.parse(List<String> arguments) {
    final roots = <String>[];
    final artifactRoots = <String>[];
    final exportRoots = <String>[];
    var timeoutMs = 10000;
    var exportTimeoutMs = 120000;
    var maxInputBytes = defaultAuthoringJsonlMaxInputBytes;
    var index = 0;
    while (index < arguments.length) {
      final option = arguments[index++];
      switch (option) {
        case '--root':
          roots.add(_nextValue(arguments, index++, option));
        case '--artifact-root':
          artifactRoots.add(_nextValue(arguments, index++, option));
        case '--export-root':
          exportRoots.add(_nextValue(arguments, index++, option));
        case '--timeout-ms':
          timeoutMs = _positiveInt(
            _nextValue(arguments, index++, option),
            option,
          );
        case '--export-timeout-ms':
          exportTimeoutMs = _positiveInt(
            _nextValue(arguments, index++, option),
            option,
          );
        case '--max-input-bytes':
          maxInputBytes = _positiveInt(
            _nextValue(arguments, index++, option),
            option,
          );
        default:
          throw const _CliUsageException('Unknown command-line option.');
      }
    }
    if (roots.isEmpty) {
      throw const _CliUsageException(
        'At least one --root option is required.',
      );
    }
    return _CliOptions(
      allowedRoots: List.unmodifiable(roots),
      artifactRoots: List.unmodifiable(artifactRoots),
      exportRoots: List.unmodifiable(exportRoots),
      commandTimeout: Duration(milliseconds: timeoutMs),
      gameExportTimeout: Duration(milliseconds: exportTimeoutMs),
      maxInputBytes: maxInputBytes,
    );
  }

  final List<String> allowedRoots;
  final List<String> artifactRoots;
  final List<String> exportRoots;
  final Duration commandTimeout;
  final Duration gameExportTimeout;
  final int maxInputBytes;
}

String _nextValue(List<String> arguments, int index, String option) {
  if (index >= arguments.length ||
      arguments[index].trim().isEmpty ||
      arguments[index].startsWith('--')) {
    throw _CliUsageException('$option requires a value.');
  }
  return arguments[index];
}

int _positiveInt(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _CliUsageException('$option requires a positive integer.');
  }
  return parsed;
}

final class _CliUsageException implements Exception {
  const _CliUsageException(this.message);

  final String message;
}
