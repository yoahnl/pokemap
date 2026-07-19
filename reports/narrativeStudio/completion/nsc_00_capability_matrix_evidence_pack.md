# NSC-00 — Evidence Pack de la matrice de capacités

Date : 2026-07-19
Lot : `NSC-00 — Matrice de capacités et contrat d'acceptation`
Branche : `main`
HEAD initial : `a8095b37`
Verdict : `PASS`

## Résultat

La source de vérité des capacités du Narrative Studio est désormais
`reports/narrativeStudio/completion/ns_completion_capability_matrix.md`.
Elle inventorie 54 capacités et sépare explicitement schema, authoring,
persistence, validation, preview et runtime. Chaque cellule incomplète possède
un propriétaire NSC unique et chaque capacité renvoie vers une preuve fichier
ou test.

Le contrat du MVP Selbrume reste distinct de celui du Narrative Studio v1.
Le réaudit de readiness du 19 juillet n'a pas été modifié : NSC-00 est un lot
documentaire et n'apporte aucune nouvelle preuve runtime.

## Audit initial

- l'ancienne matrice FG-000 mélangeait état Selbrume daté, disponibilité du
  moteur, authoring, qualité de démonstration et ordre de correction ;
- elle conservait des pourcentages et un `GATE ROUGE` antérieurs au réaudit
  post-correction du 19 juillet ;
- aucune matrice canonique ne couvrait séparément les six dimensions d'une
  capacité ;
- les décisions sur scripts, audio/FX, branches et cinématiques n'étaient pas
  figées dans le contrat de complétion ;
- les charges de gros projet n'avaient ni fixture déterministe ni protocole de
  mesure commun.

## Décisions et non-objectifs

- Les seuls états autorisés sont `Supported`, `Partial`,
  `Rejected by design` et `Legacy`.
- `Supported` exige un contrat et une preuve citée ; il ne signifie pas que
  NSC-00 a relancé la suite correspondante.
- Le script/JSON arbitraire est rejeté ; les extensions passent par des
  commandes typées enregistrées.
- Les cinématiques restent linéaires ; le branchement appartient aux Scenes.
- Audio, musique et FX ne sont publiables qu'avec résolution, preview et sink
  runtime explicites.
- Aucun seuil temporel n'est inventé avant une première baseline reproductible.
- Aucun code, schema, fixture, test ou statut FG n'est changé par ce lot.

## Fichiers modifiés

### Créés

- `reports/narrativeStudio/completion/ns_completion_capability_matrix.md` :
  document canonique complet, 54 lignes de capacité, catalogue de preuves,
  contrats d'acceptation, décisions et budgets.
- `reports/narrativeStudio/completion/nsc_00_capability_matrix_evidence_pack.md` :
  le présent rapport de clôture.

Le contenu complet de la matrice créée est reproduit en annexe A. Le présent
Evidence Pack constitue lui-même le contenu complet du second fichier créé.
Aucun contenu généré, binaire ou externe n'est requis pour les lire. Les deux
fichiers sont destinés au commit isolé NSC-00 ; ils ne sont pas décrits comme
suivis avant la réussite de cette opération Git.

### Modifié

- `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` :
  remplacement de l'ancienne matrice datée par un index secondaire court vers
  la matrice canonique et le réaudit courant ; conservation des limites
  Selbrume qui ne doivent pas être perdues.

### Délibérément inchangé

- `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md` :
  SHA-256 observé avant clôture
  `28062fc868426e761919aca96a14afc5e54aba0fcce9192d8da654029f16fb0c`.

## Zones précises modifiées

| Fichier | Zone | Effet |
|---|---|---|
| `ns_completion_capability_matrix.md` | sections 1–3 | vocabulaire, 54 capacités et catalogue de preuves |
| `ns_completion_capability_matrix.md` | section 4 | critères MVP Selbrume et Studio v1 séparés |
| `ns_completion_capability_matrix.md` | section 5 | décisions scripts, audio/FX, branches, cinématiques |
| `ns_completion_capability_matrix.md` | section 6 | fixture et protocole gros projet reproductibles |
| `fg_000_narrative_studio_selbrume_capability_matrix.md` | document complet | conversion en index de compatibilité secondaire |

## Passes indépendantes

| Passe | Verdict | Preuve |
|---|---|---|
| Audit / Architecture | `PASS` | séparation source canonique, index secondaire et réaudit |
| Implémentation documentaire | `PASS` | 54 capacités et propriétaires NSC présents |
| Tests de contrat | `PASS` | compte exact, chemins de preuve et états contrôlés |
| Build / Validation | `N/A` | aucun code ni dépendance modifié |
| Revue de spécification | `PASS` | critères NSC-00 relus indépendamment |
| Revue qualité / critique | `NEEDS_CHANGES` puis `PASS` après correction | roadmap ignorée retirée des sources normatives ; métadonnées converties en tables ; colonne renommée ; échelle CI-10/11 redescendue en `Partial → NSC-74` ; formulation du réaudit rendue vérifiable ; Evidence Pack ajouté |

## Commandes et résultats exacts

### État Git initial

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

Ces changements préexistants restent hors du commit NSC-00. Le test lighthouse
pré-stagé reste pré-stagé et non commité.

### Contrôle de la matrice

Commande exacte (exécutée depuis la racine avec `bash`, les variables étant
définies sur les trois chemins du lot) :

```bash
count=$(rg '^\| (ST|SC|DG|EV|FA|WR|VA|CI)-[0-9]{2} ' "$matrix" | wc -l | tr -d ' ')
test "$count" = 54
while IFS= read -r proof_file; do
  test -e "$proof_file" || exit 1
done < <(sed -n '/^## 3\. Catalogue de preuves/,/^## 4\./p' "$matrix" | rg -o '`[^`]+`' | tr -d '`' | rg '/')
for evidence_line in $(sed -n '/^## 3\. Catalogue de preuves/,/^## 4\./p' "$matrix" | rg '^\| E-' | cut -d'|' -f2 | tr -d ' '); do
  rg -q "^\\| ${evidence_line} .*test/" "$matrix" || exit 1
done
test "$(shasum -a 256 reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md | cut -d' ' -f1)" = 28062fc868426e761919aca96a14afc5e54aba0fcce9192d8da654029f16fb0c
git diff --check -- "$index"
git diff --no-index --check /dev/null "$matrix" >/dev/null || test $? = 1
git diff --no-index --check /dev/null "$pack" >/dev/null || test $? = 1
```

```text
CAPABILITY_COUNT=54
PROOF_PATHS=present
ALL_PROOF_PATHS_WITH_SPACES=present
DIFF_CHECK=pass
```

La revue a également contrôlé que les 54 lignes se répartissent en 6 ST,
13 SC, 4 DG, 8 EV, 6 FA/WR, 6 VA et 11 CI, et qu'aucun identifiant de lot
propriétaire n'est orphelin.

### Profil de référence constaté

```text
Model Identifier: MacBookPro18,3
Total Number of Cores: 10 (8 Performance and 2 Efficiency)
Memory: 32 GB
System Version: macOS 27.0 (26A5378j)
Dart SDK version: 3.12.1 (stable) on macos_arm64
Flutter 3.46.0-0.3.pre, channel beta
```

### Tests et build

Non exécutés pour NSC-00 : le lot ne modifie ni code, ni dépendance, ni
fixture. Relancer les suites produit aurait constitué une preuve sans rapport
avec la validité documentaire de cette matrice.

### État Git final avant commit isolé

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
?? reports/narrativeStudio/completion/ns_completion_capability_matrix.md
?? reports/narrativeStudio/completion/nsc_00_capability_matrix_evidence_pack.md
```

Commande exacte :

```bash
git status --short --untracked-files=all
```

Le commit est effectué avec `git commit --only` sur les trois chemins du lot.
L'état final post-commit et l'identifiant du commit sont contrôlés et rapportés
par l'agent principal ; ils ne peuvent pas être prédits honnêtement dans le
contenu pré-commit.

## Auto-critique et risques

- Une preuve citée peut expirer ; la règle de maintenance impose alors de
  redescendre la cellule en `Partial`.
- Les références `E-*` prouvent l'existence d'un contrat et d'un test ciblé,
  pas une exécution fraîche de toutes les suites pendant ce lot documentaire.
- Les seuils de performance sont volontairement absents tant que NSC-74 n'a
  pas produit une baseline répétable ; ce n'est pas une promesse de vitesse.
- La matrice est exhaustive au regard des specs et du dépôt observés le
  19 juillet, mais chaque nouveau type de référence devra étendre NSC-01 et la
  matrice dans le même lot.
- Le verdict `PASS` clôt uniquement NSC-00. Il ne requalifie ni Selbrume, ni
  FG-185, ni la complétude fonctionnelle du Narrative Studio.

## Statut proposé

`NSC-00 : DONE` — source canonique, preuves, propriétaires et contrats
d'acceptation sont présents ; aucune capacité produit n'est déclarée terminée
par transitivité.

## Annexe A — contenu complet du fichier créé

`reports/narrativeStudio/completion/ns_completion_capability_matrix.md` :

````markdown
# NSC-00 — Narrative Studio completion capability matrix

| Métadonnée | Valeur |
|---|---|
| Date de référence | 2026-07-19 |
| Lot | `NSC-00 — Matrice de capacités et contrat d'acceptation` |
| Autorité | Source primaire destinée au commit isolé NSC-00 |
| Sources normatives suivies | `MVP Selbrume/narrative_studio.md` et `MVP Selbrume/selbrume.md` |
| Entrée de planification locale | `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md` (ignorée par Git, donc non normative à elle seule) |
| État Selbrume observé | `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md` |

## 1. Contrat de lecture

Les colonnes de capacité n’emploient que quatre états :

| État | Sens exact |
|---|---|
| `Supported` | Le dépôt contient un contrat et une preuve fichier/test pour cette dimension. |
| `Partial` | Une tranche existe, mais la cible décrite n’est pas fermée. Chaque cellule est affectée à un lot NSC unique. |
| `Rejected by design` | La capacité est volontairement exclue du modèle canonique. |
| `Legacy` | La capacité n’existe que pour lire, migrer ou caractériser un ancien contrat ; ce n’est pas le chemin d’authoring cible. |

`Supported` décrit une capacité prouvée par les fichiers cités, pas un résultat de tests relancé par NSC-00. Ce lot est documentaire ; ses contrôles frais portent sur la cohérence Markdown et le diff. Une ligne ne peut devenir plus favorable que sa preuve la plus précise.

Dans la colonne « Propriétaire du manque ou de la migration », chaque dimension incomplète pointe vers un seul lot. Un lot ultérieur peut dépendre de ce propriétaire, mais ne devient pas un second propriétaire du même manque. Une ligne `Legacy` y indique le propriétaire de sa migration explicite.

Chaque référence `E-*` citée par une cellule `Supported` associe le contrat à
au moins un test de preuve dans le catalogue de la section 3. Elle prouve
l'existence auditable de la capacité, pas un run frais de toutes les suites au
moment de NSC-00. La fraîcheur d'exécution appartient aux Evidence Packs des
lots fonctionnels et aux gates finales.

## 2. Matrice canonique

### 2.1 Storylines, Chapters et Steps

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| ST-01 | Storyline canonique : types, statut, métadonnées | Supported | Partial | Supported | Supported | Supported | Rejected by design | E-ST-01 | Authoring → NSC-20 |
| ST-02 | `GlobalStory` comme vérité d’authoring | Legacy | Legacy | Legacy | Legacy | Legacy | Legacy | E-LEG-01 | Retrait/migration → NSC-20 |
| ST-03 | Chapter : structure, ordre et métadonnées | Supported | Partial | Supported | Supported | Supported | Rejected by design | E-ST-01 | Authoring → NSC-21 |
| ST-04 | Step : structure, liens Scene et complétion | Supported | Partial | Supported | Supported | Supported | Supported | E-ST-01, E-SC-03 | Authoring → NSC-21 |
| ST-05 | Sémantique de progression : relations, conditions et effets d’outcome | Supported | Partial | Supported | Partial | Partial | Partial | E-ST-02 | Authoring/Validation/Preview/Runtime → NSC-22 |
| ST-06 | Graph Storyline interactif dérivé, sans logique parallèle | Rejected by design | Partial | Rejected by design | Supported | Supported | Rejected by design | E-ST-02 | Authoring → NSC-23 |

### 2.2 Scenes, nœuds et conséquences

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| SC-01 | Scenes Library : cycle de vie, recherche et suppression sûre | Supported | Partial | Supported | Supported | Supported | Rejected by design | E-SC-01 | Authoring → NSC-30 |
| SC-02 | Nœuds `Start`, `End` et `Merge` | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-01, E-SC-02 | — |
| SC-03 | Nœud Dialogue et ports d’outcomes déclarés | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-01, E-DG-01 | — |
| SC-04 | Nœud Battle et ports `victory`/`defeat` | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-01, E-SC-02 | — |
| SC-05 | Nœud Cinematic et reprise sur `completed` | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-01, E-CI-02 | — |
| SC-06 | Condition V1 : Fact, story flag, Step completed, Event consommé | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-01, E-SC-02 | — |
| SC-07 | Catalogue complet des Conditions Scene | Supported | Partial | Supported | Partial | Partial | Partial | E-SC-01 | Authoring/Validation/Preview/Runtime → NSC-33 |
| SC-08 | Conséquences `setFact` et `markEventConsumed` | Supported | Supported | Supported | Supported | Supported | Supported | E-SC-03 | — |
| SC-09 | Conséquence `completeStoryStep` dans le picker no-code | Supported | Partial | Supported | Supported | Partial | Supported | E-SC-03 | Authoring/Preview → NSC-33 |
| SC-10 | Récompenses typées : item, argent, Pokémon, starter | Supported | Supported | Supported | Supported | Partial | Supported | E-SC-03 | Preview avant/après → NSC-33 |
| SC-11 | `BranchByOutcome`, convergence et `End` terminal | Supported | Partial | Supported | Partial | Partial | Partial | E-SC-01, E-SC-02 | Authoring/Validation/Preview/Runtime → NSC-32 |
| SC-12 | Script arbitraire ou JSON libre dans une Scene | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | E-DEC-01 | — |
| SC-13 | Registre de commandes narratives typées | Partial | Partial | Partial | Partial | Partial | Partial | E-SC-03, E-DEC-01 | Toutes dimensions → NSC-37 |

### 2.3 Dialogues et outcomes

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| DG-01 | Document Yarn multi-nœuds et codec lossless | Supported | Partial | Supported | Partial | Supported | Supported | E-DG-01 | Authoring/Validation → NSC-34 |
| DG-02 | Outcome Yarn stable vers port Scene | Supported | Supported | Supported | Supported | Supported | Supported | E-DG-01 | — |
| DG-03 | Renommage/suppression d’outcome avec protection des Scenes | Supported | Partial | Supported | Partial | Partial | Supported | E-DG-01 | Authoring/Validation/Preview → NSC-35 |
| DG-04 | Session Dialogue complète : preview, save, reload, undo/recovery | Supported | Partial | Partial | Supported | Partial | Supported | E-DG-01 | Authoring/Persistence/Preview → NSC-36 |

### 2.4 Events

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| EV-01 | Sources `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` | Supported | Supported | Supported | Supported | Supported | Supported | E-EV-01 | — |
| EV-02 | Sélection guidée d’une source physique réelle et retour Map Editor | Supported | Partial | Supported | Partial | Partial | Supported | E-EV-01 | Authoring/Validation/Preview → NSC-41 |
| EV-03 | Conditions V1 booléennes AND : Fact et Event consommé | Supported | Supported | Supported | Supported | Supported | Supported | E-EV-02 | — |
| EV-04 | Expressions `all/any/not` et réarmement qualifié | Partial | Partial | Partial | Partial | Partial | Partial | E-EV-02 | Toutes dimensions → NSC-43 |
| EV-05 | Politiques `oneShot`/`reusable`, priorité, ordre et dispatch fail-closed | Supported | Supported | Supported | Supported | Supported | Supported | E-EV-02, E-SEL-01 | — |
| EV-06 | Cycle draft/configured/enabled, rename, clone, delete, publish/unpublish | Supported | Partial | Partial | Supported | Partial | Supported | E-EV-02 | Authoring/Persistence/Preview → NSC-40 |
| EV-07 | Map Events View exhaustive par map | Supported | Partial | Rejected by design | Partial | Partial | Rejected by design | E-EV-01 | Authoring/Validation/Preview → NSC-44 |
| EV-08 | `MapEventDefinition` et dual-read Event historiques | Legacy | Legacy | Legacy | Legacy | Legacy | Legacy | E-LEG-02 | Migration Event → NSC-45 |

### 2.5 Facts et World Rules

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| FA-01 | Fact booléen : définition, valeur par défaut et override runtime | Supported | Supported | Supported | Supported | Supported | Supported | E-FA-01 | — |
| FA-02 | Cycle de vie Fact et suppression avec tous les consommateurs | Supported | Partial | Supported | Partial | Partial | Supported | E-FA-01 | Authoring/Validation/Preview → NSC-50 |
| FA-03 | Facts typés `bool/int/string` et opérateurs compatibles | Partial | Partial | Partial | Partial | Partial | Partial | E-FA-01 | Toutes dimensions → NSC-51 |
| WR-01 | World Rule V1 : visibilité, dialogue et Map Event legacy | Supported | Supported | Supported | Supported | Supported | Supported | E-WR-01 | — |
| WR-02 | Registry projet entier et target Event V2 distincte | Partial | Partial | Supported | Partial | Partial | Partial | E-WR-01 | Schema/Authoring/Validation/Preview/Runtime → NSC-52 |
| WR-03 | Simulation explicable d’un état du monde | Supported | Partial | Rejected by design | Partial | Partial | Partial | E-WR-01 | Authoring/Validation/Preview/Runtime → NSC-53 |

### 2.6 Validator

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| VA-01 | Diagnostics structurels locaux : références, graphes, Facts, Rules | Supported | Supported | Rejected by design | Supported | Supported | Rejected by design | E-VA-01 | — |
| VA-02 | Solvabilité symbolique corrélée avec `pass/fail/indeterminate` | Partial | Rejected by design | Rejected by design | Partial | Partial | Rejected by design | E-VA-01 | Schema/Validation/Preview → NSC-54 |
| VA-03 | Terminalité, défaite et politique de retry déclarée | Partial | Partial | Partial | Partial | Partial | Partial | E-SEL-01 | Toutes dimensions → NSC-55 |
| VA-04 | Atteignabilité physique fondée sur `map_gameplay` | Partial | Rejected by design | Rejected by design | Partial | Partial | Partial | E-VA-01 | Schema/Validation/Preview/Runtime → NSC-56 |
| VA-05 | Rapport quatre dimensions et receipt runtime frais | Partial | Rejected by design | Partial | Partial | Partial | Partial | E-VA-01, E-SEL-01 | Schema/Persistence/Validation/Preview/Runtime → NSC-57 |
| VA-06 | UX actionnable, suppressions traçables et export CI | Partial | Partial | Partial | Partial | Partial | Rejected by design | E-VA-01 | Schema/Authoring/Persistence/Validation/Preview → NSC-58 |

### 2.7 Cinematics et commandes

| ID | Capacité | Schema | Authoring | Persistence | Validation | Preview | Runtime | Preuve | Propriétaire du manque ou de la migration |
|---|---|---|---|---|---|---|---|---|---|
| CI-01 | Cinematic linéaire, stage, acteurs, bindings et timeline | Supported | Supported | Supported | Supported | Supported | Supported | E-CI-01, E-CI-02 | — |
| CI-02 | Branche ou mutation de progression dans une Cinematic | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | E-CI-01, E-DEC-01 | — |
| CI-03 | `wait`, caméra, move, face, emote et fade | Supported | Supported | Supported | Supported | Supported | Supported | E-CI-01, E-CI-02 | — |
| CI-04 | `dialogueLine` et `shake` configurables de bout en bout | Supported | Partial | Supported | Supported | Partial | Supported | E-CI-01, E-CI-02 | Authoring/Preview → NSC-66 |
| CI-05 | Catalogue projet Media/FX et ports neutres de playback | Partial | Partial | Partial | Partial | Partial | Partial | E-CI-01 | Toutes dimensions → NSC-65 |
| CI-06 | `sound`, `music` et `fx` publiables | Supported | Partial | Supported | Partial | Partial | Partial | E-CI-01, E-CI-02 | Authoring/Validation → NSC-66 ; Preview/Runtime → NSC-67 |
| CI-07 | `marker` comme métadonnée de storyboard/timeline | Supported | Supported | Supported | Supported | Supported | Rejected by design | E-CI-01, E-DEC-01 | — |
| CI-08 | Script arbitraire dans une Cinematic | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | Rejected by design | E-DEC-01 | — |
| CI-09 | Commande Cinematic scriptée mais typée et enregistrée | Partial | Partial | Partial | Partial | Partial | Partial | E-DEC-01 | Toutes dimensions → NSC-66 |
| CI-10 | Cinematics Library à l'échelle de 1 000 assets | Partial | Partial | Partial | Partial | Partial | Rejected by design | E-CI-01 | Schema/Authoring/Persistence/Validation/Preview à l'échelle → NSC-74 |
| CI-11 | Timeline à l'échelle de 1 000 blocs | Partial | Partial | Partial | Partial | Partial | Rejected by design | E-CI-01 | Schema/Authoring/Persistence/Validation/Preview à l'échelle → NSC-74 |

## 3. Catalogue de preuves

| Référence | Fichiers de contrat et tests de preuve |
|---|---|
| E-ST-01 | `packages/map_core/lib/src/models/storyline_asset.dart`; `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart`; `packages/map_core/test/storyline_asset_test.dart`; `packages/map_core/test/storyline_asset_json_test.dart`; `packages/map_core/test/storyline_authoring_operations_test.dart`; `packages/map_editor/test/storylines_workspace_shell_test.dart` |
| E-ST-02 | `packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart`; `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`; `packages/map_core/test/storyline_scene_link_diagnostics_test.dart`; `packages/map_editor/test/storylines_workspace_scene_links_test.dart` |
| E-SC-01 | `packages/map_core/lib/src/models/scene_asset.dart`; `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`; `packages/map_core/test/scene_asset_test.dart`; `packages/map_core/test/scene_authoring_operations_test.dart`; `packages/map_editor/test/scenes_workspace_shell_test.dart` |
| E-SC-02 | `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`; `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`; `packages/map_core/test/scene_runtime_plan_test.dart`; `packages/map_core/test/scene_runtime_executor_test.dart`; `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` |
| E-SC-03 | `packages/map_core/lib/src/models/scene_consequence.dart`; `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`; `packages/map_core/test/scene_consequence_model_test.dart`; `packages/map_editor/test/scenes_workspace_shell_test.dart`; `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`; `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart` |
| E-DG-01 | `packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart`; `packages/map_core/lib/src/operations/project_dialogue_refs.dart`; `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`; `packages/map_editor/test/dialogue_yarn_codec_test.dart`; `packages/map_editor/test/dialogue_preview_runner_test.dart`; `packages/map_core/test/project_dialogue_declared_outcomes_test.dart`; `packages/map_runtime/test/playable_map_game_dialogue_outcome_scene_integration_test.dart` |
| E-EV-01 | `packages/map_core/lib/src/models/narrative_event_source_ref.dart`; `packages/map_core/lib/src/operations/build_narrative_spatial_event_source_catalog.dart`; `packages/map_core/test/narrative_event_source_ref_test.dart`; `packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart`; `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart` |
| E-EV-02 | `packages/map_core/lib/src/models/narrative_event_definition.dart`; `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart`; `packages/map_core/test/narrative_event_configuration_authoring_test.dart`; `packages/map_core/test/narrative_event_publication_test.dart`; `packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart`; `packages/map_runtime/test/narrative_event_progress_save_load_test.dart` |
| E-FA-01 | `packages/map_core/lib/src/models/narrative_fact.dart`; `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`; `packages/map_core/test/narrative_fact_authoring_operations_test.dart`; `packages/map_core/test/narrative_fact_runtime_state_test.dart`; `packages/map_editor/test/facts_world_rules_manager_test.dart`; `packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart` |
| E-WR-01 | `packages/map_core/lib/src/models/world_rule.dart`; `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart`; `packages/map_core/lib/src/projection/world_rule_projection.dart`; `packages/map_core/test/world_rule_authoring_operations_test.dart`; `packages/map_core/test/world_rule_projection_test.dart`; `packages/map_editor/test/facts_world_rules_manager_test.dart`; `packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart` |
| E-VA-01 | `packages/map_core/lib/src/operations/narrative_project_validator.dart`; `packages/map_core/lib/src/validation/beta_playability_validator.dart`; `packages/map_core/test/narrative_project_validator_test.dart`; `packages/map_editor/test/narrative_validator_workspace_test.dart`; `packages/map_editor/test/selbrume_narrative_validator_test.dart` |
| E-CI-01 | `packages/map_core/lib/src/models/cinematic_asset.dart`; `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`; `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`; `packages/map_core/test/cinematic_asset_test.dart`; `packages/map_core/test/cinematic_authoring_operations_test.dart`; `packages/map_editor/test/cinematic_builder_workspace_test.dart` |
| E-CI-02 | `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart`; `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart`; `packages/map_runtime/test/cinematic_runtime_playback_controller_test.dart`; `packages/map_runtime/test/flame_cinematic_runtime_playback_sink_test.dart`; `packages/map_runtime/test/playable_map_game_cinematic_runtime_integration_test.dart` |
| E-SEL-01 | `reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md`; `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart`; `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`; `packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart`; `packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart` |
| E-LEG-01 | `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`; `packages/map_core/test/storyline_legacy_import_preview_test.dart`; `packages/map_editor/test/storylines_current_global_story_characterization_test.dart` |
| E-LEG-02 | `packages/map_core/lib/src/compatibility/narrative_event_migration_planner_impl.dart`; `packages/map_core/test/narrative_event_migration_integrity_closure_test.dart`; `packages/map_runtime/test/narrative_event_legacy_runtime_characterization_test.dart` |
| E-DEC-01 | `MVP Selbrume/narrative_studio.md` sections 8–10, 21 et 22; `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md` section 5; `packages/map_core/test/cinematic_asset_test.dart` (linéarité et rejet des branches/gameplay) |

## 4. Contrats d’acceptation séparés

### 4.1 MVP fonctionnel Selbrume

Le MVP Selbrume est une preuve ciblée du mini-jeu, pas la déclaration de complétude du Studio. Il est accepté seulement si les éléments suivants sont reproduits sur le projet promu :

1. Les 12 Steps principales, les trois Storylines secondaires et leurs assets canoniques sont représentés sans commentaire substitutif ; la fidélité finale appartient à NSC-81.
2. Un auteur reconstruit Storyline, Chapters, Steps, Dialogues, Scenes, Cinematics, Events, Facts et World Rules depuis les workflows publics, sans édition manuelle de JSON ; le harness appartient à NSC-80.
3. Au moins une chaîne réelle couvre source map → Event → Dialogue outcome → branche Scene → Cinematic → Combat → conséquence → Fact/Step → World Rule. Les manques sont détenus par les lignes SC-11, SC-13 et CI-06.
4. Victoire, défaite, retry, sauvegarde/reprise et absence de double effet sont prouvés sur la matrice Selbrume ; la fermeture exhaustive appartient à NSC-82. La preuve actuelle reste explicitement limitée : pas de defeat→retry physique dédié pour le gardien 2, pas de sauvegarde disque entre défaite réelle et retry, pas de walkthrough humain.
5. Le Validator ne transforme ni une dimension non exécutée ni un budget dépassé en réussite ; les propriétaires sont VA-02 à VA-06.
6. Le binaire et le projet packagé passent un walkthrough humain documenté ; la QA et le release gate appartiennent à NSC-83.

Audio, musique et FX ne bloquent pas le MVP fonctionnel si aucune commande correspondante n’est publiée. Dès qu’une telle commande est publiée, CI-05/CI-06 deviennent obligatoires : aucun silence runtime n’est accepté.

### 4.2 Narrative Studio v1

Narrative Studio v1 exige davantage que Selbrume :

1. Toutes les cellules de cette matrice sont `Supported` ou `Rejected by design`; aucune cellule `Partial` ne reste ouverte.
2. Aucun chemin d’authoring normal ne reste `Legacy`; la lecture de compatibilité peut subsister seulement avec migration visible, réversible et testée.
3. Les suppressions et remplacements passent par l’index de dépendances NSC-01 et les mutations atomiques NSC-02.
4. Toutes les références normales utilisent des pickers lisibles ; aucun ID ou JSON manuel n’est requis.
5. Preview, persistance après fermeture/reload et runtime consomment le même contrat publié.
6. Le Validator expose séparément structure, solvabilité narrative, atteignabilité physique et receipt runtime frais.
7. Les commandes Cinematic publiables, y compris audio/musique/FX, ont parité preview/runtime et rollback.
8. Accessibilité, localisation, recovery et budgets gros projet sont prouvés avant la gate NSC-83.

### 4.3 Profil de preuve runtime accepté

Le profil réservé `selbrume-release-v1` doit enregistrer le fingerprint complet du projet et l’exécution des suites suivantes, identifiées par leur chemin relatif :

- `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart`;
- `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart`;
- `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart`;
- `packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart`;
- `packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart`;
- `packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart`;
- `packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart`.

Un sous-ensemble, un fingerprint différent, une suite ignorée ou une fixture synthétique ne valide pas ce profil. Le transport et la fraîcheur du receipt appartiennent à NSC-57 ; la matrice finale de suites appartient à NSC-82.

## 5. Décisions figées

| Décision | État | Contrat | Propriétaire si extension |
|---|---|---|---|
| Script arbitraire/JSON comme échappatoire | Rejected by design | Les mutations persistantes utilisent `SceneConsequence`; les commandes interactives utilisent un registre typé. | NSC-37 |
| Commande scriptée enregistrée et typée | Partial | ID stable, paramètres validés, backend unique et erreur explicite si non exécutable. | NSC-37 pour Scene; NSC-66 pour Cinematic |
| Audio, musique et FX publiés sans contrat media ni sink | Rejected by design | Draft lisible possible; publication bloquée jusqu’à résolution, preview et runtime. | NSC-65, puis NSC-66, puis NSC-67 |
| Branche narrative dans une Scene | Partial | `BranchByOutcome` lit un outcome qualifié; Merge converge; End émet le résultat final. | NSC-32 |
| Branche dans une Cinematic | Rejected by design | La Scene choisit une Cinematic; la Cinematic reste linéaire. | — |
| `marker` envoyé au sink runtime | Rejected by design | Métadonnée de navigation/storyboard uniquement. | — |

## 6. Fixtures et budgets gros projet

### 6.1 Machine et protocole de référence

Profil constaté pendant NSC-00 : MacBookPro18,3, Apple M1 Pro, 10 CPU logiques, 32 Gio, arm64, macOS 27.0 build 26A5378j. Outils constatés : Dart standalone 3.12.1; Flutter 3.46.0-0.3.pre beta avec Dart 3.13.0-167.1.beta. Chaque Evidence Pack de performance doit réimprimer ces champs ou déclarer un nouveau profil, ainsi que commit, mode JIT/AOT, build debug/profile/release, nombre de warmups/itérations et exécution séquentielle. Les suites Flutter concurrentes sont interdites pour une baseline.

Fixture déterministe commune : `large_narrative_project_v1`, seed textuel `pokemap-nsc-large-v1`, IDs et ordre stables, aucun accès réseau, checksum du résultat imprimé. Sa génération appartient à NSC-74; elle ne doit pas être un JSON massif maintenu à la main.

| Surface | Charge figée | Mode | Métriques obligatoires | Budget d’acceptation | Propriétaire |
|---|---|---|---|---|---|
| Index de dépendances | 10 000 entrées narratives indexables et une mutation locale | `dart test`, JIT, séquentiel | build complet et mutation locale : p50/p95 µs, usages produits, checksum, nœuds recalculés | Résultat déterministe; la mutation ne recalcule que ses dépendances. Limite temporelle chiffrée gelée après première baseline acceptée. | NSC-74 |
| Recherche globale | 10 000 entrées, labels identiques, accents et résultat stale | core JIT puis widget test Flutter debug | construction index, requêtes exactes/fuzzy et premier résultat visible : p50/p95 µs, checksum et ordre | Résultats stables et navigation exacte; limite temporelle gelée après baseline, jamais estimée dans ce document. | NSC-70 puis mesure NSC-74 |
| Validator | Même fixture, branches corrélées, cycles et une mutation locale | core/gameplay JIT, orchestration editor séquentielle | rapport complet/incrémental : p50/p95 µs, états explorés, recalculs, fingerprint | Rapport identique full/incrémental; budget dépassé produit `indeterminate`, jamais une réussite. Limite temporelle gelée après baseline. | NSC-54/57 puis mesure NSC-74 |
| Cinematics Library | 1 000 Cinematics canoniques | Flutter test debug, fenêtre et filtre fixés | chargement, filtre, tri, premier frame : p50/p95 µs, éléments rendus, checksum d’ordre | Aucun parcours séquentiel manuel requis; limite temporelle gelée depuis la baseline NSC-60/74. | NSC-62 puis mesure NSC-74 |
| Timeline | 1 Cinematic linéaire de 1 000 blocs, plus variantes 500/1 000 | core JIT puis widget test Flutter debug | layout, viewport initial, mutation locale, reorder et undo : p50/p95 µs, blocs recalculés, checksum | Ordre déterministe et mutation locale bornée; limite temporelle gelée après baseline NSC-60/74. | NSC-64 puis mesure NSC-74 |

Aucun seuil absolu de temps n’est inventé par NSC-00. Le premier run accepté produit la valeur numérique, le profil machine et la variance à versionner; avant cette baseline, une mesure est informative et ne ferme pas NSC-74. Le budget existant de `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart` reste une baseline Event V2 historique et n’est pas réutilisé silencieusement pour le Validator narratif complet.

## 7. Maintenance

- Tout lot qui ajoute une référence étend cette matrice, son test et l’index NSC-01 dans le même changement.
- Toute cellule `Supported` doit conserver au moins un fichier de contrat et un test dans le catalogue de preuves.
- Une preuve expirée redescend en `Partial`; elle n’est jamais conservée par inertie.
- `reports/gameplay/fg_000_narrative_studio_selbrume_capability_matrix.md` est un index de compatibilité secondaire et ne peut pas diverger de ce document.
- Le réaudit 2026-07-19 reste la source du verdict Selbrume courant. NSC-00 ne l'édite pas, faute de nouvelle preuve produit ; son SHA-256 est consigné dans l'Evidence Pack, car ce fichier était déjà non suivi et Git ne fournit pas de baseline antérieure.
````
