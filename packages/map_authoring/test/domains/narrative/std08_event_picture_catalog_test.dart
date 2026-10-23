import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/narrative/event_simulation_query.dart';
import 'package:map_authoring/src/domains/narrative/narrative_document_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventId = 'evt_018f0f8c-7b8a-7def-8000-000000000008';

NarrativeEventRecord _record({bool draft = false}) => draft
    ? NarrativeEventRecord.draft(NarrativeEventDraft(
        id: _eventId,
        name: 'Show picture',
        source: NarrativeEventSourceRef.mapEnter('garden'),
        sceneId: 'presentation',
        conditions: const [],
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0))
    : NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: _eventId,
            name: 'Show picture',
            source: NarrativeEventSourceRef.mapEnter('garden'),
            sceneId: 'presentation',
            conditions: const [],
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0),
        enabled: true);

ProjectSnapshot _snapshot(
    {bool known = true, bool configured = false, bool draft = false}) {
  final map = MapData(
      id: 'garden',
      name: 'Garden',
      size: const GridSize(width: 4, height: 4),
      version: ProjectVersion.v8,
      layers: const []);
  final scene = SceneAsset(
      id: 'presentation',
      name: 'Presentation',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'show',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.worldPresentation(
                    operation: SceneWorldPresentationOperation.showPicture,
                    scope: SceneVisualScope.map,
                    slotId: 1,
                    mediaAssetId: 'banner',
                    referenceWidth: 512,
                    referenceHeight: 384,
                    x: 10,
                    y: 20))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'start_show',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'show',
            kind: SceneEdgeKind.defaultFlow),
        SceneEdge(
            id: 'show_end',
            fromNodeId: 'show',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
      ]));
  final manifest = ProjectManifest(
      name: 'Picture events',
      tilesets: const [],
      maps: const [
        ProjectMapEntry(
            id: 'garden', name: 'Garden', relativePath: 'maps/garden.json')
      ],
      scenes: [scene],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [if (configured || draft) _record(draft: draft)],
          legacyClaims: const []));
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  final media = ProjectMediaCatalog(entries: [
    if (known)
      ProjectMediaAsset(
          id: 'banner',
          label: 'Banner',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'banner_asset'),
  ]);
  final revision = computeAuthoringBytesFingerprint(projectBytes,
      logicalName: 'project.json');
  final mediaBytes = encodeProjectMediaCatalogBytes(media);
  return ProjectSnapshot(
      projectHandle: const ProjectHandle('picture-events'),
      revision: revision,
      manifest: manifest,
      maps: [
        map
      ],
      resourceFingerprints: {
        'project': revision,
        'map:garden': computeAuthoringBytesFingerprint(mapBytes,
            logicalName: 'maps/garden.json'),
        projectMediaCatalogResourceIdentity: computeAuthoringBytesFingerprint(
            mediaBytes,
            logicalName: projectMediaCatalogStorageKey),
      },
      resourceBytes: {
        'project': projectBytes,
        'map:garden': mapBytes,
        projectMediaCatalogResourceIdentity:
            encodeProjectMediaCatalogBytes(media),
      });
}

AuthoringPlanningContext _context(ProjectSnapshot snapshot, String actionId,
        Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
        snapshot: snapshot,
        planId: 'picture-event-plan',
        seed: 1,
        request: AuthoringRequest(
            requestId: 'picture-event-request',
            actionId: actionId,
            actionVersion: 1,
            workspaceHandle: 'picture-event-workspace',
            expectedRevision: snapshot.revision,
            idempotencyKey: 'picture-event-key',
            parameters: parameters));

void main() {
  for (final action in [
    'event_v2.record_upsert',
    'event_v2.record_upsert_batch',
    'event_v2.publish'
  ]) {
    test('STD08 $action resolves the canonical snapshot image catalog', () {
      final snapshot = _snapshot(draft: action == 'event_v2.publish');
      final parameters = switch (action) {
        'event_v2.publish' => <String, Object?>{'eventId': _eventId},
        'event_v2.record_upsert_batch' => <String, Object?>{
            'records': [_record().toJson()]
          },
        _ => <String, Object?>{'record': _record().toJson()},
      };
      final mutation =
          const EventV2Actions().build(_context(snapshot, action, parameters));
      expect(mutation.changeSet.changes, isNotEmpty);
    });
  }

  test('STD08 configured picture events still refuse an unknown image', () {
    final snapshot = _snapshot(known: false);
    expect(
        () => const EventV2Actions().build(_context(snapshot,
            'event_v2.record_upsert', {'record': _record().toJson()})),
        throwsA(isA<NarrativeAuthoringException>()));
  });

  test('STD08 event detail does not invent a missing image diagnostic', () {
    final result = const ProjectQueryService().query(
        _snapshot(configured: true),
        AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const [_eventId]));
    expect((result.items.single['validation'] as Map)['errorCount'], 0);
  });

  test('STD08 simulation resolves the snapshot picture catalog', () {
    final result = queryEventSimulation(
        _snapshot(configured: true),
        AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.get,
            ids: const [_eventId]));
    expect(jsonEncode(result.items), isNot(contains('sceneNotBuildable')));
  });

  test(
      'STD08 modern inspection uses the image catalog for event validation too',
      () {
    final snapshot = _snapshot(configured: true);
    final report = const ModernNarrativeInspector().inspect(
        project: snapshot.manifest,
        maps: snapshot.maps,
        presentationMediaCatalog: decodeProjectMediaCatalogBytes(
            snapshot.resourceBytes(projectMediaCatalogResourceIdentity)));
    expect(report.canPublish, isTrue, reason: '${report.toJson()}');
  });

  test('STD08 document publication preserves known image event references', () {
    final snapshot = _snapshot();
    final mutation = const NarrativeDocumentActions()
        .build(_context(snapshot, 'narrative.publish_document', {
      'map': snapshot.maps.single.toJson(),
      'mapRevision':
          narrativeEventBytesFingerprint(snapshot.resourceBytes('map:garden')),
      'events': [_record().toJson()],
    }));
    expect(mutation.changeSet.changes, isNotEmpty);
  });
}
