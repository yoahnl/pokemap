import 'dart:io';

import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'cinematic save preserves concurrent import, every map and linked sources',
    () async {
      final f = await Ui06SceneFixture.create();
      addTearDown(f.dispose);
      final port = LocalCinematicAdapter(
        session: f.session,
        mapAdapter: f.maps,
      );
      final base = await port.load(Ui06SceneFixture.cinematicId);
      final files = [
        for (final map in f.manifest.maps)
          File('${f.directory.path}/${map.relativePath}'),
        for (final dialogue in f.manifest.dialogues)
          File('${f.directory.path}/${dialogue.relativePath}'),
      ];
      final bytes = [for (final file in files) await file.readAsBytes()];
      final imported =
          await LocalResourceAdapter(
            session: f.session,
            mapAdapter: f.maps,
          ).importImage(
            ResourceImageImport(
              sourcePath: '${f.directory.path}/assets/atelier.png',
              name: 'Import pendant cinématique',
              tileWidth: 16,
              tileHeight: 16,
            ),
          );
      final receipt = await port.publish(
        id: base.asset.id,
        base: base,
        asset: base.asset.copyWith(notes: 'Notes publiées isolément'),
      );
      expect(receipt.resources.changedPaths, ['project.json']);
      final fresh = await LocalMapWorkspaceAdapter().loadProject(f.session);
      expect(fresh.tilesets, imported.manifest.tilesets);
      expect(fresh.scenes, f.manifest.scenes);
      expect(fresh.dialogues, f.manifest.dialogues);
      expect(fresh.cinematics.single.notes, 'Notes publiées isolément');
      for (var index = 0; index < files.length; index++) {
        expect(await files[index].readAsBytes(), bytes[index]);
      }
    },
  );
}
