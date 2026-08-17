import 'dart:collection';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_pokemon_summary.dart';

enum RuntimePlayerPauseSection {
  root,
  party,
  bag,
  pokedex,
  map,
  options,
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
    Set<String>? eligiblePartyTargetIds,
  }) : eligiblePartyTargetIds = eligiblePartyTargetIds == null
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

  bool allowsPartyTarget(String targetId) =>
      eligiblePartyTargetIds?.contains(targetId) ?? true;
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
    List<RuntimePlayerBagMoveTargetSnapshot> moves =
        const <RuntimePlayerBagMoveTargetSnapshot>[],
  })  : assert(targetId != ''),
        assert(label != ''),
        moves = List<RuntimePlayerBagMoveTargetSnapshot>.unmodifiable(moves);

  final String targetId;
  final String label;
  final String? subtitle;
  final List<RuntimePlayerBagMoveTargetSnapshot> moves;
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
    List<RuntimePlayerBagPartyTargetSnapshot> bagTargets =
        const <RuntimePlayerBagPartyTargetSnapshot>[],
  })  : entries = List<RuntimePlayerDetailEntrySnapshot>.unmodifiable(entries),
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
  final List<RuntimePlayerBagPartyTargetSnapshot> bagTargets;

  RuntimePlayerPauseDetailSnapshot withMessage(String? message) =>
      RuntimePlayerPauseDetailSnapshot(
        section: section,
        title: title,
        entries: entries,
        emptyMessage: emptyMessage,
        message: message,
        bagTargets: bagTargets,
      );
}

final class RuntimePlayerPauseCommand {
  const RuntimePlayerPauseCommand.useBagItem({
    required this.itemTargetId,
    required this.partyTargetId,
    this.moveTargetId,
  }) : kind = RuntimePlayerPauseCommandKind.useBagItem;

  const RuntimePlayerPauseCommand.equipHeldItem({
    required this.itemTargetId,
    required this.partyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.equipHeldItem,
        moveTargetId = null;

  const RuntimePlayerPauseCommand.unequipHeldItem({
    required this.partyTargetId,
  })  : kind = RuntimePlayerPauseCommandKind.unequipHeldItem,
        itemTargetId = '',
        moveTargetId = null;

  final RuntimePlayerPauseCommandKind kind;
  final String itemTargetId;
  final String partyTargetId;
  final String? moveTargetId;
}

enum RuntimePlayerPauseCommandKind {
  useBagItem,
  equipHeldItem,
  unequipHeldItem
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
