import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('projects the canonical Presentation graph into authoring references',
      () {
    final cinematic = _cinematic('media.shared');
    final scene = _scene('cinematic.opening');
    const media = [
      PresentationMediaReferenceDefinition(
        id: 'media.shared',
        label: 'Shared',
        type: PresentationMediaReferenceType.image,
      ),
    ];
    final coreGraph = PresentationReferenceGraph.build(
      cinematics: [cinematic],
      scenes: [scene],
      media: media,
    );

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(scene),
      presentationCinematics: [cinematic],
      presentationMedia: media,
    );

    final mediaKey = ProjectReferenceKey(kind: 'media', id: 'media.shared');
    expect(index.nodeFor(mediaKey)?.defined, isTrue);
    expect(index.nodeFor(mediaKey)?.metadata, {'mediaType': 'image'});
    expect(
      ProjectReferenceQueries(index)
          .dependents(mediaKey)
          .map((edge) => edge.owner.id),
      ['cinematic.opening'],
    );
    expect(
      ProjectReferenceImpactAnalyzer(index)
          .deletionImpact(mediaKey)
          .runtimeBlocking,
      isTrue,
    );
    expect(
      index.diagnostics.map((diagnostic) => diagnostic.code),
      coreGraph.diagnostics.map((diagnostic) => diagnostic.code),
    );
  });

  test('keeps canonical missing and wrong-type diagnostics in authoring', () {
    final cinematic = _cinematic('media.missing', audioId: 'media.wrong');
    const media = [
      PresentationMediaReferenceDefinition(
        id: 'media.wrong',
        label: 'Wrong',
        type: PresentationMediaReferenceType.image,
      ),
    ];
    final graph = PresentationReferenceGraph.build(
      cinematics: [cinematic],
      media: media,
    );

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(),
      presentationCinematics: [cinematic],
      presentationMedia: media,
    );

    expect(
      index.diagnostics.map((diagnostic) => diagnostic.toJson()),
      graph.diagnostics.map(
        (diagnostic) => {
          'code': diagnostic.code,
          'severity': 'error',
          'message': diagnostic.message,
          'action': diagnostic.action,
          'target': {
            'kind': diagnostic.target.kind.name,
            'id': diagnostic.target.id,
          },
          'owner': {
            'kind': diagnostic.owner!.kind.name,
            'id': diagnostic.owner!.id,
          },
          'fieldPath': diagnostic.path,
          'navigation': {
            'kind': diagnostic.owner!.kind.name,
            'assetId': diagnostic.owner!.id,
            'context': diagnostic.path,
          },
        },
      ),
    );
  });
}

PresentationCinematicAsset _cinematic(String visualId, {String? audioId}) {
  return PresentationCinematicAsset(
    id: 'cinematic.opening',
    title: 'Opening',
    durationUs: 1000000,
    layers: [PresentationLayer(id: 'layer.main', label: 'Main', zIndex: 0)],
    tracks: [
      PresentationTrack(
        id: 'track.visual',
        label: 'Visual',
        kind: PresentationTrackKind.visual,
        clips: [
          PresentationVisualClip(
            id: 'clip.visual',
            startUs: 0,
            durationUs: 100000,
            layerId: 'layer.main',
            resourceId: visualId,
          ),
        ],
      ),
      if (audioId != null)
        PresentationTrack(
          id: 'track.audio',
          label: 'Audio',
          kind: PresentationTrackKind.audio,
          clips: [
            PresentationAudioClip(
              id: 'clip.audio',
              startUs: 0,
              durationUs: 100000,
              resourceId: audioId,
            ),
          ],
        ),
    ],
  );
}

SceneAsset _scene(String cinematicId) {
  return SceneAsset(
    id: 'scene.pre_session',
    name: 'Pre-session',
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'presentation',
          kind: SceneNodeKind.presentationCinematic,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: cinematicId,
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge.start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'presentation',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge.end',
          fromNodeId: 'presentation',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.presentationCompleted,
        ),
      ],
    ),
  );
}

ProjectSnapshot _snapshot([SceneAsset? scene]) {
  final manifest = ProjectManifest(
    name: 'Presentation reference fixture',
    maps: const [],
    tilesets: const [],
    scenes: scene == null ? const [] : [scene],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision =
      computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
    NarrativeProjectFingerprintEntry(
        relativePath: 'project.json', bytes: bytes),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_presentation_reference'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: {'project': revision},
    resourceBytes: {'project': bytes},
  );
}
