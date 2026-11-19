part of 'battle_overlay_component.dart';

typedef BattleSpeciesDisplayNameResolver = String Function(String speciesId);
typedef BattleCombatantDisplayNameResolver = String Function(
  BattleSideId side,
  BattleCombatant combatant,
);

String buildBattleDecisionPromptForSession(
  BattleSession session, {
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName =
      _battleDisplayName,
  BattleCombatantDisplayNameResolver? resolveCombatantDisplayName,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  final player = session.state.player;
  String playerName() =>
      resolveCombatantDisplayName?.call(BattleSideId.player, player) ??
      resolveSpeciesDisplayName(player.speciesId);

  final message = switch (session.decisionRequest) {
    BattleTurnChoiceRequest() => _chooseBattleAction(playerName()),
    BattleForcedReplacementRequest() => RuntimeBattleMessage(
      RuntimeBattleMessageId.chooseReplacementAfterFaint,
      '${playerName()} est K.O. Choisis un remplaçant.',
      actor: playerName(),
    ),
    BattleContinueRequest() => const RuntimeBattleMessage(
      RuntimeBattleMessageId.continuePrompt,
      'Appuie pour continuer.',
    ),
    BattleWaitRequest(:final reason) => switch (reason) {
      BattleWaitReason.battleFinished => const RuntimeBattleMessage(
        RuntimeBattleMessageId.battleFinished,
        'Combat terminé.',
      ),
      BattleWaitReason.resolvingTurn => const RuntimeBattleMessage(
        RuntimeBattleMessageId.resolvingTurn,
        'Résolution du tour en cours.',
      ),
      BattleWaitReason.activeFaintedWithoutReplacement =>
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.noReplacement,
          'Aucun remplaçant disponible.',
        ),
      BattleWaitReason.noLegalChoice => const RuntimeBattleMessage(
        RuntimeBattleMessageId.noLegalChoice,
        'Aucune décision légale disponible.',
      ),
    },
  };
  return message.render(formatBattleMessage);
}

RuntimeBattleMessage _chooseBattleAction(String name) => RuntimeBattleMessage(
  RuntimeBattleMessageId.chooseAction,
  'Que doit faire $name ?',
  actor: name,
);

List<String> buildBattleOpeningNarrationLinesForOverlay(
  BattleSession session, {
  BattleSpeciesDisplayNameResolver resolveSpeciesDisplayName =
      _battleDisplayName,
  BattleCombatantDisplayNameResolver? resolveCombatantDisplayName,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  final enemy = session.state.enemy;
  final player = session.state.player;
  final enemyName =
      resolveCombatantDisplayName?.call(BattleSideId.enemy, enemy) ??
      resolveSpeciesDisplayName(enemy.speciesId);
  final playerName =
      resolveCombatantDisplayName?.call(BattleSideId.player, player) ??
      resolveSpeciesDisplayName(player.speciesId);
  final sendPlayer = RuntimeBattleMessage(
    RuntimeBattleMessageId.go,
    'Vas-y, $playerName !',
    target: playerName,
  );

  if (!session.setup.isTrainerBattle) {
    return List<String>.unmodifiable([
      RuntimeBattleMessage(
        RuntimeBattleMessageId.wildAppeared,
        'Un $enemyName sauvage apparaît !',
        target: enemyName,
      ).render(formatBattleMessage),
      sendPlayer.render(formatBattleMessage),
    ]);
  }
  final trainerName = session.setup.trainerId?.trim();
  final hasTrainer = trainerName != null && trainerName.isNotEmpty;
  final challenger = hasTrainer ? 'Le Dresseur $trainerName' : 'Un Dresseur';
  return List<String>.unmodifiable([
    RuntimeBattleMessage(
      hasTrainer
          ? RuntimeBattleMessageId.trainerChallenges
          : RuntimeBattleMessageId.unknownTrainerChallenges,
      '$challenger te défie !',
      actor: trainerName ?? '',
    ).render(formatBattleMessage),
    RuntimeBattleMessage(
      hasTrainer
          ? RuntimeBattleMessageId.trainerSends
          : RuntimeBattleMessageId.unknownTrainerSends,
      '$challenger envoie $enemyName !',
      actor: trainerName ?? '',
      target: enemyName,
    ).render(formatBattleMessage),
    sendPlayer.render(formatBattleMessage),
  ]);
}

String buildBattlePartyPromptForOverlay(
  BattlePartyMenuModel partyMenuModel, {
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  final message = switch (partyMenuModel.mode) {
    BattlePartyMenuMode.voluntarySwitch => const RuntimeBattleMessage(
      RuntimeBattleMessageId.choosePokemon,
      'Choisis un Pokémon.',
    ),
    BattlePartyMenuMode.forcedReplacement => const RuntimeBattleMessage(
      RuntimeBattleMessageId.chooseReplacement,
      'Choisis un remplaçant.',
    ),
    BattlePartyMenuMode.unavailable => const RuntimeBattleMessage(
      RuntimeBattleMessageId.actionUnavailable,
      'POKÉMON indisponible.',
    ),
  };
  return message.render(formatBattleMessage);
}

List<String> buildBattlePartyNarrationLinesForOverlay(
  BattlePartyMenuModel partyMenuModel, {
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  final message = switch (partyMenuModel) {
    BattlePartyMenuModel(mode: BattlePartyMenuMode.forcedReplacement) =>
      const RuntimeBattleMessage(
        RuntimeBattleMessageId.replacementRequiredHint,
        'Remplacement requis.',
      ),
    BattlePartyMenuModel(hasSelectableEntries: false) =>
      const RuntimeBattleMessage(
        RuntimeBattleMessageId.noSwitch,
        'Aucun switch disponible.',
      ),
    _ => const RuntimeBattleMessage(
      RuntimeBattleMessageId.activeOrFainted,
      'Actif et K.O. sont indisponibles.',
    ),
  };
  return [message.render(formatBattleMessage)];
}

String buildBattleBagPromptForOverlay(
  BattleBagMenuModel bagMenuModel, {
  String? feedbackMessage,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return feedbackMessage;
  }
  final message = bagMenuModel.mode == BattleBagMenuMode.empty
      ? const RuntimeBattleMessage(RuntimeBattleMessageId.emptyBag, 'Sac vide.')
      : const RuntimeBattleMessage(
          RuntimeBattleMessageId.chooseItem,
          'Choisis un objet.',
        );
  return message.render(formatBattleMessage);
}

List<String> buildBattleBagNarrationLinesForOverlay(
  BattleBagMenuModel bagMenuModel, {
  String? feedbackMessage,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return formatBattleMessage == null
        ? const ['Le sac reflète maintenant l’état réel du runtime.']
        : const [];
  }
  final message = switch (bagMenuModel.mode) {
    BattleBagMenuMode.empty => const RuntimeBattleMessage(
      RuntimeBattleMessageId.emptyBag,
      'Aucun objet dans le sac.',
    ),
    BattleBagMenuMode.available => const RuntimeBattleMessage(
      RuntimeBattleMessageId.itemsDisabled,
      'Les objets indisponibles restent grisés.',
    ),
    BattleBagMenuMode.unavailable => const RuntimeBattleMessage(
      RuntimeBattleMessageId.noUsableItem,
      'Aucun objet utilisable pour ce tour.',
    ),
  };
  return [message.render(formatBattleMessage)];
}

String buildBattleMedicineTargetPromptForOverlay(
  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
  String? feedbackMessage,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return feedbackMessage;
  }
  final item = medicineTargetMenuModel.displayName;
  return RuntimeBattleMessage(
    RuntimeBattleMessageId.chooseItemTarget,
    'Choisis une cible pour $item.',
    item: item,
  ).render(formatBattleMessage);
}

List<String> buildBattleMedicineTargetNarrationLinesForOverlay(
  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
  String? feedbackMessage,
  RuntimeBattleMessageRenderer? formatBattleMessage,
}) {
  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
    return formatBattleMessage == null
        ? const ['L’état battle/runtime affiché a déjà été mis à jour.']
        : const [];
  }
  final message = medicineTargetMenuModel.hasSelectableEntries
      ? const RuntimeBattleMessage(
          RuntimeBattleMessageId.faintedOrFullHp,
          'Les Pokémon K.O. et full HP sont indisponibles.',
        )
      : const RuntimeBattleMessage(
          RuntimeBattleMessageId.noItemTarget,
          'Aucune cible valide pour cet objet.',
        );
  return [message.render(formatBattleMessage)];
}
