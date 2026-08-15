import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_timeline_authoring_gateway.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_timeline_command.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';

void main() {
  test('commits once then restores the batch through undo and redo', () async {
    final root = await Directory.systemTemp.createTemp(
      'presentation_timeline_gateway_',
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
    final mutations = container.read(authoringMutationAdapterProvider);
    final queries = container.read(authoringQueryAdapterProvider);
    final gateway = CanonicalPresentationStudioTimelineAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );
    final command = PresentationTimelineClipCommand(
      actionId: 'presentationClip.batch',
      parameters: const <String, Object?>{
        'cinematicId': 'opening',
        'operations': <Object?>[
          <String, Object?>{
            'kind': 'edit',
            'clipId': 'hero',
            'targetTrackId': 'markers',
            'startUs': 2000000,
            'durationUs': 0,
          },
        ],
      },
    );

    final committed = await gateway.apply(
      root.path,
      expectedProject: manifest,
      command: command,
    );

    expect(_clipStart(committed.manifest), 2000000);
    expect(_clipStart(_readManifest(manifestFile)), 2000000);
    expect(mutations.lastAppliedReceipt!.actionId, 'presentationClip.batch');

    final restored = await gateway.undo(
      root.path,
      expectedProject: committed.manifest,
      transaction: committed,
    );

    expect(_clipStart(restored), 1000000);
    expect(_clipStart(_readManifest(manifestFile)), 1000000);

    final redone = await gateway.redo(
      root.path,
      expectedProject: restored,
      transaction: committed,
    );

    expect(_clipStart(redone.manifest), 2000000);
    expect(_clipStart(_readManifest(manifestFile)), 2000000);
    expect(redone.receiptId, isNot(committed.receiptId));

    final deleted = await gateway.apply(
      root.path,
      expectedProject: redone.manifest,
      command: PresentationTimelineClipCommand(
        actionId: 'presentationClip.deleteBatch',
        parameters: const <String, Object?>{
          'cinematicId': 'opening',
          'clipIds': <String>['hero'],
        },
      ),
    );

    expect(
      deleted.manifest.presentationCinematics.single.tracks.single.clips,
      isEmpty,
    );
    final deleteRestored = await gateway.undo(
      root.path,
      expectedProject: deleted.manifest,
      transaction: deleted,
    );
    expect(_clipStart(deleteRestored), 2000000);

    await manifestFile.writeAsString(
      jsonEncode(deleteRestored.copyWith(name: 'External drift').toJson()),
    );
    await expectLater(
      gateway.apply(
        root.path,
        expectedProject: deleteRestored,
        command: command,
      ),
      throwsA(isA<EditorConflictException>()),
    );
    expect(_clipStart(_readManifest(manifestFile)), 2000000);
  });
}

ProjectManifest _manifest() => ProjectManifest(
  name: 'Presentation timeline gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 5000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'markers',
          label: 'Markers',
          kind: PresentationTrackKind.marker,
          clips: <PresentationClip>[
            PresentationMarkerClip(id: 'hero', startUs: 1000000, label: 'Hero'),
          ],
        ),
      ],
    ),
  ],
);

int _clipStart(ProjectManifest manifest) =>
    manifest.presentationCinematics.single.tracks.single.clips.single.startUs;

ProjectManifest _readManifest(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded as Map));
}
