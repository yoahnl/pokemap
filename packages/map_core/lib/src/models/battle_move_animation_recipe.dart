import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'battle_recipe_json.dart';
import 'battle_spl_particle_definition.dart';

sealed class BattleRecipeAudio {
  const BattleRecipeAudio._();
}

final class BattleRecipeAudioNone extends BattleRecipeAudio {
  const BattleRecipeAudioNone._() : super._();
}

final class BattleRecipeAudioClip extends BattleRecipeAudio {
  const BattleRecipeAudioClip._(this.resourceId) : super._();

  final String resourceId;
}

final class BattleRecipeAudioOffset {
  const BattleRecipeAudioOffset._(this.ticks, this.ticksPerSecond);

  final int ticks;
  final int ticksPerSecond;
}

final class BattleRecipeAudioEvent {
  const BattleRecipeAudioEvent._(this.sourceId, this.resourceId, this.offset);

  final String sourceId;
  final String resourceId;
  final BattleRecipeAudioOffset offset;
}

final class BattleRecipeAudioSequence extends BattleRecipeAudio {
  BattleRecipeAudioSequence._(List<BattleRecipeAudioEvent> events)
    : events = List.unmodifiable(events),
      super._();

  final List<BattleRecipeAudioEvent> events;
}

final class BattleMoveAnimationRecipe {
  BattleMoveAnimationRecipe._(this._json, this.resources, this.audio);

  static const splV3RuntimeCapability = 'battle.spl-particle-v3@1';
  static const splV4RuntimeCapability = 'battle.spl-particle-v4@1';
  static const splV5RuntimeCapability = 'battle.spl-particle-v5@1';
  static const gen5MotionRuntimeCapability = 'battle.gen5-combatant-motion@1';

  static const recognizedCapabilities = {
    'sequence',
    'parallel',
    'wait',
    'sound',
    'cameraFocus',
    'cameraReset',
    'startParticle',
    'waitEffects',
    'splParticleV2',
    'splParticleV3',
    'splParticleV4',
    'splParticleV5',
    'audioSelectionV2',
    'gen5Swing',
    'gen5SpritePause',
  };
  final Map<String, dynamic> _json;
  final List<BattleMoveAnimationResource> resources;
  final BattleRecipeAudio? audio;

  int get schemaVersion => _json['schemaVersion'] as int;

  factory BattleMoveAnimationRecipe.fromJson(Map<String, dynamic> json) {
    final copy = (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>();
    _keys(copy, {
      'schemaVersion',
      'recipeId',
      'revision',
      'moveSourceId',
      'variant',
      'requiredCapabilities',
      'provenance',
      'resources',
      'program',
      if (copy['schemaVersion'] == 2) 'audio',
    });
    if (copy['schemaVersion'] is! int ||
        (copy['schemaVersion'] != 1 && copy['schemaVersion'] != 2)) {
      throw const FormatException('Unsupported schema');
    }
    final version = copy['schemaVersion'] as int;
    for (final key in ['recipeId', 'revision', 'moveSourceId', 'variant']) {
      _text(copy[key], key);
    }
    final required = _list(
      copy['requiredCapabilities'],
      'requiredCapabilities',
    );
    final capabilities = <String>{};
    for (final value in required) {
      final capability = _text(value, 'capability');
      if (!recognizedCapabilities.contains(capability) ||
          (version == 1 && {'audioSelectionV2', 'gen5Swing', 'gen5SpritePause'}.contains(capability)) ||
          !capabilities.add(capability)) {
        throw const FormatException('Unsupported or duplicate capability');
      }
    }
    if (version == 2 && !capabilities.contains('audioSelectionV2')) {
      throw const FormatException('Audio selection capability not declared');
    }
    final provenance = _map(copy['provenance'], 'provenance');
    _keys(provenance, {'source', 'sourceRevision', 'sourcePaths', 'converter'});
    for (final key in ['source', 'sourceRevision', 'converter']) {
      _text(provenance[key], key);
    }
    for (final path in _list(provenance['sourcePaths'], 'sourcePaths')) {
      _text(path, 'sourcePath');
    }
    final resources = <BattleMoveAnimationResource>[];
    final ids = <String>{};
    final resourceEntries = _list(copy['resources'], 'resources');
    if (resourceEntries.length > 256) {
      throw const FormatException('Too many resources');
    }
    for (final entry in resourceEntries) {
      final resource = BattleMoveAnimationResource.fromJson(
        _map(entry, 'resource'),
      );
      if (!ids.add(resource.id)) {
        throw const FormatException('Duplicate resource');
      }
      resources.add(resource);
    }
    for (final resource in resources) {
      if (resource.definitionVersion == 2 &&
          !capabilities.contains('splParticleV2')) {
        throw const FormatException('SPL particle capability not declared');
      }
      if (resource.definitionVersion == 3 &&
          !capabilities.contains('splParticleV3')) {
        throw const FormatException('SPL particle capability not declared');
      }
      if (resource.definitionVersion == 4 &&
          !capabilities.contains('splParticleV4')) {
        throw const FormatException('SPL particle capability not declared');
      }
      if (resource.definitionVersion == 5 &&
          !capabilities.contains('splParticleV5')) {
        throw const FormatException('SPL particle capability not declared');
      }
      for (final dependency in resource.dependencies) {
        if (!resources.any(
          (candidate) =>
              candidate.id == dependency && candidate.role == 'texture',
        )) {
          throw const FormatException('Missing particle texture');
        }
      }
    }
    BattleRecipeAudio? audio;
    if (version == 2) {
      final selection = _map(copy['audio'], 'audio');
      final kind = _text(selection['kind'], 'audio kind');
      final soundIds = {
        for (final resource in resources)
          if (resource.role == 'sound') resource.id,
      };
      String soundResource(Object? value) {
        final id = _audioText(value, 'audio resourceId');
        if (!soundIds.contains(id)) {
          throw const FormatException('Missing sound resource');
        }
        return id;
      }

      if (kind == 'none') {
        _keys(selection, {'kind'});
        if (capabilities.contains('sound')) {
          throw const FormatException('Silent audio declares sound');
        }
        audio = const BattleRecipeAudioNone._();
      } else if (kind == 'clip') {
        _keys(selection, {'kind', 'resourceId'});
        if (!capabilities.contains('sound')) {
          throw const FormatException('Sound capability not declared');
        }
        audio = BattleRecipeAudioClip._(soundResource(selection['resourceId']));
      } else if (kind == 'seq') {
        _keys(selection, {'kind', 'events'});
        if (!capabilities.contains('sound')) {
          throw const FormatException('Sound capability not declared');
        }
        final rawEvents = _list(selection['events'], 'audio events');
        if (rawEvents.isEmpty || rawEvents.length > 4096) {
          throw const FormatException('Invalid audio event count');
        }
        final events = <BattleRecipeAudioEvent>[];
        BattleRecipeAudioOffset? previous;
        for (final rawEvent in rawEvents) {
          final event = _map(rawEvent, 'audio event');
          _keys(event, {'sourceId', 'resourceId', 'offset'});
          final sourceId = _audioText(event['sourceId'], 'audio sourceId');
          final resourceId = soundResource(event['resourceId']);
          final rawOffset = _map(event['offset'], 'audio offset');
          _keys(rawOffset, {'ticks', 'ticksPerSecond'});
          final ticks = _audioInteger(rawOffset['ticks'], 0, 3600000000);
          final rate = _audioInteger(rawOffset['ticksPerSecond'], 1, 1000000);
          if (ticks > rate * 3600 ||
              (previous != null &&
                  previous.ticks * rate > ticks * previous.ticksPerSecond)) {
            throw const FormatException('Invalid audio event offset');
          }
          final offset = BattleRecipeAudioOffset._(ticks, rate);
          events.add(BattleRecipeAudioEvent._(sourceId, resourceId, offset));
          previous = offset;
        }
        audio = BattleRecipeAudioSequence._(events);
      } else {
        throw const FormatException('Unsupported audio kind');
      }
    }
    var count = 0;
    void validate(Object? node, int depth, bool inParallel) {
      if (depth > 32 || ++count > 4096) {
        throw const FormatException('Program too complex');
      }
      final step = _map(node, 'step');
      final kind = _text(step['kind'], 'kind');
      if (!capabilities.contains(kind)) {
        throw const FormatException('Undeclared capability');
      }
      switch (kind) {
        case 'sequence':
        case 'parallel':
          _keys(step, {'kind', 'steps'});
          final children = _list(step['steps'], 'steps');
          if (children.isEmpty) throw const FormatException('Empty group');
          for (final child in children) {
            validate(child, depth + 1, inParallel || kind == 'parallel');
          }
        case 'wait':
          _keys(step, {'kind', 'durationMs'});
          _duration(step);
        case 'cameraFocus':
          _keys(step, {'kind', 'target', 'durationMs'});
          if (!{'user', 'target', 'scene'}.contains(step['target'])) {
            throw const FormatException('Invalid camera target');
          }
          _duration(step);
        case 'cameraReset':
          _keys(step, {'kind', 'durationMs'});
          _duration(step);
        case 'sound':
          if (version == 2) {
            throw const FormatException('Sound step in v2 visual program');
          }
          _keys(step, {'kind', 'resourceId'});
          final id = _text(step['resourceId'], 'resourceId');
          if (!resources.any(
            (resource) => resource.id == id && resource.role == 'sound',
          )) {
            throw const FormatException('Missing sound resource');
          }
        case 'startParticle':
          _keys(step, {'kind', 'resourceId', 'from', 'to'});
          final id = _text(step['resourceId'], 'resourceId');
          if (!resources.any(
            (resource) =>
                resource.id == id && resource.role == 'particleDefinition',
          )) {
            throw const FormatException('Missing particle definition');
          }
          const anchors = {'userMouth', 'targetImpact'};
          if (!anchors.contains(step['from']) ||
              !anchors.contains(step['to'])) {
            throw const FormatException('Invalid particle anchor');
          }
        case 'waitEffects':
          _keys(step, {'kind'});
          if (inParallel) {
            throw const FormatException('Effect barrier inside parallel group');
          }
        case 'gen5Swing':
          _keys(step, {'kind', 'target', 'channel', 'x', 'y', 'frames', 'wait', 'count'});
          if (!{'user', 'target'}.contains(step['target']) ||
              !{'position', 'scale'}.contains(step['channel'])) {
            throw const FormatException('Invalid Gen 5 swing target or channel');
          }
          final min = step['channel'] == 'scale' ? -4095 : -65536;
          final max = step['channel'] == 'scale' ? 28672 : 65536;
          final x = _boundedInt(step['x'], min, max);
          final y = _boundedInt(step['y'], min, max);
          final frames = _boundedInt(step['frames'], 1, 600);
          final wait = _boundedInt(step['wait'], 0, 600);
          final count = _boundedInt(step['count'], 1, 32);
          if (frames * 2 * count * (wait + 1) - wait > 1800) {
            throw const FormatException('Gen 5 swing duration exceeds limit');
          }
          if (step['channel'] == 'scale') {
            for (final value in [x, y]) {
              final extreme = (((value * 1048576) ~/ frames + 524288) / 1048576).floor() * frames;
              if (extreme < -4095 || extreme > 28672) {
                throw const FormatException('Gen 5 swing scale exceeds limit');
              }
            }
          }
        case 'gen5SpritePause':
          _keys(step, {'kind', 'target', 'paused'});
          if (!{'user', 'target'}.contains(step['target']) || step['paused'] is! bool) {
            throw const FormatException('Invalid Gen 5 sprite pause');
          }
        default:
          throw const FormatException('Unsupported step');
      }
    }

    validate(copy['program'], 0, false);
    return BattleMoveAnimationRecipe._(
      copy,
      List.unmodifiable(resources),
      audio,
    );
  }

  Map<String, dynamic> toJson() =>
      (jsonDecode(jsonEncode(_json)) as Map).cast<String, dynamic>();

  bool get usesGen5Motion => _list(_json['requiredCapabilities'], 'requiredCapabilities')
      .any((value) => value == 'gen5Swing' || value == 'gen5SpritePause');

  Set<String> unsupportedCapabilities(Set<String> available) => _list(
    _json['requiredCapabilities'],
    'requiredCapabilities',
  ).cast<String>().toSet().difference(available);

  Set<String> verifyResources(Map<String, List<int>> bytesById) {
    return {
      for (final resource in resources)
        if (!resource.matches(bytesById[resource.id])) resource.id,
    };
  }

  void validateBundle(
    Map<String, List<int>> bytesById, {
    required Set<String> availableCapabilities,
  }) {
    _readVerifiedParticleDefinitions(
      bytesById,
      availableCapabilities: availableCapabilities,
    );
  }

  Map<String, BattleParticleDefinition> readVerifiedParticleDefinitions(
    Map<String, List<int>> bytesById, {
    required Set<String> availableCapabilities,
  }) {
    final result = _readVerifiedParticleDefinitions(
      bytesById,
      availableCapabilities: availableCapabilities,
    );
    if (result.spl.isNotEmpty) {
      throw const FormatException('Legacy particle reader cannot consume SPL');
    }
    return result.legacy;
  }

  Map<String, BattleSplParticleDefinition> readVerifiedSplParticleDefinitions(
    Map<String, List<int>> bytesById, {
    required Set<String> availableCapabilities,
  }) => _readVerifiedParticleDefinitions(
    bytesById,
    availableCapabilities: availableCapabilities,
  ).spl;

  ({
    Map<String, BattleParticleDefinition> legacy,
    Map<String, BattleSplParticleDefinition> spl,
  })
  _readVerifiedParticleDefinitions(
    Map<String, List<int>> bytesById, {
    required Set<String> availableCapabilities,
  }) {
    if (unsupportedCapabilities(availableCapabilities).isNotEmpty) {
      throw const FormatException('Unavailable recipe capability');
    }
    if (verifyResources(bytesById).isNotEmpty) {
      throw const FormatException('Missing or altered resource');
    }
    final result = <String, BattleParticleDefinition>{};
    final splResult = <String, BattleSplParticleDefinition>{};
    for (final resource in resources) {
      if (resource.role != 'particleDefinition') continue;
      final bytes = bytesById[resource.id]!;
      if (bytes.length > 262144) {
        throw const FormatException('Particle definition too large');
      }
      final decoded = decodeBoundedBattleJson(
        bytes,
        maxDepth: 16,
        label: 'Particle',
      );
      final definition = _map(decoded, 'particle definition');
      if (definition['schemaVersion'] is! int ||
          definition['schemaVersion'] != resource.definitionVersion) {
        throw const FormatException('Particle version mismatch');
      }
      if ({2, 3, 4, 5}.contains(resource.definitionVersion)) {
        final particle = BattleSplParticleDefinition.fromJson(definition);
        final declared = resource.dependencies.toSet();
        if (particle.textureIds.length != declared.length ||
            !declared.containsAll(particle.textureIds)) {
          throw const FormatException('Particle texture dependencies mismatch');
        }
        splResult[resource.id] = particle;
        continue;
      }
      _keys(definition, {'schemaVersion', 'emitters'});
      final emitters = _list(definition['emitters'], 'emitters');
      if (emitters.isEmpty || emitters.length > 32) {
        throw const FormatException('Invalid emitter count');
      }
      final textures = <String>{};
      final typedEmitters = <BattleParticleEmitterDefinition>[];
      var total = 0;
      for (final value in emitters) {
        final emitter = _map(value, 'emitter');
        _keys(emitter, {
          'textureId',
          'emissionDurationMs',
          'emissionIntervalMs',
          'particleLifetimeMs',
          'particlesPerEmission',
        });
        final textureId = _text(emitter['textureId'], 'textureId');
        textures.add(textureId);
        final duration = _boundedInt(emitter['emissionDurationMs'], 1, 60000);
        final interval = _boundedInt(emitter['emissionIntervalMs'], 1, 60000);
        final lifetime = _boundedInt(emitter['particleLifetimeMs'], 1, 60000);
        final count = _boundedInt(emitter['particlesPerEmission'], 1, 64);
        total += ((duration + interval - 1) ~/ interval) * count;
        if (total > 4096) {
          throw const FormatException('Particle emission limit exceeded');
        }
        typedEmitters.add(
          BattleParticleEmitterDefinition._(
            textureId,
            duration,
            interval,
            lifetime,
            count,
          ),
        );
      }
      final declared = resource.dependencies.toSet();
      if (textures.length != declared.length ||
          !declared.containsAll(textures)) {
        throw const FormatException('Particle texture dependencies mismatch');
      }
      result[resource.id] = BattleParticleDefinition._(
        List.unmodifiable(typedEmitters),
      );
    }
    return (legacy: Map.unmodifiable(result), spl: Map.unmodifiable(splResult));
  }
}

final class BattleParticleDefinition {
  const BattleParticleDefinition._(this.emitters);

  final List<BattleParticleEmitterDefinition> emitters;
}

final class BattleParticleEmitterDefinition {
  const BattleParticleEmitterDefinition._(
    this.textureId,
    this.emissionDurationMs,
    this.emissionIntervalMs,
    this.particleLifetimeMs,
    this.particlesPerEmission,
  );

  final String textureId;
  final int emissionDurationMs;
  final int emissionIntervalMs;
  final int particleLifetimeMs;
  final int particlesPerEmission;
}

int _boundedInt(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid particle parameter');
  }
  return value;
}

void _duration(Map<String, dynamic> step) {
  final duration = step['durationMs'];
  if (duration is! int || duration < 0 || duration > 60000) {
    throw const FormatException('Invalid duration');
  }
}

final class BattleMoveAnimationResource {
  const BattleMoveAnimationResource._(
    this.id,
    this.role,
    this.mediaType,
    this.sizeBytes,
    this.sha256Hex,
    this.dependencies,
    this.definitionVersion,
  );

  final String id;
  final String role;
  final String mediaType;
  final int sizeBytes;
  final String sha256Hex;
  final List<String> dependencies;
  final int? definitionVersion;

  factory BattleMoveAnimationResource.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'id',
      'role',
      'mediaType',
      'sizeBytes',
      'sha256',
      'dependencies',
      'definitionVersion',
    });
    final id = _text(json['id'], 'resource id');
    final role = _text(json['role'], 'resource role');
    final mediaType = _text(json['mediaType'], 'mediaType');
    final size = json['sizeBytes'];
    final hash = _text(json['sha256'], 'sha256');
    final definitionVersion = json['definitionVersion'];
    if ((role == 'particleDefinition' &&
            (definitionVersion is! int ||
                (definitionVersion != 1 &&
                    definitionVersion != 2 &&
                    definitionVersion != 3 &&
                    definitionVersion != 4 &&
                    definitionVersion != 5))) ||
        (role != 'particleDefinition' && definitionVersion != null)) {
      throw const FormatException('Unsupported particle definition version');
    }
    final validType = switch (role) {
      'sound' => mediaType.startsWith('audio/'),
      'texture' => mediaType == 'image/png',
      'particleDefinition' =>
        mediaType == 'application/vnd.avelune.particle+json',
      _ => false,
    };
    final dependencies = <String>[];
    if (role == 'particleDefinition' && !json.containsKey('dependencies')) {
      throw const FormatException('Particle dependencies must be declared');
    }
    if (json.containsKey('dependencies')) {
      if (role != 'particleDefinition') {
        throw const FormatException('Unexpected dependencies');
      }
      final unique = <String>{};
      for (final value in _list(json['dependencies'], 'dependencies')) {
        final dependency = _text(value, 'dependency');
        if (!unique.add(dependency)) {
          throw const FormatException('Duplicate dependency');
        }
        dependencies.add(dependency);
      }
    }
    if (!validType ||
        size is! int ||
        size < 0 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid resource');
    }
    return BattleMoveAnimationResource._(
      id,
      role,
      mediaType,
      size,
      hash,
      List.unmodifiable(dependencies),
      definitionVersion as int?,
    );
  }

  bool matches(List<int>? bytes) =>
      bytes != null &&
      bytes.length == sizeBytes &&
      sha256.convert(bytes).toString() == sha256Hex;
}

int _audioInteger(Object? value, int minimum, int maximum) {
  if (value is! int || value < minimum || value > maximum) {
    throw const FormatException('Invalid audio offset');
  }
  return value;
}

String _audioText(Object? value, String name) {
  final result = _text(value, name);
  if (result.length > 512 || _audioControlCharacters.hasMatch(result)) {
    throw FormatException('Invalid $name');
  }
  return result;
}

final _audioControlCharacters = RegExp(r'[\x00-\x1f\x7f]');

void _keys(Map<String, dynamic> object, Set<String> allowed) {
  if (object.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown field');
  }
}

Map<String, dynamic> _map(Object? value, String name) {
  if (value is! Map<String, dynamic>) throw FormatException('Invalid $name');
  return value;
}

List<dynamic> _list(Object? value, String name) {
  if (value is! List) throw FormatException('Invalid $name');
  return value;
}

String _text(Object? value, String name) {
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw FormatException('Invalid $name');
  }
  return value;
}
