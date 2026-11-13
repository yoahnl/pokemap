import 'package:flutter/material.dart';

class MapBuilderNameField extends StatefulWidget {
  const MapBuilderNameField({
    super.key,
    required this.value,
    required this.label,
    required this.onCommit,
    required this.enabled,
    this.lines = 1,
  });

  final String value;
  final String label;
  final ValueChanged<String> onCommit;
  final bool enabled;
  final int lines;

  @override
  State<MapBuilderNameField> createState() => _MapBuilderNameFieldState();
}

class _MapBuilderNameFieldState extends State<MapBuilderNameField> {
  late final _text = TextEditingController(text: widget.value);
  late final _focus = FocusNode()..addListener(_leave);

  @override
  void didUpdateWidget(MapBuilderNameField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_focus.hasFocus) {
      _text.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _leave() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final name = _text.text.trim();
    if (name.isEmpty) {
      _text.text = widget.value;
      return;
    }
    if (name != widget.value) widget.onCommit(name);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    focusNode: _focus,
    enabled: widget.enabled,
    minLines: widget.lines,
    maxLines: widget.lines,
    onSubmitted: (_) => _commit(),
    decoration: InputDecoration(isDense: true, labelText: widget.label),
  );
}
