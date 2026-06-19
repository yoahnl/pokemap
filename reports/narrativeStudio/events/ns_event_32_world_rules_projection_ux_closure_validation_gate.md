# NS-EVENT-32 — Event Builder World Rules Projection UX Closure / Validation Gate

## 1. Résumé exécutif

Verdict : **DONE**.

NS-EVENT-32 ferme l'UX du bloc `Changements du monde` de l'Event Builder sans ajouter de mécanique, sans authoring World Rule, sans simulation runtime, sans modification `map_core`.

Ce qui change :

- le bloc distingue mieux les `Sources projetées` et les `Règles concernées` ;
- les textes longs NS-EVENT-31 sont raccourcis ;
- les lignes `Condition observée`, `Cible`, `Effet déclaré`, `Note` sont compactées ;
- le wording de règle désactivée devient plus neutre : `Désactivée : listée pour contexte, sans effet produit.` ;
- l'inspecteur droit reste synthétique, mais utilise les mêmes compteurs no-code : `sources projetées`, `règles concernées` ;
- les tests verrouillent les garde-fous anti-authoring et anti-simulation ;
- une Visual Gate finale NS-EVENT-32 est produite.

Le lot reste strictement `map_editor` :

- aucun `map_core` modifié ;
- aucun runtime/gameplay/battle modifié ;
- aucun `WorldRuleDefinition` modifié ;
- aucun `GameState` modifié ;
- aucune donnée Selbrume modifiée ;
- aucun bouton `Créer une règle monde`, `Ajouter une règle`, `Éditer règle`, `Modifier effet` ajouté ;
- aucun drag/drop ajouté.

## 2. Usage du MCP Dart

MCP Dart demandé par le prompt, mais indisponible dans ce tour.

Vérifications effectuées :

```text
tool_search query: dart lsp diagnostics symbols references
=> outils retournés : GitHub / Atlassian / autres connecteurs, pas de namespace mcp__dart utilisable.

tool_search query: mcp__dart roots lsp dart analysis diagnostics
=> outils retournés : node_repl / codex_app / figma / notion, pas de namespace mcp__dart utilisable.
```

Contexte de reprise après compaction : des appels `mcp__dart.roots` et `mcp__dart.lsp` avaient aussi été tentés plus tôt dans le lot et avaient échoué avec des appels non supportés. Je ne revendique donc aucun diagnostic MCP Dart réussi pour NS-EVENT-32.

Compensation CLI exécutée :

- recherche `rg` des symboles et wordings ;
- lecture directe des fichiers Dart ;
- tests widget ciblés et complets ;
- régression `map_core` read model ;
- analyse Flutter ciblée ;
- build macOS debug.

## 3. Sous-agents utilisés

Sous-agents utilisés : 4 spécialistes + 1 reviewer contradictoire + orchestrateur principal.

Identifiants de session disponibles :

- Sous-agent A : `019edd6e-a8b1-7b13-ae3a-3ab63c9716e3`
- Sous-agent B : `019edd6e-cf56-7361-8cea-0e02b8e112d5`
- Sous-agent C : `019edd6e-fa55-7301-b38b-d89d317c6e1c`
- Sous-agent D : `019edd6f-2134-7df2-a89e-9e81212ea0bf`
- Sous-agent E : `019edd6f-4694-7dd1-b79e-bd412be647d9`

### Sous-agent A — UX Density / Layout

Conclusion :

- le bloc Monde NS-EVENT-31 est correct pour 1-2 règles, mais trop dense dès que plusieurs règles sont listées ;
- les causes principales sont les phrases longues, les répétitions `lecture seule / projection passive`, et les lignes label/valeur verticales ;
- le bloc central doit rester, mais il faut le structurer en deux niveaux plus lisibles : sources d'état, puis règles qui les observent.

Décision appliquée :

- titre `Effets prévisibles en lecture seule.` remplacé par `Sources projetées` ;
- titre `Règles du monde concernées` remplacé par `Règles concernées` ;
- compteur `impact(s) prévisible(s)` remplacé par `source(s) projetée(s)` côté UI ;
- cartes de règles conservées, mais leurs lignes internes sont compactées.

### Sous-agent B — Read Model Consumer / No Recalculation

Conclusion :

- l'UI consomme déjà `selected.worldImpacts` et `selected.worldRules` ;
- aucun recalcul de World Rule dans `map_editor` n'est nécessaire ;
- l'inspecteur doit rester synthétique.

Décision appliquée :

- aucune nouvelle logique de projection ajoutée ;
- aucun accès direct à `ProjectManifest.worldRules` ajouté dans l'UI ;
- l'inspecteur affiche seulement les compteurs harmonisés.

### Sous-agent C — UX No-code / Wording

Conclusion :

- retirer les mentions trop techniques ou trop longues ;
- ne pas promettre d'effet runtime ;
- éviter `read model` dans l'expérience utilisateur principale ;
- garder `Lecture seule`, `Projection passive`, `Activée` et `Désactivée`.

Décision appliquée :

- le sous-titre Monde devient `Ce que l'événement ou la scène peut modifier dans l'état du jeu.` ;
- le sous-titre des règles devient `Les règles ci-dessous observent ces sources. Elles ne sont pas simulées ici.` ;
- les états vides deviennent plus courts ;
- les tests garantissent l'absence de `Cette règle sera active`, `Effet appliqué`, `Créer une règle monde`, `Ajouter une règle`, `Éditer règle`, `Modifier effet`.

### Sous-agent D — Tests / Visual Gate

Conclusion :

- ajouter un groupe NS-EVENT-32 dans `event_builder_workspace_test.dart` ;
- couvrir les états denses, vides, sans authoring, et l'inspecteur ;
- produire une capture dédiée.

Décision appliquée :

- 4 tests widget NS-EVENT-32 ajoutés ;
- 1 test de capture NS-EVENT-32 ajouté ;
- les tests NS-EVENT-28/31 existants ont été réalignés sur le wording final.

### Sous-agent E — Reviewer contradictoire

Conclusion :

- refuser toute modification `map_core` ;
- refuser runtime/gameplay/battle ;
- refuser création, édition, simulation ou application de World Rule ;
- refuser `EventReaction`, `EventOutcome`, drag/drop et boutons d'authoring ;
- vérifier que le lot reste une fermeture UX, pas une extension.

Décision appliquée :

- seuls `packages/map_editor/lib/src/ui/canvas/events/*.dart`, le test widget et la capture sont modifiés ;
- la commande anti-scope runtime/core est vide.

### Arbitrage orchestrateur

Arbitrage retenu :

- garder le bloc central comme lieu principal de lecture ;
- harmoniser l'inspecteur sans le transformer en liste détaillée ;
- conserver les badges par règle, car le prompt les demande explicitement ;
- ne pas déplacer de responsabilité vers l'Event Builder.

## 4. Audit initial

### Gate 0

Commandes exécutées avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sorties utiles :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all => <vide>
git diff --stat => <vide>
git diff --name-only => <vide>

972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0 - DONE
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
```

### Fichiers lus

Règles :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Rapports :

- `reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md`

Code et tests :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`

## 5. Décision UX Monde

Avant NS-EVENT-32, le bloc Monde était juste, mais trop bavard :

- `Effets prévisibles en lecture seule.` ;
- `Règles du monde concernées` ;
- longue phrase sur le Builder, la simulation et l'effet ;
- lignes verticales `Condition observée`, `Cible`, `Effet déclaré`, `Note` ;
- inspecteur encore en `effets prévisibles` / `potentiellement concernées`.

Décision finale :

- `Sources projetées` = mutations directes visibles depuis l'Event/Scene ;
- `Règles concernées` = règles qui observent ces sources ;
- `Lecture seule` et `Projection passive` restent visibles ;
- les règles désactivées restent listées, mais sans promesse d'effet ;
- l'inspecteur indique seulement les compteurs.

## 6. Wording final

Wording ajouté ou harmonisé :

```text
Sources projetées
Ce que l'événement ou la scène peut modifier dans l'état du jeu.
Aucune source d'état projetée
Aucun changement d'état visible pour l'instant.
Règles concernées
Les règles ci-dessous observent ces sources. Elles ne sont pas simulées ici.
Aucune règle ne peut être reliée tant qu'aucun changement d'état n'est visible.
Aucune règle ne lit les sources affichées ci-dessus.
1 source projetée / N sources projetées
1 règle concernée / N règles concernées
Désactivée : listée pour contexte, sans effet produit.
```

Wording explicitement gardé hors UI principale :

```text
Cette règle sera active
Effet appliqué
Créer une règle monde
Ajouter une règle
Éditer règle
Modifier effet
Drag/drop
```

## 7. Modifications UI

### `event_builder_workspace.dart`

Changements principaux :

- résumé du bloc Monde harmonisé côté UI sans toucher le read model `map_core` ;
- `_WorldImpactsProjectionBlock` renommé visuellement en `Sources projetées` ;
- états vides raccourcis ;
- `_WorldRulesProjectionBlock` renommé visuellement en `Règles concernées` ;
- compteur issu de `projection.label` remplacé côté UI par un compteur compact ;
- note disabled raccourcie ;
- `_WorldRuleProjectionLine` compacte les couples label/valeur sur une seule ligne.

Extraits pertinents :

```dart
summary: selected.worldImpacts.isEmpty
    ? 'Aucune source projetée'
    : _sourceCountLabel(selected.worldImpacts.length),
```

```dart
Text('Sources projetées')
Text('Ce que l’événement ou la scène peut modifier dans l’état du jeu.')
```

```dart
Text('Règles concernées')
Text('Les règles ci-dessous observent ces sources. Elles ne sont pas simulées ici.')
```

```dart
String _sourceCountLabel(int count) {
  return '$count source${count > 1 ? 's' : ''} projetée${count > 1 ? 's' : ''}';
}

String _worldRuleCountLabel(int count) {
  return '$count règle${count > 1 ? 's' : ''} concernée${count > 1 ? 's' : ''}';
}
```

### `event_builder_inspector_panel.dart`

Changements principaux :

- l'inspecteur conserve ses lignes `Changements monde` et `Règles monde` ;
- les valeurs deviennent `Aucune source projetée`, `N sources projetées`, `N règles concernées`.

Extrait pertinent :

```dart
if (impacts.isEmpty) {
  return 'Aucune source projetée';
}
return '${impacts.length} source${impacts.length > 1 ? 's' : ''} projetée${impacts.length > 1 ? 's' : ''}';
```

## 8. Tests ajoutés / modifiés

Fichier :

- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests NS-EVENT-32 ajoutés :

- `NS-EVENT-32 distinguishes projected sources and related rules`
- `NS-EVENT-32 keeps empty states concise`
- `NS-EVENT-32 keeps no-authoring wording guardrails`
- `NS-EVENT-32 keeps several passive rules readable`
- `captures NS-EVENT-32 world rules UX closure visual gate`

Régressions réalignées :

- NS-EVENT-16 : attend `Sources projetées` ;
- NS-EVENT-28 : attend `Sources projetées`, `sources projetées`, états vides courts ;
- NS-EVENT-31 : attend `Règles concernées`, `règles concernées`, lignes compactes.

Helper de test ajouté :

```dart
EventBuilderWorldRuleProjectionReadModel _worldRuleProjection({
  required String ruleId,
  required String ruleLabel,
  required String predicateLabel,
  required String targetLabel,
  required String effectLabel,
  bool enabled = true,
})
```

## 9. Visual Gate

Capture produite :

```text
reports/narrativeStudio/events/screenshots/ns_event_32_world_rules_projection_ux_closure_validation_gate.png
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_32_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-32"
```

Résultat :

```text
00:02 +1: All tests passed!
```

Taille et hash :

```text
269825 bytes
ba03075a7bda81fc0e1ef63a4fa4e6867509fdd7f450d5cf39560a135a4e18e3
```

Inspection visuelle :

- liste d'événements visible ;
- bibliothèque visible ;
- bloc Monde visible ;
- `Règles concernées` visible ;
- 2 règles listées ;
- badges `Activée`, `Désactivée`, `Lecture seule`, `Projection passive` visibles ;
- inspecteur droit harmonisé : `2 sources projetées`, `2 règles concernées` ;
- aucun bouton d'authoring World Rule visible.

## 10. Validations exécutées

### Tests ciblés NS-EVENT-32

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-32"
```

Résultat :

```text
00:03 +5: All tests passed!
```

### Tests ciblés inspecteur + NS-EVENT-32

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-31 updates inspector world rules summary|NS-EVENT-32"
```

Résultat :

```text
00:03 +6: All tests passed!
```

### Suite complète Event Builder workspace

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat utile exact :

```text
00:10 +97: All tests passed!
```

### Régression `map_core`

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Résultat utile exact :

```text
00:00 +34: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 5 items...
No issues found! (ran in 1.8s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 11. Fichiers modifiés / créés

Modifiés :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Créés :

- `reports/narrativeStudio/events/screenshots/ns_event_32_world_rules_projection_ux_closure_validation_gate.png`
- `reports/narrativeStudio/events/ns_event_32_world_rules_projection_ux_closure_validation_gate.md`

Supprimés :

- aucun.

## 12. Non-objectifs respectés

Confirmé :

- pas de modification `map_core` ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de modification `GameState` ;
- pas de modification `WorldRuleDefinition` ;
- pas de modification Selbrume ;
- pas de modification `project.json` ;
- pas de build_runner ;
- pas de generated files ;
- pas de commit ;
- pas de simulation World Rule ;
- pas d'application d'effet ;
- pas d'authoring World Rule ;
- pas de drag/drop ;
- pas d'`EventReaction` ;
- pas d'`EventOutcome`.

## 13. Impact sur NS-EVENT-33

NS-EVENT-32 laisse un bloc Monde fermé côté UX lecture seule.

NS-EVENT-33 peut maintenant partir sur un lot distinct sans dette de lisibilité immédiate. Recommandation :

```text
NS-EVENT-33 — Event Builder MVP Closure / End-to-End Authoring Readiness Gate
```

Objectif recommandé :

- auditer le flux MVP complet Event Builder ;
- vérifier création, trigger, conditions, scene action, behavior, projections Monde ;
- lister ce qui manque avant runtime smoke ou avant prochain authoring ;
- ne pas ouvrir outcomes/reactions/drag-drop.

## 14. Limites restantes

Limites assumées :

- les règles ne sont pas simulées ;
- les World Rules restent des projections passives ;
- l'Event Builder ne permet toujours pas de créer ou modifier une World Rule ;
- les règles avec beaucoup de texte peuvent encore augmenter la hauteur des cartes ;
- le read model `map_core` conserve ses libellés internes historiques, mais l'UI les traduit sans modifier le contrat.

## 15. Evidence Pack

### Commandes de recherche utiles

```bash
rg -n "Sources projetées|Règles concernées|Aucune source projetée|source\$|règle\$|Désactivée : listée|_sourceCountLabel|_worldRuleCountLabel" \
  packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
```

Sortie utile :

```text
event_builder_inspector_panel.dart:257:    return 'Aucune source projetée';
event_builder_workspace.dart:1338:              ? 'Aucune source projetée'
event_builder_workspace.dart:1339:              : _sourceCountLabel(selected.worldImpacts.length),
event_builder_workspace.dart:2876:          'Sources projetées',
event_builder_workspace.dart:2903:            _sourceCountLabel(impacts.length),
event_builder_workspace.dart:2945:          'Règles concernées',
event_builder_workspace.dart:2984:                  _worldRuleCountLabel(projection.rules.length),
event_builder_workspace.dart:3093:                      'Désactivée : listée pour contexte, sans effet produit.',
event_builder_workspace.dart:3112:String _sourceCountLabel(int count) {
event_builder_workspace.dart:3116:String _worldRuleCountLabel(int count) {
```

### Diff stat avant rapport

```text
.../events/event_builder_inspector_panel.dart      |   6 +-
.../ui/canvas/events/event_builder_workspace.dart  |  67 ++--
.../test/event_builder_workspace_test.dart         | 433 +++++++++++++++++++--
3 files changed, 437 insertions(+), 69 deletions(-)
```

### Anti-scope avant rapport

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

## 16. Auto-review critique

Points vérifiés :

- le lot reste `map_editor` ;
- aucune World Rule n'est simulée ;
- aucune World Rule n'est créée ou modifiée ;
- l'UI consomme toujours le read model ;
- l'inspecteur ne duplique pas la liste complète ;
- le wording ne vend pas un résultat runtime garanti ;
- les tests couvrent les états vide, matching, dense, disabled, no-authoring ;
- la Visual Gate montre le bloc Monde final.

Réserve mineure :

- le compteur compact apparaît à la fois dans l'en-tête du bloc central et dans le corps du bloc. C'est accepté, car l'en-tête aide au scan global et le corps aide à comprendre le détail local.

## 17. Critique du prompt

Le prompt est large pour un lot de closure, surtout avec sous-agents, MCP Dart, Visual Gate, tests complets, analyse et build. Le périmètre reste néanmoins cohérent parce qu'il cible une fermeture UX précise.

Point de friction :

- MCP Dart n'était pas exploitable dans ce tour ; le prompt prévoit ce cas, donc la compensation CLI est acceptable.

Point produit :

- demander explicitement l'inspecteur dans NS-EVENT-32 aurait évité une découverte tardive via la capture. La capture a néanmoins rempli son rôle : elle a révélé le wording résiduel `effets prévisibles` / `potentiellement concernées`.

Décision :

- pas besoin de NS-EVENT-32-bis ;
- NS-EVENT-33 peut être une fermeture MVP/readiness plutôt qu'un autre polish Monde.

## 18. Gate final

Commandes :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie `git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_32_world_rules_projection_ux_closure_validation_gate.md
?? reports/narrativeStudio/events/screenshots/ns_event_32_world_rules_projection_ux_closure_validation_gate.png
```

Sortie `git diff --stat` :

```text
 .../events/event_builder_inspector_panel.dart      |   6 +-
 .../ui/canvas/events/event_builder_workspace.dart  |  67 ++--
 .../test/event_builder_workspace_test.dart         | 433 +++++++++++++++++++--
 3 files changed, 437 insertions(+), 69 deletions(-)
```

Sortie `git diff --name-only` :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Sortie `git diff --check` :

```text
<vide>
```

Sortie anti-scope :

```text
<vide>
```
