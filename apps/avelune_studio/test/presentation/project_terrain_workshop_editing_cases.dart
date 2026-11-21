part of 'project_terrain_workshop_test.dart';

void _editingTests() {
  testWidgets('previews a new center tile and publishes it once', (
    tester,
  ) async {
    var project = _rasterProject();
    final initial = project.smartTileCatalog.presets.single;
    final submissions = <ProjectSmartTilePreset>[];
    final revisions = <String>[];
    final visuals = _TerrainVisuals();
    await _pumpWorkshop(
      tester,
      ProjectResourcePreviews((_) async => project),
      visuals: visuals,
      editor: (
        revision: 'initial',
        pendingReceipt: null,
        onPendingReceiptChanged: (_) {},
        reconcile: (_) async {},
        publish: (preset, revision) async {
          final before = project;
          submissions.add(preset);
          revisions.add(revision);
          project = project.copyWith(
            smartTileCatalog: ProjectSmartTileCatalog(
              atlases: project.smartTileCatalog.atlases,
              materials: project.smartTileCatalog.materials,
              presets: [preset],
            ),
          );
          return ResourceMutationReceipt(
            before: before,
            manifest: project,
            beforeRevision: revision,
            revision: 'saved',
            changedPaths: const ['catalog/HEAD.json'],
            changedTerrain: preset,
          );
        },
      ),
    );

    await tester.tap(find.text('Modifier les raccords'));
    await tester.pumpAndSettle();
    expect(find.text('Centre'), findsOneWidget);
    final atlasCell = find.text('Ligne 4 · colonne 2');
    await tester.scrollUntilVisible(
      atlasCell,
      96,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(atlasCell.hitTestable(), findsOneWidget);
    visuals.tiles.clear();
    await tester.tap(atlasCell);
    await tester.pumpAndSettle();

    expect(
      visuals.tiles.map((tile) => tile.localTileId),
      containsAllInOrder([6, 14, 12, 7, 13, 13, 3, 11, 9]),
    );
    expect(submissions, isEmpty);
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(revisions, ['initial']);
    final updated = submissions.single;
    expect(updated.rules.take(15), initial.rules.take(15));
    final frame =
        updated.rules.last.candidates.single.parts.single.source
            as SmartTileFrameSource;
    expect((frame.frame.column, frame.frame.row), (1, 3));
    expect(find.text('Raccords publiés.'), findsOneWidget);
  });
}
