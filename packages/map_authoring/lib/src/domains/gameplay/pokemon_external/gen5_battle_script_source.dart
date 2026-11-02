import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final class Gen5BattleScriptInstruction {
  Gen5BattleScriptInstruction({
    required this.name,
    required List<String> arguments,
    required this.line,
  }) : arguments = List.unmodifiable(arguments);

  final String name;
  final List<String> arguments;
  final int line;
}

final class Gen5BattleScriptSource {
  Gen5BattleScriptSource._({
    required this.sourceRevision,
    required this.sourcePath,
    required this.sha256Hex,
    required this.variant,
    required List<Gen5BattleScriptInstruction> instructions,
  }) : instructions = List.unmodifiable(instructions);

  final String sourceRevision;
  final String sourcePath;
  final String sha256Hex;
  final String variant;
  final List<Gen5BattleScriptInstruction> instructions;

  static final _revisionPattern = RegExp(r'^[0-9a-f]{40}$');
  static final _digestPattern = RegExp(r'^[0-9a-f]{64}$');
  static final _pathPattern = RegExp(
    r'^res/battle/animations/moves/[a-z0-9_]{1,120}\.s$',
  );
  static final _identifierPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$');
  static final _instructionPattern = RegExp(
    r'^([A-Za-z_][A-Za-z0-9_]{0,63})(?:[ \t]+(.*))?$',
  );
  static final _operandPattern = RegExp(
    r'^(?:[A-Za-z_][A-Za-z0-9_]*|-?(?:0[xX][0-9a-fA-F]+|[0-9]+))$',
  );

  static Gen5BattleScriptSource read(
    Uint8List bytes, {
    required String sourceRevision,
    required String sourcePath,
    required String expectedSha256,
  }) {
    if (bytes.isEmpty ||
        bytes.length > 64 * 1024 ||
        !_revisionPattern.hasMatch(sourceRevision) ||
        !_pathPattern.hasMatch(sourcePath) ||
        !_digestPattern.hasMatch(expectedSha256) ||
        sha256.convert(bytes).toString() != expectedSha256 ||
        (bytes.length >= 3 &&
            bytes[0] == 0xef &&
            bytes[1] == 0xbb &&
            bytes[2] == 0xbf)) {
      throw const FormatException('Invalid battle script source');
    }
    final text = utf8.decode(bytes);
    final lines = const LineSplitter().convert(text);
    if (lines.length > 2048) {
      throw const FormatException('Battle script has too many lines');
    }
    var includeSeen = false;
    var headerSeen = false;
    String? variant;
    var labelSeen = false;
    var ended = false;
    var alignmentSeen = false;
    final instructions = <Gen5BattleScriptInstruction>[];
    for (var index = 0; index < lines.length; index++) {
      final raw = lines[index];
      if (raw.length > 512) {
        throw const FormatException('Battle script line is too long');
      }
      final line = raw.split('//').first.trim();
      if (line.isEmpty) continue;
      if (ended) {
        if (!alignmentSeen && line == '.balign 4') {
          alignmentSeen = true;
          continue;
        }
        throw const FormatException('Content after battle script end');
      }
      if (line.startsWith('#')) {
        if (includeSeen ||
            headerSeen ||
            line != '#include "asm/btlv_effvm.inc"') {
          throw const FormatException('Unsupported battle script directive');
        }
        includeSeen = true;
        continue;
      }
      if (line.endsWith(':')) {
        final label = line.substring(0, line.length - 1).trim();
        if (!headerSeen ||
            variant == null ||
            labelSeen ||
            !_identifierPattern.hasMatch(label) ||
            label != variant) {
          throw const FormatException('Invalid battle script label');
        }
        labelSeen = true;
        continue;
      }
      final match = _instructionPattern.firstMatch(line);
      if (match == null) {
        throw const FormatException('Invalid battle script instruction');
      }
      final name = match.group(1)!;
      final operandText = match.group(2)?.trim() ?? '';
      if (name == 'ScriptHeader') {
        if (headerSeen || variant != null || labelSeen || operandText != '1') {
          throw const FormatException('Unsupported battle script header');
        }
        headerSeen = true;
        continue;
      }
      if (name == 'ScriptVariant') {
        if (!headerSeen ||
            variant != null ||
            labelSeen ||
            !_identifierPattern.hasMatch(operandText)) {
          throw const FormatException('Invalid battle script variant');
        }
        variant = operandText;
        continue;
      }
      if (!labelSeen) {
        throw const FormatException('Battle script instruction before label');
      }
      final arguments = operandText.isEmpty
          ? <String>[]
          : operandText.split(',').map((value) => value.trim()).toList();
      if (arguments.length > 64 ||
          arguments.any(
            (value) => value.length > 64 || !_operandPattern.hasMatch(value),
          ) ||
          (name == 'End' && arguments.isNotEmpty)) {
        throw const FormatException('Invalid battle script operands');
      }
      if (instructions.length >= 1024) {
        throw const FormatException('Battle script has too many instructions');
      }
      instructions.add(
        Gen5BattleScriptInstruction(
          name: name,
          arguments: arguments,
          line: index + 1,
        ),
      );
      if (name == 'End') ended = true;
    }
    if (!headerSeen || variant == null || !labelSeen || !ended) {
      throw const FormatException('Incomplete battle script');
    }
    return Gen5BattleScriptSource._(
      sourceRevision: sourceRevision,
      sourcePath: sourcePath,
      sha256Hex: expectedSha256,
      variant: variant,
      instructions: instructions,
    );
  }
}
