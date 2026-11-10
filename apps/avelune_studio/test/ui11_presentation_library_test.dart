import 'dart:io';

import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/presentation_controller_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PresentationControllerFixture fixture;
  late PresentationCinematicAsset original;
  late String imageLayerId;

  setUp(() async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    fixture = await IOOverrides.runZoned(
      PresentationControllerFixture.create,
      getSystemTempDirectory: () => parent,
    );
    final controller = fixture.controller;
    expect(await controller.create(title: 'Bibliothèque'), isTrue);
    final media = await controller.importMedia(
      sourcePath: File('assets/home/hero_landscape.png').absolute.path,
      label: 'Illustration',
      kind: ProjectMediaKind.image,
    );
    expect(media, isNotNull, reason: controller.error);
    expect(
      controller.addMediaClip(media!.media),
      isNotNull,
      reason: controller.error,
    );
    expect(controller.addText(), isNotNull, reason: controller.error);
    expect(await controller.save(), isTrue, reason: controller.error);
    original = controller.active!.asset;
    imageLayerId = original.layers.first.id;
  });
  tearDown(() => fixture.dispose());

  test(
    'visual layer ordering preserves tracks, remains a draft and supports undo',
    () async {
      final controller = fixture.controller;
      final project = await fixture.files.file('project.json').readAsBytes();
      expect(
        controller.moveLayer(imageLayerId, -1),
        isTrue,
        reason: controller.error,
      );
      final moved = controller.active!.asset;
      expect(
        moved.layers.firstWhere((layer) => layer.id == imageLayerId).zIndex,
        greaterThan(
          moved.layers.firstWhere((layer) => layer.id != imageLayerId).zIndex,
        ),
      );
      expect(moved.tracks, original.tracks);
      expect(
        controller.moveLayer(imageLayerId, 1),
        isTrue,
        reason: controller.error,
      );
      expect(controller.active!.asset.layers, unorderedEquals(original.layers));
      expect(controller.active!.asset.tracks, original.tracks);
      final restored = controller.active!.asset;
      controller.undo();
      expect(controller.active!.asset, moved);
      controller.undo();
      expect(controller.active!.asset, original);
      controller.redo();
      expect(controller.active!.asset, moved);
      controller.redo();
      expect(controller.active!.asset, restored);
      controller.undo();
      expect(controller.active!.asset, moved);
      controller.undo();
      expect(controller.active!.asset, original);
      expect(await fixture.files.file('project.json').readAsBytes(), project);
      expect((await fixture.port.inner.load(original.id)).asset, original);
    },
  );

  test(
    'archive and restore preserve the real asset after independent reopening',
    () async {
      final controller = fixture.controller;
      expect(
        await controller.setArchived(original.id, true),
        isTrue,
        reason: controller.error,
      );
      expect(
        controller.catalog
            .entryFor(CinematicLibraryFamily.presentation, original.id)!
            .isArchived,
        isTrue,
      );
      expect(
        (await fixture.port.inner.load(original.id)).entry!.isArchived,
        isTrue,
      );
      expect(controller.active!.asset, original);
      expect(
        await controller.setArchived(original.id, false),
        isTrue,
        reason: controller.error,
      );
      expect(
        controller.catalog
            .entryFor(CinematicLibraryFamily.presentation, original.id)!
            .isArchived,
        isFalse,
      );
      final reopened = await fixture.port.inner.load(original.id);
      expect(reopened.entry!.isArchived, isFalse);
      expect(reopened.asset, original);
    },
  );

  test('unknown, out-of-bounds and locked layer moves preserve the draft and publication', () async {
    final controller = fixture.controller;
    final front = original.layers.singleWhere(
      (layer) => layer.id != imageLayerId,
    );
    expect(controller.moveLayer('missing', -1), isFalse);
    expect(controller.moveLayer(imageLayerId, 1), isFalse);
    expect(controller.moveLayer(front.id, -1), isFalse);
    expect(controller.active!.asset, original);
    expect(
      controller.apply('presentationLayer.setLocked', {
        'layerId': imageLayerId,
        'locked': true,
      }),
      isTrue,
      reason: controller.error,
    );
    final locked = controller.active!.asset;
    expect(controller.moveLayer(imageLayerId, -1), isFalse);
    expect(controller.active!.asset, locked);
    controller.undo();
    expect(controller.active!.asset, original);
    expect(
      controller.moveLayer(imageLayerId, -1),
      isTrue,
      reason: controller.error,
    );
    expect((await fixture.port.inner.load(original.id)).asset, original);
  });
}
