import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_source_ref.dart';

enum NarrativeOutcomeReachabilityStatus {
  reachable,
  declaredButNotEmitted,
  emittedButUndeclared,
  emittedButUnreachable,
  dialogueOutcomeNotReEmitted,
  outcomeMissing,
  producerMissing,
  producerDuplicate,
  producerInvalid,
  available,
  legacyCompatible,
  legacyBindingInvalid,
}

enum NarrativeOutcomeSourceOrigin {
  scene,
  battle,
  legacyScenario,
  referencedMissing,
}

enum NarrativeOutcomeEventSourceResolutionStatus {
  found,
  unavailable,
  missing,
  ambiguous,
}

@immutable
final class NarrativeOutcomeEventSourceDiagnostic {
  NarrativeOutcomeEventSourceDiagnostic({
    required String code,
    required String message,
    this.outcome,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message');

  final String code;
  final String message;
  final NarrativeOutcomeRef? outcome;

  Map<String, Object?> toDebugJson() => {
        'code': code,
        'message': message,
        if (outcome != null) 'outcome': outcome!.toJson(),
      };
}

@immutable
final class NarrativeOutcomeEventSourceOption {
  NarrativeOutcomeEventSourceOption({
    required this.outcome,
    required String producerLabel,
    required String outcomeLabel,
    required String humanSourceSentence,
    required this.status,
    required this.selectable,
    String? unavailableReason,
    required this.origin,
    required String debugTechnicalLabel,
    List<NarrativeOutcomeEventSourceDiagnostic> diagnostics = const [],
  })  : producerLabel = _identity(producerLabel, 'producerLabel'),
        outcomeLabel = _identity(outcomeLabel, 'outcomeLabel'),
        humanSourceSentence =
            _identity(humanSourceSentence, 'humanSourceSentence'),
        unavailableReason =
            _optionalIdentity(unavailableReason, 'unavailableReason'),
        debugTechnicalLabel =
            _identity(debugTechnicalLabel, 'debugTechnicalLabel'),
        diagnostics = List.unmodifiable(diagnostics) {
    if (selectable && (outcome == null || this.unavailableReason != null)) {
      throw ArgumentError(
        'A selectable outcome requires an identity and no unavailable reason.',
      );
    }
    if (!selectable && this.unavailableReason == null) {
      throw ArgumentError(
        'An unavailable outcome requires a human-readable reason.',
      );
    }
    final statusIsSelectable = switch (status) {
      NarrativeOutcomeReachabilityStatus.reachable ||
      NarrativeOutcomeReachabilityStatus.available ||
      NarrativeOutcomeReachabilityStatus.legacyCompatible =>
        true,
      _ => false,
    };
    if (selectable != statusIsSelectable) {
      throw ArgumentError(
        'Outcome status and selectability must describe the same state.',
      );
    }
  }

  final NarrativeOutcomeRef? outcome;
  final String producerLabel;
  final String outcomeLabel;
  final String humanSourceSentence;
  final NarrativeOutcomeReachabilityStatus status;
  final bool selectable;
  final String? unavailableReason;
  final NarrativeOutcomeSourceOrigin origin;
  final String debugTechnicalLabel;
  final List<NarrativeOutcomeEventSourceDiagnostic> diagnostics;

  Map<String, Object?> toDebugJson() => {
        if (outcome != null) 'outcome': outcome!.toJson(),
        'producerLabel': producerLabel,
        'outcomeLabel': outcomeLabel,
        'humanSourceSentence': humanSourceSentence,
        'status': status.name,
        'selectable': selectable,
        if (unavailableReason != null) 'unavailableReason': unavailableReason,
        'origin': origin.name,
        'debugTechnicalLabel': debugTechnicalLabel,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

@immutable
final class NarrativeOutcomeEventSourceResolution {
  const NarrativeOutcomeEventSourceResolution._({
    required this.status,
    this.option,
  });

  const NarrativeOutcomeEventSourceResolution.found(
    NarrativeOutcomeEventSourceOption option,
  ) : this._(
          status: NarrativeOutcomeEventSourceResolutionStatus.found,
          option: option,
        );

  const NarrativeOutcomeEventSourceResolution.unavailable(
    NarrativeOutcomeEventSourceOption option,
  ) : this._(
          status: NarrativeOutcomeEventSourceResolutionStatus.unavailable,
          option: option,
        );

  const NarrativeOutcomeEventSourceResolution.missing()
      : this._(status: NarrativeOutcomeEventSourceResolutionStatus.missing);

  const NarrativeOutcomeEventSourceResolution.ambiguous()
      : this._(status: NarrativeOutcomeEventSourceResolutionStatus.ambiguous);

  final NarrativeOutcomeEventSourceResolutionStatus status;
  final NarrativeOutcomeEventSourceOption? option;
}

@immutable
final class NarrativeOutcomeEventSourceCatalog {
  NarrativeOutcomeEventSourceCatalog({
    required List<NarrativeOutcomeEventSourceOption> options,
    required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
  })  : options = List.unmodifiable(options),
        diagnostics = List.unmodifiable(diagnostics),
        _optionsByOutcome = _indexOutcomeOptions(options);

  final List<NarrativeOutcomeEventSourceOption> options;
  final List<NarrativeOutcomeEventSourceDiagnostic> diagnostics;
  final Map<NarrativeOutcomeRef, List<NarrativeOutcomeEventSourceOption>>
      _optionsByOutcome;

  List<NarrativeOutcomeEventSourceOption> get selectableOptions =>
      List.unmodifiable(options.where((option) => option.selectable));

  NarrativeOutcomeEventSourceResolution resolve(NarrativeOutcomeRef outcome) {
    final matches = optionsForOutcome(outcome);
    if (matches.isEmpty) {
      return const NarrativeOutcomeEventSourceResolution.missing();
    }
    if (matches.length > 1) {
      return const NarrativeOutcomeEventSourceResolution.ambiguous();
    }
    final option = matches.single;
    return option.selectable
        ? NarrativeOutcomeEventSourceResolution.found(option)
        : NarrativeOutcomeEventSourceResolution.unavailable(option);
  }

  List<NarrativeOutcomeEventSourceOption> optionsForOutcome(
    NarrativeOutcomeRef outcome,
  ) =>
      _optionsByOutcome[outcome] ?? const [];

  Map<String, Object?> toDebugJson() => {
        'options': [for (final option in options) option.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

Map<NarrativeOutcomeRef, List<NarrativeOutcomeEventSourceOption>>
    _indexOutcomeOptions(List<NarrativeOutcomeEventSourceOption> options) {
  final result =
      <NarrativeOutcomeRef, List<NarrativeOutcomeEventSourceOption>>{};
  for (final option in options) {
    final outcome = option.outcome;
    if (outcome == null) continue;
    result.putIfAbsent(outcome, () => []).add(option);
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key:
          List<NarrativeOutcomeEventSourceOption>.unmodifiable(entry.value),
  });
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalIdentity(String? value, String name) {
  if (value == null) return null;
  return _identity(value, name);
}
