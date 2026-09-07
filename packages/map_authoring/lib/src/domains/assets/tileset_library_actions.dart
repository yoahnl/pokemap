import 'package:map_core/map_core.dart';

import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'tileset_actions.dart';

final class TilesetLibraryActions {
  const TilesetLibraryActions();

  static final descriptors = [
    visualLibraryDescriptor(
      'tileset.library.reorganize',
      'Consolidate element-only atlases and classify the tileset library atomically',
      resourceKinds: const ['project', 'tileset', 'tilesetFolder', 'element'],
    ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const {'placements', 'folders', 'assignments'});
    final next = reorganize(
      context.snapshot.manifest,
      maps: context.snapshot.maps,
      placements: parameters.objects('placements'),
      folders: parameters.objects('folders'),
      assignments: parameters.objects('assignments'),
    );
    return buildVisualManifestDraft(
      context.snapshot,
      next,
      operation: 'tileset.library.reorganize',
      path: '/tilesets',
      before: {'tilesets': context.snapshot.manifest.tilesets.length},
      after: {'tilesets': next.tilesets.length},
      referenceImpact: {
        'mapsUnchanged': true,
        'sourceAssetsRetained': true,
        'remappedTilesets': parameters.objects('placements').length,
      },
    );
  }

  ProjectManifest reorganize(
    ProjectManifest manifest, {
    required Iterable<MapData> maps,
    required List<Map<String, Object?>> placements,
    required List<Map<String, Object?>> folders,
    required List<Map<String, Object?>> assignments,
  }) {
    validateManifestFrames(manifest, readTilesetAtlases(manifest));
    final tilesets = {for (final entry in manifest.tilesets) entry.id: entry};
    final moves = <String, ({String target, int x, int y})>{};
    final occupied = <String, List<TilesetSourceRect>>{};
    final outside = manifest.toJson()
      ..remove('tilesets')
      ..remove('elements');
    final mapDocuments = [for (final map in maps) map.toJson()];
    for (final placement in placements) {
      final fields = VisualLibraryParameters(placement);
      fields.allow(const {'tilesetId', 'targetTilesetId', 'x', 'y'});
      final id = fields.string('tilesetId');
      final targetId = fields.string('targetTilesetId');
      final x = placement['x'];
      final y = placement['y'];
      final entry = tilesets[id];
      final target = tilesets[targetId];
      if (entry == null ||
          target == null ||
          id == targetId ||
          moves.containsKey(id) ||
          x is! int ||
          y is! int ||
          x < 0 ||
          y < 0) {
        _reject('placement_invalid', id);
      }
      final source = entry.source;
      final destination = target.source;
      if (source is! ProjectRegularAtlasTilesetSource ||
          destination is! ProjectRegularAtlasTilesetSource ||
          !_plain(source) ||
          !_plain(destination) ||
          entry.paletteEntries.isNotEmpty ||
          entry.elementGroups.isNotEmpty ||
          target.paletteEntries.isNotEmpty ||
          target.elementGroups.isNotEmpty ||
          entry.isWorldTileset ||
          target.isWorldTileset ||
          source.tileWidth != destination.tileWidth ||
          source.tileHeight != destination.tileHeight ||
          destination.pixelWidth > 8192 ||
          destination.pixelHeight > 8192 ||
          x + source.columns > destination.columns ||
          y + source.rows > destination.rows) {
        _reject('source_unsupported', id);
      }
      if (_references(outside, id) ||
          _references(mapDocuments, id) ||
          tilesets.values.where((t) => t.id != id && t.id != targetId).any(
                (t) => t.paletteEntries
                    .any((p) => p.frames.any((f) => f.tilesetId == id)),
              )) {
        _reject('references_blocking', id);
      }
      if (_references(outside, targetId) ||
          _references(mapDocuments, targetId) ||
          manifest.elements.any((element) =>
              element.tilesetId == targetId ||
              element.frames.any((frame) => frame.tilesetId == targetId))) {
        _reject('target_in_use', targetId);
      }
      final rectangle = TilesetSourceRect(
        x: x,
        y: y,
        width: source.columns,
        height: source.rows,
      );
      final previous = occupied.putIfAbsent(targetId, () => []);
      if (previous.any((r) =>
          rectangle.x < r.x + r.width &&
          rectangle.x + rectangle.width > r.x &&
          rectangle.y < r.y + r.height &&
          rectangle.y + rectangle.height > r.y)) {
        _reject('overlapping_placements', id);
      }
      previous.add(rectangle);
      moves[id] = (target: targetId, x: x, y: y);
    }
    if (moves.values.any((move) => moves.containsKey(move.target))) {
      _reject('chained_placements', 'library');
    }
    final elements = [
      for (final element in manifest.elements)
        element.copyWith(
          tilesetId: moves[element.tilesetId]?.target ?? element.tilesetId,
          frames: [
            for (final frame in element.frames)
              _remap(frame, element.tilesetId, moves),
          ],
        ),
    ];
    final folderEntries = [
      for (final folder in folders)
        ProjectTilesetFolder.fromJson(Map<String, dynamic>.from(folder)),
    ];
    if (folderEntries.map((f) => f.id).toSet().length != folderEntries.length) {
      _reject('duplicate_folder', 'library');
    }
    final classification = <String, String>{};
    for (final assignment in assignments) {
      final fields = VisualLibraryParameters(assignment);
      fields.allow(const {'tilesetId', 'folderId'});
      final id = fields.string('tilesetId');
      final folder = fields.string('folderId');
      if (!tilesets.containsKey(id) ||
          moves.containsKey(id) ||
          classification.containsKey(id) ||
          !folderEntries.any((f) => f.id == folder)) {
        _reject('assignment_invalid', id);
      }
      classification[id] = folder;
    }
    final retained =
        tilesets.values.where((t) => !moves.containsKey(t.id)).toList();
    if (classification.length != retained.length) {
      _reject('classification_incomplete', 'library');
    }
    final next = manifest.copyWith(
      tilesetFolders: folderEntries,
      tilesets: [
        for (final entry in retained)
          entry.copyWith(folderId: classification[entry.id])
      ],
      elements: elements,
    );
    ProjectValidator.validate(next);
    validateManifestFrames(next, readTilesetAtlases(next));
    return next;
  }
}

bool _plain(ProjectRegularAtlasTilesetSource source) =>
    source.marginX == 0 &&
    source.marginY == 0 &&
    source.spacingX == 0 &&
    source.spacingY == 0 &&
    source.pixelOffsetX == 0 &&
    source.pixelOffsetY == 0 &&
    source.tileProperties.isEmpty &&
    source.tileWidth > 0 &&
    source.tileHeight > 0 &&
    source.pixelWidth % source.tileWidth == 0 &&
    source.pixelHeight % source.tileHeight == 0;

TilesetVisualFrame _remap(TilesetVisualFrame frame, String owner,
    Map<String, ({String target, int x, int y})> moves) {
  final original = frame.tilesetId.isEmpty ? owner : frame.tilesetId;
  final move = moves[original];
  if (move == null) {
    return frame.tilesetId.isEmpty && moves.containsKey(owner)
        ? frame.copyWith(tilesetId: original)
        : frame;
  }
  return frame.copyWith(
    tilesetId: move.target,
    source: frame.source
        .copyWith(x: frame.source.x + move.x, y: frame.source.y + move.y),
  );
}

bool _references(Object? value, String id) {
  if (value is String) return value == id;
  if (value is List) return value.any((v) => _references(v, id));
  if (value is Map) {
    return value.entries
        .any((e) => e.key != 'elementId' && _references(e.value, id));
  }
  return false;
}

Never _reject(String code, String id) => throw VisualLibraryException(
      'tileset.library.$code',
      'The tileset library migration is not safe.',
      details: {'tilesetId': id},
    );
