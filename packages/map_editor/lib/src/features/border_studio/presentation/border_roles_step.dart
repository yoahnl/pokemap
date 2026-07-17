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
                ],
                const SizedBox(height: 4),
                PokeMapSectionHeader(
                  title: 'Couverture des rôles',
                  description: _roleRequirementDescription(
                    definition.template,
                  ),
                ),
                const SizedBox(height: 8),
                if (definition.template ==
                    BorderBlueprintTemplate.connectedLine)
                  for (final role in roles) ...[
                    _ConnectedLineRoleStatus(
                      role: role,
                      variantCount: definition.primitives
                          .where(
                            (primitive) =>
                                primitive.role == role && primitive.weight > 0,
                          )
                          .length,
                    ),
                    const SizedBox(height: 8),
                  ]
                else
                  for (final role in roles) ...[
                    PokeMapStatusTile(
                      label: _roleRequirementLabel(
                        definition.template,
                        role,
                      ),
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
        BorderPrimitiveRole.lineCap => CupertinoIcons.stop_circle,
        BorderPrimitiveRole.lineStraight => CupertinoIcons.resize_h,
        BorderPrimitiveRole.lineCorner => CupertinoIcons.arrow_turn_up_right,
        _ => CupertinoIcons.square_stack_3d_down_right,
      };

  String _roleRequirementDescription(BorderBlueprintTemplate template) =>
      switch (template) {
        BorderBlueprintTemplate.organicEdge ||
        BorderBlueprintTemplate.masonryLine =>
          'Au moins une Structure principale, Structure secondaire ou Remplissage est requise. Les autres rôles sont optionnels.',
        BorderBlueprintTemplate.postAndRailLine =>
          'Poteau et Traverse sont requis. Les autres rôles sont optionnels.',
        BorderBlueprintTemplate.connectedLine =>
          'Extrémité, Segment droit et Angle sont requis. Ajoutez plusieurs assets à un même rôle pour créer des variantes.',
      };

  String _roleRequirementLabel(
    BorderBlueprintTemplate template,
    BorderPrimitiveRole role,
  ) {
    if (!isRequiredBorderRole(template, role)) return 'Rôle optionnel';
    return switch (template) {
      BorderBlueprintTemplate.organicEdge ||
      BorderBlueprintTemplate.masonryLine =>
        'Alternative de structure requise',
      BorderBlueprintTemplate.postAndRailLine => 'Rôle requis',
      BorderBlueprintTemplate.connectedLine => 'Raccord requis',
    };
  }
}

class _ConnectedLineRoleStatus extends StatelessWidget {
  const _ConnectedLineRoleStatus({
    required this.role,
    required this.variantCount,
  });

  final BorderPrimitiveRole role;
  final int variantCount;

  @override
  Widget build(BuildContext context) {
    final isReady = variantCount > 0;
    return PokeMapCard(
      key: ValueKey<String>('border-studio-role-status-${role.name}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: borderRoleLabel(role),
            description: switch (role) {
              BorderPrimitiveRole.lineCap =>
                'Utilisée au début et à la fin d’un tracé ouvert.',
              BorderPrimitiveRole.lineStraight =>
                'Utilisée lorsque la ligne continue sans tourner.',
              BorderPrimitiveRole.lineCorner =>
                'Utilisée lorsqu’un tracé tourne à angle droit.',
              _ => '',
            },
            trailing: PokeMapBadge(
              label: isReady ? 'Prêt' : 'Manquant',
              variant: isReady
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapBadge(
              label: '$variantCount variante${variantCount > 1 ? 's' : ''}',
              variant: isReady
                  ? PokeMapBadgeVariant.info
                  : PokeMapBadgeVariant.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
