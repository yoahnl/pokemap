import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'support/spatial_package_fixture.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  final policy = PeriodicEncounterDefinition(
      rewardId: 'scene/battle',
      label: 'Rencontre quotidienne',
      consumeOnOutcomes: {PeriodicEncounterOutcome.captured});
  final project =
      ProjectManifest(name: 'Reward', maps: [], tilesets: [], scenes: [
    SceneAsset(
        id: 'reward',
        name: 'Reward',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'reward',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                  battleKind: 'wild', periodicEncounter: policy)),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'reward',
              kind: SceneEdgeKind.defaultFlow),
          for (final port in ['victory', 'defeat'])
            SceneEdge(
                id: port,
                fromNodeId: 'reward',
                fromPortId: port,
                toNodeId: 'end',
                kind: port == 'victory'
                    ? SceneEdgeKind.battleVictory
                    : SceneEdgeKind.battleDefeat),
        ]))
  ]);
  for (final portable in [false, true]) {
    test(
        'periodic encounter cannot omit required capability portable=$portable',
        () {
      final publication = PortableCatalogPublication.encodeProject(project);
      final payload = <String, List<int>>{
        'project/project.json': utf8.encode(
            jsonEncode(portable ? publication.descriptor : project.toJson())),
        if (portable)
          for (final entry in publication.storage.objects.entries)
            'project/catalog/objects/${entry.key}.json': entry.value,
      };
      final before = {
        for (final entry in payload.entries)
          entry.key: List<int>.of(entry.value)
      };
      final manifestJson = spatialManifest(
              capabilities: ['map@1', if (portable) 'catalog.partitioned@2'])
          .toJson();
      (manifestJson['compatibility'] as Map).addAll(<String, Object?>{
        'projectFormat': 'v8',
        'minHubVersion': '0.1.0',
        'saveFormat': SaveEnvelopeCodec.currentSaveFormat
      });
      final manifest =
          const GamePackageManifestCodec().decodeJson(manifestJson);
      expect(
          () => const GamePackageBuilder()
              .build(manifest: manifest, payloadFiles: payload),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.message,
              'message',
              contains('gameplay.periodic-encounter@1'))));
      expect(payload, before);
      (manifestJson['compatibility'] as Map)['requiredCapabilities'] = [
        'map@1',
        if (portable) 'catalog.partitioned@2',
        'gameplay.periodic-encounter@1'
      ];
      final supported = const GamePackageBuilder().build(
          manifest: const GamePackageManifestCodec().decodeJson(manifestJson),
          payloadFiles: payload);
      final inspection = GamePackageInspector(
              hostCompatibility: AveluneRuntimeCompatibility.host())
          .inspect(supported.packageBytes);
      expect(inspection.compatibility?.decision,
          GamePackageCompatibilityDecision.accept);
      (manifestJson['compatibility'] as Map)['requiredCapabilities'] = [
        'map@1',
        if (portable) 'catalog.partitioned@2',
        'gameplay.periodic-encounter@1',
        'gameplay.future-reward@2'
      ];
      final future = const GamePackageBuilder().build(
          manifest: const GamePackageManifestCodec().decodeJson(manifestJson),
          payloadFiles: payload);
      final originalBytes = List<int>.of(future.packageBytes);
      expect(
          () => GamePackageInspector(
                  hostCompatibility: AveluneRuntimeCompatibility.host())
              .inspect(future.packageBytes),
          throwsA(isA<GamePackageFormatException>()));
      expect(future.packageBytes, originalBytes);
    });
  }

  test('host announces the encounter only with its complete runtime surfaces',
      () {
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains('gameplay.periodic-encounter@1'));
  });
  test('host announces the periodic encounter capability', () {
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains('gameplay.periodic-encounter@1'));
  });
}
