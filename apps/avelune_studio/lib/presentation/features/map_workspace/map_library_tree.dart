import 'package:map_core/map_core_domain.dart';

class MapLibraryRow {
  const MapLibraryRow({
    required this.label,
    required this.depth,
    this.group,
    this.map,
    this.count = 0,
  });

  final String label;
  final int depth;
  final ProjectMapGroup? group;
  final ProjectMapEntry? map;
  final int count;
  bool get isFolder => map == null;
  String? get folderId => group?.id;
}

class MapLibraryTree {
  MapLibraryTree({
    required List<ProjectMapGroup> groups,
    required List<ProjectMapEntry> maps,
    String query = '',
  }) : _groups = groups,
       _maps = maps,
       _query = query.trim().toLowerCase() {
    rows = List.unmodifiable(_build());
  }

  final List<ProjectMapGroup> _groups;
  final List<ProjectMapEntry> _maps;
  final String _query;
  late final List<MapLibraryRow> rows;

  int countFor(String? groupId) {
    if (groupId == null) {
      final ids = _groups.map((group) => group.id).toSet();
      return _maps
          .where((map) => map.groupId == null || !ids.contains(map.groupId))
          .length;
    }
    return _maps.where((map) => _belongsTo(map, groupId)).length;
  }

  bool _belongsTo(ProjectMapEntry map, String groupId) {
    var current = map.groupId;
    final visited = <String>{};
    while (current != null && visited.add(current)) {
      if (current == groupId) return true;
      current = _groups
          .where((group) => group.id == current)
          .firstOrNull
          ?.parentGroupId;
    }
    return false;
  }

  List<MapLibraryRow> _build() {
    final result = <MapLibraryRow>[];
    final groupIds = _groups.map((group) => group.id).toSet();
    final byParent = <String?, List<ProjectMapGroup>>{};
    for (final group in _groups) {
      final parent = groupIds.contains(group.parentGroupId)
          ? group.parentGroupId
          : null;
      byParent.putIfAbsent(parent, () => []).add(group);
    }
    for (final siblings in byParent.values) {
      siblings.sort(
        (a, b) => _compare(a.sortOrder, a.name, b.sortOrder, b.name),
      );
    }
    final byFolder = <String?, List<ProjectMapEntry>>{};
    for (final map in _maps) {
      final folder = groupIds.contains(map.groupId) ? map.groupId : null;
      byFolder.putIfAbsent(folder, () => []).add(map);
    }
    for (final siblings in byFolder.values) {
      siblings.sort(
        (a, b) => _compare(a.sortOrder, a.name, b.sortOrder, b.name),
      );
    }

    bool matches(ProjectMapEntry map) =>
        _query.isEmpty ||
        '${map.name} ${map.id}'.toLowerCase().contains(_query);
    void visit(String? parent, int depth, bool ancestorMatches) {
      for (final group in byParent[parent] ?? const <ProjectMapGroup>[]) {
        final groupMatches =
            ancestorMatches ||
            (_query.isNotEmpty && group.name.toLowerCase().contains(_query));
        final descendants = _maps.any(
          (map) => _belongsTo(map, group.id) && matches(map),
        );
        if (_query.isNotEmpty && !groupMatches && !descendants) continue;
        result.add(
          MapLibraryRow(
            label: group.name,
            depth: depth,
            group: group,
            count: countFor(group.id),
          ),
        );
        visit(group.id, depth + 1, groupMatches);
      }
      if (parent != null) {
        for (final map in byFolder[parent] ?? const <ProjectMapEntry>[]) {
          if (!ancestorMatches && !matches(map)) continue;
          result.add(MapLibraryRow(label: map.name, depth: depth, map: map));
        }
      }
    }

    visit(null, 0, false);
    final rootMaps = byFolder[null] ?? const <ProjectMapEntry>[];
    if (rootMaps.isNotEmpty && (_query.isEmpty || rootMaps.any(matches))) {
      final rootRows = <MapLibraryRow>[
        MapLibraryRow(label: 'Sans dossier', depth: 0, count: rootMaps.length),
        for (final map in rootMaps)
          if (matches(map)) MapLibraryRow(label: map.name, depth: 1, map: map),
      ];
      result.addAll(rootRows);
    }
    return result;
  }

  int _compare(int leftOrder, String left, int rightOrder, String right) {
    final order = leftOrder.compareTo(rightOrder);
    if (order != 0) return order;
    final name = left.toLowerCase().compareTo(right.toLowerCase());
    return name == 0 ? left.compareTo(right) : name;
  }
}
