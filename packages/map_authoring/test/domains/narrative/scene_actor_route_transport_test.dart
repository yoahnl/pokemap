import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SceneAsset _scene(String id, SceneInteractiveCommand command) => SceneAsset(
      id: id,
      name: id,
      metadata: const {'keep': 'metadata'},
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'action',
            kind: SceneNodeKind.action,
            title: 'Keep title',
            description: 'Keep description',
            payload: SceneActionPayload.interactive(
              command,
              actionKind: 'keep-action',
              parameters: const {'keep': 'parameter'},
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          for (final port in ['completed', 'blocked'])
            SceneEdge(
              id: port,
              fromNodeId: 'action',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );

Map<String, dynamic> _target({String mapId = 'map', String? entityId}) => {
      'kind': entityId == null ? 'player' : 'entity',
      'mapId': mapId,
      if (entityId != null) 'entityId': entityId,
    };
Map<String, dynamic> _route({
  Map<String, dynamic>? target,
  String mediaId = 'door',
  String? initialCollisionOwnerEntityId,
}) =>
    {
      'kind': 'actorRoute',
      'target': target ?? _target(entityId: 'actor'),
      'steps': [
        {'kind': 'face', 'direction': 'south', 'durationMs': 50, 'yieldAfter': true},
        {
          'kind': 'move',
          'direction': 'south',
          'durationMs': 200,
          if (initialCollisionOwnerEntityId != null)
            'initialCollisionOwnerEntityId': initialCollisionOwnerEntityId,
        },
        {'kind': 'visibility', 'visible': false},
        {'kind': 'wait', 'durationMs': 50},
        {'kind': 'visibility', 'visible': true},
        {'kind': 'through', 'enabled': true},
        {'kind': 'sound', 'mediaAssetId': mediaId, 'gain': 0.8},
      ],
      'skippable': false,
    };
Map<String, dynamic> _visibility({Map<String, dynamic>? target}) => {
      'kind': 'actorVisibility',
      'target': target ?? _target(entityId: 'actor'),
      'visible': false,
    };

ProjectCharacterEntry _character() => ProjectCharacterEntry(
      id: 'actor-character',
      name: 'Original QA actor',
      tilesetId: 'actor-sheet',
      frameHeight: 1,
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: direction,
              frames: const [
                CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0))
              ]),
      ],
    );

const _actor = MapEntity(
    id: 'actor',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 0, y: 0),
    npc: MapEntityNpcData(characterId: 'actor-character'));
const _trainer = ProjectTrainerEntry(
    id: 'actor-trainer',
    name: 'Original QA trainer',
    trainerClass: 'QA',
    characterId: 'actor-character');

MapEntity _conditionalActor({bool missing = false}) => MapEntity(
    id: 'actor', kind: MapEntityKind.custom, pos: const GridPos(x: 0, y: 0),
    presentation: MapEntityPresentation(variants: [
      for (final (index, id) in <String?>[
        'actor-character', missing ? 'missing-character' : 'second-character', null
      ].indexed)
        MapEntityPresentationVariant(id: 'variant_$index',
          condition: NarrativeEventConditionExpression.all(const []),
          characterId: id, blocksMovement: id != null),
    ]));

void main() {
  for (final jsonl in [false, true]) {
    for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      test('conditional actor variants survive $action transport jsonl=$jsonl and reopen', () async {
        final f = await _Fixture.create(entities: [
          _conditionalActor(),
        ], characters: [_character(), _character().copyWith(id: 'second-character')]);
        addTearDown(f.dispose);
        final mapBefore = await f.mapFile.readAsBytes();
        for (final wire in [_route(), _visibility()]) {
          final request = await f.actionRequest(action, wire);
          final planned = jsonl
              ? await f.success('plan', {'projectHandle': f.project.value, 'request': request.toJson()})
              : await f.mutations.plan(f.project, request);
          if (jsonl) {
            await f.success('apply', {'projectHandle': f.project.value,
              'planId': planned['planId'], 'operationId': '${request.requestId}-apply'});
          } else {
            await f.mutations.apply(f.project, planId: planned['planId']! as String,
              operationId: '${request.requestId}-apply');
          }
          final scene = (await f.snapshot()).manifest.scenes.singleWhere((scene) => scene.id == 'edit');
          expect((scene.graph.nodes.singleWhere((node) => node.id == 'action').payload as SceneActionPayload)
              .interactiveCommand!.toJson(), wire);
        }
        final manifestBefore = await f.projectFile.readAsBytes();
        await f.success('close', {'workspaceHandle': f.workspace.value});
        await f.open();
        expect(await f.projectFile.readAsBytes(), manifestBefore);
        expect(await f.mapFile.readAsBytes(), mapBefore);
        expect((await f.snapshot()).maps.singleWhere((map) => map.id == 'map').entities.single.npc, isNull);
      });
    }
    test('conditional actor unknown characters refuse transport jsonl=$jsonl before writes', () async {
      final f = await _Fixture.create(entities: [_conditionalActor(missing: true)]);
      addTearDown(f.dispose);
      final bytes = await f.projectFile.readAsBytes();
      final request = await f.actionRequest('scene.upsert', _route());
      if (jsonl) {
        final result = await f.command('plan', {'projectHandle': f.project.value,
          'request': request.toJson()});
        expect(result.status, AuthoringResultStatus.failure);
        expect(result.error!.details['domainCode'], 'scene.publication_blocked');
      } else {
        await expectLater(f.mutations.plan(f.project, request), throwsA(isA<NarrativeAuthoringException>()));
      }
      expect(await f.projectFile.readAsBytes(), bytes);
    });
  }

  test('canonical actions describe optional face update yield', () {
    for (final id in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      final route = SceneActions.descriptors.singleWhere((d) => d.id == id)
          .extensions['actorRoute'] as Map;
      expect((route['stepFields'] as Map)['face'],
          ['kind', 'direction', 'durationMs', 'yieldAfter']);
      expect((route['stepOptionalFields'] as Map)['face'], ['durationMs', 'yieldAfter']);
      expect(route['defaultFaceYieldAfter'], isFalse);
      expect(route['faceYieldCompletion'], 'nextUpdateBeforeHold');
    }
  });

  test('sparse Scene upsert input matches the real MCP request with an initial owner', () async {
    final f = await _Fixture.create(entities: const [
      MapEntity(id: 'trainer-actor', kind: MapEntityKind.npc, pos: GridPos(x: 0, y: 0),
        npc: MapEntityNpcData(trainerId: 'actor-trainer')),
    ], trainers: [_trainer]);
    addTearDown(f.dispose);
    final wire = _route(target: _target(), initialCollisionOwnerEntityId: 'trainer-actor');
    final scene = <String, dynamic>{
      'id': 'edit', 'name': 'edit', 'metadata': {'keep': 'metadata'},
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {'id': 'action', 'kind': 'action', 'title': 'Keep title', 'payload': {
            'actionKind': 'keep-action', 'parameters': {'keep': 'parameter'}, 'interactiveCommand': wire,
          }},
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': _scene('edit', SceneInteractiveCommand.fromJson(wire)).graph.edges.map((edge) => edge.toJson()).toList(),
      },
    };
    final request = AuthoringRequest(requestId: 'sparse-owner', actionId: 'scene.upsert',
      actionVersion: 1, workspaceHandle: f.workspace.value, expectedRevision: (await f.snapshot()).revision,
      idempotencyKey: 'sparse-owner', parameters: {'scene': scene});
    final planned = await f.mutations.plan(f.project, request);
    expect(planned['planId'], isNotNull);
  });

  test('all Scene mutation entrypoints describe the optional initial owner contract', () {
    for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      final descriptor = SceneActions.descriptors.singleWhere((d) => d.id == action);
      final route = descriptor.extensions['actorRoute'] as Map;
      expect((route['stepFields'] as Map)['move'],
        ['kind', 'direction', 'durationMs', 'initialCollisionOwnerEntityId']);
      expect((route['stepOptionalFields'] as Map)['move'], ['initialCollisionOwnerEntityId']);
      final owner = route['initialCollisionOwner'] as Map;
      expect(owner['status'], 'partial');
      expect(owner['targetKind'], 'player');
      expect(owner['effectiveThrough'], isFalse);
      expect(owner['reference'], 'knownUniqueNPCCharacterOnExactTargetMap');
      expect(owner['collisionFootprintSize'], [1, 1]);
      expect(owner['collisionFootprintAnchor'], 'sameAsEntityAnchor');
      expect(owner['collisionExemption'], 'initialOwnerOverlapOnly');
      expect(owner['absent'], 'ordinaryCollisionValidation');
      expect(owner['explicitNull'], 'rejected');
      expect(owner['identity'], 'canonicalNonempty');
    }
  });

  test(
      'canonical semantic action describes typed actor routes and visual visibility',
      () {
    for (final id in ['scene.interactive_command.set', 'scene.upsert']) {
      final descriptor = SceneActions.descriptors.singleWhere(
        (d) => d.id == id,
      );
      final route = descriptor.extensions['actorRoute'];
      final visibility = descriptor.extensions['actorVisibility'];
      expect(route, isA<Map>());
      expect(visibility, isA<Map>());
      expect((route as Map)['parameters'], ['target', 'steps', 'skippable', 'transientScope']);
      expect(route['stepKinds'], ['face', 'move', 'moveDiagonal', 'wait', 'through', 'renderAboveMap', 'visibility', 'sound']);
      expect((route['stepFields'] as Map)['visibility'], ['kind', 'visible']);
      expect(route['contractVersion'], 3);
      expect(route['transientScopes'], ['route', 'scene']);
      expect(route['completion'], 'routeFinished');
      expect(route['targetReference'], 'uniqueActorOnExactMap');
      expect(route['targetMapMode'], '2D');
      expect(route['entityKind'], 'npc');
      expect(route['entityCharacterReference'],
          'knownUniqueDirectOrTrainerCharacter');
      expect(route['mediaReference'], 'knownUniqueNonLoopingSound');
      expect(route['dynamicCollisionValidation'], 'runtime');
      expect(route['outputPorts'], ['completed', 'blocked']);
      expect((visibility as Map)['collisionEffect'], 'none');
      expect(visibility['targetMapMode'], '2D');
      expect(visibility['entityKind'], 'npc');
      expect(visibility['entityCharacterReference'],
          'knownUniqueDirectOrTrainerCharacter');
      expect(visibility['persistent'], isFalse);
    }
  });

  test('native sparse graph patch matches the live MCP typed request', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final request = await f.actionRequest('scene.graph.patch', _route(target: _target()));
    final node = Map<String, dynamic>.from((request.parameters['upsertNodes'] as List).single as Map);
    node.remove('description');
    final payload = Map<String, dynamic>.from(node['payload'] as Map);
    payload.remove('kind');
    node['payload'] = payload;
    final sparse = AuthoringRequest(requestId: request.requestId, actionId: request.actionId,
      actionVersion: 1, workspaceHandle: f.workspace.value, expectedRevision: request.expectedRevision,
      idempotencyKey: request.idempotencyKey, parameters: {'sceneId': 'edit', 'upsertNodes': [node]});
    await f.mutations.plan(f.project, sparse);
  });

  for (final jsonl in [false, true]) {
    for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      test('native diagonal scene scope survives $action transport jsonl=$jsonl and strict reopen', () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final wire = <String, dynamic>{
          ..._route(target: _target()), 'transientScope': 'scene',
          'steps': [
            {'kind': 'through', 'enabled': true}, {'kind': 'renderAboveMap', 'enabled': true},
            {'kind': 'moveDiagonal', 'horizontal': 'east', 'vertical': 'north', 'durationMs': 250},
            {'kind': 'through', 'enabled': false}, {'kind': 'renderAboveMap', 'enabled': false},
          ],
        };
        final mapBefore = await f.mapFile.readAsBytes();
        final request = await f.actionRequest(action, wire);
        final planned = jsonl
          ? await f.success('plan', {'projectHandle': f.project.value, 'request': request.toJson()})
          : await f.mutations.plan(f.project, request);
        if (jsonl) {
          await f.success('apply', {'projectHandle': f.project.value, 'planId': planned['planId'], 'operationId': '${request.requestId}-apply'});
        } else {
          await f.mutations.apply(f.project, planId: planned['planId']! as String, operationId: '${request.requestId}-apply');
        }
        await f.success('close', {'workspaceHandle': f.workspace.value});
        await f.open();
        final scene = (await f.snapshot()).manifest.scenes.singleWhere((scene) => scene.id == 'edit');
        final payload = scene.graph.nodes.singleWhere((node) => node.id == 'action').payload as SceneActionPayload;
        expect(payload.interactiveCommand!.toJson(), wire);
        expect(await f.mapFile.readAsBytes(), mapBefore);
      });
    }
  }

  for (final jsonl in [false, true]) {
    final label = jsonl ? 'JSONL' : 'direct API';
    for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
      test('$label $action preserves the optional initial owner through cold reopen', () async {
        final f = await _Fixture.create(entities: [
          _actor,
          const MapEntity(id: 'trainer-actor', kind: MapEntityKind.npc, pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(trainerId: 'actor-trainer')),
          _actor.copyWith(id: 'anchored-tall', size: const GridSize(width: 1, height: 2),
            properties: {'collision.height': '1', 'collision.offsetY': '0'}),
        ], trainers: [_trainer]);
        addTearDown(f.dispose);
        final draft = (await f.snapshot()).manifest.scenes.singleWhere((s) => s.id == 'unrelated-draft');
        final mapBefore = await f.mapFile.readAsBytes();
        for (final owner in ['actor', 'trainer-actor', 'anchored-tall']) {
          final wire = _route(target: _target(), initialCollisionOwnerEntityId: owner);
          final before = await f.projectFile.readAsBytes();
          final request = await f.actionRequest(action, wire);
          final planned = jsonl
            ? await f.success('plan', {'projectHandle': f.project.value, 'request': request.toJson()})
            : await f.mutations.plan(f.project, request);
          expect(await f.projectFile.readAsBytes(), before);
          expect(await f.mapFile.readAsBytes(), mapBefore);
          if (jsonl) {
            await f.success('apply', {'projectHandle': f.project.value,
              'planId': planned['planId'], 'operationId': '${request.requestId}-apply'});
          } else {
            await f.mutations.apply(f.project, planId: planned['planId']! as String,
              operationId: '${request.requestId}-apply');
          }
          final snapshot = await f.snapshot();
          final scene = snapshot.manifest.scenes.singleWhere((s) => s.id == 'edit');
          final node = scene.graph.nodes.singleWhere((n) => n.id == 'action');
          final payload = node.payload as SceneActionPayload;
          expect(payload.interactiveCommand!.toJson(), wire);
          expect(payload.actionKind, 'keep-action');
          expect(payload.parameters, {'keep': 'parameter'});
          expect(node.title, 'Keep title');
          expect(node.description, 'Keep description');
          expect(scene.metadata, {'keep': 'metadata'});
          expect(snapshot.manifest.scenes.singleWhere((s) => s.id == 'unrelated-draft'), draft);
          final edge = ProjectReferenceIndex.fromSnapshot(snapshot).edges
            .singleWhere((e) => e.owner.id == 'edit' && e.path.endsWith('.steps[1].initialCollisionOwnerEntityId'));
          expect(edge.target.id, owner);
          expect(edge.resolution, NarrativeDependencyResolution.resolved);
          expect(await f.mapFile.readAsBytes(), mapBefore);
        }
        final bytes = await f.projectFile.readAsBytes();
        await f.success('close', {'workspaceHandle': f.workspace.value});
        await f.open();
        expect(await f.projectFile.readAsBytes(), bytes);
        final scene = (await f.snapshot()).manifest.scenes.singleWhere((s) => s.id == 'edit');
        expect(((scene.graph.nodes.singleWhere((n) => n.id == 'action').payload as SceneActionPayload)
          .interactiveCommand! as SceneActorRouteInteractiveCommand).steps[1].toJson()
          ['initialCollisionOwnerEntityId'], 'anchored-tall');
      });

      test('$label $action rejects invalid initial owner before writes', () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final mapBefore = await f.mapFile.readAsBytes();
        final ownerRoute = _route(target: _target(), initialCollisionOwnerEntityId: 'actor');
        final invalid = <Map<String, dynamic>>[
          _route(target: _target(), initialCollisionOwnerEntityId: 'missing'),
          _route(target: _target(mapId: 'other'), initialCollisionOwnerEntityId: 'actor'),
          _route(initialCollisionOwnerEntityId: 'actor'),
          for (final owner in <Object?>[null, '', ' actor', 'actor ', true])
            {...ownerRoute, 'steps': [
              {'kind': 'move', 'direction': 'south', 'durationMs': 200,
                'initialCollisionOwnerEntityId': owner},
            ]},
          {...ownerRoute, 'steps': [
            {'kind': 'through', 'enabled': true},
            {'kind': 'move', 'direction': 'south', 'durationMs': 200,
              'initialCollisionOwnerEntityId': 'actor'},
          ]},
          {...ownerRoute, 'steps': [
            {'kind': 'move', 'direction': 'south', 'durationMs': 200,
              'initialCollisionOwnerEntityId': 'actor', 'unknown': true},
          ]},
          {...ownerRoute, 'steps': [
            {'kind': 'face', 'direction': 'south', 'durationMs': 50,
              'initialCollisionOwnerEntityId': 'actor'},
          ]},
        ];
        for (final wire in invalid) {
          final before = await f.projectFile.readAsBytes();
          final request = await f.actionRequest(action, wire);
          if (jsonl) {
            final result = await f.command('plan', {'projectHandle': f.project.value,
              'request': request.toJson()});
            expect(result.status, AuthoringResultStatus.failure, reason: jsonEncode(wire));
          } else {
            await expectLater(f.mutations.plan(f.project, request),
              throwsA(isA<NarrativeAuthoringException>()), reason: jsonEncode(wire));
          }
          expect(await f.projectFile.readAsBytes(), before);
          expect(await f.mapFile.readAsBytes(), mapBefore);
        }
      });
    }

    test('$label initial owner rejects incompatible and ambiguous references on every entrypoint', () async {
      for (final entities in <List<MapEntity>>[
        const [MapEntity(id: 'actor', kind: MapEntityKind.sign, pos: GridPos(x: 0, y: 0))],
        const [MapEntity(id: 'actor', kind: MapEntityKind.npc, pos: GridPos(x: 0, y: 0))],
        const [MapEntity(id: 'actor', kind: MapEntityKind.npc, pos: GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(characterId: 'missing'))],
        const [_actor, _actor],
        [_actor.copyWith(size: const GridSize(width: 2, height: 1))],
        [_actor.copyWith(size: const GridSize(width: 1, height: 2))],
        [_actor.copyWith(size: const GridSize(width: 2, height: 1),
          properties: {'collision.width': '1', 'collision.offsetX': '1'})],
        [_actor.copyWith(size: const GridSize(width: 1, height: 2),
          properties: {'collision.height': '2'})],
      ]) {
        final f = await _Fixture.create(entities: entities);
        try {
          for (final action in ['scene.interactive_command.set', 'scene.upsert', 'scene.graph.patch']) {
            final before = await f.projectFile.readAsBytes();
            final mapBefore = await f.mapFile.readAsBytes();
            final request = await f.actionRequest(action,
              _route(target: _target(), initialCollisionOwnerEntityId: 'actor'));
            if (jsonl) {
              final result = await f.command('plan', {'projectHandle': f.project.value,
                'request': request.toJson()});
              expect(result.status, AuthoringResultStatus.failure, reason: action);
              expect(result.error!.details['domainCode'], 'scene.publication_blocked');
            } else {
              await expectLater(f.mutations.plan(f.project, request),
                throwsA(isA<NarrativeAuthoringException>()));
            }
            expect(await f.projectFile.readAsBytes(), before);
            expect(await f.mapFile.readAsBytes(), mapBefore);
          }
        } finally {
          await f.dispose();
        }
      }
    });

    test(
      '$label actor commands preserve structured steps and metadata then cold reopen',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final initial = await f.snapshot();
        final draft = initial.manifest.scenes.singleWhere(
          (s) => s.id == 'unrelated-draft',
        );
        final mapBefore = await f.mapFile.readAsBytes();
        final otherBefore =
            await File('${f.directory.path}/maps/other.json').readAsBytes();
        for (final wire in [
          _route(),
          _route(target: _target()),
          _visibility(),
        ]) {
          final before = await f.projectFile.readAsBytes();
          final request = await f.request(wire);
          final planned = jsonl
              ? await f.success('plan', {
                  'projectHandle': f.project.value,
                  'request': request.toJson(),
                })
              : await f.mutations.plan(f.project, request);
          expect(await f.projectFile.readAsBytes(), before);
          expect(await f.mapFile.readAsBytes(), mapBefore);
          if (jsonl) {
            await f.success('apply', {
              'projectHandle': f.project.value,
              'planId': planned['planId'],
              'operationId': '${request.requestId}-apply',
            });
          } else {
            await f.mutations.apply(
              f.project,
              planId: planned['planId']! as String,
              operationId: '${request.requestId}-apply',
            );
          }
          final after = await f.snapshot();
          final scene = after.manifest.scenes.singleWhere(
            (s) => s.id == 'edit',
          );
          final node = scene.graph.nodes.singleWhere((n) => n.id == 'action');
          final payload = node.payload as SceneActionPayload;
          expect(payload.interactiveCommand!.toJson(), wire);
          expect(payload.actionKind, 'keep-action');
          expect(payload.parameters, {'keep': 'parameter'});
          expect(node.title, 'Keep title');
          expect(node.description, 'Keep description');
          expect(scene.metadata, {'keep': 'metadata'});
          expect(
            after.manifest.scenes.singleWhere((s) => s.id == 'unrelated-draft'),
            draft,
          );
          expect(await f.mapFile.readAsBytes(), mapBefore);
          expect(
            await File('${f.directory.path}/maps/other.json').readAsBytes(),
            otherBefore,
          );
        }
        final snapshot = await f.snapshot();
        final edges = ProjectReferenceIndex.fromSnapshot(snapshot)
            .edges
            .where((e) => e.owner.id == 'edit')
            .toList();
        expect(edges.any((e) => e.path.endsWith('.target.mapId')), isTrue);
        expect(edges.any((e) => e.path.endsWith('.target.entityId')), isTrue);
        expect(
          edges.every(
            (e) => e.resolution == NarrativeDependencyResolution.resolved,
          ),
          isTrue,
        );
        final bytes = await f.projectFile.readAsBytes();
        await f.success('close', {'workspaceHandle': f.workspace.value});
        await f.open();
        expect((await f.snapshot()).revision, snapshot.revision);
        expect(await f.projectFile.readAsBytes(), bytes);
        final query = await f.success('query', {
          'projectHandle': f.project.value,
          'request': AuthoringQueryRequest(
            resourceKind: 'scene',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['edit'],
          ).toJson(),
        });
        expect(jsonEncode(query), contains('actorVisibility'));
      },
    );

    test(
      '$label refuses wrong-map actors and ambiguous or incompatible route sounds before writes',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        for (final wire in [
          _route(target: _target(mapId: 'missing')),
          _route(target: _target(entityId: 'missing')),
          _route(
            target: _target(mapId: 'other', entityId: 'actor'),
          ),
          _visibility(target: _target(entityId: 'missing')),
          for (final media in ['missing', 'music', 'fx', 'loop', 'ambiguous'])
            _route(mediaId: media),
        ]) {
          final before = await f.projectFile.readAsBytes();
          final request = await f.request(wire);
          if (jsonl) {
            final result = await f.command('plan', {
              'projectHandle': f.project.value,
              'request': request.toJson(),
            });
            expect(
              result.status,
              AuthoringResultStatus.failure,
              reason: jsonEncode(wire),
            );
            expect(
              result.error!.details['domainCode'],
              'scene.publication_blocked',
            );
          } else {
            await expectLater(
              f.mutations.plan(f.project, request),
              throwsA(
                isA<NarrativeAuthoringException>().having(
                  (e) => e.code,
                  'code',
                  'scene.publication_blocked',
                ),
              ),
            );
          }
          expect(await f.projectFile.readAsBytes(), before);
        }
      },
    );

    test(
      '$label refuses non-NPC ghost and spatial targets before every Scene write',
      () async {
        for (final fixture in <(
          String,
          MapEntity,
          bool,
          List<ProjectCharacterEntry>?,
          List<ProjectTrainerEntry>
        )>[
          (
            'sign',
            const MapEntity(
                id: 'actor',
                kind: MapEntityKind.sign,
                pos: GridPos(x: 0, y: 0)),
            false,
            null,
            []
          ),
          (
            'custom',
            const MapEntity(
                id: 'actor',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0)),
            false,
            null,
            []
          ),
          ('missing payload', _actor.copyWith(npc: null), false, null, []),
          (
            'empty payload',
            _actor.copyWith(npc: const MapEntityNpcData()),
            false,
            null,
            []
          ),
          (
            'unknown character',
            _actor.copyWith(
                npc: const MapEntityNpcData(characterId: 'missing')),
            false,
            null,
            []
          ),
          (
            'ambiguous character',
            _actor,
            false,
            [_character(), _character()],
            []
          ),
          (
            'unknown trainer',
            _actor.copyWith(npc: const MapEntityNpcData(trainerId: 'missing')),
            false,
            null,
            [_trainer]
          ),
          (
            'ambiguous trainer',
            _actor.copyWith(
                npc: const MapEntityNpcData(trainerId: 'actor-trainer')),
            false,
            null,
            [_trainer, _trainer]
          ),
          (
            'trainer character absent',
            _actor.copyWith(
                npc: const MapEntityNpcData(trainerId: 'actor-trainer')),
            false,
            [],
            [_trainer]
          ),
          ('spatial', _actor, true, null, []),
        ]) {
          final f = await _Fixture.create(
              entities: [fixture.$2],
              spatial: fixture.$3,
              characters: fixture.$4,
              trainers: fixture.$5);
          try {
            final mapBefore = await f.mapFile.readAsBytes();
            final wires = [
              _route(),
              _visibility(),
              if (fixture.$3) _route(target: _target()),
              if (fixture.$3) _visibility(target: _target())
            ];
            for (final wire in wires) {
              for (final action in [
                'scene.interactive_command.set',
                'scene.upsert',
                'scene.graph.patch'
              ]) {
                final before = await f.projectFile.readAsBytes();
                final scene =
                    _scene('edit', SceneInteractiveCommand.fromJson(wire));
                final semantic = await f.request(wire);
                final request = AuthoringRequest.fromJson({
                  ...semantic.toJson(),
                  'actionId': action,
                  'parameters': switch (action) {
                    'scene.upsert' => {'scene': scene.toJson()},
                    'scene.graph.patch' => {
                        'sceneId': 'edit',
                        'upsertNodes': [scene.graph.nodes[1].toJson()]
                      },
                    _ => semantic.parameters,
                  }
                });
                if (jsonl) {
                  final result = await f.command('plan', {
                    'projectHandle': f.project.value,
                    'request': request.toJson()
                  });
                  expect(result.status, AuthoringResultStatus.failure,
                      reason: '${fixture.$1} $action ${wire['kind']}');
                  expect(result.error!.details['domainCode'],
                      'scene.publication_blocked');
                } else {
                  await expectLater(
                      f.mutations.plan(f.project, request),
                      throwsA(isA<NarrativeAuthoringException>().having(
                          (e) => e.code, 'code', 'scene.publication_blocked')),
                      reason: '${fixture.$1} $action ${wire['kind']}');
                }
                expect(await f.projectFile.readAsBytes(), before);
                expect(await f.mapFile.readAsBytes(), mapBefore);
              }
            }
          } finally {
            await f.dispose();
          }
        }
      },
    );

    test(
      '$label accepts the unique character resolved through its trainer',
      () async {
        final f = await _Fixture.create(entities: [
          _actor.copyWith(
              npc: const MapEntityNpcData(trainerId: ' actor-trainer '))
        ], trainers: [
          _trainer
        ]);
        addTearDown(f.dispose);
        for (final wire in [_route(), _visibility()]) {
          final request = await f.request(wire);
          if (jsonl) {
            final result = await f.command('plan', {
              'projectHandle': f.project.value,
              'request': request.toJson()
            });
            expect(result.status, AuthoringResultStatus.success,
                reason: jsonEncode(result.toJson()));
          } else {
            await expectLater(f.mutations.plan(f.project, request), completes);
          }
        }
      },
    );

    test(
      '$label refuses unknown actor route fields and malformed steps',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        for (final wire in [
          {..._route(), 'repeat': true},
          {
            ..._route(),
            'target': {..._target(), 'entityId': 'actor'},
          },
          {
            ..._route(),
            'steps': [
              {'kind': 'move', 'direction': 'south', 'durationMs': 0},
            ],
          },
          {
            ..._route(),
            'steps': [
              {
                'kind': 'sound',
                'mediaAssetId': 'door',
                'gain': 0.8,
                'pitch': 100,
              },
            ],
          },
          {
            ..._route(),
            'steps': [
              {'kind': 'jump', 'x': 1, 'y': 1},
            ],
          },
          {..._visibility(), 'visible': 'false'},
          {..._route(), 'steps': [{'kind': 'visibility', 'visible': 128}]},
          {..._route(), 'steps': [{'kind': 'visibility', 'visible': false, 'opacity': 0}]},
        ]) {
          final before = await f.projectFile.readAsBytes();
          final request = await f.request(wire);
          if (jsonl) {
            final result = await f.command('plan', {
              'projectHandle': f.project.value,
              'request': request.toJson(),
            });
            expect(result.status, AuthoringResultStatus.failure);
            expect(
              result.error!.details['domainCode'],
              'scene.graph.payload_invalid',
            );
          } else {
            await expectLater(
              f.mutations.plan(f.project, request),
              throwsA(
                isA<NarrativeAuthoringException>().having(
                  (e) => e.code,
                  'code',
                  'scene.graph.payload_invalid',
                ),
              ),
            );
          }
          expect(await f.projectFile.readAsBytes(), before);
        }
      },
    );
  }

  test(
    'scene upsert and graph patch cannot bypass actor reference validation',
    () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final scene = _scene(
        'edit',
        SceneInteractiveCommand.fromJson(_route(mediaId: 'missing')),
      );
      for (final action in ['scene.upsert', 'scene.graph.patch']) {
        final bytes = await f.projectFile.readAsBytes();
        final id = 'bypass-${++f.sequence}';
        final request = AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: f.workspace.value,
          expectedRevision: (await f.snapshot()).revision,
          idempotencyKey: id,
          parameters: action == 'scene.upsert'
              ? {'scene': scene.toJson()}
              : {
                  'sceneId': 'edit',
                  'upsertNodes': [scene.graph.nodes[1].toJson()],
                },
        );
        final result = await f.command('plan', {
          'projectHandle': f.project.value,
          'request': request.toJson(),
        });
        expect(result.status, AuthoringResultStatus.failure);
        expect(
          result.error!.details['domainCode'],
          'scene.publication_blocked',
        );
        expect(await f.projectFile.readAsBytes(), bytes);
      }
    },
  );
}

final class _Fixture {
  _Fixture(
    this.directory,
    this.api,
    this.snapshots,
    this.mutations,
    this.worker,
  );
  final Directory directory;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late WorkspaceHandle workspace;
  late ProjectHandle project;
  var sequence = 0;
  File get projectFile => File('${directory.path}/project.json');
  File get mapFile => File('${directory.path}/maps/map.json');

  static Future<_Fixture> create({
    List<MapEntity>? entities,
    bool spatial = false,
    List<ProjectCharacterEntry>? characters,
    List<ProjectTrainerEntry> trainers = const [],
  }) async {
    final directory = await Directory.systemTemp.createTemp(
      'world-presentation-transport-',
    );
    final map = MapData(
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 4, height: 4),
      layers: const [],
      entities: entities ?? const [_actor],
      spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
      warps: const [
        MapWarp(
          id: 'arrival',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'map',
          targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
      ],
    );
    final manifest = ProjectManifest(
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      settings: ProjectSettings(
          dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
      name: 'QA',
      maps: [
        const ProjectMapEntry(
            id: 'map', name: 'Map', relativePath: 'maps/map.json'),
        if (!spatial)
          const ProjectMapEntry(
            id: 'other',
            name: 'Other',
            relativePath: 'maps/other.json',
          ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
            id: 'actor-sheet',
            name: 'Original QA sheet',
            relativePath: 'assets/actor.png')
      ],
      characters: characters ?? [_character()],
      trainers: trainers,
      scenes: [
        _scene(
          'edit',
          SceneInteractiveCommand.warp(
            destinationMapId: 'map',
            warpId: 'arrival',
          ),
        ),
        _scene(
          'unrelated-draft',
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'missing',
            volume: 0.8,
          ),
        ),
      ],
      cinematicMediaAssets: [
        for (final id in [
          'door',
          'loop',
          'music',
          'fx',
          'ambiguous',
          'ambiguous',
        ])
          CinematicMediaAsset(
            id: id,
            label: id,
            kind: id == 'music'
                ? CinematicMediaAssetKind.music
                : id == 'fx'
                    ? CinematicMediaAssetKind.cinematicFx
                    : CinematicMediaAssetKind.sound,
            relativePath: 'audio/$id.wav',
            loopByDefault: id == 'loop',
          ),
      ],
    );
    await Directory('${directory.path}/maps').create();
    await Directory('${directory.path}/audio').create();
    await Directory('${directory.path}/assets').create();
    final sheet = img.Image(width: 32, height: 32, numChannels: 4);
    img.fill(sheet, color: img.ColorRgba8(96, 128, 160, 255));
    await File('${directory.path}/assets/actor.png')
        .writeAsBytes(img.encodePng(sheet));
    await File('${directory.path}/maps/map.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${directory.path}/maps/other.json').writeAsString(
      jsonEncode(
        MapData(
          version: ProjectVersion.v8,
          id: 'other',
          name: 'Other',
          size: const GridSize(width: 4, height: 4),
          layers: const [],
        ).toJson(),
      ),
    );
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final wav = Uint8List(46);
    final data = ByteData.sublistView(wav);
    wav.setRange(0, 4, utf8.encode('RIFF'));
    data.setUint32(4, 38, Endian.little);
    wav.setRange(8, 16, utf8.encode('WAVEfmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 8000, Endian.little);
    data.setUint32(28, 16000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, utf8.encode('data'));
    data.setUint32(40, 2, Endian.little);
    for (final id in ['door', 'loop', 'music', 'fx', 'ambiguous']) {
      await File('${directory.path}/audio/$id.wav').writeAsBytes(wav);
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [directory.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final fixture = _Fixture(
      directory,
      api,
      snapshots,
      mutations,
      JsonlWorker(
        api: api,
        mutations: mutations,
        commandTimeout: const Duration(seconds: 60),
      ),
    );
    await fixture.open();
    return fixture;
  }

  Future<AuthoringResult> command(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'command-${++sequence}',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );
  Future<Map<String, Object?>> success(
    String name,
    Map<String, Object?> args,
  ) async {
    final result = await command(name, args);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: jsonEncode(result.toJson()),
    );
    return result.data;
  }

  Future<void> open() async {
    final result = await success('open', {'projectRoot': directory.path});
    workspace = WorkspaceHandle(result['workspaceHandle']! as String);
    project = ProjectHandle(result['projectHandle']! as String);
  }

  Future<ProjectSnapshot> snapshot() => snapshots.load(project);
  Future<AuthoringRequest> request(Map<String, Object?> command) async =>
      AuthoringRequest(
        requestId: 'edit-${++sequence}',
        actionId: 'scene.interactive_command.set',
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshot()).revision,
        idempotencyKey: 'edit-$sequence',
        parameters: {'sceneId': 'edit', 'nodeId': 'action', 'command': command},
      );
  Future<AuthoringRequest> actionRequest(String action, Map<String, dynamic> wire) async {
    final scene = _scene('edit', SceneInteractiveCommand.warp(
      destinationMapId: 'map', warpId: 'arrival')).toJson();
    final node = ((scene['graph'] as Map)['nodes'] as List)[1] as Map;
    (node['payload'] as Map)['interactiveCommand'] = wire;
    final id = 'owner-${++sequence}';
    return AuthoringRequest(requestId: id, actionId: action, actionVersion: 1,
      workspaceHandle: workspace.value, expectedRevision: (await snapshot()).revision,
      idempotencyKey: id, parameters: switch (action) {
        'scene.interactive_command.set' => {'sceneId': 'edit', 'nodeId': 'action', 'command': wire},
        'scene.upsert' => {'scene': scene},
        'scene.graph.patch' => {'sceneId': 'edit', 'upsertNodes': [node]},
        _ => throw ArgumentError.value(action),
      });
  }
  Future<void> dispose() async {
    await success('close', {'workspaceHandle': workspace.value});
    await directory.delete(recursive: true);
  }
}
