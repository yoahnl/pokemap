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
