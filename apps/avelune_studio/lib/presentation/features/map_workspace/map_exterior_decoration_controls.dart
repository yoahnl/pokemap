import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_exterior_decoration_controller.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_tool_strip_selection.dart';

final class MapExteriorDecorationControls extends StatelessWidget {
  const MapExteriorDecorationControls({
    super.key,
    required this.controller,
    required this.view,
    required this.onChanged,
  });
  final MapExteriorDecorationController controller;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  void changeSide(String side, String value) {
    final current = controller.current;
    controller.configureMargins(
      west: side == 'west' ? int.parse(value) : current?.west ?? 0,
      east: side == 'east' ? int.parse(value) : current?.east ?? 0,
      north: side == 'north' ? int.parse(value) : current?.north ?? 0,
      south: side == 'south' ? int.parse(value) : current?.south ?? 0,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => StudioPanel(
      compact: true,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: StudioSelect(
                label: 'Cible d’édition',
                value: controller.editingExterior ? 'exterior' : 'playable',
                options: const {
                  'playable': 'Zone jouable',
                  'exterior': 'Décor extérieur',
                },
                onChanged: controller.saving
                    ? null
                    : (value) {
                        view.pendingMove = null;
                        if (value == 'exterior') {
                          if (!isExteriorDecorationTool(view.tool)) {
                            view.tool = StudioMapTool.select;
                          }
                          if (!exteriorDecorationPaletteTabs.contains(
                            view.paletteTab,
                          )) {
                            view.paletteTab = 'Décors';
                            view.paletteTiles = false;
                          }
                        }
                        controller.setEditingExterior(value == 'exterior');
                        onChanged();
                      },
              ),
            ),
            if (controller.editingExterior)
              for (final side in const [
                ('west', 'Ouest'),
                ('east', 'Est'),
                ('north', 'Nord'),
                ('south', 'Sud'),
              ])
                SizedBox(
                  width: 120,
                  child: StudioSelect(
                    label: '${side.$2} · cases',
                    value:
                        '${switch (side.$1) {
                          'west' => controller.current?.west ?? 0,
                          'east' => controller.current?.east ?? 0,
                          'north' => controller.current?.north ?? 0,
                          _ => controller.current?.south ?? 0,
                        }}',
                    options: {
                      for (var value = 0; value <= 64; value++)
                        '$value': '$value',
                    },
                    onChanged: controller.saving
                        ? null
                        : (value) => changeSide(side.$1, value),
                  ),
                ),
          ],
        ),
        if (controller.editingExterior) ...[
          const SizedBox(height: 8),
          if (controller.current case final decoration?)
            if (decoration.west +
                    decoration.east +
                    decoration.north +
                    decoration.south ==
                0)
              const StudioNotice(
                'Définissez au moins une marge pour créer du décor extérieur.',
              )
            else if (controller.editingDocument == null)
              const StudioNotice(
                'Cliquez à l’extérieur de la zone jouable pour commencer à peindre ou placer un décor.',
              ),
          const Text(
            'Peignez le sol, l’eau et les chemins, puis placez vos bordures et arbres en dehors de la zone jouable. Les pinceaux continus traversent les limites locales ; les rectangles et motifs restent limités à la zone de départ.',
          ),
        ],
        if (controller.error != null) ...[
          const SizedBox(height: 8),
          StudioNotice(controller.error!),
        ],
      ],
    ),
  );
}
