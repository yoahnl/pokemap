import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../support/resource_replacement_fixture.dart';
import '../support/run_resource_replacement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'source replacement can be prepared without an active map or placement',
    () async {
      final host = await ResourceReplacementFixture.create(withMap: false);
      final fixture = host.fixture;
      final navigation = host.navigation;
      final imported = host.item.tileset!;
      final file = File('${fixture.root.path}/${imported.relativePath}');
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final pixels = image.decodeImage(bytes)!;
      final before = await host.reopen();
      final maps = await fixture.mapFile.readAsBytes();
      expect(host.workspace.active, isNull);
      await runReplacementForTest(
        navigation: navigation,
        item: resourceCatalog(host.workspace.project!)
            .singleWhere((item) => item.tileset?.id == imported.id),
        picker: () async => PickedResourceImage(
          file.path,
          'Source compatible',
          bytes,
          pixels.width,
          pixels.height,
        ),
        isActive: () => true,
        present: (session) async {
          expect(session.preview.preparation.noChange, isTrue);
          expect(navigation.error, isNull);
          expect(host.workspace.active, isNull);
        },
      );
      expect(await host.reopen(), before);
      expect(await fixture.mapFile.readAsBytes(), maps);
      expect(await file.readAsBytes(), bytes);
      expect(navigation.managementDialogActive, isFalse);
    },
  );

  test(
    'successful replacement clears the previous incompatible candidate error',
    () async {
      final host = await ResourceReplacementFixture.create();
      final fixture = host.fixture;
      final navigation = host.navigation;
      final imported = host.item.tileset!;
      final item = host.item;
      final originalFile = File(
        '${fixture.root.path}/${imported.relativePath}',
      );
      final before = await originalFile.readAsBytes();
      final pixels = image.decodeImage(before)!;
      final maps = await fixture.mapFile.readAsBytes();
      Future<PickedResourceImage> candidate(
        int width,
        int height,
        String name,
      ) async {
        final pixels = image.Image(
          width: width,
          height: height,
          numChannels: 4,
        );
        image.fill(pixels, color: image.ColorRgba8(255, 0, 255, 255));
        final bytes = Uint8List.fromList(image.encodePng(pixels));
        final file = File('${fixture.root.path}/$name.png');
        await file.writeAsBytes(bytes);
        return PickedResourceImage(file.path, name, bytes, width, height);
      }

      final incompatible = await candidate(1, 1, 'incompatible');
      await runReplacementForTest(
        navigation: navigation,
        item: item,
        picker: () async => incompatible,
        isActive: () => true,
        shouldPresent: false,
        present: (_) async =>
            fail('An incompatible candidate cannot be confirmed'),
      );
      expect(navigation.error, contains('tileset.candidate_geometry'));
      expect(await originalFile.readAsBytes(), before);
      expect(navigation.pendingReceipt, isNull);
      expect(navigation.managementDialogActive, isFalse);
      final replacement = await candidate(
        pixels.width,
        pixels.height,
        'compatible',
      );
      await runReplacementForTest(
        navigation: navigation,
        item: item,
        picker: () async => replacement,
        isActive: () => true,
        present: (session) async {
          session.confirm(true);
          expect(await session.apply(), isNull);
        },
      );
      final updated = host.workspace.project!.tilesets.singleWhere(
        (item) => item.id == imported.id,
      );
      final publishedFile = File(
        '${fixture.root.path}/${updated.relativePath}',
      );
      expect(await publishedFile.readAsBytes(), replacement.bytes);
      expect(updated.id, imported.id);
      expect(updated.source, imported.source);
      expect(navigation.pendingReceipt, isNull);
      expect(navigation.error, isNull);
      expect(navigation.managementDialogActive, isFalse);
      expect(
        (await host.reopen()).tilesets.singleWhere(
          (item) => item.id == imported.id,
        ),
        updated,
      );
      expect(await fixture.mapFile.readAsBytes(), maps);
    },
  );
}
