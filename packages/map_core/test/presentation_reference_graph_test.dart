import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationReferenceGraph', () {
    test('indexes Scene, cinematic, cue, media and fallback usages', () {
      final cinematic = _cinematic(
        visualResourceIds: const ['media.hero'],
        audioResourceId: 'media.music',
        captionResourceId: 'media.captions',
      );

      final graph = PresentationReferenceGraph.build(
        cinematics: [cinematic],
        scenes: [_scene('cinematic.opening')],
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.hero',
            label: 'Hero',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.music',
            label: 'Music',
            type: PresentationMediaReferenceType.audio,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.captions',
            label: 'Captions',
            type: PresentationMediaReferenceType.captions,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.hero.fallback',
            label: 'Hero fallback',
            type: PresentationMediaReferenceType.image,
          ),
        ],
        fallbacks: const [
          PresentationMediaFallbackReference(
            sourceMediaId: 'media.hero',
            fallbackMediaId: 'media.hero.fallback',
          ),
        ],
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
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.wrong',
            label: 'Wrong media',
            type: PresentationMediaReferenceType.image,
          ),
        ],
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

    test('blocks deletion and preserves every shared variant usage', () {
      final graph = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.shared', 'media.shared']),
        ],
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.shared',
            label: 'Shared',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.landscape',
            label: 'Landscape',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.portrait',
            label: 'Portrait',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.orphan',
            label: 'Orphan',
            type: PresentationMediaReferenceType.image,
          ),
        ],
        fallbacks: const [
          PresentationMediaFallbackReference(
            sourceMediaId: 'media.landscape',
            fallbackMediaId: 'media.shared',
            path: 'variants.landscape.fallbackMediaId',
          ),
          PresentationMediaFallbackReference(
            sourceMediaId: 'media.portrait',
            fallbackMediaId: 'media.shared',
            path: 'variants.portrait.fallbackMediaId',
          ),
        ],
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
          'variants.landscape.fallbackMediaId',
          'variants.portrait.fallbackMediaId',
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
      final graph = PresentationReferenceGraph.build(
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.a',
            label: 'A',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.b',
            label: 'B',
            type: PresentationMediaReferenceType.image,
          ),
        ],
        fallbacks: const [
          PresentationMediaFallbackReference(
            sourceMediaId: 'media.a',
            fallbackMediaId: 'media.b',
          ),
          PresentationMediaFallbackReference(
            sourceMediaId: 'media.b',
            fallbackMediaId: 'media.a',
          ),
        ],
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
      final graph = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.b', 'media.a']),
        ],
        scenes: [_scene('cinematic.opening')],
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.b',
            label: 'B',
            type: PresentationMediaReferenceType.video,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.a',
            label: 'A',
            type: PresentationMediaReferenceType.image,
          ),
        ],
      );
      final reordered = PresentationReferenceGraph.build(
        cinematics: [
          _cinematic(visualResourceIds: const ['media.b', 'media.a']),
        ],
        scenes: [_scene('cinematic.opening')],
        media: const [
          PresentationMediaReferenceDefinition(
            id: 'media.a',
            label: 'A',
            type: PresentationMediaReferenceType.image,
          ),
          PresentationMediaReferenceDefinition(
            id: 'media.b',
            label: 'B',
            type: PresentationMediaReferenceType.video,
          ),
        ],
      );

      final decoded = PresentationReferenceGraph.fromJson(graph.toJson());

      expect(decoded.toJson(), graph.toJson());
      expect(reordered.toJson(), graph.toJson());
    });

    test('rejects blank resource identities before indexing them', () {
      expect(
        () => PresentationReferenceGraph.build(
          media: const [
            PresentationMediaReferenceDefinition(
              id: ' ',
              label: 'Invalid',
              type: PresentationMediaReferenceType.image,
            ),
          ],
        ),
        throwsArgumentError,
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
