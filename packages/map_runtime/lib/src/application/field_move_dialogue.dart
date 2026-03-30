import 'package:map_gameplay/map_gameplay.dart';

import 'dialogue_runtime_models.dart';
import 'parse_yarn_dialogue.dart';

/// Dialogue Yarn système pour les interactions de field moves.
///
/// Ce contenu est embarqué dans le runtime — il ne dépend pas d'un fichier
/// projet externe et n'est pas pilotable par l'éditeur.
/// C'est un choix délibéré pour cette première passe ; une future version
/// pourra externaliser ces dialogues dans un fichier .yarn projet.
const String _kSurfDialogueYarn = '''
title: No_surf
---
Il semble possible de pouvoir surfer sur l'eau.
===

title: Surf_locked
---
Un Pokémon de votre équipe connaît Surf, mais vous n'avez pas encore l'autorisation de l'utiliser.
===

title: Yes_Surf
---
Voulez-vous surfer ?
-> Oui
-> Non
===
''';

// Convention de choix pour Yes_Surf :
//   index 0 = confirmer Surf ("Oui")
//   index 1 = décliner      ("Non")
// PlayableMapGame._confirmDialogueChoice se base sur cet index, pas sur le libellé.

/// Mappe un [SurfAttemptEvaluation] vers le nœud Yarn à ouvrir.
///
/// Retourne `null` pour les cas sans dialogue (cellule non-eau, déjà en surf).
String? surfEvaluationToYarnNode(SurfAttemptEvaluation evaluation) {
  return switch (evaluation) {
    MissingSurfCapablePokemon() => 'No_surf',
    SurfNotUnlocked() => 'Surf_locked',
    CanPromptSurf() => 'Yes_Surf',
    NotWater() => null,
    AlreadySurfing() => null,
  };
}

/// Charge un [DialogueSession] à partir du Yarn système Surf.
DialogueSession? loadSurfDialogueSession(String startNode) {
  final nodes = parseYarnFile(_kSurfDialogueYarn);
  return DialogueSession.start(nodes, startNode);
}
