import 'package:flutter/material.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';

class ResourceCategoryFilter extends StatelessWidget {
  const ResourceCategoryFilter({
    super.key,
    required this.categories,
    required this.items,
    required this.kind,
    required this.selected,
    required this.onChanged,
  });
  final Map<String, String> categories;
  final List<ResourceItem> items;
  final ResourceKind kind;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{'': 0};
    for (final item in items.where((item) => item.kind == kind)) {
      final category = item.category.isEmpty
          ? uncategorizedResourceCategory
          : item.category;
      counts[''] = counts['']! + 1;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return SingleChildScrollView(
      child: StudioPanel(
        title: 'Catégories',
        compact: true,
        children: [
          for (final category in {'': 'Toutes', ...categories}.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: StudioChoice(
                key: ValueKey('resource-category-${category.key}'),
                label: category.value,
                subtitle: '${counts[category.key] ?? 0}',
                selected: selected == category.key,
                onTap: () => onChanged(category.key),
              ),
            ),
        ],
      ),
    );
  }
}
