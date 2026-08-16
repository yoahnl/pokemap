import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('applies consecutive Presentation actions without mutating the baseline',
      () {
    final baseline = _manifest();
    final draft = PresentationCinematicDraft.fromSnapshot(
      _snapshot(baseline),
      expectedProject: baseline,
    );

    final first = draft.apply(
      actionId: 'presentationClip.update',
      parameters: <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'text',
        'clip': encodePresentationClip(
          _textClip(content: 'Premier brouillon'),
        ),
      },
      operationId: 'edit-1',
    );
    final second = draft.apply(
      actionId: 'presentationClip.update',
      parameters: <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'text',
        'clip': encodePresentationClip(
          _textClip(content: 'Dernier brouillon'),
        ),
      },
      operationId: 'edit-2',
    );

    expect(_content(baseline), 'Initial');
    expect(_content(first), 'Premier brouillon');
    expect(_content(second), 'Dernier brouillon');
    expect(draft.manifest, second);
  });

  test('rejects a draft opened from a stale visible project', () {
    final baseline = _manifest();
    final stale = baseline.copyWith(name: 'Projet externe');

    expect(
      () => PresentationCinematicDraft.fromSnapshot(
        _snapshot(baseline),
        expectedProject: stale,
      ),
      throwsA(isA<PresentationCinematicDraftException>()),
    );
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Draft test',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 5000000,
          layers: <PresentationLayer>[
            PresentationLayer(id: 'title', label: 'Title', zIndex: 0),
          ],
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'text',
              label: 'Text',
              kind: PresentationTrackKind.visual,
              clips: <PresentationClip>[_textClip(content: 'Initial')],
            ),
          ],
        ),
      ],
    );

PresentationTextClip _textClip({required String content}) =>
    PresentationTextClip(
      id: 'title',
      startUs: 0,
      durationUs: 3000000,
      layerId: 'title',
      text: content,
    );

String _content(ProjectManifest manifest) =>
    (manifest.presentationCinematics.single.tracks.single.clips.single
            as PresentationTextClip)
        .text;

ProjectSnapshot _snapshot(ProjectManifest manifest) {
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('draft-test'),
    revision: 'sha256:${List<String>.filled(64, 'a').join()}',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
    },
    resourceBytes: <String, List<int>>{'project': projectBytes},
    resourceStorageKeys: const <String, String>{'project': 'project.json'},
  );
}
