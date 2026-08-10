import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../project_intro_video_editor.dart';

class PersonalizationIntroInspector extends StatelessWidget {
  const PersonalizationIntroInspector({
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
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('personalization-intro-inspector'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Média principal',
        description:
            'Importez la vidéo, son poster de secours et ses sous-titres dans '
            'un seul parcours guidé.',
      ),
      const SizedBox(height: 8),
      ProjectIntroVideoEditor(
        profile: profile,
        onImportPressed: onImportPressed,
        onChanged: onChanged,
        onRemove: onRemove,
      ),
      if (profile case final intro?) ...<Widget>[
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Éléments de secours',
          description:
              'Le player utilise ces éléments si la vidéo ne peut pas être '
              'lue ou si le joueur réduit les animations.',
        ),
        const SizedBox(height: 8),
        _AssetStatus(
          icon: Icons.image_outlined,
          label: 'Poster de secours',
          ready: intro.posterPath.trim().isNotEmpty,
        ),
        const SizedBox(height: 8),
        _AssetStatus(
          icon: Icons.closed_caption_outlined,
          label: 'Sous-titres',
          ready: intro.captionsPath?.trim().isNotEmpty ?? false,
          optional: true,
        ),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Point important dans l’image',
          description:
              'Indiquez ce qui doit rester visible quand le player recadre la '
              'vidéo en paysage ou en portrait.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final focal in _focalPoints)
              PokeMapButton(
                key: ValueKey<String>('intro-focal-${focal.id}'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                isSelected: _matches(intro.media.landscape, focal),
                onPressed: () => onChanged(_withFocalPoint(intro, focal)),
                child: Text(focal.label),
              ),
          ],
        ),
      ],
    ],
  );
}

class _AssetStatus extends StatelessWidget {
  const _AssetStatus({
    required this.icon,
    required this.label,
    required this.ready,
    this.optional = false,
  });

  final IconData icon;
  final String label;
  final bool ready;
  final bool optional;

  @override
  Widget build(BuildContext context) => PokeMapCard(
    child: Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        PokeMapBadge(
          label: ready
              ? 'Prêt'
              : optional
              ? 'Optionnel'
              : 'Manquant',
          variant: ready
              ? PokeMapBadgeVariant.success
              : optional
              ? PokeMapBadgeVariant.info
              : PokeMapBadgeVariant.warning,
        ),
      ],
    ),
  );
}

typedef _FocalPoint = ({String id, String label, double x, double y});

const _focalPoints = <_FocalPoint>[
  (id: 'topLeft', label: 'Haut gauche', x: 0, y: 0),
  (id: 'top', label: 'Haut', x: .5, y: 0),
  (id: 'topRight', label: 'Haut droite', x: 1, y: 0),
  (id: 'left', label: 'Gauche', x: 0, y: .5),
  (id: 'center', label: 'Centre', x: .5, y: .5),
  (id: 'right', label: 'Droite', x: 1, y: .5),
  (id: 'bottomLeft', label: 'Bas gauche', x: 0, y: 1),
  (id: 'bottom', label: 'Bas', x: .5, y: 1),
  (id: 'bottomRight', label: 'Bas droite', x: 1, y: 1),
];

bool _matches(ProjectVideoVariantProfile variant, _FocalPoint focal) =>
    variant.focalX == focal.x && variant.focalY == focal.y;

ProjectIntroVideoProfile _withFocalPoint(
  ProjectIntroVideoProfile intro,
  _FocalPoint focal,
) {
  final media = intro.media;
  return intro.copyWith(
    media: media.copyWith(
      landscape: media.landscape.copyWith(focalX: focal.x, focalY: focal.y),
      portrait: media.portrait?.copyWith(focalX: focal.x, focalY: focal.y),
    ),
  );
}
