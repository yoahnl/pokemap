import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'artwork is read only from the current project and the expected path',
    () async {
      final root = await Directory.systemTemp.createTemp('studio-artwork-');
      addTearDown(() => root.delete(recursive: true));
      final sceneFile = File(
        '${root.path}/assets/studio/narrative/scenes/campaign-opening.png',
      );
      await sceneFile.parent.create(recursive: true);
      final bytes = await File('assets/home/hero_landscape.png').readAsBytes();
      await sceneFile.writeAsBytes(bytes);
      final adapter = LocalNarrativeAdapter(
        session: ProjectSession(
          sessionId: 'artwork-test',
          name: 'Train',
          directoryPath: await root.resolveSymbolicLinks(),
        ),
        mapAdapter: LocalMapWorkspaceAdapter(),
      );

      expect(
        await adapter.readArtwork(
          NarrativeArtworkKind.scene,
          id: 'campaign-opening',
        ),
        bytes,
      );
      expect(
        await adapter.readArtwork(NarrativeArtworkKind.scene, id: '../outside'),
        isNull,
      );
      expect(
        await adapter.readArtwork(
          NarrativeArtworkKind.story,
          id: 'campaign-opening',
        ),
        isNull,
      );
      expect(await adapter.readArtwork(NarrativeArtworkKind.hero), isNull);
      expect(await sceneFile.readAsBytes(), bytes);
    },
  );
}
