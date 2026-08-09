import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';
import 'package:pokemap_hub/platform/file_picker_background_picker.dart';

void main() {
  test(
    'native background picker routes photo library and file sources',
    () async {
      var photoCalls = 0;
      var fileCalls = 0;
      final photo = AvelunePickedBackground(
        name: 'photo.jpg',
        bytes: Uint8List.fromList(<int>[1]),
      );
      final file = AvelunePickedBackground(
        name: 'file.png',
        bytes: Uint8List.fromList(<int>[2]),
      );
      final picker = AvelunePlatformBackgroundPicker(
        pickFromPhotoLibrary: () async {
          photoCalls++;
          return photo;
        },
        pickFromFiles: () async {
          fileCalls++;
          return file;
        },
      );

      expect(
        await picker.pick(AveluneBackgroundSource.photoLibrary),
        same(photo),
      );
      expect(await picker.pick(AveluneBackgroundSource.files), same(file));
      expect(photoCalls, 1);
      expect(fileCalls, 1);
    },
  );
}
