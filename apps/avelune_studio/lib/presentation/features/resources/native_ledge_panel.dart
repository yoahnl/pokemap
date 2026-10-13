import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'resource_preview.dart';

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
  ) {
    final primitives = record.draft.definition.primitives;
    if (primitives.isEmpty) return false;
    for (final primitive in primitives) {
      if (primitive.isSpatial ||
          primitive.role != BorderPrimitiveRole.structureLarge) {
        return false;
      }
      final element = project.elements
          .where((element) => element.id == primitive.sourceElementId)
          .firstOrNull;
      if (element == null || element.frames.isEmpty) return false;
      final resourceIds = <String>{element.id};
      for (final frame in element.frames) {
        final id = frame.tilesetId.isEmpty
            ? element.tilesetId
            : frame.tilesetId;
        final tileset = project.tilesets
            .where((tile) => tile.id == id)
            .firstOrNull;
        if (tileset == null) return false;
        resourceIds.add(id);
        if (tileset.source case ProjectImageCollectionTilesetSource(
          :final pages,
        )) {
          resourceIds.addAll(pages.map((page) => page.assetId));
        }
      }
      if (visuals.diagnostics.any(
        (diagnostic) => resourceIds.contains(diagnostic.resourceId),
      )) {
        return false;
      }
    }
    return true;
  }

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
