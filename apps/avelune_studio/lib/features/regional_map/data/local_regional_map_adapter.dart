import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../domain/regional_map_port.dart';

final class LocalRegionalMapAdapter
    implements RegionalMapPort, RegionalMapDetailsPort {
  const LocalRegionalMapAdapter({
    required this.session,
    required this.mapAdapter,
    this.reader = const LocalProjectFileReader(),
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;

  @override
  Future<RegionalMapSource> load() =>
      LocalWorkshopReader(session, reader: reader).read(
        metadataFields: {'maps', 'regionalMap'},
        operation: (project, access, revision) async {
          final probe = await access.probeResource(assetCatalogStorageKey);
          final assets = probe.status == ProjectResourceProbeStatus.missing
              ? AssetCatalog(records: [])
              : AssetCatalog.fromJson(
                  jsonDecode(
                    utf8.decode(await access.readBytes(assetCatalogStorageKey)),
                  ) as Map<String, dynamic>,
                );
          return RegionalMapSource(
            project: project,
            revision: revision,
            maps: const {},
            images: {
              for (final asset in assets.records)
                if (const {
                  'image/png',
                  'image/jpeg',
                  'image/webp',
                  'image/gif',
                }.contains(asset.artifact.mediaType))
                  asset.logicalPath: asset.logicalPath.split('/').last,
            },
          );
        },
      );

  @override
  Future<MapData> readMap({
    required RegionalMapSource source,
    required String mapId,
  }) => LocalWorkshopReader(session, reader: reader).read(
    metadataFields: {'maps', 'regionalMap'},
    operation: (project, access, revision) async {
      if (source.revision != revision) {
        throw const NarrativeCatalogFailure(
          'Le projet a changé. Rechargez la carte régionale.',
        );
      }
      final entry = project.maps
          .where((entry) => entry.id == mapId)
          .firstOrNull;
      if (entry == null) {
        throw const NarrativeCatalogFailure(
          'Cette carte ne figure plus dans le projet.',
        );
      }
      final map = MapData.fromJson(
        jsonDecode(utf8.decode(await access.readBytes(entry.relativePath)))
            as Map<String, dynamic>,
      );
      if (map.id != mapId) {
        throw const FormatException('regional_map: map identity mismatch');
      }
      return map;
    },
  );

  @override
  Future<Uint8List?> readImage(String path) async {
    final bytes = await reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: assetCatalogStorageKey,
    );
    final assets = AssetCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
    );
    final asset = assets.findByLogicalPath(path);
    if (asset == null ||
        !const {
          'image/png',
          'image/jpeg',
          'image/webp',
          'image/gif',
        }.contains(asset.artifact.mediaType)) {
      return null;
    }
    return Uint8List.fromList(
      await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: assetBlobStorageKey(asset.artifact),
      ),
    );
  }

  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    final expectedMaps = {...base.maps};
    final pointValue = parameters['poi'];
    if (pointValue is Map) {
      final point = ProjectRegionPointOfInterest.fromJson(
        Map<String, dynamic>.from(pointValue),
      );
      for (final id in {
        if (point.destination != null) point.destination!.mapId,
      }) {
        expectedMaps[id] ??= await readMap(source: base, mapId: id);
      }
    }
    await LocalNarrativeCatalogTransaction(
      session: session,
      mapAdapter: mapAdapter,
    ).run(
      actionId: actionId,
      parameters: (project) {
        if (project.regionalMap != base.project.regionalMap) {
          throw const NarrativeCatalogFailure(
            'Le projet a changé. Rechargez le catalogue après avoir conservé votre brouillon.',
          );
        }
        return parameters;
      },
      validate: (project, maps) {
        final pointJson = parameters['poi'];
        if (pointJson is! Map) return;
        final point = ProjectRegionPointOfInterest.fromJson(
          Map<String, dynamic>.from(pointJson),
        );
        final ids = {if (point.destination != null) point.destination!.mapId};
        for (final id in ids) {
          final actual = maps.where((map) => map.id == id).toList();
          if (actual.length != 1 || actual.single != expectedMaps[id]) {
            throw const NarrativeCatalogFailure(
              'Une carte ou son arrivée a changé. Rechargez le catalogue avant de publier.',
            );
          }
        }
      },
    );
    final after = await load();
    return RegionalMapSource(
      project: after.project,
      revision: after.revision,
      maps: expectedMaps,
      images: after.images,
    );
  }
}
