import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'map_metadata_fixture.dart';

void main() {
  const rule = ContextualItemUseRule(
      id: 'rope-wall',
      itemId: 'rope',
      sceneId: 'secret',
      position: GridPos(x: 2, y: 2),
      facing: EntityFacing.north,
      priority: 7);
  Future<MapMetadataFixture> fixture() async {
    final f = await MapMetadataFixture.create();
    final scene = SceneAsset(
        id: 'secret',
        name: 'Secret',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end)
        ], edges: [
          SceneEdge(
              id: 'edge',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow)
        ]));
    final manifest = (await f.manifest()).copyWith(
        scenes: [scene],
        pokemon: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'items.json'}));
    await File('${f.root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    await File('${f.root.path}/items.json').writeAsString(
        jsonEncode(const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(
          id: 'rope', displayName: 'Corde', pocketId: 'items'),
    ]).toJson()));
    return f;
  }

  test('contextual rules use canonical plan apply reopen and undo', () async {
    final f = await fixture();
    addTearDown(f.dispose);
    final before = await f.map();
    final plan = await f.plan(parameters: {
      'mapId': 'town',
      'contextualItemUses': [rule.toJson()]
    });
    expect(await f.map(), before);
    final result = await f.apply(plan);
    expect((await f.map()).contextualItemUses, [rule]);
    expect((await f.map()).copyWith(mapMetadata: before.mapMetadata), before);
    final receipt = result['receipt']! as Map;
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-context');
    expect(await f.map(), before);
  });

  test(
      'unrelated metadata preserves contextual identities and conditions on disk',
      () async {
    final f = await fixture();
    addTearDown(f.dispose);
    final manifest = (await f.manifest()).copyWith(
      facts: [NarrativeFactDefinition(id: 'wall-open', label: 'Mur ouvert')],
    );
    await File('${f.root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final conditioned = ContextualItemUseRule.fromJson({
      ...rule.toJson(),
      'conditionExpression': NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('wall-open', true),
      ).toJson(),
    });
    await f.apply(await f.plan(parameters: {
      'mapId': 'town',
      'contextualItemUses': [conditioned.toJson()],
    }));
    final before = await f.map();
    final plan = await f.plan(parameters: {
      'mapId': 'town',
      'allowBicycle': false,
    });
    expect(await f.map(), before);
    await f.apply(plan);
    final reopened = await f.map();
    expect(reopened.contextualItemUses, [conditioned]);
    expect(
      reopened,
      before.copyWith(
        mapMetadata: before.mapMetadata.copyWith(allowBicycle: false),
      ),
    );
  });

  test('128 contextual rules are accepted by canonical plan apply and reopen',
      () async {
    final f = await fixture();
    addTearDown(f.dispose);
    final rules = [
      for (var index = 0; index < 128; index++)
        ContextualItemUseRule.fromJson({
          ...rule.toJson(),
          'id': 'context-item-$index',
        }),
    ];
    final before = await f.map();
    final plan = await f.plan(parameters: {
      'mapId': 'town',
      'contextualItemUses': rules.map((entry) => entry.toJson()).toList(),
    });
    expect(await f.map(), before);
    await f.apply(plan);
    expect((await f.map()).contextualItemUses, rules);
  });

  for (final invalid in ['129-rules', 'duplicate-id']) {
    test('$invalid are refused canonically without changing saved rules',
        () async {
      final f = await fixture();
      addTearDown(f.dispose);
      await f.apply(await f.plan(parameters: {
        'mapId': 'town',
        'contextualItemUses': [rule.toJson()],
      }));
      final before = await f.map();
      final originalBytes =
          await File('${f.root.path}/documents/unusual.json').readAsBytes();
      final rules = invalid == 'duplicate-id'
          ? [rule.toJson(), rule.toJson()]
          : [
              for (var index = 0; index < 129; index++)
                {...rule.toJson(), 'id': 'context-item-$index'},
            ];
      await expectLater(
        () => f.plan(parameters: {
          'mapId': 'town',
          'contextualItemUses': rules,
        }),
        throwsA(isA<Exception>()),
      );
      expect(await f.map(), before);
      expect(
        await File('${f.root.path}/documents/unusual.json').readAsBytes(),
        originalBytes,
      );
    });
  }

  for (final invalid in [
    {...rule.toJson(), 'sceneId': 'missing'},
    {...rule.toJson(), 'itemId': 'missing'},
    {
      ...rule.toJson(),
      'position': {'x': 8, 'y': 2}
    },
    {...rule.toJson(), 'facing': 'diagonal'},
  ]) {
    test(
        'invalid contextual reference or coordinate refuses before mutation $invalid',
        () async {
      final f = await fixture();
      addTearDown(f.dispose);
      final before = await f.map();
      await expectLater(
          () => f.plan(parameters: {
                'mapId': 'town',
                'contextualItemUses': [invalid]
              }),
          throwsA(isA<Exception>()));
      expect(await f.map(), before);
    });
  }
}
