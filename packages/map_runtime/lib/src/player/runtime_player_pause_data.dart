import 'dart:collection';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_pokemon_summary.dart';

enum RuntimePlayerPauseSection {
  root,
  party,
  bag,
  pokedex,
  quests,
  map,
  profile,
  options,
}

final class RuntimePlayerPokedexProgressSnapshot {
  const RuntimePlayerPokedexProgressSnapshot({
    required this.seen,
    required this.caught,
    required this.total,
  })  : assert(caught >= 0),
        assert(seen >= caught),
        assert(total >= seen);

  final int seen;
  final int caught;
  final int total;
}

final class RuntimePlayerProfileSnapshot {
  RuntimePlayerProfileSnapshot({
    required this.playerName,
    required this.currentMapId,
    required this.money,
    this.playtimeSeconds,
    this.locationName,
    this.avatarCharacterId,
    this.portraitFilePath,
    this.pronounSet = PlayerPronounSet.neutral,
    List<CharacterPortraitVariant> portraits = const [],
    List<String> badgeIds = const [],
    List<RuntimePlayerProfileBadgeSnapshot> badges = const [],
    this.badgeTotal,
    this.pokedex,
    this.currencyLabel,
  })  : portraits = List<CharacterPortraitVariant>.unmodifiable(portraits),
        badgeIds = List<String>.unmodifiable(badgeIds),
        badges = List<RuntimePlayerProfileBadgeSnapshot>.unmodifiable(badges),
        assert(playerName != ''),
        assert(money >= 0),
        assert(playtimeSeconds == null || playtimeSeconds >= 0),
        assert(badgeTotal == null || badgeTotal >= 0);

  final String playerName;
  final String currentMapId;
  final int money;
  final int? playtimeSeconds;
  final String? locationName;
  final String? avatarCharacterId;
  final String? portraitFilePath;
  final PlayerPronounSet pronounSet;
  final List<CharacterPortraitVariant> portraits;
  final List<String> badgeIds;
  final List<RuntimePlayerProfileBadgeSnapshot> badges;
  final int? badgeTotal;
  final RuntimePlayerPokedexProgressSnapshot? pokedex;
  final String? currencyLabel;
}

final class RuntimePlayerProfileBadgeSnapshot {
  const RuntimePlayerProfileBadgeSnapshot({
    required this.id,
    required this.label,
    this.iconFilePath,
  });

  final String id;
  final String label;
  final String? iconFilePath;
}

final class RuntimePlayerBagItemSnapshot {
  const RuntimePlayerBagItemSnapshot({
    required this.itemId,
    required this.quantity,
    required this.sortOrder,
    this.pocketId,
    this.description,
    this.iconFilePath,
  })  : assert(itemId != ''),
        assert(quantity > 0),
        assert(sortOrder >= 0);

  final String itemId;
  final int quantity;
  final int sortOrder;
  final String? pocketId;
  final String? description;
  final String? iconFilePath;
}

final class RuntimePlayerBagPocketSnapshot {
  const RuntimePlayerBagPocketSnapshot({required this.id, required this.label});

  final String id;
  final String label;
}

enum RuntimePlayerPokedexKnowledge { unknown, seen, caught }

final class RuntimePlayerPokedexEntrySnapshot {
  RuntimePlayerPokedexEntrySnapshot({
    required this.knowledge,
    this.nationalDex,
    this.identity,
    this.media = const RuntimePokemonSummaryMediaSnapshot(),
    this.description,
    List<String> typeIds = const [],
  }) : typeIds = List<String>.unmodifiable(typeIds) {
    if (knowledge == RuntimePlayerPokedexKnowledge.unknown &&
        (identity != null ||
            typeIds.isNotEmpty ||
            media.thumbnail != null ||
            media.illustration != null ||
            description != null)) {
      throw ArgumentError('Unknown species cannot expose private details.');
    }
  }

  final RuntimePlayerPokedexKnowledge knowledge;
  final int? nationalDex;
  final RuntimePokemonMediaIdentity? identity;
  final RuntimePokemonSummaryMediaSnapshot media;
  final String? description;
  final List<String> typeIds;
}

enum RuntimePlayerBagUseTargetKind {
  partyMember,
  partyMove,
  partyMoveReplacement,
}

final class RuntimePlayerBagItemActionSnapshot {
  RuntimePlayerBagItemActionSnapshot({
    required this.itemTargetId,
    required this.targetKind,
    required this.usability,
    required this.isEnabled,
    this.unavailableReason,
    this.learnedMoveLabel,
    Map<String, String> unavailablePartyTargetReasons = const {},
    Set<String>? eligiblePartyTargetIds,
  })  : unavailablePartyTargetReasons =
            Map.unmodifiable(unavailablePartyTargetReasons),
        eligiblePartyTargetIds = eligiblePartyTargetIds == null
            ? null
            : Set<String>.unmodifiable(eligiblePartyTargetIds) {
    if (itemTargetId.trim().isEmpty) {
      throw ArgumentError.value(
        itemTargetId,
        'itemTargetId',
        'must not be empty',
      );
    }
    if (!isEnabled &&
        (unavailableReason == null || unavailableReason!.trim().isEmpty)) {
      throw ArgumentError(
        'A disabled bag action requires a player-safe explanation.',
      );
    }
  }

  final String itemTargetId;
  final RuntimePlayerBagUseTargetKind targetKind;
  final ItemUsabilityState usability;
  final bool isEnabled;
  final String? unavailableReason;
  final Set<String>? eligiblePartyTargetIds;
  final String? learnedMoveLabel;
  final Map<String, String> unavailablePartyTargetReasons;

  bool allowsPartyTarget(String targetId) =>
      !unavailablePartyTargetReasons.containsKey(targetId) &&
      (eligiblePartyTargetIds?.contains(targetId) ?? true);
}

final class RuntimePlayerBagMoveTargetSnapshot {
  const RuntimePlayerBagMoveTargetSnapshot({
    required this.targetId,
    required this.label,
    this.subtitle,
  })  : assert(targetId != ''),
        assert(label != '');

  final String targetId;
  final String label;
  final String? subtitle;
}

final class RuntimePlayerBagPartyTargetSnapshot {
  RuntimePlayerBagPartyTargetSnapshot({
    required this.targetId,
    required this.label,
    this.subtitle,
    this.pokemonSummary,
    this.requiresMoveReplacement = false,
    List<RuntimePlayerBagMoveTargetSnapshot> moves =
        const <RuntimePlayerBagMoveTargetSnapshot>[],
  })  : assert(targetId != ''),
        assert(label != ''),
        moves = List<RuntimePlayerBagMoveTargetSnapshot>.unmodifiable(moves);

  final String targetId;
  final String label;
  final String? subtitle;
  final List<RuntimePlayerBagMoveTargetSnapshot> moves;
  final RuntimePokemonSummarySnapshot? pokemonSummary;
  final bool requiresMoveReplacement;
}

final class RuntimePlayerHeldItemOptionSnapshot {
  const RuntimePlayerHeldItemOptionSnapshot({
    required this.itemTargetId,
    required this.label,
  })  : assert(itemTargetId != ''),
        assert(label != '');

  final String itemTargetId;
  final String label;
}

final class RuntimePlayerHeldItemActionSnapshot {
  RuntimePlayerHeldItemActionSnapshot({
    required this.partyTargetId,
    this.currentItemLabel,
    List<RuntimePlayerHeldItemOptionSnapshot> options =
        const <RuntimePlayerHeldItemOptionSnapshot>[],
  })  : assert(partyTargetId != ''),
        assert(currentItemLabel == null || currentItemLabel != ''),
        options = List<RuntimePlayerHeldItemOptionSnapshot>.unmodifiable(
          options,
        );

  final String partyTargetId;
  final String? currentItemLabel;
  final List<RuntimePlayerHeldItemOptionSnapshot> options;

  bool get hasCurrentItem => currentItemLabel != null;
}

/// Generic data-only row rendered by a runtime-owned pause detail surface.
final class RuntimePlayerDetailEntrySnapshot {
  RuntimePlayerDetailEntrySnapshot({
    required this.id,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.progress,
    this.bagAction,
    this.heldItemAction,
    this.pokemonSummary,
    this.bagItem,
    this.pokedexEntry,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Detail entry id and title must not be empty.');
    }
    if (progress case final value? when value < 0 || value > 1) {
      throw ArgumentError.value(
        value,
        'progress',
        'must be between zero and one',
      );
    }
  }

  final String id;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final double? progress;
  final RuntimePlayerBagItemActionSnapshot? bagAction;
  final RuntimePlayerHeldItemActionSnapshot? heldItemAction;
  final RuntimePlayerBagItemSnapshot? bagItem;
  final RuntimePlayerPokedexEntrySnapshot? pokedexEntry;

  /// Présente uniquement sur une entrée d'équipe : la fiche canonique que le PC
  /// affiche pour le même individu.
  final RuntimePokemonSummarySnapshot? pokemonSummary;
}

/// Data-only presentation for one non-root pause section.
final class RuntimePlayerPauseDetailSnapshot {
  RuntimePlayerPauseDetailSnapshot({
    required this.section,
    required this.title,
    List<RuntimePlayerDetailEntrySnapshot> entries =
        const <RuntimePlayerDetailEntrySnapshot>[],
    this.emptyMessage,
    this.message,
    this.profile,
    this.bagMoney,
    this.bagCurrencyLabel,
    List<RuntimePlayerBagPocketSnapshot> bagPockets = const [],
    List<RuntimePlayerBagPartyTargetSnapshot> bagTargets =
        const <RuntimePlayerBagPartyTargetSnapshot>[],
  })  : bagPockets = List.unmodifiable(bagPockets),
        entries = List<RuntimePlayerDetailEntrySnapshot>.unmodifiable(entries),
        bagTargets =
            List<RuntimePlayerBagPartyTargetSnapshot>.unmodifiable(bagTargets) {
    if (section == RuntimePlayerPauseSection.root) {
      throw ArgumentError.value(
        section,
        'section',
        'the pause root is navigation, not a detail surface',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
  }

  final RuntimePlayerPauseSection section;
  final String title;
  final List<RuntimePlayerDetailEntrySnapshot> entries;
  final String? emptyMessage;
  final String? message;
  final RuntimePlayerProfileSnapshot? profile;
  final List<RuntimePlayerBagPartyTargetSnapshot> bagTargets;
  final List<RuntimePlayerBagPocketSnapshot> bagPockets;
  final int? bagMoney;
  final String? bagCurrencyLabel;

  RuntimePlayerPauseDetailSnapshot withMessage(String? message) =>
      RuntimePlayerPauseDetailSnapshot(
        section: section,
        title: title,
        entries: entries,
        emptyMessage: emptyMessage,
        message: message,
        profile: profile,
        bagTargets: bagTargets,
        bagPockets: bagPockets,
        bagMoney: bagMoney,
        bagCurrencyLabel: bagCurrencyLabel,
      );
}

final class RuntimePlayerPauseCommand {
  const RuntimePlayerPauseCommand.useBagItem({
    required this.itemTargetId,
    required this.partyTargetId,
    this.moveTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.useBagItem,
        secondPartyTargetId = null;

  const RuntimePlayerPauseCommand.equipHeldItem({
    required this.itemTargetId,
    required this.partyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.equipHeldItem,
        moveTargetId = null,
        secondPartyTargetId = null;

  const RuntimePlayerPauseCommand.unequipHeldItem({
    required this.partyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.unequipHeldItem,
        itemTargetId = '',
        moveTargetId = null,
        secondPartyTargetId = null;

  /// BETA-PTY-002. Échange deux membres de l'équipe.
  ///
  /// Les cibles sont des identifiants de cible pause (`pokemon.<individualId>`
  /// pour le ciblage stable, `party.<index>` en repli) : la sélection suit
  /// l'individu, pas sa position, donc un réordonnancement antérieur ne peut
  /// pas faire échanger le mauvais Pokémon.
  const RuntimePlayerPauseCommand.reorderPartyMember({
    required this.partyTargetId,
    required String this.secondPartyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.reorderPartyMember,
        itemTargetId = '',
        moveTargetId = null;

  /// BETA-PTY-002. Place un membre en tête d'équipe.
  const RuntimePlayerPauseCommand.setPartyLead({
    required this.partyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.setPartyLead,
        itemTargetId = '',
        moveTargetId = null,
        secondPartyTargetId = null;

  final RuntimePlayerPauseCommandKind kind;
  final String itemTargetId;
  final String partyTargetId;
  final String? moveTargetId;

  /// Seconde cible d'un échange, nulle pour les autres commandes.
  final String? secondPartyTargetId;
}

enum RuntimePlayerPauseCommandKind {
  useBagItem,
  equipHeldItem,
  unequipHeldItem,
  reorderPartyMember,
  setPartyLead,
}

enum RuntimePlayerPauseCommandStatus { accepted, unavailable, failed }

final class RuntimePlayerPauseCommandResult {
  const RuntimePlayerPauseCommandResult({
    required this.status,
    required this.safeMessage,
  });

  final RuntimePlayerPauseCommandStatus status;
  final String safeMessage;
}

abstract interface class RuntimePlayerPauseCommandPort {
  Future<RuntimePlayerPauseCommandResult> dispatchPauseCommand(
    RuntimePlayerPauseCommand command,
  );
}

/// Optional runtime-owned projection queried only while gameplay is paused.
///
/// The Hub and a future standalone host both consume the same data-only
/// snapshots. Neither host reads or interprets the live [GameState].
abstract interface class RuntimePlayerPauseDataPort {
  Future<PlayerPauseMenuState> loadPauseMenuState();

  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      loadPauseDetails();
}

Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>
    immutableRuntimePlayerPauseDetails(
  Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot> details,
) {
  return UnmodifiableMapView<RuntimePlayerPauseSection,
      RuntimePlayerPauseDetailSnapshot>(
    Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>.from(
      details,
    ),
  );
}
