import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_ramp_editing_session.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'map_workspace_view_state.dart';

class SpatialRampEditor extends StatefulWidget {
  const SpatialRampEditor({
    super.key,
    required this.document,
    required this.view,
    required this.onChanged,
    this.project,
  });

  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ProjectManifest? project;

  @override
  State<SpatialRampEditor> createState() => _SpatialRampEditorState();
}

class _SpatialRampEditorState extends State<SpatialRampEditor> {
  late SpatialRampEditingSession _editing;

  @override
  void initState() {
    super.initState();
    _editing = SpatialRampEditingSession(
      widget.document,
      widget.view,
      project: widget.project,
    );
  }

  @override
  void didUpdateWidget(SpatialRampEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document) ||
        !identical(oldWidget.view, widget.view)) {
      final selectedId = _editing.source?.id == widget.document.current.id
          ? _editing.ramp?.id
          : null;
      _editing.dispose();
      _editing = SpatialRampEditingSession(
        widget.document,
        widget.view,
        project: widget.project,
      );

      if (selectedId != null) {
        _editing.load(widget.document.current, rampId: selectedId);
      }
    } else {
      _editing.synchronize();
    }
    _editing.updateProject(widget.project);
  }

  @override
  void dispose() {
    _editing.dispose();
    super.dispose();
  }

  void _edit(VoidCallback change) {
    setState(() => _editing.edit(change));
    widget.onChanged();
  }

  void _preview() {
    setState(_editing.preview);
    widget.onChanged();
  }

  void _apply() {
    setState(_editing.apply);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.document.current;
    final scene = map.spatialScene;
    final ramps = scene?.navigation.ramps ?? const <SpatialRamp>[];
    final surfaces = _editing.surfaceChoices;
    final modelNames = {
      for (final model
          in widget.project?.models3d ?? const <ProjectModel3dEntry>[])
        model.id: model.name,
    };
    final enabled = _editing.enabled;
    final preview = widget.view.rampPreview;
    final validPreview = preview != null && preview.validFor(map);
    final picker = StudioSelect(
      key: const ValueKey('spatial-ramp-picker'),
      label: 'Pente de la carte',
      value: _editing.ramp?.id,
      options: {
        for (var index = 0; index < ramps.length; index++)
          ramps[index].id:
              'Pente ${index + 1} · X ${ramps[index].x}, Y ${ramps[index].z}',
      },
      onChanged: enabled
          ? (value) => _edit(() => _editing.load(map, rampId: value))
          : null,
    );
    final attachedInstance = scene?.instances
        .where((instance) => instance.id == _editing.ramp?.surfaceInstanceId)
        .firstOrNull;
    final automatic =
        widget.project?.models3d.any(
          (model) =>
              model.id == attachedInstance?.modelId &&
              model.rampProfile != null,
        ) ??
        false;
    if (automatic) {
      return StudioPanel(
        compact: true,
        title: 'Pente liée à un escalier',
        children: [
          picker,
          const SizedBox(height: 12),
          const StudioNotice(
            'Cette pente suit automatiquement son escalier. Déplacez ou tournez le décor ; réglez ses dimensions dans Ressources pour changer le modèle.',
          ),
        ],
      );
    }
    return StudioPanel(
      compact: true,
      title: 'Ajuster une pente',
      children: [
        if (ramps.isEmpty)
          const StudioNotice(
            'Dessinez une pente sur la carte pour pouvoir ajuster ici sa position et ses dimensions.',
          )
        else ...[
          picker,
          const SizedBox(height: 12),
          for (final field in <(String, String, ValueChanged<String>)>[
            ('X', _editing.x, (value) => _editing.x = value),
            ('Y', _editing.y, (value) => _editing.y = value),
            ('Largeur', _editing.width, (value) => _editing.width = value),
            ('Profondeur', _editing.depth, (value) => _editing.depth = value),
          ]) ...[
            StudioDraftField(
              key: ValueKey('spatial-ramp-${field.$1}'),
              label: field.$1,
              value: field.$2,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _edit(() => field.$3(value)),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Position et dimensions en cases. Un niveau représente ${scene!.levelHeight} case de hauteur.',
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('spatial-ramp-low-level'),
            label: 'Niveau bas',
            value: _editing.lowLevel,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => _edit(() => _editing.lowLevel = value),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('spatial-ramp-high-level'),
            label: 'Niveau haut',
            value: _editing.highLevel,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => _edit(() => _editing.highLevel = value),
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-direction'),
            label: 'Montée vers',
            value: _editing.direction.name,
            options: const {
              'north': 'Le haut de la carte',
              'south': 'Le bas de la carte',
              'east': 'La droite de la carte',
              'west': 'La gauche de la carte',
            },
            onChanged: enabled
                ? (value) => _edit(
                    () => _editing.direction = SpatialRampDirection.values
                        .byName(value),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-surface'),
            label: 'Apparence de la pente',
            value: _editing.surfaceInstanceId ?? '',
            options: {
              '': 'Terrain peint',
              for (var index = 0; index < surfaces.length; index++)
                surfaces[index].id:
                    '${modelNames[surfaces[index].modelId] ?? 'Décor ${index + 1}'} · X ${surfaces[index].position.x}, Y ${surfaces[index].position.z}',
            },
            onChanged: enabled
                ? (value) => _edit(
                    () => _editing.surfaceInstanceId = value.isEmpty
                        ? null
                        : value,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          const StudioNotice(
            'Choisissez un escalier déjà placé pour afficher ses marches à la place du terrain. Son emprise doit couvrir la pente ; il doit laisser passer le personnage.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('spatial-ramp-preview'),
                label: 'Aperçu',
                secondary: true,
                onPressed: enabled ? _preview : null,
              ),
              StudioButton(
                key: const ValueKey('spatial-ramp-apply'),
                label: 'Appliquer',
                onPressed: enabled && validPreview && preview.hasChanges
                    ? _apply
                    : null,
              ),
              StudioButton(
                key: const ValueKey('spatial-ramp-cancel'),
                label: 'Annuler l’aperçu',
                variant: StudioButtonVariant.quiet,
                onPressed: validPreview ? () => _edit(() {}) : null,
              ),
            ],
          ),
          if (validPreview) ...[
            const SizedBox(height: 12),
            StudioNotice(
              preview.hasChanges
                  ? 'Aperçu sur la carte. Les décors suivent leur sol et conservent leur décalage de hauteur. Appliquez pour modifier la carte.'
                  : 'La pente correspond déjà à ces valeurs.',
            ),
          ],
          if (_editing.error != null) ...[
            const SizedBox(height: 12),
            StudioNotice(_editing.error!, isError: true),
          ],
          if (_editing.notice != null) ...[
            const SizedBox(height: 12),
            StudioNotice(_editing.notice!),
          ],
        ],
      ],
    );
  }
}
