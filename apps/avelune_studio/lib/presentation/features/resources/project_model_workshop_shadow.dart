part of 'project_model_workshop.dart';

extension _ProjectModelWorkshopShadow on _ProjectModelWorkshopState {
  Widget _settings(ProjectModel3dEntry model, String? revision) {
    final save = widget.saveShadow;
    final pending = _pendingReceipt;
    final reconcile = widget.reconcileShadow;
    final enabled = _shadowDraft ?? model.castsShadowsByDefault;
    final dirty = enabled != model.castsShadowsByDefault;
    final editable =
        save != null && revision != null && !_saving && !_replacing;
    return StudioPanel(
      title: 'Ombre du modèle',
      children: [
        StudioToggleRow(
          key: const ValueKey('model-workshop-shadow'),
          label: 'Projeter une ombre',
          description: 'Réglage partagé des placements qui héritent du modèle.',
          value: enabled,
          onChanged: editable && pending == null
              ? (checked) => _update(() => _shadowDraft = checked)
              : null,
        ),
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
                  : () => _publish(model, enabled, () => reconcile(pending)),
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
                onPressed: editable && dirty
                    ? () => _publish(
                        model,
                        enabled,
                        () => save(enabled, revision),
                      )
                    : null,
              ),
              if (_published != null && !dirty && !_saving)
                const StudioBadge('Enregistré', icon: Icons.check),
            ],
          ),
        ],
      ],
    );
  }
}
