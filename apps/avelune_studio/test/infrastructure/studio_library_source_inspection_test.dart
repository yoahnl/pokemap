import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/example_project_assets.dart';

void main() {
  test(
    'the library rejects malformed and mislabeled sources before review',
    () async {
      final root = await Directory('/Users/karim/Library/Caches/AveluneQA')
          .createTemp('studio-library-source-inspection-');
      addTearDown(() => root.delete(recursive: true));
      const picker = NativeResourceImagePicker();
      final invalidPng = File('${root.path}/image-trop-courte.png');
      final wrongGlb = File('${root.path}/mauvaise-extension.glb');
      await invalidPng.writeAsBytes(exampleAtlasPng().take(33).toList());
      await wrongGlb.writeAsBytes(exampleAtlasPng());

      for (final (file, format) in [
        (invalidPng, 'PNG statique'),
        (wrongGlb, 'GLB 2.0'),
      ]) {
        await expectLater(
          picker.inspectLibraryFile(file.path),
          throwsA(
            isA<ResourceFailure>().having(
              (failure) => failure.message,
              'message',
              contains(format),
            ),
          ),
        );
      }
    },
  );
}
