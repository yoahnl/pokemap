import 'package:flutter/material.dart';
import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_connection_diagram.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'terrain_scratch_view.dart';

class TerrainRulesPanel extends StatelessWidget {
  const TerrainRulesPanel({
    super.key,
    required this.model,
    required this.frameBuilder,
    required this.onChanged,
    required this.advance,
    required this.onAdvance,
    required this.missingOnly,
    required this.onMissingOnly,
  });
  final TerrainDraftController model;
  final TerrainFrameBuilder frameBuilder;
  final VoidCallback onChanged;
  final bool advance, missingOnly;
  final ValueChanged<bool> onAdvance, onMissingOnly;

  void update(VoidCallback action) {
    action();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (var i = 0; i < 16; i++)
        if (!missingOnly || model.frameFor(i) == null) i,
    ];
    return StudioPanel(
      title: 'Raccords sur quatre côtés',
      compact: true,
      children: [
        Text('${model.assignedCount} / 16 raccords associés'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StudioTool(
              label: 'Annuler la préparation',
              icon: Icons.undo,
              onPressed: model.canUndo ? () => update(model.undo) : null,
            ),
            StudioTool(
              label: 'Rétablir la préparation',
              icon: Icons.redo,
              onPressed: model.canRedo ? () => update(model.redo) : null,
            ),
            StudioButton(
              label: missingOnly
                  ? 'Voir tous les raccords'
                  : 'Voir les raccords manquants',
              secondary: true,
              onPressed: () => onMissingOnly(!missingOnly),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Passer au raccord manquant suivant'),
          value: advance,
          onChanged: (value) => onAdvance(value ?? false),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('Tous les raccords sont associés.'))
              : LayoutBuilder(
                  builder: (context, bounds) => GridView.builder(
                    key: const ValueKey('terrain-rules'),
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          bounds.maxWidth >= 360 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 20
                          ? 4
                          : 3,
                      mainAxisExtent:
                          110 +
                          (MediaQuery.textScalerOf(context).scale(14) - 14) * 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final rule = visible[index];
                      final frame = model.frameFor(rule);
                      return StudioPaletteCard(
                        key: ValueKey('terrain-rule-$rule'),
                        name: terrainConnectionNames[rule]
                            .replaceFirst('Extrémité vers le ', 'Vers le ')
                            .replaceFirst('Extrémité vers la ', 'Vers la '),
                        maxNameLines: 2,
                        selected: model.selectedRule == rule,
                        onTap: () => update(() => model.selectedRule = rule),
                        preview: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: StudioConnectionDiagram(
                                        mask: rule,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: frame == null
                                        ? Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          )
                                        : frameBuilder(frame, 40),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              frame == null ? 'Manquant' : 'Associé',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 6),
        StudioButton(
          label: 'Retirer l’affectation',
          icon: Icons.remove_circle_outline,
          secondary: true,
          onPressed: model.frameFor(model.selectedRule) == null
              ? null
              : () => update(model.removeAssignment),
        ),
      ],
    );
  }
}
