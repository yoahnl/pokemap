import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Inspecteur contextuel du studio narratif (colonne droite).
///
/// Rôle:
/// - rester synthétique et orienté décisions produit
/// - refléter la sélection active du workspace central
/// - ne pas remplacer l'éditeur central (principe "center-first")
class NarrativeInspectorPanel extends ConsumerWidget {
  const NarrativeInspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final projection = ref.watch(narrativeWorkspaceProjectionProvider);
    final narrative = ref.watch(narrativeWorkspaceControllerProvider);

    if (projection == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    return ListView(
      padding: kInspectorTileBodyPadding,
      children: [
        _InspectorSection(
          title: 'Narrative Mode',
          content: switch (editor.workspaceMode) {
            EditorWorkspaceMode.globalStory => 'Global Story',
            EditorWorkspaceMode.step => 'Step',
            EditorWorkspaceMode.cutscene => 'Cutscene',
            _ => '—',
          },
        ),
        const SizedBox(height: 10),
        _InspectorSection(
          title: 'Selection',
          content: _selectionLabel(
            projection: projection,
            narrative: narrative,
            workspaceMode: editor.workspaceMode,
          ),
        ),
        const SizedBox(height: 10),
        _InspectorSection(
          title: 'Global Story (unique)',
          content: projection.globalStories.isEmpty
              ? 'Aucun'
              : projection.globalStories.first.name,
        ),
        if (projection.globalStories.length > 1) ...[
          const SizedBox(height: 10),
          _InspectorSection(
            title: 'Global stories en trop',
            content:
                '${projection.globalStories.length - 1} (non utilisées par Step Studio)',
          ),
        ],
        const SizedBox(height: 10),
        _InspectorSection(
          title: 'Steps (projected)',
          content: '${projection.steps.length}',
        ),
        const SizedBox(height: 10),
        _InspectorSection(
          title: 'Local Event Flows / Cutscenes',
          content: '${projection.localEventFlows.length}',
        ),
        const SizedBox(height: 10),
        _InspectorSection(
          title: 'Outcomes',
          content: '${projection.outcomes.length}',
        ),
        const SizedBox(height: 12),
        const InspectorEmbeddedFootnote(
          text:
              'This inspector is contextual only. Main authoring stays in the center workspace.',
          accent: EditorChrome.inspectorJoyCyan,
        ),
      ],
    );
  }
}

String _selectionLabel({
  required NarrativeWorkspaceProjection projection,
  required NarrativeWorkspaceState narrative,
  required EditorWorkspaceMode workspaceMode,
}) {
  switch (workspaceMode) {
    case EditorWorkspaceMode.globalStory:
      final scenarioId = narrative.selectedGlobalStoryId;
      if (scenarioId == null) return 'No global story selected';
      final scenario = projection.scenarioById[scenarioId];
      return scenario == null
          ? scenarioId
          : '${scenario.name} (${scenario.id})';
    case EditorWorkspaceMode.step:
      final stepId = narrative.selectedStepId;
      if (stepId == null) return 'No step selected';
      for (final step in projection.steps) {
        if (step.id == stepId) {
          return '${step.name} (${step.id})';
        }
      }
      return stepId;
    case EditorWorkspaceMode.cutscene:
      final scenarioId = narrative.selectedCutsceneId;
      if (scenarioId == null) return 'No cutscene selected';
      final scenario = projection.scenarioById[scenarioId];
      return scenario == null
          ? scenarioId
          : '${scenario.name} (${scenario.id})';
    default:
      return '—';
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
