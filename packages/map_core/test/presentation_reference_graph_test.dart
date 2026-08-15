import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Presentation diagnostics share stable codes and severities', () {
    expect(
      PresentationReferenceDiagnosticCodes.referenceMissing,
      PresentationDiagnosticCodes.referenceMissing,
    );
    expect(
      PresentationReferenceDiagnosticCodes.mediaMissing,
      PresentationDiagnosticCodes.mediaMissing,
    );
    expect(
      PresentationReferenceDiagnosticCodes.mediaUnsupported,
      PresentationDiagnosticCodes.mediaUnsupported,
    );
    expect(
      PresentationReferenceSeverity.error,
      PresentationDiagnosticSeverity.error,
    );
  });

  group('PresentationReferenceGraph', () {
    test('indexes Scene, cinematic, cue, media and fallback usages', () {
      final cinematic = _cinematic(
        visualResourceIds: const ['media.hero'],
        audioResourceId: 'media.music',
        captionResourceId: 'media.captions',
      );
      final mediaCatalog = ProjectMediaCatalog(
        entries: [
          _media(
            'media.hero',
            ProjectMediaKind.image,
            fallbackMediaId: 'media.hero.fallback',
          ),
          _media('media.music', ProjectMediaKind.audio),
          _media('media.captions', ProjectMediaKind.captions),
          _media('media.hero.fallback', ProjectMediaKind.image),
        ],
      );

      final graph = PresentationReferenceGraph.build(
        cinematics: [cinematic],
        scenes: [_scene('cinematic.opening')],
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog),
      );

      expect(graph.preflight.canPublish, isTrue);
      expect(graph.diagnostics, isEmpty);
      expect(
        graph.nodes.map((node) => node.key.kind).toSet(),
        containsAll({
          PresentationReferenceKind.scene,
          PresentationReferenceKind.presentationCinematic,
          PresentationReferenceKind.interactionCue,
          PresentationReferenceKind.media,
        }),
      );
      expect(
        graph.usagesOf(
          const PresentationReferenceKey.media('media.hero.fallback'),
        ),
        hasLength(1),
      );
      expect(
        graph
            .nodeFor(
              const PresentationReferenceKey.interactionCue(
                'cue.choice',
                presentationCinematicId: 'cinematic.opening',
              ),
            )
            ?.defined,
        isTrue,
      );
    });

    test('reports missing and incompatible references with stable actions', () {
      final mediaCatalog = ProjectMediaCatalog(
        entries: [_media('media.wrong', ProjectMediaKind.image)],
      );
      final graph = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(
            visualResourceIds: const ['media.missing'],
            audioResourceId: 'media.wrong',
          ),
        ],
        scenes: [
          _scene('cinematic.opening'),
          _scene('cinematic.missing', id: 'scene.missing'),
        ],
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog),
      );

      expect(graph.preflight.canPublish, isFalse);
      expect(
        graph.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          PresentationReferenceDiagnosticCodes.mediaMissing,
          PresentationReferenceDiagnosticCodes.mediaUnsupported,
          PresentationReferenceDiagnosticCodes.referenceMissing,
        }),
      );
      expect(
        graph.diagnostics,
        everyElement(
          isA<PresentationReferenceDiagnostic>()
              .having((diagnostic) => diagnostic.path, 'path', isNotEmpty)
              .having((diagnostic) => diagnostic.action, 'action', isNotEmpty),
        ),
      );
      expect(
        graph.preflight.diagnostics.map((diagnostic) => diagnostic.toJson()),
        graph.diagnostics.map((diagnostic) => diagnostic.toJson()),
      );
    });

    test('visual media kind must match the catalog media kind', () {
      final cinematic = PresentationCinematicAsset(
        id: 'cinematic.video',
        title: 'Video',
        durationUs: 100000,
        layers: [PresentationLayer(id: 'layer.main', label: 'Main', zIndex: 0)],
        tracks: [
          PresentationTrack(
            id: 'track.visual',
            label: 'Visual',
            kind: PresentationTrackKind.visual,
            clips: [
              PresentationVisualClip(
                id: 'clip.video',
                startUs: 0,
                durationUs: 100000,
                layerId: 'layer.main',
                resourceId: 'media.image',
                mediaKind: PresentationVisualMediaKind.video,
              ),
            ],
          ),
        ],
      );
      final mediaCatalog = ProjectMediaCatalog(
        entries: [_media('media.image', ProjectMediaKind.image)],
      );

      final graph = PresentationReferenceGraph.build(
        cinematics: [cinematic],
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog),
      );

      expect(graph.preflight.canPublish, isFalse);
      expect(
        graph.diagnostics,
        contains(
          isA<PresentationReferenceDiagnostic>()
              .having(
                (diagnostic) => diagnostic.code,
                'code',
                PresentationReferenceDiagnosticCodes.mediaUnsupported,
              )
              .having(
                (diagnostic) => diagnostic.path,
                'path',
                contains('resourceId'),
              ),
        ),
      );
    });

    test('blocks deletion and preserves every shared variant usage', () {
      final mediaCatalog = ProjectMediaCatalog(
        entries: [
          _media('media.shared', ProjectMediaKind.image),
          _media(
            'media.landscape',
            ProjectMediaKind.image,
            fallbackMediaId: 'media.shared',
          ),
          _media(
            'media.portrait',
            ProjectMediaKind.image,
            fallbackMediaId: 'media.shared',
          ),
          _media('media.orphan', ProjectMediaKind.image),
        ],
      );
      final graph = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.shared', 'media.shared']),
        ],
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog),
      );

      final shared = graph.planDeletion(
        const PresentationReferenceKey.media('media.shared'),
      );
      final orphan = graph.planDeletion(
        const PresentationReferenceKey.media('media.orphan'),
      );

      expect(shared.canDelete, isFalse);
      expect(shared.usages, hasLength(4));
      expect(
        shared.usages.map((usage) => usage.path),
        containsAll({
          'projectMedia[media.landscape].fallbackMediaId',
          'projectMedia[media.portrait].fallbackMediaId',
        }),
      );
      expect(
        shared.diagnostic?.code,
        PresentationReferenceDiagnosticCodes.resourceInUse,
      );
      expect(orphan.canDelete, isTrue);
      expect(orphan.usages, isEmpty);
      expect(orphan.diagnostic, isNull);
    });

    test('detects fallback cycles without recursing forever', () {
      final mediaCatalog = ProjectMediaCatalog(
        entries: [
          _media('media.a', ProjectMediaKind.image, fallbackMediaId: 'media.b'),
          _media('media.b', ProjectMediaKind.image, fallbackMediaId: 'media.a'),
        ],
      );
      final graph = PresentationReferenceGraph.build(
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog),
      );

      expect(graph.preflight.canPublish, isFalse);
      expect(
        graph.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code ==
                  PresentationReferenceDiagnosticCodes.referenceCycle,
            )
            .map((diagnostic) => diagnostic.target.id),
        ['media.a', 'media.b'],
      );
    });

    test('roundtrips deterministically independently of declaration order', () {
      final mediaCatalog = ProjectMediaCatalog(
        entries: [
          _media('media.b', ProjectMediaKind.video),
          _media('media.a', ProjectMediaKind.image),
        ],
      );
      final graph = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.b', 'media.a']),
        ],
        scenes: [_scene('cinematic.opening')],
        mediaCatalog: mediaCatalog,
        sourceAssets: _sources(mediaCatalog).reversed,
      );
      final reorderedCatalog = ProjectMediaCatalog(
        entries: [
          _media('media.a', ProjectMediaKind.image),
          _media('media.b', ProjectMediaKind.video),
        ],
      );
      final reordered = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.b', 'media.a']),
        ],
        scenes: [_scene('cinematic.opening')],
        mediaCatalog: reorderedCatalog,
        sourceAssets: _sources(reorderedCatalog),
      );

      final decoded = PresentationReferenceGraph.fromJson(graph.toJson());

      expect(decoded.toJson(), graph.toJson());
      expect(reordered.toJson(), graph.toJson());
    });

    test('rejects blank resource identities before catalog indexing', () {
      expect(
        () => ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: ' ',
              label: 'Invalid',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'asset.invalid',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('indexes the canonical media catalog and physical asset usages', () {
      final mediaCatalog = ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'opening-video',
            label: 'Opening video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening.video',
            posterMediaId: 'opening-poster',
            captionMediaIds: const ['opening-captions-fr'],
            fallbackMediaId: 'opening-poster',
          ),
          ProjectMediaAsset(
            id: 'opening-poster',
            label: 'Opening poster',
            kind: ProjectMediaKind.poster,
            sourceAssetId: 'asset.opening.poster',
          ),
          ProjectMediaAsset(
            id: 'opening-captions-fr',
            label: 'Opening captions',
            kind: ProjectMediaKind.captions,
            sourceAssetId: 'asset.opening.captions.fr',
          ),
        ],
      );

      final graph = PresentationReferenceGraph.build(
        mediaCatalog: mediaCatalog,
        sourceAssets: const [
          ProjectMediaSourceAssetDefinition(
            id: 'asset.opening.video',
            label: 'opening.mp4',
          ),
          ProjectMediaSourceAssetDefinition(
            id: 'asset.opening.poster',
            label: 'opening.webp',
          ),
          ProjectMediaSourceAssetDefinition(
            id: 'asset.opening.captions.fr',
            label: 'opening-fr.vtt',
          ),
        ],
      );

      expect(graph.preflight.canPublish, isTrue);
      expect(
        graph.usagesOf(
          const PresentationReferenceKey.asset('asset.opening.poster'),
        ),
        hasLength(1),
      );
      expect(
        graph.usagesOf(const PresentationReferenceKey.media('opening-poster')),
        hasLength(2),
      );
    });

    test('reports missing sources and incompatible media relations', () {
      final graph = PresentationReferenceGraph.build(
        mediaCatalog: ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'opening-video',
              label: 'Opening video',
              kind: ProjectMediaKind.video,
              sourceAssetId: 'asset.missing',
              posterMediaId: 'opening-audio',
            ),
            ProjectMediaAsset(
              id: 'opening-audio',
              label: 'Opening audio',
              kind: ProjectMediaKind.audio,
              sourceAssetId: 'asset.opening.audio',
            ),
          ],
        ),
        sourceAssets: const [
          ProjectMediaSourceAssetDefinition(
            id: 'asset.opening.audio',
            label: 'opening.ogg',
          ),
        ],
      );

      expect(
        graph.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          PresentationReferenceDiagnosticCodes.mediaSourceMissing,
          PresentationReferenceDiagnosticCodes.mediaUnsupported,
        }),
      );
    });
  });
}

PresentationCinematicAsset _cinematic({
  List<String> visualResourceIds = const [],
  String? audioResourceId,
  String? captionResourceId,
}) {
  final tracks = <PresentationTrack>[
    if (visualResourceIds.isNotEmpty)
      PresentationTrack(
        id: 'track.visual',
        label: 'Visual',
        kind: PresentationTrackKind.visual,
        clips: [
          for (var index = 0; index < visualResourceIds.length; index += 1)
            PresentationVisualClip(
              id: 'clip.visual.$index',
              startUs: index * 100000,
              durationUs: 100000,
              layerId: 'layer.main',
              resourceId: visualResourceIds[index],
            ),
        ],
      ),
    if (audioResourceId != null)
      PresentationTrack(
        id: 'track.audio',
        label: 'Audio',
        kind: PresentationTrackKind.audio,
        clips: [
          PresentationAudioClip(
            id: 'clip.audio',
            startUs: 0,
            durationUs: 100000,
            resourceId: audioResourceId,
          ),
        ],
      ),
    if (captionResourceId != null)
      PresentationTrack(
        id: 'track.caption',
        label: 'Caption',
        kind: PresentationTrackKind.caption,
        clips: [
          PresentationCaptionClip(
            id: 'clip.caption',
            startUs: 0,
            durationUs: 100000,
            captionId: captionResourceId,
          ),
        ],
      ),
    PresentationTrack(
      id: 'track.marker',
      label: 'Marker',
      kind: PresentationTrackKind.marker,
      clips: [
        PresentationMarkerClip(
          id: 'cue.choice',
          startUs: 50000,
          label: 'Choice',
          markerKind: PresentationMarkerKind.interactionCue,
        ),
      ],
    ),
  ];
  return PresentationCinematicAsset(
    id: 'cinematic.opening',
    title: 'Opening',
    durationUs: 1000000,
    layers: [PresentationLayer(id: 'layer.main', label: 'Main', zIndex: 0)],
    tracks: tracks,
  );
}

SceneAsset _scene(String cinematicId, {String id = 'scene.pre_session'}) {
  return SceneAsset(
    id: id,
    name: id,
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

ProjectMediaAsset _media(
  String id,
  ProjectMediaKind kind, {
  String? fallbackMediaId,
}) {
  return ProjectMediaAsset(
    id: id,
    label: id,
    kind: kind,
    sourceAssetId: 'asset.$id',
    fallbackMediaId: fallbackMediaId,
  );
}

List<ProjectMediaSourceAssetDefinition> _sources(ProjectMediaCatalog catalog) {
  return [
    for (final media in catalog.entries)
      ProjectMediaSourceAssetDefinition(
        id: media.sourceAssetId,
        label: media.sourceAssetId,
      ),
  ];
}
