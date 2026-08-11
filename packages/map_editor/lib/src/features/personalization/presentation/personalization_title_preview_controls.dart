import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';

enum PersonalizationTitlePreviewStage { prompt, menu }

class PersonalizationTitlePreviewControls extends StatelessWidget {
  const PersonalizationTitlePreviewControls({
    super.key,
    required this.stage,
    required this.onChanged,
  });

  final PersonalizationTitlePreviewStage stage;
  final ValueChanged<PersonalizationTitlePreviewStage> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      const Text('Moment du titre'),
      PokeMapSegmentedTabs(
        minimumHeight: 48,
        tabs: <PokeMapSegmentedTab>[
          PokeMapSegmentedTab(
            key: const ValueKey<String>(
              'personalization-title-preview-stage-prompt',
            ),
            label: 'Invitation',
            icon: Icons.touch_app_outlined,
            selected: stage == PersonalizationTitlePreviewStage.prompt,
            onTap: () => onChanged(PersonalizationTitlePreviewStage.prompt),
          ),
          PokeMapSegmentedTab(
            key: const ValueKey<String>(
              'personalization-title-preview-stage-menu',
            ),
            label: 'Menu',
            icon: Icons.menu_rounded,
            selected: stage == PersonalizationTitlePreviewStage.menu,
            onTap: () => onChanged(PersonalizationTitlePreviewStage.menu),
          ),
        ],
      ),
    ],
  );
}
