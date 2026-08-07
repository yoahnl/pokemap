// Enforces the repository file-length rule with a ratchet.
//
// New code must stay under [_limit] lines. Files that already exceeded it are
// frozen in `tools/file_length_baseline.txt` at their current size: they are
// tolerated, but they may never grow. Once a listed file drops back under the
// limit it is dropped from the baseline and can never regress again.
//
//   dart tools/check_file_length.dart                  # verify (CI, hooks)
//   dart tools/check_file_length.dart --update-baseline # after a split
import 'dart:io';

const int _limit = 3000;
const String _baselinePath = 'tools/file_length_baseline.txt';
const List<String> _roots = <String>['packages', 'apps'];

/// Machine-written sources; splitting them is meaningless, the generator owns
/// their shape.
bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gr.dart') ||
    path.endsWith('.config.dart');

/// Tests are exempt by decision: a long test file carries far less risk than a
/// long unit of production logic.
bool _isTest(String path) =>
    path.endsWith('_test.dart') ||
    path.contains('/test/') ||
    path.contains('/integration_test/');

/// Battle-engine catalogues are data tables, not logic. Splitting a move or
/// animation registry yields more files and no more clarity.
bool _isBattleEngineCatalogue(String path) =>
    path.startsWith('packages/map_battle/') ||
    path.contains('/flame/battle_');

bool _isExempt(String path) =>
    _isGenerated(path) || _isTest(path) || _isBattleEngineCatalogue(path);

int _countLines(File file) => file.readAsLinesSync().length;

Map<String, int> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return <String, int>{};
  final entries = <String, int>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf(' ');
    if (separator <= 0) continue;
    final lines = int.tryParse(line.substring(0, separator));
    if (lines == null) continue;
    entries[line.substring(separator + 1).trim()] = lines;
  }
  return entries;
}

void _writeBaseline(Map<String, int> entries) {
  final sorted = entries.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('# Files that exceeded $_limit lines when the rule landed.')
    ..writeln('# They are tolerated at this exact size and may never grow.')
    ..writeln('# Shrink one below $_limit and remove its line: the list only')
    ..writeln('# ever gets shorter. Regenerate with:')
    ..writeln('#   dart tools/check_file_length.dart --update-baseline')
    ..writeln();
  for (final path in sorted) {
    buffer.writeln('${entries[path]} $path');
  }
  File(_baselinePath).writeAsStringSync(buffer.toString());
}

void main(List<String> args) {
  final update = args.contains('--update-baseline');
  final oversized = <String, int>{};

  for (final root in _roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      // Build output and vendored plugin sources are not ours to split.
      if (path.contains('/build/') ||
          path.contains('/.dart_tool/') ||
          path.contains('/flutter/ephemeral/') ||
          path.contains('/.plugin_symlinks/')) {
        continue;
      }
      if (_isExempt(path)) continue;
      final lines = _countLines(entity);
      if (lines > _limit) oversized[path] = lines;
    }
  }

  if (update) {
    _writeBaseline(oversized);
    stdout.writeln('Baseline updated: ${oversized.length} file(s) over $_limit '
        'lines recorded.');
    return;
  }

  final baseline = _readBaseline();
  final introduced = <String, int>{};
  final grown = <String, ({int now, int allowed})>{};
  for (final entry in oversized.entries) {
    final allowed = baseline[entry.key];
    if (allowed == null) {
      introduced[entry.key] = entry.value;
    } else if (entry.value > allowed) {
      grown[entry.key] = (now: entry.value, allowed: allowed);
    }
  }
  final fixed = baseline.keys.where((path) => !oversized.containsKey(path));

  if (introduced.isEmpty && grown.isEmpty) {
    stdout.writeln('File length OK — no file over $_limit lines outside the '
        'baseline (${baseline.length} tolerated).');
    if (fixed.isNotEmpty) {
      stdout.writeln('\n${fixed.length} baseline file(s) now under the limit. '
          'Run with --update-baseline to lock the win in:');
      for (final path in fixed) {
        stdout.writeln('  $path');
      }
    }
    return;
  }

  stderr.writeln('File length rule violated (limit: $_limit lines).\n');
  if (introduced.isNotEmpty) {
    stderr.writeln('New file(s) over the limit — split them:');
    for (final entry in introduced.entries) {
      stderr.writeln('  ${entry.value} lines  ${entry.key}');
    }
    stderr.writeln();
  }
  if (grown.isNotEmpty) {
    stderr.writeln('Baseline file(s) that grew — they may only shrink:');
    for (final entry in grown.entries) {
      stderr.writeln('  ${entry.key}: ${entry.value.allowed} -> '
          '${entry.value.now} lines');
    }
    stderr.writeln();
  }
  stderr.writeln('Split the offending file, or move the code you added into a '
      'new one. The baseline is not a place to register new debt.');
  exitCode = 1;
}
