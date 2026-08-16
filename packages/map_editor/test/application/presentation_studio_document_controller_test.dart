import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_document_controller.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_draft_authoring_gateway.dart';

void main() {
  test(
    'updates immediately, coalesces recovery, and saves only on request',
    () async {
      final baseline = _manifest();
      final firstRecovery = Completer<bool>();
      final recovered = <ProjectManifest>[];
      var saveCalls = 0;
      final controller = PresentationStudioDocumentController(
        draftGateway: _DraftGateway(_draft(baseline)),
        applyRecovery: (manifest, {required label, required operationId}) {
          recovered.add(manifest);
          if (recovered.length == 1) return firstRecovery.future;
          return Future<bool>.value(true);
        },
        saveDurably: () async {
          saveCalls += 1;
          return true;
        },
        discardDraft: () async => true,
      );
      addTearDown(controller.dispose);
      await controller.open('/project', expectedProject: baseline);

      expect(
        controller.apply(
          actionId: 'presentationCinematic.update',
          parameters: _titleParameters('Premier titre'),
          operationId: 'edit-1',
          label: 'Premier titre',
        ),
        isTrue,
      );
      expect(
        controller.manifest.presentationCinematics.single.title,
        'Premier titre',
      );
      expect(controller.status, PresentationStudioDocumentStatus.dirty);
      expect(saveCalls, 0);

      expect(
        controller.apply(
          actionId: 'presentationCinematic.update',
          parameters: _titleParameters('Dernier titre'),
          operationId: 'edit-2',
          label: 'Dernier titre',
        ),
        isTrue,
      );
      expect(
        controller.manifest.presentationCinematics.single.title,
        'Dernier titre',
      );
      expect(recovered, hasLength(1));

      firstRecovery.complete(true);
      expect(await controller.flushRecovery(), isTrue);
      expect(recovered, hasLength(2));
      expect(
        recovered.last.presentationCinematics.single.title,
        'Dernier titre',
      );
      expect(saveCalls, 0);

      expect(await controller.save(), isTrue);
      expect(saveCalls, 1);
      expect(controller.status, PresentationStudioDocumentStatus.saved);
    },
  );

  test('keeps the draft dirty when recovery throws', () async {
    final baseline = _manifest();
    final controller = PresentationStudioDocumentController(
      draftGateway: _DraftGateway(_draft(baseline)),
      applyRecovery: (_, {required label, required operationId}) async {
        throw StateError('recovery unavailable');
      },
      saveDurably: () async => true,
      discardDraft: () async => true,
    );
    addTearDown(controller.dispose);
    await controller.open('/project', expectedProject: baseline);

    expect(
      controller.apply(
        actionId: 'presentationCinematic.update',
        parameters: _titleParameters('Titre local'),
        operationId: 'edit-failed-recovery',
        label: 'Titre local',
      ),
      isTrue,
    );

    expect(await controller.flushRecovery(), isFalse);
    expect(controller.status, PresentationStudioDocumentStatus.failed);
    expect(controller.isDirty, isTrue);
    expect(controller.errorMessage, contains('recovery unavailable'));
    expect(
      controller.manifest.presentationCinematics.single.title,
      'Titre local',
    );
  });

  test('refreshes media resources without publishing the local draft', () async {
    final baseline = _manifest();
    final source = baseline.presentationCinematics.single;
    final refreshed = baseline.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: source.id,
          title: 'Titre local',
          description: source.description,
          durationUs: source.durationUs,
          layers: source.layers,
          tracks: source.tracks,
        ),
      ],
    );
    final gateway = _SequencedDraftGateway(<PresentationCinematicDraft>[
      _draft(baseline),
      _draft(refreshed),
    ]);
    var saveCalls = 0;
    final controller = PresentationStudioDocumentController(
      draftGateway: gateway,
      applyRecovery: (_, {required label, required operationId}) async => true,
      saveDurably: () async {
        saveCalls += 1;
        return true;
      },
      discardDraft: () async => true,
    );
    addTearDown(controller.dispose);
    await controller.open('/project', expectedProject: baseline);
    controller.apply(
      actionId: 'presentationCinematic.update',
      parameters: _titleParameters('Titre local'),
      operationId: 'edit-before-import',
      label: 'Titre local',
    );

    expect(await controller.refreshResources(), isTrue);

    expect(gateway.openCalls, 2);
    expect(controller.status, PresentationStudioDocumentStatus.dirty);
    expect(controller.manifest.presentationCinematics.single.title, 'Titre local');
    expect(controller.durableBaseline, baseline);
    expect(saveCalls, 0);
  });
}

Map<String, Object?> _titleParameters(String title) => <String, Object?>{
  'cinematicId': 'opening',
  'title': title,
  'description': null,
  'durationUs': 5000000,
};

ProjectManifest _manifest() => ProjectManifest(
  name: 'Presentation document controller',
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

PresentationCinematicDraft _draft(ProjectManifest manifest) {
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  return PresentationCinematicDraft.fromSnapshot(
    ProjectSnapshot(
      projectHandle: const ProjectHandle('document-controller'),
      revision: 'sha256:${List<String>.filled(64, 'a').join()}',
      manifest: manifest,
      maps: const <MapData>[],
      resourceFingerprints: <String, String>{
        'project': computeAuthoringBytesFingerprint(
          bytes,
          logicalName: 'project.json',
        ),
      },
      resourceBytes: <String, List<int>>{'project': bytes},
      resourceStorageKeys: const <String, String>{'project': 'project.json'},
    ),
    expectedProject: manifest,
  );
}

final class _DraftGateway implements PresentationStudioDraftAuthoringGateway {
  _DraftGateway(this.draft);

  final PresentationCinematicDraft draft;

  @override
  Future<PresentationCinematicDraft> open(
    String projectRootPath, {
    required ProjectManifest expectedProject,
  }) async => draft;
}

final class _SequencedDraftGateway
    implements PresentationStudioDraftAuthoringGateway {
  _SequencedDraftGateway(this.drafts);

  final List<PresentationCinematicDraft> drafts;
  int openCalls = 0;

  @override
  Future<PresentationCinematicDraft> open(
    String projectRootPath, {
    required ProjectManifest expectedProject,
  }) async => drafts[openCalls++];
}
