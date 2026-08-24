import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_timeline_command.dart';
import 'package:map_editor/src/application/authoring_api/presentation_timeline_projection_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_layer_tree.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_timeline.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_timeline_editing_controller.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('English empty timeline stays operable at 200 percent', (
    tester,
  ) async {
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);
    final asset = PresentationCinematicAsset(
      id: 'empty',
      title: 'Empty',
      durationUs: 4_000_000,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: PokeMapTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 320,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              onPlayheadChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Undo the last clip edit'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapCinematicTimelineViewportRuler>(
            find.byType(PokeMapCinematicTimelineViewportRuler),
          )
          .semanticLabel,
      'Presentation time ruler',
    );
    expect(find.text('Empty timeline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  test('moving the playhead never invalidates the lane layout', () {
    final controller = PresentationTimelineViewportController(
      durationUs: const Duration(minutes: 2).inMicroseconds,
      pixelsPerSecond: 80,
    )..configureViewport(800);

    var layoutNotifications = 0;
    var playheadNotifications = 0;
    controller.addListener(() => layoutNotifications += 1);
    controller.playhead.addListener(() => playheadNotifications += 1);

    for (var frame = 1; frame <= 60; frame += 1) {
      controller.seekTo(frame * 16_666);
    }

    expect(controller.playhead.value, 60 * 16_666);
    expect(playheadNotifications, 60);
    // The lanes, the clips and the projections do not move with time. If a
    // playhead tick invalidated them, playback would rebuild every visible
    // clip sixty times a second.
    expect(layoutNotifications, 0);

    controller.scrollTo(120);
    expect(layoutNotifications, 1);
    controller.zoomAt(factor: 2, anchorViewportX: 400);
    expect(layoutNotifications, 2);
    expect(playheadNotifications, 60);
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

  testWidgets('a live playhead moves the marker and the ruler', (tester) async {
    final asset = _asset();
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);
    final playhead = ValueNotifier<int>(0);
    addTearDown(playhead.dispose);
    final viewport = PresentationTimelineViewportController(
      durationUs: asset.durationUs,
      pixelsPerSecond: 100,
    );
    addTearDown(viewport.dispose);

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
              playhead: playhead,
              selectionController: selection,
              onPlayheadChanged: (_) {},
              viewportController: viewport,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final before = tester.getTopLeft(
      find.byKey(presentationStudioTimelinePlayheadKey),
    );

    playhead.value = 1_000_000;
    await tester.pump();

    final after = tester.getTopLeft(
      find.byKey(presentationStudioTimelinePlayheadKey),
    );

    // One second at a hundred pixels per second.
    expect(after.dx - before.dx, closeTo(100, 0.5));
    expect(viewport.playheadUs, 1_000_000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio selection is forwarded to the shared inspector', (
    tester,
  ) async {
    final asset = PresentationCinematicAsset(
      id: 'audio-presentation',
      title: 'Audio',
      durationUs: const Duration(seconds: 5).inMicroseconds,
      tracks: [
        PresentationTrack(
          id: 'audio',
          label: 'Audio',
          kind: PresentationTrackKind.audio,
          clips: [
            PresentationAudioClip(
              id: 'voice',
              startUs: 0,
              durationUs: const Duration(seconds: 2).inMicroseconds,
              resourceId: 'voice.ogg',
              audioKind: PresentationAudioKind.voice,
              bus: PresentationAudioBus.voice,
            ),
          ],
        ),
      ],
    );
    final selection = PresentationStudioSelectionController();
    addTearDown(selection.dispose);

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
              onPlayheadChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-timeline-clip-voice')),
    );
    await tester.pump();

    expect(selection.value?.clipId, 'voice');
    expect(selection.value?.layerId, isNull);
    expect(selection.origin, PresentationStudioSelectionOrigin.timeline);
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

  testWidgets('drag previews locally and commits once only on release', (
    tester,
  ) async {
    final asset = _asset();
    final editing = PresentationTimelineEditingController(asset: asset);
    final commands = <PresentationTimelineClipCommand>[];

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
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final clip = find.byKey(
      const ValueKey<String>('presentation-timeline-clip-opening'),
    );
    final gesture = await tester.startGesture(tester.getCenter(clip));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump();

    expect(commands, isEmpty);
    expect(editing.previewClip('opening').startUs, 1200000);

    await gesture.up();
    await tester.pump();

    expect(commands, hasLength(1));
    expect(commands.single.actionId, 'presentationClip.batch');
    expect(commands.single.operations.single['startUs'], 1200000);
  });

  testWidgets('dragging one selected clip preserves the whole selection', (
    tester,
  ) async {
    final source = _asset();
    final sourceTrack = source.tracks.single;
    final asset = PresentationCinematicAsset(
      id: source.id,
      title: source.title,
      durationUs: source.durationUs,
      layers: source.layers,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: sourceTrack.id,
          label: sourceTrack.label,
          kind: sourceTrack.kind,
          clips: <PresentationClip>[
            ...sourceTrack.clips,
            PresentationVisualClip(
              id: 'closing',
              startUs: 7000000,
              durationUs: 2000000,
              layerId: 'hero',
              resourceId: 'closing.png',
            ),
          ],
        ),
      ],
    );
    final editing = PresentationTimelineEditingController(asset: asset)
      ..selectClip('opening')
      ..selectClip('closing', additive: true);
    final commands = <PresentationTimelineClipCommand>[];

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
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final clip = find.byKey(
      const ValueKey<String>('presentation-timeline-clip-opening'),
    );
    final gesture = await tester.startGesture(tester.getCenter(clip));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(16, 0));
    await gesture.up();
    await tester.pump();

    expect(commands, hasLength(1));
    expect(commands.single.operations, hasLength(2));
    expect(
      commands.single.operations.map((operation) => operation['clipId']),
      <Object?>['opening', 'closing'],
    );
  });

  testWidgets('Escape cancels an active drag before pointer release', (
    tester,
  ) async {
    final asset = _asset();
    final editing = PresentationTimelineEditingController(asset: asset);
    final commands = <PresentationTimelineClipCommand>[];

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
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final clip = find.byKey(
      const ValueKey<String>('presentation-timeline-clip-opening'),
    );
    final gesture = await tester.startGesture(tester.getCenter(clip));
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.up();
    await tester.pump();

    expect(commands, isEmpty);
    expect(editing.hasActiveDrag, isFalse);
    expect(editing.previewClip('opening').startUs, 1000000);
  });

  testWidgets('trim handle previews then emits one start trim batch', (
    tester,
  ) async {
    final asset = _asset();
    final editing = PresentationTimelineEditingController(asset: asset);
    final commands = <PresentationTimelineClipCommand>[];

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
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('opening.png'));
    await tester.pump();

    final handle = find.bySemanticsLabel('Rogner le début de opening.png');
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump();

    expect(commands, isEmpty);
    expect(editing.previewClip('opening').startUs, 1200000);
    expect(editing.previewClip('opening').durationUs, 3800000);

    await gesture.up();
    await tester.pump();

    expect(commands, hasLength(1));
    expect(commands.single.operations.single['startUs'], 1200000);
    expect(commands.single.operations.single['durationUs'], 3800000);
  });

  testWidgets('vertical drag previews on a compatible target track', (
    tester,
  ) async {
    final source = _asset();
    final asset = PresentationCinematicAsset(
      id: source.id,
      title: source.title,
      durationUs: source.durationUs,
      layers: source.layers,
      tracks: <PresentationTrack>[
        ...source.tracks,
        PresentationTrack(
          id: 'visual-secondary',
          label: 'Image secondaire',
          kind: PresentationTrackKind.visual,
        ),
      ],
    );
    final editing = PresentationTimelineEditingController(asset: asset);
    final commands = <PresentationTimelineClipCommand>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 280,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final clip = find.byKey(
      const ValueKey<String>('presentation-timeline-clip-opening'),
    );
    final sourceTop = tester.getTopLeft(clip).dy;
    final gesture = await tester.startGesture(tester.getCenter(clip));
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();

    expect(tester.getTopLeft(clip).dy, greaterThan(sourceTop + 40));

    await gesture.up();
    await tester.pump();

    expect(
      commands.single.operations.single['targetTrackId'],
      'visual-secondary',
    );
  });

  testWidgets('desktop clipboard shortcut emits one explicit paste batch', (
    tester,
  ) async {
    final asset = _asset();
    final editing = PresentationTimelineEditingController(
      asset: asset,
      duplicateIdFactory: (_) => 'opening-copy',
    );
    final commands = <PresentationTimelineClipCommand>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 260,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 6000000,
              selectionController: PresentationStudioSelectionController(),
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: commands.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('opening.png'));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(commands, hasLength(1));
    expect(commands.single.operations.single, <String, Object?>{
      'kind': 'duplicate',
      'clipId': 'opening',
      'duplicateId': 'opening-copy',
      'targetTrackId': 'visual',
      'startUs': 6000000,
    });
  });

  testWidgets('canvas or layer selection becomes the timeline primary clip', (
    tester,
  ) async {
    final asset = _asset();
    final editing = PresentationTimelineEditingController(asset: asset);
    final selection = PresentationStudioSelectionController();

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
              editingController: editing,
              onPlayheadChanged: (_) {},
              onCommand: (_) {},
            ),
          ),
        ),
      ),
    );

    selection.selectClip(
      asset: asset,
      clipId: 'opening',
      origin: PresentationStudioSelectionOrigin.canvas,
    );
    await tester.pump();

    expect(editing.selectedClipIds, <String>{'opening'});
  });

  testWidgets('specialized tracks render cached media and marker semantics', (
    tester,
  ) async {
    final asset = _specializedAsset();
    final gateway = _SpecializedProjectionGateway();
    final projections = PresentationTimelineProjectionController(
      projectRootPath: '/project',
      gateway: gateway,
    );
    final selection = PresentationStudioSelectionController();
    addTearDown(projections.dispose);
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 360,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              projectionController: projections,
              markerUsageCountById: const <String, int>{'cue': 2},
              onPlayheadChanged: (_) {},
              onCommand: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapCinematicAudioTimelinePreview), findsOneWidget);
    expect(find.byType(PokeMapCinematicVideoTimelinePreview), findsOneWidget);
    expect(find.byType(PokeMapCinematicCaptionTimelinePreview), findsOneWidget);
    expect(find.byType(PokeMapCinematicMarkerTimelinePreview), findsOneWidget);
    final audio = tester.widget<PokeMapCinematicAudioTimelinePreview>(
      find.byType(PokeMapCinematicAudioTimelinePreview),
    );
    final captions = tester.widget<PokeMapCinematicCaptionTimelinePreview>(
      find.byType(PokeMapCinematicCaptionTimelinePreview),
    );
    final marker = tester.widget<PokeMapCinematicMarkerTimelinePreview>(
      find.byType(PokeMapCinematicMarkerTimelinePreview),
    );
    expect(audio.loop, isTrue);
    expect(audio.fadeInFraction, 0.25);
    expect(captions.hasOverlap, isTrue);
    expect(marker.sceneUsageCount, 2);
    expect(gateway.requests, hasLength(3));

    await tester.drag(
      find.byKey(const ValueKey<String>('presentation-timeline-clip-audio')),
      const Offset(20, 0),
    );
    await tester.pump();

    expect(gateway.requests, hasLength(3));
  });

  testWidgets('missing media keeps clip geometry and exposes a diagnostic', (
    tester,
  ) async {
    final asset = PresentationCinematicAsset(
      id: 'missing-media',
      title: 'Missing media',
      durationUs: 5000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'audio',
          label: 'Audio',
          kind: PresentationTrackKind.audio,
          clips: <PresentationClip>[
            PresentationAudioClip(
              id: 'missing',
              startUs: 0,
              durationUs: 2000000,
              resourceId: 'missing-media',
            ),
          ],
        ),
      ],
    );
    final projections = PresentationTimelineProjectionController(
      projectRootPath: '/project',
      gateway: _MissingProjectionGateway(),
    );
    final selection = PresentationStudioSelectionController();
    addTearDown(projections.dispose);
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 160,
            child: PresentationStudioTimeline(
              asset: asset,
              playheadUs: 0,
              selectionController: selection,
              projectionController: projections,
              onPlayheadChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final clip = tester.widget<PokeMapCinematicTimelineClip>(
      find.byType(PokeMapCinematicTimelineClip),
    );
    expect(clip.state, PokeMapCinematicTimelineClipState.error);
    expect(clip.stateLabel, 'Média introuvable');
    expect(
      tester.getSize(find.byType(PokeMapCinematicTimelineClip)).width,
      160,
    );
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

PresentationCinematicAsset _specializedAsset() => PresentationCinematicAsset(
  id: 'specialized',
  title: 'Specialized',
  durationUs: 8000000,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'video-layer', label: 'Vidéo', zIndex: 0),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'audio-track',
      label: 'Audio',
      kind: PresentationTrackKind.audio,
      clips: <PresentationClip>[
        PresentationAudioClip(
          id: 'audio',
          startUs: 0,
          durationUs: 4000000,
          resourceId: 'audio-media',
          loop: true,
          fadeInUs: 1000000,
          fadeOutUs: 500000,
        ),
      ],
    ),
    PresentationTrack(
      id: 'video-track',
      label: 'Vidéo',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'video',
          startUs: 0,
          durationUs: 4000000,
          layerId: 'video-layer',
          resourceId: 'video-media',
          mediaKind: PresentationVisualMediaKind.video,
        ),
      ],
    ),
    PresentationTrack(
      id: 'captions-track',
      label: 'Captions',
      kind: PresentationTrackKind.caption,
      clips: <PresentationClip>[
        PresentationCaptionClip(
          id: 'captions',
          startUs: 0,
          durationUs: 4000000,
          captionId: 'caption-media',
          locale: 'fr-FR',
        ),
      ],
    ),
    PresentationTrack(
      id: 'marker-track',
      label: 'Repères',
      kind: PresentationTrackKind.marker,
      clips: <PresentationClip>[
        PresentationMarkerClip(
          id: 'cue',
          startUs: 1000000,
          label: 'Choix starter',
          markerKind: PresentationMarkerKind.interactionCue,
          required: true,
        ),
      ],
    ),
  ],
);

final class _SpecializedProjectionGateway
    implements PresentationTimelineProjectionGateway {
  final List<PresentationTimelineProjectionRequest> requests = [];

  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) async {
    requests.add(request);
    return switch (request.kind) {
      PresentationTimelineProjectionKind.audio =>
        PresentationTimelineMediaProjection.ready(
          mediaId: request.mediaId,
          waveform: const <double>[0.2, 0.7, 1, 0.4],
        ),
      PresentationTimelineProjectionKind.video =>
        PresentationTimelineMediaProjection.ready(
          mediaId: request.mediaId,
          thumbnailBytes: image.encodePng(image.Image(width: 4, height: 2)),
        ),
      PresentationTimelineProjectionKind.captions =>
        PresentationTimelineMediaProjection.ready(
          mediaId: request.mediaId,
          captions: const <PresentationTimelineCaptionSegment>[
            PresentationTimelineCaptionSegment(
              startUs: 0,
              endUs: 2000000,
              text: 'Bonjour',
            ),
            PresentationTimelineCaptionSegment(
              startUs: 1500000,
              endUs: 3000000,
              text: 'Bienvenue',
            ),
          ],
        ),
    };
  }
}

final class _MissingProjectionGateway
    implements PresentationTimelineProjectionGateway {
  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) async => PresentationTimelineMediaProjection.unavailable(
    mediaId: request.mediaId,
    status: PresentationTimelineProjectionStatus.missing,
    diagnostic: 'Média introuvable',
  );
}
