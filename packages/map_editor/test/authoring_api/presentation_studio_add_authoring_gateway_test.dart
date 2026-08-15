import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_add_authoring_gateway.dart';

void main() {
  test(
    'imports into the catalog then inserts exactly one timeline item',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'presentation_add_gateway_',
      );
      final manifestFile = File('${root.path}/project.json');
      final source = File('${root.path}/opening.png');
      final container = ProviderContainer();
      addTearDown(() async {
        await container.read(authoringMutationAdapterProvider).closeAll();
        await container.read(authoringQueryAdapterProvider).closeAll();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      final manifest = _manifest();
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
      await source.writeAsBytes(_png(width: 1920, height: 1080));
      var identity = 0;
      final mutations = container.read(authoringMutationAdapterProvider);
      final gateway = CanonicalPresentationStudioAddAuthoringGateway(
        mutations: mutations,
        queries: container.read(authoringQueryAdapterProvider),
        identityFactory: (prefix) => '$prefix-${identity++}',
      );

      expect(await gateway.loadMedia(root.path), isEmpty);
      final imported = await gateway.importMedia(
        root.path,
        expectedProject: manifest,
        request: PresentationStudioMediaImportRequest(
          category: PresentationStudioAddCategory.visual,
          picked: PresentationStudioPickedMedia(
            sourcePath: source.path,
            label: 'opening.png',
          ),
        ),
        isCancelled: () => false,
      );

      expect(
        imported.media.availability,
        PresentationStudioMediaAvailability.ready,
      );
      expect(imported.media.metadataLabel, contains('1920 × 1080'));
      expect(await gateway.loadMedia(root.path), hasLength(1));

      final inserted = await gateway.insert(
        root.path,
        expectedProject: imported.manifest,
        request: PresentationStudioInsertionRequest(
          asset: imported.manifest.presentationCinematics.single,
          category: PresentationStudioAddCategory.visual,
          playheadUs: 1250000,
          durationUs: 2000000,
          label: imported.media.label,
          mediaId: imported.media.id,
          targetVisualFolderId: 'characters',
        ),
      );

      final cinematic = inserted.manifest.presentationCinematics.single;
      expect(cinematic.layers, hasLength(1));
      expect(cinematic.visualFolders.single.layerIds, <String>[
        inserted.layerId!,
      ]);
      expect(cinematic.tracks, hasLength(1));
      expect(cinematic.tracks.single.clips, hasLength(1));
      expect(cinematic.tracks.single.clips.single.id, inserted.clipId);
      expect(cinematic.tracks.single.clips.single.startUs, 1250000);
      expect(
        mutations.lastAppliedReceipt?.actionId,
        'presentationTimeline.insert',
      );
    },
  );
}

ProjectManifest _manifest() => ProjectManifest(
  name: 'Presentation add gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 6000000,
      visualFolders: <PresentationVisualFolder>[
        PresentationVisualFolder(id: 'characters', label: 'Characters'),
      ],
    ),
  ],
);

Uint8List _png({required int width, required int height}) {
  final bytes = Uint8List(24)
    ..setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10])
    ..setRange(12, 16, 'IHDR'.codeUnits);
  ByteData.sublistView(bytes)
    ..setUint32(16, width)
    ..setUint32(20, height);
  return bytes;
}
