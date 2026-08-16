import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_draft_authoring_gateway.dart';

void main() {
  test(
    'opens once and keeps consecutive Presentation edits off disk',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'presentation_draft_gateway_',
      );
      final manifestFile = File('${root.path}/project.json');
      final container = ProviderContainer();
      addTearDown(() async {
        await container.read(authoringQueryAdapterProvider).closeAll();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      });
      final baseline = _manifest();
      await manifestFile.writeAsString(jsonEncode(baseline.toJson()));
      final queries = container.read(authoringQueryAdapterProvider);
      final gateway = CanonicalPresentationStudioDraftAuthoringGateway(
        queries: queries,
      );

      final draft = await gateway.open(root.path, expectedProject: baseline);
      draft.apply(
        actionId: 'presentationCinematic.update',
        parameters: const <String, Object?>{
          'cinematicId': 'opening',
          'title': 'Premier titre',
          'description': null,
          'durationUs': 5000000,
        },
        operationId: 'draft-1',
      );
      draft.apply(
        actionId: 'presentationCinematic.update',
        parameters: const <String, Object?>{
          'cinematicId': 'opening',
          'title': 'Dernier titre',
          'description': null,
          'durationUs': 5000000,
        },
        operationId: 'draft-2',
      );

      expect(
        draft.manifest.presentationCinematics.single.title,
        'Dernier titre',
      );
      expect(_readManifest(manifestFile), baseline);
      expect(queries.diagnostics.liveSessions, 1);
    },
  );
}

ProjectManifest _manifest() => ProjectManifest(
  name: 'Presentation draft gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 5000000,
    ),
  ],
);

ProjectManifest _readManifest(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded as Map));
}
