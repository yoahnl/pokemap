import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart'
    hide dialogueSteps;
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'dialogue_preview_panel.dart';
import 'dialogue_view_state.dart';
import 'dialogue_portrait_fields.dart';
import 'dialogue_results_panel.dart';
import 'dialogue_suite_actions.dart';

class DialogueInspector extends StatelessWidget {
  const DialogueInspector({
    super.key,
    required this.controller,
    required this.view,
    required this.changed,
    required this.onAddOutcome,
    required this.onDelete,
    required this.onConnect,
    this.portrait,
  });
  final DialogueWorkspaceController controller;
  final DialogueViewState view;
  final VoidCallback changed, onAddOutcome, onDelete;
  final void Function(String, String) onConnect;
  final Widget Function(String?, String?, double)? portrait;
  @override
  Widget build(BuildContext context) {
    final session = controller.active!;
    final node = session.document.nodeById(view.nodeId ?? '');
    final step = node == null
        ? null
        : dialogueSteps(
            node.steps,
          ).where((s) => s.id == view.stepId).firstOrNull;
    final branch = node == null
        ? null
        : dialogueBranches(
            node,
          ).where((b) => b.id == view.branchId).firstOrNull;
    return StudioPanel(
      compact: true,
      children: [
        StudioTabs(
          items: const {
            'properties': 'Propriétés',
            'preview': 'Aperçu',
            'yarn': 'Yarn',
          },
          selected: view.tab,
          onChanged: (tab) {
            FocusManager.instance.primaryFocus?.unfocus();
            FocusManager.instance.applyFocusChangesIfNeeded();
            view.tab = tab;
            changed();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: view.tab == 'preview'
              ? DialoguePreviewPanel(controller: controller, portrait: portrait)
              : SingleChildScrollView(
                  child: view.tab == 'yarn'
                      ? SelectableText(
                          session.source,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StudioBadge(
                              session.readOnlyReason != null
                                  ? 'Source conservée · consultation'
                                  : branch != null
                                  ? 'Réponse du joueur'
                                  : step is DeLineStep
                                  ? 'Réplique'
                                  : step is DeNarrationStep
                                  ? 'Narration'
                                  : 'Suite de conversation',
                              tone: StudioTone.feature,
                              icon: Icons.forum_outlined,
                            ),
                            const SizedBox(height: 14),
                            if (node == null)
                              const Text(
                                'Sélectionnez une suite ou une réplique.',
                              ),
                            if (node != null &&
                                session.readOnlyReason == null) ...[
                              StudioCommitField(
                                key: ValueKey('title-${node.id}'),
                                label: 'Nom de la suite',
                                value: node.title,
                                tryCommit: (value) =>
                                    controller.renameNode(node.id, value),
                              ),
                              const SizedBox(height: 12),
                              if (step == null && branch == null) ...[
                                StudioSelect(
                                  label: 'Suite suivante',
                                  value:
                                      node.steps
                                          .whereType<DeJumpStep>()
                                          .firstOrNull
                                          ?.targetTitle ??
                                      '',
                                  options: {
                                    '': 'Terminer après la suite',
                                    for (final n in session.document.nodes)
                                      n.title: n.title,
                                  },
                                  onChanged: (title) {
                                    if (title.isEmpty) {
                                      final jump = node.steps
                                          .whereType<DeJumpStep>()
                                          .firstOrNull;
                                      if (jump != null) {
                                        controller.disconnectJump(jump.id);
                                      }
                                    } else {
                                      onConnect(
                                        node.id,
                                        session.document.nodes
                                            .firstWhere((n) => n.title == title)
                                            .id,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (step is DeLineStep ||
                                  step is DeNarrationStep) ...[
                                StudioCommitField(
                                  key: ValueKey('text-${step!.id}'),
                                  label: 'Texte',
                                  value: step is DeLineStep
                                      ? step.body
                                      : (step as DeNarrationStep).text,
                                  maxLines: 5,
                                  tryCommit: (value) => controller.updateLine(
                                    step.id,
                                    text: value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (step is DeLineStep)
                                  DialoguePortraitFields(
                                    controller: controller,
                                    line: step,
                                    portrait: portrait,
                                  ),
                              ],
                              if (branch != null) ...[
                                StudioCommitField(
                                  key: ValueKey('response-${branch.id}'),
                                  label: 'Réponse du joueur',
                                  value: branch.label,
                                  maxLines: 3,
                                  tryCommit: (value) => controller
                                      .updateResponse(branch.id, value),
                                ),
                                const SizedBox(height: 12),
                                StudioSelect(
                                  label: 'Continuer vers',
                                  value:
                                      branch.steps
                                          .whereType<DeJumpStep>()
                                          .firstOrNull
                                          ?.targetTitle ??
                                      '',
                                  options: {
                                    '': 'Aucune suite reliée',
                                    for (final n in session.document.nodes)
                                      n.title: n.title,
                                  },
                                  onChanged: (title) {
                                    if (title.isEmpty) {
                                      controller.disconnect(branch.id);
                                    } else {
                                      onConnect(
                                        branch.id,
                                        session.document.nodes
                                            .firstWhere((n) => n.title == title)
                                            .id,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                StudioSelect(
                                  label: 'Résultat public',
                                  value: branch.outcomeId ?? '',
                                  options: {
                                    '': 'Aucun',
                                    for (final outcome
                                        in session.entry.declaredOutcomes)
                                      outcome.id: outcome.label,
                                  },
                                  onChanged: (id) => controller.assignOutcome(
                                    branch.id,
                                    id.isEmpty ? null : id,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StudioButton(
                                  label: 'Créer un résultat',
                                  secondary: true,
                                  icon: Icons.flag_outlined,
                                  onPressed: onAddOutcome,
                                ),
                              ],
                              if (step is DeChoiceStep && branch == null)
                                StudioButton(
                                  label: 'Ajouter une réponse',
                                  icon: Icons.add,
                                  onPressed: () => controller.addResponse(
                                    step.id,
                                    'Nouvelle réponse',
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (step != null) ...[
                                    StudioTool(
                                      label: 'Monter dans la lecture',
                                      icon: Icons.arrow_upward,
                                      onPressed: () => branch == null
                                          ? controller.moveStep(step.id, -1)
                                          : controller.reorderResponse(
                                              branch.id,
                                              -1,
                                            ),
                                    ),
                                    StudioTool(
                                      label: 'Descendre dans la lecture',
                                      icon: Icons.arrow_downward,
                                      onPressed: () => branch == null
                                          ? controller.moveStep(step.id, 1)
                                          : controller.reorderResponse(
                                              branch.id,
                                              1,
                                            ),
                                    ),
                                    if (branch == null)
                                      StudioTool(
                                        label: 'Dupliquer la réplique',
                                        icon: Icons.copy,
                                        onPressed: () =>
                                            controller.duplicateStep(step.id),
                                      ),
                                  ],
                                  StudioButton(
                                    label: 'Supprimer la sélection',
                                    secondary: true,
                                    icon: Icons.delete_outline,
                                    onPressed: onDelete,
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              DialogueSuiteActions(
                                controller: controller,
                                node: node,
                              ),
                            ],
                            const SizedBox(height: 16),
                            DialogueResultsPanel(controller: controller),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}
