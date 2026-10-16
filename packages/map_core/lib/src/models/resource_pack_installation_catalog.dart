import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'resource_pack.dart';

enum ResourcePackSupportKind {
  resourceFamily,
  elementCategory,
  tilesetFolder,
  tilesetElementGroup,
  smartTileMaterial,
  smartTileAtlas,
  smartTileAnimation,
  smartTileCategory,
  smartTilePattern,
  smartTileConnectionGroup,
  characterPortraitState,
  characterAnimationDefinition,
  borderSnapshot,
}

enum ResourcePackProvenanceStatus { unqualified, declared, qualified }

abstract class _InstallationJsonValue {
  const _InstallationJsonValue();
  Map<String, Object?> toJson();

  @override
  bool operator ==(Object other) =>
      runtimeType == other.runtimeType &&
      other is _InstallationJsonValue &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(toJson()));
}

final class ResourcePackResourceMapping extends _InstallationJsonValue {
  ResourcePackResourceMapping({
    required this.source,
    required String targetId,
    required String definitionRawSha256,
  }) : targetId = _identifier(targetId, 'mapping.targetId'),
       definitionRawSha256 = _digest(definitionRawSha256) {
    if (source.kind == ResourcePackKind.model3d &&
        (targetId.length > 128 ||
            !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(targetId))) {
      throw const FormatException('Invalid model3d mapping target identity');
    }
  }

  factory ResourcePackResourceMapping.fromJson(Map<String, Object?> json) {
    _keys(json, {'source', 'targetId', 'definitionRawSha256'});
    return ResourcePackResourceMapping(
      source: ResourcePackRef.fromJson(_object(json['source'])),
      targetId: _string(json['targetId']),
      definitionRawSha256: _string(json['definitionRawSha256']),
    );
  }

  final ResourcePackRef source;
  final String targetId;
  final String definitionRawSha256;
  String get targetIdentity => '${source.kind.name}:$targetId';

  @override
  Map<String, Object?> toJson() => {
    'source': source.toJson(),
    'targetId': targetId,
    'definitionRawSha256': definitionRawSha256,
  };
}

final class ResourcePackSupportMapping extends _InstallationJsonValue {
  ResourcePackSupportMapping({
    required this.kind,
    required String sourceId,
    required String targetId,
    this.owner,
    String? targetOwnerId,
  }) : sourceId = _portableIdentifier(sourceId),
       targetId = _identifier(targetId, 'support.targetId'),
       targetOwnerId = targetOwnerId == null
           ? null
           : _identifier(targetOwnerId, 'support.targetOwnerId') {
    if (kind == ResourcePackSupportKind.tilesetElementGroup
        ? owner?.kind != ResourcePackKind.tileset || targetOwnerId == null
        : owner != null || targetOwnerId != null) {
      throw const FormatException('Support mapping owner is invalid');
    }
  }

  factory ResourcePackSupportMapping.fromJson(Map<String, Object?> json) {
    _keys(json, {'kind', 'sourceId', 'targetId', 'owner', 'targetOwnerId'});
    return ResourcePackSupportMapping(
      kind: _enum(ResourcePackSupportKind.values, json['kind']),
      sourceId: _string(json['sourceId']),
      targetId: _string(json['targetId']),
      owner: json['owner'] == null
          ? null
          : ResourcePackRef.fromJson(_object(json['owner'])),
      targetOwnerId: json['targetOwnerId'] == null
          ? null
          : _string(json['targetOwnerId']),
    );
  }

  final ResourcePackSupportKind kind;
  final String sourceId;
  final String targetId;
  final ResourcePackRef? owner;
  final String? targetOwnerId;
  String get sourceIdentity =>
      jsonEncode([kind.name, owner?.identity, sourceId]);
  String get targetIdentity => jsonEncode([kind.name, targetOwnerId, targetId]);

  @override
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'sourceId': sourceId,
    'targetId': targetId,
    if (owner != null) 'owner': owner!.toJson(),
    if (targetOwnerId != null) 'targetOwnerId': targetOwnerId,
  };
}

final class ResourcePackAssetMapping extends _InstallationJsonValue {
  ResourcePackAssetMapping({
    required String fileId,
    required String assetId,
    required String targetPath,
    required String rawSha256,
    required this.byteLength,
    required this.mediaType,
  }) : fileId = _portableIdentifier(fileId),
       assetId = _nativeAssetId(assetId),
       targetPath = _targetPath(targetPath),
       rawSha256 = _digest(rawSha256) {
    final extension = switch (mediaType) {
      'image/png' => 'png',
      'model/gltf-binary' => 'glb',
      _ => throw const FormatException('Unsupported installed asset MIME'),
    };
    ResourcePackInventoryFile(
      path: 'blobs/$rawSha256.$extension',
      byteLength: byteLength,
      mediaType: mediaType,
      rawSha256: rawSha256,
    );
    if (!targetPath.endsWith('.$extension')) {
      throw const FormatException('Installed asset path and MIME disagree');
    }
  }

  factory ResourcePackAssetMapping.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'fileId',
      'assetId',
      'targetPath',
      'rawSha256',
      'byteLength',
      'mediaType',
    });
    return ResourcePackAssetMapping(
      fileId: _string(json['fileId']),
      assetId: _string(json['assetId']),
      targetPath: _string(json['targetPath']),
      rawSha256: _string(json['rawSha256']),
      byteLength: _integer(json['byteLength']),
      mediaType: _string(json['mediaType']),
    );
  }

  final String fileId;
  final String assetId;
  final String targetPath;
  final String rawSha256;
  final int byteLength;
  final String mediaType;

  @override
  Map<String, Object?> toJson() => {
    'fileId': fileId,
    'assetId': assetId,
    'targetPath': targetPath,
    'rawSha256': rawSha256,
    'byteLength': byteLength,
    'mediaType': mediaType,
  };
}

final class ResourcePackInstallation extends _InstallationJsonValue {
  ResourcePackInstallation({
    required String installationId,
    required String packId,
    required String packVersion,
    required String universeId,
    required String archiveRawSha256,
    required String catalogRawSha256,
    required this.copyOrdinal,
    required Iterable<ResourcePackRef> selectedRoots,
    Iterable<String> selectedSmartTilePatternIds = const [],
    required Iterable<ResourcePackResourceMapping> resources,
    required Iterable<ResourcePackSupportMapping> supports,
    required Iterable<ResourcePackAssetMapping> assets,
    required String installedAtUtc,
    required this.provenanceStatus,
  }) : installationId = _identifier(installationId, 'installationId'),
       packId = _publisherIdentity(packId),
       packVersion = _version(packVersion),
       universeId = _publisherIdentity(universeId),
       archiveRawSha256 = _digest(archiveRawSha256),
       catalogRawSha256 = _digest(catalogRawSha256),
       selectedRoots = _ordered(selectedRoots, (ref) => ref.identity),
       selectedSmartTilePatternIds = _ordered(
         selectedSmartTilePatternIds.map(_portableIdentifier),
         (id) => id,
       ),
       resources = _ordered(resources, (mapping) => mapping.source.identity),
       supports = _ordered(supports, (mapping) => mapping.sourceIdentity),
       assets = _ordered(assets, (mapping) => mapping.fileId),
       installedAtUtc = _timestamp(installedAtUtc) {
    if (copyOrdinal < 0 ||
        this.selectedRoots.isEmpty &&
            this.selectedSmartTilePatternIds.isEmpty) {
      throw const FormatException(
        'An installation needs selected roots and mappings',
      );
    }
    final mapped = this.resources
        .map((mapping) => mapping.source.identity)
        .toSet();
    if (this.selectedRoots.any((root) => !mapped.contains(root.identity))) {
      throw const FormatException('A selected root has no installed mapping');
    }
    _unique(this.resources.map((mapping) => mapping.targetIdentity));
    _unique(this.supports.map((mapping) => mapping.targetIdentity));
    final mappedPatterns = this.supports
        .where(
          (mapping) => mapping.kind == ResourcePackSupportKind.smartTilePattern,
        )
        .map((mapping) => mapping.sourceId)
        .toSet();
    if (this.selectedSmartTilePatternIds.any(
      (id) => !mappedPatterns.contains(id),
    )) {
      throw const FormatException(
        'A selected pattern has no installed mapping',
      );
    }
    final mappings = {
      for (final mapping in this.resources) mapping.source.identity: mapping,
    };
    for (final support in this.supports) {
      final owner = support.owner;
      if (owner != null &&
          mappings[owner.identity]?.targetId != support.targetOwnerId) {
        throw const FormatException(
          'Support owner does not match its recorded resource',
        );
      }
    }
    final assetRecords = <String, (String, String, int, String)>{};
    final assetPaths = <String, String>{};
    for (final asset in this.assets) {
      final record = (
        asset.targetPath,
        asset.rawSha256,
        asset.byteLength,
        asset.mediaType,
      );
      final existing = assetRecords[asset.assetId];
      final pathOwner = assetPaths[asset.targetPath];
      if (existing != null && existing != record ||
          pathOwner != null && pathOwner != asset.assetId) {
        throw const FormatException(
          'Installed asset aliases have conflicting metadata',
        );
      }
      assetRecords[asset.assetId] = record;
      assetPaths[asset.targetPath] = asset.assetId;
    }
  }

  factory ResourcePackInstallation.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'installationId',
      'packId',
      'packVersion',
      'universeId',
      'archiveRawSha256',
      'catalogRawSha256',
      'copyOrdinal',
      'selectedRoots',
      'selectedSmartTilePatternIds',
      'resources',
      'supports',
      'assets',
      'installedAtUtc',
      'provenanceStatus',
    });
    return ResourcePackInstallation(
      installationId: _string(json['installationId']),
      packId: _string(json['packId']),
      packVersion: _string(json['packVersion']),
      universeId: _string(json['universeId']),
      archiveRawSha256: _string(json['archiveRawSha256']),
      catalogRawSha256: _string(json['catalogRawSha256']),
      copyOrdinal: _integer(json['copyOrdinal']),
      selectedRoots: _objects(
        json['selectedRoots'],
      ).map(ResourcePackRef.fromJson),
      selectedSmartTilePatternIds:
          json.containsKey('selectedSmartTilePatternIds')
          ? _strings(json['selectedSmartTilePatternIds'])
          : const [],
      resources: _objects(
        json['resources'],
      ).map(ResourcePackResourceMapping.fromJson),
      supports: _objects(
        json['supports'],
      ).map(ResourcePackSupportMapping.fromJson),
      assets: _objects(json['assets']).map(ResourcePackAssetMapping.fromJson),
      installedAtUtc: _string(json['installedAtUtc']),
      provenanceStatus: _enum(
        ResourcePackProvenanceStatus.values,
        json['provenanceStatus'],
      ),
    );
  }

  final String installationId;
  final String packId;
  final String packVersion;
  final String universeId;
  final String archiveRawSha256;
  final String catalogRawSha256;
  final int copyOrdinal;
  final List<ResourcePackRef> selectedRoots;
  final List<String> selectedSmartTilePatternIds;
  final List<ResourcePackResourceMapping> resources;
  final List<ResourcePackSupportMapping> supports;
  final List<ResourcePackAssetMapping> assets;
  final String installedAtUtc;
  final ResourcePackProvenanceStatus provenanceStatus;

  String get packIdentity => '$packId@$packVersion#$archiveRawSha256';
  String get installationIdentity => '$packIdentity/$copyOrdinal';

  @override
  Map<String, Object?> toJson() => {
    'installationId': installationId,
    'packId': packId,
    'packVersion': packVersion,
    'universeId': universeId,
    'archiveRawSha256': archiveRawSha256,
    'catalogRawSha256': catalogRawSha256,
    'copyOrdinal': copyOrdinal,
    'selectedRoots': [for (final root in selectedRoots) root.toJson()],
    if (selectedSmartTilePatternIds.isNotEmpty)
      'selectedSmartTilePatternIds': selectedSmartTilePatternIds,
    'resources': [for (final mapping in resources) mapping.toJson()],
    'supports': [for (final mapping in supports) mapping.toJson()],
    'assets': [for (final mapping in assets) mapping.toJson()],
    'installedAtUtc': installedAtUtc,
    'provenanceStatus': provenanceStatus.name,
  };
}

final class ResourcePackInstallationCatalog extends _InstallationJsonValue {
  const ResourcePackInstallationCatalog.empty() : entries = const [];

  ResourcePackInstallationCatalog({
    required Iterable<ResourcePackInstallation> entries,
  }) : entries = _ordered(entries, (entry) => entry.installationId) {
    _unique(this.entries.map((entry) => entry.installationIdentity));
    final publications = <String, (String, String)>{};
    for (final entry in this.entries) {
      final key = '${entry.packId}@${entry.packVersion}';
      final identity = (entry.archiveRawSha256, entry.catalogRawSha256);
      final previous = publications[key];
      if (previous != null && previous != identity) {
        throw const FormatException(
          'An immutable pack publication has conflicting hashes',
        );
      }
      publications[key] = identity;
    }
  }

  factory ResourcePackInstallationCatalog.fromJson(Map<String, Object?> json) {
    _keys(json, {'formatVersion', 'entries'});
    if (_integer(json['formatVersion']) != currentFormatVersion) {
      throw const FormatException('Unsupported installation catalogue version');
    }
    return ResourcePackInstallationCatalog(
      entries: _objects(json['entries']).map(ResourcePackInstallation.fromJson),
    );
  }

  static const currentFormatVersion = 1;
  final List<ResourcePackInstallation> entries;
  bool get isEmpty => entries.isEmpty;

  ResourcePackInstallation? installationFor(
    String packId,
    String packVersion, {
    int copyOrdinal = 0,
  }) => entries
      .where(
        (entry) =>
            entry.packId == packId &&
            entry.packVersion == packVersion &&
            entry.copyOrdinal == copyOrdinal,
      )
      .firstOrNull;

  @override
  Map<String, Object?> toJson() => {
    'formatVersion': currentFormatVersion,
    'entries': [for (final entry in entries) entry.toJson()],
  };
}

void _keys(Map<String, Object?> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown installation contract field');
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected installation contract object');
  }
  return Map<String, Object?>.from(value);
}

Iterable<Map<String, Object?>> _objects(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected installation contract list');
  }
  return value.map(_object);
}

String _string(Object? value) {
  if (value is! String) {
    throw const FormatException('Expected installation contract string');
  }
  return value;
}

Iterable<String> _strings(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected installation string list');
  }
  return value.map(_string);
}

String _portableIdentifier(String value) {
  if (!RegExp(r'^[A-Za-z0-9._-]{1,96}$').hasMatch(value) ||
      value == '.' ||
      value == '..') {
    throw const FormatException('Invalid portable source identity');
  }
  return value;
}

String _nativeAssetId(String value) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(value) ||
      value.length > 512) {
    throw const FormatException('Invalid native AssetRecord identity');
  }
  return value;
}

int _integer(Object? value) {
  if (value is! int) {
    throw const FormatException('Expected installation contract integer');
  }
  return value;
}

T _enum<T extends Enum>(List<T> values, Object? name) {
  final value = values.where((value) => value.name == name).firstOrNull;
  if (value == null) {
    throw const FormatException('Unknown installation enum value');
  }
  return value;
}

String _identifier(String value, String field) {
  if (value.isEmpty ||
      value.length > 512 ||
      value != value.trim() ||
      value.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    throw FormatException('$field: invalid installed identity');
  }
  return value;
}

String _publisherIdentity(String value) {
  if (!RegExp(r'^[a-z0-9._-]{1,96}$').hasMatch(value) ||
      value == '.' ||
      value == '..') {
    throw const FormatException('Invalid pack publisher identity');
  }
  return value;
}

String _version(String value) {
  final match = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-([0-9A-Za-z.-]+))?$',
  ).firstMatch(value);
  if (match == null ||
      match[4] != null &&
          match[4]!
              .split('.')
              .any(
                (part) =>
                    part.isEmpty ||
                    RegExp(r'^[0-9]+$').hasMatch(part) &&
                        part.length > 1 &&
                        part.startsWith('0'),
              )) {
    throw const FormatException('Invalid immutable pack version');
  }
  return value;
}

String _digest(String value) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Expected lowercase SHA-256');
  }
  return value;
}

String _timestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
    throw const FormatException(
      'Expected canonical UTC installation timestamp',
    );
  }
  return value;
}

String _targetPath(String value) {
  if (!value.startsWith('assets/') ||
      value.contains('\\') ||
      value.contains(':') ||
      value.codeUnits.any((unit) => unit < 32 || unit == 127) ||
      value
          .split('/')
          .any(
            (part) =>
                part.isEmpty ||
                part == '.' ||
                part == '..' ||
                part != part.trim(),
          )) {
    throw const FormatException('Invalid installed logical asset path');
  }
  return value;
}

void _unique(Iterable<String> keys) {
  final seen = <String>{};
  if (keys.any((key) => !seen.add(key))) {
    throw const FormatException('Duplicate installation mapping identity');
  }
}

List<T> _ordered<T>(Iterable<T> values, String Function(T) key) {
  final result = values.toList()..sort((a, b) => key(a).compareTo(key(b)));
  _unique(result.map(key));
  return List.unmodifiable(result);
}
