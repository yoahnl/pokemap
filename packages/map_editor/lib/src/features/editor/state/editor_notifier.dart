import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart';
import '../../../application/use_cases/environment_generator_apply_use_cases.dart';
import '../../../application/use_cases/environment_generator_clear_use_cases.dart';
import '../../../application/use_cases/environment_generator_regenerate_use_cases.dart';
import '../../../application/use_cases/environment_generator_use_cases.dart';
import '../../../application/use_cases/environment_mask_use_cases.dart';
import '../../../application/use_cases/layer_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_area_management_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_area_settings_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_attachment_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_clear_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_generation_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_regenerate_use_cases.dart';
import '../../../application/models/trainer_field_update.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/environment_mask_paint_target_resolver.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';
import 'environment_generated_placement_add_element_provider.dart';
import 'environment_mask_brush_size_provider.dart';
import '../../surface_painter/surface_painting_controller.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const String _eventBuilderConditionLockedMessage =
    'Cette condition contient une partie avancée préservée. '
    'Elle ne peut pas être éditée partiellement.';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  SurfacePaintingController get _surfacePaintingController =>
      const SurfacePaintingController();
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Projet "$name" créé avec succès',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de créer le projet : $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Projet « ${manifest.name} » chargé',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(
            errorMessage: 'Impossible de charger le projet : $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (kIsWeb || !Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (kIsWeb || !Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (kIsWeb || !Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  /// Remplace le manifest projet en mémoire (aucune écriture disque).
  ///
  /// Lot Environment-16 : [statusMessage] optionnel pour feedback shell ;
  /// [errorMessage] est effacé sur succès pour éviter un message obsolète.
  void applyInMemoryProjectManifest(
    ProjectManifest manifest, {
    String? statusMessage,
  }) {
    state = statusMessage == null
        ? state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
          )
        : state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
            statusMessage: statusMessage,
          );
  }

  ProjectManifest? ensureDefaultShadowProfiles() {
    final project = state.project;
    if (project == null) return null;
    final updated = ensureDefaultGroundStaticShadowProfilesForProject(project);
    if (updated == project) {
      return project;
    }
    applyInMemoryProjectManifest(
      updated,
      statusMessage: 'Profils Shadow par défaut ajoutés',
    );
    return updated;
  }

  Future<void> applyElementAutoShadowSuggestions() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to update element shadows.',
      );
      return;
    }
    try {
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(
        ref.read(projectRepositoryProvider),
      );
      final result = await useCase.execute(fs, project);
      if (!result.hasChanges) {
        state = state.copyWith(
          statusMessage: 'Aucune ombre automatique à appliquer.',
          errorMessage: null,
        );
        return;
      }
      final appliedCount = result.appliedCount;
      final clearedCount = result.clearedCount;
      state = state.copyWith(
        project: result.project,
        statusMessage:
            'Ombres automatiques mises à jour : $appliedCount appliquée(s), $clearedCount retirée(s).',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to apply automatic element shadows: $e',
      );
    }
  }

  Future<bool> saveProjectManifest() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to save.',
      );
      return false;
    }
    debugPrint('EditorNotifier: saveProjectManifest()');
    try {
      await ref.read(projectRepositoryProvider).saveProject(
            project,
            fs.projectManifestPath,
          );
      state = state.copyWith(
        isProjectDirty: false,
        statusMessage: 'Projet sauvegardé via le flux projet existant.',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving project manifest: $e');
      state = state.copyWith(
        errorMessage: 'Failed to save project: $e',
      );
      return false;
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Carte « ${map.id} » enregistrée',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Impossible d’enregistrer la carte : $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Carte « $id » créée avec succès',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Impossible de créer la carte : $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Carte « ${map.id} » chargée',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de charger la carte : $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage:
              'La carte « ${map.id} » est déjà de taille ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Carte « ${map.id} » redimensionnée en ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(
          errorMessage: 'Impossible de redimensionner la carte : $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Carte renommée en « $newId »',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de renommer la carte : $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Carte « $mapId » supprimée',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de supprimer la carte : $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Carte « $sourceId » dupliquée',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de dupliquer la carte : $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
    TilesetTransparentColor? transparentColor,
    bool clearTransparentColor = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
        transparentColor: transparentColor,
        clearTransparentColor: clearTransparentColor,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectSurfacePreset> getSurfacePresets() {
    return state.project?.surfaceCatalog.presets ?? const [];
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectSurfacePreset? getSurfacePresetById(String? presetId) {
    final normalizedPresetId = presetId?.trim();
    if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
      return null;
    }
    final project = state.project;
    if (project == null) return null;
    return project.surfaceCatalog.presetById(normalizedPresetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  ProjectSurfacePreset? getSelectedSurfacePreset() {
    return getSurfacePresetById(state.selectedSurfacePresetId);
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  void selectPokemonCatalogSection(PokemonCatalogSection section) {
    state = _editorWorkspaceController.selectPokemonCatalogSection(
      state,
      section,
    );
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Aperçu" du Narrative Studio.
  ///
  /// Navigation pure de shell : les données affichées sont dérivées par le
  /// read model overview, pas recalculées dans le notifier.
  void selectNarrativeOverviewWorkspace() {
    state = _editorWorkspaceController.selectNarrativeOverviewWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le shell central "Scènes" sans mutation narrative.
  void selectScenesWorkspace() {
    state = _editorWorkspaceController.selectScenesWorkspace(state);
  }

  /// Ouvre le shell central "Événements" sans mutation narrative.
  void selectEventsWorkspace() {
    state = _editorWorkspaceController.selectEventsWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Bascule vers le manager Facts.
  void selectFactsWorkspace() {
    state = _editorWorkspaceController.selectFactsWorkspace(state);
  }

  /// Bascule vers le manager des règles du monde.
  void selectWorldRulesWorkspace() {
    state = _editorWorkspaceController.selectWorldRulesWorkspace(state);
  }

  /// Bascule vers Path Studio.
  ///
  /// Navigation pure de shell : aucune mutation de manifest, aucune génération
  /// de preview et aucun save flow ne sont déclenchés par ce point d'entrée.
  void selectPathStudioWorkspace() {
    state = _editorWorkspaceController.selectPathStudioWorkspace(state);
  }

  /// Bascule vers Environment Studio.
  void selectEnvironmentStudioWorkspace() {
    state = _editorWorkspaceController.selectEnvironmentStudioWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'Aucun tileset sélectionné');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    ProjectElementShadowConfig? shadow,
    bool clearShadow = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        shadow: shadow,
        clearShadow: clearShadow,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'Aucun projet chargé');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Chemin de tileset introuvable');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void paintSurfaceAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      _setPaintError('No active map selected');
      return;
    }
    final selectedPreset = getSelectedSurfacePreset();
    if (selectedPreset == null) {
      _setPaintError('Select a surface before painting');
      return;
    }

    try {
      final result = _surfacePaintingController.paint(
        map: map,
        targetLayerId: state.activeLayerId,
        surfacePresetId: selectedPreset.id,
        pos: pos,
      );
      if (!result.changed) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface painted: ${selectedPreset.name}',
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint surface: $e');
    }
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is SurfaceLayer) {
      try {
        final erased = _surfacePaintingController.erase(
          map: map,
          targetLayerId: layerId,
          pos: pos,
        );
        if (!erased.changed) {
          state = state.copyWith(errorMessage: null);
          return;
        }
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased.map,
          preferredActiveLayerId: erased.layerId,
          statusMessage: 'Surface placement erased',
          partOfStroke: true,
        );
      } catch (e) {
        _setPaintError('Failed to erase surface: $e');
      }
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  MapEventDefinition? createEventBuilderDraftEventAt({
    required EventPosition position,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour créer un brouillon d’événement.',
      );
      return null;
    }
    final layerId = position.layerId.trim();
    if (layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Couche de destination obligatoire pour l’événement.',
      );
      return null;
    }
    final layer = _findLayerById(map, layerId);
    if (layer == null) {
      state = state.copyWith(
        errorMessage:
            'Couche de destination introuvable pour l’événement : $layerId',
      );
      return null;
    }
    if (layer is! ObjectLayer) {
      state = state.copyWith(
        errorMessage: 'La couche de destination doit être une couche d’objets.',
      );
      return null;
    }

    try {
      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Nouvel événement',
        position: position,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: result.createdEvent.id,
        statusMessage: 'Brouillon d’événement créé',
      );
      return result.createdEvent;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer le brouillon d’événement : $e',
      );
      return null;
    }
  }

  bool renameEventBuilderEventTitle({
    required String eventId,
    required String title,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour renommer l’événement.',
      );
      return false;
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: 'Titre d’événement obligatoire.');
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.title.trim() == trimmedTitle) {
      return true;
    }

    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        title: trimmedTitle,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Événement renommé',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de renommer l’événement : $e',
      );
      return false;
    }
  }

  bool updateEventBuilderEventSceneAction({
    required String eventId,
    required String sceneId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier la scène de l’événement.',
      );
      return false;
    }
    final project = state.project;
    if (project == null) {
      state = state.copyWith(
        errorMessage: 'Aucun projet actif pour choisir une scène.',
      );
      return false;
    }
    final trimmedSceneId = sceneId.trim();
    if (trimmedSceneId.isEmpty) {
      state = state.copyWith(errorMessage: 'Scène d’événement obligatoire.');
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }
    final sceneExists =
        project.scenes.any((scene) => scene.id == trimmedSceneId);
    if (!sceneExists) {
      state = state.copyWith(
        errorMessage: 'Scène introuvable : $trimmedSceneId',
      );
      return false;
    }

    // NS-EVENT-11 reste aligné avec le read model Event Builder : on écrit
    // uniquement la page authorable canonique, sans créer de page implicite.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    try {
      final updated = setMapEventPageSceneTarget(
        map,
        eventId: eventId,
        pageNumber: pageNumber,
        sceneId: trimmedSceneId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Scène d’événement mise à jour',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de mettre à jour la scène de l’événement : $e',
      );
      return false;
    }
  }

  bool updateEventBuilderEventReusePolicy({
    required String eventId,
    required EventBuilderReusePolicy reusePolicy,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier le comportement de l’événement.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    // NS-EVENT-12 édite uniquement les metadata Event Builder de la page
    // canonique. Les champs sceneTarget/condition/script/message restent
    // volontairement sous la responsabilité des lots dédiés.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final pageIndex =
        event.pages.indexWhere((page) => page.pageNumber == pageNumber);
    final page = event.pages[pageIndex];
    final nextMetadata = Map<String, String>.unmodifiable({
      ...page.metadata,
      EventBuilderMetadataKeys.schemaVersion:
          EventBuilderMetadataKeys.currentSchemaVersion,
      EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
    });
    try {
      final updated = updatePageOnMapEvent(
        map,
        eventId: eventId,
        pageIndex: pageIndex,
        metadata: nextMetadata,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Comportement d’événement mis à jour',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de mettre à jour le comportement de l’événement : $e',
      );
      return false;
    }
  }

  bool addEventBuilderFactCondition({
    required String eventId,
    required String factId,
    required bool expectedValue,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier les conditions de l’événement.',
      );
      return false;
    }
    final project = state.project;
    if (project == null) {
      state = state.copyWith(
        errorMessage: 'Aucun projet actif pour choisir un Fact.',
      );
      return false;
    }
    final trimmedFactId = factId.trim();
    if (trimmedFactId.isEmpty) {
      state = state.copyWith(errorMessage: 'Fact obligatoire.');
      return false;
    }
    final factExists = project.facts.any((fact) => fact.id == trimmedFactId);
    if (!factExists) {
      state = state.copyWith(
        errorMessage: 'Fact introuvable : $trimmedFactId',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    // NS-EVENT-13 ne compile que Fact vrai/faux. Le contrat core garde le
    // garde-fou legacyConditionToPreserve pour empêcher toute perte silencieuse
    // de conditions avancées.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final contract = readEventBuilderContractFromMapEvent(
      event,
      pageNumber: pageNumber,
    );
    if (contract.legacyConditionToPreserve != null) {
      state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
      return false;
    }
    final condition = expectedValue
        ? EventBuilderConditionBinding.factIsTrue(trimmedFactId)
        : EventBuilderConditionBinding.factIsFalse(trimmedFactId);

    try {
      final updatedContract = addEventBuilderCondition(contract, condition);
      final updated = _updateEventBuilderPageCondition(
        map: map,
        event: event,
        pageNumber: pageNumber,
        conditions: updatedContract.conditions,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Condition d’événement ajoutée',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter la condition d’événement : $e',
      );
      return false;
    }
  }

  bool removeEventBuilderConditionAt({
    required String eventId,
    required int conditionIndex,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier les conditions de l’événement.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final contract = readEventBuilderContractFromMapEvent(
      event,
      pageNumber: pageNumber,
    );
    if (contract.legacyConditionToPreserve != null) {
      state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
      return false;
    }
    if (conditionIndex < 0 || conditionIndex >= contract.conditions.length) {
      state = state.copyWith(
        errorMessage: 'Condition introuvable : $conditionIndex',
      );
      return false;
    }
    final condition = contract.conditions[conditionIndex];
    if (!_isEventBuilderFactConditionKind(condition.kind)) {
      state = state.copyWith(
        errorMessage: 'Seules les conditions Fact sont éditables dans ce lot.',
      );
      return false;
    }

    try {
      final updatedContract =
          removeEventBuilderCondition(contract, conditionIndex);
      final updated = _updateEventBuilderPageCondition(
        map: map,
        event: event,
        pageNumber: pageNumber,
        conditions: updatedContract.conditions,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Condition d’événement retirée',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de retirer la condition d’événement : $e',
      );
      return false;
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        movementEffect: movementEffect,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  bool applyGeneratedGameplayZones({
    required List<MapGameplayZone> zones,
    String? selectZoneId,
    String? statusMessage,
  }) {
    final map = state.activeMap;
    if (map == null || zones.isEmpty) return false;
    try {
      var updatedMap = map;
      for (final zone in zones) {
        updatedMap = addGameplayZoneToMap(updatedMap, zone: zone);
      }

      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: statusMessage ??
            'Generated ${zones.length} gameplay ${zones.length == 1 ? 'zone' : 'zones'}',
      );

      final requestedSelection = selectZoneId?.trim();
      final hasRequestedSelection = requestedSelection != null &&
          requestedSelection.isNotEmpty &&
          updatedMap.gameplayZones.any(
            (zone) => zone.id == requestedSelection,
          );
      state = state.copyWith(
        selectedGameplayZoneId:
            hasRequestedSelection ? requestedSelection : zones.first.id,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to apply generated zones: $e');
      return false;
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(
          errorMessage: 'Aucun système de fichiers de projet disponible');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'Aucun projet chargé');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'Aucune carte active chargée');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'Aucun warp sélectionné');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void addSurfaceLayer({
    String name = 'Surfaces',
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.executeSurface(
        map,
        name: name,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Surface layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add surface layer: $e');
    }
  }

  /// Lot Environment-20 : [EnvironmentLayerContent.targetTileLayerId] uniquement.
  void setEnvironmentLayerTargetTileLayer({
    required String environmentLayerId,
    required String? targetTileLayerId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = SetEnvironmentLayerTargetTileLayerUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: environmentLayerId,
        targetTileLayerId: targetTileLayerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: targetTileLayerId == null
            ? 'Environment layer target tile layer cleared'
            : 'Environment layer target tile layer updated',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set environment target tile layer: $e',
      );
    }
  }

  void enableEnvironmentForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour activer l’environnement.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour activer l’environnement.',
      );
      return;
    }

    try {
      final result = EnableTileLayerEnvironmentAttachmentUseCase().execute(
        map,
        tileLayerId: layerId,
      );
      if (!result.created) {
        state = state.copyWith(
          activeLayerId: layerId,
          selectedEnvironmentAreaId: null,
          environmentMaskEditMode: null,
          statusMessage: 'L’environnement est déjà activé sur ce layer.',
          errorMessage: null,
        );
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: layerId,
        statusMessage: 'Environnement activé sur "${activeLayer.name}"',
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’activer l’environnement : $e',
      );
    }
  }

  void createEnvironmentAreaForActiveTileLayer({
    required String presetId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter une zone : aucune carte ou projet actif.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour ajouter une zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour ajouter une zone.',
      );
      return;
    }

    final pid = presetId.trim();
    if (pid.isEmpty ||
        !project.environmentPresets.any((preset) => preset.id == pid)) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter une zone : choisissez un preset valide.',
      );
      return;
    }

    try {
      final result = CreateTileLayerEnvironmentAreaUseCase().execute(
        map,
        manifest: project,
        tileLayerId: layerId,
        presetId: pid,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: layerId,
        statusMessage: 'Zone d’environnement ajoutée sur "${activeLayer.name}"',
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter une zone : $e',
      );
    }
  }

  void selectEnvironmentAreaForActiveTileLayer(String areaId) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour choisir une zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour choisir une zone.',
      );
      return;
    }

    final aid = areaId.trim();
    if (aid.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez une zone d’environnement valide.',
      );
      return;
    }

    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: aid,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }

    state = state.copyWith(
      activeLayerId: layerId,
      selectedEnvironmentAreaId: target.areaId,
      environmentMaskEditMode: null,
      statusMessage: 'Zone d’environnement sélectionnée.',
      errorMessage: null,
    );
  }

  void renameEnvironmentAreaForActiveTileLayer(String name) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour renommer une zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour renommer une zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de la renommer.',
      );
      return;
    }
    final mode = state.environmentMaskEditMode;

    try {
      final result = RenameTileLayerEnvironmentAreaUseCase().execute(
        map,
        tileLayerId: layerId,
        areaId: areaId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Zone renommée : ${result.name}.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: mode,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de renommer la zone : $e',
      );
    }
  }

  void deleteEnvironmentAreaForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour supprimer une zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour supprimer une zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de la supprimer.',
      );
      return;
    }
    final selectedPlacementId = state.selectedPlacedElementInstanceId?.trim();

    try {
      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
        map,
        tileLayerId: layerId,
        areaId: areaId,
      );
      final removedPlacementIds = result.removedPlacementIds.toSet();
      final shouldClearPlacedSelection = selectedPlacementId != null &&
          selectedPlacementId.isNotEmpty &&
          removedPlacementIds.contains(selectedPlacementId);
      ref.read(environmentGeneratedPlacementAddElementProvider.notifier).state =
          null;
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Zone supprimée.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: null,
        selectedPlacedElementInstanceId: shouldClearPlacedSelection
            ? null
            : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de supprimer la zone : $e',
      );
    }
  }

  void setEnvironmentAreaParamsOverrideForActiveTileLayer(
    EnvironmentGenerationParams params,
  ) {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage: 'Paramètres locaux de génération mis à jour.',
      update: (map, layerId, areaId) {
        return SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
          paramsOverride: params,
        );
      },
    );
  }

  void resetEnvironmentAreaParamsOverrideForActiveTileLayer() {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage:
          'Paramètres locaux réinitialisés sur les valeurs du preset.',
      update: (map, layerId, areaId) {
        return ResetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
        );
      },
    );
  }

  void setEnvironmentAreaSeedForActiveTileLayer(int seed) {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage: 'Seed de la zone d’environnement mis à jour.',
      update: (map, layerId, areaId) {
        return SetTileLayerEnvironmentAreaSeedForTileLayerUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
          seed: seed,
        );
      },
    );
  }

  String? _effectiveEnvironmentAreaIdForActiveTileLayer(
    MapData map,
    String tileLayerId,
  ) {
    final selected = state.selectedEnvironmentAreaId?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }

    EnvironmentLayer? attachedEnvironmentLayer;
    var attachedCount = 0;
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer &&
          layer.content.targetTileLayerId?.trim() == tileLayerId) {
        attachedEnvironmentLayer = layer;
        attachedCount++;
      }
    }
    if (attachedCount != 1) return null;

    final areas = attachedEnvironmentLayer!.content.areas;
    if (areas.length != 1) return null;
    return areas.single.id;
  }

  void _updateEnvironmentAreaSettingsForActiveTileLayer({
    required String statusMessage,
    required MapData Function(MapData map, String layerId, String areaId)
        update,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour modifier les paramètres de zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour modifier les paramètres de zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de modifier ses paramètres.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }
    final mode = state.environmentMaskEditMode;

    try {
      final updated = update(map, layerId, target.areaId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: statusMessage,
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: target.areaId,
        environmentMaskEditMode: mode,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de modifier les paramètres de génération : $e',
      );
    }
  }

  void generateEnvironmentAreaPlacementsForActiveTileLayer() {
    final map = state.activeMap;
    final manifest = state.project;
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez une zone d’environnement avant de générer.',
      );
      return;
    }

    try {
      final result =
          GenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
        map,
        manifest: manifest,
        tileLayerId: layerId,
        areaId: areaId,
      );
      if (result.generatedPlacementCount == 0) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: null,
          statusMessage: 'Aucun placement généré pour cette zone.',
          errorMessage: null,
        );
        return;
      }

      final count = result.generatedPlacementCount;
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage:
            '$count placement(s) généré(s) dans ce layer pour la zone « ${result.areaId} ».',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de générer cette zone : $e',
      );
    }
  }

  void clearEnvironmentGeneratedPlacementsForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’effacer : aucune carte active.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour effacer les placements générés.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour effacer les placements générés.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant d’effacer les placements générés.',
      );
      return;
    }

    try {
      final result =
          ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
        map,
        tileLayerId: layerId,
        areaId: areaId,
      );
      if (result.clearedReferenceCount == 0) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: null,
          statusMessage: 'Aucun placement généré à effacer pour cette zone.',
          errorMessage: null,
        );
        return;
      }

      final removedIds = result.removedPlacementIds.toSet();
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          removedIds.contains(selectionBefore);

      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: _clearTileLayerGeneratedPlacementsStatusMessage(result),
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’effacer les placements générés de cette zone : $e',
      );
    }
  }

  String _clearTileLayerGeneratedPlacementsStatusMessage(
    ClearTileLayerEnvironmentAreaGeneratedPlacementsResult result,
  ) {
    final removed = result.removedPlacementCount;
    final missing = result.clearedReferenceCount - removed;
    if (missing > 0) {
      return '$removed placement(s) effacé(s), $missing référence(s) '
          'introuvable(s) nettoyée(s).';
    }
    return '$removed placement(s) généré(s) effacé(s) pour la zone « ${result.areaId} ».';
  }

  void regenerateEnvironmentAreaPlacementsForActiveTileLayer() {
    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
      shuffle: false,
    );
  }

  void shuffleEnvironmentAreaPlacementsForActiveTileLayer() {
    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
      shuffle: true,
    );
  }

  void _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer({
    required bool shuffle,
  }) {
    final map = state.activeMap;
    final manifest = state.project;
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Impossible de shuffler : aucune carte active ou manifeste projet.'
            : 'Impossible de régénérer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez une zone d’environnement avant de shuffler.'
            : 'Sélectionnez une zone d’environnement avant de régénérer.',
      );
      return;
    }

    try {
      final result = shuffle
          ? ShuffleTileLayerEnvironmentAreaPlacementsUseCase().execute(
              map,
              manifest: manifest,
              tileLayerId: layerId,
              areaId: areaId,
            )
          : RegenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
              map,
              manifest: manifest,
              tileLayerId: layerId,
              areaId: areaId,
            );

      final removedIds = result.removedPlacementIds.toSet();
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          removedIds.contains(selectionBefore);

      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: _tileLayerRegenerationStatusMessage(
          result,
          shuffle: shuffle,
        ),
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Impossible de shuffler cette zone : $e'
            : 'Impossible de régénérer cette zone : $e',
      );
    }
  }

  String _tileLayerRegenerationStatusMessage(
    TileLayerEnvironmentRegenerationResult result, {
    required bool shuffle,
  }) {
    if (result.generatedPlacementCount == 0) {
      return shuffle
          ? 'Seed mélangée : aucun nouveau placement pour la zone « ${result.areaId} ».'
          : 'Les placements générés ont été effacés ; aucun nouveau placement n’a été généré pour la zone « ${result.areaId} ».';
    }
    return shuffle
        ? 'Seed mélangée : ${result.generatedPlacementCount} placement(s) régénéré(s) pour la zone « ${result.areaId} ».'
        : 'Zone « ${result.areaId} » régénérée : ${result.generatedPlacementCount} placement(s).';
  }

  void startEnvironmentMaskPaintingForActiveTileLayer() {
    _startEnvironmentMaskEditingForActiveTileLayer(
      mode: EnvironmentMaskEditMode.paint,
    );
  }

  void startEnvironmentMaskErasingForActiveTileLayer() {
    _startEnvironmentMaskEditingForActiveTileLayer(
      mode: EnvironmentMaskEditMode.erase,
    );
  }

  void _startEnvironmentMaskEditingForActiveTileLayer({
    required EnvironmentMaskEditMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez une zone d’environnement avant de peindre.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }

    state = state.copyWith(
      activeLayerId: layerId,
      selectedEnvironmentAreaId: target.areaId,
      environmentMaskEditMode: mode,
      statusMessage: mode == EnvironmentMaskEditMode.erase
          ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
          : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
      errorMessage: null,
    );
  }

  void stopEnvironmentMaskPainting() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Peinture du masque arrêtée.',
      errorMessage: null,
    );
  }

  void startDeletingGeneratedEnvironmentPlacementForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }
    if (target.area.generatedPlacementIds.isEmpty) {
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: target.areaId,
        environmentMaskEditMode: null,
        statusMessage:
            'Aucun placement généré à supprimer individuellement pour cette zone.',
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      activeLayerId: layerId,
      selectedEnvironmentAreaId: target.areaId,
      environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
      statusMessage:
          'Suppression active : cliquez un élément généré pour le retirer.',
      errorMessage: null,
    );
  }

  void stopDeletingGeneratedEnvironmentPlacement() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Suppression des éléments générés arrêtée.',
      errorMessage: null,
    );
  }

  bool deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    if (state.environmentMaskEditMode !=
        EnvironmentMaskEditMode.generatedDelete) {
      state = state.copyWith(
        errorMessage:
            'Activez la suppression d’un élément généré avant de cliquer.',
      );
      return false;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return false;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return false;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
      );
      return false;
    }

    try {
      final result =
          DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: state.project,
        tileLayerId: layerId,
        areaId: areaId,
        pos: pos,
      );
      if (!result.removed) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
          statusMessage:
              'Aucun placement généré de cette zone à supprimer ici.',
          errorMessage: null,
        );
        return false;
      }

      final removedId = result.removedPlacementId!;
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          selectionBefore == removedId;
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Placement généré supprimé.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de supprimer cet élément généré : $e',
      );
      return false;
    }
  }

  void selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
    String elementId,
  ) {
    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requestedElementId: elementId,
        requireGeneratedPlacements: false,
        allowImplicitSelection: false,
      );
      ref.read(environmentGeneratedPlacementAddElementProvider.notifier).state =
          selection.item.elementId;
      state = state.copyWith(
        activeLayerId: selection.tileLayerId,
        selectedEnvironmentAreaId: selection.areaId,
        statusMessage:
            'Élément à ajouter : ${selection.element.name.isEmpty ? selection.element.id : selection.element.name}.',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de sélectionner cet élément généré : $e',
      );
    }
  }

  void startAddingGeneratedEnvironmentPlacementForActiveTileLayer() {
    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requireGeneratedPlacements: true,
        allowImplicitSelection: true,
      );
      ref.read(environmentGeneratedPlacementAddElementProvider.notifier).state =
          selection.item.elementId;
      state = state.copyWith(
        activeLayerId: selection.tileLayerId,
        selectedEnvironmentAreaId: selection.areaId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        statusMessage:
            'Ajout actif : cliquez sur la carte pour ajouter cet élément.',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        environmentMaskEditMode: null,
        errorMessage: 'Impossible d’activer l’ajout : $e',
      );
    }
  }

  void stopAddingGeneratedEnvironmentPlacement() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Ajout des éléments générés arrêté.',
      errorMessage: null,
    );
  }

  bool addGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    if (state.environmentMaskEditMode != EnvironmentMaskEditMode.generatedAdd) {
      state = state.copyWith(
        errorMessage: 'Activez l’ajout d’un élément généré avant de cliquer.',
      );
      return false;
    }

    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requireGeneratedPlacements: true,
        allowImplicitSelection: true,
      );
      final result =
          AddTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: selection.project,
        tileLayerId: selection.tileLayerId,
        areaId: selection.areaId,
        elementId: selection.item.elementId,
        pos: pos,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Élément généré ajouté.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        errorMessage:
            'Impossible d’ajouter ici : position hors carte ou footprint invalide. $e',
      );
      return false;
    }
  }

  void setEnvironmentMaskBrushSize(int size) {
    if (!isValidEnvironmentMaskBrushSize(size)) {
      state = state.copyWith(
        errorMessage: 'taille du pinceau invalide : choisissez 1, 3, 5 ou 7.',
      );
      return;
    }
    final current = ref.read(environmentMaskBrushSizeProvider);
    if (current == size) {
      state = state.copyWith(errorMessage: null);
      return;
    }
    ref.read(environmentMaskBrushSizeProvider.notifier).state = size;
    state = state.copyWith(errorMessage: null);
  }

  /// Lot Environment-21 : ajoute une [EnvironmentArea] (mask vide, preset manifest).
  void addEnvironmentAreaToLayer({
    required String environmentLayerId,
    required String presetId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      state = state.copyWith(
        errorMessage:
            'Cannot add environment area: no active map or project manifest.',
      );
      return;
    }
    try {
      final useCase = AddEnvironmentAreaUseCase();
      final result = useCase.execute(
        map,
        manifest: project,
        environmentLayerId: environmentLayerId,
        presetId: presetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: 'Environment area added',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add environment area: $e',
      );
    }
  }

  /// Lot Environment-21 : change le preset d’une zone existante.
  void setEnvironmentAreaPreset({
    required String environmentLayerId,
    required String areaId,
    required String presetId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      state = state.copyWith(
        errorMessage:
            'Cannot set environment area preset: no active map or project manifest.',
      );
      return;
    }
    try {
      final useCase = SetEnvironmentAreaPresetUseCase();
      final updated = useCase.execute(
        map,
        manifest: project,
        environmentLayerId: environmentLayerId,
        areaId: areaId,
        presetId: presetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: 'Environment area preset updated',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set environment area preset: $e',
      );
    }
  }

  /// Lot Environment-21 : retire une [EnvironmentArea].
  void removeEnvironmentArea({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = RemoveEnvironmentAreaUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: environmentLayerId,
        areaId: areaId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: 'Environment area removed',
      );
      _coerceEnvironmentMaskSelectionAfterMapChange();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to remove environment area: $e',
      );
    }
  }

  /// Lot Environment-22 : area sélectionnée pour édition masque, sans activer paint/erase.
  void selectEnvironmentAreaForMaskEditing({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layer = _findLayerById(map, environmentLayerId);
    if (layer is! EnvironmentLayer) return;
    if (!layer.content.areas.any((a) => a.id == areaId)) return;
    state = state.copyWith(
      activeLayerId: environmentLayerId,
      selectedEnvironmentAreaId: areaId,
      errorMessage: null,
    );
  }

  /// Lot Environment-22 : active la peinture du masque pour une zone.
  void startEnvironmentAreaMaskPaint({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.paint,
    );
  }

  /// Lot Environment-22 : active l’effacement du masque pour une zone.
  void startEnvironmentAreaMaskErase({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.erase,
    );
  }

  /// Active l’ajout manuel d’un placement généré pour une zone.
  void startEnvironmentAreaGeneratedPlacementAdd({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.generatedAdd,
    );
  }

  /// Active la suppression au clic d’un placement généré pour une zone.
  void startEnvironmentAreaGeneratedPlacementDelete({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.generatedDelete,
    );
  }

  void _startEnvironmentAreaEditMode({
    required String environmentLayerId,
    required String areaId,
    required EnvironmentMaskEditMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layer = _findLayerById(map, environmentLayerId);
    if (layer is! EnvironmentLayer) return;
    if (!layer.content.areas.any((a) => a.id == areaId)) return;
    state = state.copyWith(
      activeLayerId: environmentLayerId,
      selectedEnvironmentAreaId: areaId,
      environmentMaskEditMode: mode,
      errorMessage: null,
    );
  }

  /// Lot Environment-22 : quitte le mode d’édition sans changer l’area sélectionnée.
  void stopEnvironmentAreaMaskEditing() {
    state = state.copyWith(environmentMaskEditMode: null, errorMessage: null);
  }

  /// Lot Environment-25 : génère des candidats (Lot 23) puis les applique (Lot 24).
  ///
  /// Aucune sauvegarde disque. En cas d’échec ou zéro placement : pas de mutation
  /// de [EditorState.activeMap] (sauf messages).
  void generateEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    final manifest = state.project;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layer = _findLayerById(map, envId);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : calque environnement introuvable.',
      );
      return;
    }
    EnvironmentArea? area;
    for (final a in layer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      state = state.copyWith(
        errorMessage: 'Impossible de générer : zone introuvable.',
      );
      return;
    }
    if (area.generatedPlacementIds.isNotEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Cette zone possède déjà des placements générés. Utilisez '
            '« Effacer les placements générés », « Régénérer » ou '
            '« Mélanger et régénérer ».',
      );
      return;
    }

    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (gen.hasErrors) {
      final first = gen.issues.firstWhere(
        (i) => i.severity == EnvironmentGenerationIssueSeverity.error,
        orElse: () => gen.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible de générer cette zone : ${_environmentGenerationIssueMessage(first)}',
      );
      return;
    }
    if (gen.placements.isEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré pour cette zone.',
      );
      return;
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
      candidates: gen.placements,
    );
    if (apply.hasErrors) {
      final first = apply.issues.firstWhere(
        (i) => i.severity == EnvironmentApplyIssueSeverity.error,
        orElse: () => apply.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible d’appliquer les placements : ${_environmentApplyIssueMessage(first)}',
      );
      return;
    }

    final n = apply.appliedPlacementCount;
    _applyMapMutation(
      previousMap: map,
      updatedMap: apply.map,
      preferredActiveLayerId: envId,
      statusMessage: '$n placement(s) généré(s) pour la zone « $aid ».',
    );
    state = state.copyWith(
      selectedEnvironmentAreaId: aid,
      environmentMaskEditMode: null,
    );
  }

  String _environmentGenerationIssueMessage(EnvironmentGenerationIssue issue) {
    return issue.message;
  }

  String _environmentApplyIssueMessage(EnvironmentApplyIssue issue) {
    return issue.message;
  }

  /// Lot Environment-26 : retire les [MapPlacedElement] listés dans
  /// [EnvironmentArea.generatedPlacementIds] puis vide cette liste.
  void clearEnvironmentGeneratedPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’effacer : aucune carte active.',
      );
      return;
    }
    final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
    final result = ClearEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (result.hasErrors) {
      final first = result.issues.firstWhere(
        (i) => i.severity == EnvironmentClearIssueSeverity.error,
        orElse: () => result.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible d’effacer les placements générés : ${first.message}',
      );
      return;
    }
    if (result
        .issuesForKind(EnvironmentClearIssueKind.noGeneratedPlacements)
        .isNotEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré à effacer pour cette zone.',
      );
      return;
    }

    final removedIds =
        result.clearedPlacements.map((c) => c.placedElementId).toSet();
    final clearSelection = selectionBefore != null &&
        selectionBefore.isNotEmpty &&
        removedIds.contains(selectionBefore);

    _applyMapMutation(
      previousMap: map,
      updatedMap: result.map,
      preferredActiveLayerId: envId,
      statusMessage: _clearGeneratedPlacementsStatusMessage(result, aid),
    );
    if (clearSelection) {
      state = state.copyWith(selectedPlacedElementInstanceId: null);
    }
  }

  String _clearGeneratedPlacementsStatusMessage(
    EnvironmentClearResult result,
    String areaId,
  ) {
    final n = result.clearedPlacementCount;
    final missing = result
        .issuesForKind(EnvironmentClearIssueKind.missingGeneratedPlacement)
        .length;
    if (missing > 0) {
      return '$n placement(s) effacé(s), $missing référence(s) introuvable(s) '
          'nettoyée(s).';
    }
    return '$n placement(s) généré(s) effacé(s) pour la zone « $areaId ».';
  }

  /// Lot Environment-27 : efface les placements générés, garde la seed, regénère et applique.
  void regenerateEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    _regenerateOrShuffleEnvironmentAreaPlacements(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      shuffle: false,
    );
  }

  /// Lot Environment-27 : optionnellement clear, nouvelle seed LCG, generate + apply.
  void shuffleEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    _regenerateOrShuffleEnvironmentAreaPlacements(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      shuffle: true,
    );
  }

  void _regenerateOrShuffleEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
    required bool shuffle,
  }) {
    final original = state.activeMap;
    final manifest = state.project;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (original == null || manifest == null) {
      state = state.copyWith(
        errorMessage: 'Impossible : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layer = _findLayerById(original, envId);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        errorMessage: 'Impossible : calque environnement introuvable.',
      );
      return;
    }
    EnvironmentArea? area;
    for (final a in layer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      state = state.copyWith(
        errorMessage: 'Impossible : zone introuvable.',
      );
      return;
    }

    if (!shuffle && area.generatedPlacementIds.isEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré à régénérer pour cette zone.',
      );
      return;
    }

    var working = original;
    var staged = false;

    final shouldClear = shuffle ? area.generatedPlacementIds.isNotEmpty : true;

    if (shouldClear) {
      final clearR = ClearEnvironmentGeneratedPlacementsUseCase().execute(
        working,
        environmentLayerId: envId,
        areaId: aid,
      );
      if (clearR.hasErrors) {
        final first = clearR.issues.firstWhere(
          (i) => i.severity == EnvironmentClearIssueSeverity.error,
          orElse: () => clearR.issues.first,
        );
        state = state.copyWith(
          errorMessage:
              'Impossible de ${shuffle ? 'mélanger et régénérer' : 'régénérer'} '
              'cette zone : ${first.message}',
        );
        return;
      }
      working = clearR.map;
      staged = true;
    }

    if (shuffle) {
      final layerNow = _findLayerById(working, envId);
      if (layerNow is! EnvironmentLayer) {
        state = state.copyWith(
          errorMessage:
              'Impossible de mélanger : calque environnement introuvable.',
        );
        return;
      }
      EnvironmentArea? areaNow;
      for (final a in layerNow.content.areas) {
        if (a.id == aid) {
          areaNow = a;
          break;
        }
      }
      if (areaNow == null) {
        state = state.copyWith(
          errorMessage: 'Impossible de mélanger : zone introuvable.',
        );
        return;
      }
      final nextS = nextEnvironmentAreaSeed(areaNow.seed);
      final seedRes = SetEnvironmentAreaSeedUseCase().execute(
        working,
        environmentLayerId: envId,
        areaId: aid,
        seed: nextS,
      );
      if (!seedRes.isSuccess) {
        state = state.copyWith(
          errorMessage:
              'Impossible de mélanger la seed : ${seedRes.failureMessage}',
        );
        return;
      }
      working = seedRes.map!;
      staged = true;
    }

    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
      working,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (gen.hasErrors) {
      final first = gen.issues.firstWhere(
        (i) => i.severity == EnvironmentGenerationIssueSeverity.error,
        orElse: () => gen.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible de ${shuffle ? 'mélanger et régénérer' : 'régénérer'} '
            'cette zone : ${_environmentGenerationIssueMessage(first)}',
      );
      return;
    }

    if (gen.placements.isEmpty) {
      if (!staged) {
        state = state.copyWith(
          errorMessage: null,
          statusMessage: 'Aucun placement généré pour cette zone.',
        );
        return;
      }
      _applyMapMutation(
        previousMap: original,
        updatedMap: working,
        preferredActiveLayerId: envId,
        statusMessage: shuffle
            ? 'Mélangé : seed mise à jour ; aucun nouveau placement pour la '
                'zone « $aid » (effacement des placements précédents effectué).'
            : 'Les placements générés ont été effacés ; aucun nouveau placement '
                'n’a été généré pour la zone « $aid ».',
      );
      state = state.copyWith(
        selectedEnvironmentAreaId: aid,
        environmentMaskEditMode: null,
      );
      return;
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      working,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
      candidates: gen.placements,
    );
    if (apply.hasErrors) {
      final first = apply.issues.firstWhere(
        (i) => i.severity == EnvironmentApplyIssueSeverity.error,
        orElse: () => apply.issues.first,
      );
      state = state.copyWith(
        errorMessage: 'Impossible d’appliquer après '
            '${shuffle ? 'mélange' : 'régénération'} : '
            '${_environmentApplyIssueMessage(first)}',
      );
      return;
    }

    final n = apply.appliedPlacementCount;
    final status = shuffle
        ? 'Seed mélangée : $n placement(s) régénéré(s) pour la zone « $aid ».'
        : 'Zone « $aid » régénérée : $n placement(s).';
    _applyMapMutation(
      previousMap: original,
      updatedMap: apply.map,
      preferredActiveLayerId: envId,
      statusMessage: status,
    );
    state = state.copyWith(
      selectedEnvironmentAreaId: aid,
      environmentMaskEditMode: null,
    );
  }

  /// Lot Environment-22 : applique paint ou erase selon [environmentMaskEditMode].
  void paintEnvironmentAreaMaskAt(
    GridPos pos, {
    bool partOfStroke = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId;
    final areaId = state.selectedEnvironmentAreaId;
    final mode = state.environmentMaskEditMode;
    if (layerId == null || areaId == null || mode == null) {
      return;
    }
    if (mode != EnvironmentMaskEditMode.paint &&
        mode != EnvironmentMaskEditMode.erase) {
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      return;
    }
    final isActive = mode == EnvironmentMaskEditMode.paint;
    try {
      final useCase = PaintEnvironmentAreaMaskBrushStrokeUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: target.environmentLayerId,
        areaId: target.areaId,
        center: pos,
        brushSize: ref.read(environmentMaskBrushSizeProvider),
        isActive: isActive,
      );
      if (identical(updated, map)) {
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: target.activeLayerId,
        partOfStroke: partOfStroke,
        statusMessage: 'Masque d’environnement mis à jour',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’éditer le masque d’environnement : $e',
      );
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Calque renommé',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Impossible de renommer le calque : $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Calque supprimé',
      );
      _coerceEnvironmentMaskSelectionAfterMapChange();
    } on EditorValidationException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de supprimer le calque : $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'Tous les calques supprimés',
      );
      _coerceEnvironmentMaskSelectionAfterMapChange();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de supprimer tous les calques : $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Calque réorganisé',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de réorganiser le calque : $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Calque réorganisé',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de réorganiser le calque : $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Calque affiché' : 'Calque masqué',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de mettre à jour le calque : $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage:
              'Impossible de mettre à jour l\'opacité du calque : $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectSurfacePreset(String? presetId) {
    final preset = getSurfacePresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Surface introuvable');
      return;
    }
    state = state.copyWith(
      selectedSurfacePresetId: preset.id,
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface sélectionnée : ${preset.name}',
      errorMessage: null,
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Preset de path introuvable');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  void selectSurfacePaintMode() {
    if (getSelectedSurfacePreset() == null) {
      state = state.copyWith(
          errorMessage: 'Sélectionnez une surface avant de peindre');
      return;
    }
    state = state.copyWith(
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Mode peinture de surface',
      errorMessage: null,
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Preset de terrain créé',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer le preset de terrain : $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Preset de terrain introuvable : $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Preset de terrain mis à jour',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de mettre à jour le preset de terrain : $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Preset de terrain supprimé',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de supprimer le preset de terrain : $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Preset de path créé',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de créer le preset de path : $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Preset de path introuvable : $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Preset de path mis à jour',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de mettre à jour le preset de path : $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Déclencheurs d\'animation mis à jour',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage:
              'Impossible de mettre à jour les déclencheurs d\'animation : $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Mode d\'animation mis à jour',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage:
              'Impossible de mettre à jour le mode d\'animation : $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Preset de path supprimé',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de supprimer le preset de path : $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void activateFirstSurfaceLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is SurfaceLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (!createIfMissing) {
      state = state.copyWith(
        errorMessage: 'No surface layer found in this map',
      );
      return;
    }

    try {
      final result = _surfacePaintingController.ensureSurfaceLayer(
        map: map,
        preferredLayerId: state.activeLayerId,
      );
      if (!result.changed) {
        state = state.copyWith(activeLayerId: result.layerId);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface layer created',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create surface layer: $e');
    }
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      selectedEnvironmentAreaId: null,
      environmentMaskEditMode: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceOpacity({
    required String instanceId,
    required double opacity,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    final normalizedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    if (previous.opacity == normalizedOpacity) {
      return;
    }
    final updatedMap = setMapPlacedElementOpacity(
      map,
      instanceId: trimmedId,
      opacity: normalizedOpacity,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Opacité mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceShadowOverride({
    required String instanceId,
    required MapPlacedElementShadowOverride? shadowOverride,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.shadowOverride == shadowOverride) {
      return;
    }
    final updatedMap = setMapPlacedElementShadowOverride(
      map,
      instanceId: trimmedId,
      shadowOverride: shadowOverride,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: shadowOverride == null
          ? 'Override d’ombre réinitialisé pour ${previous.elementId}'
          : 'Override d’ombre mis à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final generatedDeletion = _deleteEnvironmentGeneratedPlacedElement(
      map,
      placedElementId: trimmedId,
    );
    if (generatedDeletion != null) {
      try {
        MapValidator.validate(generatedDeletion);
        _applyMapMutation(
          previousMap: map,
          updatedMap: generatedDeletion,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Instance générée supprimée (${instance.elementId})',
        );
        debugPrint(
          '[editor][elements] deleted generated placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
        );
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Failed to delete generated placed element: $e',
        );
      }
      return;
    }

    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  bool addGeneratedEnvironmentPlacementAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return false;
    }
    final activeLayerId = state.activeLayerId?.trim();
    final selectedAreaId = state.selectedEnvironmentAreaId?.trim();
    if (activeLayerId == null ||
        activeLayerId.isEmpty ||
        selectedAreaId == null ||
        selectedAreaId.isEmpty) {
      return false;
    }
    final activeLayer = _findLayerById(map, activeLayerId);
    if (activeLayer is TileLayer) {
      return addGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
    }
    if (activeLayer is! EnvironmentLayer) {
      return false;
    }

    EnvironmentArea? area;
    for (final candidate in activeLayer.content.areas) {
      if (candidate.id == selectedAreaId) {
        area = candidate;
        break;
      }
    }
    if (area == null) {
      return false;
    }

    final targetLayerId = activeLayer.content.targetTileLayerId?.trim();
    if (targetLayerId == null || targetLayerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : aucun TileLayer cible.',
      );
      return false;
    }
    final targetLayer = _findLayerById(map, targetLayerId);
    if (targetLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : TileLayer cible introuvable.',
      );
      return false;
    }

    final preset = _environmentPresetById(project, area.presetId);
    if (preset == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : preset introuvable.',
      );
      return false;
    }

    EnvironmentPaletteItem? item;
    ProjectElementEntry? element;
    final targetTilesetId = _effectiveTileLayerTilesetId(targetLayer, map);
    for (final candidate in preset.palette) {
      final candidateElement = _projectElementById(
        project,
        candidate.elementId,
      );
      if (candidateElement == null) continue;
      final elementTilesetId = _elementPrimaryTilesetId(candidateElement);
      if (targetTilesetId.isNotEmpty &&
          elementTilesetId.isNotEmpty &&
          targetTilesetId != elementTilesetId) {
        continue;
      }
      item = candidate;
      element = candidateElement;
      break;
    }
    if (item == null || element == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter : aucun élément du preset ne correspond au TileLayer cible.',
      );
      return false;
    }

    final footprint = _elementFootprint(element);
    if (!_elementFootprintInBounds(
      pos: pos,
      footprint: footprint,
      mapSize: map.size,
    )) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter : l’élément dépasserait les limites de la map.',
      );
      return false;
    }

    final placedId = _generatedEnvironmentPlacementId(
      areaId: area.id,
      pos: pos,
      elementId: item.elementId,
    );
    if (area.generatedPlacementIds.contains(placedId) ||
        map.placedElements.any((placed) => placed.id == placedId)) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Placement généré déjà présent ici.',
      );
      return false;
    }

    final placed = MapPlacedElement(
      id: placedId,
      layerId: targetLayer.id,
      elementId: item.elementId,
      pos: pos,
      applyCollision: _applyCollisionFromEnvironmentMode(item.collisionMode),
    );
    final updatedMap = _addEnvironmentGeneratedPlacedElement(
      map,
      environmentLayerId: activeLayer.id,
      areaId: area.id,
      placed: placed,
    );

    try {
      MapValidator.validate(updatedMap, projectDialogueContext: project);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: activeLayer.id,
        statusMessage: 'Placement généré ajouté (${item.elementId})',
      );
      debugPrint(
        '[editor][environment] added generated placement by click id=${placed.id} elementId=${placed.elementId} pos=(${pos.x},${pos.y})',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add generated placement: $e',
      );
      return false;
    }
  }

  bool deleteGeneratedEnvironmentPlacementAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId == null || activeLayerId.isEmpty) {
      return false;
    }
    final activeLayer = _findLayerById(map, activeLayerId);
    if (activeLayer is TileLayer) {
      return deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
    }
    if (activeLayer is! EnvironmentLayer) {
      return false;
    }

    final generatedIds = <String>{};
    final selectedAreaId = state.selectedEnvironmentAreaId?.trim();
    for (final area in activeLayer.content.areas) {
      if (selectedAreaId != null &&
          selectedAreaId.isNotEmpty &&
          area.id != selectedAreaId) {
        continue;
      }
      generatedIds.addAll(area.generatedPlacementIds);
    }
    if (generatedIds.isEmpty) {
      return false;
    }

    final project = state.project;
    final elementById = <String, ProjectElementEntry>{
      if (project != null)
        for (final element in project.elements) element.id: element,
    };
    for (final instance in map.placedElements.reversed) {
      if (!generatedIds.contains(instance.id)) {
        continue;
      }
      if (!_placedElementContainsGridPos(
        instance: instance,
        element: elementById[instance.elementId],
        pos: pos,
      )) {
        continue;
      }

      final updatedMap = _deleteEnvironmentGeneratedPlacedElement(
        map,
        placedElementId: instance.id,
      );
      if (updatedMap == null) {
        return false;
      }
      try {
        MapValidator.validate(updatedMap);
        _applyMapMutation(
          previousMap: map,
          updatedMap: updatedMap,
          preferredActiveLayerId: activeLayer.id,
          statusMessage: 'Placement généré supprimé (${instance.elementId})',
        );
        debugPrint(
          '[editor][environment] deleted generated placement by click id=${instance.id} elementId=${instance.elementId} pos=(${instance.pos.x},${instance.pos.y})',
        );
        return true;
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Failed to delete generated placement: $e',
        );
        return false;
      }
    }
    return false;
  }

  bool _placedElementContainsGridPos({
    required MapPlacedElement instance,
    required ProjectElementEntry? element,
    required GridPos pos,
  }) {
    final source = element?.frames.primarySource;
    final width = source == null || source.width <= 0 ? 1 : source.width;
    final height = source == null || source.height <= 0 ? 1 : source.height;
    return pos.x >= instance.pos.x &&
        pos.y >= instance.pos.y &&
        pos.x < instance.pos.x + width &&
        pos.y < instance.pos.y + height;
  }

  MapData _addEnvironmentGeneratedPlacedElement(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required MapPlacedElement placed,
  }) {
    final updatedLayers = <MapLayer>[];
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer || layer.id != environmentLayerId) {
        updatedLayers.add(layer);
        continue;
      }

      final updatedAreas = <EnvironmentArea>[];
      for (final area in layer.content.areas) {
        if (area.id != areaId) {
          updatedAreas.add(area);
          continue;
        }
        updatedAreas.add(
          EnvironmentArea(
            id: area.id,
            name: area.name,
            presetId: area.presetId,
            mask: area.mask,
            seed: area.seed,
            paramsOverride: area.paramsOverride,
            generatedPlacementIds: [
              ...area.generatedPlacementIds,
              placed.id,
            ],
          ),
        );
      }

      updatedLayers.add(
        MapLayer.environment(
          id: layer.id,
          name: layer.name,
          isVisible: layer.isVisible,
          opacity: layer.opacity,
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: updatedAreas,
          ),
          properties: layer.properties,
        ),
      );
    }

    return map.copyWith(
      layers: updatedLayers,
      placedElements: [
        ...map.placedElements,
        placed,
      ],
    );
  }

  MapData? _deleteEnvironmentGeneratedPlacedElement(
    MapData map, {
    required String placedElementId,
  }) {
    var didRemoveReference = false;
    final updatedLayers = <MapLayer>[];
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer) {
        updatedLayers.add(layer);
        continue;
      }

      var didUpdateLayer = false;
      final updatedAreas = <EnvironmentArea>[];
      for (final area in layer.content.areas) {
        if (!area.generatedPlacementIds.contains(placedElementId)) {
          updatedAreas.add(area);
          continue;
        }

        didRemoveReference = true;
        didUpdateLayer = true;
        updatedAreas.add(
          EnvironmentArea(
            id: area.id,
            name: area.name,
            presetId: area.presetId,
            mask: area.mask,
            seed: area.seed,
            paramsOverride: area.paramsOverride,
            generatedPlacementIds: [
              for (final id in area.generatedPlacementIds)
                if (id != placedElementId) id,
            ],
          ),
        );
      }

      if (!didUpdateLayer) {
        updatedLayers.add(layer);
        continue;
      }

      updatedLayers.add(
        MapLayer.environment(
          id: layer.id,
          name: layer.name,
          isVisible: layer.isVisible,
          opacity: layer.opacity,
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: updatedAreas,
          ),
          properties: layer.properties,
        ),
      );
    }

    if (!didRemoveReference) {
      return null;
    }

    return map.copyWith(
      layers: updatedLayers,
      placedElements: [
        for (final placed in map.placedElements)
          if (placed.id != placedElementId) placed,
      ],
    );
  }

  _TileLayerGeneratedPlacementAddSelection
      _resolveGeneratedPlacementAddSelectionForTileLayer({
    String? requestedElementId,
    required bool requireGeneratedPlacements,
    required bool allowImplicitSelection,
  }) {
    final map = state.activeMap;
    if (map == null) {
      throw const EditorValidationException('Aucune carte active.');
    }
    final project = state.project;
    if (project == null) {
      throw const EditorValidationException('Aucun projet chargé.');
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      throw const EditorValidationException(
        'Sélectionnez un TileLayer avant d’ajouter un élément généré.',
      );
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      throw const EditorValidationException(
        'Sélectionnez un TileLayer avant d’ajouter un élément généré.',
      );
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      throw const EditorValidationException(
        'Sélectionnez une zone d’environnement avant d’ajouter un élément généré.',
      );
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      throw const EditorValidationException(
        'Activez d’abord l’environnement sur ce layer.',
      );
    }
    if (requireGeneratedPlacements &&
        target.area.generatedPlacementIds.isEmpty) {
      throw const EditorValidationException(
        'Générez d’abord la zone avant d’affiner manuellement.',
      );
    }
    final preset = _environmentPresetById(project, target.area.presetId);
    if (preset == null) {
      throw const EditorValidationException('Preset introuvable.');
    }

    final selectedId = (requestedElementId ??
            ref.read(environmentGeneratedPlacementAddElementProvider))
        ?.trim();
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final item in preset.palette) {
        if (item.elementId != selectedId) continue;
        final element = _projectElementById(project, item.elementId);
        if (element == null) {
          throw const EditorValidationException(
            'Élément introuvable dans le projet.',
          );
        }
        return _TileLayerGeneratedPlacementAddSelection(
          project: project,
          tileLayerId: activeLayer.id,
          environmentLayerId: target.environmentLayerId,
          areaId: target.areaId,
          item: item,
          element: element,
        );
      }
      throw const EditorValidationException(
        'L’élément choisi n’appartient pas à la palette du preset.',
      );
    }

    if (!allowImplicitSelection) {
      throw const EditorValidationException(
        'Choisissez un élément à ajouter.',
      );
    }

    final available =
        <({EnvironmentPaletteItem item, ProjectElementEntry element})>[];
    final targetTilesetId = _effectiveTileLayerTilesetId(activeLayer, map);
    for (final item in preset.palette) {
      final element = _projectElementById(project, item.elementId);
      if (element == null) continue;
      final elementTilesetId = _elementPrimaryTilesetId(element);
      if (targetTilesetId.isNotEmpty &&
          elementTilesetId.isNotEmpty &&
          targetTilesetId != elementTilesetId) {
        continue;
      }
      available.add((item: item, element: element));
    }
    if (available.length != 1) {
      throw const EditorValidationException(
        'Choisissez un élément à ajouter.',
      );
    }
    final implicit = available.single;
    return _TileLayerGeneratedPlacementAddSelection(
      project: project,
      tileLayerId: activeLayer.id,
      environmentLayerId: target.environmentLayerId,
      areaId: target.areaId,
      item: implicit.item,
      element: implicit.element,
    );
  }

  EnvironmentPreset? _environmentPresetById(
    ProjectManifest project,
    String presetId,
  ) {
    final normalizedId = presetId.trim();
    for (final preset in project.environmentPresets) {
      if (preset.id == normalizedId) {
        return preset;
      }
    }
    return null;
  }

  ProjectElementEntry? _projectElementById(
    ProjectManifest project,
    String elementId,
  ) {
    final normalizedId = elementId.trim();
    for (final element in project.elements) {
      if (element.id == normalizedId) {
        return element;
      }
    }
    return null;
  }

  GridSize _elementFootprint(ProjectElementEntry element) {
    final source = element.frames.primarySource;
    return GridSize(
      width: source.width <= 0 ? 1 : source.width,
      height: source.height <= 0 ? 1 : source.height,
    );
  }

  bool _elementFootprintInBounds({
    required GridPos pos,
    required GridSize footprint,
    required GridSize mapSize,
  }) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x + footprint.width <= mapSize.width &&
        pos.y + footprint.height <= mapSize.height;
  }

  String _effectiveTileLayerTilesetId(TileLayer layer, MapData map) {
    return (layer.tilesetId ?? map.tilesetId).trim();
  }

  String _elementPrimaryTilesetId(ProjectElementEntry element) {
    final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) return frameTilesetId;
    return element.tilesetId.trim();
  }

  bool _applyCollisionFromEnvironmentMode(EnvironmentCollisionMode mode) {
    switch (mode) {
      case EnvironmentCollisionMode.forceEnabled:
        return true;
      case EnvironmentCollisionMode.forceDisabled:
        return false;
      case EnvironmentCollisionMode.useElementDefault:
        return true;
    }
  }

  String _generatedEnvironmentPlacementId({
    required String areaId,
    required GridPos pos,
    required String elementId,
  }) {
    return 'env_gen_${_sanitizeEnvironmentIdPart(areaId)}_${pos.x}_${pos.y}_${_sanitizeEnvironmentIdPart(elementId)}';
  }

  String _sanitizeEnvironmentIdPart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  /// Retourne la même page cible que le contrat Event Builder.
  ///
  /// Les drafts actuels utilisent pageNumber 0, mais les anciens events peuvent
  /// contenir des pages non ordonnées ; on préserve donc la règle "plus petit
  /// pageNumber" au lieu de supposer que l'index 0 est toujours canonique.
  int _eventBuilderAuthorablePageNumber(MapEventDefinition event) {
    var selected = event.pages.first.pageNumber;
    for (final page in event.pages.skip(1)) {
      if (page.pageNumber < selected) {
        selected = page.pageNumber;
      }
    }
    return selected;
  }

  MapData _updateEventBuilderPageCondition({
    required MapData map,
    required MapEventDefinition event,
    required int pageNumber,
    required List<EventBuilderConditionBinding> conditions,
  }) {
    final compiled = compileEventBuilderConditionsToScriptCondition(conditions);
    if (compiled.hasErrors) {
      throw UnsupportedError(
        'Event Builder conditions contain unsupported entries for NS-EVENT-13.',
      );
    }
    final pageIndex =
        event.pages.indexWhere((page) => page.pageNumber == pageNumber);
    if (pageIndex < 0) {
      throw ValidationException(
        'Map event page not found: event=${event.id} pageNumber=$pageNumber',
      );
    }
    // updatePageOnMapEvent is intentionally used instead of applying the whole
    // Event Builder contract: this lot owns only MapEventPage.condition and
    // must not rewrite sceneTarget, metadata, script or message.
    return updatePageOnMapEvent(
      map,
      eventId: event.id,
      pageIndex: pageIndex,
      condition: compiled.condition,
      clearCondition: compiled.condition == null,
    );
  }

  bool _isEventBuilderFactConditionKind(EventBuilderConditionKind kind) {
    return switch (kind) {
      EventBuilderConditionKind.factIsTrue ||
      EventBuilderConditionKind.factIsFalse =>
        true,
      EventBuilderConditionKind.eventConsumed ||
      EventBuilderConditionKind.eventNotConsumed ||
      EventBuilderConditionKind.storyStepCompleted ||
      EventBuilderConditionKind.storyStepNotCompleted =>
        false,
    };
  }

  /// Lot Environment-22 : évite une sélection masque fantôme si le layer ou l’area disparaît.
  void _coerceEnvironmentMaskSelectionAfterMapChange() {
    final map = state.activeMap;
    final lid = state.activeLayerId;
    if (map == null || lid == null) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
      return;
    }
    final layer = _findLayerById(map, lid);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
      return;
    }
    final sid = state.selectedEnvironmentAreaId?.trim();
    if (sid == null || sid.isEmpty) {
      return;
    }
    final stillExists = layer.content.areas.any((a) => a.id == sid);
    if (!stillExists) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
    }
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: _trainerFieldUpdate<int>(battleDifficulty),
        battleBackgroundRelativePath:
            _trainerFieldUpdate<String>(battleBackgroundRelativePath),
        characterId: _trainerFieldUpdate<String>(characterId),
        portraitElementId: _trainerFieldUpdate<String>(portraitElementId),
        battleThemeId: _trainerFieldUpdate<String>(battleThemeId),
        victoryThemeId: _trainerFieldUpdate<String>(victoryThemeId),
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: _trainerFieldUpdate<String>(heldItemId),
        formId: _trainerFieldUpdate<String>(formId),
        gender: _trainerFieldUpdate<String>(gender),
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

TrainerFieldUpdate<T> _trainerFieldUpdate<T>(Object? rawValue) {
  if (identical(rawValue, _trainerUnset)) {
    return TrainerFieldUpdate<T>.keep();
  }
  return TrainerFieldUpdate<T>.set(rawValue as T?);
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}

class _TileLayerGeneratedPlacementAddSelection {
  const _TileLayerGeneratedPlacementAddSelection({
    required this.project,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.item,
    required this.element,
  });

  final ProjectManifest project;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final EnvironmentPaletteItem item;
  final ProjectElementEntry element;
}
