# NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0

## 1. Résumé exécutif

Statut : `NS-SCENES-V1-126 : DONE`.

V1-126 implémente côté `map_core` le socle pur du bloc `actorEmote` :

- le kind existant `CinematicTimelineStepKind.actorEmote` est réutilisé ;
- aucun second système d’emote n’est créé ;
- un catalogue V0 typé expose des IDs stables, labels no-code français, descriptions courtes, atlas candidats et rectangles de frames `16 x 16` ;
- les opérations pures authoring ajoutent et mettent à jour un bloc `actorEmote` authoring-owned ;
- `actorId` reste dans le champ modèle existant `CinematicTimelineStep.actorId` ;
- `emoteId` est stocké en metadata `actor.emoteId` ;
- les diagnostics core détectent acteur manquant, acteur inconnu, emote manquante, emote inconnue et durée invalide ;
- les JSON existants restent lisibles et backward-compatible ;
- l’état playback actif des emotes est volontairement reporté à V1-127.

Aucun fichier `map_editor`, `map_runtime`, `map_gameplay`, `map_battle`, `examples`, `assets`, `selbrume`, `pubspec.yaml`, `emotions.png` ou `emotions2.png` n’a été modifié.

## 2. Gate 0

Commande :

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
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7 feat: cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
```

Interprétation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0. Aucun `selbrume/project.json` dirty n’était présent au début.

## 3. Fichiers lus

Règles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Fichier absent :

- `codex_rules.md`

Rapports récents lus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Rapports acteurs/sprites/stage lus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md`

Code core lu :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`

Tests core lus :

- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`

Fichiers editor lus en lecture seule, non modifiés :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`

## 4. Rappel V1-125

V1-125 a cadré le futur système d’emotes cinématiques autour de deux fichiers racine :

- `/Users/karim/Project/pokemonProject/emotions.png`
- `/Users/karim/Project/pokemonProject/emotions2.png`

Décisions reprises :

- ces fichiers restent des assets candidats ;
- ils ne doivent pas être chargés depuis la racine du repo ;
- le chemin produit futur recommandé est `assets/cinematics/emotes/` ;
- le système passe par un catalogue typé avec IDs stables et labels no-code ;
- le bloc futur est `actorEmote` ;
- les emotes V0 sont attachées aux acteurs ;
- les FX libres restent séparés et reportés.

## 5. Audit actorEmote existant

Commande :

```bash
rg -n "actorEmote" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
```

Sortie :

```text
packages/map_core/lib/src/models/cinematic_asset.dart:8:  actorEmote,
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:666:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:800:      case CinematicTimelineStepKind.actorEmote:
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart:1127:    CinematicTimelineStepKind.actorEmote ||
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:296:    CinematicTimelineStepKind.actorEmote =>
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart:383:    CinematicTimelineStepKind.actorEmote =>
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:11990:    CinematicTimelineStepKind.actorEmote => 'Émotion acteur',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12499:    CinematicTimelineStepKind.actorEmote => CupertinoIcons.person_crop_circle,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:12560:    CinematicTimelineStepKind.actorEmote =>
```

Verdict : `actorEmote` existait comme kind et comme cas de classification/placeholder, mais sans modèle métier complet. Il n’y avait pas encore de catalogue typé, pas d’opérations pures add/update dédiées, pas de metadata `emoteId` standardisée, et pas de diagnostics emote dédiés.

## 6. Audit assets racine

Commande :

```bash
ls -lh /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
file /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
shasum -a 256 /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
sips -g pixelWidth -g pixelHeight /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
/Users/karim/Project/pokemonProject/emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  /Users/karim/Project/pokemonProject/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png
  pixelWidth: 128
  pixelHeight: 48
/Users/karim/Project/pokemonProject/emotions2.png
  pixelWidth: 128
  pixelHeight: 48
```

Confirmation :

- les assets sont toujours candidats ;
- ils restent à la racine dans ce lot ;
- V1-126 ne les charge pas depuis le code ;
- V1-126 ne les déplace pas ;
- V1-126 ne les copie pas ;
- V1-126 ne modifie aucun `pubspec.yaml`.

## 7. Décision d’architecture

Décision : V1-126 reste `map_core` pur.

Le catalogue est placé dans :

```text
packages/map_core/lib/src/models/cinematic_emote_catalog.dart
```

Raison : le catalogue décrit un contrat de modèle stable, pas un read model calculé depuis une cinématique. Il est exporté par `map_core.dart` pour que les lots suivants puissent le consommer sans dépendance Flutter.

Contradictions et arbitrages :

- Le prompt V1-126 interdit les commentaires de code.
- `codex_rule.md` demande des commentaires dans les fichiers créés.
- La demande directe du lot V1-126 est plus spécifique : aucun commentaire Dart nouveau n’a été ajouté.
- Le prompt demande aussi une recherche anti-scope avec `V1-127` en sortie vide, mais demande de pointer les roadmaps vers V1-127. Le diff documentaire contient donc naturellement `V1-127`; le diff code, lui, ne contient aucune implémentation V1-127.

## 8. Catalogue emote V0

Catalogue créé :

- atlases : `defaultReactions`, `neutralBubbles`
- asset keys futures : `assets/cinematics/emotes/emotions.png`, `assets/cinematics/emotes/emotions2.png`
- dimensions atlas : `128 x 48`
- dimensions frames : `16 x 16`
- emotes V0 : `exclamation`, `alert`, `anger`, `thought`, `question`, `music`, `idea`, `heart`, `sweat`, `silence`, `neutral`

Les IDs sont sans accents et stables. Les labels sont français et no-code. Les rects sont validés par tests contre les bornes `128 x 48`.

Contenu complet du fichier créé :

```dart
import 'package:meta/meta.dart' show immutable;

const cinematicEmoteDefaultReactionsAtlasId = 'defaultReactions';
const cinematicEmoteNeutralBubblesAtlasId = 'neutralBubbles';
const cinematicEmoteDefaultReactionsAssetKey =
    'assets/cinematics/emotes/emotions.png';
const cinematicEmoteNeutralBubblesAssetKey =
    'assets/cinematics/emotes/emotions2.png';
const cinematicDefaultActorEmoteId = 'exclamation';

@immutable
final class CinematicEmoteAtlas {
  const CinematicEmoteAtlas({
    required this.id,
    required this.label,
    required this.assetKey,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
  });

  final String id;
  final String label;
  final String assetKey;
  final int width;
  final int height;
  final int frameWidth;
  final int frameHeight;
}

@immutable
final class CinematicEmoteFrameRect {
  const CinematicEmoteFrameRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  bool fitsInside(CinematicEmoteAtlas atlas) {
    return x >= 0 &&
        y >= 0 &&
        width > 0 &&
        height > 0 &&
        x + width <= atlas.width &&
        y + height <= atlas.height;
  }
}

@immutable
final class CinematicEmoteCatalogEntry {
  const CinematicEmoteCatalogEntry({
    required this.id,
    required this.label,
    required this.description,
    required this.atlasId,
    required this.frame,
  });

  final String id;
  final String label;
  final String description;
  final String atlasId;
  final CinematicEmoteFrameRect frame;
}

const cinematicEmoteAtlases = <CinematicEmoteAtlas>[
  CinematicEmoteAtlas(
    id: cinematicEmoteDefaultReactionsAtlasId,
    label: 'Réactions',
    assetKey: cinematicEmoteDefaultReactionsAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
  CinematicEmoteAtlas(
    id: cinematicEmoteNeutralBubblesAtlasId,
    label: 'Bulles neutres',
    assetKey: cinematicEmoteNeutralBubblesAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
];

const cinematicEmoteCatalog = <CinematicEmoteCatalogEntry>[
  CinematicEmoteCatalogEntry(
    id: cinematicDefaultActorEmoteId,
    label: 'Surprise',
    description: 'Réaction forte ou découverte soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'alert',
    label: 'Alerte',
    description: 'Attention immédiate.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 16, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'anger',
    label: 'Colère',
    description: 'Agacement ou colère courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'thought',
    label: 'Pensée',
    description: 'Pensée ou réflexion.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'question',
    label: 'Question',
    description: 'Interrogation courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'music',
    label: 'Musique',
    description: 'Chant, joie ou note musicale.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'idea',
    label: 'Idée',
    description: 'Compréhension ou idée soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 48, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'heart',
    label: 'Coeur',
    description: 'Affection ou joie douce.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'sweat',
    label: 'Gêne',
    description: 'Malaise, peur légère ou embarras.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'silence',
    label: 'Silence',
    description: 'Hésitation ou silence.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 96, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'neutral',
    label: 'Bulle neutre',
    description: 'Bulle neutre ou fallback.',
    atlasId: cinematicEmoteNeutralBubblesAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
  ),
];

CinematicEmoteAtlas? cinematicEmoteAtlasById(String? atlasId) {
  final id = atlasId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final atlas in cinematicEmoteAtlases) {
    if (atlas.id == id) {
      return atlas;
    }
  }
  return null;
}

CinematicEmoteCatalogEntry? cinematicEmoteCatalogEntryById(String? emoteId) {
  final id = emoteId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final entry in cinematicEmoteCatalog) {
    if (entry.id == id) {
      return entry;
    }
  }
  return null;
}

bool isCinematicEmoteIdKnown(String? emoteId) {
  return cinematicEmoteCatalogEntryById(emoteId) != null;
}
```

## 9. Modèle actorEmote

Le modèle réutilise :

```text
CinematicTimelineStepKind.actorEmote
```

Stockage retenu :

- `actorId` : champ `CinematicTimelineStep.actorId`
- `emoteId` : metadata `actor.emoteId`
- `durationMs` : champ `CinematicTimelineStep.durationMs`

Constantes ajoutées :

```dart
const cinematicTimelineActorEmoteBlockMetadataValue = 'actorEmote';
const cinematicTimelineActorEmoteEmoteIdMetadataKey = 'actor.emoteId';
const cinematicTimelineDefaultActorEmoteDurationMs = 800;
```

Helpers ajoutés :

```dart
bool isCinematicTimelineActorEmoteStep(CinematicTimelineStep step)
String? cinematicTimelineActorEmoteActorIdOf(CinematicTimelineStep step)
String? cinematicTimelineActorEmoteEmoteIdOf(CinematicTimelineStep step)
```

## 10. Metadata / JSON backward-compatibility

Le JSON existant reste compatible car aucun champ requis n’est ajouté au modèle `CinematicTimelineStep`.

Un ancien JSON `actorEmote` sans metadata reste lisible par `CinematicTimelineStep.fromJson`. Il n’est simplement pas traité comme bloc authoring-owned par `isCinematicTimelineActorEmoteStep`, ce qui évite de casser les données historiques tout en gardant une frontière propre pour les opérations V0.

Test ajouté :

```text
V1-126 actorEmote JSON roundtrip preserves actor and emote ids
```

Test ajouté pour legacy :

```text
V1-126 legacy actorEmote without metadata remains readable but not authoring-owned
```

## 11. Opérations pures

Opérations ajoutées :

```dart
CinematicTimelineActorEmoteStepResult addCinematicTimelineActorEmoteStep(...)
CinematicTimelineStepUpdateResult updateCinematicTimelineActorEmoteStep(...)
```

Comportement :

- `add` crée un step `actorEmote` authoring-owned ;
- `actorId` doit référencer un acteur requis ;
- `emoteId` doit exister dans le catalogue ;
- l’emote par défaut est `exclamation` ;
- la durée par défaut est `800 ms` ;
- `update actor` conserve `emoteId` ;
- `update emote` conserve `actorId` ;
- `update` refuse les emotes inconnues ;
- la suppression est couverte par `removeCinematicTimelineAuthoringStep`, car `isCinematicTimelineAuthoringStep` inclut maintenant `actorEmote`.

Hunk pertinent :

```diff
+CinematicTimelineActorEmoteStepResult addCinematicTimelineActorEmoteStep(...)
+CinematicTimelineStepUpdateResult updateCinematicTimelineActorEmoteStep(...)
+bool isCinematicTimelineActorEmoteStep(CinematicTimelineStep step)
+String? cinematicTimelineActorEmoteActorIdOf(CinematicTimelineStep step)
+String? cinematicTimelineActorEmoteEmoteIdOf(CinematicTimelineStep step)
+CinematicEmoteCatalogEntry _requireEmoteEntry(String emoteId)
```

## 12. Diagnostics

Diagnostics ajoutés :

```dart
cinematicActorEmoteMissingActorRef
cinematicActorEmoteUnknownActorRef
cinematicActorEmoteMissingEmoteRef
cinematicActorEmoteUnknownEmoteRef
cinematicActorEmoteInvalidDuration
```

Messages no-code :

- `Une émotion doit référencer un acteur requis.`
- `Une émotion référence un acteur inconnu.`
- `Une émotion à afficher doit être choisie.`
- `Une émotion référence un choix indisponible.`
- `Une émotion doit durer entre 100 ms et 30000 ms.`

Les messages n’exposent pas `frameIndex`, `sourceRect` ou `atlasRect`.

## 13. Lane / labels / summary

Le lane read model classait déjà `actorEmote` dans une lane acteur si `actorId` existe. Aucun changement UI ou lane n’a été nécessaire.

Le label authoring généré par les opérations est humain :

```text
Professor affiche Question
Lysa affiche Coeur
```

Un polish plus riche côté timeline UI est reporté aux lots UI/playback suivants.

## 14. Playback state ajouté ou reporté

Décision : playback emote actif reporté à V1-127.

Raison : V1-126 doit poser le modèle core, le catalogue, les opérations et les diagnostics sans démarrer l’état `frameAt(timeMs)` des emotes. Un test de frontière vérifie que `actorEmote` reste unsupported dans le playback plan tant que V1-127 n’a pas exposé l’état actif.

Test ajouté :

```text
V1-126 actorEmote remains unsupported until emote playback state
```

## 15. Non-objectifs confirmés

Non démarrés :

- UI Emote ;
- palette Emote ;
- inspecteur Emote ;
- renderer Emote ;
- overlay Emote ;
- preview Emote ;
- runtime cinematic playback ;
- Flame ;
- GameState ;
- SceneRuntimeExecutor ;
- CinematicRuntimeAdapter ;
- pathfinding ;
- collision ;
- audio runtime ;
- déplacement/copie d’assets ;
- modification `pubspec.yaml` ;
- screenshot ;
- Visual Gate ;
- V1-127.

## 16. Hygiène de diff

Fichiers créés :

- `packages/map_core/lib/src/models/cinematic_emote_catalog.dart` : catalogue core pur V0.
- `packages/map_core/test/cinematic_emote_catalog_test.dart` : tests du catalogue.
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md` : rapport principal.
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md` : Evidence Pack.

Fichiers modifiés :

- `packages/map_core/lib/map_core.dart` : export du catalogue.
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` : opérations et helpers actorEmote.
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart` : diagnostics actorEmote.
- `packages/map_core/test/cinematic_authoring_operations_test.dart` : tests opérations/JSON.
- `packages/map_core/test/cinematic_diagnostics_test.dart` : tests diagnostics.
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart` : test frontière playback reporté.
- `reports/narrativeStudio/scenes/road_map_scenes.md` : V1-126 DONE, V1-127 recommandé.
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-126 DONE, V1-127 recommandé.

Confirmation :

- pas de reformat global conservé ;
- `map_editor` intact ;
- runtime intact ;
- Flame/GameState absents du diff code ;
- assets et pubspec intacts.

## 17. Tests RED

Avant implémentation, les tests V1-126 ont échoué comme attendu.

Commande :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart
```

Signal RED :

```text
Failed to load "test/cinematic_emote_catalog_test.dart":
Error: Undefined name 'cinematicEmoteCatalog'.
Error: Undefined name 'cinematicDefaultActorEmoteId'.
Error: Method not found: 'cinematicEmoteAtlasById'.
Error: Method not found: 'cinematicEmoteCatalogEntryById'.
Error: Method not found: 'isCinematicEmoteIdKnown'.

Failed to load "test/cinematic_authoring_operations_test.dart":
Error: Method not found: 'addCinematicTimelineActorEmoteStep'.
Error: Method not found: 'cinematicTimelineActorEmoteEmoteIdOf'.
Error: Method not found: 'isCinematicTimelineActorEmoteStep'.
Error: Method not found: 'updateCinematicTimelineActorEmoteStep'.
Error: Undefined name 'cinematicTimelineDefaultActorEmoteDurationMs'.
Error: Undefined name 'cinematicTimelineActorEmoteBlockMetadataValue'.
Error: Undefined name 'cinematicTimelineActorEmoteEmoteIdMetadataKey'.

Failed to load "test/cinematic_diagnostics_test.dart":
Member not found: 'cinematicActorEmoteMissingActorRef'
Member not found: 'cinematicActorEmoteMissingEmoteRef'
Member not found: 'cinematicActorEmoteUnknownActorRef'
Member not found: 'cinematicActorEmoteUnknownEmoteRef'
Member not found: 'cinematicActorEmoteInvalidDuration'
```

## 18. Tests GREEN

Après implémentation, les tests ciblés V1-126 passent.

Commande :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
00:00 +147: All tests passed!
```

## 19. Tests exécutés

Depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart
```

Sortie finale :

```text
00:00 +3: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
00:00 +18: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie finale :

```text
00:00 +4: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie finale :

```text
00:00 +27: All tests passed!
```

Suite complète `map_core` :

```bash
dart test --reporter=compact > /tmp/ns_v1_126_map_core_test.log && tr '\r' '\n' < /tmp/ns_v1_126_map_core_test.log | sed '/^$/d' | tail -n 1
```

Sortie :

```text
00:06 +2511: All tests passed!
```

Depuis `packages/map_editor` :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Sortie finale :

```text
00:06 +7: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

Sortie finale :

```text
00:05 +5: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie finale :

```text
00:07 +26: All tests passed!
```

## 20. Analyse statique

Commande :

```bash
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 21. Build non lancé ou justification

Build non lancé.

Justification : aucun fichier `packages/map_editor`, `packages/map_runtime`, `examples`, asset produit ou `pubspec.yaml` n’a été modifié. Le prompt indique que le build n’est pas obligatoire si aucun fichier editor n’est modifié. La compilation du Builder est couverte par les régressions Flutter ciblées.

## 22. Checks anti-scope

Commande demandée :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\\.Image|rootBundle|decodeImage|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-127" || true
```

Résultat : des lignes documentaires `V1-127` apparaissent dans les roadmaps/rapports, parce que le prompt demande explicitement de recommander V1-127. Aucune ligne de code produit ne démarre V1-127.

Commande code-scoped :

```bash
git diff --unified=0 -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\\.Image|rootBundle|decodeImage|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-127" || true
```

Sortie :

```text
Sortie : <vide>
```

Autres checks :

```bash
git diff --name-only -- packages/map_editor
git diff --name-only -- assets emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_126*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_127*' -print
```

Sortie :

```text
Sortie : <vide>
```

## 23. Roadmaps mises à jour

Roadmaps modifiées :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Ajout :

```text
NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0 | DONE | Implémenter le modèle core authoring du bloc actorEmote et un catalogue emote V0 typé, avec IDs stables, labels no-code, frame rects validées, opérations pures et diagnostics, sans UI, renderer, runtime, Flame, GameState, déplacement d’assets ni modification pubspec.
```

Prochain lot recommandé :

```text
NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
```

Justification : après le modèle core et le catalogue, le prochain verrou propre est d’exposer les emotes actives dans `frameAt(timeMs)`, avant toute UI/renderer.

## 24. git diff --check/stat/name-only/status final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../authoring/cinematic_authoring_operations.dart  | 208 ++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart | 105 +++++++-
 .../test/cinematic_authoring_operations_test.dart  | 228 ++++++++++++++--
 .../map_core/test/cinematic_diagnostics_test.dart  | 293 +++++++++++++++++----
 .../test/cinematic_preview_playback_plan_test.dart |  46 ++++
 .../scenes/road_map_scene_builder_authoring.md     |  57 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  65 +++--
 8 files changed, 875 insertions(+), 128 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés apparaissent dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/models/cinematic_emote_catalog.dart
?? packages/map_core/test/cinematic_emote_catalog_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md
```

## 25. Risques restants

- Le mapping visuel des frames reste interprétatif : seules les frames raisonnablement identifiables sont nommées.
- Les asset keys `assets/cinematics/emotes/...` sont des clés produit futures ; elles ne sont pas encore déclarées dans `pubspec.yaml`.
- Le catalogue ne charge aucune image et ne garantit pas encore que les assets futurs existent au chemin produit.
- Les diagnostics sont prêts pour l’UI future, mais l’inspecteur Emote n’existe pas encore.
- `actorEmote` reste unsupported dans le playback preview jusqu’à V1-127.

## 26. Auto-critique

Le catalogue est robuste pour un V0 : IDs uniques, labels français, rects bornés, helpers de lookup et tests dédiés. Il reste cependant volontairement prudent : certains slots des atlas ne sont pas nommés car leur sens visuel est ambigu sans validation UX.

La metadata `actor.emoteId` est légère mais cohérente avec le modèle actuel : `actorId` est déjà un champ du step, et `durationMs` reste dans le champ durée existant. Créer une structure imbriquée aurait élargi le schéma inutilement.

Les diagnostics sont suffisants pour débloquer V1-127/V1-128, mais les libellés UI pourront être polis quand l’inspecteur affichera les choix d’emotes.

Les assets racine ne doivent pas être déplacés dans V1-126. Le bon moment pour les intégrer au chemin produit officiel sera un lot d’asset registry/UI/renderer, pas ce lot core.

Playback state avant UI reste le bon ordre : V1-127 doit exposer l’état pur avant que V1-128/V1-129 ne l’affichent.

Un bis n’est pas recommandé pour V1-126 : les critères core sont couverts et l’anti-scope code est propre. La seule contradiction vient du prompt lui-même sur la recherche `V1-127`, documentée ci-dessus.

## 27. Verdict final

```text
NS-SCENES-V1-126 : DONE.
Emote Core Model / Asset Catalog : implémenté.
actorEmote existant : réutilisé.
Catalogue V0 : présent et testé.
actorId / emoteId : stockés/lus.
Diagnostics : présents.
JSON backward-compatible : oui.
UI / renderer : non démarrés.
Runtime / Flame / GameState : non touchés.
map_editor : non modifié.
Assets racine : non déplacés, non copiés.
pubspec : non modifié.
Screenshot / Visual Gate : absents.
V1-127 : recommandé, non démarré.
```

## 28. Prochain lot recommandé

```text
NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
```

Objectif recommandé : exposer les emotes actives dans `frameAt(timeMs)` via un état playback preview pur, avec `activeStepId`, `actorId`, `emoteId`, label/catalog entry et progress, sans UI/renderer.
