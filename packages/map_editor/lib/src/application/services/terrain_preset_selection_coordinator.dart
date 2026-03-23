import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_state.dart';
import 'terrain_preset_resolver.dart';

class TerrainPresetSelection {
  const TerrainPresetSelection({
    required this.selectionMode,
    required this.selectedTerrainType,
    required this.selectedTerrainPresetId,
    required this.selectedPathPresetId,
    required this.selectedTerrainPresetByType,
  });

  final TerrainSelectionMode selectionMode;
  final TerrainType selectedTerrainType;
  final String? selectedTerrainPresetId;
  final String? selectedPathPresetId;
  final Map<TerrainType, String> selectedTerrainPresetByType;
}

class TerrainPresetSelectionCoordinator {
  const TerrainPresetSelectionCoordinator({
    required TerrainPresetResolver resolver,
  }) : _resolver = resolver;

  final TerrainPresetResolver _resolver;

  TerrainPresetSelection initial(ProjectManifest project) {
    return TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.terrain,
      selectedTerrainType: TerrainType.normal,
      selectedTerrainPresetId: _resolver.resolveInitialTerrainPresetId(project),
      selectedPathPresetId: _resolver.resolveInitialPathPresetId(project),
      selectedTerrainPresetByType:
          _resolver.resolveInitialTerrainPresetByType(project),
    );
  }

  TerrainPresetSelection normalize({
    required ProjectManifest project,
    required TerrainPresetSelection current,
  }) {
    final nextByType = _resolver.sanitizeTerrainPresetSelectionByType(
      project: project,
      current: current.selectedTerrainPresetByType,
    );
    final nextTerrainPresetId = _resolver.resolveSelectedTerrainPresetId(
      project: project,
      terrainType: current.selectedTerrainType,
      preferredPresetId: current.selectedTerrainPresetId,
      selectedTerrainPresetByType: nextByType,
    );
    final nextPathPresetId = _resolver.resolveSelectedPathPresetId(
      project: project,
      preferredPresetId: current.selectedPathPresetId,
    );
    return TerrainPresetSelection(
      selectionMode: current.selectionMode,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: nextTerrainPresetId,
      selectedPathPresetId: nextPathPresetId,
      selectedTerrainPresetByType: nextByType,
    );
  }

  TerrainPresetSelection forTerrainType({
    required ProjectManifest? project,
    required TerrainPresetSelection current,
    required TerrainType terrainType,
    String? preferredTerrainPresetId,
  }) {
    final nextTerrainPresetId = _resolver.resolveSelectedTerrainPresetId(
      project: project,
      terrainType: terrainType,
      preferredPresetId:
          preferredTerrainPresetId ?? current.selectedTerrainPresetId,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
    return TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.terrain,
      selectedTerrainType: terrainType,
      selectedTerrainPresetId: nextTerrainPresetId,
      selectedPathPresetId: current.selectedPathPresetId,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
  }

  TerrainPresetSelection forTerrainPresetSelected({
    required TerrainPresetSelection current,
    required ProjectTerrainPreset preset,
  }) {
    final nextByType = Map<TerrainType, String>.from(
      current.selectedTerrainPresetByType,
    );
    nextByType[preset.terrainType] = preset.id;
    return TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.terrain,
      selectedTerrainType: preset.terrainType,
      selectedTerrainPresetId: preset.id,
      selectedPathPresetId: current.selectedPathPresetId,
      selectedTerrainPresetByType: nextByType,
    );
  }

  TerrainPresetSelection forPathPresetSelected({
    required TerrainPresetSelection current,
    required ProjectPathPreset preset,
  }) {
    return TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.path,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: current.selectedTerrainPresetId,
      selectedPathPresetId: preset.id,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
  }

  TerrainPresetSelection afterTerrainPresetCreated({
    required ProjectManifest previous,
    required ProjectManifest updated,
    required TerrainPresetSelection current,
  }) {
    final created = _resolver.findLastCreatedTerrainPreset(previous, updated);
    if (created == null) {
      return normalize(project: updated, current: current);
    }
    final selected = forTerrainPresetSelected(
      current: current,
      preset: created,
    );
    return normalize(project: updated, current: selected);
  }

  TerrainPresetSelection afterTerrainPresetUpdated({
    required ProjectManifest updated,
    required TerrainPresetSelection current,
    required ProjectTerrainPreset selectedPreset,
  }) {
    final nextByType = _resolver.sanitizeTerrainPresetSelectionByType(
      project: updated,
      current: current.selectedTerrainPresetByType,
    );
    nextByType[selectedPreset.terrainType] = selectedPreset.id;
    final next = TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.terrain,
      selectedTerrainType: selectedPreset.terrainType,
      selectedTerrainPresetId: selectedPreset.id,
      selectedPathPresetId: current.selectedPathPresetId,
      selectedTerrainPresetByType: nextByType,
    );
    return normalize(project: updated, current: next);
  }

  TerrainPresetSelection afterTerrainPresetDeleted({
    required ProjectManifest updated,
    required TerrainPresetSelection current,
    required String deletedPresetId,
  }) {
    final nextByType = _resolver.sanitizeTerrainPresetSelectionByType(
      project: updated,
      current: current.selectedTerrainPresetByType,
    );
    String? nextSelectedTerrainPresetId = current.selectedTerrainPresetId;
    if (nextSelectedTerrainPresetId == deletedPresetId ||
        _resolver.findTerrainPresetById(updated, nextSelectedTerrainPresetId) ==
            null) {
      final fallback = _resolver.listTerrainPresets(
        updated,
        terrainType: current.selectedTerrainType,
      );
      nextSelectedTerrainPresetId = fallback.isEmpty ? null : fallback.first.id;
    }
    final next = TerrainPresetSelection(
      selectionMode: current.selectionMode,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: nextSelectedTerrainPresetId,
      selectedPathPresetId: current.selectedPathPresetId,
      selectedTerrainPresetByType: nextByType,
    );
    return normalize(project: updated, current: next);
  }

  TerrainPresetSelection afterPathPresetCreated({
    required ProjectManifest previous,
    required ProjectManifest updated,
    required TerrainPresetSelection current,
  }) {
    final created = _resolver.findLastCreatedPathPreset(previous, updated);
    final next = TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.path,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: current.selectedTerrainPresetId,
      selectedPathPresetId: created?.id ?? current.selectedPathPresetId,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
    return normalize(project: updated, current: next);
  }

  TerrainPresetSelection afterPathPresetUpdated({
    required ProjectManifest updated,
    required TerrainPresetSelection current,
    required ProjectPathPreset selectedPreset,
  }) {
    final next = TerrainPresetSelection(
      selectionMode: TerrainSelectionMode.path,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: current.selectedTerrainPresetId,
      selectedPathPresetId: selectedPreset.id,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
    return normalize(project: updated, current: next);
  }

  TerrainPresetSelection afterPathPresetDeleted({
    required ProjectManifest updated,
    required TerrainPresetSelection current,
    required String deletedPresetId,
  }) {
    String? nextSelectedPathPresetId = current.selectedPathPresetId;
    if (nextSelectedPathPresetId == deletedPresetId ||
        _resolver.findPathPresetById(updated, nextSelectedPathPresetId) ==
            null) {
      final presets = _resolver.listPathPresets(updated);
      nextSelectedPathPresetId = presets.isEmpty ? null : presets.first.id;
    }
    final next = TerrainPresetSelection(
      selectionMode: current.selectionMode,
      selectedTerrainType: current.selectedTerrainType,
      selectedTerrainPresetId: current.selectedTerrainPresetId,
      selectedPathPresetId: nextSelectedPathPresetId,
      selectedTerrainPresetByType: current.selectedTerrainPresetByType,
    );
    return normalize(project: updated, current: next);
  }
}
