import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'terrain_pattern_guide.dart';
import 'terrain_scratch_view.dart';

class TerrainPatternPanel extends StatelessWidget {
  const TerrainPatternPanel({
    super.key,
    required this.model,
    required this.frameBuilder,
    required this.onChanged,
    required this.advance,
    required this.onAdvance,
    required this.missingOnly,
    required this.onMissingOnly,
    this.selectedSource,
  });

  final TerrainDraftController model;
  final TerrainFrameBuilder frameBuilder;
  final VoidCallback onChanged;
  final bool advance;
  final ValueChanged<bool> onAdvance;
  final bool missingOnly;
  final ValueChanged<bool> onMissingOnly;
  final TilesetSourceRect? selectedSource;

  static const mainPattern = <int>[6, 14, 12, 7, 15, 13, 3, 11, 9];
  static const outerCorners = <int>[16, 17, 18, 19];
  static const otherShapes = <int>[0, 1, 2, 4, 8, 5, 10];

  void _select(int rule, [TilesetSourceRect? source]) {
    model.selectedRule = rule;
    final piece = source ?? selectedSource;
    if (piece != null) model.assign(piece.x, piece.y);
    onChanged();
  }

  Widget _slot(BuildContext context, int rule) {
    final frame = model.frameFor(rule);
    final selected = model.selectedRule == rule;
    final color = Theme.of(context).colorScheme;
    final label = terrainConnectionNames[rule]
        .replaceFirst('Extrémité vers le ', 'Vers le ')
        .replaceFirst('Extrémité vers la ', 'Vers la ');
    return DragTarget<TilesetSourceRect>(
      onAcceptWithDetails: (details) => _select(rule, details.data),
      builder: (context, candidates, rejects) => Material(
        color: selected || candidates.isNotEmpty
            ? color.primaryContainer
            : color.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected || candidates.isNotEmpty
                ? color.primary
                : color.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          key: ValueKey('terrain-rule-$rule'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => _select(rule),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: frame == null
                        ? TerrainPatternGuide(rule: rule)
                        : frameBuilder(frame, 56),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<int> rules, int columns) {
    final visible = missingOnly
        ? rules.where((rule) => model.frameFor(rule) == null).toList()
        : rules;
    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Toutes les pièces de ce groupe sont associées.'),
      );
    }
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent:
            94 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      children: [for (final rule in visible) _slot(context, rule)],
    );
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Patron des raccords',
    compact: true,
    children: [
      Text(
        '${model.assignedCount} / ${model.draft.rules.length} pièces associées',
      ),
      const SizedBox(height: 4),
      const Text(
        'Choisissez une case de l’image, puis sa place dans le patron. Vous pouvez aussi la glisser depuis la pièce sélectionnée.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          StudioTool(
            label: 'Annuler la préparation',
            icon: Icons.undo,
            onPressed: model.canUndo
                ? () {
                    model.undo();
                    onChanged();
                  }
                : null,
          ),
          StudioTool(
            label: 'Rétablir la préparation',
            icon: Icons.redo,
            onPressed: model.canRedo
                ? () {
                    model.redo();
                    onChanged();
                  }
                : null,
          ),
          StudioButton(
            label: missingOnly
                ? 'Voir toutes les formes'
                : 'Voir les manquants',
            secondary: true,
            onPressed: () => onMissingOnly(!missingOnly),
          ),
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          key: const ValueKey('terrain-rules'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Contour du chemin',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              _grid(context, mainPattern, 3),
              const SizedBox(height: 16),
              Text(
                'Coins extérieurs',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                model.draft.rules.length == 16
                    ? 'Optionnels pour ce modèle. La première pièce active les quatre raccords diagonaux.'
                    : 'Ces quatre pièces dessinent les coins rentrants dans le chemin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _grid(context, outerCorners, 2),
              const SizedBox(height: 16),
              Text(
                'Extrémités et passages',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _grid(context, otherShapes, 3),
            ],
          ),
        ),
      ),
      const SizedBox(height: 5),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Passer à la pièce manquante suivante'),
        value: advance,
        onChanged: (value) => onAdvance(value ?? false),
      ),
      StudioButton(
        label: 'Retirer cette pièce',
        icon: Icons.remove_circle_outline,
        secondary: true,
        onPressed: model.frameFor(model.selectedRule) == null
            ? null
            : () {
                model.removeAssignment();
                onChanged();
              },
      ),
    ],
  );
}
