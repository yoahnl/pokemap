import 'catalog_storage.dart';

final class CatalogDynamicDependency {
  CatalogDynamicDependency({
    required this.owner,
    required Iterable<CatalogDefinitionKey> targets,
  }) : targets = List.unmodifiable(targets.toList()..sort()) {
    for (final key in [owner, ...this.targets]) {
      if ({
        CatalogDefinitionKind.catalogMetadata,
        CatalogDefinitionKind.fileBinding,
        CatalogDefinitionKind.provenance,
        CatalogDefinitionKind.resourceLibraryEntry,
      }.contains(key.kind)) {
        throw const FormatException(
          'catalog.dynamic: unsupported dependency kind',
        );
      }
    }
    if (this.targets.isEmpty ||
        this.targets.length > 4096 ||
        this.targets.toSet().length != this.targets.length) {
      throw const FormatException(
        'catalog.dynamic: empty, duplicate or excessive targets',
      );
    }
  }

  factory CatalogDynamicDependency.fromJson(Map<String, Object?> json) {
    if (json.length != 2 ||
        !json.containsKey('owner') ||
        json['owner'] is! Map<String, Object?> ||
        json['targets'] is! List<Object?>) {
      throw const FormatException('catalog.dynamic: invalid declaration');
    }
    return CatalogDynamicDependency(
      owner: CatalogDefinitionKey.fromJson(
        json['owner']! as Map<String, Object?>,
      ),
      targets: (json['targets']! as List<Object?>).map((value) {
        if (value is! Map<String, Object?>) {
          throw const FormatException('catalog.dynamic: invalid target');
        }
        return CatalogDefinitionKey.fromJson(value);
      }),
    );
  }

  final CatalogDefinitionKey owner;
  final List<CatalogDefinitionKey> targets;
  Map<String, Object?> toJson() => {
    'owner': owner.toJson(),
    'targets': targets.map((target) => target.toJson()).toList(),
  };
}
