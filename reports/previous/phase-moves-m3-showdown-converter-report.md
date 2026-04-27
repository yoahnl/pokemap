# M3 — Enrichissement du convertisseur Showdown moves vers le modèle canonique `PokemonMove`

## 1. Résumé exécutif honnête

Le lot M3 a été livré strictement dans `map_editor`.

Ce qui était réellement incomplet avant patch :
- le convertisseur Showdown existant produisait encore un JSON local minimal historique (`power`, `accuracyText`, `shortDesc`) au lieu d'entrées canoniques fondées sur `PokemonMove` ;
- aucun effet structuré `PokemonMoveEffect` n'était construit ;
- aucun `engineSupportLevel`, aucun `unsupportedReasons`, aucune traçabilité `sourceRefs.showdownHooksPresent` n'étaient produits ;
- la projection légère côté éditeur ne savait lire que l'ancien format ;
- les tests ne prouvaient pas le mapping canonique attendu par M3.

Ce que le lot fait réellement :
- enrichit `ShowdownMoveCatalogConverter` pour construire de vrais `PokemonMove`, puis sérialiser `PokemonMove.toJson()` dans `PokemonCatalogFile.entries` ;
- convertit un sous-ensemble honnête de champs et d'effets Showdown vers `PokemonMoveAccuracy` et `PokemonMoveEffect` ;
- détecte les hooks/callbacks Showdown présents dans les payloads en mémoire et les trace dans `sourceRefs.showdownHooksPresent` ;
- infère `engineSupportLevel` selon une politique explicite et documentée ;
- remplit `unsupportedReasons` avec des formats stables ;
- ajuste minimalement `LoadPokemonMovesCatalogUseCase` pour lire les entrées canoniques sans casser les entrées legacy locales encore présentes ;
- ajuste minimalement le merge de sync pour éviter de réinjecter des alias legacy morts sur les entrées resynchronisées ;
- ajoute des tests ciblés du convertisseur et renforce les tests de sync.

Ce que le lot ne fait pas :
- aucun seed embarqué ;
- aucun bootstrap projet ;
- aucun loader runtime spécialisé ;
- aucune validation projet globale enrichie ;
- aucun changement dans `map_runtime` ou `map_battle` ;
- aucun changement du modèle canonique `map_core` ;
- aucune écriture Git.

## 2. État initial audité réel

### 2.1. Fichiers audités avant modification

Audit obligatoire réellement effectué sur :
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- `packages/map_editor/pubspec.yaml`
- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move_accuracy.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.dart`
- `packages/map_core/lib/map_core.dart`
- `docs/combat/moves-data-model-spec.md`
- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- extraits représentatifs de `pokemon-showdown-master/data/moves.ts`

### 2.2. Constat réel avant patch

#### Convertisseur existant

`showdown_move_catalog_converter.dart` :
- produisait un `PokemonCatalogFile` avec des entrées génériques minimalistes ;
- mappait seulement `id`, `name`, `names.en`, `type`, `category`, `power`, `accuracy`, `accuracyText`, `pp`, `priority`, `target`, `shortDesc`, `description`, `generation` ;
- ignorait totalement `PokemonMove`, `PokemonMoveAccuracy`, `PokemonMoveEffect` ;
- n'avait aucune politique de support moteur ;
- n'avait aucune détection de hooks Showdown ;
- ne produisait aucun effet structuré.

#### Use case de sync / projection légère

`sync_pokemon_moves_catalog_use_case.dart` :
- exposait encore une vue légère calée sur les anciens champs `power`, `accuracy`, `accuracyText`, `shortDesc` ;
- ne savait pas lire une entrée canonique `PokemonMove.toJson()` ;
- mergeait les entrées locales et externes sans filtrer les anciens alias legacy devenus obsolètes.

#### Tests existants

`sync_pokemon_moves_catalog_use_case_test.dart` :
- testait encore l'ancien format `power` / `accuracyText` / `shortDesc` ;
- ne prouvait pas la conversion canonique vers `PokemonMove` ;
- ne couvrait pas les familles d'effets M3 ni la politique de support moteur.

#### Snapshot Showdown réellement accessible dans `map_editor`

`showdown_snapshot_source.dart` lit `moves.json` via `jsonDecode`.

Conséquence importante :
- le chemin HTTP réel ne peut pas transporter les fonctions JS des sources TS Showdown ;
- la détection de hooks doit donc rester capable de fonctionner si le convertisseur reçoit un payload en mémoire contenant des fonctions, mais elle ne peut pas être prouvée via le seul chemin HTTP JSON live.

Cette nuance a été conservée explicitement dans le code et les tests.

## 3. Problèmes confirmés / non confirmés

### 3.1. Problèmes confirmés

- Le convertisseur n'utilisait pas le modèle canonique `map_core`.
- Le convertisseur réintroduisait implicitement l'ancien duo `accuracy` / `accuracyText` côté stockage projet.
- Le convertisseur ne produisait aucun `effects` structuré.
- Le convertisseur ne matérialisait aucune limite via `engineSupportLevel` / `unsupportedReasons`.
- La projection légère ne savait pas lire le nouveau format canonique.
- Le merge risquait de conserver des clés legacy mortes (`power`, `accuracyText`, `shortDesc`) sur des entrées désormais canoniques.
- Les tests étaient insuffisants pour M3.

### 3.2. Problèmes non confirmés

- Aucun besoin réel de toucher `map_core` : le modèle M2-bis suffisait.
- Aucun besoin réel de toucher `map_runtime`.
- Aucun besoin réel de toucher `map_battle`.
- Aucun besoin réel d'ouvrir M4, M5, M6, M7 ou M8.
- Aucun besoin réel de créer un convertisseur parallèle ou un modèle intermédiaire local.

## 4. Cause racine réelle

La cause racine n'était pas un bug isolé mais un décalage de phase :
- le pipeline moves côté éditeur existait déjà, mais avait été introduit comme catalogue léger historique ;
- M2 / M2-bis ont créé un vrai modèle canonique dans `map_core` ;
- le convertisseur n'avait pas encore convergé vers ce modèle.

Résultat :
- le repo possédait une source de vérité canonique (`PokemonMove`) ;
- mais le point d'entrée Showdown continuait à produire un format legacy incompatible avec cette ambition.

M3 ferme précisément cet écart, sans ouvrir le runtime ni le moteur.

## 5. Décisions retenues / rejetées

### 5.1. Décisions retenues

1. Le convertisseur construit de vrais objets `PokemonMove`, puis sérialise `toJson()`.
2. `dealDamage` n'est réintroduit nulle part.
3. Les dégâts standards sont représentés uniquement par `basePower` + `category` + `usesStandardDamageFlow`.
4. Les effets additionnels ou alternatifs sont encodés via `PokemonMoveEffect`.
5. Les hooks Showdown détectés sont tracés dans `sourceRefs.showdownHooksPresent`.
6. Les limites sont matérialisées dans `unsupportedReasons` avec des formats stables.
7. `engineSupportLevel` est inféré explicitement, avec une politique commentée.
8. Le fallback legacy de la projection légère est conservé uniquement pour les vraies entrées legacy.
9. Une entrée qui a déjà la forme canonique mais ne parse plus doit faire échouer la lecture légère honnêtement au lieu d'être silencieusement rabaissée en legacy.
10. Le merge conserve les vrais champs locaux additionnels, mais ne réinjecte pas les alias legacy morts sur les entrées canoniques mises à jour.

### 5.2. Décisions rejetées

1. Ne pas créer un second convertisseur spécialisé M3.
2. Ne pas construire du `Map<String, dynamic>` canonique à la main sans passer par `PokemonMove`.
3. Ne pas rebrancher le runtime.
4. Ne pas toucher le bootstrap projet.
5. Ne pas enrichir `map_core` dans ce lot.
6. Ne pas inventer de faux effets pour des mécaniques complexes.
7. Ne pas sur-convertir les moves à charge sur deux tours en faux `chargeThenStrike` quand la donnée source ne suffit pas honnêtement.

## 6. Périmètre inclus / exclu

### 6.1. Inclus

- enrichissement du convertisseur Showdown existant ;
- conversion vers `PokemonMove` canonique ;
- mapping honnête d'un sous-ensemble utile de champs et d'effets ;
- détection des hooks Showdown quand des fonctions sont présentes dans le payload source ;
- inférence de `engineSupportLevel` ;
- alimentation de `unsupportedReasons` ;
- ajustement minimal de la projection légère de sync/load ;
- ajustement minimal du merge pour éviter les alias legacy morts ;
- tests ciblés convertisseur + sync ;
- report ultra complet.

### 6.2. Exclus

- seed embarqué ;
- bootstrap projet ;
- loader runtime spécialisé ;
- validation projet globale enrichie ;
- UI enrichie ;
- runtime ;
- battle engine ;
- extension du modèle `map_core` ;
- écriture Git.

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### 7.1. Modifiés

- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### 7.2. Créés

- `packages/map_editor/test/showdown_move_catalog_converter_test.dart`
- `reports/phase-moves-m3-showdown-converter-report.md`

### 7.3. Supprimés

- aucun

## 8. Justification fichier par fichier

### `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`

Point central du lot.

Modifications apportées :
- ajout de l'import `map_core` ;
- construction de vrais `PokemonMove` ;
- mapping des champs de base ;
- mapping de `PokemonMoveAccuracy` ;
- mapping des flags connus ;
- détection des flags inconnus ;
- mapping des effets structurés supportés ;
- ajout de `setPseudoWeather` ;
- détection des hooks Showdown ;
- alimentation de `sourceRefs.showdownHooksPresent` ;
- alimentation de `unsupportedReasons` ;
- inférence de `engineSupportLevel` ;
- commentaires structurants sur la stratégie de conversion.

Raison :
- c'est le seam canonique exact de M3.

### `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

Modifications minimales mais nécessaires :
- lecture canonique prioritaire via `PokemonMove.fromJson(entry)` ;
- fallback legacy limité aux vraies entrées non canoniques ;
- échec explicite si une entrée canonique est invalide ;
- filtrage des champs legacy morts pendant le merge (`power`, `accuracyText`, `shortDesc`) quand l'entrée externe est déjà canonique ;
- commentaires explicites sur cette frontière.

Raison :
- sans ce mini-ajustement, l'éditeur ne saurait pas lire le nouveau format M3, ou masquerait des entrées canoniques cassées.

### `packages/map_editor/test/showdown_move_catalog_converter_test.dart`

Nouveau test unitaire ciblé sur le convertisseur.

Couvre explicitement :
- move offensif standard sans `dealDamage` (`thunderbolt`) ;
- `drain` (`absorb`) ;
- `multiHit` (`double slap`) ;
- `alwaysHits` (`swift`) ;
- `applyStatus` direct (`thunder wave`) ;
- `modifyStats` self / target (`swords dance`, `leer`) ;
- `setWeather` / `setTerrain` / `setPseudoWeather` ;
- `setSideCondition` / `setSlotCondition` ;
- détection de callbacks Showdown et support partiel / catalogue seul (`thunder`, `weather ball`) ;
- `fixedDamage` (`sonic boom`) ;
- politique honnête des moves à charge (`solar beam`) ;
- `selfSwitch`, `forceSwitch`, `requireRecharge`.

Raison :
- les preuves M3 ne pouvaient pas reposer uniquement sur le test de sync existant.

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

Test d'intégration locale ajusté pour M3.

Modifications :
- vérification que les entrées synchronisées sont bien lisibles comme `PokemonMove` canoniques ;
- vérification que les alias legacy morts ne reviennent pas sur les entrées mises à jour ;
- vérification que les métadonnées locales utiles restent préservées (`names.fr`, `editorNote`) ;
- vérification que la vue légère continue de fonctionner ;
- ajout d'une preuve que l'éditeur ne rabat plus silencieusement une entrée canonique cassée vers le fallback legacy.

Raison :
- c'est la preuve locale que le flux `sync -> merge -> load` reste cohérent après M3.

## 9. Commandes réellement exécutées

### 9.1. Audit

Commandes réellement exécutées :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
sed -n '1,260p' packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '1,260p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
sed -n '1,220p' packages/map_editor/pubspec.yaml
sed -n '1,260p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '1,320p' packages/map_core/lib/src/models/pokemon_move_effect.dart
sed -n '1,220p' packages/map_core/lib/src/models/pokemon_move_accuracy.dart
sed -n '1,260p' docs/combat/moves-data-model-spec.md
sed -n '220,420p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '1,160p' packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart
sed -n '1,220p' packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart
sed -n '1,220p' packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
rg -n "ShowdownMoveCatalogConverter|accuracyText|shortDesc|power'|power\]" packages/map_editor/test packages/map_editor/lib/src/application -g'*.dart'
rg -n "fetchShowdownMovesSnapshot|showdown moves snapshot|moves snapshot|PokemonExternalSourceRepository" packages/map_editor/lib -g'*.dart'
rg -n "thunder-wave|double-slap|rain-dance|electric-terrain|trick-room|stealth-rock|future-sight|solar-beam|hyper-beam|swift|thunderbolt|absorb|swords-dance" pokemon-showdown-master/data/moves.ts
rg -n "damage:\s*'level'|damage:\s*[0-9]+|multihit:|pseudoWeather:|sideCondition:|slotCondition:|selfSwitch:|forceSwitch:|breaksProtect:|mustrecharge|charge|recharge|selfBoost:|secondary:|secondaries:" pokemon-showdown-master/data/moves.ts | head -n 200
rg -n "breaksProtect|selfSwitch|forceSwitch|mustrecharge|twoTurnMove|charge.*state|pseudoWeather|slotCondition|sideCondition|selfBoost|self:\s*\{|secondary:|secondaries:" pokemon-showdown-master/data/moves.ts | head -n 200
sed -n '18680,18780p' pokemon-showdown-master/data/moves.ts
sed -n '19480,19620p' pokemon-showdown-master/data/moves.ts
sed -n '16100,16220p' pokemon-showdown-master/data/moves.ts
sed -n '17280,17460p' pokemon-showdown-master/data/moves.ts
```

### 9.2. Format

```bash
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/test/showdown_move_catalog_converter_test.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
/opt/homebrew/bin/dart format packages/map_editor/test/showdown_move_catalog_converter_test.dart
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/test/showdown_move_catalog_converter_test.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 9.3. Analyze

```bash
/opt/homebrew/bin/flutter analyze --no-pub
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/services/showdown_move_catalog_converter.dart lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/services/showdown_move_catalog_converter.dart lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 9.4. Tests

```bash
/opt/homebrew/bin/flutter test test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
/opt/homebrew/bin/flutter test test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 9.5. Reviewer séparé

Reviewer séparé utilisé via agent `Wegener` pour relire :
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/test/showdown_move_catalog_converter_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

## 10. Résultats réels de format / analyze / tests

### 10.1. Format

Résultat final : OK.

Sortie utile :

```text
Formatted packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
Formatted packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
Formatted packages/map_editor/test/showdown_move_catalog_converter_test.dart
Formatted 4 files (3 changed) in 0.03 seconds.
```

Puis après corrections de review :

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

### 10.2. Analyze

#### Première passe package large

Résultat : non verte au premier coup.

Constat honnête :
- énorme bruit préexistant dans `packages/map_editor` hors scope (infos et warnings) ;
- un seul vrai problème introduit par le lot à ce stade :
  - `error • Undefined class 'PokemonCatalogFile' • test/showdown_move_catalog_converter_test.dart`

Cette erreur venait d'un import manquant dans le nouveau test. Elle a été corrigée.

#### Analyse ciblée finale

Résultat final : OK.

Sortie utile :

```text
Analyzing 4 items...
No issues found! (ran in 1.1s)
```

Puis après corrections de review :

```text
Analyzing 4 items...
No issues found! (ran in 1.4s)
```

### 10.3. Tests

#### Première passe ciblée

Résultat : 1 échec.

Échec rencontré :
- le test d'unknown flag attendait `structuredPartial` pour un move status vide, alors que la politique du convertisseur le classait honnêtement en `catalogOnly` dans ce cas.

Correction retenue :
- le test a été ajusté pour utiliser un move offensif standard avec flag inconnu, ce qui correspond mieux à l'intention testée (`partial` sans faux positif de catalogue seul).

#### Passe finale ciblée

Résultat final : OK.

Sortie utile :

```text
00:01 +8: All tests passed!
```

## 11. Incidents rencontrés

1. `flutter analyze --no-pub` package large a remonté beaucoup de bruit préexistant hors scope, plus un unique import manquant dans le nouveau test.
2. Le premier test ciblé a échoué sur une attente de support level mal choisie pour un cas de test artificiel (`unknown flag` sur move status vide).
3. Lors du rerun parallèle `analyze + test`, la commande `flutter test` a brièvement attendu le startup lock Flutter :

```text
Waiting for another flutter command to release the startup lock...
```

Cela s'est résolu proprement sans action destructive ni redémarrage forcé.

## 12. État git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? .DS_Store
?? packages/map_editor/test/showdown_move_catalog_converter_test.dart
?? reports/phase-moves-m3-showdown-converter-report.md
```

### `git diff --stat`

```text
 .../services/showdown_move_catalog_converter.dart  | 1234 ++++++++++++++++++--
 .../sync_pokemon_moves_catalog_use_case.dart       |   95 ++
 .../sync_pokemon_moves_catalog_use_case_test.dart  |   91 +-
 3 files changed, 1344 insertions(+), 76 deletions(-)
```

### Fichiers non suivis

```text
.DS_Store
packages/map_editor/test/showdown_move_catalog_converter_test.dart
reports/phase-moves-m3-showdown-converter-report.md
```

Note honnête :
- `.DS_Store` était déjà non suivi et hors scope ;
- aucune écriture Git n'a été faite.

## 13. Checklist finale

- [x] je me suis basé sur le code réel du repo
- [x] j’ai audité les fichiers critiques avant modification
- [x] je n’ai pas créé de convertisseur parallèle
- [x] je n’ai pas créé de modèle parallèle au `PokemonMove`
- [x] j’ai utilisé le modèle canonique `map_core`
- [x] je n’ai pas réintroduit `dealDamage`
- [x] j’ai traité `setPseudoWeather`
- [x] j’ai mappé honnêtement les champs de base
- [x] j’ai mappé honnêtement les effets supportés
- [x] j’ai détecté les hooks Showdown
- [x] j’ai rempli `sourceRefs.showdownHooksPresent`
- [x] j’ai rempli `engineSupportLevel` selon une politique explicite
- [x] j’ai rempli `unsupportedReasons` proprement
- [x] je n’ai pas menti sur les mécaniques complexes
- [x] je n’ai pas ouvert M4
- [x] je n’ai pas ouvert M5
- [x] je n’ai pas ouvert M6
- [x] je n’ai pas ouvert M7
- [x] je n’ai pas ouvert M8
- [x] je n’ai pas touché runtime
- [x] je n’ai pas touché battle
- [x] je n’ai fait aucune écriture Git interdite
- [x] j’ai mis beaucoup de commentaires utiles dans le code
- [x] j’ai ajouté/complété des tests représentatifs
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai intégré ses remarques valides
- [x] mon report final est honnête
- [x] mon report contient le contenu complet des fichiers touchés

## 14. Autocritique du reviewer séparé

Retour du reviewer `Wegener` :

1. `P2` La projection mixte canonical/legacy pouvait masquer une entrée canonique cassée en retombant silencieusement sur le fallback legacy.
2. `P3` La couverture M3 restait incomplète sur `fixedDamage` et sur la politique honnête des moves à charge (`chargeThenStrike` non fabriqué mais limite explicitée).

Le reviewer n'a pas remonté d'écart de scope hors `map_editor`, ni de réintroduction d'une structure parallèle au modèle canonique.

## 15. Corrections appliquées suite à cette review

1. `sync_pokemon_moves_catalog_use_case.dart`
   - le fallback legacy n'est plus global ;
   - si l'entrée ressemble à un `PokemonMove` canonique, on parse d'abord via `PokemonMove.fromJson(entry)` ;
   - si ce parse échoue, on jette maintenant une `EditorPersistenceException` explicite ;
   - le fallback legacy ne sert plus qu'aux vraies entrées non canoniques.

2. `sync_pokemon_moves_catalog_use_case_test.dart`
   - ajout d'un test qui prouve qu'une entrée canonique invalide ne se fait plus silencieusement rétrograder en lecture legacy.

3. `showdown_move_catalog_converter_test.dart`
   - ajout d'une preuve explicite sur `fixedDamage` via `sonic boom` ;
   - ajout d'une preuve explicite sur la politique honnête des moves à charge via `solar beam` :
     - raison `unsupported_mechanic:charge_then_strike`
     - `catalogOnly`
     - absence de faux effet `charge_then_strike` fabriqué.

4. Valider à nouveau
   - rerun analyze ciblé : OK
   - rerun tests ciblés : OK

## 16. Conclusion honnête

M3 est fermé de manière défendable.

Le convertisseur Showdown existant produit désormais des entrées canoniques fondées sur `PokemonMove`, sans structure parallèle, sans `dealDamage`, avec `setPseudoWeather`, avec une traçabilité honnête des hooks Showdown et un niveau de support moteur explicite.

Le lot reste strictement borné à `map_editor`, et les seuls ajustements latéraux effectués sont ceux nécessaires pour que le flux local `sync -> merge -> load` continue de fonctionner sans masquer une entrée canonique cassée.

Limites restantes, volontairement hors scope :
- aucun seed embarqué ;
- aucun bootstrap projet enrichi ;
- aucun loader runtime ;
- aucune validation projet globale enrichie ;
- aucun pont vers `map_battle`.

## 17. Annexe — contenu complet de tous les fichiers texte touchés

Le report s'exclut lui-même de cette annexe pour éviter la récursion infinie.

### `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un snapshot Showdown `moves.json` vers le catalogue local `moves`.
///
/// M3 change volontairement la nature de la sortie :
/// - on ne produit plus un petit JSON ad hoc de catalogue "lisible" ;
/// - on construit de vrais objets `PokemonMove` du modèle canonique `map_core` ;
/// - puis on sérialise `PokemonMove.toJson()` dans `PokemonCatalogFile.entries`.
///
/// Cette décision borne proprement la suite :
/// - le convertisseur reste l'unique pipeline Showdown -> projet ;
/// - la normalisation du modèle canonique protège la sortie ;
/// - `map_editor` ne crée aucune structure parallèle ;
/// - `map_battle` ne lit toujours pas le JSON projet brut.
class ShowdownMoveCatalogConverter {
  const ShowdownMoveCatalogConverter();

  /// Produit un [PokemonCatalogFile] moves complet à partir du snapshot brut.
  ///
  /// Invariants M3 :
  /// - les entrées sont triées par id pour garder des diffs stables ;
  /// - chaque entrée provient d'un vrai `PokemonMove` ;
  /// - les limites de conversion sont matérialisées dans :
  ///   - `engineSupportLevel`
  ///   - `unsupportedReasons`
  ///   - `sourceRefs.showdownHooksPresent`
  PokemonCatalogFile convert(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      throw const EditorValidationException(
        'Showdown moves snapshot cannot be empty',
      );
    }

    final entries = snapshot.entries
        .map(
          (snapshotEntry) => _convertEntry(
            rawId: snapshotEntry.key,
            rawEntry: snapshotEntry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ((left['id'] as String?) ?? '').compareTo(
          (right['id'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from the Pokémon Showdown moves snapshot.',
        sourcePriority: <String>['showdown', 'local_merge'],
        notes: <String>[
          'M3 converts Showdown move entries through the canonical PokemonMove model.',
          'The converter never derives battle logic from prose descriptions.',
          'Engine support limits are stored explicitly per move.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _convertEntry({
    required String rawId,
    required Object? rawEntry,
  }) {
    if (rawEntry is! Map) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" must be an object',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    final displayName = _readDisplayName(rawId, entry);
    final localId = _normalizeSnakeCaseId(displayName);
    if (localId.isEmpty) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" does not expose a usable local id',
      );
    }

    final unsupportedReasons = <String>[];
    final seenUnsupportedReasons = <String>{};
    void addUnsupportedReason(String reason) {
      final normalized = reason.trim();
      if (normalized.isEmpty || !seenUnsupportedReasons.add(normalized)) {
        return;
      }
      unsupportedReasons.add(normalized);
    }

    // La capture des hooks Showdown doit être déterministe et honnête.
    //
    // Important :
    // - le snapshot HTTP JSON réel perd déjà les fonctions JS de Showdown ;
    // - mais le convertisseur doit rester capable de signaler ces hooks quand
    //   une source en mémoire les fournit encore (tests, outillage futur,
    //   audits plus riches à partir des sources TS).
    final hooksPresent = _collectShowdownHooks(entry);
    for (final hook in hooksPresent) {
      addUnsupportedReason('showdown_callback:$hook');
    }

    final type = _readRequiredLowerCaseString(
      rawId: rawId,
      fieldName: 'type',
      rawValue: entry['type'],
    );
    final category = _readRequiredCategory(rawId, entry['category']);
    final rawTarget = _readTrimmedString(entry['target']);
    if (rawTarget == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a target',
      );
    }
    final target = _parseTarget(rawTarget);
    final resolvedTarget = target ?? PokemonMoveTarget.scripted;
    if (target == null) {
      addUnsupportedReason('unsupported_target:$rawTarget');
    }

    final flags = _mapFlags(entry['flags'], addUnsupportedReason);
    final effects = _buildStructuredEffects(
      entry: entry,
      rawTarget: rawTarget,
      addUnsupportedReason: addUnsupportedReason,
    );

    _collectUnsupportedTopLevelFields(
      entry: entry,
      addUnsupportedReason: addUnsupportedReason,
    );

    final move = PokemonMove(
      id: localId,
      name: displayName,
      names: <String, String>{'en': displayName},
      generation: _readOptionalInt(entry['gen']),
      source: 'showdown',
      type: type,
      category: category,
      target: resolvedTarget,
      basePower: _readBasePower(entry['basePower']),
      accuracy: _readAccuracy(rawId, entry['accuracy']),
      pp: _readOptionalInt(entry['pp']) ?? 0,
      noPpBoosts: _readBool(entry['noPPBoosts']),
      priority: _readOptionalInt(entry['priority']) ?? 0,
      critRatio: _readOptionalInt(entry['critRatio']) ?? 1,
      flags: flags,
      effects: _dedupeEffects(effects),
      shortDescription: _readTrimmedString(entry['shortDesc']) ?? '',
      description: _readTrimmedString(entry['desc']) ?? '',
      engineSupportLevel: _inferEngineSupportLevel(
        unsupportedReasons: unsupportedReasons,
        usesStandardDamageFlow: category != PokemonMoveCategory.status &&
            _readBasePower(entry['basePower']) > 0,
        effectsAreEmpty: effects.isEmpty,
      ),
      unsupportedReasons: unsupportedReasons,
      sourceRefs: PokemonMoveSourceRefs(
        showdownMoveId: rawId.trim().isEmpty ? null : rawId.trim(),
        showdownHooksPresent: hooksPresent,
      ),
    ).normalized();

    return move.toJson();
  }

  List<PokemonMoveEffect> _buildStructuredEffects({
    required Map<String, dynamic> entry,
    required String rawTarget,
    required void Function(String reason) addUnsupportedReason,
  }) {
    final effects = <PokemonMoveEffect>[];

    void addEffect(PokemonMoveEffect effect) {
      effects.add(effect);
    }

    // M3 assume explicitement que le flow de dégâts standards n'est plus un
    // effet structuré. `basePower` + `category` + `usesStandardDamageFlow`
    // suffisent à porter cette sémantique.
    _appendFixedDamageEffect(
      entry['damage'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendMultiHitEffect(
      entry['multihit'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    _appendDirectStatusEffect(
      rawStatus: entry['status'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: entry['volatileStatus'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: entry['boosts'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['heal'],
      kind: _FractionEffectKind.heal,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['drain'],
      kind: _FractionEffectKind.drain,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['recoil'],
      kind: _FractionEffectKind.recoil,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFieldStringEffect(
      rawValue: entry['weather'],
      fieldName: 'weather',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['terrain'],
      fieldName: 'terrain',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );
    _appendSelfSwitchEffect(entry['selfSwitch'], addEffect: addEffect);
    _appendForceSwitchEffect(entry['forceSwitch'], addEffect: addEffect);
    _appendBreakProtectEffect(entry['breaksProtect'], addEffect: addEffect);
    _appendSideConditionEffect(
      rawConditionId: entry['sideCondition'],
      targetScope: _sideConditionScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendSlotConditionEffect(
      rawConditionId: entry['slotCondition'],
      addEffect: addEffect,
    );

    // Les payloads `self` et `selfBoost` sont des seams non triviaux :
    // - ils modélisent des conséquences sur le lanceur, pas sur la cible ;
    // - certaines valeurs (`mustrecharge`) ont désormais un effet dédié ;
    // - d'autres payloads internes de Showdown restent volontairement hors
    //   scope et sont tracés comme limites explicites.
    _appendSelfPayloadEffects(
      rawSelf: entry['self'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfBoostEffects(
      rawSelfBoost: entry['selfBoost'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondaryEffects(
      rawSecondary: entry['secondary'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondariesEffects(
      rawSecondaries: entry['secondaries'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    // Les moves à charge sur deux tours sont un cas classique de faux positif
    // si on "simplifie" trop fort.
    //
    // On ne fabrique donc pas `charge_then_strike` à partir d'une simple
    // intuition sur les callbacks. En revanche, on marque la limite quand la
    // donnée source expose déjà des signaux suffisants (`flags.charge`,
    // callbacks, `condition`).
    if (_hasChargeThenStrikeSignal(entry)) {
      addUnsupportedReason('unsupported_mechanic:charge_then_strike');
    }

    return effects;
  }

  void _appendFixedDamageEffect(
    Object? rawDamage, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawDamage == null) {
      return;
    }
    if (rawDamage is num) {
      final value = rawDamage.toInt();
      if (value > 0) {
        addEffect(
          PokemonMoveEffect.fixedDamage(value: value),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:fixed_damage');
      }
      return;
    }
    if (rawDamage is String && rawDamage.trim().toLowerCase() == 'level') {
      addEffect(
        const PokemonMoveEffect.fixedDamage(usesUserLevel: true),
      );
      return;
    }
    addUnsupportedReason('unsupported_mechanic:fixed_damage');
  }

  void _appendMultiHitEffect(
    Object? rawMultiHit, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawMultiHit == null) {
      return;
    }
    if (rawMultiHit is num) {
      final hits = rawMultiHit.toInt();
      if (hits > 0) {
        addEffect(
          PokemonMoveEffect.multiHit(minHits: hits, maxHits: hits),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:multi_hit');
      }
      return;
    }
    if (rawMultiHit is List && rawMultiHit.length == 2) {
      final min = rawMultiHit[0];
      final max = rawMultiHit[1];
      if (min is num && max is num) {
        addEffect(
          PokemonMoveEffect.multiHit(
            minHits: min.toInt(),
            maxHits: max.toInt(),
          ),
        );
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:multi_hit');
  }

  void _appendDirectStatusEffect({
    required Object? rawStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final statusId = _readLowerCaseString(rawStatus);
    if (statusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyStatus(
        targetScope: targetScope,
        chance: chance,
        statusId: statusId,
      ),
    );
  }

  void _appendDirectVolatileStatusEffect({
    required Object? rawVolatileStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final volatileStatusId = _readLowerCaseString(rawVolatileStatus);
    if (volatileStatusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyVolatileStatus(
        targetScope: targetScope,
        chance: chance,
        volatileStatusId: volatileStatusId,
      ),
    );
  }

  void _appendModifyStatsEffect({
    required Object? rawBoosts,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    final stageChanges = _readStageChanges(
      rawBoosts,
      addUnsupportedReason: addUnsupportedReason,
    );
    if (stageChanges.isEmpty) {
      return;
    }
    addEffect(
      PokemonMoveEffect.modifyStats(
        targetScope: targetScope,
        chance: chance,
        stageChanges: stageChanges,
      ),
    );
  }

  void _appendFractionEffect({
    required Object? rawFraction,
    required _FractionEffectKind kind,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawFraction == null) {
      return;
    }
    if (rawFraction is List && rawFraction.length == 2) {
      final numerator = rawFraction[0];
      final denominator = rawFraction[1];
      if (numerator is num && denominator is num) {
        final normalizedNumerator = numerator.toInt();
        final normalizedDenominator = denominator.toInt();
        switch (kind) {
          case _FractionEffectKind.heal:
            addEffect(
              PokemonMoveEffect.heal(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.drain:
            addEffect(
              PokemonMoveEffect.drain(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.recoil:
            addEffect(
              PokemonMoveEffect.recoil(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
        }
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:${kind.reasonLabel}');
  }

  void _appendFieldStringEffect({
    required Object? rawValue,
    required String fieldName,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final normalizedId = _readLowerCaseString(rawValue);
    if (normalizedId == null) {
      return;
    }

    switch (fieldName) {
      case 'weather':
        addEffect(
          PokemonMoveEffect.setWeather(weatherId: normalizedId),
        );
      case 'terrain':
        addEffect(
          PokemonMoveEffect.setTerrain(terrainId: normalizedId),
        );
      case 'pseudoWeather':
        addEffect(
          PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: normalizedId),
        );
    }
  }

  void _appendSelfSwitchEffect(
    Object? rawSelfSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawSelfSwitch == true) {
      addEffect(const PokemonMoveEffect.selfSwitch());
      return;
    }
    final mode = _readLowerCaseString(rawSelfSwitch);
    if (mode != null) {
      addEffect(PokemonMoveEffect.selfSwitch(mode: mode));
    }
  }

  void _appendForceSwitchEffect(
    Object? rawForceSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawForceSwitch == true) {
      addEffect(const PokemonMoveEffect.forceSwitch());
    }
  }

  void _appendBreakProtectEffect(
    Object? rawBreaksProtect, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawBreaksProtect == true) {
      addEffect(const PokemonMoveEffect.breakProtect());
    }
  }

  void _appendSideConditionEffect({
    required Object? rawConditionId,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSideCondition(
        targetScope: targetScope,
        conditionId: conditionId,
      ),
    );
  }

  void _appendSlotConditionEffect({
    required Object? rawConditionId,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSlotCondition(conditionId: conditionId),
    );
  }

  void _appendSelfPayloadEffects({
    required Object? rawSelf,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    if (rawSelf is! Map) {
      return;
    }

    final self = rawSelf.cast<String, dynamic>();
    final supportedKeys = <String>{
      'boosts',
      'volatileStatus',
      'sideCondition',
      'pseudoWeather',
      'status',
    };

    _appendModifyStatsEffect(
      rawBoosts: self['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    final selfVolatileStatus = _readLowerCaseString(self['volatileStatus']);
    if (selfVolatileStatus == 'mustrecharge') {
      addEffect(
        const PokemonMoveEffect.requireRecharge(),
      );
    } else if (selfVolatileStatus != null) {
      _appendDirectVolatileStatusEffect(
        rawVolatileStatus: selfVolatileStatus,
        targetScope: PokemonMoveEffectTargetScope.self,
        chance: chance,
        addEffect: addEffect,
      );
    }

    _appendDirectStatusEffect(
      rawStatus: self['status'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
    );
    _appendSideConditionEffect(
      rawConditionId: self['sideCondition'],
      targetScope: PokemonMoveEffectTargetScope.allySide,
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: self['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );

    for (final entry in self.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:self.${entry.key}');
    }
  }

  void _appendSelfBoostEffects({
    required Object? rawSelfBoost,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSelfBoost is! Map) {
      return;
    }

    final selfBoost = rawSelfBoost.cast<String, dynamic>();
    _appendModifyStatsEffect(
      rawBoosts: selfBoost['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    for (final entry in selfBoost.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.key == 'boosts' || !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:selfBoost.${entry.key}');
    }
  }

  void _appendSecondaryEffects({
    required Object? rawSecondary,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondary is! Map) {
      return;
    }
    _appendSecondaryPayloadEffects(
      rawSecondary.cast<String, dynamic>(),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
      reasonPrefix: 'secondary',
    );
  }

  void _appendSecondariesEffects({
    required Object? rawSecondaries,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondaries is! List) {
      return;
    }

    for (var index = 0; index < rawSecondaries.length; index++) {
      final secondary = rawSecondaries[index];
      if (secondary is! Map) {
        addUnsupportedReason(
            'unsupported_secondary_payload:secondaries[$index]');
        continue;
      }
      _appendSecondaryPayloadEffects(
        secondary.cast<String, dynamic>(),
        addEffect: addEffect,
        addUnsupportedReason: addUnsupportedReason,
        reasonPrefix: 'secondaries[$index]',
      );
    }
  }

  void _appendSecondaryPayloadEffects(
    Map<String, dynamic> secondary, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    required String reasonPrefix,
  }) {
    final chance = _readSecondaryChance(
      secondary['chance'],
      addUnsupportedReason: addUnsupportedReason,
      reasonLabel: '$reasonPrefix.chance',
    );

    _appendDirectStatusEffect(
      rawStatus: secondary['status'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: secondary['volatileStatus'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: secondary['boosts'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfPayloadEffects(
      rawSelf: secondary['self'],
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    const supportedKeys = <String>{
      'chance',
      'status',
      'volatileStatus',
      'boosts',
      'self',
    };

    for (final entry in secondary.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_secondary_payload:${entry.key}');
    }
  }

  int? _readSecondaryChance(
    Object? rawChance, {
    required void Function(String reason) addUnsupportedReason,
    required String reasonLabel,
  }) {
    if (rawChance == null) {
      return null;
    }
    if (rawChance is num) {
      final chance = rawChance.toInt();
      if (chance >= 1 && chance <= 100) {
        return chance;
      }
    }
    addUnsupportedReason('unsupported_secondary_payload:$reasonLabel');
    return null;
  }

  List<PokemonMoveStatStageChange> _readStageChanges(
    Object? rawBoosts, {
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawBoosts is! Map) {
      return const <PokemonMoveStatStageChange>[];
    }

    final changes = <PokemonMoveStatStageChange>[];
    final sortedEntries = rawBoosts.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      final rawStat = '${entry.key}'.trim();
      final stat = _parseStatId(rawStat);
      final rawStages = entry.value;
      if (stat == null || rawStages is! num) {
        addUnsupportedReason('unsupported_mechanic:boosts');
        continue;
      }
      final stages = rawStages.toInt();
      if (stages == 0) {
        continue;
      }
      changes.add(
        PokemonMoveStatStageChange(stat: stat, stages: stages),
      );
    }

    return changes;
  }

  void _collectUnsupportedTopLevelFields({
    required Map<String, dynamic> entry,
    required void Function(String reason) addUnsupportedReason,
  }) {
    for (final mapEntry in entry.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final key = mapEntry.key;
      final value = mapEntry.value;
      if (_handledTopLevelFields.contains(key) ||
          _ignoredTopLevelMetadataFields.contains(key) ||
          !_hasMeaningfulValue(value)) {
        continue;
      }
      if (value is Function) {
        // Déjà tracé via `showdown_callback:<hookPath>`.
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:$key');
    }
  }

  List<String> _collectShowdownHooks(Map<String, dynamic> entry) {
    final hooks = <String>[];
    final seen = <String>{};

    void visit(Object? value, String path) {
      if (value is Function) {
        if (seen.add(path)) {
          hooks.add(path);
        }
        return;
      }
      if (value is Map) {
        final entries = value.entries.toList()
          ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
        for (final nested in entries) {
          final key = '${nested.key}'.trim();
          if (key.isEmpty) {
            continue;
          }
          final nestedPath = path.isEmpty ? key : '$path.$key';
          visit(nested.value, nestedPath);
        }
        return;
      }
      if (value is List) {
        for (var index = 0; index < value.length; index++) {
          visit(value[index], '$path[$index]');
        }
      }
    }

    for (final key in entry.keys.toList()..sort()) {
      visit(entry[key], key);
    }

    hooks.sort();
    return hooks;
  }

  List<PokemonMoveFlag> _mapFlags(
    Object? rawFlags,
    void Function(String reason) addUnsupportedReason,
  ) {
    if (rawFlags is! Map) {
      return const <PokemonMoveFlag>[];
    }

    final flags = <PokemonMoveFlag>[];
    final seen = <PokemonMoveFlag>{};
    final sortedEntries = rawFlags.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      if (!_isTruthyFlagValue(entry.value)) {
        continue;
      }
      final flag = _parseFlag('${entry.key}');
      if (flag == null) {
        addUnsupportedReason('unknown_flag:${entry.key}');
        continue;
      }
      if (seen.add(flag)) {
        flags.add(flag);
      }
    }

    return flags;
  }

  PokemonMoveEngineSupportLevel _inferEngineSupportLevel({
    required List<String> unsupportedReasons,
    required bool usesStandardDamageFlow,
    required bool effectsAreEmpty,
  }) {
    // Politique M3 :
    // - `structured_supported` si rien d'important n'est perdu ;
    // - `structured_partial` si la structure principale est utile mais qu'il
    //   reste des limites honnêtement tracées ;
    // - `catalog_only` si réduire le move à ce squelette deviendrait trompeur.
    if (unsupportedReasons.isEmpty) {
      return PokemonMoveEngineSupportLevel.structuredSupported;
    }

    final hasCatalogOnlyBlockingReason = unsupportedReasons.any((reason) {
      return reason == 'unsupported_mechanic:charge_then_strike' ||
          reason == 'unsupported_mechanic:condition' ||
          reason == 'unsupported_mechanic:damage' ||
          reason == 'unsupported_mechanic:damageCallback' ||
          reason == 'showdown_callback:basePowerCallback' ||
          reason == 'showdown_callback:damageCallback';
    });

    if (hasCatalogOnlyBlockingReason) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    // Si le move n'a ni flow de dégâts standard ni effet structuré utile, mais
    // dépend malgré tout de hooks ou de mécaniques non portées, on préfère
    // rester honnête et le signaler comme catalogue seulement.
    if (!usesStandardDamageFlow && effectsAreEmpty) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    return PokemonMoveEngineSupportLevel.structuredPartial;
  }

  List<PokemonMoveEffect> _dedupeEffects(List<PokemonMoveEffect> effects) {
    final uniqueEffects = <PokemonMoveEffect>[];
    final seen = <String>{};
    for (final effect in effects) {
      final fingerprint = effect.normalized().toJson().toString();
      if (!seen.add(fingerprint)) {
        continue;
      }
      uniqueEffects.add(effect);
    }
    return uniqueEffects;
  }

  PokemonMoveAccuracy _readAccuracy(String rawId, Object? rawAccuracy) {
    if (rawAccuracy == true) {
      return const PokemonMoveAccuracy.alwaysHits();
    }
    if (rawAccuracy is num) {
      return PokemonMoveAccuracy.percent(value: rawAccuracy.toInt());
    }
    throw EditorPersistenceException(
      'Showdown move entry "$rawId" does not expose a supported accuracy payload',
    );
  }

  PokemonMoveCategory _readRequiredCategory(String rawId, Object? rawValue) {
    final normalized = _readLowerCaseString(rawValue);
    switch (normalized) {
      case 'physical':
        return PokemonMoveCategory.physical;
      case 'special':
        return PokemonMoveCategory.special;
      case 'status':
        return PokemonMoveCategory.status;
      default:
        throw EditorPersistenceException(
          'Showdown move entry "$rawId" exposes an unsupported category "$rawValue"',
        );
    }
  }

  PokemonMoveTarget? _parseTarget(String rawValue) {
    switch (rawValue.trim()) {
      case 'adjacentAlly':
        return PokemonMoveTarget.adjacentAlly;
      case 'adjacentAllyOrSelf':
        return PokemonMoveTarget.adjacentAllyOrSelf;
      case 'adjacentFoe':
        return PokemonMoveTarget.adjacentFoe;
      case 'all':
        return PokemonMoveTarget.all;
      case 'allAdjacent':
        return PokemonMoveTarget.allAdjacent;
      case 'allAdjacentFoes':
        return PokemonMoveTarget.allAdjacentFoes;
      case 'allies':
        return PokemonMoveTarget.allies;
      case 'allySide':
        return PokemonMoveTarget.allySide;
      case 'allyTeam':
        return PokemonMoveTarget.allyTeam;
      case 'any':
        return PokemonMoveTarget.any;
      case 'foeSide':
        return PokemonMoveTarget.foeSide;
      case 'normal':
        return PokemonMoveTarget.normal;
      case 'randomNormal':
        return PokemonMoveTarget.randomNormal;
      case 'scripted':
        return PokemonMoveTarget.scripted;
      case 'self':
        return PokemonMoveTarget.self;
    }
    return null;
  }

  PokemonMoveFlag? _parseFlag(String rawValue) {
    switch (rawValue.trim()) {
      case 'allyanim':
        return PokemonMoveFlag.allyAnim;
      case 'bypasssub':
        return PokemonMoveFlag.bypassSubstitute;
      case 'bite':
        return PokemonMoveFlag.bite;
      case 'bullet':
        return PokemonMoveFlag.bullet;
      case 'cantusetwice':
        return PokemonMoveFlag.cantUseTwice;
      case 'charge':
        return PokemonMoveFlag.charge;
      case 'contact':
        return PokemonMoveFlag.contact;
      case 'dance':
        return PokemonMoveFlag.dance;
      case 'defrost':
        return PokemonMoveFlag.defrost;
      case 'distance':
        return PokemonMoveFlag.distance;
      case 'failcopycat':
        return PokemonMoveFlag.failCopycat;
      case 'failencore':
        return PokemonMoveFlag.failEncore;
      case 'failinstruct':
        return PokemonMoveFlag.failInstruct;
      case 'failmefirst':
        return PokemonMoveFlag.failMeFirst;
      case 'failmimic':
        return PokemonMoveFlag.failMimic;
      case 'futuremove':
        return PokemonMoveFlag.futureMove;
      case 'gravity':
        return PokemonMoveFlag.gravity;
      case 'heal':
        return PokemonMoveFlag.heal;
      case 'metronome':
        return PokemonMoveFlag.metronome;
      case 'minimize':
        return PokemonMoveFlag.minimize;
      case 'mirror':
        return PokemonMoveFlag.mirror;
      case 'mustpressure':
        return PokemonMoveFlag.mustPressure;
      case 'noassist':
        return PokemonMoveFlag.noAssist;
      case 'nonsky':
        return PokemonMoveFlag.nonSky;
      case 'noparentalbond':
        return PokemonMoveFlag.noParentalBond;
      case 'nosketch':
        return PokemonMoveFlag.noSketch;
      case 'nosleeptalk':
        return PokemonMoveFlag.noSleepTalk;
      case 'pledgecombo':
        return PokemonMoveFlag.pledgeCombo;
      case 'powder':
        return PokemonMoveFlag.powder;
      case 'protect':
        return PokemonMoveFlag.protect;
      case 'pulse':
        return PokemonMoveFlag.pulse;
      case 'punch':
        return PokemonMoveFlag.punch;
      case 'recharge':
        return PokemonMoveFlag.recharge;
      case 'reflectable':
        return PokemonMoveFlag.reflectable;
      case 'slicing':
        return PokemonMoveFlag.slicing;
      case 'snatch':
        return PokemonMoveFlag.snatch;
      case 'sound':
        return PokemonMoveFlag.sound;
      case 'wind':
        return PokemonMoveFlag.wind;
    }
    return null;
  }

  PokemonMoveStatId? _parseStatId(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'atk':
        return PokemonMoveStatId.attack;
      case 'def':
        return PokemonMoveStatId.defense;
      case 'spa':
        return PokemonMoveStatId.specialAttack;
      case 'spd':
        return PokemonMoveStatId.specialDefense;
      case 'spe':
        return PokemonMoveStatId.speed;
      case 'accuracy':
        return PokemonMoveStatId.accuracy;
      case 'evasion':
        return PokemonMoveStatId.evasion;
    }
    return null;
  }

  PokemonMoveEffectTargetScope _primaryTargetScopeForMoveTarget(
    String rawTarget,
  ) {
    if (rawTarget == 'self') {
      return PokemonMoveEffectTargetScope.self;
    }
    return PokemonMoveEffectTargetScope.target;
  }

  PokemonMoveEffectTargetScope _sideConditionScopeForMoveTarget(
    String rawTarget,
  ) {
    switch (rawTarget) {
      case 'allySide':
      case 'allyTeam':
        return PokemonMoveEffectTargetScope.allySide;
      default:
        return PokemonMoveEffectTargetScope.foeSide;
    }
  }

  String _readDisplayName(String rawId, Map<String, dynamic> entry) {
    final explicitName = _readTrimmedString(entry['name']);
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }
    return _humanizeIdentifier(rawId);
  }

  String _readRequiredLowerCaseString({
    required String rawId,
    required String fieldName,
    required Object? rawValue,
  }) {
    final value = _readLowerCaseString(rawValue);
    if (value == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a supported $fieldName',
      );
    }
    return value;
  }

  String? _readLowerCaseString(Object? rawValue) {
    final value = _readTrimmedString(rawValue);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readTrimmedString(Object? rawValue) {
    final value = rawValue as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int? _readOptionalInt(Object? rawValue) {
    return (rawValue as num?)?.toInt();
  }

  int _readBasePower(Object? rawValue) {
    return (rawValue as num?)?.toInt() ?? 0;
  }

  bool _readBool(Object? rawValue) => rawValue == true;

  bool _isTruthyFlagValue(Object? value) {
    if (value == true) {
      return true;
    }
    return value is num && value != 0;
  }

  bool _hasChargeThenStrikeSignal(Map<String, dynamic> entry) {
    final flags = entry['flags'];
    final hasChargeFlag = flags is Map && _isTruthyFlagValue(flags['charge']);
    if (!hasChargeFlag) {
      return false;
    }

    if (_hasMeaningfulValue(entry['condition'])) {
      return true;
    }

    for (final hook in _collectShowdownHooks(entry)) {
      if (hook == 'onTryMove' ||
          hook == 'onTry' ||
          hook == 'beforeMoveCallback' ||
          hook == 'onPrepareHit') {
        return true;
      }
    }

    return false;
  }

  bool _hasMeaningfulValue(Object? value) {
    if (value == null || value == false) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  String _normalizeSnakeCaseId(String rawValue) {
    final lowerCase = rawValue.trim().toLowerCase();
    if (lowerCase.isEmpty) {
      return '';
    }

    final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
    final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeIdentifier(String rawId) {
    final prepared = rawId
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (prepared.isEmpty) {
      return rawId;
    }

    return prepared
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

enum _FractionEffectKind {
  heal('heal'),
  drain('drain'),
  recoil('recoil');

  const _FractionEffectKind(this.reasonLabel);

  final String reasonLabel;
}

const Set<String> _handledTopLevelFields = <String>{
  'name',
  'type',
  'category',
  'target',
  'gen',
  'pp',
  'priority',
  'basePower',
  'accuracy',
  'shortDesc',
  'desc',
  'noPPBoosts',
  'critRatio',
  'flags',
  'status',
  'volatileStatus',
  'boosts',
  'selfBoost',
  'self',
  'secondary',
  'secondaries',
  'drain',
  'recoil',
  'heal',
  'multihit',
  'damage',
  'weather',
  'terrain',
  'pseudoWeather',
  'selfSwitch',
  'forceSwitch',
  'breaksProtect',
  'sideCondition',
  'slotCondition',
};

const Set<String> _ignoredTopLevelMetadataFields = <String>{
  'num',
  'contestType',
};
```

### `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/showdown_move_catalog_converter.dart';

/// Projection légère d'une entrée du catalogue local des attaques.
///
/// Cette vue existe pour deux besoins strictement 11B :
/// - afficher une liste locale lisible dans l'éditeur ;
/// - éviter que l'UI reparte du JSON brut pour interpréter les champs.
///
/// Non-objectifs assumés :
/// - ce n'est pas un nouveau modèle métier transverse ;
/// - ce n'est pas une "Move Library" complète ;
/// - on ne cherche pas à capturer toutes les subtilités battle de Showdown.
class PokemonMoveCatalogEntryView {
  const PokemonMoveCatalogEntryView({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.power,
    this.accuracy,
    this.accuracyText,
    this.pp,
    this.priority,
    this.target,
    this.shortDesc,
    this.generation,
  });

  final String id;
  final String name;
  final String? type;
  final String? category;
  final int? power;
  final num? accuracy;
  final String? accuracyText;
  final int? pp;
  final int? priority;
  final String? target;
  final String? shortDesc;
  final int? generation;

  String get accuracyLabel {
    if (accuracy != null) {
      return accuracy!.toString();
    }
    if (accuracyText != null && accuracyText!.trim().isNotEmpty) {
      return accuracyText!;
    }
    return '-';
  }
}

/// État lisible du catalogue moves local pour l'éditeur.
///
/// L'UI a besoin d'une réponse honnête sur deux choses distinctes :
/// - le catalogue existe-t-il et a-t-il pu être lu ;
/// - quelles entrées locales sont effectivement disponibles.
///
/// On sépare donc clairement le message de statut des entrées elles-mêmes.
class PokemonMovesCatalogView {
  const PokemonMovesCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
}

/// Résultat d'une preview ou d'une synchronisation réelle du catalogue moves.
///
/// Le use case reste volontairement déterministe :
/// - aucune merge policy "UI-configurable" supplémentaire n'est introduite ;
/// - la stratégie retenue est un merge par id, avec préservation des entrées
///   locales absentes de la source distante et des champs locaux non gérés ;
/// - le résultat expose donc uniquement les compteurs et ids utiles à l'UI.
class PokemonMovesCatalogSyncResult {
  const PokemonMovesCatalogSyncResult({
    required this.dryRun,
    required this.externalEntryCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.resultingEntryCount,
    this.warnings = const <String>[],
  });

  final bool dryRun;
  final int externalEntryCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final int resultingEntryCount;
  final List<String> warnings;

  int get createdCount => createdIds.length;
  int get updatedCount => updatedIds.length;
  int get unchangedCount => unchangedIds.length;
  int get preservedLocalOnlyCount => preservedLocalOnlyIds.length;
}

/// Charge le catalogue local des attaques pour la surface éditeur minimale.
///
/// Ce use case reste volontairement simple :
/// - il lit exclusivement `catalogs/moves.json` via le repository existant ;
/// - il projette des entrées lisibles ;
/// - il ne tente aucune réparation automatique ni enrichissement externe.
class LoadPokemonMovesCatalogUseCase {
  const LoadPokemonMovesCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonMovesCatalogView> execute(ProjectWorkspace workspace) async {
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return PokemonMovesCatalogView(
        entries: _projectEntries(catalog),
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
      );
    }
  }

  List<PokemonMoveCatalogEntryView> _projectEntries(
      PokemonCatalogFile catalog) {
    final entries = catalog.entries
        .map(_projectEntry)
        .whereType<PokemonMoveCatalogEntryView>()
        .toList(growable: false)
      ..sort((left, right) {
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  PokemonMoveCatalogEntryView? _projectEntry(Map<String, dynamic> entry) {
    // M3 introduit des entrées canoniques `PokemonMove.toJson()`, mais le
    // catalogue projet peut encore contenir des entrées legacy locales non
    // resynchronisées. Cette projection légère doit donc rester tolérante :
    // - on privilégie la lecture canonique quand elle est possible ;
    // - on garde un fallback legacy uniquement pour les vraies entrées legacy ;
    // - on n'introduit aucun modèle parallèle.
    if (_isCanonicalMoveEntry(entry)) {
      try {
        final move = PokemonMove.fromJson(entry);
        return PokemonMoveCatalogEntryView(
          id: move.id,
          name: move.name,
          type: move.type,
          category: move.category.name,
          power: move.usesStandardDamageFlow ? move.basePower : null,
          accuracy: move.accuracy.map(
            percent: (value) => value.value,
            alwaysHits: (_) => null,
          ),
          accuracyText: move.accuracy.maybeMap(
            alwaysHits: (_) => 'always',
            orElse: () => null,
          ),
          pp: move.pp,
          priority: move.priority,
          target: _encodeTarget(move.target),
          shortDesc:
              move.shortDescription.isEmpty ? null : move.shortDescription,
          generation: move.generation,
        );
      } on Object catch (error) {
        throw EditorPersistenceException(
          'Moves catalog contains an invalid canonical PokemonMove entry: $error',
        );
      }
    }

    final id = (entry['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final explicitName = (entry['name'] as String?)?.trim();
    final localizedNames = (entry['names'] as Map?)?.cast<String, dynamic>();
    final fallbackName = (localizedNames?['en'] as String?)?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name?.isNotEmpty == true ? name! : id,
      type: (entry['type'] as String?)?.trim(),
      category: (entry['category'] as String?)?.trim(),
      power: (entry['power'] as num?)?.toInt(),
      accuracy: entry['accuracy'] as num?,
      accuracyText: (entry['accuracyText'] as String?)?.trim(),
      pp: (entry['pp'] as num?)?.toInt(),
      priority: (entry['priority'] as num?)?.toInt(),
      target: (entry['target'] as String?)?.trim(),
      shortDesc: (entry['shortDesc'] as String?)?.trim(),
      generation: (entry['generation'] as num?)?.toInt(),
    );
  }
}

/// Synchronise le catalogue local `moves.json` depuis la source externe retenue.
///
/// Choix produit et technique de la 11B :
/// - on réutilise le port externe 11A existant, étendu minimalement ;
/// - la source bulk retenue est Showdown `moves.json` ;
/// - l'écriture locale continue de passer par le repository Pokémon existant ;
/// - `project.json` n'est jamais touché ;
/// - aucun pipeline parallèle n'est créé.
class SyncExternalPokemonMovesCatalogUseCase {
  const SyncExternalPokemonMovesCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
    this.converter = const ShowdownMoveCatalogConverter(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownMoveCatalogConverter converter;

  Future<PokemonMovesCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    bool dryRun = false,
  }) async {
    final externalCatalog = converter.convert(
      await externalSourceRepository.fetchShowdownMovesSnapshot(),
    );
    final localCatalog = await _readLocalCatalogIfAvailable(workspace);
    final merge = _mergeCatalogs(
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
    );

    if (!dryRun) {
      await writeRepository.saveCatalogByKey(workspace, 'moves', merge.catalog);
    }

    return PokemonMovesCatalogSyncResult(
      dryRun: dryRun,
      externalEntryCount: externalCatalog.entries.length,
      createdIds: merge.createdIds,
      updatedIds: merge.updatedIds,
      unchangedIds: merge.unchangedIds,
      preservedLocalOnlyIds: merge.preservedLocalOnlyIds,
      resultingEntryCount: merge.catalog.entries.length,
      warnings: merge.warnings,
    );
  }

  Future<PokemonCatalogFile?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace,
  ) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'moves');
    } on EditorNotFoundException {
      // Le storage 11A/11B initialise normalement le fichier, mais on garde ce
      // fallback local pour éviter qu'une absence de catalogue ne bloque
      // complètement un premier sync sur un workspace partiellement initialisé.
      return null;
    }
  }

  _MovesCatalogMerge _mergeCatalogs({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localById = <String, Map<String, dynamic>>{
      for (final entry
          in localCatalog?.entries ?? const <Map<String, dynamic>>[])
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');
    final externalById = <String, Map<String, dynamic>>{
      for (final entry in externalCatalog.entries)
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    for (final externalEntry in externalById.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))) {
      final id = externalEntry.key;
      final localEntry = localById.remove(id);
      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(_deepCopy(externalEntry.value));
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: externalEntry.value,
      );
      if (_jsonDeepEquals(localEntry, mergedEntry)) {
        unchangedIds.add(id);
      } else {
        updatedIds.add(id);
      }
      mergedEntries.add(mergedEntry);
    }

    final preservedLocalOnlyIds = localById.keys.toList(growable: false)
      ..sort();
    for (final id in preservedLocalOnlyIds) {
      mergedEntries.add(_deepCopy(localById[id]!));
    }

    mergedEntries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    final catalog = PokemonCatalogFile(
      schemaVersion: externalCatalog.schemaVersion,
      kind: externalCatalog.kind,
      catalog: externalCatalog.catalog,
      meta: _buildMergedMeta(
        localMeta: localCatalog?.meta,
        externalMeta: externalCatalog.meta,
      ),
      entries: mergedEntries,
    );

    return _MovesCatalogMerge(
      catalog: catalog,
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      warnings: preservedLocalOnlyIds.isEmpty
          ? const <String>[]
          : <String>[
              'Local move entries absent from the external snapshot were preserved unchanged.',
            ],
    );
  }

  PokemonDataMeta _buildMergedMeta({
    required PokemonDataMeta? localMeta,
    required PokemonDataMeta externalMeta,
  }) {
    final notes = <String>[
      ...externalMeta.notes,
      if (localMeta != null)
        ...localMeta.notes.where(
          (note) => !externalMeta.notes.contains(note),
        ),
    ];

    return PokemonDataMeta(
      description: externalMeta.description,
      sourcePriority: externalMeta.sourcePriority,
      notes: notes,
    );
  }

  Map<String, dynamic> _mergeEntry({
    required Map<String, dynamic> localEntry,
    required Map<String, dynamic> externalEntry,
  }) {
    final merged = <String, dynamic>{};

    for (final externalField in externalEntry.entries) {
      final key = externalField.key;
      final externalValue = externalField.value;
      final localValue = localEntry[key];

      if (key == 'names' &&
          localValue is Map &&
          externalValue is Map<String, dynamic>) {
        merged[key] = _mergeNames(localValue, externalValue);
        continue;
      }

      // Règle de merge locale et volontairement conservative :
      // - l'externe garde la priorité sur les champs qu'on sait produire ;
      // - si la valeur externe vaut `null`, on conserve une valeur locale
      //   existante plutôt que d'effacer une information déjà utile ;
      // - les champs purement locaux non gérés par 11B sont préservés plus bas.
      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      if (_isCanonicalMoveEntry(externalEntry) &&
          _obsoleteLegacyMoveFields.contains(localField.key)) {
        // M3 ne doit pas laisser les anciens alias légers (`power`,
        // `accuracyText`, `shortDesc`) se réinjecter sur une entrée maintenant
        // canonique. On continue toutefois de préserver les vrais champs
        // locaux additionnels (`names.fr`, `editorNote`, etc.).
        continue;
      }
      merged.putIfAbsent(
          localField.key, () => _deepCopyValue(localField.value));
    }

    return merged;
  }

  Map<String, dynamic> _mergeNames(
    Map localValue,
    Map<String, dynamic> externalValue,
  ) {
    final merged = <String, dynamic>{
      for (final entry in localValue.entries)
        if (entry.key is String)
          entry.key as String: _deepCopyValue(entry.value),
    };
    for (final entry in externalValue.entries) {
      merged[entry.key] = _deepCopyValue(entry.value);
    }
    return merged;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  }

  Object? _deepCopyValue(Object? value) {
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
  }

  bool _jsonDeepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }
      for (final key in left.keys) {
        if (!right.containsKey(key)) {
          return false;
        }
        if (!_jsonDeepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_jsonDeepEquals(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}

String _encodeTarget(PokemonMoveTarget target) {
  switch (target) {
    case PokemonMoveTarget.adjacentAlly:
      return 'adjacentAlly';
    case PokemonMoveTarget.adjacentAllyOrSelf:
      return 'adjacentAllyOrSelf';
    case PokemonMoveTarget.adjacentFoe:
      return 'adjacentFoe';
    case PokemonMoveTarget.all:
      return 'all';
    case PokemonMoveTarget.allAdjacent:
      return 'allAdjacent';
    case PokemonMoveTarget.allAdjacentFoes:
      return 'allAdjacentFoes';
    case PokemonMoveTarget.allies:
      return 'allies';
    case PokemonMoveTarget.allySide:
      return 'allySide';
    case PokemonMoveTarget.allyTeam:
      return 'allyTeam';
    case PokemonMoveTarget.any:
      return 'any';
    case PokemonMoveTarget.foeSide:
      return 'foeSide';
    case PokemonMoveTarget.normal:
      return 'normal';
    case PokemonMoveTarget.randomNormal:
      return 'randomNormal';
    case PokemonMoveTarget.scripted:
      return 'scripted';
    case PokemonMoveTarget.self:
      return 'self';
  }
}

bool _isCanonicalMoveEntry(Map<String, dynamic> entry) {
  return entry['basePower'] is num &&
      entry['accuracy'] is Map &&
      entry['effects'] is List &&
      entry['sourceRefs'] is Map;
}

const Set<String> _obsoleteLegacyMoveFields = <String>{
  'power',
  'accuracyText',
  'shortDesc',
};

class _MovesCatalogMerge {
  const _MovesCatalogMerge({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> warnings;
}
```

### `packages/map_editor/test/showdown_move_catalog_converter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/showdown_move_catalog_converter.dart';

void main() {
  const converter = ShowdownMoveCatalogConverter();

  test('converts standard offensive, drain, multi-hit and direct status moves',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'absorb': <String, dynamic>{
        'name': 'Absorb',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 20,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'drain': <int>[1, 2],
        'shortDesc': 'Heals the user by half the damage dealt.',
        'desc': 'A nutrient-draining attack.',
        'gen': 1,
      },
      'doubleslap': <String, dynamic>{
        'name': 'Double Slap',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 15,
        'accuracy': 85,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'multihit': <int>[2, 5],
        'shortDesc': 'Hits 2-5 times in one turn.',
        'desc': 'Repeatedly slaps 2 to 5 times.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
      'thunderwave': <String, dynamic>{
        'name': 'Thunder Wave',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'status': 'par',
        'shortDesc': 'Paralyzes the target.',
        'desc': 'A weak electric charge is launched at the target.',
        'gen': 1,
      },
      'swordsdance': <String, dynamic>{
        'name': 'Swords Dance',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'self',
        'boosts': <String, int>{'atk': 2},
        'shortDesc': 'Raises the user\'s Attack by 2.',
        'desc': 'A frenetic dance to uplift the fighting spirit.',
        'gen': 1,
      },
      'leer': <String, dynamic>{
        'name': 'Leer',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'boosts': <String, int>{'def': -1},
        'shortDesc': 'Lowers the target\'s Defense by 1.',
        'desc': 'The user gives opposing Pokémon an intimidating leer.',
        'gen': 1,
      },
    });

    final thunderbolt = _move(catalog, 'thunderbolt');
    expect(thunderbolt.source, 'showdown');
    expect(thunderbolt.basePower, 90);
    expect(thunderbolt.usesStandardDamageFlow, isTrue);
    expect(
      thunderbolt.accuracy,
      const PokemonMoveAccuracy.percent(value: 100),
    );
    expect(
      thunderbolt.effects,
      contains(
        const PokemonMoveEffect.applyStatus(
          chance: 10,
          statusId: 'par',
        ),
      ),
    );
    expect(
      thunderbolt.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('deal_damage')),
    );
    expect(
      thunderbolt.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredSupported,
    );

    final absorb = _move(catalog, 'absorb');
    expect(
      absorb.effects,
      contains(
        const PokemonMoveEffect.drain(numerator: 1, denominator: 2),
      ),
    );

    final doubleSlap = _move(catalog, 'double_slap');
    expect(
      doubleSlap.effects,
      contains(
        const PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
      ),
    );

    final swift = _move(catalog, 'swift');
    expect(swift.accuracy, const PokemonMoveAccuracy.alwaysHits());

    final thunderWave = _move(catalog, 'thunder_wave');
    expect(
      thunderWave.effects,
      contains(
        const PokemonMoveEffect.applyStatus(statusId: 'par'),
      ),
    );

    final swordsDance = _move(catalog, 'swords_dance');
    expect(
      swordsDance.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: 2,
            ),
          ],
        ),
      ),
    );

    final leer = _move(catalog, 'leer');
    expect(
      leer.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ),
    );
  });

  test('converts weather, terrain, pseudo-weather, side and slot conditions',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'raindance': <String, dynamic>{
        'name': 'Rain Dance',
        'type': 'Water',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': 0,
        'target': 'self',
        'weather': 'raindance',
        'shortDesc': 'For 5 turns, heavy rain powers Water moves.',
        'desc': 'The user summons a heavy rain.',
        'gen': 2,
      },
      'electricterrain': <String, dynamic>{
        'name': 'Electric Terrain',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'terrain': 'electricterrain',
        'shortDesc': 'For 5 turns, the terrain becomes electric.',
        'desc': 'The user electrifies the ground.',
        'gen': 6,
      },
      'trickroom': <String, dynamic>{
        'name': 'Trick Room',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': -7,
        'target': 'all',
        'pseudoWeather': 'trickroom',
        'shortDesc': 'For 5 turns, slower Pokémon move first.',
        'desc':
            'The user creates a bizarre area in which slower Pokémon get to move first.',
        'gen': 4,
      },
      'stealthrock': <String, dynamic>{
        'name': 'Stealth Rock',
        'type': 'Rock',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'foeSide',
        'sideCondition': 'stealthrock',
        'shortDesc': 'Sets a hazard on the foes\' side of the field.',
        'desc':
            'The user lays a trap of levitating stones around the opposing team.',
        'gen': 4,
      },
      'healingwish': <String, dynamic>{
        'name': 'Healing Wish',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'slotCondition': 'healingwish',
        'shortDesc': 'The user faints and heals its replacement.',
        'desc': 'The user faints and the Pokémon switched in is fully healed.',
        'gen': 4,
      },
    });

    expect(
      _move(catalog, 'rain_dance').effects,
      contains(
        const PokemonMoveEffect.setWeather(weatherId: 'raindance'),
      ),
    );
    expect(
      _move(catalog, 'electric_terrain').effects,
      contains(
        const PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
      ),
    );
    expect(
      _move(catalog, 'trick_room').effects,
      contains(
        const PokemonMoveEffect.setPseudoWeather(
          pseudoWeatherId: 'trickroom',
        ),
      ),
    );
    expect(
      _move(catalog, 'stealth_rock').effects,
      contains(
        const PokemonMoveEffect.setSideCondition(
          conditionId: 'stealthrock',
        ),
      ),
    );
    expect(
      _move(catalog, 'healing_wish').effects,
      contains(
        const PokemonMoveEffect.setSlotCondition(
          conditionId: 'healingwish',
        ),
      ),
    );
  });

  test('tracks callbacks and downgrades support level honestly', () {
    final catalog = converter.convert(<String, dynamic>{
      'thunder': <String, dynamic>{
        'name': 'Thunder',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 110,
        'accuracy': 70,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 30,
          'status': 'par',
        },
        'onModifyMove': () {},
        'shortDesc': 'May paralyze the target. Accuracy changes in weather.',
        'desc': 'A wicked thunderbolt is dropped on the target.',
        'gen': 1,
      },
      'weatherball': <String, dynamic>{
        'name': 'Weather Ball',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 50,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'basePowerCallback': () => 100,
        'shortDesc': 'Power and type change based on the weather.',
        'desc':
            'An attack move that varies in power and type depending on the weather.',
        'gen': 3,
      },
      'mysterymove': <String, dynamic>{
        'name': 'Mystery Move',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 40,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'mystery': 1},
        'shortDesc': 'Unsupported test move.',
        'desc': 'A move used to prove unknown flags are not ignored.',
        'gen': 9,
      },
    });

    final thunder = _move(catalog, 'thunder');
    expect(
      thunder.sourceRefs.showdownHooksPresent,
      contains('onModifyMove'),
    );
    expect(
      thunder.unsupportedReasons,
      contains('showdown_callback:onModifyMove'),
    );
    expect(
      thunder.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );

    final weatherBall = _move(catalog, 'weather_ball');
    expect(
      weatherBall.sourceRefs.showdownHooksPresent,
      contains('basePowerCallback'),
    );
    expect(
      weatherBall.unsupportedReasons,
      contains('showdown_callback:basePowerCallback'),
    );
    expect(
      weatherBall.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );

    final mysteryMove = _move(catalog, 'mystery_move');
    expect(
      mysteryMove.unsupportedReasons,
      contains('unknown_flag:mystery'),
    );
    expect(
      mysteryMove.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );
  });

  test(
      'converts fixed damage and keeps charge-based moves honest without fabricating effects',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'sonicboom': <String, dynamic>{
        'name': 'Sonic Boom',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 0,
        'damage': 20,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Always does 20 HP of damage.',
        'desc': 'The target is hit with a destructive shock wave.',
        'gen': 1,
      },
      'solarbeam': <String, dynamic>{
        'name': 'Solar Beam',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 120,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'charge': 1, 'protect': 1},
        'condition': <String, dynamic>{'duration': 2},
        'onTryMove': () {},
        'shortDesc': 'Charges on the first turn, attacks on the second.',
        'desc': 'In this two-turn attack, the user gathers light, then blasts.',
        'gen': 1,
      },
    });

    final sonicBoom = _move(catalog, 'sonic_boom');
    expect(
      sonicBoom.effects,
      contains(
        const PokemonMoveEffect.fixedDamage(value: 20),
      ),
    );

    final solarBeam = _move(catalog, 'solar_beam');
    expect(
      solarBeam.unsupportedReasons,
      contains('unsupported_mechanic:charge_then_strike'),
    );
    expect(
      solarBeam.sourceRefs.showdownHooksPresent,
      contains('onTryMove'),
    );
    expect(
      solarBeam.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );
    expect(
      solarBeam.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('charge_then_strike')),
    );
  });

  test('converts self switch, force switch, recharge and canonical json safely',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'uturn': <String, dynamic>{
        'name': 'U-turn',
        'type': 'Bug',
        'category': 'Physical',
        'basePower': 70,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'selfSwitch': true,
        'shortDesc': 'User switches out after damaging the target.',
        'desc': 'After making its attack, the user rushes back.',
        'gen': 4,
      },
      'roar': <String, dynamic>{
        'name': 'Roar',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': -6,
        'target': 'normal',
        'forceSwitch': true,
        'shortDesc': 'Forces the target to switch to a random ally.',
        'desc': 'The target is scared off and replaced.',
        'gen': 1,
      },
      'hyperbeam': <String, dynamic>{
        'name': 'Hyper Beam',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 150,
        'accuracy': 90,
        'pp': 5,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'recharge': 1, 'protect': 1},
        'self': <String, dynamic>{'volatileStatus': 'mustrecharge'},
        'shortDesc': 'User must recharge next turn.',
        'desc': 'The target is attacked with a powerful beam.',
        'gen': 1,
      },
    });

    final uTurn = _move(catalog, 'u_turn');
    expect(
      uTurn.effects,
      contains(const PokemonMoveEffect.selfSwitch()),
    );

    final roar = _move(catalog, 'roar');
    expect(
      roar.effects,
      contains(const PokemonMoveEffect.forceSwitch()),
    );

    final hyperBeam = _move(catalog, 'hyper_beam');
    expect(
      hyperBeam.effects,
      contains(const PokemonMoveEffect.requireRecharge()),
    );

    for (final entry in catalog.entries) {
      expect(() => PokemonMove.fromJson(entry), returnsNormally);
    }
  });
}

PokemonMove _move(PokemonCatalogFile catalog, String id) {
  final entry = catalog.entries.firstWhere((entry) => entry['id'] == id);
  return PokemonMove.fromJson(entry);
}
```

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonMovesCatalogUseCase syncUseCase;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('moves_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonMovesCatalogUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('dry-run previews the sync without writing the local catalog', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace, dryRun: true);

    expect(result.dryRun, isTrue);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'sync merges Showdown moves into the local catalog and preserves local-only metadata',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );
    final loadedView = await loadUseCase.execute(workspace);

    expect(result.dryRun, isFalse);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      containsAll(<String>['custom_move', 'swift', 'thunderbolt', 'vine_whip']),
    );

    final vineWhip = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'vine_whip',
    );
    final canonicalVineWhip = PokemonMove.fromJson(vineWhip);
    expect(canonicalVineWhip.name, 'Vine Whip');
    expect(canonicalVineWhip.type, 'grass');
    expect(canonicalVineWhip.basePower, 45);
    expect(canonicalVineWhip.generation, 1);
    expect(canonicalVineWhip.source, 'showdown');
    expect(vineWhip.containsKey('power'), isFalse);
    expect(vineWhip.containsKey('accuracyText'), isFalse);
    expect(vineWhip.containsKey('shortDesc'), isFalse);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );
    expect(vineWhip['editorNote'], 'Keep this local-only field after sync.');

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    final canonicalSwift = PokemonMove.fromJson(swift);
    expect(
      canonicalSwift.accuracy,
      const PokemonMoveAccuracy.alwaysHits(),
    );

    expect(loadedView.isAvailable, isTrue);
    final thunderboltView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'thunderbolt',
    );
    expect(thunderboltView.power, 90);
    expect(thunderboltView.accuracyLabel, '100');
    expect(thunderboltView.shortDesc, 'May paralyze the target.');

    final swiftView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'swift',
    );
    expect(swiftView.accuracyLabel, 'always');
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'load use case does not silently downgrade an invalid canonical move to legacy projection',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      const PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: 'moves',
        meta: PokemonDataMeta(
          description: 'Broken canonical move catalog.',
        ),
        entries: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'names': <String, String>{'en': 'Broken Move'},
            'source': 'showdown',
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': <String, dynamic>{'kind': 'percent', 'value': 0},
            'pp': 10,
            'priority': 0,
            'critRatio': 1,
            'flags': <String>[],
            'effects': <Map<String, dynamic>>[],
            'shortDescription': 'Broken canonical payload.',
            'description': 'Broken canonical payload.',
            'engineSupportLevel': 'structured_supported',
            'unsupportedReasons': <String>[],
            'sourceRefs': <String, dynamic>{
              'showdownMoveId': 'brokenmove',
              'showdownHooksPresent': <String>[],
            },
          },
        ],
      ),
    );

    final loadedView = await loadUseCase.execute(workspace);

    expect(loadedView.isAvailable, isFalse);
    expect(loadedView.description, 'Catalogue local des attaques illisible.');
    expect(
      loadedView.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() async {
    return <String, dynamic>{
      'vinewhip': <String, dynamic>{
        'name': 'Vine Whip',
        'type': 'Grass',
        'category': 'Physical',
        'basePower': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'desc': 'The target is struck with slender, whiplike vines.',
        'gen': 1,
      },
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

const PokemonCatalogFile _localMovesCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Local moves catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'custom_move',
      'name': 'Custom Move',
      'names': <String, String>{'en': 'Custom Move'},
      'type': 'normal',
      'category': 'status',
      'power': null,
      'accuracy': 100,
      'pp': 5,
      'priority': 0,
      'target': 'self',
      'shortDesc': 'A local-only move that must be preserved.',
      'generation': 9,
    },
    <String, dynamic>{
      'id': 'vine_whip',
      'name': 'Liane',
      'names': <String, String>{
        'en': 'Vine Whip',
        'fr': 'Fouet Lianes',
      },
      'type': 'grass',
      'category': 'physical',
      'power': 40,
      'accuracy': 95,
      'pp': 20,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'Old local description.',
      'generation': 3,
      'editorNote': 'Keep this local-only field after sync.',
    },
  ],
);
```
