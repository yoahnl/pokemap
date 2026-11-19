part of 'runtime_post_battle_decision_coordinator.dart';

final class _PostBattleMessages {
  const _PostBattleMessages(this.format);

  final RuntimeBattleMessageRenderer? format;

  String render(RuntimeBattleMessage message) => message.render(format);

  RuntimePostBattleMessage line(
    RuntimePostBattleMessageKind kind,
    RuntimeBattleMessage message, {
    int? partySlot,
  }) => RuntimePostBattleMessage(
    kind: kind,
    text: render(message),
    partySlot: partySlot,
  );

  List<RuntimePostBattleMessage> terminal(
    BattleOutcome outcome,
    CaptureDestinationKind? destination,
    String Function(String speciesId)? resolveSpecies,
  ) {
    String capturedName() => _speciesDisplayName(
      outcome.finalState.enemy.writeBackSpeciesId,
      resolveSpecies,
    );
    final messages = <RuntimePostBattleMessage>[
      switch (outcome.type) {
        BattleOutcomeType.defeat => line(
          RuntimePostBattleMessageKind.defeat,
          const RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleDefeat,
            'Tous vos Pokémon sont hors combat.',
          ),
        ),
        BattleOutcomeType.runaway => line(
          RuntimePostBattleMessageKind.fled,
          const RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleFled,
            'Vous prenez la fuite !',
          ),
        ),
        BattleOutcomeType.captured => line(
          RuntimePostBattleMessageKind.captured,
          _captured(capturedName()),
        ),
        BattleOutcomeType.victory => throw StateError(
          'Victory must use the reward progression transaction.',
        ),
      },
    ];
    if (destination != null) {
      final target = capturedName();
      messages.add(
        line(
          RuntimePostBattleMessageKind.captureDestination,
          switch (destination) {
            CaptureDestinationKind.party => RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleCaptureParty,
              '$target rejoint votre équipe.',
              target: target,
            ),
            CaptureDestinationKind.storage => RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleCaptureStorage,
              '$target est envoyé au stockage.',
              target: target,
            ),
            CaptureDestinationKind.none => const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleCaptureUnavailable,
              'La destination de capture est indisponible.',
            ),
          },
        ),
      );
    }
    return messages;
  }

  RuntimeBattleMessage _captured(String target) => RuntimeBattleMessage(
    RuntimeBattleMessageId.postBattleCaptured,
    '$target est capturé.',
    target: target,
  );

  List<RuntimePostBattleMessage> initialVictory({
    required RuntimeBattleRewardResolution resolution,
    required String Function(String speciesId)? resolveSpecies,
    required String Function(String moveId) resolveMove,
  }) {
    final messages = <RuntimePostBattleMessage>[
      line(
        RuntimePostBattleMessageKind.victory,
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleVictory,
          'Victoire !',
        ),
      ),
    ];
    final party = resolution.baseState.party;
    String displayName(int slot) =>
        _partyNickname(party, slot) ??
        _speciesDisplayName(party.members[slot].speciesId, resolveSpecies);
    for (final change in resolution.progression.changes) {
      final target = displayName(change.partySlot);
      final amount = change.experienceAwarded;
      messages.add(
        line(
          RuntimePostBattleMessageKind.experience,
          RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleExperience,
            '$target a gagné $amount points Exp. !',
            target: target,
            amount: amount,
          ),
          partySlot: change.partySlot,
        ),
      );
    }
    for (final change in resolution.progression.changes) {
      final target = displayName(change.partySlot);
      for (var level = change.oldLevel + 1; level <= change.newLevel; level++) {
        messages.add(
          line(
            RuntimePostBattleMessageKind.levelUp,
            RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleLevelUp,
              '$target monte au N. $level !',
              target: target,
              amount: level,
            ),
            partySlot: change.partySlot,
          ),
        );
      }
    }
    messages.addAll(
      moveChanges(resolution.progression.moveLearningChanges, resolveMove),
    );
    messages.addAll(
      evolutionChanges(
        resolution.progression.evolutionChanges,
        party: party,
        resolveSpecies: resolveSpecies,
      ),
    );
    return List<RuntimePostBattleMessage>.unmodifiable(messages);
  }

  List<RuntimePostBattleMessage> moveChanges(
    Iterable<BattleMoveLearningChange> changes,
    String Function(String moveId) resolveMove,
  ) => [
    for (final change in changes)
      if (change.kind != BattleMoveLearningChangeKind.replacementRequested)
        _moveChange(change, resolveMove),
  ];

  RuntimePostBattleMessage _moveChange(
    BattleMoveLearningChange change,
    String Function(String moveId) resolveMove,
  ) {
    final move = resolveMove(change.candidate.moveId);
    final kind = switch (change.kind) {
      BattleMoveLearningChangeKind.automaticallyLearned =>
        RuntimePostBattleMessageKind.moveAutomaticallyLearned,
      BattleMoveLearningChangeKind.learned =>
        RuntimePostBattleMessageKind.moveLearned,
      BattleMoveLearningChangeKind.replaced =>
        RuntimePostBattleMessageKind.moveReplaced,
      BattleMoveLearningChangeKind.declined =>
        RuntimePostBattleMessageKind.moveDeclined,
      BattleMoveLearningChangeKind.replacementRequested => throw StateError(
        'Replacement requests are rendered as prompts.',
      ),
    };
    final message = switch (change.kind) {
      BattleMoveLearningChangeKind.automaticallyLearned ||
      BattleMoveLearningChangeKind.learned => RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleMoveLearned,
        '$move est apprise.',
        move: move,
      ),
      BattleMoveLearningChangeKind.replaced => _moveReplaced(
        resolveMove(change.replacedMoveId ?? ''),
        move,
      ),
      BattleMoveLearningChangeKind.declined => RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleMoveDeclined,
        '$move n’est pas apprise.',
        move: move,
      ),
      BattleMoveLearningChangeKind.replacementRequested => throw StateError(
        'Replacement requests are rendered as prompts.',
      ),
    };
    return line(kind, message, partySlot: change.partySlot);
  }

  RuntimeBattleMessage _moveReplaced(String previousMove, String move) =>
      RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleMoveReplaced,
        '$previousMove est remplacée par $move.',
        previousMove: previousMove,
        move: move,
      );

  List<RuntimePostBattleMessage> evolutionChanges(
    Iterable<BattleEvolutionChange> changes, {
    required PlayerParty party,
    required String Function(String speciesId)? resolveSpecies,
  }) => [
    for (final change in changes)
      _evolutionChange(
        change,
        target:
            _partyNickname(party, change.partySlot) ??
            _speciesDisplayName(
              change.candidate.sourceSpeciesId,
              resolveSpecies,
            ),
        resolveSpecies: resolveSpecies,
      ),
  ];

  RuntimePostBattleMessage _evolutionChange(
    BattleEvolutionChange change, {
    required String target,
    required String Function(String speciesId)? resolveSpecies,
  }) {
    if (change.kind == BattleEvolutionChangeKind.evolved) {
      final replacement = _speciesDisplayName(
        change.candidate.targetSpeciesId,
        resolveSpecies,
      );
      return line(
        RuntimePostBattleMessageKind.evolutionAccepted,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleEvolutionAccepted,
          '$target évolue en $replacement.',
          target: target,
          replacement: replacement,
        ),
        partySlot: change.partySlot,
      );
    }
    return line(
      RuntimePostBattleMessageKind.evolutionRefused,
      RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleEvolutionRefused,
        '$target n’évolue pas.',
        target: target,
      ),
      partySlot: change.partySlot,
    );
  }

  List<RuntimePostBattleMessage> rewards(
    BattleReward reward, {
    required ItemCatalogSnapshot? itemCatalog,
    required String Function(String moveId) resolveMove,
  }) => [
    if (reward.money > 0)
      line(
        RuntimePostBattleMessageKind.money,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleMoney,
          'Vous remportez ${reward.money} ₽ !',
          amount: reward.money,
        ),
      ),
    for (final grant in reward.itemGrants)
      line(
        RuntimePostBattleMessageKind.item,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleItem,
          '${_displayId(grant.itemId)} ×${grant.quantity} obtenu.',
          item:
              itemCatalog?.definitionFor(grant.itemId)?.displayName ??
              _displayId(grant.itemId),
          amount: grant.quantity,
        ),
      ),
    for (final flagId in reward.flagIds)
      line(
        RuntimePostBattleMessageKind.flag,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleFlag,
          '${_displayId(flagId)} est débloqué.',
          target: _displayId(flagId),
        ),
      ),
    if (reward.badgeId case final badgeId?)
      line(
        RuntimePostBattleMessageKind.badge,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleBadge,
          'Badge ${_displayId(badgeId)} obtenu.',
          target: _displayId(badgeId),
        ),
      ),
    if (reward.fieldAbilityUnlock case final ability?)
      line(
        RuntimePostBattleMessageKind.fieldAbility,
        RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleAbility,
          '${_displayId(ability.name)} est maintenant utilisable.',
          move: resolveMove(ability.moveId),
        ),
      ),
  ];
}

String? _partyNickname(PlayerParty? party, int slot) {
  if (party == null || slot < 0 || slot >= party.members.length) return null;
  final nickname = party.members[slot].nickname.trim();
  return nickname.isEmpty ? null : nickname;
}
