import 'spatial_point_light.dart';
import 'spatial_flame_effects.dart';
import 'spatial_light_behavior.dart';

import 'dart:async';
import 'dart:ui' as ui show Gradient, Image;
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
import 'spatial_scene_height_cache.dart';
import 'spatial_scene_ground_image_references.dart';
import 'spatial_camera_magnification.dart';
import 'flutter_frame_graphics_device.dart';
import 'spatial_render_context.dart';
import 'spatial_actor_visual.dart';
import 'spatial_actor_occlusion.dart';
import 'spatial_actor_contact_shadow.dart';
import 'spatial_actor_landing_dust.dart';
import 'spatial_game_surface.dart';
import 'spatial_pixel_material.dart';
import 'spatial_ground.dart';
import 'spatial_cooperative_work.dart';
import 'spatial_ground_mesh_batches.dart';
import 'spatial_terrain_geometry.dart';
import 'spatial_selection.dart';
import 'spatial_cell_overlay.dart';
import 'spatial_scene_neighbor.dart';
import 'spatial_scene_decoration.dart';
import 'spatial_scene_authoring_target.dart';
import 'spatial_scene_components.dart';
import 'spatial_model_placement_preview.dart';
import 'spatial_runtime_model_index.dart';
import 'spatial_runtime_model_transform.dart';
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
import 'spatial_upscaler.dart';
import 'spatial_weather_effects.dart';
import 'spatial_renderer_initialization.dart';

export 'spatial_renderer_initialization.dart' show initializeSpatialRenderer;

part 'spatial_scene_materialization.dart';
part 'spatial_scene_decoration_rendering.dart';
part 'spatial_scene_model_sources.dart';

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
  double flameSoundGain = 0;
  SpatialSceneController({
    DateTime Function()? now,
    this.presentationEffectsEnabled = true,
  }) : _now = now ?? DateTime.now;
  final bool presentationEffectsEnabled;
  static final _clearDepthOfField = SpatialDepthOfFieldProfile();
  static final _clearWeather = SpatialWeatherSettings(
    kind: SpatialWeatherKind.clear,
    transitionSeconds: 0,
  );
  late final _clearPresentation = SpatialPresentationProfile(
    haloStrength: 0,
    fogOpacity: 0,
  );
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
  SpatialDepthOfFieldProfile get depthOfFieldProfile =>
      presentationEffectsEnabled ? _depthOfFieldProfile : _clearDepthOfField;
  set depthOfFieldProfile(SpatialDepthOfFieldProfile value) {
    _depthOfFieldProfile = value;
    super.notifyListeners();
  }

  bool get depthOfFieldEnabled => depthOfFieldProfile.enabled;
  set depthOfFieldEnabled(bool value) =>
      depthOfFieldProfile = SpatialDepthOfFieldProfile(
        enabled: value,
        strength: _depthOfFieldProfile.strength,
        focusRange: _depthOfFieldProfile.focusRange,
      );
  SpatialPresentationProfile _presentationProfile =
      SpatialPresentationProfile.disabled;
  SpatialPresentationProfile get presentationProfile =>
      presentationEffectsEnabled ? _presentationProfile : _clearPresentation;
  set presentationProfile(SpatialPresentationProfile value) {
    if (identical(_presentationProfile, value)) return;
    _presentationProfile = value;
    super.notifyListeners();
  }

  bool _halosEnabled = false, _depthFogEnabled = false;
  bool get halosEnabled => presentationEffectsEnabled && _halosEnabled;
  set halosEnabled(bool value) {
    if (_halosEnabled == value) return;
    _halosEnabled = value;
    super.notifyListeners();
  }

  bool get depthFogEnabled => presentationEffectsEnabled && _depthFogEnabled;
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
    if (!presentationEffectsEnabled) return _clearWeather;
    final base = (_authoredAtmosphere ?? _baseAtmosphere).weather;
    final environment = worldEnvironment ?? _previewEnvironment;
    final kind = environment.weatherKind;
    final intensity = base.intensity * (environment.weatherIntensity ?? 1);
    if ((kind == null || kind == base.kind) && intensity == base.intensity) return base;
    if (_resolvedWeatherBase != base || _resolvedWeather?.kind != (kind ?? base.kind) || _resolvedWeather?.intensity != intensity) {
      _resolvedWeatherBase = base;
      _resolvedWeather = base.copyWith(kind: kind, intensity: intensity);
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

  bool get fireflies => presentationEffectsEnabled && _fireflies;
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

  bool _shadowsEnabled = true;
  bool get shadowsEnabled => _shadowsEnabled;
  set shadowsEnabled(bool value) {
    if (_shadowsEnabled == value) return;
    _shadowsEnabled = value;
    notifyListeners();
  }

  SpatialUpscaling _upscaling = SpatialUpscaling.nearest;
  SpatialUpscaling get upscaling => _upscaling;
  set upscaling(SpatialUpscaling value) {
    if (_upscaling == value) return;
    _upscaling = value;
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
  SpatialDecorationRenderStats Function()? _readDecorationStats;
  SpatialDecorationRenderStats get decorationStats => _readDecorationStats?.call() ?? const SpatialDecorationRenderStats();
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
    this.decorations = const [],
    this.authoringTarget,
    this.resolveAuthoringTarget,
    this.sceneOffset = Offset.zero,
    this.animationPreview,
    this.modelRuntimeState,
    this.modelPresence,
    this.rasterAnimationElapsedMsForCell,
    this.actorOcclusionStateForCell,
    this.presentationPaused,
    this.renderPreparationPaused,
    this.presentationElapsedSeconds,
    this.cameraPose,
    this.cameraMagnification,
    this.adaptivePlaybackFraming = false,
    this.resourceBudget,
    this.renderResolutionScale = 1,
    this.resourceIdentity,
    this.modelSourceRevisions = const {},
    this.changedModelSourceIds,
    this.modelSourceDefinitions = const {},
    this.modelSourceUpdates,
  });
  final RuntimeResourceBudget? resourceBudget;
  final double renderResolutionScale;
  final String? resourceIdentity;
  final Map<String, String> modelSourceRevisions;
  final Set<String>? changedModelSourceIds;
  final Map<String, ProjectModel3dEntry> modelSourceDefinitions;
  final SpatialModelSourceUpdates? modelSourceUpdates;
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
  final bool Function()? renderPreparationPaused;
  final double Function()? presentationElapsedSeconds;
  final ({double x, double y, double z, double zoom})? Function()? cameraPose;
  final double Function()? cameraMagnification;
  final bool adaptivePlaybackFraming;
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
  final List<SpatialSceneDecoration> decorations;
  final SpatialSceneAuthoringTarget? authoringTarget;
  final SpatialSceneAuthoringTarget? Function(int x, int z)? resolveAuthoringTarget;
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
      mapEquals(modelSourceRevisions, other.modelSourceRevisions) &&
      (immutableResourcesMatch(other) ||
      _sameModelSourceProjects(groundProject, other.groundProject) &&
          loadModel == other.loadModel &&
          _sameModelSources(models, other.models));

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
  Object? _decorationFailure;
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
    widget.controller._readDecorationStats = readDecorationStats;
    widget.controller._readActorContactShadowCount =
        readActorContactShadowCount;
    initialize();
  }

  Future<bool> prepareDestination(SpatialScenePreparation request) async =>
      mounted ? await game?.prepareDestination(request) ?? false : false;

  SpatialDecorationRenderStats readDecorationStats() => game?.decorationStats ?? const SpatialDecorationRenderStats();

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
      oldWidget.controller._readDecorationStats = null;
      oldWidget.controller._readActorContactShadowCount = null;
      widget.controller._readShadowStats = readShadowStats;
      widget.controller._readDecorationStats = readDecorationStats;
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
    if (game.syncLightDefinitions(oldWidget)) return;
    if (game.canSyncModelSourceRevisions) {
      refresh();
      return;
    }
    if (game.hasVisualOrderChange) {
      refresh();
      return;
    }
    final resourceIdentityChanged =
        widget.resourceIdentity != oldWidget.resourceIdentity ||
        !identical(widget.resourceBudget, oldWidget.resourceBudget);
    final modelSourcesChanged =
        !widget.modelSourcesMatch(oldWidget) || resourceIdentityChanged;
    final sourceRevisionChanged = !resourceIdentityChanged &&
        !mapEquals(widget.modelSourceRevisions, oldWidget.modelSourceRevisions);
    if ((!widget.immutableResourcesMatch(oldWidget) &&
            !identical(oldWidget.groundProject, widget.groundProject) &&
            !(sourceRevisionChanged && _sameProjectOutsideModels(oldWidget.groundProject, widget.groundProject))) ||
        resourceIdentityChanged) {
      game.clearGroundResourceCache(retire: true);
      game.placementRenderer.clear();
    }
    if (modelSourcesChanged && !sourceRevisionChanged) {
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
      if (!_sameDecorations(oldWidget.decorations, widget.decorations)) {
        unawaited(game.syncDecorations().then((accepted) {
          if (mounted && accepted && _decorationFailure != null) {
            setState(() {
              if (identical(failure, _decorationFailure)) failure = null;
              _decorationFailure = null;
            });
          }
          return accepted;
        }).catchError((Object error, StackTrace trace) {
          if (mounted) setState(() { _decorationFailure = error; failure = error; });
          return false;
        }));
      }
      game.renderedConfiguration = widget;
      game.syncVisibility();
      game.syncContentSelection(oldWidget, widget);
      if (!identical(oldWidget.contentPreview, widget.contentPreview)) {
        game.syncContentPreview();
      }
      if (!identical(oldWidget.placementPreview, widget.placementPreview) || oldWidget.authoringTarget != widget.authoringTarget) {
        game.syncPlacementPreview();
      }
      if (!listEquals(oldWidget.cellOverlays, widget.cellOverlays) || oldWidget.authoringTarget != widget.authoringTarget) {
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
    if (widget.controller._readDecorationStats == readDecorationStats) widget.controller._readDecorationStats = null;
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
  SpatialUpscaler? _upscaler;
  SpatialDepthOfField? _activeDepthOfField;
  SpatialUpscaler? _activeUpscaler;
  late final ui.Image Function(GpuRenderTarget, Size) _postProcess = _process;
  int renderedFrameCount = 0;

  Map<String, Object?> get depthOfFieldFrame => {
    'render': renderedFrameCount,
    'enabled': device.postProcess != null,
    'strength': _depthOfField?.profile.strength,
    'focusRange': _depthOfField?.profile.focusRange,
    'focusDepth': _depthOfField?.focusDepth,
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
    renderWeatherOverlay(canvas);
    renderedFrameCount++;
  });

  @visibleForTesting
  void renderWeatherOverlay(Canvas canvas) {
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
    final flash = visibleConfiguration.presentationPaused?.call() == true
        ? 0.0
        : weather.weatherSkyFlash.clamp(0.0, .1);
    if (flash > .0001) {
      final viewport = Size(size.x, size.y);
      if (flash != _weatherFlash || viewport != _weatherFlashSize) {
        _weatherFlash = flash;
        _weatherFlashSize = viewport;
        _weatherFlashPaint.shader = ui.Gradient.linear(
          Offset.zero, Offset(0, viewport.height),
          [const Color(0xffe5edff).withValues(alpha: flash), const Color(0xffe5edff).withValues(alpha: flash * .55)],
        );
      }
      canvas.drawRect(Offset.zero & viewport, _weatherFlashPaint);
    }
  }

  void syncDepthOfField() {
    final profile = visibleConfiguration.controller.depthOfFieldProfile;
    final focus = profile.active && !_isIndoor
        ? ((_depthOfField ??= SpatialDepthOfField(device.backend))
            ..profile = profile
            ..focusDepth = (camera.position - camera.target).length)
        : null;
    final upscaler =
        visibleConfiguration.controller.upscaling == SpatialUpscaling.fsr1 &&
            renderResolutionScale < 1
        ? _upscaler ??= SpatialUpscaler(device.backend)
        : null;
    _activeDepthOfField = focus;
    _activeUpscaler = upscaler;
    device
      ..postProcess = focus == null && upscaler == null ? null : _postProcess
      ..secondaryColorClearValue = focus == null
          ? null
          : SpatialDepthOfField.depthClearValue;
  }

  ui.Image _process(GpuRenderTarget target, Size size) {
    final scene =
        _activeDepthOfField?.compositeTexture(target, size) ??
        target.colorTexture;
    final upscaler = _activeUpscaler;
    if (upscaler == null) return scene.asImage();
    return upscaler
        .upscale(
          scene,
          size,
          World3D.renderSizeFor(
            camera.viewport.virtualSize,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(buildContext!),
            resolutionScale: 1,
          ),
        )
        .asImage();
  }

  @override
  late final RenderContext3D context = SpatialRenderContext(device);

  SpatialSceneGame(
    this.configuration, {
    required this.onPreviewStatus,
    required this.onSurfaceChanged,
  }) : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40)) {
    SpatialUpscaler.registerLicense();
    _bindModelSourceUpdates();
  }
  SpatialSceneView configuration;
  final _cameraHeightCache = SpatialSceneHeightCache();
  SpatialLightingProfile? previewLighting;
  SpatialLightingProfile authoredLighting = SpatialLightingProfile.disabled;
  List<SpatialAuthoredShadowCaster> _authoredShadowCasters = const [];
  Map<String, SpatialAuthoredShadowCaster> _runtimeShadowCasters = const {};
  List<SpatialAuthoredShadowCaster> get authoredShadowCasters => _authoredShadowCasters;
  set authoredShadowCasters(List<SpatialAuthoredShadowCaster> value) {
    _authoredShadowCasters = value;
    _runtimeShadowCasters = {for (final caster in value) caster.id: caster};
  }
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

  double get allReceiverMinY => decorationChunks.isEmpty ? authoredReceiverMinY : math.min(authoredReceiverMinY, decorationReceiverMinY);
  double get allReceiverMaxY => decorationChunks.isEmpty ? authoredReceiverMaxY : math.max(authoredReceiverMaxY, decorationReceiverMaxY);

  bool syncLightDefinitions(SpatialSceneView before) => _syncLightDefinitions(before);

  void syncLighting() {
    if (visibleConfiguration.renderPreparationPaused?.call() == true) return;
    (context as SpatialRenderContext)
      ..pointLightShadowsEnabled =
          this.configuration.controller.previewPointLightShadowsEnabled
      ..shadowsEnabled = this.configuration.controller.shadowsEnabled;
    final preview = previewLighting;
    if (preview != null) {
      (context as SpatialRenderContext).lighting = preview;
      return;
    }
    final configuration = visibleConfiguration;
    final shadowCasters = _visibleShadowCasters ?? allAuthoredShadowCasters;
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
            minimumY: allReceiverMinY,
            maximumY: allReceiverMaxY,
          );
    final movingSun =
        frame != null && frame.solarPhase != 0 && frame.daylight > .001;
    final focusedReceivers =
        receiverBounds != null && (frame?.daylight ?? 1) > .001;
    final solarLighting = !movingSun && !focusedReceivers
        ? authoredLighting
        : spatialAuthoredShadowLighting(
            shadowCasters,
            receiverMinY: allReceiverMinY,
            receiverMaxY: allReceiverMaxY,
            receiverBounds: receiverBounds,
            sunDirection: sunDirection,
          );
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
      for (final binding in decorationPointLights.isEmpty ? pointLightBindings : [...pointLightBindings, ...decorationPointLights])
        if (binding.component.presentationVisible)
          _placedLight(
            binding.definition,
            binding.component,
            anchor,
            frame?.daylight ?? 1,
          ),
    ], anchor);
    flameEffects.sync(
      sources: [...pointLightBindings, ...decorationPointLights].map((binding) => SpatialFlameSource(
        key: binding.component,
        light: binding.definition,
        transform: binding.component.worldTransformMatrix,
        visible: binding.component.presentationVisible && binding.component.sourceGeometryVisible,
        strength: _lightEmission[binding.component]?.$2 ?? 1,
      )),
      elapsedSeconds: configuration.presentationElapsedSeconds?.call() ?? atmosphereElapsed,
      daylight: frame?.daylight ?? 1,
      indoors: _isIndoor,
      cameraPitch: billboardPitch,
      cameraYaw: billboardYaw,
      listenerPosition: anchor,
    );
    configuration.controller.flameSoundGain = flameEffects.soundGain;
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
  @override
  double get renderResolutionScale => configuration.renderResolutionScale;
  bool refreshing = false;
  Future<bool> syncDecorations() => _syncDecorations();

  int decorationUpdates = 0;
  int _decorationCommittedRevision = 0;
  bool _decorationLoading = false;
  SpatialDecorationRenderStats get decorationStats => SpatialDecorationRenderStats(requestRevision: _decorationGeneration, committedRevision: _decorationCommittedRevision, pending: _decorationLoading, sectorBuilds: decorationSectorBuilds, visibleSectors: decorationChunks.length);
  Map<String, List<Object?>> _decorationContourDependencies = {};
  Map<String, _MaterializedSceneChunk> _decorationMaterializations = {};
  double decorationReceiverMinY = 0;
  double decorationReceiverMaxY = 0;
  int decorationSectorBuilds = 0;
  bool _decorationReceiversEnabled = false;
  int _decorationGeneration = 0;
  Map<String, _SceneChunk> decorationChunks = {};
  Map<String, SpatialDecorationProjection> _decorationProjections = {};
  Map<(String, String), _SceneModelComponent> decorationAnimationModels = {};
  List<SpatialAuthoredShadowCaster> decorationShadowCasters = const [];
  List<({Model3dPointLight definition, _SceneModelComponent component})> decorationPointLights = const [];
  late final decorationSceneComponents = SpatialSceneComponents(world);
  final Map<String, Future<Model>> cache = {};
  Set<String> _sceneModelAssetIds = const {};
  final loadedModelSources = <String, Model>{};
  final _modelSourceDependents = <String, List<_ModelSourceDependent>>{};
  final _modelSourceInstanceDependents = <(String, String), _ModelSourceDependent>{};
  final _residentModelSourceRevisions = <String, String?>{};
  final _pendingModelSourceRevisions = <String, String?>{};
  final _pendingModelSourceDefinitions = <String, ProjectModel3dEntry>{};
  Map<String, String>? _lastModelSourceRevisions;
  SpatialModelSourceUpdates? _modelSourceUpdates;
  late final VoidCallback _modelSourceUpdateListener = _receiveModelSourceUpdates;
  bool _modelSourceRevisionPending = false;
  final _invalidatedModelChunks = <_SceneChunk>{};
  int modelSourceUpdates = 0;
  int modelSourceComponentBuilds = 0;
  int modelSourceCandidatesVisited = 0;
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
  late final actorLandingDust = SpatialActorLandingDust(world);
  late final weatherEffects = SpatialWeatherEffects(world);
  late final atmosphereEffects = SpatialAtmosphereEffects(world);
  late final presentationEffects = SpatialPresentationEffects(world);
  late final flameEffects = SpatialFlameEffects(world);
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
  Set<String> _pendingDecorationGroundImages = {};
  final _retainedGroundImages = <String>{};
  static const _maximumRetainedGroundPages = 128;
  static const _maximumRetainedGroundBytes = 48 * 1024 * 1024;
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
      groundTextureCache: {
        for (final entry in groundTextureCache.entries)
          if (!_retainedGroundImages.contains(entry.key)) entry.key: entry.value,
      },
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
      _wantedGroundImages.addAll(preparation.preparedGroundImageIds);
      _protectWantedGroundTextures();
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
    for (final id in _retainedGroundImages.toList()) {
      _removeGroundTexture(id);
    }
    groundTextureCache.clear();
    _groundTextures.clear();
    _groundTextureTokens.clear();
    _groundTextureErrors.clear();
    _reportedGroundTextureErrors.clear();
    _wantedGroundImages.clear();
    _pendingDecorationGroundImages.clear();
    _retainedGroundImages.clear();
    for (final lease in groundReservations.values) {
      lease.retainRequired();
    }
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
    _protectWantedGroundTextures();
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
        (_wantedGroundImages.contains(id) || _retainedGroundImages.contains(id));
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
            if (_retainedGroundImages.contains(id)) {
              _retainGroundTexture(id, lease);
              _trimRetainedGroundTextures();
            }
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
              _retainedGroundImages.remove(id);
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

  void _protectWantedGroundTextures() {
    for (final id in _wantedGroundImages) {
      _retainedGroundImages.remove(id);
      groundReservations[id]?.retainRequired();
    }
  }

  void _removeGroundTexture(String id) {
    _retainedGroundImages.remove(id);
    groundTextureCache.remove(id);
    _groundTextures.remove(id);
    _groundTextureTokens.remove(id);
    _groundTextureErrors.remove(id);
    _reportedGroundTextureErrors.remove(id);
    groundReservations.remove(id)?.release();
  }

  void _retainGroundTexture(String id, RuntimeResourceReservation lease) {
    lease.retainOptionally(() {
      if (identical(groundReservations[id], lease)) _removeGroundTexture(id);
    });
  }

  void _trimRetainedGroundTextures() {
    _retainedGroundImages.removeWhere((id) => !groundTextureCache.containsKey(id));
    var bytes = 0;
    for (final id in _retainedGroundImages) {
      bytes += groundReservations[id]?.residentBytes ?? 0;
    }
    while (_retainedGroundImages.length > _maximumRetainedGroundPages ||
        bytes > _maximumRetainedGroundBytes) {
      final id = _retainedGroundImages.first;
      bytes -= groundReservations[id]?.residentBytes ?? 0;
      _removeGroundTexture(id);
    }
  }

  void _pruneGroundTextures({bool sample = true}) {
    final elapsed = (groundElapsed * 1000).round();
    if (sample) {
      for (final ground in grounds) {
        if (!refreshing) {
          ground.animationElapsedMsForCell =
              decorationChunks.containsKey(ground.mapId) ? null : visibleConfiguration.rasterAnimationElapsedMsForCell;
          ground.occlusionStateForCell =
              decorationChunks.containsKey(ground.mapId) ? null : visibleConfiguration.actorOcclusionStateForCell;
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
      ..._pendingDecorationGroundImages,
    };
    _protectWantedGroundTextures();
    for (final id in groundTextureCache.keys.toList()) {
      if (_wantedGroundImages.contains(id)) continue;
      if (grounds.any((ground) => ground.plan.imageIds.contains(id))) {
        if (_retainedGroundImages.add(id)) {
          if (groundReservations[id] case final lease?) {
            _retainGroundTexture(id, lease);
          }
        }
      } else {
        _removeGroundTexture(id);
      }
    }
    _trimRetainedGroundTextures();
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
          Map<String, SmartTileCellContextResolver> cellContextResolvers,
          int width,
          int height,
          MapData map,
          bool hasGeneratedModels,
          Map<String, ({String layerId, GridPos cell})> cellOrigins,
          Map<String, ({double height, int layerRank})> paintHeightAnchors,
        })
      >.identity();

  MapData projectedSmartTileMap(MapData map, ProjectManifest? project, {Map<String, SmartTileCellContextResolver> cellContextResolvers = const {}}) {
    if (project == null) return map;
    final cached = _smartTileProjectionCache[map];
    if (cached != null &&
        identical(cached.catalog, project.smartTileCatalog) &&
        mapEquals(cached.cellContextResolvers, cellContextResolvers) &&
        cached.width == project.settings.tileWidth &&
        cached.height == project.settings.tileHeight) {
      return cached.map;
    }
    final projection = resolveSpatialSmartTileModelProjection(
      map: map,
      catalog: project.smartTileCatalog,
      sourceCellWidth: project.settings.tileWidth,
      sourceCellHeight: project.settings.tileHeight,
      cellContextResolvers: cellContextResolvers,
    );
    final projected = _mapWithSmartTileProjection(map, projection);
    final ranks = spatialSmartTileLayerPaintRanks(map);
    if (_smartTileProjectionCache.length >= 8) {
      _smartTileProjectionCache.remove(_smartTileProjectionCache.keys.first);
    }
    _smartTileProjectionCache[map] = (
      catalog: project.smartTileCatalog,
      cellContextResolvers: cellContextResolvers,
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
            allAuthoredShadowCasters.where(
              (caster) => !_hiddenShadowIds.contains(caster.id),
            ),
          );
    authoredLighting = spatialAuthoredShadowLighting(
      _visibleShadowCasters ?? allAuthoredShadowCasters,
      receiverMinY: allReceiverMinY,
      receiverMaxY: allReceiverMaxY,
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
        _modelSourceInstanceDependents[(map.id, instance.id)]?.instance = instance;
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
      cellContextResolvers: cached.cellContextResolvers,
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
    if (canSyncModelSourceRevisions) return _syncModelSourceRevisions();
    if (hasVisualOrderChange) {
      if (refreshing) return (_pendingVisualOrder ??= Completer<bool>()).future;
      if (_syncVisualOrder()) return true;
    }
    SpatialPreparedScenePlans? preparedPlans;
    final prepared = _destinationPreparation;
    if (prepared != null) {
      if (prepared.request.map.id == configuration.groundMap?.id &&
          prepared.isCurrent) {
        preparedPlans = prepared.takePreparedPlans(
          map: configuration.groundMap,
          project: configuration.groundProject,
          resourceIdentity: configuration.resourceIdentity,
          resourceBudget: resourceBudget,
        );
        prepared.commit();
      } else {
        prepared.discard();
      }
      _destinationPreparation = null;
    }
    final ticket = ++generation;
    _invalidateChangedModelSourceRevisions();
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
        snapshot.decorations.isNotEmpty ||
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
        if (previousChunk?.signature == signature && !_invalidatedModelChunks.contains(previousChunk)) {
          final chunk = previousChunk!;
          nextChunks[mapId] = chunk;
          groups[mapId] = chunk.components;
          if (chunk.ground case final ground?) nextGrounds.add(ground);
          for (final entry in chunk.models.entries) {
            nextAnimationModels[(mapId, entry.key)] = entry.value.component;
            final instance = instancesById[entry.key]!;
            final definition = placementDefinitions[instance.modelId]!;
            if (entry.value.component.sourceGeometryVisible && definition.light != null) {
              final light = definition.light!;
              nextPointLights.add((
                definition: light,
                component: entry.value.component,
              ));
            }
            final caster = !entry.value.component.sourceGeometryVisible ? null : spatialAuthoredShadowCaster(
              mapId: mapId,
              instance: instance,
              definition: definition,
              bounds: entry.value.component.visibleBounds,
              worldTransform: entry.value.component.worldTransformMatrix,
            );
            if (caster != null) nextShadowCasters.add(caster);
          }
          if (placement.active) nextModelComponents.addAll(chunk.models);
          if (placement.active) preparedPlans = null;
          continue;
        }
        final placementPlans = placement.active ? preparedPlans : null;
        preparedPlans = null;
        final materialized = await materializePlacement(
          placement: placement, snapshot: snapshot, map: map, scene: scene,
          signature: signature, cellOrigins: cellOrigins,
          receiveShadows: receiveShadows, ticket: ticket,
          preparedPlans: placementPlans,
        );
        if (materialized == null) return false;
        final chunk = materialized.chunk;
        nextChunks[mapId] = chunk;
        groups[mapId] = chunk.components;
        if (chunk.ground case final ground?) nextGrounds.add(ground);
        nextShadowCasters.addAll(materialized.casters);
        nextPointLights.addAll(materialized.lights);
        for (final entry in chunk.models.entries) {
          nextAnimationModels[(mapId, entry.key)] = entry.value.component;
        }
        if (placement.active) nextModelComponents.addAll(chunk.models);
      }
      if (ticket != generation || closed) return false;
      final nextCellOverlays = buildCellOverlays(snapshot);
      groups[(#overlays,)] = nextCellOverlays;
      final nextAuthoredLighting = spatialAuthoredShadowLighting(
        nextShadowCasters,
        receiverMinY: receiverMinimumY,
        receiverMaxY: receiverMaximumY,
      );
      final accepted = await sceneComponents.replaceGroups(
        groups,
        isCurrent: () => ticket == generation && !closed,
        onCommit: () {
          for (final entry in actorSelections.entries) {
            actors[entry.key]?.mesh.removeAll(entry.value);
          }
          actorSelections.clear();
          grounds = [...nextGrounds, for (final chunk in decorationChunks.values) if (chunk.ground case final ground?) ground];
          sceneChunks = nextChunks;
          _decorationReceiversEnabled = receiveShadows;
          _visibilityRetainedGroundImages.clear();
          _pruneGroundTextures();
          final modelIds = {
            ...activeModelIds,
            for (final component in decorationAnimationModels.values) component.definition.sourceAssetId,
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
          _sceneModelAssetIds = Set.unmodifiable(activeModelIds);
          runtimeModelIndex = SpatialRuntimeModelIndex(nextRuntimeScenes);
          renderedConfiguration = snapshot;
          _commitModelSourceRevisions(snapshot);
          _indexModelSourceDependents();
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
      if (accepted) {
        await syncDecorations();
        _invalidatedModelChunks.clear();
      }
      return accepted;
    } on Object {
      if (ticket != generation || closed) return false;
      if (identical(renderedConfiguration, snapshot)) rethrow;
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
      offset: configuration.sceneOffset + (configuration.authoringTarget?.offset ?? Offset.zero),
    );
  }

  Map<String, _ScenePlacedModel> _editingModels(SpatialSceneView configuration) {
    final key = configuration.authoringTarget?.decorationKey;
    if (key != null) return decorationChunks[key]?.models ?? const {};
    return configuration.resolveAuthoringTarget == null ? modelComponents : const {};
  }

  final Map<String, List<MeshComponent>> modelSelections = {};

  void syncContentSelection(SpatialSceneView? before, SpatialSceneView after) {
    if (before?.selectedContent?.kind == after.selectedContent?.kind &&
        before?.selectedContent?.id == after.selectedContent?.id &&
        before?.selectionColor == after.selectionColor && before?.authoringTarget?.decorationKey == after.authoringTarget?.decorationKey) {
      return;
    }
    final oldId = before?.selectedContent?.kind == SpatialSceneContentKind.model
        ? before?.selectedContent?.id
        : null;
    if (oldId != null) {
      final previous = modelSelections.remove(oldId);
      if (previous != null) {
        for (final component in previous) { component.removeFromParent(); }
      }
    }
    if (before?.selectedContent?.kind == SpatialSceneContentKind.actor) {
      final actorId = before!.selectedContent!.id;
      final previous = actorSelections.remove(actorId);
      if (previous != null) actors[actorId]?.mesh.removeAll(previous);
    }
    if (after.selectedContent?.kind != SpatialSceneContentKind.model) return;
    final id = after.selectedContent!.id;
    final component = _editingModels(after)[id]?.component;
    if (component == null || !component.sourceGeometryVisible) return;
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
    for (final entry in _editingModels(visibleConfiguration).entries) {
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
      configuration.authoringTarget?.map.spatialScene ?? configuration.scene,
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
          configuration.sceneOffset.dx + (configuration.authoringTarget?.offset.dx ?? 0),
          0,
          configuration.sceneOffset.dy + (configuration.authoringTarget?.offset.dy ?? 0),
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
    for (final entry in _editingModels(configuration).entries) {
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
    if (configuration.renderPreparationPaused?.call() == true) return;
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
    final maximumHeight = _cameraHeightCache.maximumHeight(
      scene.heightLevels,
      scene.levelHeight,
    );
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
    for (final decoration in configuration.decorations) {
      final bounds = decoration.decoration.outerBounds;
      final offset = configuration.sceneOffset + decoration.offset;
      final extent = [offset.dx + bounds.x, offset.dy + bounds.z, offset.dx + bounds.right, offset.dy + bounds.bottom].map((value) => value.abs()).reduce(math.max);
      (camera as AdaptiveCamera3D).sceneRadius = math.max((camera as AdaptiveCamera3D).sceneRadius, extent);
    }
    final cameraProfile = control.effectiveCamera(scene.camera);
    var pitch = control.pitch;
    var yaw = control.yaw;
    camera.projection = CameraProjection.perspective;
    camera.fovY = 40;
    final aspect = size.y > 0 ? size.x / size.y : 1.0;
    final adaptiveFraming =
        configuration.adaptivePlaybackFraming &&
        control.view == SpatialEditorView.game;
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
        adaptivePlaybackFraming: adaptiveFraming,
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
          !adaptiveFraming &&
              control.lockVerticalFraming &&
              control.view == SpatialEditorView.game
          ? distance * math.min(1.0, aspect)
          : distance,
      viewportAspectRatio: adaptiveFraming ? 1 : aspect,
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
    final renderPreparationPaused =
        visibleConfiguration.renderPreparationPaused?.call() == true;
    if (!refreshing && grounds.isNotEmpty) {
      if (dt.isFinite &&
          dt > 0 &&
          grounds.any((ground) => ground.plan.animated)) {
        groundElapsed += dt;
      }
    }
    if (!renderPreparationPaused && !refreshing && grounds.isNotEmpty) {
      _requestGroundAnimationTextures((groundElapsed * 1000).round());
      for (final ground in grounds.where((ground) => ground.plan.animated)) {
        final previous = ground.components;
        if (ground.resolve(
          (groundElapsed * 1000).round(),
          animationElapsedMsForCell:
              decorationChunks.containsKey(ground.mapId) ? null : visibleConfiguration.rasterAnimationElapsedMsForCell,
        )) {
          final retained = ground.components.toSet();
          final previousSet = previous.toSet();
          final removed = previous
              .where((component) => !retained.contains(component))
              .toList();
          final added = ground.components
              .where((component) => !previousSet.contains(component))
              .toList();
          final batches = decorationChunks.containsKey(ground.mapId) ? decorationSceneComponents : sceneComponents;
          batches.replaceSubset(removed, added, groupKey: ground.mapId);
          final chunk = sceneChunks[ground.mapId] ?? decorationChunks[ground.mapId];
          chunk?.components.removeWhere(removed.contains);
          chunk?.components.addAll(added);
        }
      }
    }
    if (renderPreparationPaused) {
      visibleConfiguration.actorFrames?.call(dt);
    } else {
      syncActors(dt);
      syncActorOcclusions();
      if (!refreshing) _pruneGroundTextures(sample: false);
    }
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
    if (renderPreparationPaused) return;
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
    if (component == null || !component.presentationVisible || !component.sourceGeometryVisible) return null;
    final local = source.position;
    final point = component.worldTransformMatrix.transform3(
      Vector3(local.x, local.y, local.z),
    );
    return Model3dVector3(x: point.x, y: point.y, z: point.z);
  }

  void syncRuntimeModels() {
    final provider = visibleConfiguration.modelRuntimeState;
    var movedCaster = false;
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
      if (component.runtimeTransform.apply(component.position, instance, state)) {
        final caster = _runtimeShadowCasters[component.shadowId];
        if (caster != null) {
          caster.updateWorldTransform(component.worldTransformMatrix);
          movedCaster = true;
        }
      }
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
    if (movedCaster) _refreshVisibilityLighting();
    for (final component in decorationAnimationModels.values) {
      component.playback.paused = (visibleConfiguration.presentationPaused?.call() ?? false) ||
          (visibleConfiguration.animationPreview?.isPaused(component.instanceId) ?? false);
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
    actorLandingDust.sync(
      _actorsVisibilityFiltered
          ? {
              for (final entry in frames.entries)
                if ((configuration.visibility ?? SpatialSceneVisibility.all)
                    .contentVisible(SpatialSceneContentKind.actor, entry.key))
                  entry.key: entry.value,
            }
          : frames,
      mapId: configuration.groundMap?.id ?? '__scene__',
      dt: dt,
      paused: configuration.presentationPaused?.call() ?? false,
      sceneOffset: configuration.sceneOffset,
      cameraPitch: billboardPitch,
      cameraYaw: billboardYaw,
      topView: configuration.controller.view == SpatialEditorView.top,
    );
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
      final callback = decorationChunks.containsKey(ground.mapId) ? null : configuration.actorOcclusionStateForCell;
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
      final batches = decorationChunks.containsKey(ground.mapId) ? decorationSceneComponents : sceneComponents;
      batches.replaceSubset(
        changes.removed,
        changes.added,
        groupKey: ground.mapId,
      );
      final chunk = sceneChunks[ground.mapId] ?? decorationChunks[ground.mapId];
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
    if (visibleConfiguration.resolveAuthoringTarget != null) return null;
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
    final target = _pickedAuthoringTarget ?? configuration.authoringTarget;
    if (configuration.resolveAuthoringTarget != null && target == null) return null;
    final editingOffset = configuration.sceneOffset + (target?.offset ?? Offset.zero);
    for (final instance in (target?.map.spatialScene ?? configuration.scene).instances) {
      final component = target?.decorationKey == null
          ? modelComponents[instance.id]?.component
          : decorationChunks[target!.decorationKey]?.models[instance.id]?.component;
      if (component?.sourceGeometryVisible == false) continue;
      if (target == null && !_modelVisible(
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
                editingOffset.dx +
                dx * math.cos(angle) +
                dz * math.sin(angle);
            final worldZ =
                instance.position.z +
                editingOffset.dy -
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

  (Vector3, Vector3)? _editingPointerRay(Offset offset) {
    final ray = pointerRay(offset);
    final target = _pickedAuthoringTarget ?? visibleConfiguration.authoringTarget;
    return ray == null || target == null ? ray : (ray.$1 - Vector3(target.offset.dx, 0, target.offset.dy), ray.$2);
  }

  double? contentHeight(SpatialSceneContentHit hit, Offset offset) {
    final ray = _editingPointerRay(offset);
    return ray == null
        ? null
        : spatialContentDragHeight(ray.$1, ray.$2, hit.cell);
  }

  (int, int)? pickPlaneCell(Offset offset, double height) {
    final ray = _editingPointerRay(offset);
    return ray == null ? null : pickSpatialPlaneCell(ray.$1, ray.$2, height);
  }

  (int, int)? pickCell(Offset offset) => pickSurface(offset)?.cell;

  SpatialSceneAuthoringTarget? _pickedAuthoringTarget;

  SpatialSurfaceHit? pickSurface(Offset offset) {
    final ray = pointerRay(offset, allowStableSurface: true);
    if (ray == null) return null;
    final resolve = configuration.resolveAuthoringTarget;
    if (resolve != null) {
      var cell = pickSpatialPlaneCell(ray.$1, ray.$2, 0);
      var nearest = double.infinity;
      for (final projection in _decorationProjections.values) {
        if (!projection.renderTerrainBase || projection.source.ownerMapId != configuration.groundMap?.id) continue;
        final localOffset = projection.offset - visibleConfiguration.sceneOffset;
        final hit = pickSpatialAuthoringSurface(SpatialSceneAuthoringTarget(map: projection.map, offset: localOffset), ray.$1, ray.$2);
        if (hit == null || projection.excludedCells.contains(hit.cell)) continue;
        final point = Vector3(hit.position.x + localOffset.dx, hit.position.y, hit.position.z + localOffset.dy);
        final distance = (point - ray.$1).dot(ray.$2) / ray.$2.length2;
        if (distance < 0 || distance >= nearest) continue;
        nearest = distance;
        cell = (point.x.floor(), point.z.floor());
      }
      _pickedAuthoringTarget = cell == null ? null : resolve(cell.$1, cell.$2);
      final target = _pickedAuthoringTarget;
      return target == null ? null : pickSpatialAuthoringSurface(target, ray.$1, ray.$2);
    }
    _pickedAuthoringTarget = null;
    return pickSpatialSurface(visibleConfiguration.scene, ray.$1, ray.$2);
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
    _modelSourceUpdates?.removeListener(_modelSourceUpdateListener);
    _modelSourceUpdates = null;
    _pendingVisualOrder?.complete(false);
    _pendingVisualOrder = null;
    generation++;
    atmosphereEffects.clear();
    weatherEffects.clear();
    presentationEffects.clear();
    flameEffects.clear();
    configuration.controller.flameSoundGain = 0;
    sceneComponents.dispose();
    decorationSceneComponents.dispose();
    decorationChunks.clear();
    _decorationProjections.clear();
    decorationAnimationModels.clear();
    _decorationGeneration++;
    placementRenderer.dispose();
    configuration.controller.sceneChanges.removeListener(syncCamera);
    configuration.animationPreview?.removeListener(syncAnimations);
    clearModelResourceCache();
    loadedModelSources.clear();
    _modelSourceDependents.clear();
    _modelSourceInstanceDependents.clear();
    _invalidatedModelChunks.clear();
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
    actorLandingDust.clear();
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
    this.renderTerrainBase = true,
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

  final _imageReferences = SpatialSceneGroundImageReferences();
  Set<String> get renderedImageIds => _imageReferences.resolve(
    visuals,
    cliffImageId: plan.cliff?.tilesetId,
    occlusionImageIds: renderedOcclusionImageIds,
  );
  final Color ground, edge;
  final (int, int)? selectedCell;
  bool receiveShadows;
  final bool renderTerrainBase;
  List<SpatialGroundVisual> visuals = [];
  List<MeshComponent> components = [];
  List<MeshComponent> underlays = [];
  bool initialized = false;
  int _debugVisualComparisons = 0;
  @visibleForTesting
  int get debugVisualComparisons => _debugVisualComparisons;
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
    buildSteps: (visuals) sync* {
      for (final mesh in spatialGroundMeshSteps(
        visuals,
        textures,
        scene: plan.scene,
        excludedCellsFor: plan.excludedCellsFor,
        flatSurfaceFor: plan.flatSurfaceFor,
        groundReplacements: plan.borderGroundReplacements,
      )) {
        yield mesh == null
            ? null
            : MeshComponent(
                mesh: mesh,
                position: Vector3(offset.dx, 0, offset.dy),
              );
      }
    },
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
  }) => _resolveSteps(
    elapsedMs,
    forceGeometry: forceGeometry,
    animationElapsedMsForCell: animationElapsedMsForCell,
    stepwise: false,
  ).nonNulls.single;

  Future<bool?> resolveCooperatively(
    int elapsedMs, {
    int Function(
      String mapId,
      String layerId,
      int cellX,
      int cellY,
      int elapsedMs,
    )?
    animationElapsedMsForCell,
    required SpatialCooperativeBudget budget,
    required bool Function() isCurrent,
  }) async {
    final results = await spatialCollectSteps(
      _resolveSteps(
        elapsedMs,
        forceGeometry: false,
        animationElapsedMsForCell: animationElapsedMsForCell,
        stepwise: true,
      ),
      budget: budget,
      isCurrent: isCurrent,
    );
    return results?.single;
  }

  Iterable<bool?> _resolveSteps(
    int elapsedMs, {
    required bool forceGeometry,
    required int Function(
      String mapId,
      String layerId,
      int cellX,
      int cellY,
      int elapsedMs,
    )?
    animationElapsedMsForCell,
    required bool stepwise,
  }) sync* {
    if (_sampledElapsed != elapsedMs) sampleTextureWindow(elapsedMs);
    if (currentImageIds.any((id) => !textures.containsKey(id))) {
      yield false;
      return;
    }
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
    if (!forceGeometry && initialized && identical(next, visuals)) {
      yield false;
      return;
    }
    var changed =
        forceGeometry || !initialized || next.length != visuals.length;
    var geometryChanged = changed;
    for (var index = 0; !geometryChanged && index < next.length; index++) {
      assert(() {
        _debugVisualComparisons++;
        return true;
      }());
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
    if (!changed) {
      yield false;
      return;
    }
    initialized = true;
    visuals = next;
    if (geometryChanged) {
      final nextUnderlays = <MeshComponent>[];
      if (renderTerrainBase) {
        final painted = plan.paintedCellsFor(visuals);
        SpatialGroundUnderlayIndex? supports;
        if (painted != null) {
          for (final step in plan.underlaySupportSteps(visuals)) {
            if (step != null) supports = step;
            if (stepwise) yield null;
          }
        }
        for (final mesh in terrainMeshSteps(
          plan.scene!,
          ground,
          edge,
          selectedCell: selectedCell,
          paintedCells: painted,
          excludedCells: plan.excludedCells,
          replacedGroundCells: plan.groundReplacementCells,
          borderGroundReplacements: plan.borderGroundReplacements,
          bridgeCells: plan.bridgeCells,
          underlaySupports: supports,
          includeCliffs: false,
          receiveShadows: receiveShadows,
        )) {
          if (mesh != null) {
            nextUnderlays.add(
              MeshComponent(
                mesh: mesh,
                position: Vector3(offset.dx, 0, offset.dy),
              ),
            );
          }
          if (stepwise) yield null;
        }
      }
      underlays = nextUnderlays;
    }
    if (stepwise) {
      for (final _ in _meshBatches.resolveSteps(
        visuals,
        invalidateGeometry: geometryChanged,
      )) {
        yield null;
      }
    } else {
      _meshBatches.resolve(visuals, invalidateGeometry: geometryChanged);
    }
    components = [..._meshBatches.components, ...underlays];
    yield true;
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
    required Model3dVector3 initialAnchor,
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
    runtimeTransform = SpatialRuntimeModelTransform(position: position, anchor: initialAnchor);
  }
  Model3dBounds visibleBounds;
  ProjectModel3dEntry definition;
  final String instanceId;
  late final SpatialRuntimeModelTransform runtimeTransform;
  double get initialAnchorY => runtimeTransform.initialAnchorY;
  double get initialPositionY => runtimeTransform.initialPositionY;
  set initialPositionY(double value) => runtimeTransform.initialPositionY = value;
  final String shadowId;
  bool presentationVisible = true;

  @override
  void draw(RenderContext3D context) {
    if (!presentationVisible || !sourceGeometryVisible) return;
    if (context is! SpatialRenderContext) {
      super.draw(context);
      return;
    }
    final previous = context.sourceInstanceId;
    final previousShadow = context.sourceShadowId;
    final previousOwner = context.sourceModelOwner;
    context.sourceInstanceId = instanceId;
    context.sourceShadowId = shadowId;
    context.sourceModelOwner = this;
    try {
      super.draw(context);
    } finally {
      context.sourceInstanceId = previous;
      context.sourceShadowId = previousShadow;
      context.sourceModelOwner = previousOwner;
    }
  }

  bool sourceGeometryVisible = true;

  @override
  bool isVisible(CameraComponent3D camera) => presentationVisible && sourceGeometryVisible;
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
  Set<(int, int)> excludedCells = const {},
  double? Function(double, double)? adjacentHeightAt,
}) => terrainMeshSteps(
  scene,
  ground,
  edge,
  selectedCell: selectedCell,
  paintedCells: paintedCells,
  underlaySupports: underlaySupports,
  replacedGroundCells: replacedGroundCells,
  borderGroundReplacements: borderGroundReplacements,
  bridgeCells: bridgeCells,
  includeGround: includeGround,
  includeCliffs: includeCliffs,
  receiveShadows: receiveShadows,
  cliffTexture: cliffTexture,
  excludedCells: excludedCells,
  adjacentHeightAt: adjacentHeightAt,
).nonNulls;

Iterable<Mesh?> terrainMeshSteps(
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
  Set<(int, int)> excludedCells = const {},
  double? Function(double, double)? adjacentHeightAt,
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
        excludedCells: excludedCells,
        adjacentHeightAt: adjacentHeightAt,
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
    yield null;
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
      !mapEquals(before.modelSourceRevisions, after.modelSourceRevisions) ||
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
