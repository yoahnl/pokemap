import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../assets/asset_actions.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class DialogueAudioMediaActions {
  const DialogueAudioMediaActions(
      {required this.artifactStore,
      this.probe = const PresentationMediaHeaderProbe()});

  final ArtifactStore artifactStore;
  final PresentationMediaProbePort probe;

  static final descriptors = [
    narrativeActionDescriptor('scene.dialogue.audioMedia.import',
        'Atomically import a probed dialogue sound or looping cinematic music',
        extensions: const {
          'parameterNames': [
            'artifactHandle',
            'assetId',
            'mediaId',
            'label',
            'logicalPath',
            'mediaKind'
          ],
          'mediaKind': {
            'values': ['sound', 'music'],
            'default': 'sound',
            'musicLoops': true,
            'explicitNull': 'rejected'
          },
        },
        resourceKinds: const [
          'project',
          'cinematicMediaAsset',
          'assetCatalog',
          'assetBlob',
          'asset'
        ])
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final parameters = context.request.parameters;
    rejectUnknownNarrativeParameters(parameters, const {
      'artifactHandle',
      'assetId',
      'mediaId',
      'label',
      'logicalPath',
      'mediaKind'
    });
    final kind = parameters.containsKey('mediaKind')
        ? switch (parameters['mediaKind']) {
            'sound' => CinematicMediaAssetKind.sound,
            'music' => CinematicMediaAssetKind.music,
            final value => throw ArgumentError.value(
                value, 'mediaKind', 'must be sound or music'),
          }
        : CinematicMediaAssetKind.sound;
    final mediaId = narrativeStringParameter(parameters, 'mediaId');
    final assetId = narrativeStringParameter(parameters, 'assetId');
    final label = narrativeStringParameter(parameters, 'label');
    final logicalPath = narrativeStringParameter(parameters, 'logicalPath');
    final handle = narrativeStringParameter(parameters, 'artifactHandle');
    if (context.snapshot.manifest.cinematicMediaAssets
        .any((asset) => asset.id == mediaId)) {
      throw NarrativeAuthoringException('scene.dialogue.audio_media.conflict',
          'A dialogue sound already owns this identity.');
    }
    final artifact = artifactStore.inspect(handle);
    if (artifact == null) {
      throw const ArtifactStoreException('artifact.unknown',
          'The dialogue sound requires an admitted artifact.');
    }
    final bytes = await artifactStore.read(handle);
    final inspected =
        probe.inspect(bytes, declaredMediaType: artifact.mediaType);
    if (!inspected.mediaType.startsWith('audio/') ||
        inspected.durationMilliseconds == null ||
        inspected.durationMilliseconds! < 1) {
      throw NarrativeAuthoringException(
          'scene.dialogue.audio_media.unsupported',
          'A dialogue sound requires a probed audio file with a finite duration.');
    }
    final assetDraft = await AssetActions(artifactStore: artifactStore).build(
        AuthoringPlanningContext(
            snapshot: context.snapshot,
            planId: context.planId,
            seed: context.seed,
            request: AuthoringRequest(
                requestId: context.request.requestId,
                actionId: 'asset.import',
                actionVersion: 1,
                workspaceHandle: context.request.workspaceHandle,
                parameters: {
                  'artifactHandle': handle,
                  'assetId': assetId,
                  'logicalPath': logicalPath,
                  'usages': [
                    kind == CinematicMediaAssetKind.music
                        ? 'cinematicMusic'
                        : 'dialogueAudio'
                  ],
                })));
    final media = CinematicMediaAsset(
        id: mediaId,
        label: label,
        kind: kind,
        loopByDefault: kind == CinematicMediaAssetKind.music,
        relativePath: logicalPath,
        durationMs: inspected.durationMilliseconds,
        metadata: {
          'sourceAssetId': assetId,
          'mediaType': inspected.mediaType,
          'container': inspected.container,
          'codec': inspected.codec,
        });
    final projectDraft = narrativeProjectDraft(
        context.snapshot,
        context.snapshot.manifest.copyWith(cinematicMediaAssets: [
          ...context.snapshot.manifest.cinematicMediaAssets,
          media
        ]),
        operation: context.request.actionId,
        path: '/cinematicMediaAssets/$mediaId',
        after: media.toJson());
    return AuthoringMutationDraft(
        projectedProject: projectDraft.projectedProject,
        changeSet: AuthoringChangeSet(
            changes: [
              ...assetDraft.changeSet.changes,
              ...projectDraft.changeSet.changes
            ],
            diff: AuthoringDiff([
              ...assetDraft.changeSet.diff.entries,
              ...projectDraft.changeSet.diff.entries
            ])),
        preview: {
          ...projectDraft.preview,
          'assetId': assetId,
          'media': media.toJson()
        },
        artifacts: assetDraft.artifacts);
  }
}
