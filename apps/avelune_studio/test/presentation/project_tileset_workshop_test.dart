import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'project_tileset_workshop_fixture.dart';

void main() {
  testWidgets('shows the saved grid and opens the maps using the atlas', (
    tester,
  ) async {
    final visuals = TilesetWorkshopTestVisuals();
    final opened = <String>[];
    final reads = <String>[];
    var returned = false;
    await pumpTilesetWorkshop(
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
    await pumpTilesetWorkshop(
      tester,
      const ProjectTilesetSource.regularAtlas(
        assetId: 'image',
        pixelWidth: 160,
        pixelHeight: 64,
        tileWidth: 160,
        tileHeight: 64,
      ),
      visuals: TilesetWorkshopTestVisuals(),
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
    final visuals = TilesetWorkshopTestVisuals();
    await pumpTilesetWorkshop(
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
    await pumpTilesetWorkshop(tester, null);
    expect(find.text('Aucune grille enregistrée pour cette image.'), findsOne);
    expect(find.text('Usages indisponibles.'), findsOneWidget);
    expect(find.text('Afficher la grille'), findsNothing);
    expect(find.text('Aperçu indisponible'), findsOneWidget);
  });
}
