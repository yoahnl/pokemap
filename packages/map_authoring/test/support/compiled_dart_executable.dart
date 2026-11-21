import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class CompiledDartExecutable {
  CompiledDartExecutable._({
    required this.executable,
    required this.workingDirectory,
    required Directory outputDirectory,
  }) : _outputDirectory = outputDirectory;

  final File executable;
  final String workingDirectory;
  final Directory _outputDirectory;

  static Future<CompiledDartExecutable> build({
    required String entrypoint,
    required String name,
    Map<String, String> defines = const {},
  }) async {
    final buildDirectory = await Directory('build/test').create(recursive: true);
    final outputDirectory = await buildDirectory.createTemp(
      'compiled_${name}_',
    );
    final executable = File(
      '${outputDirectory.path}/$name${Platform.isWindows ? '.exe' : ''}',
    );
    try {
      final result = await _runProcess(
        Platform.resolvedExecutable,
        <String>[
          'compile',
          'exe',
          for (final define in defines.entries) '-D${define.key}=${define.value}',
          entrypoint,
          '-o',
          executable.path,
        ],
        workingDirectory: Directory.current.path,
        timeout: const Duration(minutes: 3),
      );
      if (result.exitCode != 0) {
        throw StateError(
          'Could not compile $entrypoint for process tests: ${result.stderr}',
        );
      }
    } on Object {
      await outputDirectory.delete(recursive: true);
      rethrow;
    }
    return CompiledDartExecutable._(
      executable: executable,
      workingDirectory: Directory.current.path,
      outputDirectory: outputDirectory,
    );
  }

  Future<Process> start(List<String> arguments) {
    return Process.start(
      executable.path,
      arguments,
      workingDirectory: workingDirectory,
    );
  }

  Future<ProcessResult> run(
    List<String> arguments, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    return _runProcess(
      executable.path,
      arguments,
      workingDirectory: workingDirectory,
      timeout: timeout,
    );
  }

  static Future<void> terminate(Process process) {
    return _terminateProcess(process);
  }

  Future<void> dispose() async {
    if (await _outputDirectory.exists()) {
      await _outputDirectory.delete(recursive: true);
    }
  }
}

Future<ProcessResult> _runProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Duration timeout,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  final stdout = process.stdout.transform(utf8.decoder).join();
  final stderr = process.stderr.transform(utf8.decoder).join();
  try {
    final exitCode = await process.exitCode.timeout(timeout);
    return ProcessResult(
      process.pid,
      exitCode,
      await stdout,
      await stderr,
    );
  } on TimeoutException catch (error, stackTrace) {
    await _terminateProcess(process);
    await stdout;
    await stderr;
    Error.throwWithStackTrace(error, stackTrace);
  }
}

Future<void> _terminateProcess(Process process) async {
  final exitCode = process.exitCode;
  process.kill();
  try {
    await exitCode.timeout(const Duration(seconds: 2));
    return;
  } on TimeoutException {
    process.kill(
        Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigkill);
  }
  await exitCode.timeout(const Duration(seconds: 2));
}
