import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/environment_draft.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_library_edit_dialog.dart';

class ProjectEnvironmentEditorDialog extends StatefulWidget {
  const ProjectEnvironmentEditorDialog({
    super.key,
    required this.original,
    required this.spatial,
    required this.paletteName,
    required this.pick,
    required this.publish,
    required this.reconcile,
  });

  final EnvironmentPreset? original;
  final bool spatial;
  final String Function(EnvironmentPaletteItem) paletteName;
  final Future<ProjectLibraryItem?> Function(Set<String>) pick;
  final Future<ProjectLibraryEdit> Function(EnvironmentPreset) publish;
  final Future<ProjectLibraryEdit> Function(
    EnvironmentPreset,
    ResourceMutationReceipt,
  )
  reconcile;

  @override
  State<ProjectEnvironmentEditorDialog> createState() =>
      _ProjectEnvironmentEditorDialogState();
}

class _ProjectEnvironmentEditorDialogState
    extends State<ProjectEnvironmentEditorDialog> {
  late final _draft = EnvironmentDraft(original: widget.original);
  bool _saving = false;
  String? _error;
  ResourceMutationReceipt? _pending;

  bool get _editable => !_saving && _pending == null;

  void _change(VoidCallback edit) => setState(() {
    edit();
    _error = null;
  });

  Future<void> _add() async {
    final picked = await widget.pick({
      for (final item in _draft.palette) item.resourceId,
    });
    if (!mounted || !_editable || picked == null) return;
    _change(() => _draft.add(picked.id, spatial: widget.spatial));
  }

  Future<void> _publish() async {
    if (_saving) return;
    final EnvironmentPreset preset;
    try {
      preset = _draft.build();
    } on FormatException catch (failure) {
      setState(() => _error = failure.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final pending = _pending;
      final edit = pending == null
          ? await widget.publish(preset)
          : await widget.reconcile(preset, pending);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop<ProjectLibraryEditDialogResult>(context, (
        edit: edit,
        partialReceipt: null,
      ));
    } on ResourceFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pending = failure.partialReceipt ?? _pending;
        _error = failure.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Impossible de publier cet ensemble de décors. Réessayez.';
      });
    }
  }

  void _cancel() => Navigator.pop<ProjectLibraryEditDialogResult>(context, (
    edit: null,
    partialReceipt: _pending,
  ));

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: StudioReviewDialog(
      title: widget.original == null
          ? 'Nouvel ensemble de décors'
          : 'Modifier l’ensemble de décors',
      confirmLabel: _saving
          ? 'Publication…'
          : _pending == null
          ? 'Publier l’environnement'
          : 'Relire la publication',
      onConfirmed: _saving || !_draft.dirty ? null : _publish,
      onCancelled: _saving ? null : _cancel,
      cancelLabel: _pending == null ? 'Annuler' : 'Fermer',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioDraftField(
            key: const ValueKey('environment-name'),
            label: 'Nom de l’ensemble',
            value: _draft.name,
            enabled: _editable,
            onChanged: (name) => _change(() => _draft.name = name),
          ),
          const SizedBox(height: StudioSpacing.l),
          Text(
            'Décors à répartir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: StudioSpacing.s),
          for (final entry in _draft.palette) _paletteEntry(entry),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              label: widget.spatial
                  ? 'Ajouter un modèle 3D'
                  : 'Ajouter un décor',
              icon: Icons.add,
              variant: StudioButtonVariant.secondary,
              onPressed: _editable ? _add : null,
            ),
          ),
          const SizedBox(height: StudioSpacing.l),
          _distribution(),
          if (_error case final error?) ...[
            const SizedBox(height: StudioSpacing.m),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _paletteEntry(EnvironmentPaletteItem entry) {
    final id = entry.resourceId;
    return Padding(
      key: ValueKey('environment-palette-$id'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.paletteName(entry))),
              StudioButton(
                label: 'Retirer',
                variant: StudioButtonVariant.quiet,
                onPressed: _editable
                    ? () => _change(() => _draft.remove(id))
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: StudioDraftField(
                  label: 'Poids dans le mélange',
                  value: _draft.weightInput(id),
                  keyboardType: TextInputType.number,
                  enabled: _editable,
                  onChanged: (value) =>
                      _change(() => _draft.setWeightInput(id, value)),
                ),
              ),
              const SizedBox(width: StudioSpacing.m),
              Expanded(
                child: StudioSelect(
                  label: 'Collision',
                  value: entry.collisionMode.name,
                  options: {
                    EnvironmentCollisionMode.useElementDefault.name:
                        'Réglage du décor',
                    EnvironmentCollisionMode.forceEnabled.name: 'Activer',
                    EnvironmentCollisionMode.forceDisabled.name: 'Désactiver',
                  },
                  onChanged: !_editable
                      ? null
                      : (value) => _change(
                          () => _draft.setItem(
                            id,
                            collision: EnvironmentCollisionMode.values.byName(
                              value,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (entry.isSpatial) ...[
            const SizedBox(height: StudioSpacing.s),
            Row(
              children: [
                for (final axis in ['x', 'y', 'z'])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: axis == 'z' ? 0 : StudioSpacing.s,
                      ),
                      child: StudioDraftField(
                        label: 'Décalage ${axis.toUpperCase()}',
                        value: _draft.offsetInput(id, axis),
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        enabled: _editable,
                        onChanged: (value) => _change(
                          () => _draft.setOffsetInput(id, axis, value),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _distribution() {
    final params = _draft.params;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slider(
          'Densité',
          params.density,
          (value) => _change(() => _draft.setDistribution(density: value)),
        ),
        _slider(
          'Variation',
          params.variation,
          (value) => _change(() => _draft.setDistribution(variation: value)),
        ),
        _slider(
          'Densité aux bords',
          params.edgeDensity,
          (value) => _change(() => _draft.setDistribution(edgeDensity: value)),
        ),
        StudioDraftField(
          label: 'Espacement minimum en cases',
          value: _draft.spacingInput,
          keyboardType: TextInputType.number,
          enabled: _editable,
          onChanged: (value) => _change(() => _draft.setSpacingInput(value)),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> changed) =>
      StudioSlider(
        label: label,
        value: value,
        onChanged: _editable ? changed : null,
        valueLabel: '${(value * 100).round()} %',
      );
}
