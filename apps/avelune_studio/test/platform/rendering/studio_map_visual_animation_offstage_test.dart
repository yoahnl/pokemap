import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_map_visual_animation_fixtures.dart';

void main() {
  testWidgets(
    'initially Offstage cached child starts when it becomes visible',
    (tester) async {
      final map = animatedMap();
      final (directory, resources) = await animatedResources(tester, map);
      final boundary = GlobalKey();
      final hidden = ValueNotifier(true);
      final child = RepaintBoundary(
        key: boundary,
        child: SizedBox(
          width: 8,
          height: 8,
          child: StudioMapVisual(map: map, resources: resources),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder(
              valueListenable: hidden,
              builder: (_, value, _) => Offstage(offstage: value, child: child),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      hidden.value = false;
      await tester.pump();
      await tester.pump();
      expect(await paintedPixel(tester, boundary), redFrame);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await closeAnimationHost(tester, directory, resources);
      hidden.dispose();
    },
  );

  testWidgets(
    'resource replacement disposes the old image and restarts its own clock',
    (tester) async {
      final map = animatedMap();
      final (oldDirectory, oldResources) = await animatedResources(tester, map);
      final (directory, resources) = await animatedResources(tester, map);
      final oldImage = oldResources.images['atlas']!;
      final boundary = GlobalKey();
      await tester.pumpWidget(animationHost(map, oldResources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await tester.pumpWidget(animationHost(map, resources, boundary));
      await tester.pump();
      await tester.runAsync(() async {
        await oldResources.dispose();
        await oldDirectory.delete(recursive: true);
      });
      expect(oldImage.debugDisposed, isTrue);
      expect(await paintedPixel(tester, boundary), redFrame);
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets('a missing atlas stays idle and never advances the clock', (
    tester,
  ) async {
    final map = animatedMap();
    final (directory, resources) = await animatedResources(
      tester,
      map,
      preload: false,
    );
    await tester.runAsync(() async {
      await File('${directory.path}/atlas.png').delete();
      resources.setActiveMap(map);
      await resources.settled;
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(animationHost(map, resources, boundary));
    await tester.pump();
    expect(resources.images, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await closeAnimationHost(tester, directory, resources);
  });

  for (final zeroOpacity in [false, true]) {
    testWidgets(
      zeroOpacity
          ? 'zero-opacity cached child resumes only when visible'
          : 'fully clipped cached child resumes only when on screen',
      (tester) async {
        final map = animatedMap();
        final (directory, resources) = await animatedResources(tester, map);
        final boundary = GlobalKey();
        final hidden = ValueNotifier(true);
        final child = RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 8,
            height: 8,
            child: StudioMapVisual(map: map, resources: resources),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 8,
                height: 8,
                child: ClipRect(
                  child: ValueListenableBuilder(
                    valueListenable: hidden,
                    child: child,
                    builder: (_, value, child) => zeroOpacity
                        ? Opacity(opacity: value ? 0 : 1, child: child)
                        : Transform.translate(
                            offset: Offset(value ? 1000 : 0, 0),
                            child: child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
        hidden.value = false;
        await tester.pump();
        await tester.pump();
        expect(await paintedPixel(tester, boundary), redFrame);
        await tester.pump(const Duration(milliseconds: 100));
        expect(await paintedPixel(tester, boundary), greenFrame);
        await closeAnimationHost(tester, directory, resources);
        hidden.dispose();
      },
    );
  }
}
