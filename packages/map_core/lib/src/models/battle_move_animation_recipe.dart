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
  static const gen5SourceRuntimeCapability = 'battle.gen5-source-program@1';
  static const gen5SourceBackgroundAnimationRuntimeCapability =
      'battle.gen5-source-background-animation@1';
  static const gen5SourceOperations = {
    'moveCameraPreset', 'moveCameraRelative', 'moveCameraAbsolute', 'shakeCamera',
    'loadParticle', 'deleteParticle', 'setSourceGauge', 'startEmitter',
    'startFieldEmitter', 'startOrthoEmitter', 'startMovingEmitter',
    'startMovingOrthoEmitter', 'startMovingFieldEmitter', 'startOrbitEmitter',
    'moveCombatant', 'setActorCameraMode', 'circleCombatant', 'scaleCombatant',
    'rotateCombatant', 'setAnimationState', 'setCombatantVisibility',
    'fadeCombatantAlpha', 'fadePalette', 'fadeStagePalette', 'setShadow',
    'loadBackground', 'moveBackground', 'waveBackground', 'animateBackgroundPalette',
    'setSceneVisibility', 'playCry', 'playSound', 'panSound', 'moveSound',
    'waitTasks', 'waitFrames', 'setYield', 'end',
  };

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
    'splParticleV6',
    'splParticleV7',
    'splParticleV8',
    'splParticleV9',
    'splParticleV10',
    'splParticleV11',
    'splParticleV12',
    'splParticleV13',
    'splParticleV14',
    'splParticleV15',
    'splParticleV16',
    'splParticleV17',
    'splParticleV18',
    'splParticleV19',
    'audioSelectionV2',
    'gen5Swing',
    'gen5SpritePause',
    'gen5SourceProgram',
    'gen5SourceBackground',
    'gen5SourceBackgroundAnimation',
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
      final definitionVersion = resource.definitionVersion;
      if (definitionVersion != null && definitionVersion >= 2 &&
          !capabilities.contains('splParticleV$definitionVersion')) {
        throw const FormatException('SPL particle capability not declared');
      }
      if (definitionVersion != null && definitionVersion > 5 &&
          (version != 2 || _map(copy['program'], 'step')['kind'] != 'gen5SourceProgram')) {
        throw const FormatException('Experimental particles require a source program');
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
        case 'gen5SourceProgram':
          if (version != 2 || depth != 0) {
            throw const FormatException('Invalid Gen 5 source program location');
          }
          if (step.containsKey('backgroundBindings') &&
              !capabilities.contains('gen5SourceBackground')) {
            throw const FormatException('Source background capability not declared');
          }
          if (step.containsKey('backgroundAnimationBindings') !=
              capabilities.contains('gen5SourceBackgroundAnimation') ||
              (capabilities.contains('gen5SourceBackgroundAnimation') &&
                  !capabilities.contains('gen5SourceBackground'))) {
            throw const FormatException('Source background animation capability mismatch');
          }
          _validateGen5SourceProgram(step, copy['variant'] as String, resources);
        default:
          throw const FormatException('Unsupported step');
      }
    }

    if (capabilities.contains('gen5SourceProgram') !=
        (_map(copy['program'], 'program')['kind'] == 'gen5SourceProgram')) {
      throw const FormatException('Gen 5 source capability does not match program');
    }
    if (capabilities.contains('gen5SourceBackgroundAnimation') &&
        !capabilities.contains('gen5SourceProgram')) {
      throw const FormatException('Source background animation requires a source program');
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

  bool get usesGen5SourceProgram =>
      _list(_json['requiredCapabilities'], 'requiredCapabilities')
          .contains('gen5SourceProgram');

  bool get usesGen5SourceBackgroundAnimation =>
      _list(_json['requiredCapabilities'], 'requiredCapabilities')
          .contains('gen5SourceBackgroundAnimation');

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
      final definitionVersion = resource.definitionVersion!;
      if (definitionVersion >= 2 && definitionVersion <= 19) {
        final particle = definitionVersion > 5
            ? BattleSplParticleDefinition.fromExperimentalJson(definition)
            : BattleSplParticleDefinition.fromJson(definition);
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
    if (usesGen5SourceProgram) {
      final program = _map(_json['program'], 'source program step');
      for (final value in _list(program['particleBindings'], 'particle bindings')) {
        final binding = _map(value, 'particle binding');
        final definition = splResult[binding['resourceId']];
        if (definition == null || definition.emitters.length !=
            _list(binding['sourceEmitterIndices'], 'source emitter indices').length) {
          throw const FormatException('Source emitter mapping does not match definition');
        }
      }
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
                definitionVersion < 1 || definitionVersion > 19)) ||
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

void _validateGen5SourceProgram(
  Map<String, dynamic> step,
  String variant,
  List<BattleMoveAnimationResource> resources,
) {
  _keys(step, {'kind', 'sourceProgram', 'particleBindings', 'backgroundBindings',
    'backgroundAnimationBindings'});
  final source = _map(step['sourceProgram'], 'source program');
  var valueCount = 0;
  var stringUnits = 0;
  void bounded(Object? value, int depth) {
    if (depth > 16 || ++valueCount > 65536) {
      throw const FormatException('Source program exceeds limits');
    }
    if (value is String) {
      stringUnits += value.length;
      if (value.length > 4096 || stringUnits > 262144) {
        throw const FormatException('Source program exceeds string limits');
      }
    } else if (value is Map) {
      if (value.length > 4096) throw const FormatException('Source program map too large');
      for (final entry in value.entries) {
        if (entry.key is! String) throw const FormatException('Invalid source program key');
        bounded(entry.key, depth + 1);
        bounded(entry.value, depth + 1);
      }
    } else if (value is List) {
      if (value.length > 4096) throw const FormatException('Source program list too large');
      for (final item in value) { bounded(item, depth + 1); }
    } else if (value is int) {
      if (value.abs() > 9007199254740991) {
        throw const FormatException('Invalid source program integer');
      }
    } else if (value != null && value is! bool) {
      throw const FormatException('Invalid source program value');
    }
  }
  bounded(source, 0);
  if (source['kind'] != 'gen5SourceProgram' || source['timebaseHz'] != 60 ||
      source['conversion'] != 'supported' || source['variant'] != variant) {
    throw const FormatException('Invalid source program identity');
  }
  final variants = _list(source['variants'], 'source variants');
  final labels = _list(source['labels'], 'source labels');
  final instructions = _list(source['instructions'], 'source instructions');
  final entry = source['entryIndex'];
  if (variants.isEmpty || variants.length > 1024 || labels.isEmpty ||
      labels.length > 1024 || instructions.isEmpty || instructions.length > 1024 ||
      entry is! int || entry < 0 || entry >= instructions.length) {
    throw const FormatException('Invalid source program bounds');
  }
  final names = <String>{};
  for (final value in variants) {
    if (!names.add(_audioText(value, 'source variant'))) {
      throw const FormatException('Duplicate source variant');
    }
  }
  if (!names.contains(variant)) throw const FormatException('Unknown source variant');
  final labelNames = <String>{};
  final variantEntries = <String, int>{};
  final variantIndices = <int>{};
  var lastIndex = -1;
  var variantEnd = instructions.length;
  for (final value in labels) {
    final label = _map(value, 'source label');
    final name = _audioText(label['name'], 'source label name');
    final index = label['instructionIndex'];
    if (!labelNames.add(name) || index is! int || index < lastIndex ||
        index < 0 || index > instructions.length) {
      throw const FormatException('Invalid source label');
    }
    lastIndex = index;
    if (names.contains(name)) {
      if (index >= instructions.length || !variantIndices.add(index)) {
        throw const FormatException('Invalid source variant entry');
      }
      variantEntries[name] = index;
      if (index > entry && index < variantEnd) variantEnd = index;
    }
  }
  if (variantEntries.length != names.length || variantEntries[variant] != entry) {
    throw const FormatException('Invalid source variant entry');
  }
  final bindings = _list(step['particleBindings'], 'particle bindings');
  if (bindings.length > 256) throw const FormatException('Too many particle bindings');
  final particleIndices = <int, Set<int>>{};
  for (final value in bindings) {
    final binding = _map(value, 'particle binding');
    _keys(binding, {'particle', 'resourceId', 'sourceEmitterIndices'});
    final particle = _boundedInt(binding['particle'], 0, 65535);
    final id = _audioText(binding['resourceId'], 'particle resourceId');
    if (particleIndices.containsKey(particle) || !resources.any(
      (resource) => resource.id == id && resource.role == 'particleDefinition' &&
          resource.definitionVersion != null &&
          resource.definitionVersion! >= 2 && resource.definitionVersion! <= 19,
    )) {
      throw const FormatException('Invalid source particle binding');
    }
    final indices = _list(binding['sourceEmitterIndices'], 'source emitter indices');
    if (indices.isEmpty || indices.length > 32) {
      throw const FormatException('Invalid source emitter indices');
    }
    final unique = <int>{};
    for (final index in indices) {
      if (!unique.add(_boundedInt(index, 0, 65535))) {
        throw const FormatException('Duplicate source emitter index');
      }
    }
    particleIndices[particle] = unique;
  }
  final backgroundIds = <int>{};
  final backgrounds = step['backgroundBindings'];
  if (backgrounds != null) {
    if (backgrounds is! List || backgrounds.length > 256) {
      throw const FormatException('Invalid source background bindings');
    }
    for (final value in backgrounds) {
      final binding = _map(value, 'background binding');
      _keys(binding, {'background', 'resourceId'});
      final background = _boundedInt(binding['background'], 0, 65535);
      final resourceId = _audioText(binding['resourceId'], 'background resourceId');
      if (!backgroundIds.add(background) || !resources.any(
        (resource) => resource.id == resourceId && resource.role == 'texture',
      )) {
        throw const FormatException('Invalid source background binding');
      }
    }
  }
  final animationIds = <int>{};
  final animations = step['backgroundAnimationBindings'];
  if (animations != null) {
    if (animations is! List || animations.isEmpty || animations.length > 32) {
      throw const FormatException('Invalid source background animations');
    }
    for (final value in animations) {
      final animation = _map(value, 'background animation');
      _keys(animation, {'animation', 'background', 'frames', 'durations'});
      final animationId = _boundedInt(animation['animation'], 0, 65535);
      final background = _boundedInt(animation['background'], 0, 65535);
      final frames = _list(animation['frames'], 'background animation frames');
      final durations = _list(animation['durations'], 'background animation durations');
      if (!animationIds.add(animationId) || !backgroundIds.contains(background) ||
          frames.isEmpty || frames.length > 32 || frames.length != durations.length) {
        throw const FormatException('Invalid source background animation');
      }
      for (var i = 0; i < frames.length; i++) {
        final id = _audioText(frames[i], 'background animation frame');
        _boundedInt(durations[i], 0, 255);
        if (!resources.any((resource) => resource.id == id && resource.role == 'texture')) {
          throw const FormatException('Missing source background animation frame');
        }
      }
    }
  }
  for (final value in instructions) {
    final instruction = _map(value, 'source instruction');
    _audioText(instruction['op'], 'source operation');
    _map(instruction['args'], 'source arguments');
    _map(instruction['source'], 'source instruction metadata');
  }
  var ended = false;
  for (var index = entry; index < variantEnd; index++) {
    final instruction = _map(instructions[index], 'source instruction');
    final op = instruction['op'] as String;
    final args = _map(instruction['args'], 'source arguments');
    if (!BattleMoveAnimationRecipe.gen5SourceOperations.contains(op)) {
      throw const FormatException('Unsupported source operation');
    }
    if (animations != null && op == 'animateBackgroundPalette' &&
        !animationIds.contains(_boundedInt(args['animation'], 0, 65535))) {
      throw const FormatException('Missing source background animation');
    }
    if (op == 'loadParticle' || op == 'deleteParticle' ||
        (op.startsWith('start') && op.endsWith('Emitter'))) {
      final particle = _boundedInt(args['particle'], 0, 65535);
      final indices = particleIndices[particle];
      if (indices == null || (op.startsWith('start') &&
          !indices.contains(_boundedInt(args['emitter'], 0, 65535)))) {
        throw const FormatException('Missing source particle or emitter binding');
      }
    }
    if (op == 'end') {
      if (args.isNotEmpty) throw const FormatException('Invalid source end');
      ended = true;
      break;
    }
  }
  if (!ended) throw const FormatException('Source variant has no end');
}

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
