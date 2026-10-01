import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  test('analysis exposes refusal without a writable partial draft', () {
    final map = catalogMap('target');
    final owner = catalogMap('owner').copyWith(warps: const [
      MapWarp(
          id: 'entry',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'target',
          targetPos: GridPos(x: 5, y: 0))
    ]);
    final result = const MapLifecycleActions().analyze(catalogContext(
        catalogSnapshot([map, owner]),
        'map.resize_apply',
        {'mapId': 'target', 'width': 4, 'height': 5}));
    expect(result.canApply, isFalse);
    expect(result.errorCode, 'map.resize_impacts');
    expect(result.details['impactCount'], 1);
    expect(() => result.details['impactCount'] = 0, throwsUnsupportedError);
  });

  test('analysis no-op leaves source revision and content unchanged', () {
    final map = catalogMap('target');
    final snapshot = catalogSnapshot([map]);
    final original = List<int>.of(snapshot.resourceBytes('map:target'));
    final result = const MapLifecycleActions().analyze(catalogContext(snapshot,
        'map.resize_apply', {'mapId': 'target', 'width': 6, 'height': 5}));
    expect(result.noChange, isTrue);
    expect(snapshot.resourceBytes('map:target'), original);
  });

  test(
      'duplicate preserves external and self destinations and local identities',
      () {
    final source = catalogMap('source').copyWith(warps: const [
      MapWarp(
          id: 'local',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'source',
          targetPos: GridPos(x: 2, y: 2)),
      MapWarp(
          id: 'external',
          pos: GridPos(x: 1, y: 2),
          targetMapId: 'other',
          targetPos: GridPos(x: 0, y: 0))
    ]);
    final snapshot = catalogSnapshot([source, catalogMap('other')]);
    final before = List<int>.of(snapshot.resourceBytes('map:source'));
    final draft = const MapLifecycleActions().build(
        catalogContext(snapshot, 'map.duplicate', {'sourceMapId': 'source'}));
    final copy = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.first.afterBytes!))
            as Map<String, dynamic>);
    expect(copy.warps, source.warps);
    expect(copy.warps.first.targetMapId, 'source');
    expect(draft.preview['selfReferences'], 'sourceMap');
    expect(snapshot.resourceBytes('map:source'), before);
  });

  test('duplicate refuses global event identities rather than dropping them',
      () {
    final source = catalogMap('source').copyWith(events: const [
      MapEventDefinition(
          id: 'global_event',
          pages: [],
          position: EventPosition(layerId: 'base', x: 0, y: 0))
    ]);
    final result = const MapLifecycleActions().analyze(catalogContext(
        catalogSnapshot([source]), 'map.duplicate', {'sourceMapId': 'source'}));
    expect(result.canApply, isFalse);
    expect(result.errorCode, 'map.duplicate_global_event_identity');
    expect(result.details['eventIds'], ['global_event']);
  });

  test('blocking load diagnostic never becomes zero-reference deletion', () {
    final map = catalogMap('target');
    final snapshot = catalogSnapshot([
      map
    ], diagnostics: [
      ProjectSnapshotLoadDiagnostic(
          code: 'project.dialogue_source_missing',
          resourceKind: 'dialogueSource',
          resourceId: 'dialogue')
    ]);
    final result = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.delete_apply', {'mapId': 'target'}));
    expect(result.canApply, isFalse);
    expect(result.errorCode, 'map.inventory_incomplete');
  });

  test('project start remains a blocking owner even when disabled', () {
    final map = catalogMap('target');
    final initial = catalogSnapshot([map]);
    final snapshot = catalogSnapshot([map],
        project: initial.manifest.copyWith(
            newGame: const ProjectNewGameConfig(startMapId: 'target')));
    final result = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.delete_apply', {'mapId': 'target'}));
    expect(result.canApply, isFalse);
    expect(result.errorCode, 'map.references_blocking');
    expect(result.details['edges'].toString(), contains('newGame.startMapId'));
  });

  test('script warp blocks deletion and protects its authored destination', () {
    final map = catalogMap('target');
    final initial = catalogSnapshot([map]);
    final project = initial.manifest.copyWith(scripts: const [
      ProjectScriptEntry(
          id: 'script',
          name: 'Script',
          asset: ScriptAsset(id: 'script', nodes: [
            ScriptNode(id: 'start', commands: [
              ScriptCommand(
                  type: ScriptCommandType.warpPlayer,
                  params: {'mapId': 'target', 'x': '5', 'y': '0'})
            ])
          ]))
    ]);
    final snapshot = catalogSnapshot([map], project: project);
    final deletion = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.delete_apply', {'mapId': 'target'}));
    final resize = const MapLifecycleActions().analyze(catalogContext(snapshot,
        'map.resize_apply', {'mapId': 'target', 'width': 4, 'height': 5}));
    expect(deletion.errorCode, 'map.references_blocking');
    expect(resize.errorCode, 'map.resize_impacts');
    expect(resize.details['impacts'].toString(), contains('scriptWarp'));
  });

  test('map-bound cinematic coordinates protect a cropped point in cell units',
      () {
    final map = catalogMap('target');
    final initial = catalogSnapshot([map]);
    final project = initial.manifest.copyWith(cinematics: [
      CinematicAsset(
          id: 'cinematic',
          title: 'Cinematic',
          mapId: 'target',
          timeline: CinematicTimeline(steps: const []),
          stageContext: CinematicStageContext(stagePoints: [
            CinematicStagePoint(id: 'point', label: 'Point', x: 4.5, y: 1)
          ]))
    ]);
    final snapshot = catalogSnapshot([map], project: project);
    final result = const MapLifecycleActions().analyze(catalogContext(snapshot,
        'map.resize_apply', {'mapId': 'target', 'width': 4, 'height': 5}));
    expect(result.errorCode, 'map.resize_impacts');
    expect(result.details['impacts'].toString(), contains('cinematicPoint'));
  });

  test('scene NPC presence retains a real incoming map dependency', () {
    final map = catalogMap('target');
    final initial = catalogSnapshot([map]);
    final project = initial.manifest.copyWith(scenes: [
      SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'action',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload(
                    consequence: SceneSetNpcPresenceConsequence(
                        mapId: 'target', entityId: 'npc', present: true)))
          ], edges: const []))
    ]);
    final result = const MapLifecycleActions().analyze(catalogContext(
        catalogSnapshot([map], project: project),
        'map.delete_apply',
        {'mapId': 'target'}));
    expect(result.errorCode, 'map.references_blocking');
    expect(result.details['edges'].toString(), contains('consequence.mapId'));
  });
}
