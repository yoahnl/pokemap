import 'dart:io';
import 'dart:convert';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  test('fine collision owner saves through the real adapter and reopens independently', () async {
    late ResourceFixture fixture;
    late ProjectElementEntry original;
    late ProjectTilesetEntry tileset;
    fixture = await ResourceFixture.create();
    final initial = ProjectManifest.fromJson(
      jsonDecode(await fixture.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    await fixture.manifestFile.writeAsString(
      jsonEncode(
        initial
            .copyWith(
              settings: const ProjectSettings(tileWidth: 16, tileHeight: 24),
            )
            .toJson(),
      ),
    );
    await fixture.maps.loadProject(fixture.session);
    final imported = await fixture.import();
    tileset = imported.manifest.tilesets.single;
    final pixels = List<bool>.filled(32 * 48, false)..[4 * 32 + 20] = true;
    final mask = ElementCollisionPixelMask(
      widthPx: 32,
      heightPx: 48,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: 32,
        heightPx: 48,
        solidPixels: pixels,
      ),
    );
    final created = await fixture.resources.saveElement(
      fixture
          .element(tileset.id)
          .copyWith(
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
              visualMask: mask,
              occlusionMask: mask,
              cells: const [GridPos(x: 1, y: 0)],
            ),
          ),
    );
    original = created.manifest.elements.single;
    addTearDown(fixture.dispose);
    final mapBefore = await fixture.mapFile.readAsBytes();
    final pngBefore = await fixture.source.readAsBytes();
    final draft = DecorDraft(tileset: tileset, original: original)
      ..name = 'Arbre à collision fine';
    draft.beginCollisionPointer(5, 10, fine: true, solid: true);
    draft.endCollisionPointer();
    expect(
      await draft.save((element) async {
        await fixture.resources.saveElement(element);
      }),
      isTrue,
    );
    final freshSession = ProjectSession(
      sessionId: '${fixture.session.sessionId}-fresh',
      name: fixture.session.name,
      directoryPath: fixture.root.path,
    );
    final fresh = LocalMapWorkspaceAdapter();
    final reopened = await fresh.loadProject(freshSession);
    final saved = reopened.elements.single;
    expect(saved.name, 'Arbre à collision fine');
    expect(saved.id, original.id);
    expect(saved.frames, original.frames);
    expect(
      saved.collisionProfile!.visualMask,
      original.collisionProfile!.visualMask,
    );
    expect(
      saved.collisionProfile!.occlusionMask,
      original.collisionProfile!.occlusionMask,
    );
    final collision = saved.collisionProfile!.collisionMask!;
    final actual = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: collision.widthPx,
      heightPx: collision.heightPx,
      dataBase64: collision.dataBase64,
    );
    expect(actual[10 * 32 + 5], isTrue);
    expect(actual[4 * 32 + 20], isTrue);
    expect(actual[4 * 32 + 21], isFalse);
    final rects = resolveMapPlacedElementCollisionRects(
      instance: const MapPlacedElement(
        id: 'instance',
        elementId: 'tree',
        layerId: 'ground',
        pos: GridPos(x: 1, y: 1),
      ),
      element: saved,
      tileSize: const PixelSize(width: 16, height: 24),
    ).toList();
    bool blocked(int x, int y) => rects.any(
      (rect) =>
          x >= rect.leftPx &&
          x < rect.leftPx + rect.widthPx &&
          y >= rect.topPx &&
          y < rect.topPx + rect.heightPx,
    );
    expect(blocked(16 + 5, 24 + 10), isTrue);
    expect(blocked(16 + 20, 24 + 4), isTrue);
    expect(blocked(16 + 21, 24 + 4), isFalse);
    expect(await fixture.mapFile.readAsBytes(), mapBefore);
    expect(
      await File('${fixture.root.path}/${tileset.relativePath}').readAsBytes(),
      pngBefore,
    );
  });

  test('PNG selection, collision, variant, repeated placement, undo and disk reopen', () async {
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
    controller.acceptResources(variantReceipt.before, variantReceipt.manifest);
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
    final saved = await reader.loadMap(fixture.session, ResourceFixture.entry);
    expect(saved.map, placed);
    expect(reopened.elements, containsAll([original, variant]));
    expect(
      await File('${fixture.root.path}/${tileset.relativePath}').readAsBytes(),
      await fixture.source.readAsBytes(),
    );
  });
}
