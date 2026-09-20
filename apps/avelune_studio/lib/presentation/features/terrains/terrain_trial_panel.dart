import 'package:flutter/material.dart';
import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_palette_tabs.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'terrain_scratch_view.dart';

class TerrainTrialPanel extends StatelessWidget {
  const TerrainTrialPanel({
    super.key,
    required this.model,
    required this.tool,
    required this.onTool,
    required this.frameBuilder,
    required this.onChanged,
  });
  final TerrainDraftController model;
  final String tool;
  final ValueChanged<String> onTool;
  final TerrainFrameBuilder frameBuilder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scratch = TerrainScratchView(
      controller: model,
      frameBuilder: frameBuilder,
      onChanged: onChanged,
      tool: tool,
    );
    final actions = [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            label: 'Exemple complet',
            secondary: true,
            onPressed: () {
              model.example();
              onChanged();
            },
          ),
          StudioButton(
            label: 'Effacer l’essai',
            secondary: true,
            onPressed: () {
              model.clearScratch();
              onChanged();
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        tool == 'Examiner'
            ? 'Cliquez sur une case pour retrouver son raccord, même s’il est manquant.'
            : 'Cliquez et glissez pour tracer. Les croix indiquent les raccords non associés.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
    Widget controls({required bool withScratch}) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Essayez les raccords ici. Votre carte reste inchangée.'),
          const SizedBox(height: 12),
          StudioPaletteTabs(
            items: const ['Peindre', 'Gommer', 'Examiner'],
            selected: tool,
            onChanged: onTool,
          ),
          const SizedBox(height: 12),
          if (withScratch) ...[scratch, const SizedBox(height: 12)],
          ...actions,
        ],
      ),
    );
    return StudioPanel(
      title: 'Terrain d’essai',
      compact: true,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) => bounds.maxWidth >= 600
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: controls(withScratch: false)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: bounds.maxHeight.clamp(170, 408),
                        child: scratch,
                      ),
                    ],
                  )
                : controls(withScratch: true),
          ),
        ),
      ],
    );
  }
}
