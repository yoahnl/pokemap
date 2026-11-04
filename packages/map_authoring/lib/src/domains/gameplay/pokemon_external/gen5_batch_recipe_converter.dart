import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'gen5_battle_script_source.dart';

final class Gen5BatchParticle {
  const Gen5BatchParticle({required this.definition, required this.textures,
    this.warnings = const {}, this.sourceSha256, this.normalizedSha256,
    this.sourceEmitterIndices});
  final Uint8List definition;
  final Map<String, Uint8List> textures;
  final Set<String> warnings;
  final String? sourceSha256;
  final String? normalizedSha256;
  final List<int>? sourceEmitterIndices;
}

final class Gen5BatchParticleRequest {
  const Gen5BatchParticleRequest(this.id, this.emitterIndex, this.from, this.to, this.delayFrames);
  final int id;
  final int emitterIndex;
  final String from;
  final String to;
  final int delayFrames;
}

final class Gen5BatchAnalysis {
  const Gen5BatchAnalysis(this.particles, this.emitterIndices, this.warnings);
  final List<Gen5BatchParticleRequest> particles;
  final Map<int, Set<int>> emitterIndices;
  final Set<String> warnings;
}

final class Gen5BatchRecipe {
  const Gen5BatchRecipe(this.binding, this.bundle, this.warnings);
  final BattleMoveRecipeBinding binding;
  final InspectedBattleRecipeBundle bundle;
  final Set<String> warnings;
}

abstract final class Gen5BatchRecipeConverter {
  static Gen5BatchAnalysis analyze(Gen5BattleScriptSource script) {
    final loaded = <int>{};
    final particles = <Gen5BatchParticleRequest>[];
    final emitterIndices = <int, Set<int>>{};
    final warnings = <String>{'script-sequencing-approximated'};
    var elapsedWaitFrames = 0;
    int? firstEmitterFrame;
    String? anchor(String value) => switch (value) {
      'EFFVM_EMIT_ATTACKER' => 'userMouth',
      'EFFVM_EMIT_DEFENDER' => 'targetImpact',
      _ => null,
    };
    for (final instruction in script.instructions) {
      final args = instruction.arguments;
      switch (instruction.name) {
        case 'ParticleLoad':
          final id = args.length == 1 ? int.tryParse(args.first) : null;
          if (id == null || id < 0 || id > 65535) {
            warnings.add('unsupported-particle-identity');
          } else {
            loaded.add(id);
          }
        case 'EmitterAdd' || 'EmitterAddOrtho' || 'EmitterMove':
          final move = instruction.name == 'EmitterMove';
          final id = args.isNotEmpty ? int.tryParse(args.first) : null;
          final fromIndex = move ? 3 : 2;
          final toIndex = move ? 4 : 3;
          if (id == null || !loaded.contains(id) || args.length <= toIndex) {
            warnings.add('unsupported-emitter-particle');
            continue;
          }
          final emitter = args.length > 1 ? int.tryParse(args[1]) : null;
          if (emitter == null || emitter < 0 || emitter > 31) {
            warnings.add('unsupported-emitter-index');
            continue;
          }
          final from = anchor(args[fromIndex]);
          final to = !move && int.tryParse(args[toIndex]) == 8
              ? from : anchor(args[toIndex]);
          if (from == null || to == null) {
            warnings.add('unsupported-emitter-target:${from == null ? args[fromIndex] : args[toIndex]}');
            continue;
          }
          if (instruction.name == 'EmitterAddOrtho') {
            warnings.add('orthographic-emitter-approximated');
          }
          if (move) warnings.add('emitter-motion-not-transcribed');
          firstEmitterFrame ??= elapsedWaitFrames;
          if (particles.any((part) => part.id == id && part.emitterIndex == emitter &&
              part.from == from && part.to == to)) {
            warnings.add('repeated-emitter-omitted');
          } else {
            particles.add(Gen5BatchParticleRequest(id, emitter, from, to,
                elapsedWaitFrames - firstEmitterFrame));
          }
          emitterIndices.putIfAbsent(id, () => <int>{}).add(emitter);
          warnings.add('emitter-selection-and-timing-approximated');
        case 'WaitFrames':
          final frames = args.length == 1 ? int.tryParse(args.first) : null;
          if (frames == null || frames < 0 || frames > 3600) {
            warnings.add('untranslated-command:WaitFrames');
          } else {
            elapsedWaitFrames += frames;
          }
        case 'PlaySE' || 'MoveSE' || 'PanSE':
          warnings.add('sound-sequence-not-transcribed');
        case 'End':
          break;
        default:
          warnings.add('untranslated-command:${instruction.name}');
      }
    }
    return Gen5BatchAnalysis(List.unmodifiable(particles),
      Map.unmodifiable({for (final entry in emitterIndices.entries) entry.key: Set<int>.unmodifiable(entry.value)}),
      Set.unmodifiable(warnings));
  }

  static Gen5BatchRecipe convert({
    required String moveId,
    required int sourceMoveId,
    required Gen5BattleScriptSource script,
    required Map<int, Gen5BatchParticle> particles,
    Uint8List? sound,
    String? soundMediaType,
    bool boundedPreview = false,
  }) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(moveId) ||
        sourceMoveId < 1 || sourceMoveId > 559 ||
        (sound == null) != (soundMediaType == null) ||
        (sound != null && !{'audio/mpeg', 'audio/wav'}.contains(soundMediaType))) {
      throw const FormatException('Invalid batch recipe identity or audio');
    }
    final analysis = analyze(script);
    if (analysis.particles.isEmpty) {
      throw const FormatException('No supported particle placement');
    }
    final warnings = <String>{...analysis.warnings};
    final activeParticles = analysis.particles.take(5).toList();
    if (activeParticles.any((part) => part.delayFrames > 3600)) {
      throw const FormatException('Preview particle delay exceeds one minute');
    }
    if (activeParticles.any((part) => part.delayFrames >= 200)) {
      warnings.add('runtime-fallback-delayed-emitter');
    }
    for (final part in analysis.particles.skip(5)) {
      warnings.add('preview-omitted-emitter:${part.id}:${part.emitterIndex}');
      warnings.add('preview-omitted-placement:${part.id}:${part.emitterIndex}:${part.from}:${part.to}');
    }
    final requiredIds = activeParticles.map((part) => part.id).toSet();
    if (requiredIds.any((id) => !particles.containsKey(id))) {
      throw const FormatException('Required particle source unavailable');
    }
    final media = <String, Uint8List>{};
    final definitions = <String, BattleSplParticleDefinition>{};
    final selectedTextures = <String, Set<String>>{};
    String definitionId(int id, int emitter) => 'particle${id}e$emitter';
    for (final id in requiredIds) {
      final part = particles[id]!;
      warnings.addAll(part.warnings);
      final original = BattleSplParticleDefinition.fromJson(
          jsonDecode(utf8.decode(part.definition)) as Map<String, dynamic>);
      if (original.textureIds.length != part.textures.length ||
          !original.textureIds.containsAll(part.textures.keys)) {
        throw const FormatException('Particle texture dependencies mismatch');
      }
      final indices = activeParticles.where((entry) => entry.id == id)
          .map((entry) => entry.emitterIndex).toSet();
      final sourceIndices = part.sourceEmitterIndices;
      if (sourceIndices != null &&
          (sourceIndices.length != original.emitters.length ||
              sourceIndices.toSet().length != sourceIndices.length ||
              sourceIndices.any((index) => index < 0 || index > 31))) {
        throw const FormatException('Invalid source emitter mapping');
      }
      int localIndex(int index) => sourceIndices?.indexOf(index) ?? index;
      if (indices.any((index) => localIndex(index) < 0 || localIndex(index) >= original.emitters.length)) {
        throw const FormatException('Referenced particle emitter unavailable');
      }
      final originalEmitters = original.toJson()['emitters'] as List;
      if (boundedPreview) {
        for (final index in indices) {
          final emission = (originalEmitters[localIndex(index)] as Map)['emission'] as Map;
          for (final (field, maximum) in [('rate', 2048), ('particleLifetime', 24)]) {
            final value = emission[field];
            if (value is int && value > maximum) {
              emission[field] = maximum;
              warnings.add('preview-budget:$id:$index:$field:$value->$maximum');
            }
          }
        }
      }
      if (indices.length != original.emitters.length) warnings.add('unused-emitters-omitted');
      final usedTextures = <String>{};
      for (final index in indices) {
        final definition = BattleSplParticleDefinition.fromJson({
          'schemaVersion': original.schemaVersion,
          'emitters': [originalEmitters[localIndex(index)]],
        });
        final key = definitionId(id, index);
        selectedTextures[key] = definition.textureIds;
        usedTextures.addAll(definition.textureIds);
        if (media.containsKey(key)) {
          throw const FormatException('Duplicate particle identity');
        }
        media[key] = Uint8List.fromList(utf8.encode(jsonEncode(definition.toJson())));
        definitions[key] = definition;
      }
      for (final entry in part.textures.entries.where((entry) => usedTextures.contains(entry.key))) {
        if (media.containsKey(entry.key)) {
          throw const FormatException('Duplicate particle texture identity');
        }
        media[entry.key] = entry.value;
      }
    }
    final targetVersion = definitions.values.map((value) => value.schemaVersion).reduce((a, b) => a > b ? a : b);
    for (final id in definitions.keys.toList()) {
      final definition = definitions[id]!;
      if (definition.schemaVersion == targetVersion) continue;
      final data = definition.toJson();
      data['schemaVersion'] = targetVersion;
      for (final emitter in (data['emitters'] as List).cast<Map>()) {
        if (definition.schemaVersion < 3 && targetVersion >= 3) {
          (emitter['emission'] as Map)['positionVelocity'] = 0;
        }
        if (definition.schemaVersion < 4 && targetVersion >= 4) {
          (emitter['motion'] as Map)['magnet'] = null;
          final child = emitter['child'];
          if (child is Map) {
            child['scaleEnd'] = null;
            child['inheritBehaviors'] = false;
            child['draw'] = 'billboard';
          }
        }
        if (definition.schemaVersion < 5 && targetVersion >= 5) {
          final emission = emitter['emission'] as Map;
          emission['emissionAxis'] = 'z';
          emission['velocityVariance'] = 0;
          final appearance = emitter['appearance'] as Map;
          appearance['hasRotation'] = false;
          appearance['minRotation'] = 0;
          appearance['maxRotation'] = 0;
          appearance['dirFromPosition'] = false;
        }
      }
      final upgraded = BattleSplParticleDefinition.fromJson(data);
      definitions[id] = upgraded;
      media[id] = Uint8List.fromList(utf8.encode(jsonEncode(upgraded.toJson())));
      warnings.add('particle-schema-upgraded:${definition.schemaVersion}->$targetVersion');
    }
    if (sound == null) {
      warnings.add('missing-move-audio');
      warnings.add('runtime-fallback-silent-audio');
    } else {
      if (media.containsKey('cue')) throw const FormatException('Duplicate sound identity');
      media['cue'] = sound;
      warnings.add('move-clip-not-synchronized-to-original-sound-events');
    }
    if (definitions.values.map((value) => value.schemaVersion).toSet().length > 1) {
      warnings.add('runtime-fallback-mixed-particle-versions');
    }
    if (definitions.values.fold<int>(0, (sum, value) => sum + value.emitters.length) > 32) {
      warnings.add('runtime-fallback-emitter-limit');
    }
    if (activeParticles.where((part) => part.from != part.to)
        .map((part) => '${part.from}:${part.to}').toSet().length > 1) {
      warnings.add('runtime-fallback-multiple-directions');
    }
    Map<String, Object> resource(String id, String role, String mediaType) => {
      'id': id, 'role': role, 'mediaType': mediaType,
      'sizeBytes': media[id]!.length, 'sha256': sha256.convert(media[id]!).toString(),
    };
    final recipeId = 'bw2-$moveId-batch';
    final required = <String>{'sequence', 'parallel', 'startParticle', 'waitEffects', 'audioSelectionV2'};
    if (activeParticles.any((part) => part.delayFrames > 0)) required.add('wait');
    for (final definition in definitions.values) {
      required.add('splParticleV${definition.schemaVersion}');
    }
    if (sound != null) required.add('sound');
    final recipeBytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 2, 'recipeId': recipeId, 'revision': '2',
      'moveSourceId': moveId, 'variant': script.variant,
      'requiredCapabilities': required.toList(),
      'provenance': {'source': 'fuddlesworth/pokebw2', 'sourceRevision': script.sourceRevision,
        'sourcePaths': [script.sourcePath, for (final id in requiredIds) 'res/particles/btlv_effvm_particles/$id/particles.json'],
        'converter': 'batch-particle-preview/2'},
      'resources': [
        for (final texture in selectedTextures.values.expand((value) => value).toSet())
          resource(texture, 'texture', 'image/png'),
        for (final id in definitions.keys)
          {...resource(id, 'particleDefinition', 'application/vnd.avelune.particle+json'),
            'definitionVersion': definitions[id]!.schemaVersion,
            'dependencies': selectedTextures[id]!.toList()},
        if (sound != null) resource('cue', 'sound', soundMediaType!),
      ],
      'audio': sound == null ? {'kind': 'none'} : {'kind': 'clip', 'resourceId': 'cue'},
      'program': {'kind': 'sequence', 'steps': [
        {'kind': 'parallel', 'steps': [for (final part in activeParticles)
          if (part.delayFrames == 0)
            {'kind': 'startParticle', 'resourceId': definitionId(part.id, part.emitterIndex), 'from': part.from, 'to': part.to}
          else
            {'kind': 'sequence', 'steps': [
              {'kind': 'wait', 'durationMs': (part.delayFrames * 1000 + 30) ~/ 60},
              {'kind': 'startParticle', 'resourceId': definitionId(part.id, part.emitterIndex), 'from': part.from, 'to': part.to},
            ]}]},
        {'kind': 'waitEffects'},
      ]},
    })));
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': moveId, 'sourceMoveId': moveId,
      'catalogReleaseId': 'bw2-batch-local', 'recipeId': recipeId,
      'variant': script.variant, 'revision': '2', 'recipeSha256': sha256.convert(recipeBytes).toString(),
    });
    final inspected = const BattleRecipeBundleInspector().inspect(binding, recipeBytes, media,
      limits: const BattleRecipeBundleLimits(maxTextures: 16, maxTextureBytes: 8 * 1024 * 1024,
        maxBundleBytes: 32 * 1024 * 1024, maxDimension: 2048, maxTexturePixels: 4000000, maxTotalPixels: 16000000),
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      expectedProjectMoveId: moveId, expectedCatalogReleaseId: 'bw2-batch-local');
    inspected.recipe.readVerifiedSplParticleDefinitions(inspected.media,
        availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities);
    return Gen5BatchRecipe(binding, inspected, Set.unmodifiable(warnings));
  }
}
