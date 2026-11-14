import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'scene_finish_game_contract.dart';

const int storylineJournalTitleMaxLength = 80;
const int storylineJournalTextMaxLength = 4000;
const int storylineJournalClueTextMaxLength = 500;
const int storylineJournalClueMaxCount = 200;

@immutable
final class StorylineMilestoneJournal {
  StorylineMilestoneJournal({required this.title, required this.text}) {
    _requireText(title, storylineJournalTitleMaxLength, 'journal.title');
    _requireText(text, storylineJournalTextMaxLength, 'journal.text');
  }

  factory StorylineMilestoneJournal.fromJson(Map<String, dynamic> json) {
    return StorylineMilestoneJournal(
      title: _readLocalizedText(json, 'title', 'journal'),
      text: _readLocalizedText(json, 'text', 'journal'),
    );
  }

  final SceneLocalizedText title;
  final SceneLocalizedText text;

  Map<String, dynamic> toJson() => {
    'title': title.toJson(),
    'text': text.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineMilestoneJournal &&
          other.title == title &&
          other.text == text;

  @override
  int get hashCode => Object.hash(title, text);
}

@immutable
final class StorylineJournalClue {
  StorylineJournalClue({
    required this.id,
    required this.factId,
    required this.text,
  }) {
    _requireIdentity(id, 'journalClue.id');
    _requireIdentity(factId, 'journalClue.factId');
    _requireText(text, storylineJournalClueTextMaxLength, 'journalClue.text');
  }

  factory StorylineJournalClue.fromJson(Map<String, dynamic> json) {
    return StorylineJournalClue(
      id: _readString(json, 'id', 'journalClue'),
      factId: _readString(json, 'factId', 'journalClue'),
      text: _readLocalizedText(json, 'text', 'journalClue'),
    );
  }

  final String id;
  final String factId;
  final SceneLocalizedText text;

  Map<String, dynamic> toJson() => {
    'id': id,
    'factId': factId,
    'text': text.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineJournalClue &&
          other.id == id &&
          other.factId == factId &&
          other.text == text;

  @override
  int get hashCode => Object.hash(id, factId, text);
}

List<StorylineJournalClue> immutableStorylineJournalClues(
  List<StorylineJournalClue> clues,
) {
  if (clues.length > storylineJournalClueMaxCount) {
    throw const ValidationException(
      'StorylineAsset.journalClues exceeds $storylineJournalClueMaxCount '
      'entries',
      code: 'storyline.journal_clues_too_many',
    );
  }
  final ids = <String>{};
  for (final clue in clues) {
    if (!ids.add(clue.id)) {
      throw ValidationException(
        'StorylineAsset.journalClues contains duplicate id ${clue.id}',
        code: 'storyline.journal_clue_duplicate',
      );
    }
  }
  return List<StorylineJournalClue>.unmodifiable(clues);
}

StorylineMilestoneJournal? readStorylineMilestoneJournal(
  Map<String, dynamic> json,
) {
  final value = json['journal'];
  if (value == null) return null;
  return StorylineMilestoneJournal.fromJson(_object(value, 'journal'));
}

List<StorylineJournalClue> readStorylineJournalClues(
  Map<String, dynamic> json,
) {
  final value = json['journalClues'];
  if (value == null) return const <StorylineJournalClue>[];
  if (value is! List) {
    throw const ValidationException('journalClues must be a JSON list');
  }
  return [
    for (final item in value)
      StorylineJournalClue.fromJson(_object(item, 'journalClues')),
  ];
}

SceneLocalizedText _readLocalizedText(
  Map<String, dynamic> json,
  String key,
  String owner,
) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw ValidationException('$owner.$key must be a localized text object');
  }
  try {
    return SceneLocalizedText.fromJson(value);
  } on FormatException catch (error) {
    throw ValidationException('$owner.$key is invalid: ${error.message}');
  }
}

String _readString(Map<String, dynamic> json, String key, String owner) {
  final value = json[key];
  if (value is! String) {
    throw ValidationException('$owner.$key must be a string');
  }
  return value;
}

Map<String, dynamic> _object(Object? value, String fieldName) {
  if (value is! Map) {
    throw ValidationException('$fieldName must contain JSON objects');
  }
  return value.map((key, item) {
    if (key is! String) {
      throw ValidationException('$fieldName keys must be strings');
    }
    return MapEntry(key, item);
  });
}

void _requireIdentity(String value, String fieldName) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$fieldName must be a nonblank trimmed string');
  }
}

void _requireText(SceneLocalizedText text, int maxLength, String fieldName) {
  if (text.fallback.isEmpty) {
    throw ValidationException(
      '$fieldName must not be blank',
      code: 'storyline.journal_text_blank',
    );
  }
  for (final value in [text.fallback, ...text.translations.values]) {
    if (value.length > maxLength) {
      throw ValidationException(
        '$fieldName exceeds $maxLength characters',
        code: 'storyline.journal_text_too_long',
        details: <String, Object?>{'maxLength': maxLength},
      );
    }
  }
}
