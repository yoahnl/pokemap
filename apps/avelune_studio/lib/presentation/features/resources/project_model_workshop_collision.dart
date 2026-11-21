part of 'project_model_workshop.dart';

extension _ProjectModelWorkshopCollision on _ProjectModelWorkshopState {
  List<Widget> _collisionControls(
    ProjectModel3dEntry model, {
    required bool editable,
    required bool valid,
  }) {
    final draft = _collisionDraft;
    final custom = model.collisionBounds;
    return [
      const Text('Volume de collision'),
      Text(
        custom == null
            ? 'Limites d’origine du modèle'
            : 'Volume personnalisé \u00b7 ${_vectorLabel(custom.min)} à ${_vectorLabel(custom.max)}',
      ),
      if (draft == null && editable) ...[
        const SizedBox(height: StudioSpacing.s),
        StudioButton(
          label: 'Modifier le volume de collision',
          variant: StudioButtonVariant.secondary,
          onPressed: () =>
              _update(() => _collisionDraft = _ModelCollisionDraft(model)),
        ),
      ],
      if (draft != null) ...[
        StudioToggleRow(
          key: const ValueKey('model-workshop-collision-override'),
          label: 'Utiliser un volume personnalisé',
          description: 'Le volume est défini dans les coordonnées du modèle.',
          value: draft.custom,
          onChanged: editable
              ? (value) => _update(() => draft.custom = value)
              : null,
        ),
        if (draft.custom)
          for (final (bound, start) in [('Min.', 0), ('Max.', 3)])
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.s),
              child: Wrap(
                spacing: StudioSpacing.s,
                runSpacing: StudioSpacing.s,
                children: [
                  for (final (index, axis) in ['X', 'Y', 'Z'].indexed)
                    SizedBox(
                      width: 92,
                      child: StudioDraftField(
                        key: ValueKey(
                          'model-workshop-collision-${start + index}',
                        ),
                        value: draft.values[start + index],
                        label: '$bound $axis',
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        enabled: editable,
                        onChanged: (value) =>
                            _update(() => draft.values[start + index] = value),
                      ),
                    ),
                ],
              ),
            ),
        if (!valid)
          const StudioNotice(
            'Saisissez six nombres. Chaque maximum doit dépasser son minimum.',
            isError: true,
          ),
        const SizedBox(height: StudioSpacing.s),
        StudioButton(
          label: 'Annuler le réglage du volume',
          variant: StudioButtonVariant.quiet,
          onPressed: editable
              ? () => _update(() => _collisionDraft = null)
              : null,
        ),
      ],
    ];
  }
}

String _vectorLabel(Model3dVector3 vector) =>
    '(${vector.x}, ${vector.y}, ${vector.z})';

double? _modelDraftNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

class _ModelCollisionDraft {
  _ModelCollisionDraft(ProjectModel3dEntry model)
    : custom = model.collisionBounds != null,
      values = _components(model.collisionBounds ?? model.inspection.bounds);

  bool custom;
  final List<String> values;

  static List<String> _components(Model3dBounds bounds) => [
    for (final point in [bounds.min, bounds.max]) ...[
      point.x.toString(),
      point.y.toString(),
      point.z.toString(),
    ],
  ];

  Model3dBounds? get bounds {
    if (!custom) return null;
    final components = <double>[];
    for (final value in values) {
      final number = _modelDraftNumber(value);
      if (number == null) return null;
      components.add(number);
    }
    for (var index = 0; index < 3; index++) {
      final length = components[index + 3] - components[index];
      if (!length.isFinite || length <= 0) return null;
    }
    return Model3dBounds(
      min: Model3dVector3(x: components[0], y: components[1], z: components[2]),
      max: Model3dVector3(x: components[3], y: components[4], z: components[5]),
    );
  }
}
