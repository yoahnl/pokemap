import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

String _generateCharacterId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'character' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.characters.map((c) => c.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

class CreateCharacterUseCase {
  CreateCharacterUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Character name cannot be empty');
    }
    final trimmedTilesetId = tilesetId.trim();
    if (trimmedTilesetId.isEmpty) {
      throw const EditorValidationException('Character tilesetId cannot be empty');
    }
    final character = ProjectCharacterEntry(
      id: _generateCharacterId(project, trimmedName),
      name: trimmedName,
      tilesetId: trimmedTilesetId,
      frameWidth: frameWidth.clamp(1, 9999),
      frameHeight: frameHeight.clamp(1, 9999),
    );
    final updated = project.copyWith(
      characters: [...project.characters, character],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateCharacterUseCase {
  UpdateCharacterUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final index = project.characters.indexWhere((c) => c.id == characterId);
    if (index < 0) {
      throw EditorNotFoundException('Character not found: $characterId');
    }
    final current = project.characters[index];
    final trimmedName = name?.trim() ?? current.name;
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Character name cannot be empty');
    }
    final trimmedTileset = tilesetId?.trim() ?? current.tilesetId;
    if (trimmedTileset.isEmpty) {
      throw const EditorValidationException('Character tilesetId cannot be empty');
    }
    final updatedChar = current.copyWith(
      name: trimmedName,
      tilesetId: trimmedTileset,
      frameWidth: (frameWidth ?? current.frameWidth).clamp(1, 9999),
      frameHeight: (frameHeight ?? current.frameHeight).clamp(1, 9999),
      tags: tags ?? current.tags,
    );
    final characters = List<ProjectCharacterEntry>.from(project.characters);
    characters[index] = updatedChar;
    final updated = project.copyWith(characters: characters);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteCharacterUseCase {
  DeleteCharacterUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
  }) async {
    final index = project.characters.indexWhere((c) => c.id == characterId);
    if (index < 0) {
      throw EditorNotFoundException('Character not found: $characterId');
    }
    final characters = List<ProjectCharacterEntry>.from(project.characters)
      ..removeAt(index);
    final isPlayer = project.settings.defaultPlayerCharacterId == characterId;
    final settings = isPlayer
        ? project.settings.copyWith(defaultPlayerCharacterId: null)
        : project.settings;
    final updated = project.copyWith(
      characters: characters,
      settings: settings,
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpsertCharacterAnimationUseCase {
  UpsertCharacterAnimationUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final index = project.characters.indexWhere((c) => c.id == characterId);
    if (index < 0) {
      throw EditorNotFoundException('Character not found: $characterId');
    }
    final current = project.characters[index];
    final newAnim = CharacterAnimation(
      state: animState,
      direction: direction,
      frames: frames,
    );
    final anims = List<CharacterAnimation>.from(current.animations);
    final animIndex = anims.indexWhere(
      (a) => a.state == animState && a.direction == direction,
    );
    if (animIndex >= 0) {
      anims[animIndex] = newAnim;
    } else {
      anims.add(newAnim);
    }
    final updatedChar = current.copyWith(animations: anims);
    final characters = List<ProjectCharacterEntry>.from(project.characters);
    characters[index] = updatedChar;
    final updated = project.copyWith(characters: characters);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class SetPlayerCharacterUseCase {
  SetPlayerCharacterUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String? characterId,
  }) async {
    final trimmedId = characterId?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) {
      final exists = project.characters.any((c) => c.id == trimmedId);
      if (!exists) {
        throw EditorNotFoundException('Character not found: $trimmedId');
      }
    }
    final updated = project.copyWith(
      settings: project.settings.copyWith(
        defaultPlayerCharacterId:
            (trimmedId == null || trimmedId.isEmpty) ? null : trimmedId,
      ),
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
