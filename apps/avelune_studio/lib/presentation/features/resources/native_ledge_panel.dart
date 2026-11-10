import '../../../features/resources/application/resource_creation_sources.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_preview.dart';

import 'package:avelune_studio/features/map_workspace/application/traversal_labels.dart';

class NativeLedgePanel extends StatelessWidget {
  const NativeLedgePanel({
    super.key,
    required this.record,
    required this.project,
    required this.visuals,
    required this.jumpSide,
    required this.onJumpSideChanged,
  });

  final BorderBlueprintRecord record;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final BorderLineSide? jumpSide;
  final ValueChanged<BorderLineSide>? onJumpSideChanged;

  static bool sourcesAvailable(
    BorderBlueprintRecord record,
    ProjectManifest project,
    MapWorkspaceVisuals visuals,
  ) => nativeLedgeSourcesAvailable(
    record,
    project,
    unavailableResourceIds: visuals.diagnostics.map(
      (diagnostic) => diagnostic.resourceId,
    ),
  );

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Modules natifs du rebord',
    children: [
      const Text(
        'Chaque image conserve son orientation et son ancre d’origine. Les modules restent entiers, sans rotation ni retournement.',
      ),
      if (record.draft.definition.jumpBehavior != null) ...[
        const SizedBox(height: 16),
        StudioSelect(
          key: const ValueKey('native-ledge-jump-side'),
          label: 'Côté autorisé pour le saut',
          value: jumpSide?.name,
          options: const {
            'primary': 'Côté principal',
            'inverted': 'Côté opposé',
          },
          onChanged: onJumpSideChanged == null
              ? null
              : (value) =>
                    onJumpSideChanged!(BorderLineSide.values.byName(value)),
        ),
        const SizedBox(height: 8),
        Text(
          ledgeJumpSummary(record.draft.definition.jumpBehavior!),
          key: const ValueKey('native-ledge-jump-summary'),
        ),
        if (nativeLedgeJumpDimensionNotice(project.settings.dimension)
            case final notice?) ...[
          const SizedBox(height: 8),
          StudioNotice(notice, key: ValueKey('native-ledge-jump-2d-only')),
        ],
      ],
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < record.draft.definition.primitives.length; i++)
            _module(record.draft.definition.primitives[i], i),
        ],
      ),
      if (!sourcesAvailable(record, project, visuals)) ...[
        const SizedBox(height: 12),
        const StudioNotice(
          'Un module possède une source indisponible ou incomplète. Rétablissez les sources avant de publier ce rebord.',
          isError: true,
        ),
      ],
    ],
  );

  Widget _module(BorderPrimitiveDraft primitive, int index) {
    final element = project.elements
        .where((element) => element.id == primitive.sourceElementId)
        .firstOrNull;
    return SizedBox(
      width: 216,
      child: StudioPanel(
        compact: true,
        title: element?.name ?? 'Module ${index + 1}',
        children: [
          if (element != null)
            KeyedSubtree(
              key: ValueKey('native-ledge-preview-${primitive.id}'),
              child: resourcePreview(
                ResourceItem(
                  id: element.id,
                  name: element.name,
                  kind: ResourceKind.decors,
                  element: element,
                ),
                project,
                visuals,
                size: 96,
              ),
            ),
          const SizedBox(height: 8),
          Text(switch (primitive.authoredOrientation) {
            BorderPrimitiveOrientation.north => 'vers le nord',
            BorderPrimitiveOrientation.south => 'vers le sud',
            BorderPrimitiveOrientation.east => 'vers l’est',
            BorderPrimitiveOrientation.west => 'vers l’ouest',
            _ => 'orientation d’origine',
          }),
        ],
      ),
    );
  }
}
