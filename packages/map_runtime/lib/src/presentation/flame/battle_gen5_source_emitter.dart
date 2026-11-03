import 'battle_spl_particle_motion.dart';

({int x, int y, int z}) gen5SourceFieldEmitterOffset(Map<String, dynamic> args) => (
  x: (args['fromX'] as int) - 0x800,
  y: (args['fromY'] as int) - 0x666 + (args['offsetY'] as int),
  z: (args['fromZ'] as int) - 0x7000,
);

({BattleSplVector from, BattleSplVector to}) gen5SourceFieldMotionEndpoints(
  Map<String, dynamic> args,
) => (
  from: (x: (args['fromX'] as int) - 0x800,
      y: (args['fromY'] as int) - 0x666, z: (args['fromZ'] as int) - 0x7000),
  to: switch (args['to']) {
    'EFFVM_EMIT_ATTACKER' => (x: 0, y: 0, z: 0),
    'EFFVM_EMIT_DEFENDER' => (x: 0x4cd - 0x800, y: 0, z: -0xa000 - 0x7000),
    _ => throw const FormatException('Unsupported field emitter target'),
  },
);

void applyGen5SourceEmitterParameters(
  Map<dynamic, dynamic> emitter,
  Map<String, dynamic> args, {
  required bool orthographic,
}) {
  if (orthographic &&
      (args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER')) {
    return;
  }

  final emission = emitter['emission'] as Map;
  final appearance = emitter['appearance'] as Map;
  final radiusScale = (args['radiusScale'] as int?) ?? 0;
  final lifeScale = (args['lifeScale'] as int?) ?? 0;
  final scaleScale = (args['scaleScale'] as int?) ?? 0;
  final cameraScale = (args['cameraScale'] as int?) ?? 0;

  if (radiusScale != 0) {
    for (final field in ['radius', 'length']) {
      final value = emission[field];
      if (value is int) emission[field] = (value * radiusScale + 2048) >> 12;
    }
  }
  final lifetime = emission['particleLifetime'];
  if (lifeScale != 0 && lifetime is int) {
    emission['particleLifetime'] = (lifetime * lifeScale) >> 12;
  }
  final baseScale = appearance['baseScale'];
  if (scaleScale != 0 && baseScale is int) {
    final variance = (emission['scaleVariance'] as int?) ?? 0;
    final maximum = ((32767 * 256) ~/ (255 + variance)).clamp(0, 32767);
    appearance['baseScale'] =
        ((baseScale * scaleScale + 2048) >> 12).clamp(0, maximum);
  }
  if (cameraScale != 0) {
    for (final field in ['axisVelocity', 'positionVelocity']) {
      final value = emission[field];
      if (value is int) {
        emission[field] = ((value * cameraScale + 2048) >> 12).toSigned(16);
      }
    }
  }
}
