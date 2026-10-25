import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('dialogue presentation crosses JSON and platform transport with authored media', () {
    final source = DialoguePresentationSnapshot(
      revision: 13,
      mode: DialoguePresentationMode.choices,
      nodeTitle: 'station',
      speaker: 'Guide',
      text: 'Bon',
      fullText: 'Bonjour',
      isCurrentLineFullyRevealed: false,
      isLastContent: false,
      isAdvanceAvailable: false,
      choices: const [
        DialoguePresentationChoice(index: 2, label: 'Partir', selected: true),
        DialoguePresentationChoice(
          index: 5,
          label: 'Attendre',
          selected: false,
          enabled: false,
        ),
      ],
      portrait: const ResolvedDialoguePortrait(
        characterId: 'guide',
        characterName: 'Guide',
        portraitStateId: 'calm',
        portraitStateName: 'Calme',
        assetId: 'portrait',
        absoluteFilePath: '/game/resources/portrait.png',
        fitMode: CharacterPortraitFitMode.contain,
      ),
      segments: [
        DialogueTextSegment('Bon'),
        DialogueIconSegment(assetId: 'ticket', widthPx: 16, heightPx: 20),
      ],
      iconPngBytes: {
        'ticket': Uint8List.fromList([0, 127, 255]),
      },
    );
    final encoded = RuntimeCompanionPresentationCodec.encodeDialogue(source);
    final decoded = RuntimeCompanionPresentationCodec.decodeDialogue(
      _crossTransport(encoded),
    );
    expect(RuntimeCompanionPresentationCodec.encodeDialogue(decoded), encoded);
    expect(decoded.iconImages, isEmpty);
    expect(decoded.portrait!.absoluteFilePath, '/game/resources/portrait.png');
    expect(decoded.choices.last.enabled, isFalse);
    expect(
      () => RuntimeCompanionPresentationCodec.decodeDialogue({
        ...encoded,
        'iconPngBytes': {
          'ticket': [256],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => RuntimeCompanionPresentationCodec.decodeDialogue({
        ...encoded,
        'choices': [
          for (var i = 0; i < 2; i++) (encoded['choices'] as List).first,
        ],
      }),
      throwsFormatException,
    );
  });

  test(
    'dialogue commands retain exact revisions and reject malformed targets',
    () {
      for (final command in [
        const DialogueAdvanceCommand(snapshotRevision: 9),
        const DialogueSelectChoiceCommand(snapshotRevision: 10, choiceIndex: 3),
      ]) {
        final encoded = RuntimeCompanionPresentationCodec.encodeDialogueCommand(
          command,
        );
        final decoded = RuntimeCompanionPresentationCodec.decodeDialogueCommand(
          _crossTransport(encoded),
        );
        expect(
          RuntimeCompanionPresentationCodec.encodeDialogueCommand(decoded),
          encoded,
        );
      }
      for (final payload in [
        {'action': 'advance', 'snapshotRevision': -1},
        {'action': 'choice', 'snapshotRevision': 9, 'choiceIndex': -1},
        {'action': 'unknown', 'snapshotRevision': 9},
      ]) {
        expect(
          () =>
              RuntimeCompanionPresentationCodec.decodeDialogueCommand(payload),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'pre-session request and typed result preserve both canonical revisions',
    () {
      final request = SceneInteractionRequest.confirmation(
        requestId: 'travel',
        revision: 3,
        prompt: SceneInteractionPrompt(
          localizationKey: 'travel.confirm',
          fallbackText: 'Partir ?',
        ),
      );
      final source = RuntimePlayerSnapshot(
        revision: 22,
        phase: RuntimePlayerPhase.preSession,
        gameTitle: 'Avelune',
        preSessionRequest: request,
        actions: const [
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
        ],
      );
      final encoded = RuntimeCompanionPresentationCodec.encodePlayer(source);
      final decoded = RuntimeCompanionPresentationCodec.decodePlayer(
        _crossTransport(encoded),
      );
      expect(decoded.preSessionRequest!.toJson(), request.toJson());
      final result = SceneInteractionResult.confirmed(
        requestId: 'travel',
        revision: 3,
        value: true,
      );
      final command = RuntimePlayerCommand(
        action: RuntimePlayerAction.resolvePreSessionInteraction,
        snapshotRevision: 22,
        payload: result,
      );
      final transported = RuntimeCompanionPresentationCodec.decodePlayerCommand(
        _crossTransport(
          RuntimeCompanionPresentationCodec.encodePlayerCommand(command),
        ),
      );
      expect(transported.snapshotRevision, 22);
      expect(transported.payload, result);
      final legacy = {...encoded}..remove('preSessionRequest');
      expect(
        RuntimeCompanionPresentationCodec.decodePlayer(_crossTransport(legacy))
            .preSessionRequest,
        isNull,
      );
    },
  );

  test('world-service transport rejects mismatched typed content', () {
    final services = _worldServices().toList();
    final pc = RuntimeCompanionPresentationCodec.encodeWorldService(services[2]);
    final shop = RuntimeCompanionPresentationCodec.encodeWorldService(services[0]);
    expect(() => RuntimeCompanionPresentationCodec.decodeWorldService(_crossTransport({
      ...pc, 'content': shop['content'],
    })), throwsFormatException);
  });
  test('world-service commands reject stale revisions identities and disabled actions', () {
    final service = RuntimeWorldServiceSnapshot(
      revision: 9, request: const OpenPcService(interactionId: 'terminal'),
      stage: RuntimeWorldServiceStage.active,
      actions: const [RuntimeWorldServiceActionAvailability.enabled(RuntimeWorldServiceAction.withdraw)],
    );
    for (final (revision, interaction, action, status) in [
      (8, 'terminal', RuntimeWorldServiceAction.withdraw, RuntimeWorldServiceCommandStatus.stale),
      (9, 'other', RuntimeWorldServiceAction.withdraw, RuntimeWorldServiceCommandStatus.stale),
      (9, 'terminal', RuntimeWorldServiceAction.deposit, RuntimeWorldServiceCommandStatus.unavailable),
      (9, 'terminal', RuntimeWorldServiceAction.withdraw, RuntimeWorldServiceCommandStatus.accepted),
    ]) {
      final command = RuntimeWorldServiceCommand(action: action, snapshotRevision: revision, targetId: 'opaque');
      final decoded = RuntimeCompanionPresentationCodec.decodeWorldServiceCommand(_crossTransport(
        RuntimeCompanionPresentationCodec.encodeWorldServiceCommand(command)));
      expect(decoded.targetId, 'opaque');
      expect(RuntimeCompanionPresentationCodec.validateWorldServiceCommand(
        snapshot: service, command: decoded, interactionId: interaction).status, status);
    }
    for (final invalid in [-1, 0]) {
      expect(() => RuntimeCompanionPresentationCodec.decodeWorldServiceCommand({
        'action': 'confirm', 'snapshotRevision': 9, 'quantity': invalid,
      }), throwsFormatException);
    }
  });

  test('world-service nickname keeps its typed request identity across transport', () {
    final result = SceneInteractionResult.textSubmitted(requestId: 'gift:nickname', revision: 3, value: 'Pendule');
    final command = RuntimeCompanionPresentationCodec.decodeWorldServiceCommand(_crossTransport(
      RuntimeCompanionPresentationCodec.encodeWorldServiceCommand(RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm, snapshotRevision: 12, interactionResult: result))));
    expect(command.interactionResult, result);
  });

  for (final service in _worldServices()) {
    test('native ${service.request.kind.name} world service crosses companion transport losslessly', () {
      final encoded = RuntimeCompanionPresentationCodec.encodeWorldService(service);
      final decoded = RuntimeCompanionPresentationCodec.decodeWorldService(_crossTransport(encoded));
      expect(RuntimeCompanionPresentationCodec.encodeWorldService(decoded), encoded);
      expect(decoded.runtimeType, RuntimeWorldServiceSnapshot);
      expect(decoded.request.runtimeType, service.request.runtimeType);
      expect(decoded.content.runtimeType, service.content.runtimeType);
    });
  }
  test('companion player carries its typed world service and canonical revision', () {
    final snapshot = RuntimePlayerSnapshot(
      revision: 31, phase: RuntimePlayerPhase.playing, gameTitle: 'Companion',
      actions: const [], worldService: RuntimeWorldServiceSnapshot(
        revision: 9, request: const OpenShopService(interactionId: 'mart', shopId: 'mart'),
        stage: RuntimeWorldServiceStage.active,
        content: RuntimeShopServiceContent(title: 'Mart', message: '', money: 500,
          entries: const [RuntimeShopEntrySnapshot(itemId: 'potion', label: 'Potion', unitPrice: 60)],
          selectedItemId: 'potion', quantity: 2, totalPrice: 120),
        actions: const [RuntimeWorldServiceActionAvailability.enabled(RuntimeWorldServiceAction.confirm)],
      ),
    );
    final encoded = RuntimeCompanionPresentationCodec.encodePlayer(snapshot);
    expect(encoded['worldService'], isNotNull);
    final decoded = RuntimeCompanionPresentationCodec.decodePlayer(_crossTransport(encoded));
    expect(decoded.worldService!.revision, 9);
    expect((decoded.worldService!.content as RuntimeShopServiceContent).totalPrice, 120);
    expect(decoded.worldService!.isActionEnabled(RuntimeWorldServiceAction.confirm), isTrue);
  });
  test('doubles companion transport retains four slots and the current actor', () {
    BattleCommandOverlayHudSnapshot hud(BattleSideId side, int index) =>
        BattleCommandOverlayHudSnapshot(
          rect: Rect.fromLTWH(index * 100, 0, 90, 60),
          ownerLabel: side.name, speciesLabel: '${side.name}$index',
          combatantId: '${side.name}-$index',
          slot: BattleSlotRef(side: side, slotIndex: index),
          level: 20, currentHp: 30, maxHp: 40,
          isPlayerSide: side == BattleSideId.player,
        );
    final source = BattleCommandOverlaySnapshot(
      revision: 31, mode: BattleCommandOverlayMode.moveTarget,
      viewportSize: const Size(390, 844),
      panelRect: const Rect.fromLTWH(0, 600, 390, 244),
      enemyHud: hud(BattleSideId.enemy, 0), playerHud: hud(BattleSideId.player, 0),
      additionalHuds: [hud(BattleSideId.player, 1), hud(BattleSideId.enemy, 1)],
      actorSlot: const BattleSlotRef(side: BattleSideId.player, slotIndex: 1),
      actorCombatantId: 'player-1', battleLabel: 'Doubles', title: 'Cible',
      prompt: 'Choisis une cible.', narrationLines: const [], entries: const [],
      interactionsEnabled: true, canGoBack: true,
    );
    final payload = jsonDecode(jsonEncode(
      RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(source),
    )) as Map<String, dynamic>;
    final decoded = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(payload);
    expect(decoded, source);
    expect(decoded.combatantHuds.map((hud) => hud.effectiveSlot).toSet(), hasLength(4));
    expect(decoded.actorSlot, const BattleSlotRef(side: BattleSideId.player, slotIndex: 1));
    expect(decoded.actorCombatantId, 'player-1');
  });

  test('world bag command crosses transport without a Pokemon target', () {
    final command = RuntimeCompanionPresentationCodec.decodePlayerCommand({
      'action': RuntimePlayerAction.useBagItem.name,
      'snapshotRevision': 1,
      'payload': {
        'kind': 'pause',
        'command': 'useBagItem',
        'itemTargetId': 'repel',
      },
    });
    final pause = command.payload! as RuntimePlayerPauseCommand;
    expect(pause.itemTargetId, 'repel');
    expect(pause.partyTargetId, isEmpty);
  });

  test('companion menu retains canonical actions and nested party data', () {
    final party = RuntimePokemonSummarySnapshot(
      targetId: 'pokemon.one',
      individualId: 'one',
      speciesLabel: 'Roucool',
      nickname: 'Pico',
      level: 7,
      currentHp: 12,
      maxHp: 24,
      natureLabel: 'Calme',
      abilityLabel: 'Regard Vif',
      friendship: 90,
      moves: const [
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'tackle',
          label: 'Charge',
          currentPp: 20,
          maxPp: 35,
        )
      ],
    );
    final snapshot = RuntimePlayerSnapshot(
      revision: 21,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Train',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume)
      ],
      pauseDetails: {
        RuntimePlayerPauseSection.party: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.party,
          title: 'Équipe',
          entries: [
            RuntimePlayerDetailEntrySnapshot(
                id: 'pokemon.one', title: 'Pico', pokemonSummary: party)
          ],
        )
      },
    );
    final decoded = RuntimeCompanionPresentationCodec.decodePlayer(
      _crossTransport(RuntimeCompanionPresentationCodec.encodePlayer(snapshot)),
    );
    expect(decoded.revision, 21);
    expect(decoded.isActionEnabled(RuntimePlayerAction.resume), isTrue);
    final pokemon = decoded.pauseDetails[RuntimePlayerPauseSection.party]!
        .entries.single.pokemonSummary!;
    expect(pokemon.individualId, 'one');
    expect(pokemon.moves.single.currentPp, 20);
    expect(pokemon.maxHp, 24);
  });

  test('bag transport preserves eligibility, move replacement and favorites',
      () {
    final snapshot = _menu(RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      bagMoney: 1500,
      bagCurrencyLabel: '₽',
      bagPockets: const [
        RuntimePlayerBagPocketSnapshot(id: 'machines', label: 'CT et CS'),
      ],
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag:tm-thunder',
          title: 'CT Tonnerre',
          bagItem: const RuntimePlayerBagItemSnapshot(
            itemId: 'tm-thunder',
            quantity: 2,
            sortOrder: 3,
            pocketId: 'machines',
            description: 'Enseigne Tonnerre.',
            iconFilePath: '/project/assets/tm.png',
          ),
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'bag:tm-thunder',
            requiresConfirmation: true,
            targetKind: RuntimePlayerBagUseTargetKind.partyMoveReplacement,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
            learnedMoveLabel: 'Tonnerre',
            eligiblePartyTargetIds: {'party:one'},
            unavailablePartyTargetReasons: {
              'party:two': 'Ne peut pas apprendre'
            },
          ),
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag:rope',
          title: 'Corde Sortie',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'bag:rope',
            targetKind: RuntimePlayerBagUseTargetKind.partyMember,
            usability: ItemUsabilityState.unavailableInContext,
            isEnabled: false,
            unavailableReason: 'Utilisable dans une grotte.',
          ),
        ),
      ],
      bagTargets: [
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party:one',
          label: 'Pico',
          pokemonSummary: _pokemon(),
          requiresMoveReplacement: true,
          moves: const [
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
              subtitle: 'PP 20/35',
            ),
          ],
        ),
      ],
    ));

    final decoded = _roundTripMenu(snapshot);
    final bag = decoded.pauseDetailFor(RuntimePlayerPauseSection.bag)!;
    final action = bag.entries.first.bagAction!;

    expect(decoded.favoriteItemIds, {'tm-thunder'});
    expect(decoded.bagFavoritesAvailable, isTrue);
    expect(bag.bagPockets.single.id, 'machines');
    expect(bag.bagMoney, 1500);
    expect(bag.entries.first.bagItem!.iconFilePath, '/project/assets/tm.png');
    expect(action.allowsPartyTarget('party:one'), isTrue);
    expect(action.allowsPartyTarget('party:two'), isFalse);
    expect(action.allowsPartyTarget('party:three'), isFalse);
    expect(action.unavailablePartyTargetReasons['party:two'],
        'Ne peut pas apprendre');
    expect(
        action.targetKind, RuntimePlayerBagUseTargetKind.partyMoveReplacement);
    expect(action.learnedMoveLabel, 'Tonnerre');
    expect(action.requiresConfirmation, isTrue);
    expect(bag.entries.last.bagAction!.requiresConfirmation, isFalse);
    expect(bag.bagTargets.single.requiresMoveReplacement, isTrue);
    expect(bag.bagTargets.single.moves.single.targetId, 'tackle');
    expect(bag.bagTargets.single.pokemonSummary!.individualId, 'one');
    expect(bag.entries.last.bagAction!.isEnabled, isFalse);
    expect(bag.entries.last.bagAction!.unavailableReason,
        'Utilisable dans une grotte.');
  });

  test('party transport retains held item choices and summary media', () {
    final decoded = _roundTripMenu(_menu(RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.party,
      title: 'Équipe',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'party:one',
          title: 'Pico',
          pokemonSummary: _pokemon(),
          heldItemAction: RuntimePlayerHeldItemActionSnapshot(
            partyTargetId: 'party:one',
            currentItemLabel: 'Baie Oran',
            options: const [
              RuntimePlayerHeldItemOptionSnapshot(
                itemTargetId: 'bag:berry-sitrus',
                label: 'Baie Sitrus',
              ),
            ],
          ),
        ),
      ],
    )));
    final entry =
        decoded.pauseDetailFor(RuntimePlayerPauseSection.party)!.entries.single;

    expect(entry.heldItemAction!.hasCurrentItem, isTrue);
    expect(entry.heldItemAction!.partyTargetId, 'party:one');
    expect(
        entry.heldItemAction!.options.single.itemTargetId, 'bag:berry-sitrus');
    expect(entry.pokemonSummary!.heldItemId, 'berry-oran');
    expect(entry.pokemonSummary!.identity!.isShiny, isTrue);
    expect(entry.pokemonSummary!.moves.single.currentPp, 20);
    expect(entry.pokemonSummary!.media.thumbnail!.sampling,
        ProjectMenuImageSampling.pixelArt);
    expect(entry.pokemonSummary!.media.illustration!.absoluteFilePath,
        '/project/assets/pico-art.png');
  });

  test(
      'pokedex transport retains known media without revealing unknown species',
      () {
    final decoded = _roundTripMenu(_menu(RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.pokedex,
      title: 'Pokédex',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'dex:unknown',
          title: '???',
          pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            knowledge: RuntimePlayerPokedexKnowledge.unknown,
            nationalDex: 1,
          ),
        ),
        RuntimePlayerDetailEntrySnapshot(
          id: 'dex:caught',
          title: 'Roucool',
          pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            knowledge: RuntimePlayerPokedexKnowledge.caught,
            nationalDex: 16,
            identity: _pokemon().identity,
            media: _pokemon().media,
            description: 'Un Pokémon oiseau.',
            typeIds: ['normal', 'flying'],
          ),
        ),
      ],
    )));
    final entries =
        decoded.pauseDetailFor(RuntimePlayerPauseSection.pokedex)!.entries;
    final unknown = entries.first.pokedexEntry!;
    final caught = entries.last.pokedexEntry!;

    expect(unknown.knowledge, RuntimePlayerPokedexKnowledge.unknown);
    expect(unknown.identity, isNull);
    expect(unknown.media.thumbnail, isNull);
    expect(unknown.media.illustration, isNull);
    expect(unknown.description, isNull);
    expect(unknown.typeIds, isEmpty);
    expect(caught.knowledge, RuntimePlayerPokedexKnowledge.caught);
    expect(caught.identity!.speciesId, 'pidgey');
    expect(caught.media.thumbnail!.absoluteFilePath,
        '/project/assets/pico-thumb.png');
    expect(caught.typeIds, ['normal', 'flying']);
    expect(caught.description, 'Un Pokémon oiseau.');

    final malformed = RuntimeCompanionPresentationCodec
        .encodeRuntimePlayerPokedexEntrySnapshot(caught);
    malformed['knowledge'] = 'unknown';
    expect(
      () => RuntimeCompanionPresentationCodec
          .decodeRuntimePlayerPokedexEntrySnapshot(_crossTransport(malformed)),
      throwsArgumentError,
    );
  });

  test('profile portraits, badges and regional map positions cross transport',
      () {
    final profile = RuntimePlayerProfileSnapshot(
      playerName: 'Yoahn',
      currentMapId: 'station',
      money: 1500,
      avatarCharacterId: 'hero',
      portraitFilePath: '/project/assets/hero.png',
      portraits: const [
        CharacterPortraitVariant(
          portraitStateId: 'happy',
          assetId: 'portrait-happy',
          fitMode: CharacterPortraitFitMode.cover,
        ),
      ],
      badges: const [
        RuntimePlayerProfileBadgeSnapshot(
          id: 'badge-one',
          label: 'Badge Roche',
          iconFilePath: '/project/assets/badge.png',
        ),
      ],
      badgeIds: ['badge-one'],
      badgeTotal: 8,
      pokedex: const RuntimePlayerPokedexProgressSnapshot(
        seen: 12,
        caught: 7,
        total: 151,
      ),
    );
    final snapshot = RuntimePlayerSnapshot(
      revision: 22,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Train',
      pauseSection: RuntimePlayerPauseSection.profile,
      pauseDetails: {
        RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.profile,
          title: 'Profil',
          profile: profile,
        ),
        RuntimePlayerPauseSection.map: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.map,
          title: 'Carte',
          regionalMap: RuntimePlayerRegionMapSnapshot(regions: [
            RuntimePlayerRegionSnapshot(
              id: 'region-one',
              label: 'Kanto',
              imageFilePath: '/project/assets/map.png',
              pixelArt: true,
              points: const [
                RuntimePlayerMapPointSnapshot(
                  id: 'station',
                  label: 'Gare',
                  status: RuntimePlayerMapPointStatus.current,
                  u: .25,
                  v: .75,
                ),
                RuntimePlayerMapPointSnapshot(
                  id: 'hidden',
                  label: '???',
                  status: RuntimePlayerMapPointStatus.unknown,
                ),
              ],
            ),
          ]),
        ),
      },
    );

    final decoded = _roundTripMenu(snapshot);

    expect(decoded.playerProfile!.portraitFilePath, '/project/assets/hero.png');
    expect(decoded.playerProfile!.portraits.single.portraitStateId, 'happy');
    expect(decoded.playerProfile!.portraits.single.fitMode,
        CharacterPortraitFitMode.cover);
    expect(decoded.playerProfile!.badges.single.iconFilePath,
        '/project/assets/badge.png');
    expect(decoded.playerProfile!.badgeIds, ['badge-one']);
    expect(decoded.playerProfile!.pokedex!.caught, 7);
    final region = decoded
        .pauseDetailFor(RuntimePlayerPauseSection.map)!
        .regionalMap!
        .regions
        .single;
    expect(region.pixelArt, isTrue);
    expect(region.points.first.isLocated, isTrue);
    expect(region.points.first.u, .25);
    expect(region.points.first.v, .75);
    expect(region.points.last.isLocated, isFalse);
    expect(region.points.last.status, RuntimePlayerMapPointStatus.unknown);
  });

  test('preferences survive both menu projection and update command payload',
      () {
    const preferences = PlayerPreferencesSnapshot(
      locale: 'en-GB',
      accessibility: GameSessionAccessibilityOptions(
        reducedMotion: true,
        textScale: 1.4,
        hapticsEnabled: false,
      ),
      touchControlsOpacity: .45,
      leftHandedTouchControls: true,
      touchRunMode: RuntimePlayerTouchRunMode.automatic,
      audioMix: RuntimeAudioMix(
        masterVolume: .8,
        musicVolume: .3,
        effectsVolume: .6,
      ),
      highContrast: true,
      showInputHints: false,
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
      menuEffects: RuntimePlayerMenuEffects.opaque,
    );
    final snapshot = RuntimePlayerSnapshot(
      revision: 27,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Train',
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: preferences,
    );
    final projected = _roundTripMenu(snapshot).preferences!;
    final command = RuntimeCompanionPresentationCodec.decodePlayerCommand(
      _crossTransport(RuntimeCompanionPresentationCodec.encodePlayerCommand(
        const RuntimePlayerCommand(
          action: RuntimePlayerAction.updatePreferences,
          snapshotRevision: 27,
          payload: preferences,
        ),
      )),
    );

    expect(command.action, RuntimePlayerAction.updatePreferences);
    expect(command.snapshotRevision, 27);
    for (final value in [
      projected,
      command.payload as PlayerPreferencesSnapshot
    ]) {
      expect(value.locale, 'en-GB');
      expect(value.accessibility.reducedMotion, isTrue);
      expect(value.accessibility.textScale, 1.4);
      expect(value.accessibility.hapticsEnabled, isFalse);
      expect(value.touchControlsOpacity, .45);
      expect(value.touchRunMode, RuntimePlayerTouchRunMode.automatic);
      expect(value.audioMix.musicVolume, .3);
      expect(value.highContrast, isTrue);
      expect(value.showInputHints, isFalse);
      expect(value.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
      expect(value.menuEffects, RuntimePlayerMenuEffects.opaque);
    }
  });

  test('pause mutation payloads retain their opaque targets and command kinds',
      () {
    for (final payload in const [
      RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'bag:tm-thunder',
        partyTargetId: 'party:one',
        moveTargetId: 'tackle',
      ),
      RuntimePlayerPauseCommand.equipHeldItem(
        itemTargetId: 'bag:berry-sitrus',
        partyTargetId: 'party:one',
      ),
      RuntimePlayerPauseCommand.unequipHeldItem(partyTargetId: 'party:one'),
      RuntimePlayerPauseCommand.reorderPartyMember(
        partyTargetId: 'party:one',
        secondPartyTargetId: 'party:two',
      ),
      RuntimePlayerPauseCommand.setPartyLead(partyTargetId: 'party:two'),
    ]) {
      final command = RuntimeCompanionPresentationCodec.decodePlayerCommand(
        _crossTransport(RuntimeCompanionPresentationCodec.encodePlayerCommand(
          RuntimePlayerCommand(
            action: payload.kind ==
                        RuntimePlayerPauseCommandKind.reorderPartyMember ||
                    payload.kind == RuntimePlayerPauseCommandKind.setPartyLead
                ? RuntimePlayerAction.reorderParty
                : RuntimePlayerAction.useBagItem,
            snapshotRevision: 29,
            payload: payload,
          ),
        )),
      );
      final decoded = command.payload as RuntimePlayerPauseCommand;
      expect(command.snapshotRevision, 29);
      expect(decoded.kind, payload.kind);
      expect(decoded.itemTargetId, payload.itemTargetId);
      expect(decoded.partyTargetId, payload.partyTargetId);
      expect(decoded.moveTargetId, payload.moveTargetId);
      expect(decoded.secondPartyTargetId, payload.secondPartyTargetId);
    }
    for (final save in [false, true]) {
      final decoded = RuntimeCompanionPresentationCodec.decodePlayerCommand(
        _crossTransport(RuntimeCompanionPresentationCodec.encodePlayerCommand(
          RuntimePlayerCommand(
            action: RuntimePlayerAction.returnToTitle,
            snapshotRevision: 30,
            payload: RuntimePlayerExitRequest(saveBeforeExit: save),
          ),
        )),
      );
      expect(decoded.action, RuntimePlayerAction.returnToTitle);
      expect(
          (decoded.payload as RuntimePlayerExitRequest).saveBeforeExit, save);
    }
  });

  test('battle root order survives value equality JSON and platform codecs with guarded legacy fallback', () {
    final encoded = RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(_battle(BattlePresentationPhase.choosingCommand));
    for (final order in [[0, 2, 1, 3], [3, 2, 1, 0], [2]]) {
      final payload = {...encoded, 'rootCommandOrder': order};
      final decoded = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(payload));
      final duplicate = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(payload));
      expect(decoded.rootCommandOrder, order);
      expect(decoded, isNot(_battle(BattlePresentationPhase.choosingCommand)));
      expect(decoded, duplicate);
      expect(decoded.hashCode, duplicate.hashCode);
      expect(RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(decoded)['rootCommandOrder'], order);
    }
    final legacy = {...encoded}..remove('rootCommandOrder');
    expect(RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(legacy)).rootCommandOrder, [0, 1, 2, 3]);
    for (final order in [[], [0, 0], [-1], [4], [0, 1, 2, 3, 0], ['0'], '0,2,1,3']) {
      expect(() => RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport({...encoded, 'rootCommandOrder': order})), throwsFormatException);
    }
  });
  test('collection columns cross companion codecs and missing legacy values remain null', () {
    final encoded = RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(_battle(BattlePresentationPhase.choosingCommand));
    for (final columns in <int?>[null, 1, 2]) {
      final decoded = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport({...encoded, 'collectionColumns': columns}));
      expect(decoded.collectionColumns, columns);
      expect(RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(decoded)['collectionColumns'], columns);
    }
    final legacy = {...encoded}..remove('collectionColumns');
    expect(RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(legacy)).collectionColumns, isNull);
    for (final invalid in [0, 3, 1.0, '2', []]) {
      expect(() => RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport({...encoded, 'collectionColumns': invalid})), throwsFormatException);
    }
  });
  test('portrait touch layout crosses companion transport with a legacy false fallback', () {
    final source = _battle(BattlePresentationPhase.choosingCommand);
    final encoded = RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(source);
    for (final touch in [false, true]) {
      final payload = {...encoded, 'portraitTouchLayout': touch};
      final decoded = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(payload));
      final duplicate = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(payload));
      expect(decoded.portraitTouchLayout, touch);
      expect(decoded == source, !touch);
      expect(decoded, duplicate);
      expect(decoded.hashCode, duplicate.hashCode);
      expect(RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(decoded)['portraitTouchLayout'], touch);
    }
    final legacy = {...encoded}..remove('portraitTouchLayout');
    expect(RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(legacy)).portraitTouchLayout, isFalse);
  });

  test('battle placements cross companion transport without losing ownership geometry', () {
    for (final placement in BattleCommandPanelPlacement.values) {
      final source = _battle(BattlePresentationPhase.choosingCommand, placement: placement);
      final decoded = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(_crossTransport(RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(source)));
      expect(decoded, source);
      expect(decoded.commandPanelPlacement, placement);
    }
  });
  for (final phase in BattlePresentationPhase.values) {
    test('battle $phase transport retains command authority and selection', () {
      final source = _battle(phase);
      final decoded =
          RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot(
              _crossTransport(
        RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(
            source),
      ));

      expect(decoded, source);
      expect(decoded.entries.first.selected, isTrue);
      expect(decoded.entries.last.enabled, isFalse);
      expect(decoded.forcedReplacement,
          phase == BattlePresentationPhase.forcedReplacement);
      expect(
        validateBattlePresentationCommand(
          decoded,
          BattleSelectEntryCommand(
            snapshotRevision: decoded.revision,
            expectedMode: decoded.mode,
            entryIndex: decoded.entries.first.index,
          ),
        ).accepted,
        phase != BattlePresentationPhase.presentingTurn,
      );
      if (phase == BattlePresentationPhase.forcedReplacement) {
        expect(
          validateBattlePresentationCommand(
            decoded,
            BattleBackCommand(
              snapshotRevision: decoded.revision,
              expectedMode: decoded.mode,
            ),
          ).rejection,
          BattlePresentationCommandRejection.backUnavailable,
        );
      }
    });
  }
}

Map<String, dynamic> _crossTransport(Map<String, Object?> data) {
  const codec = StandardMessageCodec();
  final platformPayload = codec.decodeMessage(codec.encodeMessage(data));
  return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(platformPayload)) as Map);
}

RuntimePlayerSnapshot _roundTripMenu(RuntimePlayerSnapshot snapshot) =>
    RuntimeCompanionPresentationCodec.decodePlayer(
      _crossTransport(RuntimeCompanionPresentationCodec.encodePlayer(snapshot)),
    );

RuntimePlayerSnapshot _menu(RuntimePlayerPauseDetailSnapshot detail) =>
    RuntimePlayerSnapshot(
      revision: 21,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Train',
      pauseSection: detail.section,
      favoriteItemIds: {'tm-thunder'},
      bagFavoritesAvailable: true,
      pauseDetails: {detail.section: detail},
    );

RuntimePokemonSummarySnapshot _pokemon() => RuntimePokemonSummarySnapshot(
      targetId: 'party:one',
      individualId: 'one',
      speciesLabel: 'Roucool',
      nickname: 'Pico',
      level: 7,
      currentHp: 12,
      maxHp: 24,
      natureLabel: 'Calme',
      abilityLabel: 'Regard Vif',
      friendship: 90,
      heldItemId: 'berry-oran',
      heldItemLabel: 'Baie Oran',
      identity: const RuntimePokemonMediaIdentity(
        speciesId: 'pidgey',
        formId: 'standard',
        gender: 'male',
        isShiny: true,
      ),
      media: const RuntimePokemonSummaryMediaSnapshot(
        thumbnail: RuntimePokemonLocalImageSnapshot(
          absoluteFilePath: '/project/assets/pico-thumb.png',
          sampling: ProjectMenuImageSampling.pixelArt,
        ),
        illustration: RuntimePokemonLocalImageSnapshot(
          absoluteFilePath: '/project/assets/pico-art.png',
          sampling: ProjectMenuImageSampling.smooth,
        ),
      ),
      moves: const [
        RuntimePokemonMoveSummarySnapshot(
          moveId: 'tackle',
          label: 'Charge',
          currentPp: 20,
          maxPp: 35,
        ),
      ],
    );

BattleCommandOverlaySnapshot _battle(BattlePresentationPhase phase, {BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom}) {
  final forced = phase == BattlePresentationPhase.forcedReplacement;
  return BattleCommandOverlaySnapshot(
    commandPanelPlacement: placement,
    revision: 42,
    phase: phase,
    forcedReplacement: forced,
    mode: forced
        ? BattleCommandOverlayMode.pokemon
        : BattleCommandOverlayMode.fight,
    viewportSize: const Size(640, 480),
    panelRect: const Rect.fromLTWH(10, 300, 620, 160),
    enemyHud: const BattleCommandOverlayHudSnapshot(
      rect: Rect.fromLTWH(10, 20, 200, 60),
      ownerLabel: 'Sauvage',
      speciesLabel: 'Rattata',
      level: 5,
      currentHp: 15,
      maxHp: 20,
      isPlayerSide: false,
      isRevealed: false,
    ),
    playerHud: const BattleCommandOverlayHudSnapshot(
      rect: Rect.fromLTWH(400, 220, 200, 60),
      ownerLabel: 'Yoahn',
      speciesLabel: 'Pico',
      level: 7,
      currentHp: 12,
      maxHp: 24,
      isPlayerSide: true,
      displayedHp: 19,
      targetDisplayedHp: 12,
      hpTweenDurationMs: 250,
      hpTweenRevision: 4,
      experienceProgress: .25,
      experienceProgressTarget: .4,
      xpTweenDurationMs: 400,
      xpTweenRevision: 2,
    ),
    battleLabel: 'Combat sauvage',
    title: forced ? 'Choisir un Pokémon' : 'Capacités',
    prompt: 'Que doit faire Pico ?',
    narrationLines: const ['Pico est prêt.'],
    entries: [
      BattleCommandOverlayEntry(
        index: 0,
        kind: forced
            ? BattleCommandOverlayEntryKind.party
            : BattleCommandOverlayEntryKind.move,
        primaryLabel: forced ? 'Pico' : 'Charge',
        secondaryLabel: forced ? 'PV 12/24' : 'Normal',
        trailingLabel: forced ? 'Niv. 7' : 'PP 20/35',
        enabled: true,
        selected: true,
        tone: BattleCommandOverlayEntryTone.attack,
      ),
      BattleCommandOverlayEntry(
        index: 1,
        kind: forced
            ? BattleCommandOverlayEntryKind.party
            : BattleCommandOverlayEntryKind.move,
        primaryLabel: forced ? 'KO' : 'Tornade',
        secondaryLabel: forced ? 'PV 0/24' : 'Vol',
        statusLabel: 'Indisponible',
        enabled: false,
        selected: false,
        tone: BattleCommandOverlayEntryTone.disabled,
      ),
    ],
    interactionsEnabled: phase != BattlePresentationPhase.presentingTurn,
    canGoBack: phase == BattlePresentationPhase.choosingCommand,
  );
}

Iterable<RuntimeWorldServiceSnapshot> _worldServices() sync* {
  final interaction = SceneTextInteractionRequest(requestId: 'gift:nickname', revision: 4,
    prompt: SceneInteractionPrompt(localizationKey: 'nickname'), initialValue: 'Pendule',
    constraints: SceneTextInputConstraints(maxGraphemes: 10));
  for (final (request, content) in <(RuntimeWorldServiceRequest, Object)>[
    (const OpenShopService(interactionId: 'shop', shopId: 'mart'),
      RuntimeShopServiceContent(title: 'Mart', message: 'Hello', money: 120, mode: RuntimeShopMode.sell,
        selectedItemId: 'potion', quantity: 2, totalPrice: 60,
        entries: const [RuntimeShopEntrySnapshot(itemId: 'potion', label: 'Potion', unitPrice: 30, ownedQuantity: 3)])),
    (const OpenHealService(interactionId: 'heal', requiresConfirmation: false, displayEntityId: 'machine'),
      RuntimeHealServiceContent(title: 'Heal', message: 'Healing', wasHealed: true,
        display: RuntimeHealingDisplaySnapshot(mapId: 'lab', entityId: 'machine', memberCount: 1),
        members: const [RuntimeHealPartyMemberSnapshot(partyIndex: 0, label: 'Partner', currentHp: 4,
          maxHp: 20, hasStatus: true, depletedMoveCount: 2)])),
    (const OpenPcService(interactionId: 'pc', storageId: 'box'), RuntimePcServiceContent(
      title: 'PC', message: '', selectedBoxId: 'box',
      boxes: const [RuntimePcBoxSnapshot(boxId: 'box', label: 'Box', count: 1, capacity: 30)],
      stored: [RuntimePcPokemonSnapshot(targetId: 'opaque', label: 'Partner', speciesId: 'bird',
        level: 7, natureId: 'hardy', abilityId: 'clockwork', currentHp: 5, canTransfer: true,
        knownMoveIds: ['tick'], metLevel: 5, friendship: 90, nickname: 'Pendule')])),
    (const OpenPartyTradeService(interactionId: 'trade'), RuntimePartyTradeServiceContent(
      phase: RuntimePartyTradePhase.review, firstIndividualId: 'a', partnerIndividualId: 'b',
      members: const [RuntimePartyTradePokemonSnapshot(individualId: 'a', speciesId: 'bird', label: 'Bird', level: 7)])),
    (OpenPokemonGiftInteractionService(interactionId: 'gift', interaction: interaction,
      stage: PokemonGiftInteractionStage.nickname, speciesName: 'Bird', isNewPokedexEntry: true,
      pokemon: const PlayerPokemon(speciesId: 'bird', individualId: 'one', natureId: 'hardy', abilityId: 'clockwork', currentHp: 5),
      projectedState: const GameState(saveId: 'gift')), interaction),
  ]) {
    yield RuntimeWorldServiceSnapshot(revision: 7, request: request, content: content,
      stage: RuntimeWorldServiceStage.active, safeMessage: 'Native receipt', logicalSelectionId: 'selection',
      actions: [const RuntimeWorldServiceActionAvailability.enabled(RuntimeWorldServiceAction.cancel),
        RuntimeWorldServiceActionAvailability.disabled(RuntimeWorldServiceAction.confirm, reason: 'Not ready')]);
  }
}
