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
  late bool enabled;
  late SpatialRampDirection direction;
  late List<String> values;
  bool saving = false;
  String? error;

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
      reset();
    }
  }

  void reset() {
    final profile = widget.model.rampProfile;
    final bounds = widget.model.inspection.bounds;
    enabled = profile != null;
    direction = profile?.direction ?? SpatialRampDirection.north;
    values = [
      profile?.x ?? bounds.min.x,
      profile?.z ?? bounds.min.z,
      profile?.width ?? bounds.size.x,
      profile?.depth ?? bounds.size.z,
      profile?.lowHeight ?? bounds.min.y,
      profile?.highHeight ?? bounds.max.y,
    ].map((v) => '$v').toList();
    error = null;
  }

  Future<void> save() async {
    if (saving || widget.busy) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      Model3dRampProfile? profile;
      if (enabled) {
        final parsed = values
            .map((v) => double.tryParse(v.replaceAll(',', '.')))
            .toList();
        if (parsed.any((v) => v == null || !v.isFinite)) {
          throw const FormatException('Saisissez des dimensions valides.');
        }
        final n = parsed.cast<double>();
        profile = Model3dRampProfile(
          x: n[0],
          z: n[1],
          width: n[2],
          depth: n[3],
          lowHeight: n[4],
          highHeight: n[5],
          direction: direction,
        );
      }
      await widget.onSave(profile);
    } on Object catch (failure) {
      if (mounted) {
        setState(
          () => error = 'Impossible d’appliquer cet escalier : $failure',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
