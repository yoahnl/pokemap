import '../../../features/resources/application/model_definition_drafts.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ModelRampControls extends StatefulWidget {
  const ModelRampControls({
    super.key,
    required this.model,
    required this.onSave,
    this.busy = false,
  });
  final ProjectModel3dEntry model;
  final Future<void> Function(Model3dRampProfile?) onSave;
  final bool busy;

  @override
  State<ModelRampControls> createState() => _ModelRampControlsState();
}

class _ModelRampControlsState extends State<ModelRampControls> {
  late ModelRampDraft _draft;
  bool get saving => _draft.saving;
  bool get enabled => _draft.enabled;
  set enabled(bool value) => _draft.enabled = value;
  SpatialRampDirection get direction => _draft.direction;
  set direction(SpatialRampDirection value) => _draft.direction = value;
  List<String> get values => _draft.values;
  set values(List<String> value) => _draft.values = value;
  String? get error => _draft.error;
  set error(String? value) => _draft.error = value;

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(ModelRampControls old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id ||
        old.model.rampProfile != widget.model.rampProfile) {
      _draft.dispose();
      reset();
    }
  }

  void reset() {
    _draft = ModelRampDraft(widget.model);
  }

  Future<void> save() async {
    final owner = _draft;
    final saving = owner.save(
      widget.onSave,
      canSave: () => mounted && !widget.busy,
    );
    setState(() {});
    await saving;
    if (mounted && identical(_draft, owner)) setState(() {});
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Escalier franchissable',
    children: [
      StudioSelect(
        label: 'Déplacement sur ce modèle',
        value: enabled ? 'stairs' : 'decor',
        options: const {
          'decor': 'Décor classique',
          'stairs': 'Escalier · pente automatiquement liée',
        },
        onChanged: widget.busy || saving
            ? null
            : (value) => setState(() => enabled = value == 'stairs'),
      ),
      const SizedBox(height: 12),
      const Text(
        'La pente se crée à la pose et suit les déplacements, les rotations par quarts de tour et la suppression. Les plateaux autour restent à dessiner.',
      ),
      if (enabled) ...[
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Sens de la montée dans le modèle',
          value: direction.name,
          options: const {
            'north': 'Vers le fond',
            'south': 'Vers le devant',
            'east': 'Vers la droite',
            'west': 'Vers la gauche',
          },
          onChanged: widget.busy || saving
              ? null
              : (value) => setState(
                  () => direction = SpatialRampDirection.values.byName(value),
                ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Emprise et hauteurs dans le modèle, avant origine et échelle. Les dimensions du modèle sont proposées au départ.',
        ),
        const SizedBox(height: 8),
        for (final (i, label) in [
          'Début horizontal',
          'Début en profondeur',
          'Largeur',
          'Profondeur',
          'Hauteur basse',
          'Hauteur haute',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudioDraftField(
              key: ValueKey('model-ramp-$i'),
              label: label,
              value: values[i],
              enabled: !widget.busy && !saving,
              onChanged: (value) => values[i] = value,
            ),
          ),
      ],
      if (error != null) StudioNotice(error!),
      StudioButton(
        label: 'Appliquer le comportement',
        onPressed: widget.busy || saving ? null : save,
      ),
    ],
  );
}
