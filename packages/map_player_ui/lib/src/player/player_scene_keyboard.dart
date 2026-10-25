import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';

class PlayerSceneKeyboard extends StatefulWidget {
  const PlayerSceneKeyboard({
    super.key,
    required this.controller,
    required this.submit,
    required this.onChanged,
    this.maximum,
    this.numeric = false,
    this.signed = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final Widget submit;
  final VoidCallback onChanged;
  final int? maximum;
  final bool numeric;
  final bool signed;
  final bool enabled;

  @override
  State<PlayerSceneKeyboard> createState() => _PlayerSceneKeyboardState();
}

class _PlayerSceneKeyboardState extends State<PlayerSceneKeyboard> {
  var _page = 0;
  var _uppercase = false;
  String? _focused;
  final _initialFocus = FocusNode(debugLabel: 'Scene keyboard');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _initialFocus.dispose();
    super.dispose();
  }

  void _insert(String value) {
    if (!widget.enabled) return;
    final current = widget.controller.value;
    final selection = current.selection.isValid
        ? current.selection
        : TextSelection.collapsed(offset: current.text.length);
    final text = current.text.replaceRange(
      selection.start,
      selection.end,
      value,
    );
    if (widget.numeric &&
        !RegExp(widget.signed ? r'^-?[0-9]*$' : r'^[0-9]*$').hasMatch(text)) {
      return;
    }
    if (widget.maximum != null && text.characters.length > widget.maximum!) {
      return;
    }
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + value.length,
      ),
    );
    widget.onChanged();
  }

  void _erase() {
    if (!widget.enabled) return;
    final current = widget.controller.value;
    final selection = current.selection.isValid
        ? current.selection
        : TextSelection.collapsed(offset: current.text.length);
    final start = selection.start;
    if (selection.isCollapsed && start == 0) return;
    final before = current.text.substring(0, start);
    final eraseStart = selection.isCollapsed
        ? start - before.characters.last.length
        : start;
    widget.controller.value = TextEditingValue(
      text: current.text.replaceRange(eraseStart, selection.end, ''),
      selection: TextSelection.collapsed(offset: eraseStart),
    );
    widget.onChanged();
  }

  Widget _key(
    String id,
    String label,
    VoidCallback action, {
    bool autofocus = false,
    IconData? icon,
  }) {
    final theme = context.playerMenuTheme;
    final selected = _focused == id;
    return PlayerMenuSelectableRow(
      key: ValueKey('scene-keyboard-$id'),
      id: 'scene-keyboard-$id',
      label: label,
      tile: icon == null,
      iconOnly: icon != null,
      leading: icon == null ? null : Icon(icon, size: 22),
      labelStyle: theme.actionLabel.copyWith(fontSize: 14),
      contentPadding: const EdgeInsets.all(4),
      focusNode: autofocus ? _initialFocus : null,
      selected: selected,
      onFocusChanged: (focused) {
        if (mounted) {
          setState(
            () => _focused = focused
                ? id
                : _focused == id
                ? null
                : _focused,
          );
        }
      },
      onPressed: widget.enabled ? action : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final alphabet = french
        ? 'AZERTYUIOPQSDFGHJKLMWXCVBN'
        : 'QWERTYUIOPASDFGHJKLZXCVBNM';
    final characters = widget.numeric
        ? '1234567890${widget.signed ? '-' : ''}'
        : '$alphabet${french ? 'ÉÈÀÙÇ' : ''}0123456789-\' ';
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          math.min(14, ((constraints.maxWidth + 8) / 56).floor()),
        );
        final keyHeight = math.max(
          48.0,
          MediaQuery.textScalerOf(context).scale(20) + 20,
        );
        final rows = math.max(
          1,
          ((constraints.maxHeight - keyHeight) / (keyHeight + 8)).floor(),
        );
        final pageSize = columns * rows;
        final values = characters.characters.toList();
        final pages = (values.length / pageSize).ceil();
        final page = _page.clamp(0, pages - 1);
        final visible = values.skip(page * pageSize).take(pageSize).toList();
        final keyWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        final toolbar = <Widget>[
          if (pages > 1)
            _key(
              'page',
              '${page + 1}/$pages',
              () => setState(() => _page = (page + 1) % pages),
            ),
          if (!widget.numeric)
            _key(
              'case',
              _uppercase ? 'abc' : 'ABC',
              () => setState(() => _uppercase = !_uppercase),
              icon: Icons.keyboard_capslock,
            ),
          if (!widget.numeric)
            _key(
              'space',
              french ? 'Espace' : 'Space',
              () => _insert(' '),
              icon: Icons.space_bar,
            ),
          _key(
            'erase',
            french ? 'Effacer' : 'Delete',
            _erase,
            icon: Icons.backspace_outlined,
          ),
          widget.submit,
        ];
        return Column(
          key: const ValueKey('scene-controller-keyboard'),
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (
              var offset = 0;
              offset < visible.length;
              offset += columns
            ) ...[
              if (offset > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (
                    var index = offset;
                    index < math.min(offset + columns, visible.length);
                    index++
                  ) ...[
                    if (index > offset) const SizedBox(width: 8),
                    SizedBox(
                      width: keyWidth,
                      height: keyHeight,
                      child: _key(
                        'char-${visible[index]}',
                        _uppercase
                            ? visible[index]
                            : visible[index].toLowerCase(),
                        () {
                          final capital =
                              _uppercase || widget.controller.text.isEmpty;
                          _insert(
                            capital
                                ? visible[index]
                                : visible[index].toLowerCase(),
                          );
                        },
                        autofocus: index == 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: keyHeight,
              child: Row(
                children: [
                  for (var index = 0; index < toolbar.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    if (index == toolbar.length - 1)
                      Expanded(child: toolbar[index])
                    else
                      SizedBox(width: 48, child: toolbar[index]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
