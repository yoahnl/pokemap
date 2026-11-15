import 'package:map_core/map_core_domain.dart';

final class MapReliefProfile {
  const MapReliefProfile({
    required this.id,
    required this.name,
    this.twoLevelId,
  });
  final String id, name;
  final String? twoLevelId;
}

MapReliefProfile? mapReliefDefaultProfile(List<MapReliefProfile> profiles) =>
    profiles.firstOrNull;

enum MapReliefProblem {
  noProfile,
  profileUnavailable,
  profileLeftHanded,
  profileLevels,
  levelInvalid,
  stepNotLevel,
  twoLevelMissing,
  stepTooHigh,
  ambiguous,
  narrowCorner,
  cornerNearStep,
  profileIncompatible,
  surfaceLimit,
  footprintLimit,
  rampConflict,
  busy,
  unknown,
}

enum MapReliefWarning { unreachable, exteriorDecoration }

final class MapReliefOutcome {
  const MapReliefOutcome({
    this.problem,
    this.warnings = const {},
    this.diagnostics = const [],
    this.profileName,
  });
  final MapReliefProblem? problem;
  final Set<MapReliefWarning> warnings;
  final List<String> diagnostics;
  final String? profileName;
}

final class MapReliefPalette {
  const MapReliefPalette({required this.levels, required this.ground});
  final List<int> levels;
  final int ground;
}

final class MapReliefToolState {
  int level = 1;
  String? profileId;
  MapReliefOutcome? outcome;
  bool loading = false;
  Object? loadFailure;
  MapData? _paletteMap;
  MapReliefPalette? _palette;
  (ProjectManifest, String, double)? _profilesKey;
  List<MapReliefProfile> _profiles = const [];

  List<MapReliefProfile> profiles(ProjectManifest project, MapData map) {
    final key = _profilesKey;
    if (key == null ||
        !identical(key.$1, project) ||
        key.$2 != map.id ||
        key.$3 != map.spatialScene?.levelHeight) {
      _profilesKey = (project, map.id, map.spatialScene?.levelHeight ?? 0);
      _profiles = mapReliefProfiles(project, map);
    }
    return _profiles;
  }

  int maximumLevel(MapData map) =>
      (1024 / map.spatialScene!.levelHeight).floor();

  void step(MapData map, int delta) =>
      level = (level + delta).clamp(0, maximumLevel(map));

  void pick(MapData map, GridPos cell) {
    final scene = map.spatialScene!;
    level = (scene.worldHeightAt(cell.x + .5, cell.y + .5) / scene.levelHeight)
        .round()
        .clamp(0, maximumLevel(map));
  }

  MapReliefPalette palette(MapData map) {
    if (!identical(map, _paletteMap) || _palette == null) {
      _paletteMap = map;
      _palette = _measure(map);
    }
    final measured = _palette!;
    final top = [
      measured.levels.first + 2,
      level + 2,
    ].reduce((a, b) => a > b ? a : b).clamp(0, maximumLevel(map));
    return MapReliefPalette(
      levels: [for (var value = top; value >= 0; value--) value],
      ground: measured.ground,
    );
  }

  static MapReliefPalette _measure(MapData map) {
    final scene = map.spatialScene!;
    final counts = <int, int>{};
    for (var z = 0; z < scene.depth; z++) {
      for (var x = 0; x < scene.width; x++) {
        final value = (scene.worldHeightAt(x + .5, z + .5) / scene.levelHeight)
            .round();
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    final ordered = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highest = counts.keys.reduce((a, b) => a > b ? a : b);
    return MapReliefPalette(levels: [highest], ground: ordered.first.key);
  }
}

typedef _Candidate = ({String id, String name, int span, String? family});

List<MapReliefProfile> mapReliefProfiles(ProjectManifest project, MapData map) {
  final candidates = [
    for (final record in project.borderCatalog.records)
      ?_candidate(project, map, record),
  ];
  return [
    for (final one in candidates)
      if (one.span == 1) _profile(one, candidates),
  ]..sort(
    (a, b) => switch (a.name.compareTo(b.name)) {
      0 => a.id.compareTo(b.id),
      final order => order,
    },
  );
}

MapReliefProfile? mapReliefProfile(
  ProjectManifest project,
  MapData map,
  String? id,
) {
  final record = id == null ? null : project.borderCatalog.recordById(id);
  final one = record == null ? null : _candidate(project, map, record);
  if (one == null || one.span != 1) return null;
  final library = project.resourceLibraryCatalog;
  return _profile(one, [
    if (one.family != null)
      for (final other in project.borderCatalog.records)
        if (library.entryFor('borderBlueprint', other.id)?.familyId ==
            one.family)
          ?_candidate(project, map, other),
  ]);
}

MapReliefProfile _profile(_Candidate one, List<_Candidate> others) {
  final family = one.family;
  final variants = family == null || _sharedFamily(family)
      ? const <String>{}
      : {
          for (final two in others)
            if (two.span == 2 && two.family == family) two.id,
        };
  return MapReliefProfile(
    id: one.id,
    name: one.name,
    twoLevelId: variants.length == 1 ? variants.single : null,
  );
}

bool _sharedFamily(String id) =>
    ResourceLibraryCatalog.predefinedFamilies.any((family) => family.id == id);

_Candidate? _candidate(
  ProjectManifest project,
  MapData map,
  BorderBlueprintRecord record,
) {
  final levelHeight = map.spatialScene?.levelHeight;
  final library = project.resourceLibraryCatalog;
  final definition = record.latestPublished?.definition;
  if (levelHeight == null ||
      record.isDeprecated ||
      definition == null ||
      !definition.isSpatial ||
      !definition.followContourDirection ||
      !_reliefCategory(library, record.id) ||
      !borderTemplateUsesStrokeGeometry(definition.template) ||
      !library.availableForMap('borderBlueprint', record.id, map.id)) {
    return null;
  }
  final span = spatialBorderProfileLevelSpan(definition, project, levelHeight);
  if (span < 1 ||
      span > 2 ||
      validateSpatialDirectedFaceOrientation(
        blueprintId: record.id,
        definition: definition,
        manifest: project,
      ).isNotEmpty) {
    return null;
  }
  return (
    id: record.id,
    name: definition.name,
    span: span,
    family: library.entryFor('borderBlueprint', record.id)?.familyId,
  );
}

bool _reliefCategory(ResourceLibraryCatalog library, String id) {
  final entry = library.entryFor('borderBlueprint', id);
  final category = library.familyCategory(entry?.familyId) ?? entry?.category;
  return category == ResourceUsageCategory.relief;
}

MapReliefProblem mapReliefProblem(Object failure) => switch (failure) {
  ValidationException(:final code) => switch (code) {
    'spatial.relief.profile_unavailable' => MapReliefProblem.profileUnavailable,
    'spatial.relief.profile_faces_high_side' =>
      MapReliefProblem.profileLeftHanded,
    'spatial.relief.profile_level_span' => MapReliefProblem.profileLevels,
    'spatial.relief.level_invalid' => MapReliefProblem.levelInvalid,
    'spatial.relief.step_not_level' => MapReliefProblem.stepNotLevel,
    'spatial.relief.two_level_profile_missing' =>
      MapReliefProblem.twoLevelMissing,
    'spatial.relief.step_too_high' => MapReliefProblem.stepTooHigh,
    'spatial.relief.step_ambiguous' => MapReliefProblem.ambiguous,
    'spatial.relief.trace_refused' => _traceProblem(failure),
    'spatial.relief.profile_incompatible' =>
      MapReliefProblem.profileIncompatible,
    'spatial.terrain.paint.surface_limit' => MapReliefProblem.surfaceLimit,
    'spatial.terrain.paint.footprint_limit' => MapReliefProblem.footprintLimit,
    'spatial.terrain.paint.ramp_conflict' => MapReliefProblem.rampConflict,
    _ => MapReliefProblem.unknown,
  },
  _ => MapReliefProblem.unknown,
};

MapReliefProblem _traceProblem(ValidationException failure) =>
    mapReliefDiagnostics(failure)
        .contains('border.spatial.corner_join_conflict')
    ? MapReliefProblem.narrowCorner
    : MapReliefProblem.profileIncompatible;

List<String> mapReliefDiagnostics(Object failure) => switch (failure) {
  ValidationException(:final details) => {
    for (final code in (details['diagnostics'] as List?) ?? const [])
      if (code is String) code,
  }.toList(),
  _ => const [],
};
