import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

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
final class AveluneFilePickerBackgroundPicker
    implements AveluneBackgroundPicker {
  const AveluneFilePickerBackgroundPicker();

  @override
  Future<AvelunePickedBackground?> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final selected = result.files.single;
      final path = selected.path;
      if (path != null) {
        final file = File(path);
        if (await file.length() > kAveluneMaximumCustomBackgroundBytes) {
          throw const AveluneCustomBackgroundException(
            AveluneCustomBackgroundErrorCode.fileTooLarge,
            'L’image dépasse la limite de 12 Mo.',
          );
        }
      }
      final bytes = selected.bytes ??
          (path == null ? null : await File(path).readAsBytes());
      if (bytes == null) {
        throw const AveluneCustomBackgroundException(
          AveluneCustomBackgroundErrorCode.readFailed,
          'L’image sélectionnée n’a pas pu être lue.',
        );
      }
      return AvelunePickedBackground(name: selected.name, bytes: bytes);
    } on AveluneCustomBackgroundException {
      rethrow;
    } on Object {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.readFailed,
        'L’image sélectionnée n’a pas pu être lue.',
      );
    }
  }
}

/// Performs every decode, orientation and resize operation outside the UI
/// isolate. Both generated JPEGs are decoded once more before being accepted.
final class AveluneIsolateBackgroundImageProcessor
    implements AveluneBackgroundImageProcessor {
  @override
  Future<AveluneProcessedBackground> process(Uint8List bytes) async {
    try {
      final result = await compute(_processBackground, bytes);
      return AveluneProcessedBackground(
        imageBytes: result['imageBytes']! as Uint8List,
        thumbnailBytes: result['thumbnailBytes']! as Uint8List,
        width: result['width']! as int,
        height: result['height']! as int,
      );
    } on Object {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.decodeFailed,
        'Cette image ne peut pas être décodée.',
      );
    }
  }

  @override
  Future<bool> validateJpeg(Uint8List bytes) => compute(_validateJpeg, bytes);
}

final class AveluneLocalCustomBackgroundStorage
    implements AveluneCustomBackgroundStorage {
  AveluneLocalCustomBackgroundStorage({
    required this.supportRoot,
    required this.processor,
  });

  final Directory supportRoot;
  final AveluneBackgroundImageProcessor processor;
  final Random _random = Random.secure();

  Directory get aveluneRoot => Directory(p.join(supportRoot.path, 'avelune'));

  Directory get appearanceRoot =>
      Directory(p.join(aveluneRoot.path, 'appearance'));

  File get imageFile =>
      File(p.join(appearanceRoot.path, 'custom-background.jpg'));

  File get thumbnailFile => File(
        p.join(appearanceRoot.path, 'custom-background.thumbnail.jpg'),
      );

  @override
  String get imagePath => imageFile.path;

  @override
  String get thumbnailPath => thumbnailFile.path;

  @override
  Future<void> replace(AveluneProcessedBackground background) async {
    await _assertSafeDirectories(create: true);
    await _assertSafeFile(imageFile);
    await _assertSafeFile(thumbnailFile);
    final nonce =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final temporaryImage = File(
      p.join(appearanceRoot.path, 'custom-background.jpg.tmp.$nonce'),
    );
    final temporaryThumbnail = File(
      p.join(
        appearanceRoot.path,
        'custom-background.thumbnail.jpg.tmp.$nonce',
      ),
    );
    final previousImage = File(
      p.join(appearanceRoot.path, 'custom-background.jpg.previous.$nonce'),
    );
    final previousThumbnail = File(
      p.join(
        appearanceRoot.path,
        'custom-background.thumbnail.jpg.previous.$nonce',
      ),
    );
    final hadImage = await imageFile.exists();
    final hadThumbnail = await thumbnailFile.exists();
    try {
      await temporaryImage.writeAsBytes(background.imageBytes, flush: true);
      await temporaryThumbnail.writeAsBytes(
        background.thumbnailBytes,
        flush: true,
      );
      if (!await _validFile(temporaryImage) ||
          !await _validFile(temporaryThumbnail)) {
        throw const FormatException('Generated JPEG validation failed.');
      }
      if (hadImage) await imageFile.copy(previousImage.path);
      if (hadThumbnail) await thumbnailFile.copy(previousThumbnail.path);
      await _promote(temporaryImage, imageFile);
      await _promote(temporaryThumbnail, thumbnailFile);
      if (!await _validFile(imageFile) || !await _validFile(thumbnailFile)) {
        throw const FormatException('Committed JPEG validation failed.');
      }
    } on Object {
      await _restore(previousImage, imageFile, hadPrevious: hadImage);
      await _restore(
        previousThumbnail,
        thumbnailFile,
        hadPrevious: hadThumbnail,
      );
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.writeFailed,
        'L’image personnalisée n’a pas pu être enregistrée.',
      );
    } finally {
      for (final file in <File>[
        temporaryImage,
        temporaryThumbnail,
        previousImage,
        previousThumbnail,
      ]) {
        if (await file.exists()) await file.delete();
      }
    }
  }

  @override
  Future<bool> isValid() async {
    if (!await _assertSafeDirectories(create: false)) return false;
    await _assertSafeFile(imageFile);
    await _assertSafeFile(thumbnailFile);
    if (!await imageFile.exists() || !await thumbnailFile.exists()) {
      return false;
    }
    return await _validFile(imageFile) && await _validFile(thumbnailFile);
  }

  @override
  Future<void> delete() async {
    if (!await _assertSafeDirectories(create: false)) return;
    await _assertSafeFile(imageFile);
    await _assertSafeFile(thumbnailFile);
    try {
      if (await imageFile.exists()) await imageFile.delete();
      if (await thumbnailFile.exists()) await thumbnailFile.delete();
    } on Object {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.writeFailed,
        'L’image personnalisée n’a pas pu être supprimée.',
      );
    }
  }

  Future<bool> _validFile(File file) async =>
      processor.validateJpeg(await file.readAsBytes());

  Future<void> _promote(File temporary, File destination) async {
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
  }

  Future<void> _restore(
    File previous,
    File current, {
    required bool hadPrevious,
  }) async {
    try {
      if (await current.exists()) await current.delete();
      if (hadPrevious && await previous.exists()) {
        await previous.copy(current.path);
      }
    } on Object {
      // The operation still fails; the controller keeps the previous choice.
    }
  }

  Future<bool> _assertSafeDirectories({required bool create}) async {
    for (final directory in <Directory>[
      supportRoot,
      aveluneRoot,
      appearanceRoot,
    ]) {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.notFound &&
              type != FileSystemEntityType.directory)) {
        throw const AveluneCustomBackgroundException(
          AveluneCustomBackgroundErrorCode.unsafeStorage,
          'Le stockage de l’image personnalisée n’est pas sûr.',
        );
      }
      if (type == FileSystemEntityType.notFound) {
        if (!create) return false;
        await directory.create();
      }
    }
    return true;
  }

  Future<void> _assertSafeFile(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.unsafeStorage,
        'Un fichier d’image personnalisée n’est pas sûr.',
      );
    }
  }
}

final class AveluneCustomBackgroundImporter
    implements AveluneCustomBackgroundGateway {
  const AveluneCustomBackgroundImporter({
    required this.picker,
    required this.processor,
    required this.storage,
  });

  final AveluneBackgroundPicker picker;
  final AveluneBackgroundImageProcessor processor;
  final AveluneCustomBackgroundStorage storage;

  @override
  String get imagePath => storage.imagePath;

  @override
  String get thumbnailPath => storage.thumbnailPath;

  @override
  Future<AveluneCustomBackgroundImportOutcome> pickAndImport() async {
    final picked = await picker.pick();
    if (picked == null) return AveluneCustomBackgroundImportOutcome.cancelled;
    if (picked.bytes.length > kAveluneMaximumCustomBackgroundBytes) {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.fileTooLarge,
        'L’image dépasse la limite de 12 Mo.',
      );
    }
    if (!_hasAcceptedSignature(picked.bytes)) {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.unsupportedFormat,
        'Choisissez une image JPEG, PNG ou WebP valide.',
      );
    }
    final processed = await processor.process(picked.bytes);
    try {
      await storage.replace(processed);
    } on AveluneCustomBackgroundException {
      rethrow;
    } on Object {
      throw const AveluneCustomBackgroundException(
        AveluneCustomBackgroundErrorCode.writeFailed,
        'L’image personnalisée n’a pas pu être enregistrée.',
      );
    }
    return AveluneCustomBackgroundImportOutcome.imported;
  }

  @override
  Future<bool> isCurrentValid() => storage.isValid();

  @override
  Future<void> delete() => storage.delete();

  bool _hasAcceptedSignature(Uint8List bytes) {
    final jpeg = bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
    final png = bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
    final webp = bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return jpeg || png || webp;
  }
}

Map<String, Object> _processBackground(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Image decode failed.');
  var oriented = image.bakeOrientation(decoded);
  final longest = max(oriented.width, oriented.height);
  if (longest > kAveluneMaximumCustomBackgroundDimension) {
    oriented = oriented.width >= oriented.height
        ? image.copyResize(
            oriented,
            width: kAveluneMaximumCustomBackgroundDimension,
            interpolation: image.Interpolation.cubic,
          )
        : image.copyResize(
            oriented,
            height: kAveluneMaximumCustomBackgroundDimension,
            interpolation: image.Interpolation.cubic,
          );
  }
  final opaque = image.Image(
    width: oriented.width,
    height: oriented.height,
  );
  image.fill(opaque, color: image.ColorRgb8(0x17, 0x12, 0x18));
  image.compositeImage(opaque, oriented);
  final thumbnail = opaque.width >= opaque.height
      ? image.copyResize(
          opaque,
          width: kAveluneThumbnailMaximumDimension,
          interpolation: image.Interpolation.cubic,
        )
      : image.copyResize(
          opaque,
          height: kAveluneThumbnailMaximumDimension,
          interpolation: image.Interpolation.cubic,
        );
  final imageBytes = image.encodeJpg(opaque, quality: 84);
  final thumbnailBytes = image.encodeJpg(thumbnail, quality: 78);
  if (!_validateJpeg(imageBytes) || !_validateJpeg(thumbnailBytes)) {
    throw const FormatException('Generated JPEG decode failed.');
  }
  return <String, Object>{
    'imageBytes': imageBytes,
    'thumbnailBytes': thumbnailBytes,
    'width': opaque.width,
    'height': opaque.height,
  };
}

bool _validateJpeg(Uint8List bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xFF &&
    bytes[1] == 0xD8 &&
    bytes[2] == 0xFF &&
    image.decodeJpg(bytes) != null;
