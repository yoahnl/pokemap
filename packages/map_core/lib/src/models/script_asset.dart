import 'package:freezed_annotation/freezed_annotation.dart';

part 'script_asset.freezed.dart';
part 'script_asset.g.dart';

/// Asset de script narratif / système.
///
/// Un script est composé de noeuds interconnectés.
/// Chaque noeud contient des commandes à exécuter.
///
/// Le script peut être démarré depuis n'importe quel noeud.
@freezed
class ScriptAsset with _$ScriptAsset {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptAsset({
    /// Identifiant unique du script.
    required String id,

    /// Noeuds du script.
    required List<ScriptNode> nodes,

    /// Noeud de démarrage par défaut.
    @Default('start') String defaultStartNode,

    /// Métadonnées (auteur, version, notes).
    @Default({}) Map<String, String> metadata,
  }) = _ScriptAsset;

  factory ScriptAsset.fromJson(Map<String, dynamic> json) =>
      _$ScriptAssetFromJson(json);
}

/// Noeud dans un graphe de script.
///
/// Contient une liste de commandes à exécuter séquentiellement.
/// Après exécution, le script peut :
/// - continuer au noeud suivant (par ordre dans la liste)
/// - sauter à un noeud spécifique (via commande goto)
/// - se terminer (end)
@freezed
class ScriptNode with _$ScriptNode {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptNode({
    /// Identifiant unique dans le script.
    required String id,

    /// Titre optionnel (pour l'éditeur / debug).
    @Default('') String title,

    /// Commandes à exécuter dans ce noeud.
    @Default([]) List<ScriptCommand> commands,

    /// Identifiant du noeud suivant (optionnel).
    /// Si null, le script se termine après ce noeud.
    String? nextNodeId,
  }) = _ScriptNode;

  factory ScriptNode.fromJson(Map<String, dynamic> json) =>
      _$ScriptNodeFromJson(json);
}

/// Commande exécutable dans un script.
///
/// Types de commandes :
/// - Contrôle : goto, end
/// - État : setFlag, clearFlag, setVariable, incrementVariable
/// - Dialogue : openDialogue
/// - Gameplay : warpPlayer, giveItem, unlockFieldAbility
@freezed
class ScriptCommand with _$ScriptCommand {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptCommand({
    required ScriptCommandType type,

    /// Paramètres de la commande (dépend du type).
    @Default({}) Map<String, String> params,
  }) = _ScriptCommand;

  factory ScriptCommand.fromJson(Map<String, dynamic> json) =>
      _$ScriptCommandFromJson(json);
}

/// Types de commandes de script.
enum ScriptCommandType {
  /// Aller à un noeud spécifique.
  @JsonValue('goto')
  goto,

  /// Terminer le script.
  @JsonValue('end')
  end,

  /// Définir un flag à true.
  @JsonValue('setFlag')
  setFlag,

  /// Définir un flag à false.
  @JsonValue('clearFlag')
  clearFlag,

  /// Définir une variable.
  @JsonValue('setVariable')
  setVariable,

  /// Incrémenter une variable numérique.
  @JsonValue('incrementVariable')
  incrementVariable,

  /// Ouvrir un dialogue Yarn.
  @JsonValue('openDialogue')
  openDialogue,

  /// Attendre la fin d'un dialogue.
  @JsonValue('waitForDialogue')
  waitForDialogue,

  /// Téléporter le joueur.
  @JsonValue('warpPlayer')
  warpPlayer,

  /// Donner un item au joueur.
  @JsonValue('giveItem')
  giveItem,

  /// Débloquer une field ability.
  @JsonValue('unlockFieldAbility')
  unlockFieldAbility,

  /// Marquer un événement comme consommé.
  @JsonValue('markEventConsumed')
  markEventConsumed,
}

/// Référence à un dialogue Yarn.
@freezed
class YarnDialogueRef with _$YarnDialogueRef {
  @JsonSerializable(explicitToJson: true)
  const factory YarnDialogueRef({
    /// Chemin du fichier .yarn (relatif au projet).
    required String filePath,

    /// Noeud de départ dans le fichier.
    /// Si null, utilise le premier noeud.
    String? startNode,
  }) = _YarnDialogueRef;

  factory YarnDialogueRef.fromJson(Map<String, dynamic> json) =>
      _$YarnDialogueRefFromJson(json);
}
