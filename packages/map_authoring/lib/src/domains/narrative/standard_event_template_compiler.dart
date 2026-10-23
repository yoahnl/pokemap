part of 'standard_event_template.dart';

StandardEventTemplateProjection _compile(
    {required ProjectManifest project,
    required List<MapData> maps,
    required StandardEventTemplateSpec spec,
    required ProjectItemCatalog? itemCatalog,
    required bool allowOwned,
    bool validateDestination = true}) {
  if (project.settings.dimension != ProjectDimension.twoD) {
    _reject('dimension_unsupported',
        'Les événements standards sont disponibles sur les cartes 2D.');
  }
  final registry = project.eventRegistry;
  if (registry == null || registry.mode == EventSystemMode.legacyOnly) {
    _reject('registry_mode',
        'Activez explicitement le système Event V2 avant de créer un événement standard.');
  }
  final map = _one(maps.where((map) => map.id == spec.mapId), 'map');
  if (map.spatialScene != null || map.version == ProjectVersion.v9) {
    _reject('dimension_unsupported',
        'Les événements standards demandent une carte 2D.');
  }
  final entity = _one(
      map.entities.where((entity) => entity.id == spec.entityId), 'entity');
  if (!const [MapEntityKind.custom, MapEntityKind.npc].contains(entity.kind)) {
    _reject(
        'entity_kind', 'Choisissez un personnage ou un élément personnalisé.');
  }
  for (final field in ['dialogueId', 'alternateDialogueId']) {
    final id = spec.parameters[field];
    if (id != null) {
      _one(project.dialogues.where((value) => value.id == id), 'dialogue');
    }
  }
  for (final field in ['characterId', 'alternateCharacterId']) {
    final id = spec.parameters[field];
    if (id != null) {
      _one(project.characters.where((value) => value.id == id), 'character');
    }
  }
  final itemId = spec.parameters['itemId'];
  if (itemId != null && itemCatalog != null) {
    _one(itemCatalog.entries.where((value) => value.id == itemId), 'item');
  }
  if (spec.kind == StandardEventTemplateKind.conditionalNpc) {
    final fact = _one(
        project.facts.where((value) => value.id == spec.text('factId')),
        'fact');
    if (fact.valueKind != NarrativeValueKind.boolean) {
      _reject('fact_type', 'Le changement de page demande un fait booléen.');
    }
  }
  if (spec.kind == StandardEventTemplateKind.trainer) {
    _one(project.trainers.where((value) => value.id == spec.text('trainerId')),
        'trainer');
  }
  if (spec.kind == StandardEventTemplateKind.lockedDoor &&
      validateDestination) {
    final destination = _one(
        maps.where((value) => value.id == spec.text('destinationMapId')),
        'destination map');
    _one(
        destination.warps
            .where((value) => value.id == spec.text('destinationWarpId')),
        'destination warp');
  }
  final owner = jsonEncode([spec.mapId, spec.entityId]);
  final pageNames = spec.kind == StandardEventTemplateKind.conditionalNpc
      ? ['before', 'after']
      : ['main'];
  String eventId(String page) {
    final hex = sha256
        .convert(utf8.encode(jsonEncode(
            ['standardEventTemplate', 1, spec.mapId, spec.entityId, page])))
        .toString();
    return 'evt_${hex.substring(0, 8)}-${hex.substring(8, 12)}-7${hex.substring(13, 16)}-8${hex.substring(17, 20)}-${hex.substring(20, 32)}';
  }

  final eventIds = pageNames.map(eventId).toSet();
  final sceneIds = eventIds.map((id) => 'scene_$id').toSet();
  if (allowOwned) {
    final index = buildNarrativeDependencyIndex(project: project, maps: maps);
    for (final id in sceneIds) {
      if (index.usagesFor(NarrativeDependencyKey.scene(id)).any((usage) =>
          usage.owner.kind != NarrativeDependencyTargetKind.eventV2 ||
          !eventIds.contains(usage.owner.id))) {
        _reject('scene_shared',
            'Une scène générée est utilisée ailleurs ; ouvrez les détails avancés pour conserver cette liaison.');
      }
    }
  }
  for (final record in registry.records) {
    final source =
        record.definitionOrNull?.source ?? record.draftOrNull?.source;
    final wire = source?.toJson();
    if ((wire?['mapId'] == spec.mapId &&
            wire?['entityId'] == spec.entityId &&
            !eventIds.contains(record.id)) ||
        (!allowOwned && eventIds.contains(record.id))) {
      _reject('source_owned',
          'Une autre interaction utilise déjà cet élément ou ses identifiants.');
    }
  }
  for (final scene
      in project.scenes.where((scene) => sceneIds.contains(scene.id))) {
    if (!allowOwned || scene.metadata[_ownerKey] != owner) {
      _reject('scene_owned',
          'Une scène existante utilise déjà un identifiant réservé à cet événement.');
    }
  }
  final events = <NarrativeEventRecord>[];
  final scenes = <SceneAsset>[];
  final pages = <StandardEventTemplatePage>[];
  for (var index = 0; index < pageNames.length; index++) {
    final pageName = pageNames[index];
    final id = eventId(pageName);
    final condition = switch (spec.kind) {
      StandardEventTemplateKind.conditionalNpc =>
        NarrativeEventConditionExpression.leaf(NarrativeEventCondition.fact(
            spec.text('factId'), pageName == 'after')),
      StandardEventTemplateKind.pickup =>
        NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.narrativeEventConsumed(id, false)),
      _ => NarrativeEventConditionExpression.all([]),
    };
    final characterId = pageName == 'after'
        ? spec.parameters['alternateCharacterId'] as String? ??
            spec.parameters['characterId'] as String?
        : spec.parameters['characterId'] as String?;
    final appearance = MapEntityPresentationVariant(
        id: id,
        condition: condition,
        characterId: characterId,
        blocksMovement: true,
        facing: entity.npc?.facing ?? EntityFacing.south,
        interactionMode: MapEntityInteractionMode.front);
    final builder = _TemplateSceneBuilder(
        'scene_$id', '${spec.name} — $pageName', owner, spec.kind);
    final actions = <String>[];
    switch (spec.kind) {
      case StandardEventTemplateKind.conditionalNpc:
        final dialogueId = spec
            .text(pageName == 'after' ? 'alternateDialogueId' : 'dialogueId');
        builder.dialogue('dialogue', dialogueId);
        builder.edge('start', 'completed', 'dialogue');
        builder.edge('dialogue', 'completed', 'end');
        actions.add(
            'Dialogue ${_templateResourceName(project, 'dialogueId', dialogueId)}');
      case StandardEventTemplateKind.pickup:
        builder.action(
            'receive',
            SceneInteractiveCommand.giveItem(
                itemId: spec.text('itemId'),
                quantity: spec.parameters['quantity'] as int));
        builder.retry();
        builder.edge('start', 'completed', 'receive');
        builder.edge(
            'receive', 'bagFull', 'retry', SceneEdgeKind.actionCompleted);
        if (spec.parameters['dialogueId'] case final String dialogueId) {
          builder.dialogue('feedback', dialogueId);
          builder.edge(
              'receive', 'received', 'feedback', SceneEdgeKind.actionCompleted);
          builder.edge('feedback', 'completed', 'end');
        } else {
          builder.edge(
              'receive', 'received', 'end', SceneEdgeKind.actionCompleted);
        }
        actions.addAll([
          'Recevoir ${spec.parameters['quantity']} × ${_templateResourceName(project, 'itemId', spec.text('itemId'), itemCatalog: itemCatalog)}',
          'Succès : consommer cette instance et masquer son apparence',
          'Sac plein : conserver l’objet disponible'
        ]);
      case StandardEventTemplateKind.lockedDoor:
        builder.condition('gate', _inventoryCondition(spec.text('itemId')));
        builder.dialogue('locked', spec.text('dialogueId'));
        builder.action(
            'warp',
            SceneInteractiveCommand.warp(
                destinationMapId: spec.text('destinationMapId'),
                warpId: spec.text('destinationWarpId')));
        builder.edge('start', 'completed', 'gate');
        builder.edge('gate', 'true', 'warp', SceneEdgeKind.conditionTrue);
        builder.edge('gate', 'false', 'locked', SceneEdgeKind.conditionFalse);
        builder.edge('locked', 'completed', 'end');
        builder.edge('warp', 'completed', 'end', SceneEdgeKind.actionCompleted);
        builder.edge(
            'warp', 'blocked', 'locked', SceneEdgeKind.actionCompleted);
        actions.addAll([
          'Vérifier l’objet ${_templateResourceName(project, 'itemId', spec.text('itemId'), itemCatalog: itemCatalog)}',
          'Présent : passage vers ${_templateResourceName(project, 'destinationMapId', spec.text('destinationMapId'))}',
          'Absent : dialogue ${_templateResourceName(project, 'dialogueId', spec.text('dialogueId'))}'
        ]);
      case StandardEventTemplateKind.trainer:
        builder.condition(
            'defeated',
            SceneConditionSource.trainerDefeated(
                trainerId: spec.text('trainerId')));
        builder.dialogue('before', spec.text('dialogueId'));
        builder.dialogue('after', spec.text('alternateDialogueId'));
        builder.nodes.add(SceneNode(
            id: 'battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: spec.text('trainerId'),
                npcEntityId: spec.entityId,
                declaredOutcomes: ['victory', 'defeat'])));
        builder.retry();
        builder.edge('start', 'completed', 'defeated');
        builder.edge('defeated', 'true', 'after', SceneEdgeKind.conditionTrue);
        builder.edge(
            'defeated', 'false', 'before', SceneEdgeKind.conditionFalse);
        builder.edge('before', 'completed', 'battle');
        builder.edge('battle', 'victory', 'after', SceneEdgeKind.battleVictory);
        builder.edge('battle', 'defeat', 'retry', SceneEdgeKind.battleDefeat);
        builder.edge('after', 'completed', 'end');
        actions.addAll([
          'Dialogue avant : ${_templateResourceName(project, 'dialogueId', spec.text('dialogueId'))}',
          'Combat ${_templateResourceName(project, 'trainerId', spec.text('trainerId'))}',
          'Victoire : dialogue ${_templateResourceName(project, 'alternateDialogueId', spec.text('alternateDialogueId'))}',
          'Défaite : nouvelle tentative'
        ]);
    }
    scenes.add(builder.build());
    events.add(NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: id,
            name: '${spec.name} — $pageName',
            source: NarrativeEventSourceRef.entityInteract(
                spec.mapId, spec.entityId),
            conditions: condition.leaves,
            conditionExpression: condition,
            sceneId: builder.id,
            reusePolicy: spec.kind == StandardEventTemplateKind.pickup
                ? NarrativeEventReusePolicy.oneShot
                : NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: index),
        enabled: true));
    pages.add(StandardEventTemplatePage(
        id: id,
        label: spec.kind == StandardEventTemplateKind.conditionalNpc
            ? pageName == 'after'
                ? 'Après le fait'
                : 'Avant le fait'
            : switch (spec.kind) {
                StandardEventTemplateKind.pickup => 'Objet disponible',
                StandardEventTemplateKind.lockedDoor =>
                  'Porte avec objet requis',
                _ => 'Dresseur avant / après victoire'
              },
        condition: condition,
        actions: actions,
        appearance: appearance));
  }
  final first = pages.first.appearance;
  final updated = entity.copyWith(
      name: spec.name,
      kind:
          first.characterId == null ? MapEntityKind.custom : MapEntityKind.npc,
      npc: first.characterId == null
          ? null
          : MapEntityNpcData(
              characterId: first.characterId, facing: first.facing),
      size: first.size,
      blocksMovement: first.blocksMovement,
      interactionMode: first.interactionMode,
      counterInteractionSides: [],
      editorVisual: null,
      presentation: MapEntityPresentation(
          variants: pages.map((page) => page.appearance).toList()),
      properties: {
        ...entity.properties,
        _recipeKey: canonicalizeNarrativeEventJson(spec.toJson())
      });
  return StandardEventTemplateProjection(
      spec: spec,
      map: map.copyWith(entities: [
        for (final value in map.entities)
          if (value.id == entity.id) updated else value
      ]),
      scenes: scenes,
      events: events,
      pages: pages);
}

final class _TemplateSceneBuilder {
  _TemplateSceneBuilder(this.id, this.name, this.owner, this.templateKind);
  final String id, name, owner;
  final StandardEventTemplateKind templateKind;
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload:
            SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression)),
  ];
  final edges = <SceneEdge>[];
  void dialogue(String id, String dialogueId) => nodes.add(SceneNode(
      id: id,
      kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(dialogueId: dialogueId)));
  void condition(String id, SceneConditionSource source) => nodes.add(SceneNode(
      id: id,
      kind: SceneNodeKind.condition,
      payload: SceneConditionPayload(conditionSource: source)));
  void action(String id, SceneInteractiveCommand command) =>
      nodes.add(SceneNode(
          id: id,
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(command)));
  void retry() => nodes.add(SceneNode(
      id: 'retry',
      kind: SceneNodeKind.end,
      payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.retryable)));
  void edge(String from, String port, String to,
          [SceneEdgeKind kind = SceneEdgeKind.defaultFlow]) =>
      edges.add(SceneEdge(
          id: '${from}_${port}_$to',
          fromNodeId: from,
          fromPortId: port,
          toNodeId: to,
          kind: kind));
  SceneAsset build() => SceneAsset(
          id: id,
          name: name,
          graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: edges),
          metadata: {
            _ownerKey: owner,
            'standardEventTemplate.kind': templateKind.name,
            'standardEventTemplate.schemaVersion': '1'
          });
}
