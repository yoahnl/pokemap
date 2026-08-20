import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'presentation_cinematic_asset.dart';
import 'presentation_dialogue_contract.dart';

/// The sealed response union of a Presentation interaction cue —
/// BETA-CIN-070.
///
/// A cue handler no longer completes with a bare `Future<void>`: it returns
/// exactly one terminal [PresentationInteractionOutcome], and that value is
/// the whole decision. Seek and repeat destinations are carried by marker
/// IDENTITY — never by a hand-authored raw offset: the playhead position of
/// a destination is always derived from the marker clip by
/// [resolvePresentationOutcomeDestination]. Exact-once application, stale
/// callbacks and the anti-loop budget are enforced with
/// [PresentationCueOutcomeGate] and [PresentationTransitionBudget]; the
/// runtime routing of resolved destinations lands with BETA-CIN-072 and is
/// deliberately absent here.
sealed class PresentationInteractionOutcome {
  const PresentationInteractionOutcome();

  const factory PresentationInteractionOutcome.continueTimeline() =
      PresentationContinueTimelineOutcome;

  factory PresentationInteractionOutcome.seekMarker({
    required String markerId,
  }) = PresentationSeekMarkerOutcome;

  factory PresentationInteractionOutcome.repeatFromMarker({
    required String markerId,
  }) = PresentationRepeatFromMarkerOutcome;

  const factory PresentationInteractionOutcome.stop() =
      PresentationStopOutcome;

  const factory PresentationInteractionOutcome.cancelled() =
      PresentationCancelledOutcome;

  const factory PresentationInteractionOutcome.failed({
    String? diagnosticCode,
  }) = PresentationFailedOutcome;

  factory PresentationInteractionOutcome.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'];
    if (rawKind is! String) {
      throw const ValidationException(
        'PresentationInteractionOutcome.kind must be a wire name string',
      );
    }
    final kind = PresentationInteractionOutcomeKind.values
        .where((candidate) => candidate.wireName == rawKind)
        .firstOrNull;
    return switch (kind) {
      PresentationInteractionOutcomeKind.continueTimeline =>
        const PresentationContinueTimelineOutcome(),
      PresentationInteractionOutcomeKind.seekMarker =>
        PresentationSeekMarkerOutcome(markerId: _readMarkerId(json)),
      PresentationInteractionOutcomeKind.repeatFromMarker =>
        PresentationRepeatFromMarkerOutcome(markerId: _readMarkerId(json)),
      PresentationInteractionOutcomeKind.stop =>
        const PresentationStopOutcome(),
      PresentationInteractionOutcomeKind.cancelled =>
        const PresentationCancelledOutcome(),
      PresentationInteractionOutcomeKind.failed => PresentationFailedOutcome(
          diagnosticCode: switch (json['diagnosticCode']) {
            final String code when code.trim().isNotEmpty => code,
            _ => null,
          },
        ),
      null => throw ValidationException(
          'PresentationInteractionOutcome.kind "$rawKind" is not one of the '
          'sealed wire names',
        ),
    };
  }

  PresentationInteractionOutcomeKind get kind;

  Map<String, dynamic> toJson() => {'kind': kind.wireName};

  static String _readMarkerId(Map<String, dynamic> json) {
    final markerId = json['markerId'];
    if (markerId is! String || markerId.trim().isEmpty) {
      throw const ValidationException(
        'PresentationInteractionOutcome destinations are addressed by marker '
        'identity: markerId is required and must not be blank',
      );
    }
    return markerId;
  }
}

@immutable
final class PresentationContinueTimelineOutcome
    extends PresentationInteractionOutcome {
  const PresentationContinueTimelineOutcome();

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.continueTimeline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PresentationContinueTimelineOutcome;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class PresentationSeekMarkerOutcome
    extends PresentationInteractionOutcome {
  PresentationSeekMarkerOutcome({required this.markerId}) {
    if (markerId.trim().isEmpty) {
      throw const ValidationException(
        'PresentationSeekMarkerOutcome.markerId must not be blank',
      );
    }
  }

  final String markerId;

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.seekMarker;

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.wireName,
        'markerId': markerId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationSeekMarkerOutcome && other.markerId == markerId;

  @override
  int get hashCode => Object.hash(kind, markerId);
}

@immutable
final class PresentationRepeatFromMarkerOutcome
    extends PresentationInteractionOutcome {
  PresentationRepeatFromMarkerOutcome({required this.markerId}) {
    if (markerId.trim().isEmpty) {
      throw const ValidationException(
        'PresentationRepeatFromMarkerOutcome.markerId must not be blank',
      );
    }
  }

  final String markerId;

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.repeatFromMarker;

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.wireName,
        'markerId': markerId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationRepeatFromMarkerOutcome &&
          other.markerId == markerId;

  @override
  int get hashCode => Object.hash(kind, markerId);
}

@immutable
final class PresentationStopOutcome extends PresentationInteractionOutcome {
  const PresentationStopOutcome();

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.stop;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PresentationStopOutcome;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class PresentationCancelledOutcome
    extends PresentationInteractionOutcome {
  const PresentationCancelledOutcome();

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.cancelled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PresentationCancelledOutcome;

  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class PresentationFailedOutcome extends PresentationInteractionOutcome {
  const PresentationFailedOutcome({this.diagnosticCode});

  final String? diagnosticCode;

  @override
  PresentationInteractionOutcomeKind get kind =>
      PresentationInteractionOutcomeKind.failed;

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind.wireName,
        if (diagnosticCode != null) 'diagnosticCode': diagnosticCode,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationFailedOutcome &&
          other.diagnosticCode == diagnosticCode;

  @override
  int get hashCode => Object.hash(kind, diagnosticCode);
}

/// Stable diagnostic codes of the cue outcome pipeline.
abstract final class PresentationCueOutcomeCodes {
  static const unknownSeekDestination =
      'cinematic.presentation.cue.unknown_seek_destination';
  static const seekRoutingUnavailable =
      'cinematic.presentation.cue.seek_routing_unavailable';
  static const transitionBudgetExhausted =
      'cinematic.presentation.cue.transition_budget_exhausted';
  static const staleOutcome = 'cinematic.presentation.cue.stale_outcome';
  static const duplicateOutcome =
      'cinematic.presentation.cue.duplicate_outcome';
}

/// Resolution of an outcome's destination against one Presentation asset.
///
/// Only seek and repeat carry a destination. The resolved playhead position
/// is DERIVED from the marker clip: authors address markers, never offsets.
sealed class PresentationOutcomeDestinationResolution {
  const PresentationOutcomeDestinationResolution();
}

@immutable
final class PresentationOutcomeDestinationNone
    extends PresentationOutcomeDestinationResolution {
  const PresentationOutcomeDestinationNone();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PresentationOutcomeDestinationNone;

  @override
  int get hashCode => (PresentationOutcomeDestinationNone).hashCode;
}

@immutable
final class PresentationOutcomeDestinationResolved
    extends PresentationOutcomeDestinationResolution {
  const PresentationOutcomeDestinationResolved({
    required this.markerId,
    required this.startUs,
  });

  final String markerId;
  final int startUs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationOutcomeDestinationResolved &&
          other.markerId == markerId &&
          other.startUs == startUs;

  @override
  int get hashCode => Object.hash(markerId, startUs);
}

@immutable
final class PresentationOutcomeDestinationUnknown
    extends PresentationOutcomeDestinationResolution {
  const PresentationOutcomeDestinationUnknown({required this.markerId});

  final String markerId;

  String get diagnosticCode =>
      PresentationCueOutcomeCodes.unknownSeekDestination;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationOutcomeDestinationUnknown &&
          other.markerId == markerId;

  @override
  int get hashCode => markerId.hashCode;
}

PresentationOutcomeDestinationResolution
    resolvePresentationOutcomeDestination(
  PresentationCinematicAsset asset,
  PresentationInteractionOutcome outcome,
) {
  final markerId = switch (outcome) {
    PresentationSeekMarkerOutcome(markerId: final id) => id,
    PresentationRepeatFromMarkerOutcome(markerId: final id) => id,
    PresentationContinueTimelineOutcome() ||
    PresentationStopOutcome() ||
    PresentationCancelledOutcome() ||
    PresentationFailedOutcome() =>
      null,
  };
  if (markerId == null) return const PresentationOutcomeDestinationNone();
  for (final track in asset.tracks) {
    for (final clip in track.clips) {
      if (clip is PresentationMarkerClip && clip.id == markerId) {
        return PresentationOutcomeDestinationResolved(
          markerId: markerId,
          startUs: clip.startUs,
        );
      }
    }
  }
  return PresentationOutcomeDestinationUnknown(markerId: markerId);
}

/// Anti-loop guard of one Presentation execution: every applied seek or
/// repeat consumes one transition, and an exhausted budget must terminate
/// the execution with [PresentationCueOutcomeCodes.transitionBudgetExhausted]
/// instead of looping forever. One budget instance belongs to exactly one
/// execution — replays start fresh.
const defaultPresentationTransitionBudgetPerExecution = 8;

final class PresentationTransitionBudget {
  PresentationTransitionBudget({
    this.maxTransitions = defaultPresentationTransitionBudgetPerExecution,
  }) {
    if (maxTransitions < 1) {
      throw const ValidationException(
        'PresentationTransitionBudget.maxTransitions must be at least 1',
      );
    }
  }

  final int maxTransitions;
  var _consumed = 0;

  int get remaining => maxTransitions - _consumed;

  bool tryConsume() {
    if (_consumed >= maxTransitions) return false;
    _consumed += 1;
    return true;
  }
}

/// Exact-once admission of cue outcomes, keyed by cue execution identity.
///
/// The first admission wins; every later admission of the same cue
/// execution — a double response, a double skip, a stale callback racing a
/// disposal — is refused and must be ignored by the caller without moving
/// the playhead or producing a second resumption.
final class PresentationCueOutcomeGate {
  final Set<String> _admittedCueExecutionIds = <String>{};

  bool admit(String cueExecutionId) {
    if (cueExecutionId.trim().isEmpty) {
      throw const ValidationException(
        'PresentationCueOutcomeGate.admit requires a cue execution id',
      );
    }
    return _admittedCueExecutionIds.add(cueExecutionId);
  }
}
