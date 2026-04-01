# Scenario Graph Editor — UX Simplification Lot Report

## 1. Résumé exécutif honnête

Ce lot améliore fortement l’authoring guidé du Scenario Graph Editor côté `map_editor` :
- moins de saisie manuelle brute,
- plus de sélecteurs intelligents,
- meilleure adaptation des champs au contexte,
- aide orientée cas d’usage concrets.

Le cœur de l’amélioration est dans `ScenarioInspectorPanel` :
- logique conditionnelle stricte,
- presets d’usage explicites,
- filtrage map -> event/entity/warp/trigger plus lisible,
- contexte map visible (compteurs de contenu),
- support condition `playerOnMap`.

Un nouveau tutoriel utilisateur long et commitable a aussi été ajouté :
- `guides/SCENARIO_GRAPH_EDITOR_GUIDE.md`

## 2. Audit UX initial précis

### Réponses explicites aux questions demandées

1. **Champs remplaçables par dropdowns/pickers intelligents**
- `Action Kind`
- `Condition type`
- `Script`
- `Dialogue`
- `Map`
- `Event`
- `Entity`
- `Warp`
- `Trigger`
- `Trainer`
- `Flag name` / `Variable name` (mode assisté via suggestions projet)

2. **Champs affichés à tort selon le contexte**
- Les champs map-scoped (event/entity/warp/trigger) pouvaient encore être sollicités sans map choisie.
- Les usages concrets n’étaient pas assez guidés par type de node/action/condition.
- Les champs de progression (flag/variable) restaient majoritairement en texte libre sans assistance.

3. **Cas d’usage encore difficiles avant ce lot**
- Entrée zone -> dialogue.
- PNJ -> séquence scriptée.
- Bifurcation flag active/inactive.
- Ciblage d’un élément monde spécifique sans connaître les IDs.

4. **Compréhension utilisateur avant lot**
- Possible mais encore fragile, surtout pour un utilisateur non technique.
- La logique node type vs action restait ambiguë.
- Les choix map -> ressources étaient faisables mais pas assez pédagogiques.

5. **Ambiguïtés exactes relevées**
- Confusion entre `node type` (intention structurelle) et `action kind` (effet concret).
- Confusion entre `Dialogue` et `Script`.
- Confusion entre `Action` et `Reference`.
- Confusion sur la dépendance map avant sélection d’event/entity/warp/trigger.

6. **Champs devant impérativement devenir guidés**
- `Action Kind` (fait)
- `Condition type` (fait)
- `Event/Entity/Warp/Trigger` dépendants de map (renforcé)
- `Flag/Variable` (assisté par suggestions existantes de scénario)

7. **Plus petit diff UX utile**
- Renforcer l’inspecteur (pas de refonte globale shell/canvas),
- centraliser labels/presets/hints,
- durcir la logique d’affichage conditionnel,
- améliorer la découverte des ressources map au moment de l’édition.

## 3. Problèmes exacts identifiés

- Charge cognitive trop élevée dans l’inspecteur.
- Parcours auteur trop technique pour les cas concrets.
- `Action Kind` encore perçu comme champ technique.
- Découverte map-context insuffisante sans connaître les IDs.
- Besoin d’un meilleur guidage pour les scénarios “réels”.

## 4. Choix produits retenus

1. Garder le modèle métier actuel, améliorer la couche UX par-dessus.
2. Faire des presets explicites plutôt qu’un champ libre par défaut.
3. Conserver le mode avancé “raw”, mais le reléguer en secondaire.
4. Ajouter une assistance intelligente pour flags/variables via les données existantes.
5. Ajouter des blocs “usages courants” directement dans l’inspecteur.

## 5. Liste exhaustive des fichiers modifiés

- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`

## 6. Liste exhaustive des fichiers créés

- `guides/SCENARIO_GRAPH_EDITOR_GUIDE.md`
- `reports/lots/scenario_graph_ux_simplification/SCENARIO_GRAPH_EDITOR_UX_SIMPLIFICATION_REPORT.md`

## 7. Liste exhaustive des fichiers analysés mais non modifiés

- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`

## 8. Description détaillée des changements UX

### 8.1 Action Kind plus compréhensible
- Les presets d’action incluent maintenant `executionHint`.
- L’aide affichée dans l’inspecteur distingue clairement :
  - rôle du node,
  - effet de l’action.

### 8.2 Presets d’usage concret
Dans `Action` :
- preset entrée zone -> dialogue,
- preset PNJ -> script,
- preset combat dresseur.

Dans `Condition` :
- preset flag actif,
- preset event consommé,
- preset player sur map.

Dans `Reference` :
- preset référence PNJ,
- preset référence event,
- preset référence trigger.

### 8.3 Aide map-contextuelle
- Nouveau bloc “Contexte map” :
  - Events,
  - Entités,
  - Warps,
  - Triggers.

### 8.4 Gestion stricte map dépendante
- Les pickers Event/Entity/Warp/Trigger sont désactivés sans map sélectionnée.
- Aide explicite “Choisis d’abord une map”.
- Alertes explicites si la map ne contient aucun élément du type demandé.

### 8.5 Conditions renforcées
- Ajout du mode `playerOnMap`.
- Condition `eventConsumed` renforcée avec exigence map + event.
- Assistance suggestions pour `flagName` et `variableName`.

## 9. Description détaillée des dropdowns intelligents

- Script : picker projet.
- Dialogue : picker projet.
- Trainer : picker projet.
- Map : picker projet.
- Event/Entity/Warp/Trigger : picker filtré par map courante.
- Action Kind : picker presets d’action.
- Condition type : picker des modes de condition.
- Flag/Variable : champ texte + bouton “Choisir une valeur existante”.

## 10. Description détaillée des affichages conditionnels

- `Start` / `End` : quasi aucun champ fonctionnel.
- `Dialogue` : dialogue/script/message + guidance.
- `Action` : action + champs dépendants + usages courants.
- `Condition` : mode + champs dépendants + presets.
- `Choice` : guidance sur branches.
- `Reference` : type de référence + champs dépendants.

## 11. Description détaillée de la logique Action Kind

Le système reste data-driven via `actionKind` dans le payload, mais :
- l’utilisateur choisit d’abord un preset lisible,
- les champs nécessaires s’ouvrent dynamiquement,
- chaque preset expose une description + hint d’exécution.

Cela conserve la flexibilité (raw/custom) sans imposer la complexité brute.

## 12. Description détaillée de la gestion map -> resources

Logique appliquée :
1. Sélection map.
2. Nettoyage des cibles map-scoped si map change.
3. Filtrage strict des listes dépendantes.
4. Affichage de labels enrichis (type/position/target).
5. Bloc d’aperçu contextuel de la map.

## 13. Emplacement du tutoriel markdown et justification

Fichier :
- `guides/SCENARIO_GRAPH_EDITOR_GUIDE.md`

Justification :
- chemin non ignoré par Git,
- emplacement stable et orienté documentation utilisateur,
- lisible hors du flux technique des rapports.

## 14. Validations réellement exécutées

### Format
```bash
dart format packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```
Résultat : OK.

### Analyze ciblé (fichiers du lot)
```bash
flutter analyze packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```
Résultat : OK, no issues.

### Tests package map_editor
```bash
flutter test
```
Contexte : `packages/map_editor`
Résultat : OK, all tests passed.

### Analyze global map_editor
```bash
flutter analyze
```
Contexte : `packages/map_editor`
Résultat : KO (issues historiques préexistantes hors périmètre du lot).

## 15. Ce qui n’a pas été vérifié

- Pas de test widget automatisé détaillé sur chaque interaction UI de l’inspecteur.
- Pas de playtest humain complet de tous les workflows auteur après patch.
- Pas de validation runtime de l’exécution de chaque action preset (ce lot cible l’authoring UX).

## 16. Limites restantes

1. `Choice` n’a pas encore un éditeur dédié de labels d’edges (toujours via edges).
2. Le mode raw avancé reste nécessaire pour les cas non couverts.
3. Les suggestions flag/variable dépendent des données déjà présentes dans les scénarios.
4. Le graphe reste une orchestration auteur ; toutes les actions ne signifient pas exécution directe immédiate du graph.

## 17. Prochaines étapes recommandées

1. Éditeur guidé des labels de branches (Choice/Condition).
2. Validation visuelle “node incomplet / prêt”.
3. Templates de mini-flux “zone dialogue”, “PNJ script”, “flag gate” au niveau scénario.
4. Liens rapides “ouvrir la ressource” depuis les pickers (dialogue/script/map).

## 18. État git final exact

Commande :
```bash
git status --short --untracked-files=all
```

État :
```text
 M packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
 M packages/map_editor/test/scenario_authoring_ux_test.dart
?? guides/SCENARIO_GRAPH_EDITOR_GUIDE.md
?? reports/lots/scenario_graph_ux_simplification/SCENARIO_GRAPH_EDITOR_UX_SIMPLIFICATION_REPORT.md
```
