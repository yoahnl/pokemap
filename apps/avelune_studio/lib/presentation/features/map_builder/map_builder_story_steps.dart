import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_node_edit.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_projection.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

part 'map_builder_story_steps_card.dart';
part 'map_builder_story_steps_forms.dart';
part 'map_builder_story_steps_menu.dart';

class MapBuilderStorySteps extends StatelessWidget {
  const MapBuilderStorySteps({
    super.key,
    required this.scene,
    required this.project,
    required this.map,
    required this.enabled,
    required this.onChanged,
    this.highlighted,
  });

  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;
  final bool enabled;
  final bool Function(SceneAsset next) onChanged;
  final Set<String>? highlighted;

  @override
  Widget build(BuildContext context) {
    final projection = projectSceneSteps(scene.graph);
    final steps = _Steps(this, projection, context);
    return Column(
      key: const ValueKey('story-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(context.l10n.storyStepsTitle),
        const SizedBox(height: StudioSpacing.s),
        switch (projection) {
          SceneStepList(:final root) => _Sequence(
            steps: steps,
            sequence: root,
            blockNodeId: null,
            branchIndex: 0,
          ),
          SceneStepTrueGraph() => _ReadOnlyGraph(
            key: const ValueKey('story-steps-true-graph'),
            steps: steps,
            explanation: context.l10n.storyStepTrueGraph,
          ),
          SceneStepLoop() => _ReadOnlyGraph(
            key: const ValueKey('story-steps-loop'),
            steps: steps,
            explanation: context.l10n.storyStepLoop,
          ),
        },
      ],
    );
  }
}

final class _Steps {
  _Steps(this.widget, this.projection, this.context);

  final MapBuilderStorySteps widget;
  final SceneStepProjection projection;
  final BuildContext context;

  bool get editable => widget.enabled && projection is SceneStepList;
  ProjectManifest get project => widget.project;
  MapData? get map => widget.map;
  AppLocalizations get l10n => context.l10n;

  SceneNode? node(String nodeId) => projection.node(nodeId);

  SceneStepIds get _ids {
    final taken = {
      for (final node in widget.scene.graph.nodes) node.id,
      for (final edge in widget.scene.graph.edges) edge.id,
    };
    String next(String prefix) {
      var index = taken.length;
      while (!taken.add('${prefix}_$index')) {
        index++;
      }
      return '${prefix}_$index';
    }

    return SceneStepIds(node: () => next('step'), edge: () => next('link'));
  }

  void _apply(SceneStepEditResult result) {
    switch (result) {
      case SceneStepEdited(:final scene):
        if (!identical(scene, widget.scene)) widget.onChanged(scene);
      case SceneStepEditRefused():
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l10n.storyStepRefused)));
    }
  }

  void insert(SceneStepSlot at, _NewStep step) => _apply(
    insertSceneStep(
      widget.scene,
      at: at,
      kind: step.kind,
      payload: step.payload,
      ids: _ids,
    ),
  );

  void move(String nodeId, SceneStepSlot to) =>
      _apply(moveSceneStep(widget.scene, nodeId: nodeId, to: to, ids: _ids));

  void remove(String nodeId) =>
      _apply(removeSceneStep(widget.scene, nodeId: nodeId, ids: _ids));

  void wrap(SceneStepSlot from, SceneConditionPayload condition) => _apply(
    wrapSceneStepsInCondition(
      widget.scene,
      from: from,
      count: 1,
      condition: condition,
      ids: _ids,
    ),
  );

  void edit(SceneNode node) =>
      _apply(editSceneStepNode(widget.scene, node: node));
}

class _Sequence extends StatelessWidget {
  const _Sequence({
    required this.steps,
    required this.sequence,
    required this.blockNodeId,
    required this.branchIndex,
  });

  final _Steps steps;
  final SceneStepSequence sequence;
  final String? blockNodeId;
  final int branchIndex;

  String get _key => blockNodeId == null ? 'root' : '$blockNodeId-$branchIndex';

  SceneStepSlot _slot(int index) => SceneStepSlot(
    blockNodeId: blockNodeId,
    branchIndex: branchIndex,
    index: index,
  );

  @override
  Widget build(BuildContext context) {
    final items = sequence.steps;
    final open = items.isEmpty || items.last.flowsOn;
    return Column(
      key: ValueKey('story-step-sequence-$_key'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, step) in items.indexed) ...[
          _DropZone(steps: steps, slot: _slot(index), name: '$_key-$index'),
          _StepView(steps: steps, step: step, slot: _slot(index)),
        ],
        if (open)
          _DropZone(
            steps: steps,
            slot: _slot(items.length),
            name: '$_key-${items.length}',
          ),
        if (items.isEmpty) _Caption(steps.l10n.storyStepEmpty),
        if (steps.editable && open)
          _AddStep(
            key: ValueKey('story-step-add-$_key'),
            steps: steps,
            slot: _slot(items.length),
          ),
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.steps,
    required this.slot,
    required this.name,
  });

  final _Steps steps;
  final SceneStepSlot slot;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      key: ValueKey('story-step-drop-$name'),
      onWillAcceptWithDetails: (_) => steps.editable,
      onAcceptWithDetails: (details) => steps.move(details.data, slot),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: candidates.isEmpty ? StudioSpacing.s : StudioSpacing.xl,
        margin: const EdgeInsets.symmetric(vertical: StudioSpacing.xxs),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? null
              : scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}
