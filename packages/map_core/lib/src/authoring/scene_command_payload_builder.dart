import 'dart:convert';

import '../models/scene_warp_presentation.dart';
import '../models/dialogue_line_feedback.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/scene_interactive_command.dart';
import '../models/scene_actor_route.dart';
import '../models/scene_finish_game_contract.dart';
import '../models/scene_structured_interaction.dart';
import '../models/rail_journey.dart';
import '../models/moving_platform.dart';
import '../models/enums.dart';
import '../models/project_presentation_profile.dart';
import '../runtime/character_custom_animation_runtime_contract.dart';
import '../read_models/narrative_command_catalog.dart';

part 'scene_command_payload_helpers.dart';

SceneNodePayload buildScenePayloadForNarrativeCommand({
  required String commandId,
  required Map<String, String> parameters,
}) {
  int integer(String id, {int fallback = 1}) =>
      int.tryParse(parameters[id] ?? '') ?? fallback;
  return switch (commandId) {
    NarrativeCommandIds.inputTextToFact => SceneActionPayload.interactive(
      SceneInteractiveCommand.inputTextToFact(
        factId: parameters['factId']!,
        prompt: SceneInteractionPrompt(localizationKey: 'scene.inputTextToFact.prompt', fallbackText: parameters['prompt']),
        confirmationPrompt: SceneInteractionPrompt(localizationKey: 'scene.inputTextToFact.confirmation', fallbackText: parameters['confirmationPrompt']),
        constraints: SceneTextInputConstraints(minGraphemes: int.parse(parameters['minGraphemes']!), maxGraphemes: int.parse(parameters['maxGraphemes']!)),
        presetValues: const LineSplitter().convert(parameters['presetValues'] ?? '').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
        customChoiceLabel: (parameters['presetValues'] ?? '').trim().isEmpty ? null : ((parameters['customChoiceLabel'] ?? '').trim().isEmpty ? 'Personnalisé' : parameters['customChoiceLabel']),
        presetChoicePrompt: (parameters['presetValues'] ?? '').trim().isEmpty ? null : SceneInteractionPrompt(localizationKey: 'scene.inputTextToFact.choice', fallbackText: (parameters['presetChoicePrompt'] ?? '').trim().isEmpty ? parameters['prompt'] : parameters['presetChoicePrompt']),
      ),
    ),
    NarrativeCommandIds.setMapEventInstanceBoolean =>
      SceneActionPayload.consequence(_mapEventInstanceBooleanConsequence(parameters)),
    NarrativeCommandIds.setFact => SceneActionPayload.consequence(
      SceneConsequence.setFact(
        factId: parameters['factId']!,
        value: parameters['value'] == 'true',
      ),
    ),
    NarrativeCommandIds.adjustIntegerFact => _buildIntegerFactAdjustment(parameters),
    NarrativeCommandIds.setPlayerAvatar => SceneActionPayload.consequence(
      SceneConsequence.setPlayerAvatar(
        characterId: parameters['characterId'] ?? '',
      ),
    ),
    NarrativeCommandIds.markEventConsumed => SceneActionPayload.consequence(
      SceneConsequence.markEventConsumed(
        mapId: parameters['mapId']!,
        eventId: parameters['eventId']!,
      ),
    ),
    NarrativeCommandIds.completeStoryStep => SceneActionPayload.consequence(
      SceneConsequence.completeStoryStep(stepId: parameters['stepId']!),
    ),
    NarrativeCommandIds.giveItem => SceneActionPayload.consequence(
      SceneConsequence.giveItem(
        itemId: parameters['itemId']!,
        quantity: integer('quantity'),
      ),
    ),
    NarrativeCommandIds.giveItemGift => SceneActionPayload.interactive(
      SceneInteractiveCommand.giveItem(
        itemId: parameters['itemId']!,
        quantity: int.parse(parameters['quantity']!),
      ),
    ),
    NarrativeCommandIds.takeItem => SceneActionPayload.consequence(
      SceneConsequence.takeItem(
        itemId: parameters['itemId']!,
        quantity: integer('quantity'),
      ),
    ),
    NarrativeCommandIds.giveMoney => SceneActionPayload.consequence(
      SceneConsequence.giveMoney(amount: integer('amount')),
    ),
    NarrativeCommandIds.givePokemon => SceneActionPayload.consequence(
      SceneConsequence.givePokemon(
        speciesId: parameters['speciesId']!,
        formId: parameters['formId']!,
        level: integer('level'),
        currentHp: integer('currentHp', fallback: integer('level')),
        natureId: parameters['natureId'] ?? 'hardy',
        abilityId: parameters['abilityId'] ?? 'unknown',
      ),
    ),
    NarrativeCommandIds.receivePokemonFromCatalog => SceneActionPayload.interactive(
      SceneReceivePokemonFromCatalogInteractiveCommand.fromJson(
        _catalogGiftParameters(commandId, parameters),
      ),
    ),
    NarrativeCommandIds.markPokemonSeen => SceneActionPayload.consequence(SceneConsequence.markPokemonSeen(speciesId: parameters['speciesId']!)),
    NarrativeCommandIds.givePokemonFromCatalog => SceneActionPayload.consequence(
      SceneGivePokemonFromCatalogConsequence.fromJson(
        _catalogGiftParameters(commandId, parameters),
      ),
    ),
    NarrativeCommandIds.giveConfiguredStarter => SceneActionPayload.consequence(
      SceneConsequence.giveConfiguredStarter(
        starterOptionId: parameters['starterOptionId']!,
      ),
    ),
    NarrativeCommandIds.healParty => SceneActionPayload.consequence(
      SceneConsequence.healParty(),
    ),
    NarrativeCommandIds.awardBadge => SceneActionPayload.consequence(
      SceneConsequence.awardBadge(badgeId: parameters['badgeId']!),
    ),
    NarrativeCommandIds.unlockFieldAbility => SceneActionPayload.consequence(
      SceneConsequence.unlockFieldAbility(
        ability: _fieldAbilityFromId(parameters['abilityId']!),
      ),
    ),
    NarrativeCommandIds.finishGame => SceneActionPayload.consequence(
      _buildFinishGameConsequence(parameters),
    ),
    NarrativeCommandIds.setNpcPose => SceneActionPayload.consequence(
      switch (_parseNpcRef(parameters['npcRef'])) {
        (final mapId, final entityId) => SceneConsequence.setNpcPose(
          mapId: mapId, entityId: entityId,
          x: parameters['x']?.trim().isNotEmpty == true ? int.parse(parameters['x']!) : null,
          y: parameters['y']?.trim().isNotEmpty == true ? int.parse(parameters['y']!) : null,
          facing: parameters['facing']?.isNotEmpty == true ? EntityFacing.values.byName(parameters['facing']!) : null,
        ),
      },
    ),
    NarrativeCommandIds.setNpcPresence => SceneActionPayload.consequence(
      switch (_parseNpcRef(parameters['npcRef'])) {
        (final mapId, final entityId) => SceneConsequence.setNpcPresence(
          mapId: mapId,
          entityId: entityId,
          present: parameters['present'] == 'true',
        ),
      },
    ),
    NarrativeCommandIds.setPauseMenuEntryVisibility =>
      SceneActionPayload.consequence(
        SceneConsequence.setPauseMenuEntryVisibility(
          actionId: ProjectPauseActionId.values.byName(parameters['actionId']!),
          visible: parameters['visible'] == 'true',
        ),
      ),
    NarrativeCommandIds.playCharacterAnimation =>
      SceneActionPayload.interactive(
        SceneInteractiveCommand.playCharacterAnimation(
          runtimeCommand: CharacterCustomAnimationRuntimeCommand(
            actorId: parameters['actorId']!,
            definitionId: parameters['definitionId']!,
            direction: switch (parameters['direction']) {
              final direction? when direction.trim().isNotEmpty =>
                EntityFacing.values.byName(direction),
              _ => null,
            },
            playback: switch (parameters['playbackKind']) {
              'repeatCount' => CharacterCustomAnimationPlayback.repeatCount(
                integer('repeatCount'),
              ),
              'forDuration' => CharacterCustomAnimationPlayback.forDuration(
                integer('durationMs'),
              ),
              _ => CharacterCustomAnimationPlayback.once(),
            },
          ),
        ),
      ),
    NarrativeCommandIds.warp => _buildWarpPayload(parameters),
    NarrativeCommandIds.waitForActorRoutes => _buildWaitForActorRoutesPayload(parameters),
    NarrativeCommandIds.wait => _buildWaitPayload(parameters),
    NarrativeCommandIds.worldTone => _buildWorldTonePayload(parameters),
    NarrativeCommandIds.sceneMusic => _buildSceneMusicPayload(parameters),
    NarrativeCommandIds.playMusicEffect => _buildMusicEffectPayload(parameters),
    NarrativeCommandIds.playSoundEffect => _buildSoundEffectPayload(parameters),
    NarrativeCommandIds.actorVisibility => _buildActorVisibilityPayload(
      parameters,
    ),
    NarrativeCommandIds.actorRoute => throw const FormatException(
      'Actor routes require the typed target and steps builder.',
    ),
    NarrativeCommandIds.openShop => SceneActionPayload.interactive(
      SceneInteractiveCommand.openShop(shopId: parameters['shopId']!),
    ),
    NarrativeCommandIds.openHeal => SceneActionPayload.interactive(
      SceneInteractiveCommand.openHeal(
        requiresConfirmation: parameters['requiresConfirmation'] != 'false',
        displayEntityId: parameters['displayEntityId'],
      ),
    ),
    NarrativeCommandIds.openPc => SceneActionPayload.interactive(
      switch (parameters['storageId']) {
        final storageId? => SceneInteractiveCommand.openPc(
          storageId: storageId,
        ),
        null => SceneInteractiveCommand.openPc(),
      },
    ),
    NarrativeCommandIds.whiteOut => parameters.isEmpty
        ? SceneActionPayload.interactive(SceneInteractiveCommand.whiteOut())
        : throw const FormatException('White-out commands do not accept options.'),
    NarrativeCommandIds.openPartyTrade =>
      parameters.isEmpty
          ? SceneActionPayload.interactive(
              SceneInteractiveCommand.openPartyTrade(),
            )
          : throw const FormatException(
              'Party trade commands do not accept options.',
            ),
    NarrativeCommandIds.openRegionalMap => parameters.isEmpty
        ? SceneActionPayload.interactive(SceneInteractiveCommand.openRegionalMap())
        : throw const FormatException('Regional map commands do not accept options.'),
    NarrativeCommandIds.setPropState => SceneActionPayload.interactive(
      SceneInteractiveCommand.fromJson({
        'kind': 'setPropState',
        'mapId': parameters['mapId'],
        'propIds': jsonDecode(parameters['propIds'] ?? '[]'),
        'state': parameters['state'],
        'durationMs': int.parse(parameters['durationMs'] ?? '350'),
      }),
    ),
    NarrativeCommandIds.movePlatform => SceneActionPayload.interactive(
      switch (_parseNpcRef(parameters['platformRef'])) {
        (final mapId, final platformId) => SceneInteractiveCommand.movePlatform(
          mapId: mapId, platformId: platformId,
          motion: MovingPlatformMotion.values.byName(parameters['motion']!),
        ),
      },
    ),
    NarrativeCommandIds.moveNpc => SceneActionPayload.interactive(
      switch (_parseNpcRef(parameters['npcRef'])) {
        (final mapId, final entityId) => SceneInteractiveCommand.moveNpc(
          mapId: mapId,
          entityId: entityId,
          warpId: parameters['warpId']!,
        ),
      },
    ),
    NarrativeCommandIds.playModelAnimation => SceneActionPayload.interactive(
      SceneInteractiveCommand.playModelAnimation(
        mapId: parameters['mapId']!,
        instanceId: parameters['instanceId']!,
        animationIndex: int.parse(parameters['animationIndex']!),
        speed: switch (parameters['speed']) {
          final value? when value.trim().isNotEmpty => double.parse(value),
          _ => 1,
        },
        blocksMovementAfter: switch (parameters['blocksMovementAfter']) {
          'true' => true,
          'false' => false,
          null || '' => null,
          final value => throw ArgumentError.value(
            value,
            'blocksMovementAfter',
          ),
        },
      ),
    ),
    NarrativeCommandIds.railJourney => buildSceneRailJourneyPayload(parameters),
    NarrativeCommandIds.dialogue => SceneYarnDialoguePayload(
      dialogueId: parameters['dialogueId']!,
    ),
    NarrativeCommandIds.trainerBattle => SceneBattlePayload(
      battleKind: 'trainer',
      trainerId: parameters['trainerId']!,
    ),
    NarrativeCommandIds.staticEncounter => SceneBattlePayload(
      battleKind: 'static',
      trainerId: _staticEncounterTrainerId(parameters),
      battleTemplateId: _staticEncounterBattleTemplateId(parameters),
      declaredOutcomes: const ['victory', 'defeat'],
    ),
    NarrativeCommandIds.cinematic => SceneCinematicPayload(
      cinematicId: parameters['cinematicId']!,
    ),
    _ => throw ArgumentError.value(
      commandId,
      'commandId',
      'An unsupported Narrative command cannot produce a Scene payload.',
    ),
  };
}

SceneActionPayload _buildIntegerFactAdjustment(Map<String, String> parameters) {
  const fields = {'factId', 'delta', 'minimum', 'maximum'};
  if (parameters.length != fields.length ||
      !fields.every(parameters.containsKey)) {
    throw const FormatException('An integer adjustment requires its Fact and all three numeric fields.');
  }
  int value(String key) {
    final raw = parameters[key]!;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed.toString() != raw) {
      throw FormatException('Integer adjustment $key must be a canonical integer.');
    }
    return parsed;
  }
  return SceneActionPayload.consequence(SceneConsequence.adjustIntegerFact(
    factId: parameters['factId']!,
    delta: value('delta'),
    minimum: value('minimum'),
    maximum: value('maximum'),
  ));
}
Map<String, dynamic> _catalogGiftParameters(
  String commandId,
  Map<String, String> parameters,
) {
  if (parameters.containsKey('kind')) {
    throw const FormatException('Gift parameters cannot replace the command kind.');
  }
  return {
  'kind': commandId,
  for (final entry in parameters.entries)
    entry.key: switch (entry.key) {
      'level' || 'nicknameMaxGraphemes' => int.tryParse(entry.value),
      'moveIds' => switch (jsonDecode(entry.value)) {
        final List<dynamic> values => values,
        _ => throw const FormatException('Imposed gift moves must be a JSON list.'),
      },
      _ => entry.value,
    },
  };
}

SceneActionPayload _buildWaitForActorRoutesPayload(Map<String, String> parameters) {
  _requirePresentationParameters(parameters, const {'mapId'});
  return SceneActionPayload.interactive(SceneInteractiveCommand.waitForActorRoutes(mapId: parameters['mapId']!));
}

SceneActionPayload _buildWaitPayload(Map<String, String> parameters) {
  _requirePresentationParameters(parameters, const {'durationMs'});
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.wait(durationMs: int.parse(parameters['durationMs']!)),
  );
}

SceneActionPayload _buildWorldTonePayload(Map<String, String> parameters) {
  _requirePresentationParameters(parameters, const {
    'red',
    'green',
    'blue',
    'gray',
    'durationMs',
  });
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.worldTone(
      red: double.parse(parameters['red']!),
      green: double.parse(parameters['green']!),
      blue: double.parse(parameters['blue']!),
      gray: double.parse(parameters['gray']!),
      durationMs: int.parse(parameters['durationMs']!),
    ),
  );
}

SceneActionPayload _buildSoundEffectPayload(Map<String, String> parameters) {
  _requirePresentationParameters(parameters, const {'mediaAssetId', 'volume'});
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.playSoundEffect(
      mediaAssetId: parameters['mediaAssetId']!,
      volume: double.parse(parameters['volume']!),
    ),
  );
}

SceneActionPayload buildSceneActorRoutePayload({
  required SceneActorTarget target,
  required List<SceneActorRouteStep> steps,
  bool skippable = false,
  ActorRouteTransientScope transientScope = ActorRouteTransientScope.route,
  String? actionKind,
  Map<String, String> parameters = const {},
}) => SceneActionPayload.interactive(
  SceneInteractiveCommand.actorRoute(
    target: target,
    steps: steps,
    skippable: skippable,
    transientScope: transientScope,
  ),
  actionKind: actionKind,
  parameters: parameters,
);

SceneActionPayload _buildActorVisibilityPayload(
  Map<String, String> parameters,
) {
  final entity = parameters['targetKind'] == 'entity';
  _requirePresentationParameters(parameters, {
    'mapId',
    'targetKind',
    'visible',
    if (entity) 'entityId',
  });
  final target = switch (parameters['targetKind']) {
    'player' => SceneActorTarget.player(mapId: parameters['mapId']!),
    'entity' => SceneActorTarget.entity(
      mapId: parameters['mapId']!,
      entityId: parameters['entityId']!,
    ),
    _ => throw const FormatException('Unknown actor target kind.'),
  };
  final visible = switch (parameters['visible']) {
    'true' => true,
    'false' => false,
    _ => throw const FormatException('visible must be true or false.'),
  };
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.actorVisibility(target: target, visible: visible),
  );
}

void _requirePresentationParameters(
  Map<String, String> parameters,
  Set<String> fields,
) {
  final keys = parameters.keys.toSet();
  if (keys.difference(fields).isNotEmpty ||
      fields.difference(keys).isNotEmpty) {
    throw const FormatException(
      'Presentation command parameters do not match the contract.',
    );
  }
}

SceneActionPayload buildSceneRailJourneyPayload(
  Map<String, String> parameters,
) {
  final operation = SceneRailJourneyOperation.values.byName(
    parameters['operation']!,
  );
  final direction = switch (operation) {
    SceneRailJourneyOperation.begin => switch (parameters['direction']) {
      'outbound' => RailJourneyDirection.outbound,
      'return' => RailJourneyDirection.returnJourney,
      final value => throw ArgumentError.value(value, 'direction'),
    },
    SceneRailJourneyOperation.advance ||
    SceneRailJourneyOperation.acknowledge => null,
  };
  final advanceEvent = switch (operation) {
    SceneRailJourneyOperation.advance =>
      SceneRailJourneyAdvanceEvent.values.byName(parameters['advanceEvent']!),
    SceneRailJourneyOperation.begin ||
    SceneRailJourneyOperation.acknowledge => null,
  };
  final doorSide = switch ((operation, advanceEvent)) {
    (SceneRailJourneyOperation.begin, _) ||
    (
      SceneRailJourneyOperation.advance,
      SceneRailJourneyAdvanceEvent.destinationDoorUsed,
    ) => RailJourneyDoorSide.values.byName(parameters['doorSide']!),
    _ => null,
  };
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.railJourney(
      commandId: parameters['commandId']!,
      journeyId: parameters['journeyId']!,
      operation: operation,
      direction: direction,
      advanceEvent: advanceEvent,
      doorSide: doorSide,
    ),
  );
}

SceneConsequence _mapEventInstanceBooleanConsequence(Map<String, String> parameters) {
  const fields = {'mapId', 'eventId', 'key', 'value'};
  if (parameters.length != fields.length || !parameters.keys.every(fields.contains) ||
      (parameters['value'] != 'true' && parameters['value'] != 'false')) {
    throw ArgumentError.value(parameters, 'parameters',
        'Instance boolean requires mapId, eventId, key and a literal true/false value.');
  }
  return SceneConsequence.setMapEventInstanceBoolean(mapId: parameters['mapId']!,
      eventId: parameters['eventId']!, key: parameters['key']!,
      value: parameters['value'] == 'true');
}

SceneActionPayload _buildSceneMusicPayload(Map<String, String> parameters) {
  final operation = SceneMusicOperation.values.byName(
    parameters['operation'] ?? '',
  );
  _requirePresentationParameters(parameters, switch (operation) {
    SceneMusicOperation.play => const {'operation', 'mediaAssetId', 'volume'},
    SceneMusicOperation.restore => const {'operation'},
    SceneMusicOperation.fadeOut => const {'operation', 'durationMs'},
  });
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.sceneMusic(
      operation: operation,
      mediaAssetId: operation == SceneMusicOperation.play
          ? parameters['mediaAssetId']
          : null,
      volume: operation == SceneMusicOperation.play
          ? double.parse(parameters['volume']!)
          : null,
      durationMs: operation == SceneMusicOperation.fadeOut
          ? int.parse(parameters['durationMs']!)
          : null,
    ),
  );
}

SceneActionPayload _buildMusicEffectPayload(Map<String, String> parameters) {
  _requirePresentationParameters(parameters, const {
    'mediaAssetId', 'volume', 'fadeOutMs', 'fadeInMs',
  });
  return SceneActionPayload.interactive(
    SceneInteractiveCommand.playMusicEffect(
      mediaAssetId: parameters['mediaAssetId']!,
      volume: double.parse(parameters['volume']!),
      bgmInterruption: DialogueBgmInterruption(
        fadeOutMs: int.parse(parameters['fadeOutMs']!),
        fadeInMs: int.parse(parameters['fadeInMs']!),
      ),
    ),
  );
}
