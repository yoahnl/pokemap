# Environment-47 — Hide / Group Technical EnvironmentLayer V0

## 1. Résumé

Environment-47 ajoute une projection de présentation pour le `LayersPanel` afin de ne plus afficher un `EnvironmentLayer` technique attaché comme une row top-level indépendante.

Un `TileLayer` cible affiche maintenant un statut `Environnement actif` quand un `EnvironmentLayer` valide le cible. Si l’`EnvironmentLayer` technique attaché est actif, la row du `TileLayer` devient active et affiche `Environnement technique sélectionné`, ce qui évite une sélection invisible sans muter automatiquement `activeLayerId`.

Les `EnvironmentLayer` invalides ou legacy restent visibles dans la liste avec `Cible invalide`.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector pilote l’environnement depuis le TileLayer.
- `EnvironmentLayer` reste dans le modèle, mais devient un détail technique dans l’UI quand il est attaché à un vrai `TileLayer`.
- Aucune migration modèle n’est faite dans ce lot.

## 3. Orchestration sub-agents

Sub-agents utilisés :

- Sub-agent A / Audit Architecture : inspection de `LayersPanel`, sélection, actions layer, canvas/painter et risques si un `EnvironmentLayer` actif devient masqué.
- Sub-agent B / Presentation Model : recommandation d’un helper pur `layers_panel_presentation.dart`, avec `layerIndex` source pour préserver drag/drop/reorder.
- Sub-agent C / UI LayersPanel : localisation des insertions minimales dans `_LayerList`, rappel du piège `index visible != index map.layers`.
- Sub-agent D / Selection Safety : confirmation qu’il ne faut pas muter automatiquement `activeLayerId` de l’EnvironmentLayer vers le TileLayer, pour préserver les flows legacy.

Tentative Sub-agent E / QA :

```text
collab spawn failed: agent thread limit reached
```

La passe QA/Evidence a donc été exécutée dans le thread principal avec les commandes listées dans ce rapport.

Décisions prises :

- helper pur côté UI, pas de dépendance au read model d’inspector ;
- hide/grouping léger : l’EnvironmentLayer attaché valide n’a plus de row top-level normale ;
- row TileLayer annotée par `Environnement actif` ;
- row TileLayer active et annotée par `Environnement technique sélectionné` si `activeLayerId` pointe vers l’EnvironmentLayer attaché ;
- pas de mutation automatique de sélection ;
- EnvironmentLayers invalides/legacy visibles avec warning.

## 4. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_editor/test/environment_studio/environment_layer_creation_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart`

Fonctionnement actuel identifié :

- `LayersPanel` itérait directement sur `map.layers`, donc chaque `EnvironmentLayer` apparaissait comme une row normale.
- La sélection de layer appelle `notifier.setActiveLayer(layer.id)`.
- Les actions de row existantes sont visibilité, move up/down, drag reorder, rename, delete.
- `MapInspectorPanel` conserve le legacy `EnvironmentLayerInspectorPanel` quand l’active layer est un `EnvironmentLayer`.
- Les callbacks TileLayer-centric restent gardés par `activeLayer is TileLayer`, donc le legacy reste distinct.
- `MapGridPainter` ne peint pas l’`EnvironmentLayer` comme layer visuel autonome ; les placements générés vivent sur le TileLayer cible.

Risques identifiés :

- si un EnvironmentLayer attaché actif était simplement caché, l’active layer deviendrait invisible dans la liste ;
- masquer des rows casse les indices si le `DragTarget` continue à utiliser l’index visible ;
- cacher les EnvironmentLayers invalides empêcherait le diagnostic ;
- plusieurs EnvironmentLayers attachés au même TileLayer doivent être signalés sans résoudre l’anomalie métier.

## 5. Règles de grouping/hiding

Un `EnvironmentLayer` est groupé comme technique attaché si :

- `content.targetTileLayerId` est non null et non vide après `trim` ;
- la cible existe dans `map.layers` ;
- la cible est un `TileLayer`.

Dans ce cas :

- l’EnvironmentLayer attaché valide n’est pas rendu comme row top-level indépendante ;
- son id est conservé dans `attachedEnvironmentLayerIds` de la row TileLayer ;
- la row TileLayer affiche `Environnement actif` pour un attachment ;
- la row TileLayer affiche `N environnements attachés` pour plusieurs attachments.

Restent visibles comme rows normales :

- `EnvironmentLayer` sans target ;
- `EnvironmentLayer` avec target vide ;
- `EnvironmentLayer` avec target introuvable ;
- `EnvironmentLayer` avec target non TileLayer ;
- EnvironmentLayers legacy/incohérents non résolus comme attachement valide.

Ces rows visibles affichent `Cible invalide`.

## 6. Sélection safety

Si le TileLayer cible est sélectionné :

- la row TileLayer est active normalement ;
- le badge `Environnement actif` indique l’attachement.

Si un EnvironmentLayer attaché valide est sélectionné :

- `activeLayerId` n’est pas modifié ;
- la row EnvironmentLayer technique reste masquée comme top-level ;
- la row du TileLayer cible devient active ;
- la row du TileLayer cible affiche `Environnement technique sélectionné`.

Ce choix évite l’état incompréhensible où `activeLayerId = envLayer.id` mais aucune row visible ne paraît active, sans casser les flows legacy qui s’appuient encore sur un `EnvironmentLayer` actif.

## 7. Intégration UI

Changements UI :

- `LayersPanel` consomme maintenant `buildLayerPanelPresentationRows`.
- Les rows visibles conservent les actions existantes.
- Le drag/drop utilise `row.layerIndex`, donc l’index source dans `map.layers`, pas l’index visible après filtrage.
- Le sous-texte existant `${type} • ${id}` reste affiché.
- Un petit statut supplémentaire affiche `Environnement actif`, `Environnement technique sélectionné` ou `Cible invalide`.

Impact :

- TileLayer sans environnement : affichage inchangé.
- TileLayer avec EnvironmentLayer attaché valide : row TileLayer visible avec statut environnement.
- EnvironmentLayer attaché valide : plus de row top-level normale.
- EnvironmentLayer invalide : row visible avec warning.
- Layers non-environment : affichage conservé.

## 8. Tests

RED exécutés avant production code :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
```

Résultat RED :

```text
Error when reading 'lib/src/ui/panels/layers_panel_presentation.dart': No such file or directory
Method not found: 'buildLayerPanelPresentationRows'
00:00 +0 -1: Some tests failed.
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat RED :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Environnement actif"

Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Cible invalide"

Expected: no matching candidates
Actual: Found 1 widget with text "Environment — Décor"

00:01 +2 -3: Some tests failed.
```

Après implémentation :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
```

Résultat :

```text
00:00 +0: TileLayer environment layer grouping presentation TileLayer sans EnvironmentLayer reste une row normale
00:00 +1: TileLayer environment layer grouping presentation EnvironmentLayer attaché valide est groupé sur le TileLayer cible
00:00 +2: TileLayer environment layer grouping presentation EnvironmentLayer target manquant reste visible avec warning
00:00 +3: TileLayer environment layer grouping presentation EnvironmentLayer target non TileLayer reste visible avec warning
00:00 +4: TileLayer environment layer grouping presentation plusieurs EnvironmentLayers attachés au même TileLayer sont comptés
00:00 +5: TileLayer environment layer grouping presentation EnvironmentLayer attaché actif reste compréhensible via le TileLayer
00:00 +6: TileLayer environment layer grouping presentation ordre des autres layers préservé
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat :

```text
00:00 +0: TileLayer environment grouping LayersPanel affiche le TileLayer avec badge et masque la row technique
00:00 +1: TileLayer environment grouping LayersPanel EnvironmentLayer invalide reste visible avec warning
00:00 +2: TileLayer environment grouping LayersPanel sélection du TileLayer fonctionne toujours
00:00 +3: TileLayer environment grouping LayersPanel EnvironmentLayer attaché actif reste visible via le TileLayer
00:00 +4: TileLayer environment grouping LayersPanel layers non-environment restent affichés
00:00 +5: All tests passed!
```

Tests LayersPanel existants :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_layer_creation_test.dart
```

Résultat :

```text
00:00 +0: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:00 +1: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:01 +2: Lot 19 — Environment Layer dans l’éditeur de map AddMapLayerUseCase crée MapLayer.environment via map_core
00:01 +3: Lot 19 — Environment Layer dans l’éditeur de map MapInspector : section neutre quand EnvironmentLayer actif
00:01 +4: Lot 19 — Environment Layer dans l’éditeur de map MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas
00:01 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/surface_painter/surface_layer_creation_entry_test.dart
```

Résultat :

```text
00:00 +0: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +1: Surface layer creation entry explicit surface layer ids and default names stay unique
00:00 +2: All tests passed!
```

Non-régressions Environment :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:00 +0: TileLayerEnvironmentInspectorSection affiche Aucun environnement sur ce layer
00:00 +1: TileLayerEnvironmentInspectorSection affiche Activer l’environnement sans callback de mutation
00:00 +2: TileLayerEnvironmentInspectorSection active Activer l’environnement avec callback
00:00 +3: TileLayerEnvironmentInspectorSection bloque Ajouter une zone si aucun preset existe
00:00 +4: TileLayerEnvironmentInspectorSection active Ajouter une zone avec un preset unique
00:00 +5: TileLayerEnvironmentInspectorSection bloque Ajouter une zone avec plusieurs presets sans sélection
00:00 +6: TileLayerEnvironmentInspectorSection active Ajouter une zone avec plusieurs presets et sélection
00:00 +7: TileLayerEnvironmentInspectorSection affiche un état prêt avec preset zone et masque
00:00 +8: TileLayerEnvironmentInspectorSection affiche le feedback prêt avec seed et densité
00:00 +9: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:00 +10: TileLayerEnvironmentInspectorSection affiche la liste des zones d’environnement
00:00 +11: TileLayerEnvironmentInspectorSection cliquer sur Sélectionner déclenche le callback area
00:00 +12: TileLayerEnvironmentInspectorSection affiche preset et placements manquants dans une summary
00:01 +13: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:01 +14: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:01 +15: TileLayerEnvironmentInspectorSection affiche un message legacy
00:01 +16: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé sans callback
00:01 +17: TileLayerEnvironmentInspectorSection Générer dans ce layer est actif avec callback
00:01 +18: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé si canGenerate false
00:01 +19: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:01 +20: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:01 +21: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:01 +22: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:01 +23: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:01 +24: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:01 +25: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:01 +26: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:01 +27: TileLayerEnvironmentInspectorSection affiche les paramètres de génération éditables du preset
00:01 +28: TileLayerEnvironmentInspectorSection changer le slider density construit un override complet
00:01 +29: TileLayerEnvironmentInspectorSection changer le slider spacing construit un override entier
00:01 +30: TileLayerEnvironmentInspectorSection sans callback les sliders de génération sont grisés
00:01 +31: TileLayerEnvironmentInspectorSection override local active reset et seed
00:01 +32: TileLayerEnvironmentInspectorSection preset manquant affiche des paramètres non modifiables
00:01 +33: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:01 +34: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans callback
00:01 +35: TileLayerEnvironmentInspectorSection Effacer les placements générés est actif avec callback
00:01 +36: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans placement généré
00:01 +37: TileLayerEnvironmentInspectorSection Régénérer reste désactivé sans callback
00:01 +38: TileLayerEnvironmentInspectorSection Régénérer est actif avec callback
00:01 +39: TileLayerEnvironmentInspectorSection Régénérer reste désactivé sans generatedPlacementIds même avec callback
00:01 +40: TileLayerEnvironmentInspectorSection Shuffle reste désactivé sans callback
00:01 +41: TileLayerEnvironmentInspectorSection Shuffle est actif avec callback
00:01 +42: TileLayerEnvironmentInspectorSection Shuffle reste désactivé sans generatedPlacementIds même avec callback
00:01 +43: TileLayerEnvironmentInspectorSection affiche Palette du preset et les éléments disponibles
00:01 +44: TileLayerEnvironmentInspectorSection sélection d’un élément généré déclenche le callback
00:01 +45: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans generated placements
00:01 +46: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans sélection quand plusieurs items
00:01 +47: TileLayerEnvironmentInspectorSection Ajouter un élément généré actif avec élément sélectionné
00:01 +48: TileLayerEnvironmentInspectorSection mode ajout actif affiche stop et aide
00:02 +49: TileLayerEnvironmentInspectorSection Supprimer un élément généré reste désactivé sans generated placements
00:02 +50: TileLayerEnvironmentInspectorSection Supprimer un élément généré reste désactivé sans callback
00:02 +51: TileLayerEnvironmentInspectorSection Supprimer un élément généré est actif avec callback
00:02 +52: TileLayerEnvironmentInspectorSection mode suppression actif affiche stop et aide
00:02 +53: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +0: TileLayerEnvironmentAttachmentReadModel retourne un empty state quand le projet est null
00:00 +1: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand la map est null
00:00 +2: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand aucun layer est sélectionné
00:00 +3: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer sans environnement attaché
00:00 +4: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer avec EnvironmentLayer attaché
00:00 +5: TileLayerEnvironmentAttachmentReadModel détecte plusieurs EnvironmentLayers attachés au même TileLayer
00:00 +6: TileLayerEnvironmentAttachmentReadModel détecte un EnvironmentLayer sélectionné directement en mode legacy
00:00 +7: TileLayerEnvironmentAttachmentReadModel détecte targetTileLayerId manquant
00:00 +8: TileLayerEnvironmentAttachmentReadModel détecte target layer inexistant
00:00 +9: TileLayerEnvironmentAttachmentReadModel détecte target layer non TileLayer
00:00 +10: TileLayerEnvironmentAttachmentReadModel détecte absence d’area
00:00 +11: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée valide
00:00 +12: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée absente
00:00 +13: TileLayerEnvironmentAttachmentReadModel utilise la seule area existante quand aucune sélection est fournie
00:00 +14: TileLayerEnvironmentAttachmentReadModel demande une sélection quand plusieurs areas existent sans sélection
00:00 +15: TileLayerEnvironmentAttachmentReadModel expose les summaries de zones dans l’ordre avec compteurs
00:00 +16: TileLayerEnvironmentAttachmentReadModel summary signale un preset manquant
00:00 +17: TileLayerEnvironmentAttachmentReadModel détecte preset valide
00:00 +18: TileLayerEnvironmentAttachmentReadModel expose les paramètres effectifs depuis le preset sans override
00:00 +19: TileLayerEnvironmentAttachmentReadModel expose les paramètres effectifs depuis paramsOverride
00:00 +20: TileLayerEnvironmentAttachmentReadModel désactive les paramètres si le preset est manquant
00:00 +21: TileLayerEnvironmentAttachmentReadModel désactive les paramètres si aucune area effective est sélectionnée
00:00 +22: TileLayerEnvironmentAttachmentReadModel détecte preset manquant
00:00 +23: TileLayerEnvironmentAttachmentReadModel détecte masque vide
00:00 +24: TileLayerEnvironmentAttachmentReadModel détecte masque non vide
00:00 +25: TileLayerEnvironmentAttachmentReadModel compte generatedPlacementIds et placements manquants
00:00 +26: TileLayerEnvironmentAttachmentReadModel expose la palette du preset avec la sélection et les éléments manquants
00:00 +27: TileLayerEnvironmentAttachmentReadModel désactive l’ajout individuel si tous les éléments sont manquants
00:00 +28: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +29: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat :

```text
00:00 +0: Golden Slice — workflow notifier complet generate → clear → generate → regenerate → shuffle ; manuel conservé
00:00 +1: Golden Slice — workflow notifier complet shuffle sans placements générés préalables : seed change et placements
00:00 +2: Golden Slice — workflow notifier complet clear sans placements : message statut, carte inchangée
00:00 +3: Golden Slice — inspecteur minimal résumé + Generate activé quand prêt
00:00 +4: Golden Slice — inspecteur minimal Generate désactivé sans cible TileLayer
00:00 +5: Golden Slice — validation finale (Lot 29) generate → clear → generate → regenerate → shuffle : invariants manifest, tuiles, masque, sélection, ids
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
```

Résultat :

```text
00:00 +0: tap canvas ajoute un placement généré au TileLayer actif
00:00 +1: tap canvas avec footprint invalide ne mute pas la MapData
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
```

Résultat :

```text
00:00 +0: tap canvas supprime un placement généré du TileLayer actif
00:00 +1: hover canvas met en surbrillance le placement supprimable
00:00 +2: tap canvas sur placement manuel ne supprime rien
00:00 +3: All tests passed!
```

## 9. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/layers_panel_presentation.dart test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

Résultat :

```text
Analyzing 4 items...
No issues found! (ran in 1.8s)
```

Aucune dette d’analyse ciblée détectée.

## 10. Fichiers créés/modifiés

Fichiers créés par Environment-47 :

- `packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart`
- `reports/environment_studio/environment_47_hide_group_technical_environment_layer.md`

Fichier modifié par Environment-47 :

- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`

Fichiers préexistants dans le worktree non touchés :

- Aucun fichier préexistant modifié ou non suivi n’a été observé au `git status` initial du lot.

Dettes préexistantes hors lot :

- Le legacy `EnvironmentLayerInspectorPanel` reste accessible quand un `EnvironmentLayer` est actif.
- La question métier “plusieurs EnvironmentLayers attachés au même TileLayer” reste diagnostiquée visuellement mais non réparée.
- La suppression d’un TileLayer cible qui possède un EnvironmentLayer attaché reste hors lot.

Problèmes introduits par ce lot :

- Aucun problème introduit identifié par les tests ciblés, non-régressions et analyse ciblée.

## 11. Non-objectifs respectés

- Pas de migration modèle.
- Pas de suppression d’EnvironmentLayer du modèle.
- Pas de modification `map_core`.
- Pas de modification runtime.
- Pas de modification gameplay.
- Pas de modification battle.
- Pas de modification des use cases environment.
- Pas de modification canvas.
- Pas de `build_runner`.
- Pas de generated files.

## 12. Evidence pack

Git status initial Environment-47 :

```bash
git status --short --untracked-files=all
```

Résultat :

```text

```

Git status observé à la reprise après compaction, après création des tests RED Environment-47 :

```text
?? packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
```

Git diff stat :

```bash
git diff --stat
```

Résultat :

```text
 .../map_editor/lib/src/ui/panels/layers_panel.dart | 71 +++++++++++++++++++---
 1 file changed, 64 insertions(+), 7 deletions(-)
```

Note : `git diff --stat` ne liste que les modifications tracked. Les fichiers créés non suivis par Git sont listés dans le `git status final` ci-dessous et leur contenu complet est inclus dans la section diff pertinent.

Git diff name-only :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/ui/panels/layers_panel.dart
```

Git diff check :

```bash
git diff --check
```

Résultat :

```text

```

Commandes principales exécutées :

```bash
git status --short --untracked-files=all
find packages/map_editor -name AGENTS.md -print
rg -n "LayersPanel|layers panel|LayerRow|activeLayerId|selectLayer|EnvironmentLayer|targetTileLayerId|TileLayer|isVisible|opacity|deleteLayer|removeLayer|reorder|moveLayer|layer list|MapLayer" packages/map_editor/lib/src packages/map_editor/test packages/map_core/lib/src
dart format packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
dart format packages/map_editor/lib/src/ui/panels/layers_panel.dart packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
cd packages/map_editor && flutter test test/environment_studio/environment_layer_creation_test.dart
cd packages/map_editor && flutter test test/surface_painter/surface_layer_creation_entry_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
cd packages/map_editor && flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
cd packages/map_editor && flutter analyze lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/layers_panel_presentation.dart test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Résultats de tests :

- `tile_layer_environment_layer_grouping_presentation_test.dart` : pass, 7 tests.
- `tile_layer_environment_layer_grouping_panel_test.dart` : pass, 5 tests.
- `environment_layer_creation_test.dart` : pass, 5 tests.
- `surface_layer_creation_entry_test.dart` : pass, 2 tests.
- `tile_layer_environment_inspector_section_test.dart` : pass, 53 tests.
- `tile_layer_environment_attachment_read_model_test.dart` : pass, 29 tests.
- `environment_golden_slice_workflow_test.dart` : pass, 6 tests.
- `tile_layer_environment_individual_add_canvas_test.dart` : pass, 2 tests.
- `tile_layer_environment_individual_delete_canvas_test.dart` : pass, 3 tests.

Résultat d’analyse :

- `flutter analyze ...` : `No issues found! (ran in 1.8s)`.

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
?? packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
?? reports/environment_studio/environment_47_hide_group_technical_environment_layer.md
```

## 13. Diff pertinent

### `packages/map_editor/lib/src/ui/panels/layers_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/layers_panel.dart b/packages/map_editor/lib/src/ui/panels/layers_panel.dart
index adbfe1d2..dd33a12e 100644
--- a/packages/map_editor/lib/src/ui/panels/layers_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/layers_panel.dart
@@ -7,6 +7,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../features/editor/state/editor_notifier.dart';
 import '../shared/cupertino_editor_widgets.dart';
+import 'layers_panel_presentation.dart';
 
 enum _LayerCreationKind {
   tile,
@@ -323,11 +324,16 @@ class _LayerList extends StatelessWidget {
       );
     }
 
+    final rows = buildLayerPanelPresentationRows(
+      map,
+      activeLayerId: activeLayerId,
+    );
+
     return ListView.builder(
       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
-      itemCount: map.layers.length + 1,
+      itemCount: rows.length + 1,
       itemBuilder: (context, index) {
-        if (index == map.layers.length) {
+        if (index == rows.length) {
           return DragTarget<String>(
             onWillAcceptWithDetails: (_) => true,
             onAcceptWithDetails: (details) {
@@ -362,10 +368,11 @@ class _LayerList extends StatelessWidget {
           );
         }
 
-        final layer = map.layers[index];
-        final isActive = layer.id == activeLayerId;
-        final canMoveUp = index > 0;
-        final canMoveDown = index < map.layers.length - 1;
+        final row = rows[index];
+        final layer = row.layer;
+        final isActive = row.isActive;
+        final canMoveUp = row.layerIndex > 0;
+        final canMoveDown = row.layerIndex < map.layers.length - 1;
 
         final inactiveFill = Color.lerp(
           EditorChrome.islandFillElevated(context),
@@ -383,7 +390,7 @@ class _LayerList extends StatelessWidget {
         return DragTarget<String>(
           onWillAcceptWithDetails: (_) => true,
           onAcceptWithDetails: (details) {
-            notifier.moveMapLayerBeforeIndex(details.data, index);
+            notifier.moveMapLayerBeforeIndex(details.data, row.layerIndex);
           },
           builder: (context, candidateData, _) {
             final dropHovering = candidateData.isNotEmpty;
@@ -533,6 +540,32 @@ class _LayerList extends StatelessWidget {
                                                 color: metaColor,
                                               ),
                                             ),
+                                            if (row.environmentAttachmentLabel !=
+                                                null) ...[
+                                              const SizedBox(height: 4),
+                                              _LayerStatusText(
+                                                row.environmentAttachmentLabel!,
+                                                color: metaColor,
+                                              ),
+                                            ],
+                                            if (row.technicalEnvironmentSelectionLabel !=
+                                                null) ...[
+                                              const SizedBox(height: 3),
+                                              _LayerStatusText(
+                                                row.technicalEnvironmentSelectionLabel!,
+                                                color: metaColor,
+                                              ),
+                                            ],
+                                            if (row.environmentWarningLabel !=
+                                                null) ...[
+                                              const SizedBox(height: 3),
+                                              _LayerStatusText(
+                                                row.environmentWarningLabel!,
+                                                color: CupertinoColors
+                                                    .systemOrange
+                                                    .resolveFrom(context),
+                                              ),
+                                            ],
                                           ],
                                         ),
                                       ),
@@ -723,6 +756,30 @@ class _LayerList extends StatelessWidget {
   }
 }
 
+class _LayerStatusText extends StatelessWidget {
+  const _LayerStatusText(
+    this.text, {
+    required this.color,
+  });
+
+  final String text;
+  final Color color;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      text,
+      maxLines: 1,
+      overflow: TextOverflow.ellipsis,
+      style: TextStyle(
+        fontSize: 10,
+        fontWeight: FontWeight.w600,
+        color: color,
+      ),
+    );
+  }
+}
+
 /// Pastilles icônes chaudes / acides, cohérentes avec la tuile « Layers ».
 class _LayersAccentIconButton extends StatefulWidget {
```

### `packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart`

```dart
import 'package:map_core/map_core.dart';

final class LayerPanelPresentationRow {
  const LayerPanelPresentationRow({
    required this.layer,
    required this.layerIndex,
    required this.isActive,
    this.environmentAttachmentLabel,
    this.environmentWarningLabel,
    this.technicalEnvironmentSelectionLabel,
    this.attachedEnvironmentLayerIds = const <String>[],
  });

  final MapLayer layer;
  final int layerIndex;
  final bool isActive;
  final String? environmentAttachmentLabel;
  final String? environmentWarningLabel;
  final String? technicalEnvironmentSelectionLabel;
  final List<String> attachedEnvironmentLayerIds;

  bool get isTechnicalEnvironmentSelection =>
      technicalEnvironmentSelectionLabel != null;
}

List<LayerPanelPresentationRow> buildLayerPanelPresentationRows(
  MapData map, {
  String? activeLayerId,
}) {
  final layersById = {
    for (final layer in map.layers) layer.id: layer,
  };
  final attachedEnvironmentLayersByTarget = <String, List<EnvironmentLayer>>{};
  final hiddenEnvironmentLayerIds = <String>{};

  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    final targetLayerId = layer.content.targetTileLayerId?.trim();
    if (targetLayerId == null || targetLayerId.isEmpty) {
      continue;
    }
    final targetLayer = layersById[targetLayerId];
    if (targetLayer is! TileLayer) {
      continue;
    }
    attachedEnvironmentLayersByTarget
        .putIfAbsent(targetLayer.id, () => <EnvironmentLayer>[])
        .add(layer);
    hiddenEnvironmentLayerIds.add(layer.id);
  }

  final rows = <LayerPanelPresentationRow>[];
  for (var index = 0; index < map.layers.length; index += 1) {
    final layer = map.layers[index];
    if (hiddenEnvironmentLayerIds.contains(layer.id)) {
      continue;
    }

    final attachedEnvironmentLayers = layer is TileLayer
        ? attachedEnvironmentLayersByTarget[layer.id] ??
            const <EnvironmentLayer>[]
        : const <EnvironmentLayer>[];
    final attachedEnvironmentLayerIds = attachedEnvironmentLayers
        .map((environmentLayer) => environmentLayer.id)
        .toList(growable: false);
    final hasActiveTechnicalEnvironment =
        attachedEnvironmentLayerIds.contains(activeLayerId);

    rows.add(
      LayerPanelPresentationRow(
        layer: layer,
        layerIndex: index,
        isActive: layer.id == activeLayerId || hasActiveTechnicalEnvironment,
        environmentAttachmentLabel:
            _environmentAttachmentLabel(attachedEnvironmentLayerIds.length),
        environmentWarningLabel: _environmentWarningLabel(layer, layersById),
        technicalEnvironmentSelectionLabel: hasActiveTechnicalEnvironment
            ? 'Environnement technique sélectionné'
            : null,
        attachedEnvironmentLayerIds: attachedEnvironmentLayerIds,
      ),
    );
  }

  return rows;
}

String? _environmentAttachmentLabel(int count) {
  if (count == 0) {
    return null;
  }
  if (count == 1) {
    return 'Environnement actif';
  }
  return '$count environnements attachés';
}

String? _environmentWarningLabel(
  MapLayer layer,
  Map<String, MapLayer> layersById,
) {
  if (layer is! EnvironmentLayer) {
    return null;
  }
  final targetLayerId = layer.content.targetTileLayerId?.trim();
  if (targetLayerId == null || targetLayerId.isEmpty) {
    return 'Cible invalide';
  }
  final targetLayer = layersById[targetLayerId];
  if (targetLayer is TileLayer) {
    return null;
  }
  return 'Cible invalide';
}
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/layers_panel_presentation.dart';

void main() {
  group('TileLayer environment layer grouping presentation', () {
    test('TileLayer sans EnvironmentLayer reste une row normale', () {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 3, height: 3),
        layers: [
          TileLayer(
            id: 'decor',
            name: 'Décor',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
      );

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor']);
      expect(rows.single.environmentAttachmentLabel, isNull);
      expect(rows.single.isTechnicalEnvironmentSelection, isFalse);
    });

    test('EnvironmentLayer attaché valide est groupé sur le TileLayer cible',
        () {
      final map = _mapWithAttachedEnvironment();

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(rows.first.environmentAttachmentLabel, 'Environnement actif');
      expect(rows.first.attachedEnvironmentLayerIds, const ['env_decor']);
      expect(rows.first.environmentWarningLabel, isNull);
    });

    test('EnvironmentLayer target manquant reste visible avec warning', () {
      final map = _mapWithEnvironmentTarget('missing');

      final rows = buildLayerPanelPresentationRows(map);

      expect(
        rows.map((row) => row.layer.id),
        const ['decor', 'objects', 'env_decor'],
      );
      expect(rows.last.layer, isA<EnvironmentLayer>());
      expect(rows.last.environmentWarningLabel, 'Cible invalide');
    });

    test('EnvironmentLayer target non TileLayer reste visible avec warning',
        () {
      final map = _mapWithEnvironmentTarget('objects');

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id),
          const ['decor', 'objects', 'env_decor']);
      expect(rows.last.layer, isA<EnvironmentLayer>());
      expect(rows.last.environmentWarningLabel, 'Cible invalide');
    });

    test('plusieurs EnvironmentLayers attachés au même TileLayer sont comptés',
        () {
      final map = _mapWithAttachedEnvironment(extraAttached: true);

      final rows = buildLayerPanelPresentationRows(map);

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(
          rows.first.environmentAttachmentLabel, '2 environnements attachés');
      expect(
        rows.first.attachedEnvironmentLayerIds,
        const ['env_decor', 'env_decor_alt'],
      );
    });

    test('EnvironmentLayer attaché actif reste compréhensible via le TileLayer',
        () {
      final map = _mapWithAttachedEnvironment();

      final rows = buildLayerPanelPresentationRows(
        map,
        activeLayerId: 'env_decor',
      );

      expect(rows.map((row) => row.layer.id), const ['decor', 'objects']);
      expect(rows.first.isActive, isTrue);
      expect(rows.first.isTechnicalEnvironmentSelection, isTrue);
      expect(
        rows.first.technicalEnvironmentSelectionLabel,
        'Environnement technique sélectionné',
      );
    });

    test('ordre des autres layers préservé', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: [
          const CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: [
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false
            ],
          ),
          const TileLayer(
            id: 'decor',
            name: 'Décor',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          _environmentLayer('env_decor', 'decor'),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
      );

      final rows = buildLayerPanelPresentationRows(map);

      expect(
        rows.map((row) => row.layer.id),
        const ['collision', 'decor', 'objects'],
      );
    });
  });
}

MapData _mapWithAttachedEnvironment({bool extraAttached = false}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer('env_decor', 'decor'),
      if (extraAttached) _environmentLayer('env_decor_alt', 'decor'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
  );
}

MapData _mapWithEnvironmentTarget(String targetLayerId) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
      _environmentLayer('env_decor', targetLayerId),
    ],
  );
}

EnvironmentLayer _environmentLayer(String id, String targetLayerId) {
  return MapLayer.environment(
    id: id,
    name: 'Environment — $targetLayerId',
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  ) as EnvironmentLayer;
}
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';

void main() {
  group('TileLayer environment grouping LayersPanel', () {
    testWidgets('affiche le TileLayer avec badge et masque la row technique',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithAttachedEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environnement actif'), findsOneWidget);
      expect(find.text('Environment — Décor'), findsNothing);
      expect(find.text('Objects'), findsOneWidget);
      expect(container.read(editorNotifierProvider).activeLayerId, 'decor');
    });

    testWidgets('EnvironmentLayer invalide reste visible avec warning',
        (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithInvalidEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environment — Missing'), findsOneWidget);
      expect(find.text('Cible invalide'), findsOneWidget);
    });

    testWidgets('sélection du TileLayer fonctionne toujours', (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'objects',
        map: _mapWithAttachedEnvironment(),
      );

      await tester.tap(find.text('Décor'));
      await tester.pumpAndSettle();

      expect(container.read(editorNotifierProvider).activeLayerId, 'decor');
    });

    testWidgets('EnvironmentLayer attaché actif reste visible via le TileLayer',
        (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_decor',
        map: _mapWithAttachedEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environment — Décor'), findsNothing);
      expect(
        find.text('Environnement technique sélectionné'),
        findsOneWidget,
      );
    });

    testWidgets('layers non-environment restent affichés', (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'collision',
        map: _mapWithAttachedEnvironment(includeCollision: true),
      );

      expect(find.text('Collision'), findsOneWidget);
      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
    });
  });
}

Future<ProviderContainer> _pumpLayersPanel(
  WidgetTester tester, {
  required MapData map,
  required String activeLayerId,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    activeMap: map,
    activeLayerId: activeLayerId,
  );

  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 420,
              height: 600,
              child: LayersPanel(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

MapData _mapWithAttachedEnvironment({bool includeCollision = false}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      if (includeCollision)
        const CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
        ),
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer(
        id: 'env_decor',
        name: 'Environment — Décor',
        targetLayerId: 'decor',
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
  );
}

MapData _mapWithInvalidEnvironment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer(
        id: 'env_missing',
        name: 'Environment — Missing',
        targetLayerId: 'missing',
      ),
    ],
  );
}

EnvironmentLayer _environmentLayer({
  required String id,
  required String name,
  required String targetLayerId,
}) {
  return MapLayer.environment(
    id: id,
    name: name,
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  ) as EnvironmentLayer;
}
```

Le fichier de rapport est créé par ce lot. Son contenu complet est le document courant ; le recopier récursivement dans sa propre section de diff ne fournirait pas une preuve supplémentaire exploitable.

## 14. Auto-review

- Les EnvironmentLayers attachés valides sont-ils regroupés/cachés ? Oui, ils ne sont plus rendus comme rows top-level normales.
- Le TileLayer cible affiche-t-il clairement l’environnement actif ? Oui, `Environnement actif`.
- Les EnvironmentLayers invalides restent-ils visibles ? Oui, avec `Cible invalide`.
- Les layers non-environment gardent-ils leur comportement ? Oui, tests widget + test de présentation couvrent leur présence.
- La sélection active ne devient-elle jamais invisible ? Oui, si l’EnvironmentLayer technique est actif, la row TileLayer cible est active et affiche `Environnement technique sélectionné`.
- Aucune donnée modèle n’est-elle migrée ? Oui.
- Le flow TileLayer-centric reste-t-il intact ? Oui, non-régressions Environment passées.
- Le flow legacy reste-t-il accessible si nécessaire ? Oui, pas de mutation automatique de `activeLayerId` ni modification inspector legacy.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Ce qui était clair :

- définition d’un EnvironmentLayer technique attaché ;
- obligation de ne pas migrer le modèle ;
- nécessité de garder les invalides visibles ;
- nécessité d’éviter une sélection invisible.

Ce qui était ambigu :

- le prompt proposait à la fois hide pur, nested technical row, et badge/sous-ligne. Le choix final est le grouping léger : badge/sous-ligne sur TileLayer, pas de child row interactive.
- le statut d’un `EnvironmentLayer` sans target peut être lu comme legacy ou invalide. V0 le garde visible avec `Cible invalide`, ce qui favorise le diagnostic.

À trancher avant Environment-48 :

- faut-il une option développeur explicite “Afficher les layers techniques” ?
- faut-il une action UI “Sélectionner le TileLayer cible” depuis le mode legacy ?
- faut-il caractériser/corriger la suppression/reorder d’un TileLayer qui possède un EnvironmentLayer attaché ?

## 16. Verdict

```text
Environment-47 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-48 — TileLayer-centric Golden Slice Save / Reload V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement le grouping/hiding UI de l’EnvironmentLayer technique.
- [x] Je n’ai pas supprimé d’EnvironmentLayer du modèle.
- [x] Je n’ai pas migré vers TileLayer.environmentContent.
- [x] Je n’ai pas modifié les use cases environment.
- [x] Je n’ai pas modifié le canvas.
- [x] Les EnvironmentLayers invalides restent visibles.
- [x] Le TileLayer cible affiche l’environnement attaché.
- [x] La sélection active reste compréhensible.
- [x] Le flow TileLayer-centric reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
