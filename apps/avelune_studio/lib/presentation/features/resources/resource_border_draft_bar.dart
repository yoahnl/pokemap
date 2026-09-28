import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';

class ResourceBorderDraftBar extends StatelessWidget {
  const ResourceBorderDraftBar({
    super.key,
    required this.records,
    required this.onResume,
  });

  final List<BorderBlueprintRecord> records;
  final ValueChanged<BorderBlueprintRecord> onResume;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final record in records)
          StudioButton(
            label: record.latestPublished == null
                ? 'Reprendre « ${record.draft.definition.name} »'
                : 'Modifier « ${record.draft.definition.name} »',
            icon: Icons.edit_outlined,
            secondary: true,
            onPressed: () => onResume(record),
          ),
      ],
    ),
  );
}
