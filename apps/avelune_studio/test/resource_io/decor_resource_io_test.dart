import 'dart:io';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  test(
    'PNG selection, collision, variant, repeated placement, undo and disk reopen',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final controller = MapWorkspaceController(fixture.session, fixture.maps);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Travail avant import'));
      final mapBeforeImport = await fixture.mapFile.readAsBytes();
      final imported = await fixture.import();
      controller.acceptResources(imported.before, imported.manifest);
      final tileset = controller.project!.tilesets.single;
      final draft = DecorDraft(tileset: tileset)
        ..name = 'Arbre multi-cases'
        ..selection = const TilesetSourceRect(x: 1, y: 0, width: 2, height: 2)
        ..setBlocked(true);
      final receipt = await fixture.resources.saveElement(draft.build());
      controller.acceptResources(receipt.before, receipt.manifest);
      final original = controller.project!.elements.single;
      expect(original.frames.single.source, draft.selection);
      expect(original.collisionProfile!.cells, hasLength(4));
      expect(await fixture.mapFile.readAsBytes(), mapBeforeImport);
      expect(document.undoCount, 1);
      final variantDraft = DecorDraft(tileset: tileset, original: original)
        ..name = 'Arbre traversable'
        ..variant = true
        ..setBlocked(false);
      final variantReceipt = await fixture.resources.saveElement(
        variantDraft.build(),
      );
      controller.acceptResources(
        variantReceipt.before,
        variantReceipt.manifest,
      );
      expect(controller.active, same(document));
      expect(controller.project!.elements, contains(original));
      final variant = controller.project!.elements.singleWhere(
        (e) => e.id != original.id,
      );
      expect(variant.collisionProfile!.cells, isEmpty);
      final commands = MapEditingCommands(document, controller.project!);
      commands.place(original, const GridPos(x: 0, y: 0));
      commands.place(variant, const GridPos(x: 2, y: 2));
      final placed = document.current;
      expect(placed.placedElements, hasLength(2));
      document.restore(redo: false);
      expect(document.current.placedElements, hasLength(1));
      expect(controller.project!.elements, hasLength(2));
      document.restore(redo: true);
      expect(document.current, placed);
      expect(await controller.save(document), isTrue);
      final reader = LocalMapWorkspaceAdapter();
      final reopened = await reader.loadProject(fixture.session);
      final saved = await reader.loadMap(
        fixture.session,
        ResourceFixture.entry,
      );
      expect(saved.map, placed);
      expect(reopened.elements, containsAll([original, variant]));
      expect(
        await File(
          '${fixture.root.path}/${tileset.relativePath}',
        ).readAsBytes(),
        await fixture.source.readAsBytes(),
      );
    },
  );
}
