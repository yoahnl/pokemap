import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// L'union scellée des outcomes de cue — BETA-CIN-070.
///
/// Le contrat est pur : chaque variante porte exactement son kind du contrat
/// BETA-CIN-068, se sérialise sous son nom wire figé, adresse ses
/// destinations par IDENTITÉ de repère (jamais d'offset authoré), et les
/// gardes exact-once et anti-boucle sont des types testables sans runtime.
void main() {
  PresentationCinematicAsset asset() => PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 1000000,
        tracks: [
          PresentationTrack(
            id: 'markers',
            label: 'Repères',
            kind: PresentationTrackKind.marker,
            clips: [
              PresentationMarkerClip(
                id: 'chapter_two',
                startUs: 200000,
                label: 'Chapitre deux',
              ),
              PresentationMarkerClip(
                id: 'ask_name',
                startUs: 500000,
                label: 'Demander le nom',
                markerKind: PresentationMarkerKind.interactionCue,
              ),
            ],
          ),
        ],
      );

  group('BETA-CIN-070 the sealed union is total over the contract kinds', () {
    final representatives = <PresentationInteractionOutcome>[
      const PresentationInteractionOutcome.continueTimeline(),
      PresentationInteractionOutcome.seekMarker(markerId: 'chapter_two'),
      PresentationInteractionOutcome.repeatFromMarker(markerId: 'ask_name'),
      const PresentationInteractionOutcome.stop(),
      const PresentationInteractionOutcome.cancelled(),
      const PresentationInteractionOutcome.failed(diagnosticCode: 'x'),
    ];

    test('every BETA-CIN-068 outcome kind has exactly one variant', () {
      expect(
        representatives.map((outcome) => outcome.kind).toSet(),
        PresentationInteractionOutcomeKind.values.toSet(),
        reason: 'a kind without a variant would be unreachable by handlers; '
            'a variant without a kind would escape the frozen contract',
      );
    });

    test('every variant round-trips through its frozen wire shape', () {
      for (final outcome in representatives) {
        final json = outcome.toJson();
        expect(json['kind'], outcome.kind.wireName);
        expect(
          PresentationInteractionOutcome.fromJson(json),
          outcome,
          reason: '${outcome.kind.name} must survive the wire unchanged',
        );
      }
      expect(
        PresentationInteractionOutcome.fromJson(const {'kind': 'failed'}),
        const PresentationInteractionOutcome.failed(),
      );
    });

    test('an unknown wire kind refuses to load', () {
      expect(
        () => PresentationInteractionOutcome.fromJson(const {'kind': 'jump'}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => PresentationInteractionOutcome.fromJson(const {'kind': 42}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('destinations are addressed by marker identity, never by offset', () {
      final seek =
          PresentationInteractionOutcome.seekMarker(markerId: 'chapter_two');
      expect(
        seek.toJson().keys.toSet(),
        {'kind', 'markerId'},
        reason: 'no field may carry a hand-authored playhead offset',
      );
      expect(
        () => PresentationInteractionOutcome.seekMarker(markerId: '  '),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => PresentationInteractionOutcome.repeatFromMarker(markerId: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => PresentationInteractionOutcome.fromJson(
          const {'kind': 'seekMarker'},
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BETA-CIN-070 destination resolution is derived and fail-closed', () {
    test('seek and repeat resolve the playhead from the marker clip', () {
      for (final outcome in [
        PresentationInteractionOutcome.seekMarker(markerId: 'chapter_two'),
        PresentationInteractionOutcome.repeatFromMarker(
          markerId: 'chapter_two',
        ),
      ]) {
        expect(
          resolvePresentationOutcomeDestination(asset(), outcome),
          const PresentationOutcomeDestinationResolved(
            markerId: 'chapter_two',
            startUs: 200000,
          ),
        );
      }
    });

    test('an interaction cue marker is a legal stable destination too', () {
      expect(
        resolvePresentationOutcomeDestination(
          asset(),
          PresentationInteractionOutcome.repeatFromMarker(
            markerId: 'ask_name',
          ),
        ),
        const PresentationOutcomeDestinationResolved(
          markerId: 'ask_name',
          startUs: 500000,
        ),
      );
    });

    test('an absent destination reports a stable diagnostic code', () {
      final resolution = resolvePresentationOutcomeDestination(
        asset(),
        PresentationInteractionOutcome.seekMarker(markerId: 'ghost'),
      );
      expect(
        resolution,
        const PresentationOutcomeDestinationUnknown(markerId: 'ghost'),
      );
      expect(
        (resolution as PresentationOutcomeDestinationUnknown).diagnosticCode,
        'cinematic.presentation.cue.unknown_seek_destination',
      );
    });

    test('outcomes without a destination resolve to none', () {
      for (final outcome in const [
        PresentationInteractionOutcome.continueTimeline(),
        PresentationInteractionOutcome.stop(),
        PresentationInteractionOutcome.cancelled(),
        PresentationInteractionOutcome.failed(),
      ]) {
        expect(
          resolvePresentationOutcomeDestination(asset(), outcome),
          const PresentationOutcomeDestinationNone(),
        );
      }
    });
  });

  group('BETA-CIN-070 exact-once gate and anti-loop budget', () {
    test('the gate admits one application per cue execution', () {
      final gate = PresentationCueOutcomeGate();
      expect(gate.admit('run:cue:ask_name#1'), isTrue);
      expect(
        gate.admit('run:cue:ask_name#1'),
        isFalse,
        reason: 'a double response, double skip or stale callback must never '
            'produce a second resumption',
      );
      expect(gate.admit('run:cue:ask_name#2'), isTrue);
      expect(() => gate.admit('  '), throwsA(isA<ValidationException>()));
    });

    test('the transition budget exhausts instead of looping forever', () {
      final budget = PresentationTransitionBudget(maxTransitions: 3);
      expect(budget.remaining, 3);
      expect(budget.tryConsume(), isTrue);
      expect(budget.tryConsume(), isTrue);
      expect(budget.tryConsume(), isTrue);
      expect(budget.tryConsume(), isFalse);
      expect(budget.remaining, 0);
      expect(
        PresentationCueOutcomeCodes.transitionBudgetExhausted,
        'cinematic.presentation.cue.transition_budget_exhausted',
      );
    });

    test('the default budget is canonical and a zero budget is refused', () {
      expect(
        PresentationTransitionBudget().maxTransitions,
        defaultPresentationTransitionBudgetPerExecution,
      );
      expect(
        () => PresentationTransitionBudget(maxTransitions: 0),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
