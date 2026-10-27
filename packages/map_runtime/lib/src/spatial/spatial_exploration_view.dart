import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/runtime_map_bundle.dart';
import '../player/runtime_audio_mixer.dart';
import '../player/runtime_weather_audio_controller.dart';
import '../presentation/map_warp_transition_overlay.dart';
import 'spatial_exploration_session.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';

class SpatialExplorationView extends StatefulWidget {
  const SpatialExplorationView({
    super.key,
    required this.session,
    this.keyboardInputEnabled = true,
    this.staticDepthBatchesEnabled = false,
    this.onReady,
    this.previewVisuals,
    this.sceneController,
    this.onError,
    this.audioMixer,
  });
  final SpatialExplorationSession session;
  final RuntimeAudioMixer? audioMixer;
  final ValueListenable<SpatialVisualPatch>? previewVisuals;
  final SpatialSceneController? sceneController;
  final bool keyboardInputEnabled;
  final bool staticDepthBatchesEnabled;
  final VoidCallback? onReady;
  final void Function(Object)? onError;
  @override
  State<SpatialExplorationView> createState() => _SpatialExplorationViewState();
}

class _SpatialExplorationViewState extends State<SpatialExplorationView>
    with WidgetsBindingObserver {
  final focus = FocusNode();
  late RuntimeWeatherAudioController weatherAudio =
      RuntimeWeatherAudioController(
        mixer: widget.audioMixer ?? RuntimeAudioMixer(),
      );
  late final camera =
      widget.sceneController ??
      (SpatialSceneController()..setView(SpatialEditorView.game));
  void applyVisuals() {
    final overrides =
        (widget.session.worldVisualProfile?.call() ?? SpatialVisualPatch())
            .overriddenBy(widget.session.visualOverrides)
            .overriddenBy(widget.session.cinematicVisualOverrides)
            .overriddenBy(widget.previewVisuals?.value ?? SpatialVisualPatch());
    final authored = activeBundle.visualProfile.overriddenBy(overrides);
    final observed = widget.session.realWeatherAllowed
        ? widget.session.realWeather?.value.snapshot
        : null;
    final external =
        resolveWorldWeatherMode(authored, overrides: overrides) ==
            WorldWeatherMode.real.name
        ? observed
        : null;
    final profile = activeBundle.visualProfile
        .overriddenBy(external?.conditions ?? SpatialVisualPatch())
        .overriddenBy(overrides);
    final environment = widget.session.environmentClock.resolve(
      profile,
      overrides: overrides,
      realWeatherUtcOffsetSeconds: observed?.utcOffsetSeconds,
      realWeatherKind: external == null
          ? null
          : SpatialWeatherKind.parse(
              external.conditions.choice(SpatialVisualParameter.weatherKind),
            ),
    );
    camera.worldEnvironment = environment;
    camera.weatherTimelineSeconds =
        widget.session.environmentClock.elapsedSeconds;
    camera.visualProfile = profile;
    var weather = profile
        .applyAtmosphere(activeBundle.spatialAtmosphereSettings)
        .weather;
    if (environment.weatherKind case final kind? when kind != weather.kind) {
      weather = weather.copyWith(kind: kind);
    }
    if (environment.weatherIntensity case final factor?) {
      weather = weather.copyWith(intensity: weather.intensity * factor);
    }
    unawaited(
      weatherAudio.update(
        weather,
        indoors: activeBundle.map.mapMetadata.isIndoor,
        seconds: widget.session.environmentClock.elapsedSeconds,
      ),
    );
  }

  final keys = <LogicalKeyboardKey>{};
  int inputEpoch = -1;
  late RuntimeMapBundle activeBundle;
  RuntimeMapBundle? _loaderBundle;
  SpatialExplorationSession? _loaderSession;
  late Future<Uint8List> Function(String) _renderedModelLoader;
  late Future<Uint8List> Function(String) _renderedGroundLoader;

  void _bindResourceLoaders(
    SpatialExplorationSession session,
    RuntimeMapBundle bundle,
  ) {
    if (identical(_loaderBundle, bundle) && identical(_loaderSession, session)) {
      return;
    }
    _loaderBundle = bundle;
    _loaderSession = session;
    _renderedModelLoader = (id) => session.modelBytesForBundle(bundle, id);
    _renderedGroundLoader = (id) =>
        session.groundImageBytesForBundle(bundle, id);
  }

  Offset sceneOffset = Offset.zero;
  List<SpatialSceneNeighbor> neighbors = const [];
  final _decorationBundles = <String, RuntimeMapBundle>{};

  final _decorationLoaders =
      Expando<
        ({
          SpatialExplorationSession session,
          Future<Uint8List> Function(String) model,
          Future<Uint8List> Function(String) ground,
        })
      >();

  SpatialSceneDecoration _decorationSource(
    RuntimeMapBundle bundle,
    Offset offset,
  ) {
    final session = widget.session;
    var loaders = _decorationLoaders[bundle];
    if (loaders == null || !identical(loaders.session, session)) {
      loaders = (
        session: session,
        model: (id) => session.modelBytesForBundle(bundle, id),
        ground: (id) => session.groundImageBytesForBundle(bundle, id),
      );
      _decorationLoaders[bundle] = loaders;
    }
    return SpatialSceneDecoration(
      ownerMapId: bundle.map.id,
      decoration: bundle.exteriorDecoration!,
      offset: offset,
      project: bundle.manifest,
      loadGroundImage: loaders.ground,
      loadModel: loaders.model,
    );
  }

  List<SpatialSceneDecoration> get exteriorDecorations => [
    if (activeBundle.exteriorDecoration != null)
      _decorationSource(activeBundle, Offset.zero),
    for (final neighbor in neighbors)
      if (_decorationBundles[neighbor.map.id] case final bundle?)
        if (bundle.exteriorDecoration != null)
          _decorationSource(bundle, neighbor.offset),
  ];
  int neighborGeneration = 0;
  Object? neighborError;
  String? renderedFramesMapId;
  Map<String, SpatialActorVisual> renderedFrames = const {};
  Future<void> waitForBlackoutFrame() => WidgetsBinding.instance.endOfFrame;
  Future<void> prepareNativeDestination(
    RuntimeMapBundle destination,
    bool Function() isCurrent,
  ) async {
    final identity = destination.projectCatalog?.identity;
    if (identity == null) return;
    final session = widget.session;
    await camera.prepareDestination(
      SpatialScenePreparation(
        map: destination.map,
        project: destination.manifest,
        loadModel: (id) => session.modelBytesForBundle(destination, id),
        loadGroundImage: (id) => groundBytes(destination, id),
        resourceIdentity: identity,
        resourceBudget: destination.resourceBudget,
        isCurrent: () =>
            mounted && identical(widget.session, session) && isCurrent(),
      ),
    );
  }

  void release() {
    keys.clear();
    if (widget.keyboardInputEnabled) widget.session.movement.releaseInput();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.previewVisuals?.addListener(applyVisuals);
    widget.session.realWeather?.addListener(applyVisuals);
    widget.session.mapRevision.addListener(mapChanged);
    widget.session.transitioning.addListener(release);
    activeBundle = widget.session.bundle;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    unawaited(
      weatherAudio.setSuspended(
        lifecycle != null && lifecycle != AppLifecycleState.resumed,
      ),
    );
    applyVisuals();
    camera.applyAtmosphereSettings(activeBundle.spatialAtmosphereSettings);
    widget.session.waitForNativeDoorBlackoutFrame = waitForBlackoutFrame;
    widget.session.prepareNativeDoorDestination = prepareNativeDestination;
    widget.session.setVisibleMaps({});
    loadNeighbors();
  }

  void mapChanged() {
    final previous = activeBundle;
    _decorationBundles[previous.map.id] = previous;
    activeBundle = widget.session.bundle;
    applyVisuals();
    camera.applyAtmosphereSettings(activeBundle.spatialAtmosphereSettings);
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
        entry.connection.offset,
      );
      sceneOffset += translation;
      neighbors = [
        SpatialSceneNeighbor(
          map: previous.map,
          project: previous.manifest,
          offset: -translation,
          loadGroundImage: (id) => groundBytes(previous, id),
          loadModel: (id) => widget.session.modelBytesForBundle(previous, id),
        ),
        for (final existing in neighbors)
          if (existing.map.id != activeBundle.map.id)
            SpatialSceneNeighbor(
              map: existing.map,
              project: existing.project,
              offset: existing.offset - translation,
              loadGroundImage: existing.loadGroundImage,
              loadModel: existing.loadModel,
            ),
      ];
    }
    neighborError = null;
    if (mounted) setState(() {});
    loadNeighbors(previous: previous);
  }

  SpatialSceneNeighbor neighbor(
    RuntimeMapBundle bundle,
    MapConnection connection,
  ) => SpatialSceneNeighbor(
    map: bundle.map,
    project: bundle.manifest,
    loadModel: (id) => widget.session.modelBytesForBundle(bundle, id),
    offset: spatialConnectionOffset(
      activeBundle.map.size,
      bundle.map.size,
      connection.direction,
      connection.offset,
    ),
    loadGroundImage: (id) => groundBytes(bundle, id),
  );

  Future<Uint8List> groundBytes(RuntimeMapBundle bundle, String id) =>
      widget.session.groundImageBytesForBundle(bundle, id);

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
        _decorationBundles[bundle.map.id] = bundle;
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
      final retained = {
        activeBundle.map.id,
        ...loaded.map((value) => value.map.id),
      };
      _decorationBundles.removeWhere((id, _) => !retained.contains(id));
      neighborError = failure;
    });
    if (failure != null) widget.onError?.call(failure);
  }

  Map<String, SpatialActorVisual> frames(
    double dt,
    Offset renderedOrigin,
    Set<String> renderedMaps,
    String renderedMapId,
  ) {
    final frames = widget.session.frames(dt, mapIds: renderedMaps);
    applyVisuals();
    if (widget.session.bundle.map.id != renderedMapId &&
        widget.session.connectionEntry == null) {
      return renderedFramesMapId == renderedMapId ? renderedFrames : const {};
    }
    final translation = sceneOffset - renderedOrigin;
    renderedFramesMapId = renderedMapId;
    renderedFrames = Map.unmodifiable(
      translation == Offset.zero
          ? frames
          : {
              for (final entry in frames.entries)
                entry.key: SpatialActorVisual(
                  x: entry.value.x + translation.dx,
                  y: entry.value.y,
                  z: entry.value.z + translation.dy,
                  texture: entry.value.texture,
                  width: entry.value.width,
                  height: entry.value.height,
                  billboardVerticalOffset: entry.value.billboardVerticalOffset,
                  frame: entry.value.frame,
                ),
            },
    );
    return renderedFrames;
  }

  @override
  void didUpdateWidget(SpatialExplorationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioMixer != widget.audioMixer) {
      unawaited(weatherAudio.dispose());
      weatherAudio = RuntimeWeatherAudioController(
        mixer: widget.audioMixer ?? RuntimeAudioMixer(),
      );
      unawaited(
        weatherAudio.setSuspended(
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed,
        ),
      );
      applyVisuals();
    }
    if (oldWidget.previewVisuals != widget.previewVisuals) {
      oldWidget.previewVisuals?.removeListener(applyVisuals);
      widget.previewVisuals?.addListener(applyVisuals);
      applyVisuals();
    }
    if (oldWidget.session == widget.session) return;
    renderedFramesMapId = null;
    renderedFrames = const {};
    oldWidget.session.realWeather?.removeListener(applyVisuals);
    oldWidget.session.mapRevision.removeListener(mapChanged);
    oldWidget.session.transitioning.removeListener(release);
    oldWidget.session.waitForNativeDoorBlackoutFrame = null;
    oldWidget.session.prepareNativeDoorDestination = null;
    keys.clear();
    widget.session.realWeather?.addListener(applyVisuals);
    widget.session.mapRevision.addListener(mapChanged);
    widget.session.transitioning.addListener(release);
    widget.session.waitForNativeDoorBlackoutFrame = waitForBlackoutFrame;
    widget.session.prepareNativeDoorDestination = prepareNativeDestination;
    activeBundle = widget.session.bundle;
    applyVisuals();
    camera.applyAtmosphereSettings(activeBundle.spatialAtmosphereSettings);
    sceneOffset = Offset.zero;
    neighbors = const [];
    neighborError = null;
    widget.session.setVisibleMaps({});
    loadNeighbors();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(weatherAudio.setSuspended(state != AppLifecycleState.resumed));
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
            DialogueAdvanceCommand(snapshotRevision: snapshot.revision),
          );
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
      LogicalKeyboardKey.shiftRight,
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
      x:
          (pressed(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)
              ? 1
              : 0) -
          (pressed(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyQ)
              ? 1
              : 0),
      z:
          (pressed(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)
              ? 1
              : 0) -
          (pressed(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyZ)
              ? 1
              : 0),
      run:
          keys.contains(LogicalKeyboardKey.shiftLeft) ||
          keys.contains(LogicalKeyboardKey.shiftRight),
    );
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    unawaited(weatherAudio.dispose());
    neighborGeneration++;
    release();
    widget.session.realWeather?.removeListener(applyVisuals);
    widget.session.mapRevision.removeListener(mapChanged);
    widget.session.waitForNativeDoorBlackoutFrame = null;
    widget.session.prepareNativeDoorDestination = null;
    widget.session.transitioning.removeListener(release);
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    widget.previewVisuals?.removeListener(applyVisuals);
    if (widget.sceneController == null) camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final renderedSession = widget.session;
    final renderedBundle = renderedSession.bundle;
    _bindResourceLoaders(renderedSession, renderedBundle);
    final renderedOrigin = sceneOffset;
    final renderedMapId = renderedBundle.map.id;
    final renderedMaps = {
      renderedBundle.map.id,
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
        child: Stack(
          children: [
            Positioned.fill(
              child: SpatialSceneView(
                staticDepthBatchesEnabled: widget.staticDepthBatchesEnabled,
                resourceBudget: renderedBundle.resourceBudget,
                resourceIdentity: renderedBundle.projectCatalog?.identity,
                key: ObjectKey(widget.session),
                scene: renderedBundle.map.spatialScene!,
                groundMap: renderedBundle.map,
                groundProject: renderedBundle.manifest,
                loadGroundImage: _renderedGroundLoader,
                sceneOffset: sceneOffset,
                neighbors: neighbors,
                decorations: exteriorDecorations,
                models: renderedBundle.manifest.models3d,
                loadModel: _renderedModelLoader,
                controller: camera,
                onCell: (_, _) {
                  if (widget.keyboardInputEnabled) focus.requestFocus();
                },
                onReady: widget.onReady,
                onVisibleMapsChanged: widget.session.setVisibleMaps,
                actorFrames: (dt) =>
                    frames(dt, renderedOrigin, renderedMaps, renderedMapId),
                modelRuntimeState: widget.session.modelRuntimeState,
                modelPresence: widget.session.modelIsPresent,
                actorOcclusionStateForCell:
                    widget.session.actorOcclusionStateForCell,
                rasterAnimationElapsedMsForCell:
                    widget.session.rasterAnimationElapsedMsForCell,
                presentationPaused: () => widget.session.presentationPaused,
                presentationElapsedSeconds: () =>
                    widget.session.presentationSeconds,
                cameraMagnification: () =>
                    widget.session.nativeCameraMagnification,
                cameraPose: () {
                  final pose = widget.session.storyCamera?.call();
                  if (pose == null &&
                      widget.session.nativeDoorTraversalActive) {
                    final movement = widget.session.movement;
                    final anchor = widget.session.nativeCameraAnchor;
                    return (
                      x: anchor?.x ?? movement.x,
                      y: anchor == null
                          ? movement.y
                          : movement.scene.worldHeightAt(anchor.x, anchor.z),
                      z: anchor?.z ?? movement.z,
                      zoom: 1.0,
                    );
                  }
                  return pose == null
                      ? null
                      : (x: pose.x, y: pose.y, z: pose.z, zoom: pose.zoom);
                },
                background: Colors.black,
                ground: colors.primaryContainer,
                edge: colors.outlineVariant,
                errorBuilder: (_, error) {
                  scheduleMicrotask(
                    () => widget.session.reportNativeDoorRenderFailure(
                      renderedMapId,
                      error,
                    ),
                  );
                  widget.onError?.call(error);
                  return Center(
                    child: Text('Erreur d’exploration 3D : $error'),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.session.cinematicFadeOpacity,
                  builder: (context, opacity, _) => opacity == 0
                      ? const SizedBox.shrink()
                      : MapWarpTransitionOverlay(
                          key: const ValueKey('cinematic-blackout'),
                          transition: const MapWarpTransition(),
                          coverage: opacity,
                          revealing: false,
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.session.nativeDoorBlackout,
                  builder: (context, opacity, _) => opacity == 0
                      ? const SizedBox.shrink()
                      : MapWarpTransitionOverlay(
                          key: const ValueKey('native-door-blackout'),
                          transition: widget.session.nativeScreenTransition,
                          coverage: opacity,
                          revealing: widget.session.nativeScreenRevealing,
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.session.storyActive,
                builder: (context, active, _) => !active
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: widget.session.onSkipStory,
                            child: const Text('Passer la scène'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: widget.session.onCancelStory,
                            child: const Text('Annuler'),
                          ),
                        ],
                      ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ValueListenableBuilder<Object?>(
                valueListenable: widget.session.interactionError,
                builder: (context, error, _) =>
                    error == null && neighborError == null
                    ? const SizedBox.shrink()
                    : ColoredBox(
                        color: colors.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            neighborError != null && error == null
                                ? 'Impossible d’afficher une carte voisine.'
                                : 'Impossible d’ouvrir ce passage ou ce dialogue.',
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
