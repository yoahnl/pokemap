import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  testWidgets('a tileset opens its workshop and returns to the same draft', (
    tester,
  ) async {
    final (maps, port) = await _openLibrary(tester);
    final draft = maps.active!;
    draft.commit(draft.current.copyWith(name: 'Brouillon en cours'));

    final search = find.descendant(
      of: find.byKey(const ValueKey('library-search')),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'planche');
    await tester.pumpAndSettle();
    final item = find.byKey(const ValueKey('library-item-tileset:atlas'));
    await tester.tap(item);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atelier Images et tuiles'));
    await tester.pumpAndSettle();

    expect(find.text('Images et tuiles'), findsOneWidget);
    expect(port.previewReads, ['tileset:atlas']);
    await tester.tap(find.text('Retour à la bibliothèque'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(search).controller!.text, 'planche');
    expect(
      find.byKey(const ValueKey('library-detail-tileset:atlas')),
      findsOneWidget,
    );
    expect(maps.active, same(draft));
    expect(draft.current.name, 'Brouillon en cours');
    expect(port.fullReads, 0);
  });

  testWidgets('the workshop picker filters rows by resource type', (
    tester,
  ) async {
    final (_, port) = await _openLibrary(tester);
    await tester.tap(find.text('Ateliers'));
    await tester.pumpAndSettle();
    expect(find.text('Modèle repère'), findsOneWidget);
    expect(find.text('Clôture repère'), findsNothing);

    await tester.tap(find.text('Bordures et parois'));
    await tester.pumpAndSettle();
    expect(find.text('Modèle repère'), findsNothing);
    expect(find.text('Clôture repère'), findsOneWidget);
    expect(find.text('Planche repère'), findsNothing);
    expect(port.previewReads, isEmpty);

    await tester.tap(find.text('Clôture repère'));
    await tester.pumpAndSettle();
    expect(port.previewReads, ['borderBlueprint:fence']);
  });

  for (final (:kind, :id, :name, :action) in const [
    (
      kind: 'character',
      id: 'hero',
      name: 'Héros repère',
      action: 'Atelier Personnages',
    ),
    (
      kind: 'smartTilePreset',
      id: 'path',
      name: 'Chemin repère',
      action: 'Atelier Terrains',
    ),
  ]) {
    testWidgets('$kind opens the selected workshop through its card', (
      tester,
    ) async {
      final (maps, port) = await _openLibrary(tester);
      final draft = maps.active!;
      draft.commit(draft.current.copyWith(name: 'Brouillon en cours'));
      final search = find.descendant(
        of: find.byKey(const ValueKey('library-search')),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, name);
      await tester.pumpAndSettle();
      final item = find.byKey(ValueKey('library-item-$kind:$id'));
      await tester.tap(item);
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();

      expect(port.previewReads, ['$kind:$id']);
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('library-detail-$kind:$id')), findsOneWidget);
      expect(maps.active, same(draft));
      expect(draft.current.name, 'Brouillon en cours');
      expect(port.fullReads, 0);
    });
  }

  testWidgets('a workshop map link preserves the reference map filter', (
    tester,
  ) async {
    final (maps, _) = await _openLibrary(tester);
    final original = maps.active!;
    await tester.tap(find.byKey(const ValueKey('library-scope-used')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-item-tileset:atlas')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atelier Images et tuiles'));
    await tester.pumpAndSettle();
    final link = find.byKey(const ValueKey('library-map-second'));
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(maps.active?.base.mapId, secondScopedMap.id);

    await tester.tap(find.text('Retour à la bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.text('Ressources utilisées sur Première.'), findsOneWidget);
    expect(maps.documents[firstScopedMap.id], same(original));
  });
}

Future<(MapWorkspaceController, _WorkshopLibraryPort)> _openLibrary(
  WidgetTester tester,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final port = _WorkshopLibraryPort();
  final maps = MapWorkspaceController(scopedMapSession, port);
  addTearDown(maps.dispose);
  await maps.initialize();
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, refresh) => ProjectLibraryPage(
            active: true,
            maps: maps,
            visuals: null,
            onOpenMap: (id) async {
              await maps.activate(
                maps.project!.maps.firstWhere((map) => map.id == id),
              );
              if (context.mounted) refresh(() {});
              return maps.active?.base.mapId == id;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (maps, port);
}

final class _WorkshopLibraryPort extends ScopedTestMapPort
    implements
        ProjectResourceLibraryPort,
        ProjectResourcePreviewPort,
        ProjectResourceLibraryMapUsagesPort {
  final previewReads = <String>[];

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async => ProjectResourceLibrary(ResourceLibraryCatalog(), [
    ProjectLibraryItem(kind: 'model3d', id: 'model', name: 'Modèle repère'),
    ProjectLibraryItem(kind: 'tileset', id: 'atlas', name: 'Planche repère'),
    ProjectLibraryItem(
      kind: 'borderBlueprint',
      id: 'fence',
      name: 'Clôture repère',
    ),
    ProjectLibraryItem(kind: 'character', id: 'hero', name: 'Héros repère'),
    ProjectLibraryItem(
      kind: 'smartTilePreset',
      id: 'path',
      name: 'Chemin repère',
    ),
  ], revision: 'catalog-1');

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) async => {
    'tileset:atlas': {firstScopedMap.id, secondScopedMap.id},
  };

  @override
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  ) async {
    previewReads.add('$kind:$id');
    return metadata.copyWith(
      tilesets: const [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Planche repère',
          relativePath: 'atlas.png',
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Héros repère',
          tilesetId: 'atlas',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        presets: const [
          ProjectSmartTilePreset(
            id: 'path',
            name: 'Chemin repère',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'path-material',
            allowedMaterialIds: ['path-material'],
          ),
        ],
      ),
    );
  }
}
