import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ModelLightControls extends StatefulWidget {
  const ModelLightControls({
    super.key,
    required this.model,
    required this.onSave,
    this.busy = false,
  });
  final ProjectModel3dEntry model;
  final Future<void> Function(Model3dPointLight?) onSave;
  final bool busy;

  @override
  State<ModelLightControls> createState() => _ModelLightControlsState();
}

class _ModelLightControlsState extends State<ModelLightControls> {
  late bool enabled, nightOnly;
  late int color;
  late List<String> values;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(ModelLightControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.id != widget.model.id ||
        oldWidget.model.light != widget.model.light) {
      reset();
    }
  }

  void reset() {
    final light = widget.model.light;
    final bounds = widget.model.inspection.bounds;
    enabled = light != null;
    nightOnly = light?.nightOnly ?? true;
    color = light?.colorRgb ?? 0xffd59a;
    values = [
      light?.localPosition.x ?? (bounds.min.x + bounds.max.x) / 2,
      light?.localPosition.y ?? bounds.min.y + bounds.size.y * .9,
      light?.localPosition.z ?? (bounds.min.z + bounds.max.z) / 2,
      light?.radius ?? 4,
      light?.intensity ?? 1,
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
      Model3dPointLight? light;
      if (enabled) {
        final numbers = values
            .map((v) => double.tryParse(v.replaceAll(',', '.')))
            .toList();
        if (numbers.any((v) => v == null || !v.isFinite)) {
          throw const FormatException('Saisissez des nombres valides.');
        }
        final n = numbers.cast<double>();
        if (n[3] < .25 || n[3] > 64 || n[4] < 0 || n[4] > 4) {
          throw const FormatException(
            'La portée doit être comprise entre 0,25 et 64 cases, l’intensité entre 0 et 4.',
          );
        }
        light = Model3dPointLight(
          localPosition: Model3dVector3(x: n[0], y: n[1], z: n[2]),
          radius: n[3],
          intensity: n[4],
          colorRgb: color,
          nightOnly: nightOnly,
        );
      }
      await widget.onSave(light);
    } on Object catch (failure) {
      if (mounted) {
        setState(() => error = 'Éclairage non enregistré : $failure');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Éclairage',
    children: [
      StudioToggleRow(
        key: const ValueKey('model-light-enabled'),
        label: 'Émettre de la lumière',
        value: enabled,
        onChanged: saving || widget.busy
            ? null
            : (value) => setState(() => enabled = value),
      ),
      if (enabled) ...[
        const SizedBox(height: 8),
        const Text(
          'Placez la source dans le modèle. Sa position suit l’origine, l’échelle et la rotation du décor.',
        ),
        for (final (i, label) in [
          'Position X',
          'Hauteur de la source',
          'Position Z',
          'Portée en cases',
          'Intensité',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StudioDraftField(
              key: ValueKey(
                'model-light-${['x', 'y', 'z', 'radius', 'intensity'][i]}',
              ),
              label: label,
              value: values[i],
              enabled: !saving && !widget.busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (value) => setState(() => values[i] = value),
            ),
          ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Teinte de la lumière',
          value: '$color',
          options: {
            '${0xffd59a}': 'Chaud · lampadaire',
            '${0xffffff}': 'Blanc neutre',
            '${0xb8d9ff}': 'Bleu pâle',
            if (![0xffd59a, 0xffffff, 0xb8d9ff].contains(color))
              '$color': 'Couleur actuelle',
          },
          onChanged: saving || widget.busy
              ? null
              : (value) => setState(() => color = int.parse(value)),
        ),
        const SizedBox(height: 8),
        StudioToggleRow(
          key: const ValueKey('model-light-night-only'),
          label: 'Allumer seulement la nuit',
          description: 'L’allumage est progressif au crépuscule. Sans cycle, une lumière nocturne reste éteinte.',
          value: nightOnly,
          onChanged: saving || widget.busy
              ? null
              : (value) => setState(() => nightOnly = value),
        ),
        const SizedBox(height: 8),
        const Text(
          'La portée reste exprimée en cases de la carte, quelle que soit l’échelle du décor.',
        ),
      ],
      if (error != null) StudioNotice(error!, isError: true),
      const SizedBox(height: 12),
      StudioButton(
        key: const ValueKey('model-light-save'),
        label: saving ? 'Enregistrement…' : 'Enregistrer l’éclairage',
        onPressed: saving || widget.busy ? null : save,
      ),
    ],
  );
}
