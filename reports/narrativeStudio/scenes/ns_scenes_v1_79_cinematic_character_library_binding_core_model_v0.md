# NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0

## 1. Résumé exécutif

Statut : DONE.

Le lot V1-79 matérialise le contrat V1-78 dans `map_core` : un acteur cinematic-only peut maintenant recevoir une apparence issue de la Character Library via `CinematicActorAppearanceBinding`, stocké dans `CinematicStageContext.actorAppearanceBindings`.

Demandeur : Karim. Le lot a été lancé par Karim avec le prompt du prochain lot et l'autorisation d'utiliser des sub agents au besoin.

## 2. Objectif du lot

Créer le modèle core minimal pour relier un acteur `cinematicOnly` à un `ProjectCharacterEntry`, sans picker UI, sans preview réelle, sans runtime et sans donnée Selbrume.

## 3. Gate 0

Commande `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Commande `git branch --show-current` :

```text
main
```

Commande `git status --short --untracked-files=all` avant édition : sortie vide.

Commande `git diff --stat` avant édition : sortie vide.

Commande `git diff --name-only` avant édition : sortie vide.

Dernier historique pertinent : `92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)`.

## 4. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_78_cinematic_character_library_binding_prep_contract.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/project_manifest_cinematics_test.dart`

## 5. Design Gate

Réponses de cadrage retenues :

1. Le binding d'apparence est séparé du binding logique.
2. `CinematicActorBinding` ne reçoit pas `characterId`.
3. La donnée vit dans `CinematicStageContext`.
4. Le champ s'appelle `actorAppearanceBindings`.
5. L'élément s'appelle `CinematicActorAppearanceBinding`.
6. Chaque binding porte `actorId`.
7. Chaque binding porte `characterId`.
8. Les deux IDs sont requis et trimés.
9. Les anciens JSON sans `actorAppearanceBindings` chargent une liste vide.
10. Le JSON écrit toujours `actorAppearanceBindings`.
11. Un acteur ne peut avoir qu'un binding d'apparence.
12. Un binding d'apparence doit référencer un acteur existant.
13. Un binding d'apparence V0 doit référencer un actor binding `cinematicOnly`.
14. `player` n'est pas override en V0.
15. `mapEntity` n'est pas override en V0.
16. `unbound` n'est pas override en V0.
17. Le binding d'apparence ne porte pas `startMs`.
18. Le binding d'apparence ne porte pas `endMs`.
19. Le binding d'apparence ne mute pas la timeline.
20. Le binding d'apparence ne mute pas `durationMs`.
21. Les opérations authoring restent pures.
22. Upsert remplace par `actorId`.
23. Remove supprime par `actorId`.
24. Remove autorise le nettoyage même si l'acteur a disparu.
25. Les diagnostics asset-only vérifient surtout les refs acteurs et le kind.
26. Les diagnostics project-aware résolvent `ProjectManifest.characters`.
27. Character Library vide produit un warning si un acteur cinematic-only en dépendra.
28. Character inconnu produit une erreur.
29. Tileset manquant produit un warning.
30. Idle animation manquante produit un warning preview-readiness.
31. Aucun code UI n'est ajouté.
32. Aucun runtime n'est ajouté.
33. Aucun build_runner n'est nécessaire.
34. Le prochain lot logique devient le picker Character Library.

## 6. Scope autorisé

Modifications limitées à `packages/map_core`, tests `map_core`, et rapports/roadmaps Narrative Studio.

## 7. Scope réalisé

- Modèle `CinematicActorAppearanceBinding`.
- Extension `CinematicStageContext.actorAppearanceBindings`.
- Opérations `upsertCinematicActorAppearanceBinding` et `removeCinematicActorAppearanceBinding`.
- Validations authoring.
- Diagnostics actor/character/preview-readiness.
- Tests JSON, manifest, opérations et diagnostics.
- Roadmaps V1-79/V1-80/V1-90 mises à jour.

## 8. Hors scope respecté

Aucun picker UI, aucune preview réelle, aucun runtime, aucun playback, aucun pathfinding, aucune donnée Selbrume, aucune image IA, aucun changement `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

## 9. Contrat V1-78 implémenté

V1-78 recommandait l'Option B : une couche d'apparence séparée `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings`. V1-79 implémente cette option.

## 10. Modèle ajouté

`CinematicActorAppearanceBinding` est un modèle immutable avec :

- `actorId`
- `characterId`
- `fromJson`
- `toJson`
- equality/hashCode

Les deux IDs utilisent la validation existante `_requireTrimmed`.

## 11. Extension Stage Context

`CinematicStageContext` contient maintenant :

```dart
final List<CinematicActorAppearanceBinding> actorAppearanceBindings;
```

La liste est immuable et intégrée à la sérialisation, l'égalité et le hash.

## 12. Compatibilité JSON

Les anciens assets sans `actorAppearanceBindings` chargent une liste vide. Les nouveaux assets écrivent le champ sous forme de liste.

## 13. Décision characterId

`characterId` n'a pas été ajouté dans `CinematicActorBinding`, volontairement. Le binding logique décrit la source stage (`player`, `mapEntity`, `cinematicOnly`, `unbound`) ; l'apparence Character Library est une couche séparée.

## 14. Limite cinematicOnly V0

En V0, seul `cinematicOnly` peut recevoir une apparence Character Library. Les cas `player`, `mapEntity` et `unbound` restent non override pour éviter d'ouvrir trop tôt des conflits avec la map, le joueur runtime ou les entités existantes.

## 15. Opérations authoring

Deux opérations pures sont ajoutées :

- `upsertCinematicActorAppearanceBinding`
- `removeCinematicActorAppearanceBinding`

Elles retournent un `CinematicStageContextAuthoringResult`, préservent le reste du contexte stage, et passent par `updateCinematicAsset`.

## 16. Validation authoring

La validation vérifie :

- acteur existant ;
- un seul binding d'apparence par acteur ;
- actor binding existant ;
- actor binding obligatoirement `cinematicOnly`.

## 17. Diagnostics asset-only

Les diagnostics asset-only couvrent :

- `actorAppearanceBindingUnknownActor`
- `actorAppearanceBindingRequiresCinematicOnly`
- `cinematicOnlyCharacterMissing`

Ils ne résolvent pas encore les personnages, car ils n'ont pas accès au `ProjectManifest`.

## 18. Diagnostics project-aware

`diagnoseCinematicsAgainstProject` résout maintenant `ProjectManifest.characters` pour les bindings d'apparence.

Nouveaux codes :

- `actorAppearanceBindingUnknownCharacter`
- `characterLibraryUnavailable`
- `characterAssetMissingSprite`
- `characterAssetMissingPreviewData`

## 19. Relation ProjectManifest.characters

Le modèle `ProjectCharacterEntry` reste la source canonique Character Library. Le binding stocke seulement l'ID stable du personnage.

## 20. Relation player/mapEntity/unbound

Ces actors ne reçoivent pas d'apparence Character Library en V0. Les diagnostics et les opérations refusent ces overrides.

## 21. Relation timeline

Le lot ne crée aucune donnée temporelle. Aucun `startMs`, `endMs`, playhead, probe ou transport n'est persisté.

## 22. Relation durée et resize

Les opérations d'apparence ne modifient pas `durationMs`, les steps, le layout temporel dérivé ou les règles V1-68/V1-69/V1-70.

## 23. Relation future preview

Les diagnostics `characterAssetMissingSprite` et `characterAssetMissingPreviewData` préparent une future preview honnête, mais n'activent aucune preview réelle.

## 24. Anti UI

Aucun widget, picker, panel ou champ éditeur n'est ajouté. Le picker Character Library est explicitement repoussé au lot V1-80.

## 25. Anti runtime

Aucune logique runtime n'est ajoutée. Le modèle reste authoring/core.

## 26. Code ajouté dans le rapport

Extrait complet du nouveau modèle :

```dart
@immutable
final class CinematicActorAppearanceBinding {
  CinematicActorAppearanceBinding({
    required String actorId,
    required String characterId,
  })  : actorId = _requireTrimmed(
          actorId,
          'CinematicActorAppearanceBinding.actorId',
        ),
        characterId = _requireTrimmed(
          characterId,
          'CinematicActorAppearanceBinding.characterId',
        );

  factory CinematicActorAppearanceBinding.fromJson(
    Map<String, dynamic> json,
  ) {
    return CinematicActorAppearanceBinding(
      actorId: _readRequiredString(json, 'actorId'),
      characterId: _readRequiredString(json, 'characterId'),
    );
  }

  final String actorId;
  final String characterId;

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'characterId': characterId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorAppearanceBinding &&
          other.actorId == actorId &&
          other.characterId == characterId;

  @override
  int get hashCode => Object.hash(actorId, characterId);
}
```

Extrait complet des deux opérations ajoutées :

```dart
CinematicStageContextAuthoringResult upsertCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  _requireActor(cinematic, binding.actorId);
  final context = cinematic.stageContext ?? CinematicStageContext();
  _requireCinematicOnlyActorBinding(context, binding.actorId);

  final bindings = <CinematicActorAppearanceBinding>[];
  var replaced = false;
  for (final existing in context.actorAppearanceBindings) {
    if (existing.actorId == binding.actorId) {
      bindings.add(binding);
      replaced = true;
    } else {
      bindings.add(existing);
    }
  }
  if (!replaced) {
    bindings.add(binding);
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
  );
  _validateStageContextForAuthoring(cinematic, updatedContext);
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}

CinematicStageContextAuthoringResult removeCinematicActorAppearanceBinding(
  ProjectManifest project, {
  required String cinematicId,
  required String actorId,
}) {
  final cinematic = _requireCinematic(project, cinematicId);
  final id = _trimRequired(
    actorId,
    'actorId',
    'Actor appearance binding removal requires an actor id.',
  );
  final context = cinematic.stageContext ?? CinematicStageContext();
  final bindings = context.actorAppearanceBindings
      .where((binding) => binding.actorId != id)
      .toList(growable: false);
  if (bindings.length == context.actorAppearanceBindings.length) {
    throw ArgumentError.value(
      actorId,
      'actorId',
      'Actor appearance binding removal references an unknown binding.',
    );
  }
  final updatedContext = CinematicStageContext(
    backdropMode: context.backdropMode,
    actorBindings: context.actorBindings,
    actorAppearanceBindings: bindings,
    initialPlacements: context.initialPlacements,
    movementTargetBindings: context.movementTargetBindings,
  );
  final result = updateCinematicAsset(
    project,
    _copyCinematicWithStageContext(cinematic, updatedContext),
  );
  return CinematicStageContextAuthoringResult(
    updatedProject: result.updatedProject,
    cinematic: result.cinematic,
  );
}
```

Code généré : aucun fichier généré n'a été produit. `cinematic_asset.dart` est manuel et ne contient pas de `part`; `build_runner` n'était pas requis.

## 27. Tests ajoutés

Tests ajoutés dans :

- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/project_manifest_cinematics_test.dart`

Ils couvrent JSON, backward compatibility, absence de `characterId` dans `CinematicActorBinding`, upsert/remove, refus non cinematic-only, non-mutation timeline/duration/mapId, diagnostics et résolution `ProjectManifest.characters`.

## 28. Commandes de validation

Commandes vertes :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart --name 'serializes cinematic actor appearance binding for cinematic only actor'
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
cd packages/map_core && dart analyze
cd packages/map_core && dart test --reporter=compact
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultats clés :

- `cinematic_asset_test.dart` : `+14 All tests passed!`
- `project_manifest_cinematics_test.dart` : `+9 All tests passed!`
- `cinematic_authoring_operations_test.dart` : `+47 All tests passed!`
- `cinematic_diagnostics_test.dart` : `+34 All tests passed!`
- `dart analyze` map_core : `No issues found!`
- suite complète map_core : `+2390 All tests passed!`
- Library editor : `+13 All tests passed!`
- Builder editor : `+129 All tests passed!`

## 29. Analyse et build_runner

`dart analyze` dans `packages/map_core` est vert.

`build_runner` n'a pas été lancé parce qu'aucun fichier généré n'est concerné.

`flutter analyze` global `packages/map_editor` reste rouge avec `344 issues found!`, déjà présent hors lot dans la dette Pokemon SDK. Aucun fichier `map_editor` n'a été modifié.

## 30. Anti-scope

Vérification de périmètre : aucun diff dans `packages/map_editor`, `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples` ou `selbrume`.

Le lot n'ajoute pas de UI Character Library, pas de preview, pas de runtime, pas de pathfinding et pas de donnée Selbrume.

## 31. Fichiers modifiés

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/test/cinematic_asset_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/project_manifest_cinematics_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_79_cinematic_character_library_binding_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_79_evidence_pack.md`

## 32. Recommandation pour le prochain lot

Prochain lot exact recommandé : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0`.

Objectif : exposer dans le Cinematic Builder un picker no-code pour sélectionner un `ProjectCharacterEntry` pour un acteur `cinematicOnly`, en consommant `stageContext.actorAppearanceBindings`.

Backlog déplacé : `NS-SCENES-V1-90 — Cinematic Timeline Scroll / Visibility Polish V0`.
