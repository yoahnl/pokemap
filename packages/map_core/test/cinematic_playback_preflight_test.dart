import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('shared preflight accepts all advanced commands and ignores marker', () {
    final report = preflightCinematicPlayback(
      cinematic: _cinematic(),
      dialogues: const [
        ProjectDialogueEntry(
          id: 'dialogue.port',
          name: 'Port',
          relativePath: 'dialogues/port.yarn',
        ),
      ],
      mediaAssets: _media,
    );

    expect(report.isReady, isTrue);
    expect(report.issues, isEmpty);
  });

  test('shared preflight rejects missing and mismatched references', () {
    final report = preflightCinematicPlayback(
      cinematic: _cinematic(),
      dialogues: const [],
      mediaAssets: [
        CinematicMediaAsset(
          id: 'sound.bell',
          label: 'Wrong',
          kind: CinematicMediaAssetKind.music,
          relativePath: 'audio/wrong.ogg',
        ),
      ],
    );

    expect(report.isReady, isFalse);
    expect(
      report.issues.map((issue) => issue.kind),
      containsAll([
        CinematicPlaybackPreflightIssueKind.missingDialogue,
        CinematicPlaybackPreflightIssueKind.mediaTypeMismatch,
        CinematicPlaybackPreflightIssueKind.missingMedia,
      ]),
    );
  });

  test('shared preflight rejects an unavailable or inactive authored map', () {
    final unavailable = preflightCinematicPlayback(
      cinematic: _cinematic(mapId: 'map.port'),
      availableMapIds: const ['map.forest'],
    );
    final inactive = preflightCinematicPlayback(
      cinematic: _cinematic(mapId: 'map.port'),
      availableMapIds: const ['map.port', 'map.forest'],
      activeMapId: 'map.forest',
      mode: CinematicPlaybackPreflightMode.runtime,
    );

    final unavailableMapIssue = unavailable.issues.singleWhere(
      (issue) =>
          issue.kind ==
          CinematicPlaybackPreflightIssueKind.invalidMapReference,
    );
    final inactiveMapIssue = inactive.issues.singleWhere(
      (issue) =>
          issue.kind ==
          CinematicPlaybackPreflightIssueKind.invalidMapReference,
    );

    expect(
      unavailableMapIssue.referenceId,
      'map.port',
    );
    expect(inactiveMapIssue.message, contains('active map'));
  });
}

CinematicAsset _cinematic({String? mapId}) => CinematicAsset(
      id: 'cine.port',
      title: 'Port',
      mapId: mapId,
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'dialogue',
            kind: CinematicTimelineStepKind.dialogueLine,
            assetRef: 'dialogue.port',
            durationMs: 1000,
          ),
          CinematicTimelineStep(
            id: 'sound',
            kind: CinematicTimelineStepKind.sound,
            assetRef: 'sound.bell',
          ),
          CinematicTimelineStep(
            id: 'music',
            kind: CinematicTimelineStepKind.music,
            assetRef: 'music.mist',
          ),
          CinematicTimelineStep(
            id: 'fx',
            kind: CinematicTimelineStepKind.fx,
            assetRef: 'fx.fog',
            durationMs: 500,
          ),
          CinematicTimelineStep(
            id: 'marker',
            kind: CinematicTimelineStepKind.marker,
          ),
        ],
      ),
    );

final _media = [
  CinematicMediaAsset(
    id: 'sound.bell',
    label: 'Bell',
    kind: CinematicMediaAssetKind.sound,
    relativePath: 'audio/bell.ogg',
  ),
  CinematicMediaAsset(
    id: 'music.mist',
    label: 'Mist',
    kind: CinematicMediaAssetKind.music,
    relativePath: 'audio/mist.ogg',
  ),
  CinematicMediaAsset(
    id: 'fx.fog',
    label: 'Fog',
    kind: CinematicMediaAssetKind.cinematicFx,
    relativePath: 'fx/fog.json',
  ),
];
