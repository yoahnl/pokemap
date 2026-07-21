# NSC-81 — Selbrume canonical campaign authoring — Evidence Pack

Date : 2026-07-21

Lot : `NSC-81 — Campagne canonique Selbrume et polish`

Lots FG corrélés : `FG-181`, `FG-183`, contribution narrative à `FG-185`
Verdict du lot : **DONE proposé pour NSC-81**. Les statuts officiels FG ne sont
pas modifiés par ce lot ; `FG-181` et `FG-183` restent au mieux `PARTIAL` avant
les preuves reload/receipt/E2E de NSC-82.

## Résumé exécutif

Le snapshot Selbrume est à nouveau reproductible depuis son seeder canonique.
La spécification `MVP Selbrume/selbrume.md` est traduite en une matrice
exécutable couvrant les douze étapes principales et les trois quêtes
secondaires. Les sorties de combat portent désormais une intention explicite :
progression, nouvel essai ou défaite acceptée. Le runtime exécute les routes
victoire/défaite de Lysa et les récompenses persistantes des trois quêtes
optionnelles.

Le build macOS global n'est pas vert avec le SDK local Flutter 3.41.6 : le code
préexistant du runtime utilise `ScrollCacheExtent.pixels` et le paramètre
`scrollCacheExtent`, disponibles dans le lockfile Flutter >= 3.44.0. Cette
incompatibilité ne vient pas du diff NSC-81. Le test runtime ciblé passe en
important seulement les ports applicatifs concernés.

## Confirmation du scope

Inclus :

- campagne principale « La brume du phare » ;
- choix de ton et branches victoire/défaite de Lysa ;
- quêtes « Cristaux de sel », « Goélise du port » et « Cabane du phare » ;
- cohérence Storyline → Step → Scene → Event actif → Fact ;
- politiques de fin explicites ;
- polish ciblé des quatre Yarn demandés ;
- preuve runtime des Facts, Steps et récompenses.

Non-objectifs conservés :

- aucune modification du moteur de combat, des maps physiques ou de l'UI ;
- aucune fermeture anticipée du gate global `FG-185` ;
- aucune modification de `pokemap_roadmap_mecaniques_fangame.md` ;
- le Validator global, son receipt, le reload et le retry transactionnel sont
  volontairement réservés à NSC-82.

## Audit initial

État Git initial au début de NSC-81 : branche `main`, HEAD `06ee1ff8f`, arbre
propre après NSC-80. Le premier `seed --check` a ensuite détecté un drift de
`selbrume/project.json`. L'analyse du diff a montré que le seeder retirait sept
`outcomePolicy` pourtant déjà présentes dans le snapshot promu.

Contrats inspectés :

- `SceneEndPayload.outcomePolicy` et `SceneOutcomePolicy` dans `map_core` ;
- génération canonique et idempotente du seeder Selbrume ;
- liens de Steps et relations `sideQuestAvailableDuring` ;
- exécution transactionnelle par `executeNarrativeEventScene` ;
- diagnostics Event, Scene et World Rule déjà couverts par le test du seed ;
- rapport de readiness du 2026-07-19 et lots `FG-180` à `FG-185`.

Risques identifiés :

1. une régénération pouvait effacer la sémantique retry/progression ;
2. un texte « Défaite » ne doit jamais servir à inférer une règle moteur ;
3. les quêtes secondaires pouvaient exister dans le manifeste sans preuve
   d'exécution de leurs récompenses ;
4. `selbrume.md` mentionne parfois une étape séparée « unlock passage », alors
   que sa section détaillée définit douze étapes et fusionne cette action dans
   `step_report_to_soline` ; la matrice suit cette section détaillée ;
5. le Validator symbolique global dépasse actuellement son budget de 16 384
   états ; ce signal réel est transféré à NSC-82, pas masqué.

## Matrice de couverture

| Beat de spécification | Storyline / Steps | Scenes et entrée Event | État persistant prouvé |
|---|---|---|---|
| Introduction et mission | `story_main_brume_phare`, intro + mission | `scene_mael_intro` | histoire démarrée, Maël vu, mission donnée |
| Alerte au port | aller au port | `scene_port_entry` | alerte, panique ou foule rassurée |
| Rival Lysa | combat rival | `scene_lysa_port` + deux follow-ups | ton choisi, victoire ou défaite, convergence |
| Entrée des marais | entrer dans les marais | `scene_marais_entry`, `scene_mado_intro` | marais ouvert, Mado rencontrée |
| Trois indices | trouver les indices | trois Scenes d'indice | trois Facts distincts |
| Rapport à Soline | rapport / ouverture fusionnés | `scene_soline_unlock_passage` | indices réunis, passage ouvert |
| Arrivée au phare | atteindre le phare | `scene_lighthouse_arrival` | phare atteint |
| Ascension | monter dans le phare | note + deux gardiens | note, gardiens, sommet ouvert |
| Final | confrontation finale | boss + dissipation | Pokémon apaisé, brume résolue |
| Épilogue | retour + complétion | `scene_ending_port` | épilogue et histoire terminés |
| Cristaux de sel | quatre Steps optionnelles | Mado + trois cristaux + retour | quête terminée, Super Potion |
| Goélise du port | cinq Steps optionnelles | pêcheur + choix + deux retours | choix gardé/rendu, argent ou perle |
| Cabane du phare | cinq Steps optionnelles | Yvon + clé + carnet | clé, ouverture, carnet, Super Bonbon |

Toutes les Scenes de la matrice possèdent une définition Event active. Les
trois storylines secondaires n'exposent que la relation
`sideQuestAvailableDuring`; la storyline principale ne requiert aucune quête
secondaire.

## Fichiers modifiés et zones précises

| Fichier | Zone | Raison et impact |
|---|---|---|
| `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart` | `_linearScene`, `_lysaToneBattleScene`, `_battleScene`, `_canonicalYarnFiles` | Persiste les politiques de fin et rend le contenu textuel fidèle au démonstrateur. |
| `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart` | `_expectSelbrumeSpecificationMatrix`, `_expectCanonicalOutcomePolicies` | Rend la couverture de la spécification et les garde-fous de terminalité exécutables. |
| `examples/playable_runtime_host/test/selbrume_canonical_narrative_campaign_test.dart` | campagne principale, routes Lysa, side quests, `_bagQuantity` | Prouve les effets réellement consommés par le runtime. Les imports étroits évitent de compiler une UI étrangère au test. |
| `selbrume/project.json` | nodes terminaux de `scene_lysa_port` | Snapshot régénéré : victoire `progression`, défaite `terminalFailureAccepted`. |
| `selbrume/dialogues/lysa_port.yarn` | `LysaPort`, `RivalAfterWin`, `RivalAfterLoss` | Ton, respect et convergence vers les marais clarifiés. |
| `selbrume/dialogues/lysa_after_loss.yarn` | `RivalAfterLoss` | La défaite reste non bloquante et donne la direction suivante. |
| `selbrume/dialogues/lighthouse.yarn` | note et confrontation finale | Le Lanturn est explicitement effrayé et piégé, non malveillant. |
| `selbrume/dialogues/ending_port.yarn` | épilogue | Réouverture du port, activité des pêcheurs et stabilité du passage. |
| `docs/superpowers/plans/2026-07-21-nsc-81-selbrume-canonical-campaign.md` | micro-plan complet | Trace RED/GREEN, scope et transfert du Validator à NSC-82. |

Diff fonctionnel condensé :

```text
SceneEndPayload(sceneOutcomeId: victory)
  -> SceneEndPayload(..., outcomePolicy: progression)
SceneEndPayload(sceneOutcomeId: defeat)
  -> retryable pour les gardiens/boss
  -> terminalFailureAccepted pour Lysa, car la campagne converge après la perte

Matrice testée :
  13 beats -> Storylines -> Steps -> Scenes -> Events actifs -> Facts
Runtime testé :
  Lysa victoire + Lysa défaite + 3 side quests + boss défaite + résolution
```

## Tests et analyses

### RED utile

```text
flutter test test/selbrume_canonical_narrative_seed_test.dart
Expected lysa.victory=progression / lysa.defeat=terminalFailureAccepted
Actual: both null
Result: 1 test failed
```

Une première tentative de faire porter aussi le Validator global par ce test a
retourné exactement deux erreurs `narrativeSolvabilityIndeterminate` : budget
global de 16 384 états dépassé, dont une avant l'Event se terminant par `019`.
Cette assertion coûteuse a été retirée de NSC-81 et devient un critère explicite
de NSC-82.

### GREEN ciblé

```text
cd packages/map_editor
dart run tool/seed_selbrume_canonical_narrative_content.dart --project-root ../../selbrume --check
Selbrume canonical narrative content is up to date.

flutter test test/selbrume_canonical_narrative_seed_test.dart
00:01 +1: All tests passed!

cd examples/playable_runtime_host
flutter test --no-pub test/selbrume_canonical_narrative_campaign_test.dart
00:00 +4: All tests passed!
```

### Analyse statique

```text
cd packages/map_editor
dart analyze tool/seed_selbrume_canonical_narrative_content.dart test/selbrume_canonical_narrative_seed_test.dart
No issues found!

cd examples/playable_runtime_host
dart analyze test/selbrume_canonical_narrative_campaign_test.dart
No issues found!
```

### Build

```text
cd examples/playable_runtime_host
flutter build macos --debug --no-pub
```

Résultat exact : **échec** dans le code préexistant
`packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart:1175` :

```text
Couldn't find constructor 'ScrollCacheExtent.pixels'.
No named parameter with the name 'scrollCacheExtent'.
Target kernel_snapshot_program failed: Exception
** BUILD FAILED **
```

Le lockfile exige Flutter `>=3.44.0`, le SDK local est Flutter 3.41.6. Aucun
lockfile modifié automatiquement n'a été conservé.

## Passes indépendantes imposées par codex_rule.md

| Passe nommée | Verdict |
|---|---|
| Audit / Architecture | PASS — le seeder reste l'unique source automatisée du snapshot ; aucune règle runtime n'est cachée dans l'UI. |
| Implémentation | PASS — diff limité au contenu canonique, aux politiques de fin et aux preuves. |
| Tests | PASS ciblé — positif, négatif, choix, retry et non-régression optionnelle couverts. |
| Build / Validation | PARTIAL — tests/analyse verts ; build global bloqué par le SDK Flutter local antérieur au lockfile. |
| Critique finale | PASS avec réserve — aucune modification accidentelle de lockfile ; le budget symbolique global demeure un risque réel pour NSC-82. |

Les vrais sub-agents n'ont pas été utilisés : l'instruction d'orchestration
active interdit leur création sans demande explicite de l'utilisateur. Les cinq
passes manuelles nommées ci-dessus appliquent le fallback prévu par
`codex_rule.md`.

## Contenu complet du fichier créé de plan

`docs/superpowers/plans/2026-07-21-nsc-81-selbrume-canonical-campaign.md` :

```markdown
# NSC-81 Selbrume Canonical Campaign Implementation Plan

**Goal:** Prouver que chaque beat de `MVP Selbrume/selbrume.md` est représenté
par une donnée canonique réellement authorable, persistée, validée et consommée
par le runtime, ou documenter précisément l'écart restant.

**Architecture:** Le seeder reste l'automatisation reproductible du snapshot
promu et le harness NSC-80 reste la preuve du workflow humain. Une matrice typée
dans le test du seed relie les beats de spécification à leurs assets physiques
et narratifs. Le test host exécute les convergences principales et secondaires.

## Task 1 — Baseline et drift du snapshot

- [x] Lancer le seeder en `--check` et consigner tout drift.
- [x] Régénérer `selbrume/project.json` et les Yarn uniquement via le seeder.
- [x] Inspecter le diff ; refuser toute modification hors campagne canonique.

## Task 2 — Matrice de couverture exécutable

- [x] Ajouter au test du seed une matrice des 12 Steps principales et des trois
  quêtes secondaires.
- [x] Pour chaque ligne, vérifier Storyline, Scene, Event actif, source physique,
  Facts/Rules et fichiers Yarn nécessaires.
- [x] Vérifier que les side quests ne sont pas requises par la progression
  principale et que victoire/défaite Lysa convergent.
- [x] Vérifier les diagnostics de domaine dans le test du seed ; réserver le
  verdict global, sa persistance et son budget symbolique à NSC-82.

## Task 3 — Polish narratif ciblé

- [x] Renforcer les quatre Yarn imposés par la roadmap : ton Lysa, défaite non
  bloquante, explication du boss non malveillant, épilogue/world state.
- [x] Mettre à jour la source `_canonicalYarnFiles`, jamais les fichiers promus
  seuls.
- [x] Conserver les outcomes déclarés et les nodes attendus par les Scenes.

## Task 4 — Preuve runtime campagne

- [x] Étendre `selbrume_canonical_narrative_campaign_test.dart` avec victoire et
  défaite Lysa, les trois quêtes secondaires et l'épilogue.
- [x] Prouver Facts, Step completion, World Rules projetées et récompenses sans
  simuler une donnée ignorée par le runtime.
- [x] Produire la matrice lisible dans
  `reports/gameplay/fg_selbrume_narrative_campaign_authoring_evidence.md`.

## Task 5 — Gate et commit

- [x] Seeder `--check`, tests Editor/Host ciblés et analyses ; le Validator CLI
  avec receipt/reload appartient au lot NSC-82 suivant.
- [x] Consigner le build disponible et les limites mécaniques hors NSC-81.
- [x] Commit isolé : `feat(narrative): complete Selbrume canonical campaign`.
```

Le présent Evidence Pack est le second fichier créé et son contenu complet est
celui de cet artefact versionné.

## État Git final avant commit

Le diff attendu contient exclusivement les neuf fichiers fonctionnels listés
ci-dessus, ce micro-plan ignoré ajouté explicitement et le présent Evidence
Pack. `git diff --check` ne retourne aucune erreur. Après le commit de lot,
l'arbre doit être propre avant NSC-82.

## Auto-critique et risques restants

- Le test de campagne appelle directement l'exécuteur de Scene ; il ne prouve
  pas encore la sélection Event complète après reload. NSC-82 doit le faire.
- La route « rendre l'objet » du Goélise est couverte structurellement tandis
  que le scénario runtime ajouté exerce la route « garder ». La régression
  existante vérifie déjà la récompense argent de l'autre branche, mais NSC-82
  pourra traverser les deux runs persistés.
- Le Validator global est honnêtement rouge/indéterminé à cause de son budget,
  même si les diagnostics de domaine du seed sont verts.
- Le build nécessite le SDK Flutter déclaré par le lockfile ou une décision
  séparée de compatibilité ; ce lot ne doit pas modifier une UI sans rapport.

Prochaine étape autorisée par la phase : `NSC-82 — E2E
persistence/runtime/validator/retry`.
