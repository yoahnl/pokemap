import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('projects the canonical Presentation graph into authoring references',
      () {
    final cinematic = _cinematic('media.shared');
    final scene = _scene('cinematic.opening');
    final mediaCatalog = ProjectMediaCatalog(
      entries: [
        ProjectMediaAsset(
          id: 'media.shared',
          label: 'Shared',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'asset.shared',
        ),
      ],
    );
    final assetCatalog = _physicalAssets(mediaCatalog);
    final coreGraph = PresentationReferenceGraph.build(
      cinematics: [cinematic],
      scenes: [scene],
      mediaCatalog: mediaCatalog,
      sourceAssets: _sourceDefinitions(assetCatalog),
    );

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(
        scene: scene,
        mediaCatalog: mediaCatalog,
        assetCatalog: assetCatalog,
      ),
      presentationCinematics: [cinematic],
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
    final mediaCatalog = ProjectMediaCatalog(
      entries: [
        ProjectMediaAsset(
          id: 'media.wrong',
          label: 'Wrong',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'asset.wrong',
        ),
      ],
    );
    final assetCatalog = _physicalAssets(mediaCatalog);
    final graph = PresentationReferenceGraph.build(
      cinematics: [cinematic],
      mediaCatalog: mediaCatalog,
      sourceAssets: _sourceDefinitions(assetCatalog),
    );

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(
        mediaCatalog: mediaCatalog,
        assetCatalog: assetCatalog,
      ),
      presentationCinematics: [cinematic],
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

  test('loads media and physical source definitions from the snapshot', () {
    final mediaCatalog = ProjectMediaCatalog(
      entries: [
        ProjectMediaAsset(
          id: 'media.shared',
          label: 'Shared',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'asset.shared',
        ),
      ],
    );
    final assetCatalog = AssetCatalog(
      records: [
        AssetRecord(
          id: 'asset.shared',
          logicalPath:
              'assets/presentation/cinematics/media.shared/shared.webp',
          artifact: ContentArtifactRef.fromBytes(
            const [1, 2, 3],
            mediaType: 'image/webp',
          ),
        ),
      ],
    );

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(
        mediaCatalog: mediaCatalog,
        assetCatalog: assetCatalog,
      ),
    );

    final mediaKey = ProjectReferenceKey(kind: 'media', id: 'media.shared');
    final sourceKey = ProjectReferenceKey(kind: 'asset', id: 'asset.shared');
    expect(index.nodeFor(mediaKey)?.metadata, {'mediaType': 'image'});
    expect(index.nodeFor(sourceKey)?.defined, isTrue);
    expect(
      ProjectReferenceQueries(index)
          .dependencies(mediaKey)
          .map((edge) => edge.target),
      [sourceKey],
    );
    expect(
      ProjectReferenceImpactAnalyzer(index)
          .deletionImpact(sourceKey)
          .runtimeBlocking,
      isTrue,
    );
  });

  test('loads Presentation cinematic ownership from the V7 manifest', () {
    final cinematic = _cinematic('media.shared');
    final mediaCatalog = ProjectMediaCatalog(
      entries: [
        ProjectMediaAsset(
          id: 'media.shared',
          label: 'Shared',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'asset.shared',
        ),
      ],
    );
    final assetCatalog = _physicalAssets(mediaCatalog);

    final index = ProjectReferenceIndex.fromSnapshot(
      _snapshot(
        cinematic: cinematic,
        mediaCatalog: mediaCatalog,
        assetCatalog: assetCatalog,
      ),
    );

    expect(
      index
          .nodeFor(
            ProjectReferenceKey(
              kind: 'presentationCinematic',
              id: cinematic.id,
            ),
          )
          ?.defined,
      isTrue,
    );
    expect(
      ProjectReferenceQueries(index)
          .dependents(ProjectReferenceKey(kind: 'media', id: 'media.shared'))
          .map((edge) => edge.owner.id),
      [cinematic.id],
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

ProjectSnapshot _snapshot({
  SceneAsset? scene,
  PresentationCinematicAsset? cinematic,
  ProjectMediaCatalog? mediaCatalog,
  AssetCatalog? assetCatalog,
}) {
  final manifest = ProjectManifest(
    name: 'Presentation reference fixture',
    version: ProjectVersion.v7,
    maps: const [],
    tilesets: const [],
    scenes: scene == null ? const [] : [scene],
    presentationCinematics: cinematic == null ? const [] : [cinematic],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mediaBytes = mediaCatalog == null
      ? null
      : utf8.encode(jsonEncode(mediaCatalog.toJson()));
  final assetBytes = assetCatalog == null
      ? null
      : utf8.encode(jsonEncode(assetCatalog.toJson()));
  final entries = <NarrativeProjectFingerprintEntry>[
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: bytes,
    ),
    if (mediaBytes != null)
      NarrativeProjectFingerprintEntry(
        relativePath: projectMediaCatalogStorageKey,
        bytes: mediaBytes,
      ),
    if (assetBytes != null)
      NarrativeProjectFingerprintEntry(
        relativePath: assetCatalogStorageKey,
        bytes: assetBytes,
      ),
  ];
  final revision = computeNarrativeProjectFingerprint(entries);
  final resourceFingerprints = <String, String>{
    'project': computeNarrativeProjectFingerprint([entries.first]),
    if (mediaBytes != null)
      projectMediaCatalogResourceIdentity:
          computeNarrativeProjectFingerprint([entries[1]]),
    if (assetBytes != null)
      assetCatalogResourceIdentity: computeNarrativeProjectFingerprint([
        entries.last,
      ]),
  };
  final resourceBytes = <String, List<int>>{
    'project': bytes,
    if (mediaBytes != null) projectMediaCatalogResourceIdentity: mediaBytes,
    if (assetBytes != null) assetCatalogResourceIdentity: assetBytes,
  };
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_presentation_reference'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: resourceFingerprints,
    resourceBytes: resourceBytes,
  );
}

AssetCatalog _physicalAssets(ProjectMediaCatalog mediaCatalog) {
  return AssetCatalog(
    records: [
      for (final media in mediaCatalog.entries)
        AssetRecord(
          id: media.sourceAssetId,
          logicalPath:
              'assets/presentation/cinematics/${media.id}/${media.id}.bin',
          artifact: ContentArtifactRef.fromBytes(
            utf8.encode(media.id),
            mediaType: 'application/octet-stream',
          ),
        ),
    ],
  );
}

List<ProjectMediaSourceAssetDefinition> _sourceDefinitions(
  AssetCatalog catalog,
) {
  return [
    for (final asset in catalog.records)
      ProjectMediaSourceAssetDefinition(
        id: asset.id,
        label: asset.logicalPath,
      ),
  ];
}
