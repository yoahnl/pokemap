import 'project_border_catalog_json_codec.dart';
import '../models/badge_definition.dart';
import '../models/shop_definition.dart';
import '../models/smart_tile.dart';

Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
  _validateProjectVersion(raw);
  _validateManifestV5LegacyFields(raw);
  _validateManifestBorderVersion(raw);
  _validateManifestSmartTileCatalogVersion(raw);
  _validateShops(raw);
  _validateBadges(raw);
  return raw;
}

void _validateShops(Map<String, dynamic> raw) {
  final shops = raw['shops'];
  if (shops == null) return;
  if (shops is! List) {
    throw const FormatException(r'$.shops: expected a list');
  }
  final ids = <String>{};
  for (var index = 0; index < shops.length; index += 1) {
    final shop = shops[index];
    if (shop is! Map) {
      throw FormatException(r'$.shops[' '$index]: expected an object');
    }
    try {
      final definition =
          ShopDefinition.fromJson(Map<String, dynamic>.from(shop));
      if (!ids.add(definition.id)) {
        throw StateError('duplicate shop id "${definition.id}"');
      }
    } on Object catch (error) {
      throw FormatException(r'$.shops[' '$index]: $error');
    }
  }
}

void _validateBadges(Map<String, dynamic> raw) {
  final badges = raw['badges'];
  if (badges == null) return;
  if (badges is! List) {
    throw const FormatException(r'$.badges: expected a list');
  }
  final ids = <String>{};
  for (var index = 0; index < badges.length; index += 1) {
    final badge = badges[index];
    if (badge is! Map) {
      throw FormatException(r'$.badges[' '$index]: expected an object');
    }
    try {
      final definition =
          BadgeDefinition.fromJson(Map<String, dynamic>.from(badge));
      if (!ids.add(definition.id)) {
        throw StateError('duplicate badge id "${definition.id}"');
      }
    } on Object catch (error) {
      throw FormatException(r'$.badges[' '$index]: $error');
    }
  }
}

Map<String, dynamic> migrateMapDataJson(Map<String, dynamic> raw) {
  _validateProjectVersion(raw);
  _validateMapSmartTileVersion(raw);
  _validateMapBorderVersion(raw);
  return raw;
}

void _validateProjectVersion(Map<String, dynamic> raw) {
  if (!raw.containsKey('version') || raw['version'] == null) {
    return;
  }

  final version = raw['version'];
  if (version is! String) {
    throw FormatException(
      r'$.version: expected null, "v1", "v2", "v3", "v4", or "v5"',
    );
  }
  if (version != 'v1' &&
      version != 'v2' &&
      version != 'v3' &&
      version != 'v4' &&
      version != 'v5') {
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

void _validateManifestSmartTileCatalogVersion(Map<String, dynamic> raw) {
  if (_effectiveVersion(raw) == 'v5') {
    return;
  }
  final catalogJson = raw['smartTileCatalog'];
  if (catalogJson == null) {
    return;
  }
  if (catalogJson is! Map) {
    throw const FormatException(r'$.smartTileCatalog: expected an object');
  }
  final catalog = ProjectSmartTileCatalog.fromJson(
    Map<String, dynamic>.from(catalogJson),
  );
  if (catalog.isNotEmpty) {
    throw const FormatException(
      r'$.smartTileCatalog: a non-empty Smart Tile catalog requires '
      'ProjectVersion.v5',
    );
  }
}

void _validateManifestV5LegacyFields(Map<String, dynamic> raw) {
  if (_effectiveVersion(raw) != 'v5') {
    return;
  }
  for (final key in const <String>[
    'terrainCategories',
    'pathCategories',
    'terrainPresets',
    'pathPresets',
    'pathPatternPresets',
  ]) {
    final value = raw[key];
    if (value is List && value.isNotEmpty) {
      throw FormatException(
        '\$.$key: smart_tile_v5_legacy_manifest_unsupported '
        '(version=v5, field=$key)',
      );
    }
  }
}

void _validateMapSmartTileVersion(Map<String, dynamic> raw) {
  final version = _effectiveVersion(raw);
  final layers = raw['layers'];
  if (layers is! List) {
    return;
  }
  for (var index = 0; index < layers.length; index++) {
    final layer = layers[index];
    if (layer is! Map) {
      continue;
    }
    final runtimeType = layer['runtimeType'];
    if (version == 'v4' &&
        runtimeType == 'smart_tile' &&
        const <String>{
          'materialCells',
          'horizontalEdges',
          'verticalEdges',
          'corners',
        }.any(layer.containsKey)) {
      throw FormatException(
        r'$.layers['
        '$index]: smart_tile_v4_unsupported '
        '(version=v4, variant=smart_tile)',
      );
    }
    if (version == 'v5' &&
        runtimeType == 'smart_tile' &&
        const <String>{
          'materialCells',
          'horizontalEdges',
          'verticalEdges',
          'corners',
        }.any(layer.containsKey)) {
      throw FormatException(
        r'$.layers['
        '$index]: smart_tile_v5_legacy_payload_unsupported '
        '(version=v5, variant=smart_tile)',
      );
    }
    if (version == 'v5' &&
        (runtimeType == 'terrain' || runtimeType == 'path')) {
      throw FormatException(
        r'$.layers['
        '$index].runtimeType: smart_tile_v5_legacy_layer_unsupported '
        '(version=v5, variant=$runtimeType)',
      );
    }
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
