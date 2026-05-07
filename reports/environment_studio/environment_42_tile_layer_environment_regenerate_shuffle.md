# Environment-42 — TileLayer Environment Regenerate / Shuffle V0

## 1. Résumé

Environment-42 ajoute deux actions TileLayer-centric pour l’EnvironmentArea sélectionnée :

- `Régénérer` : clear des placements générés de l’area puis génération avec le même seed.
- `Shuffle` : clear des placements générés de l’area, calcul du seed suivant via `nextEnvironmentAreaSeed`, écriture du seed puis génération.

Les deux actions passent par un wrapper applicatif qui compose les use cases existants `ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase`, `SetEnvironmentAreaSeedUseCase` et `GenerateTileLayerEnvironmentAreaPlacementsUseCase`. Le notifier applique le résultat final via une seule mutation map.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets / recettes.
- Map Editor / TileLayer inspector reste le lieu où l’on peint, génère et ajuste une zone sur la map.
- Ce lot ajoute seulement `Régénérer` et `Shuffle` depuis le TileLayer inspector.
- Aucune preview n’est ajoutée.
- Aucune sauvegarde disque n’est déclenchée.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_regenerate_shuffle_test.dart`
- `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_generate_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fonctionnement legacy relevé :

- `EditorNotifier.regenerateEnvironmentAreaPlacements(...)` compose déjà clear + generate en une seule `_applyMapMutation`.
- `EditorNotifier.shuffleEnvironmentAreaPlacements(...)` compose clear éventuel + seed + generate en une seule `_applyMapMutation`.
- `nextEnvironmentAreaSeed(int currentSeed)` est le helper stable existant pour calculer le seed suivant.
- Le flow legacy conserve un comportement préexistant : `shuffle` peut générer même sans placements générés préalables.

Décision Environment-42 :

- Le flow TileLayer-centric V0 suit le prompt : `Régénérer` et `Shuffle` refusent une area sans `generatedPlacementIds`.
- La composition est faite dans un wrapper applicatif pur, pas par deux appels notifier successifs.
- Les actions UI sont passées uniquement si le read model expose `canRegenerate` / `canShuffle`.

## 4. Use cases TileLayer-centric

Fichier créé :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`

Classes ajoutées :

- `TileLayerEnvironmentRegenerationResult`
- `RegenerateTileLayerEnvironmentAreaPlacementsUseCase`
- `ShuffleTileLayerEnvironmentAreaPlacementsUseCase`

Entrées :

- `MapData map`
- `ProjectManifest manifest`
- `String tileLayerId`
- `String areaId`

Validations :

- `tileLayerId` non vide.
- `areaId` non vide.
- le layer existe.
- le layer est un `TileLayer`.
- un `EnvironmentLayer` attaché existe.
- l’area existe.
- le preset existe.
- le masque n’est pas vide.
- `generatedPlacementIds` n’est pas vide.

Composition `Régénérer` :

1. Résolution `TileLayer -> EnvironmentLayer attaché -> EnvironmentArea`.
2. Clear des placements générés existants via `ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase`.
3. Génération via `GenerateTileLayerEnvironmentAreaPlacementsUseCase` avec le même seed.
4. Retour de la map finale, des ids supprimés, des références nettoyées, du seed précédent/courant, et des nouveaux ids générés.

Composition `Shuffle` :

1. Résolution identique.
2. Clear des placements générés existants.
3. `currentSeed = nextEnvironmentAreaSeed(previousSeed)`.
4. Écriture du seed via `SetEnvironmentAreaSeedUseCase`.
5. Génération via `GenerateTileLayerEnvironmentAreaPlacementsUseCase`.

Zéro candidat :

- Le clear reste appliqué dans la map finale.
- `generatedPlacementIds` devient vide.
- Pour shuffle, le nouveau seed reste appliqué.

## 5. Notifier

Méthodes ajoutées dans `EditorNotifier` :

- `regenerateEnvironmentAreaPlacementsForActiveTileLayer()`
- `shuffleEnvironmentAreaPlacementsForActiveTileLayer()`

Comportement :

- lit `activeMap`, `project`, `activeLayerId`, `selectedEnvironmentAreaId`.
- vérifie que le layer actif est un `TileLayer`.
- appelle le wrapper dédié.
- applique la map finale via une seule `_applyMapMutation`.
- garde `activeLayerId` sur le TileLayer.
- garde `selectedEnvironmentAreaId`.
- remet `environmentMaskEditMode` à `null`.
- nettoie `selectedPlacedElementInstanceId` si l’instance sélectionnée faisait partie des anciens placements supprimés.
- renseigne un `statusMessage` distinct pour regenerate/shuffle.
- renseigne un `errorMessage` clair sans mutation en cas de refus.

## 6. Intégration UI

Modifications :

- `TileLayerEnvironmentInspectorSection` accepte deux callbacks optionnels :
  - `onRegenerateEnvironment`
  - `onShuffleEnvironment`
- `_FutureActions` ajoute les boutons `Régénérer` et `Shuffle`.
- Les boutons sont visibles dans les états où le masque peut être peint ou où les actions sont disponibles.
- Les boutons sont désactivés si le read model ne permet pas l’action, si une erreur est présente, ou si le callback est absent.
- `MapInspectorPanel` passe les callbacks seulement pour un `TileLayer` actif avec area sélectionnée, sans erreur, et avec `readModel.canRegenerate` / `readModel.canShuffle`.

Actions conservées :

- `Générer dans ce layer` reste géré par Environment-40.
- `Effacer les placements générés` reste géré par Environment-41.
- Aucune action preview n’est ajoutée.

## 7. Tests

Commandes lancées et résultats exacts :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
00:00 +0: TileLayer environment regenerate / shuffle use cases regenerate clear puis génère avec le même seed
00:00 +1: TileLayer environment regenerate / shuffle use cases shuffle clear puis change seed et génère
00:00 +2: TileLayer environment regenerate / shuffle use cases regenerate peut finir sans nouveaux candidats après clear
00:00 +3: TileLayer environment regenerate / shuffle use cases refuse les entrées invalides sans mutation
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
```

```text
00:00 +0: EditorNotifier TileLayer regenerate / shuffle regenerate garde la sélection TileLayer et conserve le seed
00:00 +1: EditorNotifier TileLayer regenerate / shuffle shuffle garde la sélection TileLayer et change le seed
00:00 +2: EditorNotifier TileLayer regenerate / shuffle refuse sans TileLayer actif ou sans area sélectionnée
00:00 +3: EditorNotifier TileLayer regenerate / shuffle refuse si generatedPlacementIds est vide
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:00 +0: TileLayerEnvironmentInspectorSection affiche Aucun environnement sur ce layer
00:01 +1: TileLayerEnvironmentInspectorSection affiche Activer l’environnement sans callback de mutation
00:01 +2: TileLayerEnvironmentInspectorSection active Activer l’environnement avec callback
00:01 +3: TileLayerEnvironmentInspectorSection bloque Ajouter une zone si aucun preset existe
00:01 +4: TileLayerEnvironmentInspectorSection active Ajouter une zone avec un preset unique
00:01 +5: TileLayerEnvironmentInspectorSection bloque Ajouter une zone avec plusieurs presets sans sélection
00:01 +6: TileLayerEnvironmentInspectorSection active Ajouter une zone avec plusieurs presets et sélection
00:01 +7: TileLayerEnvironmentInspectorSection affiche un état prêt avec preset zone et masque
00:01 +8: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:01 +9: TileLayerEnvironmentInspectorSection affiche la liste des zones d’environnement
00:01 +10: TileLayerEnvironmentInspectorSection cliquer sur Sélectionner déclenche le callback area
00:01 +11: TileLayerEnvironmentInspectorSection affiche preset et placements manquants dans une summary
00:01 +12: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:01 +13: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:01 +14: TileLayerEnvironmentInspectorSection affiche un message legacy
00:01 +15: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé sans callback
00:01 +16: TileLayerEnvironmentInspectorSection Générer dans ce layer est actif avec callback
00:02 +17: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé si canGenerate false
00:02 +18: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:02 +19: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:02 +20: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:02 +21: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:02 +22: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:02 +23: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:02 +24: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:02 +25: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:02 +26: TileLayerEnvironmentInspectorSection affiche les paramètres de génération éditables du preset
00:02 +27: TileLayerEnvironmentInspectorSection changer le slider density construit un override complet
00:02 +28: TileLayerEnvironmentInspectorSection changer le slider spacing construit un override entier
00:02 +29: TileLayerEnvironmentInspectorSection sans callback les sliders de génération sont grisés
00:02 +30: TileLayerEnvironmentInspectorSection override local active reset et seed
00:02 +31: TileLayerEnvironmentInspectorSection preset manquant affiche des paramètres non modifiables
00:02 +32: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:02 +33: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans callback
00:02 +34: TileLayerEnvironmentInspectorSection Effacer les placements générés est actif avec callback
00:02 +35: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans placement généré
00:02 +36: TileLayerEnvironmentInspectorSection Régénérer reste désactivé sans callback
00:02 +37: TileLayerEnvironmentInspectorSection Régénérer est actif avec callback
00:02 +38: TileLayerEnvironmentInspectorSection Shuffle reste désactivé sans callback
00:02 +39: TileLayerEnvironmentInspectorSection Shuffle est actif avec callback
00:02 +40: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
```

```text
00:00 +0: GenerateTileLayerEnvironmentAreaPlacementsUseCase génère des placements depuis le TileLayer ciblé
00:00 +1: GenerateTileLayerEnvironmentAreaPlacementsUseCase refuse les entrées invalides sans créer de placement
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
```

```text
00:00 +0: EditorNotifier TileLayer environment generation génère les placements et garde la sélection TileLayer stable
00:00 +1: EditorNotifier TileLayer environment generation refuse si aucun TileLayer actif
00:00 +2: EditorNotifier TileLayer environment generation refuse si aucune area est sélectionnée
00:00 +3: EditorNotifier TileLayer environment generation refuse masque vide et preset manquant sans mutation
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
```

```text
00:00 +0: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase efface les placements générés de l’area ciblée seulement
00:00 +1: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase generatedPlacementIds vide retourne un no-op clair
00:00 +2: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase refuse les entrées invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
00:00 +0: EditorNotifier TileLayer environment clear efface les placements générés et garde la sélection TileLayer stable
00:00 +1: EditorNotifier TileLayer environment clear refuse si aucun TileLayer actif
00:00 +2: EditorNotifier TileLayer environment clear refuse si aucune area est sélectionnée
00:00 +3: EditorNotifier TileLayer environment clear aucun generatedPlacementId ne mute pas la MapData
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

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
00:00 +26: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +27: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_regenerate_shuffle_test.dart
```

```text
00:00 +0: nextEnvironmentAreaSeed déterministe, >= 0, change pour des seeds simples
00:00 +1: SetEnvironmentAreaSeedUseCase change seed et préserve le reste
00:00 +2: SetEnvironmentAreaSeedUseCase rejets : layer inconnu, non-env, area inconnue, seed négative
00:00 +3: EditorNotifier regenerate / shuffle regenerate : placements remplacés, mask edit null, status régénér
00:00 +4: EditorNotifier regenerate / shuffle shuffle : seed change, placements présents, status seed/mélang
00:00 +5: EditorNotifier regenerate / shuffle shuffle sans génération préalable : crée placements
00:00 +6: EditorNotifier regenerate / shuffle regenerate sans placements : pas de mutation
00:00 +7: EditorNotifier regenerate / shuffle transactionnalité : clear OK puis generate KO → carte inchangée
00:00 +8: EnvironmentLayerInspectorPanel — Regenerate / Shuffle régénérer activé + compteur stable
00:00 +9: EnvironmentLayerInspectorPanel — Regenerate / Shuffle shuffle : seed affichée change
00:01 +10: EnvironmentLayerInspectorPanel — Regenerate / Shuffle états désactivés : regenerate sans ids, shuffle masque vide
00:01 +11: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

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
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
```

```text
00:00 +0: ClearEnvironmentGeneratedPlacementsUseCase — modèles EnvironmentClearResult copie défensivement et listes immuables
00:00 +1: ClearEnvironmentGeneratedPlacementsUseCase — modèles EnvironmentClearedGeneratedPlacement et EnvironmentClearIssue
00:00 +2: ClearEnvironmentGeneratedPlacementsUseCase clear heureux : ids supprimés, manuel conservé, masque et cible préservés
00:00 +3: ClearEnvironmentGeneratedPlacementsUseCase deux areas : clear A ne touche pas B
00:00 +4: ClearEnvironmentGeneratedPlacementsUseCase ids manquants : warning, liste vidée, existant supprimé
00:00 +5: ClearEnvironmentGeneratedPlacementsUseCase generatedPlacementIds vide : map inchangée, warning
00:00 +6: ClearEnvironmentGeneratedPlacementsUseCase erreurs bloquantes : layer / area inconnus
00:00 +7: EditorNotifier.clearEnvironmentGeneratedPlacements succès : dirty, sélection placé nettoyée, status effacé
00:00 +8: EditorNotifier.clearEnvironmentGeneratedPlacements deletePlacedElementInstance retire un placement généré individuel et sa référence
[editor][elements] deleted generated placed instance id=g1 elementId=e1 layer=tiles pos=(0,0)
00:00 +9: EditorNotifier.clearEnvironmentGeneratedPlacements deleteGeneratedEnvironmentPlacementAt supprime le placement généré cliqué dans son footprint
[editor][environment] deleted generated placement by click id=tree_a elementId=tree pos=(0,0)
00:00 +10: EditorNotifier.clearEnvironmentGeneratedPlacements addGeneratedEnvironmentPlacementAt ajoute un placement individuel du preset
[editor][environment] added generated placement by click id=env_gen_a1_1_1_tree elementId=tree pos=(1,1)
00:00 +11: EditorNotifier.clearEnvironmentGeneratedPlacements no-op ids vides : map inchangée, isDirty inchangé
00:00 +12: EnvironmentLayerInspectorPanel — Clear sans placements générés : bouton disabled + texte
00:00 +13: EnvironmentLayerInspectorPanel — Clear clear puis generate disponible
00:01 +14: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart
```

```text
00:00 +0: EnvironmentApplyResult / modèles EnvironmentApplyResult copie défensivement et expose des listes immuables
00:00 +1: EnvironmentApplyResult / modèles EnvironmentAppliedGeneratedPlacement et EnvironmentApplyIssue égalité
00:00 +2: ApplyEnvironmentGeneratedPlacementsUseCase chemin heureux : placements, generatedPlacementIds, layers préservés
00:00 +3: ApplyEnvironmentGeneratedPlacementsUseCase ordre des candidats = ordre placedElements et generatedPlacementIds
00:00 +4: ApplyEnvironmentGeneratedPlacementsUseCase collisionMode forceEnabled / forceDisabled / useElementDefault
00:00 +5: ApplyEnvironmentGeneratedPlacementsUseCase tags candidat ne sont pas copiés vers MapPlacedElement.properties
00:00 +6: ApplyEnvironmentGeneratedPlacementsUseCase erreurs layer / target / area
00:00 +7: ApplyEnvironmentGeneratedPlacementsUseCase emptyCandidates et areaAlreadyHasGeneratedPlacements
00:00 +8: ApplyEnvironmentGeneratedPlacementsUseCase erreurs candidates : wrong layer, area, preset, target, element, bounds
00:00 +9: ApplyEnvironmentGeneratedPlacementsUseCase candidateDuplicateId, placedElementIdConflict, candidatePositionDuplicate
00:00 +10: ApplyEnvironmentGeneratedPlacementsUseCase transactionnalité : deuxième candidate invalide → aucune mutation
00:00 +11: ApplyEnvironmentGeneratedPlacementsUseCase ProjectManifest et TileLayer.tiles inchangés après succès
00:00 +12: ApplyEnvironmentGeneratedPlacementsUseCase intégration Lot 23 → Lot 24
00:00 +13: ApplyEnvironmentGeneratedPlacementsUseCase candidateTargetLayerTilesetMismatch : layer vs element incompatible
00:00 +14: All tests passed!
```

## 8. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
Analyzing 7 items...                                            
No issues found! (ran in 2.3s)
```

Dettes préexistantes hors lot :

- Le legacy `shuffleEnvironmentAreaPlacements(...)` accepte encore le cas sans placements générés préalables, couvert par `environment_golden_slice_workflow_test.dart`. Environment-42 ne change pas ce flow legacy ; le flow TileLayer-centric V0 reste plus strict et exige `generatedPlacementIds` non vide.

## 9. Fichiers créés/modifiés

Fichiers préexistants dans le worktree avant Environment-42 :

- Aucun fichier modifié ou non suivi au tout début du lot : la sortie initiale de `git status --short --untracked-files=all` était vide.

Fichiers créés par Environment-42 :

- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart`
- `reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md`

Fichiers modifiés par Environment-42 :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Problèmes réellement introduits par ce lot :

- Aucun problème connu après tests ciblés, non-régressions, analyse ciblée et `git diff --check`.

## 10. Non-objectifs respectés

- Pas de preview.
- Pas de génération initiale ajoutée : `Générer dans ce layer` reste le lot 40.
- Pas de clear simple ajouté : `Effacer les placements générés` reste le lot 41.
- Pas de modification du mask.
- Pas de modification manuelle des params locaux.
- Pas de modification du preset global.
- Pas de création d’area.
- Pas de suppression/renommage d’area.
- Pas de migration vers `TileLayer.environmentContent`.
- Pas de modification de `map_core`.
- Pas de modification runtime/gameplay/battle.
- Pas de build_runner.
- Pas de generated files.

## 11. Evidence pack

### Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact au début du lot :

```text
```

Résultat exact au moment de la reprise après compaction, alors que les tests RED du lot avaient déjà été créés par Environment-42 :

```text
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
```

### Git diff --stat

Commande :

```bash
git diff --stat
```

Résultat exact :

```text
 .../src/features/editor/state/editor_notifier.dart | 115 +++++++++++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  18 +++
 .../tile_layer_environment_inspector_section.dart  |  34 ++++++
 ...e_layer_environment_inspector_section_test.dart | 124 ++++++++++++++++++++-
 4 files changed, 289 insertions(+), 2 deletions(-)
```

Note factuelle : `git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés sont listés dans le `git status` final et dans `git ls-files --others --exclude-standard` ci-dessous.

### Git diff --name-only

Commande :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

### Fichiers non suivis

Commande complémentaire :

```bash
git ls-files --others --exclude-standard
```

Résultat exact avant création du présent rapport :

```text
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
```

### Git diff --check

Commande :

```bash
git diff --check
```

Résultat exact :

```text
```

### Commandes principales

Commandes exécutées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,260p' packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
sed -n '1,320p' packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
rg -n "onGenerateEnvironment|onClearGeneratedPlacements|canRegenerate|canShuffle|Regenerate|Shuffle|Régénérer" packages/map_editor/lib/src/ui/panels packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
dart format packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_generate_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_clear_notifier_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/environment_regenerate_shuffle_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart
flutter analyze lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
git diff --check
git diff --stat
git diff --name-only
git ls-files --others --exclude-standard
git status --short --untracked-files=all
```

## 12. Diff pertinent

### Fichiers existants modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index ef527bcd..1ad169a0 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -23,6 +23,7 @@ import '../../../application/use_cases/tile_layer_environment_area_settings_use_
 import '../../../application/use_cases/tile_layer_environment_attachment_use_cases.dart';
 import '../../../application/use_cases/tile_layer_environment_clear_use_cases.dart';
 import '../../../application/use_cases/tile_layer_environment_generation_use_cases.dart';
+import '../../../application/use_cases/tile_layer_environment_regenerate_use_cases.dart';
 import '../../../application/models/trainer_field_update.dart';
 import '../../../application/models/map_tool_preview.dart';
 import '../../../application/models/path_autotile_set.dart';
@@ -5133,6 +5134,120 @@ class EditorNotifier extends _$EditorNotifier {
     return '$removed placement(s) généré(s) effacé(s) pour la zone « ${result.areaId} ».';
   }
 
+  void regenerateEnvironmentAreaPlacementsForActiveTileLayer() {
+    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
+      shuffle: false,
+    );
+  }
+
+  void shuffleEnvironmentAreaPlacementsForActiveTileLayer() {
+    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
+      shuffle: true,
+    );
+  }
+
+  void _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer({
+    required bool shuffle,
+  }) {
+    final map = state.activeMap;
+    final manifest = state.project;
+    if (map == null || manifest == null) {
+      state = state.copyWith(
+        errorMessage: shuffle
+            ? 'Impossible de shuffler : aucune carte active ou manifeste projet.'
+            : 'Impossible de régénérer : aucune carte active ou manifeste projet.',
+      );
+      return;
+    }
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: shuffle
+            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
+            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage: shuffle
+            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
+            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
+      );
+      return;
+    }
+    final areaId = state.selectedEnvironmentAreaId?.trim();
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: shuffle
+            ? 'Sélectionnez une zone d’environnement avant de shuffler.'
+            : 'Sélectionnez une zone d’environnement avant de régénérer.',
+      );
+      return;
+    }
+
+    try {
+      final result = shuffle
+          ? ShuffleTileLayerEnvironmentAreaPlacementsUseCase().execute(
+              map,
+              manifest: manifest,
+              tileLayerId: layerId,
+              areaId: areaId,
+            )
+          : RegenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
+              map,
+              manifest: manifest,
+              tileLayerId: layerId,
+              areaId: areaId,
+            );
+
+      final removedIds = result.removedPlacementIds.toSet();
+      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
+      final clearSelection = selectionBefore != null &&
+          selectionBefore.isNotEmpty &&
+          removedIds.contains(selectionBefore);
+
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage: _tileLayerRegenerationStatusMessage(
+          result,
+          shuffle: shuffle,
+        ),
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: result.areaId,
+        selectedPlacedElementInstanceId:
+            clearSelection ? null : state.selectedPlacedElementInstanceId,
+        environmentMaskEditMode: null,
+        errorMessage: null,
+      );
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: shuffle
+            ? 'Impossible de shuffler cette zone : $e'
+            : 'Impossible de régénérer cette zone : $e',
+      );
+    }
+  }
+
+  String _tileLayerRegenerationStatusMessage(
+    TileLayerEnvironmentRegenerationResult result, {
+    required bool shuffle,
+  }) {
+    if (result.generatedPlacementCount == 0) {
+      return shuffle
+          ? 'Seed mélangée : aucun nouveau placement pour la zone « ${result.areaId} ».'
+          : 'Les placements générés ont été effacés ; aucun nouveau placement n’a été généré pour la zone « ${result.areaId} ».';
+    }
+    return shuffle
+        ? 'Seed mélangée : ${result.generatedPlacementCount} placement(s) régénéré(s) pour la zone « ${result.areaId} ».'
+        : 'Zone « ${result.areaId} » régénérée : ${result.generatedPlacementCount} placement(s).';
+  }
+
   void startEnvironmentMaskPaintingForActiveTileLayer() {
     _startEnvironmentMaskEditingForActiveTileLayer(
       mode: EnvironmentMaskEditMode.paint,
diff --git a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
index eddbf3f0..9cd75fbd 100644
--- a/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
@@ -140,6 +140,16 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
             tileLayerEnvironmentReadModel.canClearGeneratedPlacements &&
             !tileLayerEnvironmentReadModel.hasErrors &&
             state.selectedEnvironmentAreaId != null;
+    final canRegenerateTileLayerEnvironment = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        tileLayerEnvironmentReadModel.canRegenerate &&
+        !tileLayerEnvironmentReadModel.hasErrors &&
+        state.selectedEnvironmentAreaId != null;
+    final canShuffleTileLayerEnvironment = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        tileLayerEnvironmentReadModel.canShuffle &&
+        !tileLayerEnvironmentReadModel.hasErrors &&
+        state.selectedEnvironmentAreaId != null;
     final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
     final showTilesSection = activeLayer is TileLayer ||
         state.activeTool == EditorToolType.tilePaint ||
@@ -308,6 +318,14 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                             ? notifier
                                 .clearEnvironmentGeneratedPlacementsForActiveTileLayer
                             : null,
+                    onRegenerateEnvironment: canRegenerateTileLayerEnvironment
+                        ? notifier
+                            .regenerateEnvironmentAreaPlacementsForActiveTileLayer
+                        : null,
+                    onShuffleEnvironment: canShuffleTileLayerEnvironment
+                        ? notifier
+                            .shuffleEnvironmentAreaPlacementsForActiveTileLayer
+                        : null,
                   ),
                 ),
               if (showEnvironmentLayerSection)
diff --git a/packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart b/packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
index 423aec42..d4a9e42a 100644
--- a/packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
+++ b/packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
@@ -29,6 +29,8 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
     this.onSetSeed,
     this.onGenerateEnvironment,
     this.onClearGeneratedPlacements,
+    this.onRegenerateEnvironment,
+    this.onShuffleEnvironment,
   });
 
   final TileLayerEnvironmentAttachmentReadModel readModel;
@@ -50,6 +52,8 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
   final ValueChanged<int>? onSetSeed;
   final VoidCallback? onGenerateEnvironment;
   final VoidCallback? onClearGeneratedPlacements;
+  final VoidCallback? onRegenerateEnvironment;
+  final VoidCallback? onShuffleEnvironment;
 
   @override
   Widget build(BuildContext context) {
@@ -155,6 +159,8 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
             onStopMaskPainting: onStopMaskPainting,
             onGenerateEnvironment: onGenerateEnvironment,
             onClearGeneratedPlacements: onClearGeneratedPlacements,
+            onRegenerateEnvironment: onRegenerateEnvironment,
+            onShuffleEnvironment: onShuffleEnvironment,
           ),
         ],
       ),
@@ -1215,6 +1221,8 @@ class _FutureActions extends StatelessWidget {
     required this.onStopMaskPainting,
     required this.onGenerateEnvironment,
     required this.onClearGeneratedPlacements,
+    required this.onRegenerateEnvironment,
+    required this.onShuffleEnvironment,
   });
 
   final TileLayerEnvironmentAttachmentReadModel readModel;
@@ -1229,6 +1237,8 @@ class _FutureActions extends StatelessWidget {
   final VoidCallback? onStopMaskPainting;
   final VoidCallback? onGenerateEnvironment;
   final VoidCallback? onClearGeneratedPlacements;
+  final VoidCallback? onRegenerateEnvironment;
+  final VoidCallback? onShuffleEnvironment;
 
   @override
   Widget build(BuildContext context) {
@@ -1311,6 +1321,30 @@ class _FutureActions extends StatelessWidget {
         ),
       );
     }
+    if (readModel.canRegenerate || readModel.canPaintMask) {
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.arrow_clockwise,
+          label: 'Régénérer',
+          enabled: readModel.canRegenerate &&
+              !readModel.hasErrors &&
+              onRegenerateEnvironment != null,
+          onPressed: readModel.canRegenerate ? onRegenerateEnvironment : null,
+        ),
+      );
+    }
+    if (readModel.canShuffle || readModel.canPaintMask) {
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.shuffle,
+          label: 'Shuffle',
+          enabled: readModel.canShuffle &&
+              !readModel.hasErrors &&
+              onShuffleEnvironment != null,
+          onPressed: readModel.canShuffle ? onShuffleEnvironment : null,
+        ),
+      );
+    }
 
     if (actions.isEmpty) {
       return InspectorEmbeddedSecondaryCapsule(
diff --git a/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart b/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
index 0e0fa23b..11d6ee4f 100644
--- a/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
+++ b/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
@@ -1254,8 +1254,124 @@ void main() {
         _buttonFor(tester, 'Effacer les placements générés').onPressed,
         isNull,
       );
-      expect(find.text('Régénérer'), findsNothing);
-      expect(find.text('Shuffle'), findsNothing);
+      expect(find.text('Régénérer'), findsOneWidget);
+      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);
+      expect(find.text('Shuffle'), findsOneWidget);
+      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);
+    });
+
+    testWidgets('Régénérer reste désactivé sans callback', (tester) async {
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          hasGeneratedPlacements: true,
+          canRegenerate: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+        ),
+      );
+
+      expect(find.text('Régénérer'), findsOneWidget);
+      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);
+    });
+
+    testWidgets('Régénérer est actif avec callback', (tester) async {
+      var regenerated = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          hasGeneratedPlacements: true,
+          canRegenerate: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+        ),
+        onRegenerateEnvironment: () {
+          regenerated++;
+        },
+      );
+
+      expect(find.text('Régénérer'), findsOneWidget);
+      expect(_buttonFor(tester, 'Régénérer').onPressed, isNotNull);
+
+      await tester.tap(find.text('Régénérer'));
+      await tester.pump();
+
+      expect(regenerated, 1);
+    });
+
+    testWidgets('Shuffle reste désactivé sans callback', (tester) async {
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          hasGeneratedPlacements: true,
+          canShuffle: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+        ),
+      );
+
+      expect(find.text('Shuffle'), findsOneWidget);
+      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);
+    });
+
+    testWidgets('Shuffle est actif avec callback', (tester) async {
+      var shuffled = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.generated,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaName: 'Bosquet nord',
+          selectedPresetName: 'Forêt',
+          maskActiveCellCount: 42,
+          hasMask: true,
+          generatedPlacementCount: 18,
+          hasGeneratedPlacements: true,
+          canShuffle: true,
+          emptyStateTitle: 'Placements générés',
+          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
+        ),
+        onShuffleEnvironment: () {
+          shuffled++;
+        },
+      );
+
+      expect(find.text('Shuffle'), findsOneWidget);
+      expect(_buttonFor(tester, 'Shuffle').onPressed, isNotNull);
+
+      await tester.tap(find.text('Shuffle'));
+      await tester.pump();
+
+      expect(shuffled, 1);
     });
   });
 }
@@ -1281,6 +1397,8 @@ Future<void> _pump(
   ValueChanged<int>? onSetSeed,
   VoidCallback? onGenerateEnvironment,
   VoidCallback? onClearGeneratedPlacements,
+  VoidCallback? onRegenerateEnvironment,
+  VoidCallback? onShuffleEnvironment,
 }) {
   return tester.pumpWidget(
     MaterialApp(
@@ -1308,6 +1426,8 @@ Future<void> _pump(
             onSetSeed: onSetSeed,
             onGenerateEnvironment: onGenerateEnvironment,
             onClearGeneratedPlacements: onClearGeneratedPlacements,
+            onRegenerateEnvironment: onRegenerateEnvironment,
+            onShuffleEnvironment: onShuffleEnvironment,
           ),
         ),
       ),
```

### Nouveau fichier : `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import 'environment_generator_regenerate_use_cases.dart';
import 'tile_layer_environment_clear_use_cases.dart';
import 'tile_layer_environment_generation_use_cases.dart';

final class TileLayerEnvironmentRegenerationResult {
  const TileLayerEnvironmentRegenerationResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.previousSeed,
    required this.currentSeed,
    required this.removedPlacementIds,
    required this.clearedReferenceCount,
    required this.generatedPlacementIds,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final int previousSeed;
  final int currentSeed;
  final List<String> removedPlacementIds;
  final int clearedReferenceCount;
  final List<String> generatedPlacementIds;

  int get removedPlacementCount => removedPlacementIds.length;
  int get generatedPlacementCount => generatedPlacementIds.length;
  bool get seedChanged => previousSeed != currentSeed;
}

class RegenerateTileLayerEnvironmentAreaPlacementsUseCase {
  TileLayerEnvironmentRegenerationResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    return _regenerateOrShuffle(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
      shuffle: false,
    );
  }
}

class ShuffleTileLayerEnvironmentAreaPlacementsUseCase {
  TileLayerEnvironmentRegenerationResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String tileLayerId,
    required String areaId,
  }) {
    return _regenerateOrShuffle(
      map,
      manifest: manifest,
      tileLayerId: tileLayerId,
      areaId: areaId,
      shuffle: true,
    );
  }
}

TileLayerEnvironmentRegenerationResult _regenerateOrShuffle(
  MapData map, {
  required ProjectManifest manifest,
  required String tileLayerId,
  required String areaId,
  required bool shuffle,
}) {
  final target = _resolveRegenerationTarget(
    map,
    manifest: manifest,
    tileLayerId: tileLayerId,
    areaId: areaId,
  );
  final previousSeed = target.area.seed;
  final clear =
      ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
    map,
    tileLayerId: target.tileLayer.id,
    areaId: target.area.id,
  );

  var working = clear.map;
  var currentSeed = previousSeed;
  if (shuffle) {
    currentSeed = nextEnvironmentAreaSeed(previousSeed);
    final seed = SetEnvironmentAreaSeedUseCase().execute(
      working,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      seed: currentSeed,
    );
    if (!seed.isSuccess) {
      throw EditorValidationException(seed.failureMessage ?? 'Seed invalide');
    }
    working = seed.map!;
  }

  final generate = GenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
    working,
    manifest: manifest,
    tileLayerId: target.tileLayer.id,
    areaId: target.area.id,
  );

  return TileLayerEnvironmentRegenerationResult(
    map: generate.map,
    tileLayerId: target.tileLayer.id,
    environmentLayerId: target.environmentLayer.id,
    areaId: target.area.id,
    previousSeed: previousSeed,
    currentSeed: currentSeed,
    removedPlacementIds: clear.removedPlacementIds,
    clearedReferenceCount: clear.clearedReferenceCount,
    generatedPlacementIds: generate.generatedPlacementIds,
  );
}

_TileLayerEnvironmentRegenerationTarget _resolveRegenerationTarget(
  MapData map, {
  required ProjectManifest manifest,
  required String tileLayerId,
  required String areaId,
}) {
  final tid = tileLayerId.trim();
  if (tid.isEmpty) {
    throw const EditorValidationException('Tile layer id cannot be empty');
  }
  final aid = areaId.trim();
  if (aid.isEmpty) {
    throw const EditorValidationException(
      'Environment area id cannot be empty',
    );
  }

  final layer = _findLayerById(map, tid);
  if (layer == null) {
    throw EditorValidationException('Tile layer not found: $tid');
  }
  if (layer is! TileLayer) {
    throw EditorValidationException('Layer is not a TileLayer: $tid');
  }

  final environmentLayer = _firstEnvironmentLayerTargeting(map, tid);
  if (environmentLayer == null) {
    throw const EditorValidationException(
      'Activez d’abord l’environnement sur ce layer.',
    );
  }

  final area = environmentLayer.content.areaById(aid);
  if (area == null) {
    throw EditorValidationException('Environment area not found: $aid');
  }
  if (_presetById(manifest, area.presetId) == null) {
    throw EditorValidationException(
      'Environment preset not found: ${area.presetId.trim()}',
    );
  }
  if (area.mask.activeCellCount == 0) {
    throw const EditorValidationException(
      'Masque vide : peignez une zone sur la carte avant de régénérer.',
    );
  }
  if (area.generatedPlacementIds.isEmpty) {
    throw const EditorValidationException(
      'Aucun placement généré à régénérer pour cette zone.',
    );
  }

  return _TileLayerEnvironmentRegenerationTarget(
    tileLayer: layer,
    environmentLayer: environmentLayer,
    area: area,
  );
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) return layer;
  }
  return null;
}

EnvironmentLayer? _firstEnvironmentLayerTargeting(
  MapData map,
  String tileLayerId,
) {
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer &&
        layer.content.targetTileLayerId?.trim() == tileLayerId) {
      return layer;
    }
  }
  return null;
}

EnvironmentPreset? _presetById(ProjectManifest manifest, String presetId) {
  final pid = presetId.trim();
  for (final preset in manifest.environmentPresets) {
    if (preset.id == pid) return preset;
  }
  return null;
}

final class _TileLayerEnvironmentRegenerationTarget {
  const _TileLayerEnvironmentRegenerationTarget({
    required this.tileLayer,
    required this.environmentLayer,
    required this.area,
  });

  final TileLayer tileLayer;
  final EnvironmentLayer environmentLayer;
  final EnvironmentArea area;
}
```

### Nouveau fichier : `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_regenerate_use_cases.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart';

void main() {
  group('TileLayer environment regenerate / shuffle use cases', () {
    test('regenerate clear puis génère avec le même seed', () {
      final map = _map();
      final result = RegenerateTileLayerEnvironmentAreaPlacementsUseCase()
          .execute(map,
              manifest: _manifest(), tileLayerId: 'tiles', areaId: 'area');

      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');
      expect(result.previousSeed, 7);
      expect(result.currentSeed, 7);
      expect(result.seedChanged, isFalse);
      expect(result.removedPlacementCount, 2);
      expect(result.clearedReferenceCount, 3);
      expect(result.generatedPlacementCount, greaterThan(0));

      final area = _areaById(result.map, 'area');
      expect(area.seed, 7);
      expect(area.generatedPlacementIds, result.generatedPlacementIds);
      expect(area.generatedPlacementIds, isNot(contains('old_a')));
      expect(area.generatedPlacementIds, isNot(contains('old_b')));
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.presetId, 'forest');
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
      expect(
        result.map.placedElements.any((e) => e.id == 'other_generated'),
        isTrue,
      );
      expect(
        _areaById(result.map, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('shuffle clear puis change seed et génère', () {
      final result = ShuffleTileLayerEnvironmentAreaPlacementsUseCase().execute(
        _map(),
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
      );

      final expectedSeed = nextEnvironmentAreaSeed(7);
      final area = _areaById(result.map, 'area');
      expect(result.previousSeed, 7);
      expect(result.currentSeed, expectedSeed);
      expect(result.seedChanged, isTrue);
      expect(area.seed, expectedSeed);
      expect(area.generatedPlacementIds, result.generatedPlacementIds);
      expect(result.generatedPlacementCount, greaterThan(0));
      expect(area.paramsOverride, _params);
      expect(area.presetId, 'forest');
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
      expect(
        result.map.placedElements.any((e) => e.id == 'other_generated'),
        isTrue,
      );
    });

    test('regenerate peut finir sans nouveaux candidats après clear', () {
      final map = _map(params: _zeroParams);
      final result = RegenerateTileLayerEnvironmentAreaPlacementsUseCase()
          .execute(map,
              manifest: _manifest(), tileLayerId: 'tiles', areaId: 'area');

      final area = _areaById(result.map, 'area');
      expect(result.removedPlacementCount, 2);
      expect(result.generatedPlacementCount, 0);
      expect(area.generatedPlacementIds, isEmpty);
      expect(result.map.placedElements.any((e) => e.id == 'old_a'), isFalse);
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('refuse les entrées invalides sans mutation', () {
      final useCase = RegenerateTileLayerEnvironmentAreaPlacementsUseCase();
      final manifest = _manifest();
      final map = _map();

      expect(
        () => useCase.execute(
          map,
          manifest: manifest,
          tileLayerId: 'missing',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithNonTileActiveLayer(),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithoutEnvironmentAttachment(),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          map,
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'missing',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(areaPresetId: 'missing'),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(cells: List<bool>.filled(4, false)),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(generatedPlacementIds: const []),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(_areaById(map, 'area').generatedPlacementIds, hasLength(3));
      expect(map.placedElements.length, 4);
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

final _zeroParams = EnvironmentGenerationParams(
  density: 0,
  variation: 0,
  edgeDensity: 0,
  minSpacingCells: 0,
);

MapData _map({
  List<String> generatedPlacementIds = const [
    'old_a',
    'old_b',
    'missing_old',
  ],
  List<bool>? cells,
  String areaPresetId = 'forest',
  EnvironmentGenerationParams? params,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Zone',
              presetId: areaPresetId,
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: cells ?? List<bool>.filled(4, true),
              ),
              seed: 7,
              paramsOverride: params ?? _params,
              generatedPlacementIds: generatedPlacementIds,
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: List<bool>.filled(4, true),
              ),
              seed: 3,
              generatedPlacementIds: const ['other_generated'],
            ),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'old_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'old_b',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 0),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

MapData _mapWithoutEnvironmentAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
      ),
    ],
  );
}

MapData _mapWithNonTileActiveLayer() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const MapLayer.object(id: 'tiles', name: 'Objects'),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
      ),
    ],
  );
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return map.layers
      .whereType<EnvironmentLayer>()
      .single
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
```

### Nouveau fichier : `packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_regenerate_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer regenerate / shuffle', () {
    test('regenerate garde la sélection TileLayer et conserve le seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );

      notifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      final area = _areaById(state.activeMap!, 'area');
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('régénér'));
      expect(state.isDirty, isTrue);
      expect(area.seed, 7);
      expect(area.generatedPlacementIds, isNotEmpty);
      expect(area.generatedPlacementIds, isNot(contains('old_a')));
      expect(
          state.activeMap!.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('shuffle garde la sélection TileLayer et change le seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
        savedMapSnapshot: map,
      );

      notifier.shuffleEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      final area = _areaById(state.activeMap!, 'area');
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('Seed'));
      expect(area.seed, nextEnvironmentAreaSeed(7));
      expect(area.generatedPlacementIds, isNotEmpty);
      expect(
          state.activeMap!.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('refuse sans TileLayer actif ou sans area sélectionnée', () {
      final noTileContainer = ProviderContainer();
      addTearDown(noTileContainer.dispose);
      final noTileNotifier =
          noTileContainer.read(editorNotifierProvider.notifier);
      final map = _map();
      noTileNotifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area',
      );

      noTileNotifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(noTileNotifier.state.activeMap, same(map));
      expect(noTileNotifier.state.activeLayerId, 'env');
      expect(noTileNotifier.state.selectedEnvironmentAreaId, 'area');
      expect(noTileNotifier.state.errorMessage, contains('TileLayer'));

      final noAreaContainer = ProviderContainer();
      addTearDown(noAreaContainer.dispose);
      final noAreaNotifier =
          noAreaContainer.read(editorNotifierProvider.notifier);
      noAreaNotifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      noAreaNotifier.shuffleEnvironmentAreaPlacementsForActiveTileLayer();

      expect(noAreaNotifier.state.activeMap, same(map));
      expect(noAreaNotifier.state.activeLayerId, 'tiles');
      expect(noAreaNotifier.state.selectedEnvironmentAreaId, isNull);
      expect(noAreaNotifier.state.errorMessage, contains('zone'));
    });

    test('refuse si generatedPlacementIds est vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(generatedPlacementIds: const []);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      notifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('placement'));
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

MapData _map({
  List<String> generatedPlacementIds = const ['old_a', 'old_b'],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Zone',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: List<bool>.filled(4, true),
              ),
              seed: 7,
              paramsOverride: _params,
              generatedPlacementIds: generatedPlacementIds,
            ),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'old_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'old_b',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 0),
      ),
    ],
  );
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return map.layers
      .whereType<EnvironmentLayer>()
      .single
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
```

Le nouveau rapport n’est pas reproduit dans un bloc de code séparé pour éviter une auto-inclusion récursive ; son contenu complet est le présent document.

## 13. Auto-review

- Regenerate compose-t-il clear + generate en une seule mutation ? Oui. Le wrapper compose la map finale ; le notifier appelle une seule `_applyMapMutation`.
- Shuffle compose-t-il clear + seed + generate en une seule mutation ? Oui. Le seed est appliqué dans le wrapper avant génération ; le notifier applique seulement la map finale.
- Regenerate conserve-t-il le seed ? Oui, couvert par tests use case et notifier.
- Shuffle change-t-il le seed ? Oui, via `nextEnvironmentAreaSeed`, couvert par tests use case et notifier.
- `generatedPlacementIds` est-il remplacé proprement ? Oui, les anciens ids sont supprimés puis les nouveaux ids sont écrits par le use case generate/apply existant.
- Les anciens `MapPlacedElement` générés sont-ils supprimés ? Oui, via le use case clear existant.
- Les placements manuels sont-ils préservés ? Oui, couvert par tests.
- Les placements d’autres areas sont-ils préservés ? Oui, couvert par test use case.
- `mask` / `paramsOverride` / `presetId` sont-ils préservés ? Oui, couvert par test use case.
- `activeLayerId` reste-t-il le TileLayer ? Oui, couvert par test notifier.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui, couvert par test notifier.
- `environmentMaskEditMode` devient-il null ? Oui, couvert par test notifier.
- Aucune sauvegarde disque n’est-elle faite ? Oui, aucune méthode de sauvegarde n’est appelée.
- Le flow legacy reste-t-il intact ? Oui, les tests legacy `environment_regenerate_shuffle_test.dart` et `environment_golden_slice_workflow_test.dart` passent.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- La sémantique V0 de `Régénérer` et `Shuffle` était bien cadrée.
- La contrainte de mutation unique côté notifier était explicite et utile.
- Les non-objectifs étaient suffisamment stricts pour éviter preview, generation initiale bis, ou clear simple.

Ambigu :

- Le legacy `shuffle` autorise une génération sans placements existants, alors que le prompt Environment-42 TileLayer-centric demande des `generatedPlacementIds` existants. Le lot garde le legacy intact et applique la règle stricte au nouveau flow.
- Le read model exposait déjà `canShuffle: true` dans l’état `ready` sans generated placements. Le wiring `MapInspectorPanel` suit le read model ; le widget reste désactivé sans callback dans ce cas. Le wrapper refuse aussi l’appel direct sans generated ids.

À trancher avant Environment-43 :

- Clarifier si `Shuffle` côté TileLayer doit rester strictement réservé aux zones déjà générées ou devenir un raccourci “nouveau seed + génération initiale” comme le legacy.
- Définir les messages UI précis pour différencier “prêt à générer”, “déjà généré”, “peut régénérer”, “peut shuffle”, “masque vide” et “preset manquant”.

## 15. Verdict

```text
Environment-42 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-43 — TileLayer Environment Generation Feedback / Readiness Polish V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement regenerate/shuffle.
- [x] Je n’ai pas ajouté de preview.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le preset global.
- [x] Je n’ai pas créé/supprimé/renommé d’area.
- [x] Regenerate conserve le seed.
- [x] Shuffle change le seed.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] environmentMaskEditMode devient null après action.
- [x] Les placements manuels sont préservés.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.

## 16. Commande finale obligatoire

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
?? reports/environment_studio/environment_42_tile_layer_environment_regenerate_shuffle.md
```
