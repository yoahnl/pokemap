# LOT 54 — Scenario Graph Editor UX Guided Authoring Report

## 1. Résumé exécutif honnête

Le graphe scénario fonctionnait déjà sur le plan technique, mais l’expérience auteur restait trop brute.  
Ce lot transforme l’inspecteur scénario en mode guidé :

- explication claire des types de nodes,
- affichage conditionnel des champs selon le type de node,
- presets d’actions/références lisibles,
- dropdowns intelligents pour ressources existantes,
- filtrage map -> event/entity/warp/trigger,
- aide contextuelle et patterns d’usage intégrés,
- clarification explicite entre Scenario Graphs / Scenario Scripts / Dialogue Library / World Maps.

En complément, un **guide utilisateur complet** a été ajouté en chemin commitable :
- `guides/SCENARIO_GRAPH_EDITOR_USER_GUIDE.md`

## 2. Diagnostic UX initial précis

### Constat avant modification

- L’inspecteur exposait beaucoup de champs techniques en même temps.
- Les différences entre `Start / Dialogue / Action / Condition / Choice / Reference / End` n’étaient pas assez pédagogiques.
- `Action Kind` était trop brut pour un usage auteur.
- Le choix des ressources demandait encore trop de saisie manuelle d’IDs.
- Le lien de compréhension entre bibliothèques (dialogues/scripts) et graphe central restait implicite.
- Le couplage `Map -> ressources de map` n’était pas suffisamment guidé.

### Sources auditées avant implémentation

- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/validation/validators.dart`

### Points structurants confirmés par audit

- Le modèle scénario (`ScenarioAsset`, `ScenarioNode`, `ScenarioEdge`) est déjà présent et persistant dans `map_core`.
- La validation métier scénario est déjà sérieuse côté `map_core` (entry node, edge endpoints, références script/dialogue/map/trainer, etc.).
- Le besoin de ce lot est donc essentiellement un **durcissement UX/authoring** côté `map_editor`.

## 3. Liste des problèmes exacts observés

1. Trop de charge cognitive dans l’inspecteur.
2. Aucune “doctrine d’usage” visible par type de node.
3. `Action Kind` peu compréhensible pour un utilisateur non technique.
4. Découverte des ressources monde insuffisante.
5. Hiérarchie conceptuelle ambiguë entre scripts/dialogues/scénarios.
6. Manque d’exemples rapides directement dans l’outil.

## 4. Décisions produit prises

1. Introduire une couche UX dédiée (`scenario_authoring_ux.dart`) pour centraliser labels, descriptions et presets.
2. Passer l’inspecteur en logique “type-driven” :
   - montrer uniquement les champs pertinents,
   - masquer les champs non pertinents,
   - garder une section “avancée” repliable pour les cas expert.
3. Remplacer la saisie libre d’action/référence par des presets lisibles.
4. Rendre les pickers dépendants de la map sélectionnée.
5. Ajouter une pédagogie in-UI :
   - définitions de node types,
   - blocs “How to use this node”,
   - blocs “Common patterns”.
6. Clarifier la terminologie dans l’explorer pour réduire la confusion produit.

## 5. Liste exhaustive des fichiers réellement modifiés

- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

## 6. Liste exhaustive des fichiers réellement créés

- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`
- `guides/SCENARIO_GRAPH_EDITOR_USER_GUIDE.md`
- `reports/lots/lot_54/LOT_54_SCENARIO_GRAPH_UX_GUIDED_AUTHORING_REPORT.md`

## 7. Liste exhaustive des fichiers analysés mais non modifiés

- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/validation/validators.dart`

## 8. Description détaillée des changements UX

### 8.1 Typologie de nodes explicitée

Implémentation :
- `scenarioNodeTypeLabel`
- `scenarioNodeTypeDescription`
- `scenarioNodeTypePickerLabel`

Effet UX :
- chaque type est décrit en langage humain,
- le picker de type devient auto-explicatif.

### 8.2 Affichage conditionnel des champs par type

`ScenarioInspectorPanel` a été structuré autour de `_buildNodeTypeSpecificSections(...)` :

- `Start` / `End` : guidance minimaliste
- `Dialogue` : dialogue/script/message
- `Action` : preset d’action + champs dépendants
- `Condition` : mode de condition + champs dépendants
- `Choice` : guidance sur labels de branches
- `Reference` : preset de référence + champs dépendants

Effet UX :
- réduction forte des champs inutiles,
- parcours auteur plus guidé.

### 8.3 Presets Action / Reference lisibles

Nouveaux presets centralisés :
- actions : message, dialogue, script, trainer battle, map event, warp, trigger, entity, set/clear flag, custom
- références : map/event/entity/warp/trigger/trainer/dialogue/script/custom

Effet UX :
- disparition du “champ technique vide”,
- choix intentionnel orienté usage.

### 8.4 Pickers map-scoped intelligents

Flow implémenté :
1. choisir `Map`,
2. lister uniquement les ressources de cette map,
3. labels enrichis (type + coordonnées + cible quand pertinent).

Exemple :
- `event_id — actor — (x,y)`
- `warp_id — (x,y) -> targetMapId`
- `trigger_id — type — area (x,y,wxh)`

### 8.5 Condition mode guidé

Modes supportés :
- aucune condition,
- flag actif,
- flag inactif,
- event consommé,
- variable égale,
- JSON brut (avancé).

Effet UX :
- usage courant simplifié,
- puissance avancée conservée via JSON brut.

### 8.6 Aide contextuelle et complexité progressive

- bloc “Repères rapides” en haut de l’inspecteur,
- cards “How to use this node” / “Common pattern”,
- section avancée repliable pour raw fields.

Effet UX :
- meilleure découverte,
- moins d’exposition brute des détails internes.

### 8.7 Clarification de terminologie explorer

Sous-libellés mis à jour pour distinguer :
- `Scenario Graphs` = orchestration,
- `Scenario Scripts` = procédures runtime réutilisables.

## 9. Description détaillée des changements techniques

### 9.1 Nouveau module `scenario_authoring_ux.dart`

Extrait :

```dart
String scenarioNodeTypeDescription(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start =>
      'Point d’entrée du scénario. Le flux commence ici.',
    ScenarioNodeType.dialogue =>
      'Affiche un dialogue ou lance une séquence dialoguée.',
    ScenarioNodeType.action => 'Déclenche une action gameplay ou narrative.',
    ScenarioNodeType.condition =>
      'Teste une condition puis redirige le flux selon le résultat.',
    ScenarioNodeType.choice =>
      'Propose un choix au joueur avec plusieurs branches.',
    ScenarioNodeType.reference =>
      'Pointe vers une ressource du projet ou un élément du monde.',
    ScenarioNodeType.end => 'Termine la séquence.',
  };
}
```

```dart
const List<ScenarioActionPreset> scenarioActionPresets = <ScenarioActionPreset>[
  ScenarioActionPreset(
    id: 'openDialogue',
    label: 'Ouvrir un dialogue',
    description: 'Lance une ressource de dialogue Yarn existante.',
    fields: {ScenarioActionField.dialogue},
  ),
  ScenarioActionPreset(
    id: 'startTrainerBattle',
    label: 'Démarrer un combat dresseur',
    description: 'Référence un dresseur pour enclencher un combat.',
    fields: {ScenarioActionField.trainer},
  ),
];
```

### 9.2 Scenario inspector piloté par type + presets

Extrait :

```dart
switch (node.type) {
  case ScenarioNodeType.action:
    return <Widget>[
      _actionPickerField(...),
      if (actionPreset != null) ..._buildFieldsForActionPreset(...),
      _quickHelpCard(...),
    ];
  case ScenarioNodeType.condition:
    return <Widget>[
      _conditionModePicker(context),
      ..._buildFieldsForConditionMode(...),
    ];
}
```

### 9.3 Filtrage dynamique des ressources par map

Extrait :

```dart
final map = await _resolveMapFromCurrentMapBinding(...);
final options = <_ScenarioMapScopedOption?>[
  null,
  ...map.events.map(
    (event) => _ScenarioMapScopedOption(
      id: event.id,
      label: '${event.id} — ${event.type.name} — (${event.position.x},${event.position.y})',
    ),
  ),
];
```

### 9.4 Canvas scénario branché sur la couche UX

Extrait :

```dart
final type = await showCupertinoListPicker<ScenarioNodeType>(
  context: context,
  title: 'Node type',
  items: ScenarioNodeType.values,
  labelOf: scenarioNodeTypePickerLabel,
);
```

### 9.5 Tests unitaires ajoutés

`scenario_authoring_ux_test.dart` couvre :
- labels/descriptions pour tous les node types,
- résolution des presets action/reference,
- comportement fallback sur preset inconnu.

## 10. Ce qui a été validé

### Format

Commande exécutée :

```bash
dart format packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```

Résultat :
- OK, aucun changement supplémentaire.

### Analyze ciblé (fichiers du lot)

Commande exécutée :

```bash
flutter analyze \
  packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart
```

Résultat :
- OK, `No issues found`.

### Tests ciblés

Commande exécutée :

```bash
flutter test test/scenario_authoring_ux_test.dart
```

Contexte :
- exécuté dans `packages/map_editor`.

Résultat :
- OK, tous les tests passent.

### Tests package `map_editor`

Commande exécutée :

```bash
flutter test
```

Contexte :
- exécuté dans `packages/map_editor`.

Résultat :
- OK, tous les tests passent.

### Analyze package complet `map_editor`

Commande exécutée :

```bash
flutter analyze
```

Contexte :
- exécuté dans `packages/map_editor`.

Résultat :
- échec global avec 227 issues, majoritairement **infos historiques préexistantes** (deprecated riverpod refs, préférences const, etc.) et warnings hors périmètre du lot.
- aucune issue bloquante restante sur les fichiers modifiés dans ce lot.

## 11. Ce qui n’a pas été validé

- Pas de test widget/UI automatisé sur le rendu visuel exact de l’inspecteur (cards, ordre de sections, ergonomie visuelle).
- Pas de session de validation manuelle runtime avec interaction humaine sur tous les cas de presets.
- Pas d’audit global cross-package hors `map_editor` pour ce lot UX.

## 12. Limites restantes

1. Le mode “advanced/raw” reste nécessaire pour certains cas non couverts par presets.
2. Les labels de branches de `Choice` restent principalement gérés côté edges, sans éditeur dédié ultra-guidé.
3. Pas encore d’onboarding interactif multi-étapes in-app (le guide markdown couvre cette partie).
4. Certaines actions presets sont orientées authoring et peuvent nécessiter des extensions runtime selon cas avancés.

## 13. Prochaines étapes recommandées

1. Ajouter un mini éditeur de labels d’edges directement dans l’inspecteur `Choice`.
2. Ajouter des badges de validité par node (incomplet / prêt).
3. Ajouter un mode “lint auteur” du graphe (ex: Action sans cible, Condition sans 2 sorties).
4. Ajouter un lien rapide “ouvrir ressource” depuis les pickers (dialogue/script/map).

## 14. État git final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie au moment de la clôture de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
?? guides/SCENARIO_GRAPH_EDITOR_USER_GUIDE.md
?? packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
?? packages/map_editor/test/scenario_authoring_ux_test.dart
?? reports/lots/lot_54/LOT_54_SCENARIO_GRAPH_UX_GUIDED_AUTHORING_REPORT.md
```

---

Note de traçabilité :
- `/docs` est ignoré par `.gitignore` dans ce repo.
- Les livrables markdown de ce lot ont été placés en chemins commitables (`guides/` et `reports/`).
