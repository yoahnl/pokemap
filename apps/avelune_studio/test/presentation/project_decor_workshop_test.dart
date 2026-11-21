import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_decor_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('publishes a valid cutout with its collision cells', (
    tester,
  ) async {
    final tileset = ProjectTilesetEntry(
      id: 'atlas',
      name: 'Planche',
      relativePath: 'assets/atlas.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'image-atlas',
        pixelWidth: 64,
        pixelHeight: 64,
        tileWidth: 16,
        tileHeight: 16,
      ),
    );
    final project = ProjectManifest(
      name: 'Recette',
      maps: [],
      tilesets: [tileset],
      elementCategories: const [
        ProjectElementCategory(id: 'decor', name: 'Décors'),
      ],
    );
    final publications = <ProjectElementEntry>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ProjectDecorEditorDialog(
                project: project,
                tileset: tileset,
                original: null,
                visuals: null,
                publish: (decor) async {
                  publications.add(decor);
                  return (
                    item: ProjectLibraryItem(
                      kind: 'element',
                      id: decor.id,
                      name: decor.name,
                    ),
                    receipt: ResourceMutationReceipt(
                      before: project,
                      manifest: project.copyWith(elements: [decor]),
                      beforeRevision: 'initial',
                      revision: 'after',
                      changedPaths: const ['catalog/HEAD.json'],
                      changedElement: decor,
                    ),
                  );
                },
                reconcile: (_) =>
                    throw StateError('No reconciliation in this test'),
              ),
            ),
            child: const Text('Ouvrir le décor'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir le décor'));
    await tester.pumpAndSettle();
    final column = find.byKey(const ValueKey('decor-crop-0'));
    final width = find.byKey(const ValueKey('decor-crop-2'));
    final publish = find.text('Publier le décor');
    await tester.ensureVisible(column);
    await tester.enterText(column, '5');
    await tester.pumpAndSettle();
    expect(find.text('Le cadre doit rester dans la planche.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: publish, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(column, '2');
    await tester.enterText(width, '2');
    await tester.pumpAndSettle();
    final block = find.text('Bloquer tout le cadre');
    await tester.ensureVisible(block);
    await tester.pumpAndSettle();
    await tester.tap(block.hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pumpAndSettle();
    final saved = publications.single;
    expect(saved.categoryId, 'decor');
    expect(
      saved.frames.single.source,
      const TilesetSourceRect(x: 1, y: 0, width: 2),
    );
    expect(saved.collisionProfile?.cells, const [
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
    ]);
  });
}
