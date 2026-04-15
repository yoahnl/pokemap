# M5 — Loader runtime spécialisé du catalogue moves + pré-gate M4

## 1. Résumé exécutif honnête

M5 est livré avec un seam runtime dédié pour le catalogue moves canonique, sans ouvrir `map_battle`, sans fallback legacy côté runtime, et sans réouvrir le bootstrap seed M4. Le runtime ne relit plus `moves.json` comme un mini tuple `id/name/power`; il délègue maintenant cette lecture à un loader spécialisé qui parse chaque entrée via `PokemonMove.fromJson(...)` et construit un index strict par id.

Le pré-gate M4 a été exécuté au début comme demandé. La conclusion retenue est **`préexistant prouvé` vis-à-vis de M4** : le test rouge `packages/map_editor/test/file_pokemon_read_repository_test.dart` échoue bien, mais sur un catalogue custom legacy écrit à la main dans le test et lu via la surface éditeur M3/M3-bis. Il ne passe pas par le seam seed/bootstrap introduit en M4.

J’ai aussi challengé le prompt sur deux points :
- je n’ai pas créé de clone runtime de `PokemonMove`, car ce serait une duplication inutile dans le repo réel ;
- je n’ai pas transformé M5 en M8 déguisé en refusant tous les moves `catalog_only` / `structured_partial` au handoff battle, car ce serait ouvrir prématurément la politique d’exécution des moves.

## 2. État initial audité réel

### 2.1. Pré-gate M4

Test exécuté immédiatement :

```text
cd packages/map_editor && /opt/homebrew/bin/flutter test test/file_pokemon_read_repository_test.dart
```

Résultat réel utile :

```text
00:02 +2 -1: FilePokemonReadRepository loads species detail and move catalog from project.json-configured paths without pokemon_data_manifest.json [E]
  Expected: true
    Actual: <false>
  test/file_pokemon_read_repository_test.dart 293:7
...
00:03 +6 -1: Some tests failed.
```

Audit du test rouge :
- le test écrit manuellement `custom/pokemon/catalogs/moves.json` ;
- ce fichier contient des entrées legacy locales avec `power`, `pp`, `type`, `category` ;
- il n’utilise ni `InitializePokemonProjectStorageUseCase`, ni `SeedPokemonDemoDataUseCase`, ni le seed embarqué M4 ;
- l’échec arrive lors du chargement via `LoadPokemonMovesCatalogUseCase`, donc sur la frontière canonique/legacy côté éditeur, pas sur le bootstrap M4.

Conclusion retenue : **préexistant prouvé vis-à-vis de M4**.

### 2.2. Runtime avant patch

Audit du runtime réel :
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` embarquait encore un mini reader local `readMovesCatalog()` ;
- ce reader fabriquait `_RuntimeMovesCatalog` et `_RuntimeMoveCatalogEntry` avec seulement `id`, `displayName`, `power` ;
- `_resolveBattleMoves()` projetait ensuite directement vers `BattleMoveData` ;
- aucune lecture stricte du canonique M2/M2-bis n’existait côté runtime ;
- les fixtures runtime écrivaient encore des catalogues moves legacy (`power` au lieu de `basePower`).

## 3. Pré-gate M4

### Statut retenu

**Préexistant prouvé**.

### Preuve et raisonnement

Pourquoi ce n’est pas une régression M4 :
- M4 a touché `initialize_pokemon_project_storage_use_case.dart`, `seed_pokemon_demo_data_use_case.dart`, leurs tests, et le seed embarqué ;
- le test rouge construit un projet custom sans passer par ce bootstrap ;
- le catalogue moves du test est legacy manuel, pas seedé par M4 ;
- l’échec se produit dans le loader éditeur local, sur la politique canonique vs legacy durcie en M3/M3-bis.

### Décision de scope

Je n’ai **pas** absorbé ce bug dans M5. Le corriger ici aurait rouvert la lecture locale éditeur alors que le lot demandé est un seam runtime spécialisé.

## 4. Problèmes confirmés / non confirmés

### Confirmés

- `runtime_battle_setup_mapper.dart` contenait encore une lecture ad hoc trop pauvre du catalogue moves.
- `map_runtime` ne possédait pas de seam dédié, strict et testé pour le catalogue moves canonique.
- Les tests runtime continuaient d’utiliser des fixtures moves legacy, incompatibles avec un runtime strict canonique.
- Le test rouge du pré-gate M4 est réel et reproductible.

### Non confirmés

- Rien ne prouve que M4 ait cassé ce test rouge.
- Rien ne justifie la création d’un DTO runtime clonant `PokemonMove` pour M5.

## 5. Cause racine réelle

La cause racine M5 est simple : le runtime avait été branché historiquement sur une lecture locale minimale `id/name/power`, suffisante pour les premiers lots battle, mais devenue incohérente depuis :
- M2/M2-bis ont introduit un vrai modèle canonique `PokemonMove` ;
- M3/M3-bis ont fait converger l’éditeur vers des entrées canoniques ;
- M4 a seedé des catalogues canoniques.

Le runtime restait donc le dernier maillon à lire `moves.json` comme un vieux catalogue léger.

## 6. Décisions retenues / rejetées

### Retenues

1. **Créer un seam dédié `RuntimeMoveCatalogLoader`**.
   - Pourquoi : extraire la lecture moves de `runtime_battle_setup_mapper.dart` sans inventer une architecture générale.

2. **Réutiliser directement `PokemonMove` côté runtime**.
   - Pourquoi : le modèle canonique existe déjà, est sérialisable, validé et partagé ; un clone runtime serait surtout une duplication.

3. **Sortir `RuntimeBattleSetupException` dans un petit fichier partagé**.
   - Pourquoi : éviter un cycle sale entre le loader et le mapper, tout en gardant une seule famille d’erreurs métier pour le handoff runtime -> battle.

4. **Rendre le loader runtime strict**.
   - Pas de fallback legacy.
   - Échec explicite sur entrée canonique invalide.
   - Échec explicite sur ids dupliqués.
   - Échec explicite sur métadonnées de catalogue manquantes ou incohérentes.

5. **Mettre les fixtures runtime en canonique réel**.
   - Pourquoi : prouver honnêtement le seam M5 sans tricher avec un vieux `power` legacy.

### Rejetées

1. **Créer un `RuntimeMoveDefinition` miroir de `PokemonMove`**.
   - Rejeté : duplication sans gain concret dans le repo réel.

2. **Faire parser `PokemonCatalogFile` dans `map_runtime`**.
   - Rejeté : `PokemonCatalogFile` vit dans `map_editor` ; le runtime ne doit pas dépendre de ce package.

3. **Corriger le test rouge du pré-gate dans M5**.
   - Rejeté : c’est un problème côté lecture locale éditeur, pas côté M4 seed/bootstrap ni côté runtime.

4. **Ajouter un gate d’exécution complet des moves `catalog_only` / `structured_partial`**.
   - Rejeté pour M5 : cela rouvrirait M8. J’ai conservé le chargement strict du canonique et explicité la limite du handoff MVP vers `BattleMoveData`.

## 7. Critique explicite du prompt reçu

### Ce qui était juste

- exiger un vrai audit avant de coder ;
- imposer le pré-gate M4 ;
- demander un seam runtime dédié ;
- interdire tout fallback legacy dans `map_runtime` ;
- demander une review séparée et une vraie autocritique.

### Ce qui était discutable

- l’idée qu’un type runtime dédié pouvait être “potentiellement acceptable” : dans le repo réel, cela poussait facilement vers une duplication inutile de `PokemonMove`.

### Ce qui aurait été dangereux si suivi aveuglément

- traiter automatiquement le test rouge `file_pokemon_read_repository_test.dart` comme une régression M4 sans auditer son chemin réel ;
- transformer M5 en M8 en décidant déjà quels moves partiellement supportés doivent être bloqués à l’exécution battle ;
- laisser un `catalog` absent passer silencieusement au loader runtime au nom d’une tolérance inutile.

### Ce que j’ai corrigé / recadré

- j’ai **reutilisé `PokemonMove` directement** au runtime ;
- j’ai **classé le pré-gate M4 comme préexistant prouvé vis-à-vis de M4** ;
- j’ai **durci le loader sur la métadonnée `catalog`** après la remarque valide du reviewer ;
- j’ai **documenté explicitement** que le handoff `BattleMoveData(power)` reste un contrat MVP et non un support complet des effets.

## 8. Périmètre inclus / exclu

### Inclus

- `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- report M5

### Exclus

- `packages/map_editor/...` hors pré-gate audit
- `packages/map_core/...`
- `packages/map_battle/...`
- seed/bootstrap M4
- validation globale projet
- UI
- pont runtime -> battle riche (M8)

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Créés

- `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `reports/phase-moves-m5-runtime-loader-report.md`

### Modifiés

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### Supprimés

- aucun

## 10. Justification fichier par fichier

- `runtime_battle_setup_exception.dart`
  - extraction minimale de l’exception partagée pour éviter un cycle loader <-> mapper ;
  - pas d’autre responsabilité.

- `runtime_move_catalog_loader.dart`
  - nouveau seam runtime strict ;
  - parse canonique via `PokemonMove.fromJson(...)` ;
  - index par id ;
  - aucun fallback legacy.

- `runtime_battle_setup_mapper.dart`
  - délégation au nouveau loader ;
  - suppression du mini parser `id/name/power` ;
  - projection battle minimale conservée, avec commentaire explicite de limite.

- `runtime_move_catalog_loader_test.dart`
  - preuves ciblées du seam M5 ;
  - cas valide, invalid canonical, duplicate ids, catalog metadata missing.

- `runtime_battle_setup_mapper_test.dart`
  - fixtures moves passées au canonique ;
  - preuve explicite que `basePower` alimente bien le handoff ;
  - preuve d’échec honnête quand un move référencé est absent.

- `wild_battle_end_to_end_flow_test.dart`
  - fixtures runtime réalignées sur le canonique, pour préserver une preuve plus verticale sans fallback legacy.

## 11. Commandes réellement exécutées

### Audit initial et pré-gate

```text
cd packages/map_editor && /opt/homebrew/bin/flutter test test/file_pokemon_read_repository_test.dart
rg -n "file_pokemon_read_repository_test|movesCatalog|LoadPokemonMovesCatalogUseCase|RuntimeMoves|RuntimeMove|moves.json|PokemonMove.fromJson" packages/map_editor packages/map_runtime -g '*.dart'
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,360p' packages/map_editor/test/file_pokemon_read_repository_test.dart
sed -n '1,320p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '320,520p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '1,240p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '240,420p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '360,520p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '240,760p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,260p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '260,760p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,280p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '1,320p' packages/map_core/lib/src/models/pokemon_move_accuracy.dart
sed -n '1,420p' packages/map_core/lib/src/models/pokemon_move_effect.dart
rg -n "power':|accuracyText|PokemonMove\(|toJson\(|buildEmbeddedPokemonMovesBootstrapSeed|catalog': 'moves'" packages/map_runtime/test packages/map_runtime/lib -g '*.dart'
sed -n '520,700p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1,260p' packages/map_runtime/lib/map_runtime.dart
ls packages/map_runtime/lib/src/application && rg -n "class Runtime.*Loader|load.*catalog|PokemonCatalogFile" packages/map_runtime/lib/src/application -g '*.dart'
sed -n '1,220p' packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
sed -n '1,260p' packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
sed -n '1,240p' packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
sed -n '1,220p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
```

### Validation

```text
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/playable_map_game.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/playable_map_game.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_move_catalog_loader.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/playable_map_game.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart test/runtime_move_catalog_loader_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/playable_map_game.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/playable_map_game.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format test/runtime_battle_setup_mapper_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_mapper.dart test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### État Git utile

```text
git status --short
git diff --stat -- packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/test/runtime_move_catalog_loader_test.dart packages/map_runtime/test/runtime_battle_setup_mapper_test.dart packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
git ls-files --others --exclude-standard
```

## 12. Résultats réels de format / analyze / tests

### Format

Résultat réel utile :

```text
Formatted test/runtime_move_catalog_loader_test.dart
Formatted test/runtime_battle_setup_mapper_test.dart
Formatted 7 files (2 changed) in 0.05 seconds.
```

Puis reruns ciblés :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
Formatted 3 files (0 changed) in 0.02 seconds.
Formatted 2 files (0 changed) in 0.04 seconds.
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Analyze

Premier analyze après implémentation :

```text
error • The property 'isNotEmpty' can't be unconditionally accessed because the receiver can be 'null' • lib/src/application/runtime_move_catalog_loader.dart:43:25 • unchecked_use_of_nullable_value
```

Correction appliquée : garde explicite `declaredCatalog != null` puis durcissement ultérieur vers champ `catalog` obligatoire non vide.

Analyze final utile :

```text
No issues found! (ran in 1.4s)
```

### Tests runtime M5

Résultat final utile :

```text
00:01 +15: All tests passed!
```

### Pré-gate M4

Résultat final du test rouge demandé :

```text
00:03 +6 -1: Some tests failed.
```

## 13. Incidents rencontrés

1. **Pré-gate M4 rouge confirmé**.
   - Incident attendu par le prompt ; traité par audit et classification, sans faux “hors scope”.

2. **Un vrai bug null-safety trouvé par analyze**.
   - Corrigé immédiatement dans `RuntimeMoveCatalogLoader`.

3. **Verrou Flutter startup lock**.
   - Une tentative de lancer `flutter analyze` et `flutter test` en parallèle a bloqué temporairement le test sur le startup lock.
   - J’ai relancé proprement la commande de test ensuite, de façon honnête et documentée.

4. **Import devenu inutile après ré-export de l’exception**.
   - Remonté par analyze dans `runtime_battle_setup_mapper_test.dart` ; corrigé.

## 14. État git utile

### `git status --short`

```text
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? .DS_Store
?? packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart
?? packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
?? packages/map_runtime/test/runtime_move_catalog_loader_test.dart
?? reports/phase-moves-m5-runtime-loader-report.md
```

### `git diff --stat`

```text
 .../application/runtime_battle_setup_mapper.dart   | 147 +++++++--------------
 .../test/runtime_battle_setup_mapper_test.dart     |  79 +++++++++--
 .../test/wild_battle_end_to_end_flow_test.dart     |  25 ++--
 3 files changed, 138 insertions(+), 113 deletions(-)
```

### Fichiers non suivis

```text
.DS_Store
packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart
packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
packages/map_runtime/test/runtime_move_catalog_loader_test.dart
reports/phase-moves-m5-runtime-loader-report.md
```

Note : `.DS_Store` est hors scope et n’a pas été touché.

## 15. Checklist finale

- [x] je me suis basé sur le code réel du repo
- [x] j’ai audité les fichiers critiques avant modification
- [x] j’ai exécuté le pré-gate M4 au début
- [x] j’ai classé le test rouge du pré-gate comme `préexistant prouvé` vis-à-vis de M4
- [x] je n’ai pas créé de loader parallèle hors `map_runtime`
- [x] je n’ai pas créé de clone runtime complet de `PokemonMove`
- [x] j’ai réutilisé le modèle canonique `PokemonMove`
- [x] je n’ai pas ajouté de fallback legacy dans `map_runtime`
- [x] j’ai rendu le loader runtime strict sur les entrées invalides
- [x] j’ai rendu le loader runtime strict sur les ids dupliqués
- [x] j’ai rendu le loader runtime strict sur la métadonnée `catalog`
- [x] `runtime_battle_setup_mapper.dart` délègue au seam dédié
- [x] il n’y a plus deux pipelines concurrents `moves.json` dans le runtime
- [x] j’ai gardé le scope borné à `map_runtime` après le pré-gate M4
- [x] je n’ai pas touché `map_battle`
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas rouvert M4 seed/bootstrap
- [x] j’ai mis beaucoup de commentaires utiles dans le code
- [x] j’ai ajouté des tests ciblés utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai intégré sa remarque valide
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report est honnête
- [x] le report contient le contenu complet des fichiers touchés

## 16. Retour du reviewer séparé

Reviewer séparé utilisé : `Halley`.

Retour initial utile :

1. **Finding valide** : le loader acceptait encore un `catalog` manquant ou vide.
   - Remarque retenue.

2. **Finding discutable mais utile** : le mapper projette encore les moves non standard en `power: 0` dans le handoff `BattleMoveData`.
   - Je n’ai pas transformé cela en gate M8 caché.
   - J’ai clarifié explicitement cette limite dans le commentaire de contrat du mapper.

Retour final après correction :

```text
No material findings.
```

## 17. Corrections appliquées suite à la review

- ajout d’une exigence stricte sur `catalog == 'moves'` et non vide dans `RuntimeMoveCatalogLoader` ;
- ajout d’un test de non-régression `fails explicitly when catalog metadata is missing` ;
- clarification du commentaire de projection `BattleMoveData` dans `RuntimeBattleSetupMapper` ;
- resserrage du diff en ré-exportant `RuntimeBattleSetupException` depuis le mapper, ce qui a permis d’éviter un import direct supplémentaire côté UI.

## 18. Autocritique finale

### Ce qui est solide

- le seam runtime dédié existe réellement ;
- le runtime charge enfin le canonique strictement ;
- il n’y a aucun fallback legacy côté runtime ;
- les tests prouvent le chargement canonique, les échecs honnêtes et l’intégration mapper.

### Ce qui reste seulement acceptable

- le handoff final vers `BattleMoveData` reste un contrat MVP `id/name/power` ;
- le runtime conserve bien `PokemonMove` complet dans son seam, mais le moteur battle n’est pas encore capable d’exploiter `accuracy`, `effects`, `engineSupportLevel` ou `unsupportedReasons`.

### Principal risque architectural restant

Le principal risque restant est le **trou entre le loader canonique riche et le handoff battle encore pauvre**. M5 le rend visible et propre, mais il ne le ferme pas entièrement. Ce sera le vrai sujet de M8.

### Ce que je corrigerais dans un M5-bis

- ajouter une politique explicite de refus ou d’annotation runtime pour certains moves canoniques impossibles à projeter honnêtement vers `BattleMoveData`, si l’équipe veut fermer davantage le trou avant M8 ;
- éventuellement centraliser les helpers de fixtures canoniques runtime si la répétition augmente dans plusieurs tests.

### Si une exigence du prompt était objectivement mauvaise

La pression implicite vers une éventuelle duplication runtime du modèle move était la moins saine. Dans le repo réel, réutiliser `PokemonMove` directement est plus simple, plus cohérent et plus défendable.

## 19. Limites restantes

- le pré-gate rouge côté `map_editor` reste ouvert mais documenté ;
- `map_battle` consomme toujours seulement `BattleMoveData(id/name/power)` ;
- les moves `catalog_only` / `structured_partial` sont chargés honnêtement par le runtime, mais leur exploitabilité complète n’est pas encore traitée ;
- M5 n’ouvre pas la validation globale projet ni la UI.

## 20. Conclusion honnête

M5 ferme proprement le seam runtime moves.

Le runtime lit maintenant le catalogue canonique via un loader dédié, strict et testé. Le mapper n’a plus son mini parser `id/name/power`, et les tests runtime ont été réalignés sur des fixtures canoniques réelles. Le pré-gate M4 a été traité honnêtement sans l’absorber de force dans un lot voisin.

Le lot reste borné. Il prépare bien la suite sans prétendre avoir déjà ouvert M8.

## 21. Annexe — contenu complet des fichiers touchés

Le report s’exclut volontairement lui-même de cette annexe pour éviter la récursion infinie.

## `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`

```dart
/// Exception levée quand le runtime ne peut pas construire un setup battle
/// honnête à partir des vraies données projet/save.
///
/// M5 l'extrait du mapper pour partager le même contrat d'erreur entre :
/// - le seam runtime spécialisé du catalogue moves ;
/// - le mapper runtime -> battle ;
/// - les call sites Flame qui doivent afficher une erreur métier claire.
///
/// Cela évite un cycle sale où le loader dépendrait du mapper uniquement pour
/// récupérer ce type d'erreur.
class RuntimeBattleSetupException implements Exception {
  const RuntimeBattleSetupException(
    this.message, {
    this.debugDetails,
  });

  final String message;
  final String? debugDetails;

  @override
  String toString() {
    final details = debugDetails?.trim();
    if (details == null || details.isEmpty) {
      return message;
    }
    return '$message ($details)';
  }
}

```

## `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

/// Loader runtime spécialisé du catalogue canonique des moves.
///
/// M5 ouvre volontairement un seam dédié ici, et pas dans `map_battle`, car :
/// - la source de vérité reste le workspace projet ;
/// - `map_runtime` est la bonne frontière pour lire ce JSON projet ;
/// - `map_battle` ne doit toujours pas connaître le stockage local ;
/// - le runtime doit être strict : aucun fallback legacy ni placeholder.
///
/// Le contrat est volontairement petit et ferme :
/// - lire `catalogFiles['moves']` depuis le manifeste projet ;
/// - parser chaque entrée via `PokemonMove.fromJson(...)` ;
/// - construire un index stable par id ;
/// - échouer explicitement si une entrée est invalide, dupliquée ou absente.
class RuntimeMoveCatalogLoader {
  const RuntimeMoveCatalogLoader();

  Future<RuntimeMoveCatalog> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    final relativePath = pokemonConfig.catalogFiles['moves']?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de charger le catalogue local des attaques pour démarrer le combat.',
        debugDetails: 'ProjectPokemonConfig.catalogFiles["moves"] is empty',
      );
    }

    final json = await _readJsonAtProjectRelativePath(
      projectRootDirectory,
      relativePath,
      label: 'Moves catalog',
    );
    final declaredCatalog = (json['catalog'] as String?)?.trim();
    if (declaredCatalog == null || declaredCatalog.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Le catalogue local des attaques est invalide; combat impossible.',
        debugDetails: 'Moves catalog is missing a non-empty "catalog" field',
      );
    }
    if (declaredCatalog != 'moves') {
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques a une forme inattendue.',
        debugDetails:
            'expected catalog="moves", actual catalog="$declaredCatalog"',
      );
    }

    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const RuntimeBattleSetupException(
        'Le catalogue local des attaques est invalide; combat impossible.',
        debugDetails: 'Moves catalog "entries" must be a JSON list',
      );
    }

    final entriesById = <String, PokemonMove>{};
    for (var index = 0; index < rawEntries.length; index++) {
      final rawEntry = rawEntries[index];
      if (rawEntry is! Map) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques contient une entrée invalide.',
          debugDetails: 'entryIndex=$index is not a JSON object',
        );
      }

      final entry = rawEntry.cast<String, dynamic>();
      final parsedMove = _parseCanonicalMoveEntry(
        entry,
        entryIndex: index,
      );

      // Le runtime est volontairement plus strict que l'éditeur :
      // - pas de fallback legacy ;
      // - pas de "last one wins" sur les ids dupliqués ;
      // - un catalogue ambigu doit être refusé avant le handoff combat.
      if (entriesById.containsKey(parsedMove.id)) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques contient des ids dupliqués.',
          debugDetails:
              'duplicate move id="${parsedMove.id}" at entryIndex=$index',
        );
      }
      entriesById[parsedMove.id] = parsedMove;
    }

    if (entriesById.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Le catalogue local des attaques est vide; combat impossible.',
      );
    }

    return RuntimeMoveCatalog._(
      Map<String, PokemonMove>.unmodifiable(entriesById),
    );
  }

  PokemonMove _parseCanonicalMoveEntry(
    Map<String, dynamic> entry, {
    required int entryIndex,
  }) {
    try {
      return PokemonMove.fromJson(entry);
    } on Object catch (error) {
      final rawId = (entry['id'] as String?)?.trim();
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques contient une entrée canonique invalide.',
        debugDetails:
            'entryIndex=$entryIndex${rawId == null || rawId.isEmpty ? '' : ', id=$rawId'} error=$error',
      );
    }
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String projectRootDirectory,
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(projectRootDirectory, relativePath)),
      label: label,
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required String label,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label file not found: ${file.path}',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label parse failed: $error',
      );
    }
  }

  String _resolveProjectPath(
    String projectRootDirectory,
    String relativeOrAbsolutePath,
  ) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

/// Index runtime en lecture seule des moves canoniques.
///
/// On réutilise directement `PokemonMove` pour éviter un faux DTO runtime
/// cloné à 95%. Ce seam donne au runtime tout ce dont il a besoin aujourd'hui :
/// - lookup strict par id ;
/// - accès aux champs canoniques ;
/// - préservation du niveau de support moteur et des raisons associées.
class RuntimeMoveCatalog {
  RuntimeMoveCatalog._(this.entriesById);

  final Map<String, PokemonMove> entriesById;

  PokemonMove? lookup(String moveId) => entriesById[moveId.trim()];
}

```

## `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'battle_start_request.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// On garde malgré tout ici un reader JSON minimal pour les espèces/learnsets
/// parce que :
/// - la source de vérité des données Pokémon de runtime est le workspace projet ;
/// - `map_runtime` ne doit pas dépendre des modèles internes de `map_editor` ;
/// - M5 n'ouvre pas encore un loader spécialisé pour toute la base Pokémon.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final reader = _RuntimePokemonProjectReader(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );

    final playerSeed = await _buildPlayerCombatantSeed(
      reader: reader,
      movesCatalog: movesCatalog,
      gameState: gameState,
      playerPartyIndex: playerPartyIndex,
    );

    final enemySeed = switch (request) {
      WildBattleStartRequest() => await _buildWildCombatantSeed(
          reader: reader,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => await _buildTrainerCombatantSeed(
          reader: reader,
          movesCatalog: movesCatalog,
          manifest: bundle.manifest,
          request: request,
        ),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(),
      enemyPokemon: enemySeed.toBattleCombatantData(),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildPlayerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required RuntimeMoveCatalog movesCatalog,
    required GameState gameState,
    int? playerPartyIndex,
  }) async {
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final species = await reader.readSpeciesById(playerPokemon.speciesId);
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            reader: reader,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon actif du joueur',
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildWildCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await reader.readSpeciesById(request.speciesId);
    final moveIds = await _deriveLearnsetMoveIds(
      reader: reader,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildTrainerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectManifest manifest,
    required TrainerBattleStartRequest request,
  }) async {
    final trainer = _findTrainer(manifest, request.trainerId);
    if (trainer.team.isEmpty) {
      throw RuntimeBattleSetupException(
        'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
        debugDetails: 'trainerId=${trainer.id}',
      );
    }

    // Le moteur battle MVP reste mono-combattant : on prend donc le premier
    // Pokémon authoré de l’équipe, sans inventer une seconde logique de party.
    final teamMember = trainer.team.first;
    final species = await reader.readSpeciesById(teamMember.speciesId);
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            reader: reader,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "${trainer.name}" (${teamMember.speciesId})',
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  /// Retourne le Pokémon joueur qui doit être injecté dans [BattleSetup].
  ///
  /// Deux cas :
  /// - lot 9 seul : on prend le premier membre jouable ;
  /// - lot 10 : le runtime fournit [playerPartyIndex] pour garantir que le
  ///   combat et le write-back visent exactement le même slot.
  ///
  /// On refuse explicitement un index invalide ou un slot déjà K.O. pour éviter
  /// tout glissement silencieux vers un autre membre de la party.
  PlayerPokemon _selectPlayerPartyMember(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final resolvedIndex =
        playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (resolvedIndex < 0 || resolvedIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, partyLength=${party.members.length}',
      );
    }

    final member = party.members[resolvedIndex];
    if (member.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, speciesId=${member.speciesId}',
      );
    }

    return member;
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required _RuntimePokemonProjectReader reader,
    required _RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await reader.readLearnsetByRef(
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    // On construit la liste de moves disponibles en respectant uniquement les
    // familles déjà exploitées ailleurs dans le projet :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    //
    // Ensuite on garde les 4 derniers IDs uniques. Cela reste simple, lisible
    // et suffisamment proche d’un move set plausible sans inventer un nouveau
    // moteur de sélection.
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final normalizedMoveIds = _normalizeUniqueIdsPreserveOrder(moveIds);
    if (normalizedMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    for (final moveId in normalizedMoveIds.take(4)) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.name,
          // Le moteur battle MVP reste borné :
          // - il ne connaît encore ni accuracy, ni effets structurés, ni
          //   support level ;
          // - il consomme uniquement une puissance de base simplifiée.
          //
          // M5 ne filtre donc pas les moves `catalog_only` ou
          // `structured_partial` : le loader runtime conserve l'objet canonique
          // complet, puis le mapper continue le handoff minimal historique vers
          // `BattleMoveData`.
          //
          // Conséquence assumée pour ce lot :
          // - si le move suit le flow de dégâts standard, on transmet
          //   `basePower` ;
          // - sinon on garde `0`, exactement comme les vieux status moves du
          //   MVP battle.
          //
          // On documente explicitement cette limite au lieu de l'étendre ici :
          // décider quels `effects`/support levels deviennent réellement
          // exécutables appartient au futur pont runtime -> battle (M8), pas
          // à ce seam de chargement M5.
          power: move.usesStandardDamageFlow ? move.basePower : 0,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    // Formule Pokémon simplifiée mais vraie dans son intention :
    // elle part bien des stats projet/save au lieu d’une constante hardcodée.
    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}

class _RuntimeBattleCombatantSeed {
  const _RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

/// Reader JSON ultra-ciblé pour le runtime battle handoff.
///
/// Il relit uniquement ce que le lot 9 doit mapper :
/// - espèces (id, base HP, ref learnset)
/// - learnsets
///
/// Le catalogue moves a été extrait dans [RuntimeMoveCatalogLoader] pour
/// éviter qu'un second parser canonique vive caché dans ce reader local.
class _RuntimePokemonProjectReader {
  const _RuntimePokemonProjectReader({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

  Future<_RuntimePokemonSpecies> readSpeciesById(String speciesId) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Une espèce Pokémon vide ne peut pas être mappée vers le combat.',
      );
    }

    final speciesDirectory = Directory(
      _resolveProjectPath(
        _normalizeConfiguredRelativePath(
          pokemonConfig.speciesDir,
          fallback: 'data/pokemon/species',
        ),
      ),
    );
    if (!await speciesDirectory.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les espèces Pokémon locales pour démarrer le combat.',
        debugDetails: 'Missing species directory: ${speciesDirectory.path}',
      );
    }

    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is! File ||
          p.extension(entity.path).toLowerCase() != '.json') {
        continue;
      }
      final rawJson = await _readJsonFile(
        entity,
        label: 'Pokemon species file',
      );
      final declaredId = (rawJson['id'] as String?)?.trim() ?? '';
      if (declaredId != normalizedSpeciesId) {
        continue;
      }

      final baseStats =
          (rawJson['baseStats'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{
            'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
          };
      final abilities =
          (rawJson['abilities'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      return _RuntimePokemonSpecies(
        id: declaredId,
        baseHp: (baseStats['hp'] as num?)?.toInt() ?? 1,
        primaryAbilityId: (abilities['primary'] as String?)?.trim() ?? '',
        learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
      );
    }

    throw RuntimeBattleSetupException(
      'Espèce Pokémon introuvable pour démarrer le combat.',
      debugDetails: 'speciesId=$speciesId',
    );
  }

  Future<_RuntimePokemonLearnset> readLearnsetByRef({
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final learnsetId =
        speciesRef.trim().isEmpty ? fallbackSpeciesId : speciesRef;
    final learnsetsDirectory = _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
    final relativePath = p.join(learnsetsDirectory, '$learnsetId.json');
    final json = await _readJsonAtProjectRelativePath(
      relativePath,
      label: 'Pokemon learnset "$learnsetId"',
    );

    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return _RuntimePokemonLearnset(
      startingMoves: ((json['startingMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      relearnMoves: ((json['relearnMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .map(
            (entry) => _RuntimePokemonLevelUpMove(
              moveId: (entry['moveId'] as String?)?.trim() ?? '',
              level: (entry['level'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(relativePath)),
      label: label,
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required String label,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label file not found: ${file.path}',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label parse failed: $error',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawPath, {
    required String fallback,
  }) {
    final trimmed = rawPath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolveProjectPath(String relativeOrAbsolutePath) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

class _RuntimePokemonSpecies {
  const _RuntimePokemonSpecies({
    required this.id,
    required this.baseHp,
    required this.primaryAbilityId,
    required this.learnsetRef,
  });

  final String id;
  final int baseHp;
  final String primaryAbilityId;
  final String learnsetRef;
}

class _RuntimePokemonLearnset {
  const _RuntimePokemonLearnset({
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<_RuntimePokemonLevelUpMove> levelUp;
}

class _RuntimePokemonLevelUpMove {
  const _RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}

```

## `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeMoveCatalogLoader', () {
    late Directory tempProjectRoot;
    const loader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_move_catalog_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test(
        'loads a canonical moves catalog and preserves runtime-relevant fields',
        () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          _canonicalMove(
            id: 'thunderbolt',
            name: 'Thunderbolt',
            type: 'electric',
            category: PokemonMoveCategory.special,
            basePower: 90,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
            effects: const <PokemonMoveEffect>[
              PokemonMoveEffect.applyStatus(
                chance: 10,
                statusId: 'par',
              ),
            ],
          ),
          _canonicalMove(
            id: 'swift',
            name: 'Swift',
            type: 'normal',
            category: PokemonMoveCategory.special,
            basePower: 60,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
          ),
          _canonicalMove(
            id: 'trick_room',
            name: 'Trick Room',
            type: 'psychic',
            category: PokemonMoveCategory.status,
            basePower: 0,
            accuracy: const PokemonMoveAccuracy.alwaysHits(),
            effects: const <PokemonMoveEffect>[
              PokemonMoveEffect.setPseudoWeather(
                pseudoWeatherId: 'trickroom',
              ),
            ],
            engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
            unsupportedReasons: const <String>[
              'unsupported_mechanic:turn_order_inversion',
            ],
          ),
        ],
      );

      final catalog = await loader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final thunderbolt = catalog.lookup('thunderbolt');
      expect(thunderbolt, isNotNull);
      expect(thunderbolt!.basePower, equals(90));
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

      final swift = catalog.lookup('swift');
      expect(swift, isNotNull);
      expect(
        swift!.accuracy,
        const PokemonMoveAccuracy.alwaysHits(),
      );

      final trickRoom = catalog.lookup('trick_room');
      expect(trickRoom, isNotNull);
      expect(
        trickRoom!.engineSupportLevel,
        PokemonMoveEngineSupportLevel.structuredPartial,
      );
      expect(
        trickRoom.unsupportedReasons,
        equals(<String>['unsupported_mechanic:turn_order_inversion']),
      );
      expect(
        trickRoom.effects,
        contains(
          const PokemonMoveEffect.setPseudoWeather(
            pseudoWeatherId: 'trickroom',
          ),
        ),
      );
    });

    test('fails explicitly on an invalid canonical move entry', () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'type': 'normal',
            'category': 'special',
            'basePower': 40,
            // Le runtime ne doit jamais accepter cette forme legacy ici :
            // c'est un catalogue canonique invalide, pas un cas à réparer.
            'accuracy': 100,
            'pp': 35,
          },
        ],
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('entrée canonique invalide'),
          ),
        ),
      );
    });

    test('fails explicitly on duplicate canonical move ids', () async {
      await _writeCanonicalMovesCatalog(
        tempProjectRoot,
        entries: <Map<String, dynamic>>[
          _canonicalMove(
            id: 'tackle',
            name: 'Tackle',
            type: 'normal',
            category: PokemonMoveCategory.physical,
            basePower: 40,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
          ),
          _canonicalMove(
            id: ' tackle ',
            name: 'Shadow Tackle',
            type: 'ghost',
            category: PokemonMoveCategory.special,
            basePower: 50,
            accuracy: const PokemonMoveAccuracy.percent(value: 100),
          ),
        ],
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ids dupliqués'),
          ),
        ),
      );
    });

    test('fails explicitly when catalog metadata is missing', () async {
      await _writeProjectRelativeJson(
        tempProjectRoot,
        'custom/pokemon/catalogs/moves.json',
        <String, dynamic>{
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'meta': <String, Object>{
            'description': 'Broken runtime move catalog loader test catalog',
          },
          'entries': <Map<String, dynamic>>[
            _canonicalMove(
              id: 'tackle',
              name: 'Tackle',
              type: 'normal',
              category: PokemonMoveCategory.physical,
              basePower: 40,
              accuracy: const PokemonMoveAccuracy.percent(value: 100),
            ),
          ],
        },
      );

      await expectLater(
        () => loader.load(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('missing a non-empty "catalog" field'),
          ),
        ),
      );
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

Future<void> _writeCanonicalMovesCatalog(
  Directory projectRoot, {
  required List<Map<String, dynamic>> entries,
}) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime move catalog loader test catalog',
      },
      'entries': entries,
    },
  );
}

Map<String, dynamic> _canonicalMove({
  required String id,
  required String name,
  required String type,
  required PokemonMoveCategory category,
  required int basePower,
  required PokemonMoveAccuracy accuracy,
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category: category,
    target: PokemonMoveTarget.normal,
    basePower: basePower,
    accuracy: accuracy,
    pp: 35,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```

## `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'aqua_ring'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'aqua_ring'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'aqua_ring',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45),
        _moveEntry('razor_leaf', 'Razor Leaf', 55),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40),
        _moveEntry('flame_wheel', 'Flame Wheel', 60),
        _moveEntry('water_gun', 'Water Gun', 40),
        _moveEntry('aqua_ring', 'Aqua Ring', 0),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: 'normal',
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```

## `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wild battle runtime flow lot 11', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('wild_battle_flow_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('real wild encounter chain resolves to victory and writes back hp',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      // On part bien du vrai chemin overworld minimal :
      // 1. world gameplay avec spawn réel
      // 2. déplacement d'une case vers une zone de rencontre
      // 3. check de rencontre sur la case atteinte
      final initialWorld = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final stepResult = stepGameplayWorld(
        initialWorld,
        const MoveIntent(Direction.east),
      );
      expect(stepResult, isA<Moved>());
      final movedWorld = stepResult.world;
      expect(movedWorld.player.pos, const GridPos(x: 1, y: 0));

      final encounterCheck = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.speciesId, equals('sparkitten'));
      expect(encounter.level, equals(6));

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      expect(request.kind, equals(RuntimeBattleKind.wild));
      expect(request.source, equals(RuntimeBattleSourceKind.encounterZone));

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);
      expect(stateWithSeen.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        stateWithSeen.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );

      final session = createBattleSession(setup);
      final afterTurn1 = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn1.state.isFinished, isFalse);
      final afterTurn2 =
          afterTurn1.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn2.state.outcome, isNotNull);
      expect(afterTurn2.state.outcome!.isVictory, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'wild-request',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field_map',
              playerPos: GridPos(x: 1, y: 0),
              playerFacing: Direction.east,
            ),
            mapId: 'field_map',
            zoneId: 'encounter_grass',
            tableId: 'field_grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'sparkitten',
            level: 6,
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
            playerPos: GridPos(x: 1, y: 0),
          ),
          playerPartyIndex: 0,
        ),
        outcome: afterTurn2.state.outcome!,
      );

      expect(updatedState.party.members.first.currentHp, equals(15));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('run choice produces a real runaway outcome without trainer flags',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);

      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceRun())
          .state
          .outcome!;
      expect(outcome.isRunaway, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members.first.currentHp, equals(20));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('wild capture is disabled when the player has no poke-ball', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(
          bag: const Bag(),
        ),
        request: request,
      );

      expect(setup.allowCapture, isFalse);
    });

    test('capture choice produces a persistent captured pokemon', () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      expect(setup.allowCapture, isTrue);

      final stateWithSeen = markSpeciesSeenInGameState(
        _playerState(),
        setup.enemyPokemon.speciesId,
      );
      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceCapture())
          .state
          .outcome!;

      expect(outcome.isCaptured, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members, hasLength(2));
      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('sparkitten'));
      expect(captured.level, equals(6));
      expect(captured.abilityId, equals('blaze'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch']));
      expect(captured.currentHp, equals(outcome.finalState.enemy.currentHp));
      expect(
        updatedState.bag.entries,
        equals(
          const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
          ],
        ),
      );
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(updatedState.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });
  });
}

GameState _playerState({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
    ],
  ),
}) {
  return GameState(
    saveId: 'wild-flow-save',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 10,
          knownMoveIds: <String>['vine_whip'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

MapData _buildMap() {
  return const MapData(
    id: 'field_map',
    name: 'Field Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_start',
        name: 'Spawn Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'spawn_start',
    ),
  );
}

RuntimeMapBundle _buildBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
  MapData map,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ProjectManifest> _writeProjectManifest(Directory projectRoot) async {
  const manifest = ProjectManifest(
    name: 'Wild Battle Flow Test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'field_grass',
        name: 'Field Grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
          ),
        ],
      ),
    ],
    pokemon: ProjectPokemonConfig(
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'data/pokemon/catalogs/moves.json',
      },
    ),
  );

  await File(
    p.join(projectRoot.path, 'project.json'),
  ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  await _writePokemonFixtures(projectRoot);
  return manifest;
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 35,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 305,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'startingMoves': <String>['vine_whip'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Wild battle flow test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('vine_whip', 'Vine Whip', 12),
        _moveEntry('scratch', 'Scratch', 5),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: 'normal',
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.physical,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() {
    if (nextDoubleValues.isEmpty) {
      return 0.0;
    }
    final index = _doubleIndex < nextDoubleValues.length
        ? _doubleIndex++
        : nextDoubleValues.length - 1;
    return nextDoubleValues[index];
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    if (nextIntValues.isEmpty) {
      return 0;
    }
    final index = _intIndex < nextIntValues.length
        ? _intIndex++
        : nextIntValues.length - 1;
    return nextIntValues[index] % max;
  }
}

```
