import 'pokemon_commerce_controller.dart';

class PokemonCaptureSpritePickerController {
  PokemonCaptureSpritePickerController({
    required this.commerce,
    required this.isActive,
  });

  final PokemonCommerceController commerce;
  final bool Function() isActive;
  bool choosing = false;
  bool _disposed = false;

  Future<bool> choose(Future<String?> Function() picker) async {
    if (_disposed ||
        !isActive() ||
        choosing ||
        commerce.importing ||
        commerce.saving) {
      return false;
    }
    final item = commerce.item;
    choosing = true;
    try {
      final source = await picker();
      if (_disposed ||
          !isActive() ||
          source == null ||
          !identical(item, commerce.item)) {
        return false;
      }
      await commerce.importCaptureSprite(sourcePath: source);
      return !_disposed && isActive() && commerce.error == null;
    } finally {
      choosing = false;
    }
  }

  void dispose() => _disposed = true;
}
