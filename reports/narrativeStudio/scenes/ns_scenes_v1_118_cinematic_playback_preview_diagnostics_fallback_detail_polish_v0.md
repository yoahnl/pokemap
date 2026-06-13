# NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0

## 1. Résumé exécutif

Verdict : `NS-SCENES-V1-118` est DONE.

Le Cinematic Builder affiche maintenant un détail compact de prévisualisation quand le playback est partiel : les raisons techniques existantes du resolver walking animation et du sprite preview plan sont transformées en messages no-code, contextualisés par acteur, sans exposer `sourceRect`, `tilesetId`, `payload`, `JSON`, `actorId` ou `map_core` comme expérience principale.

Le lot reste editor-only : aucun runtime, Flame, GameState, `map_core`, scrub/seek, pathfinding, collision, nouveau renderer ou V1-119 n'a été démarré.

## 2. Gate 0

Commande initiale :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
```

Interprétation : aucun fichier dirty n'a été listé au Gate 0 ; `git diff --stat` et `git diff --name-only` étaient vides.

## 3. Fichiers lus

Règles lues : `AGENTS.md`, `agent_rules.md`, `codex_rule.md`, `skills/README.md`, `skills/using-superpowers/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`.

Fichier absent : `codex_rules.md`.

Rapports et roadmaps lus : rapports V1-115, V1-116, V1-117, V1-117-bis, `road_map_scenes.md`, `road_map_scene_builder_authoring.md`.

Core lu en lecture seule : `cinematic_preview_playback_plan.dart`, `cinematic_actor_display_preview_model.dart`, `cinematic_authoring_operations.dart`, `cinematic_asset.dart`, `project_manifest.dart`, `enums.dart`, `map_core.dart`.

Editor/tests lus : resolver walking animation, sprite preview plan/resolver/renderer, actor display overlay, playback actor overlay adapter, builder workspace, backdrop preview panel, viewport transform, Cinematics Library, tests resolver/renderer/builder/library/core ciblés.

## 4. Rappel V1-117 / V1-117-bis

V1-117 a rendu les statuts playback cohérents : `Aperçu statique`, `Lecture en cours`, `Lecture en pause`, `Animation acteur prête`, `Animation partielle`, `Aucun acteur animé`.

V1-117-bis a corrigé l'isolation des destinations `actorMove` créées depuis la palette.

V1-118 ne change ni la cadence ni l'isolation ; il explique les fallbacks restants.

## 5. Problème produit

`Animation partielle` indiquait qu'un fallback existait, mais ne disait pas quoi corriger. Un auteur ne pouvait pas distinguer rapidement : personnage non lié, animation absente, direction indisponible, sprite indisponible ou acteur non affichable.

## 6. Sources de diagnostics/fallbacks auditées

Sources consommées :

- `CinematicActorWalkingAnimationPreviewFrame.fallbackReason` : `missingSprite`, `missingCharacter`, `missingAnimation`, `missingDirection`, `emptyFrames`, `invalidFrame`, `missingPlaybackPose`, `actorNotRenderable`.
- `CinematicActorSpritePreviewActor.status` : `placeholderFallback`, `missingCharacter`, `missingTileset`, `missingIdleAnimation`, `missingDirectionFrame`, `invalidSourceRect`, `unsupported`, `hidden`.

V1-118 ne crée pas de nouveaux diagnostics globaux ; il résume ceux déjà détectables.

## 7. Décision d'architecture

Créer un helper pur editor-only :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart
```

Le Builder collecte les frames walking résolues pendant la lecture locale, construit un `CinematicPlaybackPreviewFallbackSummary`, puis le transmet au panneau preview via `CinematicPlaybackPreviewStatus`.

## 8. Modèle diagnostics no-code

Code généré principal :

```dart
enum CinematicPlaybackPreviewAnimationState { ready, partial, none }

enum CinematicPlaybackPreviewFallbackSeverity { info, warning, error }

final class CinematicPlaybackPreviewFallbackMessage {
  const CinematicPlaybackPreviewFallbackMessage({
    required this.label,
    required this.severity,
  });

  final String label;
  final CinematicPlaybackPreviewFallbackSeverity severity;
}

final class CinematicPlaybackPreviewFallbackSummary {
  const CinematicPlaybackPreviewFallbackSummary({
    required this.messages,
    required this.visibleMessages,
    required this.extraCount,
  });

  const CinematicPlaybackPreviewFallbackSummary.empty()
      : messages = const [],
        visibleMessages = const [],
        extraCount = 0;

  final List<CinematicPlaybackPreviewFallbackMessage> messages;
  final List<CinematicPlaybackPreviewFallbackMessage> visibleMessages;
  final int extraCount;

  bool get hasDetails => visibleMessages.isNotEmpty;
}
```

Le helper reste silencieux si la lecture est inactive, si l'animation est prête, ou si aucune source de fallback n'est disponible.

## 9. Wording final

Messages utilisateur ajoutés :

- `Lysa utilise une animation de secours : animation de marche indisponible.`
- `Lysa utilise une pose fixe : animation de marche indisponible.`
- `Lysa utilise une autre direction : direction d’animation indisponible.`
- `Lysa utilise un repère visuel : sprite acteur indisponible.`
- `Lysa utilise un repère visuel : personnage non lié.`
- `Lysa utilise un repère visuel : apparence acteur à compléter.`
- `Lysa utilise une pose fixe : animation de repos indisponible.`
- `Lysa reste en pose fixe : position de preview indisponible.`
- `Prévisualisation partielle : certains acteurs restent en pose fixe.`
- `Aucun acteur ne possède encore d’animation exploitable pour cette prévisualisation.`

## 10. Sévérités

- `info` : fallback non bloquant ou absence de source animée exploitable.
- `warning` : animation, direction, personnage ou sprite manquant mais preview encore lisible.
- `error` : acteur non affichable si le système l'expose déjà.

## 11. Intégration UI

Le détail apparaît sous les badges du panneau `Carte du projet (statique)` / preview, près de `Animation partielle`.

Le bloc visible s'appelle `Détails de prévisualisation`. Il utilise `context.pokeMapColors`, `PokeMapTone` et les primitives existantes du Builder. Aucune couleur hardcodée n'a été ajoutée.

Le layout historique est conservé quand il n'y a pas de détail : le `Wrap` de badges est retourné tel quel. La `Column` enrichie n'est utilisée que quand `fallbackSummary.hasDetails` est vrai.

## 12. Limite des messages visibles

Maximum 3 messages visibles. Si plus de trois messages existent, l'UI affiche :

```text
+N autre(s) point(s) à vérifier
```

## 13. Cas Animation prête

`Animation acteur prête` n'affiche aucun détail fallback.

Test : `V1-118 ready animation does not show fallback details`.

## 14. Cas Animation partielle

`Animation partielle` affiche un détail no-code. Exemple validé par test et Visual Gate :

```text
Lysa utilise une animation de secours : animation de marche indisponible.
```

## 15. Cas Aucun acteur animé

Le helper fournit le message no-code quand un plan acteur existe mais qu'aucune animation exploitable n'est détectée :

```text
Aucun acteur ne possède encore d’animation exploitable pour cette prévisualisation.
```

Il reste silencieux si aucun plan/fallback source n'existe, afin de ne pas inventer un diagnostic et de préserver les anciens harness de test.

## 16. Non-objectifs confirmés

Non démarrés : V1-119, scrub/seek, drag playhead, runtime cinematic playback, Flame, GameState, PlayableMapGame, SceneRuntimeExecutor, CinematicRuntimeAdapter, map_runtime, map_gameplay, pathfinding, collision, route recalculation, manual path recalculation, actorMove interpolation recalculation, nouvelle cadence, nouvelle animation, nouveau renderer, timer, AnimationController, mutation `CinematicAsset`, mutation `ProjectManifest`, mutation `MapData`, asset produit, Selbrume hardcodé.

## 17. Hygiène de diff

Fichiers touchés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart` : helper no-code editor-only.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` : collecte des walking frames et passage du résumé au statut preview.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart` : affichage compact du détail fallback.
- `packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart` : tests purs du mapping/capping.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart` : tests widget V1-118 et stabilisation d'un test V1-116 sur déplacement réel plutôt que direction écran fragile.
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png` : Visual Gate.
- `reports/narrativeStudio/scenes/road_map_scenes.md` et `road_map_scene_builder_authoring.md` : V1-118 DONE, V1-119 recommandé.
- ce rapport et l'Evidence Pack.

Confirmation : pas de format global ; formatage ciblé seulement. Aucun fichier `packages/map_core`, runtime, gameplay, battle, examples, assets ou Selbrume n'a été modifié.

## 18. Tests ajoutés/modifiés

Ajout :

- `test/cinematic_playback_preview_fallback_summary_test.dart`

Ajouts V1-118 dans `test/cinematic_builder_workspace_test.dart` :

- `V1-118 ready animation does not show fallback details`
- `V1-118 partial animation shows no-code fallback details without mutation`
- `V1-118 fallback details remain visible while playback is paused`
- `captures V1-118 cinematic playback preview diagnostics fallback detail polish visual gate`

Stabilisation :

- `V1-116 manual path actorMove renders walking sprite frame while moving` vérifie désormais un déplacement réel en distance d'écran, pas uniquement `dy > start`.

## 19. Tests exécutés

Depuis `packages/map_editor` :

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
Résultat : 00:01 +13: All tests passed!

flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
Résultat : 00:01 +21: All tests passed!

flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
Résultat : 00:01 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
Résultat : 00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
Résultat : 00:04 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
Résultat : 00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
Résultat : 00:04 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
Résultat : 00:40 +236: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
Résultat : 00:06 +26: All tests passed!
```

Depuis `packages/map_core` :

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
Résultat : 00:00 +12: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
Résultat : 00:00 +27: All tests passed!

dart analyze
Résultat : Analyzing map_core... No issues found!
```

## 20. Analyse statique

Commande :

```bash
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart \
  test/cinematic_actor_walking_animation_preview_resolver_test.dart \
  test/cinematic_actor_sprite_preview_renderer_test.dart \
  test/cinematic_builder_workspace_test.dart \
  test/cinematic_playback_preview_fallback_summary_test.dart
```

Sortie :

```text
Analyzing 11 items...
77 issues found. (ran in 1.3s)
Exit code : 0 avec --no-fatal-infos.
Nature : infos prefer_const / unnecessary_const existantes dans les fichiers de tests et le Builder.
```

## 21. Build macOS debug

Commande :

```bash
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 22. Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
```

Preuves :

```text
-rw-r--r--  1 karim  staff   222K Jun 13 17:58 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
eea01b4389c922c31d2dab4dabcc756ede2d93c2326549d2574549394fa20b9b  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
```

Validation visuelle : builder ouvert, preview visible, timeline visible, lecture active à temps non nul, `Animation partielle`, bloc `Détails de prévisualisation`, message no-code visible, aucun label runtime/Flame/GameState/V1-119 visible.

## 23. Checks anti-scope

Commande diff anti-scope :

```bash
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|scrub|seek|V1-119" || true
```

Sortie : occurrences uniquement documentaires dans roadmaps, liées à la recommandation V1-119 et aux non-objectifs. Aucune occurrence code produit runtime/Flame/GameState.

Recherche UX technique :

```bash
rg -n "sourceRect|tilesetId|payload|JSON|actorId|map_core" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart || true
```

Sortie : occurrences internes existantes dans imports, helpers, clés techniques, fallback labels anciens et logique de résolution. Les tests V1-118 vérifient que les messages visibles du bloc fallback ne contiennent pas ces termes.

Anti-scope diff :

```text
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
Sortie : <vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_119*' -print
Sortie : <vide>
```

## 24. Roadmaps mises à jour

Fichiers :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Changements :

- V1-118 ajouté en `DONE`.
- Prochain lot exact recommandé : `NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract`.
- V1-119 est recommandé uniquement, non démarré.

## 25. Git final

Les commandes finales exactes sont reprises dans l'Evidence Pack V1-118, section Git final.

## 26. Risques restants

- Le mapping est volontairement borné aux diagnostics déjà disponibles ; certains cas rares de fallback map/stage peuvent rester expliqués par les diagnostics historiques.
- Le détail est visible uniquement quand il y a une source de fallback exploitable ; si un harness ou un écran ne fournit pas de plan sprite, aucun message n'est inventé.
- Le wording est no-code, mais il pourrait encore bénéficier de micro-copy orientée action dans un futur polish.

## 27. Auto-critique

Les messages sont plus compréhensibles pour un non-développeur que les raisons internes, surtout `animation de marche indisponible`, `personnage non lié`, `direction d’animation indisponible`.

Le détail est assez discret : il n'envahit pas la preview et reste sous les badges. Le risque inverse existe : sur un petit viewport, l'auteur peut le manquer.

Les détails techniques sont absents du bloc visible V1-118, mais des anciens détails internes restent dans d'autres zones/debug du Builder.

V1-119 scrub/seek prep est le bon prochain lot si aucun bug urgent de preview n'est signalé : les statuts, mouvements, animations et diagnostics ont maintenant un socle editor-only cohérent.

Aucun bis n'est recommandé.

## 28. Verdict final

```text
NS-SCENES-V1-118 : DONE.
Playback preview diagnostics polish : actif.
Fallback details : lisibles et no-code.
Animation partielle : expliquée.
Animation prête : propre.
Aucun acteur animé : expliqué.
Détails techniques UX principale : absents.
Runtime / Flame / GameState : non touchés.
map_core : non modifié.
Scrub / seek : non démarré.
V1-119 : recommandé, non démarré.
```

## 29. Prochain lot recommandé

```text
NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract
```
