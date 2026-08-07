import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';

/// Reads and writes Avelune appearance choices.
abstract interface class AveluneAppearanceRepositoryInterface {
  Future<AveluneAppearanceRead> load();

  Future<void> save(AveluneAppearancePreferences preferences);
}
