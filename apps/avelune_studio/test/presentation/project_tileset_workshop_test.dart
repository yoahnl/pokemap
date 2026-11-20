import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/presentation/features/resources/project_tileset_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('shows the saved grid and opens the maps using the atlas', (
    tester,
  ) async {
    final visuals = _Visuals();
    final opened = <String>[];
    final reads = <String>[];
    var returned = false;
    await _open(
      tester,
      const ProjectTilesetSource.regularAtlas(
        assetId: 'image',
        pixelWidth: 160,
        pixelHeight: 64,
        tileWidth: 24,
        tileHeight: 16,
        marginX: 8,
        marginY: 4,
        spacingX: 6,
        spacingY: 4,
      ),
      visuals: visuals,
      reads: reads,
      usages: const {'garden': 'Jardin des essais'},
      onOpenMap: (id) async {
        opened.add(id);
        return false;
      },
      onBack: () => returned = true,
    );

    expect(reads, ['tileset:atlas']);
    expect(find.text('Planche du jardin'), findsOneWidget);
    expect(find.text('160 × 64 px'), findsOneWidget);
    expect(find.text('24 × 16 px'), findsOneWidget);
    expect(find.text('5 colonnes × 3 lignes'), findsOneWidget);
    expect(find.text('8 × 4 px'), findsOneWidget);
    expect(find.text('6 × 4 px'), findsOneWidget);
    expect(visuals.last.showGrid, isTrue);

    await tester.tap(find.text('Afficher la grille'));
    await tester.pumpAndSettle();
    expect(visuals.last.showGrid, isFalse);
    expect(reads, ['tileset:atlas']);

    await tester.ensureVisible(find.text('Jardin des essais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jardin des essais'));
    await tester.pumpAndSettle();
    expect(opened, ['garden']);
    expect(find.text('Impossible d’ouvrir cette carte.'), findsOneWidget);

    await tester.tap(find.text('Retour à la bibliothèque'));
    expect(returned, isTrue);
  });

  testWidgets('recognizes an image imported at its full size', (tester) async {
    await _open(
      tester,
      const ProjectTilesetSource.regularAtlas(
        assetId: 'image',
        pixelWidth: 160,
        pixelHeight: 64,
        tileWidth: 160,
        tileHeight: 64,
      ),
      visuals: _Visuals(),
      usages: const {},
    );
    expect(find.text('Image entière'), findsOneWidget);
    expect(find.text('160 × 64 px'), findsOneWidget);
    expect(find.text('Afficher la grille'), findsNothing);
    expect(find.text('Aucune carte ne l’utilise.'), findsOneWidget);
  });

  testWidgets('navigates the image collection using saved page dimensions', (
    tester,
  ) async {
    final visuals = _Visuals();
    await _open(
      tester,
      const ProjectTilesetSource.imageCollection(
        pages: [
          ProjectImageCollectionPage(
            id: 'first',
            assetId: 'image-a',
            pixelWidth: 160,
            pixelHeight: 64,
          ),
          ProjectImageCollectionPage(
            id: 'second',
            assetId: 'image-b',
            pixelWidth: 32,
            pixelHeight: 64,
          ),
        ],
        tileDefinitions: [],
      ),
      visuals: visuals,
    );
    expect(find.text('Collection d’images'), findsOneWidget);
    expect(find.text('160 × 64 px'), findsOneWidget);
    expect(visuals.last.pageId, 'first');
    expect(find.text('Afficher la grille'), findsNothing);

    await tester.tap(find.text('Page 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Page 2').last);
    await tester.pumpAndSettle();
    expect(find.text('32 × 64 px'), findsOneWidget);
    expect(visuals.last.pageId, 'second');
  });

  testWidgets('does not infer a grid or usage for a historical image', (
    tester,
  ) async {
    await _open(tester, null);
    expect(find.text('Aucune grille enregistrée pour cette image.'), findsOne);
    expect(find.text('Usages indisponibles.'), findsOneWidget);
    expect(find.text('Afficher la grille'), findsNothing);
    expect(find.text('Aperçu indisponible'), findsOneWidget);
  });
}

Future<void> _open(
  WidgetTester tester,
  ProjectTilesetSource? source, {
  _Visuals? visuals,
  List<String>? reads,
  Map<String, String>? usages,
  Future<bool> Function(String)? onOpenMap,
  VoidCallback? onBack,
}) async {
  final atlas = ProjectTilesetEntry(
    id: 'atlas',
    name: 'Planche du jardin',
    relativePath: 'atlas.png',
    source: source,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectTilesetWorkshop(
          item: ProjectLibraryItem(
            kind: 'tileset',
            id: atlas.id,
            name: atlas.name,
          ),
          visuals: visuals,
          previews: ProjectResourcePreviews((item) async {
            reads?.add(item.identity);
            return ProjectManifest(
              name: 'Jardin',
              maps: const [],
              tilesets: [atlas],
            );
          }),
          usages: usages,
          onOpenMap: onOpenMap,
          onBack: onBack ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Visuals extends WorkspaceTestVisuals
    implements ScopedResourcePreviewVisuals {
  late AtlasPreviewSource last;

  @override
  void invalidateResourcePreviews(Set<String> changedRelativePaths) {}

  @override
  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  }) {
    last = source as AtlasPreviewSource;
    return const SizedBox.expand();
  }
}
