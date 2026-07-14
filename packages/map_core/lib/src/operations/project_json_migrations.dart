import 'project_border_catalog_json_codec.dart';

Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
  _validateProjectVersion(raw);
  _validateManifestBorderVersion(raw);
  return raw;
}

Map<String, dynamic> migrateMapDataJson(Map<String, dynamic> raw) {
  _validateProjectVersion(raw);
  _validateMapBorderVersion(raw);
  return raw;
}

void _validateProjectVersion(Map<String, dynamic> raw) {
  if (!raw.containsKey('version') || raw['version'] == null) {
    return;
  }

  final version = raw['version'];
  if (version is! String) {
    throw FormatException(r'$.version: expected null, "v1", or "v2"');
  }
  if (version != 'v1' && version != 'v2') {
    throw FormatException(
      r'$.version: unsupported project format version "' '$version"',
    );
  }
}

void _validateManifestBorderVersion(Map<String, dynamic> raw) {
  if (_effectiveVersion(raw) != 'v1') {
    return;
  }
  final borderCatalogJson = raw['borderCatalog'];
  if (borderCatalogJson == null) {
    return;
  }

  final borderCatalog = decodeProjectBorderCatalogJson(
    borderCatalogJson,
    path: r'$.borderCatalog',
  );
  if (borderCatalog.isNotEmpty) {
    throw const FormatException(
      r'$.borderCatalog: non-empty Border catalog requires '
      'ProjectVersion.v2',
    );
  }
}

String _effectiveVersion(Map<String, dynamic> raw) {
  final version = raw['version'];
  return version == null ? 'v1' : version as String;
}

void _validateMapBorderVersion(Map<String, dynamic> raw) {
  if (_effectiveVersion(raw) != 'v1') {
    return;
  }
  final layers = raw['layers'];
  if (layers is! List<Object?>) {
    return;
  }
  for (var index = 0; index < layers.length; index += 1) {
    final layer = layers[index];
    if (layer is Map && layer['runtimeType'] == 'border') {
      throw FormatException(
        r'$.layers['
        '$index].runtimeType: Border layers require ProjectVersion.v2',
      );
    }
  }
}
