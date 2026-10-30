import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_runtime/src/application/scene_runtime/world_presentation_image_loader.dart';

import '../scene_image_puzzle_durable_host_test.dart' show writePuzzleMedia;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final malformed in ['source', 'dimensions']) {
    test(
      'puzzle bitmap rejects contradictory $malformed before opening',
      () async {
        final parent = Directory(
          '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle',
        );
        await parent.create(recursive: true);
        final root = await parent.createTemp('bitmap-');
        addTearDown(() => root.delete(recursive: true));
        await writePuzzleMedia(root);
        final catalogFile = File('${root.path}/$projectMediaCatalogStorageKey');
        if (malformed == 'source') {
          final assets = AssetCatalog.fromJson(
            jsonDecode(
              await File('${root.path}/$assetCatalogStorageKey').readAsString(),
            ) as Map<String, dynamic>,
          );
          final source = assets.find('mosaic-source')!;
          final changed = img.Image(width: 40, height: 20)
            ..setPixelRgba(0, 0, 255, 0, 0, 255);
          await File('${root.path}/${assetBlobStorageKey(source.artifact)}')
              .writeAsBytes(img.encodePng(changed));
        } else {
          final catalog = jsonDecode(
            await catalogFile.readAsString(),
          ) as Map<String, dynamic>;
          (((catalog['entries'] as List).single as Map)['technicalMetadata']
                  as Map)['width'] =
              41;
          await catalogFile.writeAsString(jsonEncode(catalog));
        }
        await expectLater(
          WorldPresentationImageLoader(root.path).loadBitmap('mosaic-image'),
          throwsStateError,
        );
      },
    );
  }
}
