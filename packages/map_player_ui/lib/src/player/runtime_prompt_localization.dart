import 'package:map_core/map_core.dart';

import '../localization/player_localizations.dart';

/// Les clés d'invite que le PRODUIT possède, et elles seules.
///
/// Un registre fermé, pas un catalogue ouvert : c'est la différence entre
/// traduire ses propres chaînes et écraser le contenu d'un auteur. Une clé
/// absente d'ici renvoie `null`, et l'appelant retombe sur le `fallbackText`
/// — qui, pour du texte authoré, EST le contenu du jeu.
///
/// C'est pour cela que `scene.pre_session.dialogue.line` ne figure pas dans la
/// liste alors que le runtime l'émet : son `fallbackText` est la réplique
/// écrite par l'auteur, interpolée. La « traduire » remplacerait le dialogue
/// du jeu par une phrase de PokeMap.
const runtimeOwnedPromptKeys = <String>{
  'player.new_game.confirm_overwrite',
  'player.new_game.confirm_overwrite_unusable',
  'scene.pre_session.dialogue.choice',
  'overworld.item.bagFull',
  'overworld.item.received',
  'crafting.unavailable',
  'pokemonGift.received',
  'pokemonGift.nicknamePrompt',
  'pokemonGift.continue',
  'pokemonGift.nickname',
};

/// L'invite dans la langue du joueur, ou `null` si le produit ne la possède
/// pas.
///
/// Le runtime n'a pas de BuildContext : il émet une clé et un `fallbackText`
/// figé dans la langue où il a été écrit. Rien ne lisait cette clé, donc chaque
/// invite produite par le runtime s'affichait dans cette langue-là quelle que
/// soit celle du joueur.
String? localizeRuntimePrompt(
  SceneInteractionPrompt prompt,
  PokeMapPlayerLocalizations l10n,
) {
  switch (prompt.localizationKey) {
    case 'player.new_game.confirm_overwrite':
      return l10n.confirmOverwrite;
    case 'player.new_game.confirm_overwrite_unusable':
      // Le gabarit est rendu AVEC sa raison déjà substituée. Renvoyer un
      // gabarit anglais et laisser l'appelant y injecter `{reason}` — que le
      // runtime a rendu en français — reproduirait exactement la phrase
      // bilingue que BETA-CIN-086 a corrigée, en miroir.
      //
      // `reasonCode` est là pour ça : la cause lisible par machine voyage à
      // côté de la formulation, donc on choisit la nôtre au lieu de réutiliser
      // celle du runtime.
      final code = prompt.arguments['reasonCode'];
      final reason = (code == null ? null : l10n.saveUnavailableReason(code)) ??
          prompt.arguments['reason'] ??
          '';
      return l10n.confirmOverwriteUnusable(reason);
    case 'scene.pre_session.dialogue.choice':
      return l10n.dialogueChoicePrompt;
    case 'overworld.item.bagFull':
      return l10n.runtimeFeedbackOverworldBagFull;
    case 'overworld.item.received':
      final item = prompt.arguments['item'];
      final quantity = int.tryParse(prompt.arguments['quantity'] ?? '');
      if (item == null || quantity == null || quantity < 1) return null;
      return l10n.runtimeFeedbackOverworldItemReceived(
        item: item,
        quantity: quantity,
      );
    case 'crafting.unavailable':
      return l10n.runtimeFeedbackCraftInventoryBusy;
    case 'pokemonGift.received':
      return l10n.runtimeFeedbackGiftReceived;
    case 'pokemonGift.nicknamePrompt':
      return l10n.runtimeFeedbackGiftNicknamePrompt;
    case 'pokemonGift.continue':
      return l10n.continueGame;
    case 'pokemonGift.nickname':
      return prompt.arguments.containsKey('speciesId')
          ? l10n.runtimeFeedbackGiftNicknamePrompt
          : l10n.runtimeFeedbackGiftNicknameAction;
    default:
      return null;
  }
}
