import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_workspace_import_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/ui03_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalogue search source choice and return preserve the active map and library state', () async {
    final f = await createUi03Fixture();
    final manifest = File('${f.root.path}/project.json');
    final before = await manifest.readAsBytes();
    final document = f.workspace.active!;
    final beforeMap = document.current;
    final undoCount = document.undoCount;
    final navigation = f.navigation;
    final library = navigation.library;
    List<ResourceItem> visible() =>
        library.visibleItems(resourceCatalog(f.workspace.project!));
    library.selectFamily(ResourceLibraryFamily.decors);
    final first = library.reconcileSelection(visible())!.id;
    expect(document.current, same(beforeMap));
    expect(document.dirty, isFalse);
    final importer = ResourceWorkspaceImportWorkflow(
      navigation: navigation,
      isActive: () => true,
    );
    var confirmations = 0;
    expect(
      await importer.importImage(
        picker: () async => null,
        confirm: (_, _) async {
          confirmations++;
          return null;
        },
      ),
      isFalse,
    );
    expect(confirmations, 0);
    expect(await manifest.readAsBytes(), before);
    library.category = 'objets';
    library.query = 'MOBILIER';
    final furniture = visible();
    expect(furniture, hasLength(40));
    expect(library.reconcileSelection(furniture)!.id, isNot(first));
    expect(document.current, same(beforeMap));
    library.query = 'inexistant';
    expect(visible(), isEmpty);
    expect(library.reconcileSelection(visible()), isNull);
    expect(library.selectedId, isNull);
    library.query = '';
    library.category = '';
    library.offset = 350;
    final decor = library.reconcileSelection(visible())!;
    navigation.showLibrary(decor);
    expect(library.offset, 350);
    Future<bool> use(ResourceItem item) => useMapResource(
      workspace: f.workspace,
      item: item,
      view: () => f.view,
      isActive: () => true,
      chooseMap: (_) async => null,
      chooseTile: (_) async =>
          TileLayerPaletteEntry(tilesetId: item.id, localTileId: 13),
    );
    expect(await use(decor), isTrue);
    expect(f.workspace.active, same(document));
    expect(document.current, same(beforeMap));
    expect(f.view.tool, StudioMapTool.place);
    expect(f.view.brush!.id, library.selectedId);
    expect(
      MapEditingCommands(
        document,
        f.workspace.project!,
      ).place(f.view.brush!, const GridPos(x: 4, y: 4)),
      isNotNull,
    );
    expect(document.current, isNot(beforeMap));
    document.restore(redo: false);
    expect(document.current, beforeMap);
    library.selectFamily(ResourceLibraryFamily.images);
    final image = library.reconcileSelection(visible())!;
    expect(await use(image), isTrue);
    expect(f.view.tile!.localTileId, 13);
    expect(f.view.tool, StudioMapTool.paint);
    f.paintTerrain(const GridPos(x: 4, y: 4));
    expect(document.current, isNot(beforeMap));
    document.restore(redo: false);
    expect(document.current, beforeMap);
    library.selectFamily(ResourceLibraryFamily.terrains);
    final terrain = library.reconcileSelection(visible())!;
    expect(await use(terrain), isTrue);
    expect(f.view.terrain!.id, 'chemin');
    expect(f.view.tool, StudioMapTool.terrain);
    f.paintTerrain(const GridPos(x: 4, y: 4));
    expect(document.current, isNot(beforeMap));
    document.restore(redo: false);
    expect(document.current, beforeMap);
    library.query = 'ancien filtre incompatible';
    final revealed = f.workspace.project!.elements.last;
    navigation.openElement(revealed);
    expect(library.selectedId, revealed.id);
    expect(library.query, isEmpty);
    expect(library.kind, ResourceKind.decors);
    expect(library.offset, 350);
    expect(library.revealPending, isTrue);
    expect(await manifest.readAsBytes(), before);
    expect(document.current, beforeMap);
    expect(document.undoCount, undoCount);
    expect(document.dirty, isFalse);
  });
}
