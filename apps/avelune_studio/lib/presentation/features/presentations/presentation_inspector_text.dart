part of 'presentation_inspector.dart';

extension _PresentationTextFields on PresentationInspector {
  List<Widget> textFields(PresentationTextClip clip) {
    final style = Map<String, Object?>.from(
      encodePresentationClip(clip)['style']! as Map,
    );
    return [
      field('Contenu du texte', clip.text, 'text', lines: 4),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Police',
        value: clip.style.fontFamily ?? '',
        options: {
          '': 'Police du Player',
          ?clip.style.fontFamily: clip.style.fontFamily ?? '',
        },
        onChanged: (value) => onPatch({
          'style': {...style, 'fontFamily': value.isEmpty ? null : value},
        }),
      ),
      const SizedBox(height: 12),
      field(
        'Taille du texte',
        clip.style.fontSize,
        'fontSize',
        numeric: true,
        group: style,
        groupKey: 'style',
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Graisse',
        value: clip.style.weight.name,
        options: const {'regular': 'Normal', 'medium': 'Moyen', 'bold': 'Gras'},
        onChanged: (value) => onPatch({
          'style': {...style, 'weight': value},
        }),
      ),
      const SizedBox(height: 12),
      field(
        'Couleur du texte',
        clip.style.colorHex,
        'colorHex',
        group: style,
        groupKey: 'style',
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Alignement',
        value: clip.style.alignment.name,
        options: const {'start': 'Gauche', 'center': 'Centre', 'end': 'Droite'},
        onChanged: (value) => onPatch({
          'style': {...style, 'alignment': value},
        }),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Retour à la ligne',
        value: clip.style.wrapping.name,
        options: const {'wrap': 'Automatique', 'noWrap': 'Une seule ligne'},
        onChanged: (value) => onPatch({
          'style': {...style, 'wrapping': value},
        }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Respecter la zone sûre'),
        value: clip.style.respectSafeArea,
        onChanged: (value) => onPatch({
          'style': {...style, 'respectSafeArea': value},
        }),
      ),
    ];
  }
}
