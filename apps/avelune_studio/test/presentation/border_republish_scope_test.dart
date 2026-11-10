import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/border_creation_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

EditableMapDocument _traced(String mapId, String name, String borderId) =>
    EditableMapDocument(
      MapWorkspaceDocument(
        mapId: mapId,
        revision: 'r1',
        map: workspaceMap(mapId).copyWith(
          name: name,
          layers: [
            BorderLayer(
              id: '$mapId-border',
              name: 'Falaises',
              content: BorderLayerContent(
                features: [
                  for (final index in [0, 1])
                    BorderFeature(
                      id: '$mapId-feature-$index',
                      name: 'Falaise $index',
                      blueprintId: borderId,
                      seed: BorderSignedInt64.zero,
                      geometry: BorderRegionGeometry(
                        width: 1,
                        height: 1,
                        cells: [true],
                      ),
                      overrides: const [],
                      keepOutRegions: const [],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

void main() {
  test(
    'republishing a border traced on an open map requires a scope review',
    () async {
      final project = spatialBorderProject();
      final record = project.borderCatalog.records.single;
      var accepted = false;
      final scopes = <Map<String, int>>[];
      final host = BorderCreationOwnerFixture(
        project: project,
        initialRecord: record,
        confirmRepublication: (scope) async {
          scopes.add(scope);
          return accepted;
        },
      );
      host.workspace.documents['route'] = _traced(
        'route',
        'Route 30',
        record.id,
      );
      expect(await host.workflow.save(publish: true), isFalse);
      expect(scopes, [
        {'Route 30': 2},
      ]);
      expect(host.port.requests, isEmpty);
      accepted = true;
      expect(await host.workflow.save(publish: true), isFalse);
      expect(scopes, [
        {'Route 30': 2},
        {'Route 30': 2},
      ]);
      expect(host.port.requests.single.publish, isTrue);
      expect(host.port.requests.single.blueprintId, record.id);
    },
  );

  test('an untraced border republishes without a scope review', () async {
    final project = spatialBorderProject();
    var confirmations = 0;
    final host = BorderCreationOwnerFixture(
      project: project,
      initialRecord: project.borderCatalog.records.single,
      confirmRepublication: (_) async {
        confirmations++;
        return false;
      },
    );
    expect(await host.workflow.save(publish: true), isFalse);
    expect(confirmations, 0);
    expect(host.port.requests, hasLength(1));
  });
}
