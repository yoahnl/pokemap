import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-4000-7000-8000-000000000071';
const _eventB = 'evt_019abcde-4000-7000-8000-000000000072';
const _eventC = 'evt_019abcde-4000-7000-8000-000000000073';

enum _ZoneLayout { disjoint, identical, nested, overlapping, blockedOverlap, startsInside }

enum _ArrivalLayout { clear, fixedCollision, distantElement, blockingElement, actorCollision, spatial }

void main() {
  for (final (mode, blocked) in [
    (EventSystemMode.legacyOnly, null),
    (EventSystemMode.legacyOnly, 'disabled'),
    (EventSystemMode.legacyOnly, 'shadowed'),
    (EventSystemMode.legacyOnly, 'hiddenByRule'),
    (EventSystemMode.v2Only, null),
  ]) {
  test('H10: legacy page progression in ${mode.name}, obstruction=$blocked', () {
    final fixture = _fixture();
    final scene = fixture.project.scenes.single;
    final map = fixture.map.copyWith(events: [
      MapEventDefinition(
        id: 'legacy_intro',
        position: const EventPosition(layerId: 'events', x: 5, y: 5),
        pages: [
          if (blocked == 'shadowed')
            const MapEventPage(pageNumber: 0, message: 'Rien ici.'),
          MapEventPage(
            pageNumber: blocked == 'shadowed' ? 1 : 0,
            sceneTarget: MapEventSceneTarget(sceneId: scene.id),
            isDisabled: blocked == 'disabled',
          ),
        ],
      ),
    ]);
    final project = fixture.project.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: mode,
        records: const [],
        legacyClaims: const [],
      ),
      worldRules: [
        if (blocked == 'hiddenByRule')
          WorldRuleDefinition(
            id: 'hide_guide',
            label: 'Masquer le guide',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_gate',
              predicate: WorldRuleSourcePredicate.isFalse,
            ),
            target: WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEvent,
              mapId: fixture.map.id,
              eventId: 'legacy_intro',
            ),
            effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventHidden),
          ),
      ],
    );
    final report = validateNarrativeProject(project, maps: [map]);
    final available = blocked == null && mode == EventSystemMode.legacyOnly;
    expect(report.byCode('storylineStepNeverCompleted'), hasLength(available ? 0 : 1));
    expect(report.isPlayable, available);
  });
  }

  final guide = NarrativeEventSourceRef.entityInteract('map_port', 'npc_guide');
  final quay = NarrativeEventSourceRef.triggerEnter('map_port', 'zone_quay');
  final market = NarrativeEventSourceRef.triggerEnter('map_port', 'zone_a');
  final activation = NarrativeEventSourceRef.mapEnter('map_port');
  for (final (name, firstSource, secondSource, canReverseOrder, layout, reverseEditOrder) in [
    (
      'distinct interactions',
      guide,
      NarrativeEventSourceRef.entityInteract('map_port', 'npc_second'),
      true,
      _ZoneLayout.disjoint,
      false,
    ),
    ('same interaction', guide, guide, false, _ZoneLayout.disjoint, false),
    ('interaction and zone', guide, quay, true, _ZoneLayout.disjoint, false),
    ('same zone', quay, quay, false, _ZoneLayout.disjoint, false),
    ('zones on the same cell', market, quay, false, _ZoneLayout.identical, false),
    ('zones on the same cell, B ordered first', market, quay, false, _ZoneLayout.identical, true),
    ('nested zones', market, quay, false, _ZoneLayout.nested, true),
    ('overlapping zones with an independent entry', market, quay, true, _ZoneLayout.overlapping, false),
    ('overlapping zones with the independent entry blocked', market, quay, false, _ZoneLayout.blockedOverlap, false),
    ('default spawn inside the enclosing zone', market, quay, true, _ZoneLayout.startsInside, false),
    ('disjoint zones', market, quay, true, _ZoneLayout.disjoint, false),
    ('initial activation ordered first', activation, quay, false, _ZoneLayout.disjoint, false),
    ('initial activation ordered last', activation, quay, false, _ZoneLayout.disjoint, true),
  ]) {
    test('H10: reverse interaction order for $name', () {
      final fixture = _fixture();
      final story = fixture.project.storylines.single;
      final chapter = story.chapters.single;
      final first = chapter.steps.single;
      final second = StorylineStep(
        id: 'step_second',
        title: 'Rencontrer le deuxième guide',
        order: 1,
        sceneLinkIds: const ['scene_second'],
      );
      final firstScene = _h10CounterScene('scene_intro', [
        SceneConsequence.setFact(factId: 'fact_gate', value: false),
        SceneConsequence.completeStoryStep(stepId: first.id),
      ]);
      final secondScene = _h10CounterScene('scene_second', [
        SceneConsequence.completeStoryStep(stepId: second.id),
      ]);
      final project = fixture.project.copyWith(
        newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_port',
          startSpawnId: layout == _ZoneLayout.startsInside ? null : 'spawn_player',
        ),
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Passage',
            defaultValue: true,
          ),
        ],
        scenes: [firstScene, secondScene],
        storylines: [
          story.copyWith(
            chapters: [
              chapter.copyWith(steps: [first, second]),
            ],
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, source: firstSource, order: reverseEditOrder ? 1 : 0),
            _record(
              id: _eventB,
              source: secondSource,
              sceneId: secondScene.id,
              conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              order: reverseEditOrder ? 0 : 1,
            ),
          ],
          legacyClaims: const [],
        ),
      );
      final counterMap = _h10CounterMap(fixture.map);
      final overlapping = layout == _ZoneLayout.overlapping || layout == _ZoneLayout.blockedOverlap;
      final map = counterMap.copyWith(
        layers: [
          ...counterMap.layers,
          if (layout == _ZoneLayout.blockedOverlap)
            _h10CollisionAt(counterMap, const GridPos(x: 1, y: 3)),
        ],
        triggers: [
          MapTrigger(
            id: 'zone_quay',
            name: 'Quai',
            type: TriggerType.event,
            area: MapRect(
              pos: const GridPos(x: 1, y: 2),
              size: GridSize(
                width: 1,
                height: overlapping ? 2 : 1,
              ),
            ),
          ),
          MapTrigger(
            id: 'zone_a',
            name: 'Marché',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: layout == _ZoneLayout.disjoint ? 2 : 1, y: 2),
              size: GridSize(
                width: overlapping || layout == _ZoneLayout.nested || layout == _ZoneLayout.startsInside ? 2 : 1,
                height: 1,
              ),
            ),
          ),
        ],
        entities: [
          for (final entity in counterMap.entities)
            if (layout == _ZoneLayout.startsInside && entity.id == 'spawn_player')
              entity.copyWith(pos: const GridPos(x: 2, y: 2))
            else
              entity,
        ],
      );
      final afterSecond = solveNarrativeSceneSymbolically(
        secondScene,
        initialState: NarrativeSymbolicState(
          factValues: {'fact_gate': const NarrativeValue.boolean(true)},
        ),
      ).terminalStates.single;
      final afterBoth = solveNarrativeSceneSymbolically(
        firstScene,
        initialState: afterSecond,
      ).terminalStates.single;
      expect(afterBoth.completedStepIds, {first.id, second.id});
      final report = validateNarrativeProject(project, maps: [map]);
      expect(
        report.byCode('storylineStepNeverCompleted'),
        hasLength(canReverseOrder ? 0 : 1),
      );
      expect(report.isPlayable, canReverseOrder);
    });
  }

  for (final allCells in [true, false]) {
    test(
      'H10: a spawn inside a single zone must leave before reentry (all cells=$allCells)',
      () {
        final fixture = _fixture();
        final map = fixture.map.copyWith(
          triggers: [
            MapTrigger(
              id: 'zone_spawn',
              type: TriggerType.event,
              area: allCells
                  ? MapRect(
                      pos: const GridPos(x: 0, y: 0),
                      size: fixture.map.size,
                    )
                  : const MapRect(
                      pos: GridPos(x: 1, y: 1),
                      size: GridSize(width: 1, height: 1),
                    ),
            ),
          ],
        );
        final project = fixture.project.copyWith(
          newGame: ProjectNewGameConfig(enabled: true, startMapId: map.id),
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(
                id: _eventA,
                source: NarrativeEventSourceRef.triggerEnter(
                  map.id,
                  'zone_spawn',
                ),
              ),
            ],
            legacyClaims: const [],
          ),
        );

        final report = validateNarrativeProject(project, maps: [map]);

        expect(
          report.byCode('storylineStepNeverCompleted'),
          hasLength(allCells ? 1 : 0),
        );
        expect(report.isPlayable, !allCells);
      },
    );
  }

  test('H10: a moving side-quest witness retains its compatible avatar', () {
    final fixture = _fixture();
    final step = StorylineStep(
      id: 'step_side',
      title: 'Explorer le quai',
      order: 0,
      sceneLinkIds: ['scene_side'],
    );
    final quest = StorylineAsset(
      id: 'side',
      title: 'Le quai',
      type: StorylineType.sideQuest,
      status: StorylineStatus.active,
      chapters: [
        StorylineChapter(id: 'dock', title: 'Arrivée', order: 0, steps: [step]),
      ],
    );
    final map = fixture.map.copyWith(
      triggers: const [
        MapTrigger(
          id: 'zone_a',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 2, height: 1),
          ),
        ),
        MapTrigger(
          id: 'zone_quay',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );
    final project = fixture.project.copyWith(
      storylines: [...fixture.project.storylines, quest],
      scenes: [
        ...fixture.project.scenes,
        _h10CounterScene(
          'scene_outer',
          [],
          storylineId: quest.id,
          chapterId: 'dock',
        ),
        _h10CounterScene(
          'scene_side',
          [SceneConsequence.completeStoryStep(stepId: step.id)],
          storylineId: quest.id,
          chapterId: 'dock',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'avatars',
          name: 'Avatars',
          relativePath: 'assets/avatars.png',
        ),
      ],
      characters: [
        for (final id in ['avatar_a', 'avatar_b'])
          ProjectCharacterEntry(
            id: id,
            name: id,
            tilesetId: 'avatars',
            frameHeight: 1,
          ),
      ],
      newGame: ProjectNewGameConfig(
        enabled: true,
        startMapId: map.id,
        playerAvatarCharacterIds: const ['avatar_a', 'avatar_b'],
        initialFactValuesByAvatarCharacterId: const {
          'avatar_a': {'fact_gate': NarrativeValue.boolean(true)},
          'avatar_b': {'fact_gate': NarrativeValue.boolean(false)},
        },
      ),
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          ...fixture.project.eventRegistry!.records,
          _record(id: _eventB, source: market, sceneId: 'scene_outer'),
          _record(
            id: _eventC,
            source: quay,
            sceneId: 'scene_side',
            conditions: [NarrativeEventCondition.fact('fact_gate', true)],
          ),
        ],
        legacyClaims: const [],
      ),
    );

    final report = validateNarrativeProject(project, maps: [map]);
    final symbolic = report.symbolicReachability!;
    final component = symbolic.independentFactComponents.singleWhere(
      (entry) => entry.stepIds.contains(step.id),
    );
    final witness = component.states.firstWhere(
      (state) => state.completedStepIds.contains(step.id),
    );
    final avatarA = symbolic.evidenceStates.where(
      (state) => state.hasTrueFact('fact_gate'),
    );

    expect(witness.zonePosition?.cell, const GridPos(x: 1, y: 2));
    expect(witness.provenance.first.nodeId, 'avatar_a');
    expect(
      component.compatibleMainStateKeysByStateKey[witness.semanticKey],
      unorderedEquals(avatarA.map((state) => state.semanticKey)),
    );
    expect(symbolic.canSatisfyMilestones([step]), isTrue);
    expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
    expect(report.isPlayable, isTrue);
  });

  for (final (policy, retryable, canRepeat) in [
    (NarrativeEventReusePolicy.oneShot, false, false),
    (NarrativeEventReusePolicy.reusable, false, true),
    (NarrativeEventReusePolicy.oneShot, true, true),
  ]) {
    test('H10: a second interaction follows a fact changed by the first ($policy, retryable=$retryable)', () {
      final fixture = _fixture();
      final stepId = fixture.project.storylines.single.chapters.single.steps.single.id;
      final scene = SceneAsset(
        id: fixture.project.scenes.single.id,
        name: 'Le guide se souvient',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'check',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.fact,
                  sourceId: 'fact_gate',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'remember',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'fact_gate', value: true),
              ),
            ),
            SceneNode(
              id: 'finish',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.completeStoryStep(stepId: stepId),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
            if (retryable)
              SceneNode(
                id: 'retry',
                kind: SceneNodeKind.end,
                payload: SceneEndPayload(
                  sceneOutcomeId: 'try_again',
                  outcomePolicy: SceneOutcomePolicy.retryable,
                ),
              ),
          ],
          edges: [
            for (final (from, port, to, kind) in [
              ('start', 'completed', 'check', SceneEdgeKind.defaultFlow),
              ('check', 'false', 'remember', SceneEdgeKind.conditionFalse),
              ('check', 'true', 'finish', SceneEdgeKind.conditionTrue),
              ('remember', 'completed', retryable ? 'retry' : 'end', SceneEdgeKind.defaultFlow),
              ('finish', 'completed', 'end', SceneEdgeKind.defaultFlow),
            ])
              SceneEdge(id: '${from}_$port', fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind),
          ],
        ),
      );
      final first = solveNarrativeSceneSymbolically(
        scene,
        initialState: NarrativeSymbolicState(
          factValues: {'fact_gate': const NarrativeValue.boolean(false)},
        ),
      ).terminalStates.single;
      expect(first.hasTrueFact('fact_gate'), isTrue);
      expect(first.completedStepIds, isEmpty);
      expect(
        solveNarrativeSceneSymbolically(scene, initialState: first).terminalStates.single.completedStepIds,
        {stepId},
      );
      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [_record(id: _eventA, reusePolicy: policy)],
            legacyClaims: const [],
          ),
        ),
        maps: [fixture.map],
      );
      expect(
        report.byCode('storylineStepNeverCompleted'),
        hasLength(canRepeat ? 0 : 1),
      );
    });
  }

  for (final typedPage in [false, true]) {
    test('H10: integer Facts on historical pages require Event Builder provenance ($typedPage)', () {
      final fixture = _fixture();
      final scene = fixture.project.scenes.single;
      final map = fixture.map.copyWith(events: [
        MapEventDefinition(
          id: 'legacy_intro',
          position: const EventPosition(layerId: 'events', x: 5, y: 5),
          pages: [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: scene.id),
              condition: ScriptConditionFactory.factEquals('fact_integer', NarrativeValue.integer(5)),
              metadata: {
                if (typedPage) EventBuilderMetadataKeys.schemaVersion: EventBuilderMetadataKeys.currentSchemaVersion,
              },
            ),
          ],
        ),
      ]);
      final project = fixture.project.copyWith(
        facts: [
          ...fixture.project.facts,
          NarrativeFactDefinition(id: 'fact_integer', label: 'Entier', initialValue: NarrativeValue.integer(5)),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [],
          legacyClaims: [],
        ),
      );
      final report = validateNarrativeProject(project, maps: [map]);
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(typedPage ? 0 : 1));
    });
  }

  for (final linked in [false, true]) {
    test('H10: later map activation requires an authored transition ($linked)', () {
      final fixture = _fixture();
      const otherMapId = 'map_station';
      final start = fixture.map.copyWith(
        warps: [
          if (linked)
            const MapWarp(
              id: 'to_station',
              pos: GridPos(x: 2, y: 1),
              targetMapId: otherMapId,
              targetPos: GridPos(x: 1, y: 1),
            ),
        ],
      );
      final station = fixture.map.copyWith(id: otherMapId, name: 'Gare');
      final project = fixture.project.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_port',
          startSpawnId: 'spawn_player',
        ),
        maps: [
          ...fixture.project.maps,
          const ProjectMapEntry(
            id: otherMapId,
            name: 'Gare',
            relativePath: 'maps/station.json',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [_record(id: _eventA, source: NarrativeEventSourceRef.mapEnter(otherMapId))],
          legacyClaims: const [],
        ),
      );
      final report = validateNarrativeProject(project, maps: [start, station]);
      expect(
        report.byCode('storylineStepNeverCompleted'),
        hasLength(linked ? 0 : 1),
      );
    });
  }

  for (final (name, sameMap, layout, guideAvailable, playable) in [
    ('free 2D arrival on another map', false, _ArrivalLayout.clear, true, true),
    ('free 2D arrival on the same map', true, _ArrivalLayout.clear, true, true),
    ('fixed collision on another map', false, _ArrivalLayout.fixedCollision, true, false),
    ('static element far from the arrival', false, _ArrivalLayout.distantElement, true, true),
    ('static element on the arrival', false, _ArrivalLayout.blockingElement, true, false),
    ('unproven actor collision', false, _ArrivalLayout.actorCollision, true, false),
    ('unproven 3D arrival on the same map', true, _ArrivalLayout.spatial, true, false),
    ('unproven 3D arrival on another map', false, _ArrivalLayout.spatial, true, false),
    ('unavailable guide', false, _ArrivalLayout.clear, false, false),
  ]) {
    test('H10: a scene warp activates its destination after completion ($name)', () {
      final fixture = _fixture();
      final destinationId = sameMap ? fixture.map.id : 'map_station';
      const arrivalId = 'arrival';
      const arrival = GridPos(x: 4, y: 2);
      final hasBollard = layout == _ArrivalLayout.distantElement || layout == _ArrivalLayout.blockingElement;
      final start = layout == _ArrivalLayout.spatial
          ? fixture.map.copyWith(version: ProjectVersion.v9, spatialScene: MapSpatialScene(width: 16, depth: 16))
          : fixture.map;
      final destination = start.copyWith(
        id: destinationId,
        name: sameMap ? fixture.map.name : 'Gare',
        layers: [
          ...start.layers,
          if (layout == _ArrivalLayout.fixedCollision) _h10CollisionAt(start, arrival),
        ],
        placedElements: [
          if (hasBollard)
            MapPlacedElement(
              id: 'bollard_instance',
              layerId: 'events',
              elementId: 'bollard',
              pos: layout == _ArrivalLayout.blockingElement ? arrival : const GridPos(x: 13, y: 13),
              applyCollision: true,
            ),
        ],
        entities: [
          ...start.entities,
          if (layout == _ArrivalLayout.actorCollision)
            const MapEntity(
              id: 'npc_arrival',
              name: 'Garde',
              kind: MapEntityKind.npc,
              pos: arrival,
              blocksMovement: true,
            ),
        ],
        warps: [
          MapWarp(
            id: arrivalId,
            pos: arrival,
            targetMapId: destinationId,
            targetPos: arrival,
            triggerMode: MapWarpTriggerMode.sceneOnly,
          ),
        ],
      );
      final guide = SceneAsset(
        id: 'scene_departure',
        name: 'Départ vers la gare',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'warp',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.warp(
                  destinationMapId: destinationId,
                  warpId: arrivalId,
                ),
              ),
            ),
            SceneNode(
              id: 'fact',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'fact_gate', value: true),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_warp',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'warp',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'warp_done',
              fromNodeId: 'warp',
              fromPortId: 'completed',
              toNodeId: 'fact',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'warp_blocked',
              fromNodeId: 'warp',
              fromPortId: 'blocked',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'fact_end',
              fromNodeId: 'fact',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );
      final project = fixture.project.copyWith(
        tilesets: [
          if (hasBollard) const ProjectTilesetEntry(id: 'bollards', name: 'Bornes', relativePath: 'assets/bollards.png'),
        ],
        elements: [
          if (hasBollard)
            ProjectElementEntry(
              id: 'bollard', name: 'Borne', tilesetId: 'bollards', categoryId: 'objects',
              frames: const [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))],
              collisionProfile: ElementCollisionProfile(collisionMask: ElementCollisionPixelMask(
                widthPx: 16,
                heightPx: 16,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(widthPx: 16, heightPx: 16, solidPixels: List<bool>.filled(16 * 16, true)),
              )),
            ),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_port',
          startSpawnId: 'spawn_player',
        ),
        maps: [
          ...fixture.project.maps,
          if (!sameMap)
            ProjectMapEntry(
              id: destinationId,
              name: 'Gare',
              relativePath: 'maps/station.json',
            ),
        ],
        scenes: [...fixture.project.scenes, guide],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(
              id: _eventA,
              sceneId: guide.id,
              conditions: [
                if (!guideAvailable) NarrativeEventCondition.fact('fact_gate', true),
              ],
            ),
            _record(
              id: _eventB,
              source: NarrativeEventSourceRef.mapEnter(destinationId),
              conditions: [NarrativeEventCondition.fact('fact_gate', true)],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(
        project,
        maps: [if (!sameMap) start, destination],
      );

      expect(report.byCode('sceneNotBuildable'), isEmpty);
      expect(report.byCode('edgeKindUnsupportedForPort'), isEmpty);
      expect(
        report.byCode('storylineStepNeverCompleted'),
        hasLength(playable ? 0 : 1),
      );
      expect(report.isPlayable, playable, reason: report.diagnostics.map((issue) => issue.code).join(', '));
      if (layout == _ArrivalLayout.spatial || layout == _ArrivalLayout.actorCollision) {
        expect(report.byCode('narrativeSolvabilityIndeterminate'), isNotEmpty);
        final witnesses = report.symbolicReachability!.terminalStates.where(
          (state) => state.completedStepIds.contains('step_intro'),
        );
        if (sameMap) {
          expect(witnesses, isEmpty);
        } else {
          expect(witnesses, isNotEmpty);
          expect(witnesses.every((state) => state.indeterminate), isTrue);
        }
      } else {
        expect(report.byCode('narrativeSolvabilityIndeterminate'), isEmpty);
      }
    });
  }

  test('H10: independent repeatable interactions and simultaneous zones grow linearly', () {
    final counts = <int>[];
    for (final count in [24, 48, 96]) {
      final fixture = _fixture();
      final indices = List.generate(count, (index) => index);
      final map = fixture.map.copyWith(
        entities: [
          ...fixture.map.entities,
          for (final i in indices.where((index) => index.isEven))
            MapEntity(
              id: 'guide_$i',
              name: 'Guide $i',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2 + i % 12, y: 5 + i ~/ 12),
            ),
        ],
        triggers: [
          for (final i in indices.where((index) => index.isOdd))
            MapTrigger(
              id: 'zone_$i',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1 + i ~/ 4 % 8, y: 1 + i ~/ 32),
                size: const GridSize(width: 1, height: 1),
              ),
            ),
        ],
      );
      final project = fixture.project.copyWith(
        storylines: const [],
        facts: [
          for (final i in indices) NarrativeFactDefinition(id: 'fact_$i', label: 'Fact $i'),
        ],
        scenes: [
          for (final i in indices)
            _h10CounterScene('scene_$i', [
              SceneConsequence.setFact(factId: 'fact_$i', value: true),
            ]),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            for (final i in indices)
              _record(
                id: 'evt_019abcde-4500-7000-8000-${i.toString().padLeft(12, '0')}',
                sceneId: 'scene_$i',
                source: i.isEven
                    ? NarrativeEventSourceRef.entityInteract(map.id, 'guide_$i')
                    : NarrativeEventSourceRef.triggerEnter(map.id, 'zone_$i'),
                reusePolicy: i.isEven
                    ? NarrativeEventReusePolicy.reusable
                    : NarrativeEventReusePolicy.oneShot,
                order: i,
              ),
          ],
          legacyClaims: const [],
        ),
      );
      final report = solveNarrativeSymbolicReachability(project, maps: [map]);
      expect(report.issues, isEmpty);
      expect(
        report.terminalStates.any((state) => indices.every((i) => state.hasTrueFact('fact_$i'))),
        isTrue,
      );
      counts.add(report.exploredStateCount);
    }
    expect(counts[0], lessThanOrEqualTo(24 * 6));
    expect(counts[1], counts[0] * 2);
    expect(counts[2], counts[1] * 2);
  });

  for (final alternate in [false, true]) {
  test('H10 counter: independent components and avatar starts, alternate=$alternate', () {
    final fixture = _fixture(completeStep: false);
    final story = fixture.project.storylines.single;
    final chapter = story.chapters.single;
    final first = chapter.steps.single.copyWith(
      completionCondition: ScriptConditionFactory.factEquals(
        'fact_gate', NarrativeValue.boolean(alternate),
      ),
    );
    final goal = ScriptConditionFactory.factEquals(
      'fact_goal', const NarrativeValue.boolean(true),
    );
    final second = StorylineStep(
      id: 'step_second',
      title: 'Finir la quête',
      order: 1,
      sceneLinkIds: const ['scene_second'],
      completionCondition: goal,
    );
    final optional = StorylineAsset(
      id: 'story_optional',
      type: StorylineType.sideQuest,
      status: StorylineStatus.active,
      title: 'Quête optionnelle',
      chapters: [
        StorylineChapter(
          id: 'chapter_optional',
          title: 'Le guide',
          order: 0,
          steps: [
            StorylineStep(
              id: 'step_optional',
              title: 'Faire la quête',
              order: 0,
              sceneLinkIds: const ['scene_optional'],
              completionCondition: goal,
            ),
          ],
        ),
      ],
    );
    final optionalScene = alternate
    ? SceneAsset(
      id: 'scene_optional',
      name: 'Side quest',
      storylineId: optional.id,
      chapterId: optional.chapters.single.id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'check',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.fact,
                sourceId: 'fact_blocked',
                operator: SceneConditionOperator.isTrue,
              ),
            ),
          ),
          SceneNode(
            id: 'explicit',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.completeStoryStep(stepId: first.id),
            ),
          ),
          SceneNode(
            id: 'goal',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: 'fact_goal', value: true),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(id: 'start_check', fromNodeId: 'start', fromPortId: 'completed',
            toNodeId: 'check', kind: SceneEdgeKind.defaultFlow),
          SceneEdge(id: 'check_true', fromNodeId: 'check', fromPortId: 'true',
            toNodeId: 'explicit', kind: SceneEdgeKind.conditionTrue),
          SceneEdge(id: 'check_false', fromNodeId: 'check', fromPortId: 'false',
            toNodeId: 'goal', kind: SceneEdgeKind.conditionFalse),
          SceneEdge(id: 'explicit_goal', fromNodeId: 'explicit', fromPortId: 'completed',
            toNodeId: 'goal', kind: SceneEdgeKind.defaultFlow),
          SceneEdge(id: 'goal_end', fromNodeId: 'goal', fromPortId: 'completed',
            toNodeId: 'end', kind: SceneEdgeKind.defaultFlow),
        ],
      ),
    )
    : _h10CounterScene(
      'scene_optional',
      [SceneConsequence.setFact(factId: 'fact_goal', value: true)],
      storylineId: optional.id,
      chapterId: optional.chapters.single.id,
    );
    final project = fixture.project.copyWith(
      facts: [
        ...fixture.project.facts,
        NarrativeFactDefinition(id: 'fact_goal', label: 'Quête accomplie'),
        if (alternate) NarrativeFactDefinition(id: 'fact_blocked', label: 'Autre parcours'),
      ],
      scenes: [
        ...fixture.project.scenes,
        _h10CounterScene('scene_second', []),
        optionalScene,
      ],
      storylines: [
        story.copyWith(chapters: [chapter.copyWith(steps: [first, second])]),
        optional,
      ],
      tilesets: const [
        ProjectTilesetEntry(id: 'avatars', name: 'Avatars', relativePath: 'assets/avatars.png'),
      ],
      characters: [
        for (final id in ['avatar_a', 'avatar_b'])
          ProjectCharacterEntry(
            id: id,
            name: id,
            tilesetId: 'avatars',
            frameHeight: 1,
          ),
      ],
      newGame: ProjectNewGameConfig(
        enabled: true,
        startMapId: fixture.map.id,
        playerAvatarCharacterIds: const ['avatar_a', 'avatar_b'],
        initialFactValuesByAvatarCharacterId: {
          'avatar_a': {'fact_gate': NarrativeValue.boolean(!alternate)},
          'avatar_b': {'fact_gate': NarrativeValue.boolean(alternate)},
        },
      ),
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          ...fixture.project.eventRegistry!.records,
          _record(id: _eventB, entityId: 'npc_second', sceneId: 'scene_second'),
          _record(
            id: _eventC,
            entityId: 'npc_optional',
            sceneId: optionalScene.id,
            conditions: [if (!alternate) NarrativeEventCondition.fact('fact_gate', true)],
          ),
        ],
        legacyClaims: const [],
      ),
    );
    final report = validateNarrativeProject(project, maps: [_h10CounterMap(fixture.map)]);
    final symbolic = report.symbolicReachability!;
    final component = symbolic.independentFactComponents.singleWhere(
      (component) => component.factIds.contains('fact_goal'),
    );
    final witness = component.states.firstWhere((state) => state.hasTrueFact('fact_goal'));
    if (alternate) {
      final validStart = symbolic.evidenceStates.firstWhere(
        (state) => state.hasTrueFact('fact_gate'),
      );
      final actual = solveNarrativeSceneSymbolically(
        optionalScene,
        initialState: validStart,
      ).terminalStates.single;
      expect(actual.hasTrueFact('fact_gate'), isTrue);
      expect(actual.hasTrueFact('fact_goal'), isTrue);
      expect(symbolic.canSatisfyMilestones([first, second]), isTrue);
      expect(report.isPlayable, isTrue);
      return;
    }
    expect(witness.hasTrueFact('fact_gate'), isTrue);
    expect(symbolic.canSatisfyMilestones([first]), isTrue);
    expect(symbolic.canSatisfyMilestones([second]), isTrue);
    final compatible = component.compatibleMainStateKeysByStateKey[witness.semanticKey]!;
    final admitsFalseSeed = symbolic.evidenceStates.any(
      (state) => !state.hasTrueFact('fact_gate') && compatible.contains(state.semanticKey),
    );
    expect(admitsFalseSeed, isFalse);
    expect(symbolic.canSatisfyMilestones([first, second]), isFalse);
    expect(report.byCode('storylineImpossible'), isNotEmpty);
  });
  }

  SceneEdge link(
    String from,
    String port,
    String to, [
    SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
  ]) => SceneEdge(
    id: '$from-$port-$to',
    fromNodeId: from,
    fromPortId: port,
    toNodeId: to,
    kind: kind,
  );

  SceneNode setTrue(String id, String fact) => SceneNode(
    id: id,
    kind: SceneNodeKind.action,
    payload: SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: fact, value: true),
    ),
  );

  ScriptCondition equals(String id, [bool value = true]) =>
      ScriptConditionFactory.factEquals(id, NarrativeValue.boolean(value));

  test('H10: the actual initial value is a valid witness', () {
    final fixture = _fixture(completeStep: false);
    final story = fixture.project.storylines.single;
    final chapter = story.chapters.single;
    final step = chapter.steps.single.copyWith(
      completionCondition: equals('fact_gate', false),
    );
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        storylines: [
          story.copyWith(
            chapters: [
              chapter.copyWith(steps: [step]),
            ],
          ),
        ],
      ),
      maps: [fixture.map],
    );
    expect(
      report.symbolicReachability!.evidenceStates.first.factValues['fact_gate'],
      const NarrativeValue.boolean(false),
    );
    expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
    expect(report.isPlayable, isTrue);
  });

  for (final (exclusive, explicit) in [
    (true, false),
    (false, false),
    (true, true),
    (false, true),
  ]) {
    test(
      'H10: one-shot outcomes with exclusive=$exclusive and explicit=$explicit',
      () {
        final fixture = _fixture(completeStep: false);
        final story = fixture.project.storylines.single;
        final chapter = story.chapters.single;
        final original = chapter.steps.single;
        final first = original.copyWith(
          completionCondition: equals('fact_left'),
        );
        final second = StorylineStep(
          id: 'step_second',
          title: 'Deuxième jalon',
          order: 1,
          sceneLinkIds: const ['scene_second'],
          completionCondition: equals('fact_right'),
        );
        final map = fixture.map.copyWith(
          entities: [
            ...fixture.map.entities,
            const MapEntity(
              id: 'npc_second',
              name: 'Second guide',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 4),
            ),
          ],
        );
        final project = fixture.project.copyWith(
          facts: [
            for (final id in ['fact_left', 'fact_right'])
              NarrativeFactDefinition(id: id, label: id),
          ],
          dialogues: [
            ProjectDialogueEntry(
              id: 'dialogue_branch',
              name: 'Choix unique',
              relativePath: 'dialogues/branch.yarn',
              declaredOutcomes: [
                DialogueDeclaredOutcome(id: 'left', label: 'Gauche'),
                DialogueDeclaredOutcome(id: 'right', label: 'Droite'),
              ],
            ),
          ],
          scenes: [
            SceneAsset(
              id: 'scene_intro',
              name: 'Choix unique',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'choice',
                    kind: SceneNodeKind.yarnDialogue,
                    payload: SceneYarnDialoguePayload(
                      dialogueId: 'dialogue_branch',
                      expectedOutcomes: const ['left', 'right'],
                    ),
                  ),
                  if (explicit)
                    SceneNode(
                      id: 'left',
                      kind: SceneNodeKind.action,
                      payload: SceneActionPayload.consequence(
                        SceneConsequence.completeStoryStep(stepId: first.id),
                      ),
                    )
                  else
                    setTrue('left', 'fact_left'),
                  setTrue('right', 'fact_right'),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  link('start', 'completed', 'choice'),
                  link('choice', 'completed', 'end'),
                  link('choice', 'left', 'left', SceneEdgeKind.dialogueOutcome),
                  link(
                    'choice',
                    'right',
                    'right',
                    SceneEdgeKind.dialogueOutcome,
                  ),
                  link('left', 'completed', exclusive ? 'end' : 'right'),
                  link('right', 'completed', 'end'),
                ],
              ),
            ),
            SceneAsset(
              id: 'scene_second',
              name: 'Second guide',
              graph: _scene(completeStep: false).graph,
            ),
          ],
          storylines: [
            story.copyWith(
              chapters: [
                chapter.copyWith(steps: [first, second]),
              ],
            ),
          ],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              ...fixture.project.eventRegistry!.records,
              _record(
                id: _eventB,
                entityId: 'npc_second',
                sceneId: 'scene_second',
              ),
            ],
            legacyClaims: const [],
          ),
        );
        final report = validateNarrativeProject(project, maps: [map]);
        final reachability = report.symbolicReachability!;
        expect(reachability.canSatisfyMilestones([first]), isTrue);
        expect(reachability.canSatisfyAllTrueFacts({'fact_right'}), isTrue);
        expect(reachability.canSatisfyMilestones([first, second]), !exclusive);
        expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
        expect(
          report.byCode('storylineImpossible'),
          exclusive ? hasLength(1) : isEmpty,
        );
        expect(report.isPlayable, !exclusive);
      },
    );
  }

  for (final (unknown, separate) in [
    (false, false),
    (true, false),
    (true, true),
  ]) {
    test(
      'H10: optional fact witness with unknown=$unknown and separate=$separate',
      () {
        final fixture = _fixture(completeStep: false);
        final story = fixture.project.storylines.single;
        final chapter = story.chapters.single;
        final step = chapter.steps.single.copyWith(
          completionCondition: equals(
            separate ? 'fact_other' : 'fact_gate',
            !separate,
          ),
        );
        final optional = StorylineAsset(
          id: 'story_optional',
          type: StorylineType.sideQuest,
          status: StorylineStatus.active,
          title: 'Quête secondaire',
          chapters: [
            StorylineChapter(
              id: 'chapter_optional',
              title: 'Guide',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_optional',
                  title: 'Suivre le guide',
                  order: 0,
                  sceneLinkIds: const ['scene_optional'],
                  completionCondition: equals('fact_gate', !separate),
                ),
              ],
            ),
          ],
        );
        final map = fixture.map.copyWith(
          entities: [
            ...fixture.map.entities,
            const MapEntity(
              id: 'npc_second',
              name: 'Second guide',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 4),
            ),
          ],
        );
        final scene = SceneAsset(
          id: 'scene_optional',
          name: 'Optionnelle',
          storylineId: optional.id,
          chapterId: optional.chapters.single.id,
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              if (unknown)
                SceneNode(
                  id: 'check',
                  kind: SceneNodeKind.condition,
                  payload: SceneConditionPayload(
                    conditionSource: SceneConditionSource.playerFacing(
                      direction: EntityFacing.north,
                      expected: true,
                    ),
                  ),
                ),
              setTrue('grant', 'fact_gate'),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              link('start', 'completed', unknown ? 'check' : 'grant'),
              if (unknown) ...[
                link('check', 'true', 'grant', SceneEdgeKind.conditionTrue),
                link('check', 'false', 'end', SceneEdgeKind.conditionFalse),
              ],
              link('grant', 'completed', 'end'),
            ],
          ),
        );
        final project = fixture.project.copyWith(
          facts: [
            ...fixture.project.facts,
            if (separate)
              NarrativeFactDefinition(id: 'fact_other', label: 'Autre état'),
          ],
          storylines: [
            story.copyWith(
              chapters: [
                chapter.copyWith(steps: [step]),
              ],
            ),
            optional,
          ],
          scenes: [...fixture.project.scenes, scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              ...fixture.project.eventRegistry!.records,
              _record(id: _eventB, entityId: 'npc_second', sceneId: scene.id),
            ],
            legacyClaims: const [],
          ),
        );
        final report = validateNarrativeProject(project, maps: [map]);
        final symbolic = report.symbolicReachability!;
        final component = symbolic.independentFactComponents.singleWhere(
          (component) => component.factIds.contains('fact_gate'),
        );
        final witnesses = component.states.where(
          (s) => s.hasTrueFact('fact_gate'),
        );
        expect(witnesses, isNotEmpty);
        expect(witnesses.every((s) => s.indeterminate), unknown);
        if (unknown && !separate) {
          expect(
            report.byCode('storylineStepNeverCompleted').map((d) => d.stepId),
            contains(step.id),
          );
        } else {
          expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
          expect(report.isPlayable, isTrue);
        }
      },
    );
  }

  group('interpolation references in authored player text',
      _presentationTextReferenceTests);

  group('Narrative project validator', () {
    for (final value in [
      const NarrativeValue.string('heartgold'),
      NarrativeValue.integer(2),
    ]) {
      test('validates reachable ${value.kind.wireName} Fact assignments', () {
        final fixture = _fixture();
        final scene = fixture.project.scenes.single;
        final typedScene = SceneAsset(
          id: scene.id,
          name: scene.name,
          graph: SceneGraph(
            startNodeId: scene.graph.startNodeId,
            nodes: [
              ...scene.graph.nodes,
              SceneNode(
                id: 'set_choice',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneSetFactConsequence.typed(
                    factId: 'fact_choice',
                    value: value,
                  ),
                ),
              ),
            ],
            edges: [
              ...scene.graph.edges.where((edge) => edge.id != 'start_action'),
              SceneEdge(
                id: 'start_choice',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'set_choice',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'choice_action',
                fromNodeId: 'set_choice',
                fromPortId: 'completed',
                toNodeId: 'complete_step',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        );
        final report = validateNarrativeProject(
          fixture.project.copyWith(
            scenes: [typedScene],
            facts: [
              ...fixture.project.facts,
              NarrativeFactDefinition(
                id: 'fact_choice',
                label: 'Choix de version',
                initialValue: value,
              ),
            ],
          ),
          maps: [fixture.map],
        );

        expect(report.isPlayable, isTrue);
        expect(report.errorCount, 0);
        expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
      });
    }

    for (final value in [
      NarrativeValue.integer(0),
      const NarrativeValue.string('heartgold'),
      const NarrativeValue.boolean(false),
    ]) {
      test('respects typed World Rule equality for ${value.kind.wireName}', () {
        final fixture = _fixture();
        final project = fixture.project.copyWith(
          facts: [...fixture.project.facts,
            NarrativeFactDefinition(id: 'fact_phase', label: 'Phase', initialValue: value)],
          worldRules: [WorldRuleDefinition(
            id: 'phase_visibility', label: 'Phase visibility',
            source: WorldRuleSource.factValue(factId: 'fact_phase',
              operator: NarrativeFactOperator.equals, expectedValue: value),
            target: WorldRuleTarget(kind: WorldRuleTargetKind.mapEntity,
              mapId: fixture.map.id, entityId: 'npc_guide'),
            effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
          )],
        );
        final report = validateNarrativeProject(project, maps: [fixture.map]);
        expect(report.byCode('requiredFactNeverProduced'), isEmpty);
        expect(report.isPlayable, isTrue);
      });
    }

    test('validates scene actors and NPC presence against the loaded maps', () {
      final fixture = _fixture();
      final scene = SceneAsset(
        id: 'map_references',
        name: 'Map references',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'presence',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneSetNpcPresenceConsequence(
                  mapId: fixture.map.id,
                  entityId: 'npc_guide',
                  present: false,
                ),
              ),
            ),
            SceneNode(
              id: 'route',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                interactiveCommand: SceneActorRouteInteractiveCommand(
                  target: SceneActorTarget.player(mapId: fixture.map.id),
                  steps: [SceneActorRouteStep.move(direction: EntityFacing.north, durationMs: 200)],
                ),
              ),
            ),
          ],
          edges: const [],
        ),
      );
      final project = fixture.project.copyWith(
        scenes: [...fixture.project.scenes, scene],
      );
      final loaded = validateNarrativeProject(project, maps: [fixture.map]);
      expect(loaded.byCode('consequenceUnknownNpc'), isEmpty);
      expect(loaded.byCode('commandInvalidActorTarget'), isEmpty);

      final missingNpc = validateNarrativeProject(project, maps: [
        fixture.map.copyWith(entities: fixture.map.entities
            .where((entity) => entity.id != 'npc_guide').toList()),
      ]);
      expect(missingNpc.byCode('consequenceUnknownNpc'), hasLength(1));
      expect(missingNpc.byCode('commandInvalidActorTarget'), isEmpty);

      final unloaded = validateNarrativeProject(project, maps: const []);
      expect(unloaded.byCode('consequenceUnknownNpc'), hasLength(1));
      expect(unloaded.byCode('commandInvalidActorTarget'), hasLength(1));
    });

    test('aggregates a playable project and exposes its map Event view', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isTrue);
      expect(report.errorCount, 0);
      expect(report.mapEventViews, hasLength(1));
      final mapView = report.mapEventViews.single;
      expect(mapView.mapId, 'map_port');
      expect(mapView.events, hasLength(1));
      expect(mapView.events.single.eventId, _eventA);
      expect(mapView.events.single.sourceConnected, isTrue);
      expect(mapView.events.single.sourceEntityKind, MapEntityKind.npc);
      expect(mapView.events.single.sourceOwnerLabel, 'Guide');
      expect(mapView.events.single.sceneConnected, isTrue);
      expect(mapView.events.single.sceneLabel, 'Introduction');
      expect(mapView.events.single.conditionCount, 0);
    });

    for (final expectedValue in [true, false]) {
      test('accepts the Storyline completion Fact reaching $expectedValue', () {
        final fixture = _fixture(completeStep: false);
        final story = fixture.project.storylines.single;
        final chapter = story.chapters.single;
        final step = chapter.steps.single.copyWith(
          completionCondition: ScriptConditionFactory.factEquals(
            'fact_gate',
            NarrativeValue.boolean(expectedValue),
          ),
        );
        final project = fixture.project.copyWith(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate',
              label: 'Passage ouvert',
              initialValue: NarrativeValue.boolean(!expectedValue),
            ),
          ],
          storylines: [
            story.copyWith(chapters: [chapter.copyWith(steps: [step])]),
          ],
        );
        final incomplete = validateNarrativeProject(project, maps: [fixture.map]);
        expect(incomplete.byCode('storylineStepNeverCompleted').single.stepId, step.id);

        final scene = _scene(completeStep: true);
        final sceneWithFact = SceneAsset(
          id: scene.id,
          name: scene.name,
          graph: SceneGraph(
            startNodeId: scene.graph.startNodeId,
            nodes: [
              for (final node in scene.graph.nodes)
                if (node.id == 'complete_step')
                  SceneNode(
                    id: node.id,
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.setFact(
                        factId: 'fact_gate',
                        value: expectedValue,
                      ),
                    ),
                  )
                else
                  node,
            ],
            edges: scene.graph.edges,
          ),
        );
        final report = validateNarrativeProject(
          project.copyWith(scenes: [sceneWithFact]),
          maps: [fixture.map],
        );
        expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
        expect(report.isPlayable, isTrue);
      });
    }

    test('reports an impossible Step and a required Fact never produced', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.byCode('storylineStepNeverCompleted').single.stepId,
        'step_intro',
      );
      final factDiagnostic = report.byCode('requiredFactNeverProduced').single;
      expect(factDiagnostic.factId, 'fact_gate');
      expect(
        factDiagnostic.destination,
        NarrativeProjectDiagnosticDestination.fact,
      );
      expect(
        report.byDomain(NarrativeProjectDiagnosticDomain.storyline),
        isNotEmpty,
      );
    });

    test('ignores Fact producers that are unreachable inside a Scene', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final unreachableProducer = SceneNode(
        id: 'unreachable_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            SceneAsset(
              id: scene.id,
              name: scene.name,
              description: scene.description,
              storylineId: scene.storylineId,
              chapterId: scene.chapterId,
              tags: scene.tags,
              graph: SceneGraph(
                startNodeId: scene.graph.startNodeId,
                nodes: [...scene.graph.nodes, unreachableProducer],
                edges: scene.graph.edges,
              ),
              declaredOutcomes: scene.declaredOutcomes,
              metadata: scene.metadata,
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not let an Event unlock itself with its own Scene Fact', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final selfProducer = SceneNode(
        id: 'self_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );
      final selfGatedScene = SceneAsset(
        id: scene.id,
        name: scene.name,
        graph: SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: [...scene.graph.nodes, selfProducer],
          edges: [
            SceneEdge(
              id: 'start_self_fact',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'self_fact',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'self_fact_complete',
              fromNodeId: 'self_fact',
              fromPortId: 'completed',
              toNodeId: 'complete_step',
              kind: SceneEdgeKind.actionCompleted,
            ),
            ...scene.graph.edges.where(
              (edge) => edge.id != 'start_action',
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [selfGatedScene]),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepInaccessible'), hasLength(1));
    });

    test(
        'does not apply Storyline effects from an outcome the reachable Scene cannot emit',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'available_outcome',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'impossible_outcome',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('does not apply Storyline effects from an unreachable Scene producer',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenScene = _outcomeScene(
        id: 'scene_hidden',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenScene],
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: hiddenScene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('ignores Storyline outcome effects the game never executes', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
      expect(report.symbolicReachability!.trueFactIds,
          isNot(contains('fact_gate')));
      expect(report.symbolicReachability!.completedStepIds,
          isNot(contains('step_intro')));
    });

    test('legacy reachability stops at the first applicable disabled page', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenProducer = _factProducingScene('scene_legacy_hidden');
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_gate',
            pages: const [
              MapEventPage(pageNumber: 0, isDisabled: true),
              MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_hidden',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenProducer],
        ),
        maps: [map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test(
        'legacy reachability keeps the fallback when a typed Fact condition can become false',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_conditional_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.factEquals(
                  'fact_gate',
                  const NarrativeValue.boolean(true),
                ),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate initially open',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Fallback reached',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_legacy_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), isEmpty);
    });

    test('legacy reachability does not invent a jointly impossible fallback',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_exhaustive_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('fact_gate'),
              ),
              MapEventPage(
                pageNumber: 1,
                condition: ScriptConditionFactory.flagIsUnset('fact_gate'),
              ),
              const MapEventPage(
                pageNumber: 2,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_impossible_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Impossible fallback',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_impossible_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('legacy reachability fails closed within a bounded state search', () {
      final fixture = _fixture(completeStep: false);
      final branchingFactIds = [
        for (var index = 0; index < 14; index++) 'fact_branch_$index',
      ];
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_large_condition_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.anyOf([
                  for (final factId in branchingFactIds)
                    ScriptConditionFactory.flagIsUnset(factId),
                ]),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_large_condition_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          for (final factId in branchingFactIds)
            NarrativeFactDefinition(id: factId, label: factId),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Large fallback reached',
          ),
        ],
        scenes: [
          ...fixture.project.scenes,
          _manyFactScene('scene_many_fact_values', branchingFactIds),
          _factScene(
            id: 'scene_large_condition_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            ...fixture.project.eventRegistry!.records,
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              sceneId: 'scene_many_fact_values',
            ),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not traverse a statically impossible Scene condition port', () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalFactScene(
            conditionFactId: 'fact_never',
            trueFactId: 'fact_unlock',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not emit an outcome behind an impossible Scene condition port',
        () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalOutcomeScene(conditionFactId: 'fact_never'),
          _factScene(
            id: 'scene_outcome_consumer',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: _eventB,
                name: 'Impossible outcome consumer',
                source: NarrativeEventSourceRef.outcomeReceived(
                  NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.scene,
                    producerId: 'scene_intro',
                    outcomeId: 'success',
                  ),
                ),
                conditions: const [],
                sceneId: 'scene_outcome_consumer',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('reports a missing configured New Game start spawn on its map', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_missing',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnMissing').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
      expect(diagnostic.path, contains('spawn_missing'));
    });

    test('reports a configured New Game start entity that is not playerStart',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'npc_guide',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnNotPlayerStart').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('reports a configured New Game start spawn outside map bounds', () {
      final fixture = _fixture();
      final map = fixture.map.copyWith(
        entities: [
          for (final entity in fixture.map.entities)
            if (entity.id == 'spawn_player')
              entity.copyWith(pos: const GridPos(x: 16, y: 1))
            else
              entity,
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnOutOfBounds').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('accepts an in-bounds configured playerStart spawn', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('runtimeNewGameStartSpawnMissing'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnNotPlayerStart'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnOutOfBounds'), isEmpty);
    });

    test('reports an unknown trainer referenced only by a Scene battle', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_missing',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('battleTrainerRefUnknown').single;
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
      expect(diagnostic.sceneNodeId, 'battle');
    });

    test('reports an empty Scene-only static boss team', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'static',
              trainerId: 'trainer_boss',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_boss',
              name: 'Gardien',
              trainerClass: 'Static boss',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('sceneBattleTrainerHasEmptyTeam').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
      expect(diagnostic.sceneNodeId, 'battle');
    });

    test('reports missing authoritative species and moves in a Scene opponent',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_invalid_team',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_invalid_team',
              name: 'Dresseur incomplet',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(speciesId: '', level: 5),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonMissingSpecies'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMissingMoves'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in a Scene-only opponent', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_unknown_catalog_ids',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_unknown_catalog_ids',
              name: 'Dresseur invalide',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(
                  speciesId: 'missing_species',
                  level: 5,
                  moves: ['missing_move'],
                ),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
        knownSpeciesIds: const {'bulbasaur'},
        knownMoveIds: const {'tackle'},
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonSpeciesUnknown'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMoveUnknown'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in every New Game starter option', () {
      final fixture = _fixture();
      final project = fixture.project.copyWith(
        newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: fixture.map.id,
          starterOptions: const [
            ProjectStarterOption(
              id: 'starter_missing',
              label: 'Starter invalide',
              pokemon: PlayerPokemon(
                speciesId: 'missing_species',
                natureId: 'hardy',
                abilityId: 'missing_ability',
                knownMoveIds: ['missing_move'],
                level: 5,
                currentHp: 20,
              ),
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        project,
        maps: [fixture.map],
        knownSpeciesIds: const <String>{},
        knownMoveIds: const <String>{},
      );

      expect(report.byCode('runtimeMissingPokemonSpecies'), hasLength(1));
      expect(report.byCode('runtimeMissingPokemonMove'), hasLength(1));
    });

    test('fails closed when required Pokemon catalogs were not loaded', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
        requirePokemonCatalogs: true,
      );

      expect(
        report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
        hasLength(1),
      );
      expect(
        report.byCode('runtimePokemonMoveCatalogUnavailable'),
        hasLength(1),
      );
    });

    test('reports a dependency cycle as an impossible narrative branch', () {
      final fixture = _fixture(eventDependencyCycle: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.diagnostics.any(
          (diagnostic) =>
              diagnostic.domain == NarrativeProjectDiagnosticDomain.event &&
              diagnostic.code.toLowerCase().contains('cycle'),
        ),
        isTrue,
      );
    });

    test('keeps an orphaned map source visible and navigable', () {
      final fixture = _fixture(orphanSource: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      final event = report.mapEventViews.single.events.single;
      expect(event.sourceConnected, isFalse);
      expect(event.sourceOwnerId, 'npc_missing');
      expect(event.diagnosticCount, greaterThan(0));
      final diagnostic = report.diagnostics.firstWhere(
        (item) => item.eventId == _eventA && item.mapId == 'map_port',
      );
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
    });

    test('reports Storylines without a beginning or an ending', () {
      final fixture = _fixture();
      final emptyStoryline = StorylineAsset(
        id: 'story_empty',
        type: StorylineType.sideQuest,
        status: StorylineStatus.active,
        title: 'Quête vide',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          storylines: [...fixture.project.storylines, emptyStoryline],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('storylineMissingBeginning'), hasLength(1));
      expect(report.byCode('storylineMissingEnding'), hasLength(1));
      expect(
        report.byCode('storylineImpossible').single.storylineId,
        'story_empty',
      );
    });

    test('keeps a superseded Global Story authoring Scenario as a warning only',
        () {
      final fixture = _fixture();
      const legacyAuthoringGraph = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: [
          ScenarioEdge(
            id: 'start_end',
            fromNodeId: 'start',
            toNodeId: 'end',
          ),
        ],
        metadata: {
          'authoring.globalStoryStudioSchema': 'global_story_studio_v1.1',
        },
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenarios: const [legacyAuthoringGraph]),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('scenarioGraphHasNoSource').single;
      expect(
        diagnostic.severity,
        NarrativeProjectDiagnosticSeverity.warning,
      );
      expect(report.isPlayable, isTrue);
    });

    test('reports a one-shot Event that owns an explicitly retryable ending',
        () {
      final fixture = _fixture();
      final retryableScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'the_player_may_continue',
        policy: SceneOutcomePolicy.retryable,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [retryableScene]),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('oneShotRetryableOutcomeSoftlock').single;
      expect(diagnostic.eventId, _eventA);
      expect(diagnostic.sceneId, retryableScene.id);
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
    });

    for (final sameSource in [false, true]) {
    test('checks whether a reusable retry source can be selected ($sameSource)', () {
      final fixture = _fixture();
      final retryableScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'try_again',
        policy: SceneOutcomePolicy.retryable,
      );
      final reusableRetry = _record(
        id: _eventB,
        entityId: sameSource ? 'npc_guide' : 'npc_second',
        reusePolicy: NarrativeEventReusePolicy.reusable,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [retryableScene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              ...fixture.project.eventRegistry!.records,
              reusableRetry,
            ],
            legacyClaims: const [],
          ),
        ),
        maps: [_h10CounterMap(fixture.map)],
      );

      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), hasLength(sameSource ? 1 : 0));
    });
    }

    test('accepts an explicitly terminal failure without a retry source', () {
      final fixture = _fixture();
      final terminalScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'permanent_failure',
        policy: SceneOutcomePolicy.terminalFailureAccepted,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [terminalScene]),
        maps: [fixture.map],
      );

      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), isEmpty);
      expect(report.byCode('sceneOutcomePolicyIndeterminate'), isEmpty);
    });

    test('keeps an unannotated outcome indeterminate without label heuristics',
        () {
      final fixture = _fixture();
      final unannotated = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'defeat_retry_softlock',
        policy: null,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [unannotated]),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('sceneOutcomePolicyIndeterminate').single;
      expect(diagnostic.sceneId, unannotated.id);
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.warning);
      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), isEmpty);
    });
  });
}


/// BETA-CIN-086 — un placeholder malformé ne doit plus atteindre un joueur.
///
/// L'interpolateur laisse littérale toute référence qu'il ne reconnaît pas,
/// exprès. Mais rien ne relisait ce texte avant la certification, et la fixture
/// Night Watch a été packagée, certifiée, installée et jouée avec
/// `{draft.playerName}` affiché brut. Le Validator regarde maintenant.
void _presentationTextReferenceTests() {
  SceneAsset sceneWithPrompt(String fallbackText) => SceneAsset(
        id: 'presession',
        name: 'Pre-session',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'confirm',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                preSessionInteraction:
                    ScenePreSessionInteractionSpec.confirmation(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'confirm',
                    fallbackText: fallbackText,
                  ),
                ),
              ),
            ),
          ],
          edges: const <SceneEdge>[],
        ),
      );

  test('a single-brace reference is an error the export refuses', () {
    final fixture = _fixture();
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[
          ...fixture.project.scenes,
          sceneWithPrompt('Le registre dira donc {draft.playerName}.'),
        ],
      ),
      maps: <MapData>[fixture.map],
    );

    final issues = report.byCode('presentationTextReferenceUnresolvable');
    expect(issues, hasLength(1));
    expect(issues.single.sceneNodeId, 'confirm');
    expect(issues.single.severity, NarrativeProjectDiagnosticSeverity.error);
    expect(
      issues.single.path,
      'scenes.presession.nodes.confirm.preSessionInteraction.prompt',
    );
    expect(
      report.isPlayable,
      isFalse,
      reason: 'an error diagnostic is what makes the export refuse; a '
          'diagnostic nobody consumes was the original defect',
    );
  });

  test('the canonical form is accepted', () {
    final fixture = _fixture();
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[
          ...fixture.project.scenes,
          sceneWithPrompt('Le registre dira donc {{draft.playerName}}.'),
        ],
      ),
      maps: <MapData>[fixture.map],
    );

    expect(report.byCode('presentationTextReferenceUnresolvable'), isEmpty);
  });

  test('an option label is audited too, not only the prompt', () {
    final fixture = _fixture();
    final scene = SceneAsset(
      id: 'presession',
      name: 'Pre-session',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'pick',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(
              preSessionInteraction: ScenePreSessionInteractionSpec.choice(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'pick',
                  fallbackText: 'Qui prend la veille ?',
                ),
                options: <SceneInteractionOption>[
                  SceneInteractionOption(
                    id: 'dawn',
                    label: SceneInteractionPrompt(
                      localizationKey: 'dawn',
                      fallbackText: 'Celle que {draft.playerName} attend.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        edges: const <SceneEdge>[],
      ),
    );
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[...fixture.project.scenes, scene],
      ),
      maps: <MapData>[fixture.map],
    );

    final issue = report.byCode('presentationTextReferenceUnresolvable').single;
    expect(issue.sceneNodeId, 'pick');
    expect(
      issue.path,
      'scenes.presession.nodes.pick.preSessionInteraction.options[0].label',
    );
  });
}

MapLayer _h10CollisionAt(MapData map, GridPos blocked) => MapLayer.collision(
  id: 'wall',
  name: 'Mur',
  collisions: List.generate(
    map.size.width * map.size.height,
    (index) => index == map.size.width * blocked.y + blocked.x,
  ),
);

MapData _h10CounterMap(MapData map) => map.copyWith(entities: [
  ...map.entities,
  const MapEntity(
    id: 'npc_second', name: 'Second guide', kind: MapEntityKind.npc,
    pos: GridPos(x: 4, y: 4),
  ),
  const MapEntity(
    id: 'npc_optional', name: 'Guide optionnel', kind: MapEntityKind.npc,
    pos: GridPos(x: 5, y: 4),
  ),
]);

SceneAsset _h10CounterScene(
  String id,
  List<SceneConsequence> actions, {
  String? storylineId,
  String? chapterId,
}) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (final (index, action) in actions.indexed)
      SceneNode(
        id: 'action_$index', kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(action),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: id, name: id, storylineId: storylineId, chapterId: chapterId,
    graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: [
      for (var i = 0; i < nodes.length - 1; i++)
        SceneEdge(
          id: 'flow_$i', fromNodeId: nodes[i].id, fromPortId: 'completed',
          toNodeId: nodes[i + 1].id, kind: SceneEdgeKind.defaultFlow,
        ),
    ]),
  );
}

({ProjectManifest project, MapData map}) _fixture({
  bool completeStep = true,
  bool requireFact = false,
  bool eventDependencyCycle = false,
  bool orphanSource = false,
}) {
  final map = MapData(
    id: 'map_port',
    name: 'Port',
    size: const GridSize(width: 16, height: 16),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_player'),
    entities: const [
      MapEntity(
        id: 'spawn_player',
        name: 'Départ',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntity(
        id: 'npc_guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 4),
      ),
    ],
  );
  final scene = _scene(completeStep: completeStep);
  final records = <NarrativeEventRecord>[
    _record(
      id: _eventA,
      entityId: orphanSource ? 'npc_missing' : 'npc_guide',
      conditions: [
        if (requireFact) NarrativeEventCondition.fact('fact_gate', true),
        if (eventDependencyCycle)
          NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
      ],
    ),
    if (eventDependencyCycle)
      _record(
        id: _eventB,
        entityId: 'npc_guide',
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
        ],
      ),
  ];

  return (
    map: map,
    project: ProjectManifest(
      name: 'Validator fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/map_port.json',
        ),
      ],
      tilesets: const [],
      scenes: [scene],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Passage ouvert'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_main',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Histoire principale',
          chapters: [
            StorylineChapter(
              id: 'chapter_intro',
              title: 'Introduction',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_intro',
                  title: 'Rencontrer le guide',
                  order: 0,
                  sceneLinkIds: const ['scene_intro'],
                ),
              ],
            ),
          ],
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    ),
  );
}

NarrativeEventRecord _record({
  required String id,
  String entityId = 'npc_guide',
  NarrativeEventSourceRef? source,
  String sceneId = 'scene_intro',
  List<NarrativeEventCondition> conditions = const [],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
  int? order,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: 'Event $id',
      source: source ?? NarrativeEventSourceRef.entityInteract('map_port', entityId),
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: order ?? (id == _eventA ? 0 : 1),
    ),
    enabled: true,
  );
}

SceneAsset _withEndPolicy(
  SceneAsset scene, {
  required String? sceneOutcomeId,
  required SceneOutcomePolicy? policy,
}) {
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          if (node.kind == SceneNodeKind.end)
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: node.title,
              description: node.description,
              payload: SceneEndPayload(
                sceneOutcomeId: sceneOutcomeId,
                outcomePolicy: policy,
              ),
            )
          else
            node,
      ],
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: sceneOutcomeId == null
        ? scene.declaredOutcomes
        : [SceneOutcome(id: sceneOutcomeId, label: sceneOutcomeId)],
    metadata: scene.metadata,
  );
}

SceneAsset _scene({required bool completeStep}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (completeStep)
      SceneNode(
        id: 'complete_step',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.completeStoryStep(stepId: 'step_intro'),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scene_intro',
    name: 'Introduction',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: completeStep
          ? [
              SceneEdge(
                id: 'start_action',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'complete_step',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'action_end',
                fromNodeId: 'complete_step',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ]
          : [
              SceneEdge(
                id: 'start_end',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
    ),
  );
}

SceneAsset _outcomeScene({
  required String id,
  required String emittedOutcomeId,
}) {
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: [
      SceneOutcome(id: emittedOutcomeId, label: emittedOutcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: emittedOutcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'start_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factProducingScene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'fact_gate', value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({
  required String id,
  required String factId,
  required bool value,
}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: value),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _manyFactScene(String id, List<String> factIds) {
  final actionIds = [
    for (var index = 0; index < factIds.length; index++) 'set_fact_$index',
  ];
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < factIds.length; index++)
          SceneNode(
            id: actionIds[index],
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: factIds[index],
                value: true,
              ),
            ),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_to_first',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: actionIds.first,
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (var index = 0; index < actionIds.length - 1; index++)
          SceneEdge(
            id: 'action_${index}_to_${index + 1}',
            fromNodeId: actionIds[index],
            fromPortId: 'completed',
            toNodeId: actionIds[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
        SceneEdge(
          id: 'last_to_end',
          fromNodeId: actionIds.last,
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalFactScene({
  required String conditionFactId,
  required String trueFactId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional fact',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'true_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: trueFactId, value: true),
          ),
        ),
        SceneNode(id: 'true_end', kind: SceneNodeKind.end),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_condition',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'condition_true',
          fromNodeId: 'condition',
          fromPortId: 'true',
          toNodeId: 'true_action',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
        SceneEdge(
          id: 'true_action_end',
          fromNodeId: 'true_action',
          fromPortId: 'completed',
          toNodeId: 'true_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalOutcomeScene({required String conditionFactId}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional outcome',
    declaredOutcomes: [SceneOutcome(id: 'success', label: 'Success')],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'success_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'success'),
        ),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_condition',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'condition_true',
          fromNodeId: 'condition',
          fromPortId: 'true',
          toNodeId: 'success_end',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
      ],
    ),
  );
}

StorylineAsset _storylineWithOutcomeEffects({
  required StorylineAsset base,
  required String sceneId,
  required String outcomeId,
}) {
  return StorylineAsset(
    id: base.id,
    type: base.type,
    status: base.status,
    title: base.title,
    chapters: base.chapters,
    sceneLinks: [
      StorylineSceneLink(
        id: 'link_$sceneId',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        label: sceneId,
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: sceneId,
        ),
        order: 0,
        expectedOutcomeIds: [outcomeId],
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'effect_$outcomeId',
            outcomeId: outcomeId,
            effects: [
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_intro',
              ),
              StorylineEffect(
                type: StorylineEffectType.emitFact,
                targetId: 'fact_gate',
                value: 'true',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

SceneAsset _battleScene({
  required String battleKind,
  required String trainerId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Combat',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: battleKind,
            trainerId: trainerId,
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
