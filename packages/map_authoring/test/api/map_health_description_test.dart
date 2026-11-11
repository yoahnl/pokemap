import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

void main() {
  test('map health describes the scope enforced by list and get', () async {
    final descriptor = AuthoringResourceKindRegistry.canonical().find(
      'mapHealth',
    )!;
    final query = descriptor.extensions['query']! as Map<String, Object?>;
    expect(query['operations'], containsAll(['list', 'get']));
    expect(query['requiredFilters'], contains('mapId'));

    final content = ReliabilityMapContent.create(ReliabilityMapVariant.healthy);
    var reads = 0;
    Future<AuthoringQueryPage> run(AuthoringQueryRequest request) =>
        queryMapHealth(
          request: request,
          readMap: (id) async {
            reads++;
            expect(id, content.map.id);
            return (
              map: content.map,
              manifest: content.project,
              revision:
                  'sha256:0000000000000000000000000000000000000000000000000000000000000002',
            );
          },
        );

    final listed = await run(
      AuthoringQueryRequest(
        resourceKind: 'mapHealth',
        operation: AuthoringQueryOperation.list,
        filters: {'mapId': content.map.id},
      ),
    );
    final fetched = await run(
      AuthoringQueryRequest(
        resourceKind: 'mapHealth',
        operation: AuthoringQueryOperation.get,
        ids: [content.map.id],
      ),
    );
    expect(listed.items.single['mapId'], content.map.id);
    expect(fetched.items.single['mapId'], content.map.id);
    expect(reads, 2);

    await expectLater(
      run(
        AuthoringQueryRequest(
          resourceKind: 'mapHealth',
          operation: AuthoringQueryOperation.list,
        ),
      ),
      throwsA(
        isA<AuthoringQueryException>().having(
          (error) => error.code,
          'code',
          'query.map_health_unsupported',
        ),
      ),
    );
    expect(reads, 2);
  });
}
