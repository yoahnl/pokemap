import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_event_wire.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_reference_mapping.dart';

enum NarrativeEventMigrationSourceChoiceKind {
  confirmCandidate,
  explicitReassignment,
}

@immutable
final class NarrativeEventMigrationTargetProposal {
  NarrativeEventMigrationTargetProposal({
    required String name,
    this.legacyPageIndex,
    required List<NarrativeEventCondition> conditions,
    String? sceneId,
    this.reusePolicy,
    required this.priority,
    required int order,
  })  : name = _identity(name, 'name'),
        conditions = List.unmodifiable(conditions),
        sceneId = _optionalIdentity(sceneId, 'sceneId'),
        order = _nonNegative(order, 'order') {
    if (legacyPageIndex != null && legacyPageIndex! < 0) {
      throw ArgumentError.value(
        legacyPageIndex,
        'legacyPageIndex',
        'must be non-negative',
      );
    }
  }

  factory NarrativeEventMigrationTargetProposal.fromJson(Object? json) {
    const path = r'$.sourceChoices[].targets[]';
    final object = NarrativeEventWire.object(json, path: path);
    NarrativeEventWire.expectExactFields(
      object,
      const {
        'name',
        'legacyPageIndex',
        'conditions',
        'sceneId',
        'reusePolicy',
        'priority',
        'order',
      },
      path: path,
    );
    final legacyPageIndex = object['legacyPageIndex'];
    if (legacyPageIndex != null && legacyPageIndex is! int) {
      NarrativeEventWire.invalid(
        'Field "legacyPageIndex" must be an integer or null.',
        path: '$path.legacyPageIndex',
        source: legacyPageIndex,
      );
    }
    final conditions = NarrativeEventWire.requiredList(
      object,
      'conditions',
      path: path,
    );
    return NarrativeEventMigrationTargetProposal(
      name: NarrativeEventWire.requiredIdentity(object, 'name', path: path),
      legacyPageIndex: legacyPageIndex as int?,
      conditions: [
        for (final condition in conditions)
          NarrativeEventCondition.fromJson(condition),
      ],
      sceneId: NarrativeEventWire.optionalIdentity(
        object,
        'sceneId',
        path: path,
      ),
      reusePolicy: _optionalReusePolicy(object, path),
      priority: NarrativeEventWire.requiredInt(object, 'priority', path: path),
      order: NarrativeEventWire.requiredInt(object, 'order', path: path),
    );
  }

  final String name;
  final int? legacyPageIndex;
  final List<NarrativeEventCondition> conditions;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;

  bool get isConfigured => sceneId != null && reusePolicy != null;

  String recordSignature(NarrativeEventSourceRef source) {
    return canonicalizeNarrativeEventJson({
      'name': name,
      'source': source.toJson(),
      'conditions': [for (final condition in conditions) condition.toJson()],
      if (sceneId != null) 'sceneId': sceneId,
      if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
      'priority': priority,
      'order': order,
    });
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (legacyPageIndex != null) 'legacyPageIndex': legacyPageIndex,
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (sceneId != null) 'sceneId': sceneId,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        'priority': priority,
        'order': order,
      };
}

@immutable
final class NarrativeEventMigrationSourceChoice {
  NarrativeEventMigrationSourceChoice._({
    required this.kind,
    required this.provenance,
    required this.source,
    required List<NarrativeEventMigrationTargetProposal> targets,
    String? reassignmentReason,
  })  : targets = List.unmodifiable(targets),
        reassignmentReason = _optionalIdentity(
          reassignmentReason,
          'reassignmentReason',
        ) {
    if (this.targets.isEmpty) {
      throw ArgumentError.value(targets, 'targets', 'must not be empty');
    }
    switch (kind) {
      case NarrativeEventMigrationSourceChoiceKind.confirmCandidate:
        if (this.reassignmentReason != null) {
          throw ArgumentError(
            'Candidate confirmations cannot carry a reassignment reason.',
          );
        }
      case NarrativeEventMigrationSourceChoiceKind.explicitReassignment:
        if (this.reassignmentReason == null) {
          throw ArgumentError(
            'Explicit source reassignments require a non-empty reason.',
          );
        }
    }
  }

  factory NarrativeEventMigrationSourceChoice.confirmCandidate({
    required LegacySourceRef provenance,
    required NarrativeEventSourceRef source,
    required List<NarrativeEventMigrationTargetProposal> targets,
  }) {
    return NarrativeEventMigrationSourceChoice._(
      kind: NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      provenance: provenance,
      source: source,
      targets: targets,
    );
  }

  factory NarrativeEventMigrationSourceChoice.explicitReassignment({
    required LegacySourceRef provenance,
    required NarrativeEventSourceRef source,
    required List<NarrativeEventMigrationTargetProposal> targets,
    required String reason,
  }) {
    return NarrativeEventMigrationSourceChoice._(
      kind: NarrativeEventMigrationSourceChoiceKind.explicitReassignment,
      provenance: provenance,
      source: source,
      targets: targets,
      reassignmentReason: reason,
    );
  }

  factory NarrativeEventMigrationSourceChoice.fromJson(Object? json) {
    const path = r'$.sourceChoices[]';
    final object = NarrativeEventWire.object(json, path: path);
    NarrativeEventWire.expectExactFields(
      object,
      const {
        'kind',
        'provenance',
        'source',
        'targets',
        'reassignmentReason',
      },
      path: path,
    );
    final kind = _choiceKind(
      NarrativeEventWire.requiredString(object, 'kind', path: path),
      '$path.kind',
    );
    final targets = NarrativeEventWire.requiredList(
      object,
      'targets',
      path: path,
    );
    final provenance = LegacySourceRef.fromJson(object['provenance']);
    final source = NarrativeEventSourceRef.fromJson(object['source']);
    final reason = NarrativeEventWire.optionalIdentity(
      object,
      'reassignmentReason',
      path: path,
    );
    final parsedTargets = [
      for (final target in targets)
        NarrativeEventMigrationTargetProposal.fromJson(target),
    ];
    switch (kind) {
      case NarrativeEventMigrationSourceChoiceKind.confirmCandidate:
        if (object.containsKey('reassignmentReason')) {
          NarrativeEventWire.invalid(
            'Candidate confirmations cannot carry reassignmentReason.',
            path: '$path.reassignmentReason',
            source: object['reassignmentReason'],
          );
        }
        return NarrativeEventMigrationSourceChoice.confirmCandidate(
          provenance: provenance,
          source: source,
          targets: parsedTargets,
        );
      case NarrativeEventMigrationSourceChoiceKind.explicitReassignment:
        if (reason == null) {
          NarrativeEventWire.invalid(
            'Explicit source reassignments require reassignmentReason.',
            path: '$path.reassignmentReason',
            source: object,
          );
        }
        return NarrativeEventMigrationSourceChoice.explicitReassignment(
          provenance: provenance,
          source: source,
          targets: parsedTargets,
          reason: reason,
        );
    }
  }

  final NarrativeEventMigrationSourceChoiceKind kind;
  final LegacySourceRef provenance;
  final NarrativeEventSourceRef source;
  final List<NarrativeEventMigrationTargetProposal> targets;
  final String? reassignmentReason;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'provenance': provenance.toJson(),
        'source': source.toJson(),
        'targets': [for (final target in targets) target.toJson()],
        if (reassignmentReason != null)
          'reassignmentReason': reassignmentReason,
      };
}

@immutable
final class NarrativeEventMigrationChoices {
  NarrativeEventMigrationChoices({
    List<NarrativeEventMigrationSourceChoice> sourceChoices = const [],
    List<NarrativeEventReferenceResolutionChoice> referenceChoices = const [],
  })  : sourceChoices = List.unmodifiable(sourceChoices),
        referenceChoices = List.unmodifiable(referenceChoices) {
    final provenances = <LegacySourceRef>{};
    for (final choice in this.sourceChoices) {
      if (!provenances.add(choice.provenance)) {
        throw ArgumentError.value(
          choice.provenance.toJson(),
          'sourceChoices',
          'a provenance can only have one source choice',
        );
      }
    }
    final paths = <String>{};
    for (final choice in this.referenceChoices) {
      if (!paths.add(choice.path)) {
        throw ArgumentError.value(
          choice.path,
          'referenceChoices',
          'a path can only have one reference choice',
        );
      }
    }
  }

  factory NarrativeEventMigrationChoices.empty() =>
      NarrativeEventMigrationChoices();

  final List<NarrativeEventMigrationSourceChoice> sourceChoices;
  final List<NarrativeEventReferenceResolutionChoice> referenceChoices;

  NarrativeEventMigrationSourceChoice? sourceChoiceFor(
    LegacySourceRef provenance,
  ) {
    for (final choice in sourceChoices) {
      if (choice.provenance == provenance) return choice;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'sourceChoices': [
          for (final choice in sourceChoices) choice.toJson(),
        ],
        'referenceChoices': [
          for (final choice in referenceChoices) choice.toJson(),
        ],
      };
}

NarrativeEventMigrationSourceChoiceKind _choiceKind(
  String value,
  String path,
) {
  for (final kind in NarrativeEventMigrationSourceChoiceKind.values) {
    if (kind.name == value) return kind;
  }
  NarrativeEventWire.unsupported(
    'Unsupported source choice kind "$value".',
    path: path,
    source: value,
  );
}

NarrativeEventReusePolicy? _optionalReusePolicy(
  Map<String, Object?> object,
  String path,
) {
  if (!object.containsKey('reusePolicy') || object['reusePolicy'] == null) {
    return null;
  }
  final name = NarrativeEventWire.requiredString(
    object,
    'reusePolicy',
    path: path,
  );
  for (final policy in NarrativeEventReusePolicy.values) {
    if (policy.name == name) return policy;
  }
  NarrativeEventWire.unsupported(
    'Unsupported reuse policy "$name".',
    path: '$path.reusePolicy',
    source: name,
  );
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

int _nonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
  return value;
}
