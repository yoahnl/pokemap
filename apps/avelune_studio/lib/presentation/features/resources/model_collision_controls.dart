import '../../../features/resources/application/model_definition_drafts.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ModelCollisionControls extends StatefulWidget {
  const ModelCollisionControls({
    super.key,
    required this.model,
    required this.onSave,
    this.busy = false,
  });
  final ProjectModel3dEntry model;
  final Future<void> Function(
    Model3dBounds? bounds,
    bool blocksMovementByDefault,
  )
  onSave;
  final bool busy;

  @override
  State<ModelCollisionControls> createState() => _ModelCollisionControlsState();
}

class _ModelCollisionControlsState extends State<ModelCollisionControls> {
  late ModelCollisionDraft _draft;
  bool get saving => _draft.saving;
  bool get custom => _draft.custom;
  set custom(bool value) => _draft.custom = value;
  bool get blocksMovementByDefault => _draft.blocksMovementByDefault;
  set blocksMovementByDefault(bool value) =>
      _draft.blocksMovementByDefault = value;
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
  void didUpdateWidget(ModelCollisionControls old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id ||
        old.model.collisionBounds != widget.model.collisionBounds ||
        old.model.blocksMovementByDefault !=
            widget.model.blocksMovementByDefault) {
      _draft.dispose();
      reset();
    }
  }

  void reset() {
    _draft = ModelCollisionDraft(widget.model);
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
    title: 'Collision et placement',
    children: [
      StudioToggleRow(
        key: const ValueKey('model-blocks-movement-default'),
        label: 'Bloque le passage à la pose',
        description: 'Ce réglage s’applique aux nouveaux décors. Chaque décor posé conserve son propre choix.',
        value: blocksMovementByDefault,
        onChanged: saving || widget.busy
            ? null
            : (value) => setState(() => blocksMovementByDefault = value),
      ),
      const SizedBox(height: 12),
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
            label: saving ? 'Enregistrement…' : 'Enregistrer les réglages',
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
