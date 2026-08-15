import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/authoring_api/presentation_studio_timeline_command.dart';

enum PresentationTimelineDragKind { move, trimStart, trimEnd }

typedef PresentationTimelineDuplicateIdFactory =
    String Function(String sourceId);

final class PresentationTimelineEditingController extends ChangeNotifier {
  PresentationTimelineEditingController({
    required PresentationCinematicAsset asset,
    this.snapIntervalUs = 100000,
    PresentationTimelineDuplicateIdFactory? duplicateIdFactory,
  }) : assert(snapIntervalUs > 0),
       _asset = asset,
       _duplicateIdFactory = duplicateIdFactory {
    _indexAsset();
  }

  final int snapIntervalUs;
  final PresentationTimelineDuplicateIdFactory? _duplicateIdFactory;
  final LinkedHashSet<String> _selectedClipIds = LinkedHashSet<String>();
  final Map<String, _ClipPlacement> _sourcePlacements =
      <String, _ClipPlacement>{};
  final Map<String, _ClipPlacement> _previewPlacements =
      <String, _ClipPlacement>{};
  final List<_ClipboardClip> _clipboard = <_ClipboardClip>[];
  final Map<String, PresentationClip> _clips = <String, PresentationClip>{};
  final Map<String, String> _trackIdsByClip = <String, String>{};
  final Map<String, PresentationTrack> _tracks = <String, PresentationTrack>{};
  final List<String> _clipOrder = <String>[];

  PresentationCinematicAsset _asset;
  PresentationTimelineDragKind? _dragKind;
  String? _dragAnchorClipId;
  int _duplicateSequence = 0;
  final Set<String> _reservedDuplicateIds = <String>{};

  PresentationCinematicAsset get asset => _asset;
  bool get hasActiveDrag => _dragKind != null;
  bool get hasClipboard => _clipboard.isNotEmpty;
  bool get canEditSelection =>
      _selectedClipIds.isNotEmpty &&
      _selectedClipIds.every((clipId) => isClipEditable(clipId));
  Set<String> get activePreviewClipIds =>
      Set<String>.unmodifiable(_previewPlacements.keys);
  Set<String> get selectedClipIds =>
      Set<String>.unmodifiable(_orderedSelectedClipIds());

  void configureAsset(PresentationCinematicAsset asset) {
    if (_asset == asset) return;
    final cinematicChanged = _asset.id != asset.id;
    _asset = asset;
    _sourcePlacements.clear();
    _previewPlacements.clear();
    _dragKind = null;
    _dragAnchorClipId = null;
    _indexAsset();
    if (cinematicChanged) {
      _selectedClipIds.clear();
      _clipboard.clear();
      _reservedDuplicateIds.clear();
      _duplicateSequence = 0;
    } else {
      _selectedClipIds.removeWhere((id) => !_clips.containsKey(id));
    }
    notifyListeners();
  }

  bool isClipEditable(String clipId) {
    final clip = _requireClip(clipId);
    final layerId = switch (clip) {
      PresentationVisualClip() => clip.layerId,
      PresentationTextClip() => clip.layerId,
      _ => null,
    };
    return layerId == null || !_asset.isLayerEffectivelyLocked(layerId);
  }

  void selectClip(String clipId, {bool additive = false}) {
    _requireClip(clipId);
    var changed = false;
    if (!additive) {
      changed =
          _selectedClipIds.length != 1 || !_selectedClipIds.contains(clipId);
      _selectedClipIds
        ..clear()
        ..add(clipId);
    } else if (_selectedClipIds.contains(clipId)) {
      changed = _selectedClipIds.remove(clipId);
    } else {
      changed = _selectedClipIds.add(clipId);
    }
    if (changed) notifyListeners();
  }

  void clearSelection() {
    if (_selectedClipIds.isEmpty) return;
    _selectedClipIds.clear();
    notifyListeners();
  }

  void beginDrag({
    required String clipId,
    required PresentationTimelineDragKind kind,
  }) {
    final clip = _requireClip(clipId);
    if (hasActiveDrag) cancelDrag();
    if (!_selectedClipIds.contains(clipId)) {
      _selectedClipIds
        ..clear()
        ..add(clipId);
    }
    if (!canEditSelection) {
      throw StateError('Locked Presentation clips cannot be edited.');
    }
    if (kind != PresentationTimelineDragKind.move &&
        clip is PresentationMarkerClip) {
      throw ArgumentError.value(clipId, 'clipId', 'markers cannot be trimmed');
    }
    final draggedIds = kind == PresentationTimelineDragKind.move
        ? _orderedSelectedClipIds()
        : <String>[clipId];
    _sourcePlacements
      ..clear()
      ..addEntries(
        draggedIds.map((id) {
          final source = _clips[id]!;
          return MapEntry(
            id,
            _ClipPlacement(
              trackId: _trackIdsByClip[id]!,
              startUs: source.startUs,
              durationUs: source.durationUs,
            ),
          );
        }),
      );
    _previewPlacements
      ..clear()
      ..addAll(_sourcePlacements);
    _dragKind = kind;
    _dragAnchorClipId = clipId;
    notifyListeners();
  }

  void updateDrag({required int deltaUs, String? targetTrackId}) {
    final kind = _dragKind;
    final anchorId = _dragAnchorClipId;
    if (kind == null || anchorId == null) {
      throw StateError('No Presentation timeline drag is active.');
    }
    switch (kind) {
      case PresentationTimelineDragKind.move:
        _updateMove(deltaUs, targetTrackId);
      case PresentationTimelineDragKind.trimStart:
        _updateTrimStart(anchorId, deltaUs);
      case PresentationTimelineDragKind.trimEnd:
        _updateTrimEnd(anchorId, deltaUs);
    }
    notifyListeners();
  }

  PresentationTimelineClipCommand finishDrag() {
    if (!hasActiveDrag) {
      throw StateError('No Presentation timeline drag is active.');
    }
    final operations = <Map<String, Object?>>[
      for (final clipId in _clipOrder)
        if (_previewPlacements[clipId] case final placement?)
          if (placement != _sourcePlacements[clipId])
            <String, Object?>{
              'kind': 'edit',
              'clipId': clipId,
              'targetTrackId': placement.trackId,
              'startUs': placement.startUs,
              'durationUs': placement.durationUs,
            },
    ];
    _endDrag();
    if (operations.isEmpty) {
      throw StateError('The Presentation timeline drag produced no change.');
    }
    return _command(operations);
  }

  void cancelDrag() {
    if (!hasActiveDrag) return;
    _endDrag();
    notifyListeners();
  }

  PresentationClip previewClip(String clipId) {
    final clip = _requireClip(clipId);
    final placement = _previewPlacements[clipId];
    if (placement == null) return clip;
    return _copyClip(
      clip,
      startUs: placement.startUs,
      durationUs: placement.durationUs,
    );
  }

  PresentationClip sourceClip(String clipId) => _requireClip(clipId);

  String previewTrackId(String clipId) {
    _requireClip(clipId);
    return _previewPlacements[clipId]?.trackId ?? _trackIdsByClip[clipId]!;
  }

  void copySelection() {
    final selected = _orderedSelectedClipIds();
    if (selected.isEmpty) return;
    final originUs = selected.map((id) => _clips[id]!.startUs).reduce(math.min);
    _clipboard
      ..clear()
      ..addAll(
        selected.map(
          (id) => _ClipboardClip(
            sourceClipId: id,
            trackId: _trackIdsByClip[id]!,
            relativeStartUs: _clips[id]!.startUs - originUs,
          ),
        ),
      );
    notifyListeners();
  }

  PresentationTimelineClipCommand paste({required int atUs}) {
    if (_clipboard.isEmpty) {
      throw StateError('The Presentation timeline clipboard is empty.');
    }
    if (_clipboard.any((item) => !isClipEditable(item.sourceClipId))) {
      throw StateError('Locked Presentation clips cannot be pasted.');
    }
    final snappedOrigin = _snap(atUs);
    final maximumRelativeEndUs = _clipboard
        .map(
          (item) =>
              item.relativeStartUs + _clips[item.sourceClipId]!.durationUs,
        )
        .reduce(math.max);
    final boundedOrigin = snappedOrigin
        .clamp(0, math.max(0, _asset.durationUs - maximumRelativeEndUs))
        .toInt();
    return _command(<Map<String, Object?>>[
      for (final item in _clipboard)
        <String, Object?>{
          'kind': 'duplicate',
          'clipId': item.sourceClipId,
          'duplicateId': _nextDuplicateId(item.sourceClipId),
          'targetTrackId': item.trackId,
          'startUs': boundedOrigin + item.relativeStartUs,
        },
    ]);
  }

  PresentationTimelineClipCommand duplicateSelection({int offsetUs = 100000}) {
    if (!canEditSelection) {
      throw StateError('Locked Presentation clips cannot be duplicated.');
    }
    copySelection();
    final firstStartUs = _clipboard
        .map((item) => _clips[item.sourceClipId]!.startUs)
        .reduce(math.min);
    return paste(atUs: firstStartUs + offsetUs);
  }

  PresentationTimelineClipCommand deleteSelection() {
    final selected = _orderedSelectedClipIds();
    if (selected.isEmpty) {
      throw StateError('No Presentation timeline clip is selected.');
    }
    if (!canEditSelection) {
      throw StateError('Locked Presentation clips cannot be deleted.');
    }
    return PresentationTimelineClipCommand(
      actionId: 'presentationClip.deleteBatch',
      parameters: <String, Object?>{
        'cinematicId': _asset.id,
        'clipIds': List<String>.unmodifiable(selected),
      },
    );
  }

  void _updateMove(int deltaUs, String? targetTrackId) {
    final snappedDelta = _snap(deltaUs);
    final minimumStart = _sourcePlacements.values
        .map((placement) => placement.startUs)
        .reduce(math.min);
    final maximumEnd = _sourcePlacements.values
        .map((placement) => placement.startUs + placement.durationUs)
        .reduce(math.max);
    final boundedDelta = snappedDelta
        .clamp(-minimumStart, _asset.durationUs - maximumEnd)
        .toInt();
    for (final entry in _sourcePlacements.entries) {
      _previewPlacements[entry.key] = entry.value.copyWith(
        startUs: entry.value.startUs + boundedDelta,
      );
    }
    if (targetTrackId != null && _sourcePlacements.length == 1) {
      final anchorId = _dragAnchorClipId!;
      final sourceClip = _clips[anchorId]!;
      final targetTrack = _tracks[targetTrackId];
      if (targetTrack != null && targetTrack.kind == sourceClip.trackKind) {
        _previewPlacements[anchorId] = _previewPlacements[anchorId]!.copyWith(
          trackId: targetTrackId,
        );
      }
    }
  }

  void _updateTrimStart(String clipId, int deltaUs) {
    final source = _sourcePlacements[clipId]!;
    final endUs = source.startUs + source.durationUs;
    final startUs = _snap(source.startUs + deltaUs).clamp(0, endUs - 1).toInt();
    _previewPlacements[clipId] = source.copyWith(
      startUs: startUs,
      durationUs: endUs - startUs,
    );
  }

  void _updateTrimEnd(String clipId, int deltaUs) {
    final source = _sourcePlacements[clipId]!;
    final endUs = _snap(
      source.startUs + source.durationUs + deltaUs,
    ).clamp(source.startUs + 1, _asset.durationUs).toInt();
    _previewPlacements[clipId] = source.copyWith(
      durationUs: endUs - source.startUs,
    );
  }

  void _endDrag() {
    _dragKind = null;
    _dragAnchorClipId = null;
    _sourcePlacements.clear();
    _previewPlacements.clear();
  }

  PresentationTimelineClipCommand _command(
    List<Map<String, Object?>> operations,
  ) => PresentationTimelineClipCommand(
    actionId: 'presentationClip.batch',
    parameters: <String, Object?>{
      'cinematicId': _asset.id,
      'operations': List<Map<String, Object?>>.unmodifiable(
        operations.map(Map<String, Object?>.unmodifiable),
      ),
    },
  );

  int _snap(int value) => (value / snapIntervalUs).round() * snapIntervalUs;

  String _nextDuplicateId(String sourceId) {
    final generated = _duplicateIdFactory?.call(sourceId);
    if (generated != null) {
      if (_clips.containsKey(generated) ||
          !_reservedDuplicateIds.add(generated)) {
        throw StateError('Duplicate Presentation clip id: $generated');
      }
      return generated;
    }
    late String candidate;
    do {
      _duplicateSequence += 1;
      candidate = '$sourceId-copy-$_duplicateSequence';
    } while (_clips.containsKey(candidate) ||
        _reservedDuplicateIds.contains(candidate));
    _reservedDuplicateIds.add(candidate);
    return candidate;
  }

  List<String> _orderedSelectedClipIds() => <String>[
    for (final clipId in _clipOrder)
      if (_selectedClipIds.contains(clipId)) clipId,
  ];

  PresentationClip _requireClip(String clipId) {
    final clip = _clips[clipId];
    if (clip == null) {
      throw ArgumentError.value(clipId, 'clipId', 'unknown clip');
    }
    return clip;
  }

  void _indexAsset() {
    _clips.clear();
    _trackIdsByClip.clear();
    _tracks.clear();
    _clipOrder.clear();
    for (final track in _asset.tracks) {
      _tracks[track.id] = track;
      for (final clip in track.clips) {
        _clips[clip.id] = clip;
        _trackIdsByClip[clip.id] = track.id;
        _clipOrder.add(clip.id);
      }
    }
  }
}

@immutable
final class _ClipPlacement {
  const _ClipPlacement({
    required this.trackId,
    required this.startUs,
    required this.durationUs,
  });

  final String trackId;
  final int startUs;
  final int durationUs;

  _ClipPlacement copyWith({String? trackId, int? startUs, int? durationUs}) =>
      _ClipPlacement(
        trackId: trackId ?? this.trackId,
        startUs: startUs ?? this.startUs,
        durationUs: durationUs ?? this.durationUs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ClipPlacement &&
          other.trackId == trackId &&
          other.startUs == startUs &&
          other.durationUs == durationUs;

  @override
  int get hashCode => Object.hash(trackId, startUs, durationUs);
}

@immutable
final class _ClipboardClip {
  const _ClipboardClip({
    required this.sourceClipId,
    required this.trackId,
    required this.relativeStartUs,
  });

  final String sourceClipId;
  final String trackId;
  final int relativeStartUs;
}

PresentationClip _copyClip(
  PresentationClip clip, {
  required int startUs,
  required int durationUs,
}) => switch (clip) {
  PresentationVisualClip() => PresentationVisualClip(
    id: clip.id,
    startUs: startUs,
    durationUs: durationUs,
    layerId: clip.layerId,
    resourceId: clip.resourceId,
    mediaKind: clip.mediaKind,
    landscapeResourceId: clip.landscapeResourceId,
    portraitResourceId: clip.portraitResourceId,
    landscapeCompositionOverride: clip.landscapeCompositionOverride,
    portraitCompositionOverride: clip.portraitCompositionOverride,
    easing: clip.easing,
    from: clip.from,
    to: clip.to,
    transitionIn: clip.transitionIn,
    transitionOut: clip.transitionOut,
  ),
  PresentationTextClip() => PresentationTextClip(
    id: clip.id,
    startUs: startUs,
    durationUs: durationUs,
    layerId: clip.layerId,
    text: clip.text,
    localizationKey: clip.localizationKey,
    style: clip.style,
    easing: clip.easing,
    from: clip.from,
    to: clip.to,
    transitionIn: clip.transitionIn,
    transitionOut: clip.transitionOut,
  ),
  PresentationAudioClip() => PresentationAudioClip(
    id: clip.id,
    startUs: startUs,
    durationUs: durationUs,
    resourceId: clip.resourceId,
    audioKind: clip.audioKind,
    landscapeResourceId: clip.landscapeResourceId,
    portraitResourceId: clip.portraitResourceId,
    volume: clip.volume,
    loop: clip.loop,
    fadeInUs: clip.fadeInUs.clamp(0, durationUs).toInt(),
    fadeOutUs: clip.fadeOutUs.clamp(0, durationUs).toInt(),
    bus: clip.bus,
  ),
  PresentationCaptionClip() => PresentationCaptionClip(
    id: clip.id,
    startUs: startUs,
    durationUs: durationUs,
    captionId: clip.captionId,
    locale: clip.locale,
    style: clip.style,
    fallbackToProjectDefault: clip.fallbackToProjectDefault,
  ),
  PresentationMarkerClip() => PresentationMarkerClip(
    id: clip.id,
    startUs: startUs,
    label: clip.label,
    markerKind: clip.markerKind,
    required: clip.required,
  ),
};
