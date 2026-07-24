import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_launcher.dart';

import '../../tool/src/pokemap_eval_cli.dart';

void main() {
  test('web command defaults to loopback and an ephemeral port', () {
    final options = PokeMapEvalCli.parse(
      <String>['web', '--project', 'selbrume', '--no-open'],
    );

    expect(options.command, PokeMapEvalCommand.web);
    expect(options.projectId, 'selbrume');
    expect(options.port, 0);
    expect(options.openBrowser, isFalse);
  });

  test('web command validates the requested port', () {
    expect(
      () => PokeMapEvalCli.parse(<String>['web', '--port', '65536']),
      throwsA(isA<PokeMapEvalUsageException>()),
    );
    expect(
      PokeMapEvalCli.parse(<String>['web', '--port', '55123']).port,
      55123,
    );
  });

  test('launcher passes the URL as one process argument without a shell',
      () async {
    final process = _RecordingProcessRunner();
    final opened = await EvaluationWebLauncher(
      processRunner: process,
      operatingSystem: 'macos',
    ).open(Uri.parse('http://localhost:54321/'));

    expect(opened, isTrue);
    expect(process.executable, 'open');
    expect(process.arguments, <String>['http://localhost:54321/']);
    expect(process.runInShell, isFalse);
  });

  test('asset location is relative to the command script', () {
    final assets = evaluationWebAssetsForScript(
      Uri.file('/repo/examples/playable_runtime_host/tool/pokemap_eval.dart'),
    );

    expect(
      assets.path.replaceAll(r'\', '/'),
      '/repo/examples/playable_runtime_host/tool/assets/pokemap_eval_web',
    );
  });
}

final class _RecordingProcessRunner implements EvaluationProcessRunner {
  String? executable;
  List<String> arguments = const <String>[];
  bool? runInShell;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    required bool runInShell,
  }) async {
    this.executable = executable;
    this.arguments = List<String>.of(arguments);
    this.runInShell = runInShell;
    return ProcessResult(1, 0, '', '');
  }
}
