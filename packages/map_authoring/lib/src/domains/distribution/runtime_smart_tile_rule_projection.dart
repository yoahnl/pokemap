import 'package:map_core/map_core.dart';

ProjectManifest projectRuntimeSmartTileRules({
  required ProjectManifest project,
  required List<MapData> maps,
  Iterable<Object?> additionalDocuments = const [],
  int minimumRuleCount = 64,
}) {
  if (project.settings.dimension != ProjectDimension.twoD) return project;
  final ids = maps.map((map) => map.id).toSet();
  if (ids.length != maps.length ||
      ids.length != project.maps.length ||
      project.maps.map((entry) => entry.id).toSet().length != ids.length ||
      project.maps.any((entry) => !ids.contains(entry.id))) {
    throw ArgumentError('Runtime rule projection requires every project map');
  }
  final catalog = project.smartTileCatalog;
  final materialIds = catalog.materials.map((material) => material.id).toSet();
  final owners = <String, List<(MapData, SmartTileLayer)>>{};
  for (final map in maps) {
    for (final layer in map.layers.whereType<SmartTileLayer>()) {
      owners.putIfAbsent(layer.presetId, () => []).add((map, layer));
    }
  }
  final external = project.toJson()..remove('smartTileCatalog');
  final referenced = _referencedStrings([
    external,
    ...catalog.patterns.map((pattern) => pattern.toJson()),
    ...catalog.drafts.map((draft) => draft.toJson()),
    ...additionalDocuments,
  ]);
  var changed = false;
  final presets = <ProjectSmartTilePreset>[];
  for (final preset in catalog.presets) {
    final uses = owners[preset.id];
    if (uses == null ||
        preset.rules.length < minimumRuleCount ||
        !const {
          SmartTileTopology.uniform,
          SmartTileTopology.cardinal4,
          SmartTileTopology.blob8,
        }.contains(preset.topology) ||
        uses.any((owner) =>
            owner.$2.field is! SmartTileCellField ||
            owner.$2.materialPalette
                .any((id) => id.isNotEmpty && !materialIds.contains(id)))) {
      presets.add(preset);
      continue;
    }
    final retained = <String>{
      if (preset.fallbackRuleId != null) preset.fallbackRuleId!,
      for (final rule in preset.rules)
        if (referenced.contains(rule.id)) rule.id,
    };
    var valid = true;
    for (final (map, layer) in uses) {
      final resolver = _resolver(preset, catalog, map, layer);
      try {
        for (var y = 0; y < map.size.height; y++) {
          for (var x = 0; x < map.size.width; x++) {
            final resolution = resolver.resolve(
              context: smartTileCellContextForLayerCell(
                  layer: layer, map: map, preset: preset, x: x, y: y),
              x: x,
              y: y,
            );
            if (resolution.status != SmartTileResolutionStatus.resolved &&
                resolution.status != SmartTileResolutionStatus.noIntent) {
              valid = false;
            }
            if (resolution.ruleId != null) retained.add(resolution.ruleId!);
            retained.addAll(resolution.matchingRuleIds);
          }
        }
      } on ArgumentError {
        valid = false;
      }
      if (!valid) break;
    }
    if (!valid) {
      presets.add(preset);
      continue;
    }
    final coverage = _coverage(preset, catalog);
    for (final entry in coverage.cases) {
      retained.addAll(entry.ruleIds);
    }
    final rules =
        preset.rules.where((rule) => retained.contains(rule.id)).toList();
    if (rules.isEmpty || rules.length == preset.rules.length) {
      presets.add(preset);
      continue;
    }
    final candidate = preset.copyWith(rules: rules);
    if (!_sameCoverage(coverage, _coverage(candidate, catalog))) {
      presets.add(preset);
      continue;
    }
    for (final (map, layer) in uses) {
      final before = _resolver(preset, catalog, map, layer);
      final after = _resolver(candidate, catalog, map, layer);
      for (var y = 0; y < map.size.height && valid; y++) {
        for (var x = 0; x < map.size.width; x++) {
          final context = smartTileCellContextForLayerCell(
              layer: layer, map: map, preset: preset, x: x, y: y);
          if (!_sameResolution(before.resolve(context: context, x: x, y: y),
              after.resolve(context: context, x: x, y: y))) {
            valid = false;
            break;
          }
        }
      }
      if (!valid) break;
    }
    presets.add(valid ? candidate : preset);
    changed |= valid;
  }
  if (!changed) return project;
  return project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
    categories: catalog.categories,
    atlases: catalog.atlases,
    materials: catalog.materials,
    animations: catalog.animations,
    presets: presets,
    patterns: catalog.patterns,
    drafts: catalog.drafts,
  ));
}

PreparedSmartTileResolver _resolver(ProjectSmartTilePreset preset,
        ProjectSmartTileCatalog catalog, MapData map, SmartTileLayer layer) =>
    PreparedSmartTileResolver(
      preset: preset,
      materials: catalog.materials,
      mapId: map.id,
      layerId: layer.id,
      layerSeed: layer.layerSeed,
      candidateWeights: layer.candidateWeights,
    );

SmartTileCoverageReport _coverage(
        ProjectSmartTilePreset preset, ProjectSmartTileCatalog catalog) =>
    analyzeSmartTileCoverage(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );

bool _sameCoverage(SmartTileCoverageReport a, SmartTileCoverageReport b) {
  if (a.cases.length != b.cases.length ||
      a.diagnostics.length != b.diagnostics.length) {
    return false;
  }
  for (var i = 0; i < a.cases.length; i++) {
    if (a.cases[i].id != b.cases[i].id ||
        a.cases[i].status != b.cases[i].status ||
        !_sameStrings(a.cases[i].ruleIds, b.cases[i].ruleIds)) {
      return false;
    }
  }
  for (var i = 0; i < a.diagnostics.length; i++) {
    if (a.diagnostics[i].code != b.diagnostics[i].code ||
        a.diagnostics[i].scenarioId != b.diagnostics[i].scenarioId ||
        a.diagnostics[i].message != b.diagnostics[i].message) {
      return false;
    }
  }
  return true;
}

bool _sameResolution(SmartTileResolution a, SmartTileResolution b) =>
    a.status == b.status &&
    a.ruleId == b.ruleId &&
    a.candidate == b.candidate &&
    a.deterministicHash == b.deterministicHash &&
    a.transform == b.transform &&
    a.usedFallback == b.usedFallback &&
    a.message == b.message &&
    _sameStrings(a.matchingRuleIds, b.matchingRuleIds);

bool _sameStrings(List<String> a, List<String> b) =>
    a.length == b.length &&
    Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

Set<String> _referencedStrings(Object? value) {
  final strings = <String>{};
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final item = pending.removeLast();
    if (item is String) {
      strings.add(item);
    } else if (item is Map) {
      pending.addAll(item.values);
    } else if (item is List) {
      pending.addAll(item);
    }
  }
  return strings;
}
