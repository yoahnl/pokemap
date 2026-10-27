part of 'map_exterior_decoration_authoring.dart';

extension _ExteriorDecorationDependencyGuard
    on LocalMapExteriorDecorationAuthoring {
  Future<void> _guardBorderTerrainDependencies(
    _DecorationContext context,
    _DecorationIndex beforeIndex,
    Map<String, Map<String, dynamic>?> images, {
    Map<String, Map<String, dynamic>?> beforeImages = const {},
  }) async {
    final indexJson = images[context.storageKey];
    if (indexJson == null) return;
    final afterIndex = _DecorationIndex.fromJson(indexJson);
    if (afterIndex.borders.isEmpty) return;
    final changes =
        <String, (ExteriorDecorationSector?, ExteriorDecorationSector?)>{};
    for (final image in images.entries) {
      if (image.key.startsWith('$exteriorReferenceNamespace/') || image.key == context.storageKey ||
          image.key.startsWith('maps/${context.map.id}.decoration/borders/')) {
        continue;
      }
      final id = image.key
          .substring(image.key.lastIndexOf('/') + 1, image.key.length - 5);
      final summary = beforeIndex.sectors[id];
      final before = beforeImages.containsKey(image.key)
          ? beforeImages[image.key] == null
              ? null
              : ExteriorDecorationSector.fromJson(beforeImages[image.key]!)
          : summary == null
              ? null
              : await _readSector(context, summary);
      final after = image.value == null
          ? null
          : ExteriorDecorationSector.fromJson(image.value!);
      if (_exteriorTerrainIdentity(before) != _exteriorTerrainIdentity(after)) {
        changes[id] = (before, after);
      }
    }
    if (changes.isEmpty) return;
    final catalog = await _nativeCatalog(context);
    for (final summary in afterIndex.borders.values) {
      final bounds = ExteriorDecorationRect(
          x: summary.x,
          z: summary.z,
          width: summary.width,
          depth: summary.depth);
      if (!changes.values.any((change) =>
          change.$1?.bounds.overlaps(bounds) == true ||
          change.$2?.bounds.overlaps(bounds) == true)) {
        continue;
      }
      final path = _borderPath(context.map.id, summary.id);
      final border = images.containsKey(path)
          ? ExteriorDecorationBorder.fromJson(images[path]!)
          : await _readBorder(context, summary);
      final selection = await catalog.reader
          .read((source) => ProjectCatalogSelection(source).resolve({
                CatalogDefinitionKey(CatalogDefinitionKind.borderRecord,
                    border.feature.blueprintId),
                for (final instance in border.instances)
                  CatalogDefinitionKey(
                      CatalogDefinitionKind.model3d, instance.modelId),
              }));
      final probe = resolveExteriorDecorationBorder(
          manifest: selection,
          decoration: afterIndex.definition!,
          border: border,
          playableMap: context.map);
      final samples =
          probe.sourceContext!.fingerprintContext()['samples'] as List;
      final affected = samples.any((raw) {
        final sample = raw as Map;
        final x = border.originX + (sample['x'] as num).toDouble();
        final z = border.originZ + (sample['z'] as num).toDouble();
        if (afterIndex.definition!.playableBounds.contains(x, z)) return false;
        final before = _changedExteriorTerrainAt(
            changes.values.map((change) => change.$1), x, z);
        final after = _changedExteriorTerrainAt(
            changes.values.map((change) => change.$2), x, z);
        return before != after;
      });
      if (!affected) continue;
      if (!images.containsKey(path)) {
        throw const FormatException(
            'Border terrain dependency changed; rematerialize the dependent Border atomically before saving relief.');
      }
      final sectors = <ExteriorDecorationSector>[];
      for (final sectorSummary in afterIndex.sectors.values) {
        if (!samples.any((raw) {
          final sample = raw as Map;
          final x = border.originX + (sample['x'] as num),
              z = border.originZ + (sample['z'] as num);
          return x >= sectorSummary.x &&
              x < sectorSummary.x + sectorSummary.width &&
              z >= sectorSummary.z &&
              z < sectorSummary.z + sectorSummary.depth;
        })) {
          continue;
        }
        final sectorPath = _sectorPath(context.map.id, sectorSummary.id);
        sectors.add(images.containsKey(sectorPath)
            ? ExteriorDecorationSector.fromJson(images[sectorPath]!)
            : await _readSector(context, sectorSummary));
      }
      final resolved = resolveExteriorDecorationBorder(
          manifest: selection,
          decoration: _withSectors(afterIndex.definition!, sectors),
          border: border,
          playableMap: context.map);
      if (!resolved.result.canApply ||
          resolved.result.materialization != border.feature.materialization ||
          jsonEncode(resolved.modelInstances
                  .map((instance) => instance.toJson())
                  .toList()) !=
              jsonEncode(border.instances
                  .map((instance) => instance.toJson())
                  .toList())) {
        throw const FormatException(
            'Border terrain dependency changed; the atomic Border materialization is stale.');
      }
    }
  }

  Future<void> _guardReplayedBorderTerrainDependencies(
      _DecorationContext context, AuthoringReceipt receipt) async {
    final before = <String, Map<String, dynamic>?>{},
        after = <String, Map<String, dynamic>?>{};
    for (final diff in receipt.diff.entries) {
      final path = diff.extensions['storageKey']! as String;
      before[path] = diff.before == null
          ? null
          : Map<String, dynamic>.from(diff.before! as Map);
      after[path] = diff.after == null
          ? null
          : Map<String, dynamic>.from(diff.after! as Map);
    }
    final index = before[context.storageKey];
    await _guardBorderTerrainDependencies(
        context,
        index == null
            ? _DecorationIndex(null, const {})
            : _DecorationIndex.fromJson(index),
        after,
        beforeImages: before);
  }
}

String? _exteriorTerrainIdentity(ExteriorDecorationSector? sector) =>
    sector == null
        ? null
        : jsonEncode({
            'x': sector.originX,
            'z': sector.originZ,
            'width': sector.scene.width,
            'depth': sector.scene.depth,
            'levelHeight': sector.scene.levelHeight,
            'heightLevels': sector.scene.heightLevels,
            'terrainSurfaces': sector.scene.terrainSurfaces.toJson(),
          });

(String, double)? _changedExteriorTerrainAt(
    Iterable<ExteriorDecorationSector?> sectors, double x, double z) {
  for (final sector in sectors) {
    if (sector != null && sector.bounds.contains(x, z)) {
      return (
        sector.id,
        sector.scene.worldHeightAt(x - sector.originX, z - sector.originZ)
      );
    }
  }
  return null;
}
