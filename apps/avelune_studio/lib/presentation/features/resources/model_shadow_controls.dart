import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class ModelShadowControls extends StatefulWidget {
  const ModelShadowControls({
    super.key,
    required this.model,
    required this.onChanged,
    this.busy = false,
  });

  final ProjectModel3dEntry model;
  final FutureOr<void> Function(bool) onChanged;
  final bool busy;

  @override
  State<ModelShadowControls> createState() => _ModelShadowControlsState();
}

class _ModelShadowControlsState extends State<ModelShadowControls> {
  late bool value = widget.model.castsShadowsByDefault;
  bool saving = false;
  String? error;

  @override
  void didUpdateWidget(ModelShadowControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.id != widget.model.id ||
        oldWidget.model.castsShadowsByDefault !=
            widget.model.castsShadowsByDefault) {
      value = widget.model.castsShadowsByDefault;
      error = null;
    }
  }

  Future<void> save(bool next) async {
    if (saving || widget.busy) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onChanged(next);
      if (mounted) setState(() => value = next);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StudioToggleRow(
        key: const ValueKey('model-casts-shadows-default'),
        label: 'Activer les ombres',
        description: 'Les décors qui suivent cette ressource projettent une ombre calculée. Chaque décor peut avoir son propre réglage.',
        value: value,
        onChanged: saving || widget.busy ? null : save,
      ),
      if (error != null) StudioNotice(error!, isError: true),
    ],
  );
}

class ModelInstanceShadowControls extends StatelessWidget {
  const ModelInstanceShadowControls({
    super.key,
    required this.instance,
    required this.model,
    required this.onChanged,
  });

  final SpatialModelInstance instance;
  final ProjectModel3dEntry? model;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StudioToggleRow(
        key: const ValueKey('instance-casts-shadows'),
        label: 'Activer les ombres',
        description: instance.castsShadows == null
            ? 'Suit la ressource · ${(model?.castsShadowsByDefault ?? false) ? 'activées' : 'désactivées'}'
            : 'Réglage propre à ce décor.',
        value: instance.castsShadows ?? model?.castsShadowsByDefault ?? false,
        onChanged: model == null ? null : onChanged,
      ),
      if (instance.castsShadows != null) ...[
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('instance-casts-shadows-inherit'),
          label: 'Suivre le réglage de la ressource',
          secondary: true,
          onPressed: () => onChanged(null),
        ),
      ],
    ],
  );
}
