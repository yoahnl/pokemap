import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

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
  bag,
  bagMedicineTarget,
  pokemon,
  continueOnly,
}

/// Type visuel borné d'une entrée du panneau.
///
/// Ce type n'ouvre pas un système générique de widgets battle : il décrit
/// seulement les familles actuellement rendues dans le panneau de commandes.
enum BattleCommandOverlayEntryKind {
  root,
  move,
  bag,
  party,
  medicineTarget,
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
    this.genderSymbol,
    this.statusLabel,
  });

  final Rect rect;
  final String ownerLabel;
  final String speciesLabel;
  final int level;
  final int currentHp;
  final int maxHp;
  final bool isPlayerSide;
  final String? genderSymbol;
  final String? statusLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BattleCommandOverlayHudSnapshot &&
        other.rect == rect &&
        other.ownerLabel == ownerLabel &&
        other.speciesLabel == speciesLabel &&
        other.level == level &&
        other.currentHp == currentHp &&
        other.maxHp == maxHp &&
        other.isPlayerSide == isPlayerSide &&
        other.genderSymbol == genderSymbol &&
        other.statusLabel == statusLabel;
  }

  @override
  int get hashCode => Object.hash(
        rect,
        ownerLabel,
        speciesLabel,
        level,
        currentHp,
        maxHp,
        isPlayerSide,
        genderSymbol,
        statusLabel,
      );
}

class BattleCommandOverlaySnapshot {
  const BattleCommandOverlaySnapshot({
    required this.mode,
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
  });

  final BattleCommandOverlayMode mode;
  final Rect panelRect;
  final BattleCommandOverlayHudSnapshot enemyHud;
  final BattleCommandOverlayHudSnapshot playerHud;
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
        other.mode == mode &&
        other.panelRect == panelRect &&
        other.enemyHud == enemyHud &&
        other.playerHud == playerHud &&
        other.battleLabel == battleLabel &&
        other.title == title &&
        other.prompt == prompt &&
        listEquals(other.narrationLines, narrationLines) &&
        listEquals(other.entries, entries) &&
        other.interactionsEnabled == interactionsEnabled &&
        other.canGoBack == canGoBack;
  }

  @override
  int get hashCode => Object.hash(
        mode,
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
      );
}
