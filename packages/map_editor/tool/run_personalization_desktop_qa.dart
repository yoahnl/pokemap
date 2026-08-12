import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/debug/marionette_personalization_qa_seed.dart';
import 'package:map_editor/src/debug/marionette_qa_workspace.dart';

Future<void> main(List<String> arguments) async {
  final options = _QaOptions.parse(arguments);
  final packageRoot = Directory.current.resolveSymbolicLinksSync();
  final projectPath = options.projectPath;
  MarionetteQaWorkspace? workspace;
  late final String executable;
  late final String workingDirectory;
  late final List<String> launchArguments;
  if (projectPath == null) {
    final plan = MarionetteQaSeedLaunchPlan(
      packageRootPath: packageRoot,
      runId: options.runId,
    );
    executable = plan.executable;
    workingDirectory = plan.workingDirectory;
    launchArguments = plan.arguments;
    stdout.writeln(
      jsonEncode(<String, Object?>{
        'seed': MarionettePersonalizationQaSeed.seedId,
        'runId': options.runId,
        'sandboxOwned': true,
      }),
    );
  } else {
    workspace = MarionetteQaWorkspace.prepare(
      sourceProjectPath: projectPath,
      documentsRootPath: options.documentsRootPath!,
      runId: options.runId,
    );
    final plan = MarionetteQaLaunchPlan(
      packageRootPath: packageRoot,
      projectRootPath: workspace.projectRootPath,
    );
    executable = plan.executable;
    workingDirectory = plan.workingDirectory;
    launchArguments = plan.arguments;
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
  }

  try {
    final process = await Process.start(
      executable,
      launchArguments,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await process.exitCode;
  } finally {
    if (!options.keep && workspace != null) {
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

  final String? projectPath;
  final String? documentsRootPath;
  final String runId;
  final bool keep;
  final bool prepareOnly;

  static _QaOptions parse(List<String> arguments) {
    final projectPath = _value(arguments, '--project');
    final documentsRootPath = _value(arguments, '--documents-root');
    final prepareOnly = arguments.contains('--prepare-only');
    if (projectPath == null && (documentsRootPath != null || prepareOnly)) {
      throw const FormatException(
        'Usage: dart run tool/run_personalization_desktop_qa.dart '
        '[--run-id id] [--keep] or --project /absolute/project '
        '--documents-root /writable/root [--prepare-only]',
      );
    }
    if (projectPath != null && documentsRootPath == null) {
      throw const FormatException(
        '--documents-root is required with --project.',
      );
    }
    if (documentsRootPath != null) {
      Directory(documentsRootPath).createSync(recursive: true);
    }
    final runId =
        _value(arguments, '--run-id') ??
        'personalization-${DateTime.now().toUtc().microsecondsSinceEpoch}-$pid';
    return _QaOptions(
      projectPath: projectPath,
      documentsRootPath: documentsRootPath,
      runId: runId,
      keep: arguments.contains('--keep'),
      prepareOnly: prepareOnly,
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
