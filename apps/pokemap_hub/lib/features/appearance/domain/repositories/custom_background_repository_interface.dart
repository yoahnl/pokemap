
import 'package:flutter/foundation.dart';

const int kAveluneMaximumCustomBackgroundBytes = 12 * 1024 * 1024;
const int kAveluneMaximumCustomBackgroundDimension = 1800;
const int kAveluneThumbnailMaximumDimension = 480;

enum AveluneCustomBackgroundImportOutcome { imported, cancelled }

enum AveluneCustomBackgroundErrorCode {
  fileTooLarge,
  unsupportedFormat,
  readFailed,
  decodeFailed,
  writeFailed,
  unsafeStorage,
}

/// Contracts for importing a player-supplied Avelune background.
///
/// These were already `abstract interface class` declarations sitting in
/// `data/`; lot 15 recorded them as contracts without moving them. They belong
/// in `domain/` so the application layer can depend on them without reaching
/// into data.
final class AveluneCustomBackgroundException implements Exception {
  const AveluneCustomBackgroundException(this.code, this.message);

  final AveluneCustomBackgroundErrorCode code;
  final String message;

  @override
  String toString() => 'AveluneCustomBackgroundException(${code.name}): '
      '$message';
}

@immutable
final class AvelunePickedBackground {
  const AvelunePickedBackground({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

@immutable
final class AveluneProcessedBackground {
  const AveluneProcessedBackground({
    required this.imageBytes,
    required this.thumbnailBytes,
    required this.width,
    required this.height,
  });

  final Uint8List imageBytes;
  final Uint8List thumbnailBytes;
  final int width;
  final int height;
}

abstract interface class AveluneBackgroundPicker {
  Future<AvelunePickedBackground?> pick();
}

abstract interface class AveluneBackgroundImageProcessor {
  Future<AveluneProcessedBackground> process(Uint8List bytes);

  Future<bool> validateJpeg(Uint8List bytes);
}

abstract interface class AveluneCustomBackgroundStorage {
  String get imagePath;

  String get thumbnailPath;

  Future<void> replace(AveluneProcessedBackground background);

  Future<bool> isValid();

  Future<void> delete();
}

abstract interface class AveluneCustomBackgroundGateway {
  String get imagePath;

  String get thumbnailPath;

  Future<AveluneCustomBackgroundImportOutcome> pickAndImport();

  Future<bool> isCurrentValid();

  Future<void> delete();
}

/// Native picker adapter. The returned path is read but never persisted.
