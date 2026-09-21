part of 'presentation_inspector.dart';

extension _PresentationMediaFields on PresentationInspector {
  List<Widget> mediaFields(PresentationClip clip) {
    final encoded = encodePresentationClip(clip);
    final kind = clip is PresentationAudioClip
        ? ProjectMediaKind.audio
        : clip is PresentationCaptionClip
        ? ProjectMediaKind.captions
        : (clip as PresentationVisualClip).mediaKind ==
              PresentationVisualMediaKind.video
        ? ProjectMediaKind.video
        : ProjectMediaKind.image;
    final entries =
        mediaCatalog?.entries.where((entry) => entry.kind == kind) ??
        <ProjectMediaAsset>[];
    final key = clip is PresentationCaptionClip ? 'captionId' : 'resourceId';
    return [
      StudioSelect(
        label: 'Média',
        value: encoded[key]! as String,
        options: {for (final entry in entries) entry.id: entry.label},
        onChanged: (value) => onPatch({key: value}),
      ),
      if (clip is PresentationVisualClip || clip is PresentationAudioClip)
        for (final variant in const {
          'landscapeResourceId': 'Variante paysage',
          'portraitResourceId': 'Variante portrait',
        }.entries) ...[
          const SizedBox(height: 12),
          StudioSelect(
            label: variant.value,
            value: encoded[variant.key] as String? ?? '',
            options: {
              '': 'Média principal',
              for (final entry in entries) entry.id: entry.label,
            },
            onChanged: (value) =>
                onPatch({variant.key: value.isEmpty ? null : value}),
          ),
        ],
      if (clip is PresentationAudioClip) ...[
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Type audio',
          value: clip.audioKind.name,
          options: const {
            'music': 'Musique',
            'voice': 'Voix',
            'soundEffect': 'Effet sonore',
          },
          onChanged: (value) => onPatch({'audioKind': value}),
        ),
        StudioSelect(
          label: 'Bus audio',
          value: clip.bus.name,
          options: const {
            'music': 'Musique',
            'voice': 'Voix',
            'effects': 'Effets',
          },
          onChanged: (value) => onPatch({'bus': value}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Boucler le média'),
          value: clip.loop,
          onChanged: (value) => onPatch({'loop': value}),
        ),
      ],
      if (clip is PresentationCaptionClip) ...[
        const SizedBox(height: 12),
        field('Langue des sous-titres', clip.locale, 'locale'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Repli vers la langue du projet'),
          value: clip.fallbackToProjectDefault,
          onChanged: (value) => onPatch({'fallbackToProjectDefault': value}),
        ),
      ],
      const SizedBox(height: 12),
    ];
  }
}
