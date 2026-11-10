import 'package:avelune_studio/features/map_workspace/application/map_generated_owner.dart';
export 'package:avelune_studio/features/map_workspace/application/map_generated_owner.dart';
import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/environment_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_view_state.dart';

class MapGeneratedOwnerNotice extends StatelessWidget {
  const MapGeneratedOwnerNotice({
    super.key,
    required this.owner,
    required this.view,
    required this.onChanged,
  });

  final MapGeneratedOwner owner;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('generated-owner'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioNotice(
        'Généré par la zone « ${owner.areaName} » (environnement ${owner.presetName}). '
        'Il se régénère avec sa zone : modifiez la zone pour le changer.',
      ),
      const SizedBox(height: 6),
      StudioButton(
        key: const ValueKey('generated-owner-open'),
        label: 'Ouvrir sa zone',
        icon: Icons.forest_outlined,
        secondary: true,
        onPressed: () {
          view.paletteTab = 'Environnements';
          view.environment = MapEnvironmentSession(
            layerId: owner.layerId,
            areaId: owner.areaId,
          );
          view.tool = StudioMapTool.environment;
          onChanged();
        },
      ),
    ],
  );
}
