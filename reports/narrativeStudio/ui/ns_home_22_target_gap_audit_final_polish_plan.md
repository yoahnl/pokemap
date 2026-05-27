# NS-HOME-22 - Narrative Studio Target Gap Audit / Final Polish Plan V0

## 1. Résumé exécutif

NS-HOME-22 est un audit no-code de l'état réel NS-HOME-21 contre l'image cible fournie par Karim.

Verdict :

```text
La vue Aperçu est fonctionnellement acceptable en V0.
Elle n'est pas encore visuellement assez fermée pour passer directement au checkpoint final.
Recommandation : Option B, un seul dernier lot de micro-polish, puis checkpoint.
```

Pourquoi pas fermer tout de suite :

- le haut d'écran raconte encore la même information à trois niveaux : header shell, header interne, breadcrumb/titre ;
- la sidebar interne est claire mais encore plus "rail de test" que sidebar produit finale ;
- l'état empty/générique empêche de juger complètement la profondeur visuelle du dashboard ;
- l'activité récente et le footer restent peu comparables à la cible ;
- les screenshots golden affichent encore des blocs de texte partiellement substitués.

Pourquoi ne pas lancer une longue suite de lots :

- l'architecture est correcte ;
- les interactions honnêtes sont en place ;
- les disabled states sont conformes ;
- les écarts restants majeurs dépendent de futures fonctionnalités ou de vraies données ;
- les derniers ajustements utiles tiennent dans un lot ciblé.

Décision recommandée :

```text
NS-HOME-23 - Narrative Overview Final Micro-Polish V0
Puis NS-HOME-CHECKPOINT - Narrative Overview Acceptance Checkpoint V0
```

## 2. Sources lues

Sources obligatoires :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`
- `reports/narrativeStudio/ui/ns_home_16_narrative_studio_shell_v0.md`
- `reports/narrativeStudio/ui/ns_home_17_internal_narrative_studio_sidebar_v0.md`
- `reports/narrativeStudio/ui/ns_home_18_narrative_studio_interaction_wiring_v0.md`
- `reports/narrativeStudio/ui/ns_home_19_project_explorer_handoff_reduced_mode_v0.md`
- `reports/narrativeStudio/ui/ns_home_20_narrative_studio_internal_header_actions_v0.md`
- `reports/narrativeStudio/ui/ns_home_21_narrative_studio_visual_harmonization.md`

Fichiers UI relus en lecture seule :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`

Screenshots inspectés :

- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png`
- `/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png`

## 3. État réel NS-HOME-21

### Shell global PokeMap

Le shell global reste présent :

- identité PokeMap visible dans la top toolbar ;
- workspace `Narrative Studio` visible ;
- status bar globale présente ;
- top toolbar globale non reconstruite en top bar cible finale.

Satisfaisant :

- séparation claire entre chrome global et workspace ;
- status bar conforme aux lots précédents ;
- aucun `FR` ou `v0.3.0` inventé dans l'Overview.

Fragile :

- la top toolbar globale garde une logique de shell existante, moins raffinée que l'image cible ;
- le screenshot golden affiche certains textes comme blocs blancs, ce qui complique l'évaluation fine.

### Project Explorer réduit

Le Project Explorer global est réduit en rail.

Satisfaisant :

- il reste récupérable ;
- il reste global ;
- il ne devient pas la sidebar Narrative Studio ;
- il libère l'espace principal.

Fragile :

- le rail reste visible, contrairement à l'image cible où la sidebar visible est uniquement celle du Narrative Studio ;
- ce rail est acceptable en V0, mais il donne encore un léger effet "double chrome".

### NarrativeStudioShell

Le shell interne existe et encadre la sidebar, le header et le dashboard.

Satisfaisant :

- architecture conforme à NS-HOME-15 ;
- `NarrativeStudioSidebar` et `NarrativeStudioHeader` vivent bien dans le shell interne ;
- la composition est testée.

Encore V0 :

- le shell interne reste visuellement proche d'un conteneur technique ;
- les slots futurs sont implicitement préparés, pas encore finalisés.

### NarrativeStudioSidebar

La sidebar interne contient :

- `Aperçu` actif ;
- `Storylines`, `Scènes`, `Cinématiques`, `Dialogues` branchés ;
- `Facts`, `Règles du monde`, `Validateur` disabled ;
- pas de `Maps`.

Satisfaisant :

- navigation interne claire ;
- séparation avec Project Explorer nette ;
- disabled states honnêtes.

Fragile :

- largeur et densité encore plus compactes que la cible ;
- iconographie sobre mais pas encore complètement "produit final" ;
- labels disabled parfois coupés en medium.

### NarrativeStudioHeader

Le header interne affiche :

- `Narrative Studio / Aperçu` ;
- `Dashboard auteur` ;
- actions V0 : `Nouvelle storyline`, `Aperçu`, `Valider`, `Recherche`, `Notifications`, `Paramètres`.

Satisfaisant :

- `Aperçu` est la seule action réelle ;
- actions futures disabled ;
- aucun badge notification fake ;
- header clairement dans `NarrativeStudioShell`.

Fragile :

- redondance avec le header shell au-dessus et le breadcrumb/titre interne en dessous ;
- les actions disabled sont lisibles mais encore très proches d'une top bar finale.

### Dashboard Overview

Le dashboard affiche :

- breadcrumb `PokeMap / Narrative Studio / Aperçu` ;
- titre `Aperçu` ;
- bloc Projet ;
- KPI ;
- Histoire principale ;
- Modules narratifs ;
- Structure narrative ;
- données à venir / footer plus bas.

Satisfaisant :

- hiérarchie générale solide ;
- KPI visibles sans scroll excessif en desktop ;
- cards interactives seulement quand une destination existe ;
- aucun compteur cible inventé.

Encore V0 :

- données génériques `test_project` et états empty ;
- beaucoup de surfaces indiquent `Non évalué`, `Hors scope V0`, `Nécessite un modèle` ;
- le dashboard paraît plus "outil honnête" que "démo produit".

### KPI

Satisfaisant :

- six KPI tiennent sur une ligne en desktop réduit ;
- `Chapitres`, `Scènes`, `Cinématiques`, `Dialogues` restent interactifs ;
- `Quêtes`, `Problèmes ouverts` restent non actifs.

Fragile :

- textes longs serrés en six colonnes ;
- certains labels sont peu lisibles dans les screenshots golden ;
- la taille des cartes est un compromis, pas un design final.

### Histoire principale

Satisfaisant :

- état empty honnête ;
- pas de création fake ;
- bouton `Modifier à venir` disabled si aucune source explicite ;
- métriques non évaluées exposées sans mensonge.

Encore V0 :

- la cible montre une vraie histoire principale ; l'état réel montre une absence de source ;
- l'écran paraît donc plus vide que le template cible.

### Modules narratifs

Satisfaisant :

- `Cinématiques` et `Dialogues` sont branchés ;
- `Quêtes annexes`, `Conditions narratives`, `Règles du monde`, `Facts` restent non actifs ;
- les disabled states sont visibles.

Fragile :

- les modules non actifs dominent fortement l'impression visuelle avec les fixtures actuelles ;
- `Conditions narratives` reste ambigu et doit rester non actif tant que le mapping n'est pas fiable.

### Structure narrative

Satisfaisant :

- panneau à droite stable ;
- données non disponibles affichées honnêtement ;
- aucun tag cible inventé ;
- aucun statut `À jour` sans validation.

Encore V0 :

- l'état empty rend le panneau moins riche que la cible ;
- la section statut éditorial reste surtout une preuve de non-évaluation.

### Disabled states

Satisfaisant :

- actions futures disabled ;
- destinations futures disabled ;
- pas de badge notification fake ;
- pas de `Maps` dans la sidebar interne.

Fragile :

- certains disabled ressemblent encore à de petits boutons finaux, donc peuvent être perçus comme "presque actifs" par un utilisateur non averti.

### Interactions

Satisfaisant :

- navigation sidebar réelle vers workspaces existants ;
- KPI réels branchés ;
- module cards branchables actives ;
- disabled states ne changent pas de workspace.

Encore V0 :

- aucune interaction métier nouvelle ;
- pas de recherche, validation, création, notifications.

### Responsive desktop / focus / medium

Desktop :

- le layout est cohérent ;
- Structure narrative reste à droite ;
- KPI en ligne ;
- modules commencent à apparaître.

Focus :

- le haut de page est lisible ;
- header, sidebar, KPI et Structure narrative restent visibles.

Medium :

- sidebar interne stable ;
- KPI en deux lignes ;
- Structure narrative plus bas dans le flux ;
- acceptable V0.

## 4. Comparaison cible vs réel

| Zone | Image cible | État réel NS-HOME-21 | Écart | Sévérité | Décision |
| ---- | ----------- | -------------------- | ----- | -------- | -------- |
| App identity / PokeMap branding | Logo PokeMap clair, chrome premium | Identité visible, mais screenshot golden texte partiel | Qualité visuelle moins nette | acceptable V0 | Ne pas refaire la top bar maintenant |
| Project selector | Projet actif visible dans sidebar globale | Project Explorer réduit, projet non montré comme dans cible | Le rail cache la richesse projet | acceptable V0 | Garder, pas de faux projet |
| Top bar globale | Actions narratives en haut, intégrées | Top toolbar globale + header interne distincts | Deux niveaux d'actions/contexte | à corriger avant fermeture | Micro-polish de hiérarchie, pas refonte globale |
| Header interne Narrative Studio | Breadcrumb/action strip clair | Header interne clair mais redondant avec breadcrumb/titre | Répétition `Narrative Studio / Aperçu` | à corriger avant fermeture | Réduire doublons dans NS-HOME-23 |
| Sidebar interne Narrative Studio | Sidebar large, lisible, produit final | Sidebar réelle, compacte, disabled honnêtes | Plus compacte et moins finale | acceptable V0 | Micro-polish léger seulement |
| Project Explorer réduit / rail global | Non visible comme large panneau | Rail global visible et récupérable | Écart volontaire d'architecture PokeMap | acceptable V0 | Garder V0 |
| KPI cards | Cards riches, valeurs remplies | Cards denses, valeurs fixtures/empty | Moins riche, textes de golden imparfaits | acceptable V0 | Ne pas inventer de chiffres |
| Histoire principale | Histoire principale riche | Empty state honnête | Fort écart de contenu | hors scope tant que feature/donnée absente | Ne pas faker |
| Modules narratifs | Modules riches avec activité et compteurs | Modules honnêtes, beaucoup de disabled | Moins vivant | acceptable V0 | Garder disabled |
| Structure narrative | Panneau riche avec tags, statut, chapitres | Panneau honnête empty/non évalué | Moins riche | hors scope tant que source absente | Ne pas inventer tags/statuts |
| Activité récente / Données à venir | Activité récente visible | Données à venir / empty states plus bas | Écart de feature/source | hors scope tant que feature absente | Ne pas créer activité fake |
| Footer metadata | Footer discret projet/locale/version | Footer metadata honnête, locale/version non définies | Pas visible dans premier viewport | acceptable V0 | Ne pas hardcoder `FR`/version |
| Disabled actions | Cible montre actions finales | V0 montre actions disabled | Écart volontaire | acceptable V0 | Garder disabled |
| Responsive medium | Non explicitement cible | Medium lisible, KPI en deux lignes | Moins dense | acceptable V0 | Garder stable |

## 5. Écarts volontairement acceptés en V0

Ces écarts ne doivent pas être "corrigés" avec du faux :

- `Nouvelle storyline` disabled : aucun flow de création fiable n'est branché.
- `Valider` disabled : aucune validation narrative globale fiable n'est branchée.
- `Recherche` disabled : pas de recherche globale narrative.
- `Notifications` disabled : aucune source fiable, aucun badge.
- Pas de vraie activité récente : aucun modèle/source validé.
- Pas de tags réels : aucun registre de tags fiable exposé.
- Pas de `Facts` réels : modèle futur requis.
- Pas de `World Rules` réelles : surface future.
- `Validateur` interne disabled : diagnostic global futur.
- Fixtures génériques `test_project` : préférable à hardcoder `Selbrume`.
- Rail Project Explorer réduit visible : choix d'architecture PokeMap, récupérable.
- Top bar globale non pixel-perfect : hors scope tant qu'on ne refond pas le chrome global.
- Footer locale/version non définis : mieux que hardcoder `FR` ou `v0.3.0`.

Raison : la cible est une direction visuelle, pas une source de vérité métier.

## 6. Écarts restants avant fermeture V0

### Micro-polish obligatoire

Strictement parlant, aucun écart n'est bloquant pour une V0 fonctionnelle.

Mais pour fermer proprement sans laisser une impression "prototype technique", il reste un micro-polish recommandé comme dernier lot.

### Micro-polish recommandé

- Réduire la redondance entre header shell, `NarrativeStudioHeader`, breadcrumb et titre `Aperçu`.
- Clarifier visuellement les actions disabled du header pour qu'elles ressemblent moins à des actions prêtes.
- Ajuster légèrement la sidebar interne en medium pour éviter les sous-labels trop tronqués.
- Vérifier si le bloc Projet peut être moins dominant quand le header interne existe déjà.
- Harmoniser encore les rayons/bordures entre header, project strip, KPI et Structure narrative.
- Produire un dernier Visual Gate avec desktop/focus/medium et une note d'acceptance.

### Peut attendre V1

- top bar globale pixel-perfect ;
- vraie activité récente ;
- tags narratifs ;
- vraie description projet riche ;
- `Facts` et `World Rules` actifs ;
- validation globale ;
- notifications ;
- paramètres narratifs ;
- vraie démo avec données riches.

### Ne pas toucher maintenant

- ne pas activer `Nouvelle storyline` ;
- ne pas activer `Valider` ;
- ne pas réintroduire `Maps` ;
- ne pas transformer le Project Explorer en sidebar Narrative Studio ;
- ne pas inventer de compteurs ou tags.

## 7. Décision sur les prochains lots

Décision :

```text
Option B - Faire un seul dernier lot de polish.
```

Séquence recommandée :

```text
NS-HOME-23 - Narrative Overview Final Micro-Polish V0
NS-HOME-CHECKPOINT - Narrative Overview Acceptance Checkpoint V0
```

Justification :

- Option A serait défendable fonctionnellement, mais un dernier polish réduira les redondances visibles avant fermeture.
- Option C serait trop lourde : un lot de démo data réaliste risquerait de glisser vers des données fake ou un chantier fixture séparé.
- Un seul lot suffit pour nettoyer ce qui est encore vraiment visible sans relancer le chantier.

## 8. Plan final recommandé

### NS-HOME-23 - Narrative Overview Final Micro-Polish V0

Objectif :

```text
Réduire les derniers frottements visuels du haut de page et des surfaces V0,
sans nouvelle feature métier,
sans nouvelle donnée,
avant acceptance checkpoint.
```

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- tests existants de shell/overview/header si les assertions bougent ;
- rapport `reports/narrativeStudio/ui/ns_home_23_narrative_overview_final_micro_polish.md`.

Non-objectifs :

- pas de nouvelle storyline ;
- pas de validation ;
- pas de recherche ;
- pas de notifications ;
- pas de vraie activité récente ;
- pas de données cible ;
- pas de refonte top toolbar globale ;
- pas de modification `ProjectExplorerPanel`.

Tests attendus :

- shell navigation ;
- overview workspace ;
- header test ;
- project explorer handoff ;
- top toolbar ;
- status bar ;
- regression combinée courte ;
- analyse ciblée si analyse globale reste rouge.

Visual Gate attendu :

- desktop 1600x1000 ;
- focus 1600x700 ;
- medium 1180x1000 ;
- comparaison explicite avec NS-HOME-21.

Risques :

- trop supprimer de contexte et rendre l'écran moins clair ;
- rendre les actions disabled trop invisibles ;
- casser la densité medium ;
- relancer un faux chantier top bar.

Critères d'acceptation :

- moins de redondance de contexte ;
- header/breadcrumb/titre cohabitent mieux ;
- disabled states encore clairement non fonctionnels ;
- sidebar interne stable ;
- KPI et Structure narrative visibles ;
- Project Explorer réduit toujours global ;
- aucun `Maps` interne ;
- aucun fake data.

### NS-HOME-CHECKPOINT - Narrative Overview Acceptance Checkpoint V0

Objectif :

```text
Valider ou refuser officiellement la page Aperçu V0 après le dernier micro-polish.
```

Fichiers probables :

- rapport checkpoint uniquement ;
- screenshots finaux existants ou nouvellement générés via mécanisme existant.

Non-objectifs :

- pas de code ;
- pas de test ;
- pas de widget ;
- pas de nouvelle feature.

Tests attendus :

- aucun test obligatoire si audit-only ;
- relance ciblée autorisée pour preuve si Karim le demande.

Visual Gate attendu :

- revue des screenshots NS-HOME-23 ;
- table acceptance / non-acceptance.

Risques :

- confondre acceptance V0 et produit final ;
- demander une perfection pixel cible hors scope.

Critères d'acceptation :

- décision claire : V0 fermée ou bis strictement justifié ;
- liste courte de limites V1 ;
- evidence pack complet.

## 9. Garde-fous pour fermer la page Aperçu

- Ne jamais transformer `ProjectExplorerPanel` en sidebar finale Narrative Studio.
- Ne pas supprimer le Project Explorer global.
- Ne pas activer `Nouvelle storyline`.
- Ne pas activer `Valider`.
- Ne pas créer de recherche narrative.
- Ne pas créer de notifications ou badge fake.
- Ne pas créer de données fake.
- Ne pas réintroduire `Maps` dans la sidebar interne.
- Ne pas hardcoder `Selbrume`, `La brume du phare`, les tags ou chiffres de l'image cible.
- Ne pas utiliser l'image cible comme vérité métier.
- Ne pas faire de pixel-perfect.
- Garder les disabled states honnêtes.
- Conserver les interactions réelles existantes : sidebar, KPI branchables, modules branchables.
- Ne pas déplacer les modèles métier dans l'UI.

## 10. Risques

- Sur-polish : prolonger indéfiniment une V0 déjà utilisable.
- Faux réalisme : remplir l'écran avec des données inspirées de l'image cible.
- Confusion architecture : vouloir cacher le rail global en cassant la séparation Project Explorer / Narrative Studio.
- Régression responsive : compresser trop fort le medium.
- Régression honnêteté : rendre une action disabled trop ressemblante à une action active.
- Mauvaise lecture des golden tests : les blocs blancs de police sont un artefact de capture, pas forcément un problème runtime.

## 11. Evidence Pack

### Branche

```text
git branch --show-current
main
```

### Git status initial

```text
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Working tree propre au début de NS-HOME-22.

### Git diff stat initial

```text
git diff --stat
```

Sortie initiale :

```text
```

### Git diff name-only initial

```text
git diff --name-only
```

Sortie initiale :

```text
```

### Git diff check initial

```text
git diff --check
```

Sortie initiale :

```text
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- `reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md`
- `reports/narrativeStudio/ui/ns_home_16_narrative_studio_shell_v0.md`
- `reports/narrativeStudio/ui/ns_home_17_internal_narrative_studio_sidebar_v0.md`
- `reports/narrativeStudio/ui/ns_home_18_narrative_studio_interaction_wiring_v0.md`
- `reports/narrativeStudio/ui/ns_home_19_project_explorer_handoff_reduced_mode_v0.md`
- `reports/narrativeStudio/ui/ns_home_20_narrative_studio_internal_header_actions_v0.md`
- `reports/narrativeStudio/ui/ns_home_21_narrative_studio_visual_harmonization.md`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`

### Liste des screenshots inspectés

```text
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
May 27 20:18:10 2026 228756

reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png: PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
May 27 20:18:33 2026 159965

reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png: PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
May 27 20:18:55 2026 148399

reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
May 27 20:19:17 2026 228756

/Users/karim/Desktop/assets/pokeMap/définitive/1 - page d'accueil.png: PNG image data, 1672 x 941, 8-bit/color RGB, non-interlaced
May 26 20:34:05 2026 1359975
```

### Confirmations no-code

- Aucun code production modifié.
- Aucun test modifié.
- Aucun widget créé.
- Aucun modèle métier modifié.
- Aucun fichier `map_core` modifié.
- Aucun fichier runtime modifié.
- Aucun fichier gameplay modifié.
- Aucun fichier battle modifié.
- Aucun `build_runner` lancé.
- Aucun test lancé, conformément au scope audit-only.
- Aucune commande Git d'écriture lancée.

### Git status final

Après création de ce rapport uniquement :

```text
?? reports/narrativeStudio/ui/ns_home_22_target_gap_audit_final_polish_plan.md
```

### Git diff stat final

```text
git diff --stat
```

Sortie finale :

```text
```

### Git diff name-only final

```text
git diff --name-only
```

Sortie finale :

```text
```

### Git diff check final

```text
git diff --check
```

Sortie finale :

```text
```

Note : `git diff --stat`, `git diff --name-only` et `git diff --check` ne listent pas ce rapport tant qu'il est non tracké.

## 12. Auto-review critique

Le rapport distingue bien :

- les vrais écarts visuels ;
- les écarts acceptables V0 ;
- les écarts qui dépendent de features absentes ;
- les écarts dus aux fixtures ou à la capture golden ;
- les choses à ne surtout pas corriger avec du faux.

Le choix Option B est volontairement strict : un seul lot de micro-polish, puis checkpoint. Pas de sous-chantier infini.

Point faible assumé : sans screenshot runtime avec vraie police, l'audit visuel reste partiellement basé sur des golden tests imparfaits.

## 13. Regard critique sur le prompt

Le prompt force la bonne décision produit : ne pas confondre "proche de la cible" avec "copier la cible".

Il évite deux pièges :

- fermer trop tôt une vue encore un peu rugueuse ;
- continuer à polir indéfiniment une V0 déjà cohérente.

La contrainte `0 à 2 lots avant checkpoint` est saine. Elle empêche la roadmap de repartir en spirale.
