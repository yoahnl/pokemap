# ShadowV2-30 — V2 Suppresses Same-Element Legacy Static Shadow V0

## 1. Résumé exécutif

ShadowV2-30 n'a pas été implémenté.

Blocage strict détecté avant modification du code :

```text
La règle demandée rend nécessaire la mise à jour de
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart,
mais ce fichier n'est pas dans la liste des fichiers modifiables du lot.
```

Le contrat dit :

```text
Si un autre fichier semble nécessaire, tu dois t’arrêter et documenter le blocage.
Tu ne dois pas élargir le périmètre.
```

Décision appliquée :

```text
STOP.
Aucune implémentation.
Aucun fichier de production modifié.
Aucun test modifié.
Rapport de blocage uniquement.
```

## 2. Objectif du lot

Objectif initial :

```text
Quand un ProjectElementEntry possède projectedBuildingShadow.enabled == true
ET que le preset ShadowV2 référencé est résoluble,
alors la shadow V1 static placed du même élément / placement ne doit plus être produite,
ni côté runtime,
ni côté editor preview.
```

Cet objectif reste valide, mais le périmètre de fichiers autorisés est insuffisant pour le vérifier proprement avec `flutter test test/shadow`.

## 3. Rappel ShadowV2-29

ShadowV2-29 a conclu :

- la source moteur la plus probable des anciennes ombres moches est `ProjectElementEntry.shadow` V1 ;
- le runtime V1 lit `element.shadow` et `placed.shadowOverride` ;
- la preview editor V1 lit aussi `element.shadow` et `placed.shadowOverride` ;
- ShadowV2 est rendue / peinte avant V1 ;
- aucune règle actuelle ne masque V1 quand V2 existe ;
- la règle recommandée est : V2 active et résoluble masque V1 same-element, sans supprimer les données.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
Aucune ligne.
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Résultat `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Résultat `rg` :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- le design gate ShadowV2-29 est déjà satisfait ;
- ShadowV2-30 peut être une implémentation ;
- mais le contrat du Lot 30 contient une règle d'arrêt si un fichier hors périmètre devient nécessaire.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés par ce lot :

```text
reports/shadows/v2/shadow_v2_30_v2_suppresses_same_element_legacy_static_shadow.md
```

Fichiers modifiés par ce lot :

```text
Aucun.
```

Fichiers supprimés par ce lot :

```text
Aucun.
```

## 7. Audit initial runtime/editor V1

Commande runtime V1 :

```bash
rg -n "buildRuntimeStaticPlacedElementShadowSources|RuntimeStaticPlacedElementShadowSource|element.shadow|placed.shadowOverride|projectedBuildingShadow|projectedBuildingShadowCatalog|ProjectElementShadowConfig|MapPlacedElementShadowOverride" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart packages/map_runtime/test/shadow
```

Extraits pertinents :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:8:List<RuntimeStaticPlacedElementShadowSource>
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:9:    buildRuntimeStaticPlacedElementShadowSources({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:48:      RuntimeStaticPlacedElementShadowSource(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:51:        elementShadow: element.shadow,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:52:        placedOverride: placed.shadowOverride,
```

Commande editor V1 :

```bash
rg -n "buildEditorStaticShadowPreviewInstructions|element.shadow|placed.shadowOverride|projectedBuildingShadow|projectedBuildingShadowCatalog|ProjectElementShadowConfig|MapPlacedElementShadowOverride|resolveShadowConfig" packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart packages/map_editor/test
```

Extraits pertinents :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:112:    buildEditorStaticShadowPreviewInstructions({
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:154:    final resolution = resolveShadowConfig(
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:156:      elementShadow: element.shadow,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:157:      placedOverride: placed.shadowOverride,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:179:      elementFootprint: element.shadow?.footprint,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:180:      overrideFootprint: placed.shadowOverride?.footprint,
```

Commande chemins V2 :

```bash
rg -n "buildRuntimeProjectedBuildingShadowCollection|buildEditorProjectedBuildingShadowPreviewInstructions|projectedBuildingShadow|projectedBuildingShadowCatalog|presetById" packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test
```

Extraits pertinents :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:8:    buildRuntimeProjectedBuildingShadowCollection({
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:42:    final config = element.projectedBuildingShadow;
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:47:    final preset = manifest.projectedBuildingShadowCatalog.presetById(
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart:6:    buildEditorProjectedBuildingShadowPreviewInstructions({
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart:43:    final config = element.projectedBuildingShadow;
```

Commande anti-dérive initiale :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|matchesGoldenFile|SHADOW_SCREENSHOT|selbrume|reports/shadows/baselines" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart packages/map_runtime/test/shadow packages/map_editor/test
```

Extraits pertinents :

```text
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:173:    test('clears genericProjection auto shadow when policy has no suggestion',
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:498:    family: StaticShadowFamily.genericProjection,
packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart:196:  test('duplicate relativePath in manifest fails ProjectValidator', () async {
```

Interprétation :

- les hits anti-dérive initiaux sont dans des tests existants hors fichiers de production à modifier ;
- le fichier runtime V1 autorisé n'a pas de hit anti-dérive ;
- le fichier editor V1 autorisé n'appelle pas diagnostics ni auto-policy.

## 8. Règle métier implémentée

Non implémentée.

Raison :

```text
La mise en œuvre rend nécessaire l'ajustement d'un test existant hors périmètre autorisé.
```

## 9. Implémentation runtime

Non réalisée.

Point d'intégration confirmé :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
```

Le skip runtime devrait être ajouté après résolution de `element` et avant création de `RuntimeStaticPlacedElementShadowSource`.

## 10. Implémentation editor preview

Non réalisée.

Point d'intégration confirmé :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Le skip editor devrait être ajouté après résolution de `element` et avant `resolveShadowConfig(...)`.

## 11. Comportement shadowOverride

Non implémenté.

Règle prévue inchangée :

```text
Si V2 est active et résoluble, shadowOverride custom ne doit pas forcer V1.
```

## 12. Cas V2 disabled / preset manquant

Non implémenté.

Règle prévue inchangée :

```text
V2 disabled ne masque pas V1.
V2 preset manquant ne masque pas V1.
```

## 13. Tests runtime ajoutés/modifiés

Aucun test modifié.

Blocage découvert :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Ce fichier n'est pas dans le périmètre autorisé, mais son test suivant attend l'ancien comportement :

```text
runtime projected building visual POC keeps V2 before V1 in merged collection
```

Extrait lu :

```text
final collection = await _hostShadowCollection(withV1Shadow: true);
final groundStatic = collection!.groundStatic;

expect(groundStatic, hasLength(2));
_expectProjectedBuildingInstruction(groundStatic[0]);
_expectLegacyStaticInstruction(groundStatic[1]);
```

Pourquoi c'est bloquant :

```text
Après ShadowV2-30, un même élément avec V2 valide + V1 ne doit plus produire la V1.
Ce test devrait donc être mis à jour pour attendre seulement V2,
ou déplacé vers un scénario "V1 autre élément sans V2".
```

## 14. Tests editor ajoutés/modifiés

Aucun test modifié.

## 15. Tests canvas / host ajustés

Aucun test ajusté.

Le test host/visual POC hors périmètre doit être inclus dans le prochain périmètre pour que la régression `test/shadow` puisse être rendue verte après implémentation.

## 16. TDD RED initial

RED non exécuté.

Justification :

```text
Le blocage de périmètre a été identifié avant écriture de tests.
Le contrat impose de s'arrêter si un fichier hors périmètre devient nécessaire.
```

## 17. Résultats des tests

Tests non lancés.

Raison :

```text
Aucune modification d'implémentation ni de test n'a été faite.
Le lot s'arrête en blocage de périmètre.
```

## 18. Résultat analyze

Analyze non lancé.

Raison :

```text
Aucun fichier Dart n'a été modifié.
```

## 19. Audit anti-dérive

Audit initial exécuté.

Résultat utile :

- pas de nouveau hit, car aucune implémentation ;
- les hits existants concernent des tests ou concepts V1 déjà présents ;
- aucun fichier runtime/editor autorisé n'a été modifié.

## 20. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/**
packages/map_runtime/**
packages/map_editor/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 21. Ce qui n’a volontairement pas été créé

```text
migration
outil de cleanup
nouveau modèle persistant
nouveau codec
generated file
screenshot
baseline
fixture Selbrume
renderer
painter
UI
flag public
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
Aucune ligne.
```

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Résultat :

```text
Aucune ligne.
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Résultat :

```text
Aucune ligne.
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
?? reports/shadows/v2/shadow_v2_30_v2_suppresses_same_element_legacy_static_shadow.md
```

## 26. Risques / réserves

- Le périmètre autorisé du Lot 30 ne contient pas tous les tests qui codent l'ancien comportement.
- Implémenter sans mettre à jour `runtime_projected_building_shadow_visual_poc_test.dart` ferait probablement échouer `cd packages/map_runtime && flutter test test/shadow`.
- Modifier ce test sans autorisation violerait le contrat.
- La règle métier reste saine, mais le prompt doit élargir explicitement le périmètre test pour couvrir les preuves runtime existantes.

## 27. Auto-critique

- Le lot respecte-t-il strictement ShadowV2-29 ? Oui côté décision ; non implémenté à cause du périmètre.
- La règle est-elle identique runtime/editor ? Elle n'a pas été codée.
- V2 disabled garde-t-elle V1 ? Non vérifié par code.
- V2 preset manquant garde-t-il V1 ? Non vérifié par code.
- shadowOverride custom est-il bien masqué par V2 valide ? Non vérifié par code.
- Les éléments sans V2 gardent-ils leurs petites V1 utiles ? Non vérifié par code.
- Le lot évite-t-il toute migration/destruction de données ? Oui.
- Le lot évite-t-il Selbrume/screenshot/baseline ? Oui.
- Les tests prouvent-ils la suppression sans dépendre de pixels fragiles ? Non, car aucun test n'a été écrit.
- Le rapport contient-il les preuves du blocage ? Oui.

## 28. Regard critique sur le prompt

Le prompt est cohérent sur la règle métier, mais le périmètre autorisé manque un test déjà connu depuis ShadowV2-26 :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Ce test prouve historiquement la coexistence V2 + V1 dans la collection host. ShadowV2-30 inverse cette attente. Il doit donc être explicitement modifiable dans le prochain prompt.

## 29. Prochain lot recommandé

```text
ShadowV2-30-bis — V2 Suppresses Same-Element Legacy Static Shadow V0, Scope Fix
```

Objectif :

```text
Reprendre ShadowV2-30 avec le même objectif,
mais ajouter au périmètre autorisé :
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Modification test attendue :

```text
Remplacer le test "keeps V2 before V1 in merged collection"
par une preuve "suppresses same-element V1 when V2 is resolvable",
et ajouter si nécessaire un scénario séparé où V1 d'un autre élément sans V2 reste présente.
```

## 30. Code complet des fichiers créés/modifiés

Ce rapport est le seul fichier créé par le lot.

Checklist finale :

- [ ] V2 valide masque V1 same-element runtime
- [ ] V2 valide masque V1 same-element editor preview
- [ ] V2 disabled ne masque pas V1
- [ ] V2 preset manquant ne masque pas V1
- [ ] V1 non-V2 reste fonctionnelle
- [ ] shadowOverride custom ne force pas V1 si V2 valide existe
- [x] Aucune donnée supprimée
- [x] Aucun fichier map_core modifié
- [x] Aucun renderer runtime modifié
- [x] PlayableMapGame non modifié
- [x] MapLayersComponent non modifié
- [x] MapGridPainter production non modifié
- [x] Builder V2 runtime non modifié
- [x] Builder V2 editor non modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [ ] Tests runtime ciblés passés
- [ ] Tests editor ciblés passés
- [ ] Régressions utiles passées
- [ ] Analyze ciblé OK
- [x] Evidence Pack de blocage complet
- [x] git status final conforme au blocage documenté
