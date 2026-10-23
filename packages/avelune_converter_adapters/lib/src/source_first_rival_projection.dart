part of 'source_event_projection.dart';

extension _FirstRivalProjection on _ProjectionBuilder {
  SourceFirstRivalBinding? _firstRivalBinding(SourceEventDefinition event) {
    final binding = firstRivalBindings[event.identity];
    return binding?.isBoundTo(source, analysis, event) == true ? binding : null;
  }

  bool _hasFirstRivalProgram(SourceEventDefinition event) => event.pages
      .expand((p) => p.body.nodes)
      .any((n) => n is SourceFirstRivalProgramNode);

  Set<String> _firstRivalGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = _firstRivalBinding(event);
    if (binding == null) return {'sourceFirstRivalBindingsMissing'};
    final gaps = <String>{};
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      gaps.add('sourceFirstRivalSpatialUnsupported');
    }
    if (!_eventExecutionContextQualified(event) || retentionPolicy == null) {
      gaps.add('sourceFirstRivalExecutionContextMissing');
    }
    final bodies = event.pages
        .expand((p) => p.body.nodes)
        .whereType<SourceFirstRivalProgramNode>();
    for (final wrapper in bodies) {
      void visit(SourceEventBlock body) {
        for (final node in body.nodes) {
          switch (node) {
            case SourceConditionalNode():
              final battle = binding.program.battles
                  .where((b) => b.commandIndex == node.span.firstCommandIndex)
                  .singleOrNull;
              if (battle == null &&
                  (!node.condition.isQualified ||
                      node.condition.kind !=
                          SourceEventConditionKind.variableComparison ||
                      node.condition.variableId !=
                          binding.program.choiceVariableId ||
                      node.condition.comparisonOperator != 0 ||
                      !const {1, 2, 3}.contains(node.condition.minimum))) {
                gaps.add('sourceFirstRivalConditionUnsupported');
              }
              visit(node.whenTrue);
              visit(node.whenFalse);
            case SourceTextNode():
              if (node.followingChoice != null ||
                  _textFeedback(event, node.text) == null) {
                gaps.add('sourceFirstRivalDialogueUnsupported');
              }
            case SourceMusicNode():
              if (node.name != binding.music.name ||
                  node.volume != 100 ||
                  node.pitch != 100) {
                gaps.add('sourceFirstRivalMusicUnsupported');
              }
            case SourceScriptNode():
              if (!const {
                'FollowingPkmn.toggle_off',
                'FollowingPkmn.toggle_on',
                'setBattleRule("canLose")'
              }.contains(node.script.trim())) {
                gaps.add('sourceFirstRivalScriptUnsupported');
              }
            case SourceAudioControlNode():
              if (!const {'memorize', 'restoreMemorized', 'fadeOut'}.contains(node.operation) ||
                  !const {'music', 'both'}.contains(node.channel)) {
                gaps.add('sourceFirstRivalCommandUnsupported');
              }
            case SourceUnknownNode():
              final code = node.command.code;
              if (!const {247, 248, 242}.contains(code) &&
                  !_firstRivalRelativeRoutePart(wrapper, node)) {
                gaps.add('sourceFirstRivalCommandUnsupported');
              }
            case SourceForcedMoveRouteNode():
              if (node.repeat ||
                  node.skippable ||
                  node.steps.any((s) => !const {
                        SourceMoveRouteStepKind.moveDown,
                        SourceMoveRouteStepKind.moveLeft,
                        SourceMoveRouteStepKind.moveRight,
                        SourceMoveRouteStepKind.moveUp,
                        SourceMoveRouteStepKind.turnDown,
                        SourceMoveRouteStepKind.turnLeft,
                        SourceMoveRouteStepKind.turnRight,
                        SourceMoveRouteStepKind.turnUp,
                        SourceMoveRouteStepKind.wait,
                        SourceMoveRouteStepKind.hide,
                        SourceMoveRouteStepKind.throughOn,
                        SourceMoveRouteStepKind.throughOff,
                      }.contains(s.kind))) {
                gaps.add('sourceFirstRivalRouteUnsupported');
              }
              if (node.targetSourceCharacterId > 0) {
                final actor = analysis.eventAt(
                    event.sourceMapId, node.targetSourceCharacterId);
                if (actor == null ||
                    !_selectedEventIdentities.contains(actor.identity) ||
                    !_exclamationEventMatchesSource(actor) ||
                    _gaps(actor, checkCharacterBindings: checkCharacterBindings)
                        .isNotEmpty) {
                  gaps.add('sourceFirstRivalActorUnavailable');
                } else {
                  _exclamationActorDependencies
                      .putIfAbsent(event.identity, () => {})
                      .add(actor.identity);
                }
              } else if (node.targetSourceCharacterId != -1) {
                gaps.add('sourceFirstRivalRouteTargetUnsupported');
              }
            case SourceMoveRouteBarrierNode():
            case SourceSelfSwitchNode():
            case SourceAnnotationNode():
            case SourceExitEventNode():
            case SourceWaitNode():
              break;
            default:
              gaps.add('sourceFirstRivalNodeUnsupported');
          }
        }
      }

      visit(wrapper.body);
    }
    if (binding.loseTexts.values
        .any((s) => _staticSourceTextFeedback(s) == null)) {
      gaps.add('sourceFirstRivalLoseTextUnsupported');
    }
    return gaps;
  }
}

bool _firstRivalRelativeRoutePart(
        SourceFirstRivalProgramNode wrapper, SourceUnknownNode node) =>
    wrapper.program.permitsRelativePlayerRoute(node);

extension _FirstRivalSceneProjection on _SceneBuilder {
  String _firstRival(SourceFirstRivalProgramNode wrapper, String continuation) {
    final binding = projection._firstRivalBinding(event);
    if (binding == null) {
      throw const NativeWriteException('events.first_rival.binding',
          'The complete first rival requires attested native bindings.');
    }
    String lower(SourceEventBlock body, String target) {
      var next = target;
      for (final node in body.nodes.reversed) {
        switch (node) {
          case SourceConditionalNode():
            final battle = binding.program.battles
                .where((b) => b.commandIndex == node.span.firstCommandIndex)
                .singleOrNull;
            if (battle == null) {
              next = _condition(node.condition, lower(node.whenTrue, next),
                  lower(node.whenFalse, next));
            } else {
              final trueBranch = lower(node.whenTrue, next);
              final falseBranch = lower(node.whenFalse, next);
              final wait = _interactive(
                  SceneInteractiveCommand.wait(durationMs: 250), falseBranch);
              final heal = _node(
                  SceneActionPayload.consequence(SceneConsequence.healParty()));
              _edge(heal, 'completed', wait, SceneEdgeKind.actionCompleted);
              final actor = projection.analysis
                  .eventAt(event.sourceMapId, battle.actorEventId)!;
              final speech = _dialogue(node.span, null, null, trueBranch,
                  dialogueKey: 'first_rival_pbs_${battle.trainerVersion}',
                  feedbackLines: [
                    _staticSourceTextFeedback(
                        binding.loseTexts[battle.trainerVersion]!)!
                  ]);
              final fight = _node(SceneBattlePayload(
                  battleKind: 'trainer',
                  trainerId: binding.trainers[battle.trainerVersion]!.id,
                  npcEntityId: projection._key(actor, 'anchor'),
                  defeatRecovery: SceneBattleDefeatRecovery.continueScene,
                  declaredOutcomes: const ['victory', 'defeat']));
              _edge(fight, 'victory', speech, SceneEdgeKind.battleVictory);
              _edge(fight, 'defeat', heal, SceneEdgeKind.battleDefeat);
              next = fight;
            }
          case SourceForcedMoveRouteNode()
              when node.steps.length == 1 &&
                  node.steps.single.kind == SourceMoveRouteStepKind.turnDown &&
                  binding.program.battles.any((battle) =>
                      battle.actorEventId == node.targetSourceCharacterId):
            final actor = projection.analysis
                .eventAt(event.sourceMapId, node.targetSourceCharacterId)!;
            final hidden = actor.pages.last;
            var condition = hidden.condition;
            while (condition.kind == SourceEventConditionKind.all &&
                condition.children.length == 1) {
              condition = condition.children.single;
            }
            final expected = projection._sourceControlAnalyzer.selfFactId(
                event.sourceMapId, node.targetSourceCharacterId, 'A');
            if (condition.kind != SourceEventConditionKind.selfSwitch ||
                !condition.expectedValue ||
                condition.factId != expected ||
                hidden.graphic?.characterName != '' ||
                hidden.graphic?.tileId != 0) {
              throw const NativeWriteException(
                  'events.first_rival.logical_facing',
                  'A hidden companion facing requires its attested highest blank self-switch page.');
            }
            final visible =
                _block(SourceEventBlock(nodes: [node], span: node.span), next);
            final face = _node(SceneActionPayload.consequence(
                SceneConsequence.setNpcPose(
                    mapId: projection.maps[event.sourceMapId]!.id,
                    entityId: projection._key(actor, 'anchor'),
                    facing: EntityFacing.south)));
            _edge(face, 'completed', next, SceneEdgeKind.actionCompleted);
            next = _condition(condition, face, visible);
          case SourceMusicNode():
            next = _firstRivalMusic(node, binding, next);
          case SourceScriptNode():
            break;
          case SourceAudioControlNode():
            final command = _baselineSceneAudioAdaptation(node);
            if (command != null) next = _interactive(command, next);
          case SourceUnknownNode():
            if (node.command.code == 209 &&
                _firstRivalRelativeRoutePart(wrapper, node)) {
              next = _firstRivalRelativePlayerRoute(next);
            } else if (node.command.code == 248) {
              next = _interactive(
                  SceneInteractiveCommand.sceneMusic(
                      operation: SceneMusicOperation.restore),
                  next);
            } else if (node.command.code == 242) {
              final seconds = node.command.parameters.single as int;
              next = _interactive(
                  SceneInteractiveCommand.sceneMusic(
                      operation: SceneMusicOperation.fadeOut,
                      durationMs: seconds * 1000),
                  next);
            } else if (!const {247, 509}.contains(node.command.code)) {
              throw const NativeWriteException('events.first_rival.command',
                  'A first rival source command cannot be skipped.');
            }
          default:
            next =
                _block(SourceEventBlock(nodes: [node], span: node.span), next);
        }
      }
      return next;
    }

    return lower(wrapper.body, continuation);
  }

  String _firstRivalRelativePlayerRoute(String next) {
    final mapId = projection.maps[event.sourceMapId]!.id;
    var dispatch = next;
    for (final facing in EntityFacing.values.reversed) {
      final turn = switch (facing) {
        EntityFacing.north => EntityFacing.east,
        EntityFacing.east => EntityFacing.south,
        EntityFacing.south => EntityFacing.west,
        EntityFacing.west => EntityFacing.north
      };
      final back = switch (turn) {
        EntityFacing.north => EntityFacing.south,
        EntityFacing.south => EntityFacing.north,
        EntityFacing.east => EntityFacing.west,
        EntityFacing.west => EntityFacing.east
      };
      final route = _interactive(
          SceneInteractiveCommand.actorRoute(
              target: SceneActorTarget.player(mapId: mapId),
              skippable: false,
              steps: [
                SceneActorRouteStep.face(direction: turn, yieldAfter: true),
                SceneActorRouteStep.move(direction: back, durationMs: 250),
                SceneActorRouteStep.face(direction: turn, yieldAfter: true)
              ]),
          next);
      final condition = _node(SceneConditionPayload(
          conditionSource:
              SceneConditionSource.playerFacing(direction: facing)));
      _edge(condition, 'true', route, SceneEdgeKind.conditionTrue);
      _edge(condition, 'false', dispatch, SceneEdgeKind.conditionFalse);
      dispatch = condition;
    }
    return dispatch;
  }

  String _firstRivalMusic(
      SourceMusicNode node, SourceFirstRivalBinding binding, String next) {
    return _interactive(
        SceneInteractiveCommand.sceneMusic(
            operation: SceneMusicOperation.play,
            mediaAssetId: binding.music.mediaId,
            volume: binding.music.gainForVolume(node.volume)),
        next);
  }
}
