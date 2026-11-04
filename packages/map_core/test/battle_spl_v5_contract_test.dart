import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> definition(int id) => jsonDecode(File(
    '../../tools/avelune_attack_comparator/assets/bw2/particle$id/definition.json',
  ).readAsStringSync()) as Map<String, dynamic>;

  test('accepts the bounded SPL v5 definitions used by Water Gun and Surf', () {
    for (final id in [220, 222]) {
      final input = definition(id);
      final parsed = BattleSplParticleDefinition.fromJson(input);
      expect(parsed.schemaVersion, 5);
      expect(parsed.toJson(), input);
    }
  });

  test('rejects invalid v5 values and later experimental versions', () {
    for (final field in ['velocityVariance', 'emissionAxis']) {
      final input = definition(220);
      final emission = (input['emitters'] as List).first['emission'] as Map;
      emission[field] = field == 'velocityVariance' ? 256 : 'emitter';
      expect(() => BattleSplParticleDefinition.fromJson(input), throwsFormatException);
    }
    final invalidPolygon = definition(222);
    final polygon = (invalidPolygon['emitters'] as List)[3]['appearance'] as Map;
    polygon['polygonX'] = 1;
    expect(() => BattleSplParticleDefinition.fromJson(invalidPolygon), throwsFormatException);
    final later = definition(220)..['schemaVersion'] = 6;
    expect(() => BattleSplParticleDefinition.fromJson(later), throwsFormatException);
  });

  test('requires an explicit v5 capability for v5 recipe resources', () {
    final input = <String, dynamic>{
      'schemaVersion': 1,
      'recipeId': 'water',
      'revision': '1',
      'moveSourceId': 'water-gun',
      'variant': 'default',
      'requiredCapabilities': ['startParticle', 'splParticleV5'],
      'provenance': {'source': 'test', 'sourceRevision': '1', 'sourcePaths': [], 'converter': 'test'},
      'resources': [{
        'id': 'particle',
        'role': 'particleDefinition',
        'mediaType': 'application/vnd.avelune.particle+json',
        'sizeBytes': 1,
        'sha256': 'a' * 64,
        'definitionVersion': 5,
        'dependencies': [],
      }],
      'program': {'kind': 'startParticle', 'resourceId': 'particle', 'from': 'userMouth', 'to': 'targetImpact'},
    };
    expect(BattleMoveAnimationRecipe.fromJson(input).resources.single.definitionVersion, 5);
    input['requiredCapabilities'] = ['startParticle'];
    expect(() => BattleMoveAnimationRecipe.fromJson(input), throwsFormatException);
  });
}
