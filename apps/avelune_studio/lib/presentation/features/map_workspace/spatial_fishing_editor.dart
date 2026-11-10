import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_spatial_settings_commands.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

class SpatialFishingEditor extends StatelessWidget {
  const SpatialFishingEditor({
    super.key,
    required this.document,
    required this.project,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Pêche', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      StudioCommitField(
        key: const ValueKey('spatial-fishing-drop'),
        label: 'Hauteur maximale du lancer vers le bas (cases)',
        value:
            '${document.current.spatialScene!.navigation.maximumFishingDropWorld}',
        tryCommit: (text) {
          final result = MapSpatialSettingsCommands(document)
              .fishingDrop(text, project);
          onChanged();
          return result;
        },
      ),
      const SizedBox(height: 8),
      const StudioNotice(
        '0,25 conserve la règle habituelle. Augmentez cette hauteur pour pêcher depuis une berge surélevée. Les obstacles et les talus bloquent toujours le lancer.',
      ),
    ],
  );
}
