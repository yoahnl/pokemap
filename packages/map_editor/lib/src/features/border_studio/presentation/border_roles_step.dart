import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/border_studio_draft.dart';
import 'border_studio_presentation.dart';

class BorderRolesStep extends StatelessWidget {
  const BorderRolesStep({
    super.key,
    required this.state,
    required this.onRoleChanged,
  });

  final BorderStudioDraftState state;
  final void Function(String primitiveId, BorderPrimitiveRole role)
      onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final definition = state.workingDraft?.blueprint.definition;
    final roles = orderedBorderRoles(state.allowedPrimitiveRoles);
    return BorderStudioStepScaffold(
      title: '3. Rôles',
      description:
          'Confirmez ce que chaque asset doit accomplir. Aucune direction technique n’est demandée.',
      child: definition == null
          ? const PokeMapEmptyState(
              title: 'Créez un blueprint pour attribuer ses rôles',
              icon: Icon(CupertinoIcons.tag),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (definition.primitives.isNotEmpty) ...[
                  const PokeMapSectionHeader(
                    title: 'Rôle de chaque asset',
                    description:
                        'Les choix restent fonctionnels : aucune direction ou clé technique.',
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0;
                      index < definition.primitives.length;
                      index += 1) ...[
                    PokeMapCard(
                      child: PokeMapDropdownField<BorderPrimitiveRole>(
                        key: ValueKey<String>(
                          'border-studio-role-picker-${definition.primitives[index].id}',
                        ),
                        label: 'Asset ${index + 1}',
                        value: definition.primitives[index].role,
                        items: <PokeMapDropdownItem<BorderPrimitiveRole>>[
                          for (final role in roles)
                            PokeMapDropdownItem<BorderPrimitiveRole>(
                              value: role,
                              label: borderRoleLabel(role),
                            ),
                        ],
                        onChanged: (role) => onRoleChanged(
                          definition.primitives[index].id,
                          role,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  const PokeMapSectionHeader(
                    title: 'Couverture des rôles',
                    description:
                        'Le Studio signale ce qui est présent et ce qui reste à fournir.',
                  ),
                  const SizedBox(height: 8),
                ],
                for (final role in roles) ...[
                  PokeMapStatusTile(
                    label: isRequiredBorderRole(definition.template, role)
                        ? 'Rôle de raccord requis'
                        : 'Rôle optionnel',
                    value: borderRoleLabel(role),
                    icon: _roleIcon(role),
                    tone: definition.primitives.any(
                      (primitive) =>
                          primitive.role == role && primitive.weight > 0,
                    )
                        ? PokeMapTone.success
                        : PokeMapTone.neutral,
                  ),
                  const SizedBox(height: 8),
                ],
                if (unresolvedBorderRoleLabels(definition).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  BorderStudioNotice(
                    title: 'Rôles non résolus',
                    description:
                        unresolvedBorderRoleLabels(definition).join(', '),
                    tone: PokeMapTone.warning,
                    icon: CupertinoIcons.exclamationmark_triangle,
                  ),
                ],
                if (definition.template !=
                    BorderBlueprintTemplate.organicEdge) ...[
                  const SizedBox(height: 10),
                  const PokeMapBadge(
                    label: 'Publication après BORD-06',
                    variant: PokeMapBadgeVariant.warning,
                  ),
                ],
              ],
            ),
    );
  }

  IconData _roleIcon(BorderPrimitiveRole role) => switch (role) {
        BorderPrimitiveRole.post => CupertinoIcons.pin,
        BorderPrimitiveRole.span => CupertinoIcons.resize_h,
        BorderPrimitiveRole.accent ||
        BorderPrimitiveRole.outerAccent =>
          CupertinoIcons.sparkles,
        BorderPrimitiveRole.surfacePatch => CupertinoIcons.square_fill,
        _ => CupertinoIcons.square_stack_3d_down_right,
      };
}
