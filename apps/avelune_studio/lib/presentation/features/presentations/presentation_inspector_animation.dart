part of 'presentation_inspector.dart';

extension _PresentationAnimationFields on PresentationInspector {
  List<Widget> animationFields(PresentationClip clip) {
    final data = encodePresentationClip(clip);
    return [
      const SizedBox(height: 16),
      const Text('Animations et transitions'),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Courbe',
        value: data['easing']! as String,
        options: const {
          'linear': 'Linéaire',
          'easeIn': 'Accélération',
          'easeOut': 'Décélération',
          'easeInOut': 'Douce',
        },
        onChanged: (value) => onPatch({'easing': value}),
      ),
      for (final entry in const {
        'transitionIn': 'Entrée',
        'transitionOut': 'Sortie',
      }.entries) ...[
        const SizedBox(height: 12),
        StudioSelect(
          label: entry.value,
          value: (data[entry.key] as Map?)?['kind'] as String? ?? 'none',
          options: const {
            'none': 'Aucune',
            'fade': 'Fondu',
            'slideLeft': 'Vers la gauche',
            'slideRight': 'Vers la droite',
            'slideUp': 'Vers le haut',
            'slideDown': 'Vers le bas',
          },
          onChanged: (value) => onPatch({
            entry.key: {
              'kind': value,
              'durationUs': value == 'none'
                  ? 0
                  : (clip.durationUs < 500000 ? clip.durationUs : 500000),
            },
          }),
        ),
        if ((data[entry.key] as Map?)?['kind'] != null &&
            (data[entry.key] as Map?)?['kind'] != 'none')
          field(
            'Durée ${entry.value.toLowerCase()} (s)',
            ((data[entry.key] as Map)['durationUs'] as num) / 1000000,
            'durationUs',
            numeric: true,
            factor: 1000000,
            group: Map<String, Object?>.from(data[entry.key]! as Map),
            groupKey: entry.key,
          ),
      ],
      const SizedBox(height: 12),
      const StudioNotice(
        'Ombres, particules et courbes libres ne font pas partie du modèle actuel.',
      ),
    ];
  }
}
