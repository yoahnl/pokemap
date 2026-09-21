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
    if (_focus.hasFocus) {
      _committedSinceEdit = false;
    } else {
      _commit();
    }
  }

  bool _committedSinceEdit = false;
  bool _rejected = false;

  void _commit() {
    if (_committedSinceEdit) return;
    _committedSinceEdit = true;
    if (widget.alwaysCommit || _text.text != widget.value || _rejected) {
      if (widget.tryCommit case final commit?) {
        _rejected = !commit(_text.text);
        if (_rejected) _text.text = widget.value;
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
      _rejected = false;
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
    onChanged: (_) => _committedSinceEdit = false,
    onSubmitted: (_) => _commit(),
  );
}
