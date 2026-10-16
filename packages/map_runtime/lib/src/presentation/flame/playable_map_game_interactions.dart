part of 'playable_map_game.dart';

final class _ResolvedOverworldInteraction {
  const _ResolvedOverworldInteraction({
    required this.action,
    required this.result,
    this.entity,
    this.eventId,
    this.sceneId,
    this.isIntrinsicFieldObstacle = false,
    this.flashZoneId,
  });

  final RuntimeOverworldInteractionAction action;
  final GameplayStepResult result;
  final MapEntity? entity;
  final String? eventId;
  final String? sceneId;
  final bool isIntrinsicFieldObstacle;
  final String? flashZoneId;
}

extension _PlayableMapInteractions on PlayableMapGame {
  bool _canResolveOverworldInteraction({bool duringDispatch = false}) {
    if (_isRemoved ||
        _currentMapActivationId == null ||
        _onLoadInProgress ||
        _flowPhase != _RuntimeFlowPhase.overworld ||
        _activeBlockingInteractionSerial != null ||
        _blocksOverworldForMapActivationWork ||
        (!duringDispatch && _blocksOverworldForNarrativeDispatch) ||
        (!duringDispatch &&
            _narrativeActivityGate.activity != NarrativeRuntimeActivity.idle) ||
        _narrativeActivityGate.checkpointInProgress ||
        _suppressOverworldInputForScriptedPlayerMovement() ||
        _pendingTrainerSpot != null ||
        (_activeScriptController != null &&
            !_activeScriptController!.isTerminated)) {
      return false;
    }
    return !_inputLocks.snapshot.activeTokens.any(
      (token) =>
          !_derivedInputLocks.containsKey(token.owner) &&
          token.surface != RuntimeInputSurface.world,
    );
  }

  RuntimeOverworldInteractionSnapshot _readOverworldInteractionSnapshot() {
    final primaryAction = _resolveOverworldInteraction()?.action;
    final next = RuntimeOverworldInteractionSnapshot(
      sessionId: _interactionSessionId,
      mapActivationId: _currentMapActivationId ?? '',
      mapId: _activeMapId,
      movementContinuityId: '$_interactionSessionId:$_movementContinuityEpoch',
      primaryAction: primaryAction,
      tapAction: primaryAction ?? _resolveHiddenItemTapInteraction()?.action,
    );
    if (_cachedInteractionSnapshot != next) {
      _cachedInteractionSnapshot = next;
    }
    return _cachedInteractionSnapshot!;
  }

  _ResolvedOverworldInteraction? _resolveHiddenItemTapInteraction() {
    final interaction = _resolveOverworldInteraction(includeHidden: true);
    return interaction?.entity?.item?.visibility ==
            MapEntityItemVisibility.hidden
        ? interaction
        : null;
  }

  void _publishOverworldInteractions() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks ||
        binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks) {
      if (_interactionPublicationScheduled) return;
      _interactionPublicationScheduled = true;
      binding.scheduleFrame();
      binding.addPostFrameCallback((_) {
        _interactionPublicationScheduled = false;
        _flushOverworldInteractions();
      });
      return;
    }
    _flushOverworldInteractions();
  }

  void _flushOverworldInteractions() {
    final next = overworldInteractionSnapshot;
    if (_overworldInteractions.value != next) {
      _overworldInteractions.value = next;
    }
  }

  NarrativeEventDispatchAuthorityPreparation? _readInteractionAuthority(
    NarrativeEventOccurrence occurrence,
  ) {
    final project = _bundle.manifest;
    final registry = project.eventRegistry;
    if (registry == null ||
        (registry.mode == EventSystemMode.legacyOnly &&
            !registry.ownsSourceInLegacyMode(occurrence.source))) {
      return NarrativeEventDispatchAuthority.prepare(
        registryResult: registry == null
            ? EventRegistryDecodeResult.absent()
            : EventRegistryDecodeResult.decoded(registry),
        occurrence: occurrence,
        factResolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
      );
    }
    final snapshot = _cachedNarrativeRuntimeSnapshot;
    if (snapshot == null || !snapshot.matchesProject(project)) return null;
    return NarrativeEventDispatchAuthority.prepare(
      registryResult: snapshot.registryResult,
      occurrence: occurrence,
      factResolver: snapshot.factResolver,
      legacyClaimIndex: snapshot.legacyClaimIndex,
      projectCatalog: snapshot.projectCatalog,
      project: snapshot.project,
      maps: snapshot.mapsById.values.toList(growable: false),
    );
  }

  _ResolvedOverworldInteraction? _resolveOverworldInteraction({
    bool includeHidden = false,
    bool duringDispatch = false,
  }) {
    if (!_canResolveOverworldInteraction(duringDispatch: duringDispatch)) {
      return null;
    }
    final result = stepGameplayWorld(_world, const InteractIntent());
    final entity = switch (result) {
      NpcInteracted(:final entity) ||
      SignInteracted(:final entity) ||
      ItemInteracted(:final entity) ||
      EntityInteracted(:final entity) => entity,
      _ => null,
    };
    if (!includeHidden &&
        entity?.item?.visibility == MapEntityItemVisibility.hidden) {
      return null;
    }
    final placed = result is PlacedElementInteracted ? result : null;
    if (!includeHidden && placed != null && placed.element.opacity <= 0) {
      return null;
    }
    final placedCooldownReady =
        placed == null ||
        _placedBehaviorCooldownGate.remainingMs(
              key: _buildPlacedBehaviorCooldownKey(
                element: placed.element,
                behavior: placed.behavior,
                trigger: placed.trigger,
              ),
              nowMs: _runtimeClockMs,
            ) <=
            0;
    final key = (
      _bundle.manifest,
      _bundle.map,
      _world.map,
      _gameState,
      _currentMapActivationId,
      _world.player.pos,
      _world.player.facing,
      entity,
      placed?.element,
      placed?.behavior,
      placedCooldownReady,
      _placedElementWarpTraversalController.isActive,
      _cachedNarrativeRuntimeSnapshot,
      includeHidden,
    );
    if (_interactionResolutionKey == key) return _cachedInteractionResolution;
    _interactionResolutionKey = key;
    final placedAvailable =
        placed == null ||
        (placedCooldownReady && _canExecuteInteractionBehavior(placed));
    _cachedInteractionResolution = _selectOverworldInteraction(
      result,
      entity,
      placedAvailable,
      includeHidden,
    );
    return _cachedInteractionResolution;
  }

  _ResolvedOverworldInteraction? _selectOverworldInteraction(
    GameplayStepResult result,
    MapEntity? entity,
    bool placedAvailable,
    bool includeHidden,
  ) {
    var verb = RuntimeOverworldInteractionVerb.interact;
    String? eventId;
    String? sceneId;
    var isIntrinsicFieldObstacle = false;
    late String actionId;
    late String targetId;
    late GridPos cell;
    late RuntimeOverworldInteractionTargetKind kind;
    if (entity != null && entity.kind != MapEntityKind.spawn) {
      final preparation = _readInteractionAuthority(
        NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract(
            _activeMapId,
            entity.id,
          ),
        ),
      );
      if (preparation is! NarrativeEventDispatchAuthorityReady) return null;
      final decision = preparation.plan(gameState: _gameState);
      if (decision is NarrativeEventDispatchHandled) {
        eventId = decision.eventId;
        sceneId = decision.sceneId;
        actionId = jsonEncode(['eventV2', eventId, sceneId]);
      } else if (decision is NarrativeEventDispatchNoMatch &&
          entity.fieldObstacle != null &&
          !_hasIntrinsicFieldObstacleOwner(entity)) {
        final evaluation = evaluateFieldObstacleAttempt(
          map: _world.map,
          gameState: _gameState,
          entityId: entity.id,
        );
        if (evaluation case FieldObstacleUnavailable(:final reason)
            when reason != FieldObstacleBlockReason.missingMove &&
                reason != FieldObstacleBlockReason.locked) {
          return null;
        }
        final instance = _gameState.mapInstanceWorldState.instanceRef(
          _activeMapId,
        )!;
        isIntrinsicFieldObstacle = true;
        actionId = jsonEncode([
          'fieldObstacle',
          entity.id,
          entity.fieldObstacle!.toJson(),
          instance.instanceId,
        ]);
      } else if (decision is NarrativeEventDispatchNoMatch &&
          decision.legacyFallbackAllowed) {
        final source = _scenarioRuntime.selectSource(
          scenarios: _bundle.manifest.scenarios,
          sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
            mapId: _activeMapId,
            entityId: entity.id,
          ),
          gameState: _gameState,
          shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
        );
        if (source != null) {
          actionId = jsonEncode([
            'scenario',
            source.scenario.id,
            source.sourceNode.id,
          ]);
        } else {
          final native = _nativeEntityInteraction(entity);
          actionId = native.$1;
          verb = native.$2;
          if (PlayableMapGame._tileEventMayAnswer(
            result,
            scenarioHandled: false,
          )) {
            final selected = _selectInteractionMapEvent();
            if (selected != null) {
              actionId = jsonEncode([
                actionId,
                selected.$1.id,
                selected.$2.pageIndex,
                selected.$2.page.toJson(),
              ]);
              verb = RuntimeOverworldInteractionVerb.interact;
            }
          }
        }
      } else {
        return null;
      }
      kind = RuntimeOverworldInteractionTargetKind.entity;
      targetId = entity.id;
      cell = GridPos(
        x: _world.player.pos.x + _world.player.facing.dx,
        y: _world.player.pos.y + _world.player.facing.dy,
      );
    } else if (result is PlacedElementInteracted) {
      if (!placedAvailable) return null;
      kind = RuntimeOverworldInteractionTargetKind.placedElement;
      targetId = result.element.id;
      cell = result.element.pos;
      actionId = jsonEncode(['placed', result.behavior.toJson()]);
      verb = switch (result.behavior.effect.type) {
        MapPlacedElementEffectType.showMessage =>
          RuntimeOverworldInteractionVerb.read,
        MapPlacedElementEffectType.traverseWarp =>
          RuntimeOverworldInteractionVerb.enter,
        _ => RuntimeOverworldInteractionVerb.interact,
      };
    } else {
      final selected = _selectInteractionMapEvent();
      if (selected == null) {
        final target = findFlashTarget(map: _world.map, gameState: _gameState);
        if (target == null) return null;
        final prepared = prepareFlashInteraction(map: _world.map, gameState: _gameState,
          stateRevision: _gameStateRevision, zoneId: target.id);
        if (prepared == null) return null;
        final settings = _bundle.manifest.settings;
        return _ResolvedOverworldInteraction(
          action: RuntimeOverworldInteractionAction(
            request: RuntimeOverworldInteractionRequest(sessionId: _interactionSessionId,
              mapActivationId: _currentMapActivationId!, mapId: _activeMapId,
              targetKind: RuntimeOverworldInteractionTargetKind.gameplayZone,
              targetId: target.id, actionId: narrativeEventCanonicalSha256(jsonEncode(['flash', target.toJson()]))),
            verb: RuntimeOverworldInteractionVerb.interact, targetCell: _world.player.pos,
            targetBounds: PixelRect(leftPx: _world.player.pos.x * settings.tileWidth,
              topPx: _world.player.pos.y * settings.tileHeight, widthPx: settings.tileWidth, heightPx: settings.tileHeight)),
          result: result, flashZoneId: target.id);
      }
      if (!includeHidden && selected.$2.page.isHidden) return null;
      kind = RuntimeOverworldInteractionTargetKind.mapEvent;
      targetId = selected.$1.id;
      cell = GridPos(x: selected.$1.position.x, y: selected.$1.position.y);
      actionId = jsonEncode([
        'mapEvent',
        selected.$2.pageIndex,
        selected.$2.page.toJson(),
      ]);
      if (selected.$2.page.sceneTarget == null &&
          selected.$2.page.script == null &&
          (selected.$2.page.message?.trim().isNotEmpty ?? false)) {
        verb = RuntimeOverworldInteractionVerb.read;
      }
    }
    final settings = _bundle.manifest.settings;
    var bounds = PixelRect(
      leftPx: cell.x * settings.tileWidth,
      topPx: cell.y * settings.tileHeight,
      widthPx: settings.tileWidth,
      heightPx: settings.tileHeight,
    );
    if (kind == RuntimeOverworldInteractionTargetKind.entity &&
        entity?.item?.visibility != MapEntityItemVisibility.hidden) {
      bounds = resolveEntityCollisionRectPx(
        entity!,
        tileWidthPx: settings.tileWidth,
        tileHeightPx: settings.tileHeight,
      );
    } else if (result is PlacedElementInteracted) {
      final projectElement = _bundle.manifest.elements
          .where((entry) => entry.id == result.element.elementId)
          .firstOrNull;
      if (projectElement != null) {
        bounds = resolveMapPlacedElementGeometry(
          instance: result.element,
          element: projectElement,
          tileSize: PixelSize(
            width: settings.tileWidth,
            height: settings.tileHeight,
          ),
        ).logicalRect;
      }
    }
    return _ResolvedOverworldInteraction(
      action: RuntimeOverworldInteractionAction(
        request: RuntimeOverworldInteractionRequest(
          sessionId: _interactionSessionId,
          mapActivationId: _currentMapActivationId!,
          mapId: _activeMapId,
          targetKind: kind,
          targetId: targetId,
          actionId: narrativeEventCanonicalSha256(actionId),
        ),
        verb: verb,
        targetCell: cell,
        targetBounds: bounds,
      ),
      result: result,
      entity: kind == RuntimeOverworldInteractionTargetKind.entity
          ? entity
          : null,
      eventId: eventId,
      sceneId: sceneId,
      isIntrinsicFieldObstacle: isIntrinsicFieldObstacle,
    );
  }

  (String, RuntimeOverworldInteractionVerb) _nativeEntityInteraction(
    MapEntity entity,
  ) {
    DialogueRef? dialogue;
    var verb = RuntimeOverworldInteractionVerb.interact;
    if (entity.kind == MapEntityKind.npc) {
      dialogue = _resolveNpcDialogueRef(entity);
      final trainer = _bundle.manifest.trainers
          .where((entry) => entry.id == entity.npc?.trainerId)
          .firstOrNull;
      if (trainer != null) {
        final plan = resolveRuntimeTrainerInteractionPlan(
          trainer: trainer,
          npc: entity.npc!,
          isDefeated: _storyBranching.isTrainerDefeated(_gameState, trainer.id),
        );
        return (
          jsonEncode([
            'trainer',
            trainer.id,
            plan.disposition.name,
            plan.dialogue?.toJson(),
          ]),
          plan.disposition == RuntimeTrainerInteractionDisposition.dialogueOnly
              ? RuntimeOverworldInteractionVerb.talk
              : RuntimeOverworldInteractionVerb.interact,
        );
      }
      if (dialogue != null) verb = RuntimeOverworldInteractionVerb.talk;
    } else if (entity.kind == MapEntityKind.sign) {
      dialogue = entity.sign?.dialogue;
      if (dialogue != null) verb = RuntimeOverworldInteractionVerb.read;
    }
    return (jsonEncode(['native', entity.kind.name, dialogue?.toJson()]), verb);
  }

  (MapEventDefinition, ActiveEventPage)? _selectInteractionMapEvent() {
    final map = _bundle.map;
    if (!identical(_interactionEventMap, map)) {
      _interactionEventMap = map;
      _interactionEventsByCell.clear();
      for (final event in map.events) {
        _interactionEventsByCell.putIfAbsent(
          GridPos(x: event.position.x, y: event.position.y),
          () => event,
        );
      }
    }
    final facing = _world.player.facing;
    final event =
        _interactionEventsByCell[GridPos(
          x: _world.player.pos.x + facing.dx,
          y: _world.player.pos.y + facing.dy,
        )];
    if (event == null) return null;
    final factContext = ScriptEvaluationContext(
      narrativeFactResolver: _narrativeFactResolver,
    );
    final activePage = _storyBranching.pageResolver.resolve(
      event,
      _gameState,
      contextForPage: (page) =>
          hasEventBuilderPageProvenance(page) ? factContext : null,
    );
    if (activePage == null) return null;
    final projection = _resolveWorldRuleProjectionForMap(
      map.id,
      _bundle.manifest,
    );
    if (!(projection?.canTriggerMapEvent(
          event,
          defaultEnabled: !activePage.page.isDisabled,
        ) ??
        !activePage.page.isDisabled)) {
      return null;
    }
    return (event, activePage);
  }

  bool _canExecuteInteractionBehavior(PlacedElementInteracted result) {
    final behavior = result.behavior;
    if (!behavior.enabled ||
        _placedBehaviorCooldownGate.remainingMs(
              key: _buildPlacedBehaviorCooldownKey(
                element: result.element,
                behavior: behavior,
                trigger: result.trigger,
              ),
              nowMs: _runtimeClockMs,
            ) >
            0) {
      return false;
    }
    final effect = behavior.effect;
    return switch (effect.type) {
      MapPlacedElementEffectType.showMessage =>
        effect.message?.trim().isNotEmpty ?? false,
      MapPlacedElementEffectType.openDialogue => true,
      MapPlacedElementEffectType.setAnimationEnabled =>
        effect.animationEnabled != null &&
            effect.animationEnabled !=
                _resolvePlacedElementAnimationEnabled(result.element.id),
      MapPlacedElementEffectType.playAnimationOnce ||
      MapPlacedElementEffectType.traverseWarp =>
        _bundle.manifest.elements.any(
              (element) =>
                  element.id == result.element.elementId &&
                  element.frames.length >= 2,
            ) &&
            (effect.type != MapPlacedElementEffectType.traverseWarp ||
                (!_placedElementWarpTraversalController.isActive &&
                    effect.targetPos != null &&
                    (effect.targetMapId?.trim().isNotEmpty ?? false))),
    };
  }

  void _executeOverworldInteraction(_ResolvedOverworldInteraction interaction) {
    final flashZoneId = interaction.flashZoneId;
    if (flashZoneId != null) {
      final prepared = prepareFlashInteraction(map: _world.map, gameState: _gameState,
        stateRevision: _gameStateRevision, zoneId: flashZoneId);
      if (prepared == null) return;
      _openDialogue(prepared.session, onDialogueFinished: (outcome) {
        final result = prepared.complete(outcomeId: outcome, map: _world.map,
          gameState: _gameState, currentStateRevision: _gameStateRevision);
        if (result is FlashRefused) {
          _showNotification('Cette action n’est plus disponible.');
        } else if (result is FlashApplied) {
          _replaceLogicalMapInstances(result.gameState.mapInstanceWorldState);
          _gameStateRevision += 1;
          _showNotification('Votre Pokémon utilise Flash ! Cette zone est éclairée.');
          _publishOverworldInteractions();
        }
      });
      return;
    }
    final entity = interaction.entity;
    if (entity == null) {
      _runLegacyInteractionFallback(interaction.result);
      return;
    }
    if (interaction.isIntrinsicFieldObstacle) {
      if (_resolveOverworldInteraction(includeHidden: true)?.action.request !=
          interaction.action.request) {
        return;
      }
      final prepared = prepareFieldObstacleInteraction(
        map: _world.map,
        gameState: _gameState,
        stateRevision: _gameStateRevision,
        entityId: entity.id,
      );
      if (prepared == null) return;
      _openDialogue(
        prepared.session,
        onDialogueFinished: (outcome) =>
            _completeIntrinsicFieldObstacle(prepared, outcome),
      );
      return;
    }
    if (entity.kind == MapEntityKind.npc) _faceNpcTowardPlayer(entity.id);
    _runDetachedNarrativeTask(
      operation: 'entityInteract',
      task: () => _dispatchNarrativeEntityInteraction(
        interaction.result,
        entity,
        interactionGuard: NarrativeSpatialInteractionGuard(
          eventId: interaction.eventId,
          sceneId: interaction.sceneId,
          isApplicable: () =>
              _resolveOverworldInteraction(
                includeHidden: true,
                duringDispatch: true,
              )?.action.request ==
              interaction.action.request,
        ),
      ),
    );
  }

  bool _hasIntrinsicFieldObstacleOwner(MapEntity entity) {
    final source = NarrativeEventSourceRef.entityInteract(
      _activeMapId,
      entity.id,
    );
    final registry = _bundle.manifest.eventRegistry;
    if (registry?.records.any(
              (record) => record.definitionOrNull?.source == source,
            ) ==
            true ||
        registry?.legacyClaims.any((claim) => claim.source == source) == true ||
        _bundle.map.events.any(
          (event) =>
              event.position.x == entity.pos.x &&
              event.position.y == entity.pos.y,
        )) {
      return true;
    }
    return _bundle.manifest.scenarios.any(
      (scenario) => scenario.nodes.any(
        (node) =>
            node.type == ScenarioNodeType.reference &&
            node.payload.actionKind?.trim() == kScenarioSourceEntityInteract &&
            node.binding.entityId?.trim() == entity.id &&
            ((node.binding.mapId?.trim().isEmpty ?? true) ||
                node.binding.mapId?.trim() == _activeMapId),
      ),
    );
  }

  void _completeIntrinsicFieldObstacle(
    RuntimeFieldObstacleInteraction interaction,
    String? outcomeId,
  ) {
    final decision = interaction.complete(
      outcomeId: outcomeId,
      map: _world.map,
      gameState: _gameState,
      currentStateRevision: _gameStateRevision,
      authoringMap: (_runtimeBundleByMapId[_activeMapId] ?? _bundle).map,
      project: _bundle.manifest,
      collisionWorld: _world,
    );
    if (decision is FieldObstacleRefused) {
      _showNotification('Cette action n’est plus disponible.');
      return;
    }
    if (decision is! FieldObstacleApplied) return;
    _applyIntrinsicFieldObstacleState(decision.gameState);
    final ability = interaction.ticket!.fieldAction.ability;
    if (ability == FieldAbility.cut) unawaited(_overworldSfxPlayer.playCut());
    _showNotification(switch (ability) {
      FieldAbility.cut => 'Votre Pokémon utilise Coupe !',
      FieldAbility.strength => 'Force est active sur cette carte. Avancez vers un rocher pour le pousser.',
      FieldAbility.rockSmash => 'Votre Pokémon utilise Éclate-Roc !',
      _ => throw StateError('Unsupported field obstacle ability.'),
    });
    _publishOverworldInteractions();
  }

  void _applyIntrinsicFieldObstacleState(GameState state) {
    final projected = _projectMovingPlatformBundle(
      _bundle.copyWith(map: _world.map),
      state,
    );
    final nextWorld = GameplayWorldState.initial(
      map: projected.map,
      movingPlatformWorldState: state.movingPlatformWorldState,
      project: projected.manifest,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      tileWidth: projected.manifest.settings.tileWidth,
      tileHeight: projected.manifest.settings.tileHeight,
      npcMapPresencePredicate: _world.npcMapPresencePredicate,
      mapEntityPresencePredicate: _world.mapEntityPresencePredicate,
    ).withPlayer(_world.player);
    _replaceLogicalMapInstances(state.mapInstanceWorldState);
    _world = nextWorld;
    _bundle = projected;
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) loaded.bundle = _bundle;
    final instance = state.mapInstanceWorldState.instanceRef(_activeMapId)!;
    loaded?.backgroundLayers.applyFieldObstacleProjection(
      instances: state.mapInstanceWorldState,
      runtimeMap: projected.map,
      movingPlatformWorldState: state.movingPlatformWorldState,
      instance: instance,
    );
    loaded?.foregroundLayers.applyFieldObstacleProjection(
      instances: state.mapInstanceWorldState,
      runtimeMap: projected.map,
      movingPlatformWorldState: state.movingPlatformWorldState,
      instance: instance,
    );
    _syncGameStateFromWorld();
  }

  bool _tryPushStrengthObstacle(Direction direction) {
    final instance = _gameState.mapInstanceWorldState.instanceRef(_activeMapId);
    if (instance == null ||
        !_gameState.mapInstanceWorldState.isStrengthActive(instance) ||
        !_canResolveOverworldInteraction()) {
      return false;
    }
    final front = GridPos(
      x: _world.player.pos.x + direction.dx,
      y: _world.player.pos.y + direction.dy,
    );
    final targets = _world.map.entities
        .where(
          (entity) =>
              entity.pos == front &&
              entity.fieldObstacle?.kind == FieldObstacleKind.strengthBoulder,
        )
        .toList();
    if (targets.length != 1 ||
        _world.entityAt(front.x, front.y)?.id != targets.single.id ||
        _hasIntrinsicFieldObstacleOwner(targets.single)) {
      return false;
    }
    final bumpSource = NarrativeEventSourceRef.entityBump(
      _activeMapId,
      targets.single.id,
    );
    final registry = _bundle.manifest.eventRegistry;
    if (registry?.records.any(
              (record) => record.definitionOrNull?.source == bumpSource,
            ) ==
            true ||
        registry?.legacyClaims.any((claim) => claim.source == bumpSource) ==
            true) {
      return false;
    }
    _world = _world.withPlayer(_world.player.copyWith(facing: direction));
    _syncGameStateFromWorld();
    final ticket = FieldObstacleTicket(
      fieldAction: FieldActionTicket(
        ability: FieldAbility.strength,
        targetCell: front,
        issuedAtStateRevision: _gameStateRevision,
      ),
      instance: instance,
      entityId: targets.single.id,
      playerPosition: _gameState.playerPosition,
      playerPixelPosition: _gameState.playerPixelPosition,
      playerFacing: _gameState.playerFacing,
    );
    final decision = commitStrengthPush(
      ticket: ticket,
      world: _world,
      gameState: _gameState,
      currentStateRevision: _gameStateRevision,
      authoringMap: (_runtimeBundleByMapId[_activeMapId] ?? _bundle).map,
      project: _bundle.manifest,
      characterReservations: _scriptedNpcReservedOccupiedCellsByEntity.values
          .map((reservation) => reservation.contactRect)
          .whereType<PixelRect>(),
    );
    if (decision is! StrengthPushApplied) {
      _player.syncState(_world.player);
      return true;
    }
    final from = _world.player.pos;
    _world = decision.movement.world;
    _applyIntrinsicFieldObstacleState(decision.gameState);
    final loaded = _loadedMapsById[_activeMapId];
    final duration = _sprintPressed
        ? PlayerComponent.kRunStepSeconds
        : PlayerComponent.kDefaultStepSeconds;
    for (final layers in [loaded?.backgroundLayers, loaded?.foregroundLayers]) {
      layers?.animateFieldObstaclePush(
        entityId: decision.entityId,
        from: front,
        to: GridPos(x: front.x + direction.dx, y: front.y + direction.dy),
        durationSeconds: duration,
      );
    }
    _handleGameplayMovementResult(decision.movement, previousPlayerPos: from);
    _publishOverworldInteractions();
    return true;
  }
}
