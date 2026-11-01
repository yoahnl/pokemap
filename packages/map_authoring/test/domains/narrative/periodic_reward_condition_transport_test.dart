import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/spatial_map_actions.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_spatial_map_selection.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_periodic_reward_consumers.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final entity in [false, true]) {
    test('validated periodic maps avoid consumer rereads entity=$entity',
        () async {
      final value = await _ProvenanceFixture.create(entity: entity);
      addTearDown(value.dispose);
      expect(value.validatedMaps, hasLength(1));
      final maps = value.validatedMaps.single.mapsFor(
          value.change, catalogRevision: value.selection.catalogRevision,
          request: value.plan.request);
      expect(identical(maps.before, value.selection.snapshot.mapById('route')),
          isTrue);
      value.checks.clear();
      final attested = await value.consume(validated: true);
      expect(value.checks, {'before': 1, 'after': 1});
      value.checks.clear();
      final decoded = await value.consume(validated: false);
      expect(value.checks['before'], greaterThanOrEqualTo(3));
      expect(value.checks['after'], greaterThanOrEqualTo(3));
      expect(attested.map((unit) => unit.toJson()).toList(),
          decoded.map((unit) => unit.toJson()).toList());
      expect(attested.single.payload['consumers'], hasLength(1));
      final generic = await value.consume(validated: false, generic: true);
      expect(generic.map((unit) => unit.toJson()).toList(),
          decoded.map((unit) => unit.toJson()).toList());
    });
    for (final substitution in ['change', 'payload', 'root']) {
      test('validated periodic maps reject $substitution entity=$entity',
          () async {
        final value = await _ProvenanceFixture.create(entity: entity);
        addTearDown(value.dispose);
        var change = value.change;
        var snapshot = value.selection.reader.catalog.snapshot;
        if (substitution != 'root') {
          change = AuthoringResourceChange.withPayloads(
              resource: change.resource,
              storageKey: change.storageKey,
              beforePayload: substitution == 'payload'
                  ? AuthoringPayload.inline(change.beforeBytes!,
                      storageKey: change.storageKey)
                  : change.beforePayload,
              afterPayload: change.afterPayload);
        } else {
          final patch = await snapshot.patch(upserts: [
            CatalogDefinitionUnit(
                key: CatalogDefinitionKey(
                    CatalogDefinitionKind.workspaceState, 'changed-root'),
                payload: const {'value': true})
          ]);
          snapshot = await patch.nextSnapshot(
              readObject: (reference) async => patch.objects[reference.sha256] ??
                  await value.selection.reader.store.readObject(reference));
        }
        await expectLater(
            value.consume(validated: true, change: change, snapshot: snapshot),
            throwsA(isA<AuthoringPlanException>().having((error) => error.code,
                'code', 'catalog.map_provenance_mismatch')));
      });
    }
    test('validated periodic maps reject another request target entity=$entity',
        () async {
      final value = await _ProvenanceFixture.create(entity: entity);
      addTearDown(value.dispose);
      final original = value.plan.request;
      final request = AuthoringRequest(
          requestId: original.requestId, actionId: original.actionId,
          actionVersion: original.actionVersion,
          workspaceHandle: original.workspaceHandle,
          expectedRevision: original.expectedRevision,
          idempotencyKey: original.idempotencyKey,
          parameters: {...original.parameters,
            entity ? 'entityId' : 'instanceId': 'another-target'});
      await expectLater(value.consume(validated: true, requestOverride: request),
          throwsA(isA<AuthoringPlanException>().having((error) => error.code,
              'code', 'catalog.map_provenance_mismatch')));
    });
    for (final cancelled in ['before', 'after']) {
      test('validated periodic maps retain $cancelled cancellation entity=$entity',
          () async {
        final value = await _ProvenanceFixture.create(entity: entity);
        addTearDown(value.dispose);
        value.cancelled.add(cancelled);
        await expectLater(value.consume(validated: true),
            throwsA(isA<AuthoringPayloadPreparationAborted>()));
      });
    }
    for (final replace in [false, true]) {
      test('attested consumer guards changed source entity=$entity replace=$replace',
          () async {
        final value = await _ProvenanceFixture.create(entity: entity);
        addTearDown(value.dispose);
        final source = (await value.selection.reader.catalog.snapshot.lookup(
            CatalogMetadataDocuments.definitionKey('scenes', 1)))!;
        final original = _source();
        final replacement = SceneAsset(id: original.id, name: original.name,
            graph: SceneGraph(startNodeId: original.graph.startNodeId,
            edges: original.graph.edges,
            nodes: [for (final node in original.graph.nodes)
              if (node.id == 'claim')
                SceneNode(id: node.id, kind: node.kind,
                    payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.claimPeriodicReward(
                        definition: PeriodicItemRewardDefinition(
                            rewardId: 'replacement', label: 'Fruit',
                            itemId: 'fruit', quantity: 2))))
              else node]));
        final changed = CatalogDefinitionUnit(
            key: source.key, references: source.references,
            payload: {...source.payload, 'value': {
              ...Map<String, Object?>.from(source.payload['value'] as Map),
              'definition': replacement.toJson()
            }});
        await expectLater(value.consume(validated: true,
            upserts: replace ? [changed] : const [],
            removals: replace ? const [] : [source.key]),
            throwsA(isA<CatalogStorageException>().having((error) => error.code,
                'code', 'catalog.periodic_reward_reference_in_use')));
      });
    }
    test('cleared attested consumers retain unknown coverage entity=$entity',
        () async {
      final value = await _ProvenanceFixture.create(entity: entity);
      addTearDown(value.dispose);
      final fixture = value.fixture;
      final request = value.plan.request;
      await fixture.apply(await fixture.plan(request.actionId, request.parameters));
      await fixture.apply(await fixture.plan(request.actionId, {
        'mapId': 'route',
        if (entity) ...{'entityId': 'anchor', 'presentation': null}
        else ...{'instanceId': 'tree', 'visibilityCondition': null}
      }));
      expect((await fixture.facet())?['consumers'], isEmpty);
      final map = File('${fixture.root.path}/maps/route.json');
      final bytes = await map.readAsBytes();
      await expectLater(fixture.plan('scene.interactive_command.set', {
        'sceneId': 'source', 'nodeId': 'claim',
        'command': SceneInteractiveCommand.claimPeriodicReward(
            definition: PeriodicItemRewardDefinition(rewardId: 'replacement',
                label: 'Fruit', itemId: 'fruit', quantity: 2)).toJson()
      }), throwsA(predicate((error) => error.toString()
          .contains('periodic_reward_reference_coverage_unknown'))));
      expect(await map.readAsBytes(), bytes);
    });
    test('periodic provenance follows the existing scope proof entity=$entity',
        () async {
      final value = await _ProvenanceFixture.create(entity: entity);
      addTearDown(value.dispose);
      final changed = MapData.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(value.change.afterBytes!)) as Map));
      final change = AuthoringResourceChange.withPayloads(
          resource: value.change.resource,
          storageKey: value.change.storageKey,
          beforePayload: value.change.beforePayload,
          afterPayload: AuthoringPayload.inline(
              utf8.encode(jsonEncode(changed.copyWith(name: 'outside').toJson())),
              storageKey: value.change.storageKey));
      final original = value.plan;
      final plan = AuthoringPlan(
          planId: original.planId, receiptId: original.receiptId,
          request: original.request, baseRevision: original.baseRevision,
          seed: original.seed, createdAt: original.createdAt,
          expiresAt: original.expiresAt,
          changeSet: AuthoringChangeSet(
              changes: [change], diff: original.changeSet.diff));
      addTearDown(plan.releasePayloads);
      await expectLater(value.selection.translate(plan),
          throwsA(isA<AuthoringPlanException>().having((error) => error.code,
              'code', 'catalog.mutation_outside_scope')));
    });
    test('stored periodic images keep consumer decoding entity=$entity',
        () async {
      final value = await _ProvenanceFixture.create(entity: entity, stored: true);
      addTearDown(value.dispose);
      expect(value.validatedMaps, isEmpty);
      value.checks.clear();
      final units = await value.consume(validated: true);
      expect(value.checks['before'], greaterThanOrEqualTo(3));
      expect(value.checks['after'], greaterThanOrEqualTo(3));
      expect(units.single.payload['consumers'], hasLength(1));
    });
  }
  test('model-only reward consumer guards source replacement and follows undo redo', () async {
    final fixture = await _Fixture.create(catalog: true, wire: false, unrelated: 0, spatial: true);
    addTearDown(fixture.dispose);
    await fixture.apply(await fixture.plan('map3d.instance.visibility.set', {'mapId': 'route', 'instanceId': 'tree',
      'visibilityCondition': NarrativeEventConditionExpression.leaf(NarrativeEventCondition.periodicRewardAvailable(reference: _reference(), expectedValue: true)).toJson()}));
    final receiptId = fixture.lastReceiptId!;
    expect((await fixture.facet())?['consumers'], hasLength(1));
    await expectLater(fixture.plan('scene.interactive_command.set', {'sceneId': 'source', 'nodeId': 'claim',
      'command': SceneInteractiveCommand.claimPeriodicReward(definition: PeriodicItemRewardDefinition(rewardId: 'replacement', label: 'Fruit', itemId: 'fruit', quantity: 2)).toJson()}),
      throwsA(predicate((error) => error.toString().contains('periodic_reward_reference_in_use'))));
    await fixture.mutations.undoMutation(fixture.opened.projectHandle, entryId: receiptId, idempotencyKey: 'undo-visibility');
    expect((await fixture.facet())?['consumers'] ?? const [], isEmpty);
    await fixture.mutations.redoMutation(fixture.opened.projectHandle, entryId: receiptId, idempotencyKey: 'redo-visibility');
    expect((await fixture.facet())?['consumers'], hasLength(1));
  });
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      test(
          'entity presentation periodic setter is targeted catalog=$catalog JSONL=$wire',
          () async {
        final fixture = await _Fixture.create(
            catalog: catalog, wire: wire, unrelated: 80, spatial: true);
        addTearDown(fixture.dispose);
        fixture.reader.clear();
        final condition = NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.periodicRewardAvailable(
                reference: _reference(), expectedValue: true));
        final presentation = MapEntityPresentation(variants: [
          MapEntityPresentationVariant(
              id: 'daily', condition: condition, blocksMovement: false)
        ]);
        await fixture.apply(await fixture.plan('entity.set_presentation', {
          'mapId': 'route',
          'entityId': 'anchor',
          'presentation': presentation.toJson()
        }));
        final saved = MapData.fromJson(jsonDecode(
            await File('${fixture.root.path}/maps/route.json')
                .readAsString()) as Map<String, dynamic>);
        expect(saved.entities.single.presentation, presentation);
        expect(
            fixture.reader.paths.where((path) =>
                path.startsWith('maps/') && path != 'maps/route.json' ||
                path.startsWith('assets/') ||
                path == 'items.json' ||
                path == 'dialogues/foreign.yarn' ||
                path.endsWith('history.jsonl')),
            isEmpty);
        if (catalog)
          expect(
              (await fixture.facet())?['consumers'],
              contains(equals({
                'kind': 'entityPresentation',
                'mapId': 'route',
                'entityId': 'anchor',
                'variantId': 'daily',
                'conditionIndex': '0',
                'rewardId': 'daily-fruit'
              })));
      });
    }
  }
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      for (final unrelated in [0, 80]) {
        test(
            'Event periodic condition resolves one source catalog=$catalog JSONL=$wire foreign=$unrelated',
            () async {
          final fixture = await _Fixture.create(
              catalog: catalog,
              wire: wire,
              unrelated: unrelated,
              spatial: true);
          addTearDown(fixture.dispose);
          for (final expected in [true, false]) {
            fixture.reader.clear();
            final condition = NarrativeEventCondition.periodicRewardAvailable(
                reference: _reference(), expectedValue: expected);
            final record = {
              'state': 'configured',
              'enabled': false,
              'definition': {
                'id': 'evt_019abcde-0000-7000-8000-000000000001',
                'name': 'Daily entrance',
                'source': {'kind': 'mapEnter', 'mapId': 'route'},
                'conditions': [condition.toJson()],
                'sceneId': 'consumer',
                'reusePolicy': 'reusable',
                'priority': 0,
                'order': 0,
              }
            };
            await fixture.apply(await fixture
                .plan('event_v2.record_upsert', {'record': record}));
            expect(
                fixture.reader.paths.where((path) =>
                    path.startsWith('maps/') && path != 'maps/route.json' ||
                    path.startsWith('assets/') ||
                    path == 'items.json' ||
                    path == 'dialogues/foreign.yarn' ||
                    path.endsWith('history.jsonl')),
                isEmpty);
            if (catalog) expect(
                (await fixture.facet())?['consumers'],
                contains(equals({
                  'kind': 'eventCondition',
                  'eventId': 'evt_019abcde-0000-7000-8000-000000000001',
                  'conditionIndex': '0',
                  'rewardId': 'daily-fruit'
                })));
          }
        });
      }
    }
  }
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      for (final unrelated in [0, 80]) {
        test(
            'model visibility persists locally catalog=$catalog JSONL=$wire foreign=$unrelated',
            () async {
          final fixture = await _Fixture.create(
              catalog: catalog,
              wire: wire,
              unrelated: unrelated,
              spatial: true);
          addTearDown(fixture.dispose);
          for (final expected in [true, false]) {
            fixture.reader.clear();
            final condition = NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.periodicRewardAvailable(
                    reference: _reference(), expectedValue: expected));
            await fixture
                .apply(await fixture.plan('map3d.instance.visibility.set', {
              'mapId': 'route',
              'instanceId': 'tree',
              'visibilityCondition': condition.toJson()
            }));
            final saved = MapData.fromJson(jsonDecode(
                await File('${fixture.root.path}/maps/route.json')
                    .readAsString()) as Map<String, dynamic>);
            expect(saved.spatialScene!.instances.single.visibilityCondition,
                condition);
            expect(saved.spatialScene!.instances.single.blocksMovement, isTrue);
            expect(
                fixture.reader.paths.where((path) =>
                    path.startsWith('maps/') && path != 'maps/route.json' ||
                    path.startsWith('assets/') ||
                    path == 'items.json' ||
                    path == 'dialogues/foreign.yarn' ||
                    path.endsWith('history.jsonl')),
                isEmpty);
            if (catalog)
              expect(
                  (await fixture.facet())?['consumers'],
                  contains(equals({
                    'kind': 'modelVisibility',
                    'mapId': 'route',
                    'instanceId': 'tree',
                    'conditionIndex': '0',
                    'rewardId': 'daily-fruit'
                  })));
          }
          await fixture.apply(await fixture.plan(
              'map3d.instance.visibility.set', {
            'mapId': 'route',
            'instanceId': 'tree',
            'visibilityCondition': null
          }));
          final saved = MapData.fromJson(jsonDecode(
              await File('${fixture.root.path}/maps/route.json')
                  .readAsString()) as Map<String, dynamic>);
          expect(
              saved.spatialScene!.instances.single.visibilityCondition, isNull);
          if (catalog) expect((await fixture.facet())?['consumers'], isEmpty);
        });
      }
    }
  }
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      for (final unrelated in [1, 80]) {
        test(
            'World Rule periodic source stays bounded catalog=$catalog JSONL=$wire foreign=$unrelated',
            () async {
          final fixture = await _Fixture.create(
              catalog: catalog, wire: wire, unrelated: unrelated);
          addTearDown(fixture.dispose);
          for (final expected in [true, false]) {
            fixture.reader.clear();
            final rule = WorldRuleDefinition(
                id: 'world_rule_daily',
                label: 'Daily',
                source: WorldRuleSource.periodicRewardAvailable(
                    reference: _reference(), expectedValue: expected),
                target: const WorldRuleTarget(
                    kind: WorldRuleTargetKind.mapEntity,
                    mapId: 'foreign-0',
                    entityId: 'tree'),
                effect: const WorldRuleEffect(
                    kind: WorldRuleEffectKind.entityHidden));
            await fixture.apply(await fixture.plan(
                expected ? 'world_rule.create' : 'world_rule.update',
                {'rule': rule.toJson()}));
            expect(
                fixture.reader.paths.where((path) =>
                    path.startsWith('maps/') && path != 'maps/foreign-0.json'),
                isEmpty);
            expect(
                fixture.reader.paths.where((path) =>
                    path == 'dialogues/foreign.yarn' ||
                    path == 'items.json' ||
                    path.endsWith('history.jsonl')),
                isEmpty);
            expect(
                fixture.reader.definitions
                    .where(
                        (id) => id.startsWith('["projectDefinition","scenes",'))
                    .map((id) => (jsonDecode(id) as List)[2])
                    .where((position) => (position as int) > 1),
                isEmpty);
            if (catalog)
              expect(
                  (await fixture.facet())?['consumers'],
                  contains(equals({
                    'kind': 'worldRule',
                    'ruleId': 'world_rule_daily',
                    'rewardId': 'daily-fruit'
                  })));
          }
        });
      }
    }
  }
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      for (final unrelated in [0, 80]) {
        test(
            'Scene periodic setter is local and durable catalog=$catalog JSONL=$wire foreign=$unrelated',
            () async {
          final fixture = await _Fixture.create(
              catalog: catalog, wire: wire, unrelated: unrelated);
          addTearDown(fixture.dispose);
          late SceneConditionSource source;
          for (final expected in [true, false]) {
            source = SceneConditionSource.periodicRewardAvailable(
                reference: _reference(), expectedValue: expected);
            fixture.reader.clear();
            final plan = await fixture.plan('scene.condition.set', {
              'sceneId': 'consumer',
              'nodeId': 'gate',
              'conditionSource': source.toJson(),
            });
            final touched = (plan['receipt'] as Map)['diff'];
            expect(touched, isNotNull);
            await fixture.apply(plan);
            expect(
                fixture.reader.paths.where((path) =>
                    path.startsWith('maps/') ||
                    path.startsWith('assets/') ||
                    path == 'dialogues/foreign.yarn' ||
                    path == 'items.json' ||
                    path.endsWith('history.jsonl')),
                isEmpty);
            if (catalog) {
              expect(
                  fixture.reader.definitions
                      .where((id) =>
                          id.startsWith('["projectDefinition","scenes",'))
                      .map((id) => (jsonDecode(id) as List)[2] as int)
                      .where((position) => position > 1),
                  isEmpty);
            }
          }
          await fixture.reopen();
          expect(await fixture.storedCondition(), source.toJson());
          final before = await fixture.manifest.readAsBytes();
          await expectLater(
              fixture.plan('scene.condition.set', {
                'sceneId': 'consumer',
                'nodeId': 'gate',
                'conditionSource': SceneConditionSource.periodicRewardAvailable(
                        reference: _reference(reward: 'mismatch'),
                        expectedValue: false)
                    .toJson(),
              }),
              throwsA(predicate((error) =>
                  error.toString().contains('scene.publication_blocked'))));
          expect(await fixture.manifest.readAsBytes(), before);
          expect(await fixture.storedCondition(), source.toJson());
        });
      }
    }
  }
  for (final wire in [false, true]) {
    test(
        'Scene condition facets follow undo and guard referenced or unknown claim replacements JSONL=$wire',
        () async {
      final fixture =
          await _Fixture.create(catalog: true, wire: wire, unrelated: 0);
      addTearDown(fixture.dispose);
      final source = SceneConditionSource.periodicRewardAvailable(
          reference: _reference(), expectedValue: true);
      await fixture.apply(await fixture.plan('scene.condition.set', {
        'sceneId': 'consumer',
        'nodeId': 'gate',
        'conditionSource': source.toJson(),
      }));
      final expected = [
        {
          'kind': 'sceneCondition',
          'sceneId': 'consumer',
          'nodeId': 'gate',
          'rewardId': 'daily-fruit'
        }
      ];
      expect((await fixture.facet())?['consumers'], expected);
      Map<String, Object?> command(
              {String reward = 'daily-fruit', int quantity = 3}) =>
          SceneInteractiveCommand.claimPeriodicReward(
                  definition: PeriodicItemRewardDefinition(
                      rewardId: reward,
                      label: 'Fruit',
                      itemId: 'fruit',
                      quantity: quantity))
              .toJson();
      await expectLater(
          fixture.plan('scene.interactive_command.set', {
            'sceneId': 'source',
            'nodeId': 'claim',
            'command': command(reward: 'replacement'),
          }),
          throwsA(predicate((error) =>
              error.toString().contains('periodic_reward_reference_in_use'))));
      await fixture.apply(await fixture.plan('scene.interactive_command.set', {
        'sceneId': 'source',
        'nodeId': 'claim',
        'command': command(),
      }));
      expect((await fixture.facet())?['consumers'], expected);
      await fixture.apply(await fixture.plan('scene.condition.set', {
        'sceneId': 'consumer',
        'nodeId': 'gate',
        'conditionSource': SceneConditionSource.factValue(
                factId: 'old',
                operator: NarrativeFactOperator.equals,
                expectedValue: NarrativeValue.boolean(true))
            .toJson(),
      }));
      final clearing = fixture.lastReceiptId!;
      expect((await fixture.facet())?['consumers'], isEmpty);
      await expectLater(
          fixture.plan('scene.interactive_command.set', {
            'sceneId': 'source',
            'nodeId': 'claim',
            'command': command(reward: 'replacement'),
          }),
          throwsA(predicate((error) => error
              .toString()
              .contains('periodic_reward_reference_coverage_unknown'))));
      await fixture.mutations.undoMutation(fixture.opened.projectHandle,
          entryId: clearing, idempotencyKey: 'undo-clearing');
      expect((await fixture.facet())?['consumers'], expected);
      expect(await fixture.storedCondition(), source.toJson());
      await fixture.mutations.redoMutation(fixture.opened.projectHandle,
          entryId: clearing, idempotencyKey: 'redo-clearing');
      expect((await fixture.facet())?['consumers'], isEmpty);
    });
  }
  test(
      'native source replacement refuses unknown historical coverage while compatible quantity stays editable',
      () async {
    final fixture =
        await _Fixture.create(catalog: false, wire: false, unrelated: 0);
    addTearDown(fixture.dispose);
    final before = await fixture.manifest.readAsBytes();
    Map<String, Object?> parameters(String reward, int quantity) => {
          'sceneId': 'source',
          'nodeId': 'claim',
          'command': SceneInteractiveCommand.claimPeriodicReward(
                  definition: PeriodicItemRewardDefinition(
                      rewardId: reward,
                      label: 'Fruit',
                      itemId: 'fruit',
                      quantity: quantity))
              .toJson(),
        };
    await expectLater(
        fixture.legacySourcePlan(parameters('replacement', 2)),
        throwsA(predicate((error) => error
            .toString()
            .contains('periodic_reward_reference_coverage_unknown'))));
    expect(await fixture.manifest.readAsBytes(), before);
    await fixture
        .apply(await fixture.legacySourcePlan(parameters('daily-fruit', 3)));
  });
  test('a consumer added after source planning invalidates the old source plan',
      () async {
    final fixture =
        await _Fixture.create(catalog: true, wire: false, unrelated: 0);
    addTearDown(fixture.dispose);
    final earlier = await fixture.plan('scene.interactive_command.set', {
      'sceneId': 'source',
      'nodeId': 'claim',
      'command': SceneInteractiveCommand.claimPeriodicReward(
              definition: PeriodicItemRewardDefinition(
                  rewardId: 'daily-fruit',
                  label: 'Fruit',
                  itemId: 'fruit',
                  quantity: 3))
          .toJson(),
    });
    await fixture.apply(await fixture.plan('scene.condition.set', {
      'sceneId': 'consumer',
      'nodeId': 'gate',
      'conditionSource': SceneConditionSource.periodicRewardAvailable(
              reference: _reference(), expectedValue: true)
          .toJson(),
    }));
    await expectLater(
        fixture.mutations.applyMutation(fixture.opened.projectHandle,
            planId: earlier['planId'] as String,
            operationId: 'stale-source-plan'),
        throwsA(predicate((error) =>
            error.toString().contains('stale') ||
            error.toString().contains('revision_conflict'))));
    expect((await fixture.facet())?['consumers'], hasLength(1));
    final source = await fixture.storedScene('source');
    final command = (source.graph.nodes
            .singleWhere((node) => node.id == 'claim')
            .payload as SceneActionPayload)
        .interactiveCommand as SceneClaimPeriodicRewardInteractiveCommand;
    expect(command.definition.quantity, 2);
  });
  test(
      'self reference resolves the current candidate and snapshot lookup preserves ambiguity',
      () {
    SceneNode claim(String reward) => SceneNode(
        id: 'claim',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.claimPeriodicReward(
                definition: PeriodicItemRewardDefinition(
                    rewardId: reward,
                    label: 'Fruit',
                    itemId: 'fruit',
                    quantity: 1))));
    final consumer = _consumer();
    final old = SceneAsset(
        id: 'self',
        name: 'Self',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          consumer.graph.nodes.first,
          claim('old'),
          ...consumer.graph.nodes.skip(1),
        ], edges: [
          _edge('enter', 'start', 'claim'),
          for (final port in [
            'received',
            'alreadyClaimed',
            'bagFull',
            'blocked'
          ])
            _edge('claim-$port', 'claim', 'gate',
                port: port, kind: SceneEdgeKind.actionCompleted),
          ...consumer.graph.edges.skip(1),
        ]));
    final project = ProjectManifest(
        name: 'Self',
        maps: const [],
        tilesets: const [],
        scenes: [
          old
        ],
        facts: [
          NarrativeFactDefinition(
              id: 'old',
              label: 'Old',
              initialValue: NarrativeValue.boolean(true))
        ]);
    final reference = PeriodicRewardReference(
        sceneId: 'self', nodeId: 'claim', rewardId: 'current');
    final updated = const SceneActions().patchGraph(project,
        maps: const [],
        sceneId: 'self',
        lookupRewardScenes: (_) => [old],
        itemCatalog: ProjectItemCatalog(schemaVersion: 1, entries: const [
          ProjectItemDefinition(
              id: 'fruit', displayName: 'Fruit', pocketId: 'materials')
        ]),
        upsertNodes: [
          claim('current'),
          SceneNode(
              id: 'gate',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                  conditionSource: SceneConditionSource.periodicRewardAvailable(
                      reference: reference, expectedValue: true)))
        ]);
    expect(
        resolvePeriodicRewardReference(
            reference: reference,
            lookupScenes: (_) => updated.scenes).isResolved,
        isTrue);
    final snapshot = ProjectSnapshot(
        projectHandle: ProjectHandle('test'),
        revision: 'sha256:${List.filled(64, '0').join()}',
        manifest: project.copyWith(scenes: [old, old]),
        maps: const [],
        resourceFingerprints: const {});
    expect(snapshot.lookupRewardScenes('self'), hasLength(2));
    expect(
        resolvePeriodicRewardReference(
                reference: reference, lookupScenes: snapshot.lookupRewardScenes)
            .status,
        PeriodicRewardReferenceStatus.sceneAmbiguous);
  });
  test(
      'failed catalog publication leaves both Scene condition and consumer facets on the original root',
      () async {
    final fixture = await _Fixture.create(
        catalog: true,
        wire: false,
        unrelated: 0,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.beforeResourcePromotion) {
            throw StateError('controlled promotion failure');
          }
        });
    addTearDown(fixture.dispose);
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final original = (await store.readHead())!;
    final head = File('${fixture.root.path}/catalog/HEAD.json');
    final before = await head.readAsBytes();
    final plan = await fixture.plan('scene.condition.set', {
      'sceneId': 'consumer',
      'nodeId': 'gate',
      'conditionSource': SceneConditionSource.periodicRewardAvailable(
              reference: _reference(), expectedValue: true)
          .toJson(),
    });
    await expectLater(fixture.apply(plan), throwsA(anything));
    expect(await head.readAsBytes(), before);
    final snapshot = (await store.openRoot(original)).snapshot;
    expect(
        await snapshot.lookup(CatalogDefinitionKey(
            CatalogDefinitionKind.workspaceState,
            jsonEncode(['periodicRewardConsumers', 'source', 'claim']))),
        isNull);
    final saved = (await CatalogMetadataDocuments.readDocuments(
            snapshot: snapshot,
            project:
                const ProjectManifest(name: 'Original', maps: [], tilesets: []),
            ids: {
          'scenes': {'consumer'}
        }))
        .project
        .scenes
        .single;
    expect(
        (saved.graph.nodes.singleWhere((node) => node.id == 'gate').payload
                as SceneConditionPayload)
            .conditionSource!
            .sourceKind,
        SceneConditionSourceKind.fact);
  });
  for (final reverse in [false, true]) {
    test(
        'Scene physical relocation preserves semantic consumer facets regardless of upsert order reverse=$reverse',
        () async {
      final fixture =
          await _Fixture.create(catalog: true, wire: false, unrelated: 0);
      addTearDown(fixture.dispose);
      await fixture.apply(await fixture.plan('scene.condition.set', {
        'sceneId': 'consumer',
        'nodeId': 'gate',
        'conditionSource': SceneConditionSource.periodicRewardAvailable(
                reference: _reference(), expectedValue: true)
            .toJson(),
      }));
      final store =
          await CatalogStorageStore.open(projectRoot: fixture.root.path);
      final snapshot =
          (await store.openRoot((await store.readHead())!)).snapshot;
      final consumer = (await snapshot
          .lookup(CatalogMetadataDocuments.definitionKey('scenes', 0)))!;
      final source = (await snapshot
          .lookup(CatalogMetadataDocuments.definitionKey('scenes', 1)))!;
      CatalogDefinitionUnit moved(CatalogDefinitionUnit unit, int position) {
        final key = CatalogMetadataDocuments.definitionKey('scenes', position);
        return CatalogDefinitionUnit(
            key: key,
            references: unit.references,
            payload: {...unit.payload, 'id': key.id, 'position': position});
      }

      final changes = [moved(source, 0), moved(consumer, 1)];
      expect(
          await CatalogPeriodicRewardConsumers.maintainAndGuard(
              snapshot: snapshot,
              upserts: reverse ? changes.reversed : changes,
              removals: const []),
          isEmpty);
      expect((await fixture.facet())?['consumers'], hasLength(1));
    });
  }
}

PeriodicRewardReference _reference({String reward = 'daily-fruit'}) =>
    PeriodicRewardReference(
      sceneId: 'source',
      nodeId: 'claim',
      rewardId: reward,
    );

SceneEdge _edge(String id, String from, String to,
        {String port = 'completed',
        SceneEdgeKind kind = SceneEdgeKind.defaultFlow}) =>
    SceneEdge(
        id: id, fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind);

SceneAsset _consumer() => SceneAsset(
    id: 'consumer',
    name: 'Consumer',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'gate',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.factValue(
                    factId: 'old',
                    operator: NarrativeFactOperator.equals,
                    expectedValue: NarrativeValue.boolean(true)))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        _edge('enter', 'start', 'gate'),
        _edge('yes', 'gate', 'end',
            port: 'true', kind: SceneEdgeKind.conditionTrue),
        _edge('no', 'gate', 'end',
            port: 'false', kind: SceneEdgeKind.conditionFalse),
      ],
    ));

SceneAsset _source() => SceneAsset(
    id: 'source',
    name: 'Source',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'claim',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.claimPeriodicReward(
                  definition: PeriodicItemRewardDefinition(
                      rewardId: 'daily-fruit',
                      label: 'Fruit',
                      itemId: 'fruit',
                      quantity: 2)))),
      SceneNode(
          id: 'talk',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'foreign-dialogue')),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      _edge('enter', 'start', 'claim'),
      for (final port in ['received', 'alreadyClaimed', 'bagFull', 'blocked'])
        _edge('claim-$port', 'claim', 'talk',
            port: port, kind: SceneEdgeKind.actionCompleted),
      _edge('leave', 'talk', 'end'),
    ]));

final class _Fixture {
  _Fixture(this.root, this.catalog, this.wire, this.reader, this.api,
      this.mutations, this.opened);
  final Directory root;
  final bool catalog;
  final bool wire;
  final _Reader reader;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  OpenedProject opened;
  int sequence = 0;
  String? lastReceiptId;
  File get manifest => File('${root.path}/project.json');

  static Future<_Fixture> create(
      {required bool catalog,
      required bool wire,
      required int unrelated,
      bool spatial = false,
      AuthoringTransactionFaultInjector? faultInjector}) async {
    final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring');
    await qa.create(recursive: true);
    final root = Directory('${qa.path}/fixture');
    if (await root.exists()) throw StateError('The owned periodic fixture is already in use.');
    await root.create();
    final project = ProjectManifest(
        name: 'Periodic conditions',
        version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension:
                spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
        maps: [
          if (spatial)
            const ProjectMapEntry(
                id: 'route', name: 'Route', relativePath: 'maps/route.json'),
          for (var i = 0; i < unrelated; i++)
            ProjectMapEntry(
                id: 'foreign-$i',
                name: 'Foreign',
                relativePath: 'maps/foreign-$i.json'),
        ],
        tilesets: const [],
        models3d: [
          if (spatial)
            ProjectModel3dEntry(
                id: 'tree-model',
                name: 'Tree',
                sourceAssetId: 'tree-source',
                relativePath: 'assets/models3d/tree-model.glb',
                inspection: Model3dInspection(
                    bounds: Model3dBounds(
                        min: Model3dVector3(x: -.4, y: 0, z: -.4),
                        max: Model3dVector3(x: .4, y: 2, z: .4)),
                    meshCount: 1,
                    triangleCount: 4))
        ],
        scenes: [
          _consumer(),
          _source(),
          for (var i = 0; i < unrelated; i++)
            SceneAsset(
                id: 'foreign-scene-$i',
                name: 'Foreign',
                graph: SceneGraph(startNodeId: 'start', nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ], edges: [
                  _edge('leave', 'start', 'end')
                ])),
        ],
        facts: [
          NarrativeFactDefinition(
              id: 'old',
              label: 'Old',
              initialValue: NarrativeValue.boolean(true))
        ],
        dialogues: const [
          ProjectDialogueEntry(
              id: 'foreign-dialogue',
              name: 'Foreign',
              relativePath: 'dialogues/foreign.yarn')
        ],
        pokemon: const ProjectPokemonConfig(
            enabled: false,
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'items.json'}));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await Directory('${root.path}/dialogues').create();
    await File('${root.path}/dialogues/foreign.yarn')
        .writeAsString('title: Start\n---\nForeign\n===\n');
    await File('${root.path}/items.json').writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        {'id': 'fruit', 'displayName': 'Fruit', 'pocketId': 'materials'},
      ]
    }));
    await Directory('${root.path}/maps').create();
    if (spatial)
      await File('${root.path}/maps/route.json')
          .writeAsString(jsonEncode(MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v9,
        entities: [
          MapEntity(
              id: 'anchor',
              name: 'Anchor',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 1, y: 1))
        ],
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(
            width: 4,
            depth: 4,
            heightLevels: List.filled(16, 0),
            instances: [
              SpatialModelInstance(
                  id: 'tree',
                  modelId: 'tree-model',
                  position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
                  blocksMovement: true)
            ]),
      ).toJson()));
    for (var i = 0; i < unrelated; i++) {
      await File('${root.path}/maps/foreign-$i.json').writeAsString(jsonEncode(
          MapData(
              id: 'foreign-$i',
              name: 'Foreign',
              size: const GridSize(width: 4, height: 4),
              entities: [
            MapEntity(
                id: 'tree',
                name: 'Tree',
                kind: MapEntityKind.custom,
                pos: const GridPos(x: 1, y: 1))
          ]).toJson()));
    }
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
          store: store,
          projectId: 'periodic-condition',
          project: project,
          expectedProjectRevision:
              await store.gateway.readResourceRevision('project.json'));
    }
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString(
        'foreign legacy history must not be read\n' * (unrelated + 1));
    final reader = _Reader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        faultInjector: faultInjector,
        authorizationLimits:
            const AuthoringSecurityLimits(maxOperationsPerWindow: null));
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, catalog, wire, reader, api, mutations, opened);
  }

  Future<Map<String, Object?>> plan(
      String action, Map<String, Object?> parameters) async {
    final snapshot = await mutations.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    final request = AuthoringRequest(
        requestId: 'setter-${++sequence}',
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'setter-$sequence',
        parameters: parameters);
    if (!wire) {
      return (await mutations.planMutation(opened.projectHandle, request))
          .toJson();
    }
    return call('plan', {
      'projectHandle': opened.projectHandle.value,
      'request': request.toJson()
    });
  }

  Future<Map<String, Object?>> legacySourcePlan(
      Map<String, Object?> parameters) async {
    final page = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'scene',
            operation: AuthoringQueryOperation.get,
            ids: const ['source'],
            view: AuthoringQueryView.detail));
    return (await mutations.planMutation(
            opened.projectHandle,
            AuthoringRequest(
                requestId: 'legacy-${++sequence}',
                actionId: 'scene.interactive_command.set',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: page.snapshotRevision,
                idempotencyKey: 'legacy-$sequence',
                parameters: parameters)))
        .toJson();
  }

  Future<Map<String, Object?>> call(
      String command, Map<String, Object?> args) async {
    final worker = JsonlWorker(api: api, mutations: mutations);
    final result = AuthoringResult.fromJson(
        jsonDecode(await worker.processLine(jsonEncode({
      'id': 'setter-$sequence',
      'command': command,
      'args': args,
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw StateError(jsonEncode(result.toJson()));
    }
    return result.data;
  }

  Future<void> apply(Map<String, Object?> plan) async {
    final Map<String, Object?> result;
    if (wire) {
      result = await call('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': 'apply-$sequence'
      });
    } else {
      result = (await mutations.applyMutation(opened.projectHandle,
              planId: plan['planId'] as String, operationId: 'apply-$sequence'))
          .toJson();
    }
    lastReceiptId = (result['receipt'] as Map)['receiptId'] as String;
  }

  Future<Map<String, Object?>?> facet() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final reader = (await CatalogProjectReader.open(
        store: store,
        descriptor: Map<String, Object?>.from(
            jsonDecode(await manifest.readAsString()) as Map),
        metadataFields: {}))!;
    return reader.read((catalog) async => (await catalog.snapshot.lookup(
            CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
                jsonEncode(['periodicRewardConsumers', 'source', 'claim']))))
        ?.payload);
  }

  Future<Map<String, dynamic>> storedCondition() async {
    final scene = await storedScene('consumer');
    return ((scene.graph.nodes.singleWhere((node) => node.id == 'gate').payload
                as SceneConditionPayload)
            .conditionSource!)
        .toJson();
  }

  Future<SceneAsset> storedScene(String id) async {
    final ProjectManifest project;
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final reader = (await CatalogProjectReader.open(
          store: store,
          descriptor: Map<String, Object?>.from(
              jsonDecode(await manifest.readAsString()) as Map),
          metadataFields: {}))!;
      project = await reader.read((catalog) async =>
          (await CatalogMetadataDocuments.readDocuments(
                  snapshot: catalog.snapshot,
                  project: catalog.projectMetadata,
                  ids: {
                'scenes': {id}
              }))
              .project);
    } else {
      project = ProjectManifest.fromJson(
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>);
    }
    return project.scenes.singleWhere((scene) => scene.id == id);
  }

  Future<void> reopen() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final definitions = <String>[];
  void clear() {
    paths.clear();
    definitions.clear();
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      const LocalProjectFileReader().canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      const LocalProjectFileReader()
          .probeResource(projectRoot: projectRoot, relativePath: relativePath);
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    paths.add(relativePath);
    final bytes = await const LocalProjectFileReader()
        .readBytes(projectRoot: projectRoot, relativePath: relativePath);
    if (relativePath.startsWith('catalog/objects/')) {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is Map && raw['key'] is Map) {
        definitions.add((raw['key'] as Map)['id'] as String);
      }
    }
    return bytes;
  }
}

final class _ProvenanceFixture {
  _ProvenanceFixture(this.fixture, this.selection, this.plan, this.validatedMaps,
      this.checks, this.cancelled);

  final _Fixture fixture;
  final CatalogSpatialMapSelection selection;
  final AuthoringPlan plan;
  final List<CatalogValidatedMapChange> validatedMaps;
  final Map<String, int> checks;
  final Set<String> cancelled;
  AuthoringResourceChange get change => plan.changeSet.changes.single;

  static Future<_ProvenanceFixture> create(
      {required bool entity, bool stored = false}) async {
    final fixture = await _Fixture.create(
        catalog: true, wire: false, unrelated: 0, spatial: true);
    try {
      final condition = NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.periodicRewardAvailable(
              reference: _reference(), expectedValue: true));
      final action = entity
          ? 'entity.set_presentation'
          : 'map3d.instance.visibility.set';
      final parameters = <String, Object?>{
        'mapId': 'route',
        if (entity) ...{
          'entityId': 'anchor',
          'presentation': MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'daily', condition: condition, blocksMovement: false)
          ]).toJson()
        } else ...{
          'instanceId': 'tree',
          'visibilityCondition': condition.toJson()
        }
      };
      await fixture.mutations.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: action, parameters: parameters);
      final store = await CatalogStorageStore.open(projectRoot: fixture.root.path);
      final reader = (await CatalogProjectReader.open(
          store: store,
          descriptor: Map<String, Object?>.from(
              jsonDecode(await fixture.manifest.readAsString()) as Map),
          metadataFields: {}))!;
      final selection = await CatalogSpatialMapSelection.read(
          reader: reader,
          projectHandle: fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      final request = AuthoringRequest(
          requestId: 'provenance', actionId: action, actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision: selection.snapshot.revision,
          idempotencyKey: 'provenance', parameters: parameters);
      final context = AuthoringPlanningContext(snapshot: selection.snapshot,
          request: request, planId: 'provenance', seed: 0);
      final draft = entity
          ? const EntityActions().build(context)
          : const SpatialMapActions().build(context);
      final original = draft.changeSet.changes.single;
      final checks = <String, int>{};
      final cancelled = <String>{};
      Future<AuthoringPayload> checked(AuthoringPayload payload, String name) async {
        if (stored) {
          final bytes = await payload.readBytes();
          payload = await AuthoringPayload.verifiedResource(
              storageKey: payload.storageKey, byteLength: payload.byteLength,
              resourceRevision: payload.resourceRevision,
              openRead: () => Stream.value(bytes));
        }
        return payload.checkingPreparation(() {
          checks.update(name, (count) => count + 1, ifAbsent: () => 1);
          if (cancelled.contains(name)) throw StateError('cancelled');
        });
      }
      final change = AuthoringResourceChange.withPayloads(
          resource: original.resource, storageKey: original.storageKey,
          beforePayload: await checked(original.beforePayload!, 'before'),
          afterPayload: await checked(original.afterPayload!, 'after'));
      final now = DateTime.now().toUtc();
      final plan = AuthoringPlan(planId: 'provenance', receiptId: 'provenance',
          request: request, baseRevision: selection.snapshot.revision, seed: 0,
          createdAt: now, expiresAt: now.add(const Duration(minutes: 5)),
          changeSet: AuthoringChangeSet(changes: [change], diff: draft.changeSet.diff));
      final translated = await selection.translate(plan);
      return _ProvenanceFixture(fixture, selection, plan,
          translated.validatedMaps, checks, cancelled);
    } on Object {
      await fixture.dispose();
      rethrow;
    }
  }

  Future<List<CatalogDefinitionUnit>> consume({required bool validated,
      AuthoringResourceChange? change, CatalogSnapshot? snapshot,
      Iterable<CatalogDefinitionUnit> upserts = const [],
      Iterable<CatalogDefinitionKey> removals = const [],
      AuthoringRequest? requestOverride,
      bool generic = false}) => CatalogPeriodicRewardConsumers.maintainAndGuard(
          snapshot: snapshot ?? selection.reader.catalog.snapshot,
          upserts: upserts, removals: removals,
          additionalChanges: [change ?? this.change],
          validatedMaps: validated ? validatedMaps : const [],
          request: requestOverride ?? (generic
              ? AuthoringRequest(requestId: 'generic', actionId: 'map.save',
                  actionVersion: 1,
                  workspaceHandle: fixture.opened.workspaceHandle.value,
                  parameters: const {})
              : plan.request));

  Future<void> dispose() async {
    await plan.releasePayloads();
    await fixture.dispose();
  }
}
