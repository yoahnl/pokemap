import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_choice.dart';

class ResourceTerrainDraftList extends StatelessWidget {
  const ResourceTerrainDraftList({
    super.key,
    required this.drafts,
    required this.onResume,
  });
  final List<ProjectSmartTileAuthoringDraft> drafts;
  final ValueChanged<ProjectSmartTileAuthoringDraft> onResume;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Préparations en cours (${drafts.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(14) > 20 ? 104 : 74,
          child: ListView.builder(
            key: const ValueKey('terrain-drafts'),
            scrollDirection: Axis.horizontal,
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final assigned = draft.rules
                  .where((rule) => rule.candidates.isNotEmpty)
                  .length;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 260,
                  child: StudioChoice(
                    label: 'Reprendre le brouillon : ${draft.name}',
                    subtitle: '$assigned / 16 raccords associés',
                    leading: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => onResume(draft),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
