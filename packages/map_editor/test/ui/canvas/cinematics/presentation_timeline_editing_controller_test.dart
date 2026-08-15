import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_timeline_editing_controller.dart';

void main() {
  test('multi-clip drag stays local then emits one snapped batch', () {
    final controller = PresentationTimelineEditingController(asset: _asset());
    controller.selectClip('visual-a');
    controller.selectClip('visual-b', additive: true);

    controller.beginDrag(
      clipId: 'visual-a',
      kind: PresentationTimelineDragKind.move,
    );
    controller.updateDrag(deltaUs: 160000);

    expect(controller.hasActiveDrag, isTrue);
    expect(controller.previewClip('visual-a').startUs, 1200000);
    expect(controller.previewClip('visual-b').startUs, 3200000);
    expect(controller.asset.tracks.first.clips.first.startUs, 1000000);

    final command = controller.finishDrag();

    expect(command.actionId, 'presentationClip.batch');
    expect(command.parameters['cinematicId'], 'opening');
    expect(command.operations, <Map<String, Object?>>[
      <String, Object?>{
        'kind': 'edit',
        'clipId': 'visual-a',
        'targetTrackId': 'visuals',
        'startUs': 1200000,
        'durationUs': 1000000,
      },
      <String, Object?>{
        'kind': 'edit',
        'clipId': 'visual-b',
        'targetTrackId': 'visuals',
        'startUs': 3200000,
        'durationUs': 1000000,
      },
    ]);
    expect(controller.hasActiveDrag, isFalse);
  });

  test('cancel restores the exact source placements', () {
    final controller = PresentationTimelineEditingController(asset: _asset())
      ..selectClip('visual-a')
      ..beginDrag(
        clipId: 'visual-a',
        kind: PresentationTimelineDragKind.trimStart,
      )
      ..updateDrag(deltaUs: 300000);

    expect(controller.previewClip('visual-a').startUs, 1300000);
    expect(controller.previewClip('visual-a').durationUs, 700000);

    controller.cancelDrag();

    expect(controller.previewClip('visual-a').startUs, 1000000);
    expect(controller.previewClip('visual-a').durationUs, 1000000);
    expect(controller.hasActiveDrag, isFalse);
  });

  test('single clip move can target another compatible track', () {
    final controller = PresentationTimelineEditingController(asset: _asset())
      ..selectClip('visual-a')
      ..beginDrag(clipId: 'visual-a', kind: PresentationTimelineDragKind.move)
      ..updateDrag(deltaUs: 0, targetTrackId: 'visuals-secondary');

    expect(controller.previewTrackId('visual-a'), 'visuals-secondary');
    final command = controller.finishDrag();
    expect(command.operations.single['targetTrackId'], 'visuals-secondary');
  });

  test('copy and paste allocate explicit deterministic identities', () {
    var sequence = 0;
    final controller =
        PresentationTimelineEditingController(
            asset: _asset(),
            duplicateIdFactory: (sourceId) => '$sourceId-copy-${++sequence}',
          )
          ..selectClip('visual-b')
          ..selectClip('audio-a', additive: true)
          ..copySelection();

    final command = controller.paste(atUs: 5000000);

    expect(command.actionId, 'presentationClip.batch');
    expect(command.operations, <Map<String, Object?>>[
      <String, Object?>{
        'kind': 'duplicate',
        'clipId': 'visual-b',
        'duplicateId': 'visual-b-copy-1',
        'targetTrackId': 'visuals',
        'startUs': 5000000,
      },
      <String, Object?>{
        'kind': 'duplicate',
        'clipId': 'audio-a',
        'duplicateId': 'audio-a-copy-2',
        'targetTrackId': 'audio',
        'startUs': 6000000,
      },
    ]);
  });

  test('delete selection is one deterministic batch', () {
    final controller = PresentationTimelineEditingController(asset: _asset())
      ..selectClip('visual-b')
      ..selectClip('visual-a', additive: true);

    final command = controller.deleteSelection();

    expect(command.actionId, 'presentationClip.deleteBatch');
    expect(command.parameters['clipIds'], <String>['visual-a', 'visual-b']);
  });

  test('switching cinematic clears selection and the local clipboard', () {
    final controller = PresentationTimelineEditingController(asset: _asset())
      ..selectClip('visual-a')
      ..copySelection();

    controller.configureAsset(_asset(id: 'second-opening'));

    expect(controller.selectedClipIds, isEmpty);
    expect(controller.hasClipboard, isFalse);
  });

  test('an effectively locked visual layer rejects clip mutations', () {
    final controller = PresentationTimelineEditingController(
      asset: _asset(layerLocked: true),
    )..selectClip('visual-a');

    expect(controller.canEditSelection, isFalse);
    expect(
      () => controller.beginDrag(
        clipId: 'visual-a',
        kind: PresentationTimelineDragKind.move,
      ),
      throwsStateError,
    );
    expect(controller.deleteSelection, throwsStateError);
    expect(controller.duplicateSelection, throwsStateError);
  });
}

PresentationCinematicAsset _asset({
  String id = 'opening',
  bool layerLocked = false,
}) => PresentationCinematicAsset(
  id: id,
  title: 'Opening',
  durationUs: 10000000,
  layers: <PresentationLayer>[
    PresentationLayer(
      id: 'foreground',
      label: 'Foreground',
      zIndex: 0,
      locked: layerLocked,
    ),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuals',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'visual-a',
          startUs: 1000000,
          durationUs: 1000000,
          layerId: 'foreground',
          resourceId: 'visual-a-resource',
        ),
        PresentationVisualClip(
          id: 'visual-b',
          startUs: 3000000,
          durationUs: 1000000,
          layerId: 'foreground',
          resourceId: 'visual-b-resource',
        ),
      ],
    ),
    PresentationTrack(
      id: 'audio',
      label: 'Audio',
      kind: PresentationTrackKind.audio,
      clips: <PresentationClip>[
        PresentationAudioClip(
          id: 'audio-a',
          startUs: 4000000,
          durationUs: 1000000,
          resourceId: 'audio-a-resource',
        ),
      ],
    ),
    PresentationTrack(
      id: 'visuals-secondary',
      label: 'Visuals secondary',
      kind: PresentationTrackKind.visual,
    ),
  ],
);
