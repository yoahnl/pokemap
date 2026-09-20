import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test(
    'same image creates distinct drafts and reopening retains canonical identity',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final pixels = image.Image(width: 64, height: 96);
      for (var y = 0; y < pixels.height; y++) {
        for (var x = 0; x < pixels.width; x++) {
          final cell = y ~/ 24 * 4 + x ~/ 16;
          pixels.setPixelRgb(
            x,
            y,
            30 + cell * 12,
            200 - cell * 8,
            60 + cell * 5,
          );
        }
      }
      await fixture.source.writeAsBytes(image.encodePng(pixels));
      final workspace = MapWorkspaceController(fixture.session, fixture.maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      document.commit(document.current.copyWith(name: 'Carte sale conservée'));
      final diskMap = await fixture.mapFile.readAsBytes();
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: fixture.resources,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      await navigation.accept(await fixture.import());
      final source = resourceCatalog(workspace.project!).single;
      navigation.library
        ..kind = ResourceKind.images
        ..query = 'Arbres'
        ..grid = false
        ..offset = 75
        ..selectedId = source.id;
      navigation.prepareTerrain(source);
      final first = navigation.terrain!;
      first.assign(1, 2);
      first.rename('Premier terrain');
      expect(await navigation.saveDrafts(), isTrue);
      navigation.showLibrary();
      expect(navigation.library.query, 'Arbres');
      expect(navigation.library.kind, ResourceKind.images);
      expect(navigation.library.offset, 75);
      expect(navigation.library.selectedId, source.id);
      navigation.prepareTerrain(source);
      final second = navigation.terrain!;
      expect(second, isNot(same(first)));
      expect(second.draft.id, isNot(first.draft.id));
      expect(second.draft.targetPresetId, isNot(first.draft.targetPresetId));
      expect(second.atlas.tilesetId, first.atlas.tilesetId);
      second.rename('Second terrain');
      second.assign(3, 1);
      expect(await navigation.saveDrafts(), isTrue);
      expect(navigation.terrains.keys.toSet(), {
        first.draft.id,
        second.draft.id,
      });
      expect(workspace.project!.smartTileCatalog.drafts, hasLength(2));
      expect(workspace.active, same(document));
      expect(document.dirty, isTrue);
      expect(document.undoCount, 1);
      expect(await fixture.mapFile.readAsBytes(), diskMap);

      final reader = LocalMapWorkspaceAdapter();
      final reopened = MapWorkspaceController(fixture.session, reader);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      final resources = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: reader,
      );
      addTearDown(resources.dispose);
      final fresh = ResourceNavigation(
        workspace: reopened,
        port: resources,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(fresh.dispose);
      expect(fresh.pendingTerrainDrafts, hasLength(2));
      fresh.resumeTerrain(
        fresh.terrainDrafts.firstWhere((draft) => draft.id == first.draft.id),
      );
      final resumed = fresh.terrain!;
      expect(resumed.draft.targetPresetId, first.draft.targetPresetId);
      expect(resumed.frameFor(0), first.frameFor(0));
      expect(resumed.dirty, isFalse);
      for (var mask = 0; mask < 16; mask++) {
        resumed.selectedRule = mask;
        resumed.assign(mask % 4, mask ~/ 4);
      }
      expect(await resumed.save(fresh.mutate, publish: true), isTrue);
      final preset = reopened.project!.smartTileCatalog.presets.single;
      final selected = resourceCatalog(reopened.project!).firstWhere(
        (item) => item.id == preset.id && item.kind == ResourceKind.terrains,
      );
      expect(fresh.canEditTerrain(selected), isTrue);
      fresh.prepareTerrain(selected);
      expect(fresh.terrain, same(resumed));
      expect(reopened.project!.smartTileCatalog.drafts, hasLength(1));
      final publishedNavigation = ResourceNavigation(
        workspace: reopened,
        port: resources,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(publishedNavigation.dispose);
      expect(publishedNavigation.canEditTerrain(selected), isTrue);
      publishedNavigation.prepareTerrain(selected);
      final editing = publishedNavigation.terrain!;
      expect(editing.draft.targetPresetId, preset.id);
      expect(editing.draft.sourcePresetId, preset.id);
      expect(editing.frameFor(7), resumed.frameFor(7));
      editing.selectedRule = 7;
      editing.assign(3, 3);
      expect(
        await editing.save(publishedNavigation.mutate, publish: true),
        isTrue,
      );
      expect(reopened.project!.smartTileCatalog.presets.single.id, preset.id);
      expect(reopened.project!.smartTileCatalog.drafts, hasLength(1));
      expect(await fixture.mapFile.readAsBytes(), diskMap);
    },
  );

  test(
    'publication without maps selects library and never pretends to paint',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final original = ProjectManifest.fromJson(
        jsonDecode(await fixture.manifestFile.readAsString())
            as Map<String, dynamic>,
      );
      await fixture.manifestFile.writeAsString(
        jsonEncode(original.copyWith(maps: []).toJson()),
      );
      final reader = fixture.maps;
      final workspace = MapWorkspaceController(fixture.session, reader);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: fixture.resources,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) => fail('No map exists'),
      );
      addTearDown(navigation.dispose);
      await navigation.accept(await fixture.import());
      navigation.prepareTerrain(resourceCatalog(workspace.project!).single);
      final model = navigation.terrain!;
      for (var mask = 0; mask < 16; mask++) {
        model.selectedRule = mask;
        model.assign(mask % 4, mask % 2);
      }
      expect(await model.save(navigation.mutate, publish: true), isTrue);
      final preset = workspace.project!.smartTileCatalog.presets.single;
      navigation.completeTerrainPublication(preset);
      expect(navigation.page, ResourcePage.library);
      expect(navigation.library.kind, ResourceKind.terrains);
      expect(navigation.library.selectedId, preset.id);
      expect(navigation.dirty, isFalse);
      expect(workspace.documents, isEmpty);
    },
  );
}
