import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';

enum AveluneAppearanceSource { current, backup, defaults }

final class AveluneAppearanceRead {
  const AveluneAppearanceRead({
    required this.preferences,
    required this.source,
    required this.currentCorrupt,
    required this.backupCorrupt,
  });

  final AveluneAppearancePreferences preferences;
  final AveluneAppearanceSource source;
  final bool currentCorrupt;
  final bool backupCorrupt;
}

final class AveluneAppearanceStorageException implements Exception {
  const AveluneAppearanceStorageException(this.message);

  final String message;

  @override
  String toString() => 'AveluneAppearanceStorageException: $message';
}
