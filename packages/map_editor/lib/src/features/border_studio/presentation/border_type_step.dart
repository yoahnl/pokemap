import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

class BorderTypeStep extends StatelessWidget {
  const BorderTypeStep({
    super.key,
    required this.state,
    required this.onTemplateSelected,
  });

  final BorderStudioDraftState state;
  final ValueChanged<BorderBlueprintTemplate> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    final selected = state.workingDraft?.blueprint.definition.template;
    return BorderStudioStepScaffold(
      title: '1. Type',
      description:
          'Choisissez la famille de raccords. World Maps dessinera ensuite la bordure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final template in BorderBlueprintTemplate.values) ...[
            PokeMapCard(
              selected: selected == template,
              child: Row(
                children: [
                  PokeMapIconTile(
                    icon: switch (template) {
                      BorderBlueprintTemplate.organicEdge =>
                        CupertinoIcons.waveform_path,
                      BorderBlueprintTemplate.masonryLine =>
                        CupertinoIcons.square_stack_3d_down_right,
                      BorderBlueprintTemplate.postAndRailLine =>
                        CupertinoIcons.equal_square,
                    },
                    tone: template == BorderBlueprintTemplate.organicEdge
                        ? PokeMapTone.info
                        : PokeMapTone.neutral,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(borderTemplateLabel(template)),
                        const SizedBox(height: 4),
                        Text(borderTemplateDescription(template)),
                        const SizedBox(height: 8),
                        PokeMapBadge(
                          label: template == BorderBlueprintTemplate.organicEdge
                              ? 'Publication disponible'
                              : 'Publication après BORD-06',
                          variant:
                              template == BorderBlueprintTemplate.organicEdge
                                  ? PokeMapBadgeVariant.success
                                  : PokeMapBadgeVariant.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PokeMapButton(
                    key: ValueKey<String>(
                      switch (template) {
                        BorderBlueprintTemplate.organicEdge =>
                          'border-studio-template-organic',
                        BorderBlueprintTemplate.masonryLine =>
                          'border-studio-template-masonry',
                        BorderBlueprintTemplate.postAndRailLine =>
                          'border-studio-template-fence',
                      },
                    ),
                    onPressed: state.workingDraft == null
                        ? null
                        : () => onTemplateSelected(template),
                    variant: PokeMapButtonVariant.secondary,
                    isSelected: selected == template,
                    size: PokeMapButtonSize.small,
                    child:
                        Text(selected == template ? 'Sélectionné' : 'Choisir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
