import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

const _revision =
    'sha256:0000000000000000000000000000000000000000000000000000000000000002';

void main() {
  test('issue pagination keeps total and refuses a different revision',() async {
    final f=ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    final feature=f.feature;
    final map=f.map.copyWith(layers:[for(final layer in f.map.layers)
      if(layer is BorderLayer) layer.copyWith(content:BorderLayerContent(features:[
        for(var index=0;index<25;index++) BorderFeature(id:'feature-$index',name:'Feature $index',
          blueprintId:feature.blueprintId,seed:feature.seed,geometry:feature.geometry,
          overrides:const [],keepOutRegions:const []),
      ])) else layer]);
    Future<AuthoringQueryPage> query(AuthoringQueryRequest request,{String revision=_revision})=>
      queryMapHealth(request:request,readMap:(_) async =>(map:map,manifest:f.project,revision:revision));
    final first=(await query(AuthoringQueryRequest(resourceKind:'mapHealth',operation:AuthoringQueryOperation.get,
      ids:const ['map']))).items.single;
    expect(first['issueCount'],greaterThan(20));
    expect(first['issues'],hasLength(20));
    final request=AuthoringQueryRequest.fromJson(Map<String,dynamic>.from(first['nextIssueRequest'] as Map));
    final second=(await query(request)).items.single;
    expect(second['issueCount'],first['issueCount']);
    expect(second['issueOffset'],20);
    await expectLater(query(request,revision:'changed'),throwsA(isA<AuthoringQueryException>()
      .having((error)=>error.code,'code','query.cursor_stale')));
  });
  Future<Map<String, Object?>> health(ReliabilityMapVariant variant,
      {Map<String, Object?> extensions = const {}}) async {
    final content = ReliabilityMapContent.create(variant);
    var reads = 0;
    final page = await queryMapHealth(
      request: AuthoringQueryRequest(
          resourceKind: 'mapHealth',
          operation: AuthoringQueryOperation.get,
          ids: const ['map'],
          extensions: extensions),
      readMap: (mapId) async {
        reads++;
        expect(mapId, 'map');
        return (
          map: content.map,
          manifest: content.project,
          revision: _revision
        );
      },
    );
    expect(reads, 1);
    expect(page.snapshotRevision, _revision);
    return page.items.single;
  }

  test('a healthy map passes structural checks with visual not run', () async {
    final result = await health(ReliabilityMapVariant.healthy);
    expect(result['verdict'], 'pass');
    expect(result['revision'], _revision);
    expect(((result['checks'] as Map)['visual'] as Map)['status'], 'not_run');
    expect(result['issues'], isEmpty);
  });

  test('floating faces fail even though their diagnostics are warnings',
      () async {
    final result = await health(ReliabilityMapVariant.floatingCliff);
    expect(result['verdict'], 'fail');
    expect((result['issues'] as List).cast<Map>().map((issue) => issue['code']),
        contains('border.spatial.face_base_mismatch'));
  });

  test('proven interior holes fail with their location', () async {
    final result = await health(ReliabilityMapVariant.interiorHole);
    expect(result['verdict'], 'fail');
    expect((result['issues'] as List).cast<Map>().map((issue) => issue['code']),
        contains('map.ground.exposed'));
  });

  test('unexplained geometry overlaps remain incomplete', () async {
    final result = await health(ReliabilityMapVariant.dockOverlap);
    expect(result['verdict'], 'incomplete');
    expect((result['issues'] as List).cast<Map>().map((issue) => issue['code']),
        contains('map.border_object_overlap.unexplained'));
  });

  test('unsupported shapes and arbitrary extensions fail before reading',
      () async {
    for (final request in [
      AuthoringQueryRequest(
          resourceKind: 'mapHealth', operation: AuthoringQueryOperation.list),
      AuthoringQueryRequest(
          resourceKind: 'mapHealth',
          operation: AuthoringQueryOperation.get,
          ids: const ['map'],
          extensions: const {'ignoreProblems': true}),
    ]) {
      await expectLater(
          queryMapHealth(
              request: request,
              readMap: (_) async => throw StateError('must not read')),
          throwsA(isA<AuthoringQueryException>()));
    }
  });
}
