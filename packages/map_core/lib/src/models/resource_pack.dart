import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'border_catalog.dart';
import 'resource_library_catalog.dart';
import 'smart_tile.dart';

enum ResourcePackKind {
  element,
  model3d,
  smartTilePreset,
  tileset,
  borderBlueprint,
  environmentPreset,
  character,
}

enum ResourcePackConflictPolicy { preserveProject, importCopy }

enum ResourcePackOperation { stage, inspect, prepare, import, export }

abstract class _PackJsonValue {
  const _PackJsonValue();

  Map<String, Object?> toJson();

  @override
  bool operator ==(Object other) =>
      runtimeType == other.runtimeType &&
      other is _PackJsonValue &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(toJson()));
}

final class ResourcePackRef extends _PackJsonValue {
  ResourcePackRef({required this.kind, required String id})
    : id = _localId(id, 'resource.id');

  factory ResourcePackRef.fromJson(Map<String, Object?> json) {
    _keys(json, {'resourceKind', 'id'}, 'resource');
    final name = _string(json['resourceKind'], 'resource.resourceKind');
    final kind = ResourcePackKind.values
        .where((kind) => kind.name == name)
        .firstOrNull;
    if (kind == null) {
      throw FormatException('Unsupported pack resource kind: $name');
    }
    return ResourcePackRef(kind: kind, id: _string(json['id'], 'resource.id'));
  }

  final ResourcePackKind kind;
  final String id;
  String get identity => '${kind.name}:$id';

  @override
  Map<String, Object?> toJson() => {'resourceKind': kind.name, 'id': id};
}

final class ResourcePackMetadata extends _PackJsonValue {
  ResourcePackMetadata({
    required String id,
    required String version,
    required String name,
    required String description,
    required String universeId,
    required Iterable<String> authors,
    required String provenance,
  }) : id = _publisherId(id, 'pack.id'),
       version = _semver(version),
       name = _text(name, 'pack.name', maximum: 256),
       description = _text(
         description,
         'pack.description',
         maximum: 4096,
         allowEmpty: true,
       ),
       universeId = _publisherId(universeId, 'pack.universeId'),
       authors = List.unmodifiable(
         authors.map((author) => _text(author, 'pack.authors', maximum: 128)),
       ),
       provenance = _text(provenance, 'pack.provenance', maximum: 4096) {
    if (this.authors.isEmpty) {
      throw const FormatException('pack.authors must not be empty');
    }
  }

  factory ResourcePackMetadata.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'id',
      'version',
      'name',
      'description',
      'universeId',
      'authors',
      'provenance',
    }, 'pack');
    return ResourcePackMetadata(
      id: _string(json['id'], 'pack.id'),
      version: _string(json['version'], 'pack.version'),
      name: _string(json['name'], 'pack.name'),
      description: _string(json['description'], 'pack.description'),
      universeId: _string(json['universeId'], 'pack.universeId'),
      authors: _strings(json['authors'], 'pack.authors'),
      provenance: _string(json['provenance'], 'pack.provenance'),
    );
  }

  final String id;
  final String version;
  final String name;
  final String description;
  final String universeId;
  final List<String> authors;
  final String provenance;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'name': name,
    'description': description,
    'universeId': universeId,
    'authors': authors,
    'provenance': provenance,
  };
}

final class ResourcePackCompatibility extends _PackJsonValue {
  ResourcePackCompatibility({
    required this.resourceLibraryCatalogVersion,
    required this.smartTileCatalogVersion,
    required this.borderCatalogVersion,
    required Iterable<String> requiredCapabilities,
    required this.tileWidth,
    required this.tileHeight,
  }) : requiredCapabilities = _orderedUnique(
         requiredCapabilities.map(
           (capability) => _publisherId(capability, 'requiredCapabilities'),
         ),
         'requiredCapabilities',
       ) {
    if (resourceLibraryCatalogVersion !=
            ResourceLibraryCatalog.currentFormatVersion ||
        smartTileCatalogVersion !=
            ProjectSmartTileCatalog.currentFormatVersion ||
        borderCatalogVersion !=
            ProjectBorderCatalog.latestSupportedFormatVersion) {
      throw const FormatException('Unsupported native resource codec version');
    }
    if (tileWidth < 1 || tileHeight < 1) {
      throw const FormatException('Pack cell dimensions must be positive');
    }
  }

  factory ResourcePackCompatibility.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'resourceLibraryCatalogVersion',
      'smartTileCatalogVersion',
      'borderCatalogVersion',
      'requiredCapabilities',
      'tileWidth',
      'tileHeight',
    }, 'compatibility');
    return ResourcePackCompatibility(
      resourceLibraryCatalogVersion: _integer(
        json['resourceLibraryCatalogVersion'],
        'compatibility.resourceLibraryCatalogVersion',
      ),
      smartTileCatalogVersion: _integer(
        json['smartTileCatalogVersion'],
        'compatibility.smartTileCatalogVersion',
      ),
      borderCatalogVersion: _integer(
        json['borderCatalogVersion'],
        'compatibility.borderCatalogVersion',
      ),
      requiredCapabilities: _strings(
        json['requiredCapabilities'],
        'compatibility.requiredCapabilities',
      ),
      tileWidth: _integer(json['tileWidth'], 'compatibility.tileWidth'),
      tileHeight: _integer(json['tileHeight'], 'compatibility.tileHeight'),
    );
  }

  final int resourceLibraryCatalogVersion;
  final int smartTileCatalogVersion;
  final int borderCatalogVersion;
  final List<String> requiredCapabilities;
  final int tileWidth;
  final int tileHeight;

  @override
  Map<String, Object?> toJson() => {
    'resourceLibraryCatalogVersion': resourceLibraryCatalogVersion,
    'smartTileCatalogVersion': smartTileCatalogVersion,
    'borderCatalogVersion': borderCatalogVersion,
    'requiredCapabilities': requiredCapabilities,
    'tileWidth': tileWidth,
    'tileHeight': tileHeight,
  };
}

final class ResourcePackInventoryFile extends _PackJsonValue {
  ResourcePackInventoryFile({
    required this.path,
    required this.byteLength,
    required this.mediaType,
    required String rawSha256,
  }) : rawSha256 = _digest(rawSha256, 'file.rawSha256') {
    if (byteLength < 1) {
      throw const FormatException('file.byteLength must be positive');
    }
    if (path == 'catalog.json') {
      if (mediaType != 'application/json') {
        throw const FormatException(
          'catalog.json must have application/json MIME',
        );
      }
      return;
    }
    if (RegExp(r'^catalog/objects/[a-f0-9]{64}\.json$').hasMatch(path)) {
      if (path != 'catalog/objects/${this.rawSha256}.json' ||
          mediaType != 'application/json') {
        throw const FormatException('Catalog object path or MIME is invalid');
      }
      return;
    }
    final match = RegExp(
      r'^(blobs|licenses|previews)/([a-f0-9]{64})\.(png|glb|txt)$',
    ).firstMatch(path);
    if (match == null || match[2] != this.rawSha256) {
      throw const FormatException('Pack inventory path or digest is invalid');
    }
    final root = match[1], extension = match[3];
    if (root == 'blobs' && extension != 'png' && extension != 'glb' ||
        root == 'licenses' && extension != 'txt' ||
        root == 'previews' && extension != 'png') {
      throw const FormatException('Unsupported content in pack directory');
    }
    final expected = switch (extension) {
      'png' => 'image/png',
      'glb' => 'model/gltf-binary',
      'txt' => 'text/plain',
      _ => throw const FormatException('Unsupported file extension'),
    };
    if (mediaType != expected) {
      throw const FormatException('Pack MIME does not match its file type');
    }
  }

  factory ResourcePackInventoryFile.fromJson(Map<String, Object?> json) {
    _keys(json, {'path', 'byteLength', 'mediaType', 'rawSha256'}, 'file');
    return ResourcePackInventoryFile(
      path: _string(json['path'], 'file.path'),
      byteLength: _integer(json['byteLength'], 'file.byteLength'),
      mediaType: _string(json['mediaType'], 'file.mediaType'),
      rawSha256: _string(json['rawSha256'], 'file.rawSha256'),
    );
  }

  final String path;
  final int byteLength;
  final String mediaType;
  final String rawSha256;

  @override
  Map<String, Object?> toJson() => {
    'path': path,
    'byteLength': byteLength,
    'mediaType': mediaType,
    'rawSha256': rawSha256,
  };
}

final class ResourcePackContent extends _PackJsonValue {
  ResourcePackContent({
    required this.catalog,
    required Iterable<ResourcePackInventoryFile> files,
    required String treeSha256,
  }) : files = List.unmodifiable(
         files.toList()..sort((a, b) => a.path.compareTo(b.path)),
       ),
       treeSha256 = _digest(treeSha256, 'content.treeSha256') {
    if (catalog.path != 'catalog.json') {
      throw const FormatException(
        'content.catalog must reference catalog.json',
      );
    }
    final paths = <String>{};
    for (final file in this.files) {
      if (file.path == 'catalog.json' || !paths.add(file.path.toLowerCase())) {
        throw const FormatException(
          'Duplicate or reserved pack inventory path',
        );
      }
    }
  }

  factory ResourcePackContent.fromJson(Map<String, Object?> json) {
    _keys(json, {'catalog', 'files', 'treeSha256'}, 'content');
    return ResourcePackContent(
      catalog: ResourcePackInventoryFile.fromJson(
        _object(json['catalog'], 'content.catalog'),
      ),
      files: _objects(
        json['files'],
        'content.files',
      ).map(ResourcePackInventoryFile.fromJson),
      treeSha256: _string(json['treeSha256'], 'content.treeSha256'),
    );
  }

  final ResourcePackInventoryFile catalog;
  final List<ResourcePackInventoryFile> files;
  final String treeSha256;

  @override
  Map<String, Object?> toJson() => {
    'catalog': catalog.toJson(),
    'files': [for (final file in files) file.toJson()],
    'treeSha256': treeSha256,
  };
}

final class ResourcePackManifest extends _PackJsonValue {
  const ResourcePackManifest({
    required this.pack,
    required this.compatibility,
    required this.content,
  });

  factory ResourcePackManifest.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'format',
      'formatVersion',
      'pack',
      'compatibility',
      'content',
    }, 'manifest');
    if (json['format'] != format ||
        _integer(json['formatVersion'], 'formatVersion') !=
            currentFormatVersion) {
      throw const FormatException('Unsupported Avelune asset pack format');
    }
    return ResourcePackManifest(
      pack: ResourcePackMetadata.fromJson(_object(json['pack'], 'pack')),
      compatibility: ResourcePackCompatibility.fromJson(
        _object(json['compatibility'], 'compatibility'),
      ),
      content: ResourcePackContent.fromJson(
        _object(json['content'], 'content'),
      ),
    );
  }

  static const format = 'avelune.asset-pack';
  static const currentFormatVersion = 2;
  static const extension = '.aveluneassets';
  static const mediaType = 'application/vnd.avelune.asset-pack+zip';

  final ResourcePackMetadata pack;
  final ResourcePackCompatibility compatibility;
  final ResourcePackContent content;

  @override
  Map<String, Object?> toJson() => {
    'format': format,
    'formatVersion': currentFormatVersion,
    'pack': pack.toJson(),
    'compatibility': compatibility.toJson(),
    'content': content.toJson(),
  };
}

final class ResourcePackFileBinding extends _PackJsonValue {
  ResourcePackFileBinding({
    required String id,
    required String logicalPath,
    required this.archivePath,
    required this.byteLength,
    required this.mediaType,
    required String rawSha256,
    required String provenanceId,
    required Iterable<String> licenseIds,
  }) : id = _localId(id, 'fileBinding.id'),
       logicalPath = _logicalPath(logicalPath),
       rawSha256 = _digest(rawSha256, 'fileBinding.rawSha256'),
       provenanceId = _localId(provenanceId, 'fileBinding.provenanceId'),
       licenseIds = _licenses(licenseIds) {
    if (!archivePath.startsWith('blobs/')) {
      throw const FormatException('File bindings must reference pack blobs');
    }
    ResourcePackInventoryFile(
      path: archivePath,
      byteLength: byteLength,
      mediaType: mediaType,
      rawSha256: rawSha256,
    );
  }

  factory ResourcePackFileBinding.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'id',
      'logicalPath',
      'archivePath',
      'rawSha256',
      'byteLength',
      'mediaType',
      'provenanceId',
      'licenseIds',
    }, 'fileBinding');
    return ResourcePackFileBinding(
      id: _string(json['id'], 'fileBinding.id'),
      logicalPath: _string(json['logicalPath'], 'fileBinding.logicalPath'),
      archivePath: _string(json['archivePath'], 'fileBinding.archivePath'),
      rawSha256: _string(json['rawSha256'], 'fileBinding.rawSha256'),
      byteLength: _integer(json['byteLength'], 'fileBinding.byteLength'),
      mediaType: _string(json['mediaType'], 'fileBinding.mediaType'),
      provenanceId: _string(json['provenanceId'], 'fileBinding.provenanceId'),
      licenseIds: _strings(json['licenseIds'], 'fileBinding.licenseIds'),
    );
  }

  final String id;
  final String logicalPath;
  final String archivePath;
  final String rawSha256;
  final int byteLength;
  final String mediaType;
  final String provenanceId;
  final List<String> licenseIds;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'logicalPath': logicalPath,
    'archivePath': archivePath,
    'rawSha256': rawSha256,
    'byteLength': byteLength,
    'mediaType': mediaType,
    'provenanceId': provenanceId,
    'licenseIds': licenseIds,
  };
}

final class ResourcePackProvenance extends _PackJsonValue {
  ResourcePackProvenance({
    required String id,
    required String author,
    String? sourceUrl,
    required Iterable<String> licenseIds,
    Iterable<ResourcePackRef> resources = const [],
  }) : id = _localId(id, 'provenance.id'),
       author = _text(author, 'provenance.author', maximum: 128),
       sourceUrl = _sourceUrl(sourceUrl),
       licenseIds = _licenses(licenseIds),
       resources = List.unmodifiable(
         resources.toList()..sort((a, b) => a.identity.compareTo(b.identity)),
       ) {
    if (this.resources.map((ref) => ref.identity).toSet().length !=
        this.resources.length) {
      throw const FormatException(
        'Duplicate resource in provenance declaration',
      );
    }
  }

  factory ResourcePackProvenance.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'id',
      'author',
      'sourceUrl',
      'licenseIds',
      'resources',
    }, 'provenance');
    return ResourcePackProvenance(
      id: _string(json['id'], 'provenance.id'),
      author: _string(json['author'], 'provenance.author'),
      sourceUrl: json['sourceUrl'] == null
          ? null
          : _string(json['sourceUrl'], 'provenance.sourceUrl'),
      licenseIds: _strings(json['licenseIds'], 'provenance.licenseIds'),
      resources: json.containsKey('resources')
          ? _objects(
              json['resources'],
              'provenance.resources',
            ).map(ResourcePackRef.fromJson)
          : const [],
    );
  }

  final String id;
  final String author;
  final String? sourceUrl;
  final List<String> licenseIds;
  final List<ResourcePackRef> resources;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
    'licenseIds': licenseIds,
    if (resources.isNotEmpty)
      'resources': [for (final ref in resources) ref.toJson()],
  };
}

void _keys(Map<String, Object?> json, Set<String> allowed, String field) {
  final unknown = json.keys.where((key) => !allowed.contains(key));
  if (unknown.isNotEmpty) {
    throw FormatException('$field: unknown field ${unknown.first}');
  }
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field: expected an object');
  }
  return Map<String, Object?>.from(value);
}

Iterable<Map<String, Object?>> _objects(Object? value, String field) {
  if (value is! List) throw FormatException('$field: expected a list');
  return value.map((item) => _object(item, field));
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field: expected a string');
  return value;
}

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('$field: expected an integer');
  return value;
}

Iterable<String> _strings(Object? value, String field) {
  if (value is! List) throw FormatException('$field: expected a list');
  return value.map((item) => _string(item, field));
}

String _localId(String value, String field) {
  if (!RegExp(r'^[A-Za-z0-9._-]{1,96}$').hasMatch(value) ||
      value == '.' ||
      value == '..') {
    throw FormatException('$field: invalid portable identity');
  }
  return value;
}

String _publisherId(String value, String field) {
  _localId(value, field);
  if (value != value.toLowerCase()) {
    throw FormatException('$field: identity must use lowercase ASCII');
  }
  return value;
}

String _text(
  String value,
  String field, {
  required int maximum,
  bool allowEmpty = false,
}) {
  if (value.length > maximum ||
      value.contains('\u0000') ||
      !allowEmpty && (value.isEmpty || value != value.trim())) {
    throw FormatException('$field: invalid text');
  }
  return value;
}

String _semver(String value) {
  final parts = value.split('-');
  final firstDash = value.indexOf('-');
  final core = firstDash < 0 ? value : value.substring(0, firstDash);
  if (!RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$',
  ).hasMatch(core)) {
    throw const FormatException(
      'pack.version must be SemVer without build metadata',
    );
  }
  if (parts.length > 1) {
    final prerelease = value.substring(firstDash + 1).split('.');
    for (final part in prerelease) {
      if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(part) ||
          RegExp(r'^[0-9]+$').hasMatch(part) &&
              part.length > 1 &&
              part.startsWith('0')) {
        throw const FormatException(
          'pack.version has invalid prerelease identifiers',
        );
      }
    }
  }
  return value;
}

String _digest(String value, String field) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('$field: expected lowercase raw SHA-256');
  }
  return value;
}

List<String> _orderedUnique(Iterable<String> values, String field) {
  final result = values.toList()..sort();
  if (result.toSet().length != result.length) {
    throw FormatException('$field: duplicate value');
  }
  return List.unmodifiable(result);
}

List<String> _licenses(Iterable<String> values) => _orderedUnique(
  values.map((value) {
    if (!RegExp(r'^licenses/[a-f0-9]{64}\.txt$').hasMatch(value)) {
      throw const FormatException(
        'licenseIds must reference inventoried text paths',
      );
    }
    return value;
  }),
  'licenseIds',
);

String _logicalPath(String value) {
  if (value.isEmpty ||
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
    throw const FormatException(
      'logicalPath must be a portable relative file path',
    );
  }
  return value;
}

String? _sourceUrl(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (value.length > 4096 ||
      uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException(
      'provenance.sourceUrl must be a descriptive HTTP URL',
    );
  }
  return value;
}
