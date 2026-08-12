import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_capability_descriptor.dart';

class PersonalizationPreviewSourceSelector extends StatelessWidget {
  static const capabilityIds = <String>{'preview.contentSource'};

  const PersonalizationPreviewSourceSelector({
    super.key,
    required this.source,
    required this.onChanged,
  });

  final PersonalizationPreviewContentSource source;
  final ValueChanged<PersonalizationPreviewContentSource> onChanged;

  @override
  Widget build(BuildContext context) => PokeMapSegmentedTabs(
    minimumHeight: 48,
    tabs: <PokeMapSegmentedTab>[
      PokeMapSegmentedTab(
        key: const ValueKey<String>('personalization-preview-source-project'),
        label: 'Projet',
        semanticLabel: 'Données du projet, aperçu uniquement',
        icon: Icons.folder_open_outlined,
        selected: source == PersonalizationPreviewContentSource.project,
        onTap: () => onChanged(PersonalizationPreviewContentSource.project),
      ),
      PokeMapSegmentedTab(
        key: const ValueKey<String>(
          'personalization-preview-source-demonstration',
        ),
        label: 'Démonstration',
        semanticLabel: 'Données de démonstration, aperçu uniquement',
        icon: Icons.science_outlined,
        selected: source == PersonalizationPreviewContentSource.demonstration,
        onTap: () =>
            onChanged(PersonalizationPreviewContentSource.demonstration),
      ),
    ],
  );
}
