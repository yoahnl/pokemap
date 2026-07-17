import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_icon_button.dart';

/// Compact, token-driven search input for dense editor panels.
class PokeMapSearchField extends StatefulWidget {
  const PokeMapSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hintText = 'Rechercher…',
    this.semanticLabel,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String? semanticLabel;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  @override
  State<PokeMapSearchField> createState() => _PokeMapSearchFieldState();
}

class _PokeMapSearchFieldState extends State<PokeMapSearchField> {
  late final TextEditingController _ownedController;
  late final FocusNode _ownedFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    _ownedController = TextEditingController();
    _ownedFocusNode = FocusNode();
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PokeMapSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? _ownedController;
    if (oldController != _controller) {
      oldController.removeListener(_handleControllerChanged);
      _controller.addListener(_handleControllerChanged);
    }
    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    if (oldFocusNode != _focusNode) {
      oldFocusNode.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _ownedController.dispose();
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
    if (widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final hasText = _controller.text.isNotEmpty;
    final isFocused = _focusNode.hasFocus;

    return Semantics(
      container: true,
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.hintText,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 34,
        padding: const EdgeInsets.only(left: 10, right: 3),
        decoration: BoxDecoration(
          color: colors.controlSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused && widget.enabled
                ? colors.focusRing
                : colors.controlBorder,
            width: isFocused && widget.enabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.search_rounded,
                size: 16,
                color: widget.enabled ? colors.textMuted : colors.textDisabled,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: TextStyle(
                  color:
                      widget.enabled ? colors.textPrimary : colors.textDisabled,
                  fontSize: 12,
                  height: 1.2,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color:
                        widget.enabled ? colors.textMuted : colors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (hasText)
              PokeMapIconButton(
                onPressed: widget.enabled ? _clear : null,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Effacer la recherche',
                size: 27,
              ),
          ],
        ),
      ),
    );
  }
}
