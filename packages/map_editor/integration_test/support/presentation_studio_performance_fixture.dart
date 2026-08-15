import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class PresentationStudioPerformanceFixture {
  PresentationStudioPerformanceFixture._({
    required this.name,
    required this.project,
    required this.target,
    required this.folderIds,
    required this.libraryAssets,
    required this.layers,
    required this.tracks,
    required this.clips,
  });

  factory PresentationStudioPerformanceFixture.build({
    required String name,
    required int libraryAssets,
    required int layers,
    required int tracks,
    required int clips,
  }) {
    const durationUs = 15 * 60 * 1000000;
    final target = _targetAsset(
      name: name,
      durationUs: durationUs,
      layers: layers,
      tracks: tracks,
      clips: clips,
    );
    final assets = <PresentationCinematicAsset>[
      target,
      for (var index = 1; index < libraryAssets; index++)
        PresentationCinematicAsset(
          id: 'presentation-$name-$index',
          title: 'Cinématique $name ${index.toString().padLeft(4, '0')}',
          durationUs: const Duration(seconds: 12).inMicroseconds,
        ),
    ];
    final folderIds = <String>[
      for (var index = 0; index < 8; index++) '$name-folder-$index',
    ];
    final folders = <CinematicLibraryFolder>[
      for (var index = 0; index < folderIds.length; index++)
        CinematicLibraryFolder(
          id: folderIds[index],
          family: CinematicLibraryFamily.presentation,
          name: 'Dossier $name ${index + 1}',
          parentFolderId: index == 0 ? null : folderIds[index - 1],
          sortOrder: 0,
        ),
    ];
    final project = ProjectManifest(
      name: 'CIN-060 $name',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: assets,
      cinematicLibraryCatalog: CinematicLibraryCatalog(
        folders: folders,
        entries: <CinematicLibraryEntry>[
          for (var index = 0; index < assets.length; index++)
            CinematicLibraryEntry(
              family: CinematicLibraryFamily.presentation,
              cinematicId: assets[index].id,
              folderId: folderIds.last,
              sortOrder: index,
            ),
        ],
      ),
    );
    return PresentationStudioPerformanceFixture._(
      name: name,
      project: project,
      target: target,
      folderIds: List<String>.unmodifiable(folderIds),
      libraryAssets: libraryAssets,
      layers: layers,
      tracks: tracks,
      clips: clips,
    );
  }

  final String name;
  final ProjectManifest project;
  final PresentationCinematicAsset target;
  final List<String> folderIds;
  final int libraryAssets;
  final int layers;
  final int tracks;
  final int clips;

  Map<String, Object?> toContractJson() => <String, Object?>{
    'name': name,
    'libraryAssets': libraryAssets,
    'layers': layers,
    'tracks': tracks,
    'clips': clips,
    'durationUs': target.durationUs,
  };
}

PresentationCinematicAsset _targetAsset({
  required String name,
  required int durationUs,
  required int layers,
  required int tracks,
  required int clips,
}) {
  final layerEntries = <PresentationLayer>[
    for (var index = 0; index < layers; index++)
      PresentationLayer(
        id: '$name-layer-$index',
        label: 'Calque ${index + 1}',
        zIndex: index,
      ),
  ];
  final visualTracks = math.max(1, tracks - 3);
  final trackEntries = <PresentationTrack>[
    for (var trackIndex = 0; trackIndex < tracks; trackIndex++)
      _track(
        name: name,
        trackIndex: trackIndex,
        kind: trackIndex < visualTracks
            ? PresentationTrackKind.visual
            : switch (trackIndex - visualTracks) {
                0 => PresentationTrackKind.audio,
                1 => PresentationTrackKind.caption,
                _ => PresentationTrackKind.marker,
              },
        clipCount: clips ~/ tracks + (trackIndex < clips % tracks ? 1 : 0),
        durationUs: durationUs,
        layerId: layerEntries[trackIndex % layerEntries.length].id,
      ),
  ];
  return PresentationCinematicAsset(
    id: 'presentation-$name-target',
    title: 'Needle $name',
    description: 'Fixture CIN-060 $name',
    durationUs: durationUs,
    layers: layerEntries,
    tracks: trackEntries,
  );
}

PresentationTrack _track({
  required String name,
  required int trackIndex,
  required PresentationTrackKind kind,
  required int clipCount,
  required int durationUs,
  required String layerId,
}) {
  final stepUs = durationUs ~/ math.max(1, clipCount);
  final clipDurationUs = math.max(1, stepUs ~/ 2);
  return PresentationTrack(
    id: '$name-track-$trackIndex',
    label: 'Piste ${trackIndex + 1}',
    kind: kind,
    clips: <PresentationClip>[
      for (var clipIndex = 0; clipIndex < clipCount; clipIndex++)
        _clip(
          id: '$name-clip-$trackIndex-$clipIndex',
          kind: kind,
          startUs: clipIndex * stepUs,
          durationUs: clipDurationUs,
          layerId: layerId,
        ),
    ],
  );
}

PresentationClip _clip({
  required String id,
  required PresentationTrackKind kind,
  required int startUs,
  required int durationUs,
  required String layerId,
}) => switch (kind) {
  PresentationTrackKind.visual => PresentationVisualClip(
    id: id,
    startUs: startUs,
    durationUs: durationUs,
    layerId: layerId,
    resourceId: '$id-landscape.png',
    landscapeResourceId: '$id-landscape.png',
    portraitResourceId: '$id-portrait.png',
  ),
  PresentationTrackKind.audio => PresentationAudioClip(
    id: id,
    startUs: startUs,
    durationUs: durationUs,
    resourceId: '$id.ogg',
    audioKind: PresentationAudioKind.soundEffect,
    bus: PresentationAudioBus.effects,
  ),
  PresentationTrackKind.caption => PresentationCaptionClip(
    id: id,
    startUs: startUs,
    durationUs: durationUs,
    captionId: '$id.vtt',
    locale: 'fr',
  ),
  PresentationTrackKind.marker => PresentationMarkerClip(
    id: id,
    startUs: startUs,
    label: 'Repère $id',
  ),
};
