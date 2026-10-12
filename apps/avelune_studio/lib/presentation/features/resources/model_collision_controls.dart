import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ModelCollisionControls extends StatefulWidget {
  const ModelCollisionControls({
    super.key,
    required this.model,
    required this.onSave,
    this.busy = false,
  });
  final ProjectModel3dEntry model;
  final Future<void> Function(Model3dBounds? bounds) onSave;
  final bool busy;

  @override
  State<ModelCollisionControls> createState() => _ModelCollisionControlsState();
}

class _ModelCollisionControlsState extends State<ModelCollisionControls> {
  late bool custom;
  late List<String> values;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(ModelCollisionControls old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id ||
        old.model.collisionBounds != widget.model.collisionBounds) {
      reset();
    }
  }

  void reset() {
    custom = widget.model.collisionBounds != null;
    final bounds =
        widget.model.collisionBounds ?? widget.model.inspection.bounds;
    values = [
      bounds.min.x,
      bounds.min.y,
      bounds.min.z,
      bounds.max.x,
      bounds.max.y,
      bounds.max.z,
    ].map((value) => '$value').toList();
    error = null;
  }

  Future<void> save() async {
    if (saving || widget.busy) return;
    Model3dBounds? bounds;
    if (custom) {
      final parsed = values
          .map((value) => double.tryParse(value.replaceAll(',', '.')))
          .toList();
      if (parsed.any((value) => value == null || !value.isFinite)) {
        setState(() => error = 'Saisissez six nombres valides pour le volume.');
        return;
      }
      final numbers = parsed.cast<double>();
      if ([0, 1, 2].any((axis) => numbers[axis] >= numbers[axis + 3])) {
        setState(
          () => error =
              'Chaque maximum doit être supérieur au minimum correspondant.',
        );
        return;
      }
      bounds = Model3dBounds(
        min: Model3dVector3(x: numbers[0], y: numbers[1], z: numbers[2]),
        max: Model3dVector3(x: numbers[3], y: numbers[4], z: numbers[5]),
      );
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave(bounds);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Volume de collision',
    children: [
      IgnorePointer(
        ignoring: saving || widget.busy,
        child: StudioSelect(
          key: const ValueKey('model-collision-mode'),
          label: 'Volume utilisé',
          value: custom ? 'custom' : 'model',
          options: const {
            'model': 'Volume du modèle',
            'custom': 'Volume personnalisé',
          },
          onChanged: (value) => setState(() {
            custom = value == 'custom';
            error = null;
          }),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Un arbre peut bloquer uniquement avec son tronc. Le volume visuel du modèle reste indépendant.',
      ),
      if (custom) ...[
        const SizedBox(height: 12),
        Text(
          'Coordonnées locales du fichier GLB, avant origine et échelle. 1 unité source = ${widget.model.scale} case(s) dans le jeu.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < 6; index++)
              SizedBox(
                width: 200,
                child: StudioDraftField(
                  key: ValueKey(
                    'model-collision-${index < 3 ? 'min' : 'max'}-${['x', 'y', 'z'][index % 3]}',
                  ),
                  label:
                      '${index < 3 ? 'Minimum' : 'Maximum'} ${['X · largeur', 'Y · hauteur', 'Z · profondeur'][index % 3]}',
                  value: values[index],
                  enabled: !saving && !widget.busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (value) => setState(() => values[index] = value),
                ),
              ),
          ],
        ),
      ],
      if (error != null) ...[
        const SizedBox(height: 12),
        StudioNotice(error!, isError: true),
      ],
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            key: const ValueKey('model-collision-save'),
            label: saving ? 'Enregistrement…' : 'Enregistrer le volume',
            icon: Icons.save_outlined,
            onPressed: saving || widget.busy ? null : save,
          ),
          StudioButton(
            label: 'Annuler les modifications',
            secondary: true,
            onPressed: saving || widget.busy ? null : () => setState(reset),
          ),
        ],
      ),
    ],
  );
}
