import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_emitter.dart';

void main() {
  test('aims a targeted source emitter without losing its vertical angle', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{
        'axis': <dynamic, dynamic>{'x': 4096, 'y': 2048, 'z': 0},
      },
      'appearance': <dynamic, dynamic>{},
    };
    applyGen5SourceEmitterParameters(
      emitter, {}, orthographic: false, aimAtOpponent: true,
    );
    final axis = (emitter['emission'] as Map)['axis'] as Map;
    expect(axis['x'], 0);
    expect(axis['y'], closeTo(1832, 2));
    expect(axis['z'], closeTo(3664, 2));
  });

  test('keeps vertical and untargeted source axes unchanged', () {
    for (final (axis, targeted) in [
      (<dynamic, dynamic>{'x': 4096, 'y': 0, 'z': 0}, false),
      (<dynamic, dynamic>{'x': 0, 'y': 4096, 'z': 0}, true),
      (<dynamic, dynamic>{'x': 0, 'y': 0, 'z': 0}, true),
    ]) {
      final original = Map<dynamic, dynamic>.from(axis);
      applyGen5SourceEmitterParameters(
        {'emission': {'axis': axis}, 'appearance': {}}, {},
        orthographic: false, aimAtOpponent: targeted,
      );
      expect(axis, original);
    }
  });

  test('aligns a source collision plane with the workshop origin', () {
    for (final args in [
      <String, dynamic>{'from': 'EFFVM_EMIT_DEFENDER'},
      <String, dynamic>{'fromX': 0, 'fromY': 0, 'fromZ': 0},
    ]) {
      final emitter = <dynamic, dynamic>{
        'emission': <dynamic, dynamic>{},
        'appearance': <dynamic, dynamic>{},
        'motion': <dynamic, dynamic>{
          'collisionPlane': <dynamic, dynamic>{'height': 4096, 'elasticity': 2457},
        },
      };
      applyGen5SourceEmitterParameters(emitter, args, orthographic: false);
      expect(((emitter['motion'] as Map)['collisionPlane'] as Map)['height'], 4096 - 0x666);
    }
  });

  test('maps a moving field emitter to BW2 player and defender positions', () {
    final args = <String, dynamic>{'fromX': 0, 'fromY': 0x2000, 'fromZ': 0,
      'to': 'EFFVM_EMIT_DEFENDER'};
    final defender = gen5SourceFieldMotionEndpoints(args);
    expect(defender.from, (x: -0x800, y: 0x2000 - 0x666, z: -0x7000));
    expect(defender.to, (x: 0x4cd - 0x800, y: 0, z: -0xa000 - 0x7000));
    args['to'] = 'EFFVM_EMIT_ATTACKER';
    expect(gen5SourceFieldMotionEndpoints(args).to, (x: 0, y: 0, z: 0));
  });

  test('orthographic player position zero keeps source scaling', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{'axisVelocity': 1000, 'radius': 1000},
      'appearance': <dynamic, dynamic>{'baseScale': 1000},
    };
    applyGen5SourceEmitterParameters(emitter, {
      'from': 0, 'cameraScale': 8192, 'radiusScale': 8192,
      'scaleScale': 8192,
    }, orthographic: true);
    expect(emitter['emission'], {'axisVelocity': 1000, 'radius': 1000});
    expect(emitter['appearance'], {'baseScale': 1000});
  });

  test('camera scale adjusts source emitter velocities with fx16 wrapping', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{
        'axisVelocity': 1000, 'positionVelocity': -1000,
      },
      'appearance': <dynamic, dynamic>{},
    };
    applyGen5SourceEmitterParameters(emitter, {
      'from': 'EFFVM_EMIT_DEFENDER', 'cameraScale': 6144,
    }, orthographic: false);
    expect(emitter['emission'], {
      'axisVelocity': 1500, 'positionVelocity': -1500,
    });
    (emitter['emission'] as Map)['axisVelocity'] = 20000;
    applyGen5SourceEmitterParameters(emitter, {
      'from': 'EFFVM_EMIT_DEFENDER', 'cameraScale': 8192,
    }, orthographic: false);
    expect((emitter['emission'] as Map)['axisVelocity'], -25536);
  });

  test('positions a field emitter relative to the BW2 player position', () {
    expect(gen5SourceFieldEmitterOffset({
      'fromX': 0x800, 'fromY': 0x666, 'fromZ': 0x7000, 'offsetY': 0,
    }), (x: 0, y: 0, z: 0));
    expect(gen5SourceFieldEmitterOffset({
      'fromX': 0, 'fromY': 0, 'fromZ': 0x3000, 'offsetY': 0x2000,
    }), (x: -0x800, y: 0x2000 - 0x666, z: -0x4000));
  });

  test('scales source radius, length, particle lifetime and base scale', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{
        'radius': 1000, 'length': 1001, 'particleLifetime': 37,
      },
      'appearance': <dynamic, dynamic>{'baseScale': 1001},
    };
    applyGen5SourceEmitterParameters(emitter, {
      'from': 'EFFVM_EMIT_DEFENDER', 'radiusScale': 2048,
      'lifeScale': 2048, 'scaleScale': 6144,
    }, orthographic: false);
    expect(emitter['emission'], {
      'radius': 500, 'length': 501, 'particleLifetime': 18,
    });
    expect(emitter['appearance'], {'baseScale': 1502});
  });

  test('bounds scaled size while preserving the configured variance limit', () {
    for (final variance in [0, 128]) {
      final emitter = <dynamic, dynamic>{
        'emission': <dynamic, dynamic>{'scaleVariance': variance},
        'appearance': <dynamic, dynamic>{'baseScale': 20000},
      };
      applyGen5SourceEmitterParameters(emitter, {
        'from': 'EFFVM_EMIT_DEFENDER', 'scaleScale': 8192,
      }, orthographic: false);
      final scale = (emitter['appearance'] as Map)['baseScale'] as int;
      expect(scale, lessThanOrEqualTo(32767));
      expect((scale * (255 + variance)) >> 8, lessThanOrEqualTo(32767));
    }
  });

  test('zero scale factors preserve source values', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{'radius': 1000, 'particleLifetime': 37},
      'appearance': <dynamic, dynamic>{'baseScale': 1001},
    };
    applyGen5SourceEmitterParameters(emitter, {
      'from': 'EFFVM_EMIT_ATTACKER', 'radiusScale': 0,
      'lifeScale': 0, 'scaleScale': 0,
    }, orthographic: false);
    expect(emitter['emission'], {'radius': 1000, 'particleLifetime': 37});
    expect(emitter['appearance'], {'baseScale': 1001});
  });

  test('keeps the existing orthographic attacker scaling rule', () {
    final emitter = <dynamic, dynamic>{
      'emission': <dynamic, dynamic>{'radius': 1000, 'particleLifetime': 37},
      'appearance': <dynamic, dynamic>{'baseScale': 1001},
    };
    applyGen5SourceEmitterParameters(emitter, {
      'from': 'EFFVM_EMIT_ATTACKER', 'radiusScale': 2048,
      'lifeScale': 2048, 'scaleScale': 6144,
    }, orthographic: true);
    expect(emitter['emission'], {'radius': 1000, 'particleLifetime': 37});
    expect(emitter['appearance'], {'baseScale': 1001});
  });
}
