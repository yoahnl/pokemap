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
    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['compile', 'exe', entrypoint, '-o', executable.path],
      workingDirectory: Directory.current.path,
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
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final process = await start(arguments);
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
    } on TimeoutException {
      process.kill();
      await process.exitCode;
      await stdout;
      await stderr;
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (await _outputDirectory.exists()) {
      await _outputDirectory.delete(recursive: true);
    }
  }
}
