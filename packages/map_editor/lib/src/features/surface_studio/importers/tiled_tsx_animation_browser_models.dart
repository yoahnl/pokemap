import 'package:map_core/map_core.dart';

final class TiledTsxAnimationBrowserItem {
  const TiledTsxAnimationBrowserItem({
    required this.animationId,
    required this.name,
    required this.baseTileId,
    required this.frameCount,
    required this.durationTotalMs,
    required this.firstFrameColumn,
    required this.firstFrameRow,
    required this.sortOrder,
  });

  final String animationId;
  final String name;
  final int baseTileId;
  final int frameCount;
  final int durationTotalMs;
  final int firstFrameColumn;
  final int firstFrameRow;
  final int sortOrder;
}

final class TiledTsxAnimationBrowserFilter {
  const TiledTsxAnimationBrowserFilter({
    this.query = '',
    this.minFrameCount,
    this.maxFrameCount,
    this.onlySelected = false,
  });

  final String query;
  final int? minFrameCount;
  final int? maxFrameCount;
  final bool onlySelected;
}

List<TiledTsxAnimationBrowserItem> buildTiledTsxAnimationBrowserItems({
  required List<ProjectSurfaceAnimation> animations,
}) {
  return List<TiledTsxAnimationBrowserItem>.unmodifiable(
    animations.map(_itemFromAnimation),
  );
}

List<TiledTsxAnimationBrowserItem> filterTiledTsxAnimationBrowserItems({
  required List<TiledTsxAnimationBrowserItem> items,
  required TiledTsxAnimationBrowserFilter filter,
  required Set<String> selectedAnimationIds,
}) {
  final query = filter.query.trim().toLowerCase();
  return List<TiledTsxAnimationBrowserItem>.unmodifiable(
    items.where((item) {
      if (filter.onlySelected &&
          !selectedAnimationIds.contains(item.animationId)) {
        return false;
      }
      final minFrameCount = filter.minFrameCount;
      if (minFrameCount != null && item.frameCount < minFrameCount) {
        return false;
      }
      final maxFrameCount = filter.maxFrameCount;
      if (maxFrameCount != null && item.frameCount > maxFrameCount) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return item.animationId.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          '${item.baseTileId}'.contains(query);
    }),
  );
}

TiledTsxAnimationBrowserItem _itemFromAnimation(
  ProjectSurfaceAnimation animation,
) {
  final first = animation.timeline.frames.first.tileRef;
  return TiledTsxAnimationBrowserItem(
    animationId: animation.id,
    name: animation.name,
    baseTileId: _baseTileIdFromAnimation(animation),
    frameCount: animation.frameCount,
    durationTotalMs: animation.totalDurationMs,
    firstFrameColumn: first.column,
    firstFrameRow: first.row,
    sortOrder: animation.sortOrder,
  );
}

int _baseTileIdFromAnimation(ProjectSurfaceAnimation animation) {
  final idMatch = RegExp(r'(?:^|-)tile-(\d+)$').firstMatch(animation.id);
  if (idMatch != null) {
    return int.parse(idMatch.group(1)!);
  }
  final nameMatch = RegExp(r'\btile\s+(\d+)\b', caseSensitive: false)
      .firstMatch(animation.name);
  if (nameMatch != null) {
    return int.parse(nameMatch.group(1)!);
  }
  return animation.sortOrder;
}
