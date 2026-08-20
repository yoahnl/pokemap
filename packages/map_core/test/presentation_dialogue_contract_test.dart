import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Contrat des dialogues qui pilotent Presentation — BETA-CIN-068.
///
/// Ces cas sont les tests de contrat PURS : le diagramme d'état couvre les
/// onze situations du ticket et rien d'autre, la fixture Noir/Blanc se
/// déroule légalement transition par transition (retour en arrière compris),
/// les outcomes et violations sont exhaustifs et leurs noms wire figés, et
/// deux gardes structurels interdisent ce que le ticket nomme comme risque :
/// un track Dialogue dans Presentation, et la spécialisation du contrat par
/// l'identité joueur.
void main() {
  group('BETA-CIN-068 the state diagram is the eleven-situation contract', () {
    test('every ticket situation maps to exactly one state', () {
      // lecture, cue, hold, réponse, branche, reprise, stop, skip, erreur,
      // background, disposal — ni plus, ni moins.
      expect(PresentationDialoguePlaybackState.values, hasLength(11));
      expect(
        presentationDialogueLegalTransitions.keys.toSet(),
        PresentationDialoguePlaybackState.values.toSet(),
        reason: 'every state declares its outgoing transitions, even empty',
      );
    });

    test('disposed is the absolute terminal: nothing leaves, all can enter',
        () {
      expect(
        presentationDialogueLegalTransitions[
            PresentationDialoguePlaybackState.disposed],
        isEmpty,
      );
      for (final state in PresentationDialoguePlaybackState.values) {
        if (state == PresentationDialoguePlaybackState.disposed) continue;
        expect(
          presentationDialogueLegalTransitions[state],
          contains(PresentationDialoguePlaybackState.disposed),
          reason: 'disposal must be reachable from $state — a stuck '
              'presentation is a leak',
        );
      }
    });

    test('terminal narrative states only lead to disposal', () {
      for (final state in <PresentationDialoguePlaybackState>[
        PresentationDialoguePlaybackState.stopped,
        PresentationDialoguePlaybackState.skipped,
        PresentationDialoguePlaybackState.failedState,
      ]) {
        expect(
          presentationDialogueLegalTransitions[state],
          <PresentationDialoguePlaybackState>{
            PresentationDialoguePlaybackState.disposed,
          },
          reason: 'no old execution may ever resume after $state',
        );
      }
    });

    test('the hold is entered through a cue and left through a response', () {
      final intoHold = PresentationDialoguePlaybackState.values.where(
        (state) => presentationDialogueLegalTransitions[state]!
            .contains(PresentationDialoguePlaybackState.interactionHold),
      );
      expect(
        intoHold.toSet(),
        <PresentationDialoguePlaybackState>{
          PresentationDialoguePlaybackState.cueSuspended,
          PresentationDialoguePlaybackState.backgrounded,
        },
        reason: 'narrative freeze comes from a cue (or back from lifecycle), '
            'never from thin air',
      );
      expect(
        presentationDialogueLegalTransitions[
            PresentationDialoguePlaybackState.interactionHold],
        contains(PresentationDialoguePlaybackState.responseApplying),
      );
      expect(
        presentationDialogueLegalTransitions[
            PresentationDialoguePlaybackState.interactionHold],
        isNot(contains(PresentationDialoguePlaybackState.playing)),
        reason: 'a hold cannot resume the timeline without a response — that '
            'would be the exact confusion between hold and pause the ticket '
            'forbids',
      );
    });

    test('background suspends everything and restores where it left', () {
      final fromBackground = presentationDialogueLegalTransitions[
          PresentationDialoguePlaybackState.backgrounded]!;
      expect(
        fromBackground,
        containsAll(<PresentationDialoguePlaybackState>[
          PresentationDialoguePlaybackState.playing,
          PresentationDialoguePlaybackState.cueSuspended,
          PresentationDialoguePlaybackState.interactionHold,
        ]),
        reason: 'lifecycle resume returns to the exact suspended situation',
      );
      expect(
        fromBackground,
        isNot(contains(PresentationDialoguePlaybackState.responseApplying)),
        reason: 'a response can never be produced while backgrounded',
      );
    });

    test('branching resolves into resuming, never straight into playing', () {
      expect(
        presentationDialogueLegalTransitions[
            PresentationDialoguePlaybackState.branching],
        <PresentationDialoguePlaybackState>{
          PresentationDialoguePlaybackState.resuming,
          PresentationDialoguePlaybackState.failedState,
          PresentationDialoguePlaybackState.disposed,
        },
        reason: 'a seek/repeat lands on a marker then resumes — skipping the '
            'resume step would replay one-shot effects out of window',
      );
    });
  });

  group('BETA-CIN-068 outcomes and violations are the sealed vocabulary', () {
    test('the six outcomes carry their frozen wire names', () {
      expect(
        {
          for (final outcome in PresentationInteractionOutcomeKind.values)
            outcome.name: outcome.wireName,
        },
        {
          'continueTimeline': 'continue',
          'seekMarker': 'seekMarker',
          'repeatFromMarker': 'repeatFromMarker',
          'stop': 'stop',
          'cancelled': 'cancelled',
          'failed': 'failed',
        },
      );
    });

    test('the fail-closed violations are exactly the named ones', () {
      expect(
        PresentationDialogueContractViolation.values.map((v) => v.name),
        <String>[
          'unknownMarkerReference',
          'nonAwaitableSceneNode',
          'cyclicReference',
          'unknownOutcomePort',
          'transitionBudgetExhausted',
          'staleCueCallback',
          'duplicateOutcome',
        ],
      );
    });

    test('hold track policies are frozen-by-default and ambient-by-authoring',
        () {
      expect(
        PresentationHoldTrackPolicy.values,
        <PresentationHoldTrackPolicy>[
          PresentationHoldTrackPolicy.frozen,
          PresentationHoldTrackPolicy.ambientContinues,
        ],
      );
    });
  });

  group('BETA-CIN-068 the Noir/Blanc fixture walks the diagram legally', () {
    test('every consecutive step is a legal transition', () {
      for (var index = 1;
          index < presentationDialogueReferenceFixture.length;
          index++) {
        final from = presentationDialogueReferenceFixture[index - 1].state;
        final to = presentationDialogueReferenceFixture[index].state;
        expect(
          presentationDialogueLegalTransitions[from],
          contains(to),
          reason: 'fixture step $index ($from → $to) must be legal — the '
              'reference journey IS the proof the diagram covers reality',
        );
      }
    });

    test('the journey covers the negative confirmation with a repeat', () {
      final outcomes = presentationDialogueReferenceFixture
          .map((step) => step.outcome)
          .whereType<PresentationInteractionOutcomeKind>()
          .toList(growable: false);
      expect(
        outcomes,
        contains(PresentationInteractionOutcomeKind.repeatFromMarker),
        reason: 'Non → back to the name entry is the canonical branch',
      );
      expect(
        outcomes.where(
          (outcome) =>
              outcome == PresentationInteractionOutcomeKind.continueTimeline,
        ),
        hasLength(5),
        reason: 'pages, avatar, name, retry name, positive confirmation',
      );
    });

    test('every outcome is followed by its mandatory next state', () {
      // Le garde que la seule légalité des transitions ne donne pas : un
      // repeatFromMarker DOIT traverser branching — y échapper sauterait la
      // résolution par identité de repère et la fenêtre de rejeu.
      expect(
        presentationOutcomeMandatoryNextState.keys.toSet(),
        PresentationInteractionOutcomeKind.values.toSet(),
        reason: 'the mapping is total over the sealed outcome union',
      );
      for (var index = 0;
          index < presentationDialogueReferenceFixture.length - 1;
          index++) {
        final step = presentationDialogueReferenceFixture[index];
        final outcome = step.outcome;
        if (outcome == null) continue;
        expect(
          presentationDialogueReferenceFixture[index + 1].state,
          presentationOutcomeMandatoryNextState[outcome],
          reason: 'fixture step ${index + 1} must honor the mandatory next '
              'state of ${outcome.name}',
        );
      }
      // Cohérence interne : chaque état imposé est atteignable depuis
      // responseApplying dans le diagramme — sinon le contrat se contredit.
      for (final next in presentationOutcomeMandatoryNextState.values) {
        if (next == PresentationDialoguePlaybackState.skipped ||
            next == PresentationDialoguePlaybackState.failedState) {
          continue;
        }
        expect(
          presentationDialogueLegalTransitions[
              PresentationDialoguePlaybackState.responseApplying],
          contains(next),
        );
      }
    });

    test('outcomes only ever appear on responseApplying steps', () {
      for (final step in presentationDialogueReferenceFixture) {
        if (step.outcome != null) {
          expect(
            step.state,
            PresentationDialoguePlaybackState.responseApplying,
            reason: 'an outcome is the exact-once product of a response — '
                'attaching one anywhere else would break the contract',
          );
        }
      }
    });

    test('the journey ends stopped then disposed — the world handoff', () {
      final tail = presentationDialogueReferenceFixture
          .skip(presentationDialogueReferenceFixture.length - 2)
          .map((step) => step.state)
          .toList(growable: false);
      expect(tail, <PresentationDialoguePlaybackState>[
        PresentationDialoguePlaybackState.stopped,
        PresentationDialoguePlaybackState.disposed,
      ]);
    });
  });

  group('BETA-CIN-068 structural guards on the ownership boundary', () {
    test('Presentation has no Dialogue or Prompt track — and never will', () {
      // Le garde du risque principal : le jour où quelqu'un ajoute un track
      // dialogue à Presentation, ce test le nomme et cite le contrat.
      expect(
        PresentationTrackKind.values.map((kind) => kind.name),
        <String>['visual', 'audio', 'caption', 'marker'],
        reason: 'BETA-CIN-068: a marker references an awaitable Scene node; '
            'no Dialogue or Prompt track ever enters Presentation',
      );
    });

    test('the contract never specializes on the player identity', () {
      // Fail-closed lexical : le contrat ne doit contenir aucune trace de la
      // pré-session ni de l'identité joueur — c'est Scene qui les possède.
      final source = File(
        'lib/src/models/presentation_dialogue_contract.dart',
      ).readAsStringSync();
      for (final forbidden in <String>[
        'NewGameDraft',
        'playerName',
        'avatarCharacterId',
        'starterOptionId',
        'ProjectNewGameConfig',
        'preSessionInteraction',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: 'the contract must stay identity-agnostic; "$forbidden" '
              'belongs to Scene, never to the Presentation contract',
        );
      }
    });

    test('every invariant has an owner package and a delivering ticket', () {
      expect(
        presentationDialogueInvariantOwners,
        hasLength(greaterThanOrEqualTo(10)),
      );
      const knownPackages = <String>{
        'packages/map_core',
        'packages/map_runtime',
        'packages/map_player_ui',
        'packages/map_editor',
      };
      final coveredPackages = <String>{};
      final ticketPattern = RegExp(r'^BETA-CIN-0(6[89]|7\d|8[0-6])$');
      for (final owner in presentationDialogueInvariantOwners) {
        expect(knownPackages, contains(owner.ownerPackage));
        expect(
          Directory('../../${owner.ownerPackage}').existsSync(),
          isTrue,
          reason: '${owner.ownerPackage} must exist on disk',
        );
        expect(owner.deliveredBy, matches(ticketPattern));
        coveredPackages.add(owner.ownerPackage);
      }
      expect(
        coveredPackages,
        knownPackages,
        reason: 'the four boundary packages each own at least one invariant',
      );
    });
  });
}
