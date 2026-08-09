import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';

typedef AveluneBackgroundPickDelegate =
    Future<AvelunePickedBackground?> Function();

final class AvelunePlatformBackgroundPicker
    implements AveluneBackgroundPicker {
  const AvelunePlatformBackgroundPicker({
    this.pickFromPhotoLibrary = _pickFromPhotoLibrary,
    this.pickFromFiles = _pickFromFiles,
  });

  final AveluneBackgroundPickDelegate pickFromPhotoLibrary;
  final AveluneBackgroundPickDelegate pickFromFiles;

  @override
  Future<AvelunePickedBackground?> pick(AveluneBackgroundSource source) =>
      switch (source) {
        AveluneBackgroundSource.photoLibrary => pickFromPhotoLibrary(),
        AveluneBackgroundSource.files => pickFromFiles(),
      };
}

Future<AvelunePickedBackground?> _pickFromPhotoLibrary() async {
  try {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (selected == null) return null;
    final length = await selected.length();
    _ensureAcceptedSize(length);
    return AvelunePickedBackground(
      name: selected.name,
      bytes: await selected.readAsBytes(),
    );
  } on AveluneCustomBackgroundException {
    rethrow;
  } on Object {
    throw const AveluneCustomBackgroundException(
      AveluneCustomBackgroundErrorCode.readFailed,
      'L’image sélectionnée n’a pas pu être lue.',
    );
  }
}

Future<AvelunePickedBackground?> _pickFromFiles() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    _ensureAcceptedSize(selected.size);
    final bytes = selected.bytes ??
        (selected.path == null
            ? null
            : await File(selected.path!).readAsBytes());
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

void _ensureAcceptedSize(int bytes) {
  if (bytes <= kAveluneMaximumCustomBackgroundBytes) return;
  throw const AveluneCustomBackgroundException(
    AveluneCustomBackgroundErrorCode.fileTooLarge,
    'L’image dépasse la limite de 12 Mo.',
  );
}
