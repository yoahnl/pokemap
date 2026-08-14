import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/resource_ref.dart';
import '../domains/assets/asset_store.dart';
import '../domains/assets/project_media_store.dart';
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
    this.action,
    required this.target,
    this.owner,
    this.fieldPath,
    this.navigation,
  });

  final String code;
  final ProjectReferenceSeverity severity;
  final String message;
  final String? action;
  final ProjectReferenceKey target;
  final ProjectReferenceKey? owner;
  final String? fieldPath;
  final ProjectReferenceNavigation? navigation;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        if (action != null) 'action': action,
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

  factory ProjectReferenceIndex.fromSnapshot(
    ProjectSnapshot snapshot, {
    Iterable<PresentationCinematicAsset> presentationCinematics = const [],
  }) {
    final projectMediaCatalog = _projectMediaCatalog(snapshot);
    final sourceAssets = projectMediaCatalog == null
        ? const <ProjectMediaSourceAssetDefinition>[]
        : _projectMediaSourceAssets(snapshot);
    final narrative = ProjectReferenceIndex.fromNarrativeIndex(
      buildNarrativeDependencyIndex(
        project: snapshot.manifest,
        maps: snapshot.maps,
      ),
    );
    final presentation = PresentationReferenceGraph.build(
      cinematics: presentationCinematics,
      scenes: snapshot.manifest.scenes,
      mediaCatalog: projectMediaCatalog,
      sourceAssets: sourceAssets,
    );
    return narrative._withPresentationGraph(presentation);
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

  ProjectReferenceIndex _withPresentationGraph(
    PresentationReferenceGraph presentation,
  ) {
    final nodesByKey = <ProjectReferenceKey, ProjectReferenceNode>{
      for (final node in nodes) node.key: node,
    };
    for (final node in presentation.nodes) {
      final key = _presentationKey(node.key);
      final existing = nodesByKey[key];
      final metadata = <String, String>{
        ...?existing?.metadata,
        if (node.mediaType != null) 'mediaType': node.mediaType!.id,
      };
      nodesByKey[key] = ProjectReferenceNode(
        key: key,
        label: existing?.label ?? node.label,
        defined: (existing?.defined ?? false) || node.defined,
        metadata: metadata,
        navigation: existing?.navigation ?? _presentationNavigation(key),
      );
    }

    final mergedEdges = <ProjectReferenceEdge>[
      ...edges,
      for (final edge in presentation.edges)
        ProjectReferenceEdge(
          owner: _presentationKey(edge.owner),
          target: _presentationKey(edge.target),
          path: edge.path,
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: switch (edge.resolution) {
            PresentationReferenceResolution.resolved =>
              NarrativeDependencyResolution.resolved,
            PresentationReferenceResolution.missing =>
              NarrativeDependencyResolution.missing,
            PresentationReferenceResolution.incompatible =>
              NarrativeDependencyResolution.unavailable,
          },
          navigation: _presentationNavigation(
            _presentationKey(edge.owner),
            context: edge.path,
          ),
        ),
    ]..sort(compareProjectReferenceEdges);

    final mergedDiagnostics = <ProjectReferenceDiagnostic>[
      ...diagnostics,
      for (final diagnostic in presentation.diagnostics)
        ProjectReferenceDiagnostic(
          code: diagnostic.code,
          severity: ProjectReferenceSeverity.error,
          message: diagnostic.message,
          action: diagnostic.action,
          target: _presentationKey(diagnostic.target),
          owner: diagnostic.owner == null
              ? null
              : _presentationKey(diagnostic.owner!),
          fieldPath: diagnostic.path,
          navigation: diagnostic.owner == null
              ? null
              : _presentationNavigation(
                  _presentationKey(diagnostic.owner!),
                  context: diagnostic.path,
                ),
        ),
    ]..sort(compareProjectReferenceDiagnostics);

    return ProjectReferenceIndex._(
      narrativeIndex: _narrativeIndex,
      nodes: nodesByKey.values.toList()
        ..sort(
            (left, right) => compareProjectReferenceKeys(left.key, right.key)),
      edges: _deduplicateEdges(mergedEdges),
      diagnostics: _deduplicateProjectDiagnostics(mergedDiagnostics),
    );
  }

  Map<String, Object?> toJson() => {
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
        'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
        'diagnostics': diagnostics
            .map((diagnostic) => diagnostic.toJson())
            .toList(growable: false),
      };
}

ProjectMediaCatalog? _projectMediaCatalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
  return bytes == null ? null : decodeProjectMediaCatalogBytes(bytes);
}

List<ProjectMediaSourceAssetDefinition> _projectMediaSourceAssets(
  ProjectSnapshot snapshot,
) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return const [];
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw const FormatException('Asset catalog must be an object');
  }
  final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  return List.unmodifiable([
    for (final asset in catalog.records)
      ProjectMediaSourceAssetDefinition(
        id: asset.id,
        label: asset.logicalPath,
      ),
  ]);
}

ProjectReferenceKey _presentationKey(PresentationReferenceKey key) {
  return ProjectReferenceKey(
    kind: key.kind.name,
    id: key.id,
    parentId: key.parentId,
  );
}

ProjectReferenceNavigation _presentationNavigation(
  ProjectReferenceKey key, {
  String? context,
}) {
  return ProjectReferenceNavigation(
    kind: key.kind,
    assetId: key.id,
    parentId: key.parentId,
    context: context,
  );
}

List<ProjectReferenceEdge> _deduplicateEdges(
  Iterable<ProjectReferenceEdge> source,
) {
  final identities = <String>{};
  return [
    for (final edge in source)
      if (identities.add(
        '${edge.owner.toJson()}|${edge.target.toJson()}|${edge.path}|'
        '${edge.criticality.name}|${edge.resolution.name}',
      ))
        edge,
  ];
}

List<ProjectReferenceDiagnostic> _deduplicateProjectDiagnostics(
  Iterable<ProjectReferenceDiagnostic> source,
) {
  final identities = <String>{};
  return [
    for (final diagnostic in source)
      if (identities.add(
        '${diagnostic.code}|${diagnostic.target.toJson()}|'
        '${diagnostic.owner?.toJson()}|${diagnostic.fieldPath}',
      ))
        diagnostic,
  ];
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
