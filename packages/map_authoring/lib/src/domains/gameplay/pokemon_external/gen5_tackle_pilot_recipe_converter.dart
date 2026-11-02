import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'avelune_gen5_move_source.dart';
import 'gen5_battle_script_parameters.dart';
import 'gen5_battle_script_source.dart';
import 'gen5_spl_particle_converter.dart';

final class Gen5TacklePilotRecipe {
  const Gen5TacklePilotRecipe._(this.binding, this.bundle);
  final BattleMoveRecipeBinding binding;
  final InspectedBattleRecipeBundle bundle;
  List<String> get limitations => const [
        'Camera framing is adapted and not compared with BW2.',
        'Emitter offsets, motion projection and individual script scheduling are approximated.',
        'The supplied clip replaces the original individual sound commands.',
        'Source redistribution rights are unverified.',
      ];
}

abstract final class Gen5TacklePilotRecipeConverter {
  static const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
  static const _scriptHash =
      '7e4efb20a66db06afb4611900c65796e60401d02cd49e5d9e7a35fa6e40d441c';

  static Gen5TacklePilotRecipe convert({
    required AveluneGen5MoveSourceSnapshot snapshot,
    required String projectMoveId,
    required Uint8List soundBytes,
    required String soundMediaType,
  }) {
    if (snapshot.moveId != 'tackle' || snapshot.sourceMoveId != 33) {
      throw const FormatException('Unsupported Tackle pilot source');
    }
    return Gen5CommonImpactRecipeConverter.convert(
      snapshot: snapshot,
      projectMoveId: projectMoveId,
      soundBytes: soundBytes,
      soundMediaType: soundMediaType,
    );
  }
}

abstract final class Gen5CommonImpactRecipeConverter {
  static List<Gen5ImpactBatchResult> convertBatch(
      List<Gen5ImpactBatchInput> inputs) {
    if (inputs.isEmpty ||
        inputs.length > 559 ||
        inputs.map((input) => input.projectMoveId).toSet().length !=
            inputs.length) {
      throw ArgumentError('Invalid BW2 impact batch');
    }
    return List.unmodifiable(inputs.map((input) {
      try {
        return Gen5ImpactBatchResult._(
            input.projectMoveId,
            convert(
              snapshot: input.snapshot,
              projectMoveId: input.projectMoveId,
              soundBytes: input.soundBytes,
              soundMediaType: input.soundMediaType,
            ),
            null);
      } on FormatException catch (error) {
        return Gen5ImpactBatchResult._(
            input.projectMoveId, null, error.message);
      }
    }));
  }

  static Gen5TacklePilotRecipe convert({
    required AveluneGen5MoveSourceSnapshot snapshot,
    required String projectMoveId,
    required Uint8List soundBytes,
    required String soundMediaType,
  }) {
    final profile = switch ((snapshot.sourceMoveId, snapshot.moveId)) {
      (33, 'tackle') => (
          hash: Gen5TacklePilotRecipeConverter._scriptHash,
          particle: 199,
          scale: 7,
          attack: 2,
          reset: 14
        ),
      (1, 'pound') => (
          hash:
              'b35c998a2418f20b992c88948eec4c3d45e946eea0ce17af76c6f1f1369c298f',
          particle: 165,
          scale: 10,
          attack: -1,
          reset: 13
        ),
      (21, 'slam') => (
          hash:
              '62ad743f1f4c2d458e75fa5151a4481806d213493a06675aacfc150d05978d7f',
          particle: 187,
          scale: 7,
          attack: 2,
          reset: 14
        ),
      (2, 'karate-chop') => (
          hash:
              '1e17a2d6cfb536a5531d267ab80f28f58b75c9c9991903e7192588771e043012',
          particle: 166,
          scale: 6,
          attack: -1,
          reset: 12
        ),
      (398, 'poison-jab') => (
          hash:
              '9c776959829b90112cefc614fafe5a8171c36010d6e8194876aeea0acf5eaaf4',
          particle: 577,
          scale: 21,
          attack: -1,
          reset: 24
        ),
      _ => throw const FormatException('Unsupported BW2 impact source'),
    };
    final particlePath =
        'res/particles/btlv_effvm_particles/${profile.particle}/particles.json';
    if (snapshot.sourceRevision != Gen5TacklePilotRecipeConverter._revision ||
        snapshot.scriptSha256 != profile.hash ||
        snapshot.scriptPath !=
            'res/battle/animations/moves/${snapshot.moveId.replaceAll('-', '_')}.s' ||
        snapshot.effectiveDependencyStatus != 'complete' ||
        !snapshot.particleDependencyInventoryVerified ||
        snapshot.particles.length != 1 ||
        !snapshot.particles.containsKey(profile.particle) ||
        !{'audio/mpeg', 'audio/wav'}.contains(soundMediaType)) {
      throw const FormatException('Unsupported Tackle pilot source');
    }
    final script = Gen5BattleScriptParameters.read(Gen5BattleScriptSource.read(
      snapshot.scriptBytes,
      sourceRevision: snapshot.sourceRevision,
      sourcePath: snapshot.scriptPath,
      expectedSha256: profile.hash,
    ));
    int number(int index, String key) {
      final operand = script.instructions[index].parameters[key];
      if (operand is! Gen5BattleNumberOperand) {
        throw const FormatException('Expected numeric Tackle operand');
      }
      return operand.signedWord;
    }

    final particle = snapshot.particles[profile.particle]!;
    for (final entry in particle.textureBytes.entries) {
      if (sha256.convert(entry.value).toString() !=
          particle.textureSha256[entry.key]) {
        throw const FormatException('Tackle texture digest mismatch');
      }
    }
    final converted = Gen5SplParticleConverter.convert(
      particle.definitionBytes,
      particleId: profile.particle,
      sourceRevision: snapshot.sourceRevision,
      sourcePath: particlePath,
      expectedSha256: particle.definitionSha256,
      textureResourceIds: {
        for (final name in particle.textureBytes.keys) name: name
      },
    );
    if (!{2, 3, 4}.contains(converted.definition.schemaVersion) ||
        converted.definition.emitters.length != 2) {
      throw const FormatException('Unsupported Tackle particle definition');
    }
    final definitionBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(converted.definition.toJson())));
    final textures = converted.definition.textureIds.toList()..sort();
    final media = <String, Uint8List>{
      for (final id in textures) id: particle.textureBytes[id]!,
      'impact': definitionBytes,
      'cue': Uint8List.fromList(soundBytes),
    };
    Map<String, Object> resource(String id, String role, String mediaType) => {
          'id': id,
          'role': role,
          'mediaType': mediaType,
          'sizeBytes': media[id]!.length,
          'sha256': sha256.convert(media[id]!).toString(),
        };
    Map<String, Object> swing(int index, String target, String channel) => {
          'kind': 'gen5Swing',
          'target': target,
          'channel': channel,
          'x': number(index, 'x'),
          'y': number(index, 'y'),
          'frames': number(index, 'frames'),
          'wait': number(index, 'wait'),
          'count': number(index, 'times'),
        };
    final recipe = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 2,
      'recipeId': 'bw2-${snapshot.moveId}-pilot',
      'revision': '1',
      'moveSourceId': snapshot.moveId,
      'variant': 'default',
      'requiredCapabilities': [
        'sequence',
        'parallel',
        'cameraFocus',
        'cameraReset',
        'gen5SpritePause',
        'gen5Swing',
        'startParticle',
        'waitEffects',
        switch (converted.definition.schemaVersion) {
          4 => 'splParticleV4',
          3 => 'splParticleV3',
          _ => 'splParticleV2',
        },
        'sound',
        'audioSelectionV2',
      ],
      'provenance': {
        'source': 'fuddlesworth/pokebw2',
        'sourceRevision': Gen5TacklePilotRecipeConverter._revision,
        'sourcePaths': [snapshot.scriptPath, particlePath],
        'converter': 'common-impact-pilot-partial/1'
      },
      'resources': [
        for (final id in textures) resource(id, 'texture', 'image/png'),
        {
          ...resource('impact', 'particleDefinition',
              'application/vnd.avelune.particle+json'),
          'definitionVersion': converted.definition.schemaVersion,
          'dependencies': textures
        },
        resource('cue', 'sound', soundMediaType),
      ],
      'audio': {'kind': 'clip', 'resourceId': 'cue'},
      'program': {
        'kind': 'sequence',
        'steps': [
          {
            'kind': 'cameraFocus',
            'target': 'target',
            'durationMs': (number(0, 'frames') * 1000 + 30) ~/ 60
          },
          {'kind': 'gen5SpritePause', 'target': 'target', 'paused': true},
          {
            'kind': 'parallel',
            'steps': [
              {
                'kind': 'startParticle',
                'resourceId': 'impact',
                'from': 'targetImpact',
                'to': 'targetImpact'
              },
              if (profile.attack >= 0)
                swing(profile.attack, 'user', 'position'),
              swing(profile.scale, 'target', 'scale'),
            ]
          },
          {'kind': 'waitEffects'},
          {'kind': 'gen5SpritePause', 'target': 'target', 'paused': false},
          {
            'kind': 'cameraReset',
            'durationMs': (number(profile.reset, 'frames') * 1000 + 30) ~/ 60
          },
        ]
      },
    })));
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': projectMoveId,
      'sourceMoveId': snapshot.moveId,
      'catalogReleaseId': snapshot.release,
      'recipeId': 'bw2-${snapshot.moveId}-pilot',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': sha256.convert(recipe).toString(),
    });
    final bundle = const BattleRecipeBundleInspector().inspect(
      binding,
      recipe,
      media,
      limits: const BattleRecipeBundleLimits(
          maxTextures: 16,
          maxTextureBytes: 8 * 1024 * 1024,
          maxBundleBytes: 32 * 1024 * 1024,
          maxDimension: 2048,
          maxTexturePixels: 4000000,
          maxTotalPixels: 16000000),
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
      expectedProjectMoveId: projectMoveId,
      expectedCatalogReleaseId: snapshot.release,
    );
    return Gen5TacklePilotRecipe._(binding, bundle);
  }
}

final class Gen5ImpactBatchInput {
  const Gen5ImpactBatchInput(
      {required this.snapshot,
      required this.projectMoveId,
      required this.soundBytes,
      required this.soundMediaType});
  final AveluneGen5MoveSourceSnapshot snapshot;
  final String projectMoveId;
  final Uint8List soundBytes;
  final String soundMediaType;
}

final class Gen5ImpactBatchResult {
  const Gen5ImpactBatchResult._(
      this.projectMoveId, this.recipe, this.failureReason);
  final String projectMoveId;
  final Gen5TacklePilotRecipe? recipe;
  final String? failureReason;
}
