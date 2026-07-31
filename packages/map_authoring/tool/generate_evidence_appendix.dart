import 'dart:io';

/// Deterministically reproduces created text files in a Markdown Evidence Pack.
///
/// Reports intentionally exclude themselves to avoid recursive content. This
/// tool is kept in the package because every PMCP lot has the same auditable
/// full-content requirement.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/generate_evidence_appendix.dart '
      '<output.md> <title> <input> [input ...]',
    );
    exitCode = 64;
    return;
  }
  final outputPath = arguments[0];
  final title = arguments[1].trim();
  final inputPaths = arguments.sublist(2)..sort();
  if (title.isEmpty || inputPaths.contains(outputPath)) {
    stderr.writeln('Title must be nonblank and output cannot be an input.');
    exitCode = 64;
    return;
  }
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln(
      'Cette annexe reproduit intégralement les fichiers texte créés par le lot.',
    )
    ..writeln();
  for (var index = 0; index < inputPaths.length; index++) {
    final inputPath = inputPaths[index];
    final file = File(inputPath);
    if (!await file.exists()) {
      stderr.writeln('Missing input: $inputPath');
      exitCode = 66;
      return;
    }
    final content = await file.readAsString();
    final fence = _fenceFor(inputPath);
    buffer
      ..writeln('## `$inputPath`')
      ..writeln()
      ..writeln('```$fence')
      ..write(content);
    if (!content.endsWith('\n')) buffer.writeln();
    buffer.writeln('```');
    if (index < inputPaths.length - 1) buffer.writeln();
  }
  await File(outputPath).writeAsString(buffer.toString(), flush: true);
}

String _fenceFor(String path) {
  if (path.endsWith('.dart')) return 'dart';
  if (path.endsWith('.json') || path.endsWith('.jsonl')) return 'json';
  if (path.endsWith('.yaml') || path.endsWith('.yml')) return 'yaml';
  if (path.endsWith('.md')) return 'markdown';
  return 'text';
}
