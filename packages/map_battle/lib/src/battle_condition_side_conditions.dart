part of 'battle_condition_engine.dart';

/// Résultat borné d'une résolution de side conditions déjà supportées.
///
/// R3 garde ce contrat petit et concret :
/// - un side mis à jour ;
/// - les événements `Stealth Rock` effectivement produits ;
/// - les événements `Spikes` effectivement produits ;
/// - rien d'autre.
///
/// Garde-fous explicites :
/// - ce n'est pas un journal universel de side conditions ;
/// - ce n'est pas un payload extensible "pour plus tard" ;
/// - si une future mécanique exige un autre shape, elle devra l'ouvrir
///   explicitement au lieu de se glisser silencieusement ici.
final class BattleSideConditionResolution {
  const BattleSideConditionResolution({
    required this.side,
    this.stealthRockEvents = const <BattleStealthRockEvent>[],
    this.spikesEvents = const <BattleSpikesEvent>[],
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
}

/// Règles lifecycle strictement bornées aux hazards déjà ouvertes.
///
/// Pourquoi ce seam existe en R3 :
/// - `BattleSession` ne doit plus porter elle-même le "comment" de
///   `Stealth Rock` et `Spikes` ;
/// - le scheduler doit garder le "quand" ;
/// - l'engine conditionnel doit reprendre le "comment" pour réduire
///   l'asymétrie structurelle avec status / volatile / field.
///
/// Pourquoi ce seam ne dérive pas déjà vers H3 :
/// - aucune nouvelle hazard n'est ouverte ;
/// - aucune side condition générique n'est inventée ;
/// - aucun ordre dynamique "selon setup" n'est introduit ;
/// - on consolide seulement deux mécaniques déjà réellement vivantes.
final class _BattleSideConditionRules {
  const _BattleSideConditionRules();

  BattleSideConditionResolution runMoveResolved({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    // Le lifecycle move-resolved side-level reste volontairement petit :
    // - seuls les moves qui posent déjà honnêtement `Stealth Rock` ou
    //   `Spikes` passent ici ;
    // - le hit check a déjà été résolu en amont ;
    // - un miss ou une exécution annulée ne pose rien ;
    // - le scheduler garde le contrôle de l'ordre observable autour du move.
    final stealthRockResolution = _resolveStealthRockMoveResolved(
      move: move,
      didResolveHit: didResolveHit,
      targetSide: targetSide,
    );
    final spikesResolution = _resolveSpikesMoveResolved(
      move: move,
      didResolveHit: didResolveHit,
      targetSide: stealthRockResolution.side,
    );

    return BattleSideConditionResolution(
      side: spikesResolution.side,
      stealthRockEvents: stealthRockResolution.events,
      spikesEvents: spikesResolution.events,
    );
  }

  BattleSideConditionResolution runEntryHazards({
    required BattleSideState side,
  }) {
    // R3 garde ici la plus petite composition honnête :
    // - l'ordre local reste figé et documenté, pas dynamique ;
    // - `Stealth Rock` puis `Spikes` ;
    // - si `Stealth Rock` met K.O. l'entrant, `Spikes` ne se déclenche pas ;
    // - le scheduler reste propriétaire du "quand une entrée a lieu".
    final stealthRockResolution = _resolveStealthRockEntry(side: side);
    final sideAfterStealthRock = stealthRockResolution.side;
    if (sideAfterStealthRock.active.isFainted) {
      return BattleSideConditionResolution(
        side: sideAfterStealthRock,
        stealthRockEvents: stealthRockResolution.events,
        spikesEvents: const <BattleSpikesEvent>[],
      );
    }

    final spikesResolution = _resolveSpikesEntry(side: sideAfterStealthRock);
    return BattleSideConditionResolution(
      side: spikesResolution.side,
      stealthRockEvents: stealthRockResolution.events,
      spikesEvents: spikesResolution.events,
    );
  }

  _ResolvedStealthRockLifecycle _resolveStealthRockMoveResolved({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsStealthRock || !didResolveHit) {
      return _ResolvedStealthRockLifecycle(
        side: targetSide,
        events: const <BattleStealthRockEvent>[],
      );
    }

    if (targetSide.hasStealthRock) {
      return _ResolvedStealthRockLifecycle(
        side: targetSide,
        events: <BattleStealthRockEvent>[
          BattleStealthRockEvent.alreadyPresent(
            side: targetSide.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStealthRockLifecycle(
      side: targetSide.withStealthRock(true),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.set(
          side: targetSide.id,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedStealthRockLifecycle _resolveStealthRockEntry({
    required BattleSideState side,
  }) {
    if (!side.hasStealthRock) {
      return _ResolvedStealthRockLifecycle(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final intendedDamage = resolveStealthRockEntryDamage(side.active);
    if (intendedDamage <= 0) {
      return _ResolvedStealthRockLifecycle(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    return _ResolvedStealthRockLifecycle(
      side: side.withActive(side.active.withDamage(actualDamage)),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
        ),
      ],
    );
  }

  _ResolvedSpikesLifecycle _resolveSpikesMoveResolved({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsSpikes || !didResolveHit) {
      return _ResolvedSpikesLifecycle(
        side: targetSide,
        events: const <BattleSpikesEvent>[],
      );
    }

    if (targetSide.spikesLayers >= 3) {
      return _ResolvedSpikesLifecycle(
        side: targetSide,
        events: <BattleSpikesEvent>[
          BattleSpikesEvent.alreadyAtMaxLayers(
            side: targetSide.id,
            layers: targetSide.spikesLayers,
          ),
        ],
      );
    }

    final nextLayers = targetSide.spikesLayers + 1;
    return _ResolvedSpikesLifecycle(
      side: targetSide.withSpikesLayers(nextLayers),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.setLayer(
          side: targetSide.id,
          layers: nextLayers,
        ),
      ],
    );
  }

  _ResolvedSpikesLifecycle _resolveSpikesEntry({
    required BattleSideState side,
  }) {
    if (side.spikesLayers <= 0) {
      return _ResolvedSpikesLifecycle(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final intendedDamage = resolveSpikesEntryDamage(
      combatant: side.active,
      layers: side.spikesLayers,
    );
    if (intendedDamage <= 0) {
      return _ResolvedSpikesLifecycle(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    return _ResolvedSpikesLifecycle(
      side: side.withActive(side.active.withDamage(actualDamage)),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
          layers: side.spikesLayers,
        ),
      ],
    );
  }
}

final class _ResolvedStealthRockLifecycle {
  const _ResolvedStealthRockLifecycle({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

final class _ResolvedSpikesLifecycle {
  const _ResolvedSpikesLifecycle({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleSpikesEvent> events;
}
