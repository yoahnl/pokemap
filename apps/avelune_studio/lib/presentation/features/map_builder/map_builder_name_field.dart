import 'dart:async';

import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/shared/widgets/editor_text_transactions.dart';

class MapBuilderNameField extends StatefulWidget {
  const MapBuilderNameField({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    this.onCommit,
    this.onSubmit,
    this.lines = 1,
    this.literal = false,
  }) : assert((onCommit == null) != (onSubmit == null));

  final String value;
  final String label;
  final ValueChanged<String>? onCommit;
  final Future<bool> Function(String name)? onSubmit;
  final bool enabled;
  final int lines;
  final bool literal;

  static Future<void> commitFocused() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context
            ?.findAncestorStateOfType<_MapBuilderNameFieldState>()
            ?._commit() ??
        Future<void>.value();
  }

  @override
  State<MapBuilderNameField> createState() => _MapBuilderNameFieldState();
}

class _MapBuilderNameFieldState extends State<MapBuilderNameField> {
  late final _text = TextEditingController(text: widget.value);
  late final _focus = FocusNode()..addListener(_leave);
  Future<void>? _pending;
  String? _pendingName;

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
    if (!_focus.hasFocus) unawaited(_commit());
  }

  Future<void> _commit() {
    final name = widget.literal ? _text.text : _text.text.trim();
    if (name == _pendingName) return _pending ?? Future<void>.value();
    if (name.isEmpty && !widget.literal) {
      _text.text = widget.value;
      return Future<void>.value();
    }
    if (name == widget.value) return Future<void>.value();
    final submit = widget.onSubmit;
    _pendingName = name;
    final task =
        Future<bool>.sync(() {
              if (submit != null) return submit(name);
              widget.onCommit!(name);
              return true;
            })
            .then((saved) {
              if (!saved &&
                  mounted &&
                  (widget.literal ? _text.text : _text.text.trim()) == name) {
                _text.text = widget.value;
              }
            })
            .whenComplete(() {
              if (_pendingName == name) {
                _pending = null;
                _pendingName = null;
              }
            });
    return _pending =
        EditorTextTransactionsScope.maybeOf(context)?.track(task) ?? task;
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    focusNode: _focus,
    enabled: widget.enabled,
    minLines: widget.lines,
    maxLines: widget.lines,
    onEditingComplete: () =>
        _focus.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild),
    onSubmitted: (_) => unawaited(_commit()),
    onTapOutside: (_) {
      unawaited(_commit());
      _focus.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    },
    decoration: InputDecoration(isDense: true, labelText: widget.label),
  );
}
