import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'canonical_json.dart';
import 'game_package_format_exception.dart';

final class GamePackageExteriorDecorationValidation {
  const GamePackageExteriorDecorationValidation(
      {this.visualMaps = const [],
      this.animatedModels = false,
      this.modelShadows = false,
      this.pointLights = false,
      this.modelClips = false});
  final List<MapData> visualMaps;
  final bool animatedModels, modelShadows, pointLights, modelClips;
}

final class GamePackageExteriorDecorationValidator {
  const GamePackageExteriorDecorationValidator();

  GamePackageExteriorDecorationValidation validate({
    required ProjectManifest project,
    required Iterable<String> payloadPaths,
    required List<int>? Function(String) readPayload,
    required Iterable<String> requiredCapabilities,
  }) {
    final paths = payloadPaths.toSet();
    final playablePaths =
        project.maps.map((entry) => 'project/${entry.relativePath}').toSet();
    final definitions = paths
        .where((path) =>
            path.startsWith('project/maps/') &&
            path.endsWith('.decoration.json') &&
            !playablePaths.contains(path))
        .toSet();
    final sectors = paths
        .where((path) =>
            path.startsWith('project/maps/') &&
            path.contains('.decoration/') &&
            !playablePaths.contains(path))
        .toSet();
    final declared =
        requiredCapabilities.contains(MapExteriorDecoration.capabilityId);
    if (definitions.isEmpty && sectors.isEmpty && !declared) {
      return const GamePackageExteriorDecorationValidation();
    }
    if (!declared ||
        definitions.isEmpty ||
        project.settings.dimension != ProjectDimension.threeD) {
      _fail('project/project.json',
          'Exterior decoration requires a 3D project and ${MapExteriorDecoration.capabilityId}.');
    }
    final consumed = <String>{};
    final visuals = <MapData>[];
    var animatedModels = false,
        modelShadows = false,
        pointLights = false,
        modelClips = false;
    final models = {for (final model in project.models3d) model.id: model};
    final maps = {
      for (final entry in project.maps)
        'project/maps/${entry.id}.decoration.json': entry
    };
    for (final path in definitions) {
      try {
        final entry = maps[path];
        if (entry == null) {
          throw const FormatException(
              'Exterior decoration owner map is missing.');
        }
        final raw = _object(_read(readPayload, path, 131072));
        if ((raw.length != 3 && raw.length != 4) ||
            raw.keys.any((key) => !{
                  'schemaVersion',
                  'definition',
                  'sectors',
                  'borders'
                }.contains(key)) ||
            raw['schemaVersion'] is! int ||
            raw['schemaVersion'] != 1 ||
            !raw.keys
                .toSet()
                .containsAll({'schemaVersion', 'definition', 'sectors'})) {
          throw const FormatException(
              'Unsupported exterior decoration storage definition.');
        }
        final definition = MapExteriorDecoration.fromJson(
            Map<String, dynamic>.from(raw['definition'] as Map));
        if (definition.sectors.isNotEmpty || definition.borders.isNotEmpty) {
          throw const FormatException(
              'Exterior sector storage must remain independent.');
        }
        final playable = MapData.fromJson(_object(
            _read(readPayload, 'project/${entry.relativePath}', 16777216)));
        definition.validateForMap(playable);
        final summaries = raw['sectors'] as List;
        if (summaries.length > MapExteriorDecoration.maxSectors) {
          throw const FormatException('Exterior sector quota exceeded.');
        }
        final loaded = <ExteriorDecorationSector>[];
        for (final value in summaries) {
          final summary = Map<String, dynamic>.from(value as Map);
          final id = summary['id'];
          if (id is! String ||
              !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
            throw const FormatException(
                'Unsafe exterior decoration sector identity.');
          }
          final relative = 'maps/${entry.id}.decoration/$id.json';
          final sectorPath = 'project/$relative';
          if (!sectors.contains(sectorPath) || !consumed.add(sectorPath)) {
            throw const FormatException(
                'Required exterior sector is missing or duplicated.');
          }
          final bytes = _read(readPayload, sectorPath, 2097152);
          final revision = computeNarrativeProjectFingerprint([
            NarrativeProjectFingerprintEntry(
                relativePath: relative, bytes: bytes),
          ]);
          final sector = ExteriorDecorationSector.fromJson(_object(bytes));
          final expected = <String, dynamic>{
            'id': sector.id,
            'originX': sector.originX,
            'originZ': sector.originZ,
            'width': sector.scene.width,
            'depth': sector.scene.depth,
            'instances': sector.scene.instances.length,
            'revision': revision,
            'resourceIds': sector.resourceReferenceIds.toList()..sort(),
          };
          if (['originX', 'originZ', 'width', 'depth', 'instances']
                  .any((key) => summary[key] is! int) ||
              CanonicalJson.encode(summary) != CanonicalJson.encode(expected)) {
            throw const FormatException(
                'Exterior sector integrity or summary mismatch.');
          }
          loaded.add(sector);
          final visual = sector
              .asVisualMap()
              .copyWith(id: 'exterior:${entry.id}:${sector.id}');
          MapValidator.validate(visual, projectDialogueContext: project);
          visuals.add(visual);
        }
        final loadedBorders = <ExteriorDecorationBorder>[];
        final borderSummaries =
            raw.containsKey('borders') ? raw['borders'] as List : const [];
        if (borderSummaries.length > MapExteriorDecoration.maxBorders) {
          throw const FormatException(
              'Logical exterior Border quota exceeded.');
        }
        for (final value in borderSummaries) {
          final summary = Map<String, dynamic>.from(value as Map);
          final id = summary['id'];
          if (id is! String ||
              !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
            throw const FormatException(
                'Unsafe logical exterior Border identity.');
          }
          final relative = 'maps/${entry.id}.decoration/borders/$id.json';
          final borderPath = 'project/$relative';
          if (!sectors.contains(borderPath) || !consumed.add(borderPath)) {
            throw const FormatException(
                'Required logical exterior Border is missing or duplicated.');
          }
          final bytes = _read(readPayload, borderPath, 8388608);
          final border = ExteriorDecorationBorder.fromJson(_object(bytes));
          final expected = {
            'id': border.id,
            'originX': border.originX,
            'originZ': border.originZ,
            'width': border.width,
            'depth': border.depth,
            'instances': border.instances.length,
            'resourceIds': border.resourceReferenceIds.toList()..sort(),
            'revision': computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                  relativePath: relative, bytes: bytes),
            ]),
          };
          if (['originX', 'originZ', 'width', 'depth', 'instances']
                  .any((key) => summary[key] is! int) ||
              CanonicalJson.encode(summary) != CanonicalJson.encode(expected)) {
            throw const FormatException(
                'Logical exterior Border integrity or summary mismatch.');
          }
          loadedBorders.add(border);
        }
        final decoration = MapExteriorDecoration(
            mapId: definition.mapId,
            playableWidth: definition.playableWidth,
            playableDepth: definition.playableDepth,
            west: definition.west,
            east: definition.east,
            north: definition.north,
            south: definition.south,
            sectors: loaded,
            borders: loadedBorders);
        for (final border in loadedBorders) {
          final resolved = resolveExteriorDecorationBorder(
              manifest: project,
              decoration: decoration,
              border: border,
              playableMap: playable);
          if (!resolved.result.canApply ||
              resolved.result.materialization !=
                  border.feature.materialization ||
              CanonicalJson.encode(resolved.modelInstances
                      .map((instance) => instance.toJson())
                      .toList()) !=
                  CanonicalJson.encode(border.instances
                      .map((instance) => instance.toJson())
                      .toList())) {
            throw const FormatException(
                'Logical exterior Border materialization is missing, stale or incompatible.');
          }
          for (final instance in border.instances) {
            final model = models[instance.modelId];
            if (model == null) {
              throw const FormatException(
                  'Missing logical exterior Border model.');
            }
            animatedModels |= instance.animationIndex != null;
            modelClips |= instance.clip != null;
            modelShadows |= instance.effectiveCastsShadows(model);
            pointLights |= model.light != null && model.light!.intensity > 0;
          }
        }
      } on Object catch (error) {
        _fail(path, 'Invalid exterior decoration: $error');
      }
    }
    if (consumed.length != sectors.length) {
      _fail('project/maps',
          'Unreferenced exterior decoration sectors are forbidden.');
    }
    return GamePackageExteriorDecorationValidation(
        visualMaps: List.unmodifiable(visuals),
        animatedModels: animatedModels,
        modelClips: modelClips,
        modelShadows: modelShadows,
        pointLights: pointLights);
  }

  List<int> _read(List<int>? Function(String) read, String path, int maxBytes) {
    final bytes = read(path);
    if (bytes == null || bytes.length > maxBytes) {
      throw FormatException('Missing or oversized exterior resource: $path.');
    }
    return bytes;
  }

  Map<String, dynamic> _object(List<int> bytes) {
    final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Exterior resources require JSON objects.');
    }
    return raw;
  }

  Never _fail(String path, String message) => throw GamePackageFormatException(
        code: 'exteriorDecorationInvalid',
        path: path,
        message: message,
      );
}
