import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  exitCode = await generateUpdateIndexCommand(arguments);
}

Future<int> generateUpdateIndexCommand(
  List<String> arguments, {
  IOSink? output,
  IOSink? errorOutput,
}) async {
  final stdoutSink = output ?? stdout;
  final stderrSink = errorOutput ?? stderr;
  final outputPath = _readOption(arguments, '--output');
  final version = _readOption(arguments, '--version');
  final tag = _readOption(arguments, '--tag');
  final publishedAtText = _readOption(arguments, '--published-at');
  final repository = _readOption(arguments, '--repository');

  if ([outputPath, version, tag, publishedAtText, repository]
      .any((value) => value == null)) {
    stderrSink.writeln(
      'Usage: generate_update_index.dart --output path '
      '--version X.Y.Z --tag pokemap-vX.Y.Z '
      '--published-at UTC-ISO-8601 --repository owner/repo',
    );
    return 64;
  }

  final errors = <String>[];
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version!)) {
    errors.add('Version must be a stable X.Y.Z version.');
  }
  if (tag != 'pokemap-v$version') {
    errors.add('Tag must exactly match pokemap-v$version.');
  }
  if (!RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(repository!)) {
    errors.add('Repository must match owner/repo.');
  }
  final publishedAt = DateTime.tryParse(publishedAtText!);
  if (publishedAt == null || !publishedAt.isUtc) {
    errors.add('Published timestamp must be a valid UTC ISO-8601 value.');
  }
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderrSink.writeln(error);
    }
    return 65;
  }

  final index = <String, Object>{
    'schemaVersion': 1,
    'channel': 'stable',
    'version': version,
    'tag': tag!,
    'publishedAt': publishedAt!.toIso8601String(),
    'releaseNotesUrl': 'https://github.com/$repository/releases/tag/$tag',
  };
  final destination = File(outputPath!);
  try {
    await destination.parent.create(recursive: true);
    await destination.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(index)}\n',
      flush: true,
    );
  } on FileSystemException catch (error) {
    stderrSink.writeln('Unable to write update index: ${error.message}');
    return 73;
  }

  stdoutSink.writeln('Wrote stable update index to ${destination.path}.');
  return 0;
}

String? _readOption(List<String> arguments, String option) {
  final index = arguments.indexOf(option);
  if (index == -1 || index + 1 >= arguments.length) {
    return null;
  }
  return arguments[index + 1];
}
