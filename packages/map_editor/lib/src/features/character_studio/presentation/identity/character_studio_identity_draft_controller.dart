import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

@immutable
final class CharacterIdentityFormDraft {
  const CharacterIdentityFormDraft({
    required this.name,
    required this.tilesetId,
    required this.frameWidth,
    required this.frameHeight,
    required this.tags,
  });

  final String name;
  final String tilesetId;
  final String frameWidth;
  final String frameHeight;
  final String tags;

  bool matches(ProjectCharacterEntry character) {
    return name == character.name &&
        tilesetId == character.tilesetId &&
        frameWidth == '${character.frameWidth}' &&
        frameHeight == '${character.frameHeight}' &&
        _normalizedTags(tags).listEquals(character.tags);
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterIdentityFormDraft &&
        other.name == name &&
        other.tilesetId == tilesetId &&
        other.frameWidth == frameWidth &&
        other.frameHeight == frameHeight &&
        other.tags == tags;
  }

  @override
  int get hashCode =>
      Object.hash(name, tilesetId, frameWidth, frameHeight, tags);
}

@immutable
final class CharacterStudioIdentityDraftState {
  const CharacterStudioIdentityDraftState({
    this.drafts = const <String, CharacterIdentityFormDraft>{},
  });

  final Map<String, CharacterIdentityFormDraft> drafts;

  CharacterIdentityFormDraft? draftFor({
    required String projectRootPath,
    required String characterId,
  }) {
    return drafts[_draftKey(projectRootPath, characterId)];
  }
}

final characterStudioIdentityDraftProvider =
    NotifierProvider<
      CharacterStudioIdentityDraftController,
      CharacterStudioIdentityDraftState
    >(CharacterStudioIdentityDraftController.new);

final class CharacterStudioIdentityDraftController
    extends Notifier<CharacterStudioIdentityDraftState> {
  @override
  CharacterStudioIdentityDraftState build() {
    return const CharacterStudioIdentityDraftState();
  }

  void update({
    required String projectRootPath,
    required String characterId,
    required CharacterIdentityFormDraft draft,
  }) {
    final key = _draftKey(projectRootPath, characterId);
    if (state.drafts[key] == draft) return;
    state = CharacterStudioIdentityDraftState(
      drafts: Map<String, CharacterIdentityFormDraft>.unmodifiable(
        <String, CharacterIdentityFormDraft>{...state.drafts, key: draft},
      ),
    );
  }

  void clear({required String projectRootPath, required String characterId}) {
    final key = _draftKey(projectRootPath, characterId);
    if (!state.drafts.containsKey(key)) return;
    final next = Map<String, CharacterIdentityFormDraft>.of(state.drafts)
      ..remove(key);
    state = CharacterStudioIdentityDraftState(
      drafts: Map<String, CharacterIdentityFormDraft>.unmodifiable(next),
    );
  }
}

String _draftKey(String projectRootPath, String characterId) {
  return '$projectRootPath\u0000$characterId';
}

List<String> _normalizedTags(String value) {
  final result = <String>[];
  final seen = <String>{};
  for (final rawTag in value.split(',')) {
    final tag = rawTag.trim();
    if (tag.isEmpty || !seen.add(tag.toLowerCase())) continue;
    result.add(tag);
  }
  return result;
}

extension on List<String> {
  bool listEquals(List<String> other) {
    if (length != other.length) return false;
    for (var index = 0; index < length; index++) {
      if (this[index] != other[index]) return false;
    }
    return true;
  }
}
