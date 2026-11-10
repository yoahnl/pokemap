import 'package:map_core/map_core_domain.dart';

class StoryCoherenceEntry {
  const StoryCoherenceEntry._({
    this.progression,
    this.sceneLink,
    this.node,
    this.edge,
    this.sceneTarget,
  });

  final StorylineProgressionDiagnostic? progression;
  final StorylineSceneLinkDiagnostic? sceneLink;
  final StorylineProgressionNode? node;
  final StorylineProgressionEdge? edge;
  final ({String id, String name})? sceneTarget;
  String get message => progression?.message ?? sceneLink!.message;
  String? get graphTargetId => edge?.id ?? node?.id;
}

List<StoryCoherenceEntry> storyCoherence(
  ProjectManifest project,
  String storyId,
) {
  final projection = buildStorylineProgressionProjection(
    project: project,
    storylineId: storyId,
  );
  final links = diagnoseStorylineSceneLinks(project: project).diagnostics
      .where((diagnostic) => diagnostic.storylineId == storyId);
  final scenes = {for (final scene in project.scenes) scene.id: scene};
  final nodes = {for (final node in projection.nodes) node.id: node};
  final edges = <String, StorylineProgressionEdge>{};
  for (final edge in projection.edges) {
    edges.putIfAbsent(edge.id, () => edge);
  }
  return List.unmodifiable([
    for (final diagnostic in projection.diagnostics)
      StoryCoherenceEntry._(
        progression: diagnostic,
        node: nodes[diagnostic.nodeId],
        edge: edges[diagnostic.edgeId],
      ),
    for (final diagnostic in links)
      StoryCoherenceEntry._(
        sceneLink: diagnostic,
        node: nodes['step:${diagnostic.stepId}'],
        sceneTarget: switch (diagnostic.code) {
          StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink ||
          StorylineSceneLinkDiagnosticCode.storylineStepDuplicateSceneLink ||
          StorylineSceneLinkDiagnosticCode.storylineStepLinkedSceneHasErrors ||
          StorylineSceneLinkDiagnosticCode
              .storylineStepLinkedSceneNotRuntimeBuildable =>
            switch (scenes[diagnostic.sceneId]) {
              final scene? => (id: scene.id, name: scene.name),
              null => null,
            },
          _ => null,
        },
      ),
  ]);
}
