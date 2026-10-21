part of 'source_event_projection.dart';

List<Map> _starterCommands(SourceStarterChoiceProgram program, int page) =>
    ((((program.raw['pages'] as List)[page] as Map)['list']) as List)
        .cast<Map>();

Set<int> _starterForeignIds(SourceStarterChoiceProgram program) => {
      for (final command in _starterCommands(program, 1))
        if (command['code'] == 355)
          if (RegExp(r'^pbSetSelfSwitch\(([1-9][0-9]*),"[A-D]",true\)$')
                  .firstMatch((command['parameters'] as List).single as String)
              case final match?)
            int.parse(match[1]!),
    };

List<({int index, String text})> _starterTexts(List<Map> commands) {
  final result = <({int index, String text})>[];
  for (var index = 0; index < commands.length; index++) {
    if (commands[index]['code'] != 101) continue;
    final start = index;
    var text = (commands[index]['parameters'] as List).single as String;
    while (index + 1 < commands.length && commands[index + 1]['code'] == 401) {
      text += '\n${(commands[++index]['parameters'] as List).single}';
    }
    result.add((index: start, text: text));
  }
  return result;
}

extension _StarterChoiceProjection on _ProjectionBuilder {
  Set<String> _starterChoiceGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = starterChoiceBindings[event.identity]!;
    if (!binding.isBoundTo(source: source, analysis: analysis, event: event)) {
      return {'sourceStarterWholeEventBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    final gaps = <String>{};
    if (map.version == ProjectVersion.v9 ||
        map.spatialScene != null ||
        retentionPolicy == null) {
      gaps.add('sourceStarterNativeWorldUnsupported');
    }
    if (_eventFootprint(event) != const GridSize(width: 1, height: 1) ||
        _eventCounterSides(event) == null ||
        event.x < 0 ||
        event.y < 0 ||
        event.x >= map.size.width ||
        event.y >= map.size.height) {
      gaps.add('sourceStarterAnchorUnsupported');
    }
    for (final page in event.pages) {
      _conditionGaps(event, page.condition, gaps);
      final graphic = page.graphic;
      if (graphic == null) {
        gaps.add('sourceStarterGraphicMissing');
        continue;
      }
      if (checkCharacterBindings &&
          graphic.characterName.isNotEmpty &&
          characterBindings[sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction)] ==
              null) {
        gaps.add('sourceStarterCharacterMissing');
      }
      for (final text in _starterTexts(
          _starterCommands(binding.program, page.originalPageIndex))) {
        if (_textFeedback(event, text.text) == null) {
          gaps.add('sourceStarterTextUnsupported');
        }
      }
    }
    for (final command in _starterCommands(binding.program, 1)) {
      final args = command['parameters'] as List;
      if (command['code'] == 202 &&
          ((args[2] as int) >= map.size.width ||
              (args[3] as int) >= map.size.height)) {
        gaps.add('sourceStarterAbsolutePoseOutsideMap');
      }
      if (command['code'] != 209) continue;
      final targetId = args.first as int;
      final target =
          targetId == 0 ? event : analysis.eventAt(event.sourceMapId, targetId);
      if (target == null) {
        gaps.add('sourceStarterRouteActorMissing');
        continue;
      }
      var x = target.x, y = target.y;
      for (final step in ((args[1] as Map)['list'] as List).cast<Map>()) {
        switch (step['code']) {
          case 1:
            y++;
          case 2:
            x--;
          case 3:
            x++;
          case 4:
            y--;
        }
        if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
          gaps.add('sourceStarterRouteOutsideMap');
        }
      }
    }
    final actors = _starterForeignIds(binding.program);
    final routes = _starterCommands(binding.program, 1)
        .where((command) => command['code'] == 209);
    for (final route in routes) {
      final target = (route['parameters'] as List).first as int;
      if (target > 0) actors.add(target);
    }
    for (final id in actors) {
      final actor = analysis.eventAt(event.sourceMapId, id);
      if (actor == null ||
          !sourceStarterActorIsBound(
              source: source, analysis: analysis, event: actor)) {
        gaps.add('sourceStarterActorMissing:$id');
        continue;
      }
      if (starterChoiceBindings.containsKey(actor.identity)) continue;
      gaps.addAll(_starterActorPresentationGaps(actor,
              checkCharacterBindings: checkCharacterBindings)
          .map((gap) => '$gap:$id'));
    }
    return gaps;
  }

  Set<int> _starterActors(SourceStarterChoiceProgram program) => {
        ..._starterForeignIds(program),
        for (final command in _starterCommands(program, 1))
          if (command['code'] == 209 &&
              (command['parameters'] as List).first as int > 0)
            (command['parameters'] as List).first as int,
      };

  Set<String> _starterActorPresentationGaps(SourceEventDefinition actor,
      {required bool checkCharacterBindings}) {
    final gaps = <String>{};
    if (!sourceStarterActorIsBound(
        source: source, analysis: analysis, event: actor)) {
      return {'sourceStarterActorSourceMismatch'};
    }
    final map = maps[actor.sourceMapId]!;
    if (_eventFootprint(actor) != const GridSize(width: 1, height: 1) ||
        actor.x < 0 ||
        actor.y < 0 ||
        actor.x >= map.size.width ||
        actor.y >= map.size.height) {
      gaps.add('sourceStarterActorGeometryUnsupported');
    }
    for (final page in actor.pages) {
      _conditionGaps(actor, page.condition, gaps);
      final graphic = page.graphic;
      if (graphic == null ||
          graphic.tileId != 0 ||
          graphic.hue != 0 ||
          graphic.opacity != 255 ||
          graphic.blendType != 0 ||
          _sourceFacingDirection(graphic.direction) == null ||
          graphic.pattern < 0 ||
          graphic.pattern > 3 ||
          graphic.moveType != 0 ||
          graphic.stepAnime ||
          graphic.directionFix ||
          graphic.alwaysOnTop) {
        gaps.add('sourceStarterActorPresentationUnsupported');
        continue;
      }
      if (checkCharacterBindings &&
          graphic.characterName.isNotEmpty &&
          characterBindings[sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction)] ==
              null) {
        gaps.add('sourceStarterActorCharacterMissing');
      }
    }
    return gaps;
  }

  bool _starterPassiveActorCandidate(SourceEventDefinition actor) =>
      starterChoiceBindings.values.any((binding) =>
          binding.program.sourceMapId == actor.sourceMapId &&
          _starterActors(binding.program).contains(actor.sourceEventId)) &&
      _starterActorPresentationGaps(actor, checkCharacterBindings: false)
          .isEmpty;

  void _projectStarterPassiveActors() {
    final used = <(int, int)>{
      for (final entry in starterChoiceBindings.entries)
        if (gapsByEvent[entry.key]?.isEmpty == true)
          for (final id in _starterActors(entry.value.program))
            (entry.value.program.sourceMapId, id),
    };
    for (final location in used) {
      final actor = analysis.eventAt(location.$1, location.$2)!;
      if (gapsByEvent[actor.identity]?.isEmpty == true) continue;
      final map = maps[actor.sourceMapId]!;
      final ids = <String>{};
      for (final page in actor.pages) {
        _collectFacts(page.condition, ids);
      }
      for (final id in ids) {
        factsById.putIfAbsent(
            id,
            () => id.contains(':variable:')
                ? _sourceVariableFact(id)
                : _nativeFact(id));
      }
      final variants = <MapEntityPresentationVariant>[];
      for (final page in actor.pages.reversed) {
        if (_dormantBlankSourceActionPage(page)) continue;
        final graphic = page.graphic!;
        final character = graphic.characterName.isEmpty
            ? null
            : characterBindings[sourceEventCharacterBindingKey(
                characterName: graphic.characterName,
                pattern: graphic.pattern,
                direction: graphic.direction)]!;
        final guard = _all([
          _pageGuard(actor, page.condition),
          _not(_any(actor.pages
              .where(
                  (other) => other.originalPageIndex > page.originalPageIndex)
              .map((other) => _pageGuard(actor, other.condition))
              .toList()))
        ]);
        if (guard.constant == false) continue;
        variants.add(MapEntityPresentationVariant(
            id: 'page_${page.originalPageIndex}',
            condition: guard.expression ??
                NarrativeEventConditionExpression.all(const []),
            characterId: character?.characterId,
            facing: _sourceFacingDirection(graphic.direction)!,
            blocksMovement: character != null && !graphic.through));
      }
      final firstGraphic = actor.pages.first.graphic!;
      final firstCharacter = firstGraphic.characterName.isEmpty
          ? null
          : characterBindings[sourceEventCharacterBindingKey(
              characterName: firstGraphic.characterName,
              pattern: firstGraphic.pattern,
              direction: firstGraphic.direction)];
      final entity = MapEntity(
          id: _key(actor, 'anchor'),
          name: _name(actor),
          kind:
              firstCharacter == null ? MapEntityKind.custom : MapEntityKind.npc,
          npc: firstCharacter == null
              ? null
              : MapEntityNpcData(
                  characterId: firstCharacter.characterId,
                  displayName: _name(actor),
                  facing: _sourceFacingDirection(firstGraphic.direction)!),
          blocksMovement: firstCharacter != null && !firstGraphic.through,
          pos: GridPos(x: actor.x, y: actor.y),
          presentation: MapEntityPresentation(variants: variants),
          properties: {
            'sourceEventIdentity': actor.identity.value,
            'sourceInteractionPolicy': 'preservedQuarantinedWholeEvent'
          });
      maps[actor.sourceMapId] =
          map.copyWith(entities: [...map.entities, entity]);
      mutations.add(_mutation('entity.upsert', entity.id, [
        actor.identity,
        actor.sourceFileId
      ], [
        map.id,
        entity.id
      ], {
        'mapId': map.id,
        'entity': entity.copyWith(presentation: null).toJson()
      }));
      mutations.add(
          _mutation('entity.set_presentation', '${entity.id}_presentation', [
        actor.identity,
        actor.sourceFileId
      ], [
        map.id,
        entity.id
      ], {
        'mapId': map.id,
        'entityId': entity.id,
        'presentation': entity.presentation!.toJson()
      }));
    }
  }

  Set<String> _starterFactIds(SourceStarterChoiceProgram program) => {
        _sourceControlAnalyzer.variableFactId(program.choiceVariableId),
        _sourceControlAnalyzer.globalFactId(program.offerSwitchId),
        _sourceControlAnalyzer.selfFactId(program.sourceMapId,
            program.sourceEventId, program.selfSwitchLetter),
        for (final foreign in _starterForeignIds(program))
          _sourceControlAnalyzer.selfFactId(
              program.sourceMapId, foreign, program.selfSwitchLetter),
      };

  Map<String, Set<ConverterId>> _starterFactOwners() {
    final result = <String, Set<ConverterId>>{};
    for (final entry in starterChoiceBindings.entries) {
      if (gapsByEvent[entry.key]?.isEmpty != true) continue;
      for (final id in _starterFactIds(entry.value.program)) {
        result.putIfAbsent(id, () => {}).add(entry.key);
      }
      for (final actorId in _starterActors(entry.value.program)) {
        final actor =
            analysis.eventAt(entry.value.program.sourceMapId, actorId)!;
        if (gapsByEvent[actor.identity]?.isEmpty == true) continue;
        final ids = <String>{};
        for (final page in actor.pages) {
          _collectFacts(page.condition, ids);
        }
        for (final id in ids) {
          result.putIfAbsent(id, () => {}).add(actor.identity);
        }
      }
    }
    return result;
  }

  void _collectStarterChoiceFacts(SourceEventDefinition event) {
    final binding = starterChoiceBindings[event.identity];
    if (binding == null) return;
    for (final id in _starterFactIds(binding.program)) {
      factsById.putIfAbsent(
          id,
          () => id.contains(':variable:')
              ? _sourceVariableFact(id)
              : _nativeFact(id));
    }
  }
}

extension _StarterChoiceScenes on _SceneBuilder {
  String _starterChoice(SourceStarterChoiceBinding binding, String end) {
    final commands = _starterCommands(binding.program, page.originalPageIndex);
    final texts = _starterTexts(commands);
    String speech(Iterable<({int index, String text})> lines, String next,
        {SourceChoiceNode? choice, Map<int, String>? targets}) {
      if (lines.isEmpty) return next;
      return _dialogue(page.body.span, null, choice, next,
          dialogueKey: 'starter_${page.originalPageIndex}_${lines.first.index}',
          feedbackLines: [
            for (final line in lines)
              projection._textFeedback(event, line.text)!
          ],
          choiceTargets: targets);
    }

    String effect(SceneConsequence value, String next) {
      final action = _node(SceneActionPayload.consequence(value));
      _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
      return action;
    }

    if (page.originalPageIndex == 0) return speech(texts, end);
    if (page.originalPageIndex == 3) return end;
    if (page.originalPageIndex == 2) {
      final fact = projection._sourceVariableFact(projection
          ._sourceControlAnalyzer
          .variableFactId(binding.program.choiceVariableId));
      final condition = _node(SceneConditionPayload(
          conditionSource: SceneConditionSource.factValue(
              factId: fact.id,
              operator: NarrativeFactOperator.equals,
              expectedValue: NarrativeValue.integer(
                  binding.program.remainingChoiceValue))));
      _edge(condition, 'true', speech(texts, end), SceneEdgeKind.conditionTrue);
      _edge(condition, 'false', end, SceneEdgeKind.conditionFalse);
      return condition;
    }
    final choiceIndex =
        commands.indexWhere((command) => command['code'] == 102);
    final giftIndex = commands.indexWhere((command) =>
        command['code'] == 355 &&
        ((command['parameters'] as List).single as String)
            .startsWith('pbAddPokemon('));
    final foreignIndex = commands.indexWhere((command) =>
        command['code'] == 355 &&
        ((command['parameters'] as List).single as String)
            .startsWith('pbSetSelfSwitch('));
    var after = end;
    for (final command in commands.sublist(foreignIndex).reversed) {
      final args = command['parameters'] as List;
      if (command['code'] == 123) {
        after = _fact(
            projection._sourceControlAnalyzer.selfFactId(
                event.sourceMapId, event.sourceEventId, args.first as String),
            true,
            after);
      } else if (command['code'] == 121) {
        after = _fact(
            projection._sourceControlAnalyzer.globalFactId(args.first as int),
            false,
            after);
      } else if (command['code'] == 122) {
        after = effect(
            SceneConsequence.setFactValue(
                factId: projection
                    ._sourceVariableFact(projection._sourceControlAnalyzer
                        .variableFactId(args.first as int))
                    .id,
                value: NarrativeValue.integer(args[4] as int)),
            after);
      } else if (command['code'] == 202) {
        final actor =
            projection.analysis.eventAt(event.sourceMapId, args.first as int)!;
        after = effect(
            SceneConsequence.setNpcPose(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(actor, 'anchor'),
                x: args[2] as int,
                y: args[3] as int),
            after);
      } else if (command['code'] == 355) {
        final match =
            RegExp(r'^pbSetSelfSwitch\(([1-9][0-9]*),"([A-D])",true\)$')
                .firstMatch(args.single as String);
        if (match != null) {
          after = _fact(
              projection._sourceControlAnalyzer.selfFactId(
                  event.sourceMapId, int.parse(match[1]!), match[2]!),
              true,
              after);
        }
      }
    }
    final rivalHideIndex = commands.indexWhere((command) =>
        command['code'] == 209 &&
        (command['parameters'] as List).first as int > 0 &&
        (((command['parameters'] as List)[1] as Map)['list'] as List)
            .cast<Map>()
            .any((step) => step['code'] == 42));
    after = speech(
        texts.where(
            (text) => text.index > rivalHideIndex && text.index < foreignIndex),
        after);
    final rivalBallId =
        (commands[rivalHideIndex]['parameters'] as List).first as int;
    final rivalBall =
        projection.analysis.eventAt(event.sourceMapId, rivalBallId)!;
    after = _interactive(
        SceneInteractiveCommand.actorVisibility(
            target: SceneActorTarget.entity(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(rivalBall, 'anchor')),
            visible: false),
        after);
    after = speech(
        texts.where(
            (text) => text.index > giftIndex && text.index < rivalHideIndex),
        after);
    final rivalRoute = commands
        .sublist(giftIndex + 1, foreignIndex)
        .where((command) => command['code'] == 209)
        .first;
    final routeArgs = rivalRoute['parameters'] as List;
    final actor =
        projection.analysis.eventAt(event.sourceMapId, routeArgs.first as int)!;
    final steps = <SceneActorRouteStep>[];
    for (final step in ((routeArgs[1] as Map)['list'] as List).cast<Map>()) {
      final code = step['code'] as int;
      final direction = switch (code) {
        1 || 16 => EntityFacing.south,
        2 || 17 => EntityFacing.west,
        3 || 18 => EntityFacing.east,
        4 || 19 => EntityFacing.north,
        _ => null
      };
      if (direction != null) {
        steps.add(code < 16
            ? SceneActorRouteStep.move(direction: direction, durationMs: 250)
            : SceneActorRouteStep.face(direction: direction));
      }
    }
    after = _interactive(
        SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.entity(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(actor, 'anchor')),
            steps: steps,
            skippable: false),
        after);
    after = _interactive(
        SceneInteractiveCommand.actorVisibility(
            target: SceneActorTarget.entity(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(event, 'anchor')),
            visible: false),
        after);
    final gift = SceneInteractiveCommand.receivePokemonFromCatalog(
        speciesId: binding.nativeSpeciesId,
        formId: binding.nativeFormId,
        level: binding.program.level,
        nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
        nicknameMaxGraphemes: 10,
        pokedexPresentationPolicy:
            ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible);
    final grant = _node(SceneActionPayload.interactive(gift));
    for (final port in gift.outputPortIds) {
      _edge(grant, port, port == 'noCapacity' ? end : after,
          SceneEdgeKind.actionCompleted);
    }
    final accepted = speech(
        texts.where(
            (text) => text.index > choiceIndex && text.index < giftIndex),
        grant);
    final labels = ((commands[choiceIndex]['parameters'] as List).first as List)
        .cast<String>();
    final choice = SourceChoiceNode(page.body.span, cancelType: 2, branches: [
      for (final label in labels.indexed)
        SourceChoiceBranch(label.$1, label.$2,
            SourceEventBlock(nodes: const [], span: page.body.span))
    ]);
    final offered = speech(texts.where((text) => text.index < choiceIndex), end,
        choice: choice, targets: {0: accepted, 1: end});
    final seen = effect(
        SceneConsequence.markPokemonSeen(speciesId: binding.nativeSpeciesId),
        offered);
    final professorRoute =
        commands.firstWhere((command) => command['code'] == 209);
    final professorId = (professorRoute['parameters'] as List).first as int;
    final professor =
        projection.analysis.eventAt(event.sourceMapId, professorId)!;
    final professorCode =
        (((professorRoute['parameters'] as List)[1] as Map)['list'] as List)
            .cast<Map>()
            .first['code'] as int;
    final professorFacing = switch (professorCode) {
      16 => EntityFacing.south,
      17 => EntityFacing.west,
      18 => EntityFacing.east,
      19 => EntityFacing.north,
      _ => throw const FormatException('Unqualified professor facing.')
    };
    return _interactive(
        SceneInteractiveCommand.actorRoute(
            target: SceneActorTarget.entity(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(professor, 'anchor')),
            steps: [SceneActorRouteStep.face(direction: professorFacing)],
            skippable: false),
        seen);
  }
}
