import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'support/ui10_cinematic_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'UI10 real map paints inside a new RepaintBoundary with unbounded recording clip',
    (tester) async {
      final fixture = (await tester.runAsync(() => createUi10Fixture()))!;
      final resources = (await tester.runAsync(() async {
        final manifest = await fixture.readFresh();
        final result = await StudioMapResources.load(fixture.session, manifest);
        final loaded = await fixture.maps.loadMap(
          fixture.session,
          manifest.maps.first,
        );
        result.setActiveMap(loaded.map);
        await result.settled;
        return (result, loaded.map);
      }))!;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 768,
                height: 512,
                child: resources.$1.canvas(resources.$2),
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      expect((image.width, image.height), (768, 512));
      image.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      resources.$1.dispose();
      await tester.runAsync(fixture.dispose);
    },
  );

  test(
    'UI10 canonical actor renderer selects walk frames at absolute time and rewinds exactly',
    () async {
      final fixture = await createUi10Fixture();
      addTearDown(fixture.dispose);
      final manifest = await fixture.readFresh();
      final image = await decodeRuntimeTilesetImage(
        await File(
          '${fixture.directory.path}/assets/ui10_actor.png',
        ).readAsBytes(),
        transparentColor: TilesetTransparentColor.fromHexRgb('ff00ff'),
      );
      addTearDown(image.dispose);
      Future<Uint8List> frame(int ms, EntityFacing facing) async {
        final renderer = RuntimeAuthoringCharacterRenderer(
          character: manifest.characters.single,
          settings: manifest.settings,
          images: {'actor': image},
          facing: facing,
          animationState: CharacterAnimationState.walk,
          elapsedMs: ms,
        );
        expect(renderer.hasVisual, isTrue);
        final recorder = ui.PictureRecorder();
        renderer.paintThumbnail(
          ui.Canvas(recorder),
          const ui.Rect.fromLTWH(0, 0, 64, 64),
        );
        final picture = recorder.endRecording();
        final rendered = await picture.toImage(64, 64);
        final bytes = (await rendered.toByteData())!.buffer.asUint8List();
        rendered.dispose();
        picture.dispose();
        return bytes;
      }

      final initial = await frame(0, EntityFacing.east);
      expect(await frame(200, EntityFacing.east), isNot(initial));
      expect(await frame(0, EntityFacing.east), initial);
      expect(await frame(0, EntityFacing.north), isNot(initial));
      final missing = RuntimeAuthoringCharacterRenderer(
        character: manifest.characters.single,
        settings: manifest.settings,
        images: {'actor': image},
        customAnimation: const CharacterCustomAnimationClip(
          definitionId: 'wave',
          sourceAssetId: 'missing',
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 64, height: 64),
            ),
          ],
        ),
      );
      expect(missing.hasVisual, isFalse);
    },
  );
}
