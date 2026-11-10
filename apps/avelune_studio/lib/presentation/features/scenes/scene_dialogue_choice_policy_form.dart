import '../../../features/scenes/application/scene_dialogue_choice_policy_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneDialogueChoicePolicyForm extends StatefulWidget {
  const SceneDialogueChoicePolicyForm({
    super.key,
    required this.scene,
    required this.nodeId,
    required this.payload,
    required this.document,
    required this.onApply,
  });

  final SceneAsset scene;
  final String nodeId;
  final SceneYarnDialoguePayload payload;
  final RuntimeDialogueDocument document;
  final ValueChanged<SceneDialogueChoicePolicy> onApply;

  @override
  State<SceneDialogueChoicePolicyForm> createState() =>
      _SceneDialogueChoicePolicyFormState();
}

class _SceneDialogueChoicePolicyFormState
    extends State<SceneDialogueChoicePolicyForm> {
  late final SceneDialogueChoicePolicyDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneDialogueChoicePolicyDraft(
      scene: widget.scene,
      nodeId: widget.nodeId,
      payload: widget.payload,
      document: widget.document,
    );
  }

  @override
  void didUpdateWidget(SceneDialogueChoicePolicyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      scene: widget.scene,
      nodeId: widget.nodeId,
      payload: widget.payload,
      document: widget.document,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (draft.scopes.isEmpty) {
      return const StudioNotice(
        'Aucun choix dans ce dialogue. Ajoutez un bloc de choix pour configurer son comportement.',
      );
    }
    final choices = draft.choices;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('scene-choice-scope'),
          label: 'Bloc de choix',
          value: '${draft.scopeIndex}',
          options: {
            for (var index = 0; index < draft.scopes.length; index++)
              '$index':
                  '${draft.scopes[index].nodeName} · Choix ${draft.scopes[index].choiceIndex + 1} : '
                  '${draft.blocks[(draft.scopes[index].nodeName, draft.scopes[index].choiceIndex)]!.choices.map((choice) => choice.text).join(' / ')}',
          },
          onChanged: (value) => setState(() {
            draft.scopeIndex = int.parse(value);
            draft.readPolicy();
          }),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-choice-default'),
          label: 'Option sélectionnée au départ',
          value: draft.defaultValid ? draft.defaultOutcome : null,
          options: {'': 'Première option', ...choices},
          onChanged: (value) => setState(() => draft.defaultOutcome = value),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-choice-cancellation'),
          label: 'Quand le joueur annule',
          value: draft.cancellation.name,
          options: {
            'disabled': 'Annulation interdite',
            if (choices.isNotEmpty ||
                draft.cancellation ==
                    SceneDialogueChoiceCancellationKind.choice)
              'choice': 'Une option de ce choix',
            if (draft.branches.isNotEmpty ||
                draft.cancellation ==
                    SceneDialogueChoiceCancellationKind.branch)
              'branch': 'Une branche de la scène',
          },
          onChanged: (value) => setState(() {
            draft.cancellation = SceneDialogueChoiceCancellationKind.values
                .byName(value);
            draft.target = draft.targets.keys.firstOrNull;
          }),
        ),
        if (draft.cancellation !=
            SceneDialogueChoiceCancellationKind.disabled) ...[
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-choice-target'),
            label:
                draft.cancellation == SceneDialogueChoiceCancellationKind.choice
                ? 'Option retenue en cas d’annulation'
                : 'Branche suivie en cas d’annulation',
            value: draft.targetValid ? draft.target : null,
            options: draft.targets,
            onChanged: (value) => setState(() => draft.target = value),
          ),
        ],
        if (!draft.defaultValid || !draft.targetValid) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Le réglage existant vise une option qui n’existe plus ou une branche non reliée. Choisissez explicitement son nouveau comportement avant d’appliquer.',
            isError: true,
          ),
        ],
        if (choices.length != draft.block.choices.length) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Seules les options avec une sortie déclarée et unique peuvent être ciblées par ces réglages.',
          ),
        ],
        if (draft.branches.isEmpty) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Aucune branche d’annulation reliée dans cette scène. Reliez une sortie distincte du dialogue pour proposer cette possibilité.',
          ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('scene-choice-apply'),
          label: 'Appliquer le comportement des choix',
          onPressed: draft.prepared == null
              ? null
              : () => widget.onApply(draft.prepared!),
        ),
      ],
    );
  }
}
