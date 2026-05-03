import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Retour visuel local après ajout d’un preset au manifest en mémoire (Lot 17).
///
/// Complète le [statusMessage] du shell sans le remplacer ; reste dans le panel.
class EnvironmentPresetSaveFeedback extends StatelessWidget {
  const EnvironmentPresetSaveFeedback({
    super.key,
    required this.presetName,
  });

  final String presetName;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return DecoratedBox(
      key: const Key('environment-studio-post-save-local-feedback'),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preset « $presetName » ajouté au projet en mémoire.',
              key: const Key('environment-studio-post-save-line-1'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Projet modifié — pensez à sauvegarder le projet pour écrire sur disque.',
              key: const Key('environment-studio-post-save-line-2'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
