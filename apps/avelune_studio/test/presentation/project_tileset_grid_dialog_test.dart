import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_tileset_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import 'project_tileset_workshop_fixture.dart';

void main() {
  testWidgets('previews a grid before saving and rereads the durable result', (
    tester,
  ) async {
    const before = ProjectRegularAtlasTilesetSource(
      assetId: 'atlas-asset',
      pixelWidth: 64,
      pixelHeight: 64,
      tileWidth: 32,
      tileHeight: 32,
    );
    const after = ProjectRegularAtlasTilesetSource(
      assetId: 'atlas-asset',
      pixelWidth: 64,
      pixelHeight: 64,
      tileWidth: 16,
      tileHeight: 16,
    );
    var source = before;
    final visuals = TilesetWorkshopTestVisuals();
    final reads = <String>[];
    final saves = <Object>[];
    await pumpTilesetWorkshop(
      tester,
      before,
      visuals: visuals,
      reads: reads,
      cardName: 'Planche renommée',
      readSource: () => source,
      gridEditor: (
        revision: 'before',
        prepareCatalog: () async => 'prepared',
        pendingReceipt: null,
        onPendingReceiptChanged: (_) {},
        save: (size, revision) async {
          saves.add((size, revision));
          source = after;
          return _gridReceipt();
        },
        reconcile: (receipt) async => receipt,
      ),
    );
    expect(find.text('Planche renommée'), findsOneWidget);
    expect(find.text('Planche du jardin'), findsNothing);
    await _editGrid(tester);
    expect(visuals.last.gridOverride, after);
    expect(saves, isEmpty);
    expect(reads, ['tileset:atlas']);

    final widthField = find.byKey(const ValueKey('tileset-grid-width'));
    await tester.enterText(widthField, '');
    await tester.pumpAndSettle();
    expect(visuals.last.gridOverride, before);
    expect(
      find.bySemanticsLabel('Aperçu du découpage enregistré'),
      findsOneWidget,
    );
    await tester.tap(find.text('Enregistrer'));
    expect(saves, isEmpty);
    await tester.enterText(widthField, '16');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saves, [((width: 16, height: 16), 'before')]);
    expect(find.text('16 × 16 px'), findsOneWidget);
    expect(find.text('Découpage enregistré.'), findsOneWidget);
    expect(reads, ['tileset:atlas', 'tileset:atlas']);
  });

  testWidgets('keeps a refused draft and rereads an already written grid', (
    tester,
  ) async {
    const source = ProjectRegularAtlasTilesetSource(
      assetId: 'atlas-asset',
      pixelWidth: 64,
      pixelHeight: 64,
      tileWidth: 32,
      tileHeight: 32,
    );
    var saves = 0;
    final reconciled = <ResourceMutationReceipt>[];
    final pendingChanges = <ResourceMutationReceipt?>[];
    final receipt = _gridReceipt();
    ProjectTilesetGridEditor editor({ResourceMutationReceipt? pending}) => (
      revision: 'before',
      prepareCatalog: () async => 'prepared',
      pendingReceipt: pending,
      onPendingReceiptChanged: pendingChanges.add,
      save: (_, _) async {
        if (++saves == 1) {
          throw const ResourceFailure(
            'Cette planche est utilisée sur une carte.',
          );
        }
        throw ResourceFailure(
          'La grille est enregistrée.',
          partialReceipt: receipt,
        );
      },
      reconcile: (pending) async {
        reconciled.add(pending);
        return pending;
      },
    );
    await pumpTilesetWorkshop(
      tester,
      source,
      visuals: TilesetWorkshopTestVisuals(),
      gridEditor: editor(),
    );
    await _editGrid(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cette planche est utilisée sur une carte.'),
      findsOneWidget,
    );
    expect(find.text('4 colonnes × 4 lignes'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(pendingChanges, [receipt]);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(pendingChanges, [receipt]);
    await pumpTilesetWorkshop(
      tester,
      source,
      visuals: TilesetWorkshopTestVisuals(),
      gridEditor: editor(pending: pendingChanges.single),
    );
    await tester.tap(find.text('Modifier le découpage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relire la planche'));
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(reconciled, [receipt]);
    expect(pendingChanges, [receipt, null]);
    expect(find.text('Découpage enregistré.'), findsOneWidget);
  });

  testWidgets('prepares the proof explicitly and keeps the new tile sizes', (
    tester,
  ) async {
    const source = ProjectRegularAtlasTilesetSource(
      assetId: 'atlas-asset',
      pixelWidth: 64,
      pixelHeight: 64,
      tileWidth: 32,
      tileHeight: 32,
    );
    final attempts = <String>[];
    var preparations = 0;
    await pumpTilesetWorkshop(
      tester,
      source,
      visuals: TilesetWorkshopTestVisuals(),
      gridEditor: (
        revision: 'before',
        pendingReceipt: null,
        onPendingReceiptChanged: (_) {},
        prepareCatalog: () async {
          preparations++;
          return 'prepared';
        },
        save: (size, revision) async {
          attempts.add(revision);
          expect(size, (width: 16, height: 16));
          if (revision == 'before') {
            throw const ProjectLibraryNeedsPreparation();
          }
          return _gridReceipt();
        },
        reconcile: (receipt) async => receipt,
      ),
    );
    await _editGrid(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(preparations, 0);
    await tester.tap(find.text('Préparer l’index des usages'));
    await tester.pumpAndSettle();
    expect(preparations, 1);
    expect(attempts, ['before']);
    expect(find.text('4 colonnes × 4 lignes'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(attempts, ['before', 'prepared']);
  });
}

Future<void> _editGrid(WidgetTester tester) async {
  final edit = find.text('Modifier le découpage');
  await tester.ensureVisible(edit);
  await tester.pumpAndSettle();
  await tester.tap(edit);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('tileset-grid-width')),
    '16',
  );
  await tester.enterText(
    find.byKey(const ValueKey('tileset-grid-height')),
    '16',
  );
  await tester.pumpAndSettle();
}

ResourceMutationReceipt _gridReceipt() => const ResourceMutationReceipt(
  before: workspaceProject,
  manifest: workspaceProject,
  beforeRevision: 'before',
  revision: 'after',
  changedPaths: ['catalog/HEAD.json'],
);
