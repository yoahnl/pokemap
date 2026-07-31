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
