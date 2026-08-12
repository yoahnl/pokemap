import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/debug/marionette_qa_workspace.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final options = _QaOptions.parse(arguments);
  final packageRoot = Directory.current.resolveSymbolicLinksSync();
  final workspace = MarionetteQaWorkspace.prepare(
    sourceProjectPath: options.projectPath,
    documentsRootPath: options.documentsRootPath,
    runId: options.runId,
  );
  stdout.writeln(
    jsonEncode(<String, Object?>{
      ...workspace.toJson(),
      'keptAfterExit': options.keep || options.prepareOnly,
      'prepareOnly': options.prepareOnly,
    }),
  );
  if (options.prepareOnly) {
    return;
  }

  final plan = MarionetteQaLaunchPlan(
    packageRootPath: packageRoot,
    projectRootPath: workspace.projectRootPath,
  );
  try {
    final process = await Process.start(
      plan.executable,
      plan.arguments,
      workingDirectory: plan.workingDirectory,
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await process.exitCode;
  } finally {
    if (!options.keep) {
      final projectRoot = Directory(workspace.projectRootPath);
      if (projectRoot.existsSync()) {
        projectRoot.deleteSync(recursive: true);
      }
    }
  }
}

final class _QaOptions {
  const _QaOptions({
    required this.projectPath,
    required this.documentsRootPath,
    required this.runId,
    required this.keep,
    required this.prepareOnly,
  });

  final String projectPath;
  final String documentsRootPath;
  final String runId;
  final bool keep;
  final bool prepareOnly;

  static _QaOptions parse(List<String> arguments) {
    final projectPath = _value(arguments, '--project');
    if (projectPath == null) {
      throw const FormatException(
        'Usage: dart run tool/run_personalization_desktop_qa.dart '
        '--project /absolute/project [--run-id id] [--keep] [--prepare-only]',
      );
    }
    final home = Platform.environment['HOME'];
    if (home == null || home.trim().isEmpty) {
      throw StateError('HOME is required to resolve the macOS container.');
    }
    final documentsRootPath =
        _value(arguments, '--documents-root') ??
        p.join(
          home,
          'Library',
          'Containers',
          'com.yoahnl.pokemap.editor',
          'Data',
          'Documents',
        );
    Directory(documentsRootPath).createSync(recursive: true);
    final runId =
        _value(arguments, '--run-id') ??
        'personalization-${DateTime.now().toUtc().microsecondsSinceEpoch}-$pid';
    return _QaOptions(
      projectPath: projectPath,
      documentsRootPath: documentsRootPath,
      runId: runId,
      keep: arguments.contains('--keep'),
      prepareOnly: arguments.contains('--prepare-only'),
    );
  }

  static String? _value(List<String> arguments, String option) {
    final index = arguments.indexOf(option);
    if (index == -1) {
      return null;
    }
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      throw FormatException('$option requires a value.');
    }
    return arguments[index + 1];
  }
}
