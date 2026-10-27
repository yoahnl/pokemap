import 'dart:io';
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('raw asset first and repeated imports retain unrelated catalog data', () async {
    final fixture = await _Fixture.open(unrelatedRecords: 100);
    addTearDown(fixture.close);
    final png = img.encodePng(img.Image(width: 2, height: 2));
    final staged = await fixture.api.artifacts.put(png, declaredMediaType: 'image/png');
    for (var repeat = 0; repeat < 2; repeat++) {
      final entries = [for (var index = 0; index <= repeat; index++) {
        'assetId': 'image-$repeat-$index', 'logicalPath': 'assets/imported-$repeat-$index.png',
        'artifactHandle': staged.reference.handle, 'tags': ['test'], 'usages': ['image']
      }];
      final action = repeat == 0 ? 'asset.import' : 'asset.import_batch';
      final parameters = repeat == 0 ? entries.single : <String, Object?>{'entries': entries};
      final snapshot = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: action, parameters: parameters);
      expect(snapshot.maps, isEmpty);
      expect(snapshot.manifest.trainers, isEmpty);
      expect(snapshot.manifest.tilesets, isEmpty);
      expect(snapshot.availableProjectSections, isEmpty);
      await _applyScoped(fixture, action, parameters, 'raw_asset_$repeat');
      for (final entry in entries) {
        expect(await File('${fixture.root.path}/${entry['logicalPath']}').readAsBytes(), png);
      }
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptorBytes);
    }
  });

  test('contact configuration first update reopen and clear ignore unrelated data', () async {
    final fixture = await _Fixture.open(savings: true, contacts: true, unrelatedRecords: 100);
    addTearDown(fixture.close);
    await _applyScoped(fixture, 'fact.create', {'fact': NarrativeFactDefinition(
        id: 'fact_mentor_known', label: 'Mentor known').toJson()}, 'contact_fact');
    final scene = SceneAsset.fromJson({
      'id': 'contact-call', 'name': 'Contact call',
      'graph': {'startNodeId': 'start', 'nodes': [
        {'id': 'start', 'kind': 'start'}, {'id': 'end', 'kind': 'end'}
      ], 'edges': [
        {'id': 'end-edge', 'fromNodeId': 'start', 'fromPortId': 'completed', 'toNodeId': 'end', 'kind': 'defaultFlow'}
      ]}
    });
    await _applyScoped(fixture, 'scene.upsert', {'scene': scene.toJson()}, 'contact_scene');
    for (var i = 0; i < 2; i++) {
      final config = {'id': 'device', 'label': 'Device $i', 'acquiredFactId': 'enabled',
        'emptyMessage': 'No contacts', 'contacts': [
          {'id': 'mentor', 'label': 'Mentor', 'registeredFactId': 'fact_mentor_known',
            'sceneId': scene.id, 'unavailableSceneId': scene.id}
        ]};
      final parameters = <String, Object?>{'configuration': config};
      await _applyScoped(fixture, 'contact_device.configure', parameters, 'contact_$i');
      final snapshot = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: 'contact_device.configure', parameters: parameters);
      expect(snapshot.manifest.contactDevice!.label, 'Device $i');
      expect(snapshot.manifest.facts.map((f) => f.id), unorderedEquals(['enabled', 'fact_mentor_known']));
      expect(snapshot.manifest.scenes.map((s) => s.id), [scene.id]);
      expect(snapshot.manifest.trainers, isEmpty);
      expect(snapshot.manifest.shops, isEmpty);
      expect(snapshot.maps, isEmpty);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptorBytes);
    }
    await _applyScoped(fixture, 'contact_device.configure', {'configuration': null}, 'clear_contact');
    final reopened = (await CatalogProjectReader.open(store: fixture.store,
        descriptor: fixture.working.descriptor.toJson(), metadataFields: {'contactDevice'}))!;
    expect(reopened.catalog.projectMetadata.contactDevice, isNull);
  });

  test('guided publication selects typed condition Facts and scene music only', () async {
    final fixture = await _Fixture.open(savings: true, guidedMusic: true, unrelatedRecords: 80);
    addTearDown(fixture.close);
    final map = MapData(id: 'map-0', name: 'Map', size: const GridSize(width: 8, height: 8));
    final mapFile = File('${fixture.root.path}/maps/0.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final scene = SceneAsset.fromJson({
      'id': 'typed-condition-music', 'name': 'Typed condition and music',
      'graph': {'startNodeId': 'start', 'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'condition', 'kind': 'condition', 'payload': {
          'kind': 'condition', 'conditionSource': {
            'sourceKind': 'fact', 'sourceId': 'enabled', 'operator': 'equals', 'factOperator': 'equals',
            'factValueType': 'bool', 'factValue': true}}},
        {'id': 'music', 'kind': 'action', 'payload': {'kind': 'action',
          'interactiveCommand': {'kind': 'sceneMusic', 'operation': 'play',
            'mediaAssetId': 'selected-music', 'volume': 0.8}}},
        {'id': 'end', 'kind': 'end'}], 'edges': [
        {'id': 'start-edge', 'fromNodeId': 'start', 'fromPortId': 'completed', 'toNodeId': 'condition', 'kind': 'defaultFlow'},
        {'id': 'yes-edge', 'fromNodeId': 'condition', 'fromPortId': 'true', 'toNodeId': 'music', 'kind': 'conditionTrue'},
        {'id': 'no-edge', 'fromNodeId': 'condition', 'fromPortId': 'false', 'toNodeId': 'end', 'kind': 'conditionFalse'},
        {'id': 'music-edge', 'fromNodeId': 'music', 'fromPortId': 'completed', 'toNodeId': 'end', 'kind': 'actionCompleted'}]}});
    final snapshot = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
      actionId: 'narrative.publish_document', parameters: {
        'map': map.toJson(), 'scenes': [scene.toJson()]});
    expect(snapshot.manifest.facts.map((fact) => fact.id), ['enabled']);
    expect(snapshot.manifest.cinematicMediaAssets.map((media) => media.id), ['selected-music']);
    expect(snapshot.maps.map((map) => map.id), ['map-0']);
    expect(snapshot.manifest.trainers, isEmpty);
  });
  test('savings catalog scope refuses conflicting aliases before any write', () async {
    final fixture = await _Fixture.open(savings: true, ambiguousSavingsFacts: true);
    addTearDown(fixture.close);
    const config = ProjectBattleSavingsConfig(enabledFactId: 'enabled', balanceFactId: 'balance', percentage: 25, maximumBalance: 999999);
    final head = await fixture.store.readHead();
    final before = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: 'campaign.battle_savings.update', parameters: {'battleSavings': config.toJson()});
    expect(before.manifest.facts.map((fact) => fact.id), unorderedEquals(['enabled', 'balance', 'conflicting']));
    await expectLater(_applyScoped(fixture, 'campaign.battle_savings.update', {'battleSavings': config.toJson()}, 'alias-conflict'), throwsA(isA<ValidationException>()));
    expect(await fixture.store.readHead(), head);
  });
  test('savings scoped apply preserves unread maps and typed Facts on first and repeated write', () async {
    final fixture = await _Fixture.open(savings: true, unrelatedRecords: 100);
    addTearDown(fixture.close);
    for (var i = 0; i < 2; i++) {
      final config = {'enabledFactId': 'enabled', 'balanceFactId': 'balance', 'percentage': 25 + i, 'maximumBalance': 999999};
      await _applyScoped(fixture, 'campaign.battle_savings.update', {'battleSavings': config}, 'saving_$i');
      final snapshot = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
        actionId: 'campaign.battle_savings.update', parameters: {'battleSavings': config});
      expect(snapshot.manifest.battleSavings!.percentage, 25 + i);
      expect(snapshot.manifest.facts.map((f) => f.id), unorderedEquals(['enabled', 'balance']));
      expect(snapshot.maps, isEmpty);
      expect(snapshot.manifest.trainers, isEmpty);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptorBytes);
    }
  });

  test('trainer append retains unknown fields in the existing team members',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final key = CatalogMetadataDocuments.definitionKey('trainers', 0);
    final snapshot =
        (await fixture.store.openRoot((await fixture.store.readHead())!))
            .snapshot;
    final original = (await snapshot.lookup(key))!;
    final member =
        const ProjectTrainerPokemonEntry(speciesId: 'species', level: 5);
    final trainer = const ProjectTrainerEntry(
            id: 'selected', name: 'Selected', trainerClass: 'Trainer')
        .copyWith(team: [member]);
    final payload =
        jsonDecode(jsonEncode(original.payload)) as Map<String, dynamic>;
    (payload['value'] as Map)['definition'] = {
      ...trainer.toJson(),
      'futureTrainer': 'keep',
      'team': [
        {...member.toJson(), 'futureMember': 'keep'}
      ],
    };
    await _seedRawUnits(fixture, [
      CatalogDefinitionUnit(
          key: key, payload: payload, references: original.references)
    ]);
    final after = trainer.copyWith(team: [
      ...trainer.team,
      const ProjectTrainerPokemonEntry(speciesId: 'species', level: 7)
    ]);
    await _applyScoped(fixture, 'campaign.trainer.upsert',
        {'value': after.toJson()}, 'unknown_team');
    final reopened =
        (await fixture.store.openRoot((await fixture.store.readHead())!))
            .snapshot;
    final raw = (await reopened.lookup(key))!.payload['value'] as Map;
    final definition = raw['definition'] as Map;
    expect(definition['futureTrainer'], 'keep');
    expect((definition['team'] as List).length, 2);
    expect(((definition['team'] as List).first as Map)['futureMember'], 'keep');
  });

  for (final chunked in [false, true]) {
    test('ruleset edit retains unknown Pokemon fields, chunked=$chunked',
        () async {
      final fixture = await _Fixture.open();
      addTearDown(fixture.close);
      final snapshot =
          (await fixture.store.openRoot((await fixture.store.readHead())!))
              .snapshot;
      final shellKey = CatalogDefinitionKey(
          CatalogDefinitionKind.catalogMetadata, 'publication-shell');
      final shell = (await snapshot.lookup(shellKey))!;
      final payload =
          jsonDecode(jsonEncode(shell.payload)) as Map<String, dynamic>;
      final value = payload['value'] as Map;
      final pokemon = <String, Object?>{
        ...(value['pokemon'] as Map).cast<String, Object?>(),
        'futurePokemon': 'keep',
        if (chunked) 'futurePayload': 'x' * 9000
      };
      final extra = <CatalogDefinitionUnit>[];
      if (chunked) {
        final bytes = utf8.encode(jsonEncode(pokemon));
        for (final type in [
          'projectAggregateHeader',
          'projectAggregateChunk'
        ]) {
          final key = CatalogDefinitionKey(
              CatalogDefinitionKind.catalogMetadata,
              jsonEncode([type, 'pokemon', if (type.endsWith('Chunk')) 0]));
          extra.add(CatalogDefinitionUnit(key: key, payload: {
            'id': key.id,
            'section': '\$$type',
            'position': 0,
            'value': type.endsWith('Header')
                ? {
                    'field': 'pokemon',
                    'sha256': crypto.sha256.convert(bytes).toString(),
                    'byteLength': bytes.length,
                    'chunkCount': 1
                  }
                : {'field': 'pokemon', 'data': base64Encode(bytes)}
          }));
        }
        value['pokemon'] = <String, Object?>{};
      } else {
        value['pokemon'] = pokemon;
      }
      await _seedRawUnits(fixture, [
        CatalogDefinitionUnit(
            key: shell.key, payload: payload, references: shell.references),
        ...extra
      ]);
      await _applyScoped(
          fixture,
          'pokemon.ruleset.set',
          {'profile': PokemonRulesetProfile.standardV1.toJson()},
          'unknown_pokemon');
      final reopened =
          (await fixture.store.openRoot((await fixture.store.readHead())!))
              .snapshot;
      final storedShell =
          (await reopened.lookup(shellKey))!.payload['value'] as Map;
      Map raw = storedShell['pokemon'] as Map;
      final headerKey = CatalogDefinitionKey(
          CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectAggregateHeader', 'pokemon']));
      final header = await reopened.lookup(headerKey);
      if (header != null) {
        final count = (header.payload['value'] as Map)['chunkCount'] as int;
        final bytes = <int>[];
        for (var i = 0; i < count; i++) {
          final key = CatalogDefinitionKey(
              CatalogDefinitionKind.catalogMetadata,
              jsonEncode(['projectAggregateChunk', 'pokemon', i]));
          final chunk = (await reopened.lookup(key))!;
          bytes.addAll(
              base64Decode((chunk.payload['value'] as Map)['data'] as String));
        }
        raw = jsonDecode(utf8.decode(bytes)) as Map;
      }
      expect(raw['futurePokemon'], 'keep');
      if (chunked) expect(raw['futurePayload'], 'x' * 9000);
      expect((raw['ruleset'] as Map)['profileId'],
          PokemonRulesetProfile.standardV1.profileId);
    });
  }

  test('bag save uses only its own metadata and leaves foreign maps unread',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    const parameters = <String, Object?>{
      'pockets': {
        'items': {'maxDistinctItems': 30}
      }
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'bag.capacity.set',
        parameters: parameters);
    expect(snapshot.maps, isEmpty);
    expect(snapshot.manifest.trainers, isEmpty);
    expect(snapshot.manifest.maps, isEmpty);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'bag',
            actionId: 'bag.capacity.set',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'bag',
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: plan.planId, operationId: 'bag');
    final after = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'bag.capacity.set',
        parameters: parameters);
    expect(after.manifest.bagCapacity.pockets['items']!.maxDistinctItems, 30);
  });

  for (final unrelated in [
    0,
    const bool.fromEnvironment('AVELUNE_LOCAL_900') ? 900 : 9
  ]) {
    test(
        'trainer and shop updates preserve $unrelated unrelated same-field records',
        () async {
      final fixture = await _Fixture.open(unrelatedRecords: unrelated);
      addTearDown(fixture.close);
      for (var repeat = 0; repeat < 2; repeat++) {
        for (final field in ['trainers', 'shops']) {
          final action = field == 'trainers'
              ? 'campaign.trainer.upsert'
              : 'campaign.shop.upsert';
          final value = field == 'trainers'
              ? const ProjectTrainerEntry(
                      id: 'selected', name: 'Selected', trainerClass: 'Trainer')
                  .copyWith(name: 'Updated $repeat')
                  .toJson()
              : ShopDefinition(id: 'selected', label: 'Updated $repeat')
                  .toJson();
          final parameters = <String, Object?>{'value': value};
          final snapshot = await fixture.api.readWorkshopSnapshot(
              fixture.opened.projectHandle,
              actionId: action,
              parameters: parameters);
          expect(
              field == 'trainers'
                  ? snapshot.manifest.trainers.length
                  : snapshot.manifest.shops.length,
              1);
          expect(snapshot.maps, isEmpty);
          final operation = '$field-$repeat';
          final plan = await fixture.api.planMutation(
              fixture.opened.projectHandle,
              AuthoringRequest(
                  requestId: operation,
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: fixture.opened.workspaceHandle.value,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: operation,
                  parameters: parameters,
                  extensions: const {'workshopScope': true}));
          await fixture.api.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: operation);
        }
      }
      final reopened = (await CatalogProjectReader.open(
          store: fixture.store,
          descriptor: fixture.working.descriptor.toJson(),
          metadataFields: {'trainers', 'shops'}))!;
      expect(reopened.catalog.projectMetadata.trainers.length, unrelated + 1);
      expect(reopened.catalog.projectMetadata.trainers.first.name, 'Updated 1');
      expect(reopened.catalog.projectMetadata.shops.length, unrelated + 1);
      expect(reopened.catalog.projectMetadata.shops.first.label, 'Updated 1');
    }, timeout: const Timeout(Duration(minutes: 2)));
  }

  test('scoped scenes retain party move catalog validation', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final moves = File('${fixture.root.path}/data/pokemon/catalogs/moves.json');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'entries': [
        {'id': 'tackle', 'name': 'Tackle'}
      ]
    }));
    final scene = SceneAsset(
        id: 'party_scene',
        name: 'Party scene',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                  conditionSource:
                      SceneConditionSource.partyKnowsMove(moveId: 'tackle'))),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'entry',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'condition',
              kind: SceneEdgeKind.defaultFlow),
          SceneEdge(
              id: 'yes',
              fromNodeId: 'condition',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue),
          SceneEdge(
              id: 'no',
              fromNodeId: 'condition',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse),
        ]));
    final parameters = {'scene': scene.toJson()};
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'scene.upsert',
        parameters: parameters);
    expect(snapshot.hasResource('pokemonCatalog:moves'), isTrue);
    await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'party',
            actionId: 'scene.upsert',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'party',
            parameters: parameters,
            extensions: const {'workshopScope': true}));
  });

  test('scoped map dependencies keep canonical structural validation',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final mapFile = File('${fixture.root.path}/maps/0.json');
    await mapFile.parent.create(recursive: true);
    final map = MapData(
        id: 'map-0',
        name: 'Invalid map',
        size: const GridSize(width: 8, height: 8),
        tilesetId: 'unused-0',
        layers: const [
          ObjectLayer(id: 'duplicate', name: 'First'),
          ObjectLayer(id: 'duplicate', name: 'Second')
        ]);
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    await expectLater(
        fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
            actionId: 'regionalMap.poi.upsert',
            parameters: const {
              'poi': {
                'mapIds': ['map-0']
              }
            }),
        throwsA(isA<ValidationException>()));
  });

  test(
      'a changed scoped dependency prevents publication without overwriting it',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final dependency = File('${fixture.root.path}/data/dependency.json');
    await dependency.parent.create(recursive: true);
    await dependency.writeAsString('{"value":1}');
    final dependencies = {'dependency': 'data/dependency.json'};
    final parameters = {
      'facts': [
        NarrativeFactDefinition(id: 'fact_guarded', label: 'Guarded').toJson()
      ]
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'fact.create_batch',
        parameters: parameters,
        readDependencies: dependencies);
    final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'guarded',
            actionId: 'fact.create_batch',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'guarded',
            parameters: parameters,
            extensions: {
              'workshopScope': true,
              'workshopReadDependencies': dependencies
            }));
    final before = await fixture.store.readHead();
    await dependency.writeAsString('{"value":2}');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: planned.planId, operationId: 'guarded'),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
    expect(await fixture.store.readHead(), before);
    expect(await dependency.readAsString(), '{"value":2}');
  });

  test('scoped recovery publishes the retained receipt without a full snapshot',
      () async {
    var crashed = false;
    final fixture = await _Fixture.open(faultInjector: (checkpoint) {
      if (!crashed &&
          checkpoint.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(fixture.close);
    final parameters = {
      'facts': [
        NarrativeFactDefinition(id: 'fact_recovered', label: 'Recovered')
            .toJson()
      ]
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'fact.create_batch',
        parameters: parameters);
    final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'recovered',
            actionId: 'fact.create_batch',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'recovered',
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: planned.planId, operationId: 'recovered'),
        throwsA(anything));
    expect(crashed, isTrue);
    final result = await fixture.api.recoverMutation(
        fixture.opened.projectHandle,
        operationId: 'recovered');
    final after = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'fact.create_batch',
        parameters: parameters);
    expect(after.manifest.facts.single.id, 'fact_recovered');
    expect(result.snapshotRevision, after.revision);
  });

  test(
      'Pokemon document writes guard exact files without loading the inventory',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final parameters = <String, Object?>{
      'documents': [
        {
          'actionId': 'pokemon.evolution.write',
          'parameters': {
            'relativePath': 'data/pokemon/evolutions/selected.json',
            'document': {
              'schemaVersion': 1,
              'speciesId': 'selected',
              'evolutions': []
            },
          }
        },
      ]
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'pokemon.documents.write',
        parameters: parameters);
    final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'pokemon',
            actionId: 'pokemon.documents.write',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'pokemon',
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: planned.planId, operationId: 'pokemon');
    final after = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'pokemon.documents.write',
        parameters: parameters);
    expect(result.snapshotRevision, after.revision);
    expect(
        jsonDecode(utf8.decode(after.resourceBytes(
            'pokemonEvolution:data/pokemon/evolutions/selected.json'))),
        PokemonEvolutionFile.fromJson(
                {'schemaVersion': 1, 'speciesId': 'selected', 'evolutions': []})
            .toJson());
  });

  test(
      'scoped publication and receipt lookup leave unrelated legacy history unread',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final historyFile =
        File('${fixture.root.path}/.pokemap/authoring/history.jsonl');
    await historyFile.parent.create(recursive: true);
    await historyFile.writeAsString('unrelated legacy history\n');
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'fact.create_batch');
    final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'history',
            actionId: 'fact.create_batch',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'history',
            parameters: {
              'facts': [
                NarrativeFactDefinition(id: 'fact_history', label: 'History')
                    .toJson()
              ]
            },
            extensions: const {
              'workshopScope': true
            }));
    final result = await fixture.api.applyMutation(fixture.opened.projectHandle,
        planId: planned.planId, operationId: 'history');
    var fullReads = 0;
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: fixture.root.path, onFullRead: () => fullReads++);
    final receipt = await history.get(
        projectId: 'scoped-workshops', entryId: result.receipt.receiptId);
    expect(receipt!.receipt.actionId, 'fact.create_batch');
    expect(fullReads, 0);
    expect(await historyFile.readAsString(), 'unrelated legacy history\n');
  });

  test('ordinary narrative workshops publish without unrelated map files',
      () async {
    final fixture = await _Fixture.open(playerCharacters: true);
    addTearDown(fixture.close);
    final scene = SceneAsset(
        id: 'selected_scene',
        name: 'Selected scene',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'flow',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow)
        ]));
    final cinematic = CinematicAsset(
        id: 'selected_cinematic',
        title: 'Selected',
        timeline: CinematicTimeline(steps: [
          CinematicTimelineStep(
              id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 100)
        ]));
    final storyline = StorylineAsset(
        id: 'selected_story',
        type: StorylineType.main,
        title: 'Selected story');
    final entry = ProjectDialogueEntry(
        id: 'selected_dialogue',
        name: 'Selected dialogue',
        relativePath: 'dialogues/selected.yarn');
    final mapFile = File('${fixture.root.path}/maps/0.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(MapData(
        id: 'map-0',
        name: 'Selected map',
        size: const GridSize(width: 8, height: 8),
        tilesetId: 'unused-0',
        layers: const [ObjectLayer(id: 'objects', name: 'Objects')]).toJson()));
    final operations = <(String, Map<String, Object?>)>[
      ('scene.upsert', {'scene': scene.toJson()}),
      ('cinematic.upsert', {'cinematic': cinematic.toJson()}),
      ('storyline.upsert', {'storyline': storyline.toJson()}),
      (
        'event_v2.record_upsert',
        {
          'record': {
            'state': 'configured',
            'enabled': false,
            'definition': {
              'id': 'evt_019abcde-0000-7000-8000-000000000001',
              'name': 'Enter selected map',
              'source': {'kind': 'mapEnter', 'mapId': 'map-0'},
              'conditions': <Object?>[],
              'sceneId': scene.id,
              'reusePolicy': 'reusable',
              'priority': 0,
              'order': 0,
            },
          }
        }
      ),
      ('event_v2.registry_mode.set', {'mode': 'dualRead'}),
      (
        'dialogue.create',
        {'entry': entry.toJson(), 'source': 'title: Start\n---\nHello\n===\n'}
      ),
      (
        'dialogue.source_update',
        {'dialogueId': entry.id, 'source': 'title: Start\n---\nUpdated\n===\n'}
      ),
    ];
    for (var index = 0; index < operations.length; index++) {
      final (action, parameters) = operations[index];
      final snapshot = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      if (action == 'event_v2.record_upsert') {
        expect(snapshot.maps.map((map) => map.id), ['map-0']);
      } else {
        expect(snapshot.maps, isEmpty);
      }
      expect(snapshot.availableProjectSections, isNotNull);
      expect(snapshot.manifest.characters.map((entry) => entry.id),
          contains('guide'));
      if (action.startsWith('dialogue.')) {
        expect(snapshot.manifest.characters.map((entry) => entry.id),
            contains('avatar'));
      }
      final operation = 'workshop_$index';
      final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true}),
      );
      final result = await fixture.api.applyMutation(
          fixture.opened.projectHandle,
          planId: planned.planId,
          operationId: operation);
      final after = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      expect(result.snapshotRevision, after.revision);
    }
    expect(
        await File('${fixture.root.path}/dialogues/selected.yarn')
            .readAsString(),
        contains('Updated'));
    await expectLater(
        fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
            actionId: 'event_v2.registry_mode.set',
            parameters: const {'mode': 'v2Only'}),
        throwsA(isA<AuthoringPlanException>().having(
            (error) => error.code, 'code', 'catalog.mutation_scope_required')));
  });

  test('first and repeated fact publications ignore unrelated maps and assets',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    for (var index = 0; index < 2; index++) {
      final reader = (await CatalogProjectReader.open(
        store: fixture.store,
        descriptor: fixture.working.descriptor.toJson(),
        metadataFields: {},
      ))!;
      final operation = 'create_$index';
      final planned = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: 'fact.create_batch',
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision: reader.revision,
          idempotencyKey: operation,
          extensions: const {'workshopScope': true},
          parameters: {
            'facts': [
              NarrativeFactDefinition(
                id: 'fact_selected_$index',
                label: 'Selected $index',
              ).toJson(),
            ],
          },
        ),
      );
      expect(planned.plan.changeSet.changes.map((c) => c.storageKey),
          ['catalog/HEAD.json']);
      final result = await fixture.api.applyMutation(
        fixture.opened.projectHandle,
        planId: planned.planId,
        operationId: operation,
      );
      expect(result.snapshotRevision, isNotNull);
      final reopened = (await CatalogProjectReader.open(
        store: fixture.store,
        descriptor: fixture.working.descriptor.toJson(),
        metadataFields: {'facts'},
      ))!;
      expect(reopened.catalog.projectMetadata.facts.length, index + 1);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptorBytes);
    }
  });

  test('fact deletion fails closed without an incoming reference proof',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final reader = (await CatalogProjectReader.open(
      store: fixture.store,
      descriptor: fixture.working.descriptor.toJson(),
      metadataFields: {},
    ))!;
    await expectLater(
      fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
          requestId: 'delete',
          actionId: 'fact.delete',
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision: reader.revision,
          idempotencyKey: 'delete',
          parameters: const {'factId': 'unknown'},
          extensions: const {'workshopScope': true},
        ),
      ),
      throwsA(isA<AuthoringPlanException>().having(
          (error) => error.code, 'code', 'catalog.mutation_scope_required')),
    );
  });
}

Future<void> _seedRawUnits(
    _Fixture fixture, List<CatalogDefinitionUnit> units) async {
  await fixture.api.detachWorkspace(fixture.opened.workspaceHandle);
  final editing = await CatalogEditingSession.open(
      store: fixture.store,
      projectId: 'scoped-workshops',
      actorId: 'seed_unknown',
      incrementalHistory: true);
  try {
    final plan =
        await editing.planPatch(upserts: units, idempotencyKey: 'seed_unknown');
    await editing.apply(plan);
  } finally {
    await editing.close();
  }
  await fixture.api.attachProject(
      projectRootPath: fixture.root.path,
      workspaceHandle: fixture.opened.workspaceHandle,
      projectHandle: fixture.opened.projectHandle);
}

Future<void> _applyScoped(_Fixture fixture, String action,
    Map<String, Object?> parameters, String operation) async {
  final snapshot = await fixture.api.readWorkshopSnapshot(
      fixture.opened.projectHandle,
      actionId: action,
      parameters: parameters);
  final plan = await fixture.api.planMutation(
      fixture.opened.projectHandle,
      AuthoringRequest(
          requestId: operation,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: fixture.opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: parameters,
          extensions: const {'workshopScope': true}));
  await fixture.api.applyMutation(fixture.opened.projectHandle,
      planId: plan.planId, operationId: operation);
}

final class _Fixture {
  _Fixture(this.root, this.store, this.working, this.opened, this.handles,
      this.api, this.descriptorBytes);
  final Directory root;
  final CatalogStorageStore store;
  final WorkingProjectCatalog working;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;
  final List<int> descriptorBytes;

  static Future<_Fixture> open(
      {AuthoringTransactionFaultInjector? faultInjector,
      bool playerCharacters = false,
      bool savings = false,
      bool contacts = false,
      bool guidedMusic = false,
      bool ambiguousSavingsFacts = false,
      int unrelatedRecords = 0}) async {
    final qaRoot = Directory('/Users/karim/Library/Caches/AveluneQA/battle-savings');
    if (savings) await qaRoot.create(recursive: true);
    final root = savings ? await qaRoot.createTemp('catalog-') : await Directory.systemTemp.createTemp('scoped-workshops-');
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'scoped-workshops',
      project: ProjectManifest(
        name: 'Scoped workshops',
        facts: savings ? [
          NarrativeFactDefinition(id: 'enabled', label: 'Enabled', legacyFlagName: ambiguousSavingsFacts ? 'shared' : null),
          if (ambiguousSavingsFacts) NarrativeFactDefinition(id: 'conflicting', label: 'Conflict', legacyFlagName: 'shared'),
          NarrativeFactDefinition(id: 'balance', label: 'Balance', initialValue: NarrativeValue.integer(0)),
        ] : [],
        cinematicMediaAssets: [if (guidedMusic) CinematicMediaAsset(id: 'selected-music', label: 'Music', kind: CinematicMediaAssetKind.music, relativePath: 'assets/music.wav', loopByDefault: true)],
        trainers: [
          const ProjectTrainerEntry(
              id: 'selected', name: 'Selected', trainerClass: 'Trainer'),
          for (var i = 0; i < unrelatedRecords; i++)
            ProjectTrainerEntry(
                id: 'other-$i', name: 'Other $i', trainerClass: 'Trainer')
        ],
        shops: [
          const ShopDefinition(id: 'selected', label: 'Selected'),
          for (var i = 0; i < unrelatedRecords; i++)
            ShopDefinition(id: 'other-$i', label: 'Other $i')
        ],
        version: contacts ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: contacts
            ? ProjectSettings(dimension: ProjectDimension.threeD, spatialCamera: SpatialCameraProfile())
            : playerCharacters
            ? const ProjectSettings(defaultPlayerCharacterId: 'guide')
            : const ProjectSettings(),
        newGame: ProjectNewGameConfig(
            enabled: playerCharacters,
            startMapId: playerCharacters ? 'map-0' : '',
            playerAvatarCharacterIds: playerCharacters ? ['avatar'] : []),
        characters: [
          if (playerCharacters) ...const [
            ProjectCharacterEntry(
                id: 'guide', name: 'Guide', tilesetId: 'unused-0'),
            ProjectCharacterEntry(
                id: 'avatar', name: 'Avatar', tilesetId: 'unused-1'),
          ]
        ],
        maps: [
          for (var index = 0; index < 90; index++)
            ProjectMapEntry(
                id: 'map-$index',
                name: 'Map $index',
                relativePath: 'maps/$index.json'),
        ],
        tilesets: [
          for (var index = 0; index < 250; index++)
            ProjectTilesetEntry(
                id: 'unused-$index',
                name: 'Unused $index',
                relativePath: 'assets/$index.png'),
        ],
        globalProperties: {'unrelated': 'x' * 120000},
      ),
    );
    final unused = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'unused-249')))!;
    await File('${root.path}/catalog/objects/${unused.reference.sha256}.json')
        .writeAsString('unrelated resource must not be decoded');
    final descriptorBytes =
        await File('${root.path}/project.json').readAsBytes();
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      faultInjector: faultInjector,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(
        root, store, working, opened, handles, api, descriptorBytes);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
