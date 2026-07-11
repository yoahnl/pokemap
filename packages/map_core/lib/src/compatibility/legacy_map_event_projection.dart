import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/script_conditions.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import 'legacy_event_migration_models.dart';

abstract final class LegacyMapEventCompatibilityMetadataKeys {
  static const entityId = 'eventV2.source.entityId';
  static const triggerId = 'eventV2.source.triggerId';
}

abstract final class LegacyMapEventDiagnosticCodes {
  static const mapIdentityMismatch = 'mapIdentityMismatch';
  static const eventMissingFromMap = 'eventMissingFromMap';
  static const layerMissing = 'layerMissing';
  static const positionOutOfBounds = 'positionOutOfBounds';
  static const explicitSourceConflict = 'explicitSourceConflict';
  static const explicitSourceMissing = 'explicitSourceMissing';
  static const positionIsOnlyEvidence = 'positionIsOnlyEvidence';
  static const ambiguousPositionCandidates = 'ambiguousPositionCandidates';
  static const standaloneMapEvent = 'standaloneMapEvent';
  static const effectUnsupported = 'effectUnsupported';
  static const multiplePages = 'multiplePages';
  static const noPages = 'noPages';
  static const missingSceneTarget = 'missingSceneTarget';
  static const opaqueScript = 'opaqueScript';
  static const legacyMessage = 'legacyMessage';
  static const conditionNeedsReview = 'conditionNeedsReview';
  static const pageStateNeedsReview = 'pageStateNeedsReview';
  static const unknownRawData = 'unknownRawData';
  static const invalidClaim = 'invalidClaim';
  static const claimFingerprintStale = 'claimFingerprintStale';
  static const claimSourceMismatch = 'claimSourceMismatch';
  static const globalClaimConflict = 'globalClaimConflict';
  static const ambiguousLinkedReference = 'ambiguousLinkedReference';
  static const unresolvedLinkedReference = 'unresolvedLinkedReference';
  static const legacySprite = 'legacySprite';
  static const triggerRuntimeParityUnproven = 'triggerRuntimeParityUnproven';
}

enum LegacyMapEventSourceEvidenceKind {
  explicitMetadata,
  exactUniqueFootprint,
  ambiguousFootprint,
}

@immutable
final class LegacyMapEventSourceCandidate {
  LegacyMapEventSourceCandidate({
    required this.source,
    required this.evidence,
    required this.confirmed,
    required String reason,
  }) : reason = _requireText(reason, 'reason');

  final NarrativeEventSourceRef source;
  final LegacyMapEventSourceEvidenceKind evidence;
  final bool confirmed;
  final String reason;

  Map<String, Object?> toJson() => {
        'source': source.toJson(),
        'evidence': evidence.name,
        'confirmed': confirmed,
        'reason': reason,
      };
}

@immutable
final class LegacyMapEventPageProjection {
  LegacyMapEventPageProjection({
    required this.pageIndex,
    required this.pageNumber,
    required this.condition,
    required this.script,
    required this.spriteId,
    required this.message,
    required this.sceneId,
    required this.isHidden,
    required this.isDisabled,
    required Map<String, String> metadata,
  }) : metadata = Map.unmodifiable(metadata);

  final int pageIndex;
  final int pageNumber;
  final ScriptCondition? condition;
  final ScriptRef? script;
  final String? spriteId;
  final String? message;
  final String? sceneId;
  final bool isHidden;
  final bool isDisabled;
  final Map<String, String> metadata;

  Map<String, Object?> toJson() => {
        'pageIndex': pageIndex,
        'pageNumber': pageNumber,
        if (condition != null) 'condition': condition!.toJson(),
        if (script != null) 'script': script!.toJson(),
        if (spriteId != null) 'spriteId': spriteId,
        if (message != null) 'message': message,
        if (sceneId != null) 'sceneId': sceneId,
        'isHidden': isHidden,
        'isDisabled': isDisabled,
        'metadata': metadata,
      };
}

@immutable
final class LegacyMapEventProjection {
  LegacyMapEventProjection({
    required this.provenance,
    required this.classification,
    required this.claimStatus,
    required this.existingClaim,
    required this.sourceFingerprint,
    required List<LegacyMapEventSourceCandidate> sourceCandidates,
    required List<LegacyMapEventPageProjection> pages,
    required Map<String, Object?> preservedEventJson,
    required List<String> unconvertibleDataPaths,
    required List<LegacyEventReference> linkedReferences,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required List<String> manualActions,
  })  : sourceCandidates = List.unmodifiable(sourceCandidates),
        pages = List.unmodifiable(pages),
        preservedEventJson = _freezeObject(_normalizeJson(preservedEventJson)),
        unconvertibleDataPaths = List.unmodifiable(unconvertibleDataPaths),
        linkedReferences = List.unmodifiable(linkedReferences),
        diagnostics = List.unmodifiable(diagnostics),
        manualActions = List.unmodifiable(manualActions);

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final LegacyProjectionClaimStatus claimStatus;
  final LegacySourceClaim? existingClaim;
  final String sourceFingerprint;
  final List<LegacyMapEventSourceCandidate> sourceCandidates;
  final List<LegacyMapEventPageProjection> pages;
  final Map<String, Object?> preservedEventJson;
  final List<String> unconvertibleDataPaths;
  final List<LegacyEventReference> linkedReferences;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final List<String> manualActions;

  NarrativeEventSourceRef? get confirmedSource {
    for (final candidate in sourceCandidates) {
      if (candidate.confirmed) return candidate.source;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'classification': classification.name,
        'claimStatus': claimStatus.name,
        if (existingClaim != null) 'existingClaim': existingClaim!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'sourceCandidates': [
          for (final candidate in sourceCandidates) candidate.toJson(),
        ],
        if (confirmedSource != null)
          'confirmedSource': confirmedSource!.toJson(),
        'pages': [for (final page in pages) page.toJson()],
        'preservedEventJson': preservedEventJson,
        'unconvertibleDataPaths': unconvertibleDataPaths,
        'linkedReferences': [
          for (final reference in linkedReferences) reference.toJson(),
        ],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'manualActions': manualActions,
      };
}

LegacyMapEventProjection projectLegacyMapEventReadOnly({
  required String mapId,
  required MapData map,
  required MapEventDefinition event,
  required ValidatedLegacyClaimIndex claimIndex,
  List<LegacyEventReference> linkedReferences = const [],
  Map<String, Object?>? rawEventJson,
}) {
  final provenance = LegacySourceRef.mapEvent(mapId, event.id);
  var classification = LegacyMigrationClassification.autoSafe;
  final diagnostics = <LegacyMigrationDiagnostic>[];
  final manualActions = <String>[];
  final unconvertible = <String>[];
  final candidates = <LegacyMapEventSourceCandidate>[];

  void escalate(LegacyMigrationClassification next) {
    if (_classificationRank(next) > _classificationRank(classification)) {
      classification = next;
    }
  }

  void diagnose(
    String code,
    LegacyMigrationDiagnosticSeverity severity,
    String message,
    String path,
  ) {
    diagnostics.add(
      LegacyMigrationDiagnostic(
        code: code,
        severity: severity,
        message: message,
        path: path,
      ),
    );
  }

  if (map.id != mapId) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.mapIdentityMismatch,
      LegacyMigrationDiagnosticSeverity.error,
      'The supplied map context does not match the qualified mapId.',
      'mapId',
    );
  }
  if (!map.events.any((candidate) => candidate.id == event.id)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.eventMissingFromMap,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent is absent from the supplied map snapshot.',
      'event.id',
    );
  }
  if (!map.layers.any((layer) => layer.id == event.position.layerId)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.layerMissing,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent references a layer that does not exist.',
      'event.position.layerId',
    );
  }
  if (event.position.x < 0 ||
      event.position.y < 0 ||
      event.position.x >= map.size.width ||
      event.position.y >= map.size.height) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.positionOutOfBounds,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent position lies outside the map bounds.',
      'event.position',
    );
  }

  _collectSourceCandidates(
    mapId: mapId,
    map: map,
    event: event,
    candidates: candidates,
    escalate: escalate,
    diagnose: diagnose,
    manualActions: manualActions,
  );

  if (event.type == MapEventType.effect) {
    escalate(LegacyMigrationClassification.unsupported);
    unconvertible.add('type');
    diagnose(
      LegacyMapEventDiagnosticCodes.effectUnsupported,
      LegacyMigrationDiagnosticSeverity.error,
      'MapEvent effects have no Event V2 V0 source contract.',
      'event.type',
    );
  }

  final pages = <LegacyMapEventPageProjection>[];
  for (var index = 0; index < event.pages.length; index++) {
    final page = event.pages[index];
    pages.add(
      LegacyMapEventPageProjection(
        pageIndex: index,
        pageNumber: page.pageNumber,
        condition: page.condition,
        script: page.script,
        spriteId: page.spriteId,
        message: page.message,
        sceneId: page.sceneTarget?.sceneId,
        isHidden: page.isHidden,
        isDisabled: page.isDisabled,
        metadata: page.metadata,
      ),
    );
    if (page.script != null) {
      escalate(LegacyMigrationClassification.unsupported);
      unconvertible.add('pages[$index].script');
      diagnose(
        LegacyMapEventDiagnosticCodes.opaqueScript,
        LegacyMigrationDiagnosticSeverity.error,
        'Opaque legacy scripts cannot be converted by the V0 adapter.',
        'event.pages[$index].script',
      );
    }
    if ((page.spriteId ?? '').trim().isNotEmpty) {
      escalate(LegacyMigrationClassification.assisted);
      unconvertible.add('pages[$index].spriteId');
      manualActions.add(
        'Confirm how sprite ${page.spriteId} maps to the selected source.',
      );
      diagnose(
        LegacyMapEventDiagnosticCodes.legacySprite,
        LegacyMigrationDiagnosticSeverity.warning,
        'Legacy sprite ownership must be resolved on the selected map source.',
        'event.pages[$index].spriteId',
      );
    }
    if ((page.message ?? '').trim().isNotEmpty) {
      escalate(LegacyMigrationClassification.unsupported);
      unconvertible.add('pages[$index].message');
      diagnose(
        LegacyMapEventDiagnosticCodes.legacyMessage,
        LegacyMigrationDiagnosticSeverity.error,
        'Legacy page messages require an explicit Scene conversion.',
        'event.pages[$index].message',
      );
    }
    if ((page.sceneTarget?.sceneId ?? '').trim().isEmpty) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose a Scene for page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.missingSceneTarget,
        LegacyMigrationDiagnosticSeverity.error,
        'The page has no stable Scene target.',
        'event.pages[$index].sceneTarget',
      );
    }
    if (page.condition != null) {
      escalate(LegacyMigrationClassification.assisted);
      manualActions.add('Review the condition on page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.conditionNeedsReview,
        LegacyMigrationDiagnosticSeverity.warning,
        'The legacy condition must be mapped explicitly.',
        'event.pages[$index].condition',
      );
    }
    if (page.isHidden || page.isDisabled) {
      escalate(LegacyMigrationClassification.assisted);
      manualActions
          .add('Review hidden/disabled state on page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.pageStateNeedsReview,
        LegacyMigrationDiagnosticSeverity.warning,
        'Hidden and disabled page state is preserved but not inferred.',
        'event.pages[$index]',
      );
    }
  }
  if (event.pages.isEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.noPages,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent has no page to characterize.',
      'event.pages',
    );
  } else if (event.pages.length > 1) {
    escalate(LegacyMigrationClassification.blocked);
    manualActions
        .add('Map each legacy page without changing first-valid order.');
    diagnose(
      LegacyMapEventDiagnosticCodes.multiplePages,
      LegacyMigrationDiagnosticSeverity.error,
      'Multi-page MapEvents cannot be flattened automatically.',
      'event.pages',
    );
  }

  final normalizedRaw = _normalizeJson(rawEventJson ?? event.toJson());
  final preservedEventJson = _freezeObject(normalizedRaw);
  final unknownPaths = _unknownRawPaths(normalizedRaw);
  if (unknownPaths.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    unconvertible.addAll(unknownPaths);
    for (final path in unknownPaths) {
      diagnose(
        LegacyMapEventDiagnosticCodes.unknownRawData,
        LegacyMigrationDiagnosticSeverity.error,
        'Unknown legacy JSON is preserved and blocks automatic conversion.',
        path,
      );
    }
  }

  for (final reference in linkedReferences) {
    if (reference.legacyEventId != event.id ||
        reference.candidateProvenances.isEmpty ||
        (reference.candidateProvenances.length == 1 &&
            reference.candidateProvenances.single != provenance)) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Resolve reference ${reference.path} explicitly.');
      diagnose(
        LegacyMapEventDiagnosticCodes.unresolvedLinkedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'A linked legacy reference does not resolve to this provenance.',
        reference.path,
      );
    } else if (reference.candidateProvenances.length > 1) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose targets for reference ${reference.path}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.ambiguousLinkedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'A bare legacy reference resolves to several provenances.',
        reference.path,
      );
    }
  }

  final currentFingerprint = computeMapEventSourceFingerprint(
    mapId: mapId,
    event: event,
  );
  final indexedValidClaim = claimIndex.validByProvenance[provenance];
  final invalidClaimDiagnostics = claimIndex.invalidByProvenance[provenance];
  var contextualValidClaim = indexedValidClaim;
  var contextualClaimInvalid = invalidClaimDiagnostics != null;
  if (indexedValidClaim != null) {
    final members = indexedValidClaim.members
        .where((member) => member.provenance == provenance)
        .toList();
    if (members.length != 1 ||
        members.single.sourceFingerprint != currentFingerprint) {
      contextualValidClaim = null;
      contextualClaimInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyMapEventDiagnosticCodes.claimFingerprintStale,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim fingerprint no longer matches the complete MapEvent.',
        'claim.members',
      );
    }
    NarrativeEventSourceRef? confirmedSource;
    for (final candidate in candidates) {
      if (candidate.confirmed) {
        confirmedSource = candidate.source;
        break;
      }
    }
    if (confirmedSource != null &&
        indexedValidClaim.source != confirmedSource) {
      contextualValidClaim = null;
      contextualClaimInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyMapEventDiagnosticCodes.claimSourceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim source contradicts the explicitly confirmed source.',
        'claim.source',
      );
    }
  }
  final claimStatus = contextualValidClaim != null
      ? LegacyProjectionClaimStatus.valid
      : contextualClaimInvalid
          ? LegacyProjectionClaimStatus.invalid
          : LegacyProjectionClaimStatus.absent;
  if (invalidClaimDiagnostics != null) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.invalidClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'This provenance is covered by an invalid or tombstone claim.',
      'claimIndex.invalidByProvenance',
    );
  }
  if (claimIndex.globalConflicts.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.globalClaimConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'The claim index contains a global conflict.',
      'claimIndex.globalConflicts',
    );
  }

  return LegacyMapEventProjection(
    provenance: provenance,
    classification: classification,
    claimStatus: claimStatus,
    existingClaim: contextualValidClaim,
    sourceFingerprint: currentFingerprint,
    sourceCandidates: candidates,
    pages: pages,
    preservedEventJson: preservedEventJson,
    unconvertibleDataPaths: unconvertible,
    linkedReferences: linkedReferences,
    diagnostics: diagnostics,
    manualActions: manualActions,
  );
}

void _collectSourceCandidates({
  required String mapId,
  required MapData map,
  required MapEventDefinition event,
  required List<LegacyMapEventSourceCandidate> candidates,
  required void Function(LegacyMigrationClassification) escalate,
  required void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  required List<String> manualActions,
}) {
  final hasEntityKey = event.metadata
      .containsKey(LegacyMapEventCompatibilityMetadataKeys.entityId);
  final hasTriggerKey = event.metadata
      .containsKey(LegacyMapEventCompatibilityMetadataKeys.triggerId);
  final entityId =
      event.metadata[LegacyMapEventCompatibilityMetadataKeys.entityId];
  final triggerId =
      event.metadata[LegacyMapEventCompatibilityMetadataKeys.triggerId];
  final expectsEntity =
      event.type == MapEventType.actor || event.type == MapEventType.object;
  final expectsTrigger = event.type == MapEventType.triggerZone;

  if ((hasEntityKey && hasTriggerKey) ||
      (expectsEntity && hasTriggerKey) ||
      (expectsTrigger && hasEntityKey)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.explicitSourceConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'Explicit source metadata conflicts with the MapEvent type.',
      'event.metadata',
    );
    return;
  }

  if (expectsEntity && hasEntityKey) {
    final matches =
        map.entities.where((entity) => entity.id == entityId).toList();
    if (entityId == null ||
        entityId.isEmpty ||
        entityId.trim() != entityId ||
        matches.length != 1) {
      _explicitSourceMissing(escalate, diagnose, 'entityId');
      return;
    }
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'Stable entityId is encoded in legacy metadata.',
      ),
    );
    return;
  }
  if (expectsTrigger && hasTriggerKey) {
    final matches =
        map.triggers.where((trigger) => trigger.id == triggerId).toList();
    if (triggerId == null ||
        triggerId.isEmpty ||
        triggerId.trim() != triggerId ||
        matches.length != 1) {
      _explicitSourceMissing(escalate, diagnose, 'triggerId');
      return;
    }
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'Stable triggerId is encoded in legacy metadata.',
      ),
    );
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven,
      LegacyMigrationDiagnosticSeverity.warning,
      'Legacy triggerZone runtime parity is not proven in Phase C.',
      'event.type',
    );
    return;
  }

  if (event.type == MapEventType.effect) return;
  if (expectsEntity) {
    final matches = map.entities
        .where((entity) => _entityContains(entity, event.position))
        .toList();
    _addFootprintCandidates(
      matches.map(
        (entity) => NarrativeEventSourceRef.entityInteract(mapId, entity.id),
      ),
      candidates: candidates,
      escalate: escalate,
      diagnose: diagnose,
      manualActions: manualActions,
    );
    return;
  }
  final matches = map.triggers
      .where((trigger) => _triggerContains(trigger, event.position))
      .toList();
  _addFootprintCandidates(
    matches.map(
      (trigger) => NarrativeEventSourceRef.triggerEnter(mapId, trigger.id),
    ),
    candidates: candidates,
    escalate: escalate,
    diagnose: diagnose,
    manualActions: manualActions,
  );
  if (matches.length == 1) {
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven,
      LegacyMigrationDiagnosticSeverity.warning,
      'Legacy triggerZone runtime parity is not proven in Phase C.',
      'event.type',
    );
  }
}

void _explicitSourceMissing(
  void Function(LegacyMigrationClassification) escalate,
  void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  String field,
) {
  escalate(LegacyMigrationClassification.blocked);
  diagnose(
    LegacyMapEventDiagnosticCodes.explicitSourceMissing,
    LegacyMigrationDiagnosticSeverity.error,
    'The explicit source metadata does not resolve exactly once.',
    'event.metadata.$field',
  );
}

void _addFootprintCandidates(
  Iterable<NarrativeEventSourceRef> sources, {
  required List<LegacyMapEventSourceCandidate> candidates,
  required void Function(LegacyMigrationClassification) escalate,
  required void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  required List<String> manualActions,
}) {
  final values = sources.toList();
  if (values.isEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Choose or materialize an explicit Event source.');
    diagnose(
      LegacyMapEventDiagnosticCodes.standaloneMapEvent,
      LegacyMigrationDiagnosticSeverity.error,
      'No compatible source owns this MapEvent position.',
      'event.position',
    );
    return;
  }
  final evidence = values.length == 1
      ? LegacyMapEventSourceEvidenceKind.exactUniqueFootprint
      : LegacyMapEventSourceEvidenceKind.ambiguousFootprint;
  for (final source in values) {
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: source,
        evidence: evidence,
        confirmed: false,
        reason: values.length == 1
            ? 'One compatible source shares the exact footprint.'
            : 'Several compatible sources share the exact footprint.',
      ),
    );
  }
  if (values.length == 1) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add('Confirm the proposed source explicitly.');
    diagnose(
      LegacyMapEventDiagnosticCodes.positionIsOnlyEvidence,
      LegacyMigrationDiagnosticSeverity.warning,
      'Position is a migration hint, not source identity.',
      'event.position',
    );
  } else {
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Choose one source explicitly or cancel conversion.');
    diagnose(
      LegacyMapEventDiagnosticCodes.ambiguousPositionCandidates,
      LegacyMigrationDiagnosticSeverity.error,
      'Several source candidates share the MapEvent footprint.',
      'event.position',
    );
  }
}

bool _entityContains(MapEntity entity, EventPosition position) {
  return position.x >= entity.pos.x &&
      position.y >= entity.pos.y &&
      position.x < entity.pos.x + entity.size.width &&
      position.y < entity.pos.y + entity.size.height;
}

bool _triggerContains(MapTrigger trigger, EventPosition position) {
  return position.x >= trigger.area.pos.x &&
      position.y >= trigger.area.pos.y &&
      position.x < trigger.area.pos.x + trigger.area.size.width &&
      position.y < trigger.area.pos.y + trigger.area.size.height;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

Map<String, Object?> _normalizeJson(Map<String, Object?> value) {
  return Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
}

Map<String, Object?> _freezeObject(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freezeJson(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  return value;
}

List<String> _unknownRawPaths(Map<String, Object?> raw) {
  const eventFields = {'id', 'title', 'pages', 'position', 'type', 'metadata'};
  const pageFields = {
    'pageNumber',
    'condition',
    'script',
    'spriteId',
    'message',
    'sceneTarget',
    'isHidden',
    'isDisabled',
    'metadata',
  };
  const positionFields = {'layerId', 'x', 'y'};
  const sceneTargetFields = {'sceneId'};
  const scriptFields = {'scriptId', 'startNode'};
  const conditionFields = {'type', 'params', 'children'};
  final result = <String>{};
  _collectUnknownObjectKeys(raw, eventFields, 'event', result);
  _inspectKnownObject(
      raw['position'], positionFields, 'event.position', result);
  final pages = raw['pages'];
  if (pages is List) {
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final path = 'event.pages[$index]';
      if (page is! Map) {
        result.add(path);
        continue;
      }
      _collectUnknownObjectKeys(page, pageFields, path, result);
      _inspectKnownObject(
        page['sceneTarget'],
        sceneTargetFields,
        '$path.sceneTarget',
        result,
        optional: true,
      );
      _inspectKnownObject(
        page['script'],
        scriptFields,
        '$path.script',
        result,
        optional: true,
      );
      _inspectConditionJson(
        page['condition'],
        '$path.condition',
        conditionFields,
        result,
      );
    }
  } else {
    result.add('event.pages');
  }
  final sorted = result.toList()..sort();
  return sorted;
}

void _inspectKnownObject(
  Object? value,
  Set<String> knownFields,
  String path,
  Set<String> result, {
  bool optional = false,
}) {
  if (value == null && optional) return;
  if (value is! Map) {
    result.add(path);
    return;
  }
  _collectUnknownObjectKeys(value, knownFields, path, result);
}

void _inspectConditionJson(
  Object? value,
  String path,
  Set<String> knownFields,
  Set<String> result,
) {
  if (value == null) return;
  if (value is! Map) {
    result.add(path);
    return;
  }
  _collectUnknownObjectKeys(value, knownFields, path, result);
  final children = value['children'];
  if (children == null) return;
  if (children is! List) {
    result.add('$path.children');
    return;
  }
  for (var index = 0; index < children.length; index++) {
    _inspectConditionJson(
      children[index],
      '$path.children[$index]',
      knownFields,
      result,
    );
  }
}

void _collectUnknownObjectKeys(
  Map value,
  Set<String> knownFields,
  String path,
  Set<String> result,
) {
  for (final key in value.keys) {
    if (key is! String || !knownFields.contains(key)) {
      result.add('$path.$key');
    }
  }
}

String _requireText(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
