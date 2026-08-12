import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/debug/marionette_connector_compatibility.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final packageRoot = Directory.current.resolveSymbolicLinksSync();
  final packageConfigPath = p.join(
    packageRoot,
    '.dart_tool',
    'package_config.json',
  );
  final compatibility = MarionetteConnectorCompatibility.requireCompatible(
    packageConfigPath,
  );
  stdout.writeln(
    jsonEncode(<String, Object?>{
      ...compatibility.toJson(),
      'packageRootPath': packageRoot,
    }),
  );
  if (arguments.contains('--check-only')) {
    return;
  }
  if (arguments.isNotEmpty) {
    throw const FormatException(
      'Usage: dart run tool/run_marionette_mcp.dart [--check-only]',
    );
  }

  final plan = MarionetteConnectorLaunchPlan(packageRootPath: packageRoot);
  final process = await Process.start(
    plan.executable,
    plan.arguments,
    workingDirectory: plan.workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
