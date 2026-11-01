import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

import 'gen5_battle_script_parameters.dart';
import 'gen5_battle_script_symbols.dart';

enum Gen5BattleSourceBlocker {
  recipeConverter,
  scriptScheduling,
  cameraPresets,
  paletteEffects,
  combatantMotion,
  particleRuntime,
  childParticles,
  missingTextures,
  soundPlayback,
  soundAutomation,
  unresolvedSymbols,
}

final class Gen5BattleTextureSource {
  const Gen5BattleTextureSource({
    required this.sourcePath,
    required this.sizeBytes,
    required this.sha256Hex,
    required this.bytes,
  });

  final String sourcePath;
  final int sizeBytes;
  final String sha256Hex;
  final Uint8List bytes;
}

final class Gen5BattleSourceDependencies {
  Gen5BattleSourceDependencies._({
    required this.particleId,
    required this.sourceRevision,
    required this.scriptPath,
    required this.scriptSha256,
    required this.particlePath,
    required this.particleSha256,
    required List<int> emitterOrder,
    required Map<int, Set<String>> texturesByEmitter,
    required Map<String, String> textureFormats,
    required Map<String, String> textureSha256ByName,
    required Set<String> requiredTextures,
    required Set<String> integrityCheckedTextures,
    required Set<String> missingTextures,
    required List<String> soundReferences,
    required Set<String> unresolvedSymbols,
    required Set<Gen5BattleSourceBlocker> blockers,
  })  : emitterOrder = List.unmodifiable(emitterOrder),
        texturesByEmitter = Map.unmodifiable({
          for (final entry in texturesByEmitter.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        }),
        textureFormats = Map.unmodifiable(textureFormats),
        textureSha256ByName = Map.unmodifiable(textureSha256ByName),
        requiredTextures = Set.unmodifiable(requiredTextures),
        integrityCheckedTextures = Set.unmodifiable(integrityCheckedTextures),
        missingTextures = Set.unmodifiable(missingTextures),
        soundReferences = List.unmodifiable(soundReferences),
        unresolvedSymbols = Set.unmodifiable(unresolvedSymbols),
        blockers = Set.unmodifiable(blockers);

  final int particleId;
  final String sourceRevision;
  final String scriptPath;
  final String scriptSha256;
  final String particlePath;
  final String particleSha256;
  final List<int> emitterOrder;
  final Map<int, Set<String>> texturesByEmitter;
  final Map<String, String> textureFormats;
  final Map<String, String> textureSha256ByName;
  final Set<String> requiredTextures;
  final Set<String> integrityCheckedTextures;
  final Set<String> missingTextures;
  final List<String> soundReferences;
  final Set<String> unresolvedSymbols;
  final Set<Gen5BattleSourceBlocker> blockers;

  void requireConvertible() {
    if (blockers.isNotEmpty) {
      throw StateError('Battle source has unsupported conversion capabilities');
    }
  }

  static final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static final _textureName = RegExp(r'^[A-Za-z0-9_]{1,64}$');

  static Gen5BattleSourceDependencies inspect({
    required Gen5BattleScriptParameters script,
    required int particleId,
    required Uint8List particleBytes,
    required String particleRevision,
    required String particlePath,
    required String particleSha256,
    Map<String, Gen5BattleTextureSource> textures = const {},
  }) {
    final directory = 'res/particles/btlv_effvm_particles/$particleId';
    if (particleId < 0 ||
        particleId > 65535 ||
        particleRevision != script.source.sourceRevision ||
        particlePath != '$directory/particles.json' ||
        particleBytes.isEmpty ||
        particleBytes.length > 262144 ||
        !_sha256Pattern.hasMatch(particleSha256)) {
      throw const FormatException('Invalid particle source identity');
    }
    final bytes = Uint8List.fromList(particleBytes);
    if (sha256.convert(bytes).toString() != particleSha256) {
      throw const FormatException('Invalid particle source digest');
    }
    final source = utf8.decode(bytes);
    try {
      const StrictJsonStructureValidator().validate(
        source,
        path: particlePath,
        maxDepth: 16,
        maxNodes: 30000,
      );
    } on GamePackageFormatException {
      throw const FormatException('Invalid particle source JSON');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid particle source document');
    }
    final rawEmitters = decoded['emitters'];
    final rawTextures = decoded['textures'];
    if (rawEmitters is! List ||
        rawEmitters.isEmpty ||
        rawEmitters.length > 32 ||
        rawTextures is! List ||
        rawTextures.isEmpty ||
        rawTextures.length > 64 ||
        textures.length > 64) {
      throw const FormatException('Invalid particle source inventory');
    }
    final declaredTextures = <String, String>{};
    for (final raw in rawTextures) {
      if (raw is! Map ||
          raw['name'] is! String ||
          !_textureName.hasMatch(raw['name'] as String) ||
          raw['format'] is! String ||
          !_textureName.hasMatch(raw['format'] as String) ||
          declaredTextures.containsKey(raw['name'])) {
        throw const FormatException('Invalid particle texture declaration');
      }
      declaredTextures[raw['name'] as String] = raw['format'] as String;
    }

    final allEmitterTextures = <int, Set<String>>{};
    final childEmitters = <int>{};
    for (var index = 0; index < rawEmitters.length; index++) {
      final raw = rawEmitters[index];
      if (raw is! Map) {
        throw const FormatException('Invalid particle emitter');
      }
      final dependencies = <String>{};
      void addTexture(Object? name) {
        if (name is! String || !declaredTextures.containsKey(name)) {
          throw const FormatException('Undeclared particle texture');
        }
        dependencies.add(name);
      }

      addTexture(raw['texture']);
      if (raw.containsKey('textureAnim')) {
        final animation = raw['textureAnim'];
        if (animation is! Map ||
            animation['textures'] is! List ||
            (animation['textures'] as List).isEmpty ||
            (animation['textures'] as List).length > 8) {
          throw const FormatException('Invalid particle texture animation');
        }
        for (final name in animation['textures'] as List) {
          addTexture(name);
        }
      }
      if (raw.containsKey('childResource')) {
        final child = raw['childResource'];
        if (child is! Map) {
          throw const FormatException('Invalid child particle resource');
        }
        addTexture(child['texture']);
        childEmitters.add(index);
      }
      allEmitterTextures[index] = dependencies;
    }

    final emitterOrder = <int>[];
    final soundReferences = <String>[];
    final blockers = <Gen5BattleSourceBlocker>{
      Gen5BattleSourceBlocker.recipeConverter,
      Gen5BattleSourceBlocker.scriptScheduling,
    };
    var loaded = false;
    int number(Gen5BattleOperand? operand) {
      if (operand is! Gen5BattleNumberOperand || operand.signedWord < 0) {
        throw const FormatException('Unresolved particle operand');
      }
      return operand.unsignedWord;
    }

    for (final instruction in script.instructions) {
      switch (instruction.instruction.name) {
        case 'ParticleLoad':
          if (number(instruction.parameters['particle']) != particleId) {
            throw const FormatException(
                'Particle source does not match script');
          }
          loaded = true;
        case 'EmitterMove':
        case 'EmitterAdd':
          if (!loaded ||
              number(instruction.parameters['particle']) != particleId) {
            throw const FormatException(
                'Emitter particle source is unavailable');
          }
          final index = number(instruction.parameters['emitter']);
          if (!allEmitterTextures.containsKey(index)) {
            throw const FormatException('Unknown particle emitter');
          }
          emitterOrder.add(index);
          blockers.add(Gen5BattleSourceBlocker.particleRuntime);
          if (childEmitters.contains(index)) {
            blockers.add(Gen5BattleSourceBlocker.childParticles);
          }
        case 'PlaySE':
          final operand = instruction.parameters['se']!;
          soundReferences.add(operand.raw);
          blockers.add(Gen5BattleSourceBlocker.soundPlayback);
        case 'MoveSE':
        case 'PanSE':
          blockers.add(Gen5BattleSourceBlocker.soundAutomation);
        case 'CameraMovePreset':
          blockers.add(Gen5BattleSourceBlocker.cameraPresets);
        case 'PaletteFade':
        case 'McssPalFade':
          blockers.add(Gen5BattleSourceBlocker.paletteEffects);
        case 'McssMoveXY':
          blockers.add(Gen5BattleSourceBlocker.combatantMotion);
      }
    }
    if (!loaded || emitterOrder.isEmpty) {
      throw const FormatException('No particle emitter in battle script');
    }
    final byEmitter = {
      for (final index in emitterOrder.toSet())
        index: allEmitterTextures[index]!,
    };
    final required = {for (final values in byEmitter.values) ...values};
    final verified = <String>{};
    final textureDigests = <String, String>{};
    var totalBytes = 0;
    var totalPixels = 0;
    for (final entry in textures.entries) {
      final texture = entry.value;
      if (!declaredTextures.containsKey(entry.key) ||
          texture.sourcePath != '$directory/${entry.key}.png' ||
          texture.bytes.isEmpty ||
          texture.bytes.length > 4 * 1024 * 1024 ||
          texture.bytes.length != texture.sizeBytes ||
          !_sha256Pattern.hasMatch(texture.sha256Hex)) {
        throw const FormatException('Invalid particle texture source');
      }
      totalBytes += texture.bytes.length;
      if (totalBytes > 16 * 1024 * 1024) {
        throw const FormatException('Particle textures exceed byte budget');
      }
      final snapshot = Uint8List.fromList(texture.bytes);
      if (sha256.convert(snapshot).toString() != texture.sha256Hex) {
        throw const FormatException('Invalid particle texture digest');
      }
      final dimensions =
          decodeRasterImageDimensions(snapshot, mediaType: 'image/png');
      if (dimensions == null ||
          dimensions.width > 1024 ||
          dimensions.height > 1024 ||
          dimensions.width * dimensions.height > 1048576) {
        throw const FormatException('Invalid particle texture dimensions');
      }
      totalPixels += dimensions.width * dimensions.height;
      if (totalPixels > 4194304) {
        throw const FormatException('Particle textures exceed pixel budget');
      }
      verified.add(entry.key);
      textureDigests[entry.key] = texture.sha256Hex;
    }
    final missing = required.difference(verified);
    if (missing.isNotEmpty) {
      blockers.add(Gen5BattleSourceBlocker.missingTextures);
    }
    final unresolved =
        Gen5BattleScriptSymbols.resolve(script).unresolvedSymbols;
    for (final instruction in script.instructions) {
      for (final entry in instruction.parameters.entries) {
        final operand = entry.value;
        if (operand is Gen5BattleSymbolOperand &&
            unresolved.contains(operand.symbol) &&
            !(instruction.instruction.name == 'PlaySE' && entry.key == 'se')) {
          blockers.add(Gen5BattleSourceBlocker.unresolvedSymbols);
        }
      }
    }
    return Gen5BattleSourceDependencies._(
      particleId: particleId,
      sourceRevision: particleRevision,
      scriptPath: script.source.sourcePath,
      scriptSha256: script.source.sha256Hex,
      particlePath: particlePath,
      particleSha256: particleSha256,
      emitterOrder: emitterOrder,
      texturesByEmitter: byEmitter,
      textureFormats: declaredTextures,
      textureSha256ByName: textureDigests,
      requiredTextures: required,
      integrityCheckedTextures: verified,
      missingTextures: missing,
      soundReferences: soundReferences,
      unresolvedSymbols: unresolved,
      blockers: blockers,
    );
  }
}
