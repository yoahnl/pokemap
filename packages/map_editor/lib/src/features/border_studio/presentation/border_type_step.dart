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
    final definition = state.workingDraft?.blueprint.definition;
    final selected = definition?.template;
    return BorderStudioStepScaffold(
      title: '1. Type',
      description:
          'Choisissez la famille de raccords. World Maps dessinera ensuite la bordure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final template in BorderBlueprintTemplate.values) ...[
            Builder(
              builder: (context) {
                final incompatibleRoles = definition == null
                    ? const <BorderPrimitiveRole>[]
                    : _incompatibleRoles(definition, template);
                final disabledReason = incompatibleRoles.isEmpty
                    ? null
                    : _incompatibleTemplateReason(incompatibleRoles);
                return PokeMapCard(
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
                          BorderBlueprintTemplate.connectedLine =>
                            CupertinoIcons.arrow_3_trianglepath,
                          BorderBlueprintTemplate.stoneChainLine =>
                            CupertinoIcons.circle_grid_hex,
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
                            const PokeMapBadge(
                              label: 'Publication disponible',
                              variant: PokeMapBadgeVariant.success,
                            ),
                            if (disabledReason != null) ...[
                              const SizedBox(height: 8),
                              Text(disabledReason),
                            ],
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
                            BorderBlueprintTemplate.connectedLine =>
                              'border-studio-template-connected-line',
                            BorderBlueprintTemplate.stoneChainLine =>
                              'border-studio-template-stone-chain',
                          },
                        ),
                        onPressed: definition == null || disabledReason != null
                            ? null
                            : () => onTemplateSelected(template),
                        variant: PokeMapButtonVariant.secondary,
                        isSelected: selected == template,
                        size: PokeMapButtonSize.small,
                        child: Text(
                          disabledReason != null
                              ? 'Indisponible'
                              : selected == template
                                  ? 'Sélectionné'
                                  : 'Choisir',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

List<BorderPrimitiveRole> _incompatibleRoles(
  BorderBlueprintDraftDefinition definition,
  BorderBlueprintTemplate template,
) {
  final allowedRoles = borderAllowedPrimitiveRolesForTemplate(template);
  final incompatible = <BorderPrimitiveRole>{
    for (final primitive in definition.primitives)
      if (!allowedRoles.contains(primitive.role)) primitive.role,
  };
  return orderedBorderRoles(incompatible);
}

String _incompatibleTemplateReason(List<BorderPrimitiveRole> roles) {
  final labels = roles.map(borderRoleLabel).toList(growable: false);
  if (labels.length == 1) {
    return 'Indisponible : le rôle « ${labels.single} » n’est pas pris en '
        'charge. Réattribuez ou retirez l’asset concerné avant de choisir ce '
        'type.';
  }
  return 'Indisponible : les rôles ${labels.map((label) => '« $label »').join(', ')} '
      'ne sont pas pris en charge. Réattribuez ou retirez les assets concernés '
      'avant de choisir ce type.';
}
