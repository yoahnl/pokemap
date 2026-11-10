import '../../../features/scenes/application/scene_dialogue_line_policy_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class SceneDialogueLinePolicyForm extends StatefulWidget {
  const SceneDialogueLinePolicyForm({
    super.key,
    required this.project,
    required this.payload,
    required this.document,
    required this.onApply,
  });

  final ProjectManifest project;
  final SceneYarnDialoguePayload payload;
  final RuntimeDialogueDocument document;
  final ValueChanged<SceneDialogueLinePolicy> onApply;

  @override
  State<SceneDialogueLinePolicyForm> createState() =>
      _SceneDialogueLinePolicyFormState();
}

class _SceneDialogueLinePolicyFormState
    extends State<SceneDialogueLinePolicyForm> {
  late final SceneDialogueLinePolicyDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneDialogueLinePolicyDraft(
      project: widget.project,
      payload: widget.payload,
      document: widget.document,
    );
  }

  @override
  void didUpdateWidget(SceneDialogueLinePolicyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      project: widget.project,
      payload: widget.payload,
      document: widget.document,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (draft.scopes.isEmpty) {
      return const StudioNotice(
        'Aucune réplique dans ce dialogue. Ajoutez du texte pour régler son rythme.',
      );
    }
    DialogueLineFeedback? feedback;
    String? error;
    try {
      feedback = draft.feedback;
    } on FormatException catch (failure) {
      error = failure.message;
    } on ArgumentError {
      error = 'Les réglages de cette réplique sont incompatibles.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('scene-line-scope'),
          label: 'Réplique à régler',
          value: '${draft.scopeIndex}',
          options: {
            for (var index = 0; index < draft.scopes.length; index++)
              '$index':
                  '${draft.scopes[index].nodeName} · Ligne ${draft.scopes[index].lineIndex + 1} · ${draft.scopes[index].text}',
          },
          onChanged: (value) => setState(() {
            draft.scopeIndex = int.parse(value);
            draft.read();
          }),
        ),
        const SizedBox(height: 12),
        Text(draft.scope.text),
        if (draft.original.segments.isNotEmpty) ...[
          const StudioNotice('Texte enrichi et icônes conservés.'),
          for (final segment in draft.original.segments)
            if (segment is DialogueIconSegment)
              Text('Icône ${segment.widthPx} × ${segment.heightPx} px'),
        ],
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('scene-line-reveal-ms'),
          label: 'Intervalle entre les caractères (ms)',
          helperText: 'Vide : rythme par défaut. Zéro : affichage instantané.',
          value: draft.revealMs,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => setState(() => draft.revealMs = value),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-line-advance'),
          label: 'Passage à la réplique suivante',
          value: draft.advance.name,
          options: const {
            'confirm': 'Confirmation du joueur',
            'autoAfterReveal': 'Automatique après affichage',
          },
          onChanged: (value) => setState(
            () => draft.advance = DialogueLineAdvanceKind.values.byName(value),
          ),
        ),
        if (draft.advance == DialogueLineAdvanceKind.autoAfterReveal) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-line-delay-ms'),
            label: 'Délai après affichage complet (ms)',
            value: draft.delayMs,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => setState(() => draft.delayMs = value),
          ),
        ],
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('scene-line-sound'),
          label: 'Son associé à la réplique',
          value: draft.mediaId,
          options: draft.sounds,
          onChanged: (value) => setState(() => draft.mediaId = value),
        ),
        if (draft.mediaId.isNotEmpty) ...[
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-line-audio-role'),
            label: 'Comportement du son',
            value: draft.role.name,
            options: const {
              'effect': 'Effet sonore',
              'musicEffect': 'Jingle musical',
            },
            onChanged: (value) => setState(
              () => draft.role = DialogueAudioCueRole.values.byName(value),
            ),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-line-audio-volume'),
            label: 'Volume du son (%)',
            value: draft.volume,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => setState(() => draft.volume = value),
          ),
          if (draft.role == DialogueAudioCueRole.effect) ...[
            const SizedBox(height: 12),
            StudioDraftField(
              key: const ValueKey('scene-line-audio-offset'),
              label: 'Jouer après combien de caractères ?',
              helperText: 'Zéro : dès le début de la réplique.',
              value: draft.offset,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => draft.offset = value),
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: 12),
        StudioButton(
          key: const ValueKey('scene-line-apply'),
          label: 'Appliquer les réglages de la réplique',
          onPressed: feedback == null
              ? null
              : () => widget.onApply(
                  SceneDialogueLinePolicy(
                    nodeName: draft.scope.nodeName,
                    lineIndex: draft.scope.lineIndex,
                    feedback: feedback!,
                  ),
                ),
        ),
      ],
    );
  }
}
