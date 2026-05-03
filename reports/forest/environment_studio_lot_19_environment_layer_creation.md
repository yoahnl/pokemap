# Environment Studio Lot 19 — Environment Layer Creation in Map Editor V0

## 1. Résumé exécutif

L’éditeur de map expose désormais **Environment Layer** dans le dialogue d’ajout de layer (`LayersPanel`), sur le même flux que les autres kinds : `EditorNotifier.addMapLayer` → `AddMapLayerUseCase` → `map_core.addMapLayer` avec `MapLayerKind.environment`. Le layer apparaît dans la liste (icône nuage, libellé `environment · 0 area(s)`), la sélection active le nouveau layer et marque l’état **dirty** comme les autres mutations de map. L’inspecteur affiche une section dédiée avec texte neutre (sans contrôles TileLayer). Aucun `map_core` ni runtime modifié dans ce lot ; aucune zone, `targetTileLayerId`, preset manifest, ni persistance disque dans ce flux.

## 2. Périmètre du lot

Conforme au cahier Environment-19 : création d’un vrai `MapLayer.environment` depuis la World Map / panneau layers, liste + sélection + message inspecteur V0, no-op canvas. Hors scope : `EnvironmentArea`, masques, `targetTileLayerId`, générateur, `ProjectManifest.environmentPresets`, `SurfaceLayer` legacy, `map_core`, `map_runtime` (non touchés), `build_runner`, commits git.

## 3. Audit initial du workflow layers

Fichiers relus ou contrôlés pour l’audit (sans les modifier hors périmètre) :

- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart` : `AddMapLayerUseCase.execute` appelle déjà `map_core.addMapLayer` ; préfixe d’id `l_environment` pour `MapLayerKind.environment` (pré-existant).
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : `addMapLayer` applique le résultat du use case via `_applyMapMutation` avec `preferredActiveLayerId: result.layer.id` (sélection du nouveau layer alignée sur les autres kinds).
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart` : point d’entrée UI « Add Layer », picker de type, branche `surface` → `addSurfaceLayer`, sinon `addMapLayer(kind: ...)`.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` : sections conditionnelles par type de layer actif (`showTilesSection` pour `TileLayer`, etc.).
- `packages/map_core/lib/src/operations/map_layers.dart` (lecture seule) : création du layer environment déjà supportée côté contrat.

Constats :

- Les layers non-surface sont créés exclusivement via `notifier.addMapLayer` + `AddMapLayerUseCase` + `addMapLayer` map_core.
- La liste des types dans le dialogue est l’enum privé `_LayerCreationKind` + `showCupertinoListPicker`.
- Après ajout, la sélection suit `preferredActiveLayerId` dans `_applyMapMutation` (identique aux autres layers).
- Le dirty map suit le chemin existant de mutation de `activeMap` (inchangé dans ce lot).
- `EnvironmentLayer` était déjà partiellement listé côté UI layers (icône / label `environment`) depuis les lots map layer ; il manquait l’entrée **création** et l’**inspecteur** dédié.

## 4. Décisions UI / création Environment Layer

- Libellé picker et carte inspecteur : **« Environment Layer »** (anglais, cohérent avec « Tile Layer », etc.).
- Nom par défaut si champ vide quand on choisit le type : **« Environment »** (symétrique à « Surfaces » pour Surface).
- Description courte sous le formulaire (clé `layers-panel-add-environment-description`) : texte français du cahier sur les environnements organiques.
- Section inspecteur : `InspectorSectionCard` avec `subtitle: null` pour éviter la duplication de texte avec le corps du placeholder (correction après test widget).

## 5. Création MapLayer.environment

Non modifié dans ce lot : la création reste **100 %** `AddMapLayerUseCase` + `addMapLayer` (map_core). Le layer produit respecte `EnvironmentLayerContent.emptyContent` (`areas` vide, `targetTileLayerId` null), visibilité et opacité par défaut du factory map_core, `properties` vides.

## 6. Layer list / sélection / inspector

- Liste : `_iconForLayer` → `CupertinoIcons.cloud` ; `_labelForLayer` → `environment · N area(s)` (N=0 à la création).
- Sélection : inchangée, hérite du comportement `addMapLayer` (nouveau layer actif).
- Inspecteur : si `activeLayer is EnvironmentLayer`, affichage d’une carte **Environment Layer** + `_EnvironmentLayerInspectorPlaceholder` (titre + texte d’attente). Les sections Tile / palette ne s’affichent pas car `showTilesSection` exige un `TileLayer` actif (ou outil tuile / fallback si tile layers présents sans active — ici map vide tile, seul l’environment est actif).

## 7. Dirty state / mutation map active

Le test widget vérifie `state.isDirty == true` après ajout, cohérent avec `_applyMapMutation` utilisé pour tout ajout de layer. Aucun nouveau mécanisme de dirty.

## 8. Canvas / runtime no-op

`MapGridPainter` ne contient pas de branche de peinture pour `EnvironmentLayer` ; le smoke test appelle `paint` sur une map `TileLayer` + `EnvironmentLayer` sans exception. Aucune modification de `map_runtime` dans ce lot.

## 9. Non-persistance disque garantie

- `layers_panel.dart` et `layer_use_cases.dart` : **aucune** occurrence de `FileProjectRepository`, `saveProject`, `saveProjectManifest` (grep dédié, sortie en section 14).
- `editor_notifier.dart` : occurrences de `saveProject` / `saveProjectManifest` existent ailleurs dans la classe mais **pas** sur le chemin `addMapLayer` (lignes listées en preuve grep).
- Le flux testé ne charge pas de repository disque : `ProviderContainer` + état mémoire uniquement.

## 10. Pourquoi aucun area / targetTileLayer / générateur dans ce lot

C’est le périmètre contractuel V0 : poser le **meta layer auteur** dans l’éditeur sans logique de zones ni de génération, pour enchaîner en Lot 20+ sur cible tuile et édition de zones.

## 11. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/ui/panels/layers_panel.dart` | Type `environment`, labels, description, défaut de nom, appel `addMapLayer(MapLayerKind.environment)`. |
| `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` | Section inspecteur + placeholder neutre. |
| `packages/map_editor/test/environment_studio/environment_layer_creation_test.dart` | Tests picker, flux add, use case, inspecteur, smoke `MapGridPainter`. |
| `reports/forest/environment_studio_lot_19_environment_layer_creation.md` | Ce rapport. |

## 12. Tests ajoutés ou modifiés

- **Nouveau** : `test/environment_studio/environment_layer_creation_test.dart` (5 tests : 4 groupés + 1 unit use case).
- Aucune modification des tests `layers_panel_test` / `map_inspector_panel_test` : fichiers absents dans le dépôt sous ces chemins exacts.

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/environment_layer_creation_test.dart
flutter analyze lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/map_inspector_panel.dart test/environment_studio/environment_layer_creation_test.dart
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n lib/src/ui/panels/layers_panel.dart lib/src/features/editor/state/editor_notifier.dart lib/src/application/use_cases/layer_use_cases.dart || true
flutter test test/environment_studio/environment_layer_creation_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test --reporter expanded
```


## 14. Résultats des commandes

### `dart format` (packages/map_editor)

Sortie : fichiers formatés sans erreur (exit code 0).

### `flutter analyze` (3 fichiers du lot)

```
Analyzing 3 items...                                            
No issues found! (ran in 1.7s)
```

### Grep persistance (chemins imposés par le lot)

Commande :

```bash
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n \
  lib/src/ui/panels/layers_panel.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/application/use_cases/layer_use_cases.dart || true
```

Sortie complète (répertoire `packages/map_editor`) :

```
lib/src/features/editor/state/editor_notifier.dart:437:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:446:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:448:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1488:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1492:    state = await _projectContentController.saveProjectDialogueYarnBody(
```

### `flutter test test/environment_studio/environment_layer_creation_test.dart --reporter expanded`

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
00:00 +0: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:00 +1: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:00 +2: Lot 19 — Environment Layer dans l’éditeur de map AddMapLayerUseCase crée MapLayer.environment via map_core
00:00 +3: Lot 19 — Environment Layer dans l’éditeur de map MapInspector : section neutre quand EnvironmentLayer actif
00:00 +4: Lot 19 — Environment Layer dans l’éditeur de map MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas
00:01 +5: All tests passed!
```

### `flutter test test/environment_studio --reporter expanded`

Fichier journal complet `/tmp/lot19_env_studio_test.log` (213 lignes) :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: environmentDiagnosticKindLabel quelques kinds FR stables
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only browser : bouton Préparer un preset visible
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) densité 0.75 OK puis 1.5 → Densité invalide
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:01 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) Réinitialiser brouillon remet les params standard
00:01 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) Réinitialiser brouillon remet les params standard
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:02 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:02 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:02 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:02 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:02 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon callback qui lève en update : formulaire visible, message neutre
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
#0      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:304:34)
#1      _ManifestSyncPanelHostState.build.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:444:30)
#2      _EnvironmentStudioPanelState._onEnvironmentPresetSavedInMemory (package:map_editor/src/features/environment_studio/environment_studio_panel.dart:187:38)
#3      _EnvironmentPresetDraftFormState._saveDraftToProject (package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_form.dart:184:11)
#4      _CupertinoButtonState._handleTap (package:flutter/src/cupertino/button.dart:421:24)
#5      _CupertinoButtonState._handleTapUp (package:flutter/src/cupertino/button.dart:393:7)
#6      TapGestureRecognizer.handleTapUp.<anonymous closure> (package:flutter/src/gestures/tap.dart:755:57)
#7      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:345:24)
#8      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:755:11)
#9      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:383:5)
#10     BaseTapGestureRecognizer.handlePrimaryPointer (package:flutter/src/gestures/tap.dart:314:7)
#11     PrimaryPointerGestureRecognizer.handleEvent (package:flutter/src/gestures/recognizer.dart:721:9)
#12     PointerRouter._dispatch (package:flutter/src/gestures/pointer_router.dart:97:12)
#13     PointerRouter._dispatchEventToRoutes.<anonymous closure> (package:flutter/src/gestures/pointer_router.dart:142:9)
#14     _LinkedHashMapMixin.forEach (dart:_compact_hash:765:13)
#15     PointerRouter._dispatchEventToRoutes (package:flutter/src/gestures/pointer_router.dart:140:18)
#16     PointerRouter.route (package:flutter/src/gestures/pointer_router.dart:130:7)
#17     GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:528:19)
#18     GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:498:22)
#19     RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:473:11)
#20     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)
#21     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)
#22     TestWidgetsFlutterBinding.handlePointerEventForSource.<anonymous closure> (package:flutter_test/src/binding.dart:678:42)
#23     TestWidgetsFlutterBinding.withPointerEventSource (package:flutter_test/src/binding.dart:688:11)
#24     TestWidgetsFlutterBinding.handlePointerEventForSource (package:flutter_test/src/binding.dart:678:5)
#25     WidgetTester.sendEventToBinding.<anonymous closure> (package:flutter_test/src/widget_tester.dart:869:15)
#26     _rootRun (dart:async/zone.dart:1525:13)
#27     _CustomZone.run (dart:async/zone.dart:1422:19)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     WidgetTester.sendEventToBinding (package:flutter_test/src/widget_tester.dart:868:27)
#30     TestGesture.up.<anonymous closure> (package:flutter_test/src/test_pointer.dart:538:26)
#31     _rootRun (dart:async/zone.dart:1525:13)
#32     _CustomZone.run (dart:async/zone.dart:1422:19)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     TestGesture.up (package:flutter_test/src/test_pointer.dart:531:27)
#35     WidgetController.tapAt.<anonymous closure> (package:flutter_test/src/controller.dart:1117:21)
<asynchronous suspension>
#36     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#37     main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:317:7)
<asynchronous suspension>
#38     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#39     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#40     StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>

00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:03 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon champs initiaux vides et params standard
00:03 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
00:03 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
#0      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:384:36)
#1      _ManifestSyncPanelHostState.build.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:638:30)
#2      _EnvironmentStudioPanelState._onEnvironmentPresetSavedInMemory (package:map_editor/src/features/environment_studio/environment_studio_panel.dart:187:38)
#3      _EnvironmentPresetDraftFormState._saveDraftToProject (package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_form.dart:184:11)
#4      _CupertinoButtonState._handleTap (package:flutter/src/cupertino/button.dart:421:24)
#5      _CupertinoButtonState._handleTapUp (package:flutter/src/cupertino/button.dart:393:7)
#6      TapGestureRecognizer.handleTapUp.<anonymous closure> (package:flutter/src/gestures/tap.dart:755:57)
#7      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:345:24)
#8      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:755:11)
#9      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:383:5)
#10     BaseTapGestureRecognizer.handlePrimaryPointer (package:flutter/src/gestures/tap.dart:314:7)
#11     PrimaryPointerGestureRecognizer.handleEvent (package:flutter/src/gestures/recognizer.dart:721:9)
#12     PointerRouter._dispatch (package:flutter/src/gestures/pointer_router.dart:97:12)
#13     PointerRouter._dispatchEventToRoutes.<anonymous closure> (package:flutter/src/gestures/pointer_router.dart:142:9)
#14     _LinkedHashMapMixin.forEach (dart:_compact_hash:765:13)
#15     PointerRouter._dispatchEventToRoutes (package:flutter/src/gestures/pointer_router.dart:140:18)
#16     PointerRouter.route (package:flutter/src/gestures/pointer_router.dart:130:7)
#17     GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:528:19)
#18     GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:498:22)
#19     RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:473:11)
#20     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)
#21     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)
#22     TestWidgetsFlutterBinding.handlePointerEventForSource.<anonymous closure> (package:flutter_test/src/binding.dart:678:42)
#23     TestWidgetsFlutterBinding.withPointerEventSource (package:flutter_test/src/binding.dart:688:11)
#24     TestWidgetsFlutterBinding.handlePointerEventForSource (package:flutter_test/src/binding.dart:678:5)
#25     WidgetTester.sendEventToBinding.<anonymous closure> (package:flutter_test/src/widget_tester.dart:869:15)
#26     _rootRun (dart:async/zone.dart:1525:13)
#27     _CustomZone.run (dart:async/zone.dart:1422:19)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     WidgetTester.sendEventToBinding (package:flutter_test/src/widget_tester.dart:868:27)
#30     TestGesture.up.<anonymous closure> (package:flutter_test/src/test_pointer.dart:538:26)
#31     _rootRun (dart:async/zone.dart:1525:13)
#32     _CustomZone.run (dart:async/zone.dart:1422:19)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     TestGesture.up (package:flutter_test/src/test_pointer.dart:531:27)
#35     WidgetController.tapAt.<anonymous closure> (package:flutter_test/src/controller.dart:1117:21)
<asynchronous suspension>
#36     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#37     main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:411:9)
<asynchronous suspension>
#38     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#39     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#40     StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>

00:03 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:03 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:03 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:03 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:03 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:03 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:04 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:04 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:04 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon aucun Save / Create / Generate dans l’UI
00:04 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:04 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:04 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque remplit elementId
00:04 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:04 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:04 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:05 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:05 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:05 +111: All tests passed!
```

### `flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded`

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:00 +14: All tests passed!
```

### `flutter test` (suite complète `packages/map_editor`)

- **Exit code** : 1.
- **Bilan terminal** : `+944 -34` puis ligne finale `Some tests failed.` (échecs hors périmètre Lot 19 : nombreux tests catalogue/sync Pokémon et autres ; aucun échec dans `environment_layer_creation_test.dart` ni régression des tests ciblés ci-dessus).
- **Dernières lignes brutes capturées** :

```

00:58 +942 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... malformed payloads and duplicate external resources with warnings      
00:58 +942 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets   
00:58 +942 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: sync honors a custom pokemon data root for both the items catalog and local sprite assets
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_nzqaY5/project.json

00:58 +943 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: ... pokemon data root for both the items catalog and local sprite assets   
00:58 +943 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
00:58 +943 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/items_catalog_sync_37Xshf/project.json

00:58 +944 -34: /Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart: load use case reads the synced catalog after a real sync                   
00:58 +944 -34: Some tests failed.                                                                                                                                                                     
```

## 15. Git status initial et final

**État initial (message utilisateur au début de la session)** — le dépôt contenait déjà des modifications non liées au Lot 19 sur `map_core` / `map_runtime` / etc. ; elles ne font pas partie de ce lot.

**État final (commande `git status --short --untracked-files=all` à la racine du dépôt)** :

```
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
?? packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
?? reports/forest/environment_studio_lot_19_environment_layer_creation.md
```

*(Les lignes ci-dessus reflètent l’état après écriture du rapport lui-même.)*

## 16. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/ui/panels/layers_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Draggable, DragTarget, Material;
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';

enum _LayerCreationKind {
  tile,
  collision,
  terrain,
  path,
  surface,
  object,
  environment,
}

class LayersPanel extends ConsumerWidget {
  const LayersPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  static String _kindLabel(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => 'Tile Layer',
      _LayerCreationKind.collision => 'Collision Layer',
      _LayerCreationKind.terrain => 'Terrain Layer',
      _LayerCreationKind.path => 'Path Layer',
      _LayerCreationKind.surface => 'Surface Layer',
      _LayerCreationKind.object => 'Object Layer',
      _LayerCreationKind.environment => 'Environment Layer',
    };
  }

  static MapLayerKind? _mapLayerKindFor(_LayerCreationKind k) {
    return switch (k) {
      _LayerCreationKind.tile => MapLayerKind.tile,
      _LayerCreationKind.collision => MapLayerKind.collision,
      _LayerCreationKind.terrain => MapLayerKind.terrain,
      _LayerCreationKind.path => MapLayerKind.path,
      // SurfaceLayer is deliberately kept as an editor creation option instead
      // of expanding MapLayerKind here; map_core already models the layer, but
      // the editor routes surface creation through addSurfaceLayer().
      _LayerCreationKind.surface => null,
      _LayerCreationKind.object => MapLayerKind.object,
      _LayerCreationKind.environment => MapLayerKind.environment,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final subtle = EditorChrome.subtleLabel(context);
    final content = map == null
        ? Center(
            child: Text(
              'No map loaded',
              style: TextStyle(color: subtle),
            ),
          )
        : _LayerList(
            map: map,
            activeLayerId: state.activeLayerId,
            notifier: notifier,
          );

    const layerAccent = EditorChrome.inspectorJoyBlue;

    if (embedded) {
      return Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
            accent: layerAccent,
            onAddLayer: () => _showAddLayerDialog(context, notifier),
            onDeleteAllLayers: () =>
                _showDeleteAllLayersDialog(context, notifier),
            compact: true,
          ),
          const SizedBox(height: 10),
          Expanded(child: content),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.islandFill(context),
      ),
      child: Column(
        children: [
          _LayerActionsRow(
            map: map,
            notifier: notifier,
            accent: layerAccent,
            onAddLayer: () => _showAddLayerDialog(context, notifier),
            onDeleteAllLayers: () =>
                _showDeleteAllLayersDialog(context, notifier),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Future<void> _showAddLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final nameController = TextEditingController();
    var selectedType = _LayerCreationKind.tile;
    var shouldSave = false;

    await showMacosEditorModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Layer',
              style: editorMacosSheetTitleStyle(ctx),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () async {
                  final picked =
                      await showCupertinoListPicker<_LayerCreationKind>(
                    context: ctx,
                    title: 'Layer type',
                    items: _LayerCreationKind.values,
                    labelOf: _kindLabel,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedType = picked;
                      if (picked == _LayerCreationKind.surface &&
                          nameController.text.trim().isEmpty) {
                        nameController.text = 'Surfaces';
                      }
                      if (picked == _LayerCreationKind.environment &&
                          nameController.text.trim().isEmpty) {
                        nameController.text = 'Environment';
                      }
                    });
                  }
                },
                child: Text('Type: ${_kindLabel(selectedType)}'),
              ),
            ),
            const SizedBox(height: 8),
            MacosTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Name',
            ),
            if (selectedType == _LayerCreationKind.environment) ...[
              const SizedBox(height: 10),
              Text(
                'Zone auteur pour environnements organiques : forêts, bosquets, '
                'prairies, côtes rocheuses.',
                key: const Key('layers-panel-add-environment-description'),
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    shouldSave = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!shouldSave) return;
    if (selectedType == _LayerCreationKind.surface) {
      notifier.addSurfaceLayer(name: nameController.text.trim());
      return;
    }
    notifier.addMapLayer(
      kind: _mapLayerKindFor(selectedType)!,
      name: nameController.text.trim(),
    );
  }

  Future<void> _showDeleteAllLayersDialog(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Remove All Layers',
      message:
          'All current layers will be removed. The map can stay with zero layers.',
      primaryLabel: 'Remove All',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteAllMapLayers();
  }
}

class _LayerActionsRow extends StatelessWidget {
  const _LayerActionsRow({
    required this.map,
    required this.notifier,
    required this.accent,
    required this.onAddLayer,
    required this.onDeleteAllLayers,
    this.compact = false,
  });

  final MapData? map;
  final EditorNotifier notifier;
  final Color accent;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteAllLayers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = Color.lerp(muted, accent, 0.42)!;
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 8, 8, 6)
          : const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              compact ? 'Layer Actions' : 'LAYERS',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                letterSpacing: compact ? 0.4 : 1.0,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          _LayersAccentIconButton(
            accent: accent,
            onPressed: map == null ? null : onAddLayer,
            icon: CupertinoIcons.add,
            tooltip: 'Add Layer',
            iconSize: 17,
          ),
          const SizedBox(width: 6),
          _LayersAccentIconButton(
            accent: accent,
            onPressed: map == null ? null : onDeleteAllLayers,
            icon: CupertinoIcons.trash_slash,
            tooltip: 'Remove All Layers',
            iconSize: 17,
          ),
        ],
      ),
    );
  }
}

class _LayerList extends StatelessWidget {
  const _LayerList({
    required this.map,
    required this.activeLayerId,
    required this.notifier,
  });

  final MapData map;
  final String? activeLayerId;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    const layerAccent = EditorChrome.inspectorJoyBlue;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    if (map.layers.isEmpty) {
      return Center(
        child: Text(
          'No layers in this map',
          style: TextStyle(color: subtle),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemCount: map.layers.length + 1,
      itemBuilder: (context, index) {
        if (index == map.layers.length) {
          return DragTarget<String>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              notifier.moveMapLayerBeforeIndex(
                details.data,
                map.layers.length,
              );
            },
            builder: (context, candidateData, _) {
              final hovering = candidateData.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: SizedBox(
                  height: 14,
                  width: double.infinity,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: hovering ? 5 : 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: hovering
                            ? layerAccent.withValues(alpha: 0.85)
                            : subtle.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final layer = map.layers[index];
        final isActive = layer.id == activeLayerId;
        final canMoveUp = index > 0;
        final canMoveDown = index < map.layers.length - 1;

        final inactiveFill = Color.lerp(
          EditorChrome.islandFillElevated(context),
          layerAccent,
          0.16,
        )!;
        final inactiveBorder = Color.lerp(
          EditorChrome.editorIslandRim(context),
          layerAccent,
          0.45,
        )!;
        final metaColor =
            Color.lerp(secondary, layerAccent, isActive ? 0.28 : 0.22)!;

        return DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            notifier.moveMapLayerBeforeIndex(details.data, index);
          },
          builder: (context, candidateData, _) {
            final dropHovering = candidateData.isNotEmpty;
            return Padding(
              key: ValueKey(layer.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                decoration: dropHovering
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: layerAccent.withValues(alpha: 0.9),
                          width: 2,
                        ),
                      )
                    : null,
                padding:
                    dropHovering ? const EdgeInsets.all(2) : EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Draggable<String>(
                      data: layer.id,
                      axis: Axis.vertical,
                      affinity: Axis.vertical,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _dragFeedback(
                          context,
                          layer,
                          layerAccent,
                          label,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: MacosIcon(
                              CupertinoIcons.line_horizontal_3,
                              size: 16,
                              color: metaColor,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 6, 0),
                        child: MacosTooltip(
                          message: 'Glisser pour réordonner',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: MacosIcon(
                                  CupertinoIcons.line_horizontal_3,
                                  size: 16,
                                  color: metaColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isActive
                              ? Color.lerp(
                                  EditorChrome.islandFillElevated(context),
                                  layerAccent,
                                  0.36,
                                )!
                              : inactiveFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? layerAccent.withValues(alpha: 0.82)
                                : inactiveBorder,
                            width: 1,
                          ),
                          boxShadow:
                              EditorChrome.inspectorTileHardShadows(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                          child: Column(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                onPressed: () =>
                                    notifier.setActiveLayer(layer.id),
                                child: ClipRect(
                                  child: Row(
                                    children: [
                                      MacosIcon(
                                        _iconForLayer(layer),
                                        size: 16,
                                        color: isActive
                                            ? layerAccent
                                            : Color.lerp(
                                                secondary,
                                                layerAccent,
                                                0.55,
                                              )!,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              layer.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isActive
                                                    ? layerAccent
                                                    : Color.lerp(
                                                        label,
                                                        layerAccent,
                                                        0.12,
                                                      )!,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_labelForLayer(layer)} • ${layer.id}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: metaColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: () =>
                                            notifier.setMapLayerVisibility(
                                          layer.id,
                                          !layer.isVisible,
                                        ),
                                        icon: layer.isVisible
                                            ? CupertinoIcons.eye
                                            : CupertinoIcons.eye_slash,
                                        tooltip: layer.isVisible
                                            ? 'Hide layer'
                                            : 'Show layer',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: canMoveUp
                                            ? () => notifier
                                                .moveMapLayerUp(layer.id)
                                            : null,
                                        icon: CupertinoIcons.arrow_up,
                                        tooltip: 'Move up',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: canMoveDown
                                            ? () => notifier
                                                .moveMapLayerDown(layer.id)
                                            : null,
                                        icon: CupertinoIcons.arrow_down,
                                        tooltip: 'Move down',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: () => _showRenameLayerDialog(
                                          context,
                                          notifier,
                                          layer,
                                        ),
                                        icon: CupertinoIcons.pencil,
                                        tooltip: 'Rename layer',
                                        iconSize: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      _LayersAccentIconButton(
                                        accent: layerAccent,
                                        onPressed: () => _showDeleteLayerDialog(
                                          context,
                                          notifier,
                                          layer,
                                        ),
                                        icon: CupertinoIcons.trash,
                                        tooltip: 'Delete layer',
                                        iconSize: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dragFeedback(
    BuildContext context,
    MapLayer layer,
    Color layerAccent,
    Color label,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: layerAccent.withValues(alpha: 0.82),
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosIcon(
              _iconForLayer(layer),
              size: 16,
              color: layerAccent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                layer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => CupertinoIcons.square_grid_2x2,
      collision: (_) => CupertinoIcons.shield,
      terrain: (_) => CupertinoIcons.tree,
      path: (_) => CupertinoIcons.map,
      // Surface painting/rendering is a later lot; the editor lists it
      // neutrally so maps containing SurfaceLayer do not break the panel.
      surface: (_) => CupertinoIcons.map,
      object: (_) => CupertinoIcons.square_stack_3d_up,
      environment: (_) => CupertinoIcons.cloud,
    );
  }

  String _labelForLayer(MapLayer layer) {
    return layer.map(
      tile: (_) => 'tile',
      collision: (_) => 'collision',
      terrain: (_) => 'terrain',
      path: (_) => 'path',
      surface: (surfaceLayer) =>
          'surface · ${surfaceLayer.placements.length} placement(s)',
      object: (_) => 'object',
      environment: (el) => 'environment · ${el.content.areaCount} area(s)',
    );
  }

  Future<void> _showRenameLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    final controller = TextEditingController(text: layer.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename Layer',
      controller: controller,
      placeholder: 'Name',
      confirmLabel: 'Save',
    );
    if (!ok) return;
    notifier.renameMapLayer(layer.id, controller.text.trim());
  }

  Future<void> _showDeleteLayerDialog(
    BuildContext context,
    EditorNotifier notifier,
    MapLayer layer,
  ) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete Layer',
      message: 'Delete "${layer.name}"?',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    notifier.deleteMapLayer(layer.id);
  }
}

/// Pastilles icônes chaudes / acides, cohérentes avec la tuile « Layers ».
class _LayersAccentIconButton extends StatefulWidget {
  const _LayersAccentIconButton({
    required this.accent,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize = 15,
  });

  final Color accent;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final double iconSize;

  @override
  State<_LayersAccentIconButton> createState() =>
      _LayersAccentIconButtonState();
}

class _LayersAccentIconButtonState extends State<_LayersAccentIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final a = widget.accent;
    final bg = !enabled
        ? a.withValues(alpha: 0.08)
        : _hovered
            ? Color.lerp(a, const Color(0xFFFFF2E6), 0.4)!
            : Color.lerp(a, const Color(0xFF1A0C04), 0.52)!;
    final iconColor = enabled
        ? CupertinoColors.white
        : CupertinoColors.inactiveGray.resolveFrom(context);

    Widget core = MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: a.withValues(alpha: enabled ? 0.75 : 0.22),
              width: 1,
            ),
          ),
          child: MacosIcon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );

    final tip = widget.tooltip;
    if (tip != null && tip.isNotEmpty) {
      return MacosTooltip(message: tip, child: core);
    }
    return core;
  }
}
```

### `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/surface_painter/surface_palette_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';
import 'encounter_tables_panel.dart';
import 'entity_properties_panel.dart';
import 'event_properties_panel.dart';
import 'gameplay_zone_properties_panel.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'map_properties_panel.dart';
import 'terrain_map_panel.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';

enum _InspectorSectionId {
  mapProperties,
  layers,
  environmentLayer,
  tiles,
  ground,
  surfacePlacements,
  surfaces,
  entities,
  events,
  connections,
  triggers,
  warps,
  gameplayZones,
  encounterTables,
}

class MapInspectorPanel extends ConsumerStatefulWidget {
  const MapInspectorPanel({super.key});

  @override
  ConsumerState<MapInspectorPanel> createState() => _MapInspectorPanelState();
}

class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
  final Map<_InspectorSectionId, bool> _expandedSections =
      <_InspectorSectionId, bool>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    final activeLayer = _findActiveLayer(activeMap, state.activeLayerId);

    if (activeMap == null) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          'Open a map to inspect layers and map systems',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasTileLayers = activeMap.layers.any((layer) => layer is TileLayer);
    final hasTerrainLayers =
        activeMap.layers.any((layer) => layer is TerrainLayer);
    final hasPathLayers = activeMap.layers.any((layer) => layer is PathLayer);
    final hasSurfaceLayers =
        activeMap.layers.any((layer) => layer is SurfaceLayer);
    final hasSurfacePresets =
        state.project?.surfaceCatalog.presets.isNotEmpty ?? false;
    final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
    final showTilesSection = activeLayer is TileLayer ||
        state.activeTool == EditorToolType.tilePaint ||
        (state.activeLayerId == null && hasTileLayers);
    final showGroundSection = hasTerrainLayers &&
        (activeLayer is TerrainLayer ||
            (activeLayer is! PathLayer &&
                state.activeTool == EditorToolType.terrainPaint &&
                state.terrainSelectionMode == TerrainSelectionMode.terrain));
    final showSurfaceSection = hasPathLayers && activeLayer is PathLayer;
    final showSurfacePlacementSection = hasSurfaceLayers ||
        hasSurfacePresets ||
        activeLayer is SurfaceLayer ||
        state.activeTool == EditorToolType.surfacePaint;
    const showConnectionsSection = true;
    final showEntitySection =
        state.activeTool == EditorToolType.entityPlacement ||
            state.selectedEntityId != null ||
            activeMap.entities.isNotEmpty;
    final showEventSection =
        state.activeTool == EditorToolType.eventPlacement ||
            state.selectedMapEventId != null ||
            activeMap.events.isNotEmpty;
    final showTriggerSection =
        state.activeTool == EditorToolType.triggerPlacement ||
            state.selectedTriggerId != null ||
            activeMap.triggers.isNotEmpty;
    final showWarpSection = state.activeTool == EditorToolType.warpPlacement ||
        state.selectedWarpId != null ||
        activeMap.warps.isNotEmpty;
    final showGameplayZoneSection =
        state.activeTool == EditorToolType.gameplayZonePlacement ||
            state.selectedGameplayZoneId != null ||
            activeMap.gameplayZones.isNotEmpty;
    final showEncounterTablesSection =
        (state.project?.encounterTables.isNotEmpty ?? false) ||
            showGameplayZoneSection;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paletteHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(420.0, 760.0).toDouble()
            : 560.0;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InspectorOverviewCard(
                map: activeMap,
                activeLayer: activeLayer,
              ),
              InspectorSectionCard(
                title: 'Propriétés de carte',
                subtitle:
                    'Gameplay et présentation (météo, musique, spawn par défaut…)',
                icon: CupertinoIcons.slider_horizontal_3,
                accentColor: EditorChrome.inspectorJoyPlum,
                expanded: _isExpanded(
                  _InspectorSectionId.mapProperties,
                  false,
                ),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.mapProperties,
                  defaultExpanded: false,
                ),
                expandedHeight: 460,
                child: const MapPropertiesPanel(embedded: true),
              ),
              InspectorSectionCard(
                title: 'Layers',
                subtitle: activeLayer == null
                    ? 'Select the active layer for this map'
                    : 'Active: ${_layerLabel(activeLayer)}',
                icon: CupertinoIcons.layers,
                badgeText: '${activeMap.layers.length}',
                accentColor: EditorChrome.inspectorJoyBlue,
                expanded: _isExpanded(_InspectorSectionId.layers, true),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.layers,
                  defaultExpanded: true,
                ),
                expandedHeight: 260,
                child: const LayersPanel(embedded: true),
              ),
              if (showEnvironmentLayerSection)
                InspectorSectionCard(
                  title: 'Environment Layer',
                  subtitle: null,
                  icon: CupertinoIcons.cloud,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.environmentLayer,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.environmentLayer,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 200,
                  child: const _EnvironmentLayerInspectorPlaceholder(),
                ),
              if (showTilesSection)
                InspectorSectionCard(
                  title: 'Tiles & Elements',
                  subtitle:
                      'Palette de placement et gestion des instances posées sur le layer actif.',
                  icon: CupertinoIcons.square_grid_2x2,
                  accentColor: EditorChrome.inspectorJoyLilac,
                  expanded: _isExpanded(
                    _InspectorSectionId.tiles,
                    activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.tiles,
                    defaultExpanded: activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  expandedHeight: paletteHeight,
                  child: const TilesetPalettePanel(embedded: true),
                ),
              if (showGroundSection)
                InspectorSectionCard(
                  title: 'Base Ground',
                  subtitle: 'Terrain-only editing for the map background.',
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.ground,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.ground,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 300,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.groundOnly,
                  ),
                ),
              if (showSurfacePlacementSection)
                InspectorSectionCard(
                  title: 'Surfaces',
                  subtitle:
                      'Choisir une surface et poser des placements dans la map.',
                  icon: CupertinoIcons.drop,
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfacePlacements,
                    activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfacePlacements,
                    defaultExpanded: activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  expandedHeight: 380,
                  child: const SurfacePainterPanel(embedded: true),
                ),
              if (showSurfaceSection)
                InspectorSectionCard(
                  title: 'Paths',
                  subtitle:
                      'Edit the active path layer for roads and specialized surfaces.',
                  icon: CupertinoIcons.map,
                  accentColor: EditorChrome.inspectorJoyAmber,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfaces,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfaces,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 340,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.surfaceOnly,
                  ),
                ),
              if (showEntitySection)
                InspectorSectionCard(
                  title: 'Map Entities',
                  subtitle: state.selectedEntityId != null
                      ? 'Selected entity ready for editing.'
                      : 'Visible world content such as NPCs, signs, items and spawn points.',
                  icon: CupertinoIcons.sparkles,
                  badgeText: '${activeMap.entities.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.entities,
                    state.activeTool == EditorToolType.entityPlacement ||
                        state.selectedEntityId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.entities,
                    defaultExpanded:
                        state.activeTool == EditorToolType.entityPlacement ||
                            state.selectedEntityId != null,
                  ),
                  expandedHeight: 560,
                  child: const EntityPropertiesPanel(embedded: true),
                ),
              if (showEventSection)
                InspectorSectionCard(
                  title: 'Map Events',
                  subtitle: state.selectedMapEventId != null
                      ? 'Selected event ready for editing.'
                      : 'Conditional event pages and script/message authoring.',
                  icon: CupertinoIcons.flag,
                  badgeText: '${activeMap.events.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.events,
                    state.activeTool == EditorToolType.eventPlacement ||
                        state.selectedMapEventId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.events,
                    defaultExpanded:
                        state.activeTool == EditorToolType.eventPlacement ||
                            state.selectedMapEventId != null,
                  ),
                  expandedHeight: 620,
                  child: const EventPropertiesPanel(embedded: true),
                ),
              if (showConnectionsSection)
                InspectorSectionCard(
                  title: 'Connections',
                  subtitle: 'Link the current map to adjacent world maps.',
                  icon: CupertinoIcons.arrow_branch,
                  badgeText: '${activeMap.connections.length}',
                  accentColor: EditorChrome.inspectorJoyPlum,
                  expanded: _isExpanded(_InspectorSectionId.connections, false),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.connections,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 520,
                  child: const MapConnectionsPanel(embedded: true),
                ),
              if (showTriggerSection)
                InspectorSectionCard(
                  title: 'Triggers',
                  subtitle: state.selectedTriggerId != null
                      ? 'Selected trigger ready for editing.'
                      : 'Gameplay zones and editable trigger areas.',
                  icon: CupertinoIcons.square,
                  badgeText: '${activeMap.triggers.length}',
                  accentColor: EditorChrome.inspectorJoyCoral,
                  expanded: _isExpanded(
                    _InspectorSectionId.triggers,
                    state.activeTool == EditorToolType.triggerPlacement ||
                        state.selectedTriggerId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.triggers,
                    defaultExpanded:
                        state.activeTool == EditorToolType.triggerPlacement ||
                            state.selectedTriggerId != null,
                  ),
                  expandedHeight: 520,
                  child: const TriggerPropertiesPanel(embedded: true),
                ),
              if (showWarpSection)
                InspectorSectionCard(
                  title: 'Warps',
                  subtitle: state.selectedWarpId != null
                      ? 'Selected warp ready for editing.'
                      : 'Map transitions such as doors, stairs and exits.',
                  icon: CupertinoIcons.arrow_down_circle,
                  badgeText: '${activeMap.warps.length}',
                  accentColor: EditorChrome.inspectorJoyOrchid,
                  expanded: _isExpanded(
                    _InspectorSectionId.warps,
                    state.activeTool == EditorToolType.warpPlacement ||
                        state.selectedWarpId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.warps,
                    defaultExpanded:
                        state.activeTool == EditorToolType.warpPlacement ||
                            state.selectedWarpId != null,
                  ),
                  expandedHeight: 320,
                  child: const WarpPropertiesPanel(embedded: true),
                ),
              if (showGameplayZoneSection)
                InspectorSectionCard(
                  title: 'Gameplay Zones',
                  subtitle: state.selectedGameplayZoneId != null
                      ? 'Selected zone ready for editing.'
                      : 'Encounter areas, movement constraints and special zones.',
                  icon: CupertinoIcons.leaf_arrow_circlepath,
                  badgeText: '${activeMap.gameplayZones.length}',
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.gameplayZones,
                    state.activeTool == EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.gameplayZones,
                    defaultExpanded: state.activeTool ==
                            EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  expandedHeight: 520,
                  child: const GameplayZonePropertiesPanel(embedded: true),
                ),
              if (showEncounterTablesSection)
                InspectorSectionCard(
                  title: 'Encounter Tables',
                  subtitle: 'Project-level encounter tables for wild Pokémon.',
                  icon: CupertinoIcons.list_bullet,
                  badgeText: '${state.project?.encounterTables.length ?? 0}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.encounterTables,
                    false,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.encounterTables,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 480,
                  child: const EncounterTablesPanel(embedded: true),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isExpanded(_InspectorSectionId section, bool defaultExpanded) {
    return _expandedSections[section] ?? defaultExpanded;
  }

  void _toggleSection(
    _InspectorSectionId section, {
    required bool defaultExpanded,
  }) {
    setState(() {
      _expandedSections[section] =
          !(_expandedSections[section] ?? defaultExpanded);
    });
  }

  MapLayer? _findActiveLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId) {
        return layer;
      }
    }
    return null;
  }

  String _layerLabel(MapLayer layer) {
    return switch (layer) {
      TileLayer _ => 'Tile Layer',
      CollisionLayer _ => 'Collision Layer',
      TerrainLayer _ => 'Terrain Layer',
      PathLayer _ => 'Path Layer',
      SurfaceLayer _ => 'Surface Layer',
      ObjectLayer _ => 'Object Layer',
      EnvironmentLayer _ => 'Environment Layer',
    };
  }
}

/// Lot Environment-19 : pas de contrôles métier tant que zones / cible tuiles absents.
class _EnvironmentLayerInspectorPlaceholder extends StatelessWidget {
  const _EnvironmentLayerInspectorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Environment Layer',
            key: const Key('map-inspector-environment-layer-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce layer servira à dessiner des zones organiques et à générer des '
            'éléments naturels.\n'
            'La configuration des zones arrive dans un prochain lot.',
            key: const Key('map-inspector-environment-layer-body'),
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorOverviewCard extends StatelessWidget {
  const _InspectorOverviewCard({
    required this.map,
    required this.activeLayer,
  });

  final MapData map;
  final MapLayer? activeLayer;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const accentA = EditorChrome.inspectorJoyHoney;
    const accentB = EditorChrome.inspectorJoyApricot;
    final activeLayerText = activeLayer == null
        ? 'No active layer'
        : switch (activeLayer!) {
            TileLayer _ => 'Tile layer active',
            TerrainLayer _ => 'Ground layer active',
            PathLayer _ => 'Surface layer active',
            SurfaceLayer _ => 'Surface placement layer active',
            CollisionLayer _ => 'Collision layer active',
            ObjectLayer _ => 'Object layer active',
            EnvironmentLayer _ => 'Environment layer active',
          };

    final hi = EditorChrome.islandFillElevated(context);
    final lo = EditorChrome.islandFill(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accentA, 0.44)!,
            Color.lerp(lo, accentB, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(accentA, accentB, 0.5)!.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: EditorChrome.inspectorTileHardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accentA, 0.78)!,
                  Color.lerp(accentB, const Color(0xFF1A0804), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentA.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.slider_horizontal_3,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${map.size.width} x ${map.size.height} tiles  •  ${map.layers.length} layers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeLayerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
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
```

### `packages/map_editor/test/environment_studio/environment_layer_creation_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Lot 19 — Environment Layer dans l’éditeur de map', () {
    testWidgets('picker d’ajout de layer expose Environment Layer', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
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
                  width: 360,
                  height: 520,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type: Tile Layer'));
      await tester.pumpAndSettle();
      expect(find.text('Environment Layer'), findsOneWidget);
    });

    testWidgets(
        'ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
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
                  width: 360,
                  height: 520,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      final placedBefore = container
          .read(editorNotifierProvider)
          .activeMap!
          .placedElements
          .length;

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type: Tile Layer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Environment Layer'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('layers-panel-add-environment-description')),
        findsOneWidget,
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.single;
      expect(layer, isA<EnvironmentLayer>());
      final env = layer as EnvironmentLayer;
      expect(env.content.areas, isEmpty);
      expect(env.content.targetTileLayerId, isNull);
      expect(env.isVisible, isTrue);
      expect(env.opacity, 1.0);
      expect(env.properties, isEmpty);
      expect(state.activeLayerId, env.id);
      expect(state.isDirty, isTrue);
      expect(
        state.activeMap!.placedElements.length,
        placedBefore,
      );
    });

    test('AddMapLayerUseCase crée MapLayer.environment via map_core', () {
      const map = MapData(
        id: 'm',
        name: 'M',
        size: GridSize(width: 2, height: 2),
      );
      final uc = AddMapLayerUseCase();
      final r = uc.execute(
        map,
        kind: MapLayerKind.environment,
        name: 'Forêt auteur',
      );
      final layer = r.layer as EnvironmentLayer;
      expect(layer.id, startsWith('l_environment'));
      expect(layer.name, 'Forêt auteur');
      expect(layer.content, EnvironmentLayerContent.emptyContent);
    });

    testWidgets('MapInspector : section neutre quand EnvironmentLayer actif', (
      tester,
    ) async {
      const env = MapLayer.environment(
        id: 'l_environment_demo',
        name: 'Zones bio',
      );
      const map = MapData(
        id: 'map_x',
        name: 'Map X',
        size: GridSize(width: 4, height: 4),
        layers: [env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/lot19_insp',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/map_x.json',
        activeLayerId: env.id,
      );

      await tester.binding.setSurfaceSize(const Size(520, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 400,
                  height: 1100,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('map-inspector-environment-layer-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('map-inspector-environment-layer-body')),
        findsOneWidget,
      );
      expect(
        find.textContaining('La configuration des zones arrive'),
        findsOneWidget,
      );
    });

    test('MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas',
        () {
      const map = MapData(
        id: 'lab',
        name: 'lab',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.environment(id: 'env1', name: 'E'),
          TileLayer(
            id: 't1',
            name: 'T',
            tiles: <int>[1, 0, 0, 1],
          ),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        hoveredTile: null,
        activeLayerId: null,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: const <String, ui.Image?>{},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{},
        toolPreview: null,
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        gameplayZoneDraftArea: null,
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedWarpId: null,
        selectedTriggerId: null,
        selectedGameplayZoneId: null,
        selectedPlacedElementInstanceId: null,
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        selectedPathAutotileSet: null,
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: null,
      ).paint(canvas, const ui.Size(64, 64));

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
```

## 17. Diff complet

### `layers_panel.dart` et `map_inspector_panel.dart` (`git diff`)

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/layers_panel.dart b/packages/map_editor/lib/src/ui/panels/layers_panel.dart
index e4231c05..a59c0369 100644
--- a/packages/map_editor/lib/src/ui/panels/layers_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/layers_panel.dart
@@ -15,6 +15,7 @@ enum _LayerCreationKind {
   path,
   surface,
   object,
+  environment,
 }
 
 class LayersPanel extends ConsumerWidget {
@@ -33,6 +34,7 @@ class LayersPanel extends ConsumerWidget {
       _LayerCreationKind.path => 'Path Layer',
       _LayerCreationKind.surface => 'Surface Layer',
       _LayerCreationKind.object => 'Object Layer',
+      _LayerCreationKind.environment => 'Environment Layer',
     };
   }
 
@@ -44,9 +46,10 @@ class LayersPanel extends ConsumerWidget {
       _LayerCreationKind.path => MapLayerKind.path,
       // SurfaceLayer is deliberately kept as an editor creation option instead
       // of expanding MapLayerKind here; map_core already models the layer, but
-      // this bis only fixes the editor entry point.
+      // the editor routes surface creation through addSurfaceLayer().
       _LayerCreationKind.surface => null,
       _LayerCreationKind.object => MapLayerKind.object,
+      _LayerCreationKind.environment => MapLayerKind.environment,
     };
   }
 
@@ -150,6 +153,10 @@ class LayersPanel extends ConsumerWidget {
                           nameController.text.trim().isEmpty) {
                         nameController.text = 'Surfaces';
                       }
+                      if (picked == _LayerCreationKind.environment &&
+                          nameController.text.trim().isEmpty) {
+                        nameController.text = 'Environment';
+                      }
                     });
                   }
                 },
@@ -162,6 +169,19 @@ class LayersPanel extends ConsumerWidget {
               autofocus: true,
               placeholder: 'Name',
             ),
+            if (selectedType == _LayerCreationKind.environment) ...[
+              const SizedBox(height: 10),
+              Text(
+                'Zone auteur pour environnements organiques : forêts, bosquets, '
+                'prairies, côtes rocheuses.',
+                key: const Key('layers-panel-add-environment-description'),
+                style: TextStyle(
+                  color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
+                  fontSize: 11.5,
+                  height: 1.35,
+                ),
+              ),
+            ],
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
@@ -480,108 +500,108 @@ class _LayerList extends StatelessWidget {
                                               )!,
                                       ),
                                       const SizedBox(width: 7),
-                                    Expanded(
-                                      child: Column(
-                                        crossAxisAlignment:
-                                            CrossAxisAlignment.start,
-                                        children: [
-                                          Text(
-                                            layer.name,
-                                            maxLines: 1,
-                                            overflow: TextOverflow.ellipsis,
-                                            style: TextStyle(
-                                              fontSize: 12,
-                                              fontWeight: isActive
-                                                  ? FontWeight.w600
-                                                  : FontWeight.w500,
-                                              color: isActive
-                                                  ? layerAccent
-                                                  : Color.lerp(
-                                                      label,
-                                                      layerAccent,
-                                                      0.12,
-                                                    )!,
+                                      Expanded(
+                                        child: Column(
+                                          crossAxisAlignment:
+                                              CrossAxisAlignment.start,
+                                          children: [
+                                            Text(
+                                              layer.name,
+                                              maxLines: 1,
+                                              overflow: TextOverflow.ellipsis,
+                                              style: TextStyle(
+                                                fontSize: 12,
+                                                fontWeight: isActive
+                                                    ? FontWeight.w600
+                                                    : FontWeight.w500,
+                                                color: isActive
+                                                    ? layerAccent
+                                                    : Color.lerp(
+                                                        label,
+                                                        layerAccent,
+                                                        0.12,
+                                                      )!,
+                                              ),
                                             ),
-                                          ),
-                                          const SizedBox(height: 2),
-                                          Text(
-                                            '${_labelForLayer(layer)} • ${layer.id}',
-                                            maxLines: 1,
-                                            overflow: TextOverflow.ellipsis,
-                                            style: TextStyle(
-                                              fontSize: 10,
-                                              color: metaColor,
+                                            const SizedBox(height: 2),
+                                            Text(
+                                              '${_labelForLayer(layer)} • ${layer.id}',
+                                              maxLines: 1,
+                                              overflow: TextOverflow.ellipsis,
+                                              style: TextStyle(
+                                                fontSize: 10,
+                                                color: metaColor,
+                                              ),
                                             ),
-                                          ),
-                                        ],
+                                          ],
+                                        ),
+                                      ),
+                                      const SizedBox(width: 6),
+                                      _LayersAccentIconButton(
+                                        accent: layerAccent,
+                                        onPressed: () =>
+                                            notifier.setMapLayerVisibility(
+                                          layer.id,
+                                          !layer.isVisible,
+                                        ),
+                                        icon: layer.isVisible
+                                            ? CupertinoIcons.eye
+                                            : CupertinoIcons.eye_slash,
+                                        tooltip: layer.isVisible
+                                            ? 'Hide layer'
+                                            : 'Show layer',
+                                        iconSize: 15,
                                       ),
-                                    ),
-                                    const SizedBox(width: 6),
-                                    _LayersAccentIconButton(
-                                      accent: layerAccent,
-                                      onPressed: () =>
-                                          notifier.setMapLayerVisibility(
-                                        layer.id,
-                                        !layer.isVisible,
+                                      const SizedBox(width: 4),
+                                      _LayersAccentIconButton(
+                                        accent: layerAccent,
+                                        onPressed: canMoveUp
+                                            ? () => notifier
+                                                .moveMapLayerUp(layer.id)
+                                            : null,
+                                        icon: CupertinoIcons.arrow_up,
+                                        tooltip: 'Move up',
+                                        iconSize: 15,
                                       ),
-                                      icon: layer.isVisible
-                                          ? CupertinoIcons.eye
-                                          : CupertinoIcons.eye_slash,
-                                      tooltip: layer.isVisible
-                                          ? 'Hide layer'
-                                          : 'Show layer',
-                                      iconSize: 15,
-                                    ),
-                                    const SizedBox(width: 4),
-                                    _LayersAccentIconButton(
-                                      accent: layerAccent,
-                                      onPressed: canMoveUp
-                                          ? () =>
-                                              notifier.moveMapLayerUp(layer.id)
-                                          : null,
-                                      icon: CupertinoIcons.arrow_up,
-                                      tooltip: 'Move up',
-                                      iconSize: 15,
-                                    ),
-                                    const SizedBox(width: 4),
-                                    _LayersAccentIconButton(
-                                      accent: layerAccent,
-                                      onPressed: canMoveDown
-                                          ? () => notifier
-                                              .moveMapLayerDown(layer.id)
-                                          : null,
-                                      icon: CupertinoIcons.arrow_down,
-                                      tooltip: 'Move down',
-                                      iconSize: 15,
-                                    ),
-                                    const SizedBox(width: 4),
-                                    _LayersAccentIconButton(
-                                      accent: layerAccent,
-                                      onPressed: () => _showRenameLayerDialog(
-                                        context,
-                                        notifier,
-                                        layer,
+                                      const SizedBox(width: 4),
+                                      _LayersAccentIconButton(
+                                        accent: layerAccent,
+                                        onPressed: canMoveDown
+                                            ? () => notifier
+                                                .moveMapLayerDown(layer.id)
+                                            : null,
+                                        icon: CupertinoIcons.arrow_down,
+                                        tooltip: 'Move down',
+                                        iconSize: 15,
                                       ),
-                                      icon: CupertinoIcons.pencil,
-                                      tooltip: 'Rename layer',
-                                      iconSize: 15,
-                                    ),
-                                    const SizedBox(width: 4),
-                                    _LayersAccentIconButton(
-                                      accent: layerAccent,
-                                      onPressed: () => _showDeleteLayerDialog(
-                                        context,
-                                        notifier,
-                                        layer,
+                                      const SizedBox(width: 4),
+                                      _LayersAccentIconButton(
+                                        accent: layerAccent,
+                                        onPressed: () => _showRenameLayerDialog(
+                                          context,
+                                          notifier,
+                                          layer,
+                                        ),
+                                        icon: CupertinoIcons.pencil,
+                                        tooltip: 'Rename layer',
+                                        iconSize: 15,
                                       ),
-                                      icon: CupertinoIcons.trash,
-                                      tooltip: 'Delete layer',
-                                      iconSize: 15,
-                                    ),
-                                  ],
+                                      const SizedBox(width: 4),
+                                      _LayersAccentIconButton(
+                                        accent: layerAccent,
+                                        onPressed: () => _showDeleteLayerDialog(
+                                          context,
+                                          notifier,
+                                          layer,
+                                        ),
+                                        icon: CupertinoIcons.trash,
+                                        tooltip: 'Delete layer',
+                                        iconSize: 15,
+                                      ),
+                                    ],
+                                  ),
                                 ),
                               ),
-                            ),
                             ],
                           ),
                         ),
@@ -665,8 +685,7 @@ class _LayerList extends StatelessWidget {
       surface: (surfaceLayer) =>
           'surface · ${surfaceLayer.placements.length} placement(s)',
       object: (_) => 'object',
-      environment: (el) =>
-          'environment · ${el.content.areaCount} area(s)',
+      environment: (el) => 'environment · ${el.content.areaCount} area(s)',
     );
   }
 
diff --git a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
index 72b67ebd..b9d1bc5d 100644
--- a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
@@ -24,6 +24,7 @@ import 'warp_properties_panel.dart';
 enum _InspectorSectionId {
   mapProperties,
   layers,
+  environmentLayer,
   tiles,
   ground,
   surfacePlacements,
@@ -75,6 +76,7 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
         activeMap.layers.any((layer) => layer is SurfaceLayer);
     final hasSurfacePresets =
         state.project?.surfaceCatalog.presets.isNotEmpty ?? false;
+    final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
     final showTilesSection = activeLayer is TileLayer ||
         state.activeTool == EditorToolType.tilePaint ||
         (state.activeLayerId == null && hasTileLayers);
@@ -162,6 +164,23 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                 expandedHeight: 260,
                 child: const LayersPanel(embedded: true),
               ),
+              if (showEnvironmentLayerSection)
+                InspectorSectionCard(
+                  title: 'Environment Layer',
+                  subtitle: null,
+                  icon: CupertinoIcons.cloud,
+                  accentColor: EditorChrome.inspectorJoyMint,
+                  expanded: _isExpanded(
+                    _InspectorSectionId.environmentLayer,
+                    true,
+                  ),
+                  onToggle: () => _toggleSection(
+                    _InspectorSectionId.environmentLayer,
+                    defaultExpanded: true,
+                  ),
+                  expandedHeight: 200,
+                  child: const _EnvironmentLayerInspectorPlaceholder(),
+                ),
               if (showTilesSection)
                 InspectorSectionCard(
                   title: 'Tiles & Elements',
@@ -437,6 +456,47 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
   }
 }
 
+/// Lot Environment-19 : pas de contrôles métier tant que zones / cible tuiles absents.
+class _EnvironmentLayerInspectorPlaceholder extends StatelessWidget {
+  const _EnvironmentLayerInspectorPlaceholder();
+
+  @override
+  Widget build(BuildContext context) {
+    final subtle = EditorChrome.subtleLabel(context);
+    final label = EditorChrome.primaryLabel(context);
+    return Padding(
+      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Environment Layer',
+            key: const Key('map-inspector-environment-layer-title'),
+            style: TextStyle(
+              color: label,
+              fontSize: 14,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          Text(
+            'Ce layer servira à dessiner des zones organiques et à générer des '
+            'éléments naturels.\n'
+            'La configuration des zones arrive dans un prochain lot.',
+            key: const Key('map-inspector-environment-layer-body'),
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              height: 1.4,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
 class _InspectorOverviewCard extends StatelessWidget {
   const _InspectorOverviewCard({
     required this.map,
```

### `environment_layer_creation_test.dart` (`git diff --no-index /dev/null …`)

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart b/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
new file mode 100644
index 00000000..0786051a
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart
@@ -0,0 +1,265 @@
+import 'dart:ui' as ui;
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/models/path_autotile_set.dart';
+import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
+import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/ui/canvas/map_canvas.dart';
+import 'package:map_editor/src/ui/panels/layers_panel.dart';
+import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
+
+import '../shell_chrome_test_harness.dart';
+
+void main() {
+  group('Lot 19 — Environment Layer dans l’éditeur de map', () {
+    testWidgets('picker d’ajout de layer expose Environment Layer', (
+      tester,
+    ) async {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = const EditorState(
+        activeMap: MapData(
+          id: 'map_1',
+          name: 'Map 1',
+          size: GridSize(width: 3, height: 3),
+        ),
+      );
+
+      await tester.binding.setSurfaceSize(const Size(900, 700));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: const MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 360,
+                  height: 520,
+                  child: LayersPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+
+      await tester.tap(
+        find.byWidgetPredicate(
+          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(find.text('Type: Tile Layer'));
+      await tester.pumpAndSettle();
+      expect(find.text('Environment Layer'), findsOneWidget);
+    });
+
+    testWidgets(
+        'ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty',
+        (tester) async {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = const EditorState(
+        activeMap: MapData(
+          id: 'map_1',
+          name: 'Map 1',
+          size: GridSize(width: 3, height: 3),
+        ),
+      );
+
+      await tester.binding.setSurfaceSize(const Size(900, 700));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: const MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 360,
+                  height: 520,
+                  child: LayersPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+
+      final placedBefore = container
+          .read(editorNotifierProvider)
+          .activeMap!
+          .placedElements
+          .length;
+
+      await tester.tap(
+        find.byWidgetPredicate(
+          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(find.text('Type: Tile Layer'));
+      await tester.pumpAndSettle();
+      await tester.tap(find.text('Environment Layer'));
+      await tester.pumpAndSettle();
+      expect(
+        find.byKey(const Key('layers-panel-add-environment-description')),
+        findsOneWidget,
+      );
+      await tester.tap(find.text('Add'));
+      await tester.pumpAndSettle();
+
+      final state = container.read(editorNotifierProvider);
+      final layer = state.activeMap!.layers.single;
+      expect(layer, isA<EnvironmentLayer>());
+      final env = layer as EnvironmentLayer;
+      expect(env.content.areas, isEmpty);
+      expect(env.content.targetTileLayerId, isNull);
+      expect(env.isVisible, isTrue);
+      expect(env.opacity, 1.0);
+      expect(env.properties, isEmpty);
+      expect(state.activeLayerId, env.id);
+      expect(state.isDirty, isTrue);
+      expect(
+        state.activeMap!.placedElements.length,
+        placedBefore,
+      );
+    });
+
+    test('AddMapLayerUseCase crée MapLayer.environment via map_core', () {
+      const map = MapData(
+        id: 'm',
+        name: 'M',
+        size: GridSize(width: 2, height: 2),
+      );
+      final uc = AddMapLayerUseCase();
+      final r = uc.execute(
+        map,
+        kind: MapLayerKind.environment,
+        name: 'Forêt auteur',
+      );
+      final layer = r.layer as EnvironmentLayer;
+      expect(layer.id, startsWith('l_environment'));
+      expect(layer.name, 'Forêt auteur');
+      expect(layer.content, EnvironmentLayerContent.emptyContent);
+    });
+
+    testWidgets('MapInspector : section neutre quand EnvironmentLayer actif', (
+      tester,
+    ) async {
+      const env = MapLayer.environment(
+        id: 'l_environment_demo',
+        name: 'Zones bio',
+      );
+      const map = MapData(
+        id: 'map_x',
+        name: 'Map X',
+        size: GridSize(width: 4, height: 4),
+        layers: [env],
+      );
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      container.read(editorNotifierProvider.notifier).state = EditorState(
+        projectRootPath: '/tmp/lot19_insp',
+        project: buildShellChromeProject(),
+        activeMap: map,
+        activeMapPath: 'maps/map_x.json',
+        activeLayerId: env.id,
+      );
+
+      await tester.binding.setSurfaceSize(const Size(520, 1200));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+      await tester.pumpWidget(
+        UncontrolledProviderScope(
+          container: container,
+          child: MacosTheme(
+            data: MacosThemeData.light(),
+            child: const MaterialApp(
+              home: CupertinoPageScaffold(
+                child: SizedBox(
+                  width: 400,
+                  height: 1100,
+                  child: MapInspectorPanel(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const Key('map-inspector-environment-layer-title')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('map-inspector-environment-layer-body')),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('La configuration des zones arrive'),
+        findsOneWidget,
+      );
+    });
+
+    test('MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas',
+        () {
+      const map = MapData(
+        id: 'lab',
+        name: 'lab',
+        size: GridSize(width: 2, height: 2),
+        layers: <MapLayer>[
+          MapLayer.environment(id: 'env1', name: 'E'),
+          TileLayer(
+            id: 't1',
+            name: 'T',
+            tiles: <int>[1, 0, 0, 1],
+          ),
+        ],
+      );
+      final recorder = ui.PictureRecorder();
+      final canvas = ui.Canvas(recorder);
+
+      MapGridPainter(
+        map: map,
+        zoom: 1,
+        offset: ui.Offset.zero,
+        hoveredTile: null,
+        activeLayerId: null,
+        tileWidth: 32,
+        tileHeight: 32,
+        tilesetImagesById: const <String, ui.Image?>{},
+        sourceTileWidth: 32,
+        sourceTileHeight: 32,
+        tilesPerRowById: const <String, int>{},
+        toolPreview: null,
+        warps: const <MapWarp>[],
+        gameplayZones: const <MapGameplayZone>[],
+        gameplayZoneDraftArea: null,
+        selectedEntityId: null,
+        selectedMapEventId: null,
+        selectedWarpId: null,
+        selectedTriggerId: null,
+        selectedGameplayZoneId: null,
+        selectedPlacedElementInstanceId: null,
+        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
+        selectedPathAutotileSet: null,
+        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
+        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
+        project: null,
+      ).paint(canvas, const ui.Size(64, 64));
+
+      final picture = recorder.endRecording();
+      picture.dispose();
+    });
+  });
+}
```

## 18. Auto-review

- **Points solides** : respect strict du flux `addMapLayer` existant ; tests couvrant picker, mutation d’état, use case map_core, inspecteur, smoke painter ; aucune dépendance disque dans le flux testé.
- **Points discutables** : le libellé secondaire de liste `environment · 0 area(s)` expose le mot « area » avant que l’édition de zones existe (héritage du pattern `surface · N placement(s)`). Le nom par défaut « Environment » est en anglais alors qu’une partie de l’UI inspecteur reste en français.
- **Corrections faites après auto-review** : suppression du `subtitle` dupliqué sur la carte inspecteur ; clarification du commentaire Surface (`bis` → `addSurfaceLayer()`) ; `const` dans le test inspecteur pour `flutter analyze` clean ; signature `MapGridPainter` complète dans le smoke test.
- **Risques restants** : si une map a des `TileLayer` mais l’utilisateur active un `EnvironmentLayer`, `showTilesSection` peut rester vrai (fallback `activeLayerId == null`) — comportement pré-existant, non modifié dans ce lot.
- **Regard critique sur le prompt** : exposer le layer maintenant est cohérent avec la roadmap (meta layer avant cible tuile). Le label « Environment Layer » est clair pour un public auteur ; pour un utilisateur final no-code, une micro-copy FR unifiée pourrait attendre un lot i18n. Le layer meta ne dessine rien : risque visuel nul dans ce lot. Le dirty state réutilise `_applyMapMutation` sans bricolage. Le lot respecte explicitement l’absence d’areas / targetTileLayer / génération.

## 19. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Lot 19 livré : création Environment Layer dans LayersPanel, inspecteur neutre, tests et analyses ciblées vertes. Suite map_editor complète : 34 échecs préexistants hors périmètre (sync/items Pokémon, etc.), bilan +944 -34, exit code 1.
```

Prochain lot recommandé :

```
Environment-20 — Environment Layer Inspector Target TileLayer V0
```

### Evidence Pack (confirmations explicites)

- Aucun fichier modèle `ProjectManifest` dans `examples/` ou ailleurs n’a été modifié par ce lot.
- Aucun fichier sous `packages/map_core` (y compris `map_layer.dart`) n’a été modifié dans ce lot.
- `MapLayer.environment` est créé via `EditorNotifier.addMapLayer` → `AddMapLayerUseCase.execute` → `map_core.addMapLayer` (workflow existant).
- Aucune `EnvironmentArea` n’a été créée par ce lot.
- Aucun `targetTileLayerId` n’est configuré (reste `null` sur le contenu vide).
- Aucun `MapPlacedElement` n’a été ajouté par le flux testé (`placedElements` stable).
- Aucune sauvegarde disque dans le flux UI testé ; `layers_panel` / `layer_use_cases` sans `FileProjectRepository` / `saveProject` / `saveProjectManifest` ; le grep sur `editor_notifier` ne montre que des méthodes hors chemin `addMapLayer`.
- Aucun générateur d’environnement ni bouton Generate ajouté.
- Aucun `SurfaceLayer` legacy n’a été utilisé pour simuler l’Environment Layer ; l’option Surface reste distincte.
- Aucun `build_runner` lancé ; aucun fichier généré (`*.g.dart` / `*.freezed.dart`) modifié.
- Aucun `git commit`, `git add`, `git push`, `git stash`, `git reset`, `git checkout`, `git restore`, `merge`, `rebase`, ni `tag` exécuté dans ce lot.
