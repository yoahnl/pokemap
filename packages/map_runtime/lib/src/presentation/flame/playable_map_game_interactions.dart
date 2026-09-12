part of 'playable_map_game.dart';

final class _ResolvedOverworldInteraction {
  const _ResolvedOverworldInteraction({
    required this.action,
    required this.result,
    this.entity,
    this.eventId,
    this.sceneId,
  });

  final RuntimeOverworldInteractionAction action;
  final GameplayStepResult result;
  final MapEntity? entity;
  final String? eventId;
  final String? sceneId;
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
    return !_inputLocks.snapshot.activeTokens.any((token) =>
        !_derivedInputLocks.containsKey(token.owner) &&
        token.surface != RuntimeInputSurface.world);
  }

  RuntimeOverworldInteractionSnapshot _readOverworldInteractionSnapshot() {
    final primaryAction = _resolveOverworldInteraction()?.action;
    final next = RuntimeOverworldInteractionSnapshot(
      sessionId: _interactionSessionId,
      mapActivationId: _currentMapActivationId ?? '',
      mapId: _activeMapId,
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
    return interaction?.entity?.item?.visibility == MapEntityItemVisibility.hidden
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
      NarrativeEventOccurrence occurrence) {
    final project = _bundle.manifest;
    final registry = project.eventRegistry;
    if (registry == null || registry.mode == EventSystemMode.legacyOnly) {
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
      EntityInteracted(:final entity) =>
        entity,
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
    final placedCooldownReady = placed == null ||
        _placedBehaviorCooldownGate.remainingMs(
                key: _buildPlacedBehaviorCooldownKey(
                    element: placed.element,
                    behavior: placed.behavior,
                    trigger: placed.trigger),
                nowMs: _runtimeClockMs) <=
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
      includeHidden
    );
    if (_interactionResolutionKey == key) return _cachedInteractionResolution;
    _interactionResolutionKey = key;
    final placedAvailable = placed == null ||
        (placedCooldownReady && _canExecuteInteractionBehavior(placed));
    _cachedInteractionResolution = _selectOverworldInteraction(
        result, entity, placedAvailable, includeHidden);
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
    late String actionId;
    late String targetId;
    late GridPos cell;
    late RuntimeOverworldInteractionTargetKind kind;
    if (entity != null && entity.kind != MapEntityKind.spawn) {
      final preparation = _readInteractionAuthority(NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract(_activeMapId, entity.id),
      ));
      if (preparation is! NarrativeEventDispatchAuthorityReady) return null;
      final decision = preparation.plan(gameState: _gameState);
      if (decision is NarrativeEventDispatchHandled) {
        eventId = decision.eventId;
        sceneId = decision.sceneId;
        actionId = jsonEncode(['eventV2', eventId, sceneId]);
      } else if (decision is NarrativeEventDispatchNoMatch &&
          decision.legacyFallbackAllowed) {
        final source = _scenarioRuntime.selectSource(
          scenarios: _bundle.manifest.scenarios,
          sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
              mapId: _activeMapId, entityId: entity.id),
          gameState: _gameState,
          shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
        );
        if (source != null) {
          actionId = jsonEncode(
              ['scenario', source.scenario.id, source.sourceNode.id]);
        } else {
          final native = _nativeEntityInteraction(entity);
          actionId = native.$1;
          verb = native.$2;
          if (PlayableMapGame._tileEventMayAnswer(result,
              scenarioHandled: false)) {
            final selected = _selectInteractionMapEvent();
            if (selected != null) {
              actionId = jsonEncode([
                actionId,
                selected.$1.id,
                selected.$2.pageIndex,
                selected.$2.page.toJson()
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
          y: _world.player.pos.y + _world.player.facing.dy);
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
      if (selected == null) return null;
      if (!includeHidden && selected.$2.page.isHidden) return null;
      kind = RuntimeOverworldInteractionTargetKind.mapEvent;
      targetId = selected.$1.id;
      cell = GridPos(x: selected.$1.position.x, y: selected.$1.position.y);
      actionId = jsonEncode(
          ['mapEvent', selected.$2.pageIndex, selected.$2.page.toJson()]);
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
        heightPx: settings.tileHeight);
    if (kind == RuntimeOverworldInteractionTargetKind.entity &&
        entity?.item?.visibility != MapEntityItemVisibility.hidden) {
      bounds = resolveEntityCollisionRectPx(entity!,
          tileWidthPx: settings.tileWidth, tileHeightPx: settings.tileHeight);
    } else if (result is PlacedElementInteracted) {
      final projectElement = _bundle.manifest.elements
          .where((entry) => entry.id == result.element.elementId)
          .firstOrNull;
      if (projectElement != null) {
        final size = resolveMapPlacedElementFootprint(
                instance: result.element, element: projectElement)
            .destinationSize;
        bounds = PixelRect(
            leftPx: result.element.pos.x * settings.tileWidth,
            topPx: result.element.pos.y * settings.tileHeight,
            widthPx: size.width * settings.tileWidth,
            heightPx: size.height * settings.tileHeight);
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
            actionId: narrativeEventCanonicalSha256(actionId)),
        verb: verb,
        targetCell: cell,
        targetBounds: bounds,
      ),
      result: result,
      entity:
          kind == RuntimeOverworldInteractionTargetKind.entity ? entity : null,
      eventId: eventId,
      sceneId: sceneId,
    );
  }

  (String, RuntimeOverworldInteractionVerb) _nativeEntityInteraction(
      MapEntity entity) {
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
            isDefeated:
                _storyBranching.isTrainerDefeated(_gameState, trainer.id));
        return (
          jsonEncode([
            'trainer',
            trainer.id,
            plan.disposition.name,
            plan.dialogue?.toJson()
          ]),
          plan.disposition == RuntimeTrainerInteractionDisposition.dialogueOnly
              ? RuntimeOverworldInteractionVerb.talk
              : RuntimeOverworldInteractionVerb.interact
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
            GridPos(x: event.position.x, y: event.position.y), () => event);
      }
    }
    final facing = _world.player.facing;
    final event = _interactionEventsByCell[GridPos(
        x: _world.player.pos.x + facing.dx,
        y: _world.player.pos.y + facing.dy)];
    if (event == null) return null;
    final factContext =
        ScriptEvaluationContext(narrativeFactResolver: _narrativeFactResolver);
    final activePage = _storyBranching.pageResolver.resolve(event, _gameState,
        contextForPage: (page) =>
            hasEventBuilderPageProvenance(page) ? factContext : null);
    if (activePage == null) return null;
    final projection =
        _resolveWorldRuleProjectionForMap(map.id, _bundle.manifest);
    if (!(projection?.canTriggerMapEvent(event,
            defaultEnabled: !activePage.page.isDisabled) ??
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
                    trigger: result.trigger),
                nowMs: _runtimeClockMs) >
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
        _bundle.manifest.elements.any((element) =>
                element.id == result.element.elementId &&
                element.frames.length >= 2) &&
            (effect.type != MapPlacedElementEffectType.traverseWarp ||
                (!_placedElementWarpTraversalController.isActive &&
                    effect.targetPos != null &&
                    (effect.targetMapId?.trim().isNotEmpty ?? false))),
    };
  }

  void _executeOverworldInteraction(_ResolvedOverworldInteraction interaction) {
    final entity = interaction.entity;
    if (entity == null) {
      _runLegacyInteractionFallback(interaction.result);
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
                            includeHidden: true, duringDispatch: true)
                        ?.action
                        .request ==
                    interaction.action.request,
              ),
            ));
  }
}
