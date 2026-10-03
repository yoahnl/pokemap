import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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

BattleCommandOverlaySnapshot _battle(BattlePresentationPhase phase) {
  final forced = phase == BattlePresentationPhase.forcedReplacement;
  return BattleCommandOverlaySnapshot(
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
