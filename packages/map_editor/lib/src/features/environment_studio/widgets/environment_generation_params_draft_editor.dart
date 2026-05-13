import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';

/// Éditeur local des [EnvironmentGenerationParamsDraft] (Lot Environment-15).
///
/// Doubles : parse avec [double.tryParse] ; si vide ou non parseable, pas d’appel
/// à [onChanged] (le brouillon conserve la valeur précédente). Les valeurs hors
/// [0, 1] sont tout de même émises pour que [validateEnvironmentPresetDraft]
/// remonte [invalidDensity] / [invalidVariation] / [invalidEdgeDensity].
///
/// Entier : [int.tryParse] pour [minSpacingCells] ; valeurs négatives émises pour
/// [invalidMinSpacingCells].
///
/// [didUpdateWidget] resynchronise les contrôleurs quand [params] change (ex. :
/// « Réinitialiser brouillon » sur le parent).
class EnvironmentGenerationParamsDraftEditor extends StatefulWidget {
  const EnvironmentGenerationParamsDraftEditor({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final EnvironmentGenerationParamsDraft params;
  final ValueChanged<EnvironmentGenerationParamsDraft> onChanged;

  @override
  State<EnvironmentGenerationParamsDraftEditor> createState() =>
      _EnvironmentGenerationParamsDraftEditorState();
}

class _EnvironmentGenerationParamsDraftEditorState
    extends State<EnvironmentGenerationParamsDraftEditor> {
  late final TextEditingController _densityCtrl;
  late final TextEditingController _variationCtrl;
  late final TextEditingController _edgeDensityCtrl;
  late final TextEditingController _minSpacingCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.params;
    _densityCtrl = TextEditingController(text: _formatDouble(p.density));
    _variationCtrl = TextEditingController(text: _formatDouble(p.variation));
    _edgeDensityCtrl =
        TextEditingController(text: _formatDouble(p.edgeDensity));
    _minSpacingCtrl = TextEditingController(text: p.minSpacingCells.toString());
  }

  @override
  void didUpdateWidget(
      covariant EnvironmentGenerationParamsDraftEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      final p = widget.params;
      _densityCtrl.text = _formatDouble(p.density);
      _variationCtrl.text = _formatDouble(p.variation);
      _edgeDensityCtrl.text = _formatDouble(p.edgeDensity);
      _minSpacingCtrl.text = p.minSpacingCells.toString();
    }
  }

  @override
  void dispose() {
    _densityCtrl.dispose();
    _variationCtrl.dispose();
    _edgeDensityCtrl.dispose();
    _minSpacingCtrl.dispose();
    super.dispose();
  }

  static String _formatDouble(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toString();
  }

  void _emitDensity(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(density: v));
  }

  void _emitVariation(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(variation: v));
  }

  void _emitEdgeDensity(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = double.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(edgeDensity: v));
  }

  void _emitMinSpacing(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return;
    }
    final v = int.tryParse(t);
    if (v == null) {
      return;
    }
    widget.onChanged(widget.params.copyWith(minSpacingCells: v));
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paramètres par défaut',
              key: const Key('environment-studio-draft-params-section-title'),
              style: TextStyle(
                color: label,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces valeurs restent dans le brouillon local tant que la création '
              'réelle n’est pas branchée.',
              key: const Key('environment-studio-draft-params-local-note'),
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 14),
            _subLabel(context, 'Densité'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-density'),
              controller: _densityCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitDensity,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Variation'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-variation'),
              controller: _variationCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitVariation,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Densité des bords'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-edge-density'),
              controller: _edgeDensityCtrl,
              placeholder: '0.0 – 1.0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitEdgeDensity,
            ),
            const SizedBox(height: 12),
            _subLabel(context, 'Espacement minimal'),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: const Key('environment-studio-draft-params-min-spacing'),
              controller: _minSpacingCtrl,
              placeholder: '≥ 0',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: _emitMinSpacing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
