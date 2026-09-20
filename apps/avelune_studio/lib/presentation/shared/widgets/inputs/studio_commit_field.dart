import 'package:flutter/material.dart';

class StudioCommitField extends StatefulWidget {
  const StudioCommitField({
    super.key,
    required this.label,
    required this.value,
    required this.onCommit,
  });
  final String label, value;
  final ValueChanged<String> onCommit;
  @override
  State<StudioCommitField> createState() => _StudioCommitFieldState();
}

class _StudioCommitFieldState extends State<StudioCommitField> {
  late final _text = TextEditingController(text: widget.value);
  late final _focus = FocusNode()..addListener(_onFocus);
  void _onFocus() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    if (_text.text != widget.value) widget.onCommit(_text.text);
  }

  @override
  void didUpdateWidget(StudioCommitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _text.text != widget.value) {
      _text.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    focusNode: _focus,
    decoration: InputDecoration(labelText: widget.label),
    onSubmitted: (_) => _commit(),
  );
}
