import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class BorderSequenceControls extends StatelessWidget {
  const BorderSequenceControls({
    super.key,
    required this.length,
    required this.primitives,
    required this.modelNames,
    required this.activeModelId,
    required this.selections,
    required this.onLength,
    required this.onSource,
    this.problem,
  });

  final int length;
  final List<BorderPrimitiveDraft> primitives;
  final Map<String, String> modelNames;
  final String? activeModelId;
  final Map<String, String> selections;
  final bool Function(String) onLength;
  final void Function(String, String) onSource;
  final String? problem;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioCommitField(
        key: const ValueKey('border-sequence-length'),
        label: 'Nombre d’étapes du motif (1 à 64)',
        value: '$length',
        tryCommit: onLength,
      ),
      if (problem case final message?) StudioNotice(message, isError: true),
      if (length > 64)
        const Text(
          'Ce motif importé est conservé intégralement. L’édition guidée permet de régler jusqu’à 64 étapes.',
        ),
      if (length > 1 && length <= 64) ...[
        const SizedBox(height: 8),
        const Text(
          'Les étapes se répètent dans l’ordre du tracé. Choisissez un modèle dans la bibliothèque à gauche, puis cliquez sur la pièce de l’étape à remplacer. Chaque pièce conserve son orientation et ses réglages.',
        ),
        if (primitives.isEmpty)
          const Text(
            'Associez le corps et les extrémités dans le patron pour préparer les étapes.',
          ),
        for (var step = 0; step < length; step++) ...[
          const SizedBox(height: 12),
          Text('Étape ${step + 1} / $length'),
          for (final p in primitives.where((p) => p.sequenceIndex == step))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StudioButton(
                key: ValueKey('border-sequence-model-${p.id}'),
                label:
                    '${p.role == BorderPrimitiveRole.lineStraight ? 'Corps' : 'Extrémité'} · ${switch (p.authoredOrientation) {
                      BorderPrimitiveOrientation.north => 'vers le nord',
                      BorderPrimitiveOrientation.south => 'vers le sud',
                      BorderPrimitiveOrientation.east => 'vers l’est',
                      BorderPrimitiveOrientation.west => 'vers l’ouest',
                      _ => 'orientation d’origine',
                    }} : ${modelNames[selections[p.id] ?? p.sourceModelId] ?? 'Modèle indisponible'}',
                secondary: true,
                onPressed: activeModelId == null
                    ? null
                    : () => onSource(p.id, activeModelId!),
              ),
            ),
        ],
      ],
    ],
  );
}
