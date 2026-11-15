import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_step_form.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const _plainKinds = {
  SceneNodeKind.start,
  SceneNodeKind.end,
  SceneNodeKind.merge,
};

const _translatedProblems = {
  SceneDiagnosticCode.requiredOutputPortMissing,
  SceneDiagnosticCode.unreachableNode,
  SceneDiagnosticCode.unreachableEndNode,
  SceneDiagnosticCode.cycleUnsupported,
  SceneDiagnosticCode.missingEndNode,
  SceneDiagnosticCode.duplicateOutgoingPortEdge,
  SceneDiagnosticCode.edgeFromPortUnsupported,
  SceneDiagnosticCode.emptyGraph,
};

String sceneGraphProblemText(
  AppLocalizations l10n,
  SceneGraphProblem problem,
) => switch (problem) {
  SceneGraphProblem(
    code: SceneDiagnosticCode.unreachableEndNode,
    nodeId: null,
  ) =>
    l10n.sceneGraphProblem('noReachableEnd'),
  _ when _translatedProblems.contains(problem.code) => l10n.sceneGraphProblem(
    problem.code.name,
  ),
  _ => problem.message,
};

class SceneGraphInspector extends StatelessWidget {
  const SceneGraphInspector({
    super.key,
    required this.scene,
    required this.project,
    required this.map,
    required this.selection,
    required this.checks,
    required this.editable,
    required this.onEdit,
    required this.onShow,
  });

  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;
  final Set<String> selection;
  final SceneGraphChecks checks;
  final bool editable;
  final ValueChanged<SceneNode> onEdit;
  final ValueChanged<String> onShow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final node = selection.length == 1
        ? scene.graph.nodes.where((n) => n.id == selection.single).firstOrNull
        : null;
    if (node != null) {
      final title = node.title?.trim();
      return StudioSection(
        key: ValueKey('scene-graph-inspector-${node.id}'),
        title: l10n.sceneGraphKind(node.kind.name),
        children: [
          if (title != null && title.isNotEmpty)
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (SceneStepForm.covers(node))
            SceneStepForm(
              scene: scene,
              project: project,
              map: map,
              node: node,
              enabled: editable,
              onEdit: onEdit,
            )
          else if (!_plainKinds.contains(node.kind)) ...[
            Text(l10n.storyStepAdvanced),
            SceneStepCaption(l10n.storyStepAdvancedHint),
          ],
          for (final problem in checks.ofNode(node.id))
            _Problem(problem: problem, onTap: null),
        ],
      );
    }
    if (selection.length > 1) {
      return StudioSection(
        key: const ValueKey('scene-graph-inspector-many'),
        title: l10n.sceneGraphSelectionCount(selection.length),
        children: const [],
      );
    }
    return StudioSection(
      key: const ValueKey('scene-graph-checks'),
      title: l10n.sceneGraphChecksTitle,
      children: [
        if (checks.problems.isEmpty)
          SceneStepCaption(l10n.sceneGraphChecksClear),
        for (final (index, problem) in checks.problems.indexed)
          _Problem(
            key: ValueKey('scene-graph-problem-$index'),
            problem: problem,
            onTap: switch (problem.nodeId) {
              final id? => () => onShow(id),
              null => null,
            },
          ),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({super.key, required this.problem, required this.onTap});

  final SceneGraphProblem problem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final blocking = problem.level == SceneGraphProblemLevel.blocking;
    return StudioChoice(
      label: sceneGraphProblemText(l10n, problem),
      subtitle: blocking ? l10n.sceneGraphBlocking : null,
      maxLines: 3,
      tone: blocking ? StudioTone.danger : StudioTone.warning,
      onTap: onTap,
    );
  }
}
