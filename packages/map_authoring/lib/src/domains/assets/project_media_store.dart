import 'dart:convert';

import 'package:map_core/map_core.dart';

const String projectMediaCatalogStorageKey = 'assets/.pokemap-media.json';
const String projectMediaCatalogResourceIdentity = 'projectMediaCatalog';

ProjectMediaCatalog decodeProjectMediaCatalogBytes(List<int> bytes) {
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw const FormatException('Project media catalog must be an object');
  }
  return ProjectMediaCatalog.fromJson(Map<String, Object?>.from(decoded));
}

List<int> encodeProjectMediaCatalogBytes(ProjectMediaCatalog catalog) =>
    List<int>.unmodifiable(utf8.encode(jsonEncode(catalog.toJson())));

Map<String, dynamic> readProjectMediaCatalogDocumentBytes(List<int>? bytes) {
  final raw = bytes == null
      ? {'schemaVersion': 1, 'entries': <Object?>[]}
      : jsonDecode(utf8.decode(bytes));
  if (raw is! Map || raw['schemaVersion'] != 1 || raw['entries'] is! List) {
    throw const FormatException('The project media catalog is invalid.');
  }
  return Map<String, dynamic>.from(raw);
}

ProjectMediaAsset? findProjectAudioMediaForSource(
    Map<String, dynamic> document, String assetId) {
  final matches = (document['entries'] as List).whereType<Map>().where(
      (entry) => entry['sourceAssetId'] == assetId && entry['kind'] == 'audio');
  final first = matches.firstOrNull;
  return first == null
      ? null
      : ProjectMediaAsset.fromJson(Map<String, Object?>.from(first));
}
