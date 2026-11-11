part of 'presentation_inspector.dart';

extension _PresentationTransformFields on PresentationInspector {
  List<Widget> transformFields(PresentationClip clip) {
    final poseKey = presentationPoseKey(
      pose: view.pose,
      orientationOverride: view.orientationOverride,
      portrait: view.portrait,
    );
    Widget number(
      String label,
      String key,
      double fallback, {
      double factor = 1,
    }) => StudioCommitField(
      key: ValueKey('${clip.id}:$poseKey:$key'),
      label: label,
      value:
          '${presentationPoseFieldValue(clip, poseKey, key, fallback, factor: factor)}',
      tryCommit: (text) {
        final valid = commitPresentationPoseField(
          view.invalidFields,
          label,
          clip,
          key,
          text,
          pose: view.pose,
          orientationOverride: view.orientationOverride,
          portrait: view.portrait,
          apply: onPatch,
          factor: factor,
        );
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
      number(
        'Rotation (°)',
        'rotationTurns',
        0,
        factor: presentationRotationDegreeFactor,
      ),
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
