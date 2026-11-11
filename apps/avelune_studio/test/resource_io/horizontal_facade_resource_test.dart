import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/resource_replacement_fixture.dart';
import 'resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('facade drafts exclude the corner family and save through the canonical writer', () async {
    final host = await ResourceReplacementFixture.create();
    final mapBefore = await host.fixture.mapFile.readAsBytes();
    final draft =
        BorderCreationDraft(
            project: host.workspace.project!,
            unavailableResourceIds: () => const {},
          )
          ..horizontalFacade = true
          ..name = 'Façade du hall';
    final workflow = BorderCreationWorkflow(
      navigation: host.navigation,
      draft: draft,
      isActive: () => true,
      confirmDiscard: () async => false,
      confirmRepublication: (_) async => true,
    );
    addTearDown(workflow.dispose);
    expect(draft.roles, ['lineStraight', 'lineCap']);
    expect(draft.roles, isNot(contains('lineCorner')));
    expect(draft.complete, isFalse);
    expect(await workflow.save(publish: true), isFalse);
    expect((await host.reopen()).borderCatalog.records, isEmpty);
    expect(await workflow.save(publish: false), isTrue, reason: draft.error);
    final saved = await host.reopen();
    expect(
      saved.borderCatalog.records.single.draft.definition.template,
      BorderBlueprintTemplate.horizontalFacade,
    );
    expect(
      saved.borderCatalog.records.single.draft.definition.name,
      'Façade du hall',
    );
    expect(saved.borderCatalog.records.single.latestPublished, isNull);
    expect(await host.fixture.mapFile.readAsBytes(), mapBefore);
  });

  test(
    'Studio creates publishes and reopens a horizontal facade without a corner',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final mapBefore = await fixture.mapFile.readAsBytes();
      final imported = await fixture.import(tileWidth: 32);
      for (final (id, x) in [('cap', 0), ('straight', 1)]) {
        await fixture.resources.saveElement(
          fixture
              .element(imported.createdTilesetId!, id: id)
              .copyWith(
                frames: [
                  TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
                ],
              ),
        );
      }
      final result = await fixture.resources.createBorder(
        const BorderCreationRequest(
          name: 'Réception',
          template: BorderBlueprintTemplate.horizontalFacade,
          capElementId: 'cap',
          straightElementId: 'straight',
        ),
      );
      final record = result.manifest.borderCatalog.records.single;
      expect(result.manifest.borderCatalog.formatVersion, 11);
      expect(
        record.latestPublished!.definition.template,
        BorderBlueprintTemplate.horizontalFacade,
      );
      expect(
        record.draft.definition.primitives.map((p) => p.role),
        unorderedEquals([
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
        ]),
      );
      for (final primitive in record.draft.definition.primitives) {
        expect(primitive.transforms.allowedQuarterTurns, [0]);
        expect(primitive.transforms.allowFlipX, isFalse);
      }
      final renamed = await fixture.resources.createBorder(
        BorderCreationRequest(
          name: 'Réception renommée',
          blueprintId: record.id,
          expectedRecord: record,
          capElementId: 'cap',
          straightElementId: 'straight',
        ),
      );
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(
        reopened.borderCatalog.records,
        renamed.manifest.borderCatalog.records,
      );
      expect(
        reopened.borderCatalog.records.single.draft.definition.primitives,
        record.draft.definition.primitives,
      );
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
    },
  );
}
