import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  test('empty border pattern is saved as draft without publication', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final receipt = await fixture.resources.createBorder(
      const BorderCreationRequest(name: 'Bordure en cours', publish: false),
    );
    final reader = LocalMapWorkspaceAdapter();
    final reopened = await reader.loadProject(fixture.session);
    expect(
      reopened.borderCatalog.records.single.id,
      receipt.manifest.borderCatalog.records.single.id,
    );
    expect(
      reopened.borderCatalog.records.single.draft.definition.primitives,
      isEmpty,
    );
    expect(reopened.borderCatalog.records.single.latestPublished, isNull);
  });

  test('failed publication keeps one resumable border draft', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final tilesetId = imported.createdTilesetId!;
    for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
      await fixture.resources.saveElement(
        fixture
            .element(tilesetId, id: id)
            .copyWith(
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
      );
    }

    ResourceFailure? failure;
    try {
      await fixture.resources.createBorder(
        const BorderCreationRequest(
          name: 'Clôture du jardin',
          capElementId: 'cap',
          straightElementId: 'straight',
          cornerElementId: 'corner',
          acceptedWarningCodes: ['warning_inexistant'],
        ),
      );
    } on ResourceFailure catch (error) {
      failure = error;
    }
    expect(failure, isNotNull);
    expect(failure!.partialReceipt, isNotNull);
    final draft = await LocalMapWorkspaceAdapter().loadProject(fixture.session);
    expect(draft.borderCatalog.records, hasLength(1));
    expect(draft.borderCatalog.records.single.latestPublished, isNull);

    final receipt = await fixture.resources.createBorder(
      BorderCreationRequest(
        name: 'Clôture du jardin',
        capElementId: 'cap',
        straightElementId: 'straight',
        cornerElementId: 'corner',
        blueprintId: failure.borderId,
      ),
    );
    expect(receipt.manifest.borderCatalog.records, hasLength(1));
    expect(
      receipt.manifest.borderCatalog.records.single.latestPublished,
      isNotNull,
    );
    expect(receipt.manifest.borderCatalog.records.single.id, failure.borderId);

    final edited = await fixture.resources.createBorder(
      BorderCreationRequest(
        name: 'Clôture du jardin révisée',
        capElementId: 'cap',
        straightElementId: 'straight',
        cornerElementId: 'corner',
        blueprintId: failure.borderId,
      ),
    );
    final record = edited.manifest.borderCatalog.records.single;
    expect(record.id, failure.borderId);
    expect(record.latestPublished!.revision, 2);
    expect(
      record.latestPublished!.definition.name,
      'Clôture du jardin révisée',
    );
  });
}
