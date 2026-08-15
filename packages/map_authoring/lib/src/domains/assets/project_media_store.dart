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
