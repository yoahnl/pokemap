import 'dart:convert';

import 'package:crypto/crypto.dart';

final class BattleMoveAnimationRecipe {
  BattleMoveAnimationRecipe._(this._json, this.resources);

  static const supportedCapabilities = {
    'sequence',
    'parallel',
    'wait',
    'sound',
    'cameraFocus',
    'cameraReset',
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
    if (copy['schemaVersion'] != 1) {
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
      if (!supportedCapabilities.contains(capability) ||
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
    var count = 0;
    void validate(Object? node, int depth) {
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
            validate(child, depth + 1);
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
        default:
          throw const FormatException('Unsupported step');
      }
    }

    validate(copy['program'], 0);
    return BattleMoveAnimationRecipe._(copy, List.unmodifiable(resources));
  }

  Map<String, dynamic> toJson() =>
      (jsonDecode(jsonEncode(_json)) as Map).cast<String, dynamic>();

  Set<String> verifyResources(Map<String, List<int>> bytesById) {
    return {
      for (final resource in resources)
        if (!resource.matches(bytesById[resource.id])) resource.id,
    };
  }
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
  );

  final String id;
  final String role;
  final String mediaType;
  final int sizeBytes;
  final String sha256Hex;

  factory BattleMoveAnimationResource.fromJson(Map<String, dynamic> json) {
    _keys(json, {'id', 'role', 'mediaType', 'sizeBytes', 'sha256'});
    final id = _text(json['id'], 'resource id');
    final role = _text(json['role'], 'resource role');
    final mediaType = _text(json['mediaType'], 'mediaType');
    final size = json['sizeBytes'];
    final hash = _text(json['sha256'], 'sha256');
    if (role != 'sound' ||
        !mediaType.startsWith('audio/') ||
        size is! int ||
        size < 0 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid resource');
    }
    return BattleMoveAnimationResource._(id, role, mediaType, size, hash);
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
