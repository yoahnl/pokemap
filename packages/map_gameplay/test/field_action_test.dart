import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

/// Contrat commun des actions terrain — BETA-SYS-002.
///
/// Le ticket demandait un contrat, et nommait son propre risque : « faux positif
/// si présence de code confondue avec parcours produit certifié ». Surf
/// FONCTIONNAIT avant ce lot ; ce qui manquait, c'était que chaque étape soit un
/// cas particulier du runtime, sans rien pour interdire les dérives.
///
/// Ce fichier couvre les parties pures. Le verrou d'entrée, la sortie de l'eau
/// dans le vrai runtime et le tour de sauvegarde sont dans map_runtime, parce
/// qu'ils ne se démontrent que là.

const GridPos _targetCell = GridPos(x: 4, y: 7);

GameState _surfReadyState() {
  return const GameState(
    saveId: 'field-action',
    party: PlayerParty(members: <PlayerPokemon>[
      PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        level: 30,
        currentHp: 90,
        knownMoveIds: <String>['surf', 'ice_beam'],
      ),
    ]),
    progression: PlayerProgression(
      unlockedFieldAbilities: <FieldAbility>[FieldAbility.surf],
    ),
  );
}

FieldActionTicket _ticket({int revision = 12}) {
  return FieldActionTicket(
    ability: FieldAbility.surf,
    targetCell: _targetCell,
    issuedAtStateRevision: revision,
  );
}

FieldActionCommit _commit({
  required GameState gameState,
  int currentStateRevision = 12,
  int issuedAtStateRevision = 12,
  GridPos confirmedTargetCell = _targetCell,
  bool isTargetWater = true,
}) {
  return commitFieldAction(
    ticket: _ticket(revision: issuedAtStateRevision),
    gameState: gameState,
    currentStateRevision: currentStateRevision,
    confirmedTargetCell: confirmedTargetCell,
    isTargetWater: isTargetWater,
  );
}

void main() {
  group('BETA-SYS-002 the field action contract signs only Surf', () {
    test('Surf is signed and the deferred abilities are named, not silent', () {
      // FG-121 à FG-128 sont DEFERRED. Une capacité non signée doit rendre un
      // verdict NOMMÉ : sans ce cas, ajouter `cut` au vocabulaire produirait une
      // action silencieusement inerte, qui passerait pour implémentée.
      expect(betaSignedFieldAbilities, <FieldAbility>{FieldAbility.surf});

      for (final ability in FieldAbility.values) {
        final evaluation = evaluateFieldAction(
          ability: ability,
          gameState: _surfReadyState(),
          isTargetWater: true,
        );
        if (ability == FieldAbility.surf) {
          expect(evaluation, isA<CanPromptSurf>(), reason: ability.name);
        } else {
          expect(evaluation, isA<FieldActionUnsupported>(), reason: ability.name);
        }
      }
    });

    test('an unsupported ability is refused before anything else', () {
      // L'ordre compte : une capacité DEFERRED ne doit pas atteindre les
      // vérifications d'équipe et de progression, sinon son verdict dépendrait
      // de l'état et deviendrait interprétable comme « presque disponible ».
      final evaluation = evaluateFieldAction(
        ability: FieldAbility.dive,
        gameState: const GameState(saveId: 'empty'),
        isTargetWater: false,
      );

      expect(evaluation, isA<FieldActionUnsupported>());
      expect((evaluation as FieldActionUnsupported).ability, FieldAbility.dive);
    });
  });

  group('BETA-SYS-002 a confirmation is refusable by construction', () {
    test('a fresh confirmation on an unchanged state applies', () {
      final decision = _commit(gameState: _surfReadyState());

      expect(decision, isA<FieldActionApplied>());
      expect(
        (decision as FieldActionApplied).movementMode,
        MovementMode.surf,
      );
    });

    test('a stale state revision is refused', () {
      // Le critère « commande stale ». Avant ce lot, le runtime n'avait qu'un
      // booléen « une confirmation Surf est en attente » : tout ce qui se
      // passait entre l'invitation et le « oui » était invisible au commit.
      final decision = _commit(
        gameState: _surfReadyState(),
        issuedAtStateRevision: 12,
        currentStateRevision: 13,
      );

      expect(decision, isA<FieldActionRefused>());
      expect(
        (decision as FieldActionRefused).refusal,
        FieldActionRefusal.staleStateRevision,
      );
    });

    test('a confirmation on another cell than the one proposed is refused', () {
      final decision = _commit(
        gameState: _surfReadyState(),
        confirmedTargetCell: const GridPos(x: 9, y: 9),
      );

      expect(
        (decision as FieldActionRefused).refusal,
        FieldActionRefusal.targetChanged,
      );
    });

    test('a swimmer who fainted between the prompt and the yes is refused', () {
      // Le critère « Pokémon KO », et c'est LE cas qui justifie de recalculer le
      // verdict au commit plutôt que de faire confiance au jeton. La révision
      // n'a pas bougé ici : un simple contrôle de fraîcheur laisserait passer.
      // Un empoisonnement qui achève le seul nageur pendant que la boîte de
      // dialogue est ouverte est exactement ce scénario.
      final fainted = _surfReadyState().copyWith(
        party: PlayerParty(members: <PlayerPokemon>[
          _surfReadyState().party.members.single.copyWith(currentHp: 0),
        ]),
      );

      final decision = _commit(gameState: fainted);

      expect(decision, isA<FieldActionRefused>());
      final refused = decision as FieldActionRefused;
      expect(refused.refusal, FieldActionRefusal.noLongerAvailable);
      expect(refused.evaluation, isA<MissingSurfCapablePokemon>());
    });

    test('a refusal says which verdict replaced the one that was promised', () {
      // Un refus muet obligerait l'appelant à redeviner. Ici la progression a
      // perdu le déblocage entre l'invitation et la confirmation.
      final locked = _surfReadyState().copyWith(
        progression: const PlayerProgression(),
      );

      final refused = _commit(gameState: locked) as FieldActionRefused;

      expect(refused.evaluation, isA<SurfNotUnlocked>());
    });

    test('a target that stopped being water is refused', () {
      final refused = _commit(
        gameState: _surfReadyState(),
        isTargetWater: false,
      ) as FieldActionRefused;

      expect(refused.refusal, FieldActionRefusal.noLongerAvailable);
      expect(refused.evaluation, isA<NotWater>());
    });
  });

  group('BETA-SYS-002 leaving the water', () {
    test('a step onto land ends the surf without asking', () {
      // La SORTIE, qui n'existait pas : rien n'appelait le retour à la marche en
      // production, donc un joueur ayant surfé une fois surfait sur la terre
      // ferme pour le reste de la partie. La règle de mouvement ne bloque que
      // l'ENTRÉE dans l'eau sans Surf.
      expect(
        resolveMovementModeAfterStep(
          currentMode: MovementMode.surf,
          isWaterCell: false,
        ),
        MovementMode.walk,
      );
    });

    test('a step on water keeps the surf', () {
      expect(
        resolveMovementModeAfterStep(
          currentMode: MovementMode.surf,
          isWaterCell: true,
        ),
        MovementMode.surf,
      );
    });

    test('walking onto water never starts a surf by itself', () {
      // L'entrée reste soumise à confirmation. Une sortie symétrique
      // transformerait la règle de sortie en entrée automatique et rendrait tout
      // le pipeline évaluation → confirmation inutile.
      expect(
        resolveMovementModeAfterStep(
          currentMode: MovementMode.walk,
          isWaterCell: true,
        ),
        MovementMode.walk,
      );
    });
  });

  group('BETA-SYS-002 preview and runtime agree on what they share', () {
    test('the preview assumes surf exactly when the ability is unlocked', () {
      expect(
        optimisticPreviewMovementMode(
          unlockedFieldAbilities: const <FieldAbility>{FieldAbility.surf},
        ),
        MovementMode.surf,
      );
      expect(
        optimisticPreviewMovementMode(
          unlockedFieldAbilities: const <FieldAbility>{FieldAbility.cut},
        ),
        MovementMode.walk,
      );
    });

    test('the preview is deliberately more permissive than the runtime', () {
      // DIVERGENCE ASSUMÉE, épinglée pour qu'elle ne passe pas pour une parité.
      //
      // Une analyse de portée symbolique ne connaît que les capacités
      // débloquées, PAS l'équipe : NarrativeSymbolicState n'en porte aucune. Elle
      // ne peut donc pas appliquer la condition « un Pokémon non K.O. connaît la
      // capacité » que le runtime exige.
      //
      // C'est le bon choix pour un validateur de contenu — il ne doit pas
      // déclarer une zone inatteignable à cause d'une équipe de test — mais ce
      // n'est pas l'équivalence, et lire « atteignable » comme « le joueur peut
      // le faire » serait faux.
      const unlockedButNoSwimmer = GameState(
        saveId: 'no-swimmer',
        party: PlayerParty(members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: <String>['thunderbolt'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: <FieldAbility>[FieldAbility.surf],
        ),
      );

      expect(
        optimisticPreviewMovementMode(
          unlockedFieldAbilities:
              unlockedButNoSwimmer.progression.unlockedFieldAbilities.toSet(),
        ),
        MovementMode.surf,
        reason: 'the preview declares the water reachable',
      );
      expect(
        evaluateFieldAction(
          ability: FieldAbility.surf,
          gameState: unlockedButNoSwimmer,
          isTargetWater: true,
        ),
        isA<MissingSurfCapablePokemon>(),
        reason: 'the runtime refuses it, and that gap is on purpose',
      );
    });
  });
}
