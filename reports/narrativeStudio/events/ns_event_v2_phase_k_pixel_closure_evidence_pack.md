# NS-EVENT-V2 Phase K — Pixel-Perfect Visual Closure Evidence Pack

> **Réconciliation finale K7 — 2026-07-17.** Cette section remplace K6 pour le
> statut, les résultats de revue et les commandes finales. K6 et les sections
> antérieures restent un audit trail, pas la vérité courante.

## K7.1 Verdict exact

- Verdict technique de la feature : **PASS**.
- Statut mission Phase K : **PLANNED** (`NOT STARTED` au tableau maître).
- Motif : la matrice K est verte et ne conserve aucun P0/P1 attribuable, mais
  les écarts P2 du chrome global ne peuvent être déclarés acceptés sans accord
  explicite de l’utilisateur.
- Décision release : **NO-GO**, gouvernée séparément par la campagne L.

La revue finale a refusé deux affirmations trop larges de K6. Elles ont été
corrigées avant cette réconciliation :

1. le gate responsive reçoit maintenant la largeur réellement disponible après
   le shell et la sidebar Narrative (`996 px` dans le shell 1280), tout en
   conservant la largeur de fenêtre pour les tiers visuels 1672 ;
2. le fixture full-shell ne prétend plus prouver l’auto-collapse : il replie
   explicitement l’explorateur pour rendre la capture déterministe.

Le dernier P2 UX relevé par la follow-up review est également fermé : le gate
parle désormais de `Zone de travail` et de `1280 px dans la zone Event`, pas
d’une fenêtre 1280 qui serait paradoxalement suffisante. Les tests
route/workspace/responsive repassent `+29`, puis la matrice K repasse `+48`.

## K7.2 Audit, passes et fichiers de correction

| Passe obligatoire | Verdict | Preuve |
|---|---|---|
| Audit / Architecture | PASS technique | largeur fenêtre et largeur métier séparées ; ownership Event/Scene inchangé |
| Implémentation | PASS | gate sur largeur utile, fixture K enrichie, status bar adaptative |
| Tests | PASS K | commande K normative finale : `+48`, all passed |
| Build / Validation | PASS feature | analyse ciblée 23 fichiers et build editor verts |
| Critique finale | PASS après corrections | aucun blocker code ; seuls les écarts visuels P2 exigent une décision utilisateur |

Les fichiers K6 restent attribués. La passe K7 ajoute ou corrige précisément :

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | composition Events dans un `LayoutBuilder` | transmettre largeur de fenêtre et largeur métier distinctes |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | `availableWidth` + gate | bloquer avant loaders lorsque le shell ne laisse pas 1280 px |
| `packages/map_editor/lib/src/ui/shared/status_bar.dart` | seuil wide adaptatif | supprimer l’overflow du chrome au shell 1280 avec map active |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | full-shell 1280 | prouver gate, zéro loader et zéro exception |
| `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart` | commentaire/helper full-shell | décrire honnêtement le repli explicite du harness |
| `packages/map_editor/test/support/event_builder_v2_visual_harness.dart` | Event cible K | deux conditions, priorité, ordre et concurrence réalistes |
| `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart` | conflit optionnel | le conflit n’existe que si une vraie concurrence active existe |
| `packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png` | golden K | baseline rafraîchie après inspection des détails supportés |
| `design-qa.md` | statut | PASS technique, mission K `PLANNED` |

TDD observé : avant correction, le full shell 1280 montait le workspace dans
`996 px`, produisait un overflow de `40 px` dans Event et `144 px` dans la
status bar, et ne trouvait aucun narrow gate. Après correction, le test trouve
le gate, n’appelle aucun loader et ne remonte aucune exception.

## K7.3 Commandes finales

```bash
cd packages/map_editor
flutter test --no-pub --concurrency=1 \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart
```

Résultat final : exit `0`, `+48`, `All tests passed!`.

La première exécution de cette commande a honnêtement échoué sur un golden K
périmé (`4,70 %`) et un test de conflit devenu trop permissif. La fixture a été
enrichie avec les données réellement supportées, le test a été resserré sur une
concurrence active, le golden a été inspecté puis rafraîchi. Les deux tests
isolés et la matrice complète ont ensuite repassé.

```bash
flutter analyze --no-pub <23 fichiers de fermeture K/L>
```

Résultat : exit `0`, `No issues found!`.

```bash
flutter build macos --debug --no-pub
```

Résultat : exit `0`,
`✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## K7.4 Artefacts, Git et auto-critique

| Artefact | Dimensions | SHA-256 |
|---|---:|---|
| north star | 1672 × 941 | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |
| full-shell produit | 1672 × 941 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |
| côte-à-côte final | 3344 × 941 | `ba8f2d3e8f749ca5bb3da437f7ef0771452f74cb95f4a52d2753ecebac54199f` |
| overlay final | 1672 × 941 | `7153dbd5ae3be7e256694b29e5718e69f4d85f424f0da1152c202804c8e1f589` |
| golden K ciblé | 1672 × 941 | `9274c74eb58dc34b41a52bc3225afd04908e80d5fd8345c9095edeebcb928cff` |

État Git de départ conservé : HEAD
`2f68328a38bf218c843e497940f8dd24a7a9c194`, `64` entrées
suivies/indexées + `171` non suivies = `235`. État final : même HEAD, `69`
entrées suivies/indexées + `180` non suivies = `249`; `git diff --check` exit
`0`. Aucune opération Git d’écriture n’a été exécutée.

Auto-critique : la feature est nettement plus proche de la north star et ses
blocs métier sont prouvés, mais le shell PokeMap n’est pas pixel-identique à la
maquette. Ce P2 est visible dans le côte-à-côte. Le rapport refuse donc de
transformer un PASS technique en acceptation utilisateur implicite.

> **Clôture finale K6 — 2026-07-17.** Cette section remplace les verdicts K5
> et historiques situés plus bas. Ils restent conservés comme audit trail.

## K6.1 Verdict exécutif

- Lot exact : `NS-EVENT-V2 Phase K — Pixel-Perfect Visual Closure`.
- Jalons : `V2-38`, `V2-39`, `V2-40`.
- Verdict feature : **PASS / fermeture technique proposée**.
- Référence : 1672 × 941, SHA-256
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885`.
- Produit final : 1672 × 941, SHA-256
  `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673`.

Le P0 historique est fermé : la preuve finale monte la vraie
`EditorShellPage`, traverse la vraie route Events, utilise une fixture V2-only
persistée sur disque et affiche un état riche projeté par les read models de
production. Le P0 responsive est également fermé à 800 × 632. Les écarts qui
restent sont des limites explicites du modèle, pas des contrôles visuels
manquants : absence de reset canonique et absence de mapping outcome→réaction.

## K6.2 Scope et audit initial

L’audit a relu les deux roadmaps Event V2, `codex_rule.md`, les Evidence Packs
K/L, le design system, la route `NarrativeWorkspaceCanvas`, le workspace V2,
les fixtures produit et la north star fournie. Il a vérifié avant modification :

- la route V2 était réelle mais son golden s’arrêtait au canvas ;
- la fixture produit ne portait pas assez de conditions/résultats/conséquences ;
- le shell complet 1672 × 941 n’était pas capturé ;
- les notices étaient construites avant le gate étroit et causaient un overflow
  réel de 70 px ;
- le modèle supportait honnêtement conditions détaillées et priorité, mais ni
  reset, ni relation outcome→réaction canonique.

Limites de scope conservées : aucune refonte du chrome PokeMap, aucune couleur
feature codée en dur, aucune fausse branche ou interaction Scene, aucune
opération Git d’écriture et aucune correction des chantiers Pokémon SDK ou
Selbrume étrangers.

État Git initial de la passe de clôture :

```text
HEAD 2f68328a38bf218c843e497940f8dd24a7a9c194
tracked/indexed entries: 64
untracked entries: 171
total dirty entries: 235
```

## K6.3 Verdict des cinq passes obligatoires

| Passe | Verdict final | Preuve |
|---|---|---|
| Audit / Architecture | PASS | route réelle et ownership Event/Scene vérifiés |
| Implémentation | PASS | shell complet, fixture riche, gate étroit et P1 supportés |
| Tests | PASS ciblé | core `+16`, editor de fermeture `+66` |
| Build / Validation | PASS feature | analyses ciblées et build editor verts |
| Critique finale | PASS avec limites | aucun P0/P1/P2 actionnable dans le contrat supporté |

## K6.4 Fichiers et zones attribuables à cette clôture

| Fichier | Zone modifiée | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | conditions et lifecycle summaries | labels humains ordonnés, résolution, priorité/ordre/concurrence |
| `packages/map_core/test/narrative_event_builder_project_read_model_test.dart` | trois cas D3 + snapshot | positif, cible manquante, concurrence et non-fuite d’ID |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | gate étroit public | état étroit stable avant construction du workspace |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | early return responsive | aucune notice/watch avant le gate 1280 px |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart` | bloc Conditions | deux conditions lisibles dans l’ordre |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | Conditions, Scene, Comportement | détail, impact read-only, priorité et concurrence |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | pompe du shell | police déterministe optionnelle |
| `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart` | fixture disque et full-shell pump | Scene riche, trois outcomes, deux conséquences, règle monde et concurrence |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | 800 px, read model riche, golden full-shell | preuve réelle et non-régression overflow |
| `packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart` | inspector/editor contracts | conditions détaillées et priorité sans reset inventé |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png` | golden raster | route produit directe actualisée |
| `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` | nouveau golden raster | shell réel normatif |
| `reports/narrativeStudio/events/phase_k_product_route_evidence/*after*` | PNG générés | produit, côte-à-côte et overlay final |
| `design-qa.md` | verdict final | QA feature PASS, limites explicites |

Découpage précis du diff :

- projection core : nouveaux `NarrativeEventConditionDetailSummary` et champs
  lifecycle optionnels, sans changer le JSON canonique persistant ;
- produit : early return sous 1280 px, donc correction localisée sans modifier
  le layout desktop ;
- UI : lecture seule uniquement, aucune nouvelle commande d’authoring ;
- fixture : toutes les données passent par la session disque et les providers
  de production ; aucun read model synthétique injecté ;
- tests : RED observé pour l’overflow, les détails absents et la route
  full-shell avant implémentation, puis GREEN après les correctifs.

## K6.5 Artefacts visuels finaux

| Artefact | Dimensions | SHA-256 |
|---|---:|---|
| `product_after_1672x941.png` | 1672 × 941 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |
| `reference_vs_product_after_1672x941.png` | 3344 × 941 | `ba8f2d3e8f749ca5bb3da437f7ef0771452f74cb95f4a52d2753ecebac54199f` |
| `reference_vs_product_after_overlay_50.png` | 1672 × 941 | `7153dbd5ae3be7e256694b29e5718e69f4d85f424f0da1152c202804c8e1f589` |

L’inspection côte-à-côte et overlay confirme la même hiérarchie métier. Le
chrome global diffère et reste volontairement celui de l’application courante ;
le rapport ne revendique pas une identité pixel du shell.

## K6.6 Commandes fraîches

```bash
cd packages/map_core
dart test --reporter=compact test/narrative_event_builder_project_read_model_test.dart
```

Résultat : exit `0`, `+16`, `All tests passed!`.

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/event_builder_draft_creation_notifier_test.dart \
  test/project_scenario_use_cases_test.dart \
  test/scenario_authoring_claim_guard_test.dart
```

Résultat : exit `0`, `+66`, `All tests passed!`.

```bash
cd packages/map_editor
flutter test --no-pub --concurrency=1 --reporter=compact \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_validation_coordinator_test.dart
```

Résultat : exit `0`, `+6`, `All tests passed!`; mesure p50 `12057 µs`,
p95 `17255 µs`, budget p95 `36000 µs`.

```bash
cd packages/map_core
dart analyze lib/src/read_models/narrative_event_builder_project_read_model.dart \
  test/narrative_event_builder_project_read_model_test.dart
```

Résultat : exit `0`, `No issues found!`.

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Résultat : exit `0`,
`✓ Built build/macos/Build/Products/Debug/map_editor.app`.

L’analyse globale editor reste rouge à `81 errors, 10 warnings, 366 infos`,
soit `457 issues`. Les erreurs sont concentrées dans l’intégration Pokémon SDK
Moves et ne sont pas attribuables à K. Le build editor est néanmoins vert.

## K6.7 Contenus créés et auto-critique

Le seul fichier texte créé spécifiquement par la passe complète de fermeture
est le plan
`docs/superpowers/plans/2026-07-17-event-builder-v2-final-closure.md`; son
contenu complet est reproduit dans l’annexe finale de l’Evidence Pack L afin
d’éviter une seconde copie divergente. Le golden full-shell et les PNG sont des
artefacts binaires documentés par dimensions et hashes.

Auto-critique : la preuve est beaucoup plus forte qu’en K5, mais la mention
« pixel-perfect » reste à interpréter au niveau de la feature dans le shell
PokeMap existant. Toute exigence future d’identité du chrome global doit devenir
un lot de redesign du shell, pas être absorbée silencieusement dans Event V2.
Les semantics reset et outcome→réaction restent volontairement absentes jusqu’à
un contrat core/runtime ratifié.

> **Mise à jour normative — 2026-07-17.** Les sections 1 à 15 situées après
> cette mise à jour constituent l'Evidence Pack historique initial et ses
> annexes de contenu complet. Elles sont conservées pour la traçabilité, mais
> leurs anciens constats « route produit V1 », hashes, compteurs et verdicts
> sont remplacés par la présente mise à jour et par `design-qa.md`.

## Mise à jour K5 — état courant et verdict

- Lot exact : **NS-EVENT-V2 Phase K — Pixel-Perfect Visual Closure**.
- Jalons : **V2-38 à V2-40**.
- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194`.
- Verdict technique : **PARTIAL solide**.
- Verdict formel : **BLOCKED / ne pas marquer K DONE**.

La vraie route produit monte maintenant `EventBuilderV2ProductRoute` depuis
`NarrativeWorkspaceCanvas`. La grille 1672 × 941, la candidate Phase K et la
route produit possèdent des goldens non optionnels. La liste projet et la
navigation utilisent une densité DS dédiée ; les titres prioritaires sont
prouvés non tronqués avec la police de capture. La fermeture reste bloquée par
l'absence d'une capture de la vraie application dans le même shell et le même
état riche que la north star, ainsi que par des écarts P1 liés aux contrats de
conditions, de comportement et de mapping outcome/réaction.

### Audit initial corrigé

L'audit de reprise a contrôlé :

- `MVP Selbrume/road_map_event_builder_v2.md` et les critères V2-38…40 ;
- la route réelle dans `narrative_workspace_canvas.dart` ;
- le workspace V2, ses quatre panneaux et les authoring sheets ;
- le design system avant toute nouvelle primitive ;
- la north star 1672 × 941 et les anciens artefacts K ;
- les tests route produit, responsive, accessibilité, création et V1 ;
- `codex_rule.md` avant la mise à jour du rapport.

La reprise remet en cause l'ancienne conclusion selon laquelle la route reste
V1 : elle est périmée. Elle maintient en revanche le refus de fermer K sur un
harnais synthétique seul. L'alternative sûre appliquée est de consolider le
pixel guard, la densité et les preuves, sans inventer de contrats métier pour
copier la maquette.

Risques identifiés et préservés :

1. ne pas confondre harnais déterministe et shell produit end-to-end ;
2. ne pas inventer de map picker, de branche outcome/réaction ou de priorité ;
3. ne pas rendre authorable une projection appartenant à la Scene ;
4. ne pas masquer les erreurs globales préexistantes du package ;
5. ne pas attribuer au lot les 230+ changements préexistants du worktree.

### État Git initial de cette reprise

- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- 63 fichiers suivis modifiés ;
- 167 fichiers non suivis ;
- total sale : 230 ;
- worktree partagé conservé, aucune opération Git d'écriture.

### Verdict des cinq passes obligatoires

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture | PARTIAL / BLOCKED K | route V2 réelle confirmée ; preuve normative encore harnais |
| Implémentation | PASS ciblé | densité, flow complet, ownership et inspecteur corrigés |
| Tests | READY technique | `+91` ciblés et `+156` V1 |
| Build / Validation | PASS ciblé / global rouge | analyse ciblée et build verts ; 454 issues globales hors K |
| Critique finale | PARTIAL | aucun P0 code ; P1 preuve produit même état et capture réelle 800 px |

La critique contradictoire a trouvé et fait corriger pendant la reprise :

- les goldens auparavant opt-in ;
- le test focus qui ne vérifiait pas l'action exacte ;
- la preuve 125 % qui ne vérifiait pas l'atteignabilité du bas du flow ;
- les titres sélectionnés tronqués par un partage de flex trop agressif ;
- un lock Selbrume temporaire créé lors du test de l'application ;
- l'extension incorrecte de la capture réelle, JPEG renommé `.jpg`.

Finding restant de cette capture réelle : `BOTTOM OVERFLOWED BY 70 PIXELS` à
800 × 632 dans l'écran diagnostics/migration. L'artefact est une preuve
négative et non une validation du gate étroit Event Builder.

### Inventaire complet des fichiers touchés par cette reprise K

| Fichier | Zones | Raison / impact |
|---|---|---|
| `lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart` | groupes Déclencheurs/Conditions/Scene/Résultats/Réactions/Monde | densité et ownership lisibles |
| `lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart` | source compacte, flow, outcomes, fin | rail complet dans le viewport cible |
| `lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | titres, portée read-only, comportement | action réelle et hiérarchie dense |
| `lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | callback comportement et layout | branchement de l'action inspector |
| `lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart` | statuts et rows compactes | titres prioritaires lisibles |
| `lib/src/ui/design_system/pokemap_dashboard_primitives.dart` | `PokeMapStatusLabel` | dot + texte compact, tokenisé |
| `lib/src/ui/design_system/pokemap_sidebar_item.dart` | mode `compact`, trailing | primitive DS réutilisable sans casser le défaut |
| `test/support/event_builder_v2_visual_harness.dart` | chrome, CTA, nav, police, icône | fixture déterministe 1672 et matrice |
| `test/ui/canvas/event_builder_v2_phase_k_visual_test.dart` | géométrie, golden obligatoire, lisibilité | pixel guard exécuté à chaque run |
| `test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart` | 125 %, bounds, reachability | flow scrollable et actions atteignables |
| `test/ui/canvas/event_builder_v2_flow_fidelity_test.dart` | focus Scene exact | garde-fou interaction réelle |
| `test/ui/canvas/event_builder_v2_project_list_test.dart` | portée dérivée | contrat source-first |
| `test/ui/canvas/event_builder_v2_product_route_test.dart` | golden non optionnel | preuve de branchement V2 réel |
| `test/ui/canvas/event_builder_v2_creation_flow_test.dart` | helper comportement | édition via inspecteur |
| `test/ui/design_system/pokemap_card_panel_test.dart` | status compact | garde-fou DS |
| `test/ui/design_system/pokemap_sidebar_item_test.dart` | mode compact 34 px | garde-fou densité et style sélectionné |
| `design-qa.md` | rapport QA courant | verdict visuel non périmé |
| ce fichier | mise à jour normative | preuves exactes de reprise |

Les fichiers V2 et tests marqués `??` existaient déjà comme travaux non suivis
des phases précédentes. Le tableau attribue uniquement les zones effectivement
modifiées dans cette reprise ; il ne prétend pas réattribuer leur création.

Artefacts binaires mis à jour ou créés :

- six goldens sous `test/goldens/event_builder_v2/phase_k/` ;
- `test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png` ;
- six preuves sous `reports/narrativeStudio/events/phase_k_visual_evidence_v2/`.

Les PNG/JPEG sont identifiés sans transcription lossy par leurs dimensions et
hashes dans `design-qa.md`. Aucun nouveau fichier texte n'a été créé dans cette
reprise ; les fichiers texte créés lors de l'Evidence Pack initial restent
reproduits intégralement dans les annexes historiques ci-dessous.

### Diffs et zones précises

- `PokeMapSidebarItem` : ajout opt-in de `compact`, budgets 34/42 px,
  paddings/gaps/typo denses, trailing intrinsèque uniquement en mode compact ;
  le comportement par défaut reste identique.
- `PokeMapStatusLabel` : status sémantique ExcludeSemantics, icône 7 px et texte
  intrinsèque afin de ne pas voler la moitié de la ligne au titre.
- Project list : `compact: true` uniquement sur les lignes Event.
- Editor : suppression du doublon de comportement central, fin de flow visible,
  Wrap 2 colonnes pour 3+ outcomes.
- Inspector : édition du comportement via un vrai bouton `Modifier`.
- Harness : grille exacte `191 / 266 / 213 / 565 / 388`, contexte 52 px,
  navigation 817 px, police SFNS et CTA desktop.
- Tests : goldens canoniques non conditionnels, bounds/scroll 125 %, focus exact,
  titre projet et `Validateur` non tronqués avec la police de capture.

### Commandes et résultats exacts

Matrice ciblée finale :

```bash
cd packages/map_editor
flutter test --no-pub --concurrency=1 \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/ui/canvas/event_builder_v2_project_list_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_reference_contract_test.dart \
  test/ui/canvas/event_builder_v2_creation_flow_test.dart \
  test/ui/canvas/event_builder_v2_validation_navigation_test.dart \
  test/narrative_event_builder_v2_state_test.dart \
  test/narrative_event_builder_v2_session_snapshot_test.dart \
  test/ui/design_system/pokemap_button_test.dart \
  test/ui/design_system/pokemap_sidebar_item_test.dart \
  test/ui/design_system/pokemap_search_field_test.dart \
  test/ui/design_system/pokemap_diagnostic_callout_test.dart \
  test/ui/design_system/pokemap_desktop_side_sheet_test.dart \
  test/ui/design_system/pokemap_card_panel_test.dart
```

Résultat : exit `0`, `+91: All tests passed!`.

Régression V1 :

```bash
flutter test --no-pub test/event_builder_workspace_test.dart --reporter compact
```

Résultat : exit `0`, `+156: All tests passed!`.

Capture/goldens Phase K :

```bash
flutter test --no-pub --update-goldens \
  --dart-define=NS_EVENT_V2_PHASE_K_CAPTURE=true \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
```

Résultat : exit `0`, `+5: All tests passed!`.

Capture after :

```bash
flutter test --no-pub --update-goldens \
  --dart-define=NS_EVENT_V2_PHASE_K_CAPTURE_STAGE=after \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  --plain-name 'conditionally captures before and after comparison evidence'
```

Résultat : exit `0`, `+1: All tests passed!`.

Analyse ciblée :

```bash
flutter analyze lib/src/ui/canvas/events_v2 \
  lib/src/ui/design_system/pokemap_dashboard_primitives.dart \
  lib/src/ui/design_system/pokemap_sidebar_item.dart \
  test/support/event_builder_v2_visual_harness.dart \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/ui/canvas/event_builder_v2_project_list_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_creation_flow_test.dart \
  test/ui/design_system/pokemap_sidebar_item_test.dart \
  test/ui/design_system/pokemap_card_panel_test.dart
```

Résultat : exit `0`, `No issues found! (ran in 6.7s)`.

Analyse package complète :

```bash
flutter analyze
```

Résultat : exit `1`, `454 issues found. (ran in 6.0s)`. Les premiers erreurs
concernent `pokemon_sdk_move_catalog_converter.dart` (`dbSymbol`,
`PokemonMoveAimedTarget`, etc.) et sont hors du diff Phase K. Aucun résultat
global vert n'est revendiqué.

Build :

```bash
flutter build macos --debug --no-pub
```

Résultat : exit `0`,
`✓ Built build/macos/Build/Products/Debug/map_editor.app`.

### État Git final de cette reprise

- HEAD inchangé : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- 64 fichiers suivis modifiés ;
- 168 fichiers non suivis ;
- total sale : 232 ;
- aucun lock Selbrume ni dossier `test/ui/canvas/failures` laissé par la reprise ;
- aucune opération Git d'écriture exécutée.

L'écart initial/final correspond aux fichiers Phase K/DS et à la preuve réelle ;
les autres changements restent préexistants et non attribués.

### Limites, auto-critique et risques

- le 125 % prouve bounds, absence d'exception et reachability après scroll,
  pas l'absence de toute ellipse secondaire ;
- l'action Scene est prouvée focusable exactement et construite avec le
  composant DS hover-capable, sans assertion pixel de la couleur hover ;
- la capture app réelle 800 px révèle un overflow en amont du workspace ;
- le golden route produit prouve le branchement, pas un match north star ;
- conditions détaillées, priorité/reset et outcome→réaction exigeraient des
  contrats supplémentaires et n'ont pas été inventés ;
- le worktree très sale demeure un risque d'attribution.

Prochaines étapes proposées, non implémentées :

1. créer une fixture produit Selbrume riche identique à la north star ;
2. capturer le shell réel à 1672 × 941 et comparer même état / même viewport ;
3. corriger l'overflow diagnostics à 800 px ou formaliser ce viewport comme
   non supporté au niveau du shell ;
4. ajouter les contrats métier manquants avant toute UI détaillée correspondante ;
5. seulement ensuite proposer V2-38…40 `DONE` et mettre la roadmap à jour.

---

## Evidence Pack historique initial — conservé pour traçabilité

## 1. Identité et verdict

- Lot exact : **Phase K — Pixel-Perfect Visual Closure**.
- Jalons : **NS-EVENT-V2-38 à NS-EVENT-V2-40**.
- North star : 1672 × 941, SHA-256
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885`.
- HEAD observé : `2f68328a38bf218c843e497940f8dd24a7a9c194`.
- Verdict technique : **candidate visuelle PARTIAL**.
- Verdict formel : **Phase K BLOCKED / NO-GO**.

La candidate isolée possède une grille 1672 × 941 exacte, une matrice desktop
sans overflow sur les cas ciblés, une side sheet réellement modale et des
preuves raster lisibles. Elle ne ferme pas Phase K : la route produit reste V1,
H/I/J ne sont pas validées, la matrice d'états V2-40 est incomplète et les
comparaisons visibles conservent plusieurs écarts P1/P2.

| Jalon | État technique | Verdict formel | Motif principal |
|---|---|---|---|
| V2-38 | PARTIAL | BLOCKED | grille/capture harnais, pas route produit |
| V2-39 | PARTIAL | BLOCKED | style honnête, fork/mapping incomplets |
| V2-40 | PARTIAL | BLOCKED | tailles/focus verts, états/continuité incomplets |

La roadmap n'a pas été mise à jour par ce lot : aucun jalon n'est proposé DONE.

## 2. Scope confirmé

Travail autorisé et réalisé :

- géométrie cinq zones et quatre panneaux métier ;
- densité visuelle du rail, de la bibliothèque et de l'inspecteur ;
- responsive 1280/1440/1480/1672/wide ;
- text scale 125 %, side sheet modale, focus trap, Escape et retour focus ;
- harness déterministe, captures, côte-à-côte, overlay et crops focalisés ;
- tests widget/state/DS et garde-fous de wording/ownership.

Limites de scope préservées :

- aucun contrat Event/runtime/migration/validator nouveau ;
- aucun sélecteur de map indépendant, ID brut, calque ou coordonnée ;
- source atomique existante, lieu dérivé en lecture seule ;
- Event distinct de Scene ; projections Scene en lecture seule ;
- aucun grip, drag/drop ou action de réaction factice ;
- aucune couleur feature codée en dur ; tokens/tones DS uniquement.

## 3. Audit initial et remise en cause du prompt

Le prompt « faire la phase K » était incohérent avec les entry criteria du
repo : K exige Phase J validée et données de capture figées, alors que le
tableau de roadmap conserve H/I/J non validées. L'audit a aussi prouvé que
`narrative_workspace_canvas.dart` instancie encore `EventBuilderWorkspace` V1.

Alternative appliquée : avancer uniquement la portion style/test/harness de K,
sans inventer les contrats manquants et sans prétendre fermer le lot.

Inventaire initial à haut signal :

- roadmap : `MVP Selbrume/road_map_event_builder_v2.md`, lignes Phase K ;
- route réelle : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` ;
- read model/session : `narrative_event_authoring_session.dart` ;
- candidat V2 : `lib/src/ui/canvas/events_v2/` ;
- design system : `lib/src/ui/design_system/` ;
- référence fournie : fichier PNG absolu cité en section 1 ;
- rapports Phase F/G déjà présents et worktree partagé très sale.

Risques identifiés avant implémentation :

1. faire passer un shell synthétique pour la route produit ;
2. copier les grips/drop zones de la référence sans moteur fonctionnel ;
3. interpréter l'ordre des labels outcome comme victoire/défaite ;
4. baser un breakpoint sur le viewport plutôt que l'espace métier réel ;
5. valider une capture Ahem illisible ;
6. écraser les changements F/G/H concurrents.

## 4. État Git initial

Premier snapshot capturé pendant le préflight K, après démarrage du scaffolding
concurrent mais avant les corrections QA :

- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- 33 fichiers suivis modifiés ;
- 67 fichiers non suivis ;
- changements préexistants Phase F/G/runtime/editor explicitement conservés ;
- aucune opération Git d'écriture (`add`, `commit`, `stash`, `reset`, etc.).

Le lot a travaillé dans ce worktree partagé sans nettoyer ni réécrire les
modifications utilisateur. Les artefacts temporaires créés par la suite
complète (`test/failures/` et lock Selbrume) ont été supprimés après diagnostic.

## 5. Verdicts des sub-agents/passes

| Passe | Verdict | Preuve principale |
|---|---|---|
| Audit / Architecture | NO-GO | H/I/J non validées, route produit V1 |
| Implémentation état/V2-39 | PARTIAL stable | flow/state/session ciblés verts |
| DS / Harness visuel | PARTIAL stable | K `+8`, capture `+3`, analyse ciblée verte |
| Tests indépendant | PASS ciblé | matrice séquentielle `+54` |
| Build / Validation | MIXED | build vert ; package global `+2961 -96` |
| Critique finale | BLOCKED | route/harness, états V2-40, pixel match incomplet |

Findings de la critique finale encore ouverts :

- V2 non montée en production ;
- loading/saving/error, legacy visuel, IDs longs, liste dense et continuité
  scroll/catégorie non prouvés ;
- pas de véritable fork/connecteurs outcome → réactions ;
- écarts visibles de shell, densité, éditeur et inspecteur.

## 6. Inventaire complet des fichiers du lot

### 6.1 Fichiers suivis modifiés

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart` | session validée, getters `manifest`/`maps` | snapshot projet exact pour le read model V2 |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | exports DS | expose search/callout/side sheet |
| `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart` | `borderRadius` configurable | panneaux denses à rayon 8 sans changer le défaut |
| `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart` | `focusNode`, activation focus flushée | retour au vrai lanceur modal |
| `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart` | trailing flexible | supprime overflows sous contrainte/text scale |
| `packages/map_editor/test/ui/design_system/pokemap_button_test.dart` | test focus externe | garde-fou modal déterministe |
| `design-qa.md` | rapport QA complet | verdict `blocked`, comparaison et checklist |

Diff suivi exact : 333 insertions et 102 suppressions sur ces sept fichiers au
moment du contrôle. Les zones sont décrites ci-dessus ; les contenus complets
des fichiers créés sont annexés en section 14.

### 6.2 Fichiers texte créés

- `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_search_field.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_diagnostic_callout.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_desktop_side_sheet.dart`
- `packages/map_editor/test/narrative_event_builder_v2_session_snapshot_test.dart`
- `packages/map_editor/test/narrative_event_builder_v2_state_test.dart`
- `packages/map_editor/test/support/event_builder_v2_visual_harness.dart`
- `packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart`
- `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`
- `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_visual_test.dart`
- `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_search_field_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_diagnostic_callout_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_desktop_side_sheet_test.dart`
- `docs/superpowers/plans/2026-07-16-event-builder-phase-k-pixel-closure.md`
  (ignoré par `.gitignore`, conservé comme plan local).

### 6.3 Artefacts binaires créés

Baselines sous `packages/map_editor/test/goldens/event_builder_v2/phase_k/` :

- `event_builder_v2_1280x941.png` ;
- `event_builder_v2_1440x941.png` ;
- `event_builder_v2_1480x941.png` ;
- `event_builder_v2_1672x941.png` ;
- `event_builder_v2_1672x941_broken_source.png` ;
- `event_builder_v2_1920x941.png`.

Preuves combinées sous
`reports/narrativeStudio/events/phase_k_visual_evidence/` :

- `reference_vs_candidate_side_by_side.png` ;
- `reference_vs_candidate_overlay_50.png` ;
- `focus_navigation_and_event_list.png` ;
- `focus_library_and_editor.png` ;
- `focus_inspector.png`.

Les PNG sont des contenus binaires : leur contenu complet est identifié par
dimensions et SHA-256 dans `design-qa.md`, sans transcription lossy dans ce
Markdown.

## 7. Décisions techniques et zones précises

### Read model et sélection

- La session expose uniquement le manifest et les maps déjà validés.
- `NarrativeEventBuilderV2State` conserve recherche/filtre et délègue la
  sélection V2 au bridge ; une sélection legacy reste locale sans forger une
  identité V2.

### Workspace et responsive

- Largeurs exactes 1672 : `266 / 213 / 565 / 388`, gaps 8 px.
- Sous 1480 : bibliothèque via side sheet explicite.
- La bibliothèque inline exige aussi `constraints.maxWidth >= 1280`, pas
  seulement `viewportWidth >= 1480`.
- Sous 1280 viewport : état explicite « Fenêtre trop étroite » avec sélection
  conservée.

### Flow et ownership

- Rail borné à 404 px et cartes tokenisées.
- 0/1/2/3+ outcomes rendus dynamiquement.
- Outcomes neutres : aucune sémantique success/danger déduite de leur index.
- Projections Scene, conséquences et world rules toujours read-only.
- Copie « Cliquez… » retirée des lignes non interactives.

### Side sheet et focus

- Fond inerte, focus trap, `Escape`, focus retour.
- `PokeMapButton` accepte un `FocusNode` externe et applique la demande de
  focus avant d'ouvrir la route modale, supprimant une intermittence réelle.

### Capture

- DPR 1 et fixture déterministe de 20 événements couvrant tous les groupes.
- Arial macOS chargée uniquement en capture avec échec clair si absente.
- Vrais glyphes Cupertino chargés ; première baseline Ahem illisible remplacée.

## 8. Tests créés/modifiés

Couverture positive : grille exacte, rendu groupes, recherche/filtre,
outcomes 0/1/2/3+, side sheet, build du read model.

Cas négatifs : `<1280`, recherche vide, projet vide, source cassée, legacy
read-only, callback absent, fond modal inerte.

Garde-fous : aucun raw ID/calque, aucun faux drop/grip, aucune sémantique
outcome par index, largeur métier contrainte, vrai retour focus.

Non-régression : DS button/panel/search/callout/side sheet et ancien Event
Builder V1 (`156` tests).

## 9. Commandes de tests et résultats exacts

### Matrice Phase K finale

```bash
cd packages/map_editor
flutter test --concurrency=1 \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/narrative_event_builder_v2_state_test.dart \
  test/narrative_event_builder_v2_session_snapshot_test.dart \
  test/ui/design_system/pokemap_button_test.dart \
  test/ui/design_system/pokemap_search_field_test.dart \
  test/ui/design_system/pokemap_diagnostic_callout_test.dart \
  test/ui/design_system/pokemap_desktop_side_sheet_test.dart \
  test/ui/design_system/pokemap_card_panel_test.dart
```

Résultat frais : exit `0`, `+54: All tests passed!`.

### Vérification raster activée

```bash
flutter test --dart-define=NS_EVENT_V2_PHASE_K_CAPTURE=true \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
```

Résultat frais : exit `0`, `+3: All tests passed!`.

### Régression Event Builder V1

```bash
flutter test test/event_builder_workspace_test.dart
```

Résultat frais : exit `0`, `+156: All tests passed!`.

### Suite complète du package

```bash
flutter test
```

Résultat : exit `1`, durée `02:56`, `+2961 -96`, `Some tests failed.`

Premier échec exact :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3:
Error: Type 'PokemonMoveAimedTarget' not found.
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3:
Error: Type 'PokemonMoveFlags' not found.
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:339:8:
Error: Type 'PokemonMoveBattleStageMod' not found.
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:383:8:
Error: Type 'PokemonMoveStatus' not found.
```

Autres familles : SDK Pokémon, guardrail DS Cinematics, encounter tables,
goldens Scenes/Storylines, path pattern eau, Pokédex/Project Explorer et
fixtures Selbrume. Aucun signal ne cible directement `events_v2`, mais les
goldens globaux ne peuvent pas être déclarés préexistants avec certitude dans
ce worktree partagé.

## 10. Analyse statique

Analyse ciblée finale de 14 items Phase K :

```bash
flutter analyze lib/src/ui/canvas/events_v2 \
  lib/src/features/narrative/state/narrative_event_builder_v2_state.dart \
  lib/src/application/models/narrative_event_authoring_session.dart \
  lib/src/ui/design_system/pokemap_button.dart \
  lib/src/ui/design_system/pokemap_panel.dart \
  lib/src/ui/design_system/pokemap_search_field.dart \
  lib/src/ui/design_system/pokemap_diagnostic_callout.dart \
  lib/src/ui/design_system/pokemap_desktop_side_sheet.dart \
  test/support/event_builder_v2_visual_harness.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/design_system/pokemap_button_test.dart
```

Résultat frais : exit `0`, `No issues found! (ran in 4.3s)`.

Analyse complète :

```bash
flutter analyze
```

Résultat : exit `1`, `451 issues found` en `5.0s` : `81 errors`,
`10 warnings`, `360 infos`. Recherche explicite des chemins Phase K dans cette
sortie : aucune occurrence.

## 11. Build

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat exact :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Exit `0`. App produite sous
`packages/map_editor/build/macos/Build/Products/Debug/map_editor.app` ; le
dossier `build/` est ignoré.

## 12. Visual Gate

- Côte-à-côte et overlay inspectés dans un même input à 1672 × 941.
- Trois crops focalisés inspectés : navigation/liste, bibliothèque/éditeur,
  inspecteur.
- Grille externe exacte ; inspecteur à `x=1275` contre raster `x=1274`, écart
  documenté de 1 px.
- Écarts P1/P2 visibles encore ouverts : shell, badges/densité, fork central,
  structure inspecteur, typographie et matrice d'états.

Rapport canonique : `design-qa.md`, avec `final result: blocked`.

## 13. État Git final, limites, auto-critique et risques

### État Git final

Après création de cet Evidence Pack et nettoyage des artefacts temporaires :

- 37 fichiers suivis modifiés ;
- 80 fichiers non suivis ;
- 117 entrées dirty attendues ;
- aucun `test/failures/` ni lock Selbrume résiduel ;
- aucune opération Git d'écriture.

Le statut complet est annexé après les contenus source.

### Limites conservées

- Le harness est macOS-only/test-only et ne prouve pas la route produit.
- Les six PNG sont les baselines du candidat, pas la north star approuvée.
- La fonte Arial rend la capture lisible mais n'est pas la typographie produit.
- Les callbacks du harness ne prouvent pas l'authoring end-to-end.
- H/I/J et la fixture Selbrume restent nécessaires.

### Auto-critique

Points solides : TDD a attrapé la hauteur contexte, deux overflows, un contexte
Navigator invalide, un retour focus intermittent, un breakpoint erroné, une
copie trompeuse, une sémantique outcome inventée et une capture Ahem invalide.
Les garde-fous source-first/Event≠Scene ont résisté.

Points faibles : le lot a produit beaucoup de code/harness avant que les gates
amont soient ouvertes ; la candidate peut donner une impression de progrès
supérieure au produit réel si le caractère test-only est ignoré. La matrice
V2-40 et le graphe V2-39 restent incomplets. La suite globale rouge empêche une
confiance package-wide.

### Risques restants

1. dérive du shell lors du branchement production ;
2. perte scroll/catégorie au passage 1440 ↔ 1480 ;
3. read model insuffisant pour outcome → réactions/priorité ;
4. divergence typographique entre golden test et app ;
5. interactions visibles du harness non reliées aux use cases ;
6. 96 échecs/81 erreurs globaux masquant de futures régressions.

### Prochaines étapes proposées, non implémentées

1. terminer et valider H sur la route produit ;
2. valider I puis la Golden Slice J et figer les données ;
3. compléter les états/continuité V2-40 ;
4. recapturer la vraie app ;
5. répéter QA jusqu'à zéro P0/P1/P2 avant de proposer K DONE.

## 14. Contenu complet des fichiers texte créés

Les annexes suivantes reproduisent verbatim chaque fichier texte créé dans le
périmètre K. Les fichiers suivis modifiés sont couverts par les zones/diffs de
la section 6.1 ; les binaires sont couverts par SHA-256/dimensions.

### 14.1 `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart`

~~~~dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_event_map_bridge_models.dart';
import 'narrative_event_map_bridge_state.dart';

/// Human-facing project-list filters for Event Builder V2.
///
/// The enum deliberately describes author concepts rather than registry or
/// migration implementation details. Filtering never reads debug IDs.
enum NarrativeEventBuilderV2Filter {
  all,
  active,
  drafts,
  attention,
  oldFormat,
}

extension NarrativeEventBuilderV2FilterLabel on NarrativeEventBuilderV2Filter {
  String get label => switch (this) {
        NarrativeEventBuilderV2Filter.all => 'Tous les événements',
        NarrativeEventBuilderV2Filter.active => 'Actifs',
        NarrativeEventBuilderV2Filter.drafts => 'Brouillons',
        NarrativeEventBuilderV2Filter.attention => 'À corriger',
        NarrativeEventBuilderV2Filter.oldFormat => 'Ancien format à convertir',
      };
}

typedef SelectNarrativeEventBuilderV2Event = bool Function({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
});

/// Immutable UI projection of the canonical project-level read model.
///
/// It owns only list presentation state. In particular, Event selection is
/// not stored here: [NarrativeEventMapBridgeState] remains its single owner so
/// Map Editor round trips and the Event Builder cannot diverge.
@immutable
final class NarrativeEventBuilderV2State {
  const NarrativeEventBuilderV2State({
    required this.readModel,
    this.query = '',
    this.filter = NarrativeEventBuilderV2Filter.all,
    this.selectedCompatibilityStableKey,
  });

  final NarrativeEventBuilderProjectReadModel readModel;
  final String query;
  final NarrativeEventBuilderV2Filter filter;

  /// Local selection only for compatibility projections that have no V2
  /// Event identity and therefore cannot be owned by the Phase G bridge.
  final String? selectedCompatibilityStableKey;

  List<NarrativeEventProjectGroup> get visibleGroups {
    final normalizedQuery = _normalizeHumanSearch(query);
    final groups = <NarrativeEventProjectGroup>[];
    for (final group in readModel.groups) {
      final events = _visibleEventsIn(group, normalizedQuery);
      if (events.isEmpty) continue;
      groups.add(
        NarrativeEventProjectGroup(
          stableKey: group.stableKey,
          label: group.label,
          kind: group.kind,
          events: events,
        ),
      );
    }
    return List.unmodifiable(groups);
  }

  List<NarrativeEventProjectSummary> get visibleEvents => List.unmodifiable([
        for (final group in visibleGroups) ...group.events,
      ]);

  bool get isProjectEmpty => readModel.events.isEmpty;

  bool get hasNoMatchingEvents => !isProjectEmpty && visibleEvents.isEmpty;

  /// Fails closed for an invalid project snapshot and for compatibility-only
  /// projections. This never routes back to the legacy authoring surface.
  bool get isReadOnly =>
      readModel.diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventProjectSummarySeverity.error,
      ) ||
      (readModel.events.isNotEmpty &&
          readModel.events.every((event) => event.readOnly));

  NarrativeEventBuilderV2State withQuery(String value) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: value,
      filter: filter,
      selectedCompatibilityStableKey: selectedCompatibilityStableKey,
    );
  }

  NarrativeEventBuilderV2State withFilter(
    NarrativeEventBuilderV2Filter value,
  ) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: query,
      filter: value,
      selectedCompatibilityStableKey: selectedCompatibilityStableKey,
    );
  }

  NarrativeEventBuilderV2State withReadModel(
    NarrativeEventBuilderProjectReadModel value,
  ) {
    final compatibilityKey = selectedCompatibilityStableKey;
    final compatibilitySelection = compatibilityKey == null
        ? null
        : value.eventByStableKey(compatibilityKey)?.readOnly == true
            ? compatibilityKey
            : null;
    return NarrativeEventBuilderV2State(
      readModel: value,
      query: query,
      filter: filter,
      selectedCompatibilityStableKey: compatibilitySelection,
    );
  }

  NarrativeEventBuilderV2State withCompatibilitySelection(String? stableKey) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: query,
      filter: filter,
      selectedCompatibilityStableKey: stableKey,
    );
  }

  List<NarrativeEventProjectSummary> _visibleEventsIn(
    NarrativeEventProjectGroup group,
    String normalizedQuery,
  ) {
    return List.unmodifiable([
      for (final event in group.events)
        if (_matchesFilter(event) &&
            _matchesHumanQuery(event, group, normalizedQuery))
          event,
    ]);
  }

  bool _matchesFilter(NarrativeEventProjectSummary event) {
    return switch (filter) {
      NarrativeEventBuilderV2Filter.all => true,
      NarrativeEventBuilderV2Filter.active => event.enabled == true,
      NarrativeEventBuilderV2Filter.drafts =>
        event.origin == NarrativeEventProjectOrigin.v2 &&
            event.status == NarrativeEventProjectStatus.draftIncomplete,
      NarrativeEventBuilderV2Filter.attention =>
        event.origin == NarrativeEventProjectOrigin.v2 &&
            _requiresAttention(event.status),
      NarrativeEventBuilderV2Filter.oldFormat =>
        event.origin != NarrativeEventProjectOrigin.v2,
    };
  }
}

/// Ephemeral list controller. Registry writes and the selected Event stay
/// outside this controller.
final class NarrativeEventBuilderV2Controller
    extends StateNotifier<NarrativeEventBuilderV2State> {
  NarrativeEventBuilderV2Controller({
    required NarrativeEventBuilderProjectReadModel readModel,
    required SelectNarrativeEventBuilderV2Event selectEvent,
  })  : _selectEvent = selectEvent,
        super(NarrativeEventBuilderV2State(readModel: readModel));

  final SelectNarrativeEventBuilderV2Event _selectEvent;

  void replaceReadModel(NarrativeEventBuilderProjectReadModel readModel) {
    state = state.withReadModel(readModel);
  }

  void setQuery(String query) {
    state = state.withQuery(query);
  }

  void setFilter(NarrativeEventBuilderV2Filter filter) {
    state = state.withFilter(filter);
  }

  void resetFilters() {
    state = state.withQuery('').withFilter(NarrativeEventBuilderV2Filter.all);
  }

  /// Requests selection through the Phase G bridge and never mirrors the
  /// result locally.
  bool selectEvent(
    String stableKey, {
    NarrativeEventGroupContext? groupContext,
  }) {
    final event = state.readModel.eventByStableKey(stableKey);
    final eventId = event?.eventId;
    if (event == null) return false;
    if (event.readOnly || eventId == null) {
      if (!event.readOnly) return false;
      state = state.withCompatibilitySelection(event.stableKey);
      return true;
    }
    if (state.isReadOnly) return false;

    final derivedContext = narrativeEventGroupContextForSummary(event);
    final requestedContext = groupContext ?? derivedContext;
    if (event.source.source != null && requestedContext != derivedContext) {
      return false;
    }
    final selected = _selectEvent(
      eventId: eventId,
      groupContext: requestedContext,
    );
    if (selected) {
      state = state.withCompatibilitySelection(null);
    }
    return selected;
  }
}

/// Converts one canonical summary into the exact Phase G navigation context.
/// A present spatial source owns its map; all non-spatial and unconfigured
/// Events use the global context unless a caller supplies a creation context.
NarrativeEventGroupContext narrativeEventGroupContextForSummary(
  NarrativeEventProjectSummary event,
) {
  final mapId = event.source.mapId?.trim();
  if (mapId != null && mapId.isNotEmpty) {
    return NarrativeEventGroupContext.map(mapId);
  }
  return const NarrativeEventGroupContext.global();
}

/// Resolves the bridge-owned selection against the latest project snapshot.
///
/// Rebuilding the read model therefore preserves selection by stable V2 Event
/// identity without copying that identity into another state object.
NarrativeEventProjectSummary? selectedNarrativeEventBuilderV2Event({
  required NarrativeEventBuilderV2State state,
  required NarrativeEventMapBridgeState bridgeState,
}) {
  final compatibilityKey = state.selectedCompatibilityStableKey;
  if (compatibilityKey != null) {
    final compatibility = state.readModel.eventByStableKey(compatibilityKey);
    if (compatibility?.readOnly == true) return compatibility;
  }

  final selectedId = bridgeState.selectedNarrativeEventV2Id;
  if (selectedId == null) return null;
  NarrativeEventProjectSummary? selected;
  for (final event in state.readModel.events) {
    if (event.eventId == selectedId) {
      selected = event;
      break;
    }
  }
  if (selected == null) return null;

  final selectedGroup = bridgeState.selectedGroupContext;
  if (selectedGroup != null &&
      selected.source.source != null &&
      selectedGroup != narrativeEventGroupContextForSummary(selected)) {
    return null;
  }
  return selected;
}

bool _matchesHumanQuery(
  NarrativeEventProjectSummary event,
  NarrativeEventProjectGroup group,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return true;
  final humanText = <String>[
    group.label,
    event.title,
    event.source.humanSentence,
    event.source.sourceTypeLabel,
    if (event.source.mapLabel != null) event.source.mapLabel!,
    event.scene.humanLabel,
    event.conditions.humanLabel,
    event.lifecycle.humanLabel,
    event.migration.humanLabel,
    _statusLabel(event.status),
    for (final diagnostic in event.diagnostics) diagnostic.message,
  ].join(' ');
  return _normalizeHumanSearch(humanText).contains(normalizedQuery);
}

bool _requiresAttention(NarrativeEventProjectStatus status) => switch (status) {
      NarrativeEventProjectStatus.attentionRequired ||
      NarrativeEventProjectStatus.sourceMissing ||
      NarrativeEventProjectStatus.referenceInvalid ||
      NarrativeEventProjectStatus.unsupported =>
        true,
      _ => false,
    };

String _statusLabel(NarrativeEventProjectStatus status) => switch (status) {
      NarrativeEventProjectStatus.draftIncomplete => 'Brouillon à configurer',
      NarrativeEventProjectStatus.configuredDisabledReady => 'Prêt et inactif',
      NarrativeEventProjectStatus.configuredEnabledReady => 'Actif',
      NarrativeEventProjectStatus.attentionRequired => 'À corriger',
      NarrativeEventProjectStatus.sourceMissing =>
        'Élément déclencheur manquant',
      NarrativeEventProjectStatus.referenceInvalid => 'Référence à corriger',
      NarrativeEventProjectStatus.migrationAssistanceRequired =>
        'Ancien format à convertir',
      NarrativeEventProjectStatus.migrationBlocked => 'Conversion bloquée',
      NarrativeEventProjectStatus.legacyOnly => 'Ancien format à convertir',
      NarrativeEventProjectStatus.unsupported =>
        'Non disponible dans cette version',
      NarrativeEventProjectStatus.claimInvalid => 'Conversion à corriger',
    };

String _normalizeHumanSearch(String value) {
  var normalized = value.trim().toLowerCase();
  const replacements = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
    'œ': 'oe',
  };
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized;
}
~~~~


### 14.2 `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart`

~~~~dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2ProjectList extends StatelessWidget {
  const EventBuilderV2ProjectList({
    super.key,
    required this.groups,
    required this.projectEventCount,
    required this.selectedStableKey,
    required this.controls,
    required this.projectIsEmpty,
    required this.hasNoMatchingEvents,
    required this.onSelectEvent,
    required this.onCreateEvent,
  });

  final List<NarrativeEventProjectGroup> groups;
  final int projectEventCount;
  final String? selectedStableKey;
  final Widget controls;
  final bool projectIsEmpty;
  final bool hasNoMatchingEvents;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final body = projectIsEmpty
        ? const PokeMapEmptyState(
            title: 'Aucun événement dans ce projet',
            description:
                'Créez un événement puis reliez-le à un élément déjà placé sur une map.',
            icon: Icon(CupertinoIcons.bolt_horizontal_circle),
          )
        : hasNoMatchingEvents
            ? const PokeMapEmptyState(
                title: 'Aucun résultat',
                description:
                    'Modifiez la recherche ou affichez un autre statut.',
                icon: Icon(CupertinoIcons.search),
              )
            : ListView.separated(
                key: const ValueKey('event-builder-v2-event-list-scroll'),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _ProjectGroup(
                    group: group,
                    selectedStableKey: selectedStableKey,
                    onSelectEvent: onSelectEvent,
                  );
                },
              );

    return PokeMapPanel(
      expandChild: true,
      borderRadius: 8,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Événements, $projectEventCount dans le projet',
                    child: const Text(
                      'Événements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                PokeMapIconButton(
                  onPressed: onCreateEvent,
                  icon: const Icon(CupertinoIcons.add),
                  tooltip: 'Nouvel événement',
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 8),
            controls,
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-new-event'),
            onPressed: onCreateEvent,
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Nouvel événement'),
          ),
        ),
      ),
      child: body,
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({
    required this.group,
    required this.selectedStableKey,
    required this.onSelectEvent,
  });

  final NarrativeEventProjectGroup group;
  final String? selectedStableKey;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    final label = _groupLabel(group);
    return Semantics(
      container: true,
      label: '$label, ${group.events.length} événements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
            child: Row(
              children: [
                Icon(_groupIcon(group.kind), size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${group.events.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (final event in group.events)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: PokeMapSidebarItem(
                key: ValueKey('event-builder-v2-event-${event.stableKey}'),
                label: event.title,
                icon: Icon(_eventIcon(event)),
                trailing: PokeMapBadge(
                  label: _statusLabel(event),
                  variant: _statusBadgeVariant(event),
                  icon: Icon(
                    event.readOnly
                        ? CupertinoIcons.lock
                        : event.enabled == true
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                  ),
                ),
                selected: selectedStableKey == event.stableKey,
                onTap: () => onSelectEvent(event),
              ),
            ),
        ],
      ),
    );
  }
}

String _groupLabel(NarrativeEventProjectGroup group) {
  return switch (group.kind) {
    NarrativeEventProjectGroupKind.map => group.label,
    NarrativeEventProjectGroupKind.outcomes => 'Événements globaux',
    NarrativeEventProjectGroupKind.drafts => 'Brouillons à terminer',
    NarrativeEventProjectGroupKind.missingReferences => 'Références à réparer',
    NarrativeEventProjectGroupKind.legacyCompatibility =>
      'Ancien format à convertir',
  };
}

IconData _groupIcon(NarrativeEventProjectGroupKind kind) => switch (kind) {
      NarrativeEventProjectGroupKind.map => CupertinoIcons.map,
      NarrativeEventProjectGroupKind.outcomes => CupertinoIcons.globe,
      NarrativeEventProjectGroupKind.drafts => CupertinoIcons.pencil,
      NarrativeEventProjectGroupKind.missingReferences =>
        CupertinoIcons.exclamationmark_triangle,
      NarrativeEventProjectGroupKind.legacyCompatibility =>
        CupertinoIcons.archivebox,
    };

IconData _eventIcon(NarrativeEventProjectSummary event) {
  if (event.readOnly) return CupertinoIcons.archivebox;
  if (!event.source.available) return CupertinoIcons.exclamationmark_triangle;
  return CupertinoIcons.bolt_horizontal_circle;
}

String _statusLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Ancien';
  return switch (event.status) {
    NarrativeEventProjectStatus.draftIncomplete => 'Brouillon',
    NarrativeEventProjectStatus.configuredDisabledReady => 'Inactif',
    NarrativeEventProjectStatus.configuredEnabledReady => 'Actif',
    NarrativeEventProjectStatus.attentionRequired => 'Attention',
    NarrativeEventProjectStatus.sourceMissing => 'Manquant',
    NarrativeEventProjectStatus.referenceInvalid => 'À réparer',
    NarrativeEventProjectStatus.migrationAssistanceRequired ||
    NarrativeEventProjectStatus.migrationBlocked ||
    NarrativeEventProjectStatus.legacyOnly =>
      'Ancien',
    NarrativeEventProjectStatus.unsupported => 'Indisponible',
    NarrativeEventProjectStatus.claimInvalid => 'Conversion',
  };
}

PokeMapBadgeVariant _statusBadgeVariant(
  NarrativeEventProjectSummary event,
) {
  if (event.readOnly) return PokeMapBadgeVariant.warning;
  if (event.enabled == true) return PokeMapBadgeVariant.success;
  return switch (event.severity) {
    NarrativeEventProjectSummarySeverity.info => PokeMapBadgeVariant.neutral,
    NarrativeEventProjectSummarySeverity.warning => PokeMapBadgeVariant.warning,
    NarrativeEventProjectSummarySeverity.error => PokeMapBadgeVariant.error,
  };
}
~~~~


### 14.3 `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart`

~~~~dart
import 'package:flutter/cupertino.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2ElementLibrary extends StatelessWidget {
  const EventBuilderV2ElementLibrary({
    super.key,
    required this.hasLinkedScene,
    this.onOpenScene,
  });

  final bool hasLinkedScene;
  final VoidCallback? onOpenScene;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bibliothèque d’éléments',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Repères de la configuration.',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      child: ListView(
        key: const ValueKey('event-builder-v2-library-scroll'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        children: [
          const _LibrarySectionHeading(
            title: 'Configurer l’événement',
            tone: PokeMapTone.narrative,
          ),
          const SizedBox(height: 5),
          const _LibraryGroup(
            tone: PokeMapTone.narrative,
            items: [
              _LibraryItem(
                'Élément déclencheur',
                CupertinoIcons.bolt_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Conditions',
                CupertinoIcons.checkmark_alt_circle_fill,
                PokeMapTone.info,
              ),
              _LibraryItem(
                'Scene liée',
                CupertinoIcons.play_rectangle_fill,
                PokeMapTone.success,
              ),
              _LibraryItem(
                'Comportement',
                CupertinoIcons.repeat,
                PokeMapTone.brand,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-authorable',
          ),
          const SizedBox(height: 10),
          const _LibrarySectionHeading(
            title: 'Dans la Scene liée',
            tone: PokeMapTone.info,
            readOnly: true,
          ),
          const SizedBox(height: 5),
          const _LibraryGroup(
            title: 'Résultats',
            tone: PokeMapTone.narrative,
            readOnly: true,
            items: [
              _LibraryItem(
                'Résultats',
                CupertinoIcons.flag_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Branches',
                CupertinoIcons.arrow_branch,
                PokeMapTone.narrative,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-results',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Réactions',
            tone: PokeMapTone.warning,
            readOnly: true,
            items: [
              _LibraryItem(
                'Réactions et conséquences',
                CupertinoIcons.bolt_circle_fill,
                PokeMapTone.warning,
              ),
              _LibraryItem(
                'Combat et dialogue',
                CupertinoIcons.sparkles,
                PokeMapTone.warning,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-reactions',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Monde',
            tone: PokeMapTone.map,
            readOnly: true,
            items: [
              _LibraryItem(
                'Changements du monde',
                CupertinoIcons.globe,
                PokeMapTone.map,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-world',
          ),
          const SizedBox(height: 9),
          if (hasLinkedScene)
            PokeMapButton(
              onPressed: onOpenScene,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.arrow_up_right_square),
              child: const Text('Ouvrir la Scene'),
            )
          else
            const PokeMapBadge(
              label: 'Liez une Scene pour voir ses projections',
              variant: PokeMapBadgeVariant.neutral,
              icon: Icon(CupertinoIcons.info_circle),
            ),
        ],
      ),
    );
  }
}

class _LibrarySectionHeading extends StatelessWidget {
  const _LibrarySectionHeading({
    required this.title,
    required this.tone,
    this.readOnly = false,
  });

  final String title;
  final PokeMapTone tone;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    // At the compact 1480 px breakpoint the read-only badge cannot share one
    // line reliably with the section title, especially at 125% text scale.
    // Wrapping keeps the ownership label visible without inventing a click
    // target or overflowing the fixed-width library column.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: toneColors.text,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.25,
          ),
        ),
        if (readOnly)
          const PokeMapBadge(
            label: 'Lecture seule',
            variant: PokeMapBadgeVariant.neutral,
            icon: Icon(CupertinoIcons.lock),
          ),
      ],
    );
  }
}

class _LibraryGroup extends StatelessWidget {
  const _LibraryGroup({
    this.title,
    required this.tone,
    required this.items,
    required this.keyPrefix,
    this.readOnly = false,
  });

  final String? title;
  final PokeMapTone tone;
  final List<_LibraryItem> items;
  final String keyPrefix;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 7,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(
                  readOnly
                      ? CupertinoIcons.lock
                      : CupertinoIcons.slider_horizontal_3,
                  size: 10,
                  color: toneColors.icon,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: TextStyle(
                      color: toneColors.text,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          for (var index = 0; index < items.length; index++) ...[
            _LibraryRow(
              key: ValueKey('$keyPrefix-$index'),
              item: items[index],
              readOnly: readOnly,
            ),
            if (index < items.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({super.key, required this.item, required this.readOnly});

  final _LibraryItem item;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = item.tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly
          ? '${item.label}, défini dans la Scene, lecture seule'
          : '${item.label}, configurable dans l’événement',
      child: PokeMapCard(
        borderRadius: 5,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            Icon(item.icon, size: 12, color: toneColors.icon),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (readOnly)
                    const Text(
                      'Défini dans la Scene',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: 3),
              const Icon(CupertinoIcons.lock, size: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  const _LibraryItem(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;
  final PokeMapTone tone;
}
~~~~


### 14.4 `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart`

~~~~dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2Editor extends StatelessWidget {
  const EventBuilderV2Editor({
    super.key,
    required this.event,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onAddCondition,
    this.onChangeScene,
    this.onOpenScene,
    this.onChangeBehavior,
  });

  final NarrativeEventProjectSummary? event;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onAddCondition;
  final VoidCallback? onChangeScene;
  final VoidCallback? onOpenScene;
  final VoidCallback? onChangeBehavior;

  @override
  Widget build(BuildContext context) {
    final selected = event;
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Éditeur d’événement',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.title ?? 'Aucun événement sélectionné',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected != null)
              PokeMapBadge(
                label: _eventStatusLabel(selected),
                variant: _eventBadgeVariant(selected),
                icon: Icon(
                  selected.readOnly
                      ? CupertinoIcons.lock
                      : selected.enabled == true
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                ),
              ),
          ],
        ),
      ),
      child: selected == null
          ? const PokeMapEmptyState(
              title: 'Sélectionnez un événement',
              description:
                  'Son déclencheur, ses conditions et sa Scene apparaîtront ici.',
              icon: Icon(CupertinoIcons.bolt_horizontal_circle),
            )
          : ListView(
              key: const ValueKey('event-builder-v2-editor-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 18),
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    key: const ValueKey('event-builder-v2-flow-rail'),
                    constraints: const BoxConstraints(maxWidth: 404),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-source-block',
                            ),
                            title: 'Déclencheur',
                            subtitle: selected.source.humanSentence,
                            icon: CupertinoIcons.bolt_fill,
                            tone: selected.source.available
                                ? PokeMapTone.narrative
                                : PokeMapTone.warning,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly)
                                PokeMapButton(
                                  onPressed: onChangeSource,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  child: Text(
                                    selected.source.source == null
                                        ? 'Choisir un élément'
                                        : selected.source.available
                                            ? 'Changer d’élément'
                                            : 'Rebrancher l’élément',
                                  ),
                                ),
                              if (_canOpenMap(selected))
                                PokeMapButton(
                                  onPressed: onSeeOnMap,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(
                                    CupertinoIcons.map_pin_ellipse,
                                  ),
                                  child: const Text('Voir sur la carte'),
                                ),
                            ],
                            details: [
                              _CompactProperty(
                                label: 'Type',
                                value: selected.source.sourceTypeLabel,
                              ),
                              if (selected.source.mapLabel != null)
                                _CompactProperty(
                                  label: 'Lieu',
                                  value: selected.source.mapLabel!,
                                ),
                            ],
                          ),
                          const _FlowConnector(),
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-conditions-block',
                            ),
                            title: 'Conditions',
                            subtitle: selected.conditions.humanLabel,
                            icon: CupertinoIcons.checkmark_alt_circle_fill,
                            tone: selected.conditions.valid
                                ? PokeMapTone.info
                                : PokeMapTone.warning,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly)
                                PokeMapButton(
                                  onPressed: onAddCondition,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(CupertinoIcons.add),
                                  child: const Text('Ajouter une condition'),
                                ),
                            ],
                            details: [
                              const _CompactProperty(
                                label: 'Mode',
                                value: 'Toutes doivent être remplies',
                              ),
                              _CompactProperty(
                                label: 'Ordre',
                                value: selected.conditions.count == 0
                                    ? 'Aucune condition'
                                    : '${selected.conditions.count} condition(s)',
                              ),
                            ],
                          ),
                          const _FlowConnector(),
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-scene-block',
                            ),
                            title: 'Scene à jouer',
                            subtitle: selected.scene.humanLabel,
                            icon: CupertinoIcons.play_rectangle_fill,
                            tone: selected.scene.valid
                                ? PokeMapTone.success
                                : PokeMapTone.warning,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly)
                                PokeMapButton(
                                  onPressed: onChangeScene,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  child: const Text('Choisir une Scene'),
                                ),
                              if (selected.scene.sceneId != null)
                                PokeMapButton(
                                  onPressed: onOpenScene,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  leading: const Icon(
                                    CupertinoIcons.arrow_up_right_square,
                                  ),
                                  child: const Text('Ouvrir la Scene'),
                                ),
                            ],
                          ),
                          const _FlowConnector(),
                          _SceneProjectionBlock(
                            event: selected,
                            onOpenScene: onOpenScene,
                          ),
                          const _FlowConnector(),
                          _EditorBlock(
                            key: const ValueKey(
                              'event-builder-v2-behavior-block',
                            ),
                            title: 'Comportement',
                            subtitle: selected.lifecycle.humanLabel,
                            icon: CupertinoIcons.repeat,
                            tone: PokeMapTone.brand,
                            readOnly: selected.readOnly,
                            actions: [
                              if (!selected.readOnly)
                                PokeMapButton(
                                  onPressed: onChangeBehavior,
                                  variant: PokeMapButtonVariant.ghost,
                                  size: PokeMapButtonSize.small,
                                  child: const Text('Modifier'),
                                ),
                            ],
                          ),
                          const _FlowConnector(),
                          const Center(
                            child: PokeMapBadge(
                              label: 'Fin de l’événement',
                              variant: PokeMapBadgeVariant.neutral,
                              icon: Icon(CupertinoIcons.flag),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EditorBlock extends StatelessWidget {
  const _EditorBlock({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.readOnly,
    this.details = const [],
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PokeMapTone tone;
  final bool readOnly;
  final List<Widget> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly ? '$title, lecture seule' : title,
      child: PokeMapCard(
        borderRadius: 7,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokeMapIconTile(
                  icon: icon,
                  tone: tone,
                  size: 30,
                  iconSize: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: toneColors.text,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                          if (readOnly)
                            const PokeMapBadge(
                              label: 'Lecture seule',
                              variant: PokeMapBadgeVariant.neutral,
                              icon: Icon(CupertinoIcons.lock),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 7),
              for (var index = 0; index < details.length; index++) ...[
                details[index],
                if (index < details.length - 1) const SizedBox(height: 4),
              ],
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 6, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactProperty extends StatelessWidget {
  const _CompactProperty({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value, lecture seule',
      child: PokeMapCard(
        borderRadius: 6,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(CupertinoIcons.lock, size: 10),
          ],
        ),
      ),
    );
  }
}

class _SceneProjectionBlock extends StatelessWidget {
  const _SceneProjectionBlock({required this.event, this.onOpenScene});

  final NarrativeEventProjectSummary event;
  final VoidCallback? onOpenScene;

  @override
  Widget build(BuildContext context) {
    final projection = event.projection;
    final outcomes = projection.outcomeLabels;
    return Semantics(
      container: true,
      label: 'Projections de la Scene, lecture seule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProjectionBand(
            title: 'Résultats possibles',
            icon: CupertinoIcons.flag_fill,
            tone: PokeMapTone.info,
          ),
          const SizedBox(height: 6),
          _OutcomeBranches(outcomes: outcomes),
          const SizedBox(height: 7),
          _ProjectionGroup(
            title: 'Réactions et conséquences',
            icon: CupertinoIcons.bolt_circle_fill,
            tone: PokeMapTone.warning,
            emptyLabel: 'Aucune conséquence détectée dans la Scene.',
            labels: [
              for (final consequence in projection.consequences)
                consequence.humanLabel,
            ],
          ),
          const SizedBox(height: 7),
          _ProjectionGroup(
            title: 'Changements du monde',
            icon: CupertinoIcons.globe,
            tone: PokeMapTone.map,
            emptyLabel: 'Aucun changement du monde détecté.',
            labels: [
              for (final rule in projection.worldRules) rule.humanLabel,
            ],
          ),
          if (event.scene.sceneId != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: PokeMapButton(
                onPressed: onOpenScene,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.arrow_up_right_square),
                child: const Text('Voir dans la Scene'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectionBand extends StatelessWidget {
  const _ProjectionBand({
    required this.title,
    required this.icon,
    required this.tone,
  });

  final String title;
  final IconData icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 6,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 13, color: toneColors.icon),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: toneColors.text,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
              ),
            ),
          ),
          const PokeMapBadge(
            label: 'Lecture seule',
            variant: PokeMapBadgeVariant.neutral,
            icon: Icon(CupertinoIcons.lock),
          ),
        ],
      ),
    );
  }
}

class _OutcomeBranches extends StatelessWidget {
  const _OutcomeBranches({required this.outcomes});

  final List<String> outcomes;

  @override
  Widget build(BuildContext context) {
    final count = outcomes.length;
    return KeyedSubtree(
      key: ValueKey('event-builder-v2-outcomes-$count'),
      child: switch (count) {
        0 => const _ProjectionEmpty(
            label: 'Aucun résultat déclaré dans la Scene.',
          ),
        1 => _OutcomeCard(label: outcomes.single),
        2 => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _OutcomeCard(label: outcomes[0])),
              const SizedBox(width: 8),
              Expanded(child: _OutcomeCard(label: outcomes[1])),
            ],
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < outcomes.length; index++) ...[
                _OutcomeCard(label: outcomes[index]),
                if (index < outcomes.length - 1) const SizedBox(height: 5),
              ],
            ],
          ),
      },
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // The projection currently carries display labels, not typed outcome
    // semantics. A neutral narrative treatment avoids presenting the first
    // item as success and the second as failure when a Scene orders them
    // differently.
    const tone = PokeMapTone.narrative;
    final toneColors = tone.resolve(context);
    return Semantics(
      label: '$label, résultat de Scene, lecture seule',
      child: PokeMapCard(
        borderRadius: 6,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.flag_fill,
              size: 13,
              color: toneColors.icon,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectionGroup extends StatelessWidget {
  const _ProjectionGroup({
    required this.title,
    required this.icon,
    required this.tone,
    required this.emptyLabel,
    required this.labels,
  });

  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final String emptyLabel;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 7,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: toneColors.icon),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.lock, size: 10),
            ],
          ),
          const SizedBox(height: 6),
          if (labels.isEmpty)
            _ProjectionEmpty(label: emptyLabel)
          else
            for (var index = 0; index < labels.length; index++) ...[
              _ProjectionLine(label: labels[index], tone: tone),
              if (index < labels.length - 1) const SizedBox(height: 4),
            ],
        ],
      ),
    );
  }
}

class _ProjectionLine extends StatelessWidget {
  const _ProjectionLine({required this.label, required this.tone});

  final String label;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      borderRadius: 5,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.eye, size: 11, color: tone.resolve(context).icon),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionEmpty extends StatelessWidget {
  const _ProjectionEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Icon(CupertinoIcons.eye_slash, size: 12),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    final connector = PokeMapTone.neutral.resolve(context).border;
    return SizedBox(
      height: 18,
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.circle_fill, size: 4, color: connector),
            Expanded(child: Container(width: 1, color: connector)),
            Icon(CupertinoIcons.circle_fill, size: 4, color: connector),
          ],
        ),
      ),
    );
  }
}

bool _canOpenMap(NarrativeEventProjectSummary event) {
  final source = event.source.source;
  if (!event.source.available || source == null) return false;
  return source.when(
    entityInteract: (_, __) => true,
    triggerEnter: (_, __) => true,
    mapEnter: (_) => true,
    outcomeReceived: (_) => false,
  );
}

String _eventStatusLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Lecture seule';
  if (event.enabled == true) return 'Actif';
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return 'Brouillon';
  }
  return 'Inactif';
}

PokeMapBadgeVariant _eventBadgeVariant(NarrativeEventProjectSummary event) {
  if (event.readOnly) return PokeMapBadgeVariant.warning;
  if (event.enabled == true) return PokeMapBadgeVariant.success;
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return PokeMapBadgeVariant.neutral;
  }
  return PokeMapBadgeVariant.info;
}
~~~~


### 14.5 `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`

~~~~dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2Inspector extends StatelessWidget {
  const EventBuilderV2Inspector({
    super.key,
    required this.event,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onOpenScene,
    this.onManageEvaluationOrder,
  });

  final NarrativeEventProjectSummary? event;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onOpenScene;
  final VoidCallback? onManageEvaluationOrder;

  @override
  Widget build(BuildContext context) {
    final selected = event;
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(16, 11, 16, 9),
        child: Text(
          'INSPECTEUR D’ÉVÉNEMENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
      ),
      child: selected == null
          ? const PokeMapEmptyState(
              title: 'Aucun événement sélectionné',
              description: 'Choisissez un événement dans la liste du projet.',
              icon: Icon(CupertinoIcons.slider_horizontal_3),
            )
          : ListView(
              key: const ValueKey('event-builder-v2-inspector-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 18),
              children: [
                _InspectorSummary(event: selected),
                const SizedBox(height: 15),
                _InspectorSection(
                  key: const ValueKey('event-builder-v2-inspector-source'),
                  title: 'Élément déclencheur',
                  tone: selected.source.available
                      ? PokeMapTone.narrative
                      : PokeMapTone.warning,
                  children: [
                    _InspectorField(
                      label: 'Type',
                      value: selected.source.sourceTypeLabel,
                      icon: CupertinoIcons.bolt_fill,
                      tone: selected.source.available
                          ? PokeMapTone.narrative
                          : PokeMapTone.warning,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'Cible',
                      value: selected.source.humanSentence,
                      icon: selected.source.available
                          ? CupertinoIcons.person_crop_circle
                          : CupertinoIcons.exclamationmark_triangle_fill,
                      tone: selected.source.available
                          ? PokeMapTone.narrative
                          : PokeMapTone.warning,
                    ),
                    if (selected.source.mapLabel != null) ...[
                      const SizedBox(height: 5),
                      _InspectorField(
                        label: 'Lieu dérivé · lecture seule',
                        value: selected.source.mapLabel!,
                        icon: CupertinoIcons.map_fill,
                        tone: PokeMapTone.map,
                      ),
                    ],
                    if (!selected.readOnly) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PokeMapButton(
                            onPressed: onChangeSource,
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.secondary,
                            child: Text(
                              selected.source.source == null
                                  ? 'Choisir un élément'
                                  : selected.source.available
                                      ? 'Changer d’élément'
                                      : 'Rebrancher l’élément',
                            ),
                          ),
                          if (_isSpatialAndAvailable(selected))
                            PokeMapButton(
                              onPressed: onSeeOnMap,
                              size: PokeMapButtonSize.small,
                              variant: PokeMapButtonVariant.ghost,
                              leading: const Icon(
                                CupertinoIcons.map_pin_ellipse,
                              ),
                              child: const Text('Voir sur la carte'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 13),
                _InspectorSection(
                  key: const ValueKey(
                    'event-builder-v2-inspector-conditions',
                  ),
                  title: 'Conditions',
                  tone: selected.conditions.valid
                      ? PokeMapTone.info
                      : PokeMapTone.warning,
                  children: [
                    const _InspectorField(
                      label: 'Mode',
                      value: 'Toutes doivent être remplies',
                      icon: CupertinoIcons.checkmark_alt_circle_fill,
                      tone: PokeMapTone.info,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'Configuration',
                      value: selected.conditions.humanLabel,
                      icon: selected.conditions.valid
                          ? CupertinoIcons.list_bullet
                          : CupertinoIcons.exclamationmark_triangle_fill,
                      tone: selected.conditions.valid
                          ? PokeMapTone.info
                          : PokeMapTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _InspectorSection(
                  key: const ValueKey('event-builder-v2-inspector-scene'),
                  title: 'Scene liée',
                  tone: selected.scene.valid
                      ? PokeMapTone.success
                      : PokeMapTone.warning,
                  readOnly: true,
                  children: [
                    _InspectorField(
                      label: 'Orchestration',
                      value: selected.scene.humanLabel,
                      icon: CupertinoIcons.play_rectangle_fill,
                      tone: selected.scene.valid
                          ? PokeMapTone.success
                          : PokeMapTone.warning,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'Résultats · lecture seule',
                      value: _outcomeCountLabel(
                        selected.projection.outcomeLabels.length,
                      ),
                      icon: CupertinoIcons.flag_fill,
                      tone: PokeMapTone.narrative,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'Réactions · lecture seule',
                      value: _projectionCountLabel(
                        selected.projection.consequences.length,
                        singular: 'conséquence',
                        plural: 'conséquences',
                      ),
                      icon: CupertinoIcons.bolt_circle_fill,
                      tone: PokeMapTone.warning,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'Monde · lecture seule',
                      value: _projectionCountLabel(
                        selected.projection.worldRules.length,
                        singular: 'règle projetée',
                        plural: 'règles projetées',
                      ),
                      icon: CupertinoIcons.globe,
                      tone: PokeMapTone.map,
                    ),
                    if (selected.scene.sceneId != null) ...[
                      const SizedBox(height: 7),
                      PokeMapButton(
                        onPressed: onOpenScene,
                        size: PokeMapButtonSize.small,
                        variant: PokeMapButtonVariant.ghost,
                        leading: const Icon(
                          CupertinoIcons.arrow_up_right_square,
                        ),
                        child: const Text('Ouvrir la Scene'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 13),
                _InspectorSection(
                  key: const ValueKey('event-builder-v2-inspector-behavior'),
                  title: 'Comportement',
                  tone: PokeMapTone.brand,
                  children: [
                    _InspectorField(
                      label: 'Réutilisation',
                      value: selected.lifecycle.humanLabel,
                      icon: CupertinoIcons.repeat,
                      tone: PokeMapTone.brand,
                    ),
                    const SizedBox(height: 5),
                    _InspectorField(
                      label: 'État',
                      value: _eventStateLabel(selected),
                      icon: selected.enabled == true
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.pause_circle_fill,
                      tone: selected.enabled == true
                          ? PokeMapTone.success
                          : PokeMapTone.neutral,
                    ),
                  ],
                ),
                if (onManageEvaluationOrder != null) ...[
                  const SizedBox(height: 13),
                  _InspectorSection(
                    key: const ValueKey(
                      'event-builder-v2-inspector-conflict',
                    ),
                    title: 'Concurrence sur cet élément',
                    tone: PokeMapTone.warning,
                    children: [
                      const _InspectorField(
                        label: 'Ordre d’évaluation',
                        value:
                            'Le suivant peut être évalué si le premier est inéligible.',
                        icon: CupertinoIcons.list_number,
                        tone: PokeMapTone.warning,
                      ),
                      const SizedBox(height: 7),
                      PokeMapButton(
                        onPressed: onManageEvaluationOrder,
                        size: PokeMapButtonSize.small,
                        variant: PokeMapButtonVariant.ghost,
                        child: const Text(
                          'Gérer l’ordre de déclenchement',
                        ),
                      ),
                    ],
                  ),
                ],
                if (selected.diagnostics.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  _InspectorSection(
                    key: const ValueKey(
                      'event-builder-v2-inspector-diagnostics',
                    ),
                    title: 'À vérifier',
                    tone: _diagnosticTone(selected.diagnostics.first.severity),
                    children: [
                      for (var index = 0;
                          index < selected.diagnostics.length;
                          index++) ...[
                        _InspectorField(
                          label: _diagnosticLabel(
                            selected.diagnostics[index].severity,
                          ),
                          value: selected.diagnostics[index].message,
                          icon: _diagnosticIcon(
                            selected.diagnostics[index].severity,
                          ),
                          tone: _diagnosticTone(
                            selected.diagnostics[index].severity,
                          ),
                        ),
                        if (index < selected.diagnostics.length - 1)
                          const SizedBox(height: 5),
                      ],
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _InspectorSummary extends StatelessWidget {
  const _InspectorSummary({required this.event});

  final NarrativeEventProjectSummary event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokeMapIconTile(
          icon: CupertinoIcons.bolt_horizontal_circle_fill,
          tone: event.readOnly ? PokeMapTone.warning : PokeMapTone.narrative,
          size: 44,
          iconSize: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  PokeMapBadge(
                    label: event.readOnly
                        ? 'Ancien format à convertir'
                        : _eventStateLabel(event),
                    variant: event.readOnly
                        ? PokeMapBadgeVariant.warning
                        : event.enabled == true
                            ? PokeMapBadgeVariant.success
                            : PokeMapBadgeVariant.neutral,
                    icon: Icon(
                      event.readOnly
                          ? CupertinoIcons.lock
                          : event.enabled == true
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                    ),
                  ),
                  if (event.readOnly)
                    const PokeMapBadge(
                      label: 'Lecture seule',
                      variant: PokeMapBadgeVariant.neutral,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    super.key,
    required this.title,
    required this.tone,
    required this.children,
    this.readOnly = false,
  });

  final String title;
  final PokeMapTone tone;
  final List<Widget> children;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly ? '$title, lecture seule' : title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.circle_fill, size: 5, color: toneColors.icon),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (readOnly)
                const PokeMapBadge(
                  label: 'Lecture seule',
                  variant: PokeMapBadgeVariant.neutral,
                  icon: Icon(CupertinoIcons.lock),
                ),
            ],
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}

class _InspectorField extends StatelessWidget {
  const _InspectorField({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 6,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: toneColors.icon),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: toneColors.text,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSpatialAndAvailable(NarrativeEventProjectSummary event) {
  final source = event.source.source;
  if (source == null || !event.source.available) return false;
  return source.when(
    entityInteract: (_, __) => true,
    triggerEnter: (_, __) => true,
    mapEnter: (_) => true,
    outcomeReceived: (_) => false,
  );
}

String _outcomeCountLabel(int count) => switch (count) {
      0 => 'Aucun résultat déclaré',
      1 => '1 résultat projeté',
      _ => '$count résultats projetés',
    };

String _projectionCountLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  if (count == 0) return 'Aucun $singular';
  if (count == 1) return '1 $singular';
  return '$count $plural';
}

String _eventStateLabel(NarrativeEventProjectSummary event) {
  if (event.readOnly) return 'Lecture seule';
  if (event.enabled == true) return 'Actif';
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return 'Brouillon';
  }
  return 'Inactif';
}

String _diagnosticLabel(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => 'Information',
      NarrativeEventProjectSummarySeverity.warning => 'Avertissement',
      NarrativeEventProjectSummarySeverity.error => 'Erreur',
    };

IconData _diagnosticIcon(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => CupertinoIcons.info_circle,
      NarrativeEventProjectSummarySeverity.warning =>
        CupertinoIcons.exclamationmark_triangle_fill,
      NarrativeEventProjectSummarySeverity.error =>
        CupertinoIcons.xmark_octagon_fill,
    };

PokeMapTone _diagnosticTone(NarrativeEventProjectSummarySeverity severity) =>
    switch (severity) {
      NarrativeEventProjectSummarySeverity.info => PokeMapTone.info,
      NarrativeEventProjectSummarySeverity.warning => PokeMapTone.warning,
      NarrativeEventProjectSummarySeverity.error => PokeMapTone.danger,
    };
~~~~


### 14.6 `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`

~~~~dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/state/narrative_event_builder_v2_state.dart';
import '../../design_system/design_system.dart';
import 'event_builder_v2_editor.dart';
import 'event_builder_v2_element_library.dart';
import 'event_builder_v2_inspector.dart';
import 'event_builder_v2_project_list.dart';

class EventBuilderV2Workspace extends StatefulWidget {
  const EventBuilderV2Workspace({
    super.key,
    required this.state,
    required this.mode,
    required this.selectedStableKey,
    required this.viewportWidth,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSelectEvent,
    required this.onCreateEvent,
    required this.onOpenLibrary,
    this.onChangeSource,
    this.onSeeOnMap,
    this.onAddCondition,
    this.onChangeScene,
    this.onOpenScene,
    this.onChangeBehavior,
    this.onManageEvaluationOrder,
  });

  final NarrativeEventBuilderV2State state;
  final EventSystemMode mode;
  final String? selectedStableKey;
  final double viewportWidth;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<NarrativeEventBuilderV2Filter> onFilterChanged;
  final ValueChanged<NarrativeEventProjectSummary> onSelectEvent;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onChangeSource;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onAddCondition;
  final VoidCallback? onChangeScene;
  final VoidCallback? onOpenScene;
  final VoidCallback? onChangeBehavior;
  final VoidCallback? onManageEvaluationOrder;

  @override
  State<EventBuilderV2Workspace> createState() =>
      _EventBuilderV2WorkspaceState();
}

class _EventBuilderV2WorkspaceState extends State<EventBuilderV2Workspace> {
  late final TextEditingController _searchController;
  final FocusNode _libraryLauncherFocusNode = FocusNode(
    debugLabel: 'Event Builder V2 library launcher',
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant EventBuilderV2Workspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.state.query) {
      _searchController.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _libraryLauncherFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewportWidth < 1280) {
      return const PokeMapPageSurface(
        padding: EdgeInsets.zero,
        child: PokeMapEmptyState(
          title: 'Fenêtre trop étroite',
          description:
              'Agrandissez la fenêtre à au moins 1280 px. Votre sélection est conservée.',
          icon: Icon(CupertinoIcons.rectangle_expand_vertical),
        ),
      );
    }

    final selected = widget.selectedStableKey == null
        ? null
        : widget.state.readModel.eventByStableKey(
            widget.selectedStableKey!,
          );
    final controls = Row(
      children: [
        Expanded(
          child: PokeMapSearchField(
            key: const ValueKey('event-builder-v2-search'),
            controller: _searchController,
            onChanged: widget.onQueryChanged,
            hintText: 'Rechercher un événement…',
            semanticLabel: 'Rechercher dans tous les événements du projet',
          ),
        ),
        const SizedBox(width: 6),
        PokeMapIconButton(
          key: const ValueKey('event-builder-v2-filter-button'),
          onPressed: () => _openFilterSheet(context),
          icon: const Icon(CupertinoIcons.square_grid_2x2),
          tooltip: 'Filtrer les événements',
          size: 34,
        ),
      ],
    );

    return Semantics(
      container: true,
      label: 'Event Builder V2, vue projet',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The desktop viewport alone is not enough when this workspace is
          // nested inside project chrome. Keep the fifth panel inline only
          // when the business area can honor its 1280 px minimum budget.
          final inlineLibrary =
              widget.viewportWidth >= 1480 && constraints.maxWidth >= 1280;
          final metrics = _EventBuilderV2LayoutMetrics.resolve(
            availableWidth: constraints.maxWidth,
            inlineLibrary: inlineLibrary,
            referenceViewport: widget.viewportWidth >= 1672,
          );

          final list = SizedBox(
            key: const ValueKey('event-builder-v2-list'),
            width: metrics.listWidth,
            child: EventBuilderV2ProjectList(
              groups: widget.state.visibleGroups,
              projectEventCount: widget.state.readModel.events.length,
              selectedStableKey: widget.selectedStableKey,
              controls: controls,
              projectIsEmpty: widget.state.isProjectEmpty,
              hasNoMatchingEvents: widget.state.hasNoMatchingEvents,
              onSelectEvent: widget.onSelectEvent,
              onCreateEvent:
                  widget.state.isReadOnly ? null : widget.onCreateEvent,
            ),
          );

          final editor = SizedBox(
            key: const ValueKey('event-builder-v2-editor'),
            width: metrics.editorWidth,
            child: inlineLibrary
                ? EventBuilderV2Editor(
                    event: selected,
                    onChangeSource: widget.onChangeSource,
                    onSeeOnMap: widget.onSeeOnMap,
                    onAddCondition: widget.onAddCondition,
                    onChangeScene: widget.onChangeScene,
                    onOpenScene: widget.onOpenScene,
                    onChangeBehavior: widget.onChangeBehavior,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PokeMapToolbarSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PokeMapButton(
                            key: const ValueKey(
                              'event-builder-v2-open-library',
                            ),
                            // The side sheet captures the current focus before
                            // opening and restores this exact launcher on close.
                            focusNode: _libraryLauncherFocusNode,
                            onPressed: widget.onOpenLibrary,
                            variant: PokeMapButtonVariant.ghost,
                            size: PokeMapButtonSize.small,
                            leading: const Icon(CupertinoIcons.square_grid_2x2),
                            child: const Text('Ouvrir la bibliothèque'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: EventBuilderV2Editor(
                          event: selected,
                          onChangeSource: widget.onChangeSource,
                          onSeeOnMap: widget.onSeeOnMap,
                          onAddCondition: widget.onAddCondition,
                          onChangeScene: widget.onChangeScene,
                          onOpenScene: widget.onOpenScene,
                          onChangeBehavior: widget.onChangeBehavior,
                        ),
                      ),
                    ],
                  ),
          );

          final inspector = SizedBox(
            key: const ValueKey('event-builder-v2-inspector'),
            width: metrics.inspectorWidth,
            child: EventBuilderV2Inspector(
              event: selected,
              onChangeSource: widget.onChangeSource,
              onSeeOnMap: widget.onSeeOnMap,
              onOpenScene: widget.onOpenScene,
              onManageEvaluationOrder: widget.onManageEvaluationOrder,
            ),
          );

          final children = <Widget>[
            list,
            const SizedBox(width: 8),
            if (inlineLibrary) ...[
              SizedBox(
                key: const ValueKey('event-builder-v2-library'),
                width: metrics.libraryWidth,
                child: EventBuilderV2ElementLibrary(
                  hasLinkedScene: selected?.scene.sceneId != null,
                  onOpenScene: widget.onOpenScene,
                ),
              ),
              const SizedBox(width: 8),
            ],
            editor,
            const SizedBox(width: 8),
            inspector,
          ];

          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

          if (widget.mode != EventSystemMode.legacyOnly) {
            return content;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'Runtime en mode historique',
                message:
                    'Les événements V2 sont conservés mais ne seront pas joués tant que le projet reste dans ce mode.',
              ),
              const SizedBox(height: 8),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Filtrer les événements',
      semanticLabel: 'Choisir les événements à afficher',
      width: 320,
      builder: (sheetContext) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final filter in NarrativeEventBuilderV2Filter.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: PokeMapSidebarItem(
                label: filter.label,
                selected: widget.state.filter == filter,
                icon: Icon(_filterIcon(filter)),
                onTap: () {
                  widget.onFilterChanged(filter);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}

IconData _filterIcon(NarrativeEventBuilderV2Filter filter) => switch (filter) {
      NarrativeEventBuilderV2Filter.all => CupertinoIcons.square_grid_2x2,
      NarrativeEventBuilderV2Filter.active => CupertinoIcons.checkmark_circle,
      NarrativeEventBuilderV2Filter.drafts => CupertinoIcons.pencil,
      NarrativeEventBuilderV2Filter.attention =>
        CupertinoIcons.exclamationmark_triangle,
      NarrativeEventBuilderV2Filter.oldFormat => CupertinoIcons.archivebox,
    };

class _EventBuilderV2LayoutMetrics {
  const _EventBuilderV2LayoutMetrics({
    required this.listWidth,
    required this.libraryWidth,
    required this.editorWidth,
    required this.inspectorWidth,
  });

  final double listWidth;
  final double libraryWidth;
  final double editorWidth;
  final double inspectorWidth;

  static _EventBuilderV2LayoutMetrics resolve({
    required double availableWidth,
    required bool inlineLibrary,
    required bool referenceViewport,
  }) {
    if (!inlineLibrary) {
      const list = 220.0;
      const inspector = 320.0;
      final editor = (availableWidth - list - inspector - 16).clamp(
        480.0,
        double.infinity,
      );
      return _EventBuilderV2LayoutMetrics(
        listWidth: list,
        libraryWidth: 0,
        editorWidth: editor,
        inspectorWidth: inspector,
      );
    }

    if (referenceViewport && availableWidth >= 1456) {
      const list = 266.0;
      const library = 213.0;
      const inspector = 388.0;
      final editor = availableWidth - list - library - inspector - 24;
      return _EventBuilderV2LayoutMetrics(
        listWidth: list,
        libraryWidth: library,
        editorWidth: editor,
        inspectorWidth: inspector,
      );
    }

    const list = 236.0;
    const library = 190.0;
    const inspector = 330.0;
    final editor = (availableWidth - list - library - inspector - 24).clamp(
      500.0,
      double.infinity,
    );
    return _EventBuilderV2LayoutMetrics(
      listWidth: list,
      libraryWidth: library,
      editorWidth: editor,
      inspectorWidth: inspector,
    );
  }
}
~~~~


### 14.7 `packages/map_editor/lib/src/ui/design_system/pokemap_search_field.dart`

~~~~dart
import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_icon_button.dart';

/// Compact, token-driven search input for dense editor panels.
class PokeMapSearchField extends StatefulWidget {
  const PokeMapSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hintText = 'Rechercher…',
    this.semanticLabel,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String? semanticLabel;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  @override
  State<PokeMapSearchField> createState() => _PokeMapSearchFieldState();
}

class _PokeMapSearchFieldState extends State<PokeMapSearchField> {
  late final TextEditingController _ownedController;
  late final FocusNode _ownedFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    _ownedController = TextEditingController();
    _ownedFocusNode = FocusNode();
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PokeMapSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? _ownedController;
    if (oldController != _controller) {
      oldController.removeListener(_handleControllerChanged);
      _controller.addListener(_handleControllerChanged);
    }
    final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode;
    if (oldFocusNode != _focusNode) {
      oldFocusNode.removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _ownedController.dispose();
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
    if (widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final hasText = _controller.text.isNotEmpty;
    final isFocused = _focusNode.hasFocus;

    return Semantics(
      container: true,
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.hintText,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 34,
        padding: const EdgeInsets.only(left: 10, right: 3),
        decoration: BoxDecoration(
          color: colors.controlSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused && widget.enabled
                ? colors.focusRing
                : colors.controlBorder,
            width: isFocused && widget.enabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.search_rounded,
                size: 16,
                color: widget.enabled ? colors.textMuted : colors.textDisabled,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: TextStyle(
                  color:
                      widget.enabled ? colors.textPrimary : colors.textDisabled,
                  fontSize: 12,
                  height: 1.2,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color:
                        widget.enabled ? colors.textMuted : colors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (hasText)
              PokeMapIconButton(
                onPressed: widget.enabled ? _clear : null,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Effacer la recherche',
                size: 27,
              ),
          ],
        ),
      ),
    );
  }
}
~~~~


### 14.8 `packages/map_editor/lib/src/ui/design_system/pokemap_diagnostic_callout.dart`

~~~~dart
import 'package:flutter/material.dart';

import 'pokemap_button.dart';
import 'pokemap_tone.dart';

/// Severity levels for editor diagnostics.
enum PokeMapDiagnosticSeverity {
  info,
  warning,
  error,
}

/// Dense diagnostic message with text, icon, semantics and an optional action.
class PokeMapDiagnosticCallout extends StatelessWidget {
  const PokeMapDiagnosticCallout({
    super.key,
    required this.severity,
    required this.message,
    this.title,
    this.semanticLabel,
    this.actionLabel,
    this.onAction,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'actionLabel and onAction must be provided together.',
        );

  final PokeMapDiagnosticSeverity severity;
  final String message;
  final String? title;
  final String? semanticLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tone = switch (severity) {
      PokeMapDiagnosticSeverity.info => PokeMapTone.info,
      PokeMapDiagnosticSeverity.warning => PokeMapTone.warning,
      PokeMapDiagnosticSeverity.error => PokeMapTone.danger,
    };
    final toneColors = tone.resolve(context);
    final icon = switch (severity) {
      PokeMapDiagnosticSeverity.info => Icons.info_outline_rounded,
      PokeMapDiagnosticSeverity.warning => Icons.warning_amber_rounded,
      PokeMapDiagnosticSeverity.error => Icons.error_outline_rounded,
    };
    final severityLabel = switch (severity) {
      PokeMapDiagnosticSeverity.info => 'Information',
      PokeMapDiagnosticSeverity.warning => 'Avertissement',
      PokeMapDiagnosticSeverity.error => 'Erreur',
    };
    final defaultSemanticLabel = <String>[
      severityLabel,
      if (title != null && title!.trim().isNotEmpty) title!.trim(),
      message.trim(),
    ].join('. ');

    return Semantics(
      container: true,
      liveRegion: severity == PokeMapDiagnosticSeverity.error,
      label: semanticLabel ?? defaultSemanticLabel,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: toneColors.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: toneColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 17, color: toneColors.icon),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title!.trim().isNotEmpty) ...[
                          Text(
                            title!,
                            style: TextStyle(
                              color: toneColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          message,
                          style: TextStyle(
                            color: toneColors.text,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    PokeMapButton(
                      onPressed: onAction,
                      variant: PokeMapButtonVariant.ghost,
                      size: PokeMapButtonSize.small,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
~~~~


### 14.9 `packages/map_editor/lib/src/ui/design_system/pokemap_desktop_side_sheet.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

/// Opens a token-driven modal side sheet and restores the caller's focus.
Future<T?> showPokeMapDesktopSideSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  String? semanticLabel,
  String barrierLabel = 'Fermer le panneau latéral',
  FocusNode? initialFocusNode,
  double width = 420,
  bool barrierDismissible = true,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  final colors = context.pokeMapColors;

  final result = await showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 160),
    requestFocus: true,
    pageBuilder: (routeContext, animation, secondaryAnimation) {
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedWidth = width.clamp(280.0, constraints.maxWidth);
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: resolvedWidth,
                height: constraints.maxHeight,
                child: PokeMapDesktopSideSheet(
                  title: title,
                  semanticLabel: semanticLabel,
                  initialFocusNode: initialFocusNode,
                  onClose: () => Navigator.of(routeContext).maybePop(),
                  child: builder(routeContext),
                ),
              ),
            );
          },
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (previousFocus?.context != null && previousFocus!.canRequestFocus) {
    previousFocus.requestFocus();
  }
  return result;
}

/// Right-aligned desktop sheet surface used by [showPokeMapDesktopSideSheet].
class PokeMapDesktopSideSheet extends StatefulWidget {
  const PokeMapDesktopSideSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.semanticLabel,
    this.initialFocusNode,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;
  final String? semanticLabel;
  final FocusNode? initialFocusNode;

  @override
  State<PokeMapDesktopSideSheet> createState() =>
      _PokeMapDesktopSideSheetState();
}

class _PokeMapDesktopSideSheetState extends State<PokeMapDesktopSideSheet> {
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'side sheet close');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _requestInitialFocus() {
    if (!mounted) {
      return;
    }
    final initialFocusNode = widget.initialFocusNode;
    if (initialFocusNode?.context != null &&
        initialFocusNode!.canRequestFocus) {
      initialFocusNode.requestFocus();
      return;
    }
    _closeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      label: widget.semanticLabel ?? widget.title,
      explicitChildNodes: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: FocusScope(
            child: Material(
              color: colors.surfaceRaised,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                side: BorderSide(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Fermer',
                            child: IconButton(
                              focusNode: _closeFocusNode,
                              onPressed: widget.onClose,
                              style: IconButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                                hoverColor: colors.cardHover,
                                focusColor: colors.cardSelected,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.divider),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
~~~~


### 14.10 `packages/map_editor/test/narrative_event_builder_v2_session_snapshot_test.dart`

~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  test('Phase H session exposes its exact project read-model snapshot',
      () async {
    final fixture = await createPersistenceFixture(
      registry: persistenceRegistry(mode: EventSystemMode.v2Only),
    );
    addTearDown(fixture.dispose);

    final session = await NarrativeEventAuthoringSession.prepare(
      fixture.projectPath,
    );
    final readModel = buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );

    expect(session.manifest.name, 'Phase E fixture');
    expect(session.maps.map((map) => map.id), ['map_a']);
    expect(readModel.events.single.eventId, persistenceEventA);
    expect(() => session.maps.add(session.maps.single), throwsUnsupportedError);
  });
}
~~~~


### 14.11 `packages/map_editor/test/narrative_event_builder_v2_state_test.dart`

~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

const _portEventId = 'evt_00000000-0000-7000-8000-000000000101';
const _forestEventId = 'evt_00000000-0000-7000-8000-000000000102';
const _draftEventId = 'evt_00000000-0000-7000-8000-000000000103';
const _missingEventId = 'evt_00000000-0000-7000-8000-000000000104';
const _outcomeEventId = 'evt_00000000-0000-7000-8000-000000000105';

void main() {
  group('NS-EVENT-V2-26 project-level Event Builder state', () {
    test('preserves every project group without an active-map input', () {
      final readModel = _projectReadModel();

      final state = NarrativeEventBuilderV2State(readModel: readModel);

      expect(
        state.visibleGroups.map((group) => group.stableKey),
        readModel.groups.map((group) => group.stableKey),
      );
      expect(
        state.visibleGroups.map((group) => group.kind).toSet(),
        containsAll(<NarrativeEventProjectGroupKind>{
          NarrativeEventProjectGroupKind.map,
          NarrativeEventProjectGroupKind.outcomes,
          NarrativeEventProjectGroupKind.drafts,
          NarrativeEventProjectGroupKind.missingReferences,
          NarrativeEventProjectGroupKind.legacyCompatibility,
        }),
      );
      expect(
        state.visibleGroups
            .where((group) => group.kind == NarrativeEventProjectGroupKind.map)
            .map((group) => group.label),
        containsAll(<String>['Port des Brisants', 'Forêt Brumeuse']),
      );
    });

    test('searches only human-facing text and keeps source ordering', () {
      final readModel = _projectReadModel();
      final controller = NarrativeEventBuilderV2Controller(
        readModel: readModel,
        selectEvent: _rejectSelection,
      );

      controller.setQuery('foret brumeuse');

      expect(controller.state.visibleEvents, hasLength(1));
      expect(controller.state.visibleEvents.single.eventId, _forestEventId);
      expect(
        controller.state.visibleGroups.map((group) => group.stableKey),
        readModel.groups
            .where((group) =>
                group.events.any((event) => event.eventId == _forestEventId))
            .map((group) => group.stableKey),
      );

      controller.setQuery('evt_00000000');
      expect(controller.state.visibleEvents, isEmpty);
    });

    test('offers deterministic human filters without re-sorting groups', () {
      final readModel = _projectReadModel();
      final controller = NarrativeEventBuilderV2Controller(
        readModel: readModel,
        selectEvent: _rejectSelection,
      );

      final expectedGroupOrder = readModel.groups
          .map((group) => group.stableKey)
          .toList(growable: false);
      for (final filter in NarrativeEventBuilderV2Filter.values) {
        expect(filter.label, isNotEmpty);
        expect(filter.label, isNot(contains('legacy')));
        controller.setFilter(filter);
        final actualOrder = controller.state.visibleGroups
            .map((group) => group.stableKey)
            .toList(growable: false);
        expect(
          actualOrder,
          orderedEquals([
            for (final key in expectedGroupOrder)
              if (actualOrder.contains(key)) key,
          ]),
        );
      }

      controller.setFilter(NarrativeEventBuilderV2Filter.active);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId).toSet(),
        {_portEventId, _outcomeEventId},
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.drafts);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId),
        [_draftEventId],
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.attention);
      expect(
        controller.state.visibleEvents.map((event) => event.eventId),
        [_missingEventId],
      );

      controller.setFilter(NarrativeEventBuilderV2Filter.oldFormat);
      expect(
        controller.state.visibleEvents,
        everyElement(
          predicate<NarrativeEventProjectSummary>(
            (event) => event.origin != NarrativeEventProjectOrigin.v2,
          ),
        ),
      );
    });

    test('immutable query and filter helpers preserve the read snapshot', () {
      final initial = NarrativeEventBuilderV2State(
        readModel: _projectReadModel(),
      );

      final queried = initial.withQuery('port');
      final filtered = queried.withFilter(
        NarrativeEventBuilderV2Filter.active,
      );

      expect(initial.query, isEmpty);
      expect(initial.filter, NarrativeEventBuilderV2Filter.all);
      expect(queried.query, 'port');
      expect(queried.filter, NarrativeEventBuilderV2Filter.all);
      expect(filtered.query, 'port');
      expect(filtered.filter, NarrativeEventBuilderV2Filter.active);
      expect(filtered.readModel, same(initial.readModel));
      expect(filtered.selectedCompatibilityStableKey, isNull);
    });

    test('distinguishes an empty project from a search with no result', () {
      final nonEmpty = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: _rejectSelection,
      )..setQuery('aucun résultat imaginable');

      expect(nonEmpty.state.isProjectEmpty, isFalse);
      expect(nonEmpty.state.hasNoMatchingEvents, isTrue);

      final empty = NarrativeEventBuilderV2State(
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: const [],
        ),
      );
      expect(empty.isProjectEmpty, isTrue);
      expect(empty.hasNoMatchingEvents, isFalse);
    });

    test('keeps invalid project diagnostics read-only instead of falling back',
        () {
      final invalid = NarrativeEventBuilderV2State(
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: [
            NarrativeEventProjectReadDiagnostic(
              code: 'unsupportedRegistry',
              severity: NarrativeEventProjectSummarySeverity.error,
              message: 'Ce registre est non disponible dans cette version.',
            ),
          ],
        ),
      );

      expect(invalid.isReadOnly, isTrue);
      expect(invalid.isProjectEmpty, isTrue);
      expect(invalid.readModel.diagnostics.single.code, 'unsupportedRegistry');
    });

    test('delegates selection to the map bridge without storing a second copy',
        () {
      String? selectedEventId;
      NarrativeEventGroupContext? selectedGroup;
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) {
          selectedEventId = eventId;
          selectedGroup = groupContext;
          return true;
        },
      );

      expect(controller.selectEvent('v2:$_portEventId'), isTrue);
      expect(selectedEventId, _portEventId);
      expect(
        selectedGroup,
        const NarrativeEventGroupContext.map('map_port'),
      );

      final bridgeState = NarrativeEventMapBridgeState(
        selectedNarrativeEventV2Id: selectedEventId,
        selectedGroupContext: selectedGroup,
      );
      expect(
        selectedNarrativeEventBuilderV2Event(
          state: controller.state,
          bridgeState: bridgeState,
        )?.eventId,
        _portEventId,
      );
    });

    test('resolves stable selection again after a project snapshot refresh',
        () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(portTitle: 'Rencontre au port'),
        selectEvent: _rejectSelection,
      )..setQuery('port');
      const bridgeState = NarrativeEventMapBridgeState(
        selectedNarrativeEventV2Id: _portEventId,
        selectedGroupContext: NarrativeEventGroupContext.map('map_port'),
      );
      final before = selectedNarrativeEventBuilderV2Event(
        state: controller.state,
        bridgeState: bridgeState,
      );

      controller.replaceReadModel(
        _projectReadModel(portTitle: 'Rival au port'),
      );
      final after = selectedNarrativeEventBuilderV2Event(
        state: controller.state,
        bridgeState: bridgeState,
      );

      expect(before?.eventId, _portEventId);
      expect(after?.eventId, _portEventId);
      expect(after?.title, 'Rival au port');
      expect(after, isNot(same(before)));
      expect(controller.state.query, 'port');
    });

    test('selects compatibility rows locally without forging a V2 identity',
        () {
      var bridgeWrites = 0;
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) {
          bridgeWrites++;
          return true;
        },
      );
      final legacy = controller.state.readModel.events
          .firstWhere((event) => event.readOnly);

      expect(legacy.eventId, isNull);
      expect(controller.selectEvent(legacy.stableKey), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, legacy.stableKey);
      expect(bridgeWrites, 0);
      expect(
        selectedNarrativeEventBuilderV2Event(
          state: controller.state,
          bridgeState: const NarrativeEventMapBridgeState(),
        ),
        same(legacy),
      );
    });

    test('a successful V2 selection clears the local compatibility row', () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) => true,
      );
      final legacy = controller.state.readModel.events
          .firstWhere((event) => event.readOnly);

      expect(controller.selectEvent(legacy.stableKey), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, isNotNull);
      expect(controller.selectEvent('v2:$_portEventId'), isTrue);
      expect(controller.state.selectedCompatibilityStableKey, isNull);
    });

    test('rejects a contradictory spatial group selection', () {
      final controller = NarrativeEventBuilderV2Controller(
        readModel: _projectReadModel(),
        selectEvent: ({required eventId, required groupContext}) => true,
      );

      expect(
        controller.selectEvent(
          'v2:$_portEventId',
          groupContext: const NarrativeEventGroupContext.global(),
        ),
        isFalse,
      );
    });
  });
}

bool _rejectSelection({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
}) =>
    false;

NarrativeEventBuilderProjectReadModel _projectReadModel({
  String portTitle = 'Rencontre au port',
}) {
  final port = _map(
    id: 'map_port',
    name: 'Port des Brisants',
    entityId: 'npc_lysa',
    entityName: 'Lysa',
    legacyEvent: const MapEventDefinition(
      id: 'legacy_port',
      title: 'Ancienne rumeur au port',
      pages: [
        MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
        ),
      ],
      position: EventPosition(layerId: 'events', x: 1, y: 1),
    ),
  );
  final forest = _map(
    id: 'map_forest',
    name: 'Forêt Brumeuse',
    entityId: 'npc_spirit',
    entityName: 'Esprit de la forêt',
  );
  final project = ProjectManifest(
    name: 'Selbrume',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port des Brisants',
        relativePath: 'maps/port.json',
      ),
      ProjectMapEntry(
        id: 'map_forest',
        name: 'Forêt Brumeuse',
        relativePath: 'maps/forest.json',
      ),
    ],
    tilesets: const [],
    scenes: [
      _scene('scene_action', 'Rencontre'),
      _scene('scene_rival', 'Duel du rival', outcomeId: 'victory'),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        _configured(
          _portEventId,
          portTitle,
          NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
          enabled: true,
        ),
        _configured(
          _forestEventId,
          'Écho dans la brume',
          NarrativeEventSourceRef.entityInteract(
            'map_forest',
            'npc_spirit',
          ),
          enabled: false,
        ),
        _draft(_draftEventId, 'Événement à préparer'),
        _draft(
          _missingEventId,
          'Objet disparu',
          source: NarrativeEventSourceRef.entityInteract(
            'map_port',
            'npc_absent',
          ),
        ),
        _configured(
          _outcomeEventId,
          'Après la victoire',
          NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_rival',
              outcomeId: 'victory',
            ),
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
  );
  return buildNarrativeEventBuilderProjectReadModel(
    project: project,
    maps: [port, forest],
  );
}

MapData _map({
  required String id,
  required String name,
  required String entityId,
  required String entityName,
  MapEventDefinition? legacyEvent,
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: [
      MapEntity(
        id: entityId,
        name: entityName,
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
      ),
    ],
    events: [if (legacyEvent != null) legacyEvent],
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      sceneId: 'scene_action',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

NarrativeEventRecord _draft(
  String id,
  String name, {
  NarrativeEventSourceRef? source,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  );
}

SceneAsset _scene(String id, String name, {String? outcomeId}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}
~~~~


### 14.12 `packages/map_editor/test/support/event_builder_v2_visual_harness.dart`

~~~~dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_element_library.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const eventBuilderV2PhaseKReferenceViewport = Size(1672, 941);
const eventBuilderV2PhaseKCaptureViewports = <Size>[
  Size(1280, 941),
  Size(1440, 941),
  Size(1480, 941),
  eventBuilderV2PhaseKReferenceViewport,
  Size(1920, 941),
];

const eventBuilderV2PhaseKSelectedStableKey = 'event:rival';
const eventBuilderV2PhaseKBrokenSourceStableKey = 'event:broken-lantern';
const eventBuilderV2PhaseKCaptureFontFamily = 'NsEventV2PhaseKCaptureFont';

const eventBuilderV2PhaseKCaptureKey =
    ValueKey<String>('event-builder-v2-phase-k-capture');
const eventBuilderV2PhaseKHeaderKey =
    ValueKey<String>('event-builder-v2-phase-k-header');
const eventBuilderV2PhaseKContextBarKey =
    ValueKey<String>('event-builder-v2-phase-k-context-bar');
const eventBuilderV2PhaseKNavigationKey =
    ValueKey<String>('event-builder-v2-phase-k-navigation');
const eventBuilderV2PhaseKWorkspaceFrameKey =
    ValueKey<String>('event-builder-v2-phase-k-workspace-frame');

final File eventBuilderV2PhaseKAppIconFile = File(
  '${Directory.current.path}/'
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/32.png',
);

/// Loads readable text and product icon glyphs for opt-in macOS captures.
///
/// This is deliberately test-only and fails explicitly when the macOS font is
/// unavailable instead of silently producing Ahem blocks in review artifacts.
Future<void> loadEventBuilderV2PhaseKCaptureFonts() async {
  final textFont = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  if (!textFont.existsSync()) {
    throw TestFailure(
      'Phase K capture requires the macOS Arial font at '
      '${textFont.path}.',
    );
  }
  final textFontBytes = textFont.readAsBytesSync();
  final textFontLoader = FontLoader(eventBuilderV2PhaseKCaptureFontFamily)
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(textFontBytes)),
    );
  await textFontLoader.load();

  final iconFontBytes = await rootBundle.load(
    'packages/cupertino_icons/assets/CupertinoIcons.ttf',
  );
  final effectiveIconFamily = const TextStyle(
    fontFamily: CupertinoIcons.iconFont,
    package: CupertinoIcons.iconFontPackage,
  ).fontFamily!;
  final iconFontLoader = FontLoader(effectiveIconFamily)
    ..addFont(Future<ByteData>.value(iconFontBytes));
  await iconFontLoader.load();
}

Future<void> pumpEventBuilderV2PhaseK(
  WidgetTester tester, {
  required Size viewport,
  double textScaleFactor = 1,
  String selectedStableKey = eventBuilderV2PhaseKSelectedStableKey,
  NarrativeEventBuilderProjectReadModel? readModel,
  VoidCallback? onCreateEvent,
  String? fontFamily,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    EventBuilderV2PhaseKVisualHarness(
      viewport: viewport,
      textScaleFactor: textScaleFactor,
      readModel: readModel ?? buildEventBuilderV2PhaseKReadModel(),
      selectedStableKey: selectedStableKey,
      onCreateEvent: onCreateEvent,
      fontFamily: fontFamily,
    ),
  );
  await tester.pumpAndSettle();
}

class EventBuilderV2PhaseKVisualHarness extends StatefulWidget {
  const EventBuilderV2PhaseKVisualHarness({
    super.key,
    required this.viewport,
    required this.textScaleFactor,
    required this.readModel,
    required this.selectedStableKey,
    this.onCreateEvent,
    this.fontFamily,
  });

  final Size viewport;
  final double textScaleFactor;
  final NarrativeEventBuilderProjectReadModel readModel;
  final String selectedStableKey;
  final VoidCallback? onCreateEvent;
  final String? fontFamily;

  @override
  State<EventBuilderV2PhaseKVisualHarness> createState() =>
      _EventBuilderV2PhaseKVisualHarnessState();
}

class _EventBuilderV2PhaseKVisualHarnessState
    extends State<EventBuilderV2PhaseKVisualHarness> {
  late NarrativeEventBuilderV2State _state;
  late String _selectedStableKey;
  late final Uint8List _appIconBytes;

  @override
  void initState() {
    super.initState();
    _state = NarrativeEventBuilderV2State(readModel: widget.readModel);
    _selectedStableKey = widget.selectedStableKey;
    _appIconBytes = eventBuilderV2PhaseKAppIconFile.readAsBytesSync();
  }

  @override
  void didUpdateWidget(covariant EventBuilderV2PhaseKVisualHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readModel != widget.readModel) {
      _state = NarrativeEventBuilderV2State(readModel: widget.readModel);
    }
    if (oldWidget.selectedStableKey != widget.selectedStableKey) {
      _selectedStableKey = widget.selectedStableKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = PokeMapTheme.dark();
    final theme = widget.fontFamily == null
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(
              fontFamily: widget.fontFamily,
            ),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(
              fontFamily: widget.fontFamily,
            ),
          );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(widget.textScaleFactor),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontFamily: widget.fontFamily),
            child: child!,
          ),
        );
      },
      home: Scaffold(
        body: RepaintBoundary(
          key: eventBuilderV2PhaseKCaptureKey,
          child: SizedBox.expand(
            child: _PhaseKReferenceChrome(
              viewport: widget.viewport,
              appIconBytes: _appIconBytes,
              workspace: Builder(
                builder: (workspaceContext) => EventBuilderV2Workspace(
                  state: _state,
                  mode: EventSystemMode.dualRead,
                  selectedStableKey: _selectedStableKey,
                  viewportWidth: widget.viewport.width,
                  onQueryChanged: (value) {
                    setState(() => _state = _state.withQuery(value));
                  },
                  onFilterChanged: (value) {
                    setState(() => _state = _state.withFilter(value));
                  },
                  onSelectEvent: (event) {
                    setState(() => _selectedStableKey = event.stableKey);
                  },
                  onCreateEvent: widget.onCreateEvent ?? () {},
                  onOpenLibrary: () => _openLibrary(workspaceContext),
                  onChangeSource: () {},
                  onSeeOnMap: () {},
                  onAddCondition: () {},
                  onChangeScene: () {},
                  onOpenScene: () {},
                  onChangeBehavior: () {},
                  onManageEvaluationOrder: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLibrary(BuildContext workspaceContext) {
    showPokeMapDesktopSideSheet<void>(
      context: workspaceContext,
      title: 'Bibliothèque d’éléments',
      semanticLabel: 'Bibliothèque d’éléments de l’événement',
      barrierLabel: 'Fermer la bibliothèque d’éléments',
      barrierDismissible: false,
      width: 420,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(8),
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: _state.readModel
                  .eventByStableKey(_selectedStableKey)
                  ?.scene
                  .sceneId !=
              null,
          onOpenScene: () {},
        ),
      ),
    );
  }
}

class _PhaseKReferenceChrome extends StatelessWidget {
  const _PhaseKReferenceChrome({
    required this.viewport,
    required this.appIconBytes,
    required this.workspace,
  });

  final Size viewport;
  final Uint8List appIconBytes;
  final Widget workspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final navigationWidth = _navigationWidth(viewport.width);
    final businessStart = 8 + navigationWidth + 8;
    final rightMargin = viewport.width == 1672 ? 9.0 : 8.0;

    return ColoredBox(
      color: colors.chromeBackground,
      child: Column(
        children: [
          Container(
            key: eventBuilderV2PhaseKHeaderKey,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.topBarBackground,
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Image.memory(
                  appIconBytes,
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.none,
                  semanticLabel: 'Icône PokeMap',
                ),
                const SizedBox(width: 10),
                Text(
                  'PokeMap',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                const PokeMapBadge(
                  label: 'beta',
                  variant: PokeMapBadgeVariant.info,
                ),
                const Spacer(),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Rechercher',
                  icon: const Icon(CupertinoIcons.search),
                ),
                const SizedBox(width: 5),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Notifications',
                  icon: const Icon(CupertinoIcons.bell),
                ),
                const SizedBox(width: 5),
                PokeMapIconButton(
                  onPressed: () {},
                  tooltip: 'Réglages',
                  icon: const Icon(CupertinoIcons.gear),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ColoredBox(
              color: colors.chromeBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: businessStart),
                  Expanded(
                    child: Container(
                      key: eventBuilderV2PhaseKContextBarKey,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colors.topBarBackground,
                        border: Border(
                          bottom: BorderSide(color: colors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.house,
                            size: 14,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Narrative Studio  /  Event Builder',
                            style: TextStyle(
                              color: colors.brandPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          PokeMapButton(
                            onPressed: () {},
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(CupertinoIcons.eye),
                            child: const Text('Aperçu'),
                          ),
                          const SizedBox(width: 8),
                          PokeMapButton(
                            onPressed: () {},
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.success,
                            leading:
                                const Icon(CupertinoIcons.checkmark_shield),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: rightMargin,
                bottom: 22,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: eventBuilderV2PhaseKNavigationKey,
                    width: navigationWidth,
                    child: const _PhaseKNavigationPanel(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      key: eventBuilderV2PhaseKWorkspaceFrameKey,
                      child: workspace,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseKNavigationPanel extends StatelessWidget {
  const _PhaseKNavigationPanel();

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: const [
          PokeMapCard(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                PokeMapIconTile(
                  icon: CupertinoIcons.map,
                  tone: PokeMapTone.map,
                  size: 28,
                  iconSize: 14,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Selbrume Demo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(CupertinoIcons.chevron_down, size: 11),
              ],
            ),
          ),
          SizedBox(height: 10),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.house,
            label: 'Aperçu',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.rectangle_grid_1x2,
            label: 'Storylines',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.map,
            label: 'Maps',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.photo,
            label: 'Scenes',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.bolt_horizontal_circle,
            label: 'Événements',
            selected: true,
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.film,
            label: 'Cinématiques',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.text_bubble,
            label: 'Dialogues',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.doc_text,
            label: 'Facts',
          ),
          _PhaseKNavigationItem(
            icon: CupertinoIcons.checkmark_shield,
            label: 'World Rules',
          ),
          SizedBox(height: 20),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Projet prêt pour validation.',
          ),
        ],
      ),
    );
  }
}

class _PhaseKNavigationItem extends StatelessWidget {
  const _PhaseKNavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PokeMapSidebarItem(
        icon: Icon(icon),
        label: label,
        selected: selected,
        onTap: () {},
      ),
    );
  }
}

double _navigationWidth(double viewportWidth) {
  if (viewportWidth >= 1672) return 191;
  if (viewportWidth >= 1480) return 176;
  return 168;
}

NarrativeEventBuilderProjectReadModel buildEventBuilderV2PhaseKReadModel() {
  final richProjection = NarrativeEventProjectionSummary(
    outcomeLabels: const ['Victoire', 'Défaite', 'Échec'],
    consequences: [
      NarrativeEventProjectedConsequenceSummary(
        kind: SceneConsequenceKind.setFact,
        humanLabel: 'Rival battu = vrai',
        debugReference: 'fact:rival_defeated',
      ),
      NarrativeEventProjectedConsequenceSummary(
        kind: SceneConsequenceKind.markEventConsumed,
        humanLabel: 'Rencontre du port terminée',
        debugReference: 'event:rival',
      ),
    ],
    worldRules: [
      NarrativeEventProjectedWorldRuleSummary(
        ruleId: 'world_rule:guardian_gone',
        humanLabel: 'Le gardien a disparu',
        enabled: true,
      ),
    ],
    readOnly: true,
  );

  return NarrativeEventBuilderProjectReadModel(
    groups: [
      NarrativeEventProjectGroup(
        stableKey: 'group:map:port',
        label: 'Port Selbrume',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _phaseKSummary(
            stableKey: eventBuilderV2PhaseKSelectedStableKey,
            title: 'Rencontre rival au port',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_rival',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
            sceneId: 'scene_rival_meeting',
            sceneLabel: 'Rencontre rival',
            conditionsCount: 2,
            conditionsLabel: 'Étape « Aller au port » et rival non battu',
            lifecycleLabel: 'Une seule fois · actif',
            projection: richProjection,
            diagnostics: [
              NarrativeEventProjectReadDiagnostic(
                code: 'evaluation-order-information',
                severity: NarrativeEventProjectSummarySeverity.info,
                message:
                    'Le prochain événement éligible peut être évalué ensuite.',
              ),
            ],
          ),
          _phaseKSummary(
            stableKey: 'event:fisherman',
            title: 'Pêcheur en détresse',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_fisherman',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au pêcheur sur le quai.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:abandoned-chest',
            title: 'Coffre abandonné',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredDisabledReady,
            enabled: false,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_abandoned_chest',
            ),
            sourceTypeLabel: 'Interaction avec un objet',
            sourceSentence: 'Quand le joueur examine le coffre abandonné.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:sleeping-guard',
            title: 'Garde somnolent',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.attentionRequired,
            enabled: false,
            source: NarrativeEventSourceRef.triggerEnter(
              'map_port_selbrume',
              'trigger_guard_post',
            ),
            sourceTypeLabel: 'Entrée dans une zone',
            sourceSentence: 'Quand le joueur approche du poste de garde.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
          _phaseKSummary(
            stableKey: 'event:tavern-rumor',
            title: 'Rumeur au comptoir',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_bartender',
            ),
            sourceTypeLabel: 'Interaction avec un personnage',
            sourceSentence: 'Quand le joueur parle au tavernier.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:map:forest',
        label: 'Forêt Brumeuse',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _mapEvent('injured-creature', 'Créature blessée', 'Forêt Brumeuse'),
          _mapEvent('medicinal-herbs', 'Herbes médicinales', 'Forêt Brumeuse'),
          _mapEvent('team-ambush', 'Embuscade de la Team', 'Forêt Brumeuse'),
          _mapEvent('forest-spirit', 'Esprit de la forêt', 'Forêt Brumeuse'),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:map:cave',
        label: 'Grotte Marine',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _mapEvent(
              'ancient-inscription', 'Ancienne inscription', 'Grotte Marine'),
          _mapEvent('fragile-rock', 'Roche friable', 'Grotte Marine'),
          _mapEvent('mysterious-echo', 'Écho mystérieux', 'Grotte Marine'),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:outcomes',
        label: 'Événements globaux',
        kind: NarrativeEventProjectGroupKind.outcomes,
        events: [
          _phaseKSummary(
            stableKey: 'event:league-qualified',
            title: 'Qualification pour la ligue',
            group: NarrativeEventProjectGroupKind.outcomes,
            groupKey: 'outcomes',
            groupLabel: 'Événements globaux',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            source: NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'battle_port_champion',
                outcomeId: 'victory',
              ),
            ),
            sourceTypeLabel: 'Résultat reçu',
            sourceSentence: 'Quand la victoire du champion est reçue.',
          ),
          _phaseKSummary(
            stableKey: 'event:chapter-complete',
            title: 'Chapitre du port terminé',
            group: NarrativeEventProjectGroupKind.outcomes,
            groupKey: 'outcomes',
            groupLabel: 'Événements globaux',
            status: NarrativeEventProjectStatus.configuredDisabledReady,
            enabled: false,
            source: NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.scene,
                producerId: 'scene_port_departure',
                outcomeId: 'chapter_complete',
              ),
            ),
            sourceTypeLabel: 'Résultat reçu',
            sourceSentence: 'Quand le chapitre du port est terminé.',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:drafts',
        label: 'Brouillons à terminer',
        kind: NarrativeEventProjectGroupKind.drafts,
        events: [
          _phaseKSummary(
            stableKey: 'event:draft-market',
            title: 'Marché nocturne à configurer',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            sourceTypeLabel: 'Élément déclencheur',
            sourceSentence: 'Aucun élément déclencheur choisi.',
            sceneId: null,
            sceneLabel: 'Aucune Scene choisie',
            lifecycleLabel: 'Comportement à décider',
          ),
          _phaseKSummary(
            stableKey: 'event:draft-lighthouse',
            title: 'Lumière du phare après la tempête',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            source: NarrativeEventSourceRef.mapEnter('map_lighthouse'),
            sourceTypeLabel: 'Entrée sur une map',
            sourceSentence: 'Quand le joueur arrive au phare.',
            mapId: 'map_lighthouse',
            mapLabel: 'Phare de Selbrume',
            sceneId: null,
            sceneLabel: 'Aucune Scene choisie',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:missing',
        label: 'Références à réparer',
        kind: NarrativeEventProjectGroupKind.missingReferences,
        events: [
          _phaseKSummary(
            stableKey: eventBuilderV2PhaseKBrokenSourceStableKey,
            title: 'Lanterne du vieux quai',
            group: NarrativeEventProjectGroupKind.missingReferences,
            groupKey: 'missing',
            groupLabel: 'Références à réparer',
            status: NarrativeEventProjectStatus.sourceMissing,
            enabled: false,
            source: NarrativeEventSourceRef.entityInteract(
              'map_port_selbrume',
              'entity_missing_lantern',
            ),
            sourceTypeLabel: 'Interaction avec un objet',
            sourceSentence: 'L’élément déclencheur n’existe plus sur la map.',
            mapId: 'map_port_selbrume',
            mapLabel: 'Port Selbrume',
            sourceAvailable: false,
            diagnostics: [
              NarrativeEventProjectReadDiagnostic(
                code: 'source-missing',
                severity: NarrativeEventProjectSummarySeverity.error,
                message:
                    'Choisissez un autre élément ou détachez la référence.',
              ),
            ],
          ),
          _phaseKSummary(
            stableKey: 'event:unsupported-source',
            title: 'Signal ancien non pris en charge',
            group: NarrativeEventProjectGroupKind.missingReferences,
            groupKey: 'missing',
            groupLabel: 'Références à réparer',
            status: NarrativeEventProjectStatus.unsupported,
            enabled: false,
            sourceTypeLabel: 'Format non pris en charge',
            sourceSentence:
                'Cet élément déclencheur doit être remplacé avant activation.',
            sourceAvailable: false,
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:legacy',
        label: 'Ancien format à convertir',
        kind: NarrativeEventProjectGroupKind.legacyCompatibility,
        events: [
          _phaseKSummary(
            stableKey: 'legacy:messenger',
            title: 'Messager existant',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.legacyOnly,
            enabled: null,
            origin: NarrativeEventProjectOrigin.legacyMapEvent,
            readOnly: true,
            sourceTypeLabel: 'Déclencheur existant',
            sourceSentence: 'Événement existant en lecture seule.',
          ),
          _phaseKSummary(
            stableKey: 'legacy:storm-scenario',
            title: 'Ancien scénario de tempête',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.migrationAssistanceRequired,
            enabled: null,
            origin: NarrativeEventProjectOrigin.legacyScenario,
            readOnly: true,
            sourceTypeLabel: 'Ancien scénario',
            sourceSentence: 'Conversion guidée nécessaire.',
          ),
        ],
      ),
    ],
    diagnostics: [
      NarrativeEventProjectReadDiagnostic(
        code: 'fixture-stable',
        severity: NarrativeEventProjectSummarySeverity.info,
        message: 'Fixture visuelle Phase K déterministe.',
      ),
    ],
  );
}

NarrativeEventProjectSummary _mapEvent(
  String slug,
  String title,
  String mapLabel,
) {
  final mapSlug = mapLabel == 'Forêt Brumeuse' ? 'forest' : 'cave';
  return _phaseKSummary(
    stableKey: 'event:$slug',
    title: title,
    group: NarrativeEventProjectGroupKind.map,
    groupKey: 'map:$mapSlug',
    groupLabel: mapLabel,
    status: NarrativeEventProjectStatus.configuredEnabledReady,
    enabled: true,
    source: NarrativeEventSourceRef.triggerEnter(
      'map_$mapSlug',
      'trigger_$slug',
    ),
    sourceTypeLabel: 'Entrée dans une zone',
    sourceSentence: 'Quand le joueur entre dans la zone « $title ».',
    mapId: 'map_$mapSlug',
    mapLabel: mapLabel,
  );
}

NarrativeEventProjectSummary _phaseKSummary({
  required String stableKey,
  required String title,
  required NarrativeEventProjectGroupKind group,
  required String groupKey,
  required String groupLabel,
  required NarrativeEventProjectStatus status,
  required bool? enabled,
  required String sourceTypeLabel,
  required String sourceSentence,
  NarrativeEventSourceRef? source,
  String? mapId,
  String? mapLabel,
  bool sourceAvailable = true,
  String? sceneId = 'scene_default',
  String sceneLabel = 'Scene liée',
  int conditionsCount = 0,
  String conditionsLabel = 'Aucune condition',
  String lifecycleLabel = 'À chaque fois',
  NarrativeEventProjectionSummary? projection,
  List<NarrativeEventProjectReadDiagnostic> diagnostics = const [],
  NarrativeEventProjectOrigin origin = NarrativeEventProjectOrigin.v2,
  bool readOnly = false,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: origin == NarrativeEventProjectOrigin.v2
        ? stableKey.replaceFirst('event:', 'evt_')
        : null,
    title: title,
    origin: origin,
    readOnly: readOnly,
    enabled: enabled,
    group: group,
    groupKey: groupKey,
    groupLabel: groupLabel,
    status: status,
    severity: diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == NarrativeEventProjectSummarySeverity.error,
    )
        ? NarrativeEventProjectSummarySeverity.error
        : diagnostics.isEmpty
            ? NarrativeEventProjectSummarySeverity.info
            : NarrativeEventProjectSummarySeverity.warning,
    source: NarrativeEventSourceSummary(
      source: source,
      humanSentence: sourceSentence,
      sourceTypeLabel: sourceTypeLabel,
      mapId: mapId,
      mapLabel: mapLabel,
      available: sourceAvailable,
      debugTechnicalLabel: 'fixture:$stableKey',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: sceneId,
      humanLabel: sceneLabel,
      valid: sceneId != null,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: conditionsCount,
      valid: true,
      unresolvedCount: 0,
      humanLabel: conditionsLabel,
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: status == NarrativeEventProjectStatus.draftIncomplete
          ? null
          : NarrativeEventReusePolicy.oneShot,
      enabled: enabled,
      humanLabel: lifecycleLabel,
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: readOnly ? 'Ancien format à convertir' : 'Format V2',
    ),
    projection: projection ??
        NarrativeEventProjectionSummary(
          outcomeLabels: const [],
          consequences: const [],
          worldRules: const [],
          readOnly: true,
        ),
    compatibilityOrigins: const [],
    diagnostics: diagnostics,
    debug: NarrativeEventProjectDebugFields(
      eventId: origin == NarrativeEventProjectOrigin.v2
          ? stableKey.replaceFirst('event:', 'evt_')
          : null,
      sourceTechnicalLabel: source == null ? null : 'fixture-source',
      sceneId: sceneId,
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
~~~~


### 14.13 `packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';

void main() {
  group('NS-EVENT-V2-26 project workspace', () {
    testWidgets('renders the project groups without an active-map filter',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1672);

      expect(find.text('Port Selbrume'), findsOneWidget);
      expect(find.text('Brouillons à terminer'), findsOneWidget);
      expect(find.text('Ancien format à convertir'), findsOneWidget);
      expect(find.text('Rencontre rival au port'), findsWidgets);
      expect(find.text('Coffre sans déclencheur'), findsOneWidget);
      expect(find.text('Messager existant'), findsOneWidget);
      expect(find.textContaining('sourceId'), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
    });

    testWidgets('uses the exact four business panel widths at 1672',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1672);

      expect(
        tester.getSize(find.byKey(const ValueKey('event-builder-v2-list'))),
        const Size(266, 817),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('event-builder-v2-library')),
        ),
        const Size(213, 817),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('event-builder-v2-editor'))),
        const Size(565, 817),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        ),
        const Size(388, 817),
      );

      final list = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-list')),
      );
      final library = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-library')),
      );
      final editor = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-editor')),
      );
      final inspector = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-inspector')),
      );
      expect(library.dx - (list.dx + 266), 8);
      expect(editor.dx - (library.dx + 213), 8);
      expect(inspector.dx - (editor.dx + 565), 8);
    });

    testWidgets('search and human filter callbacks are functional',
        (tester) async {
      var state = NarrativeEventBuilderV2State(readModel: _readModel());
      late StateSetter rebuild;

      await tester.binding.setSurfaceSize(const Size(1456, 817));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return EventBuilderV2Workspace(
                  state: state,
                  mode: EventSystemMode.dualRead,
                  selectedStableKey: 'event:rival',
                  viewportWidth: 1672,
                  onQueryChanged: (value) {
                    rebuild(() => state = state.withQuery(value));
                  },
                  onFilterChanged: (value) {
                    rebuild(() => state = state.withFilter(value));
                  },
                  onSelectEvent: (_) {},
                  onCreateEvent: () {},
                  onOpenLibrary: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('event-builder-v2-search')),
        'coffre',
      );
      await tester.pump();

      final list = find.byKey(const ValueKey('event-builder-v2-list'));
      expect(
        find.descendant(
          of: list,
          matching: find.text('Coffre sans déclencheur'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: list,
          matching: find.text('Rencontre rival au port'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-filter-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ancien format à convertir'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: list, matching: find.text('Messager existant')),
        findsNothing,
      );
      expect(
        find.descendant(of: list, matching: find.text('Aucun résultat')),
        findsOneWidget,
      );
    });

    testWidgets('moves the library to an explicit side-sheet action at 1440',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1440, width: 1232);

      expect(
        find.byKey(const ValueKey('event-builder-v2-library')),
        findsNothing,
      );
      expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses available width when the 1480 shell is constrained',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1480, width: 1264);

      expect(
        find.byKey(const ValueKey('event-builder-v2-library')),
        findsNothing,
      );
      expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a state-preserving unsupported message below 1280',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1279, width: 1100);

      expect(find.text('Fenêtre trop étroite'), findsOneWidget);
      expect(
        find.textContaining('Votre sélection est conservée'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-list')),
        findsNothing,
      );
    });

    testWidgets('v2Only never exposes a legacy creation action',
        (tester) async {
      await _pumpWorkspace(
        tester,
        viewportWidth: 1672,
        mode: EventSystemMode.v2Only,
      );

      expect(find.text('Nouvel événement'), findsOneWidget);
      expect(find.textContaining('legacy'), findsNothing);
      expect(find.text('Ancien format à convertir'), findsOneWidget);
    });

    testWidgets('distinguishes an empty project from empty filters',
        (tester) async {
      await _pumpWorkspace(
        tester,
        viewportWidth: 1672,
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: const [],
        ),
      );

      expect(find.text('Aucun événement dans ce projet'), findsOneWidget);
      expect(find.text('Nouvel événement'), findsOneWidget);
    });
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required double viewportWidth,
  double width = 1456,
  EventSystemMode mode = EventSystemMode.dualRead,
  NarrativeEventBuilderProjectReadModel? readModel,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 817));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final state = NarrativeEventBuilderV2State(
    readModel: readModel ?? _readModel(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 817,
          child: EventBuilderV2Workspace(
            state: state,
            mode: mode,
            selectedStableKey: 'event:rival',
            viewportWidth: viewportWidth,
            onQueryChanged: (_) {},
            onFilterChanged: (_) {},
            onSelectEvent: (_) {},
            onCreateEvent: () {},
            onOpenLibrary: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

NarrativeEventBuilderProjectReadModel _readModel() {
  return NarrativeEventBuilderProjectReadModel(
    groups: [
      NarrativeEventProjectGroup(
        stableKey: 'group:map:port',
        label: 'Port Selbrume',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _summary(
            stableKey: 'event:rival',
            eventId: 'evt_rival',
            title: 'Rencontre rival au port',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            sentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:drafts',
        label: 'Brouillons à terminer',
        kind: NarrativeEventProjectGroupKind.drafts,
        events: [
          _summary(
            stableKey: 'event:chest',
            eventId: 'evt_chest',
            title: 'Coffre sans déclencheur',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            sentence: 'Aucun élément déclencheur choisi.',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:legacy',
        label: 'Ancien format à convertir',
        kind: NarrativeEventProjectGroupKind.legacyCompatibility,
        events: [
          _summary(
            stableKey: 'legacy:messenger',
            eventId: null,
            title: 'Messager existant',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.legacyOnly,
            enabled: null,
            sentence: 'Déclencheur existant, lecture seule.',
            origin: NarrativeEventProjectOrigin.legacyMapEvent,
            readOnly: true,
          ),
        ],
      ),
    ],
    diagnostics: const [],
  );
}

NarrativeEventProjectSummary _summary({
  required String stableKey,
  required String? eventId,
  required String title,
  required NarrativeEventProjectGroupKind group,
  required String groupKey,
  required String groupLabel,
  required NarrativeEventProjectStatus status,
  required bool? enabled,
  required String sentence,
  NarrativeEventProjectOrigin origin = NarrativeEventProjectOrigin.v2,
  bool readOnly = false,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: eventId,
    title: title,
    origin: origin,
    readOnly: readOnly,
    enabled: enabled,
    group: group,
    groupKey: groupKey,
    groupLabel: groupLabel,
    status: status,
    severity: NarrativeEventProjectSummarySeverity.info,
    source: NarrativeEventSourceSummary(
      source: null,
      humanSentence: sentence,
      sourceTypeLabel: 'Élément déclencheur',
      available: true,
      debugTechnicalLabel: 'hidden',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: 'scene_rival',
      humanLabel: 'Rencontre rival',
      valid: true,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: 0,
      valid: true,
      unresolvedCount: 0,
      humanLabel: 'Aucune condition',
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      enabled: enabled,
      humanLabel: enabled == true ? 'Actif' : 'Brouillon',
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: readOnly ? 'Ancien format à convertir' : 'Format V2',
    ),
    projection: NarrativeEventProjectionSummary(
      outcomeLabels: const [],
      consequences: const [],
      worldRules: const [],
      readOnly: true,
    ),
    compatibilityOrigins: const [],
    diagnostics: const [],
    debug: NarrativeEventProjectDebugFields(
      eventId: eventId,
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
~~~~


### 14.14 `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`

~~~~dart
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_editor.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_element_library.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_inspector.dart';

void main() {
  group('NS-EVENT-V2-39 editor flow fidelity', () {
    testWidgets('keeps a narrow rail and handles 0/1/2/3+ Scene outcomes',
        (tester) async {
      for (final count in [0, 1, 2, 4]) {
        await _pumpPanel(
          tester,
          width: 565,
          child: EventBuilderV2Editor(
            event: _summary(outcomeCount: count),
            onOpenScene: () {},
          ),
        );

        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('event-builder-v2-flow-rail')),
              )
              .width,
          lessThanOrEqualTo(404),
          reason: '$count outcomes',
        );
        expect(
          find.byKey(ValueKey('event-builder-v2-outcomes-$count')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$count outcomes');
      }
    });

    testWidgets('wraps long author labels without overflow', (tester) async {
      final longLabel = List.filled(
        8,
        'Victoire diplomatique au port pendant la grande célébration',
      ).join(' ');

      await _pumpPanel(
        tester,
        width: 565,
        child: EventBuilderV2Editor(
          event: _summary(
            title: longLabel,
            outcomeLabels: [longLabel, longLabel],
          ),
          onOpenScene: () {},
        ),
      );

      expect(find.text(longLabel), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Déposez'), findsNothing);
      expect(find.textContaining('Ajouter une réaction'), findsNothing);
    });

    testWidgets('does not invent outcome meaning from Scene list order',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 565,
        child: EventBuilderV2Editor(
          event: _summary(outcomeLabels: const ['Échec', 'Victoire']),
          onOpenScene: () {},
        ),
      );

      // The read model exposes labels only. Success/danger styling based on
      // list position would lie whenever the Scene orders its outcomes
      // differently, so every projected outcome stays semantically neutral.
      expect(find.byIcon(CupertinoIcons.rosette), findsNothing);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
      expect(find.byIcon(CupertinoIcons.flag_fill), findsWidgets);
    });
  });

  group('NS-EVENT-V2-39 element library fidelity', () {
    testWidgets('is dense and separates Event authoring from Scene read-only',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 213,
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: true,
          onOpenScene: () {},
        ),
      );

      expect(find.text('CONFIGURER L’ÉVÉNEMENT'), findsOneWidget);
      expect(find.text('DANS LA SCENE LIÉE'), findsOneWidget);
      expect(find.text('Lecture seule'), findsOneWidget);
      expect(find.textContaining('Défini dans la Scene'), findsWidgets);
      for (var index = 0; index < 4; index++) {
        expect(
          tester
              .getSize(
                find.byKey(
                  ValueKey('event-builder-v2-library-authorable-$index'),
                ),
              )
              .height,
          lessThanOrEqualTo(34),
        );
      }
      expect(find.textContaining('Déposez'), findsNothing);
      expect(find.textContaining('Glissez'), findsNothing);
      expect(find.byIcon(CupertinoIcons.line_horizontal_3), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the real Scene action supports hover and keyboard focus',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 213,
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: true,
          onOpenScene: () {},
        ),
      );
      final action = find.text('Ouvrir la Scene');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(action));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(action, findsOneWidget);
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('NS-EVENT-V2-39 inspector fidelity', () {
    testWidgets('renders the truthful dense hierarchy and optional conflict',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(outcomeCount: 2),
          onOpenScene: () {},
        ),
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-source')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conditions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-scene')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-behavior')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        findsNothing,
      );
      expect(find.textContaining('2 résultats'), findsOneWidget);
      expect(find.textContaining('Lecture seule'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(outcomeCount: 2),
          onOpenScene: () {},
          onManageEvaluationOrder: () {},
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        240,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        findsOneWidget,
      );
    });

    testWidgets('supports long labels and four projected outcomes',
        (tester) async {
      final longLabel = List.filled(
        7,
        'Rencontre rivale au port sous une pluie particulièrement intense',
      ).join(' ');
      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(
            title: longLabel,
            outcomeCount: 4,
            sceneLabel: longLabel,
          ),
          onOpenScene: () {},
        ),
      );

      expect(find.text(longLabel), findsWidgets);
      expect(find.textContaining('4 résultats'), findsOneWidget);
      expect(find.textContaining('sourceId'), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required double width,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 817));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(width: width, height: 817, child: child),
      ),
    ),
  );
  await tester.pump();
}

NarrativeEventProjectSummary _summary({
  String title = 'Rencontre rival au port',
  String sceneLabel = 'Rencontre avec le rival',
  int outcomeCount = 0,
  List<String>? outcomeLabels,
}) {
  final outcomes = outcomeLabels ??
      [
        for (var index = 0; index < outcomeCount; index++)
          switch (index) {
            0 => 'Victoire',
            1 => 'Défaite',
            2 => 'Échec',
            _ => 'Résultat ${index + 1}',
          },
      ];
  return NarrativeEventProjectSummary(
    stableKey: 'event:rival',
    eventId: 'evt_rival',
    title: title,
    origin: NarrativeEventProjectOrigin.v2,
    readOnly: false,
    enabled: true,
    group: NarrativeEventProjectGroupKind.map,
    groupKey: 'map:port',
    groupLabel: 'Port Selbrume',
    status: NarrativeEventProjectStatus.configuredEnabledReady,
    severity: NarrativeEventProjectSummarySeverity.info,
    source: NarrativeEventSourceSummary(
      source: NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_rival',
      ),
      humanSentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
      sourceTypeLabel: 'Interaction avec un personnage ou un objet',
      mapId: 'map_port',
      mapLabel: 'Port Selbrume',
      available: true,
      debugTechnicalLabel: 'hidden',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: 'scene_rival',
      humanLabel: sceneLabel,
      valid: true,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: 2,
      valid: true,
      unresolvedCount: 0,
      humanLabel: '2 conditions, toutes doivent être remplies',
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      enabled: true,
      humanLabel: 'Une seule fois',
    ),
    migration: NarrativeEventMigrationSummary(humanLabel: 'Format V2'),
    projection: NarrativeEventProjectionSummary(
      outcomeLabels: outcomes,
      consequences: [
        NarrativeEventProjectedConsequenceSummary(
          kind: SceneConsequenceKind.setFact,
          humanLabel: 'Le rival a été rencontré.',
          debugReference: 'hidden',
        ),
      ],
      worldRules: [
        NarrativeEventProjectedWorldRuleSummary(
          ruleId: 'rule_port',
          humanLabel: 'Le gardien du port se déplace.',
          enabled: true,
        ),
      ],
      readOnly: true,
    ),
    compatibilityOrigins: const [],
    diagnostics: const [],
    debug: NarrativeEventProjectDebugFields(
      eventId: 'evt_rival',
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
~~~~


### 14.15 `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_visual_test.dart`

~~~~dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/event_builder_v2_visual_harness.dart';

const _capturePhaseK = bool.fromEnvironment('NS_EVENT_V2_PHASE_K_CAPTURE');

void main() {
  group('NS-EVENT-V2-38 reference grid', () {
    test('visual fixture is deterministic and covers every project group', () {
      final first = buildEventBuilderV2PhaseKReadModel();
      final second = buildEventBuilderV2PhaseKReadModel();

      expect(first.toDebugJson(), second.toDebugJson());
      expect(first.events.length, greaterThanOrEqualTo(15));
      expect(
        first.groups.map((group) => group.kind).toSet(),
        NarrativeEventProjectGroupKind.values.toSet(),
      );
      expect(
        first.eventByStableKey(eventBuilderV2PhaseKSelectedStableKey),
        isNotNull,
      );
      expect(eventBuilderV2PhaseKAppIconFile.existsSync(), isTrue);
    });

    testWidgets('matches the measured five-zone geometry at 1672 by 941',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
      );

      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKCaptureKey)),
        const Rect.fromLTWH(0, 0, 1672, 941),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKHeaderKey)),
        const Rect.fromLTWH(0, 0, 1672, 50),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKContextBarKey)),
        const Rect.fromLTWH(207, 50, 1465, 52),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKNavigationKey)),
        const Rect.fromLTWH(8, 102, 191, 817),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKWorkspaceFrameKey)),
        const Rect.fromLTWH(207, 102, 1456, 817),
      );

      final list = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-list')),
      );
      final library = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-library')),
      );
      final editor = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-editor')),
      );
      final inspector = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-inspector')),
      );

      expect(list, const Rect.fromLTWH(207, 102, 266, 817));
      expect(library, const Rect.fromLTWH(481, 102, 213, 817));
      expect(editor, const Rect.fromLTWH(702, 102, 565, 817));
      expect(inspector, const Rect.fromLTWH(1275, 102, 388, 817));
      expect(library.left - list.right, 8);
      expect(editor.left - library.right, 8);
      expect(inspector.left - editor.right, 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets('conditionally captures the reference and viewport matrix',
        (tester) async {
      if (!_capturePhaseK) return;
      await loadEventBuilderV2PhaseKCaptureFonts();

      for (final viewport in eventBuilderV2PhaseKCaptureViewports) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: viewport,
          fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
        );
        final output = File(
          'test/goldens/event_builder_v2/phase_k/'
          'event_builder_v2_${viewport.width.toInt()}x${viewport.height.toInt()}.png',
        );
        output.parent.createSync(recursive: true);
        await expectLater(
          find.byKey(eventBuilderV2PhaseKCaptureKey),
          matchesGoldenFile(output.absolute.path),
        );
      }

      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
        selectedStableKey: eventBuilderV2PhaseKBrokenSourceStableKey,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );
      final brokenOutput = File(
        'test/goldens/event_builder_v2/phase_k/'
        'event_builder_v2_1672x941_broken_source.png',
      );
      brokenOutput.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(eventBuilderV2PhaseKCaptureKey),
        matchesGoldenFile(brokenOutput.absolute.path),
      );
    });
  });
}
~~~~


### 14.16 `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2-40 responsive and accessibility matrix', () {
    testWidgets('fits every supported desktop width without overflow',
        (tester) async {
      for (final viewport in eventBuilderV2PhaseKCaptureViewports) {
        await pumpEventBuilderV2PhaseK(tester, viewport: viewport);

        final workspace = tester.getRect(
          find.byKey(eventBuilderV2PhaseKWorkspaceFrameKey),
        );
        final list = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-list')),
        );
        final editor = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-editor')),
        );
        final inspector = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        );

        expect(list.left, workspace.left);
        expect(inspector.right, lessThanOrEqualTo(workspace.right));
        expect(editor.width, greaterThanOrEqualTo(480));
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: '$viewport\n${_exceptionDetails(exception)}',
        );

        final inlineLibrary = viewport.width >= 1480;
        expect(
          find.byKey(const ValueKey('event-builder-v2-library')),
          inlineLibrary ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Ouvrir la bibliothèque'),
          inlineLibrary ? findsNothing : findsOneWidget,
        );
      }
    });

    testWidgets(
        'keeps the reference width budgets at 1280, 1440, 1480 and wide',
        (tester) async {
      const expectations = <(double, List<double>)>[
        (1280, [220, 532, 320]),
        (1440, [220, 692, 320]),
        (1480, [236, 190, 500, 330]),
        (1920, [266, 213, 814, 388]),
      ];

      for (final entry in expectations) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: Size(entry.$1, 941),
        );
        final widths = <double>[
          tester
              .getSize(find.byKey(const ValueKey('event-builder-v2-list')))
              .width,
          if (entry.$1 >= 1480)
            tester
                .getSize(
                  find.byKey(const ValueKey('event-builder-v2-library')),
                )
                .width,
          tester
              .getSize(find.byKey(const ValueKey('event-builder-v2-editor')))
              .width,
          tester
              .getSize(
                find.byKey(const ValueKey('event-builder-v2-inspector')),
              )
              .width,
        ];
        expect(widths, entry.$2, reason: '${entry.$1.toInt()} px');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('supports 125 percent text scale without clipping or overflow',
        (tester) async {
      for (final viewport in const <Size>[
        Size(1280, 941),
        Size(1672, 941),
      ]) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: viewport,
          textScaleFactor: 1.25,
        );

        expect(find.text('Rencontre rival au port'), findsWidgets);
        expect(find.text('DÉCLENCHEUR'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$viewport at 125%');
      }
    });

    testWidgets('side sheet is modal, traps focus and restores the launcher',
        (tester) async {
      var createCount = 0;
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1440, 941),
        onCreateEvent: () => createCount += 1,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Event Builder V2, vue projet',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Port Selbrume, 5 événements',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ouvrir la bibliothèque'));
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.scopesRoute == true &&
              widget.properties.label ==
                  'Bibliothèque d’éléments de l’événement',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(createCount, 0,
          reason: 'The modal barrier must keep the background inert.');

      for (var index = 0; index < 6; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_primaryFocusIsInsideSideSheet(), isTrue);
      }

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_primaryFocusIsInsideSideSheet(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
      final returnFocus = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('event-builder-v2-open-library')),
      );
      expect(returnFocus.focusNode!.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the explicit unsupported state below 1280',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1279, 941),
      );

      expect(find.text('Fenêtre trop étroite'), findsOneWidget);
      expect(
          find.textContaining('Votre sélection est conservée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

bool _primaryFocusIsInsideSideSheet() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  if (focusContext.widget is PokeMapDesktopSideSheet) return true;
  var found = false;
  (focusContext as Element).visitAncestorElements((ancestor) {
    found = ancestor.widget is PokeMapDesktopSideSheet;
    return !found;
  });
  return found;
}

String _exceptionDetails(Object? exception) {
  if (exception is FlutterError) return exception.toStringDeep();
  return '$exception';
}
~~~~


### 14.17 `packages/map_editor/test/ui/design_system/pokemap_search_field_test.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'search field is compact, labelled and clears without losing focus',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final changes = <String>[];
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: PokeMapSearchField(
                hintText: 'Rechercher un événement…',
                semanticLabel: 'Rechercher un événement',
                focusNode: focusNode,
                onChanged: changes.add,
                onClear: () => cleared = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PokeMapSearchField)).height, 34);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Rechercher un événement' &&
            widget.properties.textField == true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'port');
    await tester.pump();

    expect(changes, contains('port'));
    expect(find.byTooltip('Effacer la recherche'), findsOneWidget);

    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pump();

    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(changes.last, '');
    expect(cleared, isTrue);
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search field mirrors an external controller', (tester) async {
    final controller = TextEditingController(text: 'port');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapSearchField(
            controller: controller,
            hintText: 'Rechercher',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Effacer la recherche'), findsOneWidget);

    controller.clear();
    await tester.pump();

    expect(find.byTooltip('Effacer la recherche'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
~~~~


### 14.18 `packages/map_editor/test/ui/design_system/pokemap_diagnostic_callout_test.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'diagnostic callout exposes text, icon and consolidated semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: const Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Élément introuvable',
            message: 'Choisissez un autre élément déclencheur.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Élément introuvable'), findsOneWidget);
    expect(
      find.text('Choisissez un autre élément déclencheur.'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Erreur. Élément introuvable. '
                    'Choisissez un autre élément déclencheur.' &&
            widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );

    final surface = tester.widget<Container>(
      find.descendant(
        of: find.byType(PokeMapDiagnosticCallout),
        matching: find.byType(Container),
      ),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, PokeMapColorTokens.dark.errorSoft);
    expect(tester.takeException(), isNull);
  });

  testWidgets('diagnostic action remains an accessible real button',
      (tester) async {
    var actionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Conflit possible',
            message: 'Vérifiez la priorité des événements.',
            actionLabel: 'Gérer l’ordre',
            onAction: () => actionCount += 1,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Gérer l’ordre'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.enabled == true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Gérer l’ordre'));
    await tester.pump();

    expect(actionCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('information diagnostic uses the information icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(
          body: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'La position se modifie depuis la carte.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Information. La position se modifie depuis la carte.',
      ),
      findsOneWidget,
    );
  });
}
~~~~


### 14.19 `packages/map_editor/test/ui/design_system/pokemap_desktop_side_sheet_test.dart`

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'side sheet takes initial focus, closes on Escape and restores focus',
      (tester) async {
    final launcherFocusNode = FocusNode();
    final sheetFocusNode = FocusNode();
    addTearDown(launcherFocusNode.dispose);
    addTearDown(sheetFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: launcherFocusNode,
              onPressed: () {
                launcherFocusNode.requestFocus();
                showPokeMapDesktopSideSheet<void>(
                  context: context,
                  title: 'Bibliothèque d’éléments',
                  semanticLabel: 'Bibliothèque d’éléments de l’événement',
                  initialFocusNode: sheetFocusNode,
                  builder: (_) => TextField(
                    focusNode: sheetFocusNode,
                    decoration: const InputDecoration(labelText: 'Filtrer'),
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(sheetFocusNode.hasFocus, isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.scopesRoute == true &&
            widget.properties.namesRoute == true &&
            widget.properties.label == 'Bibliothèque d’éléments de l’événement',
      ),
      findsOneWidget,
    );

    final surface = tester.widget<Material>(
      find.descendant(
        of: find.byType(PokeMapDesktopSideSheet),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material &&
              widget.color == PokeMapColorTokens.dark.surfaceRaised,
        ),
      ),
    );
    expect(surface.color, PokeMapColorTokens.dark.surfaceRaised);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    expect(launcherFocusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'side sheet has a dismissible labelled barrier and restores focus',
      (tester) async {
    final launcherFocusNode = FocusNode();
    addTearDown(launcherFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: launcherFocusNode,
              onPressed: () {
                launcherFocusNode.requestFocus();
                showPokeMapDesktopSideSheet<void>(
                  context: context,
                  title: 'Créer un événement',
                  barrierLabel: 'Fermer la création d’événement',
                  width: 360,
                  builder: (_) => const Text('Contenu du panneau'),
                );
              },
              child: const Text('Créer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
    expect(find.bySemanticsLabel('Fermer la création d’événement'),
        findsOneWidget);

    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();

    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
    expect(launcherFocusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
~~~~


### 14.20 `docs/superpowers/plans/2026-07-16-event-builder-phase-k-pixel-closure.md`

~~~~markdown
# Event Builder Phase K — Pixel-Perfect Visual Closure Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` task by task, `test-driven-development` for every measurable visual behavior, and `verification-before-completion` before any closure claim.

**Goal:** Implement NS-EVENT-V2-38 through NS-EVENT-V2-40 so the Event Builder V2 converges on the supplied 1672×941 north star, remains honest about `Event ≠ Scene`, and stays usable across the supported desktop viewport matrix.

**North star:** `/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png`, 1672×941, SHA-256 `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885`.

**Current gate status:** Phase K formally requires Phase J. H, I and J are not validated in the roadmap; the current workspace contains only a partial, unintegrated Phase H candidate. Therefore style-only K work may proceed, but Phase K cannot be marked `DONE` until those functional gates and a deterministic production capture exist.

## Fixed constraints

- Preserve all pre-existing Phase F/G and partial H changes; no Git write operations.
- Style and layout only: no new Event contract, validator, migration or runtime behavior.
- Use PokeMap design-system primitives and semantic tokens only; no hardcoded feature colors.
- Preserve source-first wording and Scene-owned projections as read-only.
- No fake drag/drop, grips, source placement, map/source double picker, raw ID, layer or coordinate UI.
- Capture the complete product tree, not only an isolated pretty mock, once the V2 route exists.
- Do not claim pixel closure from tests alone: reference + implementation must be compared in one combined image at the same viewport/state.
- Phase K’s final report must call unvalidated upstream gates out explicitly.

## Target geometry at 1672×941

```text
Header                  0,0     1672×50
Context bar             207,50  1465×52
Narrative navigation    8,102    191×817
Event list              207,102  266×817
Element library         481,102  213×817
Event editor            702,102  565×817
Inspector               1274,102 388×817
Gutters: 8 px
```

## Task 1 — K0 preflight and deterministic visual fixture

- [ ] Re-run the current V2 widget test and resolve compile errors without expanding behavior.
- [ ] Build one rich fixture matching the reference state: selected active rival Event, two conditions, linked Scene, success/defeat projections, behavior and diagnostics.
- [ ] Add stable keys for every measured region.
- [ ] Capture initial 1672×941 candidate and record visible gaps.

## Task 2 — NS-EVENT-V2-38 reference grid and five-panel alignment

- [ ] Write RED geometry assertions for the exact 191/266/213/565/388 panel grid and 8 px gaps.
- [ ] Make the Event V2 page consume the full screenshot budget by removing the redundant outer project rail and nested island padding only for the V2 Events route.
- [ ] Keep V1/`legacyOnly` shell geometry unchanged.
- [ ] Align header/context bar, panel radii, borders, internal padding, typography and independent scrolling.
- [ ] Capture the complete 1672×941 shell and isolated workspace.
- [ ] Run Event Builder/Narrative shell regressions and scoped analysis.

## Task 3 — NS-EVENT-V2-39 editor flow, library and inspector fidelity

- [ ] Write RED tests for dynamic flow heights, 0/1/2/3+ projections, long labels and read-only ownership.
- [ ] Match dense colored sections and real connector rails using token-backed widgets.
- [ ] Match the two-section library: Event-owned authoring vs Scene-owned read-only projections.
- [ ] Match inspector hierarchy, source/conditions/Scene/behavior/conflict sections and truthful actions.
- [ ] Preserve hover/focus/disabled behavior and remove any misleading affordance.
- [ ] Capture focused reference/implementation crops and overlays.

## Task 4 — NS-EVENT-V2-40 responsive and visual-state closure

- [ ] Assert 1672 exact, 1480 five panels, 1440/1280 library side sheet, wide desktop and text scale 125%.
- [ ] Assert empty, filtered-empty, unselected, draft, active/inactive, source missing, conflict, read-only/legacy, loading/saving and error states.
- [ ] Verify no overflow, independent scroll, keyboard traversal, background inertness, focus trap, Escape and focus restoration.
- [ ] Keep state and scroll/category selection when crossing responsive breakpoints.
- [ ] Capture the viewport/state matrix.

## Task 5 — Blocking design QA and evidence

- [ ] Read `codex_rule.md` before creating the QA/evidence report.
- [ ] Render the reference and latest implementation capture side by side and in a 50% overlay at identical 1672×941 state.
- [ ] Record zone-by-zone differences, fix every P0/P1/P2, recapture and repeat.
- [ ] Save `design-qa.md` at repository root with `final result: passed` only if the actual combined comparison passes; otherwise write `final result: blocked` and the exact upstream/capture blockers.
- [ ] Run targeted/full editor tests, `flutter analyze`, and `flutter build macos --debug`.
- [ ] Request an independent contradictory review of V2-38…40, source-first/Event≠Scene, DS guardrails and evidence.
- [ ] Report final Git status and propose Phase K as `DONE`, `PARTIAL` or `BLOCKED` without editing the roadmap unless explicitly requested.

## Verification commands

```bash
cd packages/map_editor
flutter test test/ui/canvas/event_builder_v2_workspace_test.dart
flutter test test/ui/canvas/event_builder_v2_visual_test.dart
flutter test test/ui/design_system/pokemap_desktop_side_sheet_test.dart
flutter test test/event_builder_workspace_test.dart
flutter test
flutter analyze
flutter build macos --debug
```
~~~~


<!-- SOURCE_APPENDICES -->

## 15. Statut Git final complet

~~~~text
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M design-qa.md
 M examples/playable_runtime_host/lib/main.dart
 M examples/playable_runtime_host/lib/src/runtime_launch_save.dart
 M examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
 M examples/playable_runtime_host/test/runtime_launch_save_test.dart
 M packages/map_editor/lib/src/app/providers/core/repository_providers.dart
 M packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/design_system/design_system.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/test/ui/design_system/pokemap_button_test.dart
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
 M packages/map_runtime/lib/src/application/script_command_executor.dart
 M packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/cutscene_runtime_runner_test.dart
 M packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
 M packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
 M packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart
 M packages/map_runtime/test/scenario_runtime_executor_test.dart
 M packages/map_runtime/test/script_runtime_mvp_test.dart
 M packages/map_runtime/test/scripted_entity_movement_controller_test.dart
?? packages/map_editor/lib/src/application/models/narrative_event_map_bridge_models.dart
?? packages/map_editor/lib/src/application/models/narrative_event_spatial_link_journal_models.dart
?? packages/map_editor/lib/src/application/models/narrative_event_spatial_source_creation_models.dart
?? packages/map_editor/lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart
?? packages/map_editor/lib/src/application/services/map_focus_viewport_resolver.dart
?? packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart
?? packages/map_editor/lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart
?? packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart
?? packages/map_editor/lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart
?? packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart
?? packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
?? packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart
?? packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart
?? packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_desktop_side_sheet.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_diagnostic_callout.dart
?? packages/map_editor/lib/src/ui/design_system/pokemap_search_field.dart
?? packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart
?? packages/map_editor/test/event_builder_map_focus_return_flow_test.dart
?? packages/map_editor/test/event_map_navigation_controller_test.dart
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1280x941.png
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1440x941.png
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1480x941.png
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941_broken_source.png
?? packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1920x941.png
?? packages/map_editor/test/map_canvas_narrative_event_focus_test.dart
?? packages/map_editor/test/map_focus_viewport_resolver_test.dart
?? packages/map_editor/test/narrative_event_builder_v2_session_snapshot_test.dart
?? packages/map_editor/test/narrative_event_builder_v2_state_test.dart
?? packages/map_editor/test/narrative_event_explicit_source_creation_test.dart
?? packages/map_editor/test/narrative_event_map_creation_bridge_test.dart
?? packages/map_editor/test/narrative_event_source_creation_recovery_test.dart
?? packages/map_editor/test/narrative_event_source_dependency_guard_test.dart
?? packages/map_editor/test/narrative_event_spatial_link_journal_repository_test.dart
?? packages/map_editor/test/narrative_event_spatial_source_link_use_case_test.dart
?? packages/map_editor/test/support/event_builder_v2_visual_harness.dart
?? packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart
?? packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart
?? packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
?? packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart
?? packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart
?? packages/map_editor/test/ui/design_system/pokemap_desktop_side_sheet_test.dart
?? packages/map_editor/test/ui/design_system/pokemap_diagnostic_callout_test.dart
?? packages/map_editor/test/ui/design_system/pokemap_search_field_test.dart
?? packages/map_editor/test/ui/panels/narrative_event_map_bridge_panel_test.dart
?? packages/map_gameplay/lib/src/narrative_trigger_enter_fronts.dart
?? packages/map_gameplay/test/narrative_trigger_enter_fronts_test.dart
?? packages/map_runtime/lib/src/application/map_activation.dart
?? packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart
?? packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart
?? packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart
?? packages/map_runtime/lib/src/application/narrative_spatial_production_dispatch_bridge.dart
?? packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart
?? packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart
?? packages/map_runtime/test/narrative_scene_runtime_execution_test.dart
?? packages/map_runtime/test/narrative_spatial_production_dispatch_bridge_test.dart
?? packages/map_runtime/test/playable_map_game_checkpoint_load_safety_integration_test.dart
?? packages/map_runtime/test/playable_map_game_entity_interaction_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart
?? packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart
?? packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart
?? packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_qualified_outcome_v2_integration_test.dart
?? packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart
?? packages/map_runtime/test/playable_map_game_trigger_enter_v2_integration_test.dart
?? reports/narrativeStudio/events/ns_event_v2_19_map_enter_production_dispatch_bridge_v0.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f2_closure_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_f2_runtime_source_bridges_closure_v0.md
?? reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md
?? reports/narrativeStudio/events/phase_k_visual_evidence/focus_inspector.png
?? reports/narrativeStudio/events/phase_k_visual_evidence/focus_library_and_editor.png
?? reports/narrativeStudio/events/phase_k_visual_evidence/focus_navigation_and_event_list.png
?? reports/narrativeStudio/events/phase_k_visual_evidence/reference_vs_candidate_overlay_50.png
?? reports/narrativeStudio/events/phase_k_visual_evidence/reference_vs_candidate_side_by_side.png
~~~~

<!-- GIT_STATUS_APPENDIX -->
