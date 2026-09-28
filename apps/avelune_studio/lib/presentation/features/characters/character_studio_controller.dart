import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/characters/application/character_studio_draft.dart';
import '../../../features/characters/application/character_studio_frame_bounds.dart';

enum CharacterStudioSection { library, identity, animations, portraits }

typedef CharacterStudioMutation =
    Future<ProjectManifest> Function(
      String actionId,
      Map<String, Object?> parameters,
    );

final class CharacterStudioController extends ChangeNotifier {
  CharacterStudioController({required this.project, required this.mutate});

  final ProjectManifest Function() project;
  final CharacterStudioMutation mutate;
  final Map<String, CharacterStudioDraft> _drafts = {};
  String? selectedId;
  String query = '';
  CharacterStudioSection section = CharacterStudioSection.animations;
  CharacterAnimationState animationState = CharacterAnimationState.walk;
  EntityFacing previewDirection = EntityFacing.south;
  bool playing = false;
  double playbackSpeed = 1;
  bool saving = false;
  String? error;

  bool get dirty => _drafts.values.any((draft) => draft.dirty);

  void notifyStateChanged() => notifyListeners();

  ProjectCharacterEntry? get selectedCharacter {
    final characters = project().characters;
    final id = selectedId;
    return id == null
        ? characters.firstOrNull
        : characters.where((character) => character.id == id).firstOrNull;
  }

  void refreshClean() {
    final characters = {
      for (final character in project().characters) character.id: character,
    };
    var changed = false;
    for (final draft in _drafts.values) {
      final current = characters[draft.saved.id];
      if (!draft.dirty && current != null && current != draft.saved) {
        draft.saved = current;
        draft.name = current.name;
        draft.frameWidth = current.frameWidth;
        draft.frameHeight = current.frameHeight;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  CharacterStudioDraft? get selectedDraft {
    final character = selectedCharacter;
    if (character == null) return null;
    return _drafts.putIfAbsent(
      character.id,
      () => CharacterStudioDraft(character),
    );
  }

  List<ProjectCharacterEntry> get visibleCharacters {
    final needle = query.trim().toLowerCase();
    return project().characters
        .where(
          (character) =>
              needle.isEmpty ||
              '${character.name} ${character.id} ${character.tags.join(' ')}'
                  .toLowerCase()
                  .contains(needle),
        )
        .toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order == 0 ? left.name.compareTo(right.name) : order;
      });
  }

  void select(String id) {
    if (selectedId == id) return;
    selectedId = id;
    error = null;
    notifyListeners();
  }

  void setSection(CharacterStudioSection next) {
    if (section == next) return;
    section = next;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setName(String value) {
    final draft = selectedDraft;
    if (draft == null) return;
    draft.name = value;
    notifyListeners();
  }

  void setAnimationState(CharacterAnimationState value) {
    animationState = value;
    notifyListeners();
  }

  void setPreviewDirection(EntityFacing value) {
    previewDirection = value;
    notifyListeners();
  }

  void setPlaying(bool value) {
    playing = value;
    notifyListeners();
  }

  void setPlaybackSpeed(double value) {
    playbackSpeed = value;
    notifyListeners();
  }

  void setFrameSize(int width, int height) {
    final draft = selectedDraft;
    if (draft == null) return;
    draft.frameWidth = width;
    draft.frameHeight = height;
    notifyListeners();
  }

  void assign(EntityFacing direction, int index, TilesetSourceRect source) {
    selectedDraft?.assign((animationState, direction), index, source);
    error = null;
    notifyListeners();
  }

  void clear(EntityFacing direction, int index) {
    selectedDraft?.clear((animationState, direction), index);
    notifyListeners();
  }

  bool assignClassicSheet(ProjectRegularAtlasTilesetSource source) {
    final draft = selectedDraft;
    if (draft == null) return false;
    final applied = draft.assignClassicSheet(
      animationState,
      source,
      frameWidth:
          project().settings.tileWidth * draft.frameWidth.clamp(2, 1 << 20),
      frameHeight:
          project().settings.tileHeight * draft.frameHeight.clamp(2, 1 << 20),
    );
    error = applied
        ? null
        : 'La planche doit contenir trois poses sur quatre directions, sans marge ni espacement.';
    notifyListeners();
    return applied;
  }

  void discardSelected() {
    selectedDraft?.discard();
    error = null;
    notifyListeners();
  }

  Future<bool> saveSelected() async {
    final draft = selectedDraft;
    if (draft == null) return true;
    return _save(draft);
  }

  Future<bool> saveAll() async {
    if (saving) return false;
    for (final draft in _drafts.values.where((draft) => draft.dirty).toList()) {
      if (!await _save(draft)) return false;
    }
    return !dirty;
  }

  Future<bool> _save(CharacterStudioDraft draft) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    var completed = 0;
    try {
      var current = project().characters
          .where((character) => character.id == draft.saved.id)
          .firstOrNull;
      if (current != draft.saved) {
        throw StateError(
          'Ce personnage a changé depuis son ouverture. Le brouillon est conservé.',
        );
      }
      final clips = draft.changedClips.toList();
      for (final key in clips) {
        final problem = draft.problemFor(key);
        if (problem != null) throw StateError(problem);
      }
      final boundsProblem = characterStudioFrameBoundsProblem(project(), draft);
      if (boundsProblem != null) throw StateError(boundsProblem);
      if (draft.name != draft.saved.name ||
          draft.frameWidth != draft.saved.frameWidth ||
          draft.frameHeight != draft.saved.frameHeight) {
        final manifest = await mutate('characterStudio.character.update', {
          'characterId': draft.saved.id,
          if (draft.name != draft.saved.name) 'name': draft.name,
          if (draft.frameWidth != draft.saved.frameWidth)
            'frameWidth': draft.frameWidth,
          if (draft.frameHeight != draft.saved.frameHeight)
            'frameHeight': draft.frameHeight,
        });
        completed++;
        current = manifest.characters.firstWhere(
          (character) => character.id == draft.saved.id,
        );
        draft.accept(current);
      }
      for (final key in clips) {
        if (!draft.clipChanged(key)) continue;
        final frames = draft.completeFrames(key);
        final manifest = await mutate(
          frames.isEmpty
              ? 'characterStudio.animationClip.delete'
              : 'characterStudio.animationClip.upsert',
          {
            'characterId': draft.saved.id,
            'kind': 'system',
            'state': key.$1.name,
            'direction': key.$2.name,
            if (frames.isNotEmpty) 'sourceAssetId': null,
            if (frames.isNotEmpty)
              'frames': [for (final frame in frames) frame.toJson()],
          },
        );
        completed++;
        current = manifest.characters.firstWhere(
          (character) => character.id == draft.saved.id,
        );
        draft.accept(current);
      }
      return !draft.dirty;
    } catch (failure) {
      error = completed == 0
          ? '$failure'
          : '$completed modification(s) enregistrée(s), puis échec : $failure';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> create(
    String name,
    String tilesetId, {
    int frameWidth = 2,
    int frameHeight = 2,
  }) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final before = project().characters
          .map((character) => character.id)
          .toSet();
      final manifest = await mutate('characterStudio.character.create', {
        'name': name.trim(),
        'tilesetId': tilesetId,
        'frameWidth': frameWidth,
        'frameHeight': frameHeight,
      });
      selectedId = manifest.characters
          .firstWhere((character) => !before.contains(character.id))
          .id;
      section = CharacterStudioSection.animations;
      return true;
    } catch (failure) {
      error = '$failure';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
