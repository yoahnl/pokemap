import 'dart:io' as io;

import 'package:map_battle/src/psdk/cli/psdk_battle_cli.dart';

/// Executable wrapper for the PSDK smoke CLI.
///
/// The reusable implementation lives under `lib/src/psdk` so tests can invoke
/// it without spawning a process, while this file remains the package entrypoint
/// for manual `dart run bin/psdk_battle_cli.dart` checks.
Future<void> main(List<String> args) async {
  final exitCode = await PsdkBattleCli(
    stdout: io.stdout.writeln,
    stderr: io.stderr.writeln,
  ).run(args);
  io.exitCode = exitCode;
}
