import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';

class PokemonCommerceIntegerField extends StatefulWidget {
  const PokemonCommerceIntegerField({
    super.key,
    required this.commerce,
    required this.fieldId,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum,
    this.optional = true,
  });

  final PokemonCommerceController commerce;
  final String fieldId;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int minimum;
  final int? maximum;
  final bool optional;

  @override
  State<PokemonCommerceIntegerField> createState() =>
      _PokemonCommerceIntegerFieldState();
}

class _PokemonCommerceIntegerFieldState
    extends State<PokemonCommerceIntegerField> {
  late final controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );
  String? error;

  @override
  void didUpdateWidget(PokemonCommerceIntegerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.fieldId != widget.fieldId) {
      final next = widget.value?.toString() ?? '';
      if (controller.text != next) controller.text = next;
      error = null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _change(String value) {
    final problem = widget.commerce.setIntegerInput(
      fieldId: widget.fieldId,
      value: value,
      minimum: widget.minimum,
      maximum: widget.maximum,
      optional: widget.optional,
      onChanged: widget.onChanged,
    );
    setState(() => error = problem);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: _change,
    decoration: InputDecoration(labelText: widget.label, errorText: error),
  );
}
