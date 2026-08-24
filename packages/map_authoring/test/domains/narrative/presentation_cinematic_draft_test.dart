import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('applies consecutive Presentation actions without mutating the baseline',
      () {
    final baseline = _manifest();
    final draft = PresentationCinematicDraft.fromSnapshot(
      _snapshot(baseline),
      expectedProject: baseline,
    );

    final first = draft.apply(
      actionId: 'presentationClip.update',
      parameters: <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'text',
        'clip': encodePresentationClip(
          _textClip(content: 'Premier brouillon'),
        ),
      },
      operationId: 'edit-1',
    );
    final second = draft.apply(
      actionId: 'presentationClip.update',
      parameters: <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'text',
        'clip': encodePresentationClip(
          _textClip(content: 'Dernier brouillon'),
        ),
      },
      operationId: 'edit-2',
    );

    expect(_content(baseline), 'Initial');
    expect(_content(first), 'Premier brouillon');
    expect(_content(second), 'Dernier brouillon');
    expect(draft.manifest, second);
  });

  test('projects a Presentation action without re-decoding project.json', () {
    final baseline = _manifest();
    final draft = PresentationCinematicDraft.fromSnapshot(
      _snapshot(baseline),
      expectedProject: baseline,
    );

    final projected = draft.apply(
      actionId: 'presentationClip.update',
      parameters: <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'text',
        'clip': encodePresentationClip(_textClip(content: 'Sans aller-retour')),
      },
      operationId: 'edit-1',
    );

    // The action already holds the projected manifest: the draft must adopt
    // that instance instead of re-parsing the bytes it just serialised. On a
    // ten-megabyte project the round trip costs hundreds of milliseconds of
    // frozen UI per edit.
    final mutation = const PresentationCinematicActions().build(
      _planningContext(
        _snapshot(baseline),
        actionId: 'presentationClip.update',
        parameters: <String, Object?>{
          'cinematicId': 'opening',
          'trackId': 'text',
          'clip': encodePresentationClip(
            _textClip(content: 'Sans aller-retour'),
          ),
        },
        operationId: 'edit-1',
      ),
    );

    expect(mutation.projectedProject, isNotNull);
    expect(mutation.projectedProject, projected);
    expect(_content(projected), 'Sans aller-retour');
  });

  test('rejects a draft opened from a stale visible project', () {
    final baseline = _manifest();
    final stale = baseline.copyWith(name: 'Projet externe');

    expect(
      () => PresentationCinematicDraft.fromSnapshot(
        _snapshot(baseline),
        expectedProject: stale,
      ),
      throwsA(isA<PresentationCinematicDraftException>()),
    );
  });

  test('authors cue branches from the Studio draft, and nothing else of Scene',
      () {
    final baseline = _manifestWithCue();
    final draft = PresentationCinematicDraft.fromSnapshot(
      _snapshot(baseline),
      expectedProject: baseline,
    );

    final projected = draft.apply(
      actionId: 'scene.presentation.cue.routes.set',
      parameters: <String, Object?>{
        'sceneId': 'intro',
        'presentationNodeId': 'presentation',
        'markerId': 'cue_confirm',
        'routes': <Object?>[
          <String, Object?>{
            'outputPortId': 'declined',
            'outcome': <String, Object?>{
              'kind': 'repeatFromMarker',
              'markerId': 'cue_confirm',
            },
          },
        ],
      },
      operationId: 'routes-1',
    );

    final payload = projected.scenes.single.graph.nodes
        .singleWhere((node) => node.id == 'presentation')
        .payload as ScenePresentationCinematicPayload;
    expect(
      payload.interactionCueBindings.single.outcomeRoutes.single.outputPortId,
      'declined',
      reason: 'the Studio panel writes the Scene binding through the '
          'headless action, never by mutating the model itself',
    );

    expect(
      () => draft.apply(
        actionId: 'scene.delete',
        parameters: const <String, Object?>{'sceneId': 'intro'},
        operationId: 'forbidden-1',
      ),
      throwsA(anything),
      reason: 'the allowance is one action wide: the Presentation Studio is '
          'not a Scene editor',
    );
  });

}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Draft test',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 5000000,
          layers: <PresentationLayer>[
            PresentationLayer(id: 'title', label: 'Title', zIndex: 0),
          ],
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'text',
              label: 'Text',
              kind: PresentationTrackKind.visual,
              clips: <PresentationClip>[_textClip(content: 'Initial')],
            ),
          ],
        ),
      ],
    );

ProjectManifest _manifestWithCue() {
  final base = _manifest();
  return base.copyWith(
    scenes: <SceneAsset>[
      SceneAsset(
        id: 'intro',
        name: 'Pré-session',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'presentation',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                presentationCinematicId: 'opening',
                interactionCueBindings: <ScenePresentationInteractionCueBinding>[
                  ScenePresentationInteractionCueBinding(
                    markerId: 'cue_confirm',
                    awaitableNodeId: 'confirm',
                  ),
                ],
              ),
            ),
            SceneNode(
              id: 'confirm',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.preSessionInteraction(
                ScenePreSessionInteractionSpec.confirmation(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'newGame.confirm',
                    fallbackText: 'On garde ce nom ?',
                  ),
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: <SceneEdge>[
            SceneEdge(
              id: 'start_presentation',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'presentation',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'presentation_end',
              fromNodeId: 'presentation',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.presentationCompleted,
            ),
          ],
        ),
      ),
    ],
  );
}

PresentationTextClip _textClip({required String content}) =>
    PresentationTextClip(
      id: 'title',
      startUs: 0,
      durationUs: 3000000,
      layerId: 'title',
      text: content,
    );

String _content(ProjectManifest manifest) =>
    (manifest.presentationCinematics.single.tracks.single.clips.single
            as PresentationTextClip)
        .text;

ProjectSnapshot _snapshot(ProjectManifest manifest) {
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('draft-test'),
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
    resourceStorageKeys: const <String, String>{'project': 'project.json'},
  );
}

AuthoringPlanningContext _planningContext(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
  required String operationId,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: operationId,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace-presentation-draft',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: operationId,
      ),
      planId: 'plan-$operationId',
      seed: 0,
    );
