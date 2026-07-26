# RM-028 — Nature/IV/EV Bridge Fidelity

## Résumé exécutif

**Lot exact :** `RM-028 — Nature/IV/EV Bridge Fidelity`

**Liens canoniques :** `FG-020`, `FG-053`

**Frontière explicite :** `FG-206`

**Verdict proposé pour RM-028 :** `DONE`

Les statistiques sauvegardées d’un Pokémon joueur sont maintenant calculées
avec une règle unique dans `map_gameplay`, puis projetées sans formule
dupliquée vers les seeds battle legacy et PSDK. Les IV et EV persistés
continuaient déjà d’exister dans `PlayerPokemon`; le bridge applique désormais
aussi la nature canonique, avec les 25 natures principales et les modificateurs
110/90 après le floor de chaque statistique non-HP.

Les adversaires n’utilisent plus des valeurs implicites dispersées :

- sauvage V0 : nature `hardy`, IV 0, EV 0 ;
- trainer/statique V0 : nature `hardy`, IV 15 partout, EV 0.

Une nature sauvegardée inconnue échoue explicitement avec un diagnostic runtime
au lieu d’être neutralisée silencieusement. Le lot ne crée aucune UI
compétitive d’édition des IV/EV/natures : cette surface reste volontairement
différée dans `FG-206`.

## Confirmation du scope

### Inclus

- catalogue gameplay pur des 25 natures canoniques ;
- application déterministe des multiplicateurs 110/90 ;
- profils de statistiques adverses V0 nommés et testés ;
- source unique de calcul pour les seeds legacy et PSDK ;
- consommation de la nature persistée pendant progression, évolution,
  restauration et présentation pause ;
- préservation des HP courants, PP, objets tenus et métadonnées existantes ;
- tests positifs, négatifs, compatibilité battle et smoke runtime.

### Volontairement hors scope

- contrôles editor avancés IV/EV/nature (`FG-206`) ;
- génération aléatoire de la nature ou des IV sauvages ;
- attribution d’EV après combat ;
- couplage des IV adverses à `battleDifficulty` ;
- extension du schéma trainer pour authorer chaque spread ;
- promotion de la capability gate complète, réservée à `RM-053` ;
- modification de la roadmap canonique.

## Audit initial

### État observé

- `PlayerPokemon` persistait déjà `natureId`, `ivs` et `evs`.
- `PokemonStatCalculator` consommait IV/EV mais ne proposait qu’une policy de
  nature explicitement neutre.
- le constructeur de seeds runtime dupliquait la formule de statistiques :
  IV/EV joueur y entraient, mais la nature était ignorée.
- wild, trainer et static utilisaient de fait IV 0, EV 0 et une nature neutre,
  sans contrat nommé.
- progression, évolution et plusieurs caps HP recalculaient les stats avec la
  policy neutre.
- `ProjectTrainerPokemonEntry` ne possède pas de champs nature/IV/EV ; les
  ajouter aurait élargi RM-028 vers l’authoring compétitif `FG-206`.

### Risques identifiés

- appliquer la nature uniquement au battle et laisser progression/évolution
  recalculer des stats divergentes ;
- arrondir avant ou après le mauvais étage de la formule ;
- neutraliser une faute de donnée et masquer une sauvegarde invalide ;
- modifier la difficulté IA en lui donnant aussi une sémantique de stats ;
- diverger entre legacy et PSDK ;
- écraser les changements utilisateur préexistants du hub/player UI ;
- annoncer `FG-053` terminé avant RM-029 et RM-053.

### Décisions

- `map_gameplay` reste propriétaire de la formule pure.
- Le multiplicateur nature s’applique au résultat entier de la statistique
  non-HP, conformément à la cible de parité définie par RM-020.
- Les IDs sont normalisés avec `trim().toLowerCase()`, mais une valeur hors des
  25 natures échoue.
- `battleDifficulty` reste exclusivement une policy IA.
- Les profils adverses V0 sont stables et identifiables par
  `pokemap-wild-zero-v0` et `pokemap-trainer-balanced-v0`.

## Verdict des cinq passes obligatoires

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | propriétaire unique gameplay, frontières core/editor respectées |
| Implémentation | PASS | 25 natures, deux profils V0, six bridges legacy/PSDK reliés |
| Tests | PASS | gameplay 404/404, runtime ciblé 68/68, battle 1757/1757 |
| Build / Validation | PASS | analyses gameplay, runtime et battle sans diagnostic |
| Critique finale | PASS avec limites déclarées | FG-206 et RM-053 non surpromus ; policy adversaire V0 volontairement simple |

Ces cinq passes ont été conduites comme cinq revues nommées et séparées dans le
même agent. Aucun sub-agent n’a été lancé pour ce lot, conformément à la
contrainte active interdisant la délégation proactive.

## Inventaire exhaustif

### Fichiers modifiés

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_gameplay/lib/map_gameplay.dart` | exports du calculateur | expose les contrats nature/profils adverses |
| `packages/map_gameplay/lib/src/pokemon_stat_calculator.dart` | policy, catalogue, profils, calcul | ajoute les 25 natures, le fail-closed et les modifiers |
| `packages/map_gameplay/lib/src/battle_progression_service.dart` | recalcul des stats | consomme la nature persistée |
| `packages/map_gameplay/lib/src/pokemon_evolution_service.dart` | recalcul après évolution | consomme la nature persistée |
| `packages/map_gameplay/test/pokemon_stat_calculator_test.dart` | groupe du calculateur | couvre catalogue, arrondis, profils et invalides |
| `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart` | six constructeurs de seed + helper | remplace la formule dupliquée et relie player/wild/trainer |
| `packages/map_runtime/lib/src/application/player_service_runtime_controller.dart` | recalcul de recovery | applique la nature persistée |
| `packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart` | preview progression | applique la nature persistée |
| `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart` | snapshot party | applique la nature persistée |
| `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart` | player/wild/trainer | prouve non-neutre, IV/EV, profils et échec inconnu |
| `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart` | mapping save réel | aligne l’attendu sur la nature persistée |

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-27-rm-028-nature-iv-ev-bridge-fidelity.md` | plan d’implémentation exécuté |
| `reports/gameplay/fg_020_053_nature_iv_ev_bridge_fidelity.md` | présent Evidence Pack |

Le présent rapport n’est pas reproduit dans lui-même afin d’éviter une
récursion infinie. L’autre fichier créé est reproduit intégralement en annexe.

## Découpage précis des modifications

### Gameplay

- `PokemonNatureStatPolicy.canonical` exige un `natureId`.
- `PokemonNatureStat` énumère les cinq statistiques modifiables.
- `PokemonNatureEffect.apply` applique 110 %, 90 % ou 100 % avec division
  entière.
- `canonicalPokemonNatureIds` et la table associée couvrent exactement 25 IDs
  uniques, dont les cinq natures neutres.
- `canonicalPokemonNatureEffect` refuse toute nature inconnue.
- `PokemonOpponentStatProfile` définit les valeurs wild et trainer V0.
- HP reste indépendant de la nature.
- IV autorisés : 0–31 ; EV autorisés : 0–252 par statistique, comme avant.

### Runtime

- la formule locale du constructeur de seeds est supprimée ;
- `_calculateResolvedStats` adapte `ProjectPokemonSpecies` vers
  `PokemonBaseStats` et appelle le calculateur gameplay ;
- une `ArgumentError` est convertie en `RuntimeBattleSetupException` avec
  profil, espèce, nature, IV et EV ;
- les seeds player legacy/PSDK utilisent les valeurs sauvegardées ;
- les seeds wild legacy/PSDK utilisent `wildV0` ;
- les seeds trainer/statique legacy/PSDK utilisent `trainerV0` ;
- les HP courants restent clampés sur le nouveau max HP ;
- moves, PP, statut, ability, typing, held item et lineup metadata ne changent
  pas.

### Consommateurs secondaires

- progression de niveau ;
- évolution ;
- récupération joueur ;
- preview de récompense/progression ;
- party affichée dans le menu pause.

Ces consommateurs utilisent tous la même nature persistée et ne peuvent plus
produire silencieusement un max HP ou une statistique non-HP incohérente avec
le combat.

## Tests créés ou modifiés

### Positifs

- formule neutre historique inchangée ;
- nature `bold` : attaque réduite et défense augmentée après floor ;
- les cinq natures neutres ne modifient aucune stat ;
- catalogue exact de 25 IDs uniques ;
- profil sauvage à IV/EV zéro ;
- profil trainer à IV 15 et EV zéro ;
- player seed legacy et PSDK avec nature non neutre et spreads non nuls ;
- trainer seed legacy et PSDK avec le profil déterministe ;
- mapper de sauvegarde réel aligné ;
- progression, évolution, rewards, pause et smoke battle non régressés.

### Négatifs

- nature canonique absente : `ArgumentError` gameplay ;
- nature sauvegardée inconnue : `RuntimeBattleSetupException` avec diagnostic ;
- IV hors 0–31 et EV hors 0–252 : rejet ;
- aucune fallback neutre silencieuse.

## Commandes et résultats exacts

### RED initial

```bash
cd packages/map_gameplay
dart test test/pokemon_stat_calculator_test.dart
```

```text
Échec de compilation attendu : catalogue canonique, enum de stat et profils
adverses encore absents.
```

```bash
cd packages/map_runtime
flutter test test/runtime_battle_combatant_seed_builder_test.dart \
  --plain-name 'builds a player combatant seed from explicit knownMoveIds'
```

```text
+0 -1 : attaque attendue 18, valeur neutre historique 20.
```

### Gameplay ciblé et groupé

```bash
cd packages/map_gameplay
dart test test/pokemon_stat_calculator_test.dart
dart test test/pokemon_stat_calculator_test.dart \
  test/battle_progression_service_test.dart \
  test/pokemon_evolution_service_test.dart
```

```text
+7: All tests passed!
+32: All tests passed!
```

### Gameplay complet

```bash
cd packages/map_gameplay
dart test --concurrency=4
dart analyze
```

```text
+404: All tests passed!
Analyzing map_gameplay... No issues found!
```

### Runtime ciblé initial

```bash
cd packages/map_runtime
flutter test test/runtime_battle_combatant_seed_builder_test.dart
```

```text
+23: All tests passed!
```

### Incident de commande et correction

La première composition du groupe runtime mentionnait par erreur
`test/runtime_psdk_battle_setup_mapper_test.dart`, fichier inexistant. Les
autres tests ont continué et ont révélé un ancien attendu neutre dans
`runtime_battle_setup_mapper_test.dart` :

```text
Failed to load .../test/runtime_psdk_battle_setup_mapper_test.dart:
Does not exist.
RuntimeBattleSetupMapper maps the real player party member from runtime save data
Expected: <16>
Actual: <14>
```

Le chemin inexistant a été retiré de la commande et l’attendu a été aligné sur
la nature `bold` réellement sauvegardée. Le test isolé a ensuite donné :

```text
+1: All tests passed!
```

### Runtime corrigé, smoke inclus

```bash
cd packages/map_runtime
flutter test \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_reward_resolver_test.dart \
  test/player/runtime_player_pause_data_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
flutter analyze
```

```text
+68: All tests passed!
Analyzing map_runtime... No issues found! (ran in 3.6s)
```

### Compatibilité moteur battle

```bash
cd packages/map_battle
dart test --concurrency=4
dart analyze
```

```text
+1757: All tests passed!
Analyzing map_battle... No issues found!
```

### Format et hygiene diff

```bash
dart format \
  packages/map_gameplay/lib/map_gameplay.dart \
  packages/map_gameplay/lib/src/pokemon_stat_calculator.dart \
  packages/map_gameplay/lib/src/battle_progression_service.dart \
  packages/map_gameplay/lib/src/pokemon_evolution_service.dart \
  packages/map_gameplay/test/pokemon_stat_calculator_test.dart \
  packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart \
  packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart \
  packages/map_runtime/lib/src/application/player_service_runtime_controller.dart \
  packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart \
  packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart \
  packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
git diff --check
```

```text
Formatted 11 files (0 changed) in 0.05 seconds.
git diff --check: aucune sortie, code 0.
```

## État Git

### État initial du lot

Le commit RM-026 était `ce4ee6b9`. Le worktree contenait uniquement les sept
fichiers utilisateur préexistants suivants :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### Isolation de commit

Seuls les onze fichiers modifiés et les deux fichiers créés listés dans cet
Evidence Pack sont inclus dans le commit RM-028. Les sept fichiers utilisateur
ci-dessus sont exclus du staging.

### État final attendu après commit

Le worktree doit revenir exactement aux sept modifications utilisateur
préexistantes. La preuve finale est contrôlée après création du commit.

## Statuts de roadmap proposés

| ID | Statut proposé après ce lot | Justification |
|---|---|---|
| `RM-028` | `DONE` | nature/IV/EV sauvegardés consommés, profils adverses définis, preuves vertes |
| `FG-020` | reste `DONE` | le contrat persisté est désormais consommé plus fidèlement |
| `FG-053` | reste `TODO` | RM-029 et la gate complète RM-053 restent à livrer |
| `FG-206` | reste `DEFERRED` | aucune UX compétitive avancée ajoutée |

La roadmap canonique n’est pas modifiée par ce lot.

## Auto-critique finale

### Points solides

- une seule formule de statistiques existe côté gameplay ;
- les deux backends battle reçoivent les mêmes valeurs ;
- l’invalidité est visible et diagnostiquée ;
- la difficulty IA n’a pas reçu de deuxième sens implicite ;
- les profils V0 sont déterministes et faciles à remplacer plus tard ;
- les suites des trois packages traversés sont vertes.

### Risques et limites restantes

- les IV/natures sauvages ne sont pas individualisés ni aléatoires ;
- tous les trainers partagent le même profil IV15/Hardy ;
- l’editor ne permet pas d’authorer ces valeurs, par choix `FG-206` ;
- le plafond EV global de 510 n’est pas introduit par RM-028 ; seule la limite
  existante de 252 par statistique est validée ;
- toute sauvegarde historique contenant une nature non canonique échouera
  maintenant explicitement au bridge battle au lieu d’être neutralisée ;
- `FG-053` ne peut être promu avant Struggle RM-029 et la gate RM-053.

### Prochain lot recommandé

`RM-029 — Exhausted PP & Struggle V0`, afin que l’absence de move avec PP ne
termine plus sur `noLegalChoice`.

## Annexe A — contenu complet du plan créé

Chemin :
`docs/superpowers/plans/2026-07-27-rm-028-nature-iv-ev-bridge-fidelity.md`

```markdown
# RM-028 Nature/IV/EV Bridge Fidelity Implementation Plan

**Goal:** appliquer la nature et les IV/EV persistés aux stats battle runtime,
et remplacer les valeurs adverses implicites par deux profils V0 déterministes.

**Architecture:** `map_gameplay` devient l’unique propriétaire de la formule de
stats et du catalogue canonique des 25 natures. `map_runtime` charge les données
projet puis appelle ce calculateur pour les seeds legacy et PSDK. Les profils
adverses restent des règles gameplay pures, sans ajouter de faux authoring
avancé dans `map_core` ou `map_editor`.

**Opponent policy V0:**

- sauvage : nature Hardy, IV 0, EV 0 ;
- trainer/statique : nature Hardy, IV 15 partout, EV 0.

**Non-goals:** UI d’édition IV/EV/nature (`FG-206`), génération aléatoire des
IV/natures sauvages, EV gagnés en combat, migration de sauvegarde, RM-053.

### Task 1: Contrat gameplay canonique

- [x] Ajouter les 25 natures et leurs modifiers 110/90.
- [x] Appliquer le modifier après le floor de la stat non-HP.
- [x] Rejeter une nature canonique absente au lieu de neutraliser silencieusement.
- [x] Définir les profils adverses sauvage et trainer V0.

### Task 2: Bridge runtime unique

- [x] Remplacer les formules runtime dupliquées par `PokemonStatCalculator`.
- [x] Appliquer nature/IV/EV joueur aux seeds legacy et PSDK.
- [x] Appliquer les profils adverses aux wild/trainer/static seeds.
- [x] Garder un diagnostic clair pour une nature ou spread invalide.

### Task 3: Cohérence des autres consommateurs

- [x] Utiliser la nature persistée dans progression et évolution.
- [x] Utiliser la nature persistée dans les caps HP runtime.
- [x] Préserver HP courant, PP, objet tenu et metadata existants.

### Task 4: Validation et clôture

- [x] Tests gameplay et runtime positifs/négatifs.
- [x] Suites package-scoped, analyses et smoke battle.
- [x] Evidence Pack FG-020/053, frontière FG-206.
- [x] Commit isolé et état Git final.
```
