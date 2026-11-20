import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_summary.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_path_preview.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_ports.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_behaviour_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneFocusSide extends StatelessWidget {
  const SceneFocusSide({
    super.key,
    required this.focus,
    this.leading,
    this.onOpenBehaviour,
    this.dialogues = const {},
    this.choiceLabels = const {},
    this.dialogueNotices = const [],
  });

  final SceneFocusController focus;
  final Widget? leading;
  final Future<bool> Function(String eventId)? onOpenBehaviour;
  final Map<String, ProjectDialogueEntry> dialogues;
  final Map<String, Map<String, String>> choiceLabels;
  final List<Widget> dialogueNotices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final launchers = focus.launchers;
    final facts = focus.changedFactIds;
    final path = focus.path;
    final details = ListView(
      key: const ValueKey('scene-focus-side'),
      padding: const EdgeInsets.all(StudioSpacing.l),
      children: [
        if (dialogueNotices.isNotEmpty)
          StudioSection(
            title: l10n.sceneGraphDialoguePreview,
            children: dialogueNotices,
          ),
        if (path != null)
          _PathSection(
            focus: focus,
            path: path,
            dialogues: dialogues,
            choiceLabels: choiceLabels,
          ),
        ?leading,
        StudioSection(
          title: l10n.sceneFocusLaunchedBy,
          children: [
            if (launchers.isEmpty)
              Text(l10n.sceneFocusNoLauncher, style: small),
            for (final record in launchers)
              Padding(
                key: ValueKey('scene-focus-launcher-${record.id}'),
                padding: const EdgeInsets.only(bottom: StudioSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name.trim().isEmpty
                          ? l10n.behavioursUnnamed
                          : record.name,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(_place(l10n, focus.place(record)), style: small),
                    if (onOpenBehaviour != null &&
                        focus.place(record).target != null)
                      StudioButton(
                        key: ValueKey(
                          'scene-focus-open-behaviour-${record.id}',
                        ),
                        label: l10n.behavioursOpenMap,
                        icon: Icons.open_in_new,
                        variant: StudioButtonVariant.quiet,
                        onPressed: () => onOpenBehaviour!(record.id),
                      ),
                    Text(
                      l10n.behaviourSummary(
                        summarizeGameBehaviour(
                          record,
                          (id) => id == focus.sceneId ? focus.scene : null,
                        ),
                        focus.factName,
                      ),
                      style: small,
                    ),
                  ],
                ),
              ),
          ],
        ),
        StudioSection(
          title: l10n.sceneFocusChangedFacts,
          children: [
            if (facts.isEmpty) Text(l10n.sceneFocusNoFactChange, style: small),
            for (final id in facts)
              Text(
                focus.factName(id) ?? l10n.memoryUnknownFact,
                key: ValueKey('scene-focus-fact-$id'),
              ),
          ],
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioPageHeader.section(
              title: l10n.inspectorTitle,
              minHeight: StudioMetrics.controlHeight,
            ),
            Expanded(child: details),
          ],
        ),
      ),
    );
  }

  String _place(AppLocalizations l10n, SceneLauncherPlace place) =>
      switch (place.target) {
        null => l10n.behavioursWithoutMap,
        final target => l10n.behavioursPlace(
          place.mapName ?? l10n.behavioursMissingMap,
          place.elementName ??
              l10n.behavioursElementKind(
                target == MapStoryElementTarget.map ? 'map' : target.name,
              ),
        ),
      };
}

class _PathSection extends StatelessWidget {
  const _PathSection({
    required this.focus,
    required this.path,
    required this.dialogues,
    required this.choiceLabels,
  });

  final SceneFocusController focus;
  final ScenePath path;
  final Map<String, ProjectDialogueEntry> dialogues;
  final Map<String, Map<String, String>> choiceLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    final graph = focus.scene!.graph;
    final nodes = {for (final node in graph.nodes) node.id: node};
    final choice = path.choiceNodeId;
    return StudioSection(
      title: l10n.sceneFocusPath,
      children: [
        Text(l10n.sceneFocusPathHint, style: small),
        const SizedBox(height: StudioSpacing.s),
        for (final (index, id) in path.nodeIds.indexed)
          Text(
            '${index + 1}. ${_label(l10n, nodes[id])}',
            key: ValueKey('scene-focus-path-$id'),
          ),
        const SizedBox(height: StudioSpacing.s),
        if (choice != null) ...[
          Text(l10n.sceneFocusChooseExit, style: small),
          const SizedBox(height: StudioSpacing.xs),
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              for (final exit in path.exits)
                StudioButton(
                  key: ValueKey('scene-focus-exit-${exit.portId}'),
                  label: _exit(l10n, nodes[choice], exit.portId),
                  variant: StudioButtonVariant.secondary,
                  onPressed: () => focus.choose(choice, exit.portId),
                ),
            ],
          ),
        ],
        if (path.ended) Text(l10n.sceneFocusPathEnded, style: small),
        if (path.looped) Text(l10n.sceneFocusPathLooped, style: small),
        const SizedBox(height: StudioSpacing.s),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: const ValueKey('scene-focus-restart'),
            label: l10n.sceneFocusRestart,
            icon: Icons.restart_alt,
            variant: StudioButtonVariant.quiet,
            onPressed: focus.choices.isEmpty ? null : focus.restart,
          ),
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, SceneNode? node) {
    if (node == null) return l10n.behavioursSceneNotFound;
    if (node.kind == SceneNodeKind.start) return l10n.sceneFocusPathStart;
    if (node.kind == SceneNodeKind.end) return l10n.sceneFocusPathEnd;
    final step = l10n.storyStepFamily(sceneStepFamilyOfNode(node).name);
    final detail =
        node.title?.trim() ??
        switch (node.payload) {
          SceneYarnDialoguePayload(:final dialogueId) =>
            focus.document.value?.dialogues
                .where((dialogue) => dialogue.id == dialogueId)
                .firstOrNull
                ?.entry
                .name,
          _ => null,
        };
    return detail == null || detail.isEmpty
        ? step
        : l10n.sceneFocusPathStepDetail(step, detail);
  }

  String _exit(AppLocalizations l10n, SceneNode? node, String port) =>
      switch ((node?.payload, port)) {
        (SceneYarnDialoguePayload(:final dialogueId), _) => sceneGraphPortLabel(
          l10n,
          port,
          dialogues[dialogueId],
          choiceLabels: choiceLabels[dialogueId] ?? const {},
        ),
        (_, 'true') => l10n.storyStepThen,
        (_, 'false') => l10n.storyStepElse,
        _ when node != null && sceneStepMainPortOf(node) == port =>
          l10n.storyStepMain,
        _ => l10n.sceneGraphPort(port),
      };
}
