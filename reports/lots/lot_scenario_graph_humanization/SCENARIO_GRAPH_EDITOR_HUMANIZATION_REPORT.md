# Scenario Graph Editor — Humanization / UX Rework Report

## 1. Résumé exécutif honnête

Ce lot transforme l’inspecteur Scenario Graph d’une logique “champs techniques” vers une logique “intentions métier”.

Changements majeurs :
- ajout d’une couche de sémantique UX (support runtime, presets source/déclencheur, résumé humain),
- ajout d’une section de recettes “Blueprint” qui génèrent des mini-flows concrets,
- durcissement de la distinction source vs exécution,
- meilleure guidance map-contextuelle,
- maintien d’un mode avancé pour les cas experts.

Ce lot améliore fortement l’authoring, mais ne prétend pas que tout le graphe est exécuté runtime de façon complète aujourd’hui.

## 2. Audit UX initial précis

### Réponses explicites aux points demandés

1. **Champs remplaçables par sélecteurs intelligents**
- Action kind, condition type, dialogue, script, trainer, map, event/entity/warp/trigger.
- Flags/variables : texte assisté + suggestions projet.

2. **Champs encore trop visibles/inutiles**
- Trop d’inputs “raw” dans le parcours principal.
- Ambiguïté entre référence descriptive et action exécutable.

3. **Cas d’usage concrets encore difficiles avant ce lot**
- map enter -> dialogue,
- trigger enter -> dialogue,
- PNJ interact -> script,
- combat trainer scénarisé,
- condition flag A/B sans construire à la main.

4. **Compréhension utilisateur sans aide**
- partielle seulement,
- trop dépendante des connaissances internes du modèle.

5. **Ambiguïtés exactes**
- node type vs action kind,
- reference vs action,
- dialogue vs script,
- authoring orchestration vs exécution runtime réelle.

6. **Champs devant devenir guidés prioritairement**
- action kind,
- condition mode,
- ressources map-scoped dépendantes de map,
- flags/variables (assistés).

7. **Plus petit diff UX utile**
- renforcer la logique d’inspecteur (sans casser modèle),
- ajouter des recettes de flow concret,
- ajouter résumé métier + statut runtime/honnêteté.

## 3. Problèmes identifiés

- Le créateur devait encore “penser moteur” au lieu de “penser gameplay/narration”.
- Les cas simples demandaient plusieurs manipulations non guidées.
- Les presets existants ne distinguaient pas assez “source de déclenchement” et “effet”.
- Le runtime support de chaque preset n’était pas explicite côté UI.

## 4. Direction produit retenue

1. Garder les types de nodes existants (pas de casse schéma).
2. Introduire explicitement des presets “source/déclencheur” via `Reference`.
3. Ajouter des recettes prêtes à l’emploi qui créent des sous-graphes.
4. Ajouter un résumé humain de node + rôle + niveau de support runtime.
5. Conserver le mode avancé, mais le garder secondaire.

## 5. Décisions UX/métier appliquées

### 5.1 Support runtime explicite

Ajout d’un enum de support :
- `runtimeReady`
- `authoringBridge`
- `planned`

Affiché dans l’inspecteur et dans les labels de picker d’action.

### 5.2 Presets source/déclencheur

Nouveaux presets `Reference` :
- `sourceMapEnter`
- `sourceTriggerEnter`
- `sourceEntityInteract`

But :
- représenter visuellement la source d’activation dans le flow.

### 5.3 Résumé humain du node

Ajout d’un résumé généré :
- rôle du node,
- phrase métier lisible,
- statut de support runtime quand applicable.

### 5.4 Recettes Blueprint

Ajout de 5 recettes automatiques :
- Entrée map -> dialogue
- Entrée trigger -> dialogue
- Parler PNJ -> script
- Combat dresseur
- Condition flag A/B

Chaque recette crée nodes + edges de base pour enlever les frictions.

### 5.5 Progressive disclosure conservé

- mode principal guidé,
- mode raw avancé conservé pour experts.

## 6. Fichiers modifiés (exhaustif)

- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`

## 7. Fichiers créés (exhaustif)

- `guides/SCENARIO_GRAPH_EDITOR_HUMAN_FIRST_GUIDE.md`
- `reports/lots/lot_scenario_graph_humanization/SCENARIO_GRAPH_EDITOR_HUMANIZATION_REPORT.md`

## 8. Fichiers analysés mais non modifiés (exhaustif)

- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

## 9. Extraits de code importants et explications

### 9.1 Presets avec support runtime

```dart
enum ScenarioPresetRuntimeSupport {
  runtimeReady,
  authoringBridge,
  planned,
}
```

```dart
ScenarioActionPreset(
  id: 'sourceTriggerEnter',
  label: 'Déclencheur : entrée dans zone/trigger',
  runtimeSupport: ScenarioPresetRuntimeSupport.authoringBridge,
  fields: {ScenarioActionField.map, ScenarioActionField.trigger},
)
```

Effet :
- l’UI peut dire honnêtement si un preset est exécution réelle ou pont d’authoring.

### 9.2 Résumé humain de node

```dart
String scenarioNodeHumanSummary(ScenarioNode node) {
  ...
  return 'Ouvre le dialogue "$dialogue".';
}
```

Effet :
- meilleure compréhension immédiate sans lire les champs techniques.

### 9.3 Recettes de flow concret

Exemple :

```dart
Future<void> _applyRecipeTriggerEnterDialogue(...) async {
  // map -> trigger -> dialogue
  // création des nodes + edges
}
```

Effet :
- un cas d’usage métier devient réalisable en quelques clics.

## 10. Choix d’architecture

- Le modèle `ScenarioAsset` n’a pas été cassé.
- Les améliorations sont concentrées dans la couche UX `map_editor`.
- Aucune dépendance runtime/gameplay nouvelle introduite.
- Les recettes utilisent les use cases/notifier existants.

## 11. Clarification authoring vs runtime

Ce lot clarifie l’intention, mais ne prétend pas exécuter runtime tous les presets “bridge”.

Règle affichée :
- certains nodes/presets sont surtout des points d’ancrage d’orchestration.
- d’autres sont des effets runtime réellement supportés.

## 12. Validations réellement exécutées

### Format
```bash
dart format packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```
Résultat : OK.

### Analyze ciblé
```bash
flutter analyze packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```
Résultat : OK (0 issue).

### Tests package map_editor
```bash
flutter test
```
Résultat : OK.

### Analyze global package map_editor
```bash
flutter analyze
```
Résultat : KO global à cause d’issues historiques préexistantes hors périmètre (deprecations, warnings de style, etc.).

## 13. Ce qui n’a PAS été vérifié

- Pas de tests widget dédiés sur le rendu exact des nouvelles sections recettes/résumé.
- Pas de validation manuelle exhaustive de chaque recette en session longue UX.
- Pas de validation runtime de bout en bout pour tous les presets bridge.

## 14. Limites restantes

1. Les recettes créent une base utile mais ne couvrent pas tous les patterns possibles.
2. Le moteur runtime n’exécute pas encore toutes les intentions d’orchestration “bridge”.
3. L’éditeur d’edges pourrait encore être amélioré (édition visuelle plus riche des labels/kinds).
4. Les suggestions flag/variable dépendent des données déjà présentes.

## 15. Prochaines étapes recommandées

1. Ajouter un “mode lecture flow” (surbrillance Trigger -> Condition -> Action).
2. Ajouter un assistant de validation métier (nodes incomplets, branches manquantes).
3. Ajouter des templates de flow complets paramétrables.
4. Ajouter une vue d’aperçu “ce que le runtime exécute réellement” par node.

## 16. État git final exact

Commande :
```bash
git status --short --untracked-files=all
```

Sortie :
```text
 M packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
 M packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
 M packages/map_editor/test/scenario_authoring_ux_test.dart
?? guides/SCENARIO_GRAPH_EDITOR_HUMAN_FIRST_GUIDE.md
?? reports/lots/lot_scenario_graph_humanization/SCENARIO_GRAPH_EDITOR_HUMANIZATION_REPORT.md
```
