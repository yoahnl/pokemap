import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'gen5_battle_script_source.dart';

final class Gen5SelectedScript {
  const Gen5SelectedScript(this.script, this.warnings);
  final Gen5BattleScriptSource script;
  final Set<String> warnings;
}

abstract final class Gen5BatchScriptSelection {
  static Gen5SelectedScript read(Uint8List bytes, {
    required String sourceRevision,
    required String sourcePath,
    required String expectedSha256,
  }) {
    try {
      return Gen5SelectedScript(Gen5BattleScriptSource.read(bytes,
        sourceRevision: sourceRevision, sourcePath: sourcePath,
        expectedSha256: expectedSha256), const {});
    } on FormatException catch (error) {
      if (!{'Unsupported battle script header', 'Invalid battle script label',
        'Content after battle script end'}.contains(error.message)) {
        rethrow;
      }
    }
    if (bytes.isEmpty || bytes.length > 64 * 1024 ||
        sha256.convert(bytes).toString() != expectedSha256) {
      throw const FormatException('Invalid battle script source');
    }
    final lines = const LineSplitter().convert(utf8.decode(bytes));
    if (lines.length > 2048 || !lines.any((line) => line.trim() == '#include "asm/btlv_effvm.inc"')) {
      throw const FormatException('Invalid battle script source');
    }
    final variants = <String>[];
    for (final line in lines) {
      final match = RegExp(r'^\s*ScriptVariant\s+([A-Za-z_][A-Za-z0-9_]*)\s*$').firstMatch(line);
      if (match != null) variants.add(match.group(1)!);
    }
    final headers = lines.map((line) => RegExp(r'^\s*ScriptHeader\s+(\d+)\s*$').firstMatch(line))
        .whereType<RegExpMatch>().toList();
    if (variants.isEmpty || variants.length > 32 || variants.toSet().length != variants.length ||
        headers.length != 1 || int.parse(headers.single.group(1)!) != variants.length) {
      throw const FormatException('Invalid battle script variants');
    }
    final selected = <({String variant, List<String> body, bool labels})>[];
    for (final variant in variants) {
      final start = lines.indexWhere((line) => line.trim() == '$variant:');
      if (start < 0) throw const FormatException('Missing battle script variant');
      final body = <String>[];
      var labels = false;
      var ended = false;
      for (var i = start + 1; i < lines.length; i++) {
        final line = lines[i].split('//').first.trim();
        if (line.isEmpty) continue;
        if (line.endsWith(':')) {
          if (variants.contains(line.substring(0, line.length - 1))) break;
          labels = true;
          continue;
        }
        if (line == 'End') { ended = true; break; }
        if (line.startsWith('.') || line.startsWith('#')) {
          throw const FormatException('Unsupported battle script directive');
        }
        body.add(line);
      }
      if (ended) selected.add((variant: variant, body: body, labels: labels));
    }
    if (selected.isEmpty) throw const FormatException('Incomplete battle script');
    final visible = selected.where((item) => item.body.any((line) => line.startsWith('ParticleLoad ')) &&
        item.body.any((line) => line.startsWith('EmitterAdd ') || line.startsWith('EmitterMove ') || line.startsWith('EmitterAddOrtho ')));
    final choice = visible.isEmpty ? selected.first : visible.first;
    final normalized = Uint8List.fromList(utf8.encode([
      '#include "asm/btlv_effvm.inc"', 'ScriptHeader 1', 'ScriptVariant ${choice.variant}',
      '${choice.variant}:', ...choice.body, 'End',
    ].join('\n')));
    final script = Gen5BattleScriptSource.read(normalized, sourceRevision: sourceRevision,
      sourcePath: sourcePath, expectedSha256: sha256.convert(normalized).toString());
    return Gen5SelectedScript(script, {
      if (variants.length > 1) 'script-variants-not-transcribed',
      if (variants.length > 1) 'script-selected-variant:${choice.variant}',
      if (choice.labels) 'script-internal-labels-not-transcribed',
      if (errorHasTrailingContent(lines, choice.variant)) 'script-content-after-end-not-transcribed',
    });
  }

  static bool errorHasTrailingContent(List<String> lines, String variant) {
    final start = lines.indexWhere((line) => line.trim() == '$variant:');
    if (start < 0) return false;
    final end = lines.indexWhere((line) => line.split('//').first.trim() == 'End', start + 1);
    if (end < 0) return false;
    return lines.skip(end + 1).any((line) {
      final text = line.split('//').first.trim();
      return text.isNotEmpty && !text.startsWith('.balign') && !text.endsWith(':');
    });
  }
}
