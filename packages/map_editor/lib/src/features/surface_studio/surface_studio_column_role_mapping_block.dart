import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Bloc UI pour le mapping des colonnes d’un atlas vertical vers des rôles Surface.
///
/// Ce widget permet à l’utilisateur de préparer localement un mapping sans
/// générer d’animations ni de presets.
class SurfaceStudioColumnRoleMappingBlock extends StatelessWidget {
  const SurfaceStudioColumnRoleMappingBlock({
    super.key,
    required this.label,
    required this.subtle,
    required this.draft,
    required this.onDraftChanged,
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_column_role_mapping');

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft draft;
  final ValueChanged<SurfaceStudioColumnRoleMappingDraft> onDraftChanged;
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;

  @override
  Widget build(BuildContext context) {
    final gridValid = surfaceStudioAtlasGridOverlayDraftValid(
      draftTileWidth,
      draftTileHeight,
      draftColumns,
      draftRows,
    );

    final cols = draftColumns;
    final rows = draftRows;

    // Cas atlas simple 1×1 : mapping non nécessaire
    if (gridValid && cols == 1 && rows == 1) {
      return Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping des colonnes',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Atlas simple : mapping de colonnes non nécessaire.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      );
    }

    // Dimensions invalides : message d’erreur
    if (!gridValid) {
      return Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping des colonnes',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Corrigez la grille avant de mapper les colonnes.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      );
    }

    // Cas normal : afficher le mapping
    final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);
    final columnCount = draft.columnCount;

    return Container(
      key: sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mapping des colonnes',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: label,
            subtle: subtle,
            summary: summary,
          ),
          if (summary.hasDuplicateRoles) ...[
            const SizedBox(height: 4),
            Text(
              'Attention : un rôle est assigné à plusieurs colonnes.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ColumnList(
            label: label,
            subtle: subtle,
            draft: draft,
            onDraftChanged: onDraftChanged,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  onDraftChanged(
                    SurfaceStudioColumnRoleMappingDraft.suggested(columnCount),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Suggérer un mapping standard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: label,
                  side: BorderSide(color: label.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  onDraftChanged(draft.cleared());
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Réinitialiser le mapping des colonnes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: label,
                  side: BorderSide(color: label.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.subtle,
    required this.summary,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryItem(
          label: 'Colonnes',
          value: '${summary.columnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Assignées',
          value: '${summary.assignedColumnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Non assignées',
          value: '${summary.unassignedColumnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Doublons',
          value: '${summary.duplicateRoleCount}',
          labelColor: label,
          valueColor: summary.hasDuplicateRoles
              ? Colors.orange.shade700
              : subtle,
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ColumnList extends StatelessWidget {
  const _ColumnList({
    required this.label,
    required this.subtle,
    required this.draft,
    required this.onDraftChanged,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft draft;
  final ValueChanged<SurfaceStudioColumnRoleMappingDraft> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final columnCount = draft.columnCount;

    // Pour un grand nombre de colonnes, on limite la hauteur avec scroll
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: columnCount,
        itemBuilder: (context, index) {
          final role = draft.roleForColumn(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Col $index',
                    style: TextStyle(
                      color: label,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<SurfaceVariantRole>(
                    isExpanded: true,
                    value: role,
                    hint: Text(
                      'Non assignée',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                      ),
                    ),
                    style: TextStyle(
                      color: label,
                      fontSize: 11,
                    ),
                    iconEnabledColor: label,
                    dropdownColor: EditorChrome.elevatedPanelBackground(context),
                    items: [
                      // Option pour désassigner
                      const DropdownMenuItem<SurfaceVariantRole>(
                        value: null,
                        child: Text(
                          'Non assignée',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      // Tous les rôles standards
                      ...SurfaceStudioRoleLabels.allRolesInOrder.map(
                        (r) => DropdownMenuItem<SurfaceVariantRole>(
                          value: r,
                          child: Text(
                            SurfaceStudioRoleLabels.labelForRole(r),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (newRole) {
                      onDraftChanged(draft.withRoleForColumn(index, newRole));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}