import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/application/map_workspace_controller.dart';
import '../../map_workspace/domain/map_atmosphere_port.dart';
import '../../project_visuals/application/project_visuals_controller.dart';
import 'project_settings_session_controller.dart';

class ProjectSettingsPreviewController extends ChangeNotifier {
  ProjectSettingsPreviewController({
    required this.workspace,
    required this.owner,
    required this.session,
  }) {
    final maps = workspace.project?.maps ?? <ProjectMapEntry>[];
    preview =
        maps
            .where((entry) => entry.id == workspace.active?.base.mapId)
            .firstOrNull ??
        maps.firstOrNull;
    _mapScopeRequested = session.scopeMapId != null;
    session.addListener(refresh);
    owner.addListener(refresh);
  }

  final MapWorkspaceController workspace;
  final ProjectVisualsController owner;
  final ProjectSettingsSessionController session;
  final rendered = ValueNotifier(SpatialVisualPatch());
  SpatialVisualPatch base = SpatialVisualPatch.fromScene(
    camera: SpatialCameraProfile(),
    atmosphere: SpatialAtmosphereSettings(),
  );
  ProjectMapEntry? preview;
  ProjectVisualsController? mapDraft;
  SpatialVisualPatch local = SpatialVisualPatch();
  bool previewLoading = false, previewSpatial = false, showSaved = false;
  String? previewProblem, scopeNotice, testError;
  int _generation = 0;
  bool _disposed = false;
  bool _mapScopeRequested = false;
  (String?, String)? _applied;

  Future<void> start() async {
    if (_disposed) return;
    if ((owner.saved == null && !owner.loading) ||
        (owner.scope != null && !owner.dirty)) {
      unawaited(owner.open());
    }
    if (preview case final entry?) await loadPreview(entry);
    refresh();
  }

  void refresh() {
    if (_disposed) return;
    final saved = owner.saved;
    if (saved != null &&
        owner.scope == null &&
        _applied != (null, saved.revision)) {
      _applied = (null, saved.revision);
      workspace.acceptVisualProfile(saved.profile);
    }
    rendered.value = showSaved
        ? base
              .overriddenBy(owner.saved?.profile ?? owner.preview.value)
              .overriddenBy(mapDraft?.saved?.profile ?? local)
        : base
              .overriddenBy(owner.preview.value)
              .overriddenBy(mapDraft?.preview.value ?? local);
    notifyListeners();
  }

  void _watchMapDraft(ProjectVisualsController? next) {
    if (identical(next, mapDraft)) return;
    mapDraft?.removeListener(refresh);
    mapDraft = next;
    mapDraft?.addListener(refresh);
  }

  Future<void> loadPreview(ProjectMapEntry entry) async {
    if (_disposed) return;
    preview = entry;
    final generation = ++_generation;
    previewLoading = true;
    _mapScopeRequested = _mapScopeRequested || session.scopeMapId != null;
    previewSpatial = false;
    base = SpatialVisualPatch.fromScene(
      camera: SpatialCameraProfile(),
      atmosphere: SpatialAtmosphereSettings(),
    );
    local = SpatialVisualPatch();
    _watchMapDraft(null);
    session.scopeTo(null);
    previewProblem = null;
    testError = null;
    notifyListeners();
    bool current() => !_disposed && generation == _generation;
    try {
      await workspace.activate(entry, isCurrent: current);
      if (!current()) return;
      if (workspace.active?.base.mapId != entry.id) {
        throw StateError(
          workspace.error ?? 'La carte d’aperçu est indisponible.',
        );
      }
      final document = workspace.documents[entry.id];
      final scene = document?.current.spatialScene;
      if (document == null || scene == null) {
        base = SpatialVisualPatch.fromScene(
          camera: SpatialCameraProfile(),
          atmosphere: SpatialAtmosphereSettings(),
        );
        previewSpatial = false;
        local = SpatialVisualPatch();
        _watchMapDraft(null);
        previewProblem =
            'La carte « ${entry.name} » n’a pas de rendu 3D : l’aperçu en jeu est indisponible. Les réglages du projet restent modifiables.';
      } else {
        final source = workspace.port;
        final atmosphere =
            document.atmosphere?.current ??
            (source is MapAtmospherePort
                ? (await (source as MapAtmospherePort).loadAtmosphere(
                    workspace.session,
                    entry.id,
                  )).settings
                : SpatialAtmosphereSettings());
        if (!current()) return;
        final existing = document.weatherVisuals;
        final saved =
            existing?.saved?.profile ??
            (await owner.port.loadVisuals(
              workspace.session,
              map: entry,
            )).profile;
        if (!current()) return;
        base = SpatialVisualPatch.fromScene(
          camera: scene.camera,
          atmosphere: atmosphere,
          cycle: scene.dayNightCycle,
        );
        previewSpatial = true;
        local = saved;
        _watchMapDraft(existing);
      }
      if (_mapScopeRequested) {
        if (!previewSpatial) {
          _mapScopeRequested = false;
          session.scopeTo(null);
          scopeNotice =
              'La portée est revenue à « Tout le projet » : la carte « ${entry.name} » n’a pas de réglages 3D locaux. Les brouillons restent conservés.';
        } else {
          session.scopeTo(entry.id);
          _watchMapDraft(document?.weatherVisuals);
        }
      }
    } on Object catch (failure) {
      if (current()) {
        previewProblem = '$failure';
        _mapScopeRequested = false;
        session.scopeTo(null);
        scopeNotice = 'La portée est revenue à « Tout le projet » : l’aperçu de cette carte est indisponible. Les brouillons restent conservés.';
      }
    } finally {
      if (current()) {
        previewLoading = false;
        refresh();
      }
    }
  }

  Future<void> choosePreview(String id) async {
    if (_disposed) return;
    final entry = workspace.project?.maps
        .where((entry) => entry.id == id)
        .firstOrNull;
    if (entry == null || entry.id == preview?.id) return;
    preview = entry;
    scopeNotice = null;
    await loadPreview(entry);
  }

  void chooseScope(String value) {
    if (_disposed || previewLoading) return;
    scopeNotice = null;
    final id = value == 'map' && previewSpatial ? preview?.id : null;
    _mapScopeRequested = id != null;
    session.scopeTo(id);
    if (id != null) _watchMapDraft(workspace.documents[id]?.weatherVisuals);
    refresh();
  }

  void compareSaved(bool value) {
    if (_disposed) return;
    showSaved = value;
    refresh();
  }

  ({ProjectMapEntry entry, String revision})? preparePlaytest() {
    if (_disposed ||
        previewLoading ||
        !previewSpatial ||
        previewProblem != null) {
      return null;
    }
    final entry = preview;
    final active = workspace.active;
    if (entry == null || active == null || active.base.mapId != entry.id) {
      return null;
    }
    if (active.dirty) {
      testError = 'Enregistrez d’abord les modifications de la carte dans l’éditeur. Les réglages restent en aperçu.';
      notifyListeners();
      return null;
    }
    testError = null;
    return (entry: entry, revision: active.base.revision);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    session.removeListener(refresh);
    owner.removeListener(refresh);
    mapDraft?.removeListener(refresh);
    rendered.dispose();
    super.dispose();
  }
}
