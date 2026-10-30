import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:map_battle/map_battle.dart';

/// Mode visible de la chrome battle rendue côté Flutter.
///
/// Le snapshot décrit maintenant toute la surface UI battle visible :
/// - HUD ennemi ;
/// - HUD joueur ;
/// - panneau de prompt / commandes ;
/// - mais jamais les sprites ni le décor, qui restent en Flame.
enum BattleCommandOverlayMode {
  root,
  fight,
  moveTarget,
  bag,
  bagMedicineTarget,
  bagMedicineMoveTarget,
  pokemon,
  continueOnly,

  /// Décision post-combat (apprendre une capacité, remplacer, évoluer).
  ///
  /// Recette du 2026-08-24 : publiée en mode `root`, la décision se faisait
  /// rhabiller par la personnalisation projet — les libellés « Apprendre » /
  /// « Ne pas apprendre » devenaient « Attaquer » / « Sac » à l'écran. Un
  /// mode dédié échappe au remapping des commandes racine.
  decision,
}

/// Phase de présentation canonique exposée au shell joueur.
///
/// Cette information évite à l'UI Flutter de déduire une règle métier à
/// partir du texte du prompt ou de l'état des boutons.
enum BattlePresentationPhase {
  choosingCommand,
  presentingTurn,
  forcedReplacement,
}

/// Type visuel borné d'une entrée du panneau.
///
/// Ce type n'ouvre pas un système générique de widgets battle : il décrit
/// seulement les familles actuellement rendues dans le panneau de commandes.
enum BattleCommandOverlayEntryKind {
  root,
  move,
  target,
  bag,
  party,
  medicineTarget,

  /// Choix d'une décision post-combat : un bouton neutre, sans la couleur ni
  /// l'icône des commandes racine.
  decision,
  continueAction,
}

/// Ton visuel d'une entrée.
///
/// Le host Flutter s'en sert seulement pour choisir une palette locale
/// cohérente avec l'UI battle existante.
enum BattleCommandOverlayEntryTone {
  neutral,
  attack,
  special,
  support,
  switching,
  medicine,
  capture,
  disabled,
}

class BattleCommandOverlayEntry {
  const BattleCommandOverlayEntry({
    required this.index,
    required this.kind,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.enabled,
    required this.selected,
    required this.tone,
    this.tertiaryLabel,
    this.trailingLabel,
    this.statusLabel,
    this.iconAssetPath,
  });

  final int index;
  final BattleCommandOverlayEntryKind kind;
  final String primaryLabel;
  final String secondaryLabel;
  final String? tertiaryLabel;
  final String? trailingLabel;
  final String? statusLabel;
  final bool enabled;
  final bool selected;
  final BattleCommandOverlayEntryTone tone;
  final String? iconAssetPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BattleCommandOverlayEntry &&
        other.index == index &&
        other.kind == kind &&
        other.primaryLabel == primaryLabel &&
        other.secondaryLabel == secondaryLabel &&
        other.tertiaryLabel == tertiaryLabel &&
        other.trailingLabel == trailingLabel &&
        other.statusLabel == statusLabel &&
        other.enabled == enabled &&
        other.selected == selected &&
        other.tone == tone &&
        other.iconAssetPath == iconAssetPath;
  }

  @override
  int get hashCode => Object.hash(
    index,
    kind,
    primaryLabel,
    secondaryLabel,
    tertiaryLabel,
    trailingLabel,
    statusLabel,
    enabled,
    selected,
    tone,
    iconAssetPath,
  );
}

/// Snapshot immutable d'un HUD battle rendu côté Flutter.
///
/// Frontière volontaire :
/// - on transporte seulement des données déjà vraies dans `BattleSession` ;
/// - aucune logique d'animation métier n'est recréée ici ;
/// - le host Flutter reçoit juste de quoi positionner et dessiner proprement
///   les deux cartouches combat.
class BattleCommandOverlayHudSnapshot {
  const BattleCommandOverlayHudSnapshot({
    required this.rect,
    required this.ownerLabel,
    required this.speciesLabel,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.isPlayerSide,
    this.displayedHp,
    this.targetDisplayedHp,
    this.hpTweenDurationMs,
    this.hpTweenRevision = 0,
    this.genderSymbol,
    this.statusLabel,
    this.experienceProgress,
    this.experienceProgressTarget,
    this.xpTweenDurationMs,
    this.xpTweenRevision = 0,
    this.isRevealed = true,
    this.isVisible = true,
    this.remainingTeamCount,
    this.teamSize,
    this.slot,
    this.combatantId = '',
  });

  /// BETA-BAT-028 : la barre d'info est-elle entrée en scène ?
  ///
  /// Parité `show_team_info` : la référence fait GLISSER les barres après le
  /// message d'apparition — l'ennemi depuis le haut, le joueur depuis le bas,
  /// en 0,2 s. Elles ne sont donc pas à l'écran au lever du rideau. Vrai par
  /// défaut : tout appelant qui l'ignore garde l'ancien comportement.
  final bool isRevealed;
  final bool isVisible;
  final int? remainingTeamCount;
  final int? teamSize;

  final Rect rect;
  final BattleSlotRef? slot;
  final String combatantId;
  BattleSlotRef get effectiveSlot =>
      slot ??
      BattleSlotRef.active(
        isPlayerSide ? BattleSideId.player : BattleSideId.enemy,
      );
  final String ownerLabel;
  final String speciesLabel;
  final int level;
  final int currentHp;
  final int maxHp;
  final bool isPlayerSide;
  final int? displayedHp;
  final int? targetDisplayedHp;
  final int? hpTweenDurationMs;
  final int hpTweenRevision;
  final String? genderSymbol;
  final String? statusLabel;
  final double? experienceProgress;
  final double? experienceProgressTarget;
  final int? xpTweenDurationMs;
  final int xpTweenRevision;

  int get effectiveDisplayedHp => displayedHp ?? currentHp;

  int get effectiveTargetDisplayedHp =>
      targetDisplayedHp ?? effectiveDisplayedHp;

  Duration? get hpTweenDuration => hpTweenDurationMs == null
      ? null
      : Duration(milliseconds: hpTweenDurationMs!);

  bool get hasHpTween =>
      hpTweenDuration != null &&
      effectiveDisplayedHp != effectiveTargetDisplayedHp;

  double? get effectiveTargetExperienceProgress =>
      experienceProgressTarget ?? experienceProgress;

  Duration? get xpTweenDuration => xpTweenDurationMs == null
      ? null
      : Duration(milliseconds: xpTweenDurationMs!);

  bool get hasXpTween =>
      xpTweenDuration != null &&
      experienceProgress != null &&
      experienceProgress != effectiveTargetExperienceProgress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BattleCommandOverlayHudSnapshot &&
        other.rect == rect &&
        other.slot == slot &&
        other.combatantId == combatantId &&
        other.ownerLabel == ownerLabel &&
        other.speciesLabel == speciesLabel &&
        other.level == level &&
        other.currentHp == currentHp &&
        other.maxHp == maxHp &&
        other.isPlayerSide == isPlayerSide &&
        other.displayedHp == displayedHp &&
        other.targetDisplayedHp == targetDisplayedHp &&
        other.hpTweenDurationMs == hpTweenDurationMs &&
        other.hpTweenRevision == hpTweenRevision &&
        other.genderSymbol == genderSymbol &&
        other.statusLabel == statusLabel &&
        other.experienceProgress == experienceProgress &&
        other.experienceProgressTarget == experienceProgressTarget &&
        other.xpTweenDurationMs == xpTweenDurationMs &&
        other.xpTweenRevision == xpTweenRevision &&
        // Sans ce champ dans l'égalité, la révélation des barres ne
        // produirait aucun nouveau snapshot : le notifier compare avant de
        // publier, et l'apparition ne serait jamais notifiée.
        other.isRevealed == isRevealed && other.isVisible == isVisible &&
        other.remainingTeamCount == remainingTeamCount && other.teamSize == teamSize;
  }

  @override
  int get hashCode => Object.hashAll([
    rect,
    ownerLabel,
    speciesLabel,
    level,
    currentHp,
    maxHp,
    isPlayerSide,
    displayedHp,
    targetDisplayedHp,
    hpTweenDurationMs,
    hpTweenRevision,
    isRevealed,
    isVisible,
    remainingTeamCount,
    teamSize,
    genderSymbol,
    statusLabel,
    experienceProgress,
    experienceProgressTarget,
    xpTweenDurationMs,
    xpTweenRevision,
    slot,
    combatantId,
  ]);
}

enum BattleCommandPanelPlacement { bottom, end, detached }

class BattleCommandOverlaySnapshot {
  const BattleCommandOverlaySnapshot({
    this.revision = 0,
    this.commandPanelPlacement = BattleCommandPanelPlacement.bottom,
    this.controllerLayout = false,
    this.portraitTouchLayout = false,
    this.rootCommandOrder = const [0, 1, 2, 3],
    this.collectionColumns,
    this.phase = BattlePresentationPhase.choosingCommand,
    this.forcedReplacement = false,
    required this.mode,
    required this.viewportSize,
    required this.panelRect,
    required this.enemyHud,
    required this.playerHud,
    required this.battleLabel,
    required this.title,
    required this.prompt,
    required this.narrationLines,
    required this.entries,
    required this.interactionsEnabled,
    required this.canGoBack,
    this.additionalHuds = const [],
    this.actorSlot,
    this.actorCombatantId,
  });

  /// Identifiant monotone d'une version visible de la présentation.
  ///
  /// Les commandes joueur transportent cette révision afin qu'une interaction
  /// différée ne puisse pas agir sur un menu devenu obsolète.
  final int revision;
  final BattleCommandPanelPlacement commandPanelPlacement;
  final bool controllerLayout;
  final bool portraitTouchLayout;
  final List<int> rootCommandOrder;
  final int? collectionColumns;
  final BattlePresentationPhase phase;
  final bool forcedReplacement;
  final BattleCommandOverlayMode mode;
  final Size viewportSize;
  final Rect panelRect;
  final BattleCommandOverlayHudSnapshot enemyHud;
  final BattleCommandOverlayHudSnapshot playerHud;
  final List<BattleCommandOverlayHudSnapshot> additionalHuds;
  final BattleSlotRef? actorSlot;
  final String? actorCombatantId;
  List<BattleCommandOverlayHudSnapshot> get combatantHuds => [
    enemyHud,
    playerHud,
    ...additionalHuds,
  ];
  final String battleLabel;
  final String title;
  final String prompt;
  final List<String> narrationLines;
  final List<BattleCommandOverlayEntry> entries;
  final bool interactionsEnabled;
  final bool canGoBack;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BattleCommandOverlaySnapshot &&
        other.revision == revision &&
        other.commandPanelPlacement == commandPanelPlacement &&
        other.controllerLayout == controllerLayout &&
        other.portraitTouchLayout == portraitTouchLayout &&
        listEquals(other.rootCommandOrder, rootCommandOrder) &&
        other.collectionColumns == collectionColumns &&
        other.phase == phase &&
        other.forcedReplacement == forcedReplacement &&
        other.mode == mode &&
        other.viewportSize == viewportSize &&
        other.panelRect == panelRect &&
        other.enemyHud == enemyHud &&
        other.playerHud == playerHud &&
        listEquals(other.additionalHuds, additionalHuds) &&
        other.actorSlot == actorSlot &&
        other.actorCombatantId == actorCombatantId &&
        other.battleLabel == battleLabel &&
        other.title == title &&
        other.prompt == prompt &&
        listEquals(other.narrationLines, narrationLines) &&
        listEquals(other.entries, entries) &&
        other.interactionsEnabled == interactionsEnabled &&
        other.canGoBack == canGoBack;
  }

  @override
  int get hashCode => Object.hashAll([
    revision,
    commandPanelPlacement,
    controllerLayout,
    portraitTouchLayout,
    Object.hashAll(rootCommandOrder),
    collectionColumns,
    phase,
    forcedReplacement,
    mode,
    viewportSize,
    panelRect,
    enemyHud,
    playerHud,
    battleLabel,
    title,
    prompt,
    Object.hashAll(narrationLines),
    Object.hashAll(entries),
    interactionsEnabled,
    canGoBack,
    Object.hashAll(additionalHuds),
    actorSlot,
    actorCombatantId,
  ]);
}

/// Commande fermée envoyée par la présentation Flutter au runtime.
///
/// L'UI ne manipule ni `BattleSession`, ni les modèles de menu Flame. Elle
/// décrit uniquement l'intention associée au snapshot qu'elle affiche.
sealed class BattlePresentationCommand {
  const BattlePresentationCommand({
    required this.snapshotRevision,
    required this.expectedMode,
  });

  final int snapshotRevision;
  final BattleCommandOverlayMode expectedMode;
}

final class BattleSelectEntryCommand extends BattlePresentationCommand {
  const BattleSelectEntryCommand({
    required super.snapshotRevision,
    required super.expectedMode,
    required this.entryIndex,
  });

  final int entryIndex;
}

final class BattleBackCommand extends BattlePresentationCommand {
  const BattleBackCommand({
    required super.snapshotRevision,
    required super.expectedMode,
  });
}

final class BattleSetCommandPanelPlacementCommand
    extends BattlePresentationCommand {
  const BattleSetCommandPanelPlacementCommand({
    required super.snapshotRevision,
    required super.expectedMode,
    required this.placement,
    this.controllerLayout = false,
    this.portraitTouchLayout = false,
    this.rootCommandOrder = const [0, 1, 2, 3],
    this.collectionColumns,
  });

  final BattleCommandPanelPlacement placement;
  final bool controllerLayout;
  final bool portraitTouchLayout;
  final List<int> rootCommandOrder;
  final int? collectionColumns;

  static bool isValidRootCommandOrder(List<int> order) =>
      order.isNotEmpty &&
      order.length <= 4 &&
      order.toSet().length == order.length &&
      order.every((index) => index >= 0 && index < 4);
}

enum BattlePresentationCommandRejection {
  staleSnapshot,
  modeMismatch,
  interactionsDisabled,
  entryMissing,
  entryDisabled,
  backUnavailable,
  invalidLayout,
}

class BattlePresentationCommandValidation {
  const BattlePresentationCommandValidation._({
    required this.accepted,
    this.rejection,
  });

  const BattlePresentationCommandValidation.accepted() : this._(accepted: true);

  const BattlePresentationCommandValidation.rejected(
    BattlePresentationCommandRejection rejection,
  ) : this._(accepted: false, rejection: rejection);

  final bool accepted;
  final BattlePresentationCommandRejection? rejection;
}

/// Valide une commande contre l'unique snapshot qui l'a produite.
BattlePresentationCommandValidation validateBattlePresentationCommand(
  BattleCommandOverlaySnapshot snapshot,
  BattlePresentationCommand command,
) {
  if (command.snapshotRevision != snapshot.revision) {
    return const BattlePresentationCommandValidation.rejected(
      BattlePresentationCommandRejection.staleSnapshot,
    );
  }
  if (command.expectedMode != snapshot.mode) {
    return const BattlePresentationCommandValidation.rejected(
      BattlePresentationCommandRejection.modeMismatch,
    );
  }
  if (command is BattleSetCommandPanelPlacementCommand) {
    return BattleSetCommandPanelPlacementCommand.isValidRootCommandOrder(
              command.rootCommandOrder,
            ) &&
            (command.collectionColumns == null ||
                command.collectionColumns == 1 ||
                command.collectionColumns == 2)
        ? const BattlePresentationCommandValidation.accepted()
        : const BattlePresentationCommandValidation.rejected(
            BattlePresentationCommandRejection.invalidLayout,
          );
  }
  if (!snapshot.interactionsEnabled) {
    return const BattlePresentationCommandValidation.rejected(
      BattlePresentationCommandRejection.interactionsDisabled,
    );
  }
  return switch (command) {
    BattleSetCommandPanelPlacementCommand() =>
      const BattlePresentationCommandValidation.accepted(),
    BattleSelectEntryCommand(:final entryIndex) =>
      _validateBattleEntrySelection(snapshot, entryIndex),
    BattleBackCommand() =>
      snapshot.canGoBack
          ? const BattlePresentationCommandValidation.accepted()
          : const BattlePresentationCommandValidation.rejected(
              BattlePresentationCommandRejection.backUnavailable,
            ),
  };
}

BattlePresentationCommandValidation _validateBattleEntrySelection(
  BattleCommandOverlaySnapshot snapshot,
  int entryIndex,
) {
  final matchingEntries = snapshot.entries.where(
    (entry) => entry.index == entryIndex,
  );
  if (matchingEntries.isEmpty) {
    return const BattlePresentationCommandValidation.rejected(
      BattlePresentationCommandRejection.entryMissing,
    );
  }
  if (!matchingEntries.first.enabled) {
    return const BattlePresentationCommandValidation.rejected(
      BattlePresentationCommandRejection.entryDisabled,
    );
  }
  return const BattlePresentationCommandValidation.accepted();
}
