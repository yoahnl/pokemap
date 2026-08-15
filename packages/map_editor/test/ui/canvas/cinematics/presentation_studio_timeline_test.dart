import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_layer_tree.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_timeline.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  test('zoom anchored under the pointer preserves the targeted instant', () {
    final controller = PresentationTimelineViewportController(
      durationUs: const Duration(minutes: 15).inMicroseconds,
      pixelsPerSecond: 80,
    )..configureViewport(800);
    controller.scrollTo(12340);
    const anchorX = 317.0;
    final before = controller.timeUsAtViewportX(anchorX);

    controller.zoomAt(factor: 2.25, anchorViewportX: anchorX);

    expect(controller.timeUsAtViewportX(anchorX), closeTo(before, 1));
    expect(controller.pixelsPerSecond, 180);
  });

  test('visible clip query is logarithmic plus the returned window', () {
    final clips = List<PresentationAudioClip>.generate(
      5400,
      (index) => PresentationAudioClip(
        id: 'clip-$index',
        startUs: index * 166666,
        durationUs: 100000,
        resourceId: 'audio-$index',
      ),
    );
    final index = PresentationTimelineClipIndex(clips);

    final visible = index.visibleBetween(
      startUs: const Duration(minutes: 8).inMicroseconds,
      endUs: const Duration(minutes: 8, seconds: 8).inMicroseconds,
    );

    expect(visible.length, lessThan(60));
    expect(visible.first.startUs, greaterThanOrEqualTo(479900000));
    expect(visible.last.endUs, lessThanOrEqualTo(488100000));
  });

  testWidgets('pointer and keyboard seek without an authoring mutation', (
    tester,
  ) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController();
    final seeks = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 260,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              onPlayheadChanged: seeks.add,
            ),
          ),
        ),
      ),
    );

    final ruler = find.byType(PokeMapCinematicTimelineViewportRuler);
    await tester.tapAt(tester.getTopLeft(ruler) + const Offset(300, 12));
    await tester.pump();
    final pointerSeek = seeks.last;

    await tester.tap(find.byKey(presentationStudioTimelineKey));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    await tester.tap(find.text('opening.png'));
    await tester.pump();

    expect(pointerSeek, greaterThan(0));
    expect(seeks.last, pointerSeek + 100000);
    expect(selection.value?.clipId, 'opening');
    expect(selection.origin, PresentationStudioSelectionOrigin.timeline);
    expect(asset.tracks.single.clips.single.startUs, 1000000);
  });

  testWidgets('clip and track widgets stay bounded by the viewport', (
    tester,
  ) async {
    final asset = _largeAsset();
    final selection = PresentationStudioSelectionController();
    final viewport = PresentationTimelineViewportController(
      durationUs: asset.durationUs,
      pixelsPerSecond: 100,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 960,
            height: 240,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              onPlayheadChanged: (_) {},
              viewportController: viewport,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byType(PokeMapCinematicTrackRow).evaluate().length,
      lessThan(8),
    );
    expect(
      find.byType(PokeMapCinematicTimelineClip).evaluate().length,
      lessThan(40),
    );

    viewport.scrollTo(viewport.maxScrollOffset);
    await tester.pump();

    expect(
      find.byType(PokeMapCinematicTrackRow).evaluate().length,
      lessThan(8),
    );
    expect(
      find.byType(PokeMapCinematicTimelineClip).evaluate().length,
      lessThan(40),
    );
  });

  testWidgets('loading disabled and diagnostic states are explicit', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();

    Future<void> pump(PresentationStudioTimelineState state) =>
        tester.pumpWidget(
          MaterialApp(
            theme: PokeMapTheme.dark(),
            home: Scaffold(
              body: PresentationStudioTimeline(
                asset: _asset(),
                playheadUs: 0,
                selectionController: selection,
                onPlayheadChanged: (_) {},
                state: state,
                diagnostic: state == PresentationStudioTimelineState.error
                    ? 'Référence de piste invalide'
                    : null,
              ),
            ),
          ),
        );

    await pump(PresentationStudioTimelineState.loading);
    expect(find.text('Chargement de la timeline'), findsOneWidget);
    await pump(PresentationStudioTimelineState.disabled);
    expect(find.text('Timeline indisponible'), findsOneWidget);
    await pump(PresentationStudioTimelineState.error);
    expect(find.text('Référence de piste invalide'), findsOneWidget);
  });

  test('hot path source has no I/O, codec or in-game timeline dependency', () {
    final source = File(
      'lib/src/ui/canvas/cinematics/presentation/presentation_studio_timeline.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("import 'dart:io'")));
    expect(source, isNot(contains('presentation_cinematic_codec')));
    expect(source, isNot(contains('cinematic_builder_workspace')));
    expect(source, isNot(contains('cinematic_timeline_panel')));
  });
}

PresentationCinematicAsset _asset() => PresentationCinematicAsset(
  id: 'presentation',
  title: 'Ouverture',
  durationUs: const Duration(seconds: 12).inMicroseconds,
  layers: [PresentationLayer(id: 'hero', label: 'Héroïne', zIndex: 0)],
  tracks: [
    PresentationTrack(
      id: 'visual',
      label: 'Image',
      kind: PresentationTrackKind.visual,
      clips: [
        PresentationVisualClip(
          id: 'opening',
          startUs: 1000000,
          durationUs: 4000000,
          layerId: 'hero',
          resourceId: 'opening.png',
        ),
      ],
    ),
  ],
);

PresentationCinematicAsset _largeAsset() {
  const durationUs = 15 * 60 * 1000000;
  final tracks = List<PresentationTrack>.generate(200, (trackIndex) {
    final clips = List<PresentationAudioClip>.generate(900, (clipIndex) {
      return PresentationAudioClip(
        id: 'clip-$trackIndex-$clipIndex',
        startUs: clipIndex * 1000000,
        durationUs: 500000,
        resourceId: 'audio-$trackIndex-$clipIndex',
      );
    });
    return PresentationTrack(
      id: 'track-$trackIndex',
      label: 'Piste $trackIndex',
      kind: PresentationTrackKind.audio,
      clips: clips,
    );
  });
  return PresentationCinematicAsset(
    id: 'long-presentation',
    title: 'Long métrage',
    durationUs: durationUs,
    tracks: tracks,
  );
}
