import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/runtime_map_bundle.dart';
import 'spatial_exploration_session.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';

class SpatialExplorationView extends StatefulWidget {
  const SpatialExplorationView(
      {super.key,
      required this.session,
      this.keyboardInputEnabled = true,
      this.onReady,
      this.onError});
  final SpatialExplorationSession session;
  final bool keyboardInputEnabled;
  final VoidCallback? onReady;
  final void Function(Object)? onError;
  @override
  State<SpatialExplorationView> createState() => _SpatialExplorationViewState();
}

class _SpatialExplorationViewState extends State<SpatialExplorationView>
    with WidgetsBindingObserver {
  final focus = FocusNode();
  final camera = SpatialSceneController()..setView(SpatialEditorView.game);
  final keys = <LogicalKeyboardKey>{};
  int inputEpoch = -1;
  late RuntimeMapBundle activeBundle;
  Offset sceneOffset = Offset.zero;
  List<SpatialSceneNeighbor> neighbors = const [];
  int neighborGeneration = 0;
  Object? neighborError;
  void release() {
    keys.clear();
    if (widget.keyboardInputEnabled) widget.session.movement.releaseInput();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.mapRevision.addListener(mapChanged);
    widget.session.transitioning.addListener(release);
    activeBundle = widget.session.bundle;
    widget.session.setVisibleMaps({});
    loadNeighbors();
  }

  void mapChanged() {
    final previous = activeBundle;
    activeBundle = widget.session.bundle;
    final entry = widget.session.connectionEntry;
    if (entry == null) {
      release();
      sceneOffset = Offset.zero;
      neighbors = const [];
    } else {
      final translation = spatialConnectionOffset(
          entry.sourceSize,
          activeBundle.map.size,
          entry.connection.direction,
          entry.connection.offset);
      sceneOffset += translation;
      neighbors = [
        SpatialSceneNeighbor(
            map: previous.map,
            offset: -translation,
            loadGroundImage: (id) => groundBytes(previous, id)),
        for (final existing in neighbors)
          if (existing.map.id != activeBundle.map.id)
            SpatialSceneNeighbor(
                map: existing.map,
                offset: existing.offset - translation,
                loadGroundImage: existing.loadGroundImage),
      ];
    }
    neighborError = null;
    if (mounted) setState(() {});
    loadNeighbors(previous: previous);
  }

  SpatialSceneNeighbor neighbor(
          RuntimeMapBundle bundle, MapConnection connection) =>
      SpatialSceneNeighbor(
          map: bundle.map,
          offset: spatialConnectionOffset(activeBundle.map.size,
              bundle.map.size, connection.direction, connection.offset),
          loadGroundImage: (id) => groundBytes(bundle, id));

  Future<Uint8List> groundBytes(RuntimeMapBundle bundle, String id) async {
    final path = bundle.runtimeImageAbsolutePathsById[id];
    if (path == null) {
      throw StateError('Image du terrain introuvable : $id');
    }
    return File(path).readAsBytes();
  }

  Future<Uint8List> loadModel(String id) async =>
      Uint8List.fromList(await widget.session.modelBytes(id));

  Future<void> loadNeighbors({RuntimeMapBundle? previous}) async {
    final generation = ++neighborGeneration;
    final session = widget.session;
    final loaded = <SpatialSceneNeighbor>[];
    Object? failure;
    for (final connection in session.viewConnections) {
      try {
        final bundle = connection.targetMapId == previous?.map.id
            ? previous!
            : await session.loadConnectionNeighbor(connection);
        if (!mounted || generation != neighborGeneration) return;
        loaded.add(neighbor(bundle, connection));
      } on Object catch (error) {
        failure = error;
      }
    }
    if (!mounted || generation != neighborGeneration) return;
    if (session.connectionEntry != null &&
        previous != null &&
        !loaded.any((neighbor) => neighbor.map.id == previous.map.id)) {
      final incoming = neighbors
          .where((neighbor) => neighbor.map.id == previous.map.id)
          .firstOrNull;
      if (incoming != null) loaded.add(incoming);
    }
    setState(() {
      neighbors = loaded;
      neighborError = failure;
    });
    if (failure != null) widget.onError?.call(failure);
  }

  Map<String, SpatialActorVisual> frames(
      double dt, Offset renderedOrigin, Set<String> renderedMaps) {
    final frames = widget.session.frames(dt, mapIds: renderedMaps);
    final translation = sceneOffset - renderedOrigin;
    if (translation == Offset.zero) return frames;
    return {
      for (final entry in frames.entries)
        entry.key: SpatialActorVisual(
            x: entry.value.x + translation.dx,
            y: entry.value.y,
            z: entry.value.z + translation.dy,
            texture: entry.value.texture,
            width: entry.value.width,
            height: entry.value.height,
            frame: entry.value.frame),
    };
  }

  @override
  void didUpdateWidget(SpatialExplorationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session == widget.session) return;
    oldWidget.session.mapRevision.removeListener(mapChanged);
    oldWidget.session.transitioning.removeListener(release);
    keys.clear();
    widget.session.mapRevision.addListener(mapChanged);
    widget.session.transitioning.addListener(release);
    activeBundle = widget.session.bundle;
    sceneOffset = Offset.zero;
    neighbors = const [];
    neighborError = null;
    widget.session.setVisibleMaps({});
    loadNeighbors();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.session.setLifecyclePaused(state != AppLifecycleState.resumed);
    if (state != AppLifecycleState.resumed) release();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (!widget.keyboardInputEnabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (inputEpoch != widget.session.movement.inputEpoch) {
      keys.clear();
      inputEpoch = widget.session.movement.inputEpoch;
    }
    if (event is KeyRepeatEvent && !keys.contains(key)) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        if (key == LogicalKeyboardKey.escape) {
          if (widget.session.storyActive.value) {
            widget.session.onCancelStory?.call();
          } else {
            widget.session.closeDialogue();
          }
        } else if (widget.session.storyActive.value) {
          widget.session.onSkipStory?.call();
        } else if (widget.session.dialoguePresentation.value
            case final snapshot?) {
          widget.session.dispatchDialogueCommand(
              DialogueAdvanceCommand(snapshotRevision: snapshot.revision));
        } else {
          widget.session.interact();
        }
      }
      return KeyEventResult.handled;
    }
    if (widget.session.interactionActive.value ||
        widget.session.transitioning.value) {
      return KeyEventResult.handled;
    }
    final supported = {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight
    };
    if (!supported.contains(key)) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    bool pressed(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        keys.contains(a) || keys.contains(b);
    widget.session.movement.setInput(
        x: (pressed(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)
                ? 1
                : 0) -
            (pressed(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyQ)
                ? 1
                : 0),
        z: (pressed(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)
                ? 1
                : 0) -
            (pressed(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyZ)
                ? 1
                : 0),
        run: keys.contains(LogicalKeyboardKey.shiftLeft) ||
            keys.contains(LogicalKeyboardKey.shiftRight));
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    neighborGeneration++;
    release();
    widget.session.mapRevision.removeListener(mapChanged);
    widget.session.transitioning.removeListener(release);
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final renderedOrigin = sceneOffset;
    final renderedMaps = {
      widget.session.bundle.map.id,
      for (final neighbor in neighbors) neighbor.map.id,
    };
    return Focus(
        autofocus: widget.keyboardInputEnabled,
        focusNode: focus,
        onFocusChange: (value) {
          if (!value) release();
        },
        onKeyEvent: onKey,
        child: Listener(
            onPointerDown: (_) {
              if (widget.keyboardInputEnabled) focus.requestFocus();
            },
            child: Stack(children: [
              Positioned.fill(
                  child: SpatialSceneView(
                      key: ObjectKey(widget.session),
                      scene: widget.session.bundle.map.spatialScene!,
                      groundMap: widget.session.bundle.map,
                      groundProject: widget.session.bundle.manifest,
                      loadGroundImage: widget.session.groundImageBytes,
                      sceneOffset: sceneOffset,
                      neighbors: neighbors,
                      models: widget.session.bundle.manifest.models3d,
                      loadModel: loadModel,
                      controller: camera,
                      onCell: (_, __) {
                        if (widget.keyboardInputEnabled) focus.requestFocus();
                      },
                      onReady: widget.onReady,
                      onVisibleMapsChanged: widget.session.setVisibleMaps,
                      actorFrames: (dt) =>
                          frames(dt, renderedOrigin, renderedMaps),
                      modelRuntimeState: (mapId, instanceId) => widget
                          .session.worldStateProvider
                          ?.call()
                          .modelState(mapId, instanceId),
                      presentationPaused: () =>
                          widget.session.presentationPaused,
                      cameraPose: () {
                        final pose = widget.session.storyCamera?.call();
                        return pose == null
                            ? null
                            : (
                                x: pose.x,
                                y: pose.y,
                                z: pose.z,
                                zoom: pose.zoom
                              );
                      },
                      background: Colors.black,
                      ground: colors.primaryContainer,
                      edge: colors.outlineVariant,
                      errorBuilder: (_, error) {
                        widget.onError?.call(error);
                        return Center(
                            child: Text('Erreur d’exploration 3D : $error'));
                      })),
              Positioned(
                  bottom: 16,
                  left: 16,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.session.storyActive,
                    builder: (context, active, _) => !active
                        ? const SizedBox.shrink()
                        : Row(children: [
                            FilledButton.tonal(
                                onPressed: widget.session.onSkipStory,
                                child: const Text('Passer la scène')),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                                onPressed: widget.session.onCancelStory,
                                child: const Text('Annuler')),
                          ]),
                  )),
              Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ValueListenableBuilder<Object?>(
                    valueListenable: widget.session.interactionError,
                    builder: (context, error, _) => error == null &&
                            neighborError == null
                        ? const SizedBox.shrink()
                        : ColoredBox(
                            color: colors.errorContainer,
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                    neighborError != null && error == null
                                        ? 'Impossible d’afficher une carte voisine.'
                                        : 'Impossible d’ouvrir ce passage ou ce dialogue.',
                                    style: TextStyle(
                                        color: colors.onErrorContainer)))),
                  )),
            ])));
  }
}
