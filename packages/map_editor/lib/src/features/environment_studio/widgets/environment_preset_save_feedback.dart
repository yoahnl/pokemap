import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../environment_preset_memory_write_kind.dart';

/// Retour visuel local après écriture mémoire d’un preset (Lots 17–18).
///
/// Complète le [statusMessage] du shell sans le remplacer ; reste dans le panel.
class EnvironmentPresetSaveFeedback extends StatelessWidget {
  const EnvironmentPresetSaveFeedback({
    super.key,
    required this.presetName,
    required this.writeKind,
  });

  final String presetName;
  final EnvironmentPresetMemoryWriteKind writeKind;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final line1 = switch (writeKind) {
      EnvironmentPresetMemoryWriteKind.create =>
        'Preset « $presetName » ajouté au projet en mémoire.',
      EnvironmentPresetMemoryWriteKind.update =>
        'Preset « $presetName » mis à jour dans le projet en mémoire.',
    };
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
              line1,
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
