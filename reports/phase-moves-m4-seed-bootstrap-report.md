# M4 — Seed standard embarqué + bootstrap projet pour le catalogue moves

## 1. Résumé exécutif honnête

M4 est livré avec un scope volontairement borné à `map_editor`.

Ce que le lot fait réellement :
- un seed versionné et canonique de `moves` existe maintenant dans le repo ;
- le bootstrap Pokémon n'écrit plus un `data/pokemon/catalogs/moves.json` vide ;
- le bootstrap copie un vrai catalogue `moves` canonique et offline dans le workspace projet ;
- le comportement non-écrasant existant sur rerun est conservé ;
- `SeedPokemonDemoDataUseCase` réutilise la même source de seed pour éviter deux seeds moves divergents et garde le chemin de compatibilité pour les anciens scaffolds vides.

Ce que le lot ne fait pas :
- aucun seed embarqué pour les autres catalogues que `moves` ;
- aucun loader runtime spécialisé ;
- aucun changement dans `map_runtime` ;
- aucun changement dans `map_battle` ;
- aucun changement dans `project.json` ;
- aucun tooling général de génération de seed ;
- aucun catalogue Showdown complet vendorizé.

## 2. État initial audité réel

Constats confirmés avant patch :
- [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart) créait bien `data/pokemon/catalogs/moves.json`, mais avec `entries: []`.
- Ce use case était déjà explicitement idempotent et non-écrasant via `_writeJsonIfAbsent(...)`.
- [`packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart) convertit déjà un snapshot Showdown en vraies entrées canoniques `PokemonMove.toJson()`.
- [`packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart) sait déjà lire les entrées canoniques via `PokemonMove.fromJson(...)` et ne retombe plus silencieusement en legacy pour les formes partiellement canoniques.
- [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart) embarquait encore son propre mini seed `moves` legacy de 4 attaques et ne réécrivait un catalogue que s'il reconnaissait l'ancien scaffold vide.
- [`packages/map_editor/pubspec.yaml`](/Users/karim/Project/pokemonProject/packages/map_editor/pubspec.yaml) n'a pas de pipeline `flutter/assets` pour des seeds JSON de ce type.

Conséquence :
- le vrai seam existant pour M4 n'était pas un asset Flutter ni un générateur live ;
- le seam naturel était un seed Dart embarqué, lu localement par le bootstrap ;
- le vrai risque caché était de créer une deuxième source de vérité moves à côté de `SeedPokemonDemoDataUseCase`.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés
- `moves.json` bootstrap était vide.
- Le repo n'avait pas encore de seed canonique embarqué dédié aux moves.
- Le seed demo moves existant était encore legacy et séparé du futur seam bootstrap.

### Problèmes non confirmés
- Le prompt supposait implicitement qu'un asset JSON serait probablement le meilleur seam. L'audit réel ne le confirme pas.
- Le prompt laissait entendre qu'un seed "idéalement complet" Showdown pouvait être une cible par défaut. L'audit réel montre qu'un dump complet vendorizé aurait ouvert soit du tooling, soit un artefact massif, donc un scope plus large que M4.

## 4. Cause racine réelle

La cause racine du trou M4 était simple : le bootstrap local Pokémon a été introduit comme scaffold de structure et non comme bootstrap de contenu. `moves` était donc resté sur le même traitement que les autres catalogues vides, malgré l'arrivée des lots M1/M2/M3 qui ont déjà rendu possible un seed canonique.

La cause racine secondaire était l'absence d'un seam seed partagé entre :
- le bootstrap projet ;
- le seed de démo Pokémon.

Sans correction, on allait soit garder un bootstrap vide, soit dupliquer des seeds moves divergents.

## 5. Décisions retenues / rejetées

### Décisions retenues
- Stocker le seed `moves` comme code Dart embarqué dans `map_editor`.
- Construire le seed via de vrais `PokemonMove` puis sérialiser `toJson()`.
- Conserver le contrat non-écrasant existant de `InitializePokemonProjectStorageUseCase`.
- Réutiliser la même source de seed dans `SeedPokemonDemoDataUseCase` pour le chemin de compatibilité des anciens scaffolds vides.
- Livrer un seed canonique curaté et utile, mais pas exhaustif.

### Décisions rejetées
- Asset JSON Flutter : rejeté car le package n'a pas déjà ce seam, cela aurait ajouté de la plomberie bundle/asset dans un use case applicatif simple.
- Parsing Showdown au bootstrap : rejeté, hors intention M4 et contraire au contrat offline.
- Dépendance réseau au bootstrap : rejetée.
- Nouveau framework générique multi-catalogues : rejeté.
- Dump complet Showdown versionné dans le repo pour M4 : rejeté comme trop large pour un lot centré sur le seam bootstrap.
- Écrasement silencieux d'un `moves.json` existant : rejeté, contraire au contrat réel déjà présent.

## 6. Périmètre inclus / exclu

### Inclus
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`
- `packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`

### Exclu
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_runtime/...`
- `packages/map_battle/...`
- `packages/map_core/...`
- seed d'autres catalogues
- UI
- validation projet globale
- tooling général de génération

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Créé
- [`packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart)

### Modifiés
- [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
- [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart)
- [`packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart)
- [`packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart)

### Supprimés
- aucun

## 8. Justification fichier par fichier

### [`packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart)
- Nouveau seam de seed versionné pour M4.
- Évite un asset Flutter ou une génération live.
- Passe par le vrai modèle canonique `PokemonMove`.
- Porte un sous-ensemble utile et honnête, avec `engineSupportLevel` explicite.

### [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
- Change uniquement le payload bootstrap de `moves`.
- Préserve intégralement la logique non-écrasante existante.
- Ne touche pas `project.json`.

### [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart)
- Touché volontairement pour éviter deux seeds moves concurrents.
- Réutilise la même source de seed que le bootstrap.
- Conserve le chemin de compatibilité pour un ancien scaffold `moves.json` vide.

### [`packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart)
- Met à jour l'attente sur `moves.json` : non vide, canonique, sans clés legacy mortes.
- Ajoute une preuve de lecture via `LoadPokemonMovesCatalogUseCase`.

### [`packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart)
- Remplace l'attente "exactement 4 moves" par une attente cohérente avec le nouveau seed partagé.
- Ajoute la preuve du chemin de compatibilité : ancien scaffold vide -> upgrade vers le seed canonique partagé.

## 9. Commandes réellement exécutées

### Audit
```bash
git status --short
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
sed -n '1,340p' packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
sed -n '1,320p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1,260p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '1,320p' packages/map_core/lib/src/models/pokemon_move_effect.dart
sed -n '1,220p' packages/map_core/lib/src/models/pokemon_move_accuracy.dart
sed -n '1,220p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,220p' packages/map_editor/pubspec.yaml
sed -n '1,360p' packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
sed -n '1,320p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
sed -n '1,260p' packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
rg -n "moves.json|InitializePokemonProjectStorageUseCase|seed" packages/map_editor/lib packages/map_editor/test
python3 (lecture ciblée de `pokemon-showdown-master/data/moves.ts` pour les moves retenus)
python3 (fetch one-shot de `https://play.pokemonshowdown.com/data/moves.json` avec user-agent explicite pour récupérer `shortDesc` / `desc`)
```

### Validation / dev support
```bash
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
cd packages/map_editor && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart test/seed_pokemon_demo_data_use_case_test.dart
cd packages/map_editor && /opt/homebrew/bin/flutter test test/initialize_pokemon_project_storage_use_case_test.dart test/seed_pokemon_demo_data_use_case_test.dart
cd packages/map_editor && /opt/homebrew/bin/flutter test test/file_pokemon_read_repository_test.dart
cd packages/map_editor && /opt/homebrew/bin/flutter test test/sync_pokemon_moves_catalog_use_case_test.dart
cd packages/map_editor && /opt/homebrew/bin/flutter test test/initialize_pokemon_project_storage_use_case_test.dart test/seed_pokemon_demo_data_use_case_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
```

### Relecture séparée
- agent d'audit/design `Confucius`
- reviewer séparé `Carver`

## 10. Résultats réels de format / analyze / tests

### Format
```text
Formatted packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
Formatted packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
Formatted 5 files (2 changed) in 0.02 seconds.
```
Puis rerun ciblé après le dernier test ajouté :
```text
Formatted packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

### Analyze
Premier analyze ciblé :
```text
info • Use 'const' with the constructor to improve performance • lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:45:11 • prefer_const_constructors
```
Correction appliquée, puis rerun :
```text
No issues found! (ran in 0.8s)
```
Rerun final après intégration du reviewer :
```text
No issues found! (ran in 1.5s)
```

### Tests ciblés utiles
Premier lot de tests directement touchés :
```text
All tests passed!
```
pour :
- `test/initialize_pokemon_project_storage_use_case_test.dart`
- `test/seed_pokemon_demo_data_use_case_test.dart`

Test complémentaire de sync frontière :
```text
All tests passed!
```
pour :
- `test/sync_pokemon_moves_catalog_use_case_test.dart`

Rerun final après correction issue de la review :
```text
All tests passed!
```
pour :
- `test/initialize_pokemon_project_storage_use_case_test.dart`
- `test/seed_pokemon_demo_data_use_case_test.dart`
- `test/sync_pokemon_moves_catalog_use_case_test.dart`

### Incident de validation supplémentaire non bloquant
Le test suivant a été lancé à titre de vérification plus large :
- `test/file_pokemon_read_repository_test.dart`

Résultat réel : échec.
Extrait utile :
```text
Expected: true
  Actual: <false>
...
test/file_pokemon_read_repository_test.dart 293:7
```

Lecture honnête de cet incident :
- l'échec se produit sur un cas legacy custom configuré sans `pokemon_data_manifest.json` ;
- il ne passe pas par le nouveau seam seed bootstrap M4 ;
- il n'est pas nécessaire de le "réparer au passage" sans audit dédié ;
- il est donc documenté comme incident hors scope, pas absorbé silencieusement dans M4.

## 11. Incidents rencontrés

1. Fetch Python direct vers Showdown sans user-agent :
```text
urllib.error.HTTPError: HTTP Error 403: Forbidden
```
Correction : rerun avec user-agent explicite, succès.

2. Tentative d'exécuter un script Dart temporaire pour réutiliser le convertisseur M3 offline :
```text
Running build hooks...Unhandled exception:
Exception: Command failed: /opt/homebrew/Cellar/swiftly/1.0.1/bin/swiftly -isysroot ...
Error: Unknown option '-isysroot'
```
Conclusion : l'environnement local de hooks natifs `objective_c` est cassé pour ce type d'exécution `dart run` temporaire. Ce n'était pas bloquant pour M4 ; la seed a été produite sans dépendre de ce chemin.

3. Reviewer séparé a trouvé un trou de couverture réel sur le chemin legacy-empty-scaffold upgrade. Correction appliquée puis rerun analyze/tests.

## 12. État git utile

### `git status --short`
```text
 M packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
 M packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
 M packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
 M packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
?? .DS_Store
?? packages/map_editor/lib/src/application/seeds/
```

### `git diff --stat`
```text
 ...nitialize_pokemon_project_storage_use_case.dart |  47 +++++++---
 .../use_cases/seed_pokemon_demo_data_use_case.dart | 100 ++++-----------------
 ...lize_pokemon_project_storage_use_case_test.dart |  86 ++++++++++++++++--
 .../test/seed_pokemon_demo_data_use_case_test.dart |  60 ++++++++++++-
 4 files changed, 191 insertions(+), 102 deletions(-)
```

Note honnête : le nouveau fichier seed apparaît dans `git status --short` comme fichier non suivi ; il n'apparaît pas dans `git diff --stat` car il est encore untracked.

## 13. Checklist finale

- [x] je me suis basé sur le code réel du repo
- [x] j’ai audité les fichiers critiques avant modification
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai pas touché `map_runtime`
- [x] je n’ai pas touché `map_battle`
- [x] je n’ai pas ouvert M5
- [x] je n’ai pas ouvert M6
- [x] je n’ai pas ouvert M7
- [x] je n’ai pas ouvert M8
- [x] le bootstrap ne crée plus un `moves.json` vide
- [x] le seed est canonique et parse via `PokemonMove.fromJson(...)`
- [x] le seed ne réintroduit pas `power`
- [x] le seed ne réintroduit pas `accuracyText`
- [x] le seed ne réintroduit pas `shortDesc`
- [x] le bootstrap ne dépend pas du réseau
- [x] `project.json` reste inchangé
- [x] le non-écrasement sur rerun est conservé
- [x] j’ai utilisé des sub-agents
- [x] j’ai intégré la remarque valide du reviewer séparé
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] mon report final est honnête
- [x] mon report contient le contenu complet des fichiers texte touchés

## 14. Retour du reviewer séparé

Retour initial utile de `Carver` :
- scope jugé sain ;
- seam Dart embarqué jugé cohérent avec le repo ;
- pas de risque d'écrasement de données sur rerun ;
- frontière canonique/legacy jugée cohérente ;
- un manque de couverture identifié : le chemin `old empty scaffold -> upgrade` dans `SeedPokemonDemoDataUseCase` n'était pas testé.

Retour final après correction :
- `No material findings remain.`
- risque résiduel non bloquant : seed curaté, pas dump complet Showdown.

## 15. Corrections appliquées suite à cette review

Correction appliquée :
- ajout d'un test dédié dans [`packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart) pour prouver qu'un ancien scaffold `moves.json` vide est bien upgradé vers le seed canonique partagé.

Rerun après correction :
- `flutter analyze --no-pub` ciblé : OK
- `flutter test` ciblé (`initialize`, `seed_demo_data`, `sync`) : OK

## 16. Limites restantes

- Le seed moves bootstrap est curaté, pas exhaustif.
- Les autres catalogues bootstrap restent vides ; ce lot n'ouvre pas un seed framework global.
- Le test plus large `file_pokemon_read_repository_test.dart` révèle un cas legacy hors scope qui mérite un audit dédié, mais il n'a pas été absorbé dans M4 sans preuve que M4 l'aurait cassé.
- Aucun enrichissement du convertisseur Showdown n'a été fait dans ce lot.

## 17. Critique du prompt reçu

Le prompt était juste sur plusieurs points :
- il fallait garder M4 strictement centré sur le seam bootstrap ;
- il fallait refuser tout parsing Showdown au bootstrap ;
- il fallait préserver l'absence d'écrasement silencieux si le contrat réel du use case allait déjà dans ce sens ;
- il fallait challenger le seam avant de coder.

Ce qui était discutable :
- l'idée implicite qu'un asset JSON serait probablement le meilleur stockage. Dans ce repo réel, ce n'était pas la solution la plus saine : pas de pipeline `flutter/assets` existant pour ce seam, et le use case d'initialisation est actuellement beaucoup plus simple à tester et à conserver en pur seam applicatif avec un seed Dart embarqué.

Ce qui aurait pu être dangereux :
- prendre au pied de la lettre la préférence "idéalement seed complet" Showdown. Sur ce repo, cela aurait facilement ouvert soit un gros artefact généré, soit un tooling de génération, soit une dépendance à une source externe. Pour M4, c'était trop large.
- ignorer l'existence de `SeedPokemonDemoDataUseCase`, ce qui aurait laissé deux seeds moves concurrents ou une sémantique de compatibilité partiellement cassée.

Ce que j'ai volontairement corrigé ou recadré :
- j'ai choisi un seed Dart embarqué au lieu d'un asset JSON ;
- j'ai retenu un seed canonique curaté mais substantiel, au lieu d'un dump complet ;
- j'ai touché `SeedPokemonDemoDataUseCase` minimalement pour partager le même seed source et préserver le chemin d'upgrade des anciens scaffolds vides.

Pourquoi :
- c'est la correction minimale la plus cohérente avec l'architecture existante ;
- elle évite les stacks parallèles ;
- elle garde le bootstrap offline, testable, et non-écrasant.

## 18. Conclusion honnête

M4 ferme le vrai trou produit visé : un projet Pokémon fraîchement initialisé n'a plus un `moves.json` vide.

Le lot reste proprement borné :
- un seed versionné et canonique est embarqué dans `map_editor` ;
- le bootstrap copie ce seed sans réseau, sans parsing Showdown live, sans toucher au runtime ni au moteur ;
- la sémantique non-écrasante existante est conservée ;
- la compatibilité avec les anciens scaffolds vides est maintenue côté seed demo.

Le lot ne prétend pas avoir seedé tout Showdown, et c'est volontaire. Le seam est maintenant propre ; l'élargissement éventuel du catalogue relèvera d'un lot suivant, pas d'un glissement furtif dans M4.

## 19. Annexe — contenu COMPLET de tous les fichiers texte touchés

### [`packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart)
```dart
import 'package:map_core/map_core.dart';

import '../models/pokemon_project_data_models.dart';

/// Version logique du seed embarqué des moves bootstrap.
///
/// On ne crée pas ici un nouveau schéma JSON ni un framework de seed générique.
/// La "version" utile pour ce lot est simplement :
/// - un entier local, facile à relire dans le code ;
/// - reporté aussi dans les notes du catalogue seedé ;
/// - assez simple pour tracer les évolutions sans rouvrir `PokemonDataMeta`.
const int embeddedPokemonMovesSeedVersion = 1;

/// Construit le catalogue `moves` embarqué pour le bootstrap projet.
///
/// Choix d'architecture volontaire :
/// - le seed est codé en Dart, pas en asset Flutter ;
/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
/// - le seed passe par les vrais modèles canoniques `PokemonMove`, puis
///   sérialise `toJson()` ;
/// - la copie dans le projet reste un simple write JSON, sans génération live.
///
/// Pourquoi pas un asset JSON pour M4 :
/// - `map_editor` ne versionne pas déjà ce type de seed via `flutter/assets` ;
/// - le use case d'initialisation est aujourd'hui un seam applicatif simple,
///   testable sans plomberie Flutter ;
/// - ajouter une lecture d'asset ici ouvrirait une couche de packaging plus
///   large que nécessaire pour ce seul lot.
///
/// Pourquoi pas le catalogue Showdown complet :
/// - cela demanderait soit du tooling de génération versionné, soit un gros
///   artefact généré hors scope M4 ;
/// - M4 doit fixer le seam bootstrap, pas ouvrir un chantier "catalog dump".
///
/// Le seed reste donc volontairement :
/// - canonique ;
/// - offline ;
/// - substantiel ;
/// - mais encore curaté.
PokemonCatalogFile buildEmbeddedPokemonMovesBootstrapSeed() {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: const PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>[
        'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
        'Curated from Showdown-backed move data and versioned in the repository.',
        'bootstrap_seed_version:$embeddedPokemonMovesSeedVersion',
      ],
    ),
    entries: _embeddedPokemonMovesSeedEntries
        .map((move) => move.toJson())
        .toList(growable: false),
  );
}

/// Le seed n'essaie pas d'être tout Showdown.
///
/// On prend un sous-ensemble volontairement utile pour un projet frais :
/// - attaques simples courantes ;
/// - quelques statuts et boosts ;
/// - quelques moves plus "structurels" pour garder des entrées qui montrent
///   honnêtement les limites actuelles (`catalog_only` quand nécessaire).
final List<PokemonMove> _embeddedPokemonMovesSeedEntries = <PokemonMove>[
  ..._structuredSupportedSeedMoves,
  ..._catalogOnlySeedMoves,
];

/// Moves dont la structure utile est déjà correctement portée par le modèle.
///
/// Même si `map_battle` ne consomme pas encore tout cela, le modèle canonique
/// est capable de les décrire sans mensonge métier majeur.
final List<PokemonMove> _structuredSupportedSeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'absorb',
    showdownMoveId: 'absorb',
    name: 'Absorb',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 20,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.drain(numerator: 1, denominator: 2),
    ],
    shortDescription: 'User recovers 50% of the damage dealt.',
    description:
        'The user recovers 1/2 the HP lost by the target, rounded half up. '
        'If Big Root is held by the user, the HP recovered is 1.3x normal, '
        'rounded half down.',
  ),
  _showdownSeedMove(
    id: 'double_slap',
    showdownMoveId: 'doubleslap',
    name: 'Double Slap',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 15,
    accuracy: const PokemonMoveAccuracy.percent(value: 85),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
    ],
    shortDescription: 'Hits 2-5 times in one turn.',
    description:
        'Hits two to five times. Has a 35% chance to hit two or three times '
        'and a 15% chance to hit four or five times. If one of the hits '
        'breaks the target\'s substitute, it will take damage for the '
        'remaining hits. If the user has the Skill Link Ability, this move '
        'will always hit five times.',
  ),
  _showdownSeedMove(
    id: 'feint',
    showdownMoveId: 'feint',
    name: 'Feint',
    generation: 4,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 30,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    priority: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.breakProtect(),
    ],
    shortDescription: 'Nullifies Detect, Protect, and Quick/Wide Guard.',
    description: 'If this move is successful, it breaks through the target\'s '
        'Baneful Bunker, Detect, King\'s Shield, Protect, or Spiky Shield for '
        'this turn, allowing other Pokemon to attack the target normally. '
        'If the target\'s side is protected by Crafty Shield, Mat Block, '
        'Quick Guard, or Wide Guard, that protection is also broken for this '
        'turn and other Pokemon may attack the target\'s side normally.',
  ),
  _showdownSeedMove(
    id: 'growl',
    showdownMoveId: 'growl',
    name: 'Growl',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 40,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.sound,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Attack by 1.',
    description: 'Lowers the target\'s Attack by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'hyper_beam',
    showdownMoveId: 'hyperbeam',
    name: 'Hyper Beam',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    basePower: 150,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.recharge,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.requireRecharge(),
    ],
    shortDescription: 'User cannot move next turn.',
    description:
        'If this move is successful, the user must recharge on the following '
        'turn and cannot select a move.',
  ),
  _showdownSeedMove(
    id: 'leer',
    showdownMoveId: 'leer',
    name: 'Leer',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'rain_dance',
    showdownMoveId: 'raindance',
    name: 'Rain Dance',
    generation: 2,
    type: 'water',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setWeather(weatherId: 'raindance'),
    ],
    shortDescription: 'For 5 turns, heavy rain powers Water moves.',
    description: 'For 5 turns, the weather becomes Rain Dance. The damage of '
        'Water-type attacks is multiplied by 1.5 and the damage of Fire-type '
        'attacks is multiplied by 0.5 during the effect. Lasts for 8 turns if '
        'the user is holding Damp Rock. Fails if the current weather is Rain '
        'Dance.',
  ),
  _showdownSeedMove(
    id: 'razor_leaf',
    showdownMoveId: 'razorleaf',
    name: 'Razor Leaf',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 55,
    accuracy: const PokemonMoveAccuracy.percent(value: 95),
    pp: 25,
    critRatio: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.slicing,
    ],
    shortDescription: 'High critical hit ratio. Hits adjacent foes.',
    description: 'Has a higher chance for a critical hit.',
  ),
  _showdownSeedMove(
    id: 'swords_dance',
    showdownMoveId: 'swordsdance',
    name: 'Swords Dance',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.dance,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        targetScope: PokemonMoveEffectTargetScope.self,
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: 2,
          ),
        ],
      ),
    ],
    shortDescription: 'Raises the user\'s Attack by 2.',
    description: 'Raises the user\'s Attack by 2 stages.',
  ),
  _showdownSeedMove(
    id: 'swift',
    showdownMoveId: 'swift',
    name: 'Swift',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 60,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'This move does not check accuracy. Hits foes.',
    description: 'This move does not check accuracy.',
  ),
  _showdownSeedMove(
    id: 'tackle',
    showdownMoveId: 'tackle',
    name: 'Tackle',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'thunder_wave',
    showdownMoveId: 'thunderwave',
    name: 'Thunder Wave',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(statusId: 'par'),
    ],
    shortDescription: 'Paralyzes the target.',
    description:
        'Paralyzes the target. This move does not ignore type immunity.',
  ),
  _showdownSeedMove(
    id: 'thunderbolt',
    showdownMoveId: 'thunderbolt',
    name: 'Thunderbolt',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.special,
    basePower: 90,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 15,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'par'),
    ],
    shortDescription: '10% chance to paralyze the target.',
    description: 'Has a 10% chance to paralyze the target.',
  ),
  _showdownSeedMove(
    id: 'u_turn',
    showdownMoveId: 'uturn',
    name: 'U-turn',
    generation: 4,
    type: 'bug',
    category: PokemonMoveCategory.physical,
    basePower: 70,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.selfSwitch(),
    ],
    shortDescription: 'User switches out after damaging the target.',
    description:
        'If this move is successful and the user has not fainted, the user '
        'switches out even if it is trapped and is replaced immediately by a '
        'selected party member. The user does not switch out if there are no '
        'unfainted party members, or if the target switched out using an '
        'Eject Button or through the effect of the Emergency Exit or Wimp Out '
        'Abilities.',
  ),
  _showdownSeedMove(
    id: 'vine_whip',
    showdownMoveId: 'vinewhip',
    name: 'Vine Whip',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    basePower: 45,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'whirlwind',
    showdownMoveId: 'whirlwind',
    name: 'Whirlwind',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    priority: -6,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.allyAnim,
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.wind,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.forceSwitch(),
    ],
    shortDescription: 'Forces the target to switch to a random ally.',
    description:
        'The target is forced to switch out and be replaced with a random '
        'unfainted ally. Fails if the target is the last unfainted Pokemon in '
        'its party, or if the target used Ingrain previously or has the '
        'Suction Cups Ability.',
  ),
];

/// Moves volontairement gardés dans le seed malgré un support encore limité.
///
/// On les garde parce qu'ils rendent le seed plus utile qu'une simple liste
/// d'attaques triviales, tout en exposant honnêtement les limites structurelles
/// actuelles via `catalog_only` et `unsupportedReasons`.
final List<PokemonMove> _catalogOnlySeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'stealth_rock',
    showdownMoveId: 'stealthrock',
    name: 'Stealth Rock',
    generation: 4,
    type: 'rock',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mustPressure,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
    ],
    shortDescription: 'Hurts foes on switch-in. Factors Rock weakness.',
    description:
        'Sets up a hazard on the opposing side of the field, damaging each '
        'opposing Pokemon that switches in. Fails if the effect is already '
        'active on the opposing side. Foes lose 1/32, 1/16, 1/8, 1/4, or 1/2 '
        'of their maximum HP, rounded down, based on their weakness to the '
        'Rock type; 0.25x, 0.5x, neutral, 2x, or 4x, respectively. Can be '
        'removed from the opposing side if any Pokemon uses Tidy Up, or if '
        'any opposing Pokemon uses Mortal Spin, Rapid Spin, or Defog '
        'successfully, or is hit by Defog.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSideStart',
      'showdown_callback:condition.onSwitchIn',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'electric_terrain',
    showdownMoveId: 'electricterrain',
    name: 'Electric Terrain',
    generation: 6,
    type: 'electric',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.nonSky,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
    ],
    shortDescription: '5 turns. Grounded: +Electric power, can\'t sleep.',
    description:
        'For 5 turns, the terrain becomes Electric Terrain. During the '
        'effect, the power of Electric-type attacks made by grounded Pokemon '
        'is multiplied by 1.3 and grounded Pokemon cannot fall asleep; Pokemon '
        'already asleep do not wake up. Grounded Pokemon cannot become '
        'affected by Yawn or fall asleep from its effect. Camouflage '
        'transforms the user into an Electric type, Nature Power becomes '
        'Thunderbolt, and Secret Power has a 30% chance to cause paralysis. '
        'Fails if the current terrain is Electric Terrain.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onBasePower',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldStart',
      'showdown_callback:condition.onSetStatus',
      'showdown_callback:condition.onTryAddVolatile',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onBasePower',
      'condition.onFieldEnd',
      'condition.onFieldStart',
      'condition.onSetStatus',
      'condition.onTryAddVolatile',
    ],
  ),
  _showdownSeedMove(
    id: 'healing_wish',
    showdownMoveId: 'healingwish',
    name: 'Healing Wish',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSlotCondition(conditionId: 'healingwish'),
    ],
    shortDescription: 'User faints. Next hurt Pokemon is fully healed.',
    description:
        'The user faints, and if the Pokemon brought out to replace it does '
        'not have full HP or has a non-volatile status condition, its HP is '
        'fully restored along with having any non-volatile status condition '
        'cured. The replacement is sent out at the end of the turn, and the '
        'healing happens before hazards take effect. This effect continues '
        'until a Pokemon that meets either of these conditions switches in at '
        'the user\'s position or gets swapped into the position with Ally '
        'Switch. Fails if the user is the last unfainted Pokemon in its party.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSwap',
      'showdown_callback:condition.onSwitchIn',
      'showdown_callback:onTryHit',
      'unsupported_mechanic:condition',
      'unsupported_mechanic:selfdestruct',
    ],
    showdownHooksPresent: <String>[
      'condition.onSwap',
      'condition.onSwitchIn',
      'onTryHit',
    ],
  ),
  _showdownSeedMove(
    id: 'solar_beam',
    showdownMoveId: 'solarbeam',
    name: 'Solar Beam',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 120,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.charge,
      PokemonMoveFlag.failInstruct,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noSleepTalk,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'Charges turn 1. Hits turn 2. No charge in sunlight.',
    description:
        'This attack charges on the first turn and executes on the second. '
        'Power is halved if the weather is Primordial Sea, Rain Dance, '
        'Sandstorm, or Snow and the user is not holding Utility Umbrella. If '
        'the user is holding a Power Herb or the weather is Desolate Land or '
        'Sunny Day, the move completes in one turn. If the user is holding '
        'Utility Umbrella and the weather is Desolate Land or Sunny Day, the '
        'move still requires a turn to charge.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:onBasePower',
      'showdown_callback:onTryMove',
      'unsupported_mechanic:charge_then_strike',
    ],
    showdownHooksPresent: <String>[
      'onBasePower',
      'onTryMove',
    ],
  ),
  _showdownSeedMove(
    id: 'trick_room',
    showdownMoveId: 'trickroom',
    name: 'Trick Room',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    priority: -7,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trickroom'),
    ],
    shortDescription: 'Goes last. For 5 turns, turn order is reversed.',
    description:
        'For 5 turns, the Speed of every Pokemon is recalculated for the '
        'purposes of determining turn order. During the effect, each '
        'Pokemon\'s Speed is considered to be (10000 - its normal Speed), and '
        'if this value is greater than 8191, 8192 is subtracted from it. If '
        'this move is used during the effect, the effect ends.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onFieldEnd',
      'condition.onFieldRestart',
      'condition.onFieldStart',
    ],
  ),
];

/// Helper unique pour garder le seed compact sans créer de framework.
///
/// `source` vaut volontairement `showdown` :
/// - il décrit l'origine du contenu métier ;
/// - pas le mode de chargement ;
/// - le bootstrap reste local/offline car ce seed est déjà versionné ici.
PokemonMove _showdownSeedMove({
  required String id,
  required String showdownMoveId,
  required String name,
  required int generation,
  required String type,
  required PokemonMoveCategory category,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int basePower = 0,
  required PokemonMoveAccuracy accuracy,
  int pp = 0,
  bool noPpBoosts = false,
  int priority = 0,
  int critRatio = 1,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  String shortDescription = '',
  String description = '',
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
  List<String> showdownHooksPresent = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: generation,
    source: 'showdown',
    type: type,
    category: category,
    target: target,
    basePower: basePower,
    accuracy: accuracy,
    pp: pp,
    noPpBoosts: noPpBoosts,
    priority: priority,
    critRatio: critRatio,
    flags: flags,
    effects: effects,
    shortDescription: shortDescription,
    description: description,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
    sourceRefs: PokemonMoveSourceRefs(
      showdownMoveId: showdownMoveId,
      showdownHooksPresent: showdownHooksPresent,
    ),
  ).normalized();
}

```

### [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart)
```dart
import 'dart:convert';

import '../seeds/pokemon_moves_bootstrap_seed.dart';
import '../ports/project_workspace.dart';

/// Initialise la structure locale Pokemon dans le workspace d'un projet
/// utilisateur.
///
/// Points importants pour ce lot :
/// - n'ecrit que sous [ProjectWorkspace.projectRoot]
/// - ne touche jamais au `project.json`
/// - ne remplace jamais un fichier JSON deja present
/// - reste idempotent si on le relance plusieurs fois
class InitializePokemonProjectStorageUseCase {
  const InitializePokemonProjectStorageUseCase();

  static const Map<String, String> _catalogDescriptions = <String, String>{
    'moves': 'Move catalog for the local Pokemon project database.',
    'abilities': 'Ability catalog for the local Pokemon project database.',
    'items': 'Item catalog for the local Pokemon project database.',
    'types': 'Type catalog for the local Pokemon project database.',
    'growth_rates':
        'Growth rate catalog for the local Pokemon project database.',
    'natures': 'Nature catalog for the local Pokemon project database.',
    'egg_groups': 'Egg group catalog for the local Pokemon project database.',
    'habitats': 'Habitat catalog for the local Pokemon project database.',
    'generations': 'Generation catalog for the local Pokemon project database.',
    'version_groups':
        'Version group catalog for the local Pokemon project database.',
    'encounter_rules':
        'Encounter rule catalog for the local Pokemon project database.',
  };

  static const Map<String, String> _catalogFiles = <String, String>{
    'moves': 'catalogs/moves.json',
    'abilities': 'catalogs/abilities.json',
    'items': 'catalogs/items.json',
    'types': 'catalogs/types.json',
    'growth_rates': 'catalogs/growth_rates.json',
    'natures': 'catalogs/natures.json',
    'egg_groups': 'catalogs/egg_groups.json',
    'habitats': 'catalogs/habitats.json',
    'generations': 'catalogs/generations.json',
    'version_groups': 'catalogs/version_groups.json',
    'encounter_rules': 'catalogs/encounter_rules.json',
  };

  static const List<String> _projectDirectories = <String>[
    'data/pokemon/species/.keep',
    'data/pokemon/learnsets/.keep',
    'data/pokemon/evolutions/.keep',
    'data/pokemon/media/.keep',
    'data/pokemon/catalogs/.keep',
    'assets/pokemon/sprites/.keep',
    'assets/pokemon/cries/.keep',
    'assets/pokemon/portraits/.keep',
  ];

  Future<void> execute(ProjectWorkspace workspace) async {
    for (final markerPath in _projectDirectories) {
      final absoluteMarkerPath =
          workspace.resolveProjectRelativePath(markerPath);
      await workspace.ensureDirectoryExists(absoluteMarkerPath);
    }

    await _writeJsonIfAbsent(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_data_manifest',
        'meta': <String, Object?>{
          'description':
              'Root manifest for the local Pokemon data stored inside a project workspace.',
          'notes': const <Object?>[],
        },
        'catalogFiles': _catalogFiles,
        'futureDataFolders': const <String, String>{
          'species': 'species/',
          'learnsets': 'learnsets/',
          'evolutions': 'evolutions/',
          'media': 'media/',
        },
      },
    );

    for (final entry in _catalogFiles.entries) {
      // M4 ouvre volontairement un seul seam spécial : `moves`.
      //
      // Tous les autres catalogues restent sur le scaffold vide historique.
      // On évite ainsi de transformer ce lot en framework de seed multi-
      // catalogues, tout en corrigeant le vrai trou produit : un projet frais
      // ne doit plus partir avec un `moves.json` vide.
      final payload = entry.key == 'moves'
          ? _movesBootstrapPayload()
          : <String, Object?>{
              'schemaVersion': 1,
              'kind': 'pokemon_catalog',
              'catalog': entry.key,
              'meta': <String, Object?>{
                'description': _catalogDescriptions[entry.key]!,
                'sourcePriority': const <String>['internal'],
                'notes': const <Object?>[],
              },
              'entries': const <Object?>[],
            };
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/${entry.value}',
        payload,
      );
    }
  }

  /// Construit le payload bootstrap du catalogue moves.
  ///
  /// Invariants de M4 :
  /// - le bootstrap ne parse jamais Showdown à l'exécution ;
  /// - il ne télécharge rien ;
  /// - il réutilise un seed versionné localement dans `map_editor` ;
  /// - il écrit la copie projet uniquement si `moves.json` n'existe pas déjà.
  ///
  /// On laisse ici `project.json` totalement hors scope :
  /// le manifeste pointe déjà vers `data/pokemon/catalogs/moves.json`, et M4
  /// ne doit pas rouvrir ce contrat.
  Map<String, Object?> _movesBootstrapPayload() {
    return buildEmbeddedPokemonMovesBootstrapSeed().toJson();
  }

  Future<void> _writeJsonIfAbsent(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (await workspace.fileExists(absolutePath)) {
      // Garde-fou central : un fichier existant appartient deja au projet
      // utilisateur et ne doit pas etre ecrase par ce bootstrap.
      return;
    }
    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}

```

### [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart)
```dart
import 'dart:convert';

import '../ports/project_workspace.dart';
import 'initialize_pokemon_project_storage_use_case.dart';
import '../seeds/pokemon_moves_bootstrap_seed.dart';

/// Seed un mini jeu de donnees Pokemon realiste dans le workspace projet.
///
/// Ce use case reste volontairement petit :
/// - il initialise d'abord la structure locale si besoin
/// - il ecrit uniquement dans le workspace projet utilisateur
/// - il ne touche jamais a `project.json`
/// - il ne remplace jamais un fichier metier deja existant
/// - il n'enrichit un catalogue existant que s'il est encore au format
///   scaffold vide du bootstrap precedent
class SeedPokemonDemoDataUseCase {
  const SeedPokemonDemoDataUseCase({
    this.initializeStorage = const InitializePokemonProjectStorageUseCase(),
  });

  final InitializePokemonProjectStorageUseCase initializeStorage;

  Future<void> execute(ProjectWorkspace workspace) async {
    await initializeStorage.execute(workspace);

    // M4 change la donne pour `moves.json` :
    // - le bootstrap projet embarque maintenant deja un seed canonique non vide ;
    // - on ne veut surtout pas maintenir ici une deuxieme source de verite
    //   concurrente pour les moves ;
    // - mais on garde le seam "upgrade old empty scaffold" pour les workspaces
    //   plus anciens qui auraient encore un `moves.json` vide.
    await _writeCatalogIfSeedable(
      workspace,
      relativePath: 'data/pokemon/catalogs/moves.json',
      catalogName: 'moves',
      scaffoldDescription: _catalogScaffoldDescriptions['moves']!,
      payload: buildEmbeddedPokemonMovesBootstrapSeed().toJson(),
    );

    for (final entry in _catalogSeeds.entries) {
      await _writeCatalogIfSeedable(
        workspace,
        relativePath: 'data/pokemon/catalogs/${entry.key}.json',
        catalogName: entry.key,
        scaffoldDescription: _catalogScaffoldDescriptions[entry.key]!,
        payload: entry.value,
      );
    }

    for (final entry in _speciesSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/species/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _learnsetSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/learnsets/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _evolutionSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/evolutions/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _mediaSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/media/${entry.key}',
        entry.value,
      );
    }
  }

  Future<void> _writeCatalogIfSeedable(
    ProjectWorkspace workspace, {
    required String relativePath,
    required String catalogName,
    required String scaffoldDescription,
    required Map<String, Object?> payload,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (!await workspace.fileExists(absolutePath)) {
      await _writeJsonIfAbsent(workspace, relativePath, payload);
      return;
    }

    final currentRaw = await workspace.readTextFile(absolutePath);
    final dynamic decoded = jsonDecode(currentRaw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    if (!_matchesBootstrapScaffold(
      decoded,
      catalogName: catalogName,
      scaffoldDescription: scaffoldDescription,
    )) {
      return;
    }

    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  bool _matchesBootstrapScaffold(
    Map<String, dynamic> json, {
    required String catalogName,
    required String scaffoldDescription,
  }) {
    final meta = json['meta'];
    final entries = json['entries'];
    if (meta is! Map<String, dynamic>) return false;
    if (entries is! List || entries.isNotEmpty) return false;

    final sourcePriority = meta['sourcePriority'];
    final notes = meta['notes'];
    if (json['schemaVersion'] != 1) return false;
    if (json['kind'] != 'pokemon_catalog') return false;
    if (json['catalog'] != catalogName) return false;
    if (meta['description'] != scaffoldDescription) return false;
    if (sourcePriority is! List || sourcePriority.length != 1) return false;
    if (sourcePriority.single != 'internal') return false;
    if (notes is! List || notes.isNotEmpty) return false;
    return true;
  }

  Future<void> _writeJsonIfAbsent(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (await workspace.fileExists(absolutePath)) {
      return;
    }
    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}

const Map<String, String> _catalogScaffoldDescriptions = <String, String>{
  'moves': 'Move catalog for the local Pokemon project database.',
  'abilities': 'Ability catalog for the local Pokemon project database.',
  'items': 'Item catalog for the local Pokemon project database.',
  'types': 'Type catalog for the local Pokemon project database.',
  'growth_rates': 'Growth rate catalog for the local Pokemon project database.',
  'natures': 'Nature catalog for the local Pokemon project database.',
  'egg_groups': 'Egg group catalog for the local Pokemon project database.',
  'habitats': 'Habitat catalog for the local Pokemon project database.',
  'generations': 'Generation catalog for the local Pokemon project database.',
  'version_groups':
      'Version group catalog for the local Pokemon project database.',
  'encounter_rules':
      'Encounter rule catalog for the local Pokemon project database.',
};

const Map<String, Map<String, Object?>> _catalogSeeds =
    <String, Map<String, Object?>>{
  'types': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'types',
    'meta': <String, Object?>{
      'description': 'Type catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'grass',
        'name': 'Grass',
        'names': <String, String>{
          'fr': 'Plante',
          'en': 'Grass',
        },
        'damageRelations': <String, Object?>{
          'weakTo': <String>['fire', 'ice', 'poison', 'flying', 'bug'],
          'resists': <String>['water', 'electric', 'grass', 'ground'],
        },
      },
      <String, Object?>{
        'id': 'poison',
        'name': 'Poison',
        'names': <String, String>{
          'fr': 'Poison',
          'en': 'Poison',
        },
        'damageRelations': <String, Object?>{
          'weakTo': <String>['ground', 'psychic'],
          'resists': <String>['grass', 'fighting', 'poison', 'bug', 'fairy'],
        },
      },
    ],
  },
  'abilities': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'abilities',
    'meta': <String, Object?>{
      'description': 'Ability catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'overgrow',
        'name': 'Overgrow',
        'names': <String, String>{
          'fr': 'Engrais',
          'en': 'Overgrow',
        },
        'shortDesc': 'Boosts Grass-type moves when the Pokemon is low on HP.',
        'generation': 3,
      },
      <String, Object?>{
        'id': 'chlorophyll',
        'name': 'Chlorophyll',
        'names': <String, String>{
          'fr': 'Chlorophylle',
          'en': 'Chlorophyll',
        },
        'shortDesc': 'Doubles Speed in harsh sunlight.',
        'generation': 3,
      },
    ],
  },
  'growth_rates': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'growth_rates',
    'meta': <String, Object?>{
      'description':
          'Growth rate catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'medium_slow',
        'name': 'Medium Slow',
        'description': 'Uses the classic medium-slow experience curve.',
      },
    ],
  },
};

const Map<String, Map<String, Object?>> _speciesSeeds =
    <String, Map<String, Object?>>{
  '0001-bulbasaur.json': <String, Object?>{
    'id': 'bulbasaur',
    'slug': 'bulbasaur',
    'nationalDex': 1,
    'names': <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    'speciesName': <String, String>{
      'fr': 'Pokémon Graine',
      'en': 'Seed Pokemon',
    },
    'genIntroduced': 1,
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
    },
    'baseStats': <String, Object?>{
      'hp': 45,
      'atk': 49,
      'def': 49,
      'spa': 65,
      'spd': 65,
      'spe': 45,
      'bst': 318,
    },
    'abilities': <String, Object?>{
      'primary': 'overgrow',
      'secondary': null,
      'hidden': 'chlorophyll',
    },
    'breeding': <String, Object?>{
      'genderRatio': <String, double>{
        'male': 0.875,
        'female': 0.125,
      },
      'eggGroups': <String>['monster', 'grass'],
      'hatchCycles': 20,
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium_slow',
      'baseExp': 64,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, Object?>{
      'learnset': 'bulbasaur',
      'evolution': 'bulbasaur',
      'media': 'bulbasaur',
    },
    'dexContent': <String, Object?>{
      'heightM': 0.7,
      'weightKg': 6.9,
      'color': 'green',
      'flavorText':
          'A strange seed was planted on its back at birth. The plant sprouts and grows with this Pokemon.',
    },
    'gameplayFlags': <String, Object?>{
      'starterEligible': true,
      'giftOnly': false,
      'tradeOnly': false,
    },
    'sourceMeta': <String, Object?>{
      'seededBy': 'SeedPokemonDemoDataUseCase',
      'seedVersion': 1,
    },
  },
  '0002-ivysaur.json': <String, Object?>{
    'id': 'ivysaur',
    'slug': 'ivysaur',
    'nationalDex': 2,
    'names': <String, String>{
      'fr': 'Herbizarre',
      'en': 'Ivysaur',
    },
    'speciesName': <String, String>{
      'fr': 'Pokémon Graine',
      'en': 'Seed Pokemon',
    },
    'genIntroduced': 1,
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
    },
    'baseStats': <String, Object?>{
      'hp': 60,
      'atk': 62,
      'def': 63,
      'spa': 80,
      'spd': 80,
      'spe': 60,
      'bst': 405,
    },
    'abilities': <String, Object?>{
      'primary': 'overgrow',
      'secondary': null,
      'hidden': 'chlorophyll',
    },
    'breeding': <String, Object?>{
      'genderRatio': <String, double>{
        'male': 0.875,
        'female': 0.125,
      },
      'eggGroups': <String>['monster', 'grass'],
      'hatchCycles': 20,
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium_slow',
      'baseExp': 142,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, Object?>{
      'learnset': 'ivysaur',
      'evolution': 'ivysaur',
      'media': 'ivysaur',
    },
    'dexContent': <String, Object?>{
      'heightM': 1.0,
      'weightKg': 13.0,
      'color': 'green',
      'flavorText':
          'When the bulb on its back grows large, it appears to lose the ability to stand on its hind legs.',
    },
    'gameplayFlags': <String, Object?>{
      'starterEligible': false,
      'giftOnly': false,
      'tradeOnly': false,
    },
    'sourceMeta': <String, Object?>{
      'seededBy': 'SeedPokemonDemoDataUseCase',
      'seedVersion': 1,
    },
  },
};

const Map<String, Map<String, Object?>> _learnsetSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'startingMoves': <String>['tackle', 'growl'],
    'relearnMoves': <String>['tackle', 'growl', 'vine_whip', 'razor_leaf'],
    'levelUp': <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 3,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 7,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'razor_leaf',
        'level': 13,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ],
    'tm': <Object?>[
      <String, Object?>{
        'moveId': 'growl',
        'versionGroup': 'demo',
      },
    ],
    'tutor': <Object?>[],
    'egg': <Object?>[],
    'event': <Object?>[],
    'transfer': <Object?>[],
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'startingMoves': <String>['tackle', 'growl', 'vine_whip'],
    'relearnMoves': <String>['tackle', 'growl', 'vine_whip', 'razor_leaf'],
    'levelUp': <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'razor_leaf',
        'level': 20,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ],
    'tm': <Object?>[],
    'tutor': <Object?>[],
    'egg': <Object?>[],
    'event': <Object?>[],
    'transfer': <Object?>[],
  },
};

const Map<String, Map<String, Object?>> _evolutionSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'preEvolution': null,
    'evolutions': <Object?>[
      <String, Object?>{
        'targetSpeciesId': 'ivysaur',
        'method': 'level_up',
        'minLevel': 16,
        'itemId': null,
        'requiredMoveId': null,
        'conditionText': <String, String>{
          'fr': 'Évolue au niveau 16',
          'en': 'Evolves at level 16',
        },
      },
    ],
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'preEvolution': 'bulbasaur',
    'evolutions': <Object?>[],
  },
};

const Map<String, Map<String, Object?>> _mediaSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'defaultFormId': 'base',
    'variants': <String, Object?>{
      'base': <String, Object?>{
        'frontStatic': 'assets/pokemon/sprites/bulbasaur/front.png',
        'backStatic': 'assets/pokemon/sprites/bulbasaur/back.png',
        'frontShinyStatic': 'assets/pokemon/sprites/bulbasaur/front_shiny.png',
        'backShinyStatic': 'assets/pokemon/sprites/bulbasaur/back_shiny.png',
        'icon': 'assets/pokemon/sprites/bulbasaur/icon.png',
        'party': 'assets/pokemon/sprites/bulbasaur/party.png',
        'overworld': 'assets/pokemon/sprites/bulbasaur/overworld.png',
        'portrait': 'assets/pokemon/portraits/bulbasaur.png',
        'cry': 'assets/pokemon/cries/bulbasaur.ogg',
        'animations': <String, Object?>{
          'battleFront': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
            'animationId': 'battle_front',
          },
          'battleBack': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/bulbasaur/battle_back_sheet.png',
            'animationId': 'battle_back',
          },
        },
      },
    },
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'defaultFormId': 'base',
    'variants': <String, Object?>{
      'base': <String, Object?>{
        'frontStatic': 'assets/pokemon/sprites/ivysaur/front.png',
        'backStatic': 'assets/pokemon/sprites/ivysaur/back.png',
        'icon': 'assets/pokemon/sprites/ivysaur/icon.png',
        'party': 'assets/pokemon/sprites/ivysaur/party.png',
        'overworld': 'assets/pokemon/sprites/ivysaur/overworld.png',
        'portrait': 'assets/pokemon/portraits/ivysaur.png',
        'cry': 'assets/pokemon/cries/ivysaur.ogg',
        'animations': <String, Object?>{
          'battleFront': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/ivysaur/battle_front_sheet.png',
            'animationId': 'battle_front',
          },
        },
      },
    },
  },
};

```

### [`packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart)
```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late InitializePokemonProjectStorageUseCase useCase;
  late ProjectFileSystem workspace;
  late LoadPokemonMovesCatalogUseCase loadMovesCatalogUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('pokemon_project_storage_');
    useCase = const InitializePokemonProjectStorageUseCase();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    loadMovesCatalogUseCase = const LoadPokemonMovesCatalogUseCase(
      readRepository: FilePokemonReadRepository(),
    );
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('InitializePokemonProjectStorageUseCase', () {
    test('creates the expected structure inside the project workspace',
        () async {
      await useCase.execute(workspace);

      for (final relativeDir in _expectedDirectories) {
        final dir =
            Directory(workspace.resolveProjectRelativePath(relativeDir));
        expect(
          await dir.exists(),
          isTrue,
          reason: 'Missing directory $relativeDir in project workspace',
        );
      }

      for (final relativeFile in _expectedFiles) {
        final file = File(
          workspace.resolveProjectRelativePath(relativeFile),
        );
        expect(
          await file.exists(),
          isTrue,
          reason: 'Missing file $relativeFile in project workspace',
        );
      }

      // Garde-fou important pour ce lot : seules les metadonnees JSON passent
      // par `data/pokemon/...`. Il ne faut pas recreer les anciens chemins
      // ambigus ou errones sous `data/pokemon/`.
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon/cries'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon/media'),
        ).exists(),
        isTrue,
      );
    });

    test(
        'writes only inside workspace projectRoot and not from cwd-relative paths',
        () async {
      final cwd = Directory.current.path;
      final cwdManifest = File(
        p.join(cwd, 'data', 'pokemon', 'pokemon_data_manifest.json'),
      );
      final cwdSprites = Directory(
        p.join(cwd, 'assets', 'pokemon', 'sprites'),
      );

      expect(
        p.equals(workspace.projectRoot, cwd),
        isFalse,
        reason: 'Test workspace must differ from cwd to validate confinement.',
      );
      expect(await cwdManifest.exists(), isFalse);
      expect(await cwdSprites.exists(), isFalse);

      await useCase.execute(workspace);

      expect(await cwdManifest.exists(), isFalse);
      expect(await cwdSprites.exists(), isFalse);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/pokemon_data_manifest.json',
          ),
        ).exists(),
        isTrue,
      );
    });

    test('creates valid json payloads with the expected schema', () async {
      await useCase.execute(workspace);

      final manifest = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/pokemon_data_manifest.json',
        ),
      );
      expect(manifest['schemaVersion'], 1);
      expect(manifest['kind'], 'pokemon_data_manifest');
      expect(manifest['meta'], <String, Object?>{
        'description':
            'Root manifest for the local Pokemon data stored inside a project workspace.',
        'notes': <Object?>[],
      });
      expect(manifest['futureDataFolders'], <String, Object?>{
        'species': 'species/',
        'learnsets': 'learnsets/',
        'evolutions': 'evolutions/',
        'media': 'media/',
      });

      final catalogFiles = manifest['catalogFiles'] as Map<String, dynamic>;
      expect(
          catalogFiles.keys,
          containsAll(<String>[
            'moves',
            'abilities',
            'items',
            'types',
            'growth_rates',
            'natures',
            'egg_groups',
            'habitats',
            'generations',
            'version_groups',
            'encounter_rules',
          ]));

      for (final entry in _expectedCatalogs.entries) {
        final catalog = await _readJsonMap(
          workspace.resolveProjectRelativePath(entry.value),
        );
        expect(catalog['schemaVersion'], 1);
        expect(catalog['kind'], 'pokemon_catalog');
        expect(catalog['catalog'], entry.key);
        if (entry.key == 'moves') {
          expect(catalog['meta'], <String, Object?>{
            'description': _expectedCatalogDescriptions[entry.key]!,
            'sourcePriority': <Object?>['internal'],
            'notes': <Object?>[
              'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
              'Curated from Showdown-backed move data and versioned in the repository.',
              'bootstrap_seed_version:1',
            ],
          });
          expect(catalog['entries'], isNotEmpty);
        } else {
          expect(catalog['meta'], <String, Object?>{
            'description': _expectedCatalogDescriptions[entry.key]!,
            'sourcePriority': <Object?>['internal'],
            'notes': <Object?>[],
          });
          expect(catalog['entries'], isEmpty);
        }
      }
    });

    test('writes a canonical non-empty moves seed without legacy dead fields',
        () async {
      await useCase.execute(workspace);

      final catalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/moves.json',
        ),
      );
      final entries = (catalog['entries'] as List<dynamic>)
          .cast<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);

      expect(entries, isNotEmpty);

      for (final entry in entries) {
        expect(() => PokemonMove.fromJson(entry), returnsNormally);
        expect(entry.containsKey('power'), isFalse);
        expect(entry.containsKey('accuracyText'), isFalse);
        expect(entry.containsKey('shortDesc'), isFalse);
      }

      expect(
        entries.map((entry) => entry['id']),
        containsAll(<String>[
          'tackle',
          'growl',
          'vine_whip',
          'razor_leaf',
          'thunderbolt',
          'trick_room',
        ]),
      );
    });

    test('keeps enriched contract absent from the monorepo root', () async {
      await useCase.execute(workspace);

      final rootManifest = File(
        p.join(Directory.current.path, 'data', 'pokemon',
            'pokemon_data_manifest.json'),
      );
      final rootMoves = File(
        p.join(
          Directory.current.path,
          'data',
          'pokemon',
          'catalogs',
          'moves.json',
        ),
      );

      expect(await rootManifest.exists(), isFalse);
      expect(await rootMoves.exists(), isFalse);
    });

    test('is idempotent and never overwrites an existing json file', () async {
      await useCase.execute(workspace);

      final movesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/catalogs/moves.json',
      );
      final file = File(movesPath);
      const customPayload = '{\n  "kept": true\n}';
      await file.writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await file.readAsString(), customPayload);
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
          'Pokemon Workspace Test', tempProjectRoot.path);

      final manifestFile = File(workspace.projectManifestPath);
      final before = await manifestFile.readAsString();

      await useCase.execute(workspace);

      final after = await manifestFile.readAsString();
      expect(after, before);
    });

    test('bootstrapped moves seed is readable by the existing local loader',
        () async {
      await useCase.execute(workspace);

      final result = await loadMovesCatalogUseCase.execute(workspace);

      expect(result.isAvailable, isTrue);
      expect(result.entries, isNotEmpty);
      expect(
        result.entries.map((entry) => entry.id),
        containsAll(<String>[
          'tackle',
          'growl',
          'vine_whip',
          'razor_leaf',
        ]),
      );
    });

    test('does not run automatically when a project is created', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );

      await createProjectUseCase.execute(
          'Manual Pokemon Bootstrap', tempProjectRoot.path);

      expect(
        await Directory(
          workspace.resolveProjectRelativePath('data/pokemon'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          workspace.resolveProjectRelativePath('assets/pokemon'),
        ).exists(),
        isFalse,
      );

      await useCase.execute(workspace);

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/pokemon_data_manifest.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

const List<String> _expectedDirectories = <String>[
  'data/pokemon/species',
  'data/pokemon/learnsets',
  'data/pokemon/evolutions',
  'data/pokemon/media',
  'data/pokemon/catalogs',
  'assets/pokemon/sprites',
  'assets/pokemon/cries',
  'assets/pokemon/portraits',
];

const List<String> _expectedFiles = <String>[
  'data/pokemon/pokemon_data_manifest.json',
  'data/pokemon/catalogs/moves.json',
  'data/pokemon/catalogs/abilities.json',
  'data/pokemon/catalogs/items.json',
  'data/pokemon/catalogs/types.json',
  'data/pokemon/catalogs/growth_rates.json',
  'data/pokemon/catalogs/natures.json',
  'data/pokemon/catalogs/egg_groups.json',
  'data/pokemon/catalogs/habitats.json',
  'data/pokemon/catalogs/generations.json',
  'data/pokemon/catalogs/version_groups.json',
  'data/pokemon/catalogs/encounter_rules.json',
];

const Map<String, String> _expectedCatalogs = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
};

const Map<String, String> _expectedCatalogDescriptions = <String, String>{
  'moves': 'Move catalog for the local Pokemon project database.',
  'abilities': 'Ability catalog for the local Pokemon project database.',
  'items': 'Item catalog for the local Pokemon project database.',
  'types': 'Type catalog for the local Pokemon project database.',
  'growth_rates': 'Growth rate catalog for the local Pokemon project database.',
  'natures': 'Nature catalog for the local Pokemon project database.',
  'egg_groups': 'Egg group catalog for the local Pokemon project database.',
  'habitats': 'Habitat catalog for the local Pokemon project database.',
  'generations': 'Generation catalog for the local Pokemon project database.',
  'version_groups':
      'Version group catalog for the local Pokemon project database.',
  'encounter_rules':
      'Encounter rule catalog for the local Pokemon project database.',
};

Future<Map<String, dynamic>> _readJsonMap(String path) async {
  final raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}

```

### [`packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart)
```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_demo_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    useCase = const SeedPokemonDemoDataUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('SeedPokemonDemoDataUseCase', () {
    test('creates the expected demo dataset inside the project workspace',
        () async {
      await useCase.execute(workspace);

      for (final relativePath in _expectedDatasetFiles) {
        expect(
          await File(workspace.resolveProjectRelativePath(relativePath))
              .exists(),
          isTrue,
          reason: 'Missing demo dataset file $relativePath',
        );
      }
    });

    test('creates nothing under the monorepo root', () async {
      await useCase.execute(workspace);

      for (final relativePath in _expectedRootLeakChecks) {
        expect(
          await File(p.join(Directory.current.path, relativePath)).exists(),
          isFalse,
          reason: 'Unexpected file leaked into monorepo root: $relativePath',
        );
      }
    });

    test('generated json files are valid and cross references stay coherent',
        () async {
      await useCase.execute(workspace);

      final bulbasaurSpecies = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final bulbasaurLearnset = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      final bulbasaurEvolution = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      final ivysaurSpecies = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0002-ivysaur.json',
        ),
      );
      final bulbasaurMedia = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/media/bulbasaur.json',
        ),
      );
      final movesCatalog = await _readJsonMap(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      );
      final abilitiesCatalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/abilities.json',
        ),
      );
      final typesCatalog = await _readJsonMap(
        workspace
            .resolveProjectRelativePath('data/pokemon/catalogs/types.json'),
      );
      final growthRatesCatalog = await _readJsonMap(
        workspace.resolveProjectRelativePath(
          'data/pokemon/catalogs/growth_rates.json',
        ),
      );

      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['learnset'],
        'bulbasaur',
      );
      expect(bulbasaurLearnset['speciesId'], 'bulbasaur');
      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['evolution'],
        'bulbasaur',
      );
      expect(bulbasaurEvolution['speciesId'], 'bulbasaur');
      expect(
        (ivysaurSpecies['refs'] as Map<String, dynamic>)['evolution'],
        'ivysaur',
      );
      expect(
        (ivysaurSpecies['refs'] as Map<String, dynamic>)['learnset'],
        'ivysaur',
      );
      expect(
        (bulbasaurSpecies['refs'] as Map<String, dynamic>)['media'],
        'bulbasaur',
      );
      expect(bulbasaurMedia['speciesId'], 'bulbasaur');
      expect(bulbasaurMedia['defaultFormId'], 'base');
      expect(
        (bulbasaurMedia['variants'] as Map<String, dynamic>)
            .containsKey('base'),
        isTrue,
      );

      final levelUp = bulbasaurLearnset['levelUp'] as List<dynamic>;
      expect(levelUp, isNotEmpty);
      expect(levelUp.first, containsPair('moveId', 'tackle'));
      expect(levelUp.first, contains('level'));
      expect(levelUp.first, containsPair('source', 'level_up'));
      expect(levelUp.first, containsPair('versionGroup', 'demo'));
      expect((bulbasaurLearnset['tm'] as List<dynamic>).first,
          containsPair('moveId', 'growl'));

      expect(
        (movesCatalog['entries'] as List<dynamic>).map((e) => e['id']).toSet(),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
      expect(
        (abilitiesCatalog['entries'] as List<dynamic>)
            .map((e) => e['id'])
            .toSet(),
        containsAll(<String>{'overgrow', 'chlorophyll'}),
      );
      expect(
        (typesCatalog['entries'] as List<dynamic>).map((e) => e['id']).toSet(),
        containsAll(<String>{'grass', 'poison'}),
      );
      expect(
        (growthRatesCatalog['entries'] as List<dynamic>)
            .map((e) => e['id'])
            .toSet(),
        contains('medium_slow'),
      );
    });

    test('is idempotent and does not overwrite an existing demo file',
        () async {
      await useCase.execute(workspace);

      final speciesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/species/0001-bulbasaur.json',
      );
      const customPayload = '{\n  "custom": true\n}';
      await File(speciesPath).writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await File(speciesPath).readAsString(), customPayload);
    });

    test(
        'enriches scaffold catalogs once but preserves a manually edited catalog',
        () async {
      await useCase.execute(workspace);

      final movesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/catalogs/moves.json',
      );
      final initialMoves = await _readJsonMap(movesPath);
      final initialEntries = (initialMoves['entries'] as List<dynamic>)
          .cast<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);
      expect(initialEntries, isNotEmpty);
      expect(
        initialEntries.map((entry) => entry['id']),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
      for (final entry in initialEntries) {
        expect(() => PokemonMove.fromJson(entry), returnsNormally);
      }

      const customPayload = '{\n  "entries": ["keep-me"]\n}';
      await File(movesPath).writeAsString(customPayload);

      await useCase.execute(workspace);

      expect(await File(movesPath).readAsString(), customPayload);
    });

    test(
        'upgrades an old empty moves scaffold to the shared canonical bootstrap seed',
        () async {
      final movesPath = workspace.resolveProjectRelativePath(
        'data/pokemon/catalogs/moves.json',
      );
      final file = File(movesPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          <String, Object?>{
            'schemaVersion': 1,
            'kind': 'pokemon_catalog',
            'catalog': 'moves',
            'meta': <String, Object?>{
              'description':
                  'Move catalog for the local Pokemon project database.',
              'sourcePriority': <String>['internal'],
              'notes': <Object?>[],
            },
            'entries': <Object?>[],
          },
        ),
      );

      await useCase.execute(workspace);

      final upgradedCatalog = await _readJsonMap(movesPath);
      final entries = (upgradedCatalog['entries'] as List<dynamic>)
          .cast<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false);

      expect(entries, isNotEmpty);
      expect(
        entries.map((entry) => entry['id']),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
      for (final entry in entries) {
        expect(() => PokemonMove.fromJson(entry), returnsNormally);
        expect(entry.containsKey('power'), isFalse);
        expect(entry.containsKey('accuracyText'), isFalse);
        expect(entry.containsKey('shortDesc'), isFalse);
      }
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute(
        'Pokemon Demo Data',
        tempProjectRoot.path,
      );

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}

const List<String> _expectedDatasetFiles = <String>[
  'data/pokemon/catalogs/moves.json',
  'data/pokemon/catalogs/abilities.json',
  'data/pokemon/catalogs/types.json',
  'data/pokemon/catalogs/growth_rates.json',
  'data/pokemon/species/0001-bulbasaur.json',
  'data/pokemon/species/0002-ivysaur.json',
  'data/pokemon/learnsets/bulbasaur.json',
  'data/pokemon/learnsets/ivysaur.json',
  'data/pokemon/evolutions/bulbasaur.json',
  'data/pokemon/evolutions/ivysaur.json',
  'data/pokemon/media/bulbasaur.json',
  'data/pokemon/media/ivysaur.json',
];

const List<String> _expectedRootLeakChecks = <String>[
  'data/pokemon/species/0001-bulbasaur.json',
  'data/pokemon/learnsets/bulbasaur.json',
  'data/pokemon/evolutions/bulbasaur.json',
  'data/pokemon/catalogs/moves.json',
];

Future<Map<String, dynamic>> _readJsonMap(String path) async {
  final raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}

```
