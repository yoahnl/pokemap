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

  Future<void> load() async {
    if (snapshot != null || loading) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    changed();
    try {
      final loaded = await port.load();
      if (_disposed || generation != _generation) return;
      snapshot = loaded;
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
    if (dirty || saving) return false;
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
    if (dirty || saving) return false;
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
    if (dirty || saving || snapshot?.catalog == null) return false;
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
    if (dirty || saving) return false;
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

  void discard() {
    if (saving) return;
    item = _baseItem;
    shop = _baseShop;
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
    if (!dirty || saving) return false;
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
      final selectedItemId = item?.id;
      final selectedShopId = shop?.id;
      snapshot = await port.load();
      if (_disposed) return false;
      _baseItem = snapshot!.catalog?.entries
          .where((value) => value.id == selectedItemId)
          .firstOrNull;
      item = _baseItem;
      _baseShop = snapshot!.shops
          .where((value) => value.id == selectedShopId)
          .firstOrNull;
      shop = _baseShop;
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

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
