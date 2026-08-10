import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_playback_controller.dart';
import 'package:map_editor/src/features/character_studio/presentation/animations/character_animation_preview.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  test('playback cadence matches per-frame runtime boundaries', () {
    final controller = CharacterAnimationPlaybackController(
      frames: _frames,
      loop: true,
    )..play();

    controller.advance(const Duration(milliseconds: 99));
    expect(controller.currentFrameIndex, 0);
    controller.advance(const Duration(milliseconds: 1));
    expect(controller.currentFrameIndex, 1);
    controller.advance(const Duration(milliseconds: 199));
    expect(controller.currentFrameIndex, 1);
    controller.advance(const Duration(milliseconds: 1));
    expect(controller.currentFrameIndex, 0);
  });

  test(
    'non-looping playback stops on the last frame and speed is transient',
    () {
      final controller =
          CharacterAnimationPlaybackController(frames: _frames, loop: false)
            ..speed = 2
            ..play();

      controller.advance(const Duration(milliseconds: 50));
      expect(controller.currentFrameIndex, 1);
      controller.advance(const Duration(seconds: 2));

      expect(controller.currentFrameIndex, 1);
      expect(controller.isPlaying, isFalse);
      expect(controller.speed, 2);
    },
  );

  test('replaying a completed non-looping clip restarts at frame zero', () {
    final controller = CharacterAnimationPlaybackController(
      frames: _frames,
      loop: false,
    )..play();

    controller.advance(const Duration(seconds: 1));
    expect(controller.isPlaying, isFalse);
    expect(controller.currentFrameIndex, 1);

    controller.play();

    expect(controller.isPlaying, isTrue);
    expect(controller.currentFrameIndex, 0);
  });

  test('step controls wrap deterministically while paused', () {
    final controller = CharacterAnimationPlaybackController(
      frames: _frames,
      loop: true,
    );

    controller.stepPrevious();
    expect(controller.currentFrameIndex, 1);
    controller.stepNext();
    expect(controller.currentFrameIndex, 0);
    expect(controller.isPlaying, isFalse);
  });

  testWidgets('preview plays with pump time and persists only loop changes', (
    tester,
  ) async {
    var loop = true;
    var loopChanges = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                width: 520,
                height: 380,
                child: CharacterAnimationPreview(
                  sourceBytes: base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                  ),
                  frames: _frames,
                  loop: loop,
                  slotIdentity: 'base-north',
                  directionLabel: 'Nord',
                  enabled: true,
                  onLoopChanged: (value) async {
                    loopChanges++;
                    loop = value;
                    rebuild(() {});
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('animation-preview-frame-0')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-preview-play-pause')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('animation-preview-frame-1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-preview-loop')),
    );
    await tester.pump();
    expect(loop, isFalse);
    expect(loopChanges, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('animation-preview-speed-2')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-preview-zoom-4')),
    );
    await tester.pump();
    expect(loopChanges, 1);
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('Zoom 4×'), findsOneWidget);
  });

  testWidgets('slot replacement cancels playback and resets the frame', (
    tester,
  ) async {
    var identity = 'base-north';
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SizedBox(
                width: 520,
                height: 380,
                child: CharacterAnimationPreview(
                  sourceBytes: base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                  ),
                  frames: _frames,
                  loop: true,
                  slotIdentity: identity,
                  directionLabel: 'Nord',
                  enabled: true,
                  onLoopChanged: (_) async {},
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('animation-preview-play-pause')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey<String>('animation-preview-frame-1')),
      findsOneWidget,
    );

    identity = 'base-south';
    rebuild(() {});
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('animation-preview-frame-0')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}

const _frames = <CharacterAnimationFrame>[
  CharacterAnimationFrame(
    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
    durationMs: 100,
  ),
  CharacterAnimationFrame(
    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
    durationMs: 200,
  ),
];
