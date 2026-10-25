import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_commerce_port.dart';

part 'pokemon_commerce_import_commands.dart';

enum PokemonCommerceSection {
  overview,
  effects,
  references,
  catalog,
  availability,
}

final class PokemonCommerceController {
  PokemonCommerceController(this.port, {required this.changed});

  final PokemonCommercePort port;
  final void Function() changed;
  PokemonCommerceSnapshot? snapshot;
  ProjectItemDefinition? item;
  ProjectItemDefinition? _baseItem;
  ShopDefinition? shop;
  ShopDefinition? _baseShop;
  PokemonCommerceSection section = PokemonCommerceSection.overview;
  String itemSearch = '';
  String shopSearch = '';
  String? pocketFilter;
  String? error;
  String? notice;
  bool loading = false;
  bool saving = false;
  bool importing = false;
  PokemonCommerceImportPreview? importPreview;
  final fieldErrors = <String, String>{};
  int formVersion = 0;
  bool _disposed = false;
  int _generation = 0;

  bool get dirty =>
      fieldErrors.isNotEmpty ||
      (item != null &&
          jsonEncode(item!.toJson()) != jsonEncode(_baseItem?.toJson())) ||
      (shop != null &&
          jsonEncode(shop!.toJson()) != jsonEncode(_baseShop?.toJson()));

  List<ProjectItemDefinition> get visibleItems {
    final query = itemSearch.trim().toLowerCase();
    return [
      for (final value
          in snapshot?.catalog?.entries ?? const <ProjectItemDefinition>[])
        if ((query.isEmpty ||
                value.id.toLowerCase().contains(query) ||
                value.displayName.toLowerCase().contains(query)) &&
            (pocketFilter == null || value.pocketId == pocketFilter))
          value,
    ];
  }

  List<ShopDefinition> get visibleShops {
    final query = shopSearch.trim().toLowerCase();
    return [
      for (final value in snapshot?.shops ?? const <ShopDefinition>[])
        if (query.isEmpty ||
            value.id.toLowerCase().contains(query) ||
            value.label.toLowerCase().contains(query))
          value,
    ];
  }

  Future<void> analyzeReferences() =>
      load(refresh: true, analyzeReferences: true);

  Future<void> load({
    bool refresh = false,
    bool analyzeReferences = false,
  }) async {
    if ((snapshot != null || loading) && !refresh) return;
    if (refresh && (dirty || saving || importing)) {
      error = 'Actualisation reportée : une fiche est encore en cours.';
      changed();
      return;
    }
    final generation = ++_generation;
    loading = true;
    error = null;
    changed();
    try {
      final loaded = analyzeReferences && port is PokemonCommerceReferencePort
          ? await (port as PokemonCommerceReferencePort).analyzeReferences()
          : await port.load();
      if (_disposed || generation != _generation) return;
      if (dirty || saving || importing) {
        error = 'Actualisation reportée : le brouillon est conservé.';
        return;
      }
      final selectedItemId = item?.id;
      final selectedShopId = shop?.id;
      snapshot = loaded;
      _baseItem = loaded.catalog?.entries
          .where((value) => value.id == selectedItemId)
          .firstOrNull;
      item = _baseItem;
      _baseShop = loaded.shops
          .where((value) => value.id == selectedShopId)
          .firstOrNull;
      shop = _baseShop;
      if ((selectedItemId != null && item == null) ||
          (selectedShopId != null && shop == null)) {
        section = PokemonCommerceSection.overview;
      }
      formVersion++;
      notice = null;
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        changed();
      }
    }
  }

  bool selectItem(ProjectItemDefinition value) {
    if (dirty || saving || importing) return false;
    _baseItem = value;
    fieldErrors.clear();
    formVersion++;
    item = value;
    shop = null;
    _baseShop = null;
    section = PokemonCommerceSection.overview;
    error = null;
    changed();
    return true;
  }

  bool selectShop(ShopDefinition value) {
    if (dirty || saving || importing) return false;
    _baseShop = value;
    fieldErrors.clear();
    formVersion++;
    shop = value;
    item = null;
    _baseItem = null;
    section = PokemonCommerceSection.overview;
    error = null;
    changed();
    return true;
  }

  bool createItem(String id) {
    if (dirty || saving || importing || snapshot?.catalog == null) return false;
    final normalized = id.trim();
    if (normalized.isEmpty ||
        snapshot!.catalog!.entries.any((value) => value.id == normalized)) {
      error = 'Identifiant vide ou déjà utilisé.';
      changed();
      return false;
    }
    _baseItem = null;
    item = ProjectItemDefinition(
      id: normalized,
      displayName: normalized,
      pocketId: 'items',
    );
    shop = null;
    _baseShop = null;
    fieldErrors.clear();
    formVersion++;
    section = PokemonCommerceSection.overview;
    changed();
    return true;
  }

  bool createShop(String id) {
    if (dirty || saving || importing) return false;
    final normalized = id.trim();
    if (normalized.isEmpty ||
        snapshot?.shops.any((value) => value.id == normalized) == true) {
      error = 'Identifiant vide ou déjà utilisé.';
      changed();
      return false;
    }
    _baseShop = null;
    shop = ShopDefinition(id: normalized, label: normalized);
    item = null;
    _baseItem = null;
    fieldErrors.clear();
    formVersion++;
    section = PokemonCommerceSection.overview;
    changed();
    return true;
  }

  void editItem(ProjectItemDefinition Function(ProjectItemDefinition) update) {
    if (item == null || saving || importing) return;
    item = update(item!);
    notice = null;
    changed();
  }

  void editShop(ShopDefinition Function(ShopDefinition) update) {
    if (shop == null || saving || importing) return;
    shop = update(shop!);
    notice = null;
    changed();
  }

  void discardSelected() {
    if (saving || importing) return;
    if (item != null) {
      item = _baseItem;
    } else if (shop != null) {
      shop = _baseShop;
    }
    fieldErrors.clear();
    formVersion++;
    error = null;
    changed();
  }

  void setFieldError(String id, String? message) {
    if (message == null) {
      fieldErrors.remove(id);
    } else {
      fieldErrors[id] = message;
    }
    changed();
  }

  Future<bool> save() async {
    if (!dirty || saving || importing) return false;
    if (fieldErrors.isNotEmpty) {
      error = 'Corrigez les nombres indiqués avant d’enregistrer.';
      changed();
      return false;
    }
    saving = true;
    error = null;
    changed();
    try {
      if (item case final current?) {
        await port.saveItem(_baseItem, current);
      } else if (shop case final current?) {
        await port.saveShop(_baseShop, current);
      }
      if (_disposed) return false;
      final previous = snapshot!;
      final savedItem = item?.normalized();
      final savedShop = shop?.normalized();
      final catalog = savedItem == null
          ? previous.catalog
          : previous.catalog!.copyWith(
              entries: [
                for (final entry in previous.catalog!.entries)
                  if (entry.id == savedItem.id) savedItem else entry,
                if (!previous.catalog!.entries.any(
                  (entry) => entry.id == savedItem.id,
                ))
                  savedItem,
              ],
            );
      final shops = savedShop == null
          ? previous.shops
          : [
              for (final entry in previous.shops)
                if (entry.id == savedShop.id) savedShop else entry,
              if (!previous.shops.any((entry) => entry.id == savedShop.id))
                savedShop,
            ];
      final project = previous.project.copyWith(shops: shops);
      _acceptSavedSnapshot(project, catalog, shops, changedShop: savedShop);
      item = savedItem;
      shop = savedShop;
      _baseItem = savedItem;
      _baseShop = savedShop;
      notice = 'Modifications enregistrées.';
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Enregistrement refusé : $failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }

  Future<bool> saveBagCapacity(
    ProjectBagCapacity before,
    ProjectBagCapacity after,
  ) async {
    if (_disposed ||
        dirty ||
        saving ||
        importing ||
        loading ||
        snapshot == null) {
      return false;
    }
    saving = true;
    final currentSnapshot = snapshot!;
    error = null;
    changed();
    try {
      final outcome = await port.saveBagCapacity(before, after);
      if (_disposed) return true;
      _acceptSavedSnapshot(
        currentSnapshot.project.copyWith(bagCapacity: after),
        currentSnapshot.catalog,
        currentSnapshot.shops,
      );
      notice = 'Capacité du sac enregistrée.';
      error = outcome.refreshWarning;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Enregistrement refusé : $failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }

  void _acceptSavedSnapshot(
    ProjectManifest project,
    ProjectItemCatalog? catalog,
    List<ShopDefinition> shops, {
    ShopDefinition? changedShop,
  }) {
    final previous = snapshot!;
    final diagnostics = changedShop == null
        ? previous.shopDiagnostics
        : [
            for (final diagnostic in previous.shopDiagnostics)
              if (diagnostic.shopId != changedShop.id) diagnostic,
            ...ShopStateValidator(
              project: project.copyWith(shops: [changedShop]),
              knownItemIds: {
                for (final entry
                    in catalog?.entries ?? const <ProjectItemDefinition>[])
                  entry.id,
              },
            ).validate(),
          ];
    snapshot = PokemonCommerceSnapshot(
      project: project,
      catalog: catalog,
      shops: shops,
      references: ProjectItemReferenceIndex(const []),
      narrativeReferences: NarrativeDependencyIndex(),
      shopDiagnostics: diagnostics,
      catalogPath: previous.catalogPath,
      problem: previous.problem,
      referencesComplete: false,
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }

  Future<void> importCaptureSprite({required String sourcePath}) async {
    final current = item;
    if (current?.capture == null || saving || importing || _disposed) return;
    importing = true;
    error = null;
    changed();
    bool isCurrent() => !_disposed && identical(item, current);
    try {
      final path = await port.importCaptureSprite(
        sourcePath: sourcePath,
        itemId: current!.id,
        shouldContinue: isCurrent,
      );
      if (!isCurrent()) return;
      item = current.copyWith(
        capture: current.capture!.copyWith(animationSpritePath: path),
      );
      notice = 'Animation ajoutée au brouillon. Enregistrez pour l’associer.';
    } on Object catch (failure) {
      if (!_disposed) error = 'Import refusé : $failure';
    } finally {
      importing = false;
      if (!_disposed) changed();
    }
  }
}
