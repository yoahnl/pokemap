import 'dart:typed_data';
import 'dart:ui';
import 'package:map_core/map_core.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_gameplay/map_gameplay.dart';
import '../session/player_input.dart';
import '../application/dialogue_portrait_resolver.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
import '../presentation/flame/dialogue_text_speed.dart';
import '../player/runtime_audio_mixer.dart';
import '../player/runtime_player_host.dart';
import '../player/runtime_player_models.dart';
import '../player/runtime_player_pause_data.dart';
import '../player/runtime_pokemon_summary.dart';
import '../player/runtime_regional_map.dart';
import '../presentation/flutter/battle_command_overlay_snapshot.dart';
import '../session/game_session_contract.dart';
import 'runtime_world_service_models.dart';

part 'runtime_world_service_companion_codec.dart';

abstract final class RuntimeCompanionPresentationCodec {
  static Map<String, dynamic> _map(Object? value) =>
      normalizeMap(value);

  static Map<String, dynamic> normalizeMap(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Presentation data must be a string-keyed object.');
    }
    Object? normalize(Object? item) => switch (item) {
      final Map map => normalizeMap(map),
      final List list => list.map(normalize).toList(),
      null || String() || bool() || num() => item,
      _ => throw const FormatException('Unsupported presentation value.'),
    };
    return value.map((key, item) => MapEntry(key as String, normalize(item)));
  }

  static Map<String, Object?> encodePlayer(RuntimePlayerSnapshot value) => {
        'revision': value.revision,
        'preSessionRequest': value.preSessionRequest?.toJson(),
        'worldService': value.worldService == null ? null : encodeWorldService(value.worldService!),
        'phase': value.phase.name,
        'gameTitle': value.gameTitle,
        'pauseSection': value.pauseSection?.name,
        'actions': value.actions
            .map((action) => {
                  'action': action.action.name,
                  'isEnabled': action.isEnabled,
                  'reason': action.unavailableReason,
                })
            .toList(),
        'logicalSelectionId': value.logicalSelectionId,
        'activeInputSource': value.activeInputSource?.name,
        'preferences': value.preferences == null
            ? null
            : encodePlayerPreferencesSnapshot(value.preferences!),
        'defaultPreferences':
            encodePlayerPreferencesSnapshot(value.defaultPreferences),
        'activeSaveAddress': value.activeSaveAddress == null
            ? null
            : encodeRuntimePlayerSaveAddress(value.activeSaveAddress!),
        'saveReceipt': value.saveReceipt == null
            ? null
            : encodeRuntimePlayerSaveReceipt(value.saveReceipt!),
        'pauseMenuState': value.pauseMenuState.toJson(),
        'favoriteItemIds': value.favoriteItemIds.toList(),
        'bagFavoritesAvailable': value.bagFavoritesAvailable,
        'pauseDetails': value.pauseDetails.values
            .map(encodeRuntimePlayerPauseDetailSnapshot)
            .toList(),
      };

  static RuntimePlayerSnapshot decodePlayer(Map<String, dynamic> data) =>
      RuntimePlayerSnapshot(
        revision: data['revision'] as int,
        preSessionRequest: data['preSessionRequest'] == null
            ? null
            : SceneInteractionRequest.fromJson(_map(data['preSessionRequest'])),
        worldService: data['worldService'] == null ? null : decodeWorldService(_map(data['worldService'])),
        phase: RuntimePlayerPhase.values.byName(data['phase'] as String),
        gameTitle: data['gameTitle'] as String,
        pauseSection: data['pauseSection'] == null
            ? null
            : RuntimePlayerPauseSection.values
                .byName(data['pauseSection'] as String),
        actions: (data['actions'] as List).map((raw) {
          final action = _map(raw);
          final id =
              RuntimePlayerAction.values.byName(action['action'] as String);
          return action['isEnabled'] == true
              ? RuntimePlayerActionAvailability.enabled(id)
              : RuntimePlayerActionAvailability.disabled(id,
                  reason: action['reason'] as String);
        }).toList(),
        logicalSelectionId: data['logicalSelectionId'] as String?,
        activeInputSource: data['activeInputSource'] == null
            ? null
            : PlayerInputSource.values
                .byName(data['activeInputSource'] as String),
        preferences: data['preferences'] == null
            ? null
            : decodePlayerPreferencesSnapshot(_map(data['preferences'])),
        defaultPreferences:
            decodePlayerPreferencesSnapshot(_map(data['defaultPreferences'])),
        activeSaveAddress: data['activeSaveAddress'] == null
            ? null
            : decodeRuntimePlayerSaveAddress(_map(data['activeSaveAddress'])),
        saveReceipt: data['saveReceipt'] == null
            ? null
            : decodeRuntimePlayerSaveReceipt(_map(data['saveReceipt'])),
        pauseMenuState:
            PlayerPauseMenuState.fromJson(_map(data['pauseMenuState'])),
        favoriteItemIds:
            (data['favoriteItemIds'] as List).cast<String>().toSet(),
        bagFavoritesAvailable: data['bagFavoritesAvailable'] as bool,
        pauseDetails: {
          for (final raw in data['pauseDetails'] as List)
            RuntimePlayerPauseSection.values
                    .byName(_map(raw)['section'] as String):
                decodeRuntimePlayerPauseDetailSnapshot(_map(raw)),
        },
      );

  static Map<String, Object?> encodeDialogue(
    DialoguePresentationSnapshot value,
  ) => {
    'revision': value.revision,
    'mode': value.mode.name,
    'nodeTitle': value.nodeTitle,
    'speaker': value.speaker,
    'text': value.text,
    'fullText': value.fullText,
    'isCurrentLineFullyRevealed': value.isCurrentLineFullyRevealed,
    'isLastContent': value.isLastContent,
    'isAdvanceAvailable': value.isAdvanceAvailable,
    'choices': [
      for (final choice in value.choices)
        {
          'index': choice.index,
          'label': choice.label,
          'selected': choice.selected,
          'enabled': choice.enabled,
        },
    ],
    'portrait': value.portrait == null
        ? null
        : {
            'characterId': value.portrait!.characterId,
            'characterName': value.portrait!.characterName,
            'portraitStateId': value.portrait!.portraitStateId,
            'portraitStateName': value.portrait!.portraitStateName,
            'assetId': value.portrait!.assetId,
            'absoluteFilePath': value.portrait!.absoluteFilePath,
            'fitMode': value.portrait!.fitMode.name,
          },
    'segments': value.segments.map((segment) => segment.toJson()).toList(),
    'iconPngBytes': {
      for (final entry in value.iconPngBytes.entries)
        entry.key: entry.value.toList(growable: false),
    },
  };

  static DialoguePresentationSnapshot decodeDialogue(
    Map<String, dynamic> data,
  ) {
    final revision = data['revision'];
    if (revision is! int || revision < 0) {
      throw const FormatException('Invalid dialogue presentation revision.');
    }
    final choices = (data['choices'] as List)
        .map((raw) {
          final choice = _map(raw);
          final index = choice['index'];
          if (index is! int || index < 0) {
            throw const FormatException('Invalid dialogue choice index.');
          }
          return DialoguePresentationChoice(
            index: index,
            label: choice['label'] as String,
            selected: choice['selected'] as bool,
            enabled: choice['enabled'] as bool,
          );
        })
        .toList(growable: false);
    if (choices.map((choice) => choice.index).toSet().length !=
        choices.length) {
      throw const FormatException('Duplicate dialogue choice index.');
    }
    final portrait = data['portrait'] == null ? null : _map(data['portrait']);
    return DialoguePresentationSnapshot(
      revision: revision,
      mode: DialoguePresentationMode.values.byName(data['mode'] as String),
      nodeTitle: data['nodeTitle'] as String?,
      speaker: data['speaker'] as String?,
      text: data['text'] as String,
      fullText: data['fullText'] as String,
      isCurrentLineFullyRevealed: data['isCurrentLineFullyRevealed'] as bool,
      isLastContent: data['isLastContent'] as bool,
      isAdvanceAvailable: data['isAdvanceAvailable'] as bool,
      choices: choices,
      portrait: portrait == null
          ? null
          : ResolvedDialoguePortrait(
              characterId: portrait['characterId'] as String,
              characterName: portrait['characterName'] as String,
              portraitStateId: portrait['portraitStateId'] as String,
              portraitStateName: portrait['portraitStateName'] as String,
              assetId: portrait['assetId'] as String,
              absoluteFilePath: portrait['absoluteFilePath'] as String,
              fitMode: CharacterPortraitFitMode.values.byName(
                portrait['fitMode'] as String,
              ),
            ),
      segments: (data['segments'] as List)
          .map((raw) => DialogueLineSegment.fromJson(_map(raw)))
          .toList(growable: false),
      iconPngBytes: {
        for (final entry in _map(data['iconPngBytes']).entries)
          entry.key: _dialogueIconBytes(entry.value),
      },
    );
  }

  static Uint8List _dialogueIconBytes(Object? value) {
    if (value is! List ||
        value.any((byte) => byte is! int || byte < 0 || byte > 255)) {
      throw const FormatException('Invalid dialogue icon bytes.');
    }
    return Uint8List.fromList(value.cast<int>());
  }

  static Map<String, Object?> encodeDialogueCommand(
    DialoguePresentationCommand command,
  ) => {
    'snapshotRevision': command.snapshotRevision,
    'action': command is DialogueAdvanceCommand ? 'advance' : 'choice',
    if (command is DialogueSelectChoiceCommand)
      'choiceIndex': command.choiceIndex,
  };

  static DialoguePresentationCommand decodeDialogueCommand(
    Map<String, dynamic> data,
  ) {
    final revision = data['snapshotRevision'];
    if (revision is! int || revision < 0) {
      throw const FormatException('Invalid dialogue command revision.');
    }
    return switch (data['action']) {
      'advance' => DialogueAdvanceCommand(snapshotRevision: revision),
      'choice'
          when data['choiceIndex'] is int &&
              (data['choiceIndex'] as int) >= 0 =>
        DialogueSelectChoiceCommand(
          snapshotRevision: revision,
          choiceIndex: data['choiceIndex'] as int,
        ),
      _ => throw const FormatException('Invalid dialogue command.'),
    };
  }

  static bool supportsWorldService(RuntimeWorldServiceSnapshot value) =>
      const {RuntimeWorldServiceKind.shop, RuntimeWorldServiceKind.heal,
        RuntimeWorldServiceKind.pc, RuntimeWorldServiceKind.partyTrade,
        RuntimeWorldServiceKind.pokemonGift}.contains(value.request.kind);

  static Map<String, Object?> encodeWorldService(RuntimeWorldServiceSnapshot value) =>
      _RuntimeWorldServiceCompanionCodec.encode(value);

  static RuntimeWorldServiceSnapshot decodeWorldService(Map<String, dynamic> data) =>
      _RuntimeWorldServiceCompanionCodec.decode(data);

  static Map<String, Object?> encodeWorldServiceCommand(RuntimeWorldServiceCommand command) => {
    'action': command.action.name, 'snapshotRevision': command.snapshotRevision,
    'targetId': command.targetId, 'secondaryTargetId': command.secondaryTargetId,
    'quantity': command.quantity, 'interactionResult': command.interactionResult?.toJson(),
  };

  static RuntimeWorldServiceCommand decodeWorldServiceCommand(Map<String, dynamic> data) {
    final revision = data['snapshotRevision'];
    final quantity = data['quantity'];
    if (revision is! int || revision < 0 || quantity != null && (quantity is! int || quantity <= 0)) {
      throw const FormatException('Invalid companion world-service command.');
    }
    return RuntimeWorldServiceCommand(
      action: RuntimeWorldServiceAction.values.byName(data['action'] as String),
      snapshotRevision: revision, targetId: data['targetId'] as String?,
      secondaryTargetId: data['secondaryTargetId'] as String?, quantity: quantity as int?,
      interactionResult: data['interactionResult'] == null ? null : SceneInteractionResult.fromJson(_map(data['interactionResult'])),
    );
  }

  static RuntimeWorldServiceCommandResult validateWorldServiceCommand({
    required RuntimeWorldServiceSnapshot snapshot,
    required RuntimeWorldServiceCommand command,
    required String interactionId,
  }) {
    if (snapshot.revision != command.snapshotRevision || snapshot.request.interactionId != interactionId) {
      return const RuntimeWorldServiceCommandResult(status: RuntimeWorldServiceCommandStatus.stale);
    }
    if (!snapshot.isActionEnabled(command.action)) {
      return RuntimeWorldServiceCommandResult(status: RuntimeWorldServiceCommandStatus.unavailable,
        safeMessage: snapshot.unavailableReasonFor(command.action));
    }
    return const RuntimeWorldServiceCommandResult(status: RuntimeWorldServiceCommandStatus.accepted);
  }

  static Map<String, Object?> encodePlayerCommand(
          RuntimePlayerCommand command) =>
      {
        'action': command.action.name,
        'snapshotRevision': command.snapshotRevision,
        'payload': switch (command.payload) {
          null => null,
          final PlayerPreferencesSnapshot value => {
              'kind': 'preferences',
              'value': encodePlayerPreferencesSnapshot(value)
            },
          final SceneInteractionResult value => {
              'kind': 'interaction',
              'value': value.toJson(),
            },
          final RuntimePlayerExitRequest value => {
              'kind': 'exit',
              'saveBeforeExit': value.saveBeforeExit
            },
          final RuntimePlayerPauseCommand value => {
              'kind': 'pause',
              'command': value.kind.name,
              'itemTargetId': value.itemTargetId,
              'partyTargetId': value.partyTargetId,
              'moveTargetId': value.moveTargetId,
              'secondPartyTargetId': value.secondPartyTargetId,
              if (value.contactId != null) 'contactId': value.contactId,
            },
          _ => throw const FormatException(
              'Unsupported companion command payload.'),
        },
      };

  static RuntimePlayerCommand decodePlayerCommand(Map<String, dynamic> data) {
    final raw = data['payload'];
    Object? payload;
    if (raw != null) {
      final value = _map(raw);
      payload = switch (value['kind']) {
        'preferences' => decodePlayerPreferencesSnapshot(_map(value['value'])),
        'interaction' => SceneInteractionResult.fromJson(_map(value['value'])),
        'exit' => RuntimePlayerExitRequest(
            saveBeforeExit: value['saveBeforeExit'] as bool),
        'pause' => switch (RuntimePlayerPauseCommandKind.values
              .byName(value['command'] as String)) {
            RuntimePlayerPauseCommandKind.callContact =>
              RuntimePlayerPauseCommand.callContact(contactId: value['contactId'] as String),
            RuntimePlayerPauseCommandKind.useBagItem =>
              RuntimePlayerPauseCommand.useBagItem(
                  itemTargetId: value['itemTargetId'] as String,
                  partyTargetId: value['partyTargetId'] as String? ?? '',
                  moveTargetId: value['moveTargetId'] as String?),
            RuntimePlayerPauseCommandKind.equipHeldItem =>
              RuntimePlayerPauseCommand.equipHeldItem(
                  itemTargetId: value['itemTargetId'] as String,
                  partyTargetId: value['partyTargetId'] as String),
            RuntimePlayerPauseCommandKind.unequipHeldItem =>
              RuntimePlayerPauseCommand.unequipHeldItem(
                  partyTargetId: value['partyTargetId'] as String),
            RuntimePlayerPauseCommandKind.reorderPartyMember =>
              RuntimePlayerPauseCommand.reorderPartyMember(
                  partyTargetId: value['partyTargetId'] as String,
                  secondPartyTargetId: value['secondPartyTargetId'] as String),
            RuntimePlayerPauseCommandKind.setPartyLead =>
              RuntimePlayerPauseCommand.setPartyLead(
                  partyTargetId: value['partyTargetId'] as String),
          },
        _ => throw const FormatException('Unsupported companion payload.'),
      };
    }
    return RuntimePlayerCommand(
        action: RuntimePlayerAction.values.byName(data['action'] as String),
        snapshotRevision: data['snapshotRevision'] as int,
        payload: payload);
  }

  static Map<String, Object?> encodeRuntimePokemonMediaIdentity(
          RuntimePokemonMediaIdentity value) =>
      {
        'speciesId': value.speciesId,
        'formId': value.formId,
        'defaultFormId':
            value.defaultFormId,
        'gender': value.gender,
        'isShiny': value.isShiny,
        'mediaRef': value.mediaRef,
      };
  static RuntimePokemonMediaIdentity decodeRuntimePokemonMediaIdentity(
          Map<String, dynamic> data) =>
      RuntimePokemonMediaIdentity(
        speciesId: data['speciesId'] as String,
        formId: data['formId'] == null ? null : data['formId'] as String,
        defaultFormId: data['defaultFormId'] == null
            ? null
            : data['defaultFormId'] as String,
        gender: data['gender'] == null ? null : data['gender'] as String,
        isShiny: data['isShiny'] as bool,
        mediaRef: data['mediaRef'] == null ? null : data['mediaRef'] as String,
      );

  static Map<String, Object?> encodeRuntimePokemonLocalImageSnapshot(
          RuntimePokemonLocalImageSnapshot value) =>
      {
        'absoluteFilePath': value.absoluteFilePath,
        'sampling': value.sampling.name,
      };
  static RuntimePokemonLocalImageSnapshot
      decodeRuntimePokemonLocalImageSnapshot(Map<String, dynamic> data) =>
          RuntimePokemonLocalImageSnapshot(
            absoluteFilePath: data['absoluteFilePath'] as String,
            sampling: ProjectMenuImageSampling.values
                .byName(data['sampling'] as String),
          );

  static Map<String, Object?> encodeRuntimePokemonSummaryMediaSnapshot(
          RuntimePokemonSummaryMediaSnapshot value) =>
      {
        'thumbnail': value.thumbnail == null
            ? null
            : encodeRuntimePokemonLocalImageSnapshot(value.thumbnail!),
        'illustration': value.illustration == null
            ? null
            : encodeRuntimePokemonLocalImageSnapshot(value.illustration!),
      };
  static RuntimePokemonSummaryMediaSnapshot
      decodeRuntimePokemonSummaryMediaSnapshot(Map<String, dynamic> data) =>
          RuntimePokemonSummaryMediaSnapshot(
            thumbnail: data['thumbnail'] == null
                ? null
                : decodeRuntimePokemonLocalImageSnapshot(
                    _map(data['thumbnail'])),
            illustration: data['illustration'] == null
                ? null
                : decodeRuntimePokemonLocalImageSnapshot(
                    _map(data['illustration'])),
          );

  static Map<String, Object?> encodeRuntimePokemonSummarySnapshot(
          RuntimePokemonSummarySnapshot value) =>
      {
        'targetId': value.targetId,
        'individualId': value.individualId,
        'speciesLabel': value.speciesLabel,
        'nickname': value.nickname,
        'formLabel': value.formLabel,
        'level': value.level,
        'experience': value.experience,
        'currentHp': value.currentHp,
        'maxHp': value.maxHp,
        'stats': value.stats == null
            ? null
            : encodeRuntimePokemonStatsSummarySnapshot(value.stats!),
        'natureLabel': value.natureLabel,
        'abilityLabel': value.abilityLabel,
        'genderLabel': value.genderLabel,
        'isShiny': value.isShiny,
        'heldItemLabel':
            value.heldItemLabel,
        'statusLabel': value.statusLabel,
        'friendship': value.friendship,
        'moves': value.moves
            .map((value) => encodeRuntimePokemonMoveSummarySnapshot(value))
            .toList(),
        'provenance': value.provenance == null
            ? null
            : encodeRuntimePokemonProvenanceSummarySnapshot(value.provenance!),
        'identity': value.identity == null
            ? null
            : encodeRuntimePokemonMediaIdentity(value.identity!),
        'media': encodeRuntimePokemonSummaryMediaSnapshot(value.media),
        'typeIds': value.typeIds.map((value) => value).toList(),
        'abilityId': value.abilityId,
        'heldItemId': value.heldItemId,
        'statusId': value.statusId,
      };
  static RuntimePokemonSummarySnapshot decodeRuntimePokemonSummarySnapshot(
          Map<String, dynamic> data) =>
      RuntimePokemonSummarySnapshot(
        targetId: data['targetId'] as String,
        individualId: data['individualId'] as String,
        speciesLabel: data['speciesLabel'] as String,
        nickname: data['nickname'] as String,
        formLabel:
            data['formLabel'] == null ? null : data['formLabel'] as String,
        level: data['level'] as int,
        experience:
            data['experience'] == null ? null : data['experience'] as int,
        currentHp: data['currentHp'] as int,
        maxHp: data['maxHp'] as int,
        stats: data['stats'] == null
            ? null
            : decodeRuntimePokemonStatsSummarySnapshot(_map(data['stats'])),
        natureLabel: data['natureLabel'] as String,
        abilityLabel: data['abilityLabel'] as String,
        genderLabel:
            data['genderLabel'] == null ? null : data['genderLabel'] as String,
        isShiny: data['isShiny'] as bool,
        heldItemLabel: data['heldItemLabel'] == null
            ? null
            : data['heldItemLabel'] as String,
        statusLabel:
            data['statusLabel'] == null ? null : data['statusLabel'] as String,
        friendship: data['friendship'] as int,
        moves: (data['moves'] as List)
            .map(
                (value) => decodeRuntimePokemonMoveSummarySnapshot(_map(value)))
            .toList(),
        provenance: data['provenance'] == null
            ? null
            : decodeRuntimePokemonProvenanceSummarySnapshot(
                _map(data['provenance'])),
        identity: data['identity'] == null
            ? null
            : decodeRuntimePokemonMediaIdentity(_map(data['identity'])),
        media: decodeRuntimePokemonSummaryMediaSnapshot(_map(data['media'])),
        typeIds:
            (data['typeIds'] as List).map((value) => value as String).toList(),
        abilityId:
            data['abilityId'] == null ? null : data['abilityId'] as String,
        heldItemId:
            data['heldItemId'] == null ? null : data['heldItemId'] as String,
        statusId: data['statusId'] == null ? null : data['statusId'] as String,
      );

  static Map<String, Object?> encodeRuntimePokemonStatsSummarySnapshot(
          RuntimePokemonStatsSummarySnapshot value) =>
      {
        'attack': value.attack,
        'defense': value.defense,
        'specialAttack': value.specialAttack,
        'specialDefense': value.specialDefense,
        'speed': value.speed,
      };
  static RuntimePokemonStatsSummarySnapshot
      decodeRuntimePokemonStatsSummarySnapshot(Map<String, dynamic> data) =>
          RuntimePokemonStatsSummarySnapshot(
            attack: data['attack'] as int,
            defense: data['defense'] as int,
            specialAttack: data['specialAttack'] as int,
            specialDefense: data['specialDefense'] as int,
            speed: data['speed'] as int,
          );

  static Map<String, Object?> encodeRuntimePokemonMoveSummarySnapshot(
          RuntimePokemonMoveSummarySnapshot value) =>
      {
        'moveId': value.moveId,
        'label': value.label,
        'typeLabel': value.typeLabel,
        'typeId': value.typeId,
        'currentPp': value.currentPp,
        'maxPp': value.maxPp,
      };
  static RuntimePokemonMoveSummarySnapshot
      decodeRuntimePokemonMoveSummarySnapshot(Map<String, dynamic> data) =>
          RuntimePokemonMoveSummarySnapshot(
            moveId: data['moveId'] as String,
            label: data['label'] as String,
            typeLabel:
                data['typeLabel'] == null ? null : data['typeLabel'] as String,
            typeId: data['typeId'] == null ? null : data['typeId'] as String,
            currentPp:
                data['currentPp'] == null ? null : data['currentPp'] as int,
            maxPp: data['maxPp'] == null ? null : data['maxPp'] as int,
          );

  static Map<String, Object?> encodeRuntimePokemonProvenanceSummarySnapshot(
          RuntimePokemonProvenanceSummarySnapshot value) =>
      {
        'originLabel': value.originLabel,
        'metMapLabel': value.metMapLabel,
        'metSourceLabel':
            value.metSourceLabel,
        'metLevel': value.metLevel,
        'ballLabel': value.ballLabel,
      };
  static RuntimePokemonProvenanceSummarySnapshot
      decodeRuntimePokemonProvenanceSummarySnapshot(
              Map<String, dynamic> data) =>
          RuntimePokemonProvenanceSummarySnapshot(
            originLabel: data['originLabel'] as String,
            metMapLabel: data['metMapLabel'] == null
                ? null
                : data['metMapLabel'] as String,
            metSourceLabel: data['metSourceLabel'] == null
                ? null
                : data['metSourceLabel'] as String,
            metLevel: data['metLevel'] == null ? null : data['metLevel'] as int,
            ballLabel:
                data['ballLabel'] == null ? null : data['ballLabel'] as String,
          );

  static Map<String, Object?> encodeRuntimePlayerRegionMapSnapshot(
          RuntimePlayerRegionMapSnapshot value) =>
      {
        'regions': value.regions
            .map((value) => encodeRuntimePlayerRegionSnapshot(value))
            .toList(),
      };
  static RuntimePlayerRegionMapSnapshot decodeRuntimePlayerRegionMapSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerRegionMapSnapshot(
        regions: (data['regions'] as List)
            .map((value) => decodeRuntimePlayerRegionSnapshot(_map(value)))
            .toList(),
      );

  static Map<String, Object?> encodeRuntimePlayerRegionSnapshot(
          RuntimePlayerRegionSnapshot value) =>
      {
        'id': value.id,
        'label': value.label,
        'imageFilePath':
            value.imageFilePath,
        'pixelArt': value.pixelArt,
        'points': value.points
            .map((value) => encodeRuntimePlayerMapPointSnapshot(value))
            .toList(),
      };
  static RuntimePlayerRegionSnapshot decodeRuntimePlayerRegionSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerRegionSnapshot(
        id: data['id'] as String,
        label: data['label'] as String,
        imageFilePath: data['imageFilePath'] == null
            ? null
            : data['imageFilePath'] as String,
        pixelArt: data['pixelArt'] as bool,
        points: (data['points'] as List)
            .map((value) => decodeRuntimePlayerMapPointSnapshot(_map(value)))
            .toList(),
      );

  static Map<String, Object?> encodeRuntimePlayerMapPointSnapshot(
          RuntimePlayerMapPointSnapshot value) =>
      {
        'id': value.id,
        'label': value.label,
        'status': value.status.name,
        'u': value.u,
        'v': value.v,
        'description': value.description,
        'destination': value.destination?.toJson(),
        'thumbnailFilePath':
            value.thumbnailFilePath,
      };
  static RuntimePlayerMapPointSnapshot decodeRuntimePlayerMapPointSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerMapPointSnapshot(
        id: data['id'] as String,
        label: data['label'] as String,
        status:
            RuntimePlayerMapPointStatus.values.byName(data['status'] as String),
        u: data['u'] == null ? null : (data['u'] as num).toDouble(),
        v: data['v'] == null ? null : (data['v'] as num).toDouble(),
        description:
            data['description'] == null ? null : data['description'] as String,
        destination: data['destination'] == null ? null : ProjectRegionDestination.fromJson(_map(data['destination'])),
        thumbnailFilePath: data['thumbnailFilePath'] == null
            ? null
            : data['thumbnailFilePath'] as String,
      );

  static Map<String, Object?> encodeRuntimePlayerPokedexProgressSnapshot(
          RuntimePlayerPokedexProgressSnapshot value) =>
      {
        'seen': value.seen,
        'caught': value.caught,
        'total': value.total,
      };
  static RuntimePlayerPokedexProgressSnapshot
      decodeRuntimePlayerPokedexProgressSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerPokedexProgressSnapshot(
            seen: data['seen'] as int,
            caught: data['caught'] as int,
            total: data['total'] as int,
          );

  static Map<String, Object?> encodeRuntimePlayerProfileSnapshot(
          RuntimePlayerProfileSnapshot value) =>
      {
        'playerName': value.playerName,
        'currentMapId': value.currentMapId,
        'money': value.money,
        'playtimeSeconds':
            value.playtimeSeconds,
        'locationName': value.locationName,
        'avatarCharacterId':
            value.avatarCharacterId,
        'portraitFilePath':
            value.portraitFilePath,
        'pronounSet': value.pronounSet.name,
        'portraits': value.portraits.map((value) => value.toJson()).toList(),
        'badgeIds': value.badgeIds.map((value) => value).toList(),
        'badges': value.badges
            .map((value) => encodeRuntimePlayerProfileBadgeSnapshot(value))
            .toList(),
        'badgeTotal': value.badgeTotal,
        'pokedex': value.pokedex == null
            ? null
            : encodeRuntimePlayerPokedexProgressSnapshot(value.pokedex!),
        'currencyLabel':
            value.currencyLabel,
      };
  static RuntimePlayerProfileSnapshot decodeRuntimePlayerProfileSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerProfileSnapshot(
        playerName: data['playerName'] as String,
        currentMapId: data['currentMapId'] as String,
        money: data['money'] as int,
        playtimeSeconds: data['playtimeSeconds'] == null
            ? null
            : data['playtimeSeconds'] as int,
        locationName: data['locationName'] == null
            ? null
            : data['locationName'] as String,
        avatarCharacterId: data['avatarCharacterId'] == null
            ? null
            : data['avatarCharacterId'] as String,
        portraitFilePath: data['portraitFilePath'] == null
            ? null
            : data['portraitFilePath'] as String,
        pronounSet:
            PlayerPronounSet.values.byName(data['pronounSet'] as String),
        portraits: (data['portraits'] as List)
            .map((value) => CharacterPortraitVariant.fromJson(_map(value)))
            .toList(),
        badgeIds:
            (data['badgeIds'] as List).map((value) => value as String).toList(),
        badges: (data['badges'] as List)
            .map(
                (value) => decodeRuntimePlayerProfileBadgeSnapshot(_map(value)))
            .toList(),
        badgeTotal:
            data['badgeTotal'] == null ? null : data['badgeTotal'] as int,
        pokedex: data['pokedex'] == null
            ? null
            : decodeRuntimePlayerPokedexProgressSnapshot(_map(data['pokedex'])),
        currencyLabel: data['currencyLabel'] == null
            ? null
            : data['currencyLabel'] as String,
      );

  static Map<String, Object?> encodeRuntimePlayerProfileBadgeSnapshot(
          RuntimePlayerProfileBadgeSnapshot value) =>
      {
        'id': value.id,
        'label': value.label,
        'iconFilePath': value.iconFilePath,
      };
  static RuntimePlayerProfileBadgeSnapshot
      decodeRuntimePlayerProfileBadgeSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerProfileBadgeSnapshot(
            id: data['id'] as String,
            label: data['label'] as String,
            iconFilePath: data['iconFilePath'] == null
                ? null
                : data['iconFilePath'] as String,
          );

  static Map<String, Object?> encodeRuntimePlayerBagItemSnapshot(
          RuntimePlayerBagItemSnapshot value) =>
      {
        'itemId': value.itemId,
        'quantity': value.quantity,
        'sortOrder': value.sortOrder,
        'pocketId': value.pocketId,
        'description': value.description,
        'iconFilePath': value.iconFilePath,
      };
  static RuntimePlayerBagItemSnapshot decodeRuntimePlayerBagItemSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerBagItemSnapshot(
        itemId: data['itemId'] as String,
        quantity: data['quantity'] as int,
        sortOrder: data['sortOrder'] as int,
        pocketId: data['pocketId'] == null ? null : data['pocketId'] as String,
        description:
            data['description'] == null ? null : data['description'] as String,
        iconFilePath: data['iconFilePath'] == null
            ? null
            : data['iconFilePath'] as String,
      );

  static Map<String, Object?> encodeRuntimePlayerBagPocketSnapshot(
          RuntimePlayerBagPocketSnapshot value) =>
      {
        'id': value.id,
        'label': value.label,
      };
  static RuntimePlayerBagPocketSnapshot decodeRuntimePlayerBagPocketSnapshot(
          Map<String, dynamic> data) =>
      RuntimePlayerBagPocketSnapshot(
        id: data['id'] as String,
        label: data['label'] as String,
      );

  static Map<String, Object?> encodeRuntimePlayerPokedexEntrySnapshot(
          RuntimePlayerPokedexEntrySnapshot value) =>
      {
        'knowledge': value.knowledge.name,
        'nationalDex': value.nationalDex,
        'identity': value.identity == null
            ? null
            : encodeRuntimePokemonMediaIdentity(value.identity!),
        'media': encodeRuntimePokemonSummaryMediaSnapshot(value.media),
        'description': value.description,
        'typeIds': value.typeIds.map((value) => value).toList(),
      };
  static RuntimePlayerPokedexEntrySnapshot
      decodeRuntimePlayerPokedexEntrySnapshot(Map<String, dynamic> data) =>
          RuntimePlayerPokedexEntrySnapshot(
            knowledge: RuntimePlayerPokedexKnowledge.values
                .byName(data['knowledge'] as String),
            nationalDex:
                data['nationalDex'] == null ? null : data['nationalDex'] as int,
            identity: data['identity'] == null
                ? null
                : decodeRuntimePokemonMediaIdentity(_map(data['identity'])),
            media:
                decodeRuntimePokemonSummaryMediaSnapshot(_map(data['media'])),
            description: data['description'] == null
                ? null
                : data['description'] as String,
            typeIds: (data['typeIds'] as List)
                .map((value) => value as String)
                .toList(),
          );

  static Map<String, Object?> encodeRuntimePlayerBagItemActionSnapshot(
          RuntimePlayerBagItemActionSnapshot value) =>
      {
        'itemTargetId': value.itemTargetId,
        'targetKind': value.targetKind.name,
        'usability': value.usability.name,
        'isEnabled': value.isEnabled,
        'requiresConfirmation': value.requiresConfirmation,
        'unavailableReason':
            value.unavailableReason,
        'eligiblePartyTargetIds': value.eligiblePartyTargetIds?.map((value) => value).toList(),
        'learnedMoveLabel':
            value.learnedMoveLabel,
        'unavailablePartyTargetReasons':
            Map<String, String>.from(value.unavailablePartyTargetReasons),
      };
  static RuntimePlayerBagItemActionSnapshot
      decodeRuntimePlayerBagItemActionSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerBagItemActionSnapshot(
            itemTargetId: data['itemTargetId'] as String,
            targetKind: RuntimePlayerBagUseTargetKind.values
                .byName(data['targetKind'] as String),
            usability:
                ItemUsabilityState.values.byName(data['usability'] as String),
            isEnabled: data['isEnabled'] as bool,
            requiresConfirmation: data['requiresConfirmation'] as bool,
            unavailableReason: data['unavailableReason'] == null
                ? null
                : data['unavailableReason'] as String,
            eligiblePartyTargetIds: data['eligiblePartyTargetIds'] == null
                ? null
                : (data['eligiblePartyTargetIds'] as List)
                    .map((value) => value as String)
                    .toSet(),
            learnedMoveLabel: data['learnedMoveLabel'] == null
                ? null
                : data['learnedMoveLabel'] as String,
            unavailablePartyTargetReasons: Map<String, String>.from(
                data['unavailablePartyTargetReasons'] as Map),
          );

  static Map<String, Object?> encodeRuntimePlayerBagMoveTargetSnapshot(
          RuntimePlayerBagMoveTargetSnapshot value) =>
      {
        'targetId': value.targetId,
        'label': value.label,
        'subtitle': value.subtitle,
      };
  static RuntimePlayerBagMoveTargetSnapshot
      decodeRuntimePlayerBagMoveTargetSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerBagMoveTargetSnapshot(
            targetId: data['targetId'] as String,
            label: data['label'] as String,
            subtitle:
                data['subtitle'] == null ? null : data['subtitle'] as String,
          );

  static Map<String, Object?> encodeRuntimePlayerBagPartyTargetSnapshot(
          RuntimePlayerBagPartyTargetSnapshot value) =>
      {
        'targetId': value.targetId,
        'label': value.label,
        'subtitle': value.subtitle,
        'moves': value.moves
            .map((value) => encodeRuntimePlayerBagMoveTargetSnapshot(value))
            .toList(),
        'pokemonSummary': value.pokemonSummary == null
            ? null
            : encodeRuntimePokemonSummarySnapshot(value.pokemonSummary!),
        'requiresMoveReplacement': value.requiresMoveReplacement,
      };
  static RuntimePlayerBagPartyTargetSnapshot
      decodeRuntimePlayerBagPartyTargetSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: data['targetId'] as String,
            label: data['label'] as String,
            subtitle:
                data['subtitle'] == null ? null : data['subtitle'] as String,
            moves: (data['moves'] as List)
                .map((value) =>
                    decodeRuntimePlayerBagMoveTargetSnapshot(_map(value)))
                .toList(),
            pokemonSummary: data['pokemonSummary'] == null
                ? null
                : decodeRuntimePokemonSummarySnapshot(
                    _map(data['pokemonSummary'])),
            requiresMoveReplacement: data['requiresMoveReplacement'] as bool,
          );

  static Map<String, Object?> encodeRuntimePlayerHeldItemOptionSnapshot(
          RuntimePlayerHeldItemOptionSnapshot value) =>
      {
        'itemTargetId': value.itemTargetId,
        'label': value.label,
      };
  static RuntimePlayerHeldItemOptionSnapshot
      decodeRuntimePlayerHeldItemOptionSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerHeldItemOptionSnapshot(
            itemTargetId: data['itemTargetId'] as String,
            label: data['label'] as String,
          );

  static Map<String, Object?> encodeRuntimePlayerHeldItemActionSnapshot(
          RuntimePlayerHeldItemActionSnapshot value) =>
      {
        'partyTargetId': value.partyTargetId,
        'currentItemLabel':
            value.currentItemLabel,
        'options': value.options
            .map((value) => encodeRuntimePlayerHeldItemOptionSnapshot(value))
            .toList(),
      };
  static RuntimePlayerHeldItemActionSnapshot
      decodeRuntimePlayerHeldItemActionSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerHeldItemActionSnapshot(
            partyTargetId: data['partyTargetId'] as String,
            currentItemLabel: data['currentItemLabel'] == null
                ? null
                : data['currentItemLabel'] as String,
            options: (data['options'] as List)
                .map((value) =>
                    decodeRuntimePlayerHeldItemOptionSnapshot(_map(value)))
                .toList(),
          );

  static Map<String, Object?> encodeRuntimePlayerDetailEntrySnapshot(
          RuntimePlayerDetailEntrySnapshot value) =>
      {
        'id': value.id,
        if (value.portraitFilePath != null) 'portraitFilePath': value.portraitFilePath,
        'title': value.title,
        'subtitle': value.subtitle,
        'trailingLabel':
            value.trailingLabel,
        'progress': value.progress,
        'bagAction': value.bagAction == null
            ? null
            : encodeRuntimePlayerBagItemActionSnapshot(value.bagAction!),
        'heldItemAction': value.heldItemAction == null
            ? null
            : encodeRuntimePlayerHeldItemActionSnapshot(value.heldItemAction!),
        'bagItem': value.bagItem == null
            ? null
            : encodeRuntimePlayerBagItemSnapshot(value.bagItem!),
        'pokedexEntry': value.pokedexEntry == null
            ? null
            : encodeRuntimePlayerPokedexEntrySnapshot(value.pokedexEntry!),
        'pokemonSummary': value.pokemonSummary == null
            ? null
            : encodeRuntimePokemonSummarySnapshot(value.pokemonSummary!),
      };
  static RuntimePlayerDetailEntrySnapshot
      decodeRuntimePlayerDetailEntrySnapshot(Map<String, dynamic> data) =>
          RuntimePlayerDetailEntrySnapshot(
            portraitFilePath: data['portraitFilePath'] as String?,
            id: data['id'] as String,
            title: data['title'] as String,
            subtitle:
                data['subtitle'] == null ? null : data['subtitle'] as String,
            trailingLabel: data['trailingLabel'] == null
                ? null
                : data['trailingLabel'] as String,
            progress: data['progress'] == null
                ? null
                : (data['progress'] as num).toDouble(),
            bagAction: data['bagAction'] == null
                ? null
                : decodeRuntimePlayerBagItemActionSnapshot(
                    _map(data['bagAction'])),
            heldItemAction: data['heldItemAction'] == null
                ? null
                : decodeRuntimePlayerHeldItemActionSnapshot(
                    _map(data['heldItemAction'])),
            bagItem: data['bagItem'] == null
                ? null
                : decodeRuntimePlayerBagItemSnapshot(_map(data['bagItem'])),
            pokedexEntry: data['pokedexEntry'] == null
                ? null
                : decodeRuntimePlayerPokedexEntrySnapshot(
                    _map(data['pokedexEntry'])),
            pokemonSummary: data['pokemonSummary'] == null
                ? null
                : decodeRuntimePokemonSummarySnapshot(
                    _map(data['pokemonSummary'])),
          );

  static Map<String, Object?> encodeRuntimePlayerPauseDetailSnapshot(
          RuntimePlayerPauseDetailSnapshot value) =>
      {
        'section': value.section.name,
        'title': value.title,
        'entries': value.entries
            .map((value) => encodeRuntimePlayerDetailEntrySnapshot(value))
            .toList(),
        'emptyMessage': value.emptyMessage,
        'message': value.message,
        'profile': value.profile == null
            ? null
            : encodeRuntimePlayerProfileSnapshot(value.profile!),
        'regionalMap': value.regionalMap == null
            ? null
            : encodeRuntimePlayerRegionMapSnapshot(value.regionalMap!),
        'bagTargets': value.bagTargets
            .map((value) => encodeRuntimePlayerBagPartyTargetSnapshot(value))
            .toList(),
        'bagPockets': value.bagPockets
            .map((value) => encodeRuntimePlayerBagPocketSnapshot(value))
            .toList(),
        'bagMoney': value.bagMoney,
        'bagCurrencyLabel':
            value.bagCurrencyLabel,
      };
  static RuntimePlayerPauseDetailSnapshot
      decodeRuntimePlayerPauseDetailSnapshot(Map<String, dynamic> data) =>
          RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.values
                .byName(data['section'] as String),
            title: data['title'] as String,
            entries: (data['entries'] as List)
                .map((value) =>
                    decodeRuntimePlayerDetailEntrySnapshot(_map(value)))
                .toList(),
            emptyMessage: data['emptyMessage'] == null
                ? null
                : data['emptyMessage'] as String,
            message: data['message'] == null ? null : data['message'] as String,
            profile: data['profile'] == null
                ? null
                : decodeRuntimePlayerProfileSnapshot(_map(data['profile'])),
            regionalMap: data['regionalMap'] == null
                ? null
                : decodeRuntimePlayerRegionMapSnapshot(
                    _map(data['regionalMap'])),
            bagTargets: (data['bagTargets'] as List)
                .map((value) =>
                    decodeRuntimePlayerBagPartyTargetSnapshot(_map(value)))
                .toList(),
            bagPockets: (data['bagPockets'] as List)
                .map((value) =>
                    decodeRuntimePlayerBagPocketSnapshot(_map(value)))
                .toList(),
            bagMoney: data['bagMoney'] == null ? null : data['bagMoney'] as int,
            bagCurrencyLabel: data['bagCurrencyLabel'] == null
                ? null
                : data['bagCurrencyLabel'] as String,
          );

  static Map<String, Object?> encodeBattleCommandOverlayEntry(
          BattleCommandOverlayEntry value) =>
      {
        'index': value.index,
        'kind': value.kind.name,
        'primaryLabel': value.primaryLabel,
        'secondaryLabel': value.secondaryLabel,
        'tertiaryLabel':
            value.tertiaryLabel,
        'trailingLabel':
            value.trailingLabel,
        'statusLabel': value.statusLabel,
        'enabled': value.enabled,
        'selected': value.selected,
        'tone': value.tone.name,
        'iconAssetPath':
            value.iconAssetPath,
      };
  static BattleCommandOverlayEntry decodeBattleCommandOverlayEntry(
          Map<String, dynamic> data) =>
      BattleCommandOverlayEntry(
        index: data['index'] as int,
        kind:
            BattleCommandOverlayEntryKind.values.byName(data['kind'] as String),
        primaryLabel: data['primaryLabel'] as String,
        secondaryLabel: data['secondaryLabel'] as String,
        tertiaryLabel: data['tertiaryLabel'] == null
            ? null
            : data['tertiaryLabel'] as String,
        trailingLabel: data['trailingLabel'] == null
            ? null
            : data['trailingLabel'] as String,
        statusLabel:
            data['statusLabel'] == null ? null : data['statusLabel'] as String,
        enabled: data['enabled'] as bool,
        selected: data['selected'] as bool,
        tone:
            BattleCommandOverlayEntryTone.values.byName(data['tone'] as String),
        iconAssetPath: data['iconAssetPath'] == null
            ? null
            : data['iconAssetPath'] as String,
      );

  static Map<String, Object?>? _encodeBattleSlot(BattleSlotRef? slot) => slot == null
      ? null : {'side': slot.side.name, 'slotIndex': slot.slotIndex};

  static BattleSlotRef? _decodeBattleSlot(Object? value) {
    if (value == null) return null;
    final data = _map(value);
    return BattleSlotRef(
      side: BattleSideId.values.byName(data['side'] as String),
      slotIndex: data['slotIndex'] as int,
    );
  }

  static Map<String, Object?> encodeBattleCommandOverlayHudSnapshot(
          BattleCommandOverlayHudSnapshot value) =>
      {
        'isRevealed': value.isRevealed,
        'slot': _encodeBattleSlot(value.slot),
        'combatantId': value.combatantId,
        'rect': [
          value.rect.left,
          value.rect.top,
          value.rect.right,
          value.rect.bottom
        ],
        'ownerLabel': value.ownerLabel,
        'speciesLabel': value.speciesLabel,
        'level': value.level,
        'currentHp': value.currentHp,
        'maxHp': value.maxHp,
        'isPlayerSide': value.isPlayerSide,
        'displayedHp': value.displayedHp,
        'targetDisplayedHp':
            value.targetDisplayedHp,
        'hpTweenDurationMs':
            value.hpTweenDurationMs,
        'hpTweenRevision': value.hpTweenRevision,
        'genderSymbol': value.genderSymbol,
        'statusLabel': value.statusLabel,
        'experienceProgress':
            value.experienceProgress,
        'experienceProgressTarget': value.experienceProgressTarget,
        'xpTweenDurationMs':
            value.xpTweenDurationMs,
        'xpTweenRevision': value.xpTweenRevision,
      };
  static BattleCommandOverlayHudSnapshot decodeBattleCommandOverlayHudSnapshot(
          Map<String, dynamic> data) =>
      BattleCommandOverlayHudSnapshot(
        isRevealed: data['isRevealed'] as bool,
        slot: _decodeBattleSlot(data['slot']),
        combatantId: data['combatantId'] as String,
        rect: Rect.fromLTRB(
            (data['rect'] as List)[0].toDouble(),
            (data['rect'] as List)[1].toDouble(),
            (data['rect'] as List)[2].toDouble(),
            (data['rect'] as List)[3].toDouble()),
        ownerLabel: data['ownerLabel'] as String,
        speciesLabel: data['speciesLabel'] as String,
        level: data['level'] as int,
        currentHp: data['currentHp'] as int,
        maxHp: data['maxHp'] as int,
        isPlayerSide: data['isPlayerSide'] as bool,
        displayedHp:
            data['displayedHp'] == null ? null : data['displayedHp'] as int,
        targetDisplayedHp: data['targetDisplayedHp'] == null
            ? null
            : data['targetDisplayedHp'] as int,
        hpTweenDurationMs: data['hpTweenDurationMs'] == null
            ? null
            : data['hpTweenDurationMs'] as int,
        hpTweenRevision: data['hpTweenRevision'] as int,
        genderSymbol: data['genderSymbol'] == null
            ? null
            : data['genderSymbol'] as String,
        statusLabel:
            data['statusLabel'] == null ? null : data['statusLabel'] as String,
        experienceProgress: data['experienceProgress'] == null
            ? null
            : (data['experienceProgress'] as num).toDouble(),
        experienceProgressTarget: data['experienceProgressTarget'] == null
            ? null
            : (data['experienceProgressTarget'] as num).toDouble(),
        xpTweenDurationMs: data['xpTweenDurationMs'] == null
            ? null
            : data['xpTweenDurationMs'] as int,
        xpTweenRevision: data['xpTweenRevision'] as int,
      );

  static Map<String, Object?> encodeBattleCommandOverlaySnapshot(
          BattleCommandOverlaySnapshot value) =>
      {
        'revision': value.revision,
        'phase': value.phase.name,
        'commandPanelPlacement': value.commandPanelPlacement.name,
        'controllerLayout': value.controllerLayout,
        'portraitTouchLayout': value.portraitTouchLayout,
        'rootCommandOrder': value.rootCommandOrder,
        'collectionColumns': value.collectionColumns,
        'forcedReplacement': value.forcedReplacement,
        'mode': value.mode.name,
        'viewportSize': [value.viewportSize.width, value.viewportSize.height],
        'panelRect': [
          value.panelRect.left,
          value.panelRect.top,
          value.panelRect.right,
          value.panelRect.bottom
        ],
        'additionalHuds': value.additionalHuds.map(encodeBattleCommandOverlayHudSnapshot).toList(),
        'actorSlot': _encodeBattleSlot(value.actorSlot),
        'actorCombatantId': value.actorCombatantId,
        'enemyHud': encodeBattleCommandOverlayHudSnapshot(value.enemyHud),
        'playerHud': encodeBattleCommandOverlayHudSnapshot(value.playerHud),
        'battleLabel': value.battleLabel,
        'title': value.title,
        'prompt': value.prompt,
        'narrationLines': value.narrationLines.map((value) => value).toList(),
        'entries': value.entries
            .map((value) => encodeBattleCommandOverlayEntry(value))
            .toList(),
        'interactionsEnabled': value.interactionsEnabled,
        'canGoBack': value.canGoBack,
      };
  static int? _decodeBattleCollectionColumns(Object? value) {
    if (value == null || value == 1 || value == 2) {
      if (value is int?) return value;
    }
    throw const FormatException('Invalid battle collection columns');
  }

  static List<int> _decodeBattleRootCommandOrder(Object? value) {
    if (value == null) return const [0, 1, 2, 3];
    if (value is! List || value.any((index) => index is! int)) {
      throw const FormatException('Invalid battle root command order');
    }
    final order = List<int>.unmodifiable(value.cast<int>());
    if (!BattleSetCommandPanelPlacementCommand.isValidRootCommandOrder(order)) {
      throw const FormatException('Invalid battle root command order');
    }
    return order;
  }

  static BattleCommandOverlaySnapshot decodeBattleCommandOverlaySnapshot(
          Map<String, dynamic> data) =>
      BattleCommandOverlaySnapshot(
        revision: data['revision'] as int,
        phase: BattlePresentationPhase.values.byName(data['phase'] as String),
        commandPanelPlacement: BattleCommandPanelPlacement.values.byName(data['commandPanelPlacement'] as String),
        controllerLayout: data['controllerLayout'] as bool,
        portraitTouchLayout: data['portraitTouchLayout'] as bool? ?? false,
        rootCommandOrder: _decodeBattleRootCommandOrder(data['rootCommandOrder']),
        collectionColumns: _decodeBattleCollectionColumns(data['collectionColumns']),
        forcedReplacement: data['forcedReplacement'] as bool,
        mode: BattleCommandOverlayMode.values.byName(data['mode'] as String),
        viewportSize: Size((data['viewportSize'] as List)[0].toDouble(),
            (data['viewportSize'] as List)[1].toDouble()),
        panelRect: Rect.fromLTRB(
            (data['panelRect'] as List)[0].toDouble(),
            (data['panelRect'] as List)[1].toDouble(),
            (data['panelRect'] as List)[2].toDouble(),
            (data['panelRect'] as List)[3].toDouble()),
        additionalHuds: (data['additionalHuds'] as List).map((value) => decodeBattleCommandOverlayHudSnapshot(_map(value))).toList(),
        actorSlot: _decodeBattleSlot(data['actorSlot']),
        actorCombatantId: data['actorCombatantId'] as String?,
        enemyHud: decodeBattleCommandOverlayHudSnapshot(_map(data['enemyHud'])),
        playerHud:
            decodeBattleCommandOverlayHudSnapshot(_map(data['playerHud'])),
        battleLabel: data['battleLabel'] as String,
        title: data['title'] as String,
        prompt: data['prompt'] as String,
        narrationLines: (data['narrationLines'] as List)
            .map((value) => value as String)
            .toList(),
        entries: (data['entries'] as List)
            .map((value) => decodeBattleCommandOverlayEntry(_map(value)))
            .toList(),
        interactionsEnabled: data['interactionsEnabled'] as bool,
        canGoBack: data['canGoBack'] as bool,
      );

  static Map<String, Object?> encodePlayerPreferencesSnapshot(
          PlayerPreferencesSnapshot value) =>
      {
        'locale': value.locale,
        'accessibility':
            encodeGameSessionAccessibilityOptions(value.accessibility),
        'touchControlsOpacity': value.touchControlsOpacity,
        'leftHandedTouchControls': value.leftHandedTouchControls,
        'touchRunMode': value.touchRunMode.name,
        'audioMix': encodeRuntimeAudioMix(value.audioMix),
        'highContrast': value.highContrast,
        'showInputHints': value.showInputHints,
        'dialogueTextSpeed': value.dialogueTextSpeed.name,
        'menuEffects': value.menuEffects.name,
      };
  static PlayerPreferencesSnapshot decodePlayerPreferencesSnapshot(
          Map<String, dynamic> data) =>
      PlayerPreferencesSnapshot(
        locale: data['locale'] as String,
        accessibility:
            decodeGameSessionAccessibilityOptions(_map(data['accessibility'])),
        touchControlsOpacity: (data['touchControlsOpacity'] as num).toDouble(),
        leftHandedTouchControls: data['leftHandedTouchControls'] as bool,
        touchRunMode: RuntimePlayerTouchRunMode.values
            .byName(data['touchRunMode'] as String),
        audioMix: decodeRuntimeAudioMix(_map(data['audioMix'])),
        highContrast: data['highContrast'] as bool,
        showInputHints: data['showInputHints'] as bool,
        dialogueTextSpeed: RuntimeDialogueTextSpeed.values
            .byName(data['dialogueTextSpeed'] as String),
        menuEffects: RuntimePlayerMenuEffects.values
            .byName(data['menuEffects'] as String),
      );

  static Map<String, Object?> encodeRuntimeAudioMix(RuntimeAudioMix value) => {
        'masterVolume': value.masterVolume,
        'musicVolume': value.musicVolume,
        'effectsVolume': value.effectsVolume,
      };
  static RuntimeAudioMix decodeRuntimeAudioMix(Map<String, dynamic> data) =>
      RuntimeAudioMix(
        masterVolume: (data['masterVolume'] as num).toDouble(),
        musicVolume: (data['musicVolume'] as num).toDouble(),
        effectsVolume: (data['effectsVolume'] as num).toDouble(),
      );

  static Map<String, Object?> encodeGameSessionAccessibilityOptions(
          GameSessionAccessibilityOptions value) =>
      {
        'reducedMotion': value.reducedMotion,
        'textScale': value.textScale,
        'hapticsEnabled': value.hapticsEnabled,
      };
  static GameSessionAccessibilityOptions decodeGameSessionAccessibilityOptions(
          Map<String, dynamic> data) =>
      GameSessionAccessibilityOptions(
        reducedMotion: data['reducedMotion'] as bool,
        textScale: (data['textScale'] as num).toDouble(),
        hapticsEnabled: data['hapticsEnabled'] as bool,
      );

  static Map<String, Object?> encodeRuntimePlayerSaveAddress(
          RuntimePlayerSaveAddress value) =>
      {
        'gameId': value.gameId,
        'profileId': value.profileId,
        'slotId': value.slotId,
      };
  static RuntimePlayerSaveAddress decodeRuntimePlayerSaveAddress(
          Map<String, dynamic> data) =>
      RuntimePlayerSaveAddress(
        gameId: data['gameId'] as String,
        profileId: data['profileId'] as String,
        slotId: data['slotId'] as String,
      );

  static Map<String, Object?> encodeRuntimePlayerSaveReceipt(
          RuntimePlayerSaveReceipt value) =>
      {
        'address': encodeRuntimePlayerSaveAddress(value.address),
        'trigger': value.trigger.name,
      };
  static RuntimePlayerSaveReceipt decodeRuntimePlayerSaveReceipt(
          Map<String, dynamic> data) =>
      RuntimePlayerSaveReceipt(
        address: decodeRuntimePlayerSaveAddress(_map(data['address'])),
        trigger: GameSessionCheckpointTrigger.values
            .byName(data['trigger'] as String),
      );
}
