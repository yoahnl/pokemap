import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/scene_interactive_command.dart';
import '../models/scene_finish_game_contract.dart';
import '../models/rail_journey.dart';
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
    NarrativeCommandIds.setFact => SceneActionPayload.consequence(
      SceneConsequence.setFact(
        factId: parameters['factId']!,
        value: parameters['value'] == 'true',
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
    NarrativeCommandIds.warp => SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: parameters['destinationMapId']!,
        warpId: parameters['warpId']!,
      ),
    ),
    NarrativeCommandIds.openShop => SceneActionPayload.interactive(
      SceneInteractiveCommand.openShop(shopId: parameters['shopId']!),
    ),
    NarrativeCommandIds.openHeal => SceneActionPayload.interactive(
      SceneInteractiveCommand.openHeal(
        requiresConfirmation: parameters['requiresConfirmation'] != 'false',
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
    NarrativeCommandIds.moveNpc => SceneActionPayload.interactive(
      switch (_parseNpcRef(parameters['npcRef'])) {
        (final mapId, final entityId) => SceneInteractiveCommand.moveNpc(
          mapId: mapId,
          entityId: entityId,
          warpId: parameters['warpId']!,
        ),
      },
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
