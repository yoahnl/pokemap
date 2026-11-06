import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'gen5_batch_recipe_converter.dart';
import 'gen5_source_program_converter.dart';

abstract final class Gen5SourceRecipeConverter {
  static Gen5BatchRecipe convert({
    required String moveId,
    required Map<String, dynamic> sourceProgram,
    required Map<int, Gen5BatchParticle> particles,
    Map<int, Uint8List> backgrounds = const {},
    Map<int, ({int background, List<Uint8List> frames, List<int> durations})>
        backgroundAnimations = const {},
    Uint8List? sound,
    String? soundMediaType,
  }) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(moveId) ||
        (sound == null) != (soundMediaType == null) ||
        (sound != null && !{'audio/mpeg', 'audio/wav', 'audio/ogg'}.contains(soundMediaType))) {
      throw const FormatException('Invalid source recipe identity or audio');
    }
    final source = sourceProgram['source'];
    final variant = sourceProgram['variant'];
    if (source is! Map || source['revision'] != Gen5SourceProgramConverter.sourceRevision ||
        source['path'] is! String || !RegExp(r'^res/battle/animations/moves/[a-z0-9_]{1,120}\.s$').hasMatch(source['path'] as String) ||
        source['sha256'] is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(source['sha256'] as String) ||
        variant is! String || variant.isEmpty) {
      throw const FormatException('Invalid source program provenance');
    }
    final media = <String, Uint8List>{};
    final definitions = <int, BattleSplParticleDefinition>{};
    final indices = <int, List<int>>{};
    final warnings = <String>{'source-audio-not-mapped', 'source-program-not-reverified',
      if (sound == null) 'missing-move-audio'};
    final orderedParticles = particles.keys.toList()..sort();
    for (final id in orderedParticles) {
      if (id < 0 || id > 65535) throw const FormatException('Invalid source particle');
      final particle = particles[id]!;
      warnings.addAll(particle.warnings);
      final definitionJson =
          jsonDecode(utf8.decode(particle.definition)) as Map<String, dynamic>;
      final definition = (definitionJson['schemaVersion'] as int) > 5
          ? BattleSplParticleDefinition.fromExperimentalJson(definitionJson)
          : BattleSplParticleDefinition.fromJson(definitionJson);
      if (definition.textureIds.length != particle.textures.length ||
          !definition.textureIds.containsAll(particle.textures.keys)) {
        throw const FormatException('Particle texture dependencies mismatch');
      }
      final sourceIndices = particle.sourceEmitterIndices ??
          List<int>.generate(definition.emitters.length, (index) => index);
      if (sourceIndices.length != definition.emitters.length ||
          sourceIndices.toSet().length != sourceIndices.length ||
          sourceIndices.any((index) => index < 0 || index > 65535)) {
        throw const FormatException('Invalid source emitter mapping');
      }
      final resourceId = 'gen5-particle-$id';
      if (media.containsKey(resourceId)) throw const FormatException('Duplicate particle resource');
      media[resourceId] = Uint8List.fromList(particle.definition);
      definitions[id] = definition;
      indices[id] = List.unmodifiable(sourceIndices);
      for (final entry in particle.textures.entries) {
        final existing = media[entry.key];
        if (existing != null && sha256.convert(existing) != sha256.convert(entry.value)) {
          throw const FormatException('Conflicting texture resource');
        }
        media[entry.key] = Uint8List.fromList(entry.value);
      }
    }
    if (sound != null) {
      if (media.containsKey('cue')) throw const FormatException('Conflicting audio resource');
      media['cue'] = Uint8List.fromList(sound);
    }
    final orderedBackgrounds = backgrounds.keys.toList()..sort();
    for (final id in orderedBackgrounds) {
      if (id < 0 || id > 65535) throw const FormatException('Invalid source background');
      final resourceId = 'gen5-background-$id';
      if (media.containsKey(resourceId)) throw const FormatException('Conflicting background resource');
      media[resourceId] = Uint8List.fromList(backgrounds[id]!);
    }
    final orderedAnimations = backgroundAnimations.keys.toList()..sort();
    final backgroundFrameResources = <int, List<String>>{};
    final backgroundResourceByHash = <String, String>{
      for (final id in orderedBackgrounds)
        sha256.convert(backgrounds[id]!).toString(): 'gen5-background-$id',
    };
    final newBackgroundFrameResources = <String>[];
    if (orderedAnimations.length > 32) {
      throw const FormatException('Too many source background animations');
    }
    for (final id in orderedAnimations) {
      final animation = backgroundAnimations[id]!;
      if (id < 0 || id > 65535 || !backgrounds.containsKey(animation.background) ||
          animation.frames.isEmpty || animation.frames.length > 32 ||
          animation.frames.length != animation.durations.length ||
          animation.durations.any((duration) => duration < 0 || duration > 255)) {
        throw const FormatException('Invalid source background animation');
      }
      final frames = <String>[];
      for (var i = 0; i < animation.frames.length; i++) {
        final hash = sha256.convert(animation.frames[i]).toString();
        var resourceId = backgroundResourceByHash[hash];
        if (resourceId == null) {
          resourceId = 'gen5-background-animation-$id-frame-$i';
          if (media.containsKey(resourceId)) {
            throw const FormatException('Conflicting background animation resource');
          }
          media[resourceId] = Uint8List.fromList(animation.frames[i]);
          backgroundResourceByHash[hash] = resourceId;
          newBackgroundFrameResources.add(resourceId);
        }
        frames.add(resourceId);
      }
      backgroundFrameResources[id] = frames;
    }
    Map<String, Object> resource(String id, String role, String mediaType) => {
      'id': id, 'role': role, 'mediaType': mediaType,
      'sizeBytes': media[id]!.length, 'sha256': sha256.convert(media[id]!).toString(),
    };
    final textures = definitions.values.expand((value) => value.textureIds).toSet().toList()..sort();
    final recipeId = 'bw2-$moveId-source';
    final capabilities = <String>{'audioSelectionV2', 'gen5SourceProgram',
      for (final definition in definitions.values) 'splParticleV${definition.schemaVersion}',
      if (backgrounds.isNotEmpty) 'gen5SourceBackground',
      if (backgroundAnimations.isNotEmpty) 'gen5SourceBackgroundAnimation',
      if (sound != null) 'sound'};
    final recipeBytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 2, 'recipeId': recipeId, 'revision': '1',
      'moveSourceId': moveId, 'variant': variant,
      'requiredCapabilities': capabilities.toList(),
      'provenance': {'source': 'fuddlesworth/pokebw2', 'sourceRevision': source['revision'],
        'sourcePaths': [source['path']], 'converter': 'gen5-source-recipe/1'},
      'resources': [
        for (final texture in textures) resource(texture, 'texture', 'image/png'),
        for (final id in orderedBackgrounds) resource('gen5-background-$id', 'texture', 'image/png'),
        for (final id in newBackgroundFrameResources) resource(id, 'texture', 'image/png'),
        for (final id in orderedParticles)
          {...resource('gen5-particle-$id', 'particleDefinition', 'application/vnd.avelune.particle+json'),
            'definitionVersion': definitions[id]!.schemaVersion,
            'dependencies': definitions[id]!.textureIds.toList()..sort()},
        if (sound != null) resource('cue', 'sound', soundMediaType!),
      ],
      'audio': sound == null ? {'kind': 'none'} : {'kind': 'clip', 'resourceId': 'cue'},
      'program': {'kind': 'gen5SourceProgram', 'sourceProgram': sourceProgram,
        'particleBindings': [for (final id in orderedParticles) {
          'particle': id, 'resourceId': 'gen5-particle-$id', 'sourceEmitterIndices': indices[id],
        }],
        if (orderedBackgrounds.isNotEmpty) 'backgroundBindings': [
          for (final id in orderedBackgrounds)
            {'background': id, 'resourceId': 'gen5-background-$id'},
        ],
        if (orderedAnimations.isNotEmpty) 'backgroundAnimationBindings': [
          for (final id in orderedAnimations) {
            'animation': id, 'background': backgroundAnimations[id]!.background,
            'frames': backgroundFrameResources[id]!,
            'durations': backgroundAnimations[id]!.durations,
          },
        ]},
    })));
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1, 'projectMoveId': moveId, 'sourceMoveId': moveId,
      'catalogReleaseId': 'bw2-source-local', 'recipeId': recipeId,
      'variant': variant, 'revision': '1', 'recipeSha256': sha256.convert(recipeBytes).toString(),
    });
    final bundle = const BattleRecipeBundleInspector().inspect(binding, recipeBytes, media,
      limits: const BattleRecipeBundleLimits(maxTextures: 256, maxTextureBytes: 8 * 1024 * 1024,
        maxBundleBytes: 64 * 1024 * 1024, maxDimension: 2048, maxTexturePixels: 4000000,
        maxTotalPixels: 16000000),
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      expectedProjectMoveId: moveId, expectedCatalogReleaseId: 'bw2-source-local');
    return Gen5BatchRecipe(binding, bundle, Set.unmodifiable(warnings));
  }
}
