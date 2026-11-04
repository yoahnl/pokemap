import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_particle_approximation.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_background_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_spl_particle_converter.dart';
import 'package:map_core/map_core.dart' show BattleSplParticleDefinition;

import 'gen5_workshop_texture_baker.dart';

const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const root = 'https://raw.githubusercontent.com/fuddlesworth/pokebw2/$revision';

bool admitted(List<Map<String, dynamic>> instructions) {
  bool bounded(Object? value, int min, int max) =>
      value is int && value >= min && value <= max;
  const actors = {'EFFVM_ATTACKER', 'EFFVM_DEFENDER'};
  const anchors = {'EFFVM_EMIT_ATTACKER', 'EFFVM_EMIT_DEFENDER'};
  for (final item in instructions) {
    final op = item['op'];
    final a = item['args'] as Map<String, dynamic>;
    switch (op) {
      case 'moveCameraPreset':
        if (a['moveType'] != 1 ||
            !{0, 1, 8, 9, 10, 11, 12, 14, 15, 16, 17, 20, 21}.contains(a['camera'])) {
          return false;
        }
      case 'moveCameraRelative' || 'moveCameraAbsolute':
        if (a['moveType'] != (op == 'moveCameraAbsolute' ? 1 : 2) ||
            !['x', 'y', 'z', 'targetX', 'targetY', 'targetZ']
                .every((field) => bounded(a[field], -131072, 131072)) ||
            !bounded(a['frames'], 1, 600) || !bounded(a['wait'], 0, 600) ||
            !bounded(a['brake'], 0, 600)) {
          return false;
        }
      case 'shakeCamera':
        if (!{0, 1}.contains(a['direction']) ||
            !bounded(a['frames'], 1, 600) ||
            !bounded(a['amplitude'], -28672, 28672) ||
            !bounded(a['wait'], 0, 600) ||
            !bounded(a['count'], 1, 64) ||
            (a['frames'] as int) * 4 * (a['count'] as int) *
                    ((a['wait'] as int) + 1) - (a['wait'] as int) > 1800) {
          return false;
        }
      case 'moveCombatant' || 'scaleCombatant':
        final scaleStep = op == 'scaleCombatant' && a['type'] == 1;
        final positionStep = op == 'moveCombatant' &&
            (a['type'] == 1 || a['type'] == 5);
        final step = scaleStep || positionStep;
        final minCoordinate = scaleStep ? 1 : positionStep ? -131072 :
            op == 'moveCombatant' ? -65536 : -28672;
        final maxCoordinate = scaleStep ? 32768 : positionStep ? 131072 :
            op == 'moveCombatant' ? 65536 : 28672;
        if (!(a['targets'] == 'EFFVM_ALL' || actors.contains(a['targets'])) ||
            !(step || a['type'] == 2 || a['type'] == 3) ||
            !bounded(a['x'], minCoordinate, maxCoordinate) ||
            !bounded(a['y'], minCoordinate, maxCoordinate) ||
            !bounded(a['frames'], positionStep ? 0 : 1, 600) ||
            !bounded(a['wait'], 0, 600) ||
            !bounded(a['times'], step ? 0 : 1, step ? 32 : 64)) {
          return false;
        }
        if (step && (a['frames'] as int) * ((a['wait'] as int) + 1) > 900) {
          return false;
        }
        if (a['type'] == 3) {
          final frames = a['frames'] as int;
          final wait = a['wait'] as int;
          final times = a['times'] as int;
          if (times > 32 || frames * 4 * times * (wait + 1) - wait > 1800) {
            return false;
          }
          if (op != 'scaleCombatant') break;
          bool validShake(Object? value) {
            if (!bounded(value, -4095, 4095)) return false;
            final step = (((value as int) * 1048576 ~/ frames + 524288) /
                    1048576)
                .floor();
            return (step * frames).abs() <= 4095;
          }
          if (!validShake(a['x']) || !validShake(a['y'])) {
            return false;
          }
        }
      case 'circleCombatant':
        if (!actors.contains(a['targets']) ||
            !bounded(a['mode'], 0, 5) ||
            !bounded(a['start'], 0, 3) ||
            !bounded(a['radius1'], -32768, 32768) ||
            !bounded(a['radius2'], -32768, 32768) ||
            !bounded(a['frames'], 1, 600) ||
            !bounded(a['wait'], 0, 600) ||
            !bounded(a['count'], 1, 32) ||
            !bounded(a['turnWait'], 0, 600)) {
          return false;
        }
        final frames = a['frames'] as int;
        final wait = a['wait'] as int;
        final count = a['count'] as int;
        final speed = 65536 ~/ frames;
        if ((65536 ~/ speed + 1) * count * (wait + 1) +
                (count - 1) * (a['turnWait'] as int) >
            1800) return false;
      case 'rotateCombatant':
        if (!actors.contains(a['targets']) ||
            !{1, 2, 3}.contains(a['type']) ||
            !bounded(a['angle'], -268435456, 268435456) ||
            !bounded(a['frames'], 1, 600) ||
            !bounded(a['wait'], 0, 600) ||
            !bounded(a['times'], a['type'] == 1 ? 0 : 1, 32) ||
            (a['type'] == 1
                ? (a['frames'] as int) * ((a['wait'] as int) + 1)
                : (a['frames'] as int) * (a['type'] == 3 ? 4 : 2) *
                    (a['times'] as int) * ((a['wait'] as int) + 1) -
                    (a['wait'] as int)) > 1800) {
          return false;
        }
      case 'setAnimationState' || 'fadePalette':
        if (!(a['targets'] == 'EFFVM_ALL' || actors.contains(a['targets']))) {
          return false;
        }
      case 'setActorCameraMode':
        if (a['mode'] != 0 || a['scope'] != 0) return false;
      case 'setCombatantVisibility':
        if (!actors.contains(a['targets']) || !{3, 4}.contains(a['mode'])) {
          return false;
        }
      case 'fadeCombatantAlpha':
        if (!actors.contains(a['targets']) || !{0, 1, 2}.contains(a['type']) ||
            (a['type'] == 2 && a['times'] != 0) ||
            !bounded(a['alpha'], 0, 31) ||
            !bounded(a['frames'], a['type'] == 0 ? 0 : 1, 600) ||
            !bounded(a['wait'], 0, 600) || !bounded(a['times'], 0, 32) ||
            (a['frames'] as int) * ((a['wait'] as int) + 1) > 1800) {
          return false;
        }
      case 'startEmitter':
        if (!(a['from'] == 0 || anchors.contains(a['from'])) ||
            !(a['to'] == 8 || anchors.contains(a['to'])) ||
            !bounded(a['unk18'], 0, 4294967295) ||
            !bounded(a['unused'], 0, 4294967295) ||
            !bounded(a['radiusScale'], 0, 8192) ||
            !bounded(a['lifeScale'], 0, 12288) ||
            !bounded(a['scaleScale'], 0, 20480) ||
            !bounded(a['cameraScale'], 0, 12288)) {
          return false;
        }
      case 'startFieldEmitter':
        if (!['fromX', 'fromY', 'fromZ', 'toX', 'toY', 'toZ', 'offsetY']
                .every((field) => bounded(a[field], -131072, 131072)) ||
            !bounded(a['unk18'], 0, 4294967295) ||
            !bounded(a['unused'], 0, 4294967295) ||
            !bounded(a['radiusScale'], 0, 8192) ||
            !bounded(a['lifeScale'], 0, 12288) ||
            !bounded(a['scaleScale'], 0, 12288) ||
            !{0, 4096}.contains(a['cameraScale'])) {
          return false;
        }
      case 'startOrthoEmitter':
        final unscaled = a['from'] == 0 || a['from'] == 'EFFVM_EMIT_ATTACKER';
        if (!(a['from'] == 0 || anchors.contains(a['from'])) ||
            !(a['to'] == 8 || anchors.contains(a['to'])) ||
            !bounded(a['offsetX'], -65536, 65536) ||
            !bounded(a['offsetY'], -65536, 65536) ||
            !bounded(a['offsetZ'], -65536, 65536) ||
            !bounded(a['radiusScale'], 0, 8192) ||
            !bounded(a['lifeScale'], 0, 8192) ||
            !bounded(a['scaleScale'], 0, 8192) ||
            !bounded(a['cameraScale'], 0, 8192) ||
            (!unscaled && !{0, 4096}.contains(a['cameraScale']))) {
          return false;
        }
      case 'startOrbitEmitter':
        if (!bounded(a['particle'], 0, 65535) ||
            !bounded(a['emitter'], 0, 31) || !bounded(a['type'], 0, 3) ||
            !bounded(a['radiusX'], -32768, 32768) ||
            !bounded(a['radiusZ'], -32768, 32768) ||
            !bounded(a['offsetY'], -131072, 131072) ||
            !bounded(a['frames'], 1, 600) || !bounded(a['wait'], 0, 600) ||
            !bounded(a['unknown'], 0, 600) || !bounded(a['delay'], 0, 600)) {
          return false;
        }
      case 'setSourceGauge':
        if (!{2, 3}.contains(a['mode']) || !{3, 4}.contains(a['target'])) {
          return false;
        }
      case 'startMovingEmitter' || 'startMovingOrthoEmitter':
        if (!anchors.contains(a['from']) ||
            !anchors.contains(a['to']) ||
            a['from'] == a['to'] ||
            !{1, 2, 5, 6}.contains(a['motion']) ||
            ({5, 6}.contains(a['motion']) && !bounded(a['turns'], 0, 32768)) ||
            !bounded(a['lifeScale'], 0, 8192) ||
            !{0, 4096}.contains(a['cameraScale']) ||
            !(a['motionFramesFx32'] == 0 ||
                bounded(a['motionFramesFx32'], 4096, 600 * 4096))) {
          return false;
        }
      case 'startMovingFieldEmitter':
        if (!['fromX', 'fromY', 'fromZ']
                .every((field) => bounded(a[field], -131072, 131072)) ||
            !anchors.contains(a['to']) ||
            !{1, 2, 5, 6}.contains(a['motion']) ||
            ({5, 6}.contains(a['motion']) && !bounded(a['turns'], 0, 32768)) ||
            !bounded(a['lifeScale'], 0, 8192) ||
            !{0, 4096, 8192}.contains(a['cameraScale']) ||
            !(a['motionFramesFx32'] == 0 ||
                bounded(a['motionFramesFx32'], 4096, 600 * 4096))) {
          return false;
        }
      case 'loadBackground':
        if (!bounded(a['background'], 0, 65533)) return false;
      case 'moveBackground':
        if (!bounded(a['x'], -512, 512) || !bounded(a['y'], -512, 512)) {
          return false;
        }
        if (a['mode'] == 4) {
          if (!bounded(a['frames'], 0, 60000) ||
              !bounded(a['wait'], 0, 600) ||
              !bounded(a['count'], 0, 32)) {
            return false;
          }
        } else if (a['mode'] == 1) {
          if (!bounded(a['frames'], 1, 600) ||
              !bounded(a['wait'], 0, 600) ||
              !bounded(a['count'], 0, 32) ||
              (a['frames'] as int) * ((a['wait'] as int) + 1) > 1800) {
            return false;
          }
        } else if (a['mode'] == 2) {
          if (!bounded(a['frames'], 1, 600) ||
              !bounded(a['wait'], 0, 600) ||
              !bounded(a['count'], 1, 32) ||
              (a['frames'] as int) * 2 * (a['count'] as int) *
                      ((a['wait'] as int) + 1) - (a['wait'] as int) > 1800) {
            return false;
          }
        } else {
          return false;
        }
      case 'waveBackground':
        if (!{0, 1}.contains(a['mode']) ||
            !bounded(a['amplitude'], 0, 65536) ||
            !bounded(a['step'], 1, 360) ||
            !bounded(a['frames'], 1, 600) ||
            a['fadeMode'] != 0 || a['fadeFrames'] != 0) {
          return false;
        }
      case 'setSceneVisibility':
        if (!{0, 1, 2}.contains(a['target']) ||
            !{0, 1}.contains(a['hide'])) {
          return false;
        }
      case 'animateBackgroundPalette':
        if (!bounded(a['animation'], 0, 65534) || !bounded(a['loops'], 0, 32)) {
          return false;
        }
      case 'setShadow' ||
            'fadeStagePalette' ||
            'loadParticle' ||
            'deleteParticle' ||
            'playCry' ||
            'playSound' ||
            'panSound' ||
            'moveSound' ||
            'waitFrames' ||
            'waitTasks' ||
            'setYield' ||
            'end':
        break;
      default:
        return false;
    }
  }
  return true;
}

Future<Uint8List> fetch(HttpClient client, String path, int limit) async {
  final request = await client
      .getUrl(Uri.parse('$root/$path'))
      .timeout(const Duration(seconds: 20));
  final response = await request.close().timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw FormatException('HTTP ${response.statusCode}: $path');
  }
  final bytes = BytesBuilder(copy: false);
  await for (final part in response.timeout(const Duration(seconds: 20))) {
    bytes.add(part);
    if (bytes.length > limit) {
      throw FormatException('Resource too large: $path');
    }
  }
  return bytes.takeBytes();
}

String nameFor(Map move, String language, String fallback) {
  for (final name in (move['names'] as List? ?? const [])) {
    if ((name['language'] as Map?)?['name'] == language &&
        name['name'] is String) {
      return name['name'] as String;
    }
  }
  return fallback;
}

Map<String, Object?>? specializeWorkshopContext(Map<String, Object?> program) {
  final variant = program['variant'] as String;
  final variants = (program['variants'] as List).cast<String>();
  final labels = (program['labels'] as List).cast<Map>();
  final instructions = (program['instructions'] as List).cast<Map<String, dynamic>>();
  final entry = program['entryIndex'] as int;
  var end = instructions.length;
  for (final label in labels) {
    final index = label['instructionIndex'] as int;
    if (variants.contains(label['name']) && index > entry && index < end) {
      end = index;
    }
  }
  final variantLabel = labels.firstWhere((label) => label['name'] == variant);
  final selected = <Map<String, dynamic>>[];
  final visited = <int>{};
  var index = entry;
  final assumptions = <String>{};
  while (index < end && visited.add(index)) {
    var instruction = instructions[index];
    if (instruction['op'] == 'unsupported') {
      final source = instruction['source'] as Map;
      final operands = source['operands'] as List;
      if (source['name'] == 'Jump' && operands.length == 1) {
        final targets = labels.where((label) => label['name'] == operands[0]);
        if (targets.length != 1) return null;
        final target = targets.single['instructionIndex'] as int;
        if (target <= index || target >= end) return null;
        index = target;
        continue;
      }
      if (source['name'] != 'IfVarConst' || operands.length != 4) return null;
      final variable = operands[0];
      final comparison = operands[1];
      final value = operands[2];
      if (variable == 'EFFVM_VAR_ATTACKER_SIDE' &&
          comparison == 'EFFVM_CMP_EQ' && {'0', '1'}.contains(value)) {
        assumptions.add('player-side-only');
      } else if (variable == 'EFFVM_VAR_BATTLE_STYLE' &&
          {'EFFVM_CMP_EQ', 'EFFVM_CMP_NE'}.contains(comparison) &&
          {'0', '1', '2', '3'}.contains(value)) {
        assumptions.add('single-battle-only');
      } else {
        return null;
      }
      final targets = labels.where((label) => label['name'] == operands[3]);
      if (targets.length != 1) return null;
      final target = targets.single['instructionIndex'] as int;
      if (target <= index || target >= end) return null;
      final equal = value == '0';
      final shouldJump = comparison == 'EFFVM_CMP_EQ' ? equal : !equal;
      index = shouldJump ? target : index + 1;
      continue;
    }
    if ({'startEmitter', 'startMovingEmitter'}.contains(instruction['op'])) {
      final args = Map<String, dynamic>.from(instruction['args'] as Map);
      for (final key in ['from', 'to']) {
        final value = args[key];
        if (value == 0 || value == 1) {
          args[key] = value == 0 ? 'EFFVM_EMIT_ATTACKER' : 'EFFVM_EMIT_DEFENDER';
          assumptions.add('player-side-only');
        }
      }
      instruction = {...instruction, 'args': args};
    }
    selected.add(instruction);
    if (instruction['op'] == 'end') break;
    index++;
  }
  if (assumptions.isEmpty || selected.isEmpty || selected.last['op'] != 'end') {
    return null;
  }
  return {
    ...program,
    'variants': [variant],
    'labels': [
      {'name': variant, 'instructionIndex': 0, 'line': variantLabel['line']},
    ],
    'entryIndex': 0,
    'conversion': 'supported',
    'verification': 'sourceWorkshopContextSpecialization',
    'assumptions': assumptions.toList(),
    'diagnostics': <Object>[],
    'instructions': selected,
  };
}

Map<String, Object?>? selectSupportedVariant(Map<String, Object?> program) {
  final variant = program['variant'] as String;
  final variants = (program['variants'] as List).cast<String>();
  final labels = (program['labels'] as List).cast<Map>();
  final instructions =
      (program['instructions'] as List).cast<Map<String, dynamic>>();
  final entry = program['entryIndex'] as int;
  var limit = instructions.length;
  for (final label in labels) {
    final index = label['instructionIndex'] as int;
    if (variants.contains(label['name']) && index > entry && index < limit) {
      limit = index;
    }
  }
  var end = entry;
  while (end < limit && instructions[end]['op'] != 'end') {
    end++;
  }
  if (end == limit) return null;
  final diagnostics = (program['diagnostics'] as List).cast<Map>();
  if (diagnostics.any((diagnostic) {
    final index = diagnostic['instructionIndex'] as int;
    return index >= entry && index <= end;
  })) {
    return null;
  }
  final selected = instructions.sublist(entry, end + 1);
  if (!admitted(selected)) return null;
  return {
    ...program,
    'variants': [variant],
    'labels': [
      for (final label in labels)
        if ((label['instructionIndex'] as int) >= entry &&
            (label['instructionIndex'] as int) <= end)
          {...label.cast<String, Object?>(),
            'instructionIndex': (label['instructionIndex'] as int) - entry},
    ],
    'entryIndex': 0,
    'conversion': 'supported',
    'diagnostics': <Object>[],
    'instructions': selected,
  };
}

Future<Map<String, Object?>?> convert(
    Map document, Map move, HttpClient client,
    {Future<Uint8List> Function(String path, int limit)? fetchResource,
    String? selectedVariant}) async {
  Future<Uint8List> read(String path, int limit) =>
      fetchResource?.call(path, limit) ?? fetch(client, path, limit);
  final script = document['script'] as Map;
  final bytes = base64Decode(script['data'] as String);
  final source = utf8.decode(bytes);
  final variant = selectedVariant ?? RegExp(r'^\s*ScriptVariant\s+(\w+)', multiLine: true)
      .firstMatch(source)
      ?.group(1);
  if (variant == null) return null;
  var program = Gen5SourceProgramConverter.convert(bytes,
      sourceRevision: (document['source'] as Map)['revision'] as String,
      sourcePath: script['path'] as String,
      expectedSha256: script['sha256'] as String,
      variant: variant);
  final sourceVariantCount = (program['variants'] as List).length;
  if (program['conversion'] != 'supported') {
    var selected = specializeWorkshopContext(program);
    selected ??= selectSupportedVariant(program);
    if (selected == null) return null;
    program = selected;
  }
  final instructions =
      (program['instructions'] as List).cast<Map<String, dynamic>>();
  final selected = <Map<String, dynamic>>[];
  for (var index = program['entryIndex'] as int;
      index < instructions.length;
      index++) {
    selected.add(instructions[index]);
    if (instructions[index]['op'] == 'end') break;
  }
  if (!admitted(selected)) return null;
  final emitters = selected
      .where((item) =>
          item['op'] == 'startEmitter' || item['op'] == 'startMovingEmitter' ||
          item['op'] == 'startMovingFieldEmitter' || item['op'] == 'startOrbitEmitter' ||
          item['op'] == 'startMovingOrthoEmitter' ||
          item['op'] == 'startOrthoEmitter' || item['op'] == 'startFieldEmitter')
      .toList();
  if (emitters.length > 32) return null;
  final particleIds =
      emitters.map((item) => (item['args'] as Map)['particle'] as int).toSet();
  const actorOrSceneEffects = {
    'moveCombatant', 'scaleCombatant', 'rotateCombatant', 'circleCombatant',
    'fadePalette', 'fadeStagePalette', 'shakeCamera', 'loadBackground',
  };
  const cameraEffects = {'moveCameraPreset', 'moveCameraRelative', 'moveCameraAbsolute'};
  if (particleIds.isEmpty &&
      !selected.any((item) => actorOrSceneEffects.contains(item['op'])) &&
      !(selectedVariant != null && selected.any((item) => cameraEffects.contains(item['op'])))) {
    return null;
  }
  final particle = particleIds.length == 1 ? particleIds.single : null;
  final approximations = <String>{};
  if (selected.any((item) => item['op'] == 'moveCameraRelative')) {
    approximations.add('camera:relative-adapted-to-workshop');
  }
  if (selected.any((item) => item['op'] == 'moveCameraAbsolute')) {
    approximations.add('camera:absolute-adapted-to-workshop');
  }
  if (selected.any((item) => item['op'] == 'setActorCameraMode')) {
    approximations.add('source-actor:camera-mode-approximation');
  }
  if (selected.any((item) => item['op'] == 'scaleCombatant' &&
      ((item['args'] as Map)['x'] == -4096 || (item['args'] as Map)['y'] == -4096))) {
    approximations.add('source-actor:zero-scale-clamped');
  }
  for (final assumption in (program['assumptions'] as List? ?? const [])) {
    approximations.add('source-branch:$assumption');
  }
  if (selected.any((item) => item['op'] == 'setCombatantVisibility')) {
    approximations.add('actor-visibility:shadow-hidden');
  }
  if (selected.any((item) => item['op'] == 'moveCombatant' &&
      {1, 5}.contains((item['args'] as Map)['type']))) {
    approximations.add('actor-position:screen-space-approximation');
  }
  if (selected.any((item) => item['op'] == 'waitTasks' &&
      (item['args'] as Map)['what'] == 'SE_PLAYER_1')) {
    approximations.add('source-audio:channel-wait-uses-all-audio');
  }
  if (selected.any((item) => item['op'] == 'playCry')) {
    approximations.add('source-audio:cry-and-timing-unavailable');
  }
  if (selected.any((item) => item['op'] == 'setSourceGauge')) {
    approximations.add('source-gauge:preview-restored');
  }
  if (emitters.any((item) => item['op'] == 'startFieldEmitter')) {
    approximations.add('source-emitter:field-coordinate-calibration');
  }
  if (emitters.any((item) => item['op'] == 'startMovingFieldEmitter')) {
    approximations.add('source-emitter:field-motion-calibration');
  }
  if (emitters.any((item) => item['op'] == 'startOrbitEmitter')) {
    approximations.add('source-emitter:orbit-geometry-experimental');
  }
  if (emitters.any((item) => item['op'] == 'startMovingOrthoEmitter')) {
    approximations.add('particle-projection:orthographic-motion-experimental');
  }
  if (emitters.any((item) => item['op'] == 'startEmitter' &&
      !{0, 4096}.contains((item['args'] as Map)['cameraScale']))) {
    approximations.add('source-emitter:camera-position-scale-approximation');
  }
  if (emitters.any((item) => item['op'] == 'startMovingEmitter' &&
      {5, 6}.contains((item['args'] as Map)['motion']))) {
    approximations.add('particle-motion:sinusoid-phase-assumed');
  }
  if (emitters.any((item) => (item['args'] as Map)['from'] == 0)) {
    approximations.add('source-emitter:absolute-player-in-workshop');
  }
  if (emitters.any((item) => item['op'] == 'startOrthoEmitter' &&
      (item['args'] as Map)['to'] != 8 &&
      (item['args'] as Map)['to'] != (item['args'] as Map)['from'])) {
    approximations.add('source-emitter:orthographic-direction-approximation');
  }
  if (selected.any((item) => item['op'] == 'waitTasks' &&
      (item['args'] as Map)['what'] == 'STAGE_FIELD_FADE')) {
    approximations.add('source-fade:stage-field-shared-job');
  }
  if (sourceVariantCount > 1 && selectedVariant == null) {
    approximations.add('source-variant:first-only');
  }
  if (selected.any((item) => item['op'] == 'waveBackground')) {
    approximations.add('background-wave:trigonometry-experimental');
  }
  if (selected.any((item) => item['op'] == 'fadeStagePalette' &&
      (item['args'] as Map)['fade'] == 4)) {
    approximations.add('scene-palette-fade:layer-approximation');
  }
  final backgrounds = <String, String>{};
  final backgroundSourceHashes = <String, List<String>>{};
  final backgroundSources = <int, List<Uint8List>>{};
  final backgroundsWithMissingPalette = <int>{};
  final backgroundIds = selected
      .where((item) => item['op'] == 'loadBackground')
      .map((item) => (item['args'] as Map)['background'] as int)
      .toSet();
  for (final id in backgroundIds) {
    String file(int number, String extension) =>
        'res/graphics/btlv_effvm_bg/${number.toString().padLeft(3, '0')}.$extension';
    final sources = await Future.wait([
      read(file(id, 'nscr'), 1024 * 1024),
      read(file(id + 1, 'png'), 8 * 1024 * 1024),
      read(file(id + 2, 'pal'), 65536),
    ]);
    late final Uint8List png;
    try {
      png = Gen5BattleBackgroundConverter.convert(
        tileMap: sources[0], tilesPng: sources[1], palette: ascii.decode(sources[2]),
      );
    } on FormatException catch (error) {
      if (error.message != 'Background palette entry is missing') rethrow;
      png = Gen5BattleBackgroundConverter.convert(
        tileMap: sources[0], tilesPng: sources[1], palette: ascii.decode(sources[2]),
        allowMissingPalette: true,
      );
      approximations.add('background-palette:missing-bank-transparent');
      backgroundsWithMissingPalette.add(id);
    }
    backgroundSources[id] = sources;
    backgrounds['$id'] = base64Encode(png);
    backgroundSourceHashes['$id'] =
        sources.map((bytes) => sha256.convert(bytes).toString()).toList();
    approximations.add('background-palette-fade:layer-approximation');
  }
  final backgroundAnimations = <String, Object>{};
  final animationSourceHashes = <String, List<String>>{};
  final animationIds = selected
      .where((item) => item['op'] == 'animateBackgroundPalette')
      .map((item) => (item['args'] as Map)['animation'] as int)
      .toSet();
  if (animationIds.isNotEmpty && backgroundIds.length != 1) return null;
  for (final animationId in animationIds) {
    final backgroundId = backgroundIds.single;
    final sources = backgroundSources[backgroundId]!;
    String file(int number, String extension) =>
        'res/graphics/btlv_effvm_pal_anim/${number.toString().padLeft(2, '0')}.$extension';
    final animationSources = await Future.wait([
      read(file(animationId, 'bin'), 65536),
      read(file(animationId + 1, 'pal'), 65536),
    ]);
    ({List<Uint8List> frames, List<int> durations}) convertAnimation({
      bool allowMissingAnimationPalette = false,
    }) => Gen5BattleBackgroundConverter.convertPaletteAnimation(
      tileMap: sources[0], tilesPng: sources[1],
      basePalette: ascii.decode(sources[2]),
      animationSequence: animationSources[0],
      animationPalette: ascii.decode(animationSources[1]),
      allowMissingPalette: backgroundsWithMissingPalette.contains(backgroundId),
      allowMissingAnimationPalette: allowMissingAnimationPalette,
    );
    late final ({List<Uint8List> frames, List<int> durations}) animation;
    try {
      animation = convertAnimation();
    } on FormatException catch (error) {
      if (error.message != 'Background animation palette bank is missing') rethrow;
      animation = convertAnimation(allowMissingAnimationPalette: true);
      approximations.add('background-palette-animation:missing-bank-base');
    }
    backgroundAnimations['$animationId'] = {
      'background': backgroundId,
      'durations': animation.durations,
      'frames': animation.frames.map(base64Encode).toList(),
    };
    animationSourceHashes['$animationId'] = animationSources
        .map((bytes) => sha256.convert(bytes).toString()).toList();
    approximations.add('background-palette-animation:timing-experimental');
  }
  if (selected.any((item) => item['op'] == 'startOrthoEmitter')) {
    approximations.add('particle-projection:orthographic-experimental');
  }
  final particleGroups = <String, Map<String, Object?>>{};
  for (final id in particleIds) {
    final particleWarnings = <String>{};
    final indices = emitters
        .where((item) => (item['args'] as Map)['particle'] == id)
        .map((item) => (item['args'] as Map)['emitter'] as int)
        .toSet()
        .toList()
      ..sort();
    final directory = 'res/particles/btlv_effvm_particles/$id';
    final raw = await read('$directory/particles.json', 262144);
    final rawJson = jsonDecode(utf8.decode(raw)) as Map;
    final textureNames = (rawJson['textures'] as List)
        .map((entry) => (entry as Map)['name'] as String)
        .toList();
    Gen5SplParticleConversion convertParticle(Uint8List input) =>
        Gen5SplParticleConverter.convert(input,
            particleId: id,
            sourceRevision: revision,
            sourcePath: '$directory/particles.json',
            expectedSha256: sha256.convert(input).toString(),
            textureResourceIds: {for (final name in textureNames) name: name},
            experimentalSourceEmitterIndices: indices);
    late final Gen5SplParticleConversion particleDefinition;
    try {
      particleDefinition = convertParticle(raw);
    } on FormatException {
      final original = jsonDecode(jsonEncode(rawJson)) as Map<String, dynamic>;
      final allEmitters = original['emitters'] as List;
      Map<String, dynamic> selectedSource() => {
            ...original,
            'emitters': [for (final index in indices) allEmitters[index]],
          };
      final normalized = Gen5BatchParticleApproximation.normalize(
        selectedSource(),
        preserveExperimentalFeatures: true,
      );
      original['textures'] = normalized.document['textures'];
      for (var i = 0; i < indices.length; i++) {
        allEmitters[indices[i]] = (normalized.document['emitters'] as List)[i];
      }
      particleWarnings.addAll(normalized.warnings);
      try {
        particleDefinition = convertParticle(
            Uint8List.fromList(utf8.encode(jsonEncode(original))));
      } on FormatException catch (error) {
        if (!error.message.toString().contains('SPL child')) rethrow;
        final withoutChildren = Gen5BatchParticleApproximation.normalize(
            selectedSource(),
            omitChildren: true,
            preserveExperimentalFeatures: true);
        for (var i = 0; i < indices.length; i++) {
          allEmitters[indices[i]] =
              (withoutChildren.document['emitters'] as List)[i];
        }
        particleWarnings.addAll(withoutChildren.warnings);
        particleDefinition = convertParticle(
            Uint8List.fromList(utf8.encode(jsonEncode(original))));
      }
    }
    for (final item in emitters) {
      final args = item['args'] as Map;
      if (args['particle'] != id ||
          (item['op'] == 'startOrthoEmitter' &&
              (args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER'))) {
        continue;
      }
      final factor = args['scaleScale'] as int? ?? 0;
      if (factor == 0) continue;
      final emitter = particleDefinition.definition.emitters[
          indices.indexOf(args['emitter'] as int)].toJson();
      final appearance = emitter['appearance'] as Map;
      final emission = emitter['emission'] as Map;
      final scale = ((appearance['baseScale'] as int) * factor + 2048) >> 12;
      final variance = emission['scaleVariance'] as int;
      if (scale > 32767 || (scale * (255 + variance)) >> 8 > 32767) {
        approximations.add('source-emitter:scaled-size-clamped');
      }
    }
    final sourceTextures = <String, Uint8List>{};
    if (particleDefinition.definition.emitters.any(
        (emitter) => (emitter.toJson()['motion'] as Map).containsKey('spin'))) {
      approximations.add('particle-spin:trigonometry-experimental');
    }
    for (final texture in particleDefinition.definition.textureIds) {
      final png = await read('$directory/$texture.png', 8 * 1024 * 1024);
      sourceTextures[texture] = png;
    }
    final baked = Gen5WorkshopTextureBaker.bake(
      source: Map<String, dynamic>.from(rawJson),
      sourceEmitterIndices: indices,
      definition: particleDefinition.definition.toJson(),
      textures: sourceTextures,
    );
    BattleSplParticleDefinition.fromExperimentalJson(baked.definition);
    particleWarnings.removeAll({
      'texture-field:repeat', 'texture-field:flip',
      'particle-field:textureRepeatShiftS', 'particle-field:textureRepeatShiftT',
      'particle-field:flipTextureS', 'particle-field:flipTextureT',
    });
    final rawEmitters = rawJson['emitters'] as List;
    final bakedEmitters = baked.definition['emitters'] as List;
    final omittedChild = indices.indexed.any((entry) =>
        (rawEmitters[entry.$2] as Map)['childResource'] != null &&
        (bakedEmitters[entry.$1] as Map)['child'] == null);
    if (!omittedChild) {
      particleWarnings.removeAll({
        'particle-child:textureRepeatShiftS', 'particle-child:textureRepeatShiftT',
        'particle-child:flipTextureS', 'particle-child:flipTextureT',
      });
    }
    approximations.addAll(particleWarnings);
    particleGroups['$id'] = {
      'sourceParticleSha256': sha256.convert(raw).toString(),
      'sourceEmitterIndices': indices,
      'definition': baked.definition,
      'textureSha256': {
        for (final entry in baked.textures.entries)
          entry.key: sha256.convert(entry.value).toString(),
      },
      'textures': {
        for (final entry in baked.textures.entries)
          entry.key: base64Encode(entry.value),
      },
    };
  }
  final singleGroup = particle == null ? null : particleGroups['$particle'];
  final identity = document['move'] as Map;
  final id = identity['id'] as String;
  return {
    'id': id,
    'sourceId': identity['sourceId'],
    'label': nameFor(move, 'fr', id),
    'englishName': nameFor(move, 'en', id),
    'type': (move['type'] as Map?)?['name'] ?? 'normal',
    'category': (move['damage_class'] as Map?)?['name'] ?? 'physical',
    'particle': particle,
    if (singleGroup != null) ...singleGroup,
    if (particleIds.length > 1) 'particleGroups': particleGroups,
    'approximations': approximations.toList()..sort(),
    'program': program,
    if (particleIds.isEmpty) 'sourceEmitterIndices': <int>[],
    if (particleIds.isEmpty) 'textureSha256': <String, String>{},
    if (particleIds.isEmpty) 'textures': <String, String>{},
    if (backgrounds.isNotEmpty) 'backgrounds': backgrounds,
    if (backgroundSourceHashes.isNotEmpty)
      'backgroundSourceSha256': backgroundSourceHashes,
    if (backgroundAnimations.isNotEmpty)
      'backgroundAnimations': backgroundAnimations,
    if (animationSourceHashes.isNotEmpty)
      'backgroundAnimationSourceSha256': animationSourceHashes,
  };
}

Future<void> main() async {
  final records = <Map>[];
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isNotEmpty) records.add(jsonDecode(line) as Map);
  }
  final output = List<Map<String, Object?>?>.filled(records.length, null);
  final failures = <Map<String, Object?>>[];
  final client = HttpClient()..maxConnectionsPerHost = 4;
  var cursor = 0;
  Future<void> worker() async {
    while (cursor < records.length) {
      final index = cursor++;
      final item = records[index];
      try {
        output[index] = await convert(item['script'] as Map, item['move'] as Map,
            client, selectedVariant: item['variant'] as String?);
      } on Object catch (error) {
        final script = item['script'] as Map;
        failures.add(
            {'id': (script['move'] as Map)['id'], 'reason': error.toString()});
      }
    }
  }

  try {
    await Future.wait(List.generate(4, (_) => worker()));
    stdout.writeln(jsonEncode({
      'input': records.length,
      'bundles': output.whereType<Map<String, Object?>>().toList(),
      'failures': failures
    }));
  } finally {
    client.close(force: true);
  }
}
