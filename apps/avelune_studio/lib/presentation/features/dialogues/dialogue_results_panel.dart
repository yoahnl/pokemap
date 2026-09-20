import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

class DialogueResultsPanel extends StatelessWidget {
  const DialogueResultsPanel({super.key, required this.controller});
  final DialogueWorkspaceController controller;
  @override
  Widget build(BuildContext context) {
    final session = controller.active!;
    final emitted = session.document
        .documentOutcomes()
        .map((o) => o.id)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Résultats publics',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (session.entry.declaredOutcomes.isEmpty)
          const Text('Aucun résultat déclaré.'),
        for (final outcome in session.entry.declaredOutcomes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: session.readOnlyReason == null
                          ? StudioCommitField(
                              key: ValueKey('outcome-${outcome.id}'),
                              label: 'Nom du résultat',
                              value: outcome.label,
                              tryCommit: (label) =>
                                  controller.renameOutcome(outcome.id, label),
                            )
                          : StudioBadge(
                              outcome.label,
                              tone: StudioTone.success,
                            ),
                    ),
                    if (session.readOnlyReason == null)
                      StudioTool(
                        label: 'Retirer ${outcome.label}',
                        icon: Icons.close,
                        onPressed: () => controller.removeOutcome(outcome.id),
                      ),
                  ],
                ),
                if (!emitted.contains(outcome.id))
                  const Text('Déclaré, mais aucune réponse ne l’émet encore.'),
              ],
            ),
          ),
        const Text(
          'Les conséquences se règlent dans la scène. Le dialogue transmet le résultat choisi.',
        ),
      ],
    );
  }
}
