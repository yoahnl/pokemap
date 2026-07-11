import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'legacy_event_migration_models.dart';

String computeNarrativeEventMigrationTargetKey({
  required LegacySourceRef provenance,
  required String targetSignature,
}) {
  final signature = _identity(targetSignature, 'targetSignature');
  return 'met_${narrativeEventCanonicalSha256({
        'provenance': provenance.toJson(),
        'targetSignature': signature,
      })}';
}

enum NarrativeEventReferenceDomain {
  progression,
  condition,
  worldRule,
  consequence,
  save,
}

enum NarrativeEventReferenceMappingStatus {
  mapped,
  readyForAllocation,
  preservedTombstone,
  requiresChoice,
  cancelled,
  blocked,
}

enum NarrativeEventReferenceCollisionDecision {
  consumeAllTargets,
  selectedTargets,
  cancel,
}

enum NarrativeEventPageMappingStatus { mapped, preservedLegacy }

@immutable
final class NarrativeEventReferenceCatalog {
  NarrativeEventReferenceCatalog({
    List<LegacyEventReference> progression = const [],
    List<LegacyEventReference> conditions = const [],
    List<LegacyEventReference> worldRules = const [],
    List<LegacyEventReference> consequences = const [],
    List<LegacyEventReference> saves = const [],
  })  : progression = List.unmodifiable(progression),
        conditions = List.unmodifiable(conditions),
        worldRules = List.unmodifiable(worldRules),
        consequences = List.unmodifiable(consequences),
        saves = List.unmodifiable(saves) {
    final paths = <String>{};
    for (final reference in all) {
      if (!paths.add(reference.path)) {
        throw ArgumentError.value(
          reference.path,
          'references',
          'reference paths must be unique across the catalog',
        );
      }
    }
    _requireReferenceKinds(
      this.progression,
      'progression',
      const {LegacyEventReferenceKind.consumedEventState},
    );
    _requireReferenceKinds(
      this.conditions,
      'conditions',
      const {LegacyEventReferenceKind.scriptCondition},
    );
    _requireReferenceKinds(
      this.worldRules,
      'worldRules',
      const {
        LegacyEventReferenceKind.worldRuleSource,
        LegacyEventReferenceKind.worldRuleTarget,
      },
    );
    _requireReferenceKinds(
      this.consequences,
      'consequences',
      const {
        LegacyEventReferenceKind.sceneConsequence,
        LegacyEventReferenceKind.scenarioNodeBinding,
        LegacyEventReferenceKind.scriptCommand,
        LegacyEventReferenceKind.metadata,
        LegacyEventReferenceKind.validatorDiagnostic,
      },
    );
    _requireReferenceKinds(
      this.saves,
      'saves',
      const {LegacyEventReferenceKind.consumedEventState},
    );
  }

  factory NarrativeEventReferenceCatalog.empty() =>
      NarrativeEventReferenceCatalog();

  factory NarrativeEventReferenceCatalog.fromJson(Object? json) {
    final object = _object(json, 'referenceCatalog');
    return NarrativeEventReferenceCatalog(
      progression: _referenceList(object['progression'], 'progression'),
      conditions: _referenceList(object['conditions'], 'conditions'),
      worldRules: _referenceList(object['worldRules'], 'worldRules'),
      consequences: _referenceList(object['consequences'], 'consequences'),
      saves: _referenceList(object['saves'], 'saves'),
    );
  }

  final List<LegacyEventReference> progression;
  final List<LegacyEventReference> conditions;
  final List<LegacyEventReference> worldRules;
  final List<LegacyEventReference> consequences;
  final List<LegacyEventReference> saves;

  List<LegacyEventReference> get all => List.unmodifiable([
        ...progression,
        ...conditions,
        ...worldRules,
        ...consequences,
        ...saves,
      ]);

  bool get isEmpty => all.isEmpty;

  Map<String, Object?> toJson() => {
        'progression': [for (final value in progression) value.toJson()],
        'conditions': [for (final value in conditions) value.toJson()],
        'worldRules': [for (final value in worldRules) value.toJson()],
        'consequences': [for (final value in consequences) value.toJson()],
        'saves': [for (final value in saves) value.toJson()],
      };
}

void _requireReferenceKinds(
  List<LegacyEventReference> references,
  String domain,
  Set<LegacyEventReferenceKind> allowed,
) {
  for (final reference in references) {
    if (!allowed.contains(reference.kind)) {
      throw ArgumentError.value(
        reference.kind,
        domain,
        'reference kind is incompatible with the catalog domain',
      );
    }
  }
}

@immutable
final class NarrativeEventReferenceResolutionChoice {
  NarrativeEventReferenceResolutionChoice({
    required String path,
    required this.decision,
    List<String> selectedTargetEventIds = const [],
    List<String> selectedTargetKeys = const [],
  })  : path = _identity(path, 'path'),
        selectedTargetEventIds = _sortedUniqueIds(
          selectedTargetEventIds,
          'selectedTargetEventIds',
        ),
        selectedTargetKeys = _sortedUniqueIds(
          selectedTargetKeys,
          'selectedTargetKeys',
        ) {
    final selectionCount = (this.selectedTargetEventIds.isEmpty ? 0 : 1) +
        (this.selectedTargetKeys.isEmpty ? 0 : 1);
    if (decision == NarrativeEventReferenceCollisionDecision.selectedTargets &&
        selectionCount != 1) {
      throw ArgumentError.value(
        [selectedTargetEventIds, selectedTargetKeys],
        'selectedTargets',
        'must use exactly one non-empty ID or stable-key selection',
      );
    }
    if (decision != NarrativeEventReferenceCollisionDecision.selectedTargets &&
        selectionCount != 0) {
      throw ArgumentError.value(
        [selectedTargetEventIds, selectedTargetKeys],
        'selectedTargets',
        'must be empty unless selectedTargets is used',
      );
    }
  }

  factory NarrativeEventReferenceResolutionChoice.fromJson(Object? json) {
    final object = _object(json, 'referenceChoice');
    return NarrativeEventReferenceResolutionChoice(
      path: _string(object, 'path'),
      decision: _enumByName(
        NarrativeEventReferenceCollisionDecision.values,
        _string(object, 'decision'),
        'decision',
      ),
      selectedTargetEventIds: _stringList(
        object['selectedTargetEventIds'],
        'selectedTargetEventIds',
      ),
      selectedTargetKeys: object.containsKey('selectedTargetKeys')
          ? _stringList(object['selectedTargetKeys'], 'selectedTargetKeys')
          : const [],
    );
  }

  final String path;
  final NarrativeEventReferenceCollisionDecision decision;
  final List<String> selectedTargetEventIds;
  final List<String> selectedTargetKeys;

  Map<String, Object?> toJson() => {
        'path': path,
        'decision': decision.name,
        'selectedTargetEventIds': selectedTargetEventIds,
        if (selectedTargetKeys.isNotEmpty)
          'selectedTargetKeys': selectedTargetKeys,
      };
}

@immutable
final class NarrativeEventIdMapping {
  NarrativeEventIdMapping({
    required this.provenance,
    required String legacyId,
    required List<String> targetEventIds,
  })  : legacyId = _identity(legacyId, 'legacyId'),
        targetEventIds = _sortedUniqueIds(
          targetEventIds,
          'targetEventIds',
          requireNotEmpty: true,
        );

  factory NarrativeEventIdMapping.fromJson(Object? json) {
    final object = _object(json, 'idMapping');
    return NarrativeEventIdMapping(
      provenance: LegacySourceRef.fromJson(object['provenance']),
      legacyId: _string(object, 'legacyId'),
      targetEventIds: _stringList(
        object['targetEventIds'],
        'targetEventIds',
      ),
    );
  }

  final LegacySourceRef provenance;
  final String legacyId;
  final List<String> targetEventIds;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'legacyId': legacyId,
        'targetEventIds': targetEventIds,
      };
}

@immutable
final class NarrativeEventPageMapping {
  NarrativeEventPageMapping({
    required this.provenance,
    required int pageIndex,
    required this.pageNumber,
    required this.status,
    String? targetEventId,
    String? sceneId,
    required Map<String, Object?> preservedPageJson,
  })  : pageIndex = _nonNegative(pageIndex, 'pageIndex'),
        targetEventId = _optionalIdentity(targetEventId, 'targetEventId'),
        sceneId = _optionalIdentity(sceneId, 'sceneId'),
        preservedPageJson = _freezeMap(preservedPageJson) {
    if (status == NarrativeEventPageMappingStatus.mapped &&
        this.targetEventId == null) {
      throw ArgumentError('A mapped page requires targetEventId.');
    }
    if (status == NarrativeEventPageMappingStatus.preservedLegacy &&
        this.targetEventId != null) {
      throw ArgumentError(
        'A preserved legacy page cannot claim a targetEventId.',
      );
    }
  }

  factory NarrativeEventPageMapping.fromJson(Object? json) {
    final object = _object(json, 'pageMapping');
    return NarrativeEventPageMapping(
      provenance: LegacySourceRef.fromJson(object['provenance']),
      pageIndex: _integer(object, 'pageIndex'),
      pageNumber: _integer(object, 'pageNumber'),
      status: _enumByName(
        NarrativeEventPageMappingStatus.values,
        _string(object, 'status'),
        'status',
      ),
      targetEventId: _optionalString(object['targetEventId'], 'targetEventId'),
      sceneId: _optionalString(object['sceneId'], 'sceneId'),
      preservedPageJson: _object(
        object['preservedPageJson'],
        'preservedPageJson',
      ),
    );
  }

  final LegacySourceRef provenance;
  final int pageIndex;
  final int pageNumber;
  final NarrativeEventPageMappingStatus status;
  final String? targetEventId;
  final String? sceneId;
  final Map<String, Object?> preservedPageJson;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'pageIndex': pageIndex,
        'pageNumber': pageNumber,
        'status': status.name,
        if (targetEventId != null) 'targetEventId': targetEventId,
        if (sceneId != null) 'sceneId': sceneId,
        'preservedPageJson': preservedPageJson,
      };
}

@immutable
final class NarrativeEventReferenceMapping {
  NarrativeEventReferenceMapping({
    required this.domain,
    required this.kind,
    required String path,
    required String legacyEventId,
    String? mapId,
    required List<LegacySourceRef> candidateProvenances,
    required List<String> targetEventIds,
    List<String> availableTargetKeys = const [],
    required this.status,
    this.decision,
  })  : path = _identity(path, 'path'),
        legacyEventId = _identity(legacyEventId, 'legacyEventId'),
        mapId = _optionalIdentity(mapId, 'mapId'),
        candidateProvenances = _sortedProvenances(candidateProvenances),
        targetEventIds = _sortedUniqueIds(
          targetEventIds,
          'targetEventIds',
        ),
        availableTargetKeys = _sortedUniqueIds(
          availableTargetKeys,
          'availableTargetKeys',
        ) {
    if (status == NarrativeEventReferenceMappingStatus.mapped &&
        this.targetEventIds.isEmpty) {
      throw ArgumentError('A mapped reference requires targetEventIds.');
    }
    if (status != NarrativeEventReferenceMappingStatus.mapped &&
        this.targetEventIds.isNotEmpty) {
      throw ArgumentError(
        'Only mapped references may expose targetEventIds.',
      );
    }
  }

  factory NarrativeEventReferenceMapping.fromJson(Object? json) {
    final object = _object(json, 'referenceMapping');
    final decisionName = _optionalString(object['decision'], 'decision');
    return NarrativeEventReferenceMapping(
      domain: _enumByName(
        NarrativeEventReferenceDomain.values,
        _string(object, 'domain'),
        'domain',
      ),
      kind: _enumByName(
        LegacyEventReferenceKind.values,
        _string(object, 'kind'),
        'kind',
      ),
      path: _string(object, 'path'),
      legacyEventId: _string(object, 'legacyEventId'),
      mapId: _optionalString(object['mapId'], 'mapId'),
      candidateProvenances: _list(
        object['candidateProvenances'],
        'candidateProvenances',
      ).map(LegacySourceRef.fromJson).toList(),
      targetEventIds: _stringList(
        object['targetEventIds'],
        'targetEventIds',
      ),
      availableTargetKeys: object.containsKey('availableTargetKeys')
          ? _stringList(
              object['availableTargetKeys'],
              'availableTargetKeys',
            )
          : const [],
      status: _enumByName(
        NarrativeEventReferenceMappingStatus.values,
        _string(object, 'status'),
        'status',
      ),
      decision: decisionName == null
          ? null
          : _enumByName(
              NarrativeEventReferenceCollisionDecision.values,
              decisionName,
              'decision',
            ),
    );
  }

  final NarrativeEventReferenceDomain domain;
  final LegacyEventReferenceKind kind;
  final String path;
  final String legacyEventId;
  final String? mapId;
  final List<LegacySourceRef> candidateProvenances;
  final List<String> targetEventIds;
  final List<String> availableTargetKeys;
  final NarrativeEventReferenceMappingStatus status;
  final NarrativeEventReferenceCollisionDecision? decision;

  Map<String, Object?> toJson() => {
        'domain': domain.name,
        'kind': kind.name,
        'path': path,
        'legacyEventId': legacyEventId,
        if (mapId != null) 'mapId': mapId,
        'candidateProvenances': [
          for (final provenance in candidateProvenances) provenance.toJson(),
        ],
        'targetEventIds': targetEventIds,
        if (availableTargetKeys.isNotEmpty)
          'availableTargetKeys': availableTargetKeys,
        'status': status.name,
        if (decision != null) 'decision': decision!.name,
      };
}

@immutable
final class NarrativeEventReferenceMappings {
  NarrativeEventReferenceMappings({
    List<NarrativeEventIdMapping> idMappings = const [],
    List<NarrativeEventPageMapping> pageMappings = const [],
    List<NarrativeEventReferenceMapping> progressionMappings = const [],
    List<NarrativeEventReferenceMapping> conditionMappings = const [],
    List<NarrativeEventReferenceMapping> worldRuleMappings = const [],
    List<NarrativeEventReferenceMapping> consequenceMappings = const [],
    List<NarrativeEventReferenceMapping> saveMappings = const [],
  })  : idMappings = List.unmodifiable(idMappings),
        pageMappings = List.unmodifiable(pageMappings),
        progressionMappings = List.unmodifiable(progressionMappings),
        conditionMappings = List.unmodifiable(conditionMappings),
        worldRuleMappings = List.unmodifiable(worldRuleMappings),
        consequenceMappings = List.unmodifiable(consequenceMappings),
        saveMappings = List.unmodifiable(saveMappings);

  factory NarrativeEventReferenceMappings.fromJson(Object? json) {
    final object = _object(json, 'referenceMappings');
    return NarrativeEventReferenceMappings(
      idMappings: _list(object['ids'], 'ids')
          .map(NarrativeEventIdMapping.fromJson)
          .toList(),
      pageMappings: _list(object['pages'], 'pages')
          .map(NarrativeEventPageMapping.fromJson)
          .toList(),
      progressionMappings: _mappingList(object, 'progression'),
      conditionMappings: _mappingList(object, 'conditions'),
      worldRuleMappings: _mappingList(object, 'worldRules'),
      consequenceMappings: _mappingList(object, 'consequences'),
      saveMappings: _mappingList(object, 'saves'),
    );
  }

  final List<NarrativeEventIdMapping> idMappings;
  final List<NarrativeEventPageMapping> pageMappings;
  final List<NarrativeEventReferenceMapping> progressionMappings;
  final List<NarrativeEventReferenceMapping> conditionMappings;
  final List<NarrativeEventReferenceMapping> worldRuleMappings;
  final List<NarrativeEventReferenceMapping> consequenceMappings;
  final List<NarrativeEventReferenceMapping> saveMappings;

  List<NarrativeEventReferenceMapping> get allReferenceMappings =>
      List.unmodifiable([
        ...progressionMappings,
        ...conditionMappings,
        ...worldRuleMappings,
        ...consequenceMappings,
        ...saveMappings,
      ]);

  bool get hasBlockingMappings => allReferenceMappings.any(
        (mapping) =>
            mapping.status != NarrativeEventReferenceMappingStatus.mapped &&
            mapping.status !=
                NarrativeEventReferenceMappingStatus.readyForAllocation &&
            mapping.status !=
                NarrativeEventReferenceMappingStatus.preservedTombstone,
      );

  Map<String, Object?> toJson() => {
        'ids': [for (final value in idMappings) value.toJson()],
        'pages': [for (final value in pageMappings) value.toJson()],
        'progression': [
          for (final value in progressionMappings) value.toJson(),
        ],
        'conditions': [
          for (final value in conditionMappings) value.toJson(),
        ],
        'worldRules': [
          for (final value in worldRuleMappings) value.toJson(),
        ],
        'consequences': [
          for (final value in consequenceMappings) value.toJson(),
        ],
        'saves': [for (final value in saveMappings) value.toJson()],
      };
}

NarrativeEventReferenceMappings buildNarrativeEventReferenceMappings({
  required Map<LegacySourceRef, List<String>> targetEventIdsByProvenance,
  Map<LegacySourceRef, Map<String, String>> targetEventIdsByTargetKey =
      const {},
  required NarrativeEventReferenceCatalog references,
  List<NarrativeEventReferenceResolutionChoice> choices = const [],
  List<NarrativeEventIdMapping> idMappings = const [],
  List<NarrativeEventPageMapping> pageMappings = const [],
}) {
  final choicesByPath = <String, NarrativeEventReferenceResolutionChoice>{};
  for (final choice in choices) {
    if (choicesByPath.containsKey(choice.path)) {
      throw ArgumentError.value(
        choice.path,
        'choices',
        'a reference path can only have one resolution choice',
      );
    }
    choicesByPath[choice.path] = choice;
  }

  List<NarrativeEventReferenceMapping> resolve(
    NarrativeEventReferenceDomain domain,
    List<LegacyEventReference> source,
  ) {
    final sorted = List<LegacyEventReference>.of(source)
      ..sort((left, right) => left.path.compareTo(right.path));
    return [
      for (final reference in sorted)
        _resolveReference(
          domain: domain,
          reference: reference,
          targets: targetEventIdsByProvenance,
          keyedTargets: targetEventIdsByTargetKey,
          choice: choicesByPath[reference.path],
        ),
    ];
  }

  return NarrativeEventReferenceMappings(
    idMappings: idMappings,
    pageMappings: pageMappings,
    progressionMappings: resolve(
      NarrativeEventReferenceDomain.progression,
      references.progression,
    ),
    conditionMappings: resolve(
      NarrativeEventReferenceDomain.condition,
      references.conditions,
    ),
    worldRuleMappings: resolve(
      NarrativeEventReferenceDomain.worldRule,
      references.worldRules,
    ),
    consequenceMappings: resolve(
      NarrativeEventReferenceDomain.consequence,
      references.consequences,
    ),
    saveMappings: resolve(
      NarrativeEventReferenceDomain.save,
      references.saves,
    ),
  );
}

NarrativeEventReferenceMapping _resolveReference({
  required NarrativeEventReferenceDomain domain,
  required LegacyEventReference reference,
  required Map<LegacySourceRef, List<String>> targets,
  required Map<LegacySourceRef, Map<String, String>> keyedTargets,
  required NarrativeEventReferenceResolutionChoice? choice,
}) {
  final available = <String>{};
  final availableByKey = <String, String>{};
  var allCandidatesMapped = true;
  for (final provenance in reference.candidateProvenances) {
    final candidateTargets = targets[provenance] ?? const <String>[];
    if (candidateTargets.isEmpty) allCandidatesMapped = false;
    available.addAll(candidateTargets);
    availableByKey.addAll(keyedTargets[provenance] ?? const {});
  }
  final sortedAvailable = available.toList()..sort();
  final availableTargetKeys = availableByKey.keys.toList()..sort();

  NarrativeEventReferenceMapping result(
    NarrativeEventReferenceMappingStatus status, {
    List<String> targetEventIds = const [],
    NarrativeEventReferenceCollisionDecision? decision,
  }) {
    return NarrativeEventReferenceMapping(
      domain: domain,
      kind: reference.kind,
      path: reference.path,
      legacyEventId: reference.legacyEventId,
      mapId: reference.mapId,
      candidateProvenances: reference.candidateProvenances,
      targetEventIds: targetEventIds,
      availableTargetKeys: availableTargetKeys,
      status: status,
      decision: decision,
    );
  }

  if (reference.candidateProvenances.isEmpty) {
    if (domain == NarrativeEventReferenceDomain.progression ||
        domain == NarrativeEventReferenceDomain.save) {
      return result(
        NarrativeEventReferenceMappingStatus.preservedTombstone,
      );
    }
    return result(NarrativeEventReferenceMappingStatus.blocked);
  }

  if (reference.candidateProvenances.length == 1 && choice == null) {
    if (sortedAvailable.isEmpty) {
      return result(NarrativeEventReferenceMappingStatus.blocked);
    }
    if (sortedAvailable.length > 1) {
      return result(NarrativeEventReferenceMappingStatus.requiresChoice);
    }
    return result(
      NarrativeEventReferenceMappingStatus.mapped,
      targetEventIds: sortedAvailable,
    );
  }

  if (choice == null) {
    return result(NarrativeEventReferenceMappingStatus.requiresChoice);
  }

  switch (choice.decision) {
    case NarrativeEventReferenceCollisionDecision.cancel:
      return result(
        NarrativeEventReferenceMappingStatus.cancelled,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.consumeAllTargets:
      if (domain != NarrativeEventReferenceDomain.progression &&
          domain != NarrativeEventReferenceDomain.save) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      if (!allCandidatesMapped || sortedAvailable.isEmpty) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      return result(
        NarrativeEventReferenceMappingStatus.mapped,
        targetEventIds: sortedAvailable,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.selectedTargets:
      if (choice.selectedTargetKeys.isNotEmpty) {
        if (choice.selectedTargetKeys.any(
          (targetKey) => !availableByKey.containsKey(targetKey),
        )) {
          return result(
            NarrativeEventReferenceMappingStatus.blocked,
            decision: choice.decision,
          );
        }
        final selectedIds = {
          for (final targetKey in choice.selectedTargetKeys)
            availableByKey[targetKey]!,
        }.toList()
          ..sort();
        return result(
          NarrativeEventReferenceMappingStatus.mapped,
          targetEventIds: selectedIds,
          decision: choice.decision,
        );
      }
      if (choice.selectedTargetEventIds.any(
        (target) => !available.contains(target),
      )) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      return result(
        NarrativeEventReferenceMappingStatus.mapped,
        targetEventIds: choice.selectedTargetEventIds,
        decision: choice.decision,
      );
  }
}

List<NarrativeEventReferenceMapping> _mappingList(
  Map<String, Object?> object,
  String key,
) {
  return _list(object[key], key)
      .map(NarrativeEventReferenceMapping.fromJson)
      .toList();
}

List<LegacyEventReference> _referenceList(Object? value, String path) {
  return _list(value, path).map((item) {
    final object = _object(item, path);
    return LegacyEventReference(
      kind: _enumByName(
        LegacyEventReferenceKind.values,
        _string(object, 'kind'),
        '$path.kind',
      ),
      path: _string(object, 'path'),
      legacyEventId: _string(object, 'legacyEventId'),
      mapId: _optionalString(object['mapId'], '$path.mapId'),
      candidateProvenances: _list(
        object['candidateProvenances'],
        '$path.candidateProvenances',
      ).map(LegacySourceRef.fromJson).toList(),
    );
  }).toList();
}

List<LegacySourceRef> _sortedProvenances(
  List<LegacySourceRef> values,
) {
  final sorted = List<LegacySourceRef>.of(values)
    ..sort(compareLegacySourceRefs);
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(
        values,
        'candidateProvenances',
        'must not contain duplicates',
      );
    }
  }
  return List.unmodifiable(sorted);
}

List<String> _sortedUniqueIds(
  List<String> values,
  String name, {
  bool requireNotEmpty = false,
}) {
  final sorted = values.map((value) => _identity(value, name)).toList()..sort();
  if (requireNotEmpty && sorted.isEmpty) {
    throw ArgumentError.value(values, name, 'must not be empty');
  }
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return List.unmodifiable(sorted);
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List.unmodifiable([for (final item in value) _freezeJson(item)]);
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        _jsonKey(entry.key): _freezeJson(entry.value),
    });
  }
  throw ArgumentError.value(value, 'json', 'must contain JSON values only');
}

String _jsonKey(Object? value) {
  if (value is! String) {
    throw ArgumentError.value(value, 'json key', 'must be a String');
  }
  return value;
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return {
    for (final entry in value.entries) _jsonKey(entry.key): entry.value,
  };
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be a list.');
  return List<Object?>.from(value);
}

List<String> _stringList(Object? value, String path) {
  return _list(value, path).map((item) {
    if (item is! String) throw FormatException('$path must contain strings.');
    return item;
  }).toList();
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('$key must be a String.');
  return value;
}

String? _optionalString(Object? value, String path) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$path must be a String.');
  return value;
}

int _integer(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('$key must be an int.');
  return value;
}

T _enumByName<T extends Enum>(List<T> values, String name, String path) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$path has unsupported value "$name".');
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
