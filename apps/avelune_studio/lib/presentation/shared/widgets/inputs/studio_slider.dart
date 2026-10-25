import 'package:flutter/material.dart';

class StudioSlider extends StatelessWidget {
  const StudioSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.valueLabel,
    this.onChangeStart,
    this.onChangeEnd,
  });
  final String label;
  final double value;
  final double min, max;
  final int? divisions;
  final String? valueLabel;
  final ValueChanged<double>? onChangeStart, onChangeEnd;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '$label · ${valueLabel ?? '${(value * 100).round()} %'}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        onChanged: onChanged,
        semanticFormatterCallback: (value) =>
            valueLabel ?? '${(value * 100).round()} %',
      ),
    ],
  );
}
