part of 'project_model_workshop.dart';

extension _ProjectModelWorkshopTransform on _ProjectModelWorkshopState {
  List<Widget> _transformControls(
    ProjectModel3dEntry model, {
    required bool editable,
    required bool valid,
  }) {
    final draft = _transformDraft;
    final ramp = model.rampProfile != null;
    const labels = ['Échelle', 'Pivot X', 'Pivot Y', 'Pivot Z'];
    return [
      Text('Échelle de définition ×${model.scale}'),
      Text('Pivot ${_vectorLabel(model.pivot)}'),
      if (ramp)
        const StudioNotice(
          'Le pivot et l’échelle d’une rampe nécessitent une mise à jour des placements.',
        ),
      if (draft == null && editable && !ramp)
        StudioButton(
          label: 'Modifier le pivot et l’échelle',
          variant: StudioButtonVariant.secondary,
          onPressed: () =>
              _update(() => _transformDraft = _ModelTransformDraft(model)),
        ),
      if (draft != null) ...[
        const SizedBox(height: StudioSpacing.s),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            for (final (index, label) in labels.indexed)
              SizedBox(
                width: 110,
                child: StudioDraftField(
                  key: ValueKey('model-workshop-transform-$index'),
                  label: label,
                  value: draft.values[index],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  enabled: editable && !ramp,
                  onChanged: (value) =>
                      _update(() => draft.values[index] = value),
                ),
              ),
          ],
        ),
        if (!valid && !ramp)
          const StudioNotice(
            'Saisissez un pivot numérique et une échelle positive jusqu’à 1 000 000.',
            isError: true,
          ),
        StudioButton(
          label: 'Annuler le pivot et l’échelle',
          variant: StudioButtonVariant.quiet,
          onPressed: editable
              ? () => _update(() => _transformDraft = null)
              : null,
        ),
      ],
      if (model.inspection.animations.isNotEmpty)
        Text(
          'Animations intégrées dans le GLB\n'
          '${model.inspection.animations.map((clip) => clip.name).join(', ')}',
        ),
    ];
  }
}

class _ModelTransformDraft {
  _ModelTransformDraft(ProjectModel3dEntry model)
    : values = [
        '${model.scale}',
        '${model.pivot.x}',
        '${model.pivot.y}',
        '${model.pivot.z}',
      ];

  final List<String> values;

  ({double scale, Model3dVector3 pivot})? get value {
    final scale = _modelDraftNumber(values[0]);
    final x = _modelDraftNumber(values[1]);
    final y = _modelDraftNumber(values[2]);
    final z = _modelDraftNumber(values[3]);
    if (scale == null ||
        scale <= 0 ||
        scale > 1000000 ||
        x == null ||
        y == null ||
        z == null) {
      return null;
    }
    return (scale: scale, pivot: Model3dVector3(x: x, y: y, z: z));
  }
}
