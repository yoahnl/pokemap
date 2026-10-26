import 'spatial_point_light.dart';
import 'spatial_light_behavior.dart';

import 'dart:async';
import 'dart:ui' as ui show Gradient;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart' hide Matrix4, Texture;
import 'package:map_core/map_core.dart';

import 'model_byte_loader.dart';
import 'model_preview.dart';
import 'model_playback.dart';
import 'spatial_picking.dart';
import 'adaptive_camera.dart';
import 'spatial_camera_magnification.dart';
import 'flutter_frame_graphics_device.dart';
import 'spatial_render_context.dart';
import 'spatial_actor_visual.dart';
import 'spatial_actor_occlusion.dart';
import 'spatial_actor_contact_shadow.dart';
import 'spatial_game_surface.dart';
import 'spatial_pixel_material.dart';
import 'spatial_ground.dart';
import 'spatial_ground_mesh_batches.dart';
import 'spatial_terrain_geometry.dart';
import 'spatial_selection.dart';
import 'spatial_cell_overlay.dart';
import 'spatial_scene_neighbor.dart';
import 'spatial_scene_components.dart';
import 'spatial_model_placement_preview.dart';
import 'spatial_runtime_model_index.dart';
import 'spatial_clipped_model_cache.dart';
import 'spatial_model_source_clip.dart';
import 'spatial_scene_preparation.dart';
import 'spatial_lighting_preview.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_authored_shadows.dart';
import 'spatial_environment_lighting.dart';
import 'spatial_atmosphere.dart';
import 'spatial_presentation_effects.dart';
import 'spatial_depth_of_field.dart';
import 'spatial_weather_effects.dart';
import 'spatial_renderer_initialization.dart';

export 'spatial_renderer_initialization.dart' show initializeSpatialRenderer;

enum SpatialEditorView { orbit, top, game }

enum SpatialSceneContentKind { actor, model, marker, warp }

final class SpatialSceneVisibility {
  SpatialSceneVisibility({
    Iterable<(SpatialSceneContentKind, String)> hiddenContent = const [],
    Iterable<SpatialSceneContentKind> hiddenKinds = const [],
    Iterable<String> hiddenLayers = const [],
    this.allLayersHidden = false,
  }) : hiddenContent = Set.unmodifiable(hiddenContent),
       hiddenKinds = Set.unmodifiable(hiddenKinds),
       hiddenLayers = Set.unmodifiable(hiddenLayers);

  static final all = SpatialSceneVisibility();
  final Set<(SpatialSceneContentKind, String)> hiddenContent;
  final Set<SpatialSceneContentKind> hiddenKinds;
  final Set<String> hiddenLayers;
  final bool allLayersHidden;

  bool contentVisible(SpatialSceneContentKind kind, String id) =>
      !hiddenKinds.contains(kind) && !hiddenContent.contains((kind, id));

  bool layerVisible(String id) =>
      !allLayersHidden && !hiddenLayers.contains(id);

  bool layersMatch(SpatialSceneVisibility other) =>
      allLayersHidden == other.allLayersHidden &&
      setEquals(hiddenLayers, other.hiddenLayers);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialSceneVisibility &&
          layersMatch(other) &&
          setEquals(hiddenContent, other.hiddenContent) &&
          setEquals(hiddenKinds, other.hiddenKinds);

  @override
  int get hashCode => Object.hash(
    allLayersHidden,
    Object.hashAllUnordered(hiddenLayers),
    Object.hashAllUnordered(hiddenContent),
    Object.hashAllUnordered(hiddenKinds),
  );
}

final class SpatialSceneContentHit {
  const SpatialSceneContentHit({
    required this.kind,
    required this.id,
    required this.cell,
  });
  final SpatialSceneContentKind kind;
  final String id;
  final (int, int) cell;
}

final class SpatialSceneContentPreview {
  const SpatialSceneContentPreview({
    required this.kind,
    required this.id,
    required this.position,
  });
  final SpatialSceneContentKind kind;
  final String id;
  final Model3dVector3 position;
}

class SpatialSceneController extends ModelPreviewController {
  SpatialSceneController({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  WorldEnvironmentFrame? worldEnvironment;
  double? weatherTimelineSeconds;
  WorldEnvironmentFrame _previewEnvironment = const WorldEnvironmentFrame();
  double _environmentElapsed = 0;
  SpatialWeatherSettings? _resolvedWeather;
  SpatialWeatherSettings? _resolvedWeatherBase;
  SpatialVisualPatch _visualProfile = SpatialVisualPatch();
  SpatialVisualPatch get visualProfile => _visualProfile;
  set visualProfile(SpatialVisualPatch value) {
    if (_visualProfile == value) return;
    _visualProfile = value;
    _applyAtmosphereSettings(value.applyAtmosphere(_baseAtmosphere));
    super.notifyListeners();
  }

  SpatialAtmosphereSettings _baseAtmosphere = SpatialAtmosphereSettings();
  SpatialCameraProfile effectiveCamera(SpatialCameraProfile base) =>
      _visualProfile.applyCamera(base);
  SpatialDayNightCycle? effectiveCycle(SpatialDayNightCycle? base) =>
      _visualProfile.applyCycle(base);
  bool get lockVerticalFraming =>
      _visualProfile.enabled(SpatialVisualParameter.lockVerticalFraming) ??
      false;

  SpatialDepthOfFieldProfile _depthOfFieldProfile =
      SpatialDepthOfFieldProfile();
  SpatialDepthOfFieldProfile get depthOfFieldProfile => _depthOfFieldProfile;
  set depthOfFieldProfile(SpatialDepthOfFieldProfile value) {
    _depthOfFieldProfile = value;
    super.notifyListeners();
  }

  bool get depthOfFieldEnabled => _depthOfFieldProfile.enabled;
  set depthOfFieldEnabled(bool value) =>
      depthOfFieldProfile = SpatialDepthOfFieldProfile(
        enabled: value,
        strength: _depthOfFieldProfile.strength,
        focusRange: _depthOfFieldProfile.focusRange,
      );
  SpatialPresentationProfile _presentationProfile =
      SpatialPresentationProfile.disabled;
  SpatialPresentationProfile get presentationProfile => _presentationProfile;
  set presentationProfile(SpatialPresentationProfile value) {
    if (identical(_presentationProfile, value)) return;
    _presentationProfile = value;
    super.notifyListeners();
  }

  bool _halosEnabled = false, _depthFogEnabled = false;
  bool get halosEnabled => _halosEnabled;
  set halosEnabled(bool value) {
    if (_halosEnabled == value) return;
    _halosEnabled = value;
    super.notifyListeners();
  }

  bool get depthFogEnabled => _depthFogEnabled;
  set depthFogEnabled(bool value) {
    if (_depthFogEnabled == value) return;
    _depthFogEnabled = value;
    super.notifyListeners();
  }

  int _haloAllocations = 0, _haloCount = 0;
  int get haloAllocations => _haloAllocations;
  int get haloCount => _haloCount;
  final _sceneChanges = ChangeNotifier();
  Listenable get sceneChanges => _sceneChanges;
  @override
  void notifyListeners() {
    super.notifyListeners();
    _sceneChanges.notifyListeners();
  }

  @override
  void dispose() {
    _sceneChanges.dispose();
    super.dispose();
  }

  SpatialAtmosphereProfile _atmosphereProfile =
      SpatialAtmosphereProfile.disabled;
  SpatialAtmosphereProfile get atmosphereProfile => _atmosphereProfile;
  set atmosphereProfile(SpatialAtmosphereProfile value) {
    if (identical(_atmosphereProfile, value)) return;
    _atmosphereProfile = value;
    super.notifyListeners();
  }

  SpatialWeatherSettings get weatherSettings {
    final base = (_authoredAtmosphere ?? _baseAtmosphere).weather;
    final kind = (worldEnvironment ?? _previewEnvironment).weatherKind;
    if (kind == null || kind == base.kind) return base;
    if (_resolvedWeatherBase != base || _resolvedWeather?.kind != kind) {
      _resolvedWeatherBase = base;
      _resolvedWeather = base.copyWith(kind: kind);
    }
    return _resolvedWeather!;
  }
  SpatialAtmosphereSettings? _authoredAtmosphere;
  void applyAtmosphereSettings(SpatialAtmosphereSettings settings) {
    _baseAtmosphere = settings;
    _applyAtmosphereSettings(_visualProfile.applyAtmosphere(settings));
  }

  void _applyAtmosphereSettings(SpatialAtmosphereSettings settings) {
    if (_authoredAtmosphere == settings) return;
    final previous = _authoredAtmosphere;
    final geometryChanged =
        previous == null ||
        previous.copyWith(
              weather: settings.weather,
              halosEnabled: settings.halosEnabled,
              depthFogEnabled: settings.depthFogEnabled,
              depthOfFieldEnabled: settings.depthOfFieldEnabled,
              depthOfFieldStrength: settings.depthOfFieldStrength,
              depthOfFieldFocusRange: settings.depthOfFieldFocusRange,
              haloStrength: settings.haloStrength,
              haloSpread: settings.haloSpread,
              fogOpacity: settings.fogOpacity,
              fogStart: settings.fogStart,
              fogEnd: settings.fogEnd,
              halos: settings.halos,
              waterAnimated: settings.waterAnimated,
              windowsLit: settings.windowsLit,
              fireflies: settings.fireflies,
              waterStrength: settings.waterStrength,
              waterSpeed: settings.waterSpeed,
              windowStrength: settings.windowStrength,
              fireflyDensity: settings.fireflyDensity,
              fireflyLighting: settings.fireflyLighting,
              fireflyYellowAmount: settings.fireflyYellowAmount,
              fireflyGreenAmount: settings.fireflyGreenAmount,
              fireflyBlueAmount: settings.fireflyBlueAmount,
              fireflyPinkAmount: settings.fireflyPinkAmount,
              fireflyLightStrength: settings.fireflyLightStrength,
              fireflyLightRadius: settings.fireflyLightRadius,
            ) !=
            settings;
    if (geometryChanged) {
      _atmosphereProfile = SpatialAtmosphereProfile.fromSettings(settings);
    } else {
      _atmosphereProfile
        ..waterStrength = settings.waterStrength
        ..waterSpeed = settings.waterSpeed
        ..windowStrength = settings.windowStrength
        ..fireflyDensity = settings.fireflyDensity
        ..fireflyLighting = settings.fireflyLighting
        ..fireflyYellowAmount = settings.fireflyYellowAmount
        ..fireflyGreenAmount = settings.fireflyGreenAmount
        ..fireflyBlueAmount = settings.fireflyBlueAmount
        ..fireflyPinkAmount = settings.fireflyPinkAmount
        ..fireflyLightStrength = settings.fireflyLightStrength
        ..fireflyLightRadius = settings.fireflyLightRadius;
    }
    if (previous == null ||
        previous.copyWith(halos: settings.halos) != previous) {
      _presentationProfile = SpatialPresentationProfile.fromSettings(settings);
    } else {
      _presentationProfile
        ..haloStrength = settings.haloStrength
        ..haloSpread = settings.haloSpread
        ..fogStart = settings.fogStart
        ..fogEnd = settings.fogEnd
        ..fogOpacity = settings.fogOpacity;
    }
    _halosEnabled = settings.halosEnabled;
    _depthFogEnabled = settings.depthFogEnabled;
    _depthOfFieldProfile = SpatialDepthOfFieldProfile(
      enabled: settings.depthOfFieldEnabled,
      strength: settings.depthOfFieldStrength,
      focusRange: settings.depthOfFieldFocusRange,
    );
    _authoredAtmosphere = settings;
    _waterAnimated = settings.waterAnimated;
    _windowsLit = settings.windowsLit;
    _fireflies = settings.fireflies;
    super.notifyListeners();
  }

  bool _waterAnimated = false, _windowsLit = false, _fireflies = false;
  bool get waterAnimated => _waterAnimated;
  set waterAnimated(bool value) {
    if (_waterAnimated == value) return;
    _waterAnimated = value;
    super.notifyListeners();
  }

  bool get windowsLit => _windowsLit;
  set windowsLit(bool value) {
    if (_windowsLit == value) return;
    _windowsLit = value;
    super.notifyListeners();
  }

  bool get fireflies => _fireflies;
  set fireflies(bool value) {
    if (_fireflies == value) return;
    _fireflies = value;
    super.notifyListeners();
  }

  ({bool water, bool windows, bool fireflies}) get atmosphereAvailability => (
    water: _atmosphereProfile.waterTargets.isNotEmpty,
    windows: _atmosphereProfile.windows.isNotEmpty,
    fireflies: _atmosphereProfile.fireflyZones.isNotEmpty,
  );

  bool _previewPointLightShadowsEnabled = true;
  bool get previewPointLightShadowsEnabled => _previewPointLightShadowsEnabled;
  set previewPointLightShadowsEnabled(bool value) {
    if (_previewPointLightShadowsEnabled == value) return;
    _previewPointLightShadowsEnabled = value;
    notifyListeners();
  }

  final _dayNightClock = SpatialDayNightPreviewClock();
  double? _dayNightMinute;
  double _dayNightNotificationElapsed = 0;
  bool _dayNightNotificationPending = false;
  double? get previewMinuteOfDay => _dayNightClock.minuteOverride;
  set previewMinuteOfDay(double? value) {
    _dayNightClock.seek(value);
    _dayNightMinute = value;
    notifyListeners();
  }

  bool get previewDayNightRunning => _dayNightClock.running;
  set previewDayNightRunning(bool value) {
    if (_dayNightClock.running == value) return;
    _dayNightClock.running = value;
    notifyListeners();
  }

  double? get dayNightMinuteOfDay => _dayNightMinute;

  void advanceEnvironment(
    double dt,
    SpatialDayNightCycle? cycle,
    double? externalElapsed,
  ) {
    _dayNightClock.advance(dt);
    if (dt.isFinite && dt > 0) _environmentElapsed += dt;
    if (worldEnvironment == null && _visualProfile.requiresWorldEnvironment) {
      _previewEnvironment = resolveWorldEnvironment(
        settings: _visualProfile,
        elapsedSeconds: externalElapsed ?? _environmentElapsed,
        localTime: _visualProfile.choice(SpatialVisualParameter.timeMode) == WorldTimeMode.real.name ? _now() : null,
      );
    } else if (!_visualProfile.requiresWorldEnvironment) {
      _previewEnvironment = const WorldEnvironmentFrame();
    }
    final environment = worldEnvironment ?? _previewEnvironment;
    final preview = previewMinuteOfDay;
    final minute = preview != null
        ? (cycle == null ? preview : _dayNightClock.minute(cycle))
        : worldEnvironment?.minuteOfDay ??
          (_visualProfile.choice(SpatialVisualParameter.timeMode) == WorldTimeMode.cycle.name && cycle != null
              ? _dayNightClock.minute(cycle, externalElapsedSeconds: externalElapsed)
              : environment.minuteOfDay) ?? (cycle == null
            ? visualProfile.number(SpatialVisualParameter.minuteOfDay)
            : _dayNightClock.minute(cycle, externalElapsedSeconds: externalElapsed));
    final before = _dayNightMinute;
    if (minute != before) {
      _dayNightMinute = minute;
      _dayNightNotificationPending = true;
    }
    if (!_dayNightNotificationPending) return;
    _dayNightNotificationElapsed += dt;
    if (before == null || minute == null || _dayNightNotificationElapsed >= 1) {
      _dayNightNotificationElapsed = 0;
      _dayNightNotificationPending = false;
      notifyListeners();
    }
  }

  Future<bool> Function(SpatialScenePreparation)? _prepareDestination;
  SpatialShadowStats Function()? _readShadowStats;
  int Function()? _readActorContactShadowCount;
  int get actorContactShadowCount => _readActorContactShadowCount?.call() ?? 0;
  SpatialShadowStats get shadowStats =>
      _readShadowStats?.call() ?? const SpatialShadowStats();

  Future<bool> prepareDestination(SpatialScenePreparation request) =>
      _prepareDestination?.call(request) ?? Future.value(false);
  @override
  void dolly(double delta) {
    zoom = (zoom * math.exp(delta * .001)).clamp(.125, 1 / .15);
    notifyListeners();
  }

  SpatialEditorView view = SpatialEditorView.orbit;
  Offset pan = Offset.zero;
  void panBy(double x, double z) {
    pan += Offset(x, z);
    notifyListeners();
  }

  @override
  void reset() {
    pan = Offset.zero;
    super.reset();
  }

  void setView(SpatialEditorView value) {
    view = value;
    notifyListeners();
  }
}

class SpatialSceneView extends StatefulWidget {
  const SpatialSceneView({
    super.key,
    required this.scene,
    required this.models,
    required this.loadModel,
    required this.controller,
    required this.onCell,
    required this.background,
    required this.ground,
    required this.edge,
    required this.errorBuilder,
    this.selectedCell,
    this.selectedContent,
    this.contentPreview,
    this.placementPreview,
    this.onHover,
    this.onSurfaceTap,
    this.cellOverlays = const [],
    this.selectionColor,
    this.actorFrames,
    this.onReady,
    this.onVisibleMapsChanged,
    this.onContent,
    this.selectContent = true,
    this.canSelectContent,
    this.canSelectLayer,
    this.visibility,
    this.onZoom,
    this.onContextMenu,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.groundMap,
    this.groundProject,
    this.loadGroundImage,
    this.neighbors = const [],
    this.sceneOffset = Offset.zero,
    this.animationPreview,
    this.modelRuntimeState,
    this.modelPresence,
    this.rasterAnimationElapsedMsForCell,
    this.actorOcclusionStateForCell,
    this.presentationPaused,
    this.presentationElapsedSeconds,
    this.cameraPose,
    this.cameraMagnification,
    this.resourceBudget,
    this.resourceIdentity,
  });
  final RuntimeResourceBudget? resourceBudget;
  final String? resourceIdentity;
  final SpatialModelRuntimeState? Function(String mapId, String instanceId)?
  modelRuntimeState;
  final bool Function(String mapId, String instanceId)? modelPresence;
  final int Function(
    String mapId,
    String layerId,
    int cellX,
    int cellY,
    int elapsedMs,
  )?
  rasterAnimationElapsedMsForCell;
  final SpatialActorOcclusionStateForCell? actorOcclusionStateForCell;
  final bool Function()? presentationPaused;
  final double Function()? presentationElapsedSeconds;
  final ({double x, double y, double z, double zoom})? Function()? cameraPose;
  final double Function()? cameraMagnification;
  final Map<String, SpatialActorVisual> Function(double dt)? actorFrames;
  final VoidCallback? onReady;
  final ValueChanged<Set<String>>? onVisibleMapsChanged;
  final ValueChanged<SpatialSceneContentHit>? onContent;
  final bool selectContent;
  final bool Function(SpatialSceneContentKind kind, String id)?
  canSelectContent;
  final bool Function(String layerId)? canSelectLayer;
  final SpatialSceneVisibility? visibility;
  final ValueChanged<double>? onZoom;
  final void Function(GridPos, Offset)? onContextMenu;
  final bool Function(int, int, SpatialSceneContentHit?)? onDragStart;
  final ValueChanged<(int, int)>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;
  final MapData? groundMap;
  final ProjectManifest? groundProject;
  final Future<Uint8List> Function(String id)? loadGroundImage;
  final List<SpatialSceneNeighbor> neighbors;
  final Offset sceneOffset;
  final SpatialAnimationPreviewController? animationPreview;
  final MapSpatialScene scene;
  final List<ProjectModel3dEntry> models;
  final Future<Uint8List> Function(String id) loadModel;
  final SpatialSceneController controller;
  final void Function(int x, int z) onCell;
  final Color background, ground, edge;
  final (int, int)? selectedCell;
  final SpatialSceneContentHit? selectedContent;
  final SpatialSceneContentPreview? contentPreview;
  final SpatialModelPlacementPreview? placementPreview;
  final ValueChanged<SpatialSurfaceHit?>? onHover;
  final ValueChanged<SpatialSurfaceHit>? onSurfaceTap;
  final List<SpatialCellOverlay> cellOverlays;
  final Color? selectionColor;
  final Widget Function(BuildContext, Object) errorBuilder;

  bool modelSourcesMatch(SpatialSceneView other) =>
      immutableResourcesMatch(other) ||
      _sameModelSourceProjects(groundProject, other.groundProject) &&
          loadModel == other.loadModel &&
          _sameModelSources(models, other.models);

  bool lightingDefaultsMatch(SpatialSceneView other) =>
      models.length == other.models.length &&
      models.indexed.every(
        (entry) =>
            entry.$2.id == other.models[entry.$1].id &&
            entry.$2.castsShadowsByDefault ==
                other.models[entry.$1].castsShadowsByDefault &&
            entry.$2.light == other.models[entry.$1].light,
      );

  bool immutableResourcesMatch(SpatialSceneView other) =>
      resourceIdentity != null &&
      resourceIdentity!.isNotEmpty &&
      resourceIdentity == other.resourceIdentity &&
      resourceBudget != null &&
      identical(resourceBudget, other.resourceBudget);

  bool surfaceGeometryMatches(SpatialSceneView other) =>
      groundProject != null &&
      identical(groundProject, other.groundProject) &&
      groundMap != null &&
      groundMap!.id == other.groundMap?.id &&
      identical(controller, other.controller) &&
      sceneOffset == other.sceneOffset &&
      scene.width == other.scene.width &&
      scene.depth == other.scene.depth &&
      scene.levelHeight == other.scene.levelHeight &&
      scene.navigation == other.scene.navigation &&
      scene.camera == other.scene.camera &&
      listEquals(scene.heightLevels, other.scene.heightLevels);

  @override
  State<SpatialSceneView> createState() => _SpatialSceneViewState();
}

class _SpatialSceneViewState extends State<SpatialSceneView> {
  SpatialSceneGame? game;
  Object? failure;
  Object? previewFailure;
  Object? pendingPreviewFailure;
  bool previewStatusUpdateScheduled = false;
  bool draggingContent = false;
  SpatialContentDrag? contentDrag;
  double? contentDragHeight;
  double trackpadScale = 1;
  int? navigationPointer;
  Offset? navigationOrigin, navigationPosition;
  bool navigationDragged = false, navigationSequence = false;
  Offset? hoverPosition;
  bool hoverRefreshPending = false;
  bool get zoomEnabled =>
      widget.onZoom != null ||
      widget.controller.view != SpatialEditorView.game ||
      widget.onDragStart != null;

  void zoom(double delta) {
    if (!zoomEnabled) return;
    final onZoom = widget.onZoom;
    if (onZoom != null) {
      onZoom(delta);
    } else {
      widget.controller.dolly(delta);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.sceneChanges.addListener(scheduleHoverRefresh);
    widget.controller._prepareDestination = prepareDestination;
    widget.controller._readShadowStats = readShadowStats;
    widget.controller._readActorContactShadowCount =
        readActorContactShadowCount;
    initialize();
  }

  Future<bool> prepareDestination(SpatialScenePreparation request) async =>
      mounted ? await game?.prepareDestination(request) ?? false : false;

  SpatialShadowStats readShadowStats() => game == null
      ? const SpatialShadowStats()
      : (game!.context as SpatialRenderContext).shadowStats;

  int readActorContactShadowCount() =>
      game?.actorContactShadows.components.length ?? 0;

  void scheduleHoverRefresh() {
    if (!mounted ||
        hoverPosition == null ||
        widget.onHover == null ||
        hoverRefreshPending) {
      return;
    }
    hoverRefreshPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hoverRefreshPending = false;
      if (mounted) refreshHover();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void refreshHover() {
    final position = hoverPosition;
    if (position == null || widget.onHover == null) return;
    final game = this.game;
    if (game?.refreshing == true) return;
    game?.syncCamera();
    widget.onHover!(game?.pickSurface(position));
  }

  void hoverAt(Offset position) {
    if (widget.onHover == null || navigationPointer != null) return;
    hoverPosition = position;
    enterHover();
    final game = this.game;
    if (game?.refreshing == true) return;
    widget.onHover!(game?.pickSurface(position));
  }

  void enterHover() {
    final game = this.game;
    if (game != null && game.placementPreviewHidden) {
      game.placementPreviewHidden = false;
      game.syncPlacementPreview();
    }
  }

  void handlePreviewStatus(Object? error) {
    if (!mounted) return;
    if (previewStatusUpdateScheduled ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
      pendingPreviewFailure = error;
      if (previewStatusUpdateScheduled) return;
      previewStatusUpdateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previewStatusUpdateScheduled = false;
        final next = pendingPreviewFailure;
        pendingPreviewFailure = null;
        if (mounted && !identical(previewFailure, next)) {
          setState(() => previewFailure = next);
        }
      });
      return;
    }
    if (mounted && !identical(previewFailure, error)) {
      setState(() => previewFailure = error);
    }
  }

  void exitHover() {
    hoverPosition = null;
    final game = this.game;
    if (game != null) {
      game.placementPreviewHidden = true;
      game.placementRenderer.clear();
    }
    widget.onHover?.call(null);
  }

  void startNavigation(PointerEvent event, Offset origin) {
    if (draggingContent) widget.onDragCancel?.call();
    draggingContent = false;
    contentDrag = null;
    contentDragHeight = null;
    navigationPointer = event.pointer;
    navigationOrigin = navigationPosition = origin;
    navigationDragged = false;
    navigationSequence = true;
    exitHover();
    setState(() {});
  }

  void pointerDown(PointerDownEvent event) {
    if (navigationPointer != null) return;
    navigationSequence = false;
    navigationDragged = false;
    if (widget.onDragStart != null &&
        event.kind == PointerDeviceKind.mouse &&
        event.buttons & kSecondaryMouseButton != 0) {
      startNavigation(event, event.localPosition);
    }
  }

  void pointerMove(PointerMoveEvent event) {
    if (widget.onDragStart == null || event.kind != PointerDeviceKind.mouse) {
      return;
    }
    if (event.buttons & kSecondaryMouseButton == 0) {
      endNavigation(event);
      return;
    }
    if (navigationPointer == null) {
      startNavigation(event, event.localPosition - event.localDelta);
    }
    if (navigationPointer != event.pointer) return;
    if (!navigationDragged &&
        (event.localPosition - navigationOrigin!).distance <=
            kPrecisePointerPanSlop) {
      return;
    }
    navigationDragged = true;
    final delta = event.localPosition - navigationPosition!;
    navigationPosition = event.localPosition;
    final viewport = context.size;
    if (viewport == null || viewport.isEmpty) return;
    final yaw = switch (widget.controller.view) {
      SpatialEditorView.game => widget.scene.camera.yawDegrees * math.pi / 180,
      SpatialEditorView.top => 0.0,
      SpatialEditorView.orbit => widget.controller.yaw,
    };
    final x =
        -delta.dx /
        viewport.width *
        widget.scene.width *
        widget.controller.zoom;
    final z =
        -delta.dy /
        viewport.height *
        widget.scene.depth *
        widget.controller.zoom;
    widget.controller.panBy(
      x * math.cos(yaw) + z * math.sin(yaw),
      -x * math.sin(yaw) + z * math.cos(yaw),
    );
  }

  void endNavigation(PointerEvent event) {
    if (navigationPointer != event.pointer) return;
    navigationPointer = null;
    navigationOrigin = navigationPosition = null;
    setState(() {});
  }

  Future<void> initialize() async {
    try {
      await initializeSpatialRenderer();
      if (!mounted) return;
      final initialized = SpatialSceneGame(
        widget,
        onPreviewStatus: handlePreviewStatus,
        onSurfaceChanged: scheduleHoverRefresh,
      );
      setState(() => game = initialized);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  Future<void> refresh() async {
    try {
      final refreshed = await game?.refresh();
      if (mounted && refreshed == true) setState(() => failure = null);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  @override
  void didUpdateWidget(SpatialSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.sceneChanges.removeListener(scheduleHoverRefresh);
      if (oldWidget.controller._prepareDestination == prepareDestination) {
        oldWidget.controller._prepareDestination = null;
      }
      widget.controller.sceneChanges.addListener(scheduleHoverRefresh);
      widget.controller._prepareDestination = prepareDestination;
      oldWidget.controller._readShadowStats = null;
      oldWidget.controller._readActorContactShadowCount = null;
      widget.controller._readShadowStats = readShadowStats;
      widget.controller._readActorContactShadowCount =
          readActorContactShadowCount;
    }
    if (widget.onHover == null) hoverPosition = null;
    final game = this.game;
    if (game == null) return;
    if (oldWidget.controller != widget.controller && game.sceneReady) {
      oldWidget.controller.sceneChanges.removeListener(game.syncCamera);
      widget.controller.sceneChanges.addListener(game.syncCamera);
    }
    if (oldWidget.animationPreview != widget.animationPreview &&
        game.sceneReady) {
      oldWidget.animationPreview?.removeListener(game.syncAnimations);
      widget.animationPreview?.addListener(game.syncAnimations);
    }
    game.configuration = widget;
    if (game.hasVisualOrderChange) {
      refresh();
      return;
    }
    final resourceIdentityChanged =
        widget.resourceIdentity != oldWidget.resourceIdentity ||
        !identical(widget.resourceBudget, oldWidget.resourceBudget);
    final modelSourcesChanged =
        !widget.modelSourcesMatch(oldWidget) || resourceIdentityChanged;
    if ((!widget.immutableResourcesMatch(oldWidget) &&
            !identical(oldWidget.groundProject, widget.groundProject)) ||
        resourceIdentityChanged) {
      game.clearGroundResourceCache(retire: true);
      game.placementRenderer.clear();
    }
    if (modelSourcesChanged) {
      game.clearModelResourceCache(retire: true);
      game.loadedModelSources.clear();
      game.clippedModelCache.clear();
      game.sceneChunks.clear();
      game.placementRenderer.clear();
    }
    if (widget.placementPreview == null) game.placementRenderer.clear();
    if (!identical(oldWidget.scene, widget.scene) ||
        !identical(oldWidget.groundMap, widget.groundMap) ||
        !identical(oldWidget.groundProject, widget.groundProject) ||
        modelSourcesChanged ||
        !widget.lightingDefaultsMatch(oldWidget) ||
        !_sameNeighbors(oldWidget.neighbors, widget.neighbors) ||
        oldWidget.sceneOffset != widget.sceneOffset ||
        oldWidget.selectedCell != widget.selectedCell) {
      refresh();
    } else if (!game.refreshing) {
      game.renderedConfiguration = widget;
      game.syncVisibility();
      game.syncContentSelection(oldWidget, widget);
      if (!identical(oldWidget.contentPreview, widget.contentPreview)) {
        game.syncContentPreview();
      }
      if (!identical(oldWidget.placementPreview, widget.placementPreview)) {
        game.syncPlacementPreview();
      }
      if (!listEquals(oldWidget.cellOverlays, widget.cellOverlays)) {
        game.syncCellOverlays();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.sceneChanges.removeListener(scheduleHoverRefresh);
    if (widget.controller._prepareDestination == prepareDestination) {
      widget.controller._prepareDestination = null;
    }
    if (widget.controller._readActorContactShadowCount ==
        readActorContactShadowCount) {
      widget.controller._readActorContactShadowCount = null;
    }
    game?.placementRenderer.dispose();
    if (widget.controller._readShadowStats == readShadowStats) {
      widget.controller._readShadowStats = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = this.game;
    final lighting = SpatialLightingPreview.maybeOf(context);
    if (game != null) {
      game.previewLighting = lighting;
      game.syncLighting();
    }
    return MouseRegion(
      cursor: navigationPointer == null
          ? MouseCursor.defer
          : SystemMouseCursors.grabbing,
      onEnter: widget.placementPreview == null ? null : (_) => enterHover(),
      onHover: widget.onHover == null
          ? null
          : (event) => hoverAt(event.localPosition),
      onExit: widget.onHover == null && widget.placementPreview == null
          ? null
          : (_) => exitHover(),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: pointerDown,
        onPointerMove: pointerMove,
        onPointerUp: endNavigation,
        onPointerCancel: endNavigation,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && zoomEnabled) {
            GestureBinding.instance.pointerSignalResolver.register(
              event,
              (_) => zoom(event.scrollDelta.dy),
            );
          }
        },
        onPointerPanZoomStart: (_) => trackpadScale = 1,
        onPointerPanZoomUpdate: (event) {
          zoom(
            -event.panDelta.dy - math.log(event.scale / trackpadScale) * 1000,
          );
          trackpadScale = event.scale;
        },
        child: game == null
            ? failure == null
                  ? const Center(child: Text('Chargement de la scène…'))
                  : widget.errorBuilder(context, failure!)
            : GestureDetector(
                supportedDevices: zoomEnabled
                    ? (PointerDeviceKind.values.toSet()
                        ..remove(PointerDeviceKind.trackpad))
                    : null,
                onSecondaryTapUp: (event) {
                  if (navigationDragged) return;
                  final cell = game.pickContentCell(event.localPosition);
                  if (cell != null)
                    widget.onContextMenu?.call(
                      GridPos(x: cell.$1, y: cell.$2),
                      event.globalPosition,
                    );
                },
                onPanStart: (event) {
                  if (navigationSequence) return;
                  hoverAt(event.localPosition);
                  final orbit =
                      widget.controller.view == SpatialEditorView.orbit &&
                      HardwareKeyboard.instance.isAltPressed;
                  final hit = widget.selectContent && !orbit
                      ? game.pickContent(event.localPosition)
                      : null;
                  contentDragHeight = hit == null
                      ? null
                      : game.contentHeight(hit, event.localPosition);
                  final ground = contentDragHeight == null
                      ? game.pickCell(event.localPosition)
                      : game.pickPlaneCell(
                          event.localPosition,
                          contentDragHeight!,
                        );
                  final cell = hit?.cell ?? ground;
                  draggingContent =
                      cell != null &&
                      ground != null &&
                      !orbit &&
                      (widget.onDragStart?.call(cell.$1, cell.$2, hit) ??
                          false);
                  contentDrag = draggingContent
                      ? SpatialContentDrag(
                          anchor: cell!,
                          pointerOrigin: ground!,
                        )
                      : null;
                  if (!draggingContent) contentDragHeight = null;
                },
                onPanEnd: (_) {
                  if (draggingContent) widget.onDragEnd?.call();
                  draggingContent = false;
                  contentDrag = null;
                  contentDragHeight = null;
                },
                onPanCancel: () {
                  if (draggingContent) widget.onDragCancel?.call();
                  draggingContent = false;
                  contentDrag = null;
                  contentDragHeight = null;
                },
                onPanUpdate: (event) {
                  if (navigationSequence) return;
                  hoverAt(event.localPosition);
                  if (draggingContent) {
                    final cell = contentDragHeight == null
                        ? game.pickCell(event.localPosition)
                        : game.pickPlaneCell(
                            event.localPosition,
                            contentDragHeight!,
                          );
                    if (cell != null)
                      widget.onDragUpdate?.call(contentDrag!.cellAt(cell));
                    return;
                  }
                  if (widget.onDragStart != null &&
                      widget.controller.view == SpatialEditorView.game) {
                    widget.controller.panBy(
                      -event.delta.dx /
                          game.size.x *
                          widget.scene.width *
                          widget.controller.zoom,
                      -event.delta.dy /
                          game.size.y *
                          widget.scene.depth *
                          widget.controller.zoom,
                    );
                  }
                  if (widget.controller.view == SpatialEditorView.orbit) {
                    widget.controller.orbit(event.delta.dx, event.delta.dy);
                  }
                },
                onTapUp: (event) {
                  if (navigationSequence) return;
                  final hit = widget.selectContent
                      ? game.pickContent(event.localPosition)
                      : null;
                  if (hit != null && widget.onContent != null) {
                    widget.onContent!(hit);
                    return;
                  }
                  final surface = game.pickSurface(event.localPosition);
                  if (surface != null && widget.onSurfaceTap != null) {
                    widget.onSurfaceTap!(surface);
                    return;
                  }
                  final cell = surface?.cell;
                  if (cell != null) widget.onCell(cell.$1, cell.$2);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SpatialGameSurface<SpatialSceneGame>(
                        game: game,
                        loadingBuilder: (_) => const Center(
                          child: Text('Chargement de la scène…'),
                        ),
                        errorBuilder: widget.errorBuilder,
                      ),
                    ),
                    if (failure != null || previewFailure != null)
                      Positioned.fill(
                        child: widget.errorBuilder(
                          context,
                          failure ?? previewFailure!,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

@visibleForTesting
class SpatialSceneGame extends FlameGame3D<World3D, CameraComponent3D> {
  @override
  late final FlutterFrameGraphicsDevice device = FlutterFrameGraphicsDevice();

  SpatialDepthOfField? _depthOfField;
  int renderedFrameCount = 0;

  Map<String, Object?> get depthOfFieldFrame => {
    'render': renderedFrameCount,
    'enabled': (context as SpatialRenderContext).depthOfField != null,
    'strength': _depthOfField?.profile.strength,
    'focusRange': _depthOfField?.profile.focusRange,
    'focusDepth': _depthOfField?.focusDepth,
    'depthPasses': _depthOfField?.depthPasses ?? 0,
    'compositePasses': _depthOfField?.compositePasses ?? 0,
    'targetAllocations': _depthOfField?.targetAllocations ?? 0,
  };

  final Paint _weatherFlashPaint = Paint()..blendMode = BlendMode.screen;
  final Paint _weatherVeilPaint = Paint();
  double _weatherVeil = -1;
  Size _weatherVeilSize = Size.zero;
  double _weatherFlash = -1;
  Size _weatherFlashSize = Size.zero;

  @override
  void render(Canvas canvas) => device.guardFrame(() {
    syncDepthOfField();
    super.render(canvas);
    final weather = context as SpatialRenderContext;
    final veil = (weather.weatherVeilOpacity * 200).round() / 200;
    if (veil > 0) {
      final viewport = Size(size.x, size.y);
      if (veil != _weatherVeil || viewport != _weatherVeilSize) {
        _weatherVeil = veil;
        _weatherVeilSize = viewport;
        _weatherVeilPaint.shader = ui.Gradient.linear(Offset.zero, Offset(viewport.width * .3, viewport.height), [const Color(0xff637c98).withValues(alpha: veil), const Color(0xff637c98).withValues(alpha: veil * .3)]);
      }
      canvas.drawRect(Offset.zero & viewport, _weatherVeilPaint);
    }
    final flash = weather.weatherSkyFlash;
    if (flash > .0001) {
      final viewport = Size(size.x, size.y);
      if (flash != _weatherFlash || viewport != _weatherFlashSize) {
        _weatherFlash = flash;
        _weatherFlashSize = viewport;
        _weatherFlashPaint.shader = ui.Gradient.linear(
          Offset.zero, Offset(0, viewport.height),
          [const Color(0xffe5edff).withValues(alpha: flash * 9), const Color(0xffe5edff).withValues(alpha: flash * 5)],
        );
      }
      canvas.drawRect(Offset.zero & viewport, _weatherFlashPaint);
    }
    renderedFrameCount++;
  });

  void syncDepthOfField() {
    final renderContext = context as SpatialRenderContext;
    final profile = visibleConfiguration.controller.depthOfFieldProfile;
    if (profile.active && !_isIndoor) {
      final focus = _depthOfField ??= SpatialDepthOfField(device.backend);
      focus
        ..profile = profile
        ..focusDepth = (camera.position - camera.target).length;
      renderContext.depthOfField = focus;
      device.postProcess = focus.composite;
    } else {
      renderContext.depthOfField = null;
      device.postProcess = null;
    }
  }

  @override
  late final RenderContext3D context = SpatialRenderContext(device);

  SpatialSceneGame(
    this.configuration, {
    required this.onPreviewStatus,
    required this.onSurfaceChanged,
  }) : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));
  SpatialSceneView configuration;
  SpatialLightingProfile? previewLighting;
  SpatialLightingProfile authoredLighting = SpatialLightingProfile.disabled;
  List<SpatialAuthoredShadowCaster> authoredShadowCasters = const [];
  double authoredReceiverMinY = 0;
  double authoredReceiverMaxY = 0;
  List<({Model3dPointLight definition, _SceneModelComponent component})>
  pointLightBindings = [];
  final _lightProximity = Expando<SpatialLightProximityState>();
  final _lightEmission = Expando<(Color, double)>();

  bool get _isIndoor {
    final metadata = visibleConfiguration.groundMap?.mapMetadata;
    return metadata?.isIndoor == true ||
        switch (metadata?.mapType) {
          MapType.building ||
          MapType.interior ||
          MapType.facility ||
          MapType.cave => true,
          _ => false,
        };
  }

  void syncLighting() {
    (context as SpatialRenderContext).pointLightShadowsEnabled =
        this.configuration.controller.previewPointLightShadowsEnabled;
    final preview = previewLighting;
    if (preview != null) {
      (context as SpatialRenderContext).lighting = preview;
      return;
    }
    final configuration = visibleConfiguration;
    final shadowCasters = _visibleShadowCasters ?? authoredShadowCasters;
    final cycle = configuration.controller.effectiveCycle(
      configuration.scene.dayNightCycle,
    );
    final minute = configuration.controller.dayNightMinuteOfDay ?? configuration.controller.worldEnvironment?.minuteOfDay ?? (cycle == null
        ? configuration.controller.previewMinuteOfDay ??
              configuration.controller.visualProfile.number(
                SpatialVisualParameter.minuteOfDay,
              )
        : configuration.controller._dayNightClock.minute(
            cycle,
            externalElapsedSeconds: configuration.presentationElapsedSeconds
                ?.call(),
          ));
    final frame = _isIndoor || minute == null
        ? null
        : spatialDayNightFrame(minute);
    final sunDirection = frame == null
        ? authoredLighting.sunDirection
        : spatialDayNightSunDirection(authoredLighting.sunDirection, frame);
    final receiverBounds = shadowCasters.isEmpty || size.x <= 0 || size.y <= 0
        ? null
        : spatialShadowReceiverBounds(
            camera.viewProjectionMatrix,
            minimumY: authoredReceiverMinY,
            maximumY: authoredReceiverMaxY,
          );
    final movingSun =
        frame != null && frame.solarPhase != 0 && frame.daylight > .001;
    final focusedReceivers =
        receiverBounds != null && (frame?.daylight ?? 1) > .001;
    final solarLighting = !movingSun && !focusedReceivers
        ? authoredLighting
        : spatialAuthoredShadowLighting(
            shadowCasters,
            receiverMinY: authoredReceiverMinY,
            receiverMaxY: authoredReceiverMaxY,
            receiverBounds: receiverBounds,
            sunDirection: sunDirection,
          );
    if (frame == null &&
        pointLightBindings.isEmpty &&
        !configuration.controller.atmosphereProfile.fireflyLighting) {
      (context as SpatialRenderContext).lighting = solarLighting;
      return;
    }
    final hero = actorVisual;
    final anchor = hero == null
        ? Vector3(
            configuration.scene.width / 2 +
                configuration.sceneOffset.dx +
                configuration.controller.pan.dx,
            0,
            configuration.scene.depth / 2 +
                configuration.sceneOffset.dy +
                configuration.controller.pan.dy,
          )
        : Vector3(
            hero.x + configuration.sceneOffset.dx,
            hero.y,
            hero.z + configuration.sceneOffset.dy,
          );
    final lights = spatialVisiblePointLights([
      for (final binding in pointLightBindings)
        if (binding.component.presentationVisible)
          _placedLight(
            binding.definition,
            binding.component,
            anchor,
            frame?.daylight ?? 1,
          ),
    ], anchor);
    (context as SpatialRenderContext).lighting = spatialEnvironmentLighting(
      solarLighting,
      frame: frame,
      lights: lights,
      fireflyLights: atmosphereEffects.lights(anchor),
      sunDirection: sunDirection,
    );
  }

  SpatialPointLight _placedLight(
    Model3dPointLight definition,
    _SceneModelComponent component,
    Vector3 anchor,
    double daylight,
  ) {
    final configuration = visibleConfiguration;
    final elapsed =
        configuration.presentationElapsedSeconds?.call() ?? atmosphereElapsed;
    final origin = component.worldTransformMatrix.transform3(Vector3.zero());
    final strength =
        (_lightProximity[component] ??= SpatialLightProximityState()).sample(
          rule: definition.proximity,
          elapsedSeconds: elapsed,
          distanceSquared:
              (origin.x - anchor.x) * (origin.x - anchor.x) +
              (origin.z - anchor.z) * (origin.z - anchor.z),
        );
    final light = spatialPlacedPointLight(
      definition,
      component.worldTransformMatrix,
      daylight: daylight,
      indoors: _isIndoor,
      elapsedSeconds: elapsed,
      proximityStrength: strength,
    );
    _lightEmission[component] = (light.color, strength);
    return light;
  }

  (Color, double)? _haloEmission(String instanceId) {
    final component = modelComponents[instanceId]?.component;
    return component == null ? null : _lightEmission[component];
  }

  final ValueChanged<Object?> onPreviewStatus;
  final VoidCallback onSurfaceChanged;
  SpatialSceneView? renderedConfiguration;
  SpatialSceneView get visibleConfiguration =>
      renderedConfiguration ?? configuration;
  bool refreshing = false;
  final Map<String, Future<Model>> cache = {};
  final loadedModelSources = <String, Model>{};
  final clippedModelCache = SpatialClippedModelCache();
  Map<
    String,
    ({_SceneModelComponent component, Vector3 position, Model3dVector3 anchor})
  >
  modelComponents = {};
  Map<(String, String), _SceneModelComponent> animationModels = {};
  SpatialRuntimeModelIndex runtimeModelIndex = SpatialRuntimeModelIndex(
    const {},
  );
  bool sceneReady = false, closed = false;
  final actorSelections = <String, List<MeshComponent>>{};
  int generation = 0;
  int visualOrderUpdates = 0;
  int visualGroundRebuilds = 0;
  int visibilityUpdates = 0;
  int visibilityGroundRebuilds = 0;
  SpatialSceneVisibility _appliedVisibility = SpatialSceneVisibility.all;
  List<SpatialAuthoredShadowCaster>? _visibleShadowCasters;
  Set<String> _hiddenShadowIds = {};
  Set<String> _casterShadowIds = {};
  bool _actorsVisibilityFiltered = false;
  final _visibilityRetainedGroundImages = <String>{};
  Completer<bool>? _pendingVisualOrder;
  final actors =
      <String, ({MeshComponent mesh, SpatialPixelMaterial material})>{};
  late final actorContactShadows = SpatialActorContactShadows(world);
  late final weatherEffects = SpatialWeatherEffects(world);
  late final atmosphereEffects = SpatialAtmosphereEffects(world);
  late final presentationEffects = SpatialPresentationEffects(world);
  double atmosphereElapsed = 0;
  Map<String, SpatialActorVisual> actorFrames = const {};
  SpatialActorVisual? actorVisual;
  double billboardPitch = 0, billboardYaw = 0;
  final groundTextureCache = <String, Future<Texture>>{};
  final _groundTextures = <String, Texture>{};
  final _groundTextureTokens = <String, Object>{};
  final _groundTextureErrors = <String, Object>{};
  final _reportedGroundTextureErrors = <String, Object>{};
  Set<String> _wantedGroundImages = {};
  final _ownedResourceBudget = RuntimeResourceBudget();
  RuntimeResourceBudget get resourceBudget =>
      configuration.resourceBudget ?? _ownedResourceBudget;
  final modelReservations = <String, RuntimeResourceReservation>{};
  final groundReservations = <String, RuntimeResourceReservation>{};
  final retiredReservations = <RuntimeResourceReservation>[];
  SpatialSceneResourcePreparation? _destinationPreparation;

  Future<bool> prepareDestination(SpatialScenePreparation request) async {
    if (!sceneReady ||
        closed ||
        refreshing ||
        request.resourceIdentity.isEmpty ||
        request.resourceIdentity != configuration.resourceIdentity ||
        !identical(request.resourceBudget, resourceBudget) ||
        !request.isCurrent())
      return false;
    _destinationPreparation?.discard();
    final ticket = generation;
    final preparation = SpatialSceneResourcePreparation(
      request,
      modelCache: cache,
      groundTextureCache: groundTextureCache,
      isCurrent: () =>
          !closed &&
          generation == ticket &&
          configuration.resourceIdentity == request.resourceIdentity &&
          identical(resourceBudget, request.resourceBudget),
    );
    _destinationPreparation = preparation;
    try {
      if (!await preparation.prepare()) return false;
      preparation.adoptInto(
        cache,
        groundTextureCache,
        modelReservations,
        groundReservations,
      );
      return true;
    } on Object {
      preparation.discard();
      if (identical(_destinationPreparation, preparation)) {
        _destinationPreparation = null;
      }
      rethrow;
    }
  }

  void clearGroundResourceCache({bool retire = false}) {
    groundTextureCache.clear();
    _groundTextures.clear();
    _groundTextureTokens.clear();
    _groundTextureErrors.clear();
    _reportedGroundTextureErrors.clear();
    _wantedGroundImages.clear();
    if (retire) {
      retiredReservations.addAll(groundReservations.values);
    } else {
      for (final lease in groundReservations.values) {
        lease.release();
      }
    }
    groundReservations.clear();
  }

  Future<Texture> _loadGroundTexture(
    String id,
    Future<Uint8List> Function(String) loader,
    ProjectManifest project, {
    required int ticket,
    bool prefetch = false,
  }) {
    final existing = groundTextureCache[id];
    if (existing != null) {
      return existing.then((texture) {
        if (!closed &&
            ticket == generation &&
            identical(groundTextureCache[id], existing)) {
          _groundTextures[id] = texture;
        }
        return texture;
      });
    }
    final token = Object();
    _groundTextureTokens[id] = token;
    bool current() =>
        !closed &&
        ticket == generation &&
        identical(_groundTextureTokens[id], token) &&
        _wantedGroundImages.contains(id);
    late final Future<Texture> pending;
    pending =
        loadSpatialGroundTextureFromSource(
          () => loader(id),
          transparentColor: project.tilesets
              .where((tileset) => tileset.id == id)
              .firstOrNull
              ?.transparentColor,
          budget: resourceBudget,
          prefetch: prefetch,
          isCurrent: current,
          onResident: (lease) {
            if (!current()) {
              lease.release();
              return;
            }
            groundReservations.remove(id)?.release();
            groundReservations[id] = lease;
          },
        ).then(
          (texture) {
            if (current()) {
              _groundTextures[id] = texture;
              _groundTextureErrors.remove(id);
            }
            return texture;
          },
          onError: (Object error, StackTrace stack) {
            if (identical(groundTextureCache[id], pending)) {
              groundTextureCache.remove(id);
              if (current() &&
                  (!prefetch || error is! RuntimeResourceAdmissionException)) {
                _groundTextureErrors[id] = error;
              }
              _groundTextureTokens.remove(id);
            }
            Error.throwWithStackTrace(error, stack);
          },
        );
    groundTextureCache[id] = pending;
    return pending;
  }

  void _pruneGroundTextures({bool sample = true}) {
    final elapsed = (groundElapsed * 1000).round();
    if (sample) {
      for (final ground in grounds) {
        if (!refreshing) {
          ground.animationElapsedMsForCell =
              visibleConfiguration.rasterAnimationElapsedMsForCell;
          ground.occlusionStateForCell =
              visibleConfiguration.actorOcclusionStateForCell;
          ground.presentationElapsedSeconds =
              visibleConfiguration.presentationElapsedSeconds;
        }
        ground.sampleTextureWindow(elapsed);
      }
    }
    _wantedGroundImages = {
      for (final ground in grounds) ...ground.currentImageIds,
      for (final ground in grounds) ...ground.nextImageIds,
      for (final ground in grounds) ...ground.renderedImageIds,
      ...?_destinationPreparation?.preparedGroundImageIds,
      ..._visibilityRetainedGroundImages,
    };
    for (final id in groundTextureCache.keys.toList()) {
      if (_wantedGroundImages.contains(id)) continue;
      groundTextureCache.remove(id);
      _groundTextures.remove(id);
      _groundTextureTokens.remove(id);
      _groundTextureErrors.remove(id);
      _reportedGroundTextureErrors.remove(id);
      groundReservations.remove(id)?.release();
    }
  }

  void _requestGroundAnimationTextures(int elapsed) {
    _pruneGroundTextures();
    final required = <String>{};
    for (final ground in grounds) {
      required.addAll(ground.currentImageIds);
    }
    for (final prefetch in [false, true]) {
      for (final ground in grounds) {
        final ids = prefetch ? ground.nextImageIds : ground.currentImageIds;
        for (final id in ids) {
          if (prefetch && required.contains(id)) continue;
          final error = _groundTextureErrors[id];
          if (error != null) {
            if (!prefetch &&
                !identical(_reportedGroundTextureErrors[id], error)) {
              _reportedGroundTextureErrors[id] = error;
              onPreviewStatus(error);
            }
            continue;
          }
          if (_groundTextures.containsKey(id)) continue;
          final pending = _loadGroundTexture(
            id,
            ground.loader,
            ground.project,
            ticket: generation,
            prefetch: prefetch,
          );
          unawaited(
            pending.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
          );
        }
      }
    }
  }

  void clearModelResourceCache({bool retire = false}) {
    cache.clear();
    if (retire) {
      retiredReservations.addAll(modelReservations.values);
    } else {
      for (final lease in modelReservations.values) {
        lease.release();
      }
    }
    modelReservations.clear();
  }

  void retainModelReservation(String key, RuntimeResourceReservation lease) {
    if (closed || !cache.containsKey(key)) {
      lease.release();
      return;
    }
    modelReservations.remove(key)?.release();
    modelReservations[key] = lease;
  }

  Map<String, _SceneChunk> sceneChunks = {};
  final _smartTileProjectionCache =
      Map<
        MapData,
        ({
          ProjectSmartTileCatalog catalog,
          int width,
          int height,
          MapData map,
          bool hasGeneratedModels,
          Map<String, ({String layerId, GridPos cell})> cellOrigins,
          Map<String, ({double height, int layerRank})> paintHeightAnchors,
        })
      >.identity();

  MapData projectedSmartTileMap(MapData map, ProjectManifest? project) {
    if (project == null) return map;
    final cached = _smartTileProjectionCache[map];
    if (cached != null &&
        identical(cached.catalog, project.smartTileCatalog) &&
        cached.width == project.settings.tileWidth &&
        cached.height == project.settings.tileHeight) {
      return cached.map;
    }
    final projection = resolveSpatialSmartTileModelProjection(
      map: map,
      catalog: project.smartTileCatalog,
      sourceCellWidth: project.settings.tileWidth,
      sourceCellHeight: project.settings.tileHeight,
    );
    final projected = _mapWithSmartTileProjection(map, projection);
    final ranks = spatialSmartTileLayerPaintRanks(map);
    if (_smartTileProjectionCache.length >= 8) {
      _smartTileProjectionCache.remove(_smartTileProjectionCache.keys.first);
    }
    _smartTileProjectionCache[map] = (
      catalog: project.smartTileCatalog,
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
      map: projected,
      hasGeneratedModels: projection.instances.isNotEmpty,
      cellOrigins: projection.cellOrigins,
      paintHeightAnchors: Map.unmodifiable({
        for (final instance in projection.instances)
          if (projection.paintHeightInstanceIds.contains(instance.id))
            instance.id: (
              height: instance.position.y,
              layerRank: ranks[projection.cellOrigins[instance.id]!.layerId]!,
            ),
      }),
    );
    return projected;
  }

  List<_SceneGround> grounds = [];
  late final sceneComponents = SpatialSceneComponents(world);
  late final placementRenderer = SpatialPlacementPreviewRenderer(
    world,
    onStatus: onPreviewStatus,
    loadModel: (definition) {
      final ticket = generation;
      return ModelByteLoader.loadCached(
        cache,
        definition.sourceAssetId,
        () => configuration.loadModel(definition.id),
        budget: resourceBudget,
        isCurrent: () => ticket == generation && !closed,
        onResident: retainModelReservation,
      );
    },
  );
  bool placementPreviewHidden = false;
  List<MeshComponent> cellOverlayComponents = [];
  double groundElapsed = 0;
  @override
  Color backgroundColor() => visibleConfiguration.background;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (closed) return;
    weatherEffects.prepare();
    sceneReady = true;
    configuration.controller.sceneChanges.addListener(syncCamera);
    configuration.animationPreview?.addListener(syncAnimations);
    world.add(LightComponent.ambient(intensity: 0.85));
    await refresh();
    if (!closed) {
      configuration.onReady?.call();
      if (configuration.onHover != null) onSurfaceChanged();
    }
  }

  bool get hasVisualOrderChange =>
      renderedConfiguration != null &&
      _visualOrderChange(renderedConfiguration!, configuration) != null;

  bool _modelVisible(String mapId, String id) {
    final current = visibleConfiguration;
    if (current.visibility == null) return true;
    if (mapId != (current.groundMap?.id ?? '__scene__')) return true;
    final visibility = current.visibility ?? SpatialSceneVisibility.all;
    final origin = sceneChunks[mapId]?.cellOrigins[id];
    return visibility.contentVisible(SpatialSceneContentKind.model, id) &&
        (origin == null || visibility.layerVisible(origin.layerId));
  }

  void syncVisibility() {
    if (!sceneReady || closed || refreshing) return;
    final current = visibleConfiguration;
    final next = current.visibility ?? SpatialSceneVisibility.all;
    final before = _appliedVisibility;
    if (before == next) return;
    _appliedVisibility = next;
    _actorsVisibilityFiltered =
        next.hiddenKinds.contains(SpatialSceneContentKind.actor) ||
        next.hiddenContent.any(
          (entry) => entry.$1 == SpatialSceneContentKind.actor,
        );
    final mapId = current.groundMap?.id ?? '__scene__';
    final chunk = sceneChunks[mapId];
    final modelIds = <String>{
      for (final entry in {...before.hiddenContent, ...next.hiddenContent})
        if (entry.$1 == SpatialSceneContentKind.model &&
            before.hiddenContent.contains(entry) !=
                next.hiddenContent.contains(entry))
          entry.$2,
      if (before.hiddenKinds.contains(SpatialSceneContentKind.model) !=
          next.hiddenKinds.contains(SpatialSceneContentKind.model))
        ...modelComponents.keys,
    };
    if (!before.layersMatch(next) && chunk != null) {
      if (before.allLayersHidden != next.allLayersHidden) {
        modelIds.addAll(chunk.cellOrigins.keys);
      } else {
        for (final layer in {...before.hiddenLayers, ...next.hiddenLayers}) {
          if (before.hiddenLayers.contains(layer) ==
              next.hiddenLayers.contains(layer))
            continue;
          modelIds.addAll(chunk.modelIdsByLayer[layer] ?? const <String>{});
        }
      }
      _syncVisibleGround(chunk, next);
    }
    var shadowsChanged = false;
    var lightsChanged = false;
    for (final id in modelIds) {
      final component = modelComponents[id]?.component;
      if (component == null) continue;
      component.presentationVisible =
          _modelVisible(mapId, id) &&
          (current.modelPresence?.call(mapId, id) ?? true);
      if (component.definition.light != null) lightsChanged = true;
      if (_casterShadowIds.contains(component.shadowId)) {
        shadowsChanged = true;
        _modelVisible(mapId, id)
            ? _hiddenShadowIds.remove(component.shadowId)
            : _hiddenShadowIds.add(component.shadowId);
      }
      if (!component.presentationVisible) {
        final selection = modelSelections.remove(id);
        if (selection != null) component.removeAll(selection);
      }
    }
    if (shadowsChanged) {
      _refreshVisibilityLighting();
    }
    final actorIds = <String>{
      for (final entry in {...before.hiddenContent, ...next.hiddenContent})
        if (entry.$1 == SpatialSceneContentKind.actor &&
            before.hiddenContent.contains(entry) !=
                next.hiddenContent.contains(entry))
          entry.$2,
      if (before.hiddenKinds.contains(SpatialSceneContentKind.actor) !=
          next.hiddenKinds.contains(SpatialSceneContentKind.actor))
        ...actors.keys,
    };
    for (final id in actorIds) {
      final actor = actors[id]?.mesh;
      if (actor is! _SceneActorComponent) continue;
      actor.presentationVisible = next.contentVisible(
        SpatialSceneContentKind.actor,
        id,
      );
      if (!actor.presentationVisible) {
        final selection = actorSelections.remove(id);
        if (selection != null) actor.removeAll(selection);
      }
    }
    if (actorIds.isNotEmpty) syncActorContactShadows();
    if (current.cellOverlays.any((overlay) {
      final kind = switch (overlay.kind) {
        SpatialCellOverlayKind.spawn => SpatialSceneContentKind.marker,
        SpatialCellOverlayKind.warp => SpatialSceneContentKind.warp,
        _ => null,
      };
      return kind != null &&
          before.contentVisible(kind, overlay.id) !=
              next.contentVisible(kind, overlay.id);
    }))
      syncCellOverlays();
    if (shadowsChanged || lightsChanged) syncLighting();
    visibilityUpdates++;
    if (current.onHover != null) onSurfaceChanged();
  }

  void _refreshVisibilityLighting() {
    _visibleShadowCasters = _hiddenShadowIds.isEmpty
        ? null
        : List.unmodifiable(
            authoredShadowCasters.where(
              (caster) => !_hiddenShadowIds.contains(caster.id),
            ),
          );
    authoredLighting = spatialAuthoredShadowLighting(
      _visibleShadowCasters ?? authoredShadowCasters,
      receiverMinY: authoredReceiverMinY,
      receiverMaxY: authoredReceiverMaxY,
    );
  }

  void _syncVisibleGround(
    _SceneChunk chunk,
    SpatialSceneVisibility visibility,
  ) {
    final current = visibleConfiguration;
    final ground = chunk.ground;
    final map = chunk.signature.$1;
    final project = current.groundProject;
    if (ground == null || map == null || project == null) return;
    if (ground.sourcePlan.layersMatchVisibility(
          ground.plan,
          visibility.layerVisible,
        ) &&
        ground.sourceOcclusionPlan.layersMatchVisibility(
          ground.occlusionPlan,
          visibility.layerVisible,
        ))
      return;
    _visibilityRetainedGroundImages.addAll({
      ...ground.currentImageIds,
      ...ground.nextImageIds,
      ...ground.renderedImageIds,
    });
    final plan = ground.sourcePlan.withLayerVisibility(visibility.layerVisible);
    final previous = <Object3D>[...ground.components, ...chunk.terrain];
    ground.plan = plan;
    ground.occlusionPlan = ground.sourceOcclusionPlan.withLayerVisibility(
      visibility.layerVisible,
    );
    ground.resolve(
      ground._sampledElapsed ?? (groundElapsed * 1000).round(),
      animationElapsedMsForCell: current.rasterAnimationElapsedMsForCell,
      forceGeometry: true,
    );
    chunk.terrain
      ..clear()
      ..addAll([
        for (final mesh in terrainMeshes(
          plan.scene!,
          current.ground,
          current.edge,
          selectedCell: current.selectedCell,
          includeGround: false,
          receiveShadows: ground.receiveShadows,
          replacedGroundCells: plan.groundReplacementCells,
          borderGroundReplacements: plan.borderGroundReplacements,
          bridgeCells: plan.bridgeCells,
          cliffTexture: plan.cliff == null
              ? null
              : (
                  texture: ground.textures[plan.cliff!.tilesetId]!,
                  sourceRect: plan.cliff!.sourceRect,
                ),
        ))
          MeshComponent(
            mesh: mesh,
            position: Vector3(ground.offset.dx, 0, ground.offset.dy),
          ),
      ]);
    final replacement = <Object3D>[...ground.components, ...chunk.terrain];
    sceneComponents.replaceSubset(
      previous,
      replacement,
      groupKey: ground.mapId,
    );
    chunk.components.removeWhere(previous.contains);
    chunk.components.addAll(replacement);
    if (!visibility.allLayersHidden && visibility.hiddenLayers.isEmpty) {
      _visibilityRetainedGroundImages.clear();
    }
    syncActorOcclusions([ground]);
    visibilityGroundRebuilds++;
  }

  bool _syncVisualOrder() {
    final before = renderedConfiguration;
    if (before == null) return false;
    final change = _visualOrderChange(before, configuration);
    if (change == null) return false;
    final map = configuration.groundMap!;
    final previousMap = before.groundMap!;
    final chunk = sceneChunks[map.id];
    final cached = _smartTileProjectionCache[previousMap];
    if (chunk == null || cached == null) return false;
    final ranks =
        change == _VisualOrderChange.layers && cached.hasGeneratedModels
        ? spatialSmartTileLayerPaintRanks(map)
        : const <String, int>{};
    final projectedScene =
        change == _VisualOrderChange.layers && cached.hasGeneratedModels
        ? cached.map.spatialScene!.copyWith(
            instances: [
              for (final instance in cached.map.spatialScene!.instances)
                if (cached.paintHeightAnchors[instance.id] case final anchor?)
                  instance.copyWith(
                    position: Model3dVector3(
                      x: instance.position.x,
                      y:
                          anchor.height +
                          spatialSmartTileLayerPaintStep *
                              (ranks[cached
                                      .cellOrigins[instance.id]!
                                      .layerId]! -
                                  anchor.layerRank),
                      z: instance.position.z,
                    ),
                  )
                else
                  instance,
            ],
          )
        : cached.map.spatialScene;
    final projected = cached.map.copyWith(
      layers: map.layers,
      placedElements: map.placedElements,
      spatialScene: projectedScene,
    );
    final changedCasters = <String, SpatialAuthoredShadowCaster>{};
    if (change == _VisualOrderChange.layers && cached.hasGeneratedModels) {
      final generated = projected.spatialScene!.instances
          .where((instance) => instance.id.startsWith('smt_'))
          .toList();
      final previousGenerated = {
        for (final instance in cached.map.spatialScene!.instances.where(
          (instance) => instance.id.startsWith('smt_'),
        ))
          instance.id: instance,
      };
      if (!setEquals(
        previousGenerated.keys.toSet(),
        generated.map((instance) => instance.id).toSet(),
      )) {
        throw StateError(
          'L’ordre modifie la composition des modèles générés. Une reconstruction explicite de cette projection est nécessaire.',
        );
      }
      for (final instance in generated) {
        if (previousGenerated[instance.id]!.copyWith(
              position: instance.position,
            ) !=
            instance) {
          throw StateError(
            'L’ordre modifie une propriété non spatiale des modèles générés. Une reconstruction explicite de cette projection est nécessaire.',
          );
        }
        final previous = chunk.models[instance.id];
        if (previous != null &&
            (previous.anchor.x != instance.position.x ||
                previous.anchor.z != instance.position.z)) {
          throw StateError(
            'Layer order changed a generated model outside its paint-height dependency.',
          );
        }
        if (runtimeModelIndex.instance(map.id, instance.id) == null) {
          throw StateError(
            'Layer order introduced an unknown generated model instance.',
          );
        }
      }
      for (final instance in generated) {
        runtimeModelIndex.replaceInstance(map.id, instance);
        final previous = chunk.models[instance.id];
        if (previous == null || previous.anchor == instance.position) continue;
        final component = previous.component;
        final previewOffset = component.position.y - previous.position.y;
        final height =
            component.initialPositionY +
            (instance.position.y - component.initialAnchorY);
        component.position.y = height + previewOffset;
        final position = previous.position.clone()..y = height;
        final updated = (
          component: component,
          position: position,
          anchor: instance.position,
        );
        chunk.models[instance.id] = updated;
        modelComponents[instance.id] = updated;
        final caster = spatialAuthoredShadowCaster(
          mapId: map.id,
          instance: instance,
          definition: component.definition,
          bounds: component.visibleBounds,
          worldTransform: component.worldTransformMatrix,
        );
        if (caster != null) changedCasters[caster.id] = caster;
      }
    }
    final ground = chunk.ground;
    if (change == _VisualOrderChange.layers && ground != null) {
      final oldPlan = ground.plan;
      final sourcePlan = ground.sourcePlan.reordered(projected);
      final sourceOcclusionPlan = ground.sourceOcclusionPlan.reordered(
        projected,
      );
      final visibility = configuration.visibility ?? SpatialSceneVisibility.all;
      final plan = sourcePlan.withLayerVisibility(visibility.layerVisible);
      final occlusionPlan = sourceOcclusionPlan.withLayerVisibility(
        visibility.layerVisible,
      );
      final terrainChanged =
          !setEquals(oldPlan.bridgeCells, plan.bridgeCells) ||
          !setEquals(
            oldPlan.groundReplacementCells,
            plan.groundReplacementCells,
          ) ||
          !listEquals(
            previousMap.layers
                .whereType<BorderLayer>()
                .map((layer) => layer.id)
                .toList(),
            map.layers
                .whereType<BorderLayer>()
                .map((layer) => layer.id)
                .toList(),
          );
      final previous = <Object3D>[
        ...ground.components,
        if (terrainChanged) ...chunk.terrain,
      ];
      ground.plan = plan;
      ground.sourcePlan = sourcePlan;
      ground.occlusionPlan = occlusionPlan;
      ground.sourceOcclusionPlan = sourceOcclusionPlan;
      ground.resolve(
        ground._sampledElapsed ?? (groundElapsed * 1000).round(),
        animationElapsedMsForCell:
            configuration.rasterAnimationElapsedMsForCell,
        forceGeometry: true,
      );
      if (terrainChanged) {
        chunk.terrain
          ..clear()
          ..addAll([
            for (final mesh in terrainMeshes(
              plan.scene!,
              configuration.ground,
              configuration.edge,
              selectedCell: configuration.selectedCell,
              includeGround: false,
              receiveShadows: ground.receiveShadows,
              replacedGroundCells: plan.groundReplacementCells,
              borderGroundReplacements: plan.borderGroundReplacements,
              bridgeCells: plan.bridgeCells,
              cliffTexture: plan.cliff == null
                  ? null
                  : (
                      texture: ground.textures[plan.cliff!.tilesetId]!,
                      sourceRect: plan.cliff!.sourceRect,
                    ),
            ))
              MeshComponent(
                mesh: mesh,
                position: Vector3(ground.offset.dx, 0, ground.offset.dy),
              ),
          ]);
      }
      final next = <Object3D>[
        ...ground.components,
        if (terrainChanged) ...chunk.terrain,
      ];
      sceneComponents.replaceSubset(previous, next, groupKey: map.id);
      chunk.components.removeWhere(previous.contains);
      chunk.components.addAll(next);
      visualGroundRebuilds++;
    }
    _smartTileProjectionCache[map] = (
      catalog: cached.catalog,
      width: cached.width,
      height: cached.height,
      map: projected,
      hasGeneratedModels: cached.hasGeneratedModels,
      cellOrigins: cached.cellOrigins,
      paintHeightAnchors: cached.paintHeightAnchors,
    );
    if (_smartTileProjectionCache.length > 8)
      _smartTileProjectionCache.remove(_smartTileProjectionCache.keys.first);
    chunk.cellOrigins = cached.cellOrigins;
    final signature = chunk.signature;
    chunk.signature = (
      projected,
      projected.spatialScene ?? configuration.scene,
      signature.$3,
      signature.$4,
      signature.$5,
      signature.$6,
      signature.$7,
      signature.$8,
    );
    renderedConfiguration = configuration;
    syncVisibility();
    if (changedCasters.isNotEmpty) {
      authoredShadowCasters = List.unmodifiable([
        for (final caster in authoredShadowCasters)
          changedCasters[caster.id] ?? caster,
      ]);
      _refreshVisibilityLighting();
      syncLighting();
    }
    syncContentSelection(before, configuration);
    if (!identical(before.contentPreview, configuration.contentPreview))
      syncContentPreview();
    if (!identical(before.placementPreview, configuration.placementPreview))
      syncPlacementPreview();
    if (!listEquals(before.cellOverlays, configuration.cellOverlays))
      syncCellOverlays();
    if (change == _VisualOrderChange.layers && ground != null)
      syncActorOcclusions([ground]);
    visualOrderUpdates++;
    if (configuration.onHover != null) onSurfaceChanged();
    return true;
  }

  Future<bool> refresh() async {
    if (!sceneReady || closed) return false;
    if (hasVisualOrderChange) {
      if (refreshing) return (_pendingVisualOrder ??= Completer<bool>()).future;
      if (_syncVisualOrder()) return true;
    }
    final prepared = _destinationPreparation;
    if (prepared != null) {
      if (prepared.request.map.id == configuration.groundMap?.id &&
          prepared.isCurrent) {
        prepared.commit();
      } else {
        prepared.discard();
      }
      _destinationPreparation = null;
    }
    final ticket = ++generation;
    _groundTextureErrors.clear();
    _reportedGroundTextureErrors.clear();
    _wantedGroundImages = {
      for (final ground in grounds) ...ground.renderedImageIds,
    };
    cache.removeWhere((key, _) => !modelReservations.containsKey(key));
    groundTextureCache.removeWhere((key, _) {
      if (groundReservations.containsKey(key)) return false;
      _groundTextureTokens.remove(key);
      return true;
    });
    refreshing = true;
    placementRenderer.clear();
    sceneComponents.cancelPending();
    final snapshot = configuration;
    final initialModelKeys = cache.keys.toSet();
    final initialGroundKeys = groundTextureCache.keys.toSet();
    final neighbors = List<SpatialSceneNeighbor>.of(snapshot.neighbors);
    final definitions = {
      for (final neighbor in neighbors)
        for (final model
            in neighbor.project?.models3d ?? const <ProjectModel3dEntry>[])
          model.id: model,
      for (final model in snapshot.models) model.id: model,
    };
    final activeModelIds = <String>{};
    final groups = <Object, Iterable<Object3D>>{};
    final nextChunks = <String, _SceneChunk>{};
    final nextGrounds = <_SceneGround>[];
    final nextAnimationModels = <(String, String), _SceneModelComponent>{};
    final nextRuntimeScenes = <String, Iterable<SpatialModelInstance>>{};
    final nextShadowCasters = <SpatialAuthoredShadowCaster>[];
    final nextPointLights =
        <({Model3dPointLight definition, _SceneModelComponent component})>[];
    var receiverMaximumY = snapshot.scene.maximumWorldHeight;
    var receiverMinimumY = spatialShadowReceiverMinimumHeight(snapshot.scene);
    final nextModelComponents =
        <
          String,
          ({
            _SceneModelComponent component,
            Vector3 position,
            Model3dVector3 anchor,
          })
        >{};
    final placements = [
      (
        scene: snapshot.scene,
        map: snapshot.groundMap,
        offset: snapshot.sceneOffset,
        loader: snapshot.loadGroundImage,
        modelLoader: snapshot.loadModel,
        project: snapshot.groundProject,
        definitions: {for (final model in snapshot.models) model.id: model},
        active: true,
      ),
      for (final neighbor in neighbors)
        if (neighbor.map.spatialScene case final scene?)
          (
            scene: scene,
            map: neighbor.map,
            offset: snapshot.sceneOffset + neighbor.offset,
            loader: neighbor.loadGroundImage,
            modelLoader: neighbor.loadModel ?? snapshot.loadModel,
            project: neighbor.project ?? snapshot.groundProject,
            definitions: {
              for (final model in neighbor.project?.models3d ?? snapshot.models)
                model.id: model,
            },
            active: false,
          ),
    ];
    final receiveShadows =
        snapshot.scene.dayNightCycle != null ||
        placements.any((placement) {
          final map = placement.map == null
              ? null
              : projectedSmartTileMap(placement.map!, placement.project);
          return (map?.spatialScene ?? placement.scene).instances.any((
            instance,
          ) {
            final definition = placement.definitions[instance.modelId];
            return definition != null &&
                (instance.effectiveCastsShadows(definition) ||
                    definition.light != null);
          });
        });
    try {
      for (final placement in placements) {
        final project = placement.project;
        final placementDefinitions = placement.definitions;
        final map = placement.map == null
            ? null
            : projectedSmartTileMap(placement.map!, project);
        final cellOrigins = placement.map == null
            ? const <String, ({String layerId, GridPos cell})>{}
            : _smartTileProjectionCache[placement.map]?.cellOrigins ??
                  const <String, ({String layerId, GridPos cell})>{};
        final scene = map?.spatialScene ?? placement.scene;
        final instancesById = {
          for (final instance in scene.instances) instance.id: instance,
        };
        receiverMaximumY = math.max(receiverMaximumY, scene.maximumWorldHeight);
        receiverMinimumY = math.min(
          receiverMinimumY,
          spatialShadowReceiverMinimumHeight(scene),
        );
        for (final instance in scene.instances) {
          final sourceAssetId =
              placementDefinitions[instance.modelId]?.sourceAssetId;
          if (sourceAssetId != null) activeModelIds.add(sourceAssetId);
        }
        final loader = placement.loader;
        final mapId = map?.id ?? '__scene__';
        nextRuntimeScenes[mapId] = scene.instances;
        final signature = (
          map,
          scene,
          project,
          placement.offset,
          snapshot.ground,
          snapshot.edge,
          placement.active ? snapshot.selectedCell : null,
          receiveShadows,
        );
        final previousChunk = sceneChunks[mapId];
        if (previousChunk?.signature == signature) {
          final chunk = previousChunk!;
          nextChunks[mapId] = chunk;
          groups[mapId] = chunk.components;
          if (chunk.ground case final ground?) nextGrounds.add(ground);
          for (final entry in chunk.models.entries) {
            nextAnimationModels[(mapId, entry.key)] = entry.value.component;
            final instance = instancesById[entry.key]!;
            final definition = placementDefinitions[instance.modelId]!;
            if (definition.light case final light?) {
              nextPointLights.add((
                definition: light,
                component: entry.value.component,
              ));
            }
            final caster = spatialAuthoredShadowCaster(
              mapId: mapId,
              instance: instance,
              definition: definition,
              bounds: entry.value.component.visibleBounds,
              worldTransform: entry.value.component.worldTransformMatrix,
            );
            if (caster != null) nextShadowCasters.add(caster);
          }
          if (placement.active) nextModelComponents.addAll(chunk.models);
          continue;
        }
        final components = <Object3D>[];
        final placedModels = <String, _ScenePlacedModel>{};
        final terrainComponents = <Object3D>[];
        _SceneGround? sceneGround;
        SpatialGroundPlan? groundPlan;
        final textures = <String, Texture>{};
        if (map != null &&
            (map.layers.isNotEmpty || map.spatialScene?.cliffFrame != null)) {
          if (project == null || loader == null) {
            throw StateError('Les ressources du sol 3D sont indisponibles.');
          }
          final plan = SpatialGroundPlan(map, project);
          groundPlan = plan;
          final elapsed = (groundElapsed * 1000).round();
          final ground = _SceneGround(
            plan,
            _groundTextures,
            placement.offset,
            mapId: mapId,
            project: project,
            loader: loader,
            animationElapsedMsForCell: snapshot.rasterAnimationElapsedMsForCell,
            occlusionStateForCell: snapshot.actorOcclusionStateForCell,
            presentationElapsedSeconds: snapshot.presentationElapsedSeconds,
            ground: snapshot.ground,
            edge: snapshot.edge,
            selectedCell: placement.active ? snapshot.selectedCell : null,
            receiveShadows: receiveShadows,
            occlusionPlan: SpatialActorOcclusionPlan(map, project),
          );
          ground.sampleTextureWindow(elapsed);
          final requiredImages = ground.currentImageIds;
          final nextImages = ground.nextImageIds;
          _wantedGroundImages.addAll({...requiredImages, ...nextImages});
          for (final id in requiredImages) {
            textures[id] = await _loadGroundTexture(
              id,
              loader,
              project,
              ticket: ticket,
            );
            if (ticket != generation || closed) return false;
          }
          for (final id in nextImages.difference(requiredImages)) {
            final pending = _loadGroundTexture(
              id,
              loader,
              project,
              ticket: ticket,
              prefetch: true,
            );
            unawaited(
              pending.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
            );
          }
          sceneGround = ground;
          ground.resolve(
            (groundElapsed * 1000).round(),
            animationElapsedMsForCell: snapshot.rasterAnimationElapsedMsForCell,
          );
          nextGrounds.add(ground);
          components.addAll(ground.components);
        }
        for (final mesh in terrainMeshes(
          scene,
          snapshot.ground,
          snapshot.edge,
          selectedCell: placement.active ? snapshot.selectedCell : null,
          includeGround: groundPlan == null,
          receiveShadows: receiveShadows,
          replacedGroundCells: groundPlan?.groundReplacementCells ?? const {},
          borderGroundReplacements:
              groundPlan?.borderGroundReplacements ?? const {},
          bridgeCells: groundPlan?.bridgeCells ?? const {},
          cliffTexture: groundPlan?.cliff == null
              ? null
              : (
                  texture: textures[groundPlan!.cliff!.tilesetId]!,
                  sourceRect: groundPlan.cliff!.sourceRect,
                ),
        )) {
          final component = MeshComponent(
            mesh: mesh,
            position: Vector3(placement.offset.dx, 0, placement.offset.dy),
          );
          terrainComponents.add(component);
          components.add(component);
        }
        final modelSources = <String, Future<Uint8List> Function()>{};
        for (final instance in scene.instances) {
          final definition = placementDefinitions[instance.modelId];
          if (definition == null) {
            throw StateError('Modèle absent : ${instance.modelId}');
          }
          modelSources.putIfAbsent(
            definition.sourceAssetId,
            () =>
                () => placement.modelLoader(definition.id),
          );
        }
        final modelsReady = await ModelByteLoader.preloadCached(
          cache,
          modelSources,
          isCurrent: () => ticket == generation && !closed,
          budget: resourceBudget,
          onResident: retainModelReservation,
        );
        if (!modelsReady || ticket != generation || closed) return false;
        for (final instance in scene.instances) {
          final definition = placementDefinitions[instance.modelId]!;
          final sourceModel = await ModelByteLoader.loadCached(
            cache,
            definition.sourceAssetId,
            () => placement.modelLoader(definition.id),
            budget: resourceBudget,
            isCurrent: () => ticket == generation && !closed,
            onResident: retainModelReservation,
          );
          if (ticket != generation || closed) return false;
          loadedModelSources[definition.sourceAssetId] = sourceModel;
          final sourceClip = spatialModelSourceClip(instance, definition);
          final clipped = sourceClip == null
              ? null
              : clippedModelCache.resolve(sourceModel, sourceClip);
          if (sourceClip != null && clipped == null) continue;
          final model = clipped?.model ?? sourceModel;
          final visibleBounds = clipped?.bounds ?? definition.inspection.bounds;
          final scale = definition.scale * instance.scale;
          final rotation = Quaternion.axisAngle(
            Vector3(0, 1, 0),
            instance.rotationDegrees * math.pi / 180,
          );
          final pivot =
              Vector3(
                definition.pivot.x,
                definition.pivot.y,
                definition.pivot.z,
              ) *
              scale;
          rotation.asRotationMatrix().transform(pivot);
          final animationKey = (placement.map?.id ?? '__scene__', instance.id);
          final previous = animationModels[animationKey];
          final component = _SceneModelComponent(
            instanceId: instance.id,
            initialAnchorY: instance.position.y,
            shadowId: spatialShadowInstanceId(mapId, instance.id),
            model: model,
            visibleBounds: visibleBounds,
            definition: definition,
            playback: identical(previous?.model, model)
                ? ModelPlaybackState.from(previous!.playback)
                : null,
            runtimePoseBefore: identical(previous?.model, model)
                ? previous?.runtimePoseBefore
                : null,
            position:
                Vector3(
                  instance.position.x + placement.offset.dx,
                  instance.position.y,
                  instance.position.z + placement.offset.dy,
                ) -
                pivot,
            rotation: rotation,
            scale: Vector3.all(scale),
          );
          final caster = spatialAuthoredShadowCaster(
            mapId: mapId,
            instance: instance,
            definition: definition,
            bounds: visibleBounds,
            worldTransform: component.worldTransformMatrix,
          );
          if (caster != null) nextShadowCasters.add(caster);
          if (definition.light case final light?) {
            nextPointLights.add((definition: light, component: component));
          }
          component.bindAnimation(
            instance.animationIndex,
            loop: instance.animationLoop,
            speed: instance.animationSpeed,
          );
          nextAnimationModels[animationKey] = component;
          components.add(component);
          placedModels[instance.id] = (
            component: component,
            position: component.position.clone(),
            anchor: instance.position,
          );
          if (placement.active) {
            nextModelComponents[instance.id] = placedModels[instance.id]!;
          }
        }
        nextChunks[mapId] = _SceneChunk(
          signature: signature,
          components: components,
          ground: sceneGround,
          models: placedModels,
          terrain: terrainComponents,
          cellOrigins: cellOrigins,
        );
        groups[mapId] = components;
      }
      if (ticket != generation || closed) return false;
      final nextCellOverlays = buildCellOverlays(snapshot);
      groups[(#overlays,)] = nextCellOverlays;
      final nextAuthoredLighting = spatialAuthoredShadowLighting(
        nextShadowCasters,
        receiverMinY: receiverMinimumY,
        receiverMaxY: receiverMaximumY,
      );
      return await sceneComponents.replaceGroups(
        groups,
        isCurrent: () => ticket == generation && !closed,
        onCommit: () {
          for (final entry in actorSelections.entries) {
            actors[entry.key]?.mesh.removeAll(entry.value);
          }
          actorSelections.clear();
          grounds = nextGrounds;
          sceneChunks = nextChunks;
          _visibilityRetainedGroundImages.clear();
          _pruneGroundTextures();
          final modelIds = {
            ...activeModelIds,
            if (snapshot.placementPreview case final preview?)
              definitions[preview.modelId]?.sourceAssetId,
          };
          cache.removeWhere((id, _) {
            if (modelIds.contains(id)) return false;
            modelReservations.remove(id)?.release();
            final source = loadedModelSources.remove(id);
            if (source != null) clippedModelCache.releaseSource(source);
            return true;
          });
          for (final lease in retiredReservations) {
            lease.release();
          }
          retiredReservations.clear();
          for (final entry in nextAnimationModels.entries) {
            final previous = animationModels[entry.key];
            if (previous != null) {
              entry.value.playback.synchronizeClock(previous.playback);
            }
          }
          for (final entry in modelSelections.entries) {
            modelComponents[entry.key]?.component.removeAll(entry.value);
          }
          modelSelections.clear();
          modelComponents = nextModelComponents;
          animationModels = nextAnimationModels;
          runtimeModelIndex = SpatialRuntimeModelIndex(nextRuntimeScenes);
          renderedConfiguration = snapshot;
          syncContentSelection(null, snapshot);
          authoredLighting = nextAuthoredLighting;
          authoredShadowCasters = List.unmodifiable(nextShadowCasters);
          _casterShadowIds = nextShadowCasters
              .map((caster) => caster.id)
              .toSet();
          _visibleShadowCasters = null;
          _hiddenShadowIds = {};
          _appliedVisibility = SpatialSceneVisibility.all;
          _actorsVisibilityFiltered = false;
          authoredReceiverMinY = receiverMinimumY;
          authoredReceiverMaxY = receiverMaximumY;
          (context as SpatialRenderContext).shadowCasters = nextAnimationModels
              .values
              .where(
                (component) =>
                    nextAuthoredLighting.shadow?.casterInstanceIds.contains(
                      component.shadowId,
                    ) ==
                    true,
              )
              .toList();
          pointLightBindings = nextPointLights;
          syncLighting();
          actorVisual = null;
          cellOverlayComponents = nextCellOverlays;
          refreshing = false;
          if (identical(snapshot.scene, configuration.scene) &&
              identical(snapshot.groundMap, configuration.groundMap) &&
              snapshot.visibility != configuration.visibility) {
            renderedConfiguration = configuration;
            syncContentSelection(snapshot, configuration);
          }
          syncVisibility();
          syncAnimations();
          syncContentPreview();
          syncPlacementPreview();
          syncCamera();
          syncActors(0);
          syncActorContactShadows();
          snapshot.onVisibleMapsChanged?.call(
            Set.unmodifiable({
              for (final placement in placements)
                if (placement.map case final map?) map.id,
            }),
          );
          if (!listEquals(snapshot.cellOverlays, configuration.cellOverlays)) {
            syncCellOverlays();
          }
          if (configuration.onHover != null) onSurfaceChanged();
        },
      );
    } on Object {
      if (ticket != generation || closed) return false;
      cache.removeWhere((key, _) {
        if (initialModelKeys.contains(key)) return false;
        modelReservations.remove(key)?.release();
        return true;
      });
      groundTextureCache.removeWhere((key, _) {
        if (initialGroundKeys.contains(key)) return false;
        groundReservations.remove(key)?.release();
        _groundTextures.remove(key);
        _groundTextureTokens.remove(key);
        return true;
      });
      rethrow;
    } finally {
      if (ticket == generation) {
        refreshing = false;
        final pending = _pendingVisualOrder;
        if (pending != null) {
          _pendingVisualOrder = null;
          if (closed) {
            pending.complete(false);
          } else if (identical(renderedConfiguration, configuration)) {
            pending.complete(true);
          } else {
            unawaited(
              refresh().then(pending.complete, onError: pending.completeError),
            );
          }
        }
      }
    }
  }

  Future<void> syncPlacementPreview() async {
    if (!sceneReady || closed || refreshing) return;
    await placementRenderer.sync(
      preview: placementPreviewHidden ? null : configuration.placementPreview,
      models: configuration.models,
      color: configuration.selectionColor ?? configuration.edge,
      offset: configuration.sceneOffset,
    );
  }

  final Map<String, List<MeshComponent>> modelSelections = {};

  void syncContentSelection(SpatialSceneView? before, SpatialSceneView after) {
    if (before?.selectedContent?.kind == after.selectedContent?.kind &&
        before?.selectedContent?.id == after.selectedContent?.id &&
        before?.selectionColor == after.selectionColor) {
      return;
    }
    final oldId = before?.selectedContent?.kind == SpatialSceneContentKind.model
        ? before?.selectedContent?.id
        : null;
    if (oldId != null) {
      final previous = modelSelections.remove(oldId);
      if (previous != null) {
        modelComponents[oldId]?.component.removeAll(previous);
      }
    }
    if (before?.selectedContent?.kind == SpatialSceneContentKind.actor) {
      final actorId = before!.selectedContent!.id;
      final previous = actorSelections.remove(actorId);
      if (previous != null) actors[actorId]?.mesh.removeAll(previous);
    }
    if (after.selectedContent?.kind != SpatialSceneContentKind.model) return;
    final id = after.selectedContent!.id;
    final component = modelComponents[id]?.component;
    if (component == null) return;
    final bounds = component.visibleBounds;
    final selection = spatialSelectionFrame(
      Vector3(bounds.min.x, bounds.min.y, bounds.min.z),
      Vector3(bounds.max.x, bounds.max.y, bounds.max.z),
      .04 / component.scale.x,
      after.selectionColor ?? after.edge,
    );
    modelSelections[id] = selection;
    component.addAll(selection);
  }

  void syncContentPreview() {
    if (refreshing) return;
    final preview = visibleConfiguration.contentPreview;
    for (final entry in modelComponents.entries) {
      final model = entry.value;
      final position =
          preview?.kind == SpatialSceneContentKind.model &&
              preview?.id == entry.key
          ? preview!.position
          : model.anchor;
      model.component.position.setValues(
        model.position.x + position.x - model.anchor.x,
        model.position.y + position.y - model.anchor.y,
        model.position.z + position.z - model.anchor.z,
      );
    }
  }

  List<MeshComponent> buildCellOverlays(SpatialSceneView configuration) => [
    for (final mesh in spatialCellOverlayMeshes(
      configuration.scene,
      configuration.cellOverlays.where((overlay) {
        final kind = switch (overlay.kind) {
          SpatialCellOverlayKind.spawn => SpatialSceneContentKind.marker,
          SpatialCellOverlayKind.warp => SpatialSceneContentKind.warp,
          _ => null,
        };
        return kind == null ||
            (configuration.visibility ?? SpatialSceneVisibility.all)
                .contentVisible(kind, overlay.id);
      }).toList(),
    ))
      MeshComponent(
        mesh: mesh,
        position: Vector3(
          configuration.sceneOffset.dx,
          0,
          configuration.sceneOffset.dy,
        ),
      ),
  ];

  void syncCellOverlays() {
    if (!sceneReady || closed || refreshing) return;
    final next = buildCellOverlays(visibleConfiguration);
    sceneComponents.replaceSubset(cellOverlayComponents, next);
    cellOverlayComponents = next;
  }

  final animationRestartVersions = <String, int>{};

  void syncAnimations() {
    if (refreshing) return;
    final preview = configuration.animationPreview;
    for (final entry in modelComponents.entries) {
      final version = preview?.restartVersion(entry.key) ?? 0;
      if (version != (animationRestartVersions[entry.key] ?? 0)) {
        entry.value.component.playback.restart();
      }
      entry.value.component.playback.paused =
          preview?.isPaused(entry.key) ?? false;
      animationRestartVersions[entry.key] = version;
    }
  }

  void syncCamera() {
    if (refreshing && renderedConfiguration == null) return;
    final configuration = visibleConfiguration;
    final scene = configuration.scene;
    final control = configuration.controller;
    final visual = actorVisual;
    final cameraPose = configuration.cameraPose?.call();
    final center = cameraPose != null
        ? Vector3(cameraPose.x, cameraPose.y, cameraPose.z)
        : visual == null
        ? Vector3(
            scene.width / 2,
            scene.heightAt(scene.width ~/ 2, scene.depth ~/ 2),
            scene.depth / 2,
          )
        : Vector3(visual.x, visual.y, visual.z);
    final maximumHeight =
        scene.heightLevels.reduce(math.max) * scene.levelHeight;
    (camera as AdaptiveCamera3D).sceneRadius = math.max(
      math.max(scene.width, scene.depth).toDouble(),
      32 * scene.levelHeight,
    );
    for (final neighbor in configuration.neighbors) {
      final neighborScene = neighbor.map.spatialScene;
      if (neighborScene == null) continue;
      final radius = math.max(
        neighbor.offset.dx.abs() + neighborScene.width,
        neighbor.offset.dy.abs() + neighborScene.depth,
      );
      (camera as AdaptiveCamera3D).sceneRadius = math.max(
        (camera as AdaptiveCamera3D).sceneRadius,
        radius,
      );
    }
    final cameraProfile = control.effectiveCamera(scene.camera);
    var pitch = control.pitch;
    var yaw = control.yaw;
    camera.projection = CameraProjection.perspective;
    camera.fovY = 40;
    final aspect = size.y > 0 ? size.x / size.y : 1.0;
    var distance =
        math.max(math.max(scene.width, scene.depth), maximumHeight) /
        (2 * math.tan(math.pi / 9)) *
        1.35 *
        control.zoom;
    if (control.view == SpatialEditorView.top) {
      pitch = math.pi / 2 - 0.0001;
      yaw = 0;
    } else if (control.view == SpatialEditorView.game) {
      pitch = cameraProfile.pitchDegrees * math.pi / 180;
      yaw = cameraProfile.yawDegrees * math.pi / 180;
      final zoom = control.zoom * (cameraPose?.zoom ?? 1);
      distance =
          cameraProfile.distance *
          (cameraProfile.projection == SpatialCameraProjection.perspective
              ? zoom
              : 1);
      applySpatialCameraProfile(
        camera,
        profile: cameraProfile,
        zoom: zoom,
        viewportAspectRatio: aspect,
        magnification: configuration.cameraMagnification?.call() ?? 1,
      );
    }
    center.x += control.pan.dx + configuration.sceneOffset.dx;
    center.z += control.pan.dy + configuration.sceneOffset.dy;
    billboardPitch = pitch;
    billboardYaw = yaw;
    (camera as AdaptiveCamera3D).frame(
      center,
      pitch: pitch,
      yaw: yaw,
      distance:
          control.lockVerticalFraming && control.view == SpatialEditorView.game
          ? distance * math.min(1.0, aspect)
          : distance,
      viewportAspectRatio: aspect,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final prepared = _destinationPreparation;
    if (prepared != null && !prepared.isCurrent) {
      prepared.discard();
      _destinationPreparation = null;
    }
    if (!sceneReady || closed || (refreshing && renderedConfiguration == null))
      return;
    if (!refreshing && grounds.isNotEmpty) {
      if (dt.isFinite &&
          dt > 0 &&
          grounds.any((ground) => ground.plan.animated)) {
        groundElapsed += dt;
      }
      _requestGroundAnimationTextures((groundElapsed * 1000).round());
      for (final ground in grounds.where((ground) => ground.plan.animated)) {
        final previous = ground.components;
        if (ground.resolve(
          (groundElapsed * 1000).round(),
          animationElapsedMsForCell:
              visibleConfiguration.rasterAnimationElapsedMsForCell,
        )) {
          final retained = ground.components.toSet();
          final previousSet = previous.toSet();
          final removed = previous
              .where((component) => !retained.contains(component))
              .toList();
          final added = ground.components
              .where((component) => !previousSet.contains(component))
              .toList();
          sceneComponents.replaceSubset(removed, added, groupKey: ground.mapId);
          final chunk = sceneChunks[ground.mapId];
          chunk?.components.removeWhere(removed.contains);
          chunk?.components.addAll(added);
        }
      }
      _pruneGroundTextures(sample: false);
    }
    syncActors(dt);
    syncActorOcclusions();
    if (!refreshing) _pruneGroundTextures(sample: false);
    syncRuntimeModels();
    final configuration = visibleConfiguration;
    configuration.controller.advanceEnvironment(
      configuration.presentationPaused?.call() == true ? 0 : dt,
      configuration.controller.effectiveCycle(
        configuration.scene.dayNightCycle,
      ),
      configuration.presentationElapsedSeconds?.call(),
    );
    if (configuration.presentationPaused?.call() != true &&
        dt.isFinite &&
        dt > 0)
      atmosphereElapsed += dt;
    final control = configuration.controller;
    final elapsed =
        configuration.presentationElapsedSeconds?.call() ?? atmosphereElapsed;
    final minute =
        control.dayNightMinuteOfDay ??
        control.previewMinuteOfDay ??
        control.visualProfile.number(SpatialVisualParameter.minuteOfDay);
    final night = _isIndoor || minute == null
        ? 0.0
        : 1 - spatialDayNightFrame(minute).daylight;
    final renderContext = context as SpatialRenderContext;
    renderContext
      ..presentationProfile = control.presentationProfile
      ..depthFogEnabled = control.depthFogEnabled
      ..depthFogColor = spatialDepthFogColor(night)
      ..atmosphereProfile = control.atmosphereProfile
      ..waterAnimated = control.waterAnimated
      ..windowsLit = control.windowsLit
      ..atmosphereElapsedSeconds = elapsed
      ..atmosphereNight = night;
    atmosphereEffects.sync(
      profile: control.atmosphereProfile,
      enabled: control.fireflies,
      elapsedSeconds: elapsed,
      night: night,
      cameraPitch: billboardPitch,
      cameraYaw: billboardYaw,
    );
    syncLighting();
    final hero = actorVisual;
    final weatherAnchor = hero == null
        ? camera.target.clone()
        : Vector3(
            hero.x + configuration.sceneOffset.dx,
            hero.y,
            hero.z + configuration.sceneOffset.dy,
          );
    weatherEffects.sync(
      settings: control.weatherSettings,
      context: renderContext,
      dt: dt,
      seconds: control.weatherTimelineSeconds ?? elapsed,
      night: night,
      indoors: configuration.groundMap?.mapMetadata.isIndoor ?? false,
      anchor: weatherAnchor,
      bounds: Rect.fromLTWH(
        configuration.sceneOffset.dx,
        configuration.sceneOffset.dy,
        configuration.scene.width.toDouble(),
        configuration.scene.depth.toDouble(),
      ),
      cameraDistance: (camera.position - camera.target).length,
    );
    presentationEffects.sync(
      profile: control.presentationProfile,
      enabled: control.halosEnabled,
      windowsLit: control.windowsLit,
      night: night,
      cameraPitch: billboardPitch,
      cameraYaw: billboardYaw,
      windowStrength: control.atmosphereProfile.windowStrength,
      locate: _haloPosition,
      colorForInstance: (id) => _haloEmission(id)?.$1,
      strengthForInstance: (id) => _haloEmission(id)?.$2 ?? 1,
    );
    control._haloAllocations = presentationEffects.allocations;
    control._haloCount = presentationEffects.visibleCount;
    syncActorContactShadows();
  }

  Model3dVector3? _haloPosition(SpatialHaloSource source) {
    final component = modelComponents[source.instanceId]?.component;
    if (component == null || !component.presentationVisible) return null;
    final local = source.position;
    final point = component.worldTransformMatrix.transform3(
      Vector3(local.x, local.y, local.z),
    );
    return Model3dVector3(x: point.x, y: point.y, z: point.z);
  }

  void syncRuntimeModels() {
    final provider = visibleConfiguration.modelRuntimeState;
    for (final entry in animationModels.entries) {
      final component = entry.value;
      component.presentationVisible =
          _modelVisible(entry.key.$1, entry.key.$2) &&
          (visibleConfiguration.modelPresence?.call(
                entry.key.$1,
                entry.key.$2,
              ) ??
              true);
      final state = provider?.call(entry.key.$1, entry.key.$2);
      final instance = runtimeModelIndex.instance(entry.key.$1, entry.key.$2);
      if (instance == null) continue;
      component.bindRuntimeState(
        state,
        authoredAnimationIndex: instance.animationIndex,
        authoredLoop: instance.animationLoop,
        authoredSpeed: instance.animationSpeed,
        paused:
            (visibleConfiguration.presentationPaused?.call() ?? false) ||
            (visibleConfiguration.animationPreview?.isPaused(instance.id) ??
                false),
      );
    }
  }

  void syncActors(double dt) {
    final configuration = visibleConfiguration;
    final frames =
        configuration.actorFrames?.call(dt) ??
        const <String, SpatialActorVisual>{};
    actorFrames = frames;
    actorVisual = frames['hero'];
    for (final id
        in actors.keys.where((id) => !frames.containsKey(id)).toList()) {
      actors.remove(id)!.mesh.removeFromParent();
      actorSelections.remove(id);
    }
    for (final entry in frames.entries) {
      final frame = entry.value;
      var actor = actors[entry.key];
      if (actor == null) {
        final actorMaterial = SpatialPixelMaterial(
          frame.texture.texture,
          lightingRole: SpatialPixelLightingRole.actor,
        );
        const width = 1.92;
        final mesh = Mesh()
          ..addSurface(
            Surface(
              vertices: [
                Vertex(
                  position: Vector3(-width / 2, 0, 0),
                  texCoord: Vector2(0, 1),
                ),
                Vertex(
                  position: Vector3(width / 2, 0, 0),
                  texCoord: Vector2(1, 1),
                ),
                Vertex(
                  position: Vector3(width / 2, 1.92, 0),
                  texCoord: Vector2(1, 0),
                ),
                Vertex(
                  position: Vector3(-width / 2, 1.92, 0),
                  texCoord: Vector2(0, 0),
                ),
              ],
              indices: [0, 1, 2, 2, 3, 0],
              material: actorMaterial,
            ),
          );
        actor = (
          mesh: _SceneActorComponent(mesh: mesh),
          material: actorMaterial,
        );
        actors[entry.key] = actor;
        world.add(actor.mesh);
      }
      final preview = configuration.contentPreview;
      final actorVisible =
          (configuration.visibility ?? SpatialSceneVisibility.all)
              .contentVisible(SpatialSceneContentKind.actor, entry.key);
      (actor.mesh as _SceneActorComponent).presentationVisible = actorVisible;
      final position =
          preview?.kind == SpatialSceneContentKind.actor &&
              preview?.id == entry.key
          ? preview!.position
          : null;
      actor.mesh.position.setValues(
        (position?.x ?? frame.x) + configuration.sceneOffset.dx,
        (position?.y ?? frame.y) + .02,
        (position?.z ?? frame.z) + configuration.sceneOffset.dy,
      );
      (actor.material.shadowSamplePosition ??= Vector3.zero()).setValues(
        (position?.x ?? frame.x) + configuration.sceneOffset.dx,
        position?.y ?? frame.groundY ?? frame.y,
        (position?.z ?? frame.z) + configuration.sceneOffset.dy,
      );
      final transform = spatialActorTransform(
        SpatialCameraProfile(
          pitchDegrees: billboardPitch * 180 / math.pi,
          yawDegrees: billboardYaw * 180 / math.pi,
        ),
      );
      actor.mesh.rotation.setFrom(transform.rotation);
      actor.mesh.scale.setFrom(transform.scale);
      if (configuration.controller.view == SpatialEditorView.top) {
        actor.mesh.rotation.setFrom(
          Quaternion.axisAngle(Vector3(1, 0, 0), -math.pi / 2),
        );
        actor.mesh.scale.setValues(1, 1, 1);
      }
      if (frame.billboardVerticalOffset != 0) {
        actor.mesh.position.add(
          spatialActorBillboardOffset(
            verticalOffset: frame.billboardVerticalOffset,
            rotation: actor.mesh.rotation,
            scale: actor.mesh.scale,
          ),
        );
      }
      actor.mesh.scale.x *= frame.resolvedWidth / 1.92;
      actor.mesh.scale.y *= frame.height / 1.92;
      final selected =
          actorVisible &&
          configuration.selectedContent?.kind ==
              SpatialSceneContentKind.actor &&
          configuration.selectedContent?.id == entry.key;
      if (selected && !actorSelections.containsKey(entry.key)) {
        final selection = spatialSelectionFrame(
          Vector3(-.96, 0, 0),
          Vector3(.96, 1.92, 0),
          .04,
          configuration.selectionColor ?? configuration.edge,
        );
        actorSelections[entry.key] = selection;
        actor.mesh.addAll(selection);
      } else if (!selected && actorSelections.containsKey(entry.key)) {
        actor.mesh.removeAll(actorSelections.remove(entry.key)!);
      }
      final texture = frame.texture.texture;
      actor.material
        ..albedoTexture = texture
        ..uvRect.setValues(
          frame.frame.left / texture.width,
          frame.frame.top / texture.height,
          frame.frame.width / texture.width,
          frame.frame.height / texture.height,
        );
    }
    syncCamera();
  }

  void syncActorOcclusions([Iterable<_SceneGround>? affected]) {
    final configuration = visibleConfiguration;
    final elapsed =
        ((configuration.presentationElapsedSeconds?.call() ?? groundElapsed) *
                1000)
            .floor();
    final cameraProfile = SpatialCameraProfile(
      pitchDegrees: billboardPitch * 180 / math.pi,
      yawDegrees: billboardYaw * 180 / math.pi,
    );
    for (final ground in affected ?? grounds) {
      final callback = configuration.actorOcclusionStateForCell;
      final visuals = ground.occlusionPlan.resolve(
        elapsed,
        stateForCell: callback == null
            ? null
            : (layer, x, y, time) => callback(ground.mapId, layer, x, y, time),
      );
      if (visuals.any(
        (item) => !ground.textures.containsKey(item.visual.tilesetId),
      ))
        continue;
      ground.renderedOcclusionImageIds = {
        for (final item in visuals) item.visual.tilesetId,
      };
      final changes = ground.occlusions.sync(
        visuals,
        ground.textures,
        camera: cameraProfile,
        offset: ground.offset,
        topView: configuration.controller.view == SpatialEditorView.top,
      );
      if (changes.added.isEmpty && changes.removed.isEmpty) continue;
      sceneComponents.replaceSubset(
        changes.removed,
        changes.added,
        groupKey: ground.mapId,
      );
      final chunk = sceneChunks[ground.mapId];
      chunk?.components.removeWhere(changes.removed.contains);
      chunk?.components.addAll(changes.added);
    }
  }

  void syncActorContactShadows() {
    final configuration = visibleConfiguration;
    final preview = configuration.contentPreview;
    actorContactShadows.sync(
      _actorsVisibilityFiltered
          ? {
              for (final entry in actorFrames.entries)
                if ((configuration.visibility ?? SpatialSceneVisibility.all)
                    .contentVisible(SpatialSceneContentKind.actor, entry.key))
                  entry.key: entry.value,
            }
          : actorFrames,
      sceneOffset: configuration.sceneOffset,
      lighting: (context as SpatialRenderContext).lighting,
      previewActorId: preview?.kind == SpatialSceneContentKind.actor
          ? preview?.id
          : null,
      previewPosition: preview?.position,
      cameraPitch: billboardPitch,
      cameraYaw: billboardYaw,
      topView: configuration.controller.view == SpatialEditorView.top,
    );
  }

  String? pickActor(Offset offset) {
    if (refreshing) return null;
    final configuration = visibleConfiguration;
    String? result;
    var nearest = double.infinity;
    for (final entry in actors.entries) {
      if (!(configuration.visibility ?? SpatialSceneVisibility.all)
          .contentVisible(SpatialSceneContentKind.actor, entry.key))
        continue;
      if (configuration.canSelectContent?.call(
            SpatialSceneContentKind.actor,
            entry.key,
          ) ==
          false)
        continue;
      final actor = entry.value.mesh;
      final matrix = Matrix4.compose(
        actor.position,
        actor.rotation,
        actor.scale,
      );
      final projected = <Offset>[];
      var depth = 0.0;
      for (final corner in [
        Vector3(-.96, 0, 0),
        Vector3(.96, 0, 0),
        Vector3(.96, 1.92, 0),
        Vector3(-.96, 1.92, 0),
      ]) {
        final world = matrix.transform3(corner);
        final clip = camera.viewProjectionMatrix.transform(
          Vector4(world.x, world.y, world.z, 1),
        );
        if (clip.w <= 0) {
          projected.clear();
          break;
        }
        projected.add(
          Offset(
            (clip.x / clip.w + 1) * size.x / 2,
            (1 - clip.y / clip.w) * size.y / 2,
          ),
        );
        depth += clip.z / clip.w;
      }
      if (projected.isEmpty) continue;
      final bounds = Rect.fromLTRB(
        projected.map((p) => p.dx).reduce(math.min),
        projected.map((p) => p.dy).reduce(math.min),
        projected.map((p) => p.dx).reduce(math.max),
        projected.map((p) => p.dy).reduce(math.max),
      );
      if (bounds.contains(offset) && depth < nearest) {
        result = entry.key;
        nearest = depth;
      }
    }
    return result;
  }

  SpatialSceneContentHit? pickContent(Offset offset) {
    if (refreshing) return null;
    final configuration = visibleConfiguration;
    final cell = pickCell(offset);
    for (final overlay in configuration.cellOverlays.reversed) {
      final kind = overlay.kind == SpatialCellOverlayKind.spawn
          ? SpatialSceneContentKind.marker
          : SpatialSceneContentKind.warp;
      if (!(configuration.visibility ?? SpatialSceneVisibility.all)
          .contentVisible(kind, overlay.id))
        continue;
      if (configuration.canSelectContent?.call(kind, overlay.id) == false)
        continue;
      if (overlay.cell == cell &&
          (overlay.kind == SpatialCellOverlayKind.spawn ||
              overlay.kind == SpatialCellOverlayKind.warp)) {
        return SpatialSceneContentHit(
          kind: overlay.kind == SpatialCellOverlayKind.spawn
              ? SpatialSceneContentKind.marker
              : SpatialSceneContentKind.warp,
          id: overlay.id,
          cell: overlay.cell,
        );
      }
    }
    final actorId = pickActor(offset);
    if (actorId != null) {
      final actor = actors[actorId]!.mesh;
      return SpatialSceneContentHit(
        kind: SpatialSceneContentKind.actor,
        id: actorId,
        cell: (
          (actor.position.x - configuration.sceneOffset.dx).floor(),
          (actor.position.z - configuration.sceneOffset.dy).floor(),
        ),
      );
    }
    final model = pickModel(offset);
    return model == null
        ? null
        : SpatialSceneContentHit(
            kind: SpatialSceneContentKind.model,
            id: model.id,
            cell: (
              model.supportPosition.x.floor(),
              model.supportPosition.z.floor(),
            ),
          );
  }

  (int, int)? pickContentCell(Offset offset) =>
      pickContent(offset)?.cell ?? pickCell(offset);
  SpatialModelInstance? pickModel(Offset offset) {
    if (refreshing) return null;
    final configuration = visibleConfiguration;
    SpatialModelInstance? selected;
    var nearest = double.infinity;
    for (final instance in configuration.scene.instances) {
      if (!_modelVisible(
        configuration.groundMap?.id ?? '__scene__',
        instance.id,
      ))
        continue;
      final layerId = configuration.groundMap == null
          ? null
          : sceneChunks[configuration.groundMap!.id]
                ?.cellOrigins[instance.id]
                ?.layerId;
      if (layerId != null &&
          configuration.canSelectLayer?.call(layerId) == false)
        continue;
      if (configuration.canSelectContent?.call(
            SpatialSceneContentKind.model,
            instance.id,
          ) ==
          false)
        continue;
      final definition = configuration.models
          .where((model) => model.id == instance.modelId)
          .firstOrNull;
      if (definition == null) continue;
      final bounds = instance.clip == null
          ? definition.inspection.bounds
          : modelComponents[instance.id]?.component.visibleBounds;
      if (bounds == null) continue;
      final angle = instance.rotationDegrees * math.pi / 180;
      final scale = instance.scale * definition.scale;
      final projected = <Offset>[];
      var depth = 0.0;
      for (final x in [bounds.min.x, bounds.max.x]) {
        for (final y in [bounds.min.y, bounds.max.y]) {
          for (final z in [bounds.min.z, bounds.max.z]) {
            final dx = (x - definition.pivot.x) * scale;
            final dz = (z - definition.pivot.z) * scale;
            final worldX =
                instance.position.x +
                configuration.sceneOffset.dx +
                dx * math.cos(angle) +
                dz * math.sin(angle);
            final worldZ =
                instance.position.z +
                configuration.sceneOffset.dy -
                dx * math.sin(angle) +
                dz * math.cos(angle);
            final clip = camera.viewProjectionMatrix.transform(
              Vector4(
                worldX,
                instance.position.y + (y - definition.pivot.y) * scale,
                worldZ,
                1,
              ),
            );
            if (clip.w <= 0) continue;
            projected.add(
              Offset(
                (clip.x / clip.w + 1) * size.x / 2,
                (1 - clip.y / clip.w) * size.y / 2,
              ),
            );
            depth += clip.z / clip.w;
          }
        }
      }
      if (projected.length != 8) continue;
      final rect = Rect.fromLTRB(
        projected.map((point) => point.dx).reduce(math.min),
        projected.map((point) => point.dy).reduce(math.min),
        projected.map((point) => point.dx).reduce(math.max),
        projected.map((point) => point.dy).reduce(math.max),
      );
      if (rect.contains(offset) && depth < nearest) {
        selected = instance;
        nearest = depth;
      }
    }
    return selected;
  }

  double? contentHeight(SpatialSceneContentHit hit, Offset offset) {
    final ray = pointerRay(offset);
    return ray == null
        ? null
        : spatialContentDragHeight(ray.$1, ray.$2, hit.cell);
  }

  (int, int)? pickPlaneCell(Offset offset, double height) {
    final ray = pointerRay(offset);
    return ray == null ? null : pickSpatialPlaneCell(ray.$1, ray.$2, height);
  }

  (int, int)? pickCell(Offset offset) => pickSurface(offset)?.cell;

  SpatialSurfaceHit? pickSurface(Offset offset) {
    final ray = pointerRay(offset, allowStableSurface: true);
    return ray == null
        ? null
        : pickSpatialSurface(visibleConfiguration.scene, ray.$1, ray.$2);
  }

  (Vector3, Vector3)? pointerRay(
    Offset offset, {
    bool allowStableSurface = false,
  }) {
    if (!sceneReady || size.x <= 0 || size.y <= 0) return null;
    if (refreshing &&
        (!allowStableSurface ||
            !configuration.surfaceGeometryMatches(visibleConfiguration))) {
      return null;
    }
    final inverse = Matrix4.copy(camera.viewProjectionMatrix);
    if (inverse.invert() == 0) return null;
    final x = offset.dx / size.x * 2 - 1;
    final y = 1 - offset.dy / size.y * 2;
    Vector3 unproject(double z) {
      final point = inverse.transform(Vector4(x, y, z, 1));
      return Vector3(point.x / point.w, point.y / point.w, point.z / point.w);
    }

    final start = unproject(-1);
    final direction = unproject(1) - start;
    final sceneOffset = visibleConfiguration.sceneOffset;
    start.x -= sceneOffset.dx;
    start.z -= sceneOffset.dy;
    return (start, direction);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (sceneReady) {
      syncCamera();
      if (configuration.onHover != null) onSurfaceChanged();
    }
  }

  @override
  void onRemove() {
    _destinationPreparation?.discard();
    _destinationPreparation = null;
    closed = true;
    _pendingVisualOrder?.complete(false);
    _pendingVisualOrder = null;
    generation++;
    atmosphereEffects.clear();
    weatherEffects.clear();
    presentationEffects.clear();
    sceneComponents.dispose();
    placementRenderer.dispose();
    configuration.controller.sceneChanges.removeListener(syncCamera);
    configuration.animationPreview?.removeListener(syncAnimations);
    clearModelResourceCache();
    loadedModelSources.clear();
    clippedModelCache.clear();
    modelComponents.clear();
    animationModels.clear();
    runtimeModelIndex = SpatialRuntimeModelIndex(const {});
    clearGroundResourceCache();
    for (final lease in retiredReservations) {
      lease.release();
    }
    retiredReservations.clear();
    _ownedResourceBudget.dispose();
    for (final ground in grounds) {
      ground.occlusions.clear();
    }
    grounds.clear();
    sceneChunks.clear();
    _smartTileProjectionCache.clear();
    actorSelections.clear();
    actorContactShadows.clear();
    actorFrames = const {};
    super.onRemove();
  }
}

bool _sameNeighbors(
  List<SpatialSceneNeighbor> before,
  List<SpatialSceneNeighbor> after,
) {
  if (before.length != after.length) return false;
  for (var index = 0; index < before.length; index++) {
    if (!identical(before[index].map, after[index].map) ||
        !identical(before[index].project, after[index].project) ||
        before[index].offset != after[index].offset) {
      return false;
    }
  }
  return true;
}

bool _sameModelSources(
  List<ProjectModel3dEntry> before,
  List<ProjectModel3dEntry> after,
) {
  if (before.length != after.length) return false;
  for (var index = 0; index < before.length; index++) {
    final a = before[index], b = after[index];
    if (a != b &&
        a.copyWith(
              castsShadowsByDefault: b.castsShadowsByDefault,
              light: b.light,
              clearLight: b.light == null,
            ) !=
            b) {
      return false;
    }
  }
  return true;
}

bool _sameModelSourceProjects(
  ProjectManifest? before,
  ProjectManifest? after,
) =>
    identical(before, after) ||
    before != null &&
        after != null &&
        _sameModelSources(before.models3d, after.models3d) &&
        before.copyWith(models3d: after.models3d) == after;

typedef _ScenePlacedModel = ({
  _SceneModelComponent component,
  Vector3 position,
  Model3dVector3 anchor,
});

typedef _SceneChunkSignature = (
  MapData?,
  MapSpatialScene,
  ProjectManifest?,
  Offset,
  Color,
  Color,
  (int, int)?,
  bool,
);

final class _SceneChunk {
  _SceneChunk({
    required this.signature,
    required this.components,
    required this.ground,
    required this.models,
    required this.terrain,
    required Map<String, ({String layerId, GridPos cell})> cellOrigins,
  }) {
    this.cellOrigins = cellOrigins;
  }

  _SceneChunkSignature signature;
  final List<Object3D> components;
  final _SceneGround? ground;
  final Map<String, _ScenePlacedModel> models;
  final List<Object3D> terrain;
  Map<String, ({String layerId, GridPos cell})> _cellOrigins = const {};
  Map<String, Set<String>> modelIdsByLayer = const {};
  Map<String, ({String layerId, GridPos cell})> get cellOrigins => _cellOrigins;
  set cellOrigins(Map<String, ({String layerId, GridPos cell})> value) {
    _cellOrigins = value;
    final byLayer = <String, Set<String>>{};
    for (final entry in value.entries) {
      byLayer.putIfAbsent(entry.value.layerId, () => {}).add(entry.key);
    }
    modelIdsByLayer = byLayer;
  }
}

final class _SceneGround {
  _SceneGround(
    this.plan,
    this.textures,
    this.offset, {
    required this.mapId,
    required this.project,
    required this.loader,
    required this.animationElapsedMsForCell,
    required this.occlusionStateForCell,
    required this.presentationElapsedSeconds,
    required this.ground,
    required this.edge,
    required this.selectedCell,
    required this.receiveShadows,
    required this.occlusionPlan,
  }) : sourcePlan = plan,
       sourceOcclusionPlan = occlusionPlan;

  SpatialActorOcclusionPlan occlusionPlan;
  SpatialActorOcclusionPlan sourceOcclusionPlan;
  final occlusions = SpatialActorOcclusionBillboards();
  SpatialGroundPlan plan;
  SpatialGroundPlan sourcePlan;
  final Map<String, Texture> textures;
  final Offset offset;
  final String mapId;
  final ProjectManifest project;
  final Future<Uint8List> Function(String) loader;
  int Function(String, String, int, int, int)? animationElapsedMsForCell;
  SpatialActorOcclusionStateForCell? occlusionStateForCell;
  double Function()? presentationElapsedSeconds;
  int? _sampledElapsed;
  Set<String> currentImageIds = {}, nextImageIds = {};
  Set<String> renderedOcclusionImageIds = {};
  void sampleTextureWindow(int elapsed) {
    Set<String> at(int delta) => {
      ...plan.imageIdsAt(
        elapsed + delta,
        animationElapsedMsForCell: animationElapsedMsForCell == null
            ? null
            : (layer, x, y, time) =>
                  animationElapsedMsForCell!(mapId, layer, x, y, time),
      ),
      for (final item in occlusionPlan.resolve(
        ((presentationElapsedSeconds?.call() ?? elapsed / 1000) * 1000)
                .floor() +
            delta,
        stateForCell: occlusionStateForCell == null
            ? null
            : (layer, x, y, time) =>
                  occlusionStateForCell!(mapId, layer, x, y, time),
      ))
        item.visual.tilesetId,
    };
    currentImageIds = at(0);
    nextImageIds = plan.animated ? at(plan.animationLookaheadMs) : const {};
    _sampledElapsed = elapsed;
  }

  Set<String> get renderedImageIds => {
    if (plan.cliff case final cliff?) cliff.tilesetId,
    for (final item in visuals) item.visual.tilesetId,
    ...renderedOcclusionImageIds,
  };
  final Color ground, edge;
  final (int, int)? selectedCell;
  final bool receiveShadows;
  List<SpatialGroundVisual> visuals = [];
  List<MeshComponent> components = [];
  List<MeshComponent> underlays = [];
  bool initialized = false;
  late final _meshBatches = SpatialGroundMeshBatches(
    (visuals) => [
      for (final mesh in spatialGroundMeshes(
        visuals,
        textures,
        scene: plan.scene,
        excludedCellsFor: plan.excludedCellsFor,
        flatSurfaceFor: plan.flatSurfaceFor,
        groundReplacements: plan.borderGroundReplacements,
      ))
        MeshComponent(mesh: mesh, position: Vector3(offset.dx, 0, offset.dy)),
    ],
  );

  bool resolve(
    int elapsedMs, {
    bool forceGeometry = false,
    int Function(
      String mapId,
      String layerId,
      int cellX,
      int cellY,
      int elapsedMs,
    )?
    animationElapsedMsForCell,
  }) {
    if (_sampledElapsed != elapsedMs) sampleTextureWindow(elapsedMs);
    if (currentImageIds.any((id) => !textures.containsKey(id))) return false;
    final next = plan.resolve(
      elapsedMs,
      animationElapsedMsForCell: animationElapsedMsForCell == null
          ? null
          : (layerId, cellX, cellY, elapsedMs) => animationElapsedMsForCell(
              mapId,
              layerId,
              cellX,
              cellY,
              elapsedMs,
            ),
    );
    var changed =
        forceGeometry || !initialized || next.length != visuals.length;
    var geometryChanged = changed;
    for (var index = 0; !geometryChanged && index < next.length; index++) {
      final before = visuals[index].visual, after = next[index].visual;
      geometryChanged =
          before.transform != after.transform ||
          before.geometry.destinationRect != after.geometry.destinationRect ||
          before.geometry.visualBounds != after.geometry.visualBounds ||
          before.geometry.anchorOffset != after.geometry.anchorOffset ||
          before.geometry.transformedAnchorOffset !=
              after.geometry.transformedAnchorOffset ||
          before.spatialFollowTerrain != after.spatialFollowTerrain ||
          before.spatialHeightOffset != after.spatialHeightOffset ||
          before.spatialClip != after.spatialClip;
      changed =
          changed ||
          geometryChanged ||
          before.sourceRect != after.sourceRect ||
          before.tilesetId != after.tilesetId ||
          visuals[index].height != next[index].height ||
          visuals[index].opacity != next[index].opacity;
    }
    if (!changed) return false;
    initialized = true;
    visuals = next;
    if (geometryChanged) {
      final painted = plan.paintedCellsFor(visuals);
      underlays = [
        for (final mesh in terrainMeshes(
          plan.scene!,
          ground,
          edge,
          selectedCell: selectedCell,
          paintedCells: painted,
          replacedGroundCells: plan.groundReplacementCells,
          borderGroundReplacements: plan.borderGroundReplacements,
          bridgeCells: plan.bridgeCells,
          underlaySupports: painted == null
              ? null
              : plan.underlaySupportsFor(visuals),
          includeCliffs: false,
          receiveShadows: receiveShadows,
        ))
          MeshComponent(mesh: mesh, position: Vector3(offset.dx, 0, offset.dy)),
      ];
    }
    _meshBatches.resolve(visuals, invalidateGeometry: geometryChanged);
    components = [..._meshBatches.components, ...underlays];
    return true;
  }
}

class _SceneActorComponent extends MeshComponent {
  _SceneActorComponent({required super.mesh});

  bool presentationVisible = true;

  @override
  void draw(RenderContext3D context) {
    if (presentationVisible) super.draw(context);
  }

  @override
  bool isVisible(CameraComponent3D camera) =>
      presentationVisible && super.isVisible(camera);
}

class _SceneModelComponent extends AnimatedModelComponent {
  _SceneModelComponent({
    required this.instanceId,
    required this.initialAnchorY,
    required this.shadowId,
    required super.model,
    required this.visibleBounds,
    required this.definition,
    super.position,
    super.rotation,
    super.scale,
    super.playback,
    super.runtimePoseBefore,
  }) {
    initialPositionY = position.y;
  }
  final Model3dBounds visibleBounds;
  final ProjectModel3dEntry definition;
  final String instanceId;
  final double initialAnchorY;
  late final double initialPositionY;
  final String shadowId;
  bool presentationVisible = true;
  @override
  void draw(RenderContext3D context) {
    if (!presentationVisible) return;
    if (context is! SpatialRenderContext) {
      super.draw(context);
      return;
    }
    final previous = context.sourceInstanceId;
    final previousShadow = context.sourceShadowId;
    context.sourceInstanceId = instanceId;
    context.sourceShadowId = shadowId;
    try {
      super.draw(context);
    } finally {
      context.sourceInstanceId = previous;
      context.sourceShadowId = previousShadow;
    }
  }

  @override
  bool isVisible(CameraComponent3D camera) => presentationVisible;
}

Iterable<Mesh> terrainMeshes(
  MapSpatialScene scene,
  Color ground,
  Color edge, {
  (int, int)? selectedCell,
  Set<(int, int)>? paintedCells,
  SpatialGroundUnderlayIndex? underlaySupports,
  Set<(int, int)> replacedGroundCells = const {},
  SpatialBorderGroundReplacementIndex borderGroundReplacements = const {},
  Set<(int, int)> bridgeCells = const {},
  bool includeGround = true,
  bool includeCliffs = true,
  bool receiveShadows = false,
  ({Texture texture, SmartTileSourceRect sourceRect})? cliffTexture,
}) sync* {
  final groups =
      <(Color, bool), ({List<Vertex> vertices, List<int> indices})>{};
  var vertexCount = 0;
  if (cliffTexture != null) {
    final rect = cliffTexture.sourceRect, texture = cliffTexture.texture;
    if (rect.x < 0 ||
        rect.y < 0 ||
        rect.width <= 0 ||
        rect.height <= 0 ||
        rect.x + rect.width > texture.width ||
        rect.y + rect.height > texture.height) {
      throw StateError('Frame de falaise hors de son atlas.');
    }
  }
  Mesh flush() {
    final mesh = Mesh();
    for (final entry in groups.entries) {
      final cliff = cliffTexture;
      final material = entry.key.$2 && cliff != null
          ? (SpatialPixelMaterial(
                cliff.texture,
                lightingRole: receiveShadows
                    ? SpatialPixelLightingRole.ground
                    : SpatialPixelLightingRole.surface,
              )
              ..uvRect.setValues(
                cliff.sourceRect.x / cliff.texture.width,
                cliff.sourceRect.y / cliff.texture.height,
                cliff.sourceRect.width / cliff.texture.width,
                cliff.sourceRect.height / cliff.texture.height,
              ))
          : receiveShadows
          ? (SpatialPixelMaterial(
              Texture.standard,
              lightingRole: SpatialPixelLightingRole.ground,
              preserveUnlitColor: true,
            )..albedoColor = entry.key.$1)
          : UnlitMaterial(albedoColor: entry.key.$1);
      mesh.addSurface(
        Surface(
          vertices: entry.value.vertices,
          indices: entry.value.indices,
          material: material,
        ),
      );
    }
    groups.clear();
    vertexCount = 0;
    return mesh;
  }

  for (final face
      in spatialTerrainFaces(
        scene,
        groundReplacements: borderGroundReplacements,
      ).expand(
        (face) => underlaySupports == null
            ? [face]
            : spatialTerrainUnderlayFaces(face, underlaySupports),
      )) {
    if (face.isTop ? !includeGround : !includeCliffs) continue;
    if (face.isTop && replacedGroundCells.contains(face.cell)) continue;
    if (!face.isTop && bridgeCells.contains(face.cell)) continue;
    if (face.isTop &&
        paintedCells != null &&
        !paintedCells.contains(face.cell)) {
      continue;
    }
    if (vertexCount + face.positions.length > 60000) yield flush();
    final (x, z) = face.cell;
    final color = !face.isTop
        ? edge
        : selectedCell == face.cell
        ? Color.lerp(ground, edge, .8)!
        : (x + z).isEven
        ? ground
        : Color.lerp(ground, edge, .15)!;
    final textured = !face.isTop && cliffTexture != null;
    final group = groups.putIfAbsent((
      color,
      textured,
    ), () => (vertices: <Vertex>[], indices: <int>[]));
    final base = group.vertices.length;
    for (var index = 0; index < face.positions.length; index++) {
      group.vertices.add(
        Vertex(
          position: face.positions[index],
          texCoord: face.uvs[index],
          color: textured ? const Color(0xffffffff) : color,
        ),
      );
    }
    for (var index = 1; index < face.positions.length - 1; index++) {
      group.indices.addAll([base, base + index, base + index + 1]);
    }
    vertexCount += face.positions.length;
  }
  if (vertexCount > 0) yield flush();
}

MapData _mapWithSmartTileProjection(
  MapData map,
  SpatialSmartTileModelProjection projection,
) {
  final scene = map.spatialScene;
  if (scene == null) return map;
  final instances = [
    for (final instance in scene.instances)
      if (!instance.id.startsWith('smt_')) instance,
    ...projection.instances,
  ];
  return listEquals(instances, scene.instances)
      ? map
      : map.copyWith(spatialScene: scene.copyWith(instances: instances));
}

enum _VisualOrderChange { layers, decor }

_VisualOrderChange? _visualOrderChange(
  SpatialSceneView before,
  SpatialSceneView after,
) {
  final a = before.groundMap, b = after.groundMap;
  if (a == null ||
      b == null ||
      identical(a, b) ||
      !identical(before.scene, after.scene) ||
      !identical(before.groundProject, after.groundProject) ||
      before.groundProject == null ||
      before.models != after.models ||
      before.loadModel != after.loadModel ||
      before.loadGroundImage != after.loadGroundImage ||
      !identical(before.resourceBudget, after.resourceBudget) ||
      before.resourceIdentity != after.resourceIdentity ||
      !identical(before.controller, after.controller) ||
      !identical(before.animationPreview, after.animationPreview) ||
      before.sceneOffset != after.sceneOffset ||
      before.ground != after.ground ||
      before.edge != after.edge ||
      before.selectedCell != after.selectedCell ||
      !_sameNeighbors(before.neighbors, after.neighbors) ||
      before.rasterAnimationElapsedMsForCell !=
          after.rasterAnimationElapsedMsForCell ||
      before.actorOcclusionStateForCell != after.actorOcclusionStateForCell ||
      !mapSharesNonVisualOrderStorage(a, b) ||
      a.layers.length != b.layers.length ||
      a.placedElements.length != b.placedElements.length)
    return null;
  final layers = {for (final layer in a.layers) layer.id: layer};
  var reordered = false;
  for (final (index, layer) in b.layers.indexed) {
    if (layers[layer.id] != layer) return null;
    reordered = reordered || a.layers[index].id != layer.id;
  }
  for (var index = 0; index < a.placedElements.length; index++) {
    final previous = a.placedElements[index], next = b.placedElements[index];
    if (!identical(previous, next) &&
        previous.copyWith(visualOrder: next.visualOrder) != next)
      return null;
  }
  return reordered ? _VisualOrderChange.layers : _VisualOrderChange.decor;
}
