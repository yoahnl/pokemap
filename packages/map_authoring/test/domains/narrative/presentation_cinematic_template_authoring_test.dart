import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Presentation cinematic template authoring', () {
    test('publishes the six templates as queryable resources', () {
      const service = ProjectQueryService();
      final page = service.query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationCinematicTemplate',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );

      expect(page.totalAvailable, 6);
      expect(
        page.items.map((item) => item['id']),
        <String>[
          'blank',
          'titleIdentity',
          'immersiveOpening',
          'stagedStory',
          'interactivePath',
          'adaptiveVideo',
        ],
      );
      expect(
        page.items.every(
          (item) =>
              (item['compositions']! as List<Object?>).length == 2 &&
              item['resourceKind'] == 'presentationCinematicTemplate',
        ),
        isTrue,
      );
    });

    test('instantiates every recipe deterministically without fake media', () {
      final catalog = PresentationCinematicTemplateCatalog.canonical();

      for (final template in catalog.templates) {
        final first = _instantiate(
          templateId: template.id,
          templateVersion: template.version,
        );
        final second = _instantiate(
          templateId: template.id,
          templateVersion: template.version,
        );
        final firstAsset = first.presentationCinematics.single;
        final secondAsset = second.presentationCinematics.single;

        expect(firstAsset, secondAsset, reason: template.id);
        expect(firstAsset.durationUs, template.defaultDurationUs);
        expect(
          firstAsset.tracks.expand((track) => track.clips).where(
                (clip) =>
                    clip is PresentationVisualClip ||
                    clip is PresentationAudioClip ||
                    clip is PresentationCaptionClip,
              ),
          isEmpty,
          reason: template.id,
        );
        expect(
          decodePresentationCinematicAsset(
            encodePresentationCinematicAsset(firstAsset),
          ),
          firstAsset,
          reason: template.id,
        );
      }
    });

    test('keeps the approved semantic skeletons editable', () {
      final title = _instantiate(templateId: 'titleIdentity')
          .presentationCinematics
          .single;
      final interactive = _instantiate(templateId: 'interactivePath')
          .presentationCinematics
          .single;
      final video = _instantiate(templateId: 'adaptiveVideo')
          .presentationCinematics
          .single;

      expect(
        title.layers.map((layer) => layer.id),
        <String>['background', 'identity', 'title', 'subtitle'],
      );
      expect(
        interactive.tracks
            .expand((track) => track.clips)
            .whereType<PresentationMarkerClip>()
            .single
            .markerKind,
        PresentationMarkerKind.interactionCue,
      );
      expect(
          video.layers.map((layer) => layer.id), <String>['poster', 'video']);
      expect(
        video.tracks.map((track) => track.kind),
        containsAll(<PresentationTrackKind>{
          PresentationTrackKind.visual,
          PresentationTrackKind.audio,
          PresentationTrackKind.caption,
          PresentationTrackKind.marker,
        }),
      );
    });

    test('rejects unknown template identity and version before creation', () {
      expect(
        () => _instantiate(templateId: 'unknown'),
        throwsA(
          isA<PresentationCinematicTemplateAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation_cinematic_template.unknown',
          ),
        ),
      );
      expect(
        () => _instantiate(templateId: 'blank', templateVersion: 2),
        throwsA(
          isA<PresentationCinematicTemplateAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation_cinematic_template.version_unsupported',
          ),
        ),
      );
    });

    test('registers instantiate with canonical transaction guarantees', () {
      final descriptor =
          AuthoringMutationDispatcher.canonical().descriptors.singleWhere(
                (candidate) =>
                    candidate.id == 'presentationCinematicTemplate.instantiate',
              );

      expect(
        descriptor.resourceKinds,
        containsAll(<String>[
          'project',
          'presentationCinematic',
          'presentationCinematicTemplate',
        ]),
      );
      expect(
        descriptor.guarantees,
        containsAll(<AuthoringGuarantee>{
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        }),
      );
    });
  });
}

ProjectManifest _instantiate({
  required String templateId,
  int templateVersion = 1,
}) {
  final snapshot = _snapshot();
  final draft = const PresentationCinematicTemplateActions().build(
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request-template',
        actionId: 'presentationCinematicTemplate.instantiate',
        actionVersion: 1,
        workspaceHandle: 'workspace-template',
        parameters: <String, Object?>{
          'templateId': templateId,
          'templateVersion': templateVersion,
          'cinematicId': 'opening',
          'title': 'Opening',
          'description': null,
        },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'instantiate-template',
      ),
      planId: 'plan-template',
      seed: 1,
    ),
  );
  final bytes = draft.changeSet.changes.single.afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Presentation template fixture',
    version: ProjectVersion.v7,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_presentation_template'),
    revision: 'sha256:${List<String>.filled(64, 'a').join()}',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
    },
    resourceBytes: <String, List<int>>{'project': projectBytes},
  );
}
