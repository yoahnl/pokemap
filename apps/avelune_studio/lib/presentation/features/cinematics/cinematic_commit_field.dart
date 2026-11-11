import 'package:flutter/material.dart';

import '../../../features/cinematics/application/cinematic_input_state.dart';

class CinematicCommitField extends StatefulWidget {
  CinematicCommitField({
    required ValueKey<String> key,
    required this.inputs,
    required this.changed,
    required this.label,
    required this.value,
    required this.tryCommit,
    this.maxLines = 1,
    this.alwaysCommit = false,
  }) : inputId = key.value,
       super(key: key);

  final CinematicInputState inputs;
  final VoidCallback changed;
  final String inputId, label, value;
  final bool Function(String) tryCommit;
  final int maxLines;
  final bool alwaysCommit;

  @override
  State<CinematicCommitField> createState() => _CinematicCommitFieldState();
}

class _CinematicCommitFieldState extends State<CinematicCommitField> {
  late CinematicFieldInput _input = widget.inputs.field(
    widget.inputId,
    widget.value,
  );
  late final _text = TextEditingController(text: _input.text);
  late final _focus = FocusNode()..addListener(_onFocus);

  void _onFocus() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final result = widget.inputs.commitField(
      _input,
      tryCommit: widget.tryCommit,
      fallbackError: 'Corrigez la saisie de « ${widget.label} ».',
      alwaysCommit: widget.alwaysCommit,
    );
    if (result != CinematicFieldCommitResult.skipped) {
      widget.changed();
    }
  }

  @override
  void didUpdateWidget(CinematicCommitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _input = widget.inputs.field(widget.inputId, widget.value);
    if (_text.text != _input.text) _text.text = _input.text;
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
    onChanged: (value) {
      _input.edit(value);
      widget.changed();
    },
    onSubmitted: (_) => _commit(),
  );
}
