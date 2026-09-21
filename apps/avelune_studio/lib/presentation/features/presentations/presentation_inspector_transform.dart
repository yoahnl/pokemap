part of 'presentation_inspector.dart';

extension _PresentationTransformFields on PresentationInspector {
  List<Widget> transformFields(PresentationClip clip) {
    final encoded = encodePresentationClip(clip);
    final poseKey = view.orientationOverride
        ? (view.portrait
              ? 'portraitCompositionOverride'
              : 'landscapeCompositionOverride')
        : view.pose == PresentationPose.end
        ? 'to'
        : 'from';
    final pose = Map<String, Object?>.from(encoded[poseKey] as Map? ?? {});
    Widget number(
      String label,
      String key,
      double fallback, {
      double factor = 1,
    }) => StudioCommitField(
      key: ValueKey('${clip.id}:$poseKey:$key'),
      label: label,
      value: '${((pose[key] as num?)?.toDouble() ?? fallback) / factor}',
      tryCommit: (text) {
        final number = double.tryParse(text.replaceAll(',', '.'));
        final patched = {...pose, key: number == null ? null : number * factor};
        final valid =
            number != null &&
            number.isFinite &&
            onPatch({
              poseKey: patched,
              if (!view.orientationOverride &&
                  view.pose == PresentationPose.trajectory)
                'to': {
                  ...Map<String, Object?>.from(encoded['to'] as Map? ?? {}),
                  key: number * factor,
                },
            });
        if (valid) {
          view.invalidFields.remove(label);
        } else {
          view.invalidFields.add(label);
        }
        changed();
        return valid;
      },
    );
    return [
      const SizedBox(height: 16),
      const Text('Transformations'),
      const SizedBox(height: 10),
      StudioSelect(
        label: 'Modifier la pose',
        value: view.pose.name,
        options: const {
          'start': 'Début',
          'end': 'Fin',
          'trajectory': 'Toute la trajectoire',
        },
        onChanged: (value) {
          view.pose = PresentationPose.values.byName(value);
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Pose ${view.portrait ? 'portrait' : 'paysage'} indépendante',
        ),
        value: view.orientationOverride,
        onChanged: (value) {
          view.orientationOverride = value;
          changed();
        },
      ),
      number('Position X', 'translateX', 0),
      const SizedBox(height: 10),
      number('Position Y', 'translateY', 0),
      const SizedBox(height: 10),
      number('Échelle X', 'scaleX', 1),
      const SizedBox(height: 10),
      number('Échelle Y', 'scaleY', 1),
      const SizedBox(height: 10),
      number('Rotation (°)', 'rotationTurns', 0, factor: 1 / 360),
      const SizedBox(height: 10),
      number('Opacité', 'opacity', 1),
      const SizedBox(height: 10),
      for (final side in const {
        'Left': 'gauche',
        'Top': 'haut',
        'Right': 'droite',
        'Bottom': 'bas',
      }.entries) ...[
        number('Recadrage ${side.value}', 'crop${side.key}', 0),
        const SizedBox(height: 10),
      ],
    ];
  }
}
