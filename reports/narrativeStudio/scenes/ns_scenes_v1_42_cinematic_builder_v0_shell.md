# NS-SCENES-V1-42 — Cinematic Builder V0 Shell

## 1. Statut

`NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est propose DONE.

## 2. Resume

Le Cinematic Builder V0 dispose maintenant d'une coque editor read-only ouverte depuis la Cinematics Library pour les `CinematicAsset` canoniques. Le shell affiche un header, une palette verrouillee, un apercu sandbox, un deroule en lecture seule et un inspecteur placeholder.

## 3. Scope realise

- Navigation Library -> Builder -> Library.
- Ouverture uniquement depuis une entree canonique.
- Bridge legacy visible dans la Library mais exclu du Builder canonique.
- Palette visible et non authorable : Camera, Deplacement acteur, Dialogue, FX, Son, Fondu, Attente.
- Apercu sandbox placeholder, sans player visuel.
- Timeline vide/existante affichee en lecture seule.
- Inspecteur placeholder avec metadonnees, acteurs, usages et diagnostics.
- Boutons Valider, Apercu et Sauvegarder visibles mais inactifs.

## 4. Hors scope confirme

- Aucun modele core modifie.
- Aucune mutation `ProjectManifest` depuis le Builder.
- Aucune edition de timeline.
- Aucune creation, suppression ou reorganisation de step.
- Aucun player visuel.
- Aucune migration legacy.
- Aucun package runtime/gameplay/battle/examples modifie.

## 5. Design Gate

1. Le branchement est local a la Cinematics Library : pas de nouveau `EditorWorkspaceMode`.
2. Le `CinematicAsset` selectionne est relu depuis `buildCinematicsLibraryReadModel` via son id et transmis au `CinematicBuilderWorkspace`.
3. Les bridges legacy restent `scenarioBridge` et ne definissent jamais `_builderEntryId`.
4. Le shell contient header, palette, apercu sandbox, deroule et inspecteur.
5. Toutes les zones sont read-only.
6. Valider/Apercu/Sauvegarder sont inactifs car V1-42 ne valide, ne joue et ne sauvegarde rien depuis le Builder.
7. Retour Library vide seulement l'id local du Builder.
8. L'UI utilise le design system et `context.pokeMapColors`.
9. Il n'y a aucun controle d'authoring timeline.
10. Les tests couvrent navigation, bridge legacy, layout, boutons inactifs, timeline vide et non-mutation.
11. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`.

## 6. Architecture

Le Builder consomme un `CinematicsLibraryEntry`, pas un `ProjectManifest`. Cette frontiere rend impossible une mutation de donnees depuis le shell V0 et garde la Library responsable de la resolution canonique/legacy.

## 7. UI

Le shell est compose de :

- `CinematicBuilderWorkspace`
- `_BuilderHeader`
- `_BlockPalette`
- `_PreviewSandbox`
- `_TimelinePlaceholder`
- `_InspectorPlaceholder`

Les elements interactifs du header restent explicites, mais les actions de Builder sont inactives.

## 8. Navigation

La Library ajoute un bouton `Ouvrir le Builder` sur les entrees canoniques. Le bouton retour du Builder appelle `onBackToLibrary`, ce qui remet `_builderEntryId` a `null`.

## 9. Legacy

Les entrees bridge affichent `Builder canonique indisponible` avec un bouton inactif. Elles ne peuvent pas ouvrir le shell canonique.

## 10. Read-only

Le shell n'a aucun callback de sauvegarde, aucun callback d'edition, aucun champ texte et aucun controle de modification de timeline. Les tests verifient aussi que le `ProjectManifest` fixture reste identique apres rendu.

## 11. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 12. Fichiers ajoutes

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md`

## 13. Extraits de diff essentiels

- `CinematicsLibraryWorkspace` ajoute `_builderEntryId`, branche `CinematicBuilderWorkspace` si l'entree est canonique, et ajoute l'action `cinematics-library-open-builder-button`.
- `_BridgeDetailsPanel` ajoute `cinematics-library-legacy-builder-disabled-button`.
- `CinematicBuilderWorkspace` introduit les cinq zones UI read-only et les boutons header inactifs.
- Les tests Library ajoutent le parcours canonique et le verrou legacy.
- Le test Builder direct ajoute layout, etat vide, retour et screenshot gate.

## 14. Gate 0

Commandes lues avant edition :

```text
pwd -> /Users/karim/Project/pokemonProject
git branch --show-current -> main
git status --short --untracked-files=all -> sortie vide
git diff --stat -> sortie vide
git diff --name-only -> sortie vide
```

Dernier commit lu :

```text
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
```

## 15. Tests rouges

`cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

Resultat attendu rouge :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'cinematics-library-open-builder-button'>]
Test: opens builder shell for canonical cinematic and returns
Some tests failed.
```

Un lancement parallele d'un second `flutter test` a provoque un verrou Flutter local :

```text
PathExistsException: Cannot create link ... macos_window_utils-1.9.1
```

Il s'agissait d'une collision de tooling, pas d'un comportement produit. Les relances finales ont ete faites sequentiellement.

## 16. Correction intermediaire

Le premier passage du test direct a revele que le bloc `Attente` etait dans un `ListView` non construit sans scroll. La palette a ete basculee vers une colonne scrollable afin que tous les labels requis soient presents dans l'arbre widget.

## 17. Tests verts

`cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:01 +4: All tests passed!
```

`cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

```text
00:02 +7: All tests passed!
```

## 18. Visual Gate

`cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_42_CAPTURE_CINEMATIC_BUILDER=true --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:02 +4: All tests passed!
```

Fichier produit :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png
taille : 148681 bytes
```

## 19. Analyze

`cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematics_library_workspace_test.dart test/cinematic_builder_workspace_test.dart`

```text
Analyzing 4 items...
No issues found! (ran in 1.7s)
```

## 20. Gardes anti-scope

`git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples`

```text
sortie vide
```

`rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

```text
sortie vide
```

`rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

```text
sortie vide
```

`rg -n "add.*Step|remove.*Step|reorder|drag|drop|TimelineEditor|scrubber|keyframe|save.*timeline|copyWith\\(.*timeline" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true`

```text
sortie vide
```

Garde produit hors lot :

```text
git diff -U0 -- <modified tracked files> --no-ext-diff | rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" || true
rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" <new V1-42 files> || true
```

```text
sortie vide
```

## 21. Diff hygiene

`git diff --check`

```text
sortie vide
```

## 22. Roadmaps

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-42 DONE et recommandent :

```text
NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0
```

## 23. Non-regressions fonctionnelles

- La creation metadata-only existante reste verte.
- L'edition/suppression metadata Library reste verte.
- Les usages et diagnostics Library restent visibles.
- Les bridges legacy restent visibles et non canoniques.

## 24. Risques residuels

- Les icones Cupertino peuvent apparaitre comme placeholders dans le golden si la police d'icones n'est pas chargee par le runner de test, mais les libelles texte sont lisibles.
- La prochaine etape devra choisir comment representer une selection locale de step sans ouvrir d'authoring.

## 25. Decisions

- Pas de nouveau mode global pour eviter du churn d'etat/generation.
- Pas de dependance runtime.
- Pas de mutation de projet dans le Builder.
- Palette presente mais verrouillee.

## 26. Statut propose

`NS-SCENES-V1-42 — Cinematic Builder V0 Shell` peut etre considere DONE.

## 27. Prochain lot

`NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`

Objectif recommande : rendre le deroule existant inspectable en lecture seule, avec selection locale de bloc et details contextualises, sans operation de modification.
