import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// BETA-BAT-034, lot 2 — le défaut de projet des transitions de combat.
///
/// `ProjectManifest.battleTransitions` existait depuis BETA-BAT-019 et
/// n'avait AUCUN producteur : le runtime le lisait, personne ne l'écrivait.
/// Sans lui, changer la transition de tous les combats demandait de passer
/// calque par calque et dresseur par dresseur.
void main() {
  group('project.battle_transitions.update', () {
    test('écrit les deux défauts du projet', () async {
      final harness = await _Harness.create('set');
      addTearDown(harness.dispose);

      await harness.update(
        suffix: 'set',
        parameters: <String, Object?>{
          'wildTransitionId': 'dpp_wild',
          'trainerTransitionId': 'hgss_trainer',
        },
      );

      final config = await harness.battleTransitions();
      expect(config?.wildTransitionId, 'dpp_wild');
      expect(config?.trainerTransitionId, 'hgss_trainer');
    });

    test('laisse intact un côté dont on ne parle pas', () async {
      final harness = await _Harness.create('partial');
      addTearDown(harness.dispose);

      await harness.update(
        suffix: 'partial-a',
        parameters: <String, Object?>{'wildTransitionId': 'rs_wild'},
      );
      await harness.update(
        suffix: 'partial-b',
        parameters: <String, Object?>{'trainerTransitionId': 'rby_trainer'},
      );

      final config = await harness.battleTransitions();
      expect(
        config?.wildTransitionId,
        'rs_wild',
        reason: 'régler le dresseur ne doit pas effacer le sauvage',
      );
      expect(config?.trainerTransitionId, 'rby_trainer');
    });

    test('une chaîne vide rend la main au défaut moteur', () async {
      final harness = await _Harness.create('clear');
      addTearDown(harness.dispose);

      await harness.update(
        suffix: 'clear-set',
        parameters: <String, Object?>{
          'wildTransitionId': 'gold_wild',
          'trainerTransitionId': 'rs_trainer',
        },
      );
      await harness.update(
        suffix: 'clear-both',
        parameters: <String, Object?>{
          'wildTransitionId': '',
          'trainerTransitionId': '',
        },
      );

      expect(
        await harness.battleTransitions(),
        isNull,
        reason: 'tout vide retire la section au lieu d’écrire des nulls',
      );
    });

    test('refuse un identifiant inconnu', () async {
      final harness = await _Harness.create('unknown');
      addTearDown(harness.dispose);

      await expectLater(
        harness.update(
          suffix: 'unknown',
          parameters: <String, Object?>{'wildTransitionId': 'nawak'},
        ),
        throwsA(anything),
      );
      expect(await harness.battleTransitions(), isNull);
    });

    test('refuse une transition de dresseur du côté sauvage', () async {
      // Les deux listes du contrat partagé sont distinctes : `dpp_trainer`
      // est valide, mais pas pour une rencontre sauvage. Sans ce test, le
      // seul garde-fou serait « l'id existe quelque part ».
      final harness = await _Harness.create('side');
      addTearDown(harness.dispose);

      await expectLater(
        harness.update(
          suffix: 'side',
          parameters: <String, Object?>{'wildTransitionId': 'dpp_trainer'},
        ),
        throwsA(anything),
      );
    });
  });
}

final class _Harness {
  _Harness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'battle-transition-default-$suffix-',
    );
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(_manifest().toJson()),
    );
    await File('${root.path}/maps/route.json').writeAsString(
      jsonEncode(_map().toJson()),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    return _Harness(
      root: root,
      readApi: AuthoringReadApi(
        openService: ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
        ),
        snapshotLoader: snapshots,
      ),
      mutations: LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      ),
      snapshots: snapshots,
    );
  }

  Future<void> update({
    required String suffix,
    required Map<String, Object?> parameters,
  }) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      AuthoringRequest(
        requestId: 'battle-transition-default-$suffix',
        actionId: 'project.battle_transitions.update',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'battle-transition-default-$suffix',
        dryRun: false,
      ),
    );
    await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'battle-transition-default-$suffix',
    );
  }

  Future<ProjectBattleTransitionConfig?> battleTransitions() async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    return manifest.battleTransitions;
  }

  Future<void> dispose() async {
    await root.delete(recursive: true);
  }
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Battle transition default fixture',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'tiles-asset',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
  );
}

MapData _map() {
  return const MapData(
    id: 'route',
    name: 'Route',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[],
  );
}
