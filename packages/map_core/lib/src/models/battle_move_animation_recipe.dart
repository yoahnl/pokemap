import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'battle_recipe_json.dart';

final class BattleMoveAnimationRecipe {
  BattleMoveAnimationRecipe._(this._json, this.resources);

  static const recognizedCapabilities = {
    'sequence',
    'parallel',
    'wait',
    'sound',
    'cameraFocus',
    'cameraReset',
    'startParticle',
    'waitEffects',
  };
  final Map<String, dynamic> _json;
  final List<BattleMoveAnimationResource> resources;

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
    });
    if (copy['schemaVersion'] is! int || copy['schemaVersion'] != 1) {
      throw const FormatException('Unsupported schema');
    }
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
          !capabilities.add(capability)) {
        throw const FormatException('Unsupported or duplicate capability');
      }
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
      for (final dependency in resource.dependencies) {
        if (!resources.any(
          (candidate) =>
              candidate.id == dependency && candidate.role == 'texture',
        )) {
          throw const FormatException('Missing particle texture');
        }
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
        default:
          throw const FormatException('Unsupported step');
      }
    }

    validate(copy['program'], 0, false);
    return BattleMoveAnimationRecipe._(copy, List.unmodifiable(resources));
  }

  Map<String, dynamic> toJson() =>
      (jsonDecode(jsonEncode(_json)) as Map).cast<String, dynamic>();

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
    readVerifiedParticleDefinitions(
      bytesById,
      availableCapabilities: availableCapabilities,
    );
  }

  Map<String, BattleParticleDefinition> readVerifiedParticleDefinitions(
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
      _keys(definition, {'schemaVersion', 'emitters'});
      if (definition['schemaVersion'] is! int ||
          definition['schemaVersion'] != resource.definitionVersion) {
        throw const FormatException('Particle version mismatch');
      }
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
    return Map.unmodifiable(result);
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
            (definitionVersion is! int || definitionVersion != 1)) ||
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
