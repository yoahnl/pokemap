import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/project_media_store.dart';
import 'narrative_action_support.dart';

final class PresentationCinematicAuthoringException implements Exception {
  PresentationCinematicAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() =>
      'PresentationCinematicAuthoringException($code): $message';
}

final class PresentationCinematicActions {
  const PresentationCinematicActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      for (final action in const <(String, String, String, AuthoringRiskLevel)>[
        (
          'presentationCinematic.create',
          'Create one Presentation cinematic',
          'presentationCinematic',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationCinematic.update',
          'Update Presentation cinematic metadata and duration',
          'presentationCinematic',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationCinematic.duplicate',
          'Duplicate one Presentation cinematic',
          'presentationCinematic',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationCinematic.delete',
          'Delete one unreferenced Presentation cinematic',
          'presentationCinematic',
          AuthoringRiskLevel.high,
        ),
        (
          'presentationTrack.create',
          'Create one typed Presentation track',
          'presentationTrack',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationTrack.update',
          'Update one typed Presentation track',
          'presentationTrack',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationTrack.move',
          'Move one Presentation track in timeline order',
          'presentationTrack',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationTrack.duplicate',
          'Duplicate one Presentation track and its clips',
          'presentationTrack',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationTrack.delete',
          'Delete one Presentation track',
          'presentationTrack',
          AuthoringRiskLevel.high,
        ),
        (
          'presentationClip.create',
          'Create one Presentation clip',
          'presentationClip',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationClip.update',
          'Update one Presentation clip',
          'presentationClip',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationClip.move',
          'Move one Presentation clip in time or between compatible tracks',
          'presentationClip',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationClip.resize',
          'Resize one temporal Presentation clip',
          'presentationClip',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationClip.duplicate',
          'Duplicate one Presentation clip',
          'presentationClip',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationClip.delete',
          'Delete one Presentation clip',
          'presentationClip',
          AuthoringRiskLevel.high,
        ),
        (
          'presentationLayer.create',
          'Create one Presentation visual layer',
          'presentationLayer',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationLayer.update',
          'Update one Presentation visual layer',
          'presentationLayer',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationLayer.move',
          'Move one Presentation visual layer in z-order',
          'presentationLayer',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationLayer.duplicate',
          'Duplicate one Presentation visual layer',
          'presentationLayer',
          AuthoringRiskLevel.low,
        ),
        (
          'presentationLayer.delete',
          'Delete one unused Presentation visual layer',
          'presentationLayer',
          AuthoringRiskLevel.high,
        ),
      ])
        _descriptor(action),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    _requireProjectV7(context);
    try {
      final mutation = switch (context.request.actionId) {
        'presentationCinematic.create' => _createCinematic(context),
        'presentationCinematic.update' => _updateCinematic(context),
        'presentationCinematic.duplicate' => _duplicateCinematic(context),
        'presentationCinematic.delete' => _deleteCinematic(context),
        'presentationTrack.create' => _createTrack(context),
        'presentationTrack.update' => _updateTrack(context),
        'presentationTrack.move' => _moveTrack(context),
        'presentationTrack.duplicate' => _duplicateTrack(context),
        'presentationTrack.delete' => _deleteTrack(context),
        'presentationClip.create' => _createClip(context),
        'presentationClip.update' => _updateClip(context),
        'presentationClip.move' => _moveClip(context),
        'presentationClip.resize' => _resizeClip(context),
        'presentationClip.duplicate' => _duplicateClip(context),
        'presentationClip.delete' => _deleteClip(context),
        'presentationLayer.create' => _createLayer(context),
        'presentationLayer.update' => _updateLayer(context),
        'presentationLayer.move' => _moveLayer(context),
        'presentationLayer.duplicate' => _duplicateLayer(context),
        'presentationLayer.delete' => _deleteLayer(context),
        _ => throw PresentationCinematicAuthoringException(
            'presentation_cinematic.action_unsupported',
            'The requested Presentation cinematic action is unsupported.',
            details: <String, Object?>{
              'actionId': context.request.actionId,
            },
          ),
      };
      _validateReferences(
        context,
        mutation.project,
        cinematicId: mutation.cinematicId,
      );
      return narrativeProjectDraft(
        context.snapshot,
        mutation.project,
        operation: context.request.actionId,
        path: mutation.path,
        before: mutation.before,
        after: mutation.after,
        preview: <String, Object?>{
          'resourceKind': mutation.resourceKind,
          'cinematicId': mutation.cinematicId,
        },
      );
    } on PresentationCinematicAuthoringException {
      rethrow;
    } on PresentationCinematicCodecException catch (error) {
      throw PresentationCinematicAuthoringException(
        'presentation_cinematic.payload_invalid',
        'The Presentation cinematic payload is invalid.',
        details: <String, Object?>{
          'codecCode': error.code.name,
          'path': error.path,
        },
      );
    } on PresentationCinematicValidationException catch (error) {
      throw PresentationCinematicAuthoringException(
        'presentation_cinematic.validation_failed',
        error.message,
        details: <String, Object?>{
          'validationCode': error.code.name,
          'path': error.path,
        },
      );
    } on ArgumentError catch (error) {
      throw PresentationCinematicAuthoringException(
        'presentation_cinematic.request_invalid',
        error.message?.toString() ?? 'The request is invalid.',
      );
    } on FormatException catch (error) {
      throw PresentationCinematicAuthoringException(
        'presentation_cinematic.request_invalid',
        error.message.toString(),
      );
    }
  }
}

_PresentationMutation _createCinematic(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'title', 'description', 'durationUs'},
  );
  final project = context.snapshot.manifest;
  final cinematicId = _string(parameters, 'cinematicId');
  _requireAvailableCinematicId(project, cinematicId);
  final cinematic = PresentationCinematicAsset(
    id: cinematicId,
    title: _string(parameters, 'title'),
    description: _optionalString(parameters, 'description'),
    durationUs: _integer(parameters, 'durationUs'),
  );
  return _PresentationMutation(
    project: project.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        ...project.presentationCinematics,
        cinematic,
      ],
    ),
    cinematicId: cinematicId,
    resourceKind: 'presentationCinematic',
    path: '/presentationCinematics/$cinematicId',
    after: encodePresentationCinematicAsset(cinematic),
  );
}

_PresentationMutation _updateCinematic(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'title', 'description', 'durationUs'},
  );
  final project = context.snapshot.manifest;
  final cinematicId = _string(parameters, 'cinematicId');
  final current = _requireCinematic(project, cinematicId);
  final updated = PresentationCinematicAsset(
    id: current.id,
    title: _string(parameters, 'title'),
    description: _optionalString(parameters, 'description'),
    durationUs: _integer(parameters, 'durationUs'),
    layers: current.layers,
    tracks: current.tracks,
  );
  return _assetMutation(
    project,
    current: current,
    updated: updated,
    resourceKind: 'presentationCinematic',
    path: '/presentationCinematics/$cinematicId',
  );
}

_PresentationMutation _duplicateCinematic(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'duplicateId', 'title'},
  );
  final project = context.snapshot.manifest;
  final source = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final duplicateId = _string(parameters, 'duplicateId');
  _requireAvailableCinematicId(project, duplicateId);
  final duplicate = PresentationCinematicAsset(
    id: duplicateId,
    title: _string(parameters, 'title'),
    description: source.description,
    durationUs: source.durationUs,
    layers: source.layers,
    tracks: <PresentationTrack>[
      for (final track in source.tracks)
        PresentationTrack(
          id: track.id,
          label: track.label,
          kind: track.kind,
          clips: <PresentationClip>[
            for (final clip in track.clips)
              _copyClip(clip, id: '$duplicateId-${clip.id}'),
          ],
        ),
    ],
  );
  return _PresentationMutation(
    project: project.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        ...project.presentationCinematics,
        duplicate,
      ],
    ),
    cinematicId: duplicateId,
    resourceKind: 'presentationCinematic',
    path: '/presentationCinematics/$duplicateId',
    after: encodePresentationCinematicAsset(duplicate),
  );
}

_PresentationMutation _deleteCinematic(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'cinematicId'});
  final project = context.snapshot.manifest;
  final cinematicId = _string(parameters, 'cinematicId');
  final current = _requireCinematic(project, cinematicId);
  final plan = PresentationReferenceGraph.build(
    cinematics: project.presentationCinematics,
    scenes: project.scenes,
  ).planDeletion(PresentationReferenceKey.presentationCinematic(cinematicId));
  if (!plan.canDelete) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.in_use',
      'The Presentation cinematic is still referenced.',
      details: <String, Object?>{
        'usages': <Object?>[
          for (final usage in plan.usages) usage.toJson(),
        ],
      },
    );
  }
  return _PresentationMutation(
    project: project.copyWith(
      presentationCinematics: <PresentationCinematicAsset>[
        for (final cinematic in project.presentationCinematics)
          if (cinematic.id != cinematicId) cinematic,
      ],
    ),
    cinematicId: cinematicId,
    resourceKind: 'presentationCinematic',
    path: '/presentationCinematics/$cinematicId',
    before: encodePresentationCinematicAsset(current),
  );
}

_PresentationMutation _createTrack(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'cinematicId', 'track'});
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final track = _decodeTrack(cinematic, _object(parameters, 'track'));
  final updated = _copyCinematic(
    cinematic,
    tracks: <PresentationTrack>[...cinematic.tracks, track],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationTrack',
    path: '/presentationCinematics/${cinematic.id}/tracks/${track.id}',
    before: null,
    after: _encodedTrack(updated, updated.tracks.length - 1),
  );
}

_PresentationMutation _updateTrack(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'cinematicId', 'track'});
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final track = _decodeTrack(cinematic, _object(parameters, 'track'));
  final index = _trackIndex(cinematic, track.id);
  final tracks = cinematic.tracks.toList()..[index] = track;
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationTrack',
    path: '/presentationCinematics/${cinematic.id}/tracks/${track.id}',
    before: _encodedTrack(cinematic, index),
    after: _encodedTrack(updated, index),
  );
}

_PresentationMutation _moveTrack(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'trackId', 'insertionIndex'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final trackId = _string(parameters, 'trackId');
  final index = _trackIndex(cinematic, trackId);
  final tracks = cinematic.tracks.toList();
  final moved = tracks.removeAt(index);
  final insertionIndex = _integer(parameters, 'insertionIndex');
  if (insertionIndex < 0 || insertionIndex > tracks.length) {
    throw PresentationCinematicAuthoringException(
      'presentation_track.insertion_index_invalid',
      'The Presentation track insertion index is outside the timeline.',
    );
  }
  tracks.insert(insertionIndex, moved);
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationTrack',
    path: '/presentationCinematics/${cinematic.id}/tracks/$trackId',
    before: _encodedTrack(cinematic, index),
    after: _encodedTrack(updated, insertionIndex),
  );
}

_PresentationMutation _duplicateTrack(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'trackId', 'duplicateId', 'label'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final source = cinematic.tracks[_trackIndex(
    cinematic,
    _string(parameters, 'trackId'),
  )];
  final duplicateId = _string(parameters, 'duplicateId');
  if (cinematic.tracks.any((track) => track.id == duplicateId)) {
    throw PresentationCinematicAuthoringException(
      'presentation_track.id_conflict',
      'The duplicate Presentation track identity already exists.',
    );
  }
  final duplicate = PresentationTrack(
    id: duplicateId,
    label: _string(parameters, 'label'),
    kind: source.kind,
    clips: <PresentationClip>[
      for (final clip in source.clips)
        _copyClip(clip, id: '$duplicateId-${clip.id}'),
    ],
  );
  final updated = _copyCinematic(
    cinematic,
    tracks: <PresentationTrack>[...cinematic.tracks, duplicate],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationTrack',
    path: '/presentationCinematics/${cinematic.id}/tracks/$duplicateId',
    before: null,
    after: _encodedTrack(updated, updated.tracks.length - 1),
  );
}

_PresentationMutation _deleteTrack(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'trackId'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final trackId = _string(parameters, 'trackId');
  final index = _trackIndex(cinematic, trackId);
  final before = _encodedTrack(cinematic, index);
  final updated = _copyCinematic(
    cinematic,
    tracks: <PresentationTrack>[
      for (final track in cinematic.tracks)
        if (track.id != trackId) track,
    ],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationTrack',
    path: '/presentationCinematics/${cinematic.id}/tracks/$trackId',
    before: before,
    after: null,
  );
}

_PresentationMutation _createClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'trackId', 'clip'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final trackIndex = _trackIndex(cinematic, _string(parameters, 'trackId'));
  final clip = _decodeClip(
    cinematic,
    trackIndex,
    _object(parameters, 'clip'),
  );
  final tracks = cinematic.tracks.toList();
  final track = tracks[trackIndex];
  tracks[trackIndex] = _copyTrack(
    track,
    clips: <PresentationClip>[...track.clips, clip],
  );
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path:
        '/presentationCinematics/${cinematic.id}/tracks/${track.id}/clips/${clip.id}',
    before: null,
    after: _encodedClip(updated, trackIndex, track.clips.length),
  );
}

_PresentationMutation _updateClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'trackId', 'clip'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final trackIndex = _trackIndex(cinematic, _string(parameters, 'trackId'));
  final clip = _decodeClip(
    cinematic,
    trackIndex,
    _object(parameters, 'clip'),
  );
  final clipIndex = _clipIndex(cinematic.tracks[trackIndex], clip.id);
  final tracks = cinematic.tracks.toList();
  final clips = tracks[trackIndex].clips.toList()..[clipIndex] = clip;
  tracks[trackIndex] = _copyTrack(tracks[trackIndex], clips: clips);
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path:
        '/presentationCinematics/${cinematic.id}/tracks/${tracks[trackIndex].id}/clips/${clip.id}',
    before: _encodedClip(cinematic, trackIndex, clipIndex),
    after: _encodedClip(updated, trackIndex, clipIndex),
  );
}

_PresentationMutation _moveClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{
      'cinematicId',
      'clipId',
      'targetTrackId',
      'startUs',
    },
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final clipId = _string(parameters, 'clipId');
  final source = _clipLocation(cinematic, clipId);
  final targetTrackIndex = _trackIndex(
    cinematic,
    _string(parameters, 'targetTrackId'),
  );
  final moved = _copyClip(
    source.clip,
    startUs: _integer(parameters, 'startUs'),
  );
  final tracks = cinematic.tracks.toList();
  final sourceClips = tracks[source.trackIndex].clips.toList()
    ..removeAt(source.clipIndex);
  tracks[source.trackIndex] = _copyTrack(
    tracks[source.trackIndex],
    clips: sourceClips,
  );
  final targetClips = tracks[targetTrackIndex].clips.toList()..add(moved);
  tracks[targetTrackIndex] = _copyTrack(
    tracks[targetTrackIndex],
    clips: targetClips,
  );
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path: '/presentationCinematics/${cinematic.id}/clips/$clipId',
    before: _encodedClip(
      cinematic,
      source.trackIndex,
      source.clipIndex,
    ),
    after: _encodedClip(
      updated,
      targetTrackIndex,
      tracks[targetTrackIndex].clips.length - 1,
    ),
  );
}

_PresentationMutation _resizeClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'clipId', 'durationUs'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final location = _clipLocation(
    cinematic,
    _string(parameters, 'clipId'),
  );
  if (location.clip is PresentationMarkerClip) {
    throw PresentationCinematicAuthoringException(
      'presentation_clip.marker_resize_unsupported',
      'Presentation marker clips always have zero duration.',
    );
  }
  final resized = _copyClip(
    location.clip,
    durationUs: _integer(parameters, 'durationUs'),
  );
  final tracks = cinematic.tracks.toList();
  final clips = tracks[location.trackIndex].clips.toList()
    ..[location.clipIndex] = resized;
  tracks[location.trackIndex] = _copyTrack(
    tracks[location.trackIndex],
    clips: clips,
  );
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path: '/presentationCinematics/${cinematic.id}/clips/${resized.id}',
    before: _encodedClip(
      cinematic,
      location.trackIndex,
      location.clipIndex,
    ),
    after: _encodedClip(
      updated,
      location.trackIndex,
      location.clipIndex,
    ),
  );
}

_PresentationMutation _duplicateClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{
      'cinematicId',
      'clipId',
      'duplicateId',
      'targetTrackId',
      'startUs',
    },
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final source = _clipLocation(cinematic, _string(parameters, 'clipId'));
  final targetTrackIndex = _trackIndex(
    cinematic,
    _string(parameters, 'targetTrackId'),
  );
  final duplicate = _copyClip(
    source.clip,
    id: _string(parameters, 'duplicateId'),
    startUs: _integer(parameters, 'startUs'),
  );
  final tracks = cinematic.tracks.toList();
  final clips = tracks[targetTrackIndex].clips.toList()..add(duplicate);
  tracks[targetTrackIndex] = _copyTrack(
    tracks[targetTrackIndex],
    clips: clips,
  );
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path: '/presentationCinematics/${cinematic.id}/clips/${duplicate.id}',
    before: null,
    after: _encodedClip(
      updated,
      targetTrackIndex,
      tracks[targetTrackIndex].clips.length - 1,
    ),
  );
}

_PresentationMutation _deleteClip(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'clipId'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final location = _clipLocation(
    cinematic,
    _string(parameters, 'clipId'),
  );
  final before = _encodedClip(
    cinematic,
    location.trackIndex,
    location.clipIndex,
  );
  final tracks = cinematic.tracks.toList();
  final clips = tracks[location.trackIndex].clips.toList()
    ..removeAt(location.clipIndex);
  tracks[location.trackIndex] = _copyTrack(
    tracks[location.trackIndex],
    clips: clips,
  );
  final updated = _copyCinematic(cinematic, tracks: tracks);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationClip',
    path: '/presentationCinematics/${cinematic.id}/clips/${location.clip.id}',
    before: before,
    after: null,
  );
}

_PresentationMutation _createLayer(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'cinematicId', 'layer'});
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final layer = _decodeLayer(_object(parameters, 'layer'));
  final updated = _copyCinematic(
    cinematic,
    layers: <PresentationLayer>[...cinematic.layers, layer],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationLayer',
    path: '/presentationCinematics/${cinematic.id}/layers/${layer.id}',
    before: null,
    after: _encodedLayer(updated, updated.layers.length - 1),
  );
}

_PresentationMutation _updateLayer(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'cinematicId', 'layer'});
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final layer = _decodeLayer(_object(parameters, 'layer'));
  final index = _layerIndex(cinematic, layer.id);
  final layers = cinematic.layers.toList()..[index] = layer;
  final updated = _copyCinematic(cinematic, layers: layers);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationLayer',
    path: '/presentationCinematics/${cinematic.id}/layers/${layer.id}',
    before: _encodedLayer(cinematic, index),
    after: _encodedLayer(updated, index),
  );
}

_PresentationMutation _moveLayer(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'layerId', 'zIndex'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final layerId = _string(parameters, 'layerId');
  final index = _layerIndex(cinematic, layerId);
  final current = cinematic.layers[index];
  final moved = PresentationLayer(
    id: current.id,
    label: current.label,
    zIndex: _integer(parameters, 'zIndex'),
  );
  final layers = cinematic.layers.toList()..[index] = moved;
  final updated = _copyCinematic(cinematic, layers: layers);
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationLayer',
    path: '/presentationCinematics/${cinematic.id}/layers/$layerId',
    before: _encodedLayer(cinematic, index),
    after: _encodedLayer(updated, index),
  );
}

_PresentationMutation _duplicateLayer(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{
      'cinematicId',
      'layerId',
      'duplicateId',
      'label',
      'zIndex',
    },
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  _layerIndex(cinematic, _string(parameters, 'layerId'));
  final duplicate = PresentationLayer(
    id: _string(parameters, 'duplicateId'),
    label: _string(parameters, 'label'),
    zIndex: _integer(parameters, 'zIndex'),
  );
  final updated = _copyCinematic(
    cinematic,
    layers: <PresentationLayer>[...cinematic.layers, duplicate],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationLayer',
    path: '/presentationCinematics/${cinematic.id}/layers/${duplicate.id}',
    before: null,
    after: _encodedLayer(updated, updated.layers.length - 1),
  );
}

_PresentationMutation _deleteLayer(AuthoringPlanningContext context) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{'cinematicId', 'layerId'},
  );
  final project = context.snapshot.manifest;
  final cinematic = _requireCinematic(
    project,
    _string(parameters, 'cinematicId'),
  );
  final layerId = _string(parameters, 'layerId');
  final index = _layerIndex(cinematic, layerId);
  final usages = <String>[
    for (final track in cinematic.tracks)
      for (final clip in track.clips)
        if (clip is PresentationVisualClip && clip.layerId == layerId) clip.id,
  ];
  if (usages.isNotEmpty) {
    throw PresentationCinematicAuthoringException(
      'presentation_layer.in_use',
      'The Presentation layer is still referenced by visual clips.',
      details: <String, Object?>{'clipIds': usages},
    );
  }
  final before = _encodedLayer(cinematic, index);
  final updated = _copyCinematic(
    cinematic,
    layers: <PresentationLayer>[
      for (final layer in cinematic.layers)
        if (layer.id != layerId) layer,
    ],
  );
  return _assetMutation(
    project,
    current: cinematic,
    updated: updated,
    resourceKind: 'presentationLayer',
    path: '/presentationCinematics/${cinematic.id}/layers/$layerId',
    before: before,
    after: null,
  );
}

void _requireProjectV7(AuthoringPlanningContext context) {
  if (context.snapshot.manifest.version != ProjectVersion.v7) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.project_v7_required',
      'Presentation cinematic authoring requires ProjectVersion.v7.',
      details: <String, Object?>{
        'projectVersion': context.snapshot.manifest.version.name,
      },
    );
  }
}

void _validateReferences(
  AuthoringPlanningContext context,
  ProjectManifest projected, {
  required String cinematicId,
}) {
  final mediaBytes = context.snapshot.findResourceBytes(
    projectMediaCatalogResourceIdentity,
  );
  final mediaCatalog =
      mediaBytes == null ? null : decodeProjectMediaCatalogBytes(mediaBytes);
  final graph = PresentationReferenceGraph.build(
    cinematics: projected.presentationCinematics,
    scenes: projected.scenes,
    mediaCatalog: mediaCatalog,
  );
  final diagnostics = graph.diagnostics.where((diagnostic) {
    final owner = diagnostic.owner;
    return owner?.kind == PresentationReferenceKind.presentationCinematic &&
        owner?.id == cinematicId;
  }).toList(growable: false);
  if (diagnostics.isNotEmpty) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.references_invalid',
      'The Presentation cinematic contains unresolved media references.',
      details: <String, Object?>{
        'diagnostics': <Object?>[
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
      },
    );
  }
}

PresentationCinematicAsset _requireCinematic(
  ProjectManifest project,
  String cinematicId,
) {
  for (final cinematic in project.presentationCinematics) {
    if (cinematic.id == cinematicId) return cinematic;
  }
  throw PresentationCinematicAuthoringException(
    'presentation_cinematic.not_found',
    'The requested Presentation cinematic does not exist.',
    details: <String, Object?>{'cinematicId': cinematicId},
  );
}

void _requireAvailableCinematicId(ProjectManifest project, String id) {
  if (project.presentationCinematics.any((cinematic) => cinematic.id == id)) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.id_conflict',
      'The Presentation cinematic identity already exists.',
      details: <String, Object?>{'cinematicId': id},
    );
  }
}

PresentationCinematicAsset _copyCinematic(
  PresentationCinematicAsset cinematic, {
  List<PresentationLayer>? layers,
  List<PresentationTrack>? tracks,
}) =>
    PresentationCinematicAsset(
      id: cinematic.id,
      title: cinematic.title,
      description: cinematic.description,
      durationUs: cinematic.durationUs,
      layers: layers ?? cinematic.layers,
      tracks: tracks ?? cinematic.tracks,
    );

PresentationTrack _copyTrack(
  PresentationTrack track, {
  List<PresentationClip>? clips,
}) =>
    PresentationTrack(
      id: track.id,
      label: track.label,
      kind: track.kind,
      clips: clips ?? track.clips,
    );

PresentationClip _copyClip(
  PresentationClip clip, {
  String? id,
  int? startUs,
  int? durationUs,
}) =>
    switch (clip) {
      PresentationVisualClip() => PresentationVisualClip(
          id: id ?? clip.id,
          startUs: startUs ?? clip.startUs,
          durationUs: durationUs ?? clip.durationUs,
          layerId: clip.layerId,
          resourceId: clip.resourceId,
          easing: clip.easing,
          from: clip.from,
          to: clip.to,
          transitionIn: clip.transitionIn,
          transitionOut: clip.transitionOut,
        ),
      PresentationAudioClip() => PresentationAudioClip(
          id: id ?? clip.id,
          startUs: startUs ?? clip.startUs,
          durationUs: durationUs ?? clip.durationUs,
          resourceId: clip.resourceId,
        ),
      PresentationCaptionClip() => PresentationCaptionClip(
          id: id ?? clip.id,
          startUs: startUs ?? clip.startUs,
          durationUs: durationUs ?? clip.durationUs,
          captionId: clip.captionId,
        ),
      PresentationMarkerClip() => PresentationMarkerClip(
          id: id ?? clip.id,
          startUs: startUs ?? clip.startUs,
          label: clip.label,
          markerKind: clip.markerKind,
        ),
    };

PresentationTrack _decodeTrack(
  PresentationCinematicAsset cinematic,
  Map<String, Object?> rawTrack,
) {
  final encoded = encodePresentationCinematicAsset(cinematic);
  encoded['tracks'] = <Object?>[rawTrack];
  return decodePresentationCinematicAsset(encoded).tracks.single;
}

PresentationClip _decodeClip(
  PresentationCinematicAsset cinematic,
  int trackIndex,
  Map<String, Object?> rawClip,
) {
  final encoded = encodePresentationCinematicAsset(cinematic);
  final tracks = (encoded['tracks']! as List<Object?>)
      .map((track) => Map<String, Object?>.from(track! as Map))
      .toList(growable: false);
  tracks[trackIndex]['clips'] = <Object?>[rawClip];
  encoded['tracks'] = tracks;
  return decodePresentationCinematicAsset(encoded)
      .tracks[trackIndex]
      .clips
      .single;
}

PresentationLayer _decodeLayer(Map<String, Object?> rawLayer) {
  _requireExactParameters(rawLayer, const <String>{'id', 'label', 'zIndex'});
  return PresentationLayer(
    id: _string(rawLayer, 'id'),
    label: _string(rawLayer, 'label'),
    zIndex: _integer(rawLayer, 'zIndex'),
  );
}

int _trackIndex(PresentationCinematicAsset cinematic, String trackId) {
  final index = cinematic.tracks.indexWhere((track) => track.id == trackId);
  if (index < 0) {
    throw PresentationCinematicAuthoringException(
      'presentation_track.not_found',
      'The requested Presentation track does not exist.',
      details: <String, Object?>{'trackId': trackId},
    );
  }
  return index;
}

int _clipIndex(PresentationTrack track, String clipId) {
  final index = track.clips.indexWhere((clip) => clip.id == clipId);
  if (index < 0) {
    throw PresentationCinematicAuthoringException(
      'presentation_clip.not_found',
      'The requested Presentation clip does not exist.',
      details: <String, Object?>{'clipId': clipId},
    );
  }
  return index;
}

_ClipLocation _clipLocation(
  PresentationCinematicAsset cinematic,
  String clipId,
) {
  for (var trackIndex = 0;
      trackIndex < cinematic.tracks.length;
      trackIndex += 1) {
    final track = cinematic.tracks[trackIndex];
    final clipIndex = track.clips.indexWhere((clip) => clip.id == clipId);
    if (clipIndex >= 0) {
      return _ClipLocation(
        trackIndex: trackIndex,
        clipIndex: clipIndex,
        clip: track.clips[clipIndex],
      );
    }
  }
  throw PresentationCinematicAuthoringException(
    'presentation_clip.not_found',
    'The requested Presentation clip does not exist.',
    details: <String, Object?>{'clipId': clipId},
  );
}

int _layerIndex(PresentationCinematicAsset cinematic, String layerId) {
  final index = cinematic.layers.indexWhere((layer) => layer.id == layerId);
  if (index < 0) {
    throw PresentationCinematicAuthoringException(
      'presentation_layer.not_found',
      'The requested Presentation layer does not exist.',
      details: <String, Object?>{'layerId': layerId},
    );
  }
  return index;
}

Map<String, Object?> _encodedTrack(
  PresentationCinematicAsset cinematic,
  int index,
) =>
    Map<String, Object?>.from(
      (encodePresentationCinematicAsset(cinematic)['tracks']!
          as List<Object?>)[index]! as Map,
    );

Map<String, Object?> _encodedClip(
  PresentationCinematicAsset cinematic,
  int trackIndex,
  int clipIndex,
) {
  final track = _encodedTrack(cinematic, trackIndex);
  return Map<String, Object?>.from(
    (track['clips']! as List<Object?>)[clipIndex]! as Map,
  );
}

Map<String, Object?> _encodedLayer(
  PresentationCinematicAsset cinematic,
  int index,
) =>
    Map<String, Object?>.from(
      (encodePresentationCinematicAsset(cinematic)['layers']!
          as List<Object?>)[index]! as Map,
    );

_PresentationMutation _assetMutation(
  ProjectManifest project, {
  required PresentationCinematicAsset current,
  required PresentationCinematicAsset updated,
  required String resourceKind,
  required String path,
  Object? before = _useEncodedAsset,
  Object? after = _useEncodedAsset,
}) =>
    _PresentationMutation(
      project: project.copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          for (final cinematic in project.presentationCinematics)
            if (cinematic.id == updated.id) updated else cinematic,
        ],
      ),
      cinematicId: updated.id,
      resourceKind: resourceKind,
      path: path,
      before: identical(before, _useEncodedAsset)
          ? encodePresentationCinematicAsset(current)
          : before,
      after: identical(after, _useEncodedAsset)
          ? encodePresentationCinematicAsset(updated)
          : after,
    );

void _requireExactParameters(
  Map<String, Object?> parameters,
  Set<String> expected,
) {
  final actual = parameters.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.parameters_invalid',
      'The Presentation cinematic parameters do not match the action.',
      details: <String, Object?>{
        'expected': expected.toList()..sort(),
        'actual': actual.toList()..sort(),
      },
    );
  }
}

String _string(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.parameter_invalid',
      'Parameter $key must be a nonblank trimmed string.',
    );
  }
  return value;
}

String? _optionalString(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value == null) return null;
  return _string(parameters, key);
}

int _integer(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! int) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.parameter_invalid',
      'Parameter $key must be an integer.',
    );
  }
  return value;
}

Map<String, Object?> _object(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value is! Map || value.keys.any((item) => item is! String)) {
    throw PresentationCinematicAuthoringException(
      'presentation_cinematic.parameter_invalid',
      'Parameter $key must be an object.',
    );
  }
  return Map<String, Object?>.from(value);
}

final class _PresentationMutation {
  const _PresentationMutation({
    required this.project,
    required this.cinematicId,
    required this.resourceKind,
    required this.path,
    this.before,
    this.after,
  });

  final ProjectManifest project;
  final String cinematicId;
  final String resourceKind;
  final String path;
  final Object? before;
  final Object? after;
}

final class _ClipLocation {
  const _ClipLocation({
    required this.trackIndex,
    required this.clipIndex,
    required this.clip,
  });

  final int trackIndex;
  final int clipIndex;
  final PresentationClip clip;
}

const Object _useEncodedAsset = Object();

AuthoringActionDescriptor _descriptor(
  (String, String, String, AuthoringRiskLevel) action,
) =>
    AuthoringActionDescriptor(
      id: action.$1,
      version: 1,
      summary: action.$2,
      inputSchemaId: 'pokemap.authoring/${action.$1}.input.v1',
      outputSchemaId: 'pokemap.authoring/${action.$1}.output.v1',
      riskLevel: action.$4,
      resourceKinds: <String>['project', action.$3],
      capabilityIds: const <String>['authoring.cinematic.presentation'],
      requiredPermissions: const <AuthoringPermission>[
        AuthoringPermission.projectWrite,
      ],
      guarantees: const <AuthoringGuarantee>[
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );
