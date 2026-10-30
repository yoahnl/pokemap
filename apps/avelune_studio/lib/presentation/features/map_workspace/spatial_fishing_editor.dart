import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
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
          if (document.saving) return false;
          final value = double.tryParse(text.replaceAll(',', '.'));
          if (value == null || !value.isFinite || value < 0 || value > 4) {
            document.error =
                'Choisissez une hauteur de lancer comprise entre 0 et 4 cases.';
            onChanged();
            return false;
          }
          final map = document.current;
          document.commit(
            const SpatialMapOperations().configureNavigation(
              map,
              map.spatialScene!.navigation.copyWith(
                maximumFishingDropWorld: value,
              ),
              models: project.models3d,
            ),
          );
          document.error = null;
          onChanged();
          return true;
        },
      ),
      const SizedBox(height: 8),
      const StudioNotice(
        '0,25 conserve la règle habituelle. Augmentez cette hauteur pour pêcher depuis une berge surélevée. Les obstacles et les talus bloquent toujours le lancer.',
      ),
    ],
  );
}
