import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'resource_pack_native_remapper.dart';

(String, String) _nativeIdentity(CatalogDefinitionKey key) {
  if (key.kind == CatalogDefinitionKind.characterStudioDefinition) {
    final value = jsonDecode(key.id);
    if (value is! List ||
        value.length != 2 ||
        value[1] is! String ||
        (value[1] as String).isEmpty ||
        !{'characterPortraitState', 'characterAnimationDefinition'}
            .contains(value[0]) ||
        jsonEncode(value) != key.id) {
      throw const FormatException(
          'catalog.dynamic: invalid studio definition key');
    }
    return (value[0] as String, value[1] as String);
  }
  final kind = switch (key.kind) {
    CatalogDefinitionKind.borderRecord => 'borderBlueprint',
    CatalogDefinitionKind.borderVisualSnapshot => 'borderSnapshot',
    CatalogDefinitionKind.catalogMetadata ||
    CatalogDefinitionKind.provenance ||
    CatalogDefinitionKind.resourceLibraryEntry ||
    CatalogDefinitionKind.fileBinding =>
      throw const FormatException(
          'catalog.dynamic: unsupported dependency kind'),
    _ => key.kind.name,
  };
  return (kind, key.id);
}

String resourcePackDynamicNativeKey(CatalogDefinitionKey key) {
  final (kind, id) = _nativeIdentity(key);
  return jsonEncode([kind, null, id]);
}

CatalogDefinitionKey remapResourcePackDynamicKey(
    CatalogDefinitionKey key, ResourcePackReferenceMapping reference) {
  final (kind, sourceId) = _nativeIdentity(key);
  final id = reference(kind, sourceId);
  return CatalogDefinitionKey(
      key.kind,
      key.kind == CatalogDefinitionKind.characterStudioDefinition
          ? jsonEncode([kind, id])
          : id);
}

CatalogDynamicDependency remapResourcePackDynamicDependency(
        CatalogDynamicDependency declaration,
        ResourcePackReferenceMapping reference) =>
    CatalogDynamicDependency(
        owner: remapResourcePackDynamicKey(declaration.owner, reference),
        targets: declaration.targets
            .map((target) => remapResourcePackDynamicKey(target, reference)));
