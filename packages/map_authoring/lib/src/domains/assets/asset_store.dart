import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';
import '../../contracts/json_contract_support.dart';
import '../../ports/project_file_reader.dart';

const String assetCatalogStorageKey = 'assets/.pokemap-assets.json';
const String assetCatalogResourceIdentity = 'assetCatalog';

String assetBlobResourceIdentity(String digest) => 'assetBlob:$digest';

String assetBlobStorageKey(ContentArtifactRef artifact) =>
    'assets/.pokemap-store/${artifact.hexDigest}.blob';

/// Computes references from canonical project/map payloads instead of trusting
/// a caller-provided usage list. Stable owner/path strings are sufficient for
/// delete preflight without leaking storage paths outside the package.
List<String> deriveAssetUsages({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
  required AssetRecord asset,
}) {
  final needles = {
    asset.id,
    asset.logicalPath,
    asset.artifact.handle,
    asset.artifact.digest,
  };
  final usages = <String>{};
  _collectAssetUsages(
    manifest.toJson(),
    owner: 'project',
    path: r'$',
    needles: needles,
    output: usages,
  );
  for (final map in maps) {
    _collectAssetUsages(
      map.toJson(),
      owner: 'map:${map.id}',
      path: r'$',
      needles: needles,
      output: usages,
    );
  }
  return List.unmodifiable(usages.toList()..sort());
}

final class AssetRecord {
  AssetRecord({
    required String id,
    required String logicalPath,
    required this.artifact,
    Iterable<String> usages = const [],
    Iterable<String> tags = const [],
  })  : id = _identity(id, 'id'),
        logicalPath = _logicalPath(logicalPath),
        usages = normalizedContractStrings(usages, 'usages'),
        tags = normalizedContractStrings(tags, 'tags');

  factory AssetRecord.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
      json,
      const {'id', 'logicalPath', 'artifact', 'usages', 'tags'},
    );
    final rawArtifact = json['artifact'];
    if (rawArtifact is! Map) {
      throw const FormatException('artifact must be a JSON object');
    }
    try {
      return AssetRecord(
        id: requireContractString(json['id'], 'id'),
        logicalPath: requireContractString(json['logicalPath'], 'logicalPath'),
        artifact: ContentArtifactRef.fromJson(
          Map<String, dynamic>.from(rawArtifact),
        ),
        usages: readContractStringList(json['usages'], 'usages'),
        tags: readContractStringList(json['tags'], 'tags'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final String logicalPath;
  final ContentArtifactRef artifact;
  final List<String> usages;
  final List<String> tags;

  AssetRecord copyWith({
    String? logicalPath,
    ContentArtifactRef? artifact,
    Iterable<String>? usages,
    Iterable<String>? tags,
  }) =>
      AssetRecord(
        id: id,
        logicalPath: logicalPath ?? this.logicalPath,
        artifact: artifact ?? this.artifact,
        usages: usages ?? this.usages,
        tags: tags ?? this.tags,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'logicalPath': logicalPath,
        'artifact': artifact.toJson(),
        'usages': usages,
        'tags': tags,
      };
}

/// Deterministically ordered project asset registry.
final class AssetCatalog {
  AssetCatalog({Iterable<AssetRecord> records = const []})
      : records = _validatedRecords(records) {
    _byId = Map.unmodifiable(
        {for (final record in this.records) record.id: record});
    _byLogicalPath = Map.unmodifiable(
      {for (final record in this.records) record.logicalPath: record},
    );
  }

  factory AssetCatalog.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'schemaVersion', 'records'});
    if (json['schemaVersion'] != 1 || json['records'] is! List) {
      throw const FormatException('Unsupported asset catalog document');
    }
    return AssetCatalog(
      records: (json['records']! as List).map((raw) {
        if (raw is! Map) {
          throw const FormatException('record must be an object');
        }
        return AssetRecord.fromJson(Map<String, dynamic>.from(raw));
      }),
    );
  }

  final List<AssetRecord> records;
  late final Map<String, AssetRecord> _byId;
  late final Map<String, AssetRecord> _byLogicalPath;

  AssetRecord? find(String id) => _byId[id];

  AssetRecord? findByLogicalPath(String logicalPath) =>
      _byLogicalPath[logicalPath];

  AssetRecord require(String id) =>
      find(id) ??
      (throw AssetCatalogException(
        'asset.unknown',
        'The asset identity is unknown.',
        details: {'assetId': id},
      ));

  List<AssetRecord> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return records;
    return List.unmodifiable(records.where((record) {
      return record.id.toLowerCase().contains(needle) ||
          record.logicalPath.toLowerCase().contains(needle) ||
          record.artifact.mediaType.contains(needle) ||
          record.tags.any((tag) => tag.toLowerCase().contains(needle));
    }));
  }

  List<AssetRecord> unused() =>
      List.unmodifiable(records.where((record) => record.usages.isEmpty));

  List<List<AssetRecord>> duplicateGroups() {
    final groups = <String, List<AssetRecord>>{};
    for (final record in records) {
      groups.putIfAbsent(record.artifact.digest, () => []).add(record);
    }
    final duplicates = groups.values.where((group) => group.length > 1).toList()
      ..sort((left, right) => left.first.id.compareTo(right.first.id));
    return List.unmodifiable([
      for (final group in duplicates) List<AssetRecord>.unmodifiable(group),
    ]);
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'records': [for (final record in records) record.toJson()],
      };
}

final class AssetCatalogException implements Exception {
  AssetCatalogException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'AssetCatalogException($code): $message';
}

List<AssetRecord> _validatedRecords(Iterable<AssetRecord> values) {
  final records = values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final ids = <String>{};
  final paths = <String>{};
  for (final record in records) {
    if (!ids.add(record.id)) {
      throw AssetCatalogException(
        'asset.duplicate_id',
        'Asset identities must be unique.',
        details: {'assetId': record.id},
      );
    }
    if (!paths.add(record.logicalPath)) {
      throw AssetCatalogException(
        'asset.duplicate_path',
        'Asset logical paths must be unique.',
        details: {'logicalPath': record.logicalPath},
      );
    }
  }
  return List.unmodifiable(records);
}

String _identity(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable identity');
  }
  return normalized;
}

String _logicalPath(String value) {
  final segments = validateProjectRelativePath(value);
  final normalized = segments.join('/');
  if (normalized != value || segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'logicalPath',
      'must be a canonical project-relative path',
    );
  }
  return normalized;
}

void _collectAssetUsages(
  Object? value, {
  required String owner,
  required String path,
  required Set<String> needles,
  required Set<String> output,
}) {
  if (value is String) {
    if (needles.contains(value)) output.add('$owner:$path');
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      _collectAssetUsages(
        value[index],
        owner: owner,
        path: '$path[$index]',
        needles: needles,
        output: output,
      );
    }
    return;
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      _collectAssetUsages(
        value[key],
        owner: owner,
        path: '$path.$key',
        needles: needles,
        output: output,
      );
    }
  }
}
