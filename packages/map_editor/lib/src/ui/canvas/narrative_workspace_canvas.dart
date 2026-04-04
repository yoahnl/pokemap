import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import 'cutscene_studio_workspace.dart';

/// Workspace central du studio narratif.
///
/// Ce widget est la "surface de création" principale pour:
/// - Global Story
/// - Step
/// - Cutscene
///
/// Intention produit:
/// - éviter un modèle "inspecteur de champs à droite"
/// - rendre la narration éditable dans l'îlot central, comme un vrai workspace
class NarrativeWorkspaceCanvas extends ConsumerWidget {
  const NarrativeWorkspaceCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final editorNotifier = ref.read(editorNotifierProvider.notifier);
    final narrative = ref.watch(narrativeWorkspaceControllerProvider);
    final narrativeController =
        ref.read(narrativeWorkspaceControllerProvider.notifier);
    final projection = ref.watch(narrativeWorkspaceProjectionProvider);

    if (projection == null) {
      return Center(
        child: Text(
          'Load a project to start structuring Global Story, Steps and Cutscenes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final selectedGlobal = _resolveScenarioById(
      projection,
      narrative.selectedGlobalStoryId,
      fallback: projection.globalStories.isNotEmpty
          ? projection.globalStories.first
          : null,
    );
    final selectedCutscene = _resolveScenarioById(
      projection,
      narrative.selectedCutsceneId,
      fallback: projection.localEventFlows.isNotEmpty
          ? projection.localEventFlows.first
          : null,
    );
    final selectedStep = _resolveStepById(
      projection,
      narrative.selectedStepId,
      fallback: projection.steps.isNotEmpty ? projection.steps.first : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NarrativeModeStrip(
          workspaceMode: editor.workspaceMode,
          onSelectGlobal: () {
            editorNotifier.selectGlobalStoryWorkspace();
            narrativeController.openGlobalStory(
              scenarioId: selectedGlobal?.id,
            );
          },
          onSelectStep: () {
            editorNotifier.selectStepWorkspace();
            narrativeController.openStep(
              stepId: selectedStep?.id,
              globalScenarioId: selectedStep?.globalScenarioId,
            );
          },
          onSelectCutscene: () {
            editorNotifier.selectCutsceneWorkspace();
            narrativeController.openCutscene(
              cutsceneScenarioId: selectedCutscene?.id,
            );
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: switch (editor.workspaceMode) {
            EditorWorkspaceMode.globalStory => _GlobalStoryWorkspaceBody(
                projection: projection,
                selectedGlobal: selectedGlobal,
                onSelectGlobal: (id) {
                  narrativeController.selectGlobalStory(id);
                  narrativeController.openGlobalStory(scenarioId: id);
                },
                onSelectOutcome: narrativeController.selectOutcome,
              ),
            EditorWorkspaceMode.step => _StepWorkspaceBody(
                projection: projection,
                selectedStep: selectedStep,
                onSelectStep: (stepId) {
                  final step = projection.steps
                      .where((s) => s.id == stepId)
                      .cast<NarrativeStepSummary?>()
                      .firstWhere((s) => s != null, orElse: () => null);
                  narrativeController.selectStep(stepId);
                  narrativeController.openStep(
                    stepId: stepId,
                    globalScenarioId: step?.globalScenarioId,
                  );
                },
                onSelectOutcome: narrativeController.selectOutcome,
              ),
            EditorWorkspaceMode.cutscene => _CutsceneWorkspaceBody(
                editorNotifier: editorNotifier,
                project: editor.project,
                activeMap: editor.activeMap,
                projection: projection,
                selectedCutscene: selectedCutscene,
                onSelectCutscene: (scenarioId) {
                  narrativeController.selectCutscene(scenarioId);
                  narrativeController.openCutscene(
                    cutsceneScenarioId: scenarioId,
                  );
                },
                onSelectOutcome: narrativeController.selectOutcome,
              ),
            // Workspaces non narratifs: ce widget ne doit pas être utilisé.
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

NarrativeScenarioSummary? _resolveScenarioById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeScenarioSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  return projection.scenarioById[id] ?? fallback;
}

NarrativeStepSummary? _resolveStepById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeStepSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  for (final step in projection.steps) {
    if (step.id == id) {
      return step;
    }
  }
  return fallback;
}

class _NarrativeModeStrip extends StatelessWidget {
  const _NarrativeModeStrip({
    required this.workspaceMode,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          label: 'Global Story',
          selected: workspaceMode == EditorWorkspaceMode.globalStory,
          onTap: onSelectGlobal,
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Step',
          selected: workspaceMode == EditorWorkspaceMode.step,
          onTap: onSelectStep,
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: 'Cutscene',
          selected: workspaceMode == EditorWorkspaceMode.cutscene,
          onTap: onSelectCutscene,
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? EditorChrome.islandFillElevated(context)
              : EditorChrome.sidebarHoverFill(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _GlobalStoryWorkspaceBody extends StatelessWidget {
  const _GlobalStoryWorkspaceBody({
    required this.projection,
    required this.selectedGlobal,
    required this.onSelectGlobal,
    required this.onSelectOutcome,
  });

  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedGlobal;
  final ValueChanged<String> onSelectGlobal;
  final ValueChanged<String?> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: _NarrativeListCard(
            title: 'Global Story Graphs',
            subtitle: 'Macro progression structure',
            emptyText: 'No global story graph yet.',
            children: projection.globalStories
                .map(
                  (scenario) => EditorSidebarListRow(
                    selected: selectedGlobal?.id == scenario.id,
                    onTap: () => onSelectGlobal(scenario.id),
                    leading: const Icon(CupertinoIcons.link),
                    title: Text(scenario.name),
                    subtitle: Text(
                      '${scenario.nodeCount} nodes • ${scenario.edgeCount} links',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NarrativeDetailCard(
            title: selectedGlobal?.name ?? 'No global story selected',
            subtitle: selectedGlobal == null
                ? 'Select a global graph from the left list.'
                : 'Structure your arcs, milestones and major narrative transitions.',
            sections: [
              const _DetailSectionData(
                label: 'Role',
                content:
                    'Global Story defines macro progression. It should not carry scene execution details.',
              ),
              _DetailSectionData(
                label: 'Declared outcomes',
                content: selectedGlobal == null
                    ? '—'
                    : _joinOrDash(selectedGlobal!.declaredOutcomes),
                onTap: selectedGlobal == null
                    ? null
                    : () {
                        final first = selectedGlobal!.declaredOutcomes.isEmpty
                            ? null
                            : selectedGlobal!.declaredOutcomes.first;
                        onSelectOutcome(first);
                      },
              ),
              _DetailSectionData(
                label: 'Consumes outcomes',
                content: selectedGlobal == null
                    ? '—'
                    : _joinOrDash(selectedGlobal!.consumedOutcomes),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepWorkspaceBody extends StatelessWidget {
  const _StepWorkspaceBody({
    required this.projection,
    required this.selectedStep,
    required this.onSelectStep,
    required this.onSelectOutcome,
  });

  final NarrativeWorkspaceProjection projection;
  final NarrativeStepSummary? selectedStep;
  final ValueChanged<String> onSelectStep;
  final ValueChanged<String?> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: _NarrativeListCard(
            title: 'Steps',
            subtitle: 'Progression units',
            emptyText: 'No step projection yet.',
            children: projection.steps
                .map(
                  (step) => EditorSidebarListRow(
                    selected: selectedStep?.id == step.id,
                    onTap: () => onSelectStep(step.id),
                    leading: const Icon(CupertinoIcons.flag),
                    title: Text(step.name),
                    subtitle: Text(
                      'Cutscenes: ${step.linkedCutsceneIds.length} • Outcomes: ${step.emittedOutcomeIds.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NarrativeDetailCard(
            title: selectedStep?.name ?? 'No step selected',
            subtitle: selectedStep == null
                ? 'Select a step from the left list.'
                : selectedStep!.description,
            sections: [
              _DetailSectionData(
                label: 'Linked global scenario',
                content: selectedStep?.globalScenarioId ?? '—',
              ),
              _DetailSectionData(
                label: 'Linked cutscenes',
                content: selectedStep == null
                    ? '—'
                    : _joinOrDash(selectedStep!.linkedCutsceneIds),
              ),
              _DetailSectionData(
                label: 'Expected outcomes',
                content: selectedStep == null
                    ? '—'
                    : _joinOrDash(selectedStep!.expectedOutcomeIds),
              ),
              _DetailSectionData(
                label: 'Emitted outcomes',
                content: selectedStep == null
                    ? '—'
                    : _joinOrDash(selectedStep!.emittedOutcomeIds),
                onTap: selectedStep == null ||
                        selectedStep!.emittedOutcomeIds.isEmpty
                    ? null
                    : () =>
                        onSelectOutcome(selectedStep!.emittedOutcomeIds.first),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CutsceneWorkspaceBody extends StatelessWidget {
  const _CutsceneWorkspaceBody({
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedCutscene,
    required this.onSelectCutscene,
    required this.onSelectOutcome,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedCutscene;
  final ValueChanged<String> onSelectCutscene;
  final ValueChanged<String?> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: _NarrativeListCard(
            title: 'Local Event Flows / Cutscenes',
            subtitle: 'Scene execution layer',
            emptyText: 'No local flow available.',
            children: projection.localEventFlows
                .map(
                  (scenario) => EditorSidebarListRow(
                    selected: selectedCutscene?.id == scenario.id,
                    onTap: () => onSelectCutscene(scenario.id),
                    leading: const Icon(CupertinoIcons.play_rectangle),
                    title: Text(scenario.name),
                    subtitle: Text(
                      '${scenario.nodeCount} nodes • entry: ${scenario.entryNodeId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: project == null
              ? const EditorPaneSurface(
                  radius: 20,
                  tint: EditorChrome.islandWarmTint,
                  child: Center(
                    child: Text('Load a project to edit cutscenes.'),
                  ),
                )
              : CutsceneStudioWorkspace(
                  editorNotifier: editorNotifier,
                  project: project!,
                  activeMap: activeMap,
                  projection: projection,
                  selectedCutscene: selectedCutscene,
                  onSelectCutscene: onSelectCutscene,
                  onSelectOutcome: onSelectOutcome,
                ),
        ),
      ],
    );
  }
}

class _NarrativeListCard extends StatelessWidget {
  const _NarrativeListCard({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandNeutralTint,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: children.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) => children[index],
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemCount: children.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NarrativeDetailCard extends StatelessWidget {
  const _NarrativeDetailCard({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<_DetailSectionData> sections;

  @override
  Widget build(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: ListView(
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          for (final section in sections) ...[
            _DetailSection(section: section),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DetailSectionData {
  const _DetailSectionData({
    required this.label,
    required this.content,
    this.onTap,
  });

  final String label;
  final String content;
  final VoidCallback? onTap;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.section,
  });

  final _DetailSectionData section;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.content,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (section.onTap == null) {
      return body;
    }
    return GestureDetector(
      onTap: section.onTap,
      child: body,
    );
  }
}

String _joinOrDash(List<String> values) {
  if (values.isEmpty) {
    return '—';
  }
  return values.join(', ');
}
