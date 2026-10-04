import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_catalog_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class MapLifecycleIssues extends StatelessWidget {
  const MapLifecycleIssues({
    super.key,
    required this.issues,
    required this.controller,
  });
  final List<MapCatalogIssue> issues;
  final MapWorkspaceController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final issue in issues)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioNotice(issue.message, isError: true),
              if (controller.project?.maps
                      .where((map) => map.id == issue.mapId)
                      .firstOrNull
                  case final entry?)
                StudioButton(
                  label: 'Voir la carte ${entry.name}',
                  secondary: true,
                  icon: Icons.open_in_new,
                  onPressed: () async {
                    Navigator.pop(context);
                    await controller.activate(entry);
                  },
                ),
            ],
          ),
        ),
    ],
  );
}
