import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class DialoguePreviewPanel extends StatelessWidget {
  const DialoguePreviewPanel({
    super.key,
    required this.controller,
    this.portrait,
  });
  final DialogueWorkspaceController controller;
  final Widget Function(String?, String?, double)? portrait;
  @override
  Widget build(BuildContext context) {
    final preview = controller.preview;
    final session = controller.active;
    return StudioPanel(
      compact: true,
      title: 'Test de dialogue',
      actions: [
        StudioButton(
          label: preview == null ? 'Essayer' : 'Recommencer',
          secondary: true,
          icon: Icons.play_arrow,
          onPressed: () => controller.startPreview(),
        ),
      ],
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Départ : ${session?.startNode ?? session?.entry.defaultStartNode ?? 'départ du document'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (preview == null)
                  const Text(
                    'Essayez chaque réponse. Cet aperçu ne modifie pas la partie.',
                  ),
                if (preview?.error case final error?)
                  StudioNotice(error, isError: true),
                if (preview?.line case final line?)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (portrait != null) ...[
                        portrait!(line.characterId, line.portraitStateId, 48),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: Text(line.text)),
                    ],
                  ),
                if (preview != null) ...[
                  for (var i = 0; i < preview.choices.length; i++)
                    StudioChoice(
                      label: preview.choices[i].text,
                      tone: StudioTone.feature,
                      onTap: () => controller.choosePreview(i),
                    ),
                  if (preview.line != null &&
                      preview.error == null &&
                      !preview.ended)
                    Align(
                      alignment: Alignment.centerRight,
                      child: StudioButton(
                        label: 'Continuer',
                        icon: Icons.chevron_right,
                        onPressed: controller.advancePreview,
                      ),
                    ),
                  if (preview.ended)
                    const StudioBadge(
                      'Conversation terminée',
                      tone: StudioTone.success,
                    ),
                  if (preview.outcomes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final outcome in preview.outcomes)
                          StudioBadge(
                            'Résultat observé : $outcome',
                            tone: StudioTone.success,
                          ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
