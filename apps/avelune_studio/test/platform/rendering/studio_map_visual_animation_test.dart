import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'studio_map_visual_animation_fixtures.dart';

void main() {
  testWidgets(
    'editor visibility keeps the renderer, decoded images and animation clock',
    (tester) async {
      final map = animatedMap();
      var decodes = 0;
      final (directory, resources) = await animatedResources(
        tester,
        map,
        decode: (bytes, {transparentColor}) {
          decodes++;
          return decodeRuntimeTilesetImage(
            bytes,
            transparentColor: transparentColor,
          );
        },
      );
      final boundary = GlobalKey();
      final counter = PaintCounter();
      await tester.pumpWidget(
        animationHost(
          map,
          resources,
          boundary,
          editorState: MapEditorState(),
          paintCounter: counter,
        ),
      );
      await tester.pump();
      final dynamic state = tester.state(find.byType(StudioMapVisual));
      final renderer = state.renderer;
      final image = resources.images['atlas'];
      expect(await paintedPixel(tester, boundary), redFrame);
      final initialDecodes = decodes;
      await tester.pumpWidget(
        animationHost(
          map,
          resources,
          boundary,
          editorState: MapEditorState(hiddenElements: {'layer:tiles'}),
          paintCounter: counter,
        ),
      );
      expect(await paintedPixel(tester, boundary), [0, 0, 0, 0]);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpWidget(
        animationHost(
          map,
          resources,
          boundary,
          editorState: MapEditorState(),
          paintCounter: counter,
        ),
      );
      expect(await paintedPixel(tester, boundary), greenFrame);
      expect(tester.state(find.byType(StudioMapVisual)), same(state));
      expect(state.renderer, same(renderer));
      expect(resources.images['atlas'], same(image));
      expect(decodes, initialDecodes);
      final beforeLock = counter.count;
      await tester.pumpWidget(
        animationHost(
          map,
          resources,
          boundary,
          editorState: MapEditorState(lockedFamilies: {'layer'}),
          paintCounter: counter,
        ),
      );
      expect(counter.count, beforeLock);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets(
    'non-binary millisecond boundaries cannot leave the painted frame behind the clock',
    (tester) async {
      final map = animatedMap();
      final (directory, resources) = await animatedResources(
        tester,
        map,
        durations: [1001, 2001, 3001],
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(animationHost(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(await paintedPixel(tester, boundary), redFrame);
      await tester.pump(const Duration(microseconds: 999));
      expect(await paintedPixel(tester, boundary), redFrame);
      await tester.pump(const Duration(microseconds: 1));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await tester.pump(const Duration(milliseconds: 2001));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await tester.pump(const Duration(milliseconds: 3001));
      expect(await paintedPixel(tester, boundary), redFrame);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets(
    'native atlas paints all three timed frames at boundaries and loops',
    (tester) async {
      final map = animatedMap();
      final (directory, resources) = await animatedResources(tester, map);
      final boundary = GlobalKey();
      final paintCounter = PaintCounter();
      await tester.pumpWidget(
        animationHost(map, resources, boundary, paintCounter: paintCounter),
      );
      await tester.pump();
      final painted = paintCounter.count;
      expect(await paintedPixel(tester, boundary), redFrame);
      await tester.pump(const Duration(milliseconds: 99));
      expect(await paintedPixel(tester, boundary), redFrame);
      expect(paintCounter.count, painted);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await paintedPixel(tester, boundary), greenFrame);
      expect(paintCounter.count, painted + 1);
      await tester.pump(const Duration(milliseconds: 199));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await tester.pump(const Duration(milliseconds: 299));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await paintedPixel(tester, boundary), redFrame);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets(
    'TickerMode pauses clock and resumes without hidden elapsed time',
    (tester) async {
      final map = animatedMap();
      final (directory, resources) = await animatedResources(tester, map);
      final boundary = GlobalKey();
      await tester.pumpWidget(animationHost(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await tester.pumpWidget(
        animationHost(map, resources, boundary, ticking: false),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(await paintedPixel(tester, boundary), greenFrame);
      await tester.pumpWidget(animationHost(map, resources, boundary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 199));
      expect(await paintedPixel(tester, boundary), greenFrame);
      await tester.pump(const Duration(milliseconds: 1));
      expect(await paintedPixel(tester, boundary), blueFrame);
      await closeAnimationHost(tester, directory, resources);
    },
  );

  testWidgets('Offstage pauses and disposal reaps the animation ticker', (
    tester,
  ) async {
    final map = animatedMap();
    final (directory, resources) = await animatedResources(tester, map);
    final boundary = GlobalKey();
    await tester.pumpWidget(animationHost(map, resources, boundary));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(
      animationHost(map, resources, boundary, offstage: true),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(animationHost(map, resources, boundary));
    await tester.pump();
    expect(await paintedPixel(tester, boundary), greenFrame);
    await tester.pump(const Duration(milliseconds: 200));
    expect(await paintedPixel(tester, boundary), blueFrame);
    await closeAnimationHost(tester, directory, resources);
  });
}
