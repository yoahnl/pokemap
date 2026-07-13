import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class PokeMapDropdownItem<T> {
  const PokeMapDropdownItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Token-driven dropdown field with a visible label, value and chevron.
class PokeMapDropdownField<T> extends StatelessWidget {
  const PokeMapDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<PokeMapDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selected = items.where((item) => item.value == value).firstOrNull;
    final canOpen = enabled && items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        MouseRegion(
          cursor: canOpen ? SystemMouseCursors.click : MouseCursor.defer,
          child: Semantics(
            button: true,
            enabled: canOpen,
            label: '$label: ${selected?.label ?? ''}',
            child: Opacity(
              opacity: canOpen ? 1 : 0.55,
              child: Container(
                height: 42,
                padding: const EdgeInsets.only(left: 12, right: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: selected?.value,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(8),
                    menuMaxHeight: 320,
                    dropdownColor: colors.surfaceBase,
                    focusColor: colors.surfaceSubtle,
                    icon: Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: canOpen
                          ? colors.brandPrimary
                          : colors.textMuted,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    onChanged: canOpen
                        ? (next) {
                            if (next != null) onChanged(next);
                          }
                        : null,
                    selectedItemBuilder: (context) => [
                      for (final item in items)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    items: [
                      for (final item in items)
                        DropdownMenuItem<T>(
                          value: item.value,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: item.value == value
                                    ? Icon(
                                        CupertinoIcons.checkmark,
                                        size: 14,
                                        color: colors.brandPrimary,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
