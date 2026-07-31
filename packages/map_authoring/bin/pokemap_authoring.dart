import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

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
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: fileReader,
      handles: handles,
    ),
    snapshotLoader: snapshots,
  );
  final mutations = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: snapshots,
  );
  final worker = JsonlWorker(
    api: api,
    mutations: mutations,
    commandTimeout: options.commandTimeout,
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
    '[--root <allowed-root> ...] [--timeout-ms <positive-int>] '
    '[--max-input-bytes <positive-int>]';

final class _CliOptions {
  const _CliOptions({
    required this.allowedRoots,
    required this.commandTimeout,
    required this.maxInputBytes,
  });

  factory _CliOptions.parse(List<String> arguments) {
    final roots = <String>[];
    var timeoutMs = 10000;
    var maxInputBytes = 64 * 1024;
    var index = 0;
    while (index < arguments.length) {
      final option = arguments[index++];
      switch (option) {
        case '--root':
          roots.add(_nextValue(arguments, index++, option));
        case '--timeout-ms':
          timeoutMs = _positiveInt(
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
      commandTimeout: Duration(milliseconds: timeoutMs),
      maxInputBytes: maxInputBytes,
    );
  }

  final List<String> allowedRoots;
  final Duration commandTimeout;
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
