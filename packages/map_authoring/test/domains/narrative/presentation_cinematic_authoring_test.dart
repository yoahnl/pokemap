import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Presentation cinematic semantic authoring', () {
    test('publishes every nested Presentation resource kind', () {
      final registry = AuthoringResourceKindRegistry.canonical();

      expect(
        registry.queryableResourceKindIds,
        containsAll(<String>{
          'presentationCinematic',
          'presentationTrack',
          'presentationClip',
          'presentationLayer',
          'presentationMedia',
        }),
      );
    });

    test('queries cinematics, tracks, clips and layers with stable ids', () {
      const service = ProjectQueryService();
      final snapshot = _snapshot();

      final cinematics = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationCinematic',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
        ),
      );
      final tracks = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationTrack',
          operation: AuthoringQueryOperation.list,
          filters: const <String, Object?>{'cinematicId': 'opening'},
          view: AuthoringQueryView.detail,
        ),
      );
      final clip = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationClip',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['opening:visuals:hero'],
          view: AuthoringQueryView.detail,
        ),
      );
      final layer = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationLayer',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['opening:foreground'],
          view: AuthoringQueryView.detail,
          fieldMask: const <String>['cinematicId', 'zIndex'],
        ),
      );

      expect(cinematics.totalAvailable, 2);
      expect(cinematics.items.single['id'], 'credits');
      expect(cinematics.nextCursor, isNotNull);
      expect(tracks.items.single, containsPair('id', 'opening:visuals'));
      expect(tracks.items.single, containsPair('clipCount', 1));
      expect(clip.items.single, containsPair('resourceId', 'hero-landscape'));
      expect(clip.items.single, containsPair('startUs', 250000));
      expect(
        layer.items.single,
        <String, Object?>{
          'id': 'opening:foreground',
          'name': 'Foreground',
          'resourceKind': 'presentationLayer',
          'cinematicId': 'opening',
          'zIndex': 2,
        },
      );
    });

    test('escapes scoped resource id segments without collisions', () {
      const service = ProjectQueryService();
      final manifest = ProjectManifest(
        name: 'Presentation scoped ids',
        version: ProjectVersion.v7,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        presentationCinematics: <PresentationCinematicAsset>[
          PresentationCinematicAsset(
            id: 'opening:act',
            title: 'Opening act',
            durationUs: 1000000,
            tracks: <PresentationTrack>[
              PresentationTrack(
                id: 'markers',
                label: 'Markers',
                kind: PresentationTrackKind.marker,
              ),
            ],
          ),
          PresentationCinematicAsset(
            id: 'opening',
            title: 'Opening',
            durationUs: 1000000,
            tracks: <PresentationTrack>[
              PresentationTrack(
                id: 'act:markers',
                label: 'Act markers',
                kind: PresentationTrackKind.marker,
              ),
            ],
          ),
        ],
      );

      final tracks = service.query(
        _snapshot(manifest: manifest),
        AuthoringQueryRequest(
          resourceKind: 'presentationTrack',
          operation: AuthoringQueryOperation.list,
        ),
      );

      expect(
        tracks.items.map((item) => item['id']).toSet(),
        <String>{'opening%3Aact:markers', 'opening:act%3Amarkers'},
      );
    });

    test('registers the semantic action surface with transaction guarantees',
        () {
      final descriptors = <String, AuthoringActionDescriptor>{
        for (final descriptor
            in AuthoringMutationDispatcher.canonical().descriptors)
          descriptor.id: descriptor,
      };
      const expected = <String>{
        'presentationCinematic.create',
        'presentationCinematic.update',
        'presentationCinematic.duplicate',
        'presentationCinematic.delete',
        'presentationTrack.create',
        'presentationTrack.update',
        'presentationTrack.move',
        'presentationTrack.duplicate',
        'presentationTrack.delete',
        'presentationClip.create',
        'presentationClip.update',
        'presentationClip.move',
        'presentationClip.resize',
        'presentationClip.duplicate',
        'presentationClip.delete',
        'presentationLayer.create',
        'presentationLayer.update',
        'presentationLayer.move',
        'presentationLayer.duplicate',
        'presentationLayer.delete',
      };

      expect(descriptors.keys, containsAll(expected));
      for (final actionId in expected) {
        expect(
          descriptors[actionId]!.guarantees,
          containsAll(<AuthoringGuarantee>{
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.atomic,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
          }),
          reason: actionId,
        );
      }
    });

    test('creates, updates, duplicates and deletes cinematic resources', () {
      final snapshot = _snapshot();

      final created = _apply(
        snapshot,
        'presentationCinematic.create',
        const <String, Object?>{
          'cinematicId': 'intro',
          'title': 'Intro',
          'description': 'Before title',
          'durationUs': 1500000,
        },
      );
      final updated = _apply(
        snapshot,
        'presentationCinematic.update',
        const <String, Object?>{
          'cinematicId': 'opening',
          'title': 'Opening revised',
          'description': null,
          'durationUs': 5000000,
        },
      );
      final duplicated = _apply(
        snapshot,
        'presentationCinematic.duplicate',
        const <String, Object?>{
          'cinematicId': 'opening',
          'duplicateId': 'opening-copy',
          'title': 'Opening copy',
        },
      );
      final deleted = _apply(
        snapshot,
        'presentationCinematic.delete',
        const <String, Object?>{'cinematicId': 'credits'},
      );

      expect(created.presentationCinematics.last.id, 'intro');
      expect(created.presentationCinematics.last.description, 'Before title');
      expect(updated.presentationCinematics.first.title, 'Opening revised');
      expect(updated.presentationCinematics.first.durationUs, 5000000);
      final copy = duplicated.presentationCinematics.last;
      expect(copy.id, 'opening-copy');
      expect(copy.title, 'Opening copy');
      expect(copy.tracks.single.clips.single.id, 'opening-copy-hero');
      expect(
        deleted.presentationCinematics.map((item) => item.id),
        isNot(contains('credits')),
      );
    });

    test('creates, updates, moves, duplicates and deletes tracks', () {
      final snapshot = _snapshot(withSecondTrack: true);
      final encoded = encodePresentationCinematicAsset(
        snapshot.manifest.presentationCinematics.first,
      );
      final visualTrack = Map<String, Object?>.from(
        (encoded['tracks']! as List<Object?>).first! as Map,
      )..['label'] = 'Visuals revised';

      final created = _apply(
        snapshot,
        'presentationTrack.create',
        const <String, Object?>{
          'cinematicId': 'credits',
          'track': <String, Object?>{
            'id': 'captions',
            'label': 'Captions',
            'kind': 'caption',
            'clips': <Object?>[],
          },
        },
      );
      final updated = _apply(
        snapshot,
        'presentationTrack.update',
        <String, Object?>{
          'cinematicId': 'opening',
          'track': visualTrack,
        },
      );
      final moved = _apply(
        snapshot,
        'presentationTrack.move',
        const <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'visuals',
          'insertionIndex': 1,
        },
      );
      final duplicated = _apply(
        snapshot,
        'presentationTrack.duplicate',
        const <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'visuals',
          'duplicateId': 'visuals-copy',
          'label': 'Visuals copy',
        },
      );
      final deleted = _apply(
        snapshot,
        'presentationTrack.delete',
        const <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'audio',
        },
      );

      expect(created.presentationCinematics.last.tracks.single.id, 'captions');
      expect(updated.presentationCinematics.first.tracks.first.label,
          'Visuals revised');
      expect(
        moved.presentationCinematics.first.tracks.map((track) => track.id),
        <String>['audio', 'visuals'],
      );
      final trackCopy = duplicated.presentationCinematics.first.tracks.last;
      expect(trackCopy.id, 'visuals-copy');
      expect(trackCopy.clips.single.id, 'visuals-copy-hero');
      expect(
        deleted.presentationCinematics.first.tracks.map((track) => track.id),
        <String>['visuals'],
      );
    });

    test('creates, updates, moves, resizes, duplicates and deletes clips', () {
      final snapshot = _snapshot();
      const revisedClip = <String, Object?>{
        'id': 'hero',
        'kind': 'visual',
        'startUs': 500000,
        'durationUs': 1000000,
        'layerId': 'foreground',
        'resourceId': 'hero-portrait',
        'easing': 'linear',
        'from': <String, Object?>{},
        'to': <String, Object?>{},
        'transitionIn': <String, Object?>{'kind': 'none', 'durationUs': 0},
        'transitionOut': <String, Object?>{'kind': 'none', 'durationUs': 0},
      };

      final created = _apply(
        snapshot,
        'presentationClip.create',
        const <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'visuals',
          'clip': <String, Object?>{
            'id': 'logo',
            'kind': 'visual',
            'startUs': 2500000,
            'durationUs': 500000,
            'layerId': 'background',
            'resourceId': 'hero-landscape',
            'easing': 'linear',
            'from': <String, Object?>{},
            'to': <String, Object?>{},
            'transitionIn': <String, Object?>{
              'kind': 'none',
              'durationUs': 0,
            },
            'transitionOut': <String, Object?>{
              'kind': 'none',
              'durationUs': 0,
            },
          },
        },
      );
      final updated = _apply(
        snapshot,
        'presentationClip.update',
        const <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'visuals',
          'clip': revisedClip,
        },
      );
      final moved = _apply(
        snapshot,
        'presentationClip.move',
        const <String, Object?>{
          'cinematicId': 'opening',
          'clipId': 'hero',
          'targetTrackId': 'visuals',
          'startUs': 750000,
        },
      );
      final resized = _apply(
        snapshot,
        'presentationClip.resize',
        const <String, Object?>{
          'cinematicId': 'opening',
          'clipId': 'hero',
          'durationUs': 1000000,
        },
      );
      final duplicated = _apply(
        snapshot,
        'presentationClip.duplicate',
        const <String, Object?>{
          'cinematicId': 'opening',
          'clipId': 'hero',
          'duplicateId': 'hero-copy',
          'targetTrackId': 'visuals',
          'startUs': 2000000,
        },
      );
      final deleted = _apply(
        snapshot,
        'presentationClip.delete',
        const <String, Object?>{
          'cinematicId': 'opening',
          'clipId': 'hero',
        },
      );

      expect(created.presentationCinematics.first.tracks.first.clips,
          hasLength(2));
      expect(
        (updated.presentationCinematics.first.tracks.first.clips.single
                as PresentationVisualClip)
            .resourceId,
        'hero-portrait',
      );
      expect(
          moved.presentationCinematics.first.tracks.first.clips.single.startUs,
          750000);
      expect(
          resized.presentationCinematics.first.tracks.first.clips.single
              .durationUs,
          1000000);
      expect(duplicated.presentationCinematics.first.tracks.first.clips.last.id,
          'hero-copy');
      expect(deleted.presentationCinematics.first.tracks.first.clips, isEmpty);
    });

    test('creates, updates, moves, duplicates and deletes visual layers', () {
      final snapshot = _snapshot();

      final created = _apply(
        snapshot,
        'presentationLayer.create',
        const <String, Object?>{
          'cinematicId': 'credits',
          'layer': <String, Object?>{
            'id': 'titles',
            'label': 'Titles',
            'zIndex': 1,
          },
        },
      );
      final updated = _apply(
        snapshot,
        'presentationLayer.update',
        const <String, Object?>{
          'cinematicId': 'opening',
          'layer': <String, Object?>{
            'id': 'foreground',
            'label': 'Hero',
            'zIndex': 3,
          },
        },
      );
      final moved = _apply(
        snapshot,
        'presentationLayer.move',
        const <String, Object?>{
          'cinematicId': 'opening',
          'layerId': 'foreground',
          'zIndex': 8,
        },
      );
      final duplicated = _apply(
        snapshot,
        'presentationLayer.duplicate',
        const <String, Object?>{
          'cinematicId': 'opening',
          'layerId': 'foreground',
          'duplicateId': 'hero-copy',
          'label': 'Hero copy',
          'zIndex': 9,
        },
      );
      final deleted = _apply(
        snapshot,
        'presentationLayer.delete',
        const <String, Object?>{
          'cinematicId': 'opening',
          'layerId': 'background',
        },
      );

      expect(created.presentationCinematics.last.layers.single.id, 'titles');
      expect(updated.presentationCinematics.first.layers.first.label, 'Hero');
      expect(moved.presentationCinematics.first.layers.first.zIndex, 8);
      expect(
          duplicated.presentationCinematics.first.layers.last.id, 'hero-copy');
      expect(
        deleted.presentationCinematics.first.layers.map((layer) => layer.id),
        <String>['foreground'],
      );
    });

    test('fails closed on v6, used layers and Scene-owned cinematics', () {
      final v6 = _snapshot(
        manifest: ProjectManifest(
          name: 'V6',
          version: ProjectVersion.v6,
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
        ),
      );
      final referenced = _snapshot(
        manifest: _snapshot().manifest.copyWith(
          scenes: <SceneAsset>[_scene('opening')],
        ),
      );

      expect(
        () => _apply(
          v6,
          'presentationCinematic.create',
          const <String, Object?>{
            'cinematicId': 'intro',
            'title': 'Intro',
            'description': null,
            'durationUs': 1000000,
          },
        ),
        throwsA(
          isA<PresentationCinematicAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation_cinematic.project_v7_required',
          ),
        ),
      );
      expect(
        () => _apply(
          _snapshot(),
          'presentationLayer.delete',
          const <String, Object?>{
            'cinematicId': 'opening',
            'layerId': 'foreground',
          },
        ),
        throwsA(
          isA<PresentationCinematicAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation_layer.in_use',
          ),
        ),
      );
      expect(
        () => _apply(
          referenced,
          'presentationCinematic.delete',
          const <String, Object?>{'cinematicId': 'opening'},
        ),
        throwsA(
          isA<PresentationCinematicAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation_cinematic.in_use',
          ),
        ),
      );
    });
  });
}

ProjectSnapshot _snapshot({
  ProjectManifest? manifest,
  bool withSecondTrack = false,
}) {
  final opening = PresentationCinematicAsset(
    id: 'opening',
    title: 'Opening',
    durationUs: 4000000,
    layers: <PresentationLayer>[
      PresentationLayer(id: 'foreground', label: 'Foreground', zIndex: 2),
      PresentationLayer(id: 'background', label: 'Background', zIndex: 0),
    ],
    tracks: <PresentationTrack>[
      PresentationTrack(
        id: 'visuals',
        label: 'Visuals',
        kind: PresentationTrackKind.visual,
        clips: <PresentationClip>[
          PresentationVisualClip(
            id: 'hero',
            startUs: 250000,
            durationUs: 2000000,
            layerId: 'foreground',
            resourceId: 'hero-landscape',
          ),
        ],
      ),
      if (withSecondTrack)
        PresentationTrack(
          id: 'audio',
          label: 'Audio',
          kind: PresentationTrackKind.audio,
          clips: <PresentationClip>[
            PresentationAudioClip(
              id: 'music',
              startUs: 0,
              durationUs: 4000000,
              resourceId: 'opening-music',
            ),
          ],
        ),
    ],
  );
  final effectiveManifest = manifest ??
      ProjectManifest(
        name: 'Presentation authoring',
        version: ProjectVersion.v7,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        presentationCinematics: <PresentationCinematicAsset>[
          opening,
          PresentationCinematicAsset(
            id: 'credits',
            title: 'Credits',
            durationUs: 1000000,
          ),
        ],
      );
  final projectBytes = utf8.encode(jsonEncode(effectiveManifest.toJson()));
  final mediaCatalog = ProjectMediaCatalog(
    entries: <ProjectMediaAsset>[
      ProjectMediaAsset(
        id: 'hero-landscape',
        label: 'Hero landscape',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'asset-hero-landscape',
      ),
      ProjectMediaAsset(
        id: 'hero-portrait',
        label: 'Hero portrait',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'asset-hero-portrait',
      ),
      ProjectMediaAsset(
        id: 'opening-music',
        label: 'Opening music',
        kind: ProjectMediaKind.audio,
        sourceAssetId: 'asset-opening-music',
      ),
    ],
  );
  final mediaBytes = encodeProjectMediaCatalogBytes(mediaCatalog);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_presentation_cinematic'),
    revision: 'sha256:${List<String>.filled(64, 'a').join()}',
    manifest: effectiveManifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
      projectMediaCatalogResourceIdentity: computeAuthoringBytesFingerprint(
        mediaBytes,
        logicalName: projectMediaCatalogStorageKey,
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': projectBytes,
      projectMediaCatalogResourceIdentity: mediaBytes,
    },
  );
}

ProjectManifest _apply(
  ProjectSnapshot snapshot,
  String actionId,
  Map<String, Object?> parameters,
) {
  final draft = const PresentationCinematicActions().build(
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request-$actionId',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace-presentation',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idempotency-$actionId',
      ),
      planId: 'plan-presentation',
      seed: 1,
    ),
  );
  final bytes = draft.changeSet.changes.single.afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}

SceneAsset _scene(String cinematicId) => SceneAsset(
      id: 'scene-pre-session',
      name: 'Pre-session',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
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
        edges: <SceneEdge>[
          SceneEdge(
            id: 'edge-start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'presentation',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'edge-end',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.presentationCompleted,
          ),
        ],
      ),
    );
