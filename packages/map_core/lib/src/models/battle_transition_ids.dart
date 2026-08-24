/// Les transitions de début de combat proposables à l'authoring —
/// BETA-BAT-019.
///
/// Le CONTRAT partagé entre l'éditeur (qui propose ces ids dans l'Encounter
/// Studio et le Trainer Studio) et le runtime (dont le registre moteur
/// `battleTransitionRegistry` les résout — un test côté runtime garantit que
/// chaque id listé ici se résout réellement). Un id inconnu du moteur est
/// écarté sans casser l'entrée en combat : ajouter ici sans porter la spec
/// n'explose rien, mais ne montre rien non plus.
library;

/// Les transitions proposables pour une rencontre SAUVAGE, dans l'ordre du
/// panel d'authoring.
const List<String> battleWildTransitionIds = <String>[
  'rby_wild',
  'gold_wild',
  'crystal_wild',
  'hgss_wild',
  'hgss_cave',
  'rs_wild',
  'dpp_wild',
  'rs_cave',
  'dpp_cave',
];

/// Les transitions proposables pour un combat DRESSEUR, dans l'ordre du
/// panel d'authoring.
const List<String> battleTrainerTransitionIds = <String>[
  'dpp_trainer',
  'hgss_trainer',
  'rby_trainer',
  'rs_trainer',
  'battle_frontier_v',
  'battle_frontier_h',
];

/// Libellés d'authoring, par id — le nom de la génération de la référence.
const Map<String, String> battleTransitionDisplayLabels = <String, String>{
  'rby_wild': 'Rouge/Bleu/Jaune',
  'gold_wild': 'Or',
  'crystal_wild': 'Cristal',
  'hgss_wild': 'HeartGold/SoulSilver',
  'hgss_cave': 'HeartGold/SoulSilver — grotte',
  'rs_wild': 'Rubis/Saphir',
  'dpp_wild': 'Diamant/Perle/Platine',
  'dpp_trainer': 'Dresseur Diamant/Perle/Platine',
  'hgss_trainer': 'Dresseur HeartGold/SoulSilver',
  'rs_cave': 'Rubis/Saphir — grotte',
  'dpp_cave': 'Diamant/Perle — grotte',
  'rby_trainer': 'Dresseur Rouge/Bleu/Jaune',
  'rs_trainer': 'Dresseur Rubis/Saphir',
  'battle_frontier_v': 'Zone de Combat — vertical',
  'battle_frontier_h': 'Zone de Combat — horizontal',
};
