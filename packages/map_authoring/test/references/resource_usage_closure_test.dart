import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';
import 'resource_usage_projection_test.dart' show noPokemon, planche;

void main() {
  test('typed dependency closure terminates cycles without unrelated matches',
      () {
    CinematicMediaAsset media(String id, String source,
            {String path = 'images/other.png'}) =>
        CinematicMediaAsset(
          id: id,
          label: id,
          kind: CinematicMediaAssetKind.cinematicFx,
          relativePath: path,
          metadata: {'mediaAssetId': source},
        );
    final scene = SceneAsset(
      id: 'intro',
      name: 'Introduction',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
      ], edges: const []),
      metadata: const {'mediaAssetId': 'third'},
    );
    final snapshot = catalogSnapshot([],
        project: ProjectManifest(
          name: 'Fixture',
          maps: [],
          pokemon: noPokemon,
          tilesets: [planche],
          scenes: [scene],
          cinematicMediaAssets: [
            media('first', 'second', path: planche.relativePath),
            media('second', 'first'),
            media('third', 'second'),
            for (var index = 0; index < 200; index++)
              CinematicMediaAsset(
                id: 'unrelated-$index',
                label: 'first',
                kind: CinematicMediaAssetKind.cinematicFx,
                relativePath: 'images/other.png',
                metadata: const {'description': 'second', 'path': 'first'},
              ),
          ],
        ));
    final report = const ResourceUsageProjection().analyze(
        snapshot, ResourceUsageTarget(family: 'images', id: planche.id));
    expect(report.complete, isTrue, reason: report.coverageIssues.toString());
    expect(report.entries, hasLength(6));
    expect(report.entries.any((entry) => entry.ownerId.startsWith('unrelated')),
        isFalse);
    final first = report.entries.where((entry) => entry.ownerId == 'first');
    expect(
        first.map((entry) => entry.relation),
        containsAll(
            [ResourceUsageRelation.direct, ResourceUsageRelation.indirect]));
    final placed =
        report.entries.singleWhere((entry) => entry.ownerKind == 'scene');
    expect(placed.relation, ResourceUsageRelation.indirect);
    expect(placed.ownerId, 'intro');
    expect(
        report.entries
            .map((entry) =>
                '${entry.ownerKind}:${entry.ownerId}:${entry.location}')
            .toSet(),
        hasLength(report.entries.length));
  });
}
