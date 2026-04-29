import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_drag_payload.dart';
import '../surface_studio_motion.dart';
import '../surface_studio_role_assignment_draft.dart';
import 'surface_studio_role_thumbnail_painter.dart';

typedef SurfaceStudioRoleDropCallback = void Function(
  SurfaceVariantRole role,
  SurfaceStudioColumnDragPayload payload,
);

class SurfaceStudioSchemaPanel extends StatelessWidget {
  const SurfaceStudioSchemaPanel({
    super.key,
    required this.collapsed,
    required this.openGroups,
    required this.assignmentDraft,
    required this.onToggleCollapsed,
    required this.onToggleGroup,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final bool collapsed;
  final Set<String> openGroups;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onToggleGroup;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('surfaceStudio.schema.panel'),
      duration: SurfaceStudioMotion.panelSlide,
      curve: SurfaceStudioMotion.easeInOut,
      width: collapsed
          ? SurfaceStudioDesignTokens.rightPanelWidthCollapsed
          : SurfaceStudioDesignTokens.rightPanelWidthExpanded,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: collapsed
          ? _CollapsedSchema(onToggle: onToggleCollapsed)
          : _ExpandedSchema(
              openGroups: openGroups,
              assignmentDraft: assignmentDraft,
              onToggleCollapsed: onToggleCollapsed,
              onToggleGroup: onToggleGroup,
              onDrop: onDrop,
              onClearRole: onClearRole,
              onClearColumn: onClearColumn,
            ),
    );
  }
}

class _CollapsedSchema extends StatelessWidget {
  const _CollapsedSchema({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('surfaceStudio.schema.collapsed'),
      children: [
        Tooltip(
          message: 'Déployer le schéma de surface',
          child: CupertinoButton(
            key: const ValueKey('surfaceStudio.schema.collapseButton'),
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(38),
            onPressed: onToggle,
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: SurfaceStudioDesignTokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Icon(
          CupertinoIcons.square_grid_2x2,
          color: SurfaceStudioDesignTokens.accentGold,
        ),
      ],
    );
  }
}

class _ExpandedSchema extends StatelessWidget {
  const _ExpandedSchema({
    required this.openGroups,
    required this.assignmentDraft,
    required this.onToggleCollapsed,
    required this.onToggleGroup,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final Set<String> openGroups;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onToggleGroup;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('surfaceStudio.schema.expanded'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Schéma de surface (glissez-déposez)',
                style: TextStyle(
                  color: SurfaceStudioDesignTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Tooltip(
              message: 'Aide schéma',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed: () {},
                child: const Icon(
                  CupertinoIcons.question_circle,
                  color: SurfaceStudioDesignTokens.textSecondary,
                  size: 18,
                ),
              ),
            ),
            Tooltip(
              message: 'Réduire le schéma',
              child: CupertinoButton(
                key: const ValueKey('surfaceStudio.schema.collapseButton'),
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed: onToggleCollapsed,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: SurfaceStudioDesignTokens.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final group in _schemaGroups)
                  _SchemaAccordion(
                    group: group,
                    open: openGroups.contains(group.id),
                    assignedCount:
                        assignmentDraft.assignedCountForRoles(group.roles),
                    assignmentDraft: assignmentDraft,
                    onToggle: () => onToggleGroup(group.id),
                    onDrop: onDrop,
                    onClearRole: onClearRole,
                    onClearColumn: onClearColumn,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SchemaAccordion extends StatelessWidget {
  const _SchemaAccordion({
    required this.group,
    required this.open,
    required this.assignedCount,
    required this.assignmentDraft,
    required this.onToggle,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final _RoleGroup group;
  final bool open;
  final int assignedCount;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggle;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('surfaceStudio.schema.group.${group.id}'),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assignedCount > 0
              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.42)
              : SurfaceStudioDesignTokens.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            key: ValueKey('surfaceStudio.schema.group.${group.id}.header'),
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    open
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    color: SurfaceStudioDesignTokens.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.label,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$assignedCount/${group.roles.length}',
                    style: TextStyle(
                      color: assignedCount > 0
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: SurfaceStudioMotion.accordion,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final role in group.roles)
                          SurfaceStudioRoleSlotCard(
                            role: role,
                            columns: assignmentDraft.columnsForRole(role),
                            onDrop: onDrop,
                            onClearRole: onClearRole,
                            onClearColumn: onClearColumn,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioRoleSlotCard extends StatelessWidget {
  const SurfaceStudioRoleSlotCard({
    super.key,
    required this.role,
    required this.columns,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final SurfaceVariantRole role;
  final List<int> columns;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  bool get _isCenter => role == SurfaceVariantRole.isolated;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SurfaceStudioColumnDragPayload>(
      onWillAcceptWithDetails: (details) =>
          validateSurfaceStudioRoleDrop(
            role: role,
            payload: details.data,
            draft: const SurfaceStudioRoleAssignmentDraft.empty(),
          ) ==
          SurfaceStudioDropValidation.valid,
      onAcceptWithDetails: (details) => onDrop(role, details.data),
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.isNotEmpty ? candidateData.first : null;
        final validation = candidate == null
            ? SurfaceStudioDropValidation.valid
            : validateSurfaceStudioRoleDrop(
                role: role,
                payload: candidate,
                draft: const SurfaceStudioRoleAssignmentDraft.empty(),
              );
        final validHover = candidate != null &&
            validation == SurfaceStudioDropValidation.valid;
        final invalidHover = candidate != null &&
            validation != SurfaceStudioDropValidation.valid;
        return AnimatedContainer(
          key: role == SurfaceVariantRole.isolated
              ? const ValueKey('surfaceStudio.schema.role.center')
              : ValueKey('surfaceStudio.schema.role.${role.name}'),
          duration: SurfaceStudioMotion.fast,
          width: _isCenter ? 132 : 106,
          constraints: BoxConstraints(minHeight: _isCenter ? 94 : 86),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: validHover
                ? SurfaceStudioDesignTokens.accentTealSoft
                : invalidHover
                    ? SurfaceStudioDesignTokens.dangerSoft
                        .withValues(alpha: 0.16)
                    : columns.isNotEmpty
                        ? SurfaceStudioDesignTokens.backgroundElevated
                        : SurfaceStudioDesignTokens.backgroundPanel,
            borderRadius:
                BorderRadius.circular(SurfaceStudioDesignTokens.slotRadius),
            border: Border.all(
              color: validHover
                  ? SurfaceStudioDesignTokens.accentTeal
                  : invalidHover
                      ? SurfaceStudioDesignTokens.dangerSoft
                      : columns.isNotEmpty
                          ? SurfaceStudioDesignTokens.borderStrong
                          : SurfaceStudioDesignTokens.borderSubtle,
              width: validHover || invalidHover ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _roleLabel(role),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (columns.isNotEmpty)
                    GestureDetector(
                      onTap: () => onClearRole(role),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: SurfaceStudioDesignTokens.textMuted,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: _isCenter ? 30 : 34,
                child: CustomPaint(
                  painter: SurfaceStudioRoleThumbnailPainter(
                    role: role,
                    assigned: columns.isNotEmpty,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              if (validHover)
                const Text(
                  'Déposer ici',
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.accentTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else if (invalidHover)
                const Text(
                  'Une seule colonne attendue',
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.dangerSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                _AssignmentChips(
                  columns: columns,
                  role: role,
                  center: _isCenter,
                  onClearColumn: onClearColumn,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentChips extends StatelessWidget {
  const _AssignmentChips({
    required this.columns,
    required this.role,
    required this.center,
    required this.onClearColumn,
  });

  final List<int> columns;
  final SurfaceVariantRole role;
  final bool center;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return Text(
        center ? 'Multi-colonnes autorisé' : 'Déposez une colonne',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final column in columns)
          GestureDetector(
            onTap: center ? () => onClearColumn(role, column) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: SurfaceStudioDesignTokens.accentGoldSoft,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
              ),
              child: Text(
                '$column',
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (center)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundDeep,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: SurfaceStudioDesignTokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        if (center)
          const Text(
            'Multi-colonnes autorisé',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

final _schemaGroups = <_RoleGroup>[
  const _RoleGroup(
    id: 'surfaceMain',
    label: 'Surface principale',
    roles: [
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.horizontal,
      SurfaceVariantRole.vertical,
    ],
  ),
  const _RoleGroup(
    id: 'edges',
    label: 'Bords',
    roles: [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ],
  ),
  const _RoleGroup(
    id: 'externalCorners',
    label: 'Coins externes',
    roles: [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ],
  ),
  const _RoleGroup(
    id: 'internalCorners',
    label: 'Coins internes',
    roles: [
      SurfaceVariantRole.innerCornerNW,
      SurfaceVariantRole.innerCornerNE,
      SurfaceVariantRole.innerCornerSW,
      SurfaceVariantRole.innerCornerSE,
    ],
  ),
  const _RoleGroup(
    id: 'junctions',
    label: 'Jonctions',
    roles: [
      SurfaceVariantRole.teeNorth,
      SurfaceVariantRole.teeEast,
      SurfaceVariantRole.teeSouth,
      SurfaceVariantRole.teeWest,
      SurfaceVariantRole.cross,
    ],
  ),
];

class _RoleGroup {
  const _RoleGroup({
    required this.id,
    required this.label,
    required this.roles,
  });

  final String id;
  final String label;
  final List<SurfaceVariantRole> roles;
}

String _roleLabel(SurfaceVariantRole role) => switch (role) {
      SurfaceVariantRole.isolated => 'Plein (center)',
      SurfaceVariantRole.endNorth => 'Bord haut',
      SurfaceVariantRole.endEast => 'Bord droit',
      SurfaceVariantRole.endSouth => 'Bord bas',
      SurfaceVariantRole.endWest => 'Bord gauche',
      SurfaceVariantRole.horizontal => 'Horizontal',
      SurfaceVariantRole.vertical => 'Vertical',
      SurfaceVariantRole.cornerNW => 'Coin haut gauche',
      SurfaceVariantRole.cornerNE => 'Coin haut droit',
      SurfaceVariantRole.cornerSW => 'Coin bas gauche',
      SurfaceVariantRole.cornerSE => 'Coin bas droit',
      SurfaceVariantRole.innerCornerNW => 'Coin int. haut gauche',
      SurfaceVariantRole.innerCornerNE => 'Coin int. haut droit',
      SurfaceVariantRole.innerCornerSW => 'Coin int. bas gauche',
      SurfaceVariantRole.innerCornerSE => 'Coin int. bas droit',
      SurfaceVariantRole.teeNorth => 'Té haut',
      SurfaceVariantRole.teeEast => 'Té droit',
      SurfaceVariantRole.teeSouth => 'Té bas',
      SurfaceVariantRole.teeWest => 'Té gauche',
      SurfaceVariantRole.cross => 'Croix',
    };
