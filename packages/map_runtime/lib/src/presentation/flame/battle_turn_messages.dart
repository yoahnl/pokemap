import 'package:map_battle/map_battle.dart';

import '../runtime_battle_message.dart';
import 'battle_animation_plan.dart';

final class BattleTurnMessages {
  const BattleTurnMessages(this.format);

  final RuntimeBattleMessageRenderer? format;

  ShowMessageStep show(RuntimeBattleMessage message) =>
      ShowMessageStep(message: message.render(format));

  String sideLabel(BattleSideId side) => switch (side) {
    BattleSideId.player => const RuntimeBattleMessage(
      RuntimeBattleMessageId.player,
      'Joueur',
    ).render(format),
    BattleSideId.enemy => const RuntimeBattleMessage(
      RuntimeBattleMessageId.enemy,
      'Ennemi',
    ).render(format),
  };

  ShowMessageStep moveUsed(String actor, String move, {required int damage}) {
    final message = RuntimeBattleMessage(
      RuntimeBattleMessageId.moveUsed,
      '$actor utilise $move !',
      actor: actor,
      move: move,
    ).render(format);
    final summary = format != null && damage > 0
        ? RuntimeBattleMessage(
            RuntimeBattleMessageId.moveDamageSummary,
            '$actor utilise $move et inflige $damage dégâts.',
            actor: actor,
            move: move,
            amount: damage,
          ).render(format)
        : null;
    return ShowMessageStep(message: message, summaryMessage: summary);
  }

  ShowMessageStep moveDodged(String target) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.moveDodged,
      '$target évite l’attaque !',
      target: target,
    ),
  );

  ShowMessageStep moveImmune(String target) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.moveImmune,
      'Ça n’affecte pas $target…',
      target: target,
    ),
  );

  ShowMessageStep fainted(String target) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.fainted,
      '$target est K.O. !',
      target: target,
    ),
  );

  ShowMessageStep itemUsed(BattleSideId side, String item, String target) {
    final actor = sideLabel(side);
    return show(
      RuntimeBattleMessage(
        RuntimeBattleMessageId.itemUsed,
        '$actor utilise $item sur $target !',
        actor: actor,
        item: item,
        target: target,
      ),
    );
  }

  ShowMessageStep hpRecovered(String target, int amount) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.hpRecovered,
      '$target récupère $amount PV.',
      target: target,
      amount: amount,
    ),
  );

  ShowMessageStep statusCured(String target) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.statusCured,
      '$target est guéri de son problème de statut.',
      target: target,
    ),
  );

  ShowMessageStep ppRecovered(String move, int amount) => show(
    RuntimeBattleMessage(
      RuntimeBattleMessageId.ppRecovered,
      '$move récupère $amount PP.',
      move: move,
      amount: amount,
    ),
  );

  ShowMessageStep statStage(BattleTurnStatStageEvent event, String target) {
    final label = switch (event.stat) {
      BattleStatId.attack => 'L’Attaque',
      BattleStatId.defense => 'La Défense',
      BattleStatId.specialAttack => 'L’Attaque Spéciale',
      BattleStatId.specialDefense => 'La Défense Spéciale',
      BattleStatId.speed => 'La Vitesse',
      BattleStatId.accuracy => 'La Précision',
      BattleStatId.evasion => 'L’Esquive',
    };
    final amount = event.amount.abs();
    final magnitude = switch (amount) {
      0 || 1 => '',
      2 => ' beaucoup',
      _ => ' énormément',
    };
    final (id, phrase) = switch (event.amount) {
      > 0 => (RuntimeBattleMessageId.statRaised, 'augmente$magnitude'),
      < 0 => (RuntimeBattleMessageId.statLowered, 'baisse$magnitude'),
      _ when event.currentStage > 0 => (
        RuntimeBattleMessageId.statCannotRaise,
        'ne peut plus augmenter',
      ),
      _ => (RuntimeBattleMessageId.statCannotLower, 'ne peut plus baisser'),
    };
    return show(
      RuntimeBattleMessage(
        id,
        '$label de $target $phrase !',
        target: target,
        stat: event.stat,
        amount: amount,
      ),
    );
  }

  ShowMessageStep status(BattleStatusEvent event, String target) {
    final (id, text) = switch (event.kind) {
      BattleStatusEventKind.applied => switch (event.status) {
        BattleMajorStatusId.par => (
          RuntimeBattleMessageId.paralyzed,
          '$target est paralysé ! Il aura du mal à attaquer !',
        ),
        BattleMajorStatusId.brn => (
          RuntimeBattleMessageId.burned,
          '$target est brûlé !',
        ),
        BattleMajorStatusId.psn => (
          RuntimeBattleMessageId.poisoned,
          '$target est empoisonné !',
        ),
        BattleMajorStatusId.tox => (
          RuntimeBattleMessageId.badlyPoisoned,
          '$target est gravement empoisonné !',
        ),
        BattleMajorStatusId.slp => (
          RuntimeBattleMessageId.fellAsleep,
          '$target s’est endormi !',
        ),
        BattleMajorStatusId.frz => (
          RuntimeBattleMessageId.frozen,
          '$target est gelé !',
        ),
      },
      BattleStatusEventKind.blockedExistingMajorStatus => (
        RuntimeBattleMessageId.alreadyHasStatus,
        '$target a déjà un statut majeur.',
      ),
      BattleStatusEventKind.preventedAction => (
        RuntimeBattleMessageId.cannotAct,
        '$target ne peut pas agir !',
      ),
      BattleStatusEventKind.residualDamage => switch (event.status) {
        BattleMajorStatusId.brn => (
          RuntimeBattleMessageId.burnDamage,
          '$target souffre de sa brûlure !',
        ),
        BattleMajorStatusId.psn || BattleMajorStatusId.tox => (
          RuntimeBattleMessageId.poisonDamage,
          '$target souffre du poison !',
        ),
        _ => (
          RuntimeBattleMessageId.statusDamage,
          '$target subit des dégâts !',
        ),
      },
    };
    return show(RuntimeBattleMessage(id, text, target: target));
  }

  ShowMessageStep volatile(BattleVolatileEvent event, String actor) {
    final (id, text) = switch (event.kind) {
      BattleVolatileEventKind.protectActivated => (
        RuntimeBattleMessageId.protectActivated,
        '$actor se protège !',
      ),
      BattleVolatileEventKind.protectBlocked => (
        RuntimeBattleMessageId.protectBlocked,
        'L’attaque est bloquée par Protect !',
      ),
      BattleVolatileEventKind.protectBroken => (
        RuntimeBattleMessageId.protectBroken,
        'La protection est brisée !',
      ),
      BattleVolatileEventKind.rechargeRequired => (
        RuntimeBattleMessageId.rechargeRequired,
        '$actor doit se recharger !',
      ),
      BattleVolatileEventKind.rechargeTurnSpent => (
        RuntimeBattleMessageId.rechargeTurnSpent,
        '$actor récupère son souffle.',
      ),
      BattleVolatileEventKind.chargeStarted => (
        RuntimeBattleMessageId.chargeStarted,
        '$actor se charge !',
      ),
      BattleVolatileEventKind.chargeReleased => (
        RuntimeBattleMessageId.chargeReleased,
        '$actor libère son attaque !',
      ),
      BattleVolatileEventKind.confusionApplied => (
        RuntimeBattleMessageId.confusionApplied,
        'Ça rend $actor confus !',
      ),
      BattleVolatileEventKind.confusionActive => (
        RuntimeBattleMessageId.confusionActive,
        '$actor est confus !',
      ),
      BattleVolatileEventKind.confusionEnded => (
        RuntimeBattleMessageId.confusionEnded,
        '$actor n’est plus confus !',
      ),
    };
    return show(RuntimeBattleMessage(id, text, actor: actor));
  }

  ShowMessageStep field(BattleFieldEvent event, String? target) {
    final (id, text) = switch (event.kind) {
      BattleFieldEventKind.weatherSet =>
        event.weather == BattleWeatherId.rain
            ? (
                RuntimeBattleMessageId.rainStarted,
                'La pluie commence à tomber.',
              )
            : (
                RuntimeBattleMessageId.sandstormStarted,
                'Une tempête de sable se lève.',
              ),
      BattleFieldEventKind.weatherResidualDamage => (
        RuntimeBattleMessageId.sandstormDamage,
        '$target est blessé par la tempête de sable !',
      ),
      BattleFieldEventKind.weatherExpired => (
        RuntimeBattleMessageId.weatherExpired,
        'La météo se dissipe.',
      ),
      BattleFieldEventKind.pseudoWeatherSet => (
        RuntimeBattleMessageId.trickRoomStarted,
        'L’espace se tord bizarrement.',
      ),
      BattleFieldEventKind.pseudoWeatherCleared => (
        RuntimeBattleMessageId.fieldCleared,
        'Le pseudo-climat de champ disparaît.',
      ),
      BattleFieldEventKind.pseudoWeatherExpired => (
        RuntimeBattleMessageId.fieldExpired,
        'L’effet de champ prend fin.',
      ),
    };
    return show(RuntimeBattleMessage(id, text, target: target ?? 'Pokémon'));
  }

  ShowMessageStep stealthRock(BattleStealthRockEvent event) =>
      show(switch (event.kind) {
        BattleStealthRockEventKind.set => const RuntimeBattleMessage(
          RuntimeBattleMessageId.stealthRockSet,
          'Des pièges de roc entourent le camp adverse !',
        ),
        BattleStealthRockEventKind.alreadyPresent => const RuntimeBattleMessage(
          RuntimeBattleMessageId.stealthRockAlreadyPresent,
          'Les pièges de roc sont déjà en place.',
        ),
        BattleStealthRockEventKind.damagedOnEntry => const RuntimeBattleMessage(
          RuntimeBattleMessageId.stealthRockDamage,
          'Les pièges de roc blessent le Pokémon entrant !',
        ),
      });

  ShowMessageStep spikes(BattleSpikesEvent event) => show(switch (event.kind) {
    BattleSpikesEventKind.setLayer => const RuntimeBattleMessage(
      RuntimeBattleMessageId.spikesSet,
      'Des picots se dispersent sur le terrain adverse !',
    ),
    BattleSpikesEventKind.alreadyAtMaxLayers => const RuntimeBattleMessage(
      RuntimeBattleMessageId.spikesAlreadyPresent,
      'Les picots sont déjà au maximum.',
    ),
    BattleSpikesEventKind.damagedOnEntry => const RuntimeBattleMessage(
      RuntimeBattleMessageId.spikesDamage,
      'Les picots blessent le Pokémon entrant !',
    ),
  });

  ShowMessageStep switchCombatant({
    required BattleSwitchEvent event,
    required String outgoing,
    required String incoming,
  }) {
    final actor = sideLabel(event.side);
    return show(switch (event.kind) {
      BattleSwitchEventKind.switched => RuntimeBattleMessage(
        RuntimeBattleMessageId.switched,
        '$actor rappelle ${event.fromSpeciesId} et envoie ${event.toSpeciesId} !',
        actor: actor,
        target: outgoing,
        replacement: incoming,
      ),
      BattleSwitchEventKind.replacementRequired => RuntimeBattleMessage(
        RuntimeBattleMessageId.replacementRequired,
        '$actor doit remplacer ${event.fromSpeciesId} !',
        actor: actor,
        target: outgoing,
      ),
    });
  }
}
