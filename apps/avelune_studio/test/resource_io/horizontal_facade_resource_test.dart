import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/features/resources/border_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';

import '../support/uwu_resource_host.dart';
import '../support/m2_ui_fixture.dart';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  testWidgets('Studio offers the facade mode and removes the angle family', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    final pane = find.byType(ResourceWorkspacePane);
    final dialog = showDialog<bool>(
      context: tester.element(pane),
      builder: (_) => BorderCreationDialog(
        navigation: host.navigation,
        project: host.navigation.workspace.project!,
        visuals: host.navigation.visuals,
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('border-horizontal-facade'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Façades sur des tracés ouverts horizontaux'),
      findsOneWidget,
    );
    expect(find.text('Angle'), findsNothing);
    expect(find.textContaining('0 / 2 familles'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('border-name')),
      'Façade du hall',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer le brouillon'));
    await pumpIo(tester, frames: 30);
    final saved = await tester.runAsync(
      () => host.fixture.port.loadProject(host.fixture.session),
    );
    expect(
      saved!.borderCatalog.records.single.draft.definition.template,
      BorderBlueprintTemplate.horizontalFacade,
    );
    expect(find.byType(BorderCreationDialog), findsNothing);
    expect(await dialog, isTrue);
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
