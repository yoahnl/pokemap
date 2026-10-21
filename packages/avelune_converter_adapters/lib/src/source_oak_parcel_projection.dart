part of 'source_event_projection.dart';

extension _OakParcelProjection on _ProjectionBuilder {
  bool _hasOakParcelProgram(SourceEventDefinition event) => event.pages
      .expand((page) => page.body.nodes)
      .any((node) => node is SourceOakParcelProgramNode);

  SourceOakParcelBinding? _oakParcelBinding(SourceEventDefinition event) {
    return _oakParcelBindingCache.putIfAbsent(event, () {
      final binding = oakParcelBindings[event.identity];
      return binding?.isBoundTo(source, analysis, event) == true
          ? binding
          : null;
    });
  }

  SourceOakParcelTileBinding? _oakTileBinding(SourceEventDefinition event) {
    return _oakTileBindingCache.putIfAbsent(event, () {
      for (final owner in oakParcelBindings.entries) {
        final sourceOwner = analysis.events
            .where((candidate) => candidate.identity == owner.key)
            .singleOrNull;
        if (sourceOwner == null || _oakParcelBinding(sourceOwner) == null) {
          continue;
        }
        final prop = owner.value.tileActors[event.identity];
        if (prop != null && prop.isBoundTo(source, analysis)) return prop;
      }
      return null;
    });
  }

  Set<String> _oakTileGaps(SourceEventDefinition event) {
    final binding = _oakTileBinding(event);
    if (binding == null) return {'sourceOakParcelTileBindingMissing'};
    final map = maps[event.sourceMapId];
    if (map == null ||
        map.version == ProjectVersion.v9 ||
        map.spatialScene != null ||
        event.x < 0 ||
        event.y < 0 ||
        event.x >= map.size.width ||
        event.y >= map.size.height) {
      return {'sourceOakParcelTileMapUnsupported'};
    }
    return {};
  }

  Set<String> _oakParcelGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = _oakParcelBinding(event);
    if (binding == null) return {'sourceOakParcelBindingsMissing'};
    final gaps = <String>{};
    final map = maps[event.sourceMapId]!;
    if (map.version == ProjectVersion.v9 ||
        map.spatialScene != null ||
        !executionContextQualified ||
        retentionPolicy == null ||
        _eventFootprint(event) != const GridSize(width: 1, height: 1)) {
      gaps.add('sourceOakParcelExecutionContextMissing');
    }
    for (final page in event.pages) {
      _conditionGaps(event, page.condition, gaps);
      final graphic = page.graphic;
      if (graphic == null ||
          graphic.characterName.isEmpty ||
          graphic.tileId != 0 ||
          graphic.hue != 0 ||
          graphic.opacity != 255 ||
          graphic.blendType != 0 ||
          graphic.directionFix ||
          graphic.moveType != 0 ||
          graphic.stepAnime ||
          graphic.through ||
          graphic.alwaysOnTop ||
          page.triggerCode != 0) {
        gaps.add('sourceOakParcelPresentationUnsupported');
        continue;
      }
      if (checkCharacterBindings) {
        final character = characterBindings[sourceEventCharacterBindingKey(
            characterName: graphic.characterName,
            pattern: graphic.pattern,
            direction: graphic.direction)];
        final file = source.snapshot.entries
            .where((entry) => entry.fileId == character?.sourceFileId)
            .singleOrNull;
        if (character == null ||
            file == null ||
            character.fixedDirection ||
            character.sourceSnapshotHash != sourceSnapshotHash ||
            character.sourceFileHash != file.sha256 ||
            character.sourcePattern != graphic.pattern ||
            character.sourceDirection != graphic.direction ||
            character.characterId.trim().isEmpty ||
            file.relativePath !=
                resolveSourceCharacterPresentation(
                        snapshot: source.snapshot,
                        profile: source.interpretationProfile,
                        charsetName: graphic.characterName)
                    ?.actualSourceFile
                    .relativePath) {
          gaps.add('characterBindingMissing');
        }
      }
    }
    for (final id in binding.companionHashes.keys) {
      final actor = analysis.eventAt(event.sourceMapId, id);
      if (actor == null ||
          !_selectedEventIdentities.contains(actor.identity) ||
          _gaps(actor, checkCharacterBindings: checkCharacterBindings)
              .isNotEmpty) {
        gaps.add('sourceOakParcelActorUnavailable');
      } else {
        _exclamationActorDependencies
            .putIfAbsent(event.identity, () => {})
            .add(actor.identity);
      }
    }
    final pickup = pickupBindings[sourcePickupFeedbackBindingKey(
        sourceMapId: event.sourceMapId,
        sourceSymbol: 'POKEBALL',
        helper: SourceItemGrantHelper.receiveItem,
        quantity: 5)];
    if (pickup == null ||
        pickup.quantity != 5 ||
        pickup.helper != SourceItemGrantHelper.receiveItem ||
        pickup.item.sourceSymbol != 'POKEBALL' ||
        pickup.item.definition.id != binding.items['POKEBALL']!.definition.id ||
        pickup.sourceSnapshotHash != sourceSnapshotHash ||
        pickup.sourceMapId != event.sourceMapId ||
        pickup.evidence['sourceQuantity'] != 5 ||
        pickup.evidence['sourceHelper'] !=
            SourceItemGrantHelper.receiveItem.name ||
        pickup.foundFeedback(cueId: 'source-bound-quantity').plainText !=
            'You obtained 5 ${pickup.item.portionNamePlural}!') {
      gaps.add('sourceOakParcelFiveBallFeedbackMissing');
    }
    for (final audio in binding.audio.entries) {
      final actual = soundBindings[audio.key];
      if (actual == null ||
          actual.name != audio.value.name ||
          actual.kind != audio.value.kind ||
          actual.policy != audio.value.policy ||
          actual.mediaId != audio.value.mediaId ||
          actual.audioFile.fileId != audio.value.audioFile.fileId ||
          actual.audioFile.sha256 != audio.value.audioFile.sha256 ||
          actual.sourceSnapshotHash != sourceSnapshotHash ||
          actual.artifact.rawSha256 != audio.value.artifact.rawSha256 ||
          canonicalJsonOf(actual.evidence) !=
              canonicalJsonOf(audio.value.evidence)) {
        gaps.add('sourceOakParcelAudioBindingMissing');
      }
    }
    void visit(SourceEventBlock body) {
      for (final node in body.nodes) {
        switch (node) {
          case SourceConditionalNode():
            final facing = SourceOakParcelProgram.approaches.any((approach) =>
                approach.firstCommandIndex == node.span.firstCommandIndex);
            if (!facing &&
                node.condition.kind != SourceEventConditionKind.itemPresence) {
              gaps.add('sourceOakParcelConditionUnsupported');
            }
            if (!facing) _conditionGaps(event, node.condition, gaps);
            visit(node.whenTrue);
            visit(node.whenFalse);
          case SourceTextNode():
            if (node.followingChoice != null ||
                _textFeedback(event, node.text) == null) {
              gaps.add('sourceOakParcelDialogueUnsupported');
            }
          case SourceScriptNode():
            if (!const {
              'FollowingPkmn.toggle_off',
              r'$player.has_pokedex = true',
              r'$player.pokedex.unlock(1)',
              r'$player.has_pokedex = true' '\n' r'$player.pokedex.unlock(1)',
              'FollowingPkmn.toggle_off\n'
                  r'$player.has_pokedex = true'
                  '\n'
                  r'$player.pokedex.unlock(1)',
              r'$bag.remove(:OAKPARCEL)'
            }.contains(node.script.trim())) {
              gaps.add('sourceOakParcelScriptUnsupported');
            }
          case SourceUnknownNode():
            if (!const {247, 248, 242}.contains(node.command.code)) {
              gaps.add('sourceOakParcelCommandUnsupported');
            }
          case SourceMusicNode():
            if (binding.audio['bgm:${node.name}'] == null ||
                node.volume != 100 ||
                node.pitch != 100) {
              gaps.add('sourceOakParcelMusicUnsupported');
            }
          case SourceForcedMoveRouteNode():
            if (node.repeat ||
                node.skippable ||
                !const {-1, 0, 1, 12, 15, 25}
                    .contains(node.targetSourceCharacterId) ||
                node.steps.any((step) => !const {
                      SourceMoveRouteStepKind.moveDown,
                      SourceMoveRouteStepKind.moveUp,
                      SourceMoveRouteStepKind.moveLeft,
                      SourceMoveRouteStepKind.moveRight,
                      SourceMoveRouteStepKind.turnDown,
                      SourceMoveRouteStepKind.turnUp,
                      SourceMoveRouteStepKind.turnLeft,
                      SourceMoveRouteStepKind.turnRight,
                      SourceMoveRouteStepKind.wait,
                      SourceMoveRouteStepKind.hide
                    }.contains(step.kind))) {
              gaps.add('sourceOakParcelRouteUnsupported');
            }
          case SourcePickupNode():
            if (node.sourceSymbol != 'POKEBALL' ||
                node.quantity != 5 ||
                node.helper != SourceItemGrantHelper.receiveItem) {
              gaps.add('sourceOakParcelRewardUnsupported');
            }
          case SourceSelfSwitchNode():
            _blockGaps(
                event, SourceEventBlock(nodes: [node], span: node.span), gaps,
                checkCharacterBindings: checkCharacterBindings);
          case SourceSwitchNode():
          case SourceInteractionFacingNode():
          case SourceMoveRouteBarrierNode():
          case SourceWaitNode():
          case SourceAnnotationNode():
            break;
          case SourceExclamationNode():
            if (node.targetSourceCharacterId != event.sourceEventId) {
              gaps.add('sourceOakParcelExclamationUnsupported');
            }
          case SourceMusicEffectNode():
            _blockGaps(
                event, SourceEventBlock(nodes: [node], span: node.span), gaps,
                checkCharacterBindings: checkCharacterBindings);
          default:
            gaps.add('sourceOakParcelNodeUnsupported');
        }
      }
    }

    for (final wrapper in event.pages
        .take(4)
        .expand((page) => page.body.nodes)
        .whereType<SourceOakParcelProgramNode>()) {
      visit(wrapper.body);
    }
    return gaps;
  }

  SourceEventCharacterBinding? _oakTileCharacter(
      SourceEventDefinition event, SourceEventGraphic graphic) {
    final tile = _oakTileBinding(event);
    if (tile == null || graphic.tileId != tile.sourceTileId) return null;
    return SourceEventCharacterBinding(
        characterId: tile.character.id,
        sourceSnapshotHash: sourceSnapshotHash,
        sourceFileId: tile.sourceImage.fileId,
        sourceFileHash: tile.sourceImage.sha256!,
        sourcePattern: graphic.pattern,
        sourceDirection: graphic.direction);
  }
}

extension _OakParcelSceneProjection on _SceneBuilder {
  String _oakParcel(SourceOakParcelProgramNode wrapper, String next) {
    final binding = projection._oakParcelBinding(event);
    if (binding == null || wrapper.pageIndex >= 4) {
      throw const NativeWriteException('events.oak_parcel.binding',
          'A source parcel page requires its exact admitted program.');
    }
    String consequence(SceneConsequence value, String continuation) {
      final action = _node(SceneActionPayload.consequence(value));
      _edge(action, 'completed', continuation, SceneEdgeKind.actionCompleted);
      return action;
    }

    String lower(SourceEventBlock body, String continuation) {
      var target = continuation;
      for (final node in body.nodes.reversed) {
        switch (node) {
          case SourceConditionalNode():
            final approach = SourceOakParcelProgram.approaches
                .where((approach) =>
                    approach.firstCommandIndex == node.span.firstCommandIndex)
                .singleOrNull;
            if (approach == null) {
              target = _condition(node.condition, lower(node.whenTrue, target),
                  lower(node.whenFalse, target));
            } else {
              final facing = switch (approach.sourceActorDirection) {
                2 => EntityFacing.north,
                8 => EntityFacing.south,
                4 => EntityFacing.east,
                6 => EntityFacing.west,
                _ => throw const NativeWriteException(
                    'events.oak_parcel.facing',
                    'An attested cardinal actor direction is required.'),
              };
              final guard = _node(SceneConditionPayload(
                  conditionSource:
                      SceneConditionSource.playerFacing(direction: facing)));
              _edge(guard, 'true', lower(node.whenTrue, target),
                  SceneEdgeKind.conditionTrue);
              _edge(guard, 'false', lower(node.whenFalse, target),
                  SceneEdgeKind.conditionFalse);
              target = guard;
            }
          case SourceScriptNode():
            switch (node.script.trim()) {
              case 'FollowingPkmn.toggle_off':
                break;
              case r'$player.has_pokedex = true':
                target = _fact(
                    binding.hasPokedexSourceFactId,
                    true,
                    consequence(
                        SceneConsequence.setPauseMenuEntryVisibility(
                            actionId: ProjectPauseActionId.pokedex,
                            visible: true),
                        target));
              case 'FollowingPkmn.toggle_off\n'
                    r'$player.has_pokedex = true'
                    '\n'
                    r'$player.pokedex.unlock(1)':
              case r'$player.has_pokedex = true'
                    '\n'
                    r'$player.pokedex.unlock(1)':
                target = _fact(
                    binding.hasPokedexSourceFactId,
                    true,
                    consequence(
                        SceneConsequence.setPauseMenuEntryVisibility(
                            actionId: ProjectPauseActionId.pokedex,
                            visible: true),
                        _fact(binding.unlockedDexSourceFactId, true, target)));
              case r'$player.pokedex.unlock(1)':
                target = _fact(binding.unlockedDexSourceFactId, true, target);
              case r'$bag.remove(:OAKPARCEL)':
                final item = binding.items['OAKPARCEL']!.definition;
                projection.usedItems[item.id] = item;
                target = consequence(
                    SceneConsequence.takeItem(itemId: item.id, quantity: 1),
                    target);
              default:
                throw const NativeWriteException('events.oak_parcel.script',
                    'An unknown source command cannot be omitted.');
            }
          case SourceMusicNode():
            final audio = binding.audio['bgm:${node.name}']!;
            target = _interactive(
                SceneInteractiveCommand.sceneMusic(
                    operation: SceneMusicOperation.play,
                    mediaAssetId: audio.mediaId,
                    volume: audio.gainForVolume(node.volume)),
                target);
          case SourceUnknownNode():
            switch (node.command.code) {
              case 247:
                break;
              case 248:
                target = _interactive(
                    SceneInteractiveCommand.sceneMusic(
                        operation: SceneMusicOperation.restore),
                    target);
              case 242:
                final seconds = node.command.parameters.single as int;
                target = _interactive(
                    SceneInteractiveCommand.sceneMusic(
                        operation: SceneMusicOperation.fadeOut,
                        durationMs: seconds * 1000),
                    target);
              default:
                throw const NativeWriteException('events.oak_parcel.command',
                    'An unknown source command cannot be omitted.');
            }
          case SourceInteractionFacingNode():
            target = _oakFaceOwner(target);
          case SourceForcedMoveRouteNode():
            target = _block(
                SourceEventBlock(nodes: [node], span: node.span), target,
                initialActorRouteThrough: node.targetSourceCharacterId == 25);
          case SourcePickupNode():
            target = _oakFiveBalls(node, target);
          default:
            target = _block(
                SourceEventBlock(nodes: [node], span: node.span), target);
        }
      }
      return target;
    }

    return lower(wrapper.body, next);
  }

  String _oakFaceOwner(String next) {
    final mapId = projection.maps[event.sourceMapId]!.id;
    final joined = _interactive(
        SceneInteractiveCommand.waitForActorRoutes(mapId: mapId), next);
    var dispatch = eventEnd;
    for (final facing in EntityFacing.values) {
      final toward = switch (facing) {
        EntityFacing.north => EntityFacing.south,
        EntityFacing.south => EntityFacing.north,
        EntityFacing.east => EntityFacing.west,
        EntityFacing.west => EntityFacing.east,
      };
      final route = _interactive(
          SceneInteractiveCommand.actorRoute(
              target: SceneActorTarget.entity(
                  mapId: mapId, entityId: projection._key(event, 'anchor')),
              steps: [
                SceneActorRouteStep.face(direction: toward, yieldAfter: true)
              ]),
          joined);
      final guard = _node(SceneConditionPayload(
          conditionSource:
              SceneConditionSource.playerFacing(direction: facing)));
      _edge(guard, 'true', route, SceneEdgeKind.conditionTrue);
      _edge(guard, 'false', dispatch, SceneEdgeKind.conditionFalse);
      dispatch = guard;
    }
    return dispatch;
  }

  String _oakFiveBalls(SourcePickupNode pickup, String next) {
    final key = sourcePickupFeedbackBindingKey(
        sourceMapId: event.sourceMapId,
        sourceSymbol: pickup.sourceSymbol,
        helper: pickup.helper,
        quantity: pickup.quantity);
    final binding = projection.pickupBindings[key]!;
    projection.usedItems[binding.item.definition.id] = binding.item.definition;
    projection.usedPickupBindingKeys.add(key);
    final suffix =
        'receive_${page.originalPageIndex}_${pickup.span.firstCommandIndex}';
    final bag = binding.bagFeedback;
    final feedback = _dialogue(pickup.span, bag.plainText, null, next,
        feedbackLines: [bag], dialogueKey: '${suffix}_bag');
    final grant = _node(SceneActionPayload.interactive(
        SceneInteractiveCommand.giveItem(
            itemId: binding.item.definition.id, quantity: pickup.quantity)));
    _edge(grant, 'received', feedback, SceneEdgeKind.actionCompleted);
    _edge(grant, 'bagFull', next, SceneEdgeKind.actionCompleted);
    final obtained =
        binding.foundFeedback(cueId: projection._key(event, suffix));
    return _dialogue(pickup.span, obtained.plainText, null, grant,
        feedbackLines: [obtained], dialogueKey: '${suffix}_obtained');
  }
}
