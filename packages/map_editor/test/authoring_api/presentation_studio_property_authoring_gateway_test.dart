import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_property_authoring_gateway.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_property_command.dart';

void main() {
  test(
    'property mutations commit through authoring and support undo redo',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'presentation_property_gateway_',
      );
      final manifestFile = File('${root.path}/project.json');
      final container = ProviderContainer();
      addTearDown(() async {
        await container.read(authoringMutationAdapterProvider).closeAll();
        await container.read(authoringQueryAdapterProvider).closeAll();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });

      final manifest = _manifest();
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
      final gateway = CanonicalPresentationStudioPropertyAuthoringGateway(
        mutations: container.read(authoringMutationAdapterProvider),
        queries: container.read(authoringQueryAdapterProvider),
      );
      final asset = manifest.presentationCinematics.single;
      final track = asset.tracks.single;
      final clip = track.clips.single as PresentationTextClip;
      final command = PresentationStudioPropertyCommand.updateClip(
        cinematicId: asset.id,
        trackId: track.id,
        clip: PresentationTextClip(
          id: clip.id,
          startUs: clip.startUs,
          durationUs: clip.durationUs,
          layerId: clip.layerId,
          text: 'Nouveau titre',
        ),
      );

      final committed = await gateway.apply(
        root.path,
        expectedProject: manifest,
        command: command,
      );

      expect(_clip(committed.manifest).text, 'Nouveau titre');
      expect(_clip(_readManifest(manifestFile)).text, 'Nouveau titre');

      final restored = await gateway.undo(
        root.path,
        expectedProject: committed.manifest,
        transaction: committed,
      );
      expect(_clip(restored).text, 'Titre original');

      final redone = await gateway.redo(
        root.path,
        expectedProject: restored,
        transaction: committed,
      );
      expect(_clip(redone.manifest).text, 'Nouveau titre');
      expect(redone.receiptId, isNot(committed.receiptId));
    },
  );
}

ProjectManifest _manifest() => ProjectManifest(
  name: 'Presentation property gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 5_000_000,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'hero-layer', label: 'Hero', zIndex: 0),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationTextClip(
              id: 'hero',
              startUs: 0,
              durationUs: 5_000_000,
              layerId: 'hero-layer',
              text: 'Titre original',
            ),
          ],
        ),
      ],
    ),
  ],
);

PresentationTextClip _clip(ProjectManifest manifest) =>
    manifest.presentationCinematics.single.tracks.single.clips.single
        as PresentationTextClip;

ProjectManifest _readManifest(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded as Map));
}
