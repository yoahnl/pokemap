import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_dialog.dart';
import 'pokemap_guided_slider.dart';

const pokeMapColorPickerDialogKey = ValueKey<String>(
  'pokemap-color-picker-dialog',
);
const pokeMapColorPickerApplyKey = ValueKey<String>(
  'pokemap-color-picker-apply',
);

class PokeMapColorPicker extends StatelessWidget {
  const PokeMapColorPicker({
    super.key,
    required this.label,
    required this.valueHex,
    required this.onChanged,
    required this.dialogTitle,
    required this.cancelLabel,
    required this.applyLabel,
    required this.hueLabel,
    required this.saturationLabel,
    required this.brightnessLabel,
    required this.opacityLabel,
    this.buttonKey,
  });

  final String label;
  final String valueHex;
  final ValueChanged<String> onChanged;
  final String dialogTitle;
  final String cancelLabel;
  final String applyLabel;
  final String hueLabel;
  final String saturationLabel;
  final String brightnessLabel;
  final String opacityLabel;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(label, style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 5),
      PokeMapButton(
        key: buttonKey,
        variant: PokeMapButtonVariant.secondary,
        onPressed: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (context) => _PokeMapColorPickerDialog(
              valueHex: valueHex,
              title: dialogTitle,
              cancelLabel: cancelLabel,
              applyLabel: applyLabel,
              hueLabel: hueLabel,
              saturationLabel: saturationLabel,
              brightnessLabel: brightnessLabel,
              opacityLabel: opacityLabel,
            ),
          );
          if (selected != null && selected != valueHex) onChanged(selected);
        },
        leading: _ColorSwatch(color: _colorFromHex(valueHex), size: 22),
        child: Text(valueHex.toUpperCase()),
      ),
    ],
  );
}

class _PokeMapColorPickerDialog extends StatefulWidget {
  const _PokeMapColorPickerDialog({
    required this.valueHex,
    required this.title,
    required this.cancelLabel,
    required this.applyLabel,
    required this.hueLabel,
    required this.saturationLabel,
    required this.brightnessLabel,
    required this.opacityLabel,
  });

  final String valueHex;
  final String title;
  final String cancelLabel;
  final String applyLabel;
  final String hueLabel;
  final String saturationLabel;
  final String brightnessLabel;
  final String opacityLabel;

  @override
  State<_PokeMapColorPickerDialog> createState() =>
      _PokeMapColorPickerDialogState();
}

class _PokeMapColorPickerDialogState extends State<_PokeMapColorPickerDialog> {
  static const _presets = <String>[
    '#FFFFFFFF',
    '#111827FF',
    '#EF4444FF',
    '#7AA2FFFF',
    '#22C55EFF',
    '#F59E0BFF',
    '#A855F7FF',
    '#EC4899FF',
  ];

  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(_colorFromHex(widget.valueHex));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selectedHex = _hexFromColor(_color.toColor());
    return PokeMapDialog(
      key: pokeMapColorPickerDialogKey,
      title: widget.title,
      maxWidth: 520,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          PokeMapButton(
            variant: PokeMapButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.cancelLabel),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: pokeMapColorPickerApplyKey,
            onPressed: () => Navigator.of(context).pop(selectedHex),
            child: Text(widget.applyLabel),
          ),
        ],
      ),
      child: SizedBox(
        height: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _color.toColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: SizedBox(
                  height: 72,
                  child: Center(
                    child: Text(
                      selectedHex,
                      style: TextStyle(
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  _color.toColor(),
                                ) ==
                                Brightness.light
                            ? colors.textInverse
                            : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (var index = 0; index < _presets.length; index++)
                    PokeMapButton(
                      key: ValueKey<String>('pokemap-color-preset-$index'),
                      semanticLabel: _presets[index],
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.ghost,
                      onPressed: () => setState(
                        () => _color = HSVColor.fromColor(
                          _colorFromHex(_presets[index]),
                        ),
                      ),
                      child: _ColorSwatch(
                        color: _colorFromHex(_presets[index]),
                        size: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              PokeMapGuidedSlider(
                label: widget.hueLabel,
                value: _color.hue.round(),
                min: 0,
                max: 360,
                onChanged: (value) =>
                    setState(() => _color = _color.withHue(value.toDouble())),
              ),
              const SizedBox(height: 8),
              PokeMapGuidedSlider(
                label: widget.saturationLabel,
                value: (_color.saturation * 100).round(),
                onChanged: (value) =>
                    setState(() => _color = _color.withSaturation(value / 100)),
              ),
              const SizedBox(height: 8),
              PokeMapGuidedSlider(
                label: widget.brightnessLabel,
                value: (_color.value * 100).round(),
                onChanged: (value) =>
                    setState(() => _color = _color.withValue(value / 100)),
              ),
              const SizedBox(height: 8),
              PokeMapGuidedSlider(
                label: widget.opacityLabel,
                value: (_color.alpha * 100).round(),
                onChanged: (value) =>
                    setState(() => _color = _color.withAlpha(value / 100)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: context.pokeMapColors.borderSubtle),
    ),
    child: SizedBox.square(dimension: size),
  );
}

Color _colorFromHex(String value) {
  final normalized = value.substring(1).toUpperCase();
  final rgba = normalized.length == 6 ? '${normalized}FF' : normalized;
  final red = int.parse(rgba.substring(0, 2), radix: 16);
  final green = int.parse(rgba.substring(2, 4), radix: 16);
  final blue = int.parse(rgba.substring(4, 6), radix: 16);
  final alpha = int.parse(rgba.substring(6, 8), radix: 16);
  return Color.fromARGB(alpha, red, green, blue);
}

String _hexFromColor(Color color) {
  final argb = color.toARGB32();
  final alpha = (argb >> 24) & 0xff;
  final red = (argb >> 16) & 0xff;
  final green = (argb >> 8) & 0xff;
  final blue = argb & 0xff;
  return '#${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}'
          '${alpha.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
