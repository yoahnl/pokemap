import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'support/spatial_package_fixture.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  final command = SceneInteractiveCommand.claimPeriodicReward(
      definition: PeriodicItemRewardDefinition(
          rewardId: 'fruit-tree',
          label: 'Fruit',
          itemId: 'fruit',
          quantity: 1));
  final project =
      ProjectManifest(name: 'Reward', maps: [], tilesets: [], scenes: [
    SceneAsset(
        id: 'reward',
        name: 'Reward',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'reward',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(command)),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'reward',
              kind: SceneEdgeKind.defaultFlow),
          for (final port in command.outputPortIds)
            SceneEdge(
                id: port,
                fromNodeId: 'reward',
                fromPortId: port,
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted),
        ]))
  ]);
  for (final portable in [false, true]) {
    test('periodic command cannot omit required capability portable=$portable',
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
              contains('gameplay.periodic-reward@1'))));
      expect(payload, before);
      (manifestJson['compatibility'] as Map)['requiredCapabilities'] = [
        'map@1',
        if (portable) 'catalog.partitioned@2',
        SpatialGameplayCapabilities.periodicRewardCapabilityId
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
        SpatialGameplayCapabilities.periodicRewardCapabilityId,
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

  test('host announces the condition only with its complete runtime surfaces', () {
    expect(AveluneRuntimeCompatibility.host().capabilities, contains(SpatialGameplayCapabilities.periodicRewardConditionCapabilityId));
  });
  test('host announces the durable periodic reward capability', () {
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains('gameplay.periodic-reward@1'));
  });
}
