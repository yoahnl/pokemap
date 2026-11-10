import '../domain/pokemon_commerce_port.dart';
import 'pokemon_commerce_controller.dart';

class PokemonCommerceImportWorkflow {
  PokemonCommerceImportWorkflow({
    required this.commerce,
    required this.isActive,
  });

  final PokemonCommerceController commerce;
  final bool Function() isActive;
  bool choosing = false;
  String? refusal;
  bool _disposed = false;

  Future<bool> importJson({
    required bool items,
    required Future<String?> Function() picker,
    required Future<bool> Function(PokemonCommerceImportPreview preview)
    confirm,
  }) async {
    refusal = null;
    if (_disposed ||
        !isActive() ||
        choosing ||
        commerce.importing ||
        commerce.saving) {
      return false;
    }
    if (commerce.dirty) {
      refusal = 'Enregistrez ou annulez le brouillon avant l’import.';
      return false;
    }
    choosing = true;
    try {
      final path = await picker();
      if (_disposed || !isActive() || path == null) return false;
      await commerce.prepareImport(path, item: items);
      if (_disposed || !isActive()) return false;
      final preview = commerce.importPreview;
      if (preview == null) return false;
      final accept = await confirm(preview);
      if (!identical(commerce.importPreview, preview)) return false;
      if (_disposed || !isActive() || !accept) {
        commerce.cancelImport();
        return false;
      }
      return await commerce.applyImport(confirmOverwrite: preview.conflict) &&
          !_disposed &&
          isActive();
    } finally {
      choosing = false;
    }
  }

  void dispose() => _disposed = true;
}
