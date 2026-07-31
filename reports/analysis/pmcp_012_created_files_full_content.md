# PMCP-012 — Full created-file contents

This appendix is part of the PMCP-012 Evidence Pack and reproduces every production and test file created by the lot. The report and appendix exclude themselves to avoid self-reference.

## `packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

/// JSON-safe projection of one explicit capability attestation.
final class AuthoringCapabilityTruthRecord {
  const AuthoringCapabilityTruthRecord({
    required this.capabilityId,
    required this.authoringControl,
    required this.contractField,
    required this.runtimeConsumer,
    required this.playerSurface,
    required this.positiveTest,
    required this.negativeTest,
    required this.status,
    required this.reason,
  });

  factory AuthoringCapabilityTruthRecord.fromCore(
    ProjectCapabilityTruthRecord record,
  ) {
    return AuthoringCapabilityTruthRecord(
      capabilityId: record.capabilityId,
      authoringControl: record.authoringControl,
      contractField: record.contractField,
      runtimeConsumer: record.runtimeConsumer,
      playerSurface: record.playerSurface,
      positiveTest: record.positiveTest,
      negativeTest: record.negativeTest,
      status: record.status.name,
      reason: record.reason,
    );
  }

  final String capabilityId;
  final String? authoringControl;
  final String? contractField;
  final String? runtimeConsumer;
  final String? playerSurface;
  final String? positiveTest;
  final String? negativeTest;
  final String status;
  final String? reason;

  Map<String, Object?> toJson() => {
        'capabilityId': capabilityId,
        'authoringControl': authoringControl,
        'contractField': contractField,
        'runtimeConsumer': runtimeConsumer,
        'playerSurface': playerSurface,
        'positiveTest': positiveTest,
        'negativeTest': negativeTest,
        'status': status,
        'reason': reason,
      };
}

/// JSON-safe projection of one coded capability-truth issue.
final class AuthoringCapabilityTruthIssue {
  const AuthoringCapabilityTruthIssue({
    required this.code,
    required this.capabilityId,
    required this.message,
  });

  factory AuthoringCapabilityTruthIssue.fromCore(
    ProjectCapabilityTruthIssue issue,
  ) {
    return AuthoringCapabilityTruthIssue(
      code: issue.code.name,
      capabilityId: issue.capabilityId,
      message: issue.message,
    );
  }

  final String code;
  final String capabilityId;
  final String message;

  Map<String, Object?> toJson() => {
        'code': code,
        'capabilityId': capabilityId,
        'message': message,
      };
}

/// Immutable authoring view of the fail-closed capability truth gate.
final class AuthoringCapabilityTruthReport {
  AuthoringCapabilityTruthReport._({
    required this.isPassing,
    required Iterable<AuthoringCapabilityTruthRecord> capabilities,
    required Iterable<AuthoringCapabilityTruthIssue> issues,
  })  : capabilities = List.unmodifiable(capabilities),
        issues = List.unmodifiable(issues);

  factory AuthoringCapabilityTruthReport.fromCore(
    ProjectCapabilityTruthReport report,
  ) {
    return AuthoringCapabilityTruthReport._(
      isPassing: report.isPassing,
      capabilities: report.capabilities.map(
        AuthoringCapabilityTruthRecord.fromCore,
      ),
      issues: report.issues.map(AuthoringCapabilityTruthIssue.fromCore),
    );
  }

  final bool isPassing;
  final List<AuthoringCapabilityTruthRecord> capabilities;
  final List<AuthoringCapabilityTruthIssue> issues;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'status': isPassing ? 'pass' : 'fail',
        'capabilities': capabilities
            .map((capability) => capability.toJson())
            .toList(growable: false),
        'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      };
}

/// Adapts explicit truth records without inferring support from project data.
///
/// Deliberately no overload accepts a [ProjectManifest]: model presence is not
/// proof of an authoring control, runtime consumer, player surface, or tests.
abstract final class ProjectCapabilityTruthAdapter {
  static AuthoringCapabilityTruthReport evaluate({
    required Iterable<ProjectCapabilityTruthRecord> records,
    required Set<String> requiredCapabilityIds,
  }) {
    final report = ProjectCapabilityTruthReport.evaluate(
      records,
      requiredCapabilityIds: requiredCapabilityIds,
    );
    return AuthoringCapabilityTruthReport.fromCore(report);
  }
}
~~~~~~~~
## `packages/map_authoring/lib/src/references/project_reference_index.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

import '../contracts/resource_ref.dart';
import '../workspace/project_snapshot.dart';

enum ProjectReferenceSeverity { info, warning, error }

/// Stable, path-free identity used by the authoring reference API.
final class ProjectReferenceKey {
  ProjectReferenceKey({
    required String kind,
    required String id,
    String? scope,
    String? parentId,
    String? sourceKind,
  })  : kind = _requireNonBlank(kind, 'kind'),
        id = _requireNonBlank(id, 'id'),
        scope = _optionalNonBlank(scope, 'scope'),
        parentId = _optionalNonBlank(parentId, 'parentId'),
        sourceKind = _optionalNonBlank(sourceKind, 'sourceKind');

  factory ProjectReferenceKey.fromNarrativeKey(
    NarrativeDependencyKey key,
  ) {
    return ProjectReferenceKey(
      kind: key.kind.name,
      id: key.id,
      scope: key.scope,
      parentId: key.parentId,
      sourceKind: key.sourceKind,
    );
  }

  final String kind;
  final String id;
  final String? scope;
  final String? parentId;
  final String? sourceKind;

  NarrativeDependencyKey toNarrativeKey() {
    final narrativeKind = NarrativeDependencyTargetKind.values
        .where((candidate) => candidate.name == kind)
        .firstOrNull;
    if (narrativeKind == null) {
      throw StateError('Reference kind "$kind" is not a narrative kind.');
    }
    return NarrativeDependencyKey(
      narrativeKind,
      id,
      scope: scope,
      parentId: parentId,
      sourceKind: sourceKind,
    );
  }

  ProjectReferenceKey withId(String newId) {
    return ProjectReferenceKey(
      kind: kind,
      id: newId,
      scope: scope,
      parentId: parentId,
      sourceKind: sourceKind,
    );
  }

  AuthoringResourceRef toResourceRef() {
    return AuthoringResourceRef(
      kind: kind,
      id: id,
      extensions: {
        if (scope != null) 'scope': scope,
        if (parentId != null) 'parentId': parentId,
        if (sourceKind != null) 'sourceKind': sourceKind,
      },
    );
  }

  Map<String, Object?> toJson() => {
        'kind': kind,
        'id': id,
        if (scope != null) 'scope': scope,
        if (parentId != null) 'parentId': parentId,
        if (sourceKind != null) 'sourceKind': sourceKind,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectReferenceKey &&
          other.kind == kind &&
          other.id == id &&
          other.scope == scope &&
          other.parentId == parentId &&
          other.sourceKind == sourceKind;

  @override
  int get hashCode => Object.hash(kind, id, scope, parentId, sourceKind);

  @override
  String toString() => toJson().toString();
}

final class ProjectReferenceNavigation {
  ProjectReferenceNavigation({
    required this.kind,
    required this.assetId,
    this.parentId,
    this.rootId,
    this.scope,
    this.sourceKind,
    this.mapId,
    this.context,
  });

  factory ProjectReferenceNavigation.fromNarrativeIntent(
    NarrativeDependencyNavigationIntent intent,
  ) {
    return ProjectReferenceNavigation(
      kind: intent.kind.name,
      assetId: intent.assetId,
      parentId: intent.parentId,
      rootId: intent.rootId,
      scope: intent.scope,
      sourceKind: intent.sourceKind,
      mapId: intent.mapId,
      context: intent.context,
    );
  }

  final String kind;
  final String assetId;
  final String? parentId;
  final String? rootId;
  final String? scope;
  final String? sourceKind;
  final String? mapId;
  final String? context;

  Map<String, Object?> toJson() => {
        'kind': kind,
        'assetId': assetId,
        if (parentId != null) 'parentId': parentId,
        if (rootId != null) 'rootId': rootId,
        if (scope != null) 'scope': scope,
        if (sourceKind != null) 'sourceKind': sourceKind,
        if (mapId != null) 'mapId': mapId,
        if (context != null) 'context': context,
      };
}

final class ProjectReferenceNode {
  ProjectReferenceNode({
    required this.key,
    required this.label,
    required this.defined,
    Map<String, String> metadata = const {},
    this.navigation,
  }) : metadata = Map.unmodifiable(_sortedStringMap(metadata));

  final ProjectReferenceKey key;
  final String label;
  final bool defined;
  final Map<String, String> metadata;
  final ProjectReferenceNavigation? navigation;

  Map<String, Object?> toJson() => {
        'key': key.toJson(),
        'label': label,
        'defined': defined,
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (navigation != null) 'navigation': navigation!.toJson(),
      };
}

final class ProjectReferenceEdge {
  ProjectReferenceEdge({
    required this.owner,
    required this.target,
    required this.path,
    required this.criticality,
    required this.resolution,
    this.navigation,
  });

  final ProjectReferenceKey owner;
  final ProjectReferenceKey target;
  final String path;
  final NarrativeDependencyCriticality criticality;
  final NarrativeDependencyResolution resolution;
  final ProjectReferenceNavigation? navigation;

  Map<String, Object?> toJson() => {
        'owner': owner.toJson(),
        'target': target.toJson(),
        'path': path,
        'criticality': criticality.name,
        'resolution': resolution.name,
        if (navigation != null) 'navigation': navigation!.toJson(),
      };
}

final class ProjectReferenceDiagnostic {
  ProjectReferenceDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.target,
    this.owner,
    this.fieldPath,
    this.navigation,
  });

  final String code;
  final ProjectReferenceSeverity severity;
  final String message;
  final ProjectReferenceKey target;
  final ProjectReferenceKey? owner;
  final String? fieldPath;
  final ProjectReferenceNavigation? navigation;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'target': target.toJson(),
        if (owner != null) 'owner': owner!.toJson(),
        if (fieldPath != null) 'fieldPath': fieldPath,
        if (navigation != null) 'navigation': navigation!.toJson(),
      };
}

/// Deterministic authoring projection of the canonical narrative dependency
/// index.
final class ProjectReferenceIndex {
  ProjectReferenceIndex._({
    required NarrativeDependencyIndex narrativeIndex,
    required List<ProjectReferenceNode> nodes,
    required List<ProjectReferenceEdge> edges,
    required List<ProjectReferenceDiagnostic> diagnostics,
  })  : _narrativeIndex = narrativeIndex,
        nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges),
        diagnostics = List.unmodifiable(diagnostics),
        _nodesByKey = Map.unmodifiable({
          for (final node in nodes) node.key: node,
        });

  factory ProjectReferenceIndex.fromSnapshot(ProjectSnapshot snapshot) {
    return ProjectReferenceIndex.fromNarrativeIndex(
      buildNarrativeDependencyIndex(
        project: snapshot.manifest,
        maps: snapshot.maps,
      ),
    );
  }

  factory ProjectReferenceIndex.fromNarrativeIndex(
    NarrativeDependencyIndex narrativeIndex,
  ) {
    final narrativeKeys = <NarrativeDependencyKey>{};
    for (final definition in narrativeIndex.definitions) {
      narrativeKeys
        ..add(definition.key)
        ..addAll(
          definition.owner == null
              ? const <NarrativeDependencyKey>[]
              : <NarrativeDependencyKey>[definition.owner!],
        );
    }
    for (final usage in narrativeIndex.usages) {
      narrativeKeys
        ..add(usage.owner)
        ..add(usage.target);
    }
    for (final issue in narrativeIndex.issues) {
      narrativeKeys
        ..add(issue.target)
        ..addAll(
          issue.owner == null
              ? const <NarrativeDependencyKey>[]
              : <NarrativeDependencyKey>[issue.owner!],
        );
    }

    final sortedKeys = narrativeKeys.toList()..sort(_compareNarrativeKeys);
    final nodes = <ProjectReferenceNode>[
      for (final key in sortedKeys) _nodeForNarrativeKey(narrativeIndex, key),
    ];

    final edges = <ProjectReferenceEdge>[
      for (final usage in narrativeIndex.usages)
        ProjectReferenceEdge(
          owner: ProjectReferenceKey.fromNarrativeKey(usage.owner),
          target: ProjectReferenceKey.fromNarrativeKey(usage.target),
          path: usage.path,
          criticality: usage.criticality,
          resolution: usage.resolution,
          navigation: _navigation(usage.navigationIntent),
        ),
    ]..sort(compareProjectReferenceEdges);

    final diagnostics = _buildDiagnostics(narrativeIndex)
      ..sort(compareProjectReferenceDiagnostics);
    return ProjectReferenceIndex._(
      narrativeIndex: narrativeIndex,
      nodes: nodes,
      edges: edges,
      diagnostics: diagnostics,
    );
  }

  final NarrativeDependencyIndex _narrativeIndex;
  final List<ProjectReferenceNode> nodes;
  final List<ProjectReferenceEdge> edges;
  final List<ProjectReferenceDiagnostic> diagnostics;
  final Map<ProjectReferenceKey, ProjectReferenceNode> _nodesByKey;

  NarrativeDependencyIndex get narrativeIndex => _narrativeIndex;

  ProjectReferenceNode? nodeFor(ProjectReferenceKey key) => _nodesByKey[key];

  Map<String, Object?> toJson() => {
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
        'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
        'diagnostics': diagnostics
            .map((diagnostic) => diagnostic.toJson())
            .toList(growable: false),
      };
}

int compareProjectReferenceKeys(
  ProjectReferenceKey left,
  ProjectReferenceKey right,
) {
  var comparison = left.kind.compareTo(right.kind);
  if (comparison != 0) return comparison;
  comparison = left.id.compareTo(right.id);
  if (comparison != 0) return comparison;
  comparison = (left.scope ?? '').compareTo(right.scope ?? '');
  if (comparison != 0) return comparison;
  comparison = (left.parentId ?? '').compareTo(right.parentId ?? '');
  if (comparison != 0) return comparison;
  return (left.sourceKind ?? '').compareTo(right.sourceKind ?? '');
}

int compareProjectReferenceEdges(
  ProjectReferenceEdge left,
  ProjectReferenceEdge right,
) {
  var comparison = compareProjectReferenceKeys(left.owner, right.owner);
  if (comparison != 0) return comparison;
  comparison = compareProjectReferenceKeys(left.target, right.target);
  if (comparison != 0) return comparison;
  comparison = left.path.compareTo(right.path);
  if (comparison != 0) return comparison;
  comparison = left.criticality.name.compareTo(right.criticality.name);
  if (comparison != 0) return comparison;
  return left.resolution.name.compareTo(right.resolution.name);
}

int compareProjectReferenceDiagnostics(
  ProjectReferenceDiagnostic left,
  ProjectReferenceDiagnostic right,
) {
  var comparison = left.code.compareTo(right.code);
  if (comparison != 0) return comparison;
  comparison = compareProjectReferenceKeys(left.target, right.target);
  if (comparison != 0) return comparison;
  final leftOwner = left.owner;
  final rightOwner = right.owner;
  if (leftOwner == null && rightOwner != null) return -1;
  if (leftOwner != null && rightOwner == null) return 1;
  if (leftOwner != null && rightOwner != null) {
    comparison = compareProjectReferenceKeys(leftOwner, rightOwner);
    if (comparison != 0) return comparison;
  }
  comparison = (left.fieldPath ?? '').compareTo(right.fieldPath ?? '');
  if (comparison != 0) return comparison;
  return left.message.compareTo(right.message);
}

ProjectReferenceNode _nodeForNarrativeKey(
  NarrativeDependencyIndex index,
  NarrativeDependencyKey key,
) {
  final definitions = index.definitionsFor(key);
  final firstDefinition = definitions.firstOrNull;
  final navigationIntent = firstDefinition?.navigationIntent ??
      index
          .usagesFor(key)
          .map((usage) => usage.navigationIntent)
          .whereType<NarrativeDependencyNavigationIntent>()
          .firstOrNull;
  final label = firstDefinition?.label.trim();
  return ProjectReferenceNode(
    key: ProjectReferenceKey.fromNarrativeKey(key),
    label: label == null || label.isEmpty ? key.id : label,
    defined: definitions.isNotEmpty,
    metadata: firstDefinition?.metadata ?? const {},
    navigation: _navigation(navigationIntent),
  );
}

List<ProjectReferenceDiagnostic> _buildDiagnostics(
  NarrativeDependencyIndex index,
) {
  final diagnostics = <ProjectReferenceDiagnostic>[];
  final identities = <String>{};

  void add(ProjectReferenceDiagnostic diagnostic) {
    final identity = [
      diagnostic.code,
      diagnostic.target.toJson(),
      diagnostic.owner?.toJson(),
      diagnostic.fieldPath,
    ].join('|');
    if (identities.add(identity)) diagnostics.add(diagnostic);
  }

  for (final issue in index.issues) {
    final usage = index.usages
        .where(
          (candidate) =>
              candidate.target == issue.target &&
              candidate.owner == issue.owner &&
              (issue.path == null || candidate.path == issue.path),
        )
        .firstOrNull;
    add(
      ProjectReferenceDiagnostic(
        code: 'reference.${issue.kind.name}',
        severity: _severity(issue.criticality),
        message: issue.message,
        target: ProjectReferenceKey.fromNarrativeKey(issue.target),
        owner: issue.owner == null
            ? null
            : ProjectReferenceKey.fromNarrativeKey(issue.owner!),
        fieldPath: issue.path,
        navigation: _navigation(usage?.navigationIntent),
      ),
    );
  }

  for (final usage in index.usages) {
    if (usage.resolution == NarrativeDependencyResolution.resolved) continue;
    add(
      ProjectReferenceDiagnostic(
        code: _diagnosticCode(usage.resolution),
        severity: _severity(usage.criticality),
        message: _diagnosticMessage(usage.resolution),
        target: ProjectReferenceKey.fromNarrativeKey(usage.target),
        owner: ProjectReferenceKey.fromNarrativeKey(usage.owner),
        fieldPath: usage.path,
        navigation: _navigation(usage.navigationIntent),
      ),
    );
  }
  return diagnostics;
}

ProjectReferenceSeverity _severity(
  NarrativeDependencyCriticality criticality,
) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational =>
      ProjectReferenceSeverity.info,
    NarrativeDependencyCriticality.authoringWarning =>
      ProjectReferenceSeverity.warning,
    NarrativeDependencyCriticality.runtimeBlocking =>
      ProjectReferenceSeverity.error,
  };
}

String _diagnosticCode(NarrativeDependencyResolution resolution) {
  return switch (resolution) {
    NarrativeDependencyResolution.resolved => 'reference.resolved',
    NarrativeDependencyResolution.missing => 'reference.missingReference',
    NarrativeDependencyResolution.ambiguous => 'reference.ambiguousReference',
    NarrativeDependencyResolution.unavailable =>
      'reference.unavailableReference',
    NarrativeDependencyResolution.legacyExternal =>
      'reference.legacyExternalReference',
  };
}

String _diagnosticMessage(NarrativeDependencyResolution resolution) {
  return switch (resolution) {
    NarrativeDependencyResolution.resolved => 'Reference resolved.',
    NarrativeDependencyResolution.missing => 'Referenced resource is missing.',
    NarrativeDependencyResolution.ambiguous =>
      'Referenced resource has multiple definitions.',
    NarrativeDependencyResolution.unavailable =>
      'Referenced resource is unavailable.',
    NarrativeDependencyResolution.legacyExternal =>
      'Reference is managed by a legacy external source.',
  };
}

ProjectReferenceNavigation? _navigation(
  NarrativeDependencyNavigationIntent? intent,
) {
  return intent == null
      ? null
      : ProjectReferenceNavigation.fromNarrativeIntent(intent);
}

int _compareNarrativeKeys(
  NarrativeDependencyKey left,
  NarrativeDependencyKey right,
) {
  return compareProjectReferenceKeys(
    ProjectReferenceKey.fromNarrativeKey(left),
    ProjectReferenceKey.fromNarrativeKey(right),
  );
}

Map<String, String> _sortedStringMap(Map<String, String> source) {
  final keys = source.keys.toList()..sort();
  return {
    for (final key in keys) key: source[key]!,
  };
}

String _requireNonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

String? _optionalNonBlank(String? value, String field) {
  if (value == null) return null;
  return _requireNonBlank(value, field);
}
~~~~~~~~

## `packages/map_authoring/lib/src/references/reference_impact.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

import 'project_reference_index.dart';

enum ProjectReferenceImpactKind { deletion, rename }

final class ProjectReferenceImpact {
  ProjectReferenceImpact({
    required this.kind,
    required this.target,
    required this.replacement,
    required Iterable<ProjectReferenceKey> directDependents,
    required Iterable<ProjectReferenceEdge> affectedEdges,
    required Iterable<ProjectReferenceDiagnostic> diagnostics,
    required this.runtimeBlocking,
  })  : directDependents = List.unmodifiable(directDependents),
        affectedEdges = List.unmodifiable(affectedEdges),
        diagnostics = List.unmodifiable(diagnostics);

  final ProjectReferenceImpactKind kind;
  final ProjectReferenceKey target;
  final ProjectReferenceKey? replacement;
  final List<ProjectReferenceKey> directDependents;
  final List<ProjectReferenceEdge> affectedEdges;
  final List<ProjectReferenceDiagnostic> diagnostics;
  final bool runtimeBlocking;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'target': target.toJson(),
        if (replacement != null) 'replacement': replacement!.toJson(),
        'directDependents': directDependents
            .map((dependent) => dependent.toJson())
            .toList(growable: false),
        'affectedEdges':
            affectedEdges.map((edge) => edge.toJson()).toList(growable: false),
        'diagnostics': diagnostics
            .map((diagnostic) => diagnostic.toJson())
            .toList(growable: false),
        'runtimeBlocking': runtimeBlocking,
      };
}

final class ProjectReferenceImpactAnalyzer {
  const ProjectReferenceImpactAnalyzer(this.index);

  final ProjectReferenceIndex index;

  ProjectReferenceImpact deletionImpact(ProjectReferenceKey target) {
    return _impact(
      kind: ProjectReferenceImpactKind.deletion,
      target: target,
    );
  }

  ProjectReferenceImpact renameImpact(
    ProjectReferenceKey target, {
    required String newId,
  }) {
    return _impact(
      kind: ProjectReferenceImpactKind.rename,
      target: target,
      replacement: target.withId(newId),
    );
  }

  ProjectReferenceImpact _impact({
    required ProjectReferenceImpactKind kind,
    required ProjectReferenceKey target,
    ProjectReferenceKey? replacement,
  }) {
    final affectedEdges = index.edges
        .where((edge) => edge.target == target)
        .toList(growable: false);
    final directDependents = affectedEdges.map((edge) => edge.owner).toSet();
    final sortedDependents = directDependents.toList()
      ..sort(compareProjectReferenceKeys);
    final diagnostics = index.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.target == target || diagnostic.owner == target,
        )
        .toList(growable: false);
    return ProjectReferenceImpact(
      kind: kind,
      target: target,
      replacement: replacement,
      directDependents: sortedDependents,
      affectedEdges: affectedEdges,
      diagnostics: diagnostics,
      runtimeBlocking: affectedEdges.any(
        (edge) =>
            edge.criticality == NarrativeDependencyCriticality.runtimeBlocking,
      ),
    );
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/references/reference_queries.dart`

~~~~~~~~dart
import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'project_reference_index.dart';

final class ProjectReferenceGraph {
  ProjectReferenceGraph({
    required Iterable<ProjectReferenceNode> nodes,
    required Iterable<ProjectReferenceEdge> edges,
    required this.truncated,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges);

  final List<ProjectReferenceNode> nodes;
  final List<ProjectReferenceEdge> edges;
  final bool truncated;

  Map<String, Object?> toJson() => {
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
        'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
        'truncated': truncated,
      };
}

final class ProjectReferencePickerOption {
  ProjectReferencePickerOption({
    required this.key,
    required this.label,
    required this.technicalId,
    required this.kindLabel,
    required this.groupLabel,
    required Iterable<String> breadcrumbLabels,
    required this.publicationStatus,
    required this.availability,
    required this.diagnostic,
    required this.navigation,
    required this.usageCount,
  }) : breadcrumbLabels = List.unmodifiable(breadcrumbLabels);

  factory ProjectReferencePickerOption.fromCanonical(
    CanonicalNarrativeReferenceOption option,
  ) {
    return ProjectReferencePickerOption(
      key: ProjectReferenceKey.fromNarrativeKey(option.key),
      label: option.label,
      technicalId: option.technicalId,
      kindLabel: option.kindLabel,
      groupLabel: option.groupLabel,
      breadcrumbLabels: option.breadcrumbLabels,
      publicationStatus: option.publicationStatus.name,
      availability: option.availability.name,
      diagnostic: option.diagnostic,
      navigation: option.navigationIntent == null
          ? null
          : ProjectReferenceNavigation.fromNarrativeIntent(
              option.navigationIntent!,
            ),
      usageCount: option.usageCount,
    );
  }

  final ProjectReferenceKey key;
  final String label;
  final String technicalId;
  final String kindLabel;
  final String groupLabel;
  final List<String> breadcrumbLabels;
  final String publicationStatus;
  final String availability;
  final String? diagnostic;
  final ProjectReferenceNavigation? navigation;
  final int usageCount;

  Map<String, Object?> toJson() => {
        'key': key.toJson(),
        'label': label,
        'technicalId': technicalId,
        'kindLabel': kindLabel,
        'groupLabel': groupLabel,
        'breadcrumbLabels': breadcrumbLabels,
        'publicationStatus': publicationStatus,
        'availability': availability,
        if (diagnostic != null) 'diagnostic': diagnostic,
        if (navigation != null) 'navigation': navigation!.toJson(),
        'usageCount': usageCount,
      };
}

final class ProjectReferencePickerGroup {
  ProjectReferencePickerGroup({
    required this.label,
    required Iterable<ProjectReferencePickerOption> options,
  }) : options = List.unmodifiable(options);

  final String label;
  final List<ProjectReferencePickerOption> options;

  Map<String, Object?> toJson() => {
        'label': label,
        'options':
            options.map((option) => option.toJson()).toList(growable: false),
      };
}

final class ProjectReferencePicker {
  ProjectReferencePicker({
    required Iterable<ProjectReferencePickerGroup> groups,
    required this.missingSelection,
    required this.incompatibleSelection,
  }) : groups = List.unmodifiable(groups);

  final List<ProjectReferencePickerGroup> groups;
  final ProjectReferencePickerOption? missingSelection;
  final ProjectReferencePickerOption? incompatibleSelection;

  Map<String, Object?> toJson() => {
        'groups': groups.map((group) => group.toJson()).toList(growable: false),
        if (missingSelection != null)
          'missingSelection': missingSelection!.toJson(),
        if (incompatibleSelection != null)
          'incompatibleSelection': incompatibleSelection!.toJson(),
      };
}

final class ProjectReferenceQueries {
  const ProjectReferenceQueries(this.index);

  final ProjectReferenceIndex index;

  List<ProjectReferenceEdge> dependencies(ProjectReferenceKey owner) {
    return List.unmodifiable(
      index.edges.where((edge) => edge.owner == owner),
    );
  }

  List<ProjectReferenceEdge> dependents(ProjectReferenceKey target) {
    return List.unmodifiable(
      index.edges.where((edge) => edge.target == target),
    );
  }

  List<ProjectReferenceDiagnostic> brokenReferences() {
    return List.unmodifiable(index.diagnostics);
  }

  ProjectReferenceGraph graph(
    ProjectReferenceKey root, {
    int maxDepth = 4,
    int maxNodes = 100,
  }) {
    if (maxDepth < 0) {
      throw ArgumentError.value(maxDepth, 'maxDepth', 'must be non-negative');
    }
    if (maxNodes <= 0) {
      throw ArgumentError.value(maxNodes, 'maxNodes', 'must be positive');
    }
    final rootNode = index.nodeFor(root);
    if (rootNode == null) {
      throw ArgumentError.value(root, 'root', 'does not exist in the index');
    }

    final visited = <ProjectReferenceKey>{root};
    final queue = Queue<_GraphVisit>()..add(_GraphVisit(root, 0));
    var truncated = false;
    while (queue.isNotEmpty) {
      final visit = queue.removeFirst();
      final outgoing = dependencies(visit.key);
      if (visit.depth >= maxDepth) {
        if (outgoing.any((edge) => !visited.contains(edge.target))) {
          truncated = true;
        }
        continue;
      }
      for (final edge in outgoing) {
        if (visited.contains(edge.target)) continue;
        if (visited.length >= maxNodes) {
          truncated = true;
          continue;
        }
        visited.add(edge.target);
        queue.add(_GraphVisit(edge.target, visit.depth + 1));
      }
    }

    final sortedNodes = visited
        .map(index.nodeFor)
        .whereType<ProjectReferenceNode>()
        .toList()
      ..sort((left, right) => compareProjectReferenceKeys(left.key, right.key));
    final edges = index.edges
        .where(
          (edge) =>
              visited.contains(edge.owner) && visited.contains(edge.target),
        )
        .toList(growable: false);
    return ProjectReferenceGraph(
      nodes: sortedNodes,
      edges: edges,
      truncated: truncated,
    );
  }

  ProjectReferencePicker picker({
    required Set<NarrativeDependencyTargetKind> allowedKinds,
    NarrativeDependencyKey? selectedKey,
    Map<NarrativeDependencyKey, String> incompatibleReasons = const {},
  }) {
    final canonical = buildCanonicalNarrativeReferencePickerReadModel(
      index: index.narrativeIndex,
      allowedKinds: allowedKinds,
      selectedKey: selectedKey,
      incompatibleReasons: incompatibleReasons,
    );
    return ProjectReferencePicker(
      groups: canonical.groups.map(
        (group) => ProjectReferencePickerGroup(
          label: group.label,
          options: group.options.map(
            ProjectReferencePickerOption.fromCanonical,
          ),
        ),
      ),
      missingSelection: canonical.missingSelection == null
          ? null
          : ProjectReferencePickerOption.fromCanonical(
              canonical.missingSelection!,
            ),
      incompatibleSelection: canonical.incompatibleSelection == null
          ? null
          : ProjectReferencePickerOption.fromCanonical(
              canonical.incompatibleSelection!,
            ),
    );
  }
}

final class _GraphVisit {
  const _GraphVisit(this.key, this.depth);

  final ProjectReferenceKey key;
  final int depth;
}
~~~~~~~~

## `packages/map_authoring/test/domains/project/capability_truth_adapter_test.dart`

~~~~~~~~dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectCapabilityTruthAdapter', () {
    test('preserves an explicit promoted attestation', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [
          ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'narrative.command.dialogue',
            authoringControl: 'Dialogue picker',
            contractField: 'DialogueCommand.dialogueId',
            runtimeConsumer: 'DialogueCommandRunner',
            playerSurface: 'Dialogue overlay',
            positiveTest: 'dialogue_positive_test.dart',
            negativeTest: 'dialogue_missing_test.dart',
          ),
        ],
        requiredCapabilityIds: const {'narrative.command.dialogue'},
      );

      expect(truth.isPassing, isTrue);
      expect(truth.capabilities.single.toJson(), {
        'capabilityId': 'narrative.command.dialogue',
        'authoringControl': 'Dialogue picker',
        'contractField': 'DialogueCommand.dialogueId',
        'runtimeConsumer': 'DialogueCommandRunner',
        'playerSurface': 'Dialogue overlay',
        'positiveTest': 'dialogue_positive_test.dart',
        'negativeTest': 'dialogue_missing_test.dart',
        'status': 'promoted',
        'reason': null,
      });
      expect(truth.issues, isEmpty);
    });

    test('preserves deferred reasons without pretending support', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [
          ProjectCapabilityTruthRecord.deferred(
            capabilityId: 'battle.held-items',
            reason: 'Runtime bridge not delivered.',
          ),
        ],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(truth.isPassing, isFalse);
      expect(truth.capabilities.single.status, 'deferred');
      expect(
        truth.capabilities.single.reason,
        'Runtime bridge not delivered.',
      );
      expect(
        truth.issues.map((issue) => issue.code),
        contains('noPromotedCapabilities'),
      );
    });

    test('keeps missing attestations as coded issues', () {
      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [],
        requiredCapabilityIds: const {
          'narrative.command.dialogue',
          'narrative.command.setFact',
        },
      );

      expect(
        truth.issues
            .where((issue) => issue.code == 'missingExpectedCapability')
            .map((issue) => issue.capabilityId),
        [
          'narrative.command.dialogue',
          'narrative.command.setFact',
        ],
      );
      expect(
        truth.issues.map((issue) => issue.code),
        contains('noPromotedCapabilities'),
      );
    });

    test('is deterministic independently of record and requirement order', () {
      const promoted = ProjectCapabilityTruthRecord.promoted(
        capabilityId: 'capability.a',
        authoringControl: 'control',
        contractField: 'contract',
        runtimeConsumer: 'runtime',
        playerSurface: 'surface',
        positiveTest: 'positive',
        negativeTest: 'negative',
      );
      const deferred = ProjectCapabilityTruthRecord.deferred(
        capabilityId: 'capability.b',
        reason: 'Deferred.',
      );

      final forward = ProjectCapabilityTruthAdapter.evaluate(
        records: const [promoted, deferred],
        requiredCapabilityIds: const {'capability.a', 'capability.b'},
      );
      final reverse = ProjectCapabilityTruthAdapter.evaluate(
        records: const [deferred, promoted],
        requiredCapabilityIds: {'capability.b', 'capability.a'},
      );

      expect(forward.toJson(), reverse.toJson());
    });

    test('does not promote capabilities from populated project models', () {
      final manifest = ProjectManifest(
        name: 'Populated project',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'fact.ready',
            label: 'Ready',
          ),
        ],
      );
      expect(manifest.facts, isNotEmpty);

      final truth = ProjectCapabilityTruthAdapter.evaluate(
        records: const [],
        requiredCapabilityIds: const {'narrative.fact'},
      );

      expect(truth.capabilities, isEmpty);
      expect(truth.isPassing, isFalse);
      expect(
        truth.issues.map((issue) => issue.code),
        containsAll([
          'missingExpectedCapability',
          'noPromotedCapabilities',
        ]),
      );
    });
  });
}
~~~~~~~~

## `packages/map_authoring/test/references/project_reference_index_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReferenceIndex', () {
    test('adapts cross-domain references from the real project snapshot',
        () async {
      final snapshot = await _realSnapshot();

      final index = ProjectReferenceIndex.fromSnapshot(snapshot);

      expect(index.nodes, isNotEmpty);
      expect(
        index.nodes.map((node) => node.key.kind).toSet(),
        contains(NarrativeDependencyTargetKind.sourceMap.name),
      );
      expect(
        index.nodes.any(
          (node) =>
              node.key.kind == NarrativeDependencyTargetKind.sourceMap.name &&
              node.key.sourceKind == 'map',
        ),
        isTrue,
      );
      expect(index.edges, isNotEmpty);
      final physicalMap = index.nodes.singleWhere(
        (node) =>
            node.key.kind == NarrativeDependencyTargetKind.sourceMap.name &&
            node.key.sourceKind == 'map',
      );
      expect(physicalMap.key.toResourceRef().toJson(), {
        'kind': NarrativeDependencyTargetKind.sourceMap.name,
        'id': physicalMap.key.id,
        'extensions': {
          'scope': physicalMap.key.scope,
          'parentId': physicalMap.key.parentId,
          'sourceKind': 'map',
        },
      });
      expect(jsonEncode(index.toJson()), isNotEmpty);
      expect(index.toJson().toString(), isNot(contains('/Users/')));
    });

    test('provides deterministic dependency and dependent directions', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.ready',
      );
      const scene = NarrativeDependencyKey.scene('scene.intro');
      const storyline = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        'story.main',
      );
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: fact, label: 'Ready'),
            NarrativeDependencyDefinition(key: scene, label: 'Intro'),
            NarrativeDependencyDefinition(key: storyline, label: 'Main'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: fact,
              owner: scene,
              path: 'scenes[scene.intro].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            ),
            NarrativeDependencyUsage(
              target: scene,
              owner: storyline,
              path: 'storylines[story.main].sceneId',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
          ],
        ),
      );
      final queries = ProjectReferenceQueries(index);

      expect(
        queries
            .dependencies(ProjectReferenceKey.fromNarrativeKey(scene))
            .map((edge) => edge.target.id),
        ['fact.ready'],
      );
      expect(
        queries
            .dependents(ProjectReferenceKey.fromNarrativeKey(scene))
            .map((edge) => edge.owner.id),
        ['story.main'],
      );
    });

    test('keeps broken references coded and navigable', () {
      const missing = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.missing',
      );
      const owner = NarrativeDependencyKey.scene('scene.owner');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: owner, label: 'Owner'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: missing,
              owner: owner,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
              resolution: NarrativeDependencyResolution.missing,
              navigationIntent: NarrativeDependencyNavigationIntent(
                kind: NarrativeDependencyTargetKind.scene,
                assetId: 'scene.owner',
                context: 'scenes[scene.owner].condition',
              ),
            ),
          ],
          issues: const [
            NarrativeDependencyIssue(
              kind: NarrativeDependencyIssueKind.missingReference,
              target: missing,
              owner: owner,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
              message: 'Missing fact.',
            ),
          ],
        ),
      );

      final broken = ProjectReferenceQueries(index).brokenReferences();

      expect(broken, hasLength(1));
      expect(broken.single.code, 'reference.missingReference');
      expect(broken.single.target.id, 'fact.missing');
      expect(broken.single.owner?.id, 'scene.owner');
      expect(broken.single.navigation, isNotNull);
      expect(broken.single.severity, ProjectReferenceSeverity.error);
    });

    test('bounded graph terminates cycles and reports truncation', () {
      const a = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'a',
      );
      const b = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'b',
      );
      const c = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'c',
      );
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: a, label: 'A'),
            NarrativeDependencyDefinition(key: b, label: 'B'),
            NarrativeDependencyDefinition(key: c, label: 'C'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: b,
              owner: a,
              path: 'a.toB',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: a,
              owner: b,
              path: 'b.toA',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: c,
              owner: b,
              path: 'b.toC',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
          ],
        ),
      );
      final queries = ProjectReferenceQueries(index);
      final complete = queries.graph(
        ProjectReferenceKey.fromNarrativeKey(a),
        maxDepth: 8,
        maxNodes: 20,
      );
      final bounded = queries.graph(
        ProjectReferenceKey.fromNarrativeKey(a),
        maxDepth: 8,
        maxNodes: 2,
      );

      expect(complete.nodes.map((node) => node.key.id), ['a', 'b', 'c']);
      expect(complete.truncated, isFalse);
      expect(bounded.nodes, hasLength(2));
      expect(bounded.truncated, isTrue);
    });

    test('computes deterministic delete and rename impact', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.old',
      );
      const scene = NarrativeDependencyKey.scene('scene.owner');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: fact, label: 'Old'),
            NarrativeDependencyDefinition(key: scene, label: 'Owner'),
          ],
          usages: const [
            NarrativeDependencyUsage(
              target: fact,
              owner: fact,
              path: 'facts[fact.old].self',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            ),
            NarrativeDependencyUsage(
              target: fact,
              owner: scene,
              path: 'scenes[scene.owner].condition',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            ),
          ],
        ),
      );
      final analyzer = ProjectReferenceImpactAnalyzer(index);
      final target = ProjectReferenceKey.fromNarrativeKey(fact);

      final deletion = analyzer.deletionImpact(target);
      final rename = analyzer.renameImpact(target, newId: 'fact.new');

      expect(
        deletion.directDependents.map((dependent) => dependent.id),
        ['fact.old', 'scene.owner'],
      );
      expect(deletion.affectedEdges, hasLength(2));
      expect(deletion.runtimeBlocking, isTrue);
      expect(rename.replacement?.id, 'fact.new');
      expect(rename.directDependents, deletion.directDependents);
    });

    test('reuses canonical picker read models including missing selection', () {
      const map = NarrativeDependencyKey.map('map.port');
      const scene = NarrativeDependencyKey.scene('scene.port');
      final index = ProjectReferenceIndex.fromNarrativeIndex(
        NarrativeDependencyIndex(
          definitions: [
            NarrativeDependencyDefinition(key: map, label: 'Port'),
            NarrativeDependencyDefinition(key: scene, label: 'Arrival'),
          ],
        ),
      );

      final picker = ProjectReferenceQueries(index).picker(
        allowedKinds: const {NarrativeDependencyTargetKind.scene},
        selectedKey: const NarrativeDependencyKey.scene('scene.missing'),
      );

      expect(picker.groups.single.label, 'Scenes');
      expect(picker.groups.single.options.single.key.id, 'scene.port');
      expect(picker.missingSelection?.key.id, 'scene.missing');
      expect(
        picker.missingSelection?.availability,
        NarrativeReferenceAvailability.missing.name,
      );
    });

    test('is deterministic independently of source declaration order', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.ready',
      );
      const scene = NarrativeDependencyKey.scene('scene.intro');
      final forward = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: fact, label: 'Ready'),
          NarrativeDependencyDefinition(key: scene, label: 'Intro'),
        ],
      );
      final reverse = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: scene, label: 'Intro'),
          NarrativeDependencyDefinition(key: fact, label: 'Ready'),
        ],
      );

      expect(
        ProjectReferenceIndex.fromNarrativeIndex(forward).toJson(),
        ProjectReferenceIndex.fromNarrativeIndex(reverse).toJson(),
      );
    });
  });
}

Future<ProjectSnapshot> _realSnapshot() async {
  final fixture = Directory(
    [
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ].join(Platform.pathSeparator),
  );
  var token = 0;
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [fixture.parent.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore(
    clock: () => DateTime.utc(2026, 7, 31, 12),
    tokenFactory: (prefix) => '$prefix${token++}',
  );
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(fixture.path);
  return ProjectSnapshotLoader(handles: handles).load(opened.projectHandle);
}
~~~~~~~~
