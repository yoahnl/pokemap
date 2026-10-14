import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _wire = <String, dynamic>{'kind': 'waitForActorRoutes', 'mapId': 'map'};
void main() {
  test('canonical barriers reject unknown ambiguous unloaded and spatial maps', () {
    final scene = _scene();
    final project = _project(scene);
    final map = MapData(id: 'map', name: 'Map', size: const GridSize(width: 4, height: 4));
    for (final (manifest, maps) in <(ProjectManifest, Map<String, MapData>)>[
      (project.copyWith(maps: []), {'map': map}),
      (project.copyWith(maps: [...project.maps, ...project.maps]), {'map': map}),
      (project, {}),
      (project, {'map': map.copyWith(id: 'other')}),
      (project, {'map': map.copyWith(version: ProjectVersion.v9)}),
      (project, {'map': map.copyWith(spatialScene: MapSpatialScene(width: 4, depth: 4))}),
    ]) {
      final report = diagnoseSceneAgainstProject(scene, manifest, mapsById: maps);
      expect(report.diagnostics.where((d) => d.code.name == 'commandUnknownMap'), isNotEmpty,
        reason: '${manifest.maps} ${maps.values}');
    }
    expect(diagnoseSceneAgainstProject(scene, project.copyWith(settings: const ProjectSettings(dimension: ProjectDimension.threeD)),
      mapsById: {'map': map}).diagnostics.where((d) => d.code.name == 'commandUnsupportedDimension'), isNotEmpty);
    expect(diagnoseSceneAgainstProject(scene, project, mapsById: {'map': map}).diagnostics
      .where((d) => d.code.name == 'commandUnknownMap' || d.code.name == 'commandUnsupportedDimension'), isEmpty);
  });
  test('route barrier dependency index records the exact map reference', () {
    final scene = _scene();
    final project = _project(scene);
    final map = MapData(id: 'map', name: 'Map', size: const GridSize(width: 4, height: 4));
    final index = buildNarrativeDependencyIndex(project: project, maps: [map]);
    final uses = index.usages.where((use) => use.owner.id == scene.id && use.target.kind == NarrativeDependencyTargetKind.sourceMap);
    expect(uses, hasLength(1));
    expect(uses.single.target.id, 'map');
    expect(uses.single.resolution, NarrativeDependencyResolution.resolved);
    final spatial = buildNarrativeDependencyIndex(project: project, maps: [map.copyWith(spatialScene: MapSpatialScene(width: 4, depth: 4))]);
    expect(spatial.usages.where((use) => use.owner.id == scene.id && use.target.kind == NarrativeDependencyTargetKind.sourceMap).single.resolution,
      NarrativeDependencyResolution.unavailable);
  });
  test('global route barrier has a strict map reference and only completed output', () {
    expect(() => SceneInteractiveCommand.fromJson(_wire), returnsNormally);
    final command = SceneInteractiveCommand.fromJson(_wire);
    expect(command.runtimeType.toString(), 'SceneWaitForActorRoutesInteractiveCommand');
    expect(command.kind.name, 'waitForActorRoutes');
    expect(command.toJson(), _wire);
    expect(command.outputPortIds, ['completed']);
    final restored = SceneInteractiveCommand.fromJson(jsonDecode(jsonEncode(command.toJson())) as Map<String, dynamic>);
    expect(restored, command);
    expect(restored.hashCode, command.hashCode);
    expect(SceneInteractiveCommand.fromJson({..._wire, 'mapId': 'Map'}), isNot(command));
  });
  test('global route barrier rejects incomplete mixed and noncanonical JSON', () {
    for (final wire in <Map<String, dynamic>>[
      {'kind': 'waitForActorRoutes'},
      for (final value in <Object?>[null, '', ' map', 'map ', 1, true]) {..._wire, 'mapId': value},
      {..._wire, 'durationMs': 100}, {..._wire, 'timeoutMs': 100},
      {..._wire, 'entityId': 'npc'}, {..._wire, 'target': {'kind': 'player', 'mapId': 'map'}},
      {..._wire, 'kind': 'wait_for_actor_routes'},
    ]) {
      expect(() => SceneInteractiveCommand.fromJson(wire), throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())), reason: '$wire');
    }
  });
  test('canonical builder preserves the exact barrier map without an invented timeout', () {
    expect(() => buildScenePayloadForNarrativeCommand(commandId: 'waitForActorRoutes', parameters: const {'mapId': 'map'}), returnsNormally);
    final payload = buildScenePayloadForNarrativeCommand(commandId: 'waitForActorRoutes', parameters: const {'mapId': 'map'}) as SceneActionPayload;
    expect(payload.interactiveCommand!.toJson(), _wire);
    for (final value in ['', ' map', 'map ']) {
      expect(() => buildScenePayloadForNarrativeCommand(commandId: 'waitForActorRoutes', parameters: {'mapId': value}), throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())));
    }
  });
  test('canonical catalogue exposes an awaitable 2D map-picker contract', () {
    final descriptor = NarrativeCommandCatalog.canonical().byId('waitForActorRoutes');
    expect(descriptor, isNotNull);
    expect(descriptor!.label, 'Attendre les déplacements');
    expect(descriptor.parameters.single.id, 'mapId');
    expect(descriptor.parameters.single.kind, NarrativeCommandParameterKind.map);
    expect(descriptor.isAwaitable, isTrue);
  });
}

SceneAsset _scene() => SceneAsset(id: 'barrier', name: 'Barrier', graph: SceneGraph(
  startNodeId: 'start', nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'action', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(SceneInteractiveCommand.fromJson(_wire))),
    SceneNode(id: 'end', kind: SceneNodeKind.end)],
  edges: [SceneEdge(id: 'start-action', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'action', kind: SceneEdgeKind.defaultFlow),
    SceneEdge(id: 'done', fromNodeId: 'action', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted)]));
ProjectManifest _project(SceneAsset scene) => ProjectManifest(name: 'Barrier', tilesets: const [],
  maps: const [ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')], scenes: [scene]);
