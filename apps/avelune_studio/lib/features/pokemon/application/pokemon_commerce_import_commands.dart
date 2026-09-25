part of 'pokemon_commerce_controller.dart';

extension PokemonCommerceImportCommands on PokemonCommerceController {
  Future<void> prepareImport(String path, {required bool item}) async {
    if (dirty || saving || importing) return;
    importing = true;
    error = null;
    importPreview = null;
    changed();
    try {
      final preview = await port.previewJson(path, item: item);
      if (!_disposed) importPreview = preview;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import impossible : $failure';
    } finally {
      importing = false;
      if (!_disposed) changed();
    }
  }

  Future<bool> applyImport({required bool confirmOverwrite}) async {
    final preview = importPreview;
    if (preview == null ||
        dirty ||
        saving ||
        importing ||
        (preview.conflict && !confirmOverwrite)) {
      return false;
    }
    importing = true;
    error = null;
    changed();
    try {
      if (preview.item case final item?) {
        await port.saveItem(preview.existingItem, item);
      } else if (preview.shop case final shop?) {
        await port.saveShop(preview.existingShop, shop);
      }
      if (_disposed) return false;
      snapshot = await port.load();
      if (_disposed) return false;
      importPreview = null;
      if (preview.item case final item?) {
        selectItem(
          snapshot!.catalog!.entries.firstWhere((value) => value.id == item.id),
        );
      } else if (preview.shop case final shop?) {
        selectShop(snapshot!.shops.firstWhere((value) => value.id == shop.id));
      }
      notice = 'Import ${preview.id} terminé.';
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import refusé : $failure';
      return false;
    } finally {
      importing = false;
      if (!_disposed) changed();
    }
  }

  void cancelImport() {
    importPreview = null;
    changed();
  }
}
