import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

/// Guided, no-code editor for the optional project introduction video.
class ProjectIntroVideoEditor extends StatelessWidget {
  const ProjectIntroVideoEditor({
    super.key,
    required this.profile,
    required this.onImportPressed,
    required this.onChanged,
    this.onRemove,
  });

  final ProjectIntroVideoProfile? profile;
  final VoidCallback onImportPressed;
  final ValueChanged<ProjectIntroVideoProfile> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final intro = profile;
    if (intro == null) {
      return PokeMapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Ajoutez une ouverture cinématique à votre jeu.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'MP4 · H.264 · AAC optionnel · paysage ou portrait · '
              '1920 px maximum sur le côté long · 1080 px sur le côté '
              'court · 2 minutes maximum · 100 Mio maximum.',
            ),
            const SizedBox(height: 16),
            PokeMapButton(
              key: const ValueKey<String>('personalization-intro-import'),
              onPressed: onImportPressed,
              leading: const Icon(Icons.video_file_outlined),
              child: const Text('Importer une vidéo'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Vidéo installable',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapBadge(
                    label: _formatDuration(intro.durationMilliseconds),
                    icon: const Icon(Icons.schedule_outlined),
                  ),
                  PokeMapBadge(
                    label: '${intro.width} × ${intro.height}',
                    icon: const Icon(Icons.aspect_ratio_outlined),
                  ),
                  PokeMapBadge(
                    label: _orientationLabel(intro.width, intro.height),
                    variant: PokeMapBadgeVariant.info,
                    icon: Icon(
                      intro.height > intro.width
                          ? Icons.stay_current_portrait_outlined
                          : Icons.stay_current_landscape_outlined,
                    ),
                  ),
                  PokeMapBadge(
                    label: '${intro.bitrateKbps} kbit/s',
                    icon: const Icon(Icons.speed_outlined),
                  ),
                  PokeMapBadge(
                    label: intro.captionsPath == null
                        ? 'Sans sous-titres'
                        : 'Sous-titres WebVTT',
                    variant: intro.captionsPath == null
                        ? PokeMapBadgeVariant.warning
                        : PokeMapBadgeVariant.success,
                    icon: const Icon(Icons.closed_caption_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'personalization-intro-replace',
                    ),
                    onPressed: onImportPressed,
                    variant: PokeMapButtonVariant.secondary,
                    leading: const Icon(Icons.sync_outlined),
                    child: const Text('Remplacer'),
                  ),
                  if (onRemove != null)
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'personalization-intro-remove',
                      ),
                      onPressed: onRemove,
                      variant: PokeMapButtonVariant.danger,
                      leading: const Icon(Icons.delete_outline),
                      child: const Text('Retirer'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokeMapToggleTile(
          key: const ValueKey<String>('intro-allow-replay'),
          label: 'Autoriser “Rejouer”',
          description:
              'L’option reste disponible sur l’écran titre après la lecture.',
          value: intro.allowReplay,
          onChanged: (value) => onChanged(intro.copyWith(allowReplay: value)),
        ),
        const SizedBox(height: 12),
        PokeMapPanel(
          header: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Si les animations sont réduites',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: const ValueKey<String>('intro-reduced-motion-poster'),
                onPressed: () =>
                    onChanged(intro.copyWith(reducedMotionBehavior: 'poster')),
                variant: PokeMapButtonVariant.secondary,
                isSelected: intro.reducedMotionBehavior == 'poster',
                leading: const Icon(Icons.image_outlined),
                child: const Text('Afficher le poster'),
              ),
              PokeMapButton(
                key: const ValueKey<String>('intro-reduced-motion-skip'),
                onPressed: () =>
                    onChanged(intro.copyWith(reducedMotionBehavior: 'skip')),
                variant: PokeMapButtonVariant.secondary,
                isSelected: intro.reducedMotionBehavior == 'skip',
                leading: const Icon(Icons.skip_next_outlined),
                child: const Text('Passer l’intro'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDuration(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}

String _orientationLabel(int width, int height) {
  if (height > width) return 'Portrait 9:16';
  if (width > height) return 'Paysage 16:9';
  return 'Carré 1:1';
}
