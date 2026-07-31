import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

final class PaletteActions {
  const PaletteActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    visualLibraryDescriptor(
      'palette.upsert',
      'Create or replace one validated tileset palette entry',
    ),
    visualLibraryDescriptor(
      'palette.delete',
      'Delete one tileset palette entry',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    switch (context.request.actionId) {
      case 'palette.upsert':
        parameters.allow(const {'tilesetId', 'entry'});
        final tilesetId = parameters.string('tilesetId');
        final entry = TilesetPaletteEntry.fromJson(
          Map<String, dynamic>.from(parameters.object('entry')),
        );
        final next = upsert(
          context.snapshot.manifest,
          tilesetId: tilesetId,
          entry: entry,
          atlases: readTilesetAtlases(context.snapshot.manifest),
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'palette.upsert',
          path: '/tilesets/$tilesetId/paletteEntries/${entry.id}',
          after: entry.toJson(),
        );
      case 'palette.delete':
        parameters.allow(const {'tilesetId', 'entryId'});
        final tilesetId = parameters.string('tilesetId');
        final entryId = parameters.string('entryId');
        final next = delete(
          context.snapshot.manifest,
          tilesetId: tilesetId,
          entryId: entryId,
        );
        return buildVisualManifestDraft(
          context.snapshot,
          next,
          operation: 'palette.delete',
          path: '/tilesets/$tilesetId/paletteEntries/$entryId',
          before: {'entryId': entryId},
        );
      default:
        throw VisualLibraryException(
          'visual.action_unsupported',
          'The requested palette action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest manifest, {
    required String tilesetId,
    required TilesetPaletteEntry entry,
    required Map<String, TilesetAtlasSpec> atlases,
  }) {
    if (entry.frames.isEmpty) {
      throw VisualLibraryException(
        'palette.frames_required',
        'A palette entry requires at least one frame.',
      );
    }
    for (final frame in entry.frames) {
      const TilesetActions().validateFrame(
        frame,
        owningTilesetId: tilesetId,
        atlases: atlases,
      );
    }
    final tilesets = [
      for (final tileset in manifest.tilesets)
        if (tileset.id == tilesetId)
          tileset.copyWith(
            paletteEntries: [
              for (final existing in tileset.paletteEntries)
                if (existing.id != entry.id) existing,
              entry,
            ]..sort((left, right) => left.id.compareTo(right.id)),
          )
        else
          tileset,
    ];
    if (!tilesets.any((tileset) => tileset.id == tilesetId)) {
      throw VisualLibraryException(
        'tileset.unknown',
        'The palette owner tileset is unknown.',
      );
    }
    return manifest.copyWith(tilesets: tilesets);
  }

  ProjectManifest delete(
    ProjectManifest manifest, {
    required String tilesetId,
    required String entryId,
  }) {
    var found = false;
    final tilesets = [
      for (final tileset in manifest.tilesets)
        if (tileset.id == tilesetId)
          tileset.copyWith(
            paletteEntries: tileset.paletteEntries.where((entry) {
              if (entry.id == entryId) found = true;
              return entry.id != entryId;
            }).toList(growable: false),
          )
        else
          tileset,
    ];
    if (!found) {
      throw VisualLibraryException(
        'palette.unknown',
        'The palette entry is unknown.',
        details: {'tilesetId': tilesetId, 'entryId': entryId},
      );
    }
    return manifest.copyWith(tilesets: tilesets);
  }
}
