import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'gen5_battle_script_commands.dart';

abstract final class Gen5SourceProgramConverter {
  static const sourceRevision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';

  static final _path =
      RegExp(r'^res/battle/animations/moves/[a-z0-9_]{1,120}\.s$');
  static final _digest = RegExp(r'^[0-9a-f]{64}$');
  static final _identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$');
  static final _instruction =
      RegExp(r'^([A-Za-z_][A-Za-z0-9_]{0,63})(?:[ \t]+(.*))?$');
  static final _operand =
      RegExp(r'^(?:[A-Za-z_][A-Za-z0-9_]*|-?(?:0[xX][0-9a-fA-F]+|[0-9]+))$');
  static final _number = RegExp(r'^-?(?:0[xX][0-9a-fA-F]+|[0-9]+)$');
  static final _sound = RegExp(r'^SEQ_SE_[A-Za-z0-9_]+$');

  static const _operations = <String, String>{
    'CameraMovePreset': 'moveCameraPreset',
    'CameraShake': 'shakeCamera',
    'ParticleLoad': 'loadParticle',
    'EmitterAdd': 'startEmitter',
    'EmitterMove': 'startMovingEmitter',
    'McssMoveXY': 'moveCombatant',
    'McssScale': 'scaleCombatant',
    'McssSetVanish': 'setAnimationState',
    'McssPalFade': 'fadePalette',
    'McssSetValue': 'setShadow',
    'PlaySE': 'playSound',
    'PanSE': 'panSound',
    'MoveSE': 'moveSound',
    'Wait': 'waitTasks',
    'WaitFrames': 'waitFrames',
    'SetYield': 'setYield',
    'End': 'end',
  };

  static const _waitKinds = <String, String>{
    'EFFVM_WAIT_ALL': 'ALL',
    'EFFVM_WAIT_CAMERA': 'CAMERA',
    'EFFVM_WAIT_PARTICLES': 'PARTICLES',
    'EFFVM_WAIT_MCSS': 'MCSS',
    'EFFVM_WAIT_SE': 'SE',
  };

  static const _targets = {'EFFVM_ATTACKER', 'EFFVM_DEFENDER', 'EFFVM_ALL'};
  static const _combatants = {'EFFVM_ATTACKER', 'EFFVM_DEFENDER'};
  static const _emitterPositions = {
    'EFFVM_EMIT_ATTACKER',
    'EFFVM_EMIT_DEFENDER'
  };

  static const _unsignedFields = <String, Set<String>>{
    'ParticleLoad': {'particle'},
    'EmitterAdd': {'particle', 'from', 'to', 'unk18', 'unused'},
    'EmitterMove': {'particle', 'motion', 'from', 'to'},
    'McssPalFade': {'color'},
    'PlaySE': {'se', 'player'},
    'PanSE': {'player', 'type'},
    'MoveSE': {'player', 'type', 'param'},
    'Wait': {'what'},
  };

  static Map<String, Object?> convert(
    Uint8List bytes, {
    required String sourceRevision,
    required String sourcePath,
    required String expectedSha256,
    required String variant,
  }) {
    if (sourceRevision != Gen5SourceProgramConverter.sourceRevision ||
        !_path.hasMatch(sourcePath) ||
        !_digest.hasMatch(expectedSha256) ||
        bytes.isEmpty ||
        bytes.length > 64 * 1024 ||
        sha256.convert(bytes).toString() != expectedSha256 ||
        (bytes.length >= 3 &&
            bytes[0] == 0xef &&
            bytes[1] == 0xbb &&
            bytes[2] == 0xbf)) {
      throw const FormatException('Invalid battle script source identity');
    }
    final lines = const LineSplitter().convert(utf8.decode(bytes));
    if (lines.length > 2048) {
      throw const FormatException('Too many source lines');
    }
    var included = false;
    int? headerCount;
    var bodyStarted = false;
    var aligned = false;
    final variants = <String>[];
    final labels = <Map<String, Object>>[];
    final instructions = <_SourceInstruction>[];
    for (var index = 0; index < lines.length; index++) {
      final original = lines[index];
      if (original.length > 512) {
        throw const FormatException('Source line is too long');
      }
      final line = original.split('//').first.trim();
      if (line.isEmpty) continue;
      if (aligned) throw const FormatException('Content after alignment');
      if (line.startsWith('#')) {
        if (included ||
            headerCount != null ||
            line != '#include "asm/btlv_effvm.inc"') {
          throw const FormatException('Unsupported source directive');
        }
        included = true;
        continue;
      }
      if (line == '.balign 4') {
        if (instructions.isEmpty || instructions.last.name != 'End') {
          throw const FormatException('Invalid source alignment');
        }
        aligned = true;
        continue;
      }
      if (line.endsWith(':')) {
        final name = line.substring(0, line.length - 1).trim();
        if (headerCount == null ||
            variants.length != headerCount ||
            !_identifier.hasMatch(name) ||
            labels.any((label) => label['name'] == name) ||
            labels.length >= 1024) {
          throw const FormatException('Invalid source label');
        }
        bodyStarted = true;
        labels.add({
          'name': name,
          'instructionIndex': instructions.length,
          'line': index + 1
        });
        continue;
      }
      final match = _instruction.firstMatch(line);
      if (match == null) {
        throw const FormatException('Invalid source instruction');
      }
      final name = match.group(1)!;
      final operandText = match.group(2)?.trim() ?? '';
      if (name == 'ScriptHeader') {
        final count = int.tryParse(operandText);
        if (!included ||
            headerCount != null ||
            count == null ||
            count < 1 ||
            count > 32) {
          throw const FormatException('Invalid source header');
        }
        headerCount = count;
        continue;
      }
      if (name == 'ScriptVariant') {
        if (headerCount == null ||
            bodyStarted ||
            variants.length >= headerCount ||
            !_identifier.hasMatch(operandText) ||
            variants.contains(operandText)) {
          throw const FormatException('Invalid source variant');
        }
        variants.add(operandText);
        continue;
      }
      if (!bodyStarted || instructions.length >= 1024) {
        throw const FormatException('Invalid source instruction position');
      }
      final operands = operandText.isEmpty
          ? <String>[]
          : operandText.split(',').map((value) => value.trim()).toList();
      if (operands.length > 64 ||
          operands
              .any((value) => value.length > 64 || !_operand.hasMatch(value)) ||
          (name == 'End' && operands.isNotEmpty)) {
        throw const FormatException('Invalid source operands');
      }
      instructions.add(_SourceInstruction(name, operands, index + 1));
    }
    if (!included ||
        headerCount == null ||
        variants.length != headerCount ||
        instructions.isEmpty ||
        !instructions.any((item) => item.name == 'End') ||
        variants.any((name) => !labels.any((label) => label['name'] == name))) {
      throw const FormatException('Incomplete source document');
    }
    if (!variants.contains(variant)) {
      throw const FormatException('Unknown source variant');
    }
    final entry = labels
        .firstWhere((label) => label['name'] == variant)['instructionIndex']!;
    final diagnostics = <Map<String, Object>>[];
    final variantLabels =
        labels.where((label) => variants.contains(label['name'])).toList();
    for (final label in variantLabels) {
      final start = label['instructionIndex']! as int;
      var end = instructions.length;
      for (final next in variantLabels) {
        final nextIndex = next['instructionIndex']! as int;
        if (nextIndex > start && nextIndex < end) end = nextIndex;
      }
      if (!instructions.sublist(start, end).any((item) => item.name == 'End')) {
        diagnostics.add({
          'instructionIndex': start,
          'line': label['line']!,
          'code': 'missingVariantEnd',
          'variant': label['name']!,
        });
      }
    }
    final translated = <Map<String, Object?>>[];
    for (var index = 0; index < instructions.length; index++) {
      final item = instructions[index];
      final original = <String, Object>{
        'index': index,
        'line': item.line,
        'name': item.name,
        'operands': item.operands,
      };
      try {
        final operation = _operations[item.name];
        final fields = gen5BattleCommandFields[item.name];
        if (operation == null) throw const FormatException('unsupportedOpcode');
        if (fields == null || fields.length != item.operands.length) {
          throw const FormatException('invalidArity');
        }
        final args = <String, Object>{
          for (var i = 0; i < fields.length; i++)
            fields[i]: _value(item.operands[i]),
        };
        _normalize(item.name, args);
        translated.add({'op': operation, 'source': original, 'args': args});
      } on FormatException catch (error) {
        diagnostics.add({
          'instructionIndex': index,
          'line': item.line,
          'code': error.message
        });
        translated.add({
          'op': 'unsupported',
          'source': original,
          'args': <String, Object>{}
        });
      }
    }
    return {
      'kind': 'gen5SourceProgram',
      'timebaseHz': 60,
      'source': {
        'revision': sourceRevision,
        'path': sourcePath,
        'sha256': expectedSha256
      },
      'variants': variants,
      'labels': labels,
      'variant': variant,
      'entryIndex': entry,
      'conversion': diagnostics.isEmpty ? 'supported' : 'unsupported',
      'verification': 'sourceTranscriptionOnly',
      'diagnostics': diagnostics,
      'instructions': translated,
    };
  }

  static Object _value(String raw) {
    if (!_number.hasMatch(raw)) return raw;
    final negative = raw.startsWith('-');
    final magnitude = negative ? raw.substring(1) : raw;
    final hex = magnitude.startsWith('0x') || magnitude.startsWith('0X');
    final parsed = BigInt.parse(hex ? magnitude.substring(2) : magnitude,
        radix: hex ? 16 : 10);
    final value = negative ? -parsed : parsed;
    if (value < BigInt.from(-2147483648) || value > BigInt.from(4294967295)) {
      throw const FormatException('operandOutOfRange');
    }
    return value.toInt();
  }

  static void _normalize(String name, Map<String, Object> args) {
    void require(bool valid) {
      if (!valid) throw const FormatException('unsupportedOperand');
    }

    bool numeric(String field) => args[field] is int;
    bool bounded(String field, int min, int max) =>
        args[field] is int &&
        (args[field] as int) >= min &&
        (args[field] as int) <= max;
    bool inSet(String field, Set<Object> allowed) =>
        allowed.contains(args[field]);
    void requireNumericExcept(Set<String> excluded) {
      require(args.keys.where((key) => !excluded.contains(key)).every(numeric));
    }

    final unsigned = _unsignedFields[name] ?? const <String>{};
    for (final field in args.keys) {
      final rawValue = args[field];
      if (rawValue is! int) continue;
      final word = rawValue < 0 ? rawValue + 4294967296 : rawValue;
      args[field] = unsigned.contains(field) || word < 2147483648
          ? word
          : word - 4294967296;
    }

    bool boundedTiming(String field) => bounded(field, 0, 60000);

    switch (name) {
      case 'CameraMovePreset':
        requireNumericExcept({});
        require(args['moveType'] == 1 && inSet('camera', {8, 9, 11, 20}));
        require(boundedTiming('frames') &&
            boundedTiming('wait') &&
            boundedTiming('brake'));
      case 'CameraShake':
        requireNumericExcept({});
        require(args['direction'] == 0 &&
            boundedTiming('frames') &&
            boundedTiming('wait') &&
            boundedTiming('count'));
      case 'ParticleLoad':
        require(bounded('particle', 0, 65535));
      case 'EmitterAdd':
        requireNumericExcept({'from', 'to'});
        require(bounded('particle', 0, 65535) && bounded('emitter', 0, 31));
        require(inSet('from', _emitterPositions) &&
            (args['to'] == 8 || inSet('to', _emitterPositions)));
        require(args['unk18'] == 0 && args['unused'] == 0);
        require(['radiusScale', 'lifeScale', 'scaleScale', 'cameraScale']
            .every((field) => bounded(field, 0, 2147483647)));
      case 'EmitterMove':
        requireNumericExcept({'from', 'to'});
        require(bounded('particle', 0, 65535) && bounded('emitter', 0, 31));
        require(args['motion'] == 1 &&
            inSet('from', _emitterPositions) &&
            inSet('to', _emitterPositions));
        require(bounded('frames', 4096, 2147483647));
        require(['lifeScale', 'cameraScale', 'turns']
            .every((field) => bounded(field, 0, 2147483647)));
        final frames = args.remove('frames') as int;
        args['motionFramesFx32'] = frames;
        args['motionFrames'] = frames >> 12;
      case 'McssMoveXY' || 'McssScale':
        requireNumericExcept({'targets'});
        require(inSet('targets', _targets) &&
            args['type'] == 2 &&
            bounded('x', -65536, 65536) &&
            bounded('y', -65536, 65536) &&
            bounded('frames', 1, 600) &&
            bounded('wait', 0, 600) &&
            bounded('times', 1, 32));
        final frames = args['frames'] as int;
        final wait = args['wait'] as int;
        final times = args['times'] as int;
        require(frames * 2 * times * (wait + 1) - wait <= 1800);
        if (name == 'McssScale') {
          bool validScale(String field) {
            final value = args[field] as int;
            final step =
                (((value * 1048576) ~/ frames + 524288) / 1048576).floor();
            final peak = step * frames;
            return value >= -4095 &&
                value <= 28672 &&
                peak >= -4095 &&
                peak <= 28672;
          }

          require(validScale('x') && validScale('y'));
        }
      case 'McssSetVanish':
        require(inSet('targets', _targets));
        final value = args.remove('vanish');
        args['mode'] = switch (value) {
          'FALSE' || 0 => 0,
          'TRUE' || 1 => 1,
          _ => throw const FormatException('unsupportedOperand'),
        };
      case 'McssPalFade':
        requireNumericExcept({'targets'});
        require(inSet('targets', _targets) &&
            bounded('startEvy', 0, 16) &&
            bounded('endEvy', 0, 16) &&
            boundedTiming('wait') &&
            bounded('color', 0, 32767));
      case 'McssSetValue':
        require(inSet('targets', _targets) && inSet('value', {0, 1}));
      case 'PlaySE':
        requireNumericExcept({'se', 'pan'});
        require(args['se'] is String && _sound.hasMatch(args['se'] as String));
        require(inSet('pan', _combatants) &&
            inSet('player', {1, 2}) &&
            boundedTiming('wait') &&
            bounded('pitch', -32768, 32767) &&
            bounded('volume', 0, 127) &&
            bounded('modDepth', 0, 127) &&
            bounded('modSpeed', 0, 127) &&
            args['unused'] == 0);
      case 'PanSE':
        requireNumericExcept({'from', 'to'});
        require(args['type'] == 0 &&
            inSet('player', {1, 2}) &&
            inSet('from', _combatants) &&
            inSet('to', _combatants) &&
            boundedTiming('delay') &&
            bounded('frames', 1, 60000) &&
            boundedTiming('stepWait') &&
            boundedTiming('count'));
      case 'MoveSE':
        requireNumericExcept({});
        require(args['type'] == 0 &&
            args['param'] == 1 &&
            inSet('player', {1, 2}) &&
            bounded('start', 0, 127) &&
            bounded('end', 0, 127) &&
            boundedTiming('delay') &&
            bounded('frames', 1, 60000) &&
            boundedTiming('stepWait') &&
            boundedTiming('count'));
      case 'Wait':
        final kind = _waitKinds[args['what']];
        require(kind != null);
        args['what'] = kind!;
      case 'WaitFrames':
        require(bounded('frames', 0, 60000));
      case 'SetYield':
        final value = args.remove('yield');
        args['value'] = switch (value) {
          'FALSE' || 0 => false,
          'TRUE' || 1 => true,
          _ => throw const FormatException('unsupportedOperand'),
        };
      case 'End':
        break;
      default:
        throw const FormatException('unsupportedOpcode');
    }
  }
}

final class _SourceInstruction {
  const _SourceInstruction(this.name, this.operands, this.line);

  final String name;
  final List<String> operands;
  final int line;
}
