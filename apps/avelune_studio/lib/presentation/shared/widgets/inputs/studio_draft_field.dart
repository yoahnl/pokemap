import 'package:flutter/material.dart';

class StudioDraftField extends StatefulWidget {
  const StudioDraftField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.lines = 1,
    this.enabled = true,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final int lines;
  final bool enabled;
  @override
  State<StudioDraftField> createState() => _StudioDraftFieldState();
}

class _StudioDraftFieldState extends State<StudioDraftField> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(StudioDraftField old) {
    super.didUpdateWidget(old);
    if (controller.text == widget.value) return;
    final offset = controller.selection.extentOffset.clamp(
      0,
      widget.value.length,
    );
    controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    minLines: widget.lines,
    maxLines: widget.lines == 1 ? 1 : null,
    decoration: InputDecoration(labelText: widget.label),
  );
}
