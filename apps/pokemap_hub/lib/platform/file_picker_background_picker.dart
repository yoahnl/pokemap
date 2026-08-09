import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';

/// Host file picker adapter for custom Avelune backgrounds.
///
/// Native integration, so it lives in `platform/` rather than in the
/// appearance feature's data layer.
final class AveluneFilePickerBackgroundPicker
    implements AveluneBackgroundPicker {
  const AveluneFilePickerBackgroundPicker();

  @override
  Future<AvelunePickedBackground?> pick() async {
    try {
      final result = await FilePicker.pickFiles(
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
