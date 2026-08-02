import 'dart:io';

import 'package:map_editor/src/features/editor_updates/domain/editor_release_version.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await validateReleaseVersionCommand(arguments);
}

Future<int> validateReleaseVersionCommand(
  List<String> arguments, {
  IOSink? output,
  IOSink? errorOutput,
}) async {
  final stdoutSink = output ?? stdout;
  final stderrSink = errorOutput ?? stderr;
  final tag = _readOption(arguments, '--tag');
  final pubspecPath = _readOption(arguments, '--pubspec');
  final previousBuildText = _readOption(arguments, '--previous-build');

  if (tag == null || pubspecPath == null) {
    stderrSink.writeln(
      'Usage: validate_release_version.dart '
      '--tag pokemap-vX.Y.Z --pubspec path/to/pubspec.yaml '
      '[--previous-build N]',
    );
    return 64;
  }

  int? previousBuildNumber;
  if (previousBuildText != null) {
    previousBuildNumber = int.tryParse(previousBuildText);
    if (previousBuildNumber == null || previousBuildNumber < 0) {
      stderrSink.writeln('--previous-build must be a non-negative integer.');
      return 64;
    }
  }

  final pubspec = File(pubspecPath);
  if (!await pubspec.exists()) {
    stderrSink.writeln('Pubspec not found: $pubspecPath');
    return 66;
  }

  final validation = EditorReleaseVersionContract.validate(
    tag: tag,
    pubspecContents: await pubspec.readAsString(),
    previousBuildNumber: previousBuildNumber,
  );
  if (!validation.isValid) {
    for (final error in validation.errors) {
      stderrSink.writeln(error);
    }
    return 65;
  }

  stdoutSink.writeln(
    'Validated PokeMap Editor ${validation.displayVersion} '
    'build ${validation.buildNumber}.',
  );
  return 0;
}

String? _readOption(List<String> arguments, String option) {
  final index = arguments.indexOf(option);
  if (index == -1 || index + 1 >= arguments.length) {
    return null;
  }
  return arguments[index + 1];
}
