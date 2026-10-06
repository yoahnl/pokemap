import 'package:flutter/material.dart';

class StudioSlider extends StatelessWidget {
  const StudioSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '$label · ${(value * 100).round()} %',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      Slider(
        value: value,
        onChanged: onChanged,
        semanticFormatterCallback: (value) => '${(value * 100).round()} %',
      ),
    ],
  );
}
