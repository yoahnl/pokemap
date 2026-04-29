# Lot TSX-5 — Optional Mistral grouping assistant for TSX animations V0

## 1. Verdict

TSX-5 partiellement validé par tests automatisés.

Le lot ajoute un assistant Mistral optionnel pour proposer un mapping
`SurfaceVariantRole -> ProjectSurfaceAnimation.id` depuis des animations TSX
sélectionnées. Il ne crée pas de preset, ne modifie pas le catalogue tant que
l'utilisateur n'accepte pas une suggestion dans le draft local, ne touche pas
aux frames TSX et ne fait aucun appel IA en test.

Limite : aucune QA interactive macOS n'a été lancée pour manipuler le browser
réel. La validation est donc automatisée.

## 2. Audit initial

Commandes initiales :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "TiledTsx|SurfacePresetDraft|SurfacePresetBuilder|AnimationBrowser|selectedAnimation|ProjectSurfaceAnimation|SurfaceVariantRole|roleAnimation|Mistral|reasoning_effort|response_format|json_schema|thinking|extractMistralAssistantTextContent|MISTRAL_API_KEY|resolveEditorMistralApiKey" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
```

Résultat utile :

- `pwd` : `/Users/karim/Project/pokemonProject`
- `ctx` indisponible dans le shell (`command -v ctx` sans résultat).
- Worktree initial déjà sale hors périmètre, uniquement dans
  `packages/map_runtime/test/*`.
- TSX-3 existe : `tiled_tsx_animation_browser.dart` + modèles browser,
  sélection locale `_selectedIds`, preview `TiledTsxSurfaceAnimationPreview`.
- TSX-4 existe : `tiled_tsx_surface_preset_draft.dart`, builder explicite
  `TiledTsxSurfacePresetDraft`, validation, construction de
  `ProjectSurfacePreset` et ajout au work catalog via callback.
- Parser Mistral robuste existant :
  `surface_studio_mistral_response_parser.dart` supporte `content String` et
  `content List`, concatène les chunks `text` et ignore les chunks `thinking`.
- Vision pack existant avant TSX-5 : atlas/colonnes Surface Studio, pas un pack
  animation TSX sélectionnée.
- Clé Mistral existante : `resolveEditorMistralApiKey(ProjectSettings?)`
  lit `ProjectSettings.mistralApiKey`, puis `MISTRAL_API_KEY`.

## 3. Ce que TSX-3 et TSX-4 avaient réellement livré

TSX-3 :

- browser d'animations TSX visible ;
- recherche par id/nom/tile id ;
- sélection locale d'animations ;
- preview frame par frame basée sur `ProjectSurfaceAnimation.timeline.frames` ;
- aucun manifest muté par la sélection.

TSX-4 :

- draft local `role -> animationId` ;
- `isolated` obligatoire ;
- construction de `ProjectSurfacePreset` uniquement après mapping explicite ;
- ajout au work catalog seulement via action "Créer le preset" ;
- aucun rôle deviné automatiquement.

## 4. Modèles / fonctions ajoutés

Fichiers ajoutés :

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_animation_pack.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_prompt_builder.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart`

Principaux modèles :

- `TiledTsxMistralGroupingRequest`
- `TiledTsxRoleAnimationSuggestion`
- `TiledTsxMistralGroupingResult`
- `TiledTsxAnimationGroupingSuggester`
- `TiledTsxMistralAnimationGroupingSuggester`

## 5. Vision pack animations

Le pack TSX-5 construit :

- une contact sheet des animations sélectionnées ;
- des cartes par animation avec id lisible et frames échantillonnées ;
- un JSON metadata contenant `animationId`, `frameCount`, `totalDurationMs`,
  `firstFrame`, `sampledFrames`.

Le pack utilise les frames déjà importées depuis `ProjectSurfaceAnimation`.
Il ne reconstruit pas les animations depuis des colonnes/lignes supposées.

Le test vérifie :

- data URL PNG créée ;
- une card par animation sélectionnée ;
- metadata sans chemin local sensible ;
- metadata sans clé API.

## 6. Prompt Mistral

Le prompt TSX-5 impose :

- "Do not infer or change frames" ;
- "Only propose mappings from SurfaceVariantRole to existing animationId" ;
- pas de `tileId` brut ;
- pas de coordonnées atlas brutes ;
- abstention préférée aux mappings faux ;
- JSON uniquement ;
- pas de chain-of-thought exposée.

Rôles autorisés envoyés :

```text
isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross
```

Schéma attendu :

```json
{
  "suggestions": [
    {
      "role": "isolated",
      "animationId": "existing-animation-id",
      "confidence": "high",
      "evidenceAnimationIds": ["existing-animation-id"],
      "reason": "Short visual evidence."
    }
  ],
  "rejectedAnimationIds": ["existing-animation-id"],
  "warnings": ["Ambiguity note."]
}
```

## 7. Provider Mistral

Provider ajouté :

```text
TiledTsxMistralAnimationGroupingSuggester
```

Paramètres envoyés :

- `model = mistral-large-latest`
- `temperature = 0.1`
- `reasoning_effort = high`
- `response_format.type = json_schema`
- body avec prompt + une image contact sheet

Sécurité :

- clé uniquement dans header `Authorization` ;
- clé absente du body ;
- HTTP client injectable ;
- aucun réseau en test.

## 8. Parser / validation

Le parser TSX-5 réutilise :

- `extractMistralAssistantTextContent`
- `extractFirstJsonObjectFromMistralText`

Donc :

- `content String` supporté ;
- `content List` supporté ;
- chunks `thinking` ignorés ;
- seul `text` est parsé.

Validation locale :

- rôle inconnu rejeté ;
- `animationId` inconnu ou non sélectionné rejeté ;
- confidence inconnue rejetée ;
- rôle dupliqué rejeté ;
- animation dupliquée rejetée ;
- `evidenceAnimationIds` inconnus rejetés ;
- warnings conservés.

## 9. UI / review

Le browser TSX expose :

- bouton `Proposer un mapping avec Mistral` ;
- disabled sans sélection ;
- disabled sans clé Mistral ;
- message clé absente ;
- confirmation obligatoire avant envoi ;
- spinner/progress pendant l'appel ;
- review "Suggestions Mistral" ;
- accepter/rejeter par ligne ;
- appliquer les suggestions fiables ;
- tout appliquer.

L'acceptation remplit uniquement les champs du draft TSX-4. Le bouton
`Créer le preset` reste l'action séparée et explicite.

## 10. Tests

Commandes exécutées :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_mistral_grouping_prompt_test.dart --no-pub --reporter expanded
```

Résultat final :

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_mistral_grouping_suggester_test.dart --no-pub --reporter expanded
```

Résultat final :

```text
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart --no-pub --reporter expanded
```

Résultat final :

```text
00:01 +3: All tests passed!
```

Régressions TSX :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart --no-pub --reporter expanded
```

```text
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_animation_importer_test.dart --no-pub --reporter expanded
```

```text
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animation_browser_test.dart --no-pub --reporter expanded
```

```text
00:01 +7: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_preset_builder_test.dart --no-pub --reporter expanded
```

```text
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart --no-pub --reporter expanded
```

```text
00:01 +1: All tests passed!
```

Tous les tests Surface Studio :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

```text
00:22 +398: All tests passed!
```

## 11. Analyze

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
```

Résultat :

```text
No issues found! (ran in 1.8s)
```

## 12. Non-objectifs confirmés

- Aucun `map_gameplay` modifié.
- Aucun `map_runtime` modifié par ce lot.
- Aucun `map_battle` modifié.
- Aucun PixelLab.
- Aucun MCP.
- Aucun appel IA réel en test.
- Aucun nouveau secret.
- Aucun preset créé automatiquement.
- Aucun mapping appliqué automatiquement.
- Aucune frame TSX modifiée ou devinée.
- Aucun gameplay.

## 13. Limites restantes

- Pas de QA interactive macOS.
- Le pack image est une première contact sheet V0 ; il faudra probablement
  améliorer sa lisibilité pour de gros sets.
- Le provider envoie une seule contact sheet, pas encore plusieurs pages si la
  sélection est très grande.
- Le browser TSX reste dans le drawer avancé Surface Studio.

## 14. Roadmap suivante

Suites possibles :

- TSX-6 — Improve TSX region picker / visual grouping UX.
- TSX-6 — Paginated Mistral animation contact sheets.
- TSX-6 — Generated missing tile completion architecture V0, seulement après
  validation de l'import TSX/browser/builder/assistant.

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat au moment du rapport :

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_animation_pack.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_prompt_builder.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_prompt_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_suggester_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
?? reports/surface/surface_studio_tiled_tsx_mistral_grouping_v0.md
```

Les fichiers `packages/map_runtime/test/*` sont des modifications
préexistantes hors périmètre TSX-5 et n'ont pas été touchés par ce lot.
