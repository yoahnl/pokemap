import 'package:map_core/map_core_domain.dart';

final class PokemonCommerceSnapshot {
  const PokemonCommerceSnapshot({
    required this.project,
    required this.catalog,
    required this.shops,
    required this.references,
    required this.narrativeReferences,
    required this.shopDiagnostics,
    required this.catalogPath,
    required this.problem,
  });

  final ProjectManifest project;
  final ProjectItemCatalog? catalog;
  final List<ShopDefinition> shops;
  final ProjectItemReferenceIndex references;
  final NarrativeDependencyIndex narrativeReferences;
  final List<ShopStateDiagnostic> shopDiagnostics;
  final String? catalogPath;
  final String? problem;
}

final class PokemonCommerceImportPreview {
  const PokemonCommerceImportPreview({
    required this.item,
    required this.shop,
    required this.existingItem,
    required this.existingShop,
  });

  final ProjectItemDefinition? item;
  final ShopDefinition? shop;
  final ProjectItemDefinition? existingItem;
  final ShopDefinition? existingShop;
  bool get conflict => existingItem != null || existingShop != null;
  String get id => item?.id ?? shop!.id;
  String get label => item?.displayName ?? shop!.label;
}

abstract interface class PokemonCommercePort {
  Future<PokemonCommerceSnapshot> load();

  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  );

  Future<void> saveShop(ShopDefinition? before, ShopDefinition after);

  Future<PokemonCommerceImportPreview> previewJson(
    String path, {
    required bool item,
  });
}
