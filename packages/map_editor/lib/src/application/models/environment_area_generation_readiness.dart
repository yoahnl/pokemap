import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Lot Environment-28 — règles Golden Slice (readiness) pour une EnvironmentArea.
// Pur Dart, testable sans Flutter ; ne remplace pas la validation des use cases.
// ---------------------------------------------------------------------------

/// Premier blocage « métier » pour le résumé d’état (ordre stable d’affichage).
enum EnvironmentAreaGenerationPrimaryBlocker {
  none,
  missingPreset,
  invalidTargetTileLayer,
  missingTargetTileLayer,
  emptyMask,
  alreadyGenerated,
}

/// Règles UX centralisées : boutons activables + messages de désactivation + résumé.
///
/// Aligné sur Lots 25–27 : Generate / Clear / Regenerate / Shuffle.
final class EnvironmentAreaGenerationReadiness {
  const EnvironmentAreaGenerationReadiness({
    required this.canGenerate,
    required this.canClear,
    required this.canRegenerate,
    required this.canShuffle,
    required this.generateDisabledMessage,
    required this.clearDisabledMessage,
    required this.regenerateDisabledMessage,
    required this.shuffleDisabledMessage,
    required this.stateSummaryLine,
    required this.primaryBlocker,
  });

  final bool canGenerate;
  final bool canClear;
  final bool canRegenerate;
  final bool canShuffle;

  /// Non null ssi l’action correspondante est désactivée.
  final String? generateDisabledMessage;
  final String? clearDisabledMessage;
  final String? regenerateDisabledMessage;
  final String? shuffleDisabledMessage;

  /// Une ligne courte du type `État : …` pour l’inspecteur.
  final String stateSummaryLine;

  final EnvironmentAreaGenerationPrimaryBlocker primaryBlocker;

  /// [hasTargetTileLayerId] : [EnvironmentLayerContent.targetTileLayerId] non null.
  /// [targetTileLayerInvalid] : id présent mais [resolvedTargetTileLayer] null.
  static EnvironmentAreaGenerationReadiness evaluate({
    required EnvironmentArea area,
    required EnvironmentPreset? preset,
    required bool hasTargetTileLayerId,
    required bool targetTileLayerInvalid,
    required TileLayer? resolvedTargetTileLayer,
  }) {
    final missingTarget = !hasTargetTileLayerId;
    final invalidTarget = hasTargetTileLayerId && targetTileLayerInvalid;
    final targetOk = hasTargetTileLayerId &&
        !targetTileLayerInvalid &&
        resolvedTargetTileLayer != null;

    final maskOk = area.mask.activeCellCount > 0;
    final presetOk = preset != null;
    final noGeneratedYet = area.generatedPlacementIds.isEmpty;
    final hasGenerated = area.generatedPlacementIds.isNotEmpty;

    final canGenerate = targetOk && presetOk && maskOk && noGeneratedYet;
    final canClear = hasGenerated;
    final canRegenerate = targetOk && presetOk && maskOk && hasGenerated;
    final canShuffle = targetOk && presetOk && maskOk;

    String? genMsg;
    if (!canGenerate) {
      if (missingTarget) {
        genMsg = 'Choisissez un TileLayer cible avant de générer.';
      } else if (invalidTarget) {
        genMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        genMsg = 'Le preset associé est introuvable.';
      } else if (!noGeneratedYet) {
        genMsg = 'Cette zone possède déjà des placements générés. Utilisez '
            '« Effacer les placements générés », « Régénérer » ou '
            '« Mélanger et régénérer ».';
      } else if (!maskOk) {
        genMsg = 'Peignez le masque avant de générer.';
      }
    }

    final clearMsg = canClear ? null : 'Aucun placement généré à effacer.';

    String? regMsg;
    if (!canRegenerate) {
      if (!hasGenerated) {
        regMsg = 'Aucun placement généré à régénérer.';
      } else if (missingTarget) {
        regMsg = 'Choisissez un TileLayer cible avant de régénérer.';
      } else if (invalidTarget) {
        regMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        regMsg = 'Le preset associé est introuvable.';
      } else if (!maskOk) {
        regMsg = 'Peignez le masque avant de régénérer.';
      }
    }

    String? shufMsg;
    if (!canShuffle) {
      if (missingTarget) {
        shufMsg = 'Choisissez un TileLayer cible avant de mélanger.';
      } else if (invalidTarget) {
        shufMsg = 'Le TileLayer cible est introuvable ou invalide.';
      } else if (!presetOk) {
        shufMsg = 'Le preset associé est introuvable.';
      } else if (!maskOk) {
        shufMsg = 'Peignez le masque avant de mélanger.';
      }
    }

    EnvironmentAreaGenerationPrimaryBlocker blocker;
    String summary;
    if (canGenerate) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
      summary = 'État : prêt à générer';
    } else if (!presetOk) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingPreset;
      summary = 'État : preset introuvable';
    } else if (invalidTarget) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.invalidTargetTileLayer;
      summary = 'État : cible invalide';
    } else if (missingTarget) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.missingTargetTileLayer;
      summary = 'État : cible manquante';
    } else if (!maskOk) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.emptyMask;
      summary = 'État : masque vide';
    } else if (!noGeneratedYet) {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.alreadyGenerated;
      summary = 'État : déjà généré';
    } else {
      blocker = EnvironmentAreaGenerationPrimaryBlocker.none;
      summary = 'État : en cours de configuration';
    }

    return EnvironmentAreaGenerationReadiness(
      canGenerate: canGenerate,
      canClear: canClear,
      canRegenerate: canRegenerate,
      canShuffle: canShuffle,
      generateDisabledMessage: genMsg,
      clearDisabledMessage: clearMsg,
      regenerateDisabledMessage: regMsg,
      shuffleDisabledMessage: shufMsg,
      stateSummaryLine: summary,
      primaryBlocker: blocker,
    );
  }
}
