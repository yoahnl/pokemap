part of 'project_model_workshop.dart';

extension _ProjectModelWorkshopShadow on _ProjectModelWorkshopState {
  Widget _settings(ProjectModel3dEntry model, String? revision) {
    final save = widget.saveShadow;
    final saveSettings = widget.saveSettings;
    final pending = _pendingReceipt;
    final reconcile = widget.reconcileShadow;
    final enabled = _shadowDraft ?? model.castsShadowsByDefault;
    final shadowChanged = enabled != model.castsShadowsByDefault;
    final collisionDraft = _collisionDraft;
    final bounds = collisionDraft?.bounds;
    final collisionChanged =
        collisionDraft != null && bounds != model.collisionBounds;
    final transform = _transformDraft?.value;
    final scale = transform?.scale;
    final pivot = transform?.pivot;
    final scaleChanged = scale != null && scale != model.scale;
    final pivotChanged = pivot != null && pivot != model.pivot;
    final settingsChanged = collisionChanged || scaleChanged || pivotChanged;
    final dirty = shadowChanged || settingsChanged;
    final collisionValid = collisionDraft?.custom != true || bounds != null;
    final transformValid =
        _transformDraft == null ||
        (transform != null && model.rampProfile == null);
    final editable =
        save != null && revision != null && !_saving && !_replacing;
    final editingSettings = collisionDraft != null || _transformDraft != null;
    final canEditSettings = editable && saveSettings != null && pending == null;
    final definitionControls = <Widget>[
      const SizedBox(height: StudioSpacing.l),
      ..._collisionControls(
        model,
        editable: canEditSettings,
        valid: collisionValid,
      ),
      const SizedBox(height: StudioSpacing.l),
      ..._transformControls(
        model,
        editable: canEditSettings,
        valid: transformValid,
      ),
    ];
    return StudioPanel(
      title: 'Réglages partagés du modèle',
      children: [
        StudioToggleRow(
          key: const ValueKey('model-workshop-shadow'),
          label: 'Projeter une ombre',
          description: 'Réglage partagé des placements qui héritent du modèle.',
          value: enabled,
          onChanged: editable && pending == null
              ? (checked) => _update(
                  () => _shadowDraft = checked == model.castsShadowsByDefault
                      ? null
                      : checked,
                )
              : null,
        ),
        if (editingSettings) ...definitionControls,
        if (pending != null) ...[
          const SizedBox(height: StudioSpacing.m),
          const StudioNotice(
            'Le réglage est enregistré. Relisez l’enregistrement pour actualiser le Studio.',
          ),
          if (_problem case final problem?) ...[
            const SizedBox(height: StudioSpacing.m),
            StudioNotice(problem, isError: true),
          ],
          if (reconcile != null) ...[
            const SizedBox(height: StudioSpacing.m),
            StudioButton(
              label: _saving ? 'Relecture…' : 'Relire l’enregistrement',
              loading: _saving,
              onPressed: _saving || _replacing
                  ? null
                  : () => _publish(model, () => reconcile(pending)),
            ),
          ],
        ] else if (_problem case final problem?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(problem, isError: true),
          const SizedBox(height: StudioSpacing.m),
          StudioButton(
            label: 'Relire le modèle',
            variant: StudioButtonVariant.quiet,
            onPressed: () => _update(() => _read(keepDraft: true)),
          ),
        ] else if (save != null && revision != null) ...[
          const SizedBox(height: StudioSpacing.l),
          Wrap(
            spacing: StudioSpacing.m,
            runSpacing: StudioSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StudioButton(
                key: const ValueKey('model-workshop-save'),
                label: _saving ? 'Enregistrement…' : 'Enregistrer',
                icon: Icons.save_outlined,
                loading: _saving,
                onPressed: editable && dirty && collisionValid && transformValid
                    ? () => _publish(
                        model,
                        () => settingsChanged && saveSettings != null
                            ? saveSettings((
                                collisionChanged: collisionChanged,
                                collisionBounds: bounds,
                                castsShadows: shadowChanged ? enabled : null,
                                scale: scaleChanged ? scale : null,
                                pivot: pivotChanged ? pivot : null,
                              ), revision)
                            : save(enabled, revision),
                      )
                    : null,
              ),
              if (_published != null && !dirty && !_saving)
                const StudioBadge('Enregistré', icon: Icons.check),
            ],
          ),
        ],
        if (!editingSettings) ...definitionControls,
      ],
    );
  }
}
