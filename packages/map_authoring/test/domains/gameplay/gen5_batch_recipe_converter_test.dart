import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_recipe_converter.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_particle_approximation.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_script_selection.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_batch_audio_matcher.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Gen5BattleScriptSource script(String instructions) {
  final bytes = Uint8List.fromList(utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 1
ScriptVariant Example
Example:
$instructions
End
'''));
  return Gen5BattleScriptSource.read(bytes,
      sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
      sourcePath: 'res/battle/animations/moves/example.s',
      expectedSha256: sha256.convert(bytes).toString());
}

void main() {
  test('finds shared emitter patterns and records unsupported commands', () {
    final result = Gen5BatchRecipeConverter.analyze(script('''
ParticleLoad 199
EmitterAdd 199, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
McssRotate EFFVM_ATTACKER, 0, 30, 4, 0, 1
PlaySE SEQ_EXAMPLE, 0, 0, 0, 0, 0, 0, 0, 0
'''));
    expect(result.particles.single.id, 199);
    expect(result.emitterIndices[199], {0});
    expect(result.particles.single.from, 'targetImpact');
    expect(result.warnings, contains('untranslated-command:McssRotate'));
    expect(result.warnings, contains('sound-sequence-not-transcribed'));
    expect(result.warnings, contains('emitter-selection-and-timing-approximated'));
  });

  test('builds and validates a recipe from a particle and an explicitly selected sound', () async {
    final definition = await File('../map_core/test/fixtures/spl_particle_v2.json').readAsBytes();
    final pixels = image.Image(width: 2, height: 2);
    image.fill(pixels, color: image.ColorRgba8(255, 255, 255, 255));
    final texture = Uint8List.fromList(image.encodePng(pixels));
    final sound = await File('../map_runtime/assets/audio/overworld/jump.wav').readAsBytes();
    final source = script('''
ParticleLoad 199
EmitterAdd 199, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
PlaySE SEQ_EXAMPLE, 0, 0, 0, 0, 0, 0, 0, 0
''');
    final result = Gen5BatchRecipeConverter.convert(
      moveId: 'example', sourceMoveId: 99, script: source,
      particles: {199: Gen5BatchParticle(definition: definition, textures: {'tex': texture})},
      sound: sound, soundMediaType: 'audio/wav',
    );
    expect(result.binding.sourceMoveId, 'example');
    expect(result.bundle.recipe.resources.map((e) => e.role), containsAll(['particleDefinition', 'texture', 'sound']));
    expect(result.warnings, contains('sound-sequence-not-transcribed'));
    expect(result.bundle.recipe.readVerifiedSplParticleDefinitions(result.bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities), hasLength(1));
  });

  test('does not invent a sound or silently invent an unknown emitter target', () async {
    final analysis = Gen5BatchRecipeConverter.analyze(script('''
ParticleLoad 199
EmitterAdd 199, 0, SOME_UNKNOWN_TARGET, 8, 0, 0, 0, 0, 0, 0, 0
'''));
    expect(analysis.particles, isEmpty);
    expect(analysis.warnings, contains('unsupported-emitter-target:SOME_UNKNOWN_TARGET'));
    expect(() => Gen5BatchRecipeConverter.convert(
      moveId: 'example', sourceMoveId: 99, script: script('''
ParticleLoad 199
EmitterAdd 199, 0, SOME_UNKNOWN_TARGET, 8, 0, 0, 0, 0, 0, 0, 0
'''), particles: const {}), throwsFormatException);
  });

  test('selects only source emitters actually invoked and reports a missing sound', () async {
    final definition = jsonDecode(await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString()) as Map<String, dynamic>;
    final emitters = definition['emitters'] as List;
    emitters.add(jsonDecode(jsonEncode(emitters.single)));
    final pixels = image.Image(width: 2, height: 2);
    image.fill(pixels, color: image.ColorRgba8(255, 255, 255, 255));
    final result = Gen5BatchRecipeConverter.convert(moveId: 'example', sourceMoveId: 99,
      script: script('''
ParticleLoad 199
EmitterAdd 199, 1, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
'''), particles: {199: Gen5BatchParticle(
        definition: Uint8List.fromList(utf8.encode(jsonEncode(definition))),
        textures: {'tex': Uint8List.fromList(image.encodePng(pixels))})});
    final selected = result.bundle.recipe.readVerifiedSplParticleDefinitions(result.bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities);
    expect(selected.values.single.emitters, hasLength(1));
    expect(result.warnings, containsAll(['unused-emitters-omitted', 'missing-move-audio', 'runtime-fallback-silent-audio']));
    expect(result.bundle.recipe.resources.where((item) => item.role == 'sound'), isEmpty);
  });

  test('bounds a preview and explicitly lists the emitters it omits', () async {
    final definition = jsonDecode(await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString()) as Map<String, dynamic>;
    final original = (definition['emitters'] as List).single;
    definition['emitters'] = [for (var i = 0; i < 8; i++) jsonDecode(jsonEncode(original))];
    final pixels = image.Image(width: 2, height: 2);
    final instructions = ['ParticleLoad 199', for (var i = 0; i < 8; i++)
      'EmitterAdd 199, $i, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0'].join('\n');
    final result = Gen5BatchRecipeConverter.convert(moveId: 'example', sourceMoveId: 99,
      script: script(instructions), particles: {199: Gen5BatchParticle(
        definition: Uint8List.fromList(utf8.encode(jsonEncode(definition))),
        textures: {'tex': Uint8List.fromList(image.encodePng(pixels))})});
    final selected = result.bundle.recipe.readVerifiedSplParticleDefinitions(result.bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities);
    expect(selected.values.single.emitters, hasLength(5));
    expect(result.warnings, containsAll(['preview-omitted-emitter:199:5',
      'preview-omitted-emitter:199:6', 'preview-omitted-emitter:199:7']));
  });

  test('marks particle approximations and leaves the original data untouched', () {
    final source = {
      r'$schema': '../../particles.schema.json',
      'textures': [{'name': 'tex', 'format': 'a5i3', 'repeat': 'st', 'flip': 'none', 'palColor0': true}],
      'emitters': [{'emissionType': 'circle_border', 'drawType': 'billboard',
        'emissionAxis': 'emitter', 'hasRotation': true, 'spinBehavior': {'speed': 1}}],
    };
    final result = Gen5BatchParticleApproximation.normalize(source);
    final emitter = (result.document['emitters'] as List).single as Map;
    expect(emitter['emissionType'], 'sphere_surface');
    expect(emitter['hasRotation'], isFalse);
    expect(emitter['emissionAxis'], 'z');
    expect(emitter.containsKey('spinBehavior'), isFalse);
    expect(result.warnings, containsAll(['particle-shape:circle_border->sphere_surface',
      'particle-field:hasRotation', 'particle-field:emissionAxis', 'particle-field:spinBehavior', 'texture-field:repeat']));
    expect((source['emitters'] as List).single['hasRotation'], isTrue);
    expect((source['textures'] as List).single['repeat'], 'st');
    expect((emitter['scaleAnim'] as Map)['out'], 254);
    expect((emitter['alphaAnim'] as Map)['out'], 254);
    expect(result.warnings, containsAll(['particle-default:scaleAnim', 'particle-default:alphaAnim']));
    final withChild = {'textures': <Object>[], 'emitters': [{'childResource': {'texture': 'tex'}}]};
    final withoutChild = Gen5BatchParticleApproximation.normalize(withChild, omitChildren: true);
    expect((withoutChild.document['emitters'] as List).single.containsKey('childResource'), isFalse);
    expect(withoutChild.warnings, contains('particle-child:omitted-for-preview'));
    expect((withChild['emitters'] as List).single.containsKey('childResource'), isTrue);
  });

  test('selects a visible variant without hiding discarded branches', () {
    final bytes = Uint8List.fromList(utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant Begin
ScriptVariant Impact
Begin:
WaitFrames 10
End
Impact:
ParticleLoad 199
Impact_Inner:
EmitterAdd 199, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
End
'''));
    final selected = Gen5BatchScriptSelection.read(bytes,
      sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
      sourcePath: 'res/battle/animations/moves/example.s',
      expectedSha256: sha256.convert(bytes).toString());
    expect(selected.script.variant, 'Impact');
    expect(selected.warnings, contains('script-variants-not-transcribed'));
    expect(selected.warnings, contains('script-internal-labels-not-transcribed'));
    expect(selected.script.instructions.map((item) => item.name), contains('EmitterAdd'));
    expect(() => Gen5BatchScriptSelection.read(bytes,
      sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
      sourcePath: 'res/battle/animations/moves/example.s',
      expectedSha256: '0' * 64), throwsFormatException);
  });

  test('chooses a unique one-hit clip only when no exact audio exists', () {
    final result = Gen5BatchAudioMatcher.select('double-kick', ['Double Kick 1hit.mp3', 'Double Kick 2hits.mp3']);
    expect(result.fileName, 'Double Kick 1hit.mp3');
    expect(result.warnings, contains('sound-multihit-one-hit-preview'));
    final exact = Gen5BatchAudioMatcher.select('double-kick', ['Double Kick.mp3', 'Double Kick 1hit.mp3']);
    expect(exact.fileName, 'Double Kick.mp3');
    expect(exact.warnings, isEmpty);
    final ambiguous = Gen5BatchAudioMatcher.select('double-kick', ['Double Kick 1hit.mp3', 'Double-Kick-1hit.mp3']);
    expect(ambiguous.fileName, isNull);
    expect(ambiguous.warnings, contains('ambiguous-move-audio'));
  });

  test('upgrades compatible particle schemas to a shared version', () async {
    final source = jsonDecode(await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString()) as Map<String, dynamic>;
    final other = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
    other['schemaVersion'] = 3;
    final secondEmitter = (other['emitters'] as List).single as Map;
    (secondEmitter['emission'] as Map)['positionVelocity'] = 0;
    (secondEmitter['appearance'] as Map)['initialTexture'] = 'tex2';
    final pixels = Uint8List.fromList(image.encodePng(image.Image(width: 2, height: 2)));
    final result = Gen5BatchRecipeConverter.convert(moveId: 'example', sourceMoveId: 99,
      script: script('''
ParticleLoad 199
EmitterAdd 199, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
ParticleLoad 200
EmitterAdd 200, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
'''), particles: {
        199: Gen5BatchParticle(definition: Uint8List.fromList(utf8.encode(jsonEncode(source))), textures: {'tex': pixels}),
        200: Gen5BatchParticle(definition: Uint8List.fromList(utf8.encode(jsonEncode(other))), textures: {'tex2': pixels}),
      });
    expect(result.bundle.recipe.resources.where((r) => r.role == 'particleDefinition').map((r) => r.definitionVersion), everyElement(3));
    expect(result.warnings, contains('particle-schema-upgraded:2->3'));
    expect(result.warnings, isNot(contains('runtime-fallback-mixed-particle-versions')));
  });

  test('limits particle workload only for explicitly requested previews', () async {
    final definition = jsonDecode(await File('../map_core/test/fixtures/spl_particle_v2.json').readAsString()) as Map<String, dynamic>;
    final emission = ((definition['emitters'] as List).single as Map)['emission'] as Map;
    emission['rate'] = 16384;
    emission['particleLifetime'] = 60;
    final pixels = Uint8List.fromList(image.encodePng(image.Image(width: 2, height: 2)));
    final result = Gen5BatchRecipeConverter.convert(moveId: 'example', sourceMoveId: 99,
      script: script('''
ParticleLoad 199
EmitterAdd 199, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 0, 0, 0, 0
'''), particles: {199: Gen5BatchParticle(
        definition: Uint8List.fromList(utf8.encode(jsonEncode(definition))), textures: {'tex': pixels})},
      boundedPreview: true);
    final selected = result.bundle.recipe.readVerifiedSplParticleDefinitions(result.bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities).values.single.toJson();
    final limited = (((selected['emitters'] as List).single as Map)['emission'] as Map);
    expect(limited['rate'], 2048);
    expect(limited['particleLifetime'], 24);
    expect(result.warnings, contains('preview-budget:199:0:rate:16384->2048'));
    expect(result.warnings, contains('preview-budget:199:0:particleLifetime:60->24'));
  });
}
