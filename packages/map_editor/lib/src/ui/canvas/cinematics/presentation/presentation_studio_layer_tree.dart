import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../design_system/design_system.dart';

enum PresentationStudioSelectionOrigin { canvas, layers, properties, timeline }

@immutable
final class PresentationStudioSelection {
  const PresentationStudioSelection({
    required this.layerId,
    this.trackId,
    this.clipId,
  });

  final String layerId;
  final String? trackId;
  final String? clipId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationStudioSelection &&
          other.layerId == layerId &&
          other.trackId == trackId &&
          other.clipId == clipId;

  @override
  int get hashCode => Object.hash(layerId, trackId, clipId);
}

final class PresentationStudioSelectionController extends ChangeNotifier {
  PresentationStudioSelectionController({
    PresentationStudioSelection? initialSelection,
    PresentationStudioSelectionOrigin? initialOrigin,
  }) : _value = initialSelection,
       _origin = initialOrigin;

  PresentationStudioSelection? _value;
  PresentationStudioSelectionOrigin? _origin;
  Offset? _lastCanvasPosition;
  int? _lastCanvasTimeUs;
  String? _lastCanvasStack;
  int _canvasCycleIndex = 0;

  PresentationStudioSelection? get value => _value;
  PresentationStudioSelectionOrigin? get origin => _origin;

  void clear({
    PresentationStudioSelectionOrigin origin =
        PresentationStudioSelectionOrigin.layers,
  }) {
    _setValue(null, origin);
    resetCanvasCycle();
  }

  void selectLayer({
    required PresentationCinematicAsset asset,
    required String layerId,
    required int timeUs,
    PresentationStudioSelectionOrigin origin =
        PresentationStudioSelectionOrigin.layers,
  }) {
    _requireLayer(asset, layerId);
    PresentationVisualClip? activeClip;
    String? trackId;
    for (final track in asset.tracks) {
      if (track.kind != PresentationTrackKind.visual) continue;
      for (final clip in track.clips) {
        if (clip is PresentationVisualClip &&
            clip.layerId == layerId &&
            clip.startUs <= timeUs &&
            timeUs < clip.endUs) {
          activeClip = clip;
          trackId = track.id;
          break;
        }
      }
      if (activeClip != null) break;
    }
    _setValue(
      PresentationStudioSelection(
        layerId: layerId,
        trackId: trackId,
        clipId: activeClip?.id,
      ),
      origin,
    );
    if (origin != PresentationStudioSelectionOrigin.canvas) {
      resetCanvasCycle();
    }
  }

  void selectClip({
    required PresentationCinematicAsset asset,
    required String clipId,
    PresentationStudioSelectionOrigin origin =
        PresentationStudioSelectionOrigin.timeline,
  }) {
    for (final track in asset.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId && clip is PresentationVisualClip) {
          _setValue(
            PresentationStudioSelection(
              layerId: clip.layerId,
              trackId: track.id,
              clipId: clip.id,
            ),
            origin,
          );
          resetCanvasCycle();
          return;
        }
      }
    }
    throw ArgumentError.value(clipId, 'clipId', 'unknown visual clip');
  }

  void selectCanvas({
    required PresentationCinematicAsset asset,
    required PresentationFrame frame,
    required Offset normalizedPosition,
  }) {
    final candidates =
        <PresentationVisualFrameClip>[
          for (final clip in frame.visuals)
            if (!asset.isLayerEffectivelyLocked(clip.layerId) &&
                _contains(clip.composition, normalizedPosition))
              clip,
        ]..sort((left, right) {
          final zOrder = right.zIndex.compareTo(left.zIndex);
          return zOrder != 0 ? zOrder : left.layerId.compareTo(right.layerId);
        });
    if (candidates.isEmpty) {
      clear(origin: PresentationStudioSelectionOrigin.canvas);
      return;
    }
    final stack = candidates
        .map((clip) => '${clip.layerId}:${clip.clipId}:${clip.zIndex}')
        .join('|');
    final sameCycle =
        _lastCanvasPosition == normalizedPosition &&
        _lastCanvasTimeUs == frame.timeUs &&
        _lastCanvasStack == stack;
    _canvasCycleIndex = sameCycle
        ? (_canvasCycleIndex + 1) % candidates.length
        : 0;
    _lastCanvasPosition = normalizedPosition;
    _lastCanvasTimeUs = frame.timeUs;
    _lastCanvasStack = stack;
    final selected = candidates[_canvasCycleIndex];
    _setValue(
      PresentationStudioSelection(
        layerId: selected.layerId,
        trackId: selected.trackId,
        clipId: selected.clipId,
      ),
      PresentationStudioSelectionOrigin.canvas,
    );
  }

  void resetCanvasCycle() {
    _lastCanvasPosition = null;
    _lastCanvasTimeUs = null;
    _lastCanvasStack = null;
    _canvasCycleIndex = 0;
  }

  void _setValue(
    PresentationStudioSelection? value,
    PresentationStudioSelectionOrigin origin,
  ) {
    if (_value == value && _origin == origin) return;
    _value = value;
    _origin = origin;
    notifyListeners();
  }
}

@immutable
final class PresentationStudioLayerCommand {
  PresentationStudioLayerCommand({
    required this.actionId,
    required Map<String, Object?> parameters,
  }) : parameters = Map<String, Object?>.unmodifiable(parameters);

  final String actionId;
  final Map<String, Object?> parameters;
}

class PresentationStudioLayerTree extends StatefulWidget {
  const PresentationStudioLayerTree({
    super.key,
    required this.asset,
    required this.playheadUs,
    required this.selectionController,
    required this.onCommand,
  });

  final PresentationCinematicAsset asset;
  final int playheadUs;
  final PresentationStudioSelectionController selectionController;
  final ValueChanged<PresentationStudioLayerCommand> onCommand;

  @override
  State<PresentationStudioLayerTree> createState() =>
      _PresentationStudioLayerTreeState();
}

class _PresentationStudioLayerTreeState
    extends State<PresentationStudioLayerTree> {
  final Set<String> _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.selectionController,
      builder: (context, _) => ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Banque de calques',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                PokeMapIconButton(
                  key: const ValueKey<String>(
                    'presentation-layer-create-folder',
                  ),
                  semanticLabel: 'Créer un dossier visuel',
                  tooltip: 'Créer un dossier visuel',
                  onPressed: () => _editFolder(),
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
          ),
          _systemGroup(
            id: 'visuals',
            label: 'Visuels',
            children: _visualChildren(),
          ),
          _systemGroup(
            id: 'audio',
            label: 'Audio',
            children: _trackChildren(PresentationTrackKind.audio),
          ),
          _systemGroup(
            id: 'captions',
            label: 'Sous-titres',
            children: _trackChildren(PresentationTrackKind.caption),
          ),
          _systemGroup(
            id: 'markers',
            label: 'Repères',
            children: _trackChildren(PresentationTrackKind.marker),
          ),
        ],
      ),
    );
  }

  Widget _systemGroup({
    required String id,
    required String label,
    required List<Widget> children,
  }) {
    final expanded = !_collapsed.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapCinematicLayerGroupHeader(
          label: label,
          expanded: expanded,
          hidden: false,
          locked: false,
          toggleLabel: '${expanded ? 'Replier' : 'Déplier'} $label',
          stateLabel: label,
          onToggleExpanded: () => _toggle(id),
        ),
        if (expanded) ...children,
      ],
    );
  }

  List<Widget> _visualChildren() {
    final ordered = widget.asset.layers.toList()
      ..sort((left, right) {
        final zOrder = right.zIndex.compareTo(left.zIndex);
        return zOrder != 0 ? zOrder : left.id.compareTo(right.id);
      });
    final folderByLayer = <String, PresentationVisualFolder>{
      for (final folder in widget.asset.visualFolders)
        for (final layerId in folder.layerIds) layerId: folder,
    };
    final renderedFolders = <String>{};
    final children = <Widget>[];
    for (final layer in ordered) {
      final folder = folderByLayer[layer.id];
      if (folder == null) {
        children.add(_layerRow(layer));
        continue;
      }
      if (!renderedFolders.add(folder.id)) continue;
      children.add(_folder(folder));
    }
    for (final folder in widget.asset.visualFolders) {
      if (renderedFolders.add(folder.id)) children.add(_folder(folder));
    }
    return children;
  }

  Widget _folder(PresentationVisualFolder folder) {
    final expanded = !_collapsed.contains('folder:${folder.id}');
    final header = PokeMapCinematicLayerGroupHeader(
      label: folder.label,
      expanded: expanded,
      hidden: folder.hidden,
      locked: folder.locked,
      toggleLabel: '${expanded ? 'Replier' : 'Déplier'} ${folder.label}',
      stateLabel: folder.label,
      onToggleExpanded: () => _toggle('folder:${folder.id}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PokeMapIconButton(
            semanticLabel: folder.hidden
                ? 'Afficher ${folder.label}'
                : 'Masquer ${folder.label}',
            tooltip: folder.hidden
                ? 'Afficher ${folder.label}'
                : 'Masquer ${folder.label}',
            onPressed: () => widget.onCommand(
              PresentationStudioLayerCommand(
                actionId: 'presentationVisualFolder.setVisibility',
                parameters: <String, Object?>{
                  'cinematicId': widget.asset.id,
                  'folderId': folder.id,
                  'visible': folder.hidden,
                },
              ),
            ),
            icon: Icon(
              folder.hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            size: 30,
          ),
          PokeMapIconButton(
            semanticLabel: folder.locked
                ? 'Déverrouiller ${folder.label}'
                : 'Verrouiller ${folder.label}',
            tooltip: folder.locked
                ? 'Déverrouiller ${folder.label}'
                : 'Verrouiller ${folder.label}',
            onPressed: () => widget.onCommand(
              PresentationStudioLayerCommand(
                actionId: 'presentationVisualFolder.setLocked',
                parameters: <String, Object?>{
                  'cinematicId': widget.asset.id,
                  'folderId': folder.id,
                  'locked': !folder.locked,
                },
              ),
            ),
            icon: Icon(
              folder.locked
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
            ),
            size: 30,
          ),
          PokeMapMenuIconButton<_FolderMenuAction>(
            semanticLabel: 'Actions pour ${folder.label}',
            tooltip: 'Actions pour ${folder.label}',
            items: const <PokeMapMenuItem<_FolderMenuAction>>[
              PokeMapMenuItem<_FolderMenuAction>(
                value: _FolderMenuAction.rename,
                label: 'Renommer',
              ),
              PokeMapMenuItem<_FolderMenuAction>(
                value: _FolderMenuAction.delete,
                label: 'Supprimer',
                destructive: true,
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _FolderMenuAction.rename:
                  _editFolder(folder: folder);
                case _FolderMenuAction.delete:
                  _deleteFolder(folder);
              }
            },
            icon: const Icon(Icons.more_horiz_rounded),
            size: 30,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _dropTarget(
          targetLayerId: _firstOrNull(folder.layerIds),
          targetFolderId: folder.id,
          child: LongPressDraggable<_LayerDragPayload>(
            data: _LayerDragPayload.folder(folder.id),
            feedback: Material(
              type: MaterialType.transparency,
              child: PokeMapBadge(label: folder.label),
            ),
            child: header,
          ),
        ),
        if (expanded)
          for (final layerId in folder.layerIds)
            _layerRow(_layer(layerId), indent: 1),
      ],
    );
  }

  Widget _layerRow(PresentationLayer layer, {int indent = 0}) {
    final selected = widget.selectionController.value?.layerId == layer.id;
    final row = PokeMapCinematicLayerRow(
      key: ValueKey<String>('presentation-layer-${layer.id}'),
      kind: PokeMapCinematicLayerKind.visual,
      label: layer.label,
      visible: layer.visible,
      locked: layer.locked,
      selected: selected,
      indent: indent,
      visibilityLabel:
          '${layer.visible ? 'Masquer' : 'Afficher'} ${layer.label}',
      lockLabel:
          '${layer.locked ? 'Déverrouiller' : 'Verrouiller'} ${layer.label}',
      dragLabel: 'Réordonner ${layer.label}',
      dragHandle: LongPressDraggable<_LayerDragPayload>(
        data: _LayerDragPayload.layer(layer.id),
        feedback: Material(
          type: MaterialType.transparency,
          child: PokeMapBadge(label: layer.label),
        ),
        child: const Icon(Icons.drag_indicator_rounded, size: 16),
      ),
      onSelect: () => widget.selectionController.selectLayer(
        asset: widget.asset,
        layerId: layer.id,
        timeUs: widget.playheadUs,
      ),
      onVisibilityChanged: (visible) => widget.onCommand(
        PresentationStudioLayerCommand(
          actionId: 'presentationLayer.setVisibility',
          parameters: <String, Object?>{
            'cinematicId': widget.asset.id,
            'layerId': layer.id,
            'visible': visible,
          },
        ),
      ),
      onLockChanged: (locked) => widget.onCommand(
        PresentationStudioLayerCommand(
          actionId: 'presentationLayer.setLocked',
          parameters: <String, Object?>{
            'cinematicId': widget.asset.id,
            'layerId': layer.id,
            'locked': locked,
          },
        ),
      ),
    );
    return _dropTarget(
      targetLayerId: layer.id,
      targetFolderId: widget.asset.folderForLayer(layer.id)?.id,
      child: row,
    );
  }

  List<Widget> _trackChildren(PresentationTrackKind kind) => <Widget>[
    for (final track in widget.asset.tracks)
      if (track.kind == kind)
        PokeMapCinematicLayerRow(
          key: ValueKey<String>('presentation-track-${track.id}'),
          kind: switch (kind) {
            PresentationTrackKind.visual => PokeMapCinematicLayerKind.visual,
            PresentationTrackKind.audio => PokeMapCinematicLayerKind.audio,
            PresentationTrackKind.caption => PokeMapCinematicLayerKind.captions,
            PresentationTrackKind.marker => PokeMapCinematicLayerKind.markers,
          },
          label: track.label,
          visible: true,
          locked: false,
          visibilityLabel: '${track.label} visible',
          lockLabel: '${track.label} déverrouillé',
          dragLabel: 'Réordonner ${track.label}',
        ),
  ];

  PresentationLayer _layer(String layerId) {
    for (final layer in widget.asset.layers) {
      if (layer.id == layerId) return layer;
    }
    throw StateError('Unknown Presentation layer $layerId');
  }

  void _toggle(String id) {
    setState(() {
      if (!_collapsed.add(id)) _collapsed.remove(id);
    });
  }

  Widget _dropTarget({
    required String? targetLayerId,
    required String? targetFolderId,
    required Widget child,
  }) => DragTarget<_LayerDragPayload>(
    onWillAcceptWithDetails: (details) =>
        targetLayerId != null &&
        details.data.id != targetLayerId &&
        !(details.data.folder && details.data.id == targetFolderId),
    onAcceptWithDetails: (details) => _move(
      details.data,
      targetLayerId: targetLayerId!,
      targetFolderId: targetFolderId,
    ),
    builder: (context, candidates, rejected) => child,
  );

  void _move(
    _LayerDragPayload payload, {
    required String targetLayerId,
    required String? targetFolderId,
  }) {
    final orderedIds = widget.asset.layers.toList()
      ..sort((left, right) {
        final zOrder = right.zIndex.compareTo(left.zIndex);
        return zOrder != 0 ? zOrder : left.id.compareTo(right.id);
      });
    final ids = orderedIds.map((layer) => layer.id).toList();
    if (payload.folder) {
      final folder = widget.asset.visualFolders.firstWhere(
        (candidate) => candidate.id == payload.id,
      );
      ids.removeWhere(folder.layerIds.contains);
      final targetFolder = targetFolderId == null
          ? null
          : widget.asset.visualFolders.firstWhere(
              (candidate) => candidate.id == targetFolderId,
            );
      final anchorId = _firstOrNull(targetFolder?.layerIds) ?? targetLayerId;
      final insertionIndex = ids.indexOf(anchorId);
      if (insertionIndex < 0) return;
      widget.onCommand(
        PresentationStudioLayerCommand(
          actionId: 'presentationVisualFolder.move',
          parameters: <String, Object?>{
            'cinematicId': widget.asset.id,
            'folderId': payload.id,
            'insertionIndex': insertionIndex,
          },
        ),
      );
      return;
    }
    ids.remove(payload.id);
    final targetFolder = targetFolderId == null
        ? null
        : widget.asset.visualFolders.firstWhere(
            (candidate) => candidate.id == targetFolderId,
          );
    final anchorId = _firstOrNull(targetFolder?.layerIds) ?? targetLayerId;
    final insertionIndex = ids.indexOf(anchorId);
    if (insertionIndex < 0) return;
    widget.onCommand(
      PresentationStudioLayerCommand(
        actionId: 'presentationLayer.move',
        parameters: <String, Object?>{
          'cinematicId': widget.asset.id,
          'layerId': payload.id,
          'insertionIndex': insertionIndex,
          'targetFolderId': targetFolderId,
        },
      ),
    );
  }

  Future<void> _editFolder({PresentationVisualFolder? folder}) async {
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _FolderNameDialog(
        initialLabel: folder?.label,
        creating: folder == null,
      ),
    );
    if (!mounted || label == null || label.isEmpty) return;
    if (folder == null) {
      widget.onCommand(
        PresentationStudioLayerCommand(
          actionId: 'presentationVisualFolder.create',
          parameters: <String, Object?>{
            'cinematicId': widget.asset.id,
            'folderId': _nextFolderId(label),
            'label': label,
          },
        ),
      );
      return;
    }
    widget.onCommand(
      PresentationStudioLayerCommand(
        actionId: 'presentationVisualFolder.update',
        parameters: <String, Object?>{
          'cinematicId': widget.asset.id,
          'folderId': folder.id,
          'label': label,
        },
      ),
    );
  }

  Future<void> _deleteFolder(PresentationVisualFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PokeMapDialog(
        title: 'Supprimer ${folder.label} ?',
        message:
            'Les calques restent dans Visuels et conservent leur profondeur.',
        icon: Icons.delete_outline_rounded,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              variant: PokeMapButtonVariant.ghost,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              variant: PokeMapButtonVariant.danger,
              child: const Text('Supprimer le dossier'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    widget.onCommand(
      PresentationStudioLayerCommand(
        actionId: 'presentationVisualFolder.delete',
        parameters: <String, Object?>{
          'cinematicId': widget.asset.id,
          'folderId': folder.id,
        },
      ),
    );
  }

  String _nextFolderId(String label) {
    final base = label
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final safeBase = base.isEmpty ? 'folder' : base;
    final existing = widget.asset.visualFolders
        .map((folder) => folder.id)
        .toSet();
    if (!existing.contains(safeBase)) return safeBase;
    for (var suffix = 2; suffix < 10000; suffix += 1) {
      final candidate = '$safeBase-$suffix';
      if (!existing.contains(candidate)) return candidate;
    }
    throw StateError('Unable to allocate a Presentation folder id');
  }
}

final class _LayerDragPayload {
  const _LayerDragPayload.layer(this.id) : folder = false;
  const _LayerDragPayload.folder(this.id) : folder = true;

  final String id;
  final bool folder;
}

enum _FolderMenuAction { rename, delete }

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.creating, this.initialLabel});

  final bool creating;
  final String? initialLabel;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapDialog(
    title: widget.creating ? 'Nouveau dossier visuel' : 'Renommer le dossier',
    icon: Icons.folder_outlined,
    footer: Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        PokeMapButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: PokeMapButtonVariant.ghost,
          child: const Text('Annuler'),
        ),
        PokeMapButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.creating ? 'Créer' : 'Renommer'),
        ),
      ],
    ),
    child: PokeMapTextField(
      label: 'Nom du dossier',
      controller: _controller,
      autofocus: true,
      onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
    ),
  );
}

void _requireLayer(PresentationCinematicAsset asset, String layerId) {
  if (!asset.layers.any((layer) => layer.id == layerId)) {
    throw ArgumentError.value(layerId, 'layerId', 'unknown layer');
  }
}

bool _contains(PresentationVisualComposition composition, Offset position) {
  final translatedX = position.dx - composition.translateX - 0.5;
  final translatedY = position.dy - composition.translateY - 0.5;
  final angle = -composition.rotationTurns * math.pi * 2;
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  final rotatedX = translatedX * cosine - translatedY * sine;
  final rotatedY = translatedX * sine + translatedY * cosine;
  final localX = rotatedX / composition.scaleX + 0.5;
  final localY = rotatedY / composition.scaleY + 0.5;
  return localX >= composition.cropLeft &&
      localX <= 1 - composition.cropRight &&
      localY >= composition.cropTop &&
      localY <= 1 - composition.cropBottom;
}

T? _firstOrNull<T>(Iterable<T>? values) {
  if (values == null || values.isEmpty) return null;
  return values.first;
}
