import 'package:flutter/material.dart';

class StudioCommitField extends StatefulWidget {
  const StudioCommitField({
    super.key,
    required this.label,
    required this.value,
    this.onCommit,
    this.tryCommit,
    this.maxLines = 1,
    this.alwaysCommit = false,
  }) : assert((onCommit == null) != (tryCommit == null));
  final String label, value;
  final ValueChanged<String>? onCommit;
  final bool Function(String)? tryCommit;
  final int maxLines;
  final bool alwaysCommit;
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
    if (widget.alwaysCommit || _text.text != widget.value) {
      if (widget.tryCommit case final commit?) {
        if (!commit(_text.text)) _text.text = widget.value;
      } else {
        widget.onCommit!(_text.text);
      }
    }
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
    maxLines: widget.maxLines,
    decoration: InputDecoration(labelText: widget.label),
    onSubmitted: (_) => _commit(),
  );
}
