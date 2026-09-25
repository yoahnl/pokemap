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
    this.optional = true,
  });

  final PokemonCommerceController commerce;
  final String fieldId;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int minimum;
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
    final number = int.tryParse(value);
    final valid = value.isEmpty
        ? widget.optional
        : number != null && number >= widget.minimum;
    setState(
      () => error = valid ? null : 'Valeur entière ≥ ${widget.minimum} requise',
    );
    widget.commerce.setFieldError(widget.fieldId, error);
    if (valid) widget.onChanged(value.isEmpty ? null : number);
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
