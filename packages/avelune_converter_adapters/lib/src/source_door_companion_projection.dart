part of 'source_event_projection.dart';

extension _DoorCompanionProjection on _ProjectionBuilder {
  Set<String> _doorCompanionPresentationGaps(SourceEventDefinition actor,
      {required bool checkCharacterBindings}) {
    final gaps = <String>{..._sourceControlGaps(actor)};
    if (!sourceRoutedDoorCompanionIsBound(
        source: source, analysis: analysis, event: actor)) {
      return {'sourceDoorCompanionSourceMismatch'};
    }
    final map = maps[actor.sourceMapId]!;
    if (_eventFootprint(actor) != const GridSize(width: 1, height: 1) ||
        actor.x < 0 ||
        actor.y < 0 ||
        actor.x >= map.size.width ||
        actor.y >= map.size.height) {
      gaps.add('sourceDoorCompanionGeometryUnsupported');
    }
    for (final page in actor.pages) {
      if (page.triggerCode != 0) {
        gaps.add('sourceDoorCompanionTriggerUnsupported');
      }
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
          (graphic.moveType != 0 && _fixedRouteBindings(actor) == null) ||
          graphic.stepAnime ||
          (graphic.directionFix && graphic.moveType != 0) ||
          graphic.alwaysOnTop) {
        gaps.add('sourceDoorCompanionPresentationUnsupported');
        continue;
      }
      if (checkCharacterBindings &&
          graphic.characterName.isNotEmpty &&
          characterBindings[sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction,
                  fixedDirection: graphic.directionFix)] ==
              null) {
        gaps.add('sourceDoorCompanionCharacterMissing');
      }
    }
    return gaps;
  }

  bool _doorCompanionCandidate(SourceEventDefinition actor) =>
      routedDoorPrograms.values.any((program) =>
          program.sourceMapId == actor.sourceMapId &&
          program.foreignCompanionEventIds.contains(actor.sourceEventId)) &&
      _doorCompanionPresentationGaps(actor, checkCharacterBindings: false)
          .isEmpty;

  bool _qualifiedDoorCompanion(
          SourceEventDefinition owner, SourceEventDefinition actor,
          {required bool checkCharacterBindings}) =>
      qualifiedRoutedDoorContexts.contains(owner.identity) &&
      routedDoorPrograms[owner.identity]
              ?.foreignCompanionEventIds
              .contains(actor.sourceEventId) ==
          true &&
      owner.sourceMapId == actor.sourceMapId &&
      _doorCompanionPresentationGaps(actor,
              checkCharacterBindings: checkCharacterBindings)
          .isEmpty;

  void _projectDoorCompanions() {
    final used = <(int, int)>{
      for (final entry in routedDoorPrograms.entries)
        if (gapsByEvent[entry.key]?.isEmpty == true)
          for (final id in entry.value.foreignCompanionEventIds)
            (entry.value.sourceMapId, id),
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
        final graphic = page.graphic!;
        final character = graphic.characterName.isEmpty
            ? null
            : characterBindings[sourceEventCharacterBindingKey(
                characterName: graphic.characterName,
                pattern: graphic.pattern,
                direction: graphic.direction,
                fixedDirection: graphic.directionFix)]!;
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
              direction: firstGraphic.direction,
              fixedDirection: firstGraphic.directionFix)];
      final entity = MapEntity(
          id: _key(actor, 'anchor'),
          name: _name(actor),
          kind:
              firstCharacter == null ? MapEntityKind.custom : MapEntityKind.npc,
          npc: firstCharacter == null
              ? null
              : MapEntityNpcData(
                  characterId: firstCharacter.characterId,
                  movement: _nativeFixedMovement(actor),
                  displayName: _name(actor),
                  facing: _sourceFacingDirection(firstGraphic.direction)!),
          blocksMovement: firstCharacter != null && !firstGraphic.through,
          pos: GridPos(x: actor.x, y: actor.y),
          presentation: MapEntityPresentation(variants: variants),
          properties: {
            'sourceEventIdentity': actor.identity.value,
            'sourceInteractionPolicy': 'preservedQuarantinedWholeEvent',
            'sourceCompanionPolicy': 'closedRoutedDoorForeignStatePresentation'
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

  List<Map<String, Object?>> _doorCompanionEvidence() => [
        for (final entry in routedDoorPrograms.entries)
          if (gapsByEvent[entry.key]?.isEmpty == true)
            for (final id in entry.value.foreignCompanionEventIds)
              if (analysis.eventAt(entry.value.sourceMapId, id)
                  case final actor?)
                {
                  'ownerIdentity': entry.key.value,
                  'actorIdentity': actor.identity.value,
                  'sourceMapId': actor.sourceMapId,
                  'sourceEventId': actor.sourceEventId,
                  'sourceName': actor.name,
                  'x': actor.x,
                  'y': actor.y,
                  'presentationAndFlagsQualified': true,
                  'interactionPlaybackQualified':
                      gapsByEvent[actor.identity]?.isEmpty == true,
                  'interactionGaps': gapsByEvent[actor.identity]!.toList()
                    ..sort(),
                  'sourceScriptsExecuted': 0,
                  'pages': [
                    for (final page in actor.pages)
                      {
                        'sourcePageIndex': page.originalPageIndex,
                        'rawDataRef': page.rawDataRef?.toJson(),
                        'condition': page.condition.toJson(),
                        'fixedDirection': page.graphic?.directionFix,
                      }
                  ],
                  if (_fixedRouteBindings(actor) case final bindings?)
                    'autonomousMovement':
                        bindings.map((binding) => binding.toJson()).toList(),
                },
      ];

  Map<String, Set<ConverterId>> _doorCompanionFactOwners() {
    final result = <String, Set<ConverterId>>{};
    for (final entry in routedDoorPrograms.entries) {
      if (gapsByEvent[entry.key]?.isEmpty != true) continue;
      for (final actorId in entry.value.foreignCompanionEventIds) {
        final actor = analysis.eventAt(entry.value.sourceMapId, actorId)!;
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
}
