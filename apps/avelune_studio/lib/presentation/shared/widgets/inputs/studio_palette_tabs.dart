import 'package:flutter/material.dart';

class StudioPaletteTabs extends StatelessWidget {
  const StudioPaletteTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.items,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = Theme.of(context).colorScheme;
      final dense = items.length > 4;
      return Wrap(
        spacing: 6,
        runSpacing: dense ? 4 : 6,
        children: [
          for (final name in items)
            SizedBox(
              width: (constraints.maxWidth - 6) / 2,
              child: Tooltip(
                message: name,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: dense ? 4 : 8,
                    ),
                    minimumSize: dense ? const Size(0, 32) : null,
                    tapTargetSize: dense
                        ? MaterialTapTargetSize.shrinkWrap
                        : null,
                    foregroundColor: selected == name
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                    backgroundColor: selected == name
                        ? colors.primaryContainer
                        : colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: BorderSide(
                        color: selected == name
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                    ),
                  ),
                  onPressed: () => onChanged(name),
                  child: Semantics(
                    selected: selected == name,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
