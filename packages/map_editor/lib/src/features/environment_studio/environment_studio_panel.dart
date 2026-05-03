import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Shell read-only central pour Environment Studio (Lot Environment-9).
///
/// Aucune mutation manifest, aucun flux save, aucune génération : affichage
/// purement informatif à partir du [ProjectManifest] déjà en mémoire.
class EnvironmentStudioPanel extends StatelessWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final n = manifest.environmentPresets.length;
    final report = diagnoseProjectEnvironmentAuthoring(
      manifest,
      maps: const [],
    );
    final s = report.summary;

    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(
        context,
        tint: EditorChrome.accentJade.withValues(alpha: 0.06),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Environment Studio',
                    key: const Key('environment-studio-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presets d’environnements organiques',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EditorChrome.chipFill(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Lecture seule — édition et génération arrivent dans les prochains lots.',
                      key: Key('environment-studio-read-only-banner'),
                      style: TextStyle(
                        color: EditorChrome.accentJade,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Créez et gérez des presets d’environnements organiques pour générer des forêts, bosquets, prairies, côtes rocheuses et autres zones naturelles.',
                    key: const Key('environment-studio-description'),
                    style: TextStyle(
                      color: label,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Presets d’environnement',
                    key: const Key('environment-studio-preset-section-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n == 1 ? '1 preset' : '$n presets',
                    key: const Key('environment-studio-preset-count'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (n == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Aucun preset d’environnement pour le moment.\nLes presets seront créés ici dans un prochain lot.',
                      key: const Key('environment-studio-empty-presets'),
                      style: TextStyle(
                        color: subtle,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Diagnostics Environment',
                    key: const Key('environment-studio-diagnostics-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
                    key: const Key('environment-studio-diagnostics-counts'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Les diagnostics d’usage dans les maps seront activés quand les cartes chargées seront connectées au workspace.',
                    key: const Key('environment-studio-diagnostics-map-note'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bientôt :',
                    key: const Key('environment-studio-soon-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• création de presets ;\n'
                    '• édition de palettes ;\n'
                    '• utilisation dans les Environment Layers ;\n'
                    '• génération organique sur les maps.',
                    key: const Key('environment-studio-soon-bullets'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
