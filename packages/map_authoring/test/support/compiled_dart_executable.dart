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
  }) async {
    final outputDirectory = await Directory('build/test').createTemp(
      'compiled_${name}_',
    );
    final executable = File(
      '${outputDirectory.path}/$name${Platform.isWindows ? '.exe' : ''}',
    );
    final result = await _runProcess(
      Platform.resolvedExecutable,
      <String>['compile', 'exe', entrypoint, '-o', executable.path],
      workingDirectory: Directory.current.path,
      timeout: const Duration(minutes: 1),
    );
    if (result.exitCode != 0) {
      await outputDirectory.delete(recursive: true);
      throw StateError(
        'Could not compile $entrypoint for process tests: ${result.stderr}',
      );
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
