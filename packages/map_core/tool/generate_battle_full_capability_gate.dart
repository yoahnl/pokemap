import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

void main(List<String> arguments) {
  final mode = switch (arguments) {
    ['--write'] => _GeneratorMode.write,
    ['--check'] => _GeneratorMode.check,
    _ => null,
  };
  if (mode == null) {
    stderr.writeln(
      'Usage: dart run tool/generate_battle_full_capability_gate.dart '
      '--write|--check',
    );
    exitCode = 64;
    return;
  }

  final gate = BattleFullCapabilityGate.canonical();
  // This executable is deliberately separate from the MVP generator. A stale
  // RM-053 artifact must fail the full audit without expanding the FG-185
  // release cutline owned by battle.mvp.v0.
  if (!gate.report.isPassing) {
    stderr.writeln(gate.agentMarkdown);
    exitCode = 1;
    return;
  }

  final repositoryRoot = Directory.current.parent.parent;
  // No timestamp or machine path is emitted: identical source truth must
  // produce byte-identical committed artifacts.
  final expected = <String, String>{
    battleFullCapabilityJsonRelativePath:
        '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n',
    battleFullCapabilityMarkdownRelativePath: '${gate.agentMarkdown}\n',
  };

  switch (mode) {
    case _GeneratorMode.write:
      for (final entry in expected.entries) {
        final file = File('${repositoryRoot.path}/${entry.key}');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(entry.value);
        stdout.writeln('Wrote ${entry.key}');
      }
    case _GeneratorMode.check:
      var isCurrent = true;
      for (final entry in expected.entries) {
        final file = File('${repositoryRoot.path}/${entry.key}');
        if (!file.existsSync() || file.readAsStringSync() != entry.value) {
          stderr.writeln('Stale generated artifact: ${entry.key}');
          isCurrent = false;
        }
      }
      if (!isCurrent) {
        exitCode = 1;
        return;
      }
      stdout.writeln('Battle full capability gate artifacts are up to date.');
  }
}

enum _GeneratorMode { write, check }
