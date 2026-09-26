import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'map_workspace_view_state.dart';

class MapEncounterModePicker extends StatelessWidget {
  const MapEncounterModePicker({
    super.key,
    required this.view,
    required this.onChanged,
  });

  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final paintTool = StudioMapTool.values
        .where((tool) => tool.name == 'encounterPaint')
        .firstOrNull;
    final eraseTool = StudioMapTool.values
        .where((tool) => tool.name == 'encounterErase')
        .firstOrNull;
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Rencontres', style: Theme.of(context).textTheme.titleSmall),
        ChoiceChip(
          label: const Text('Rectangle'),
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          selected:
              view.tool == StudioMapTool.gameplayZone &&
              view.zoneKind == GameplayZoneKind.encounter,
          onSelected: (_) {
            view.zoneKind = GameplayZoneKind.encounter;
            view.tool = StudioMapTool.gameplayZone;
            onChanged();
          },
        ),
        if (paintTool != null)
          ChoiceChip(
            label: const Text('Case par case'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selected: view.tool == paintTool,
            onSelected: (_) {
              view.tool = paintTool;
              onChanged();
            },
          ),
        if (eraseTool != null)
          ChoiceChip(
            label: const Text('Effacer'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selected: view.tool == eraseTool,
            onSelected: (_) {
              view.tool = eraseTool;
              onChanged();
            },
          ),
      ],
    );
  }
}
