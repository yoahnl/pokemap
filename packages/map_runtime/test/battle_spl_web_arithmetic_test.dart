import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves signed SPL arithmetic in dart2js', () async {
    final qaPath = Platform.environment['AVELUNE_SPL_WEB_QA_DIR'];
    if (qaPath == null) {
      throw StateError(
        'AVELUNE_SPL_WEB_QA_DIR must identify this task’s QA directory',
      );
    }
    final qaDirectory = Directory(qaPath);
    if (!qaDirectory.isAbsolute || !await qaDirectory.exists()) {
      throw StateError('The SPL web QA directory must already exist');
    }
    final resolved = await qaDirectory.resolveSymbolicLinks();
    if (Platform.isMacOS) {
      final allowed = await Directory('/Users/karim/Library/Caches/AveluneQA')
          .resolveSymbolicLinks();
      if (!resolved.startsWith('$allowed/')) {
        throw StateError('The SPL web QA directory is outside AveluneQA');
      }
    }
    final directory = await Directory(resolved).createTemp('spl-web-');
    addTearDown(() => directory.delete(recursive: true));
    final output = '${directory.path}/probe.js';
    final compile = await Process.run('dart', [
      'compile',
      'js',
      '-O2',
      '-o',
      output,
      'test/support/battle_spl_web_arithmetic_probe.dart',
    ]);
    expect(compile.exitCode, 0, reason: '${compile.stdout}\n${compile.stderr}');
    final result = await Process.run('node', [output]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, skip: Platform.environment['AVELUNE_SPL_WEB_TEST'] != '1');
}
