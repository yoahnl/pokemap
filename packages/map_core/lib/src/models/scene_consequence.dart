import 'package:meta/meta.dart' show immutable;

import 'enums.dart';
import 'narrative_value.dart';
import 'project_presentation_profile.dart';
import 'scene_finish_game_contract.dart';

enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
  completeStoryStep,
  giveItem,
  takeItem,
  giveMoney,
  grantRailCurrency,
  grantRailStamp,
  givePokemon,
  giveConfiguredStarter,
  healParty,
  awardBadge,
  unlockFieldAbility,
  setNpcPresence,
  setPauseMenuEntryVisibility,
  finishGame,
}

@immutable
abstract base class SceneConsequence {
  const SceneConsequence();

  factory SceneConsequence.setFact({
    required String factId,
    required bool value,
    String? label,
    String? notes,
  }) = SceneSetFactConsequence;

  factory SceneConsequence.setFactValue({
    required String factId,
    required NarrativeValue value,
    String? label,
    String? notes,
  }) = SceneSetFactConsequence.typed;

  factory SceneConsequence.markEventConsumed({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  }) = SceneMarkEventConsumedConsequence;

  factory SceneConsequence.completeStoryStep({
    required String stepId,
    String? label,
    String? notes,
  }) = SceneCompleteStoryStepConsequence;

  factory SceneConsequence.giveItem({
    required String itemId,
    required int quantity,
    String? label,
    String? notes,
  }) = SceneGiveItemConsequence;

  factory SceneConsequence.takeItem({
    required String itemId,
    required int quantity,
    String? label,
    String? notes,
  }) = SceneTakeItemConsequence;

  factory SceneConsequence.giveMoney({
    required int amount,
    String? label,
    String? notes,
  }) = SceneGiveMoneyConsequence;

  factory SceneConsequence.grantRailCurrency({
    required String semanticCurrencyId,
    required int amount,
    String? label,
    String? notes,
  }) = SceneGrantRailCurrencyConsequence;

  factory SceneConsequence.grantRailStamp({
    required String stampId,
    String? label,
    String? notes,
  }) = SceneGrantRailStampConsequence;

  factory SceneConsequence.givePokemon({
    required String speciesId,
    required String formId,
    required int level,
    required int currentHp,
    String natureId,
    String abilityId,
    String nickname,
    int friendship,
    String? label,
    String? notes,
  }) = SceneGivePokemonConsequence;

  factory SceneConsequence.giveConfiguredStarter({
    required String starterOptionId,
    String? label,
    String? notes,
  }) = SceneGiveConfiguredStarterConsequence;

  factory SceneConsequence.healParty({
    String? label,
    String? notes,
  }) = SceneHealPartyConsequence;

  factory SceneConsequence.awardBadge({
    required String badgeId,
    String? label,
    String? notes,
  }) = SceneAwardBadgeConsequence;

  factory SceneConsequence.unlockFieldAbility({
    required FieldAbility ability,
    String? label,
    String? notes,
  }) = SceneUnlockFieldAbilityConsequence;

  factory SceneConsequence.setNpcPresence({
    required String mapId,
    required String entityId,
    required bool present,
    String? label,
    String? notes,
  }) = SceneSetNpcPresenceConsequence;

  factory SceneConsequence.setPauseMenuEntryVisibility({
    required ProjectPauseActionId actionId,
    required bool visible,
    String? label,
    String? notes,
  }) = SceneSetPauseMenuEntryVisibilityConsequence;

  factory SceneConsequence.finishGame({
    int contractVersion,
    required String endingId,
    required SceneGameCompletionOutcome outcome,
    SceneFinishGameCommitPolicy commitPolicy,
    required SceneFinishGameResult result,
    SceneFinishGameCredits? credits,
    required ScenePostGamePolicy postGamePolicy,
    String? label,
    String? notes,
  }) = SceneFinishGameConsequence;

  factory SceneConsequence.fromJson(Map<String, dynamic> json) {
    final kind = _readKind(json['kind']);
    return switch (kind) {
      SceneConsequenceKind.setFact => SceneSetFactConsequence.fromJson(json),
      SceneConsequenceKind.markEventConsumed =>
        SceneMarkEventConsumedConsequence.fromJson(json),
      SceneConsequenceKind.completeStoryStep =>
        SceneCompleteStoryStepConsequence.fromJson(json),
      SceneConsequenceKind.giveItem => SceneGiveItemConsequence.fromJson(json),
      SceneConsequenceKind.takeItem => SceneTakeItemConsequence.fromJson(json),
      SceneConsequenceKind.giveMoney =>
        SceneGiveMoneyConsequence.fromJson(json),
      SceneConsequenceKind.grantRailCurrency =>
        SceneGrantRailCurrencyConsequence.fromJson(json),
      SceneConsequenceKind.grantRailStamp =>
        SceneGrantRailStampConsequence.fromJson(json),
      SceneConsequenceKind.givePokemon =>
        SceneGivePokemonConsequence.fromJson(json),
      SceneConsequenceKind.giveConfiguredStarter =>
        SceneGiveConfiguredStarterConsequence.fromJson(json),
      SceneConsequenceKind.healParty =>
        SceneHealPartyConsequence.fromJson(json),
      SceneConsequenceKind.awardBadge =>
        SceneAwardBadgeConsequence.fromJson(json),
      SceneConsequenceKind.unlockFieldAbility =>
        SceneUnlockFieldAbilityConsequence.fromJson(json),
      SceneConsequenceKind.setNpcPresence =>
        SceneSetNpcPresenceConsequence.fromJson(json),
      SceneConsequenceKind.setPauseMenuEntryVisibility =>
        SceneSetPauseMenuEntryVisibilityConsequence.fromJson(json),
      SceneConsequenceKind.finishGame =>
        SceneFinishGameConsequence.fromJson(json),
    };
  }

  SceneConsequenceKind get kind;

  Map<String, dynamic> toJson();
}

@immutable
final class SceneSetFactConsequence extends SceneConsequence {
  SceneSetFactConsequence({
    required String factId,
    required bool value,
    String? label,
    String? notes,
  })  : factId = factId.trim(),
        narrativeValue = NarrativeValue.boolean(value),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  SceneSetFactConsequence.typed({
    required String factId,
    required NarrativeValue value,
    String? label,
    String? notes,
  })  : factId = factId.trim(),
        narrativeValue = value,
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneSetFactConsequence.fromJson(Map<String, dynamic> json) {
    final valueType = _readOptionalString(json, 'valueType');
    return valueType == null
        ? SceneSetFactConsequence(
            factId: _readRequiredString(json, 'factId'),
            value: _readRequiredBool(json, 'value'),
            label: _readOptionalString(json, 'label'),
            notes: _readOptionalString(json, 'notes'),
          )
        : SceneSetFactConsequence.typed(
            factId: _readRequiredString(json, 'factId'),
            value: NarrativeValue.fromJson(
              json['value'],
              declaredKind: NarrativeValueKind.fromWireName(valueType),
            ),
            label: _readOptionalString(json, 'label'),
            notes: _readOptionalString(json, 'notes'),
          );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.setFact;

  final String factId;
  final NarrativeValue narrativeValue;

  bool get value => narrativeValue.boolValue;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'factId': factId,
        if (narrativeValue.kind != NarrativeValueKind.boolean)
          'valueType': narrativeValue.kind.wireName,
        'value': narrativeValue.toJson(),
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetFactConsequence &&
          other.factId == factId &&
          other.narrativeValue == narrativeValue &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(factId, narrativeValue, label, notes);
}

@immutable
final class SceneMarkEventConsumedConsequence extends SceneConsequence {
  SceneMarkEventConsumedConsequence({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  })  : mapId = mapId.trim(),
        eventId = eventId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneMarkEventConsumedConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    return SceneMarkEventConsumedConsequence(
      mapId: _readRequiredString(json, 'mapId'),
      eventId: _readRequiredString(json, 'eventId'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.markEventConsumed;

  final String mapId;
  final String eventId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'mapId': mapId,
        'eventId': eventId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneMarkEventConsumedConsequence &&
          other.mapId == mapId &&
          other.eventId == eventId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(mapId, eventId, label, notes);
}

@immutable
final class SceneCompleteStoryStepConsequence extends SceneConsequence {
  SceneCompleteStoryStepConsequence({
    required String stepId,
    String? label,
    String? notes,
  })  : stepId = stepId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneCompleteStoryStepConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    return SceneCompleteStoryStepConsequence(
      stepId: _readRequiredString(json, 'stepId'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.completeStoryStep;

  final String stepId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'stepId': stepId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneCompleteStoryStepConsequence &&
          other.stepId == stepId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(stepId, label, notes);
}

@immutable
final class SceneGiveItemConsequence extends SceneConsequence {
  SceneGiveItemConsequence({
    required String itemId,
    required this.quantity,
    String? label,
    String? notes,
  })  : itemId = itemId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGiveItemConsequence.fromJson(Map<String, dynamic> json) {
    return SceneGiveItemConsequence(
      itemId: _readRequiredString(json, 'itemId'),
      quantity: _readRequiredInt(json, 'quantity'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.giveItem;

  final String itemId;
  final int quantity;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'itemId': itemId,
        'quantity': quantity,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGiveItemConsequence &&
          other.itemId == itemId &&
          other.quantity == quantity &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(itemId, quantity, label, notes);
}

@immutable
final class SceneTakeItemConsequence extends SceneConsequence {
  SceneTakeItemConsequence({
    required String itemId,
    required this.quantity,
    String? label,
    String? notes,
  })  : itemId = itemId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneTakeItemConsequence.fromJson(Map<String, dynamic> json) {
    return SceneTakeItemConsequence(
      itemId: _readRequiredString(json, 'itemId'),
      quantity: _readRequiredInt(json, 'quantity'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.takeItem;

  final String itemId;
  final int quantity;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'itemId': itemId,
        'quantity': quantity,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneTakeItemConsequence &&
          other.itemId == itemId &&
          other.quantity == quantity &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(itemId, quantity, label, notes);
}

@immutable
final class SceneGiveMoneyConsequence extends SceneConsequence {
  SceneGiveMoneyConsequence({
    required this.amount,
    String? label,
    String? notes,
  })  : label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGiveMoneyConsequence.fromJson(Map<String, dynamic> json) {
    return SceneGiveMoneyConsequence(
      amount: _readRequiredInt(json, 'amount'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.giveMoney;

  final int amount;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'amount': amount,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGiveMoneyConsequence &&
          other.amount == amount &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(amount, label, notes);
}

@immutable
final class SceneGrantRailCurrencyConsequence extends SceneConsequence {
  SceneGrantRailCurrencyConsequence({
    required String semanticCurrencyId,
    required this.amount,
    String? label,
    String? notes,
  })  : semanticCurrencyId = semanticCurrencyId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGrantRailCurrencyConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    return SceneGrantRailCurrencyConsequence(
      semanticCurrencyId: _readRequiredString(json, 'semanticCurrencyId'),
      amount: _readRequiredInt(json, 'amount'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.grantRailCurrency;

  final String semanticCurrencyId;
  final int amount;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'semanticCurrencyId': semanticCurrencyId,
        'amount': amount,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGrantRailCurrencyConsequence &&
          other.semanticCurrencyId == semanticCurrencyId &&
          other.amount == amount &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(semanticCurrencyId, amount, label, notes);
}

@immutable
final class SceneGrantRailStampConsequence extends SceneConsequence {
  SceneGrantRailStampConsequence({
    required String stampId,
    String? label,
    String? notes,
  })  : stampId = stampId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGrantRailStampConsequence.fromJson(Map<String, dynamic> json) {
    return SceneGrantRailStampConsequence(
      stampId: _readRequiredString(json, 'stampId'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.grantRailStamp;

  final String stampId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'stampId': stampId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGrantRailStampConsequence &&
          other.stampId == stampId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(stampId, label, notes);
}

@immutable
final class SceneGivePokemonConsequence extends SceneConsequence {
  SceneGivePokemonConsequence({
    required String speciesId,
    required String formId,
    required this.level,
    required this.currentHp,
    this.currentHpIsLegacyFallback = false,
    String natureId = 'hardy',
    String abilityId = 'unknown',
    String nickname = '',
    this.friendship = 0,
    String? label,
    String? notes,
  })  : speciesId = speciesId.trim(),
        formId = formId.trim(),
        natureId = natureId.trim(),
        abilityId = abilityId.trim(),
        nickname = nickname.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGivePokemonConsequence.fromJson(Map<String, dynamic> json) {
    final level = _readRequiredInt(json, 'level');
    final hasAuthoredCurrentHp = json.containsKey('currentHp');
    return SceneGivePokemonConsequence(
      speciesId: _readRequiredString(json, 'speciesId'),
      formId: _readRequiredString(json, 'formId'),
      level: level,
      currentHp:
          hasAuthoredCurrentHp ? _readRequiredInt(json, 'currentHp') : level,
      currentHpIsLegacyFallback: !hasAuthoredCurrentHp,
      natureId: _readOptionalString(json, 'natureId') ?? 'hardy',
      abilityId: _readOptionalString(json, 'abilityId') ?? 'unknown',
      nickname: _readOptionalString(json, 'nickname') ?? '',
      friendship: json.containsKey('friendship')
          ? _readRequiredInt(json, 'friendship')
          : 0,
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.givePokemon;

  final String speciesId;
  final String formId;
  final int level;
  final int currentHp;
  final bool currentHpIsLegacyFallback;
  final String natureId;
  final String abilityId;
  final String nickname;
  final int friendship;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'speciesId': speciesId,
        'formId': formId,
        'level': level,
        if (!currentHpIsLegacyFallback) 'currentHp': currentHp,
        'natureId': natureId,
        'abilityId': abilityId,
        if (nickname.isNotEmpty) 'nickname': nickname,
        if (friendship != 0) 'friendship': friendship,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGivePokemonConsequence &&
          other.speciesId == speciesId &&
          other.formId == formId &&
          other.level == level &&
          other.currentHp == currentHp &&
          other.currentHpIsLegacyFallback == currentHpIsLegacyFallback &&
          other.natureId == natureId &&
          other.abilityId == abilityId &&
          other.nickname == nickname &&
          other.friendship == friendship &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        speciesId,
        formId,
        level,
        currentHp,
        currentHpIsLegacyFallback,
        natureId,
        abilityId,
        nickname,
        friendship,
        label,
        notes,
      );
}

@immutable
final class SceneGiveConfiguredStarterConsequence extends SceneConsequence {
  SceneGiveConfiguredStarterConsequence({
    required String starterOptionId,
    String? label,
    String? notes,
  })  : starterOptionId = starterOptionId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneGiveConfiguredStarterConsequence.fromJson(
    Map<String, dynamic> json,
  ) {
    return SceneGiveConfiguredStarterConsequence(
      starterOptionId: _readRequiredString(json, 'starterOptionId'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.giveConfiguredStarter;

  final String starterOptionId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'starterOptionId': starterOptionId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneGiveConfiguredStarterConsequence &&
          other.starterOptionId == starterOptionId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(starterOptionId, label, notes);
}

@immutable
final class SceneHealPartyConsequence extends SceneConsequence {
  SceneHealPartyConsequence({String? label, String? notes})
      : label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneHealPartyConsequence.fromJson(Map<String, dynamic> json) =>
      SceneHealPartyConsequence(
        label: _readOptionalString(json, 'label'),
        notes: _readOptionalString(json, 'notes'),
      );

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.healParty;

  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneHealPartyConsequence &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(label, notes);
}

@immutable
final class SceneAwardBadgeConsequence extends SceneConsequence {
  SceneAwardBadgeConsequence({
    required String badgeId,
    String? label,
    String? notes,
  })  : badgeId = badgeId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneAwardBadgeConsequence.fromJson(Map<String, dynamic> json) =>
      SceneAwardBadgeConsequence(
        badgeId: _readRequiredString(json, 'badgeId'),
        label: _readOptionalString(json, 'label'),
        notes: _readOptionalString(json, 'notes'),
      );

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.awardBadge;

  final String badgeId;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'badgeId': badgeId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneAwardBadgeConsequence &&
          other.badgeId == badgeId &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(badgeId, label, notes);
}

@immutable
final class SceneUnlockFieldAbilityConsequence extends SceneConsequence {
  SceneUnlockFieldAbilityConsequence({
    required this.ability,
    String? label,
    String? notes,
  })  : label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneUnlockFieldAbilityConsequence.fromJson(
    Map<String, dynamic> json,
  ) =>
      SceneUnlockFieldAbilityConsequence(
        ability: _readFieldAbility(json, 'abilityId'),
        label: _readOptionalString(json, 'label'),
        notes: _readOptionalString(json, 'notes'),
      );

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.unlockFieldAbility;

  final FieldAbility ability;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'abilityId': ability.moveId,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneUnlockFieldAbilityConsequence &&
          other.ability == ability &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(ability, label, notes);
}

@immutable
final class SceneSetNpcPresenceConsequence extends SceneConsequence {
  SceneSetNpcPresenceConsequence({
    required String mapId,
    required String entityId,
    required this.present,
    String? label,
    String? notes,
  })  : mapId = mapId.trim(),
        entityId = entityId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneSetNpcPresenceConsequence.fromJson(
    Map<String, dynamic> json,
  ) =>
      SceneSetNpcPresenceConsequence(
        mapId: _readRequiredString(json, 'mapId'),
        entityId: _readRequiredString(json, 'entityId'),
        present: _readRequiredBool(json, 'present'),
        label: _readOptionalString(json, 'label'),
        notes: _readOptionalString(json, 'notes'),
      );

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.setNpcPresence;

  final String mapId;
  final String entityId;
  final bool present;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'mapId': mapId,
        'entityId': entityId,
        'present': present,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetNpcPresenceConsequence &&
          other.mapId == mapId &&
          other.entityId == entityId &&
          other.present == present &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(mapId, entityId, present, label, notes);
}

@immutable
final class SceneSetPauseMenuEntryVisibilityConsequence
    extends SceneConsequence {
  SceneSetPauseMenuEntryVisibilityConsequence({
    required this.actionId,
    required this.visible,
    String? label,
    String? notes,
  })  : label = _trimOptional(label),
        notes = _trimOptional(notes) {
    if (actionId == ProjectPauseActionId.resume) {
      throw ArgumentError.value(
        actionId,
        'actionId',
        'Resume visibility cannot be changed',
      );
    }
  }

  factory SceneSetPauseMenuEntryVisibilityConsequence.fromJson(
    Map<String, dynamic> json,
  ) =>
      SceneSetPauseMenuEntryVisibilityConsequence(
        actionId: _readPauseActionId(json, 'actionId'),
        visible: _readRequiredBool(json, 'visible'),
        label: _readOptionalString(json, 'label'),
        notes: _readOptionalString(json, 'notes'),
      );

  @override
  SceneConsequenceKind get kind =>
      SceneConsequenceKind.setPauseMenuEntryVisibility;

  final ProjectPauseActionId actionId;
  final bool visible;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'actionId': actionId.name,
        'visible': visible,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetPauseMenuEntryVisibilityConsequence &&
          other.actionId == actionId &&
          other.visible == visible &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(actionId, visible, label, notes);
}

/// Terminal authored consequence.
///
/// [endingId] forms the idempotency key with the active session. The only V1
/// commit policy requires the final checkpoint to be persisted before result
/// or credits presentation. A null [credits] value asks the runtime to build
/// its safe project-metadata fallback.
@immutable
final class SceneFinishGameConsequence extends SceneConsequence {
  SceneFinishGameConsequence({
    this.contractVersion = sceneFinishGameContractVersion,
    required String endingId,
    required this.outcome,
    this.commitPolicy = SceneFinishGameCommitPolicy.persistBeforePresentation,
    required this.result,
    this.credits,
    required this.postGamePolicy,
    String? label,
    String? notes,
  })  : endingId = endingId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes) {
    if (contractVersion != sceneFinishGameContractVersion) {
      throw ArgumentError.value(
        contractVersion,
        'contractVersion',
        'Only Finish Game contract version '
            '$sceneFinishGameContractVersion is supported.',
      );
    }
  }

  factory SceneFinishGameConsequence.fromJson(Map<String, dynamic> json) {
    final version = json['contractVersion'];
    if (version == null) {
      return SceneFinishGameConsequence._fromLegacyJson(json);
    }
    if (version is! int || version != sceneFinishGameContractVersion) {
      throw FormatException(
        'Unsupported Finish Game contractVersion: $version.',
      );
    }
    return SceneFinishGameConsequence(
      contractVersion: version,
      endingId: _readRequiredString(json, 'endingId'),
      outcome: _readGameCompletionOutcome(json['outcome']),
      commitPolicy: _readFinishGameCommitPolicy(json['commitPolicy']),
      result: SceneFinishGameResult.fromJson(json['result']),
      credits: json['credits'] == null
          ? null
          : SceneFinishGameCredits.fromJson(json['credits']),
      postGamePolicy: _readPostGamePolicy(json['postGamePolicy']),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  factory SceneFinishGameConsequence._fromLegacyJson(
    Map<String, dynamic> json,
  ) {
    final rawDetails = json['resultDetails'];
    if (rawDetails != null &&
        (rawDetails is! List || rawDetails.any((entry) => entry is! String))) {
      throw const FormatException(
        'Legacy Finish Game resultDetails must be a list of strings.',
      );
    }
    final hasCredits = const [
      'creditsTitle',
      'creditsAuthor',
      'creditsEndingLabel',
    ].any(json.containsKey);
    return SceneFinishGameConsequence(
      endingId: _readRequiredString(json, 'endingId'),
      outcome: _readGameCompletionOutcome(json['outcome']),
      result: SceneFinishGameResult(
        title: SceneLocalizedText(
          fallback: _readRequiredString(json, 'resultTitle'),
        ),
        summary: SceneLocalizedText(
          fallback: _readRequiredString(json, 'resultSummary'),
        ),
        details: [
          for (final detail in (rawDetails as List? ?? const []))
            SceneLocalizedText(fallback: detail as String),
        ],
      ),
      credits: hasCredits
          ? SceneFinishGameCredits(
              title: SceneLocalizedText(
                fallback: _readRequiredString(json, 'creditsTitle'),
              ),
              author: _readRequiredString(json, 'creditsAuthor'),
              endingLabel: SceneLocalizedText(
                fallback: _readRequiredString(json, 'creditsEndingLabel'),
              ),
              skippable: json['creditsSkippable'] == null
                  ? true
                  : _readRequiredBool(json, 'creditsSkippable'),
            )
          : null,
      postGamePolicy: json['postGamePolicy'] == null
          ? ScenePostGamePolicy.returnToTitle
          : _readPostGamePolicy(json['postGamePolicy']),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.finishGame;

  final int contractVersion;
  final String endingId;
  final SceneGameCompletionOutcome outcome;
  final SceneFinishGameCommitPolicy commitPolicy;
  final SceneFinishGameResult result;
  final SceneFinishGameCredits? credits;
  final ScenePostGamePolicy postGamePolicy;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'contractVersion': contractVersion,
        'endingId': endingId,
        'outcome': outcome.name,
        'commitPolicy': commitPolicy.name,
        'result': result.toJson(),
        'credits': credits?.toJson(),
        'postGamePolicy': postGamePolicy.name,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneFinishGameConsequence &&
          other.contractVersion == contractVersion &&
          other.endingId == endingId &&
          other.outcome == outcome &&
          other.commitPolicy == commitPolicy &&
          other.result == result &&
          other.credits == credits &&
          other.postGamePolicy == postGamePolicy &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        contractVersion,
        endingId,
        outcome,
        commitPolicy,
        result,
        credits,
        postGamePolicy,
        label,
        notes,
      );
}

SceneConsequenceKind _readKind(Object? value) {
  if (value is! String) {
    throw FormatException(
      'SceneConsequence.kind must be one of: '
      '${SceneConsequenceKind.values.map(_kindToJson).join(', ')}.',
    );
  }
  for (final kind in SceneConsequenceKind.values) {
    if (_kindToJson(kind) == value) {
      return kind;
    }
  }
  throw FormatException('Unknown SceneConsequence.kind: $value.');
}

String _kindToJson(SceneConsequenceKind kind) {
  return switch (kind) {
    SceneConsequenceKind.setFact => 'setFact',
    SceneConsequenceKind.markEventConsumed => 'markEventConsumed',
    SceneConsequenceKind.completeStoryStep => 'completeStoryStep',
    SceneConsequenceKind.giveItem => 'giveItem',
    SceneConsequenceKind.takeItem => 'takeItem',
    SceneConsequenceKind.giveMoney => 'giveMoney',
    SceneConsequenceKind.grantRailCurrency => 'grantRailCurrency',
    SceneConsequenceKind.grantRailStamp => 'grantRailStamp',
    SceneConsequenceKind.givePokemon => 'givePokemon',
    SceneConsequenceKind.giveConfiguredStarter => 'giveConfiguredStarter',
    SceneConsequenceKind.healParty => 'healParty',
    SceneConsequenceKind.awardBadge => 'awardBadge',
    SceneConsequenceKind.unlockFieldAbility => 'unlockFieldAbility',
    SceneConsequenceKind.setNpcPresence => 'setNpcPresence',
    SceneConsequenceKind.setPauseMenuEntryVisibility =>
      'setPauseMenuEntryVisibility',
    SceneConsequenceKind.finishGame => 'finishGame',
  };
}

ProjectPauseActionId _readPauseActionId(
  Map<String, dynamic> json,
  String key,
) {
  final value = _readRequiredString(json, key);
  for (final actionId in ProjectPauseActionId.values) {
    if (actionId.name == value) return actionId;
  }
  throw FormatException('Unknown SceneConsequence.$key: $value.');
}

SceneGameCompletionOutcome _readGameCompletionOutcome(Object? value) {
  return _readNamedEnum(
    value,
    SceneGameCompletionOutcome.values,
    'outcome',
  );
}

SceneFinishGameCommitPolicy _readFinishGameCommitPolicy(Object? value) {
  return _readNamedEnum(
    value,
    SceneFinishGameCommitPolicy.values,
    'commitPolicy',
  );
}

ScenePostGamePolicy _readPostGamePolicy(Object? value) {
  return _readNamedEnum(
    value,
    ScenePostGamePolicy.values,
    'postGamePolicy',
  );
}

T _readNamedEnum<T extends Enum>(
  Object? value,
  List<T> values,
  String field,
) {
  if (value is! String) {
    throw FormatException('SceneConsequence.$field must be a string.');
  }
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unknown SceneConsequence.$field: $value.');
}

FieldAbility _readFieldAbility(Map<String, dynamic> json, String key) {
  final wireId = _readRequiredString(json, key).trim();
  for (final ability in FieldAbility.values) {
    if (ability.moveId == wireId) return ability;
  }
  throw FormatException('Unknown SceneConsequence.$key: $wireId.');
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('SceneConsequence.$key must be a string.');
  }
  return value;
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('SceneConsequence.$key must be a string.');
  }
  return value;
}

bool _readRequiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('SceneConsequence.$key must be a boolean.');
  }
  return value;
}

int _readRequiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('SceneConsequence.$key must be an integer.');
  }
  return value;
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
