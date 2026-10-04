import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';

Future<void> main(List<String> arguments) async {
  final lifecycle = arguments.contains('--lifecycle');
  final repository = Directory.current.parent.parent;
  for (final fixture in {
    'S': 'examples/playable_runtime_host/golden_battle_slice',
    'M': 'examples/playable_runtime_host/golden_fangame_slice',
    'L': 'selbrume',
  }.entries) {
    final parent = await Directory.systemTemp.createTemp(
      'uwu-catalogue-measure-',
    );
    MapWorkspaceController? controller;
    try {
      final source = Directory('${repository.path}/${fixture.value}');
      final root = Directory('${parent.path}/project');
      await root.create();
      await for (final file in source.list(
        recursive: true,
        followLinks: false,
      )) {
        final destination =
            '${root.path}${file.path.substring(source.path.length)}';
        if (file is Directory) {
          await Directory(destination).create(recursive: true);
        } else if (file is File) {
          await File(destination).parent.create(recursive: true);
          await file.copy(destination);
        }
      }
      final session = ProjectSession(
        sessionId: root.path,
        name: fixture.key,
        directoryPath: await root.resolveSymbolicLinks(),
      );
      ProjectManifest.fromJson(
        jsonDecode(await File('${root.path}/project.json').readAsString())
            as Map<String, dynamic>,
      );
      final maps = LocalMapWorkspaceAdapter();
      final profiles = <ProjectSnapshotLoadProfile>[];
      final catalogue = LocalMapCatalogAdapter(maps, profileSink: profiles.add);
      controller = MapWorkspaceController(
        session,
        maps,
        catalogPort: catalogue,
      );
      await controller.initialize();
      if (controller.project == null || controller.error != null) {
        throw StateError(controller.error ?? 'Projet indisponible');
      }
      final project = controller.project!;
      if (lifecycle) {
        await _lifecycle(controller, fixture.key, fixture.value, profiles);
        continue;
      }
      for (var i = 0; i < 2; i++) {
        profiles.clear();
        final stopwatch = Stopwatch()..start();
        final result = await controller.mutateCatalog(
          'map.library.reorganize',
          {
            'groups': [
              ...project.groups.map((group) => group.toJson()),
              ProjectMapGroup(
                id: 'uwu-measure',
                name: 'Mesure $i',
                type: MapGroupType.special,
              ).toJson(),
            ],
            'assignments': [],
          },
        );
        stopwatch.stop();
        if (!result.integrated) {
          throw StateError(result.error ?? 'Mutation non intégrée');
        }
        stdout.writeln(
          jsonEncode({
            'fixture': fixture.key,
            'source': fixture.value,
            'maps': project.maps.length,
            'phase': i == 0 ? 'cold' : 'warm',
            'elapsedMicros': stopwatch.elapsedMicroseconds,
            'snapshotLoads': profiles.length,
            'cacheHits': profiles.where((p) => p.cacheHit).length,
            'initialReadMicros': profiles.fold(
              0,
              (sum, p) => sum + p.initialReadMicroseconds,
            ),
            'decodeMicros': profiles.fold(
              0,
              (sum, p) => sum + p.decodeModelMicroseconds,
            ),
            'identityReads': profiles.fold(
              0,
              (sum, p) => sum + p.cacheIdentityReads,
            ),
            'snapshotResources': profiles.last.resourceCount,
            'loadedMapDocuments': controller.documents.length,
          }),
        );
      }
    } on Object catch (failure) {
      stdout.writeln(
        jsonEncode({
          'fixture': fixture.key,
          'result': 'NON_VERIFIE',
          'reason': failure.toString(),
        }),
      );
      exitCode = 1;
    } finally {
      controller?.dispose();
      await parent.delete(recursive: true);
    }
  }
}

Future<void> _lifecycle(
  MapWorkspaceController controller,
  String fixture,
  String source,
  List<ProjectSnapshotLoadProfile> profiles,
) async {
  final original = controller.project!.maps.first;
  for (final phase in ['cold', 'warm']) {
    final duplication = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'duplicate.prepare',
      profiles,
      () => controller.prepareCatalog('map.duplicate', {
        'sourceMapId': original.id,
        'name': '${original.name} — copie de mesure',
      }),
    );
    _requireApplicable(duplication);
    final duplicated = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'duplicate.apply',
      profiles,
      () => controller.applyPreparedCatalog(duplication),
    );
    _requireIntegrated(duplicated);
    final copyId = duplicated.receipt!.createdMapId!;
    await controller.activate(
      controller.project!.maps.singleWhere((entry) => entry.id == copyId),
    );
    final copy = controller.active!;
    final resize = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'resize.prepare',
      profiles,
      () => controller.prepareCatalog('map.resize_apply', {
        'mapId': copyId,
        'width': copy.current.size.width + 2,
        'height': copy.current.size.height + 2,
      }),
    );
    _requireApplicable(resize);
    final resized = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'resize.apply',
      profiles,
      () => controller.applyPreparedCatalog(resize),
    );
    _requireIntegrated(resized);
    final deletion = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'delete.prepare',
      profiles,
      () => controller.prepareCatalog('map.delete_apply', {'mapId': copyId}),
    );
    _requireApplicable(deletion);
    final deleted = await _measureLifecycle(
      controller,
      fixture,
      source,
      phase,
      'delete.apply',
      profiles,
      () => controller.applyPreparedCatalog(deletion, confirmDestructive: true),
    );
    _requireIntegrated(deleted);
  }
}

void _requireApplicable(MapCatalogPreparation prepared) {
  if (!prepared.canApply) {
    throw StateError(
      prepared.issues
          .map((issue) => '${issue.code}: ${issue.message}')
          .join('; '),
    );
  }
}

void _requireIntegrated(MapCatalogResult result) {
  if (!result.integrated) {
    throw StateError(result.error ?? 'Publication non intégrée');
  }
}

Future<T> _measureLifecycle<T>(
  MapWorkspaceController controller,
  String fixture,
  String source,
  String phase,
  String operation,
  List<ProjectSnapshotLoadProfile> profiles,
  Future<T> Function() action,
) async {
  profiles.clear();
  final watch = Stopwatch()..start();
  final result = await action();
  watch.stop();
  stdout.writeln(
    jsonEncode({
      'fixture': fixture,
      'source': source,
      'maps': controller.project!.maps.length,
      'phase': phase,
      'operation': operation,
      'elapsedMicros': watch.elapsedMicroseconds,
      'snapshotLoads': profiles.length,
      'cacheHits': profiles.where((profile) => profile.cacheHit).length,
      'initialReadMicros': profiles.fold(
        0,
        (sum, profile) => sum + profile.initialReadMicroseconds,
      ),
      'decodeMicros': profiles.fold(
        0,
        (sum, profile) => sum + profile.decodeModelMicroseconds,
      ),
      'identityReads': profiles.fold(
        0,
        (sum, profile) => sum + profile.cacheIdentityReads,
      ),
      'snapshotResources': profiles.lastOrNull?.resourceCount,
      'loadedMapDocuments': controller.documents.length,
      if (result is MapCatalogPreparation) 'canApply': result.canApply,
      if (result is MapCatalogResult) ...{
        'published': result.published,
        'integrated': result.integrated,
      },
    }),
  );
  return result;
}
