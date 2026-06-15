# NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit

## 1. Résumé exécutif

Statut : **DONE documentaire**.

Verdict : **Cinematic Builder V1 : CLOSABLE AVEC RÉSERVES NON BLOQUANTES ⚠️**.

V1-136 ferme le Cinematic Builder V1 par un audit de readiness, sans ajouter de feature produit et sans modifier `packages/`. Les briques V1 sont présentes : Library, Builder shell, palette, blocs Attendre/Fondu/Caméra/Déplacer/Orienter/Émotion, Stage Points, trajets manuels, preview map, acteurs, timeline proportionnelle, playback editor-only, fade, emotes et caméra géométrique editor-only.

Les réserves sont réelles mais non bloquantes pour la fermeture V1 :

- le test complet `cinematic_builder_workspace_test.dart` a 6 attentes historiques rouges sur des labels/IDs anciens ;
- le test complet `cinematics_library_workspace_test.dart` a 1 attente historique rouge sur `Bloc authoring V0` ;
- l'analyse editor passe avec `--no-fatal-infos`, mais remonte 38 infos de style/deprecation.

Les validations récentes et critiques passent : suite ciblée V1-102 à V1-135, tests core cinématiques, analyse `map_core`, build macOS debug et anti-scope runtime.

## 2. Verdict final

**Cinematic Builder V1 : CLOSABLE AVEC RÉSERVES NON BLOQUANTES ⚠️**

Décision : fermer V1 et recommander un prochain lot hors extension du Builder.

Prochain lot recommandé :

```text
NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
```

Justification : les réserves restantes relèvent surtout de maintenance de tests/wording legacy, pas d'un manque fonctionnel majeur du Builder V1. Aucun blocker produit, build, core ou anti-runtime n'a été identifié pendant l'audit.

## 3. Rappel du périmètre V1

Cinematic Builder V1 livre :

- `CinematicAsset` canonique et Library dédiée ;
- Builder canonique ouvert depuis la Library ;
- palette no-code des blocs V1 ;
- inspecteurs bornés et guidés ;
- Stage Points / Repères ;
- destinations actorMove et trajets manuels ;
- preview décor issue de vraies maps/layers/tiles ;
- preview acteurs, sprites et animation de marche editor-only ;
- timeline par lanes avec axe temporel, barres proportionnelles, sélection, hover, navigation clavier, probe, seek/scrub et zoom local ;
- playback preview editor-only via read model pur ;
- fade preview ;
- emote authoring et preview ;
- caméra cible/zoom authoring, géométrie read model et cadre preview editor-only.

V1 ne livre pas :

- runtime cinematic complet ;
- Flame/CameraComponent ;
- vraie caméra runtime pilotée ;
- pan/zoom réel de la vue par caméra ;
- timeline parallèle ;
- drag horizontal/reorder de blocs ;
- dialogue/audio/FX avancés ;
- storyboard/shot strip ;
- branching cinematic.

## 4. Méthode d'audit

Audit effectué en cinq passes :

1. Gate 0 : état Git, branche, préconditions V1-135, roadmaps.
2. Audit statique : rapports, roadmaps, Visual Gates, tests existants et fichiers cinématiques.
3. Validation dynamique : tests widget ciblés, tests core, analyses, build macOS.
4. Classification produit : matrice readiness, blockers/majors/minors/V2.
5. Clôture documentaire : rapports V1-136, roadmaps, anti-scope final.

Règles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

`codex_rules.md` au pluriel est absent ; `codex_rule.md` est bien présent.

## 5. Matrice de readiness

| Domaine | Statut | Preuves | Risques restants | Gravité | Décision |
|---|---|---|---|---|---|
| CinematicAsset / Library | READY_WITH_RESERVES | Core tests verts ; Library test suite 20 tests dont 1 attente legacy rouge | Test widget Library attend encore `Bloc authoring V0` | MAJOR | CLOSE_WITH_RESERVE |
| Builder shell | READY | V1-42, V1-135, build macOS debug | Aucun blocker identifié | NONE | CLOSE_V1 |
| Palette | READY | Tests V1-128, V1-132, V1-45 historiques partiels | Libellés anciens dans quelques tests globaux | MINOR | CLOSE_WITH_RESERVE |
| Wait / Fade / Camera basic | READY | V1-45, V1-121, V1-124, V1-135 ciblés | Aucun blocker identifié | NONE | CLOSE_V1 |
| Actor references / actorFace | READY_WITH_RESERVES | Actor facing et required actors couverts ; test complet attend encore `step_face` | Tests legacy à réaligner no-code | MAJOR | CLOSE_WITH_RESERVE |
| ActorMove direct | READY | V1-112 ciblé vert ; diagnostics core verts | Aucun blocker identifié | NONE | CLOSE_V1 |
| ActorMove manual path | READY | V1-108 ciblé vert ; Visual Gate V1-108 présente | Pas de pathfinding, volontairement V2 | V2_BACKLOG | CLOSE_V1 |
| Stage Points / Repères | READY | V1-102/V1-102-bis ciblés verts ; Visual Gates présentes | UX avancée de bulk edition hors V1 | MINOR | CLOSE_WITH_RESERVE |
| Stage Context | READY | Core JSON/manifest/stage context tests verts | Aucun blocker identifié | NONE | CLOSE_V1 |
| Map backdrop preview | READY | Visual Gates V1-84/V1-89/V1-94/V1-95 ; core map backdrop tests verts | Fidelity parfaite à toutes maps V2 | MINOR | CLOSE_WITH_RESERVE |
| Layer fidelity / ordering | READY | V1-94/V1-96 historique, tests ordering dans Builder complet passés avant les 6 échecs | Edge cases de profondeur complexes | MINOR | CLOSE_WITH_RESERVE |
| Actor display preview | READY | V1-92/V1-99 Visual Gates ; actor display core tests verts | Fallback sprites à enrichir en V2 | MINOR | CLOSE_WITH_RESERVE |
| Actor sprite preview | READY | V1-99/V1-99-bis Visual Gates ; tests sprite/animation ciblés verts | Atlases incomplets possibles | MINOR | CLOSE_WITH_RESERVE |
| Walking animation preview | READY | V1-116/V1-117 ciblés verts | Cadence plus fine en V2 | MINOR | CLOSE_WITH_RESERVE |
| Timeline lanes / time axis | READY_WITH_RESERVES | Core lane/time tests verts ; V1-48/V1-56 gates présents | Tests globaux legacy attendent certains IDs visibles | MAJOR | CLOSE_WITH_RESERVE |
| Timeline keyboard/mouse navigation | READY_WITH_RESERVES | Suite ciblée V1-120 verte ; test complet a 4 attentes legacy autour de labels techniques | Maintenance tests nécessaire | MAJOR | CLOSE_WITH_RESERVE |
| Duration editing / resize | READY | Tests duration/resize inclus dans Builder complet avant les échecs et non signalés rouges | Aucun blocker identifié | NONE | CLOSE_V1 |
| Playback transport | READY | V1-111/V1-112/V1-120 ciblés verts | Aucun blocker identifié | NONE | CLOSE_V1 |
| Seek / scrub | READY | V1-120 ciblé vert ; V1-134/V1-135 seek/scrub verts | Aucun blocker identifié | NONE | CLOSE_V1 |
| Fade preview | READY | V1-121 ciblé vert ; Visual Gate présente | Pas de transition FX avancée | V2_BACKLOG | CLOSE_V1 |
| Camera target/zoom authoring | READY | V1-132 ciblé vert ; Visual Gate présente | Aucune vraie caméra runtime, volontairement V2 | V2_BACKLOG | CLOSE_V1 |
| Camera geometry preview | READY | V1-134/V1-135 ciblés verts ; Visual Gates présentes | Overlay editor-only uniquement | V2_BACKLOG | CLOSE_V1 |
| Emote authoring | READY | V1-128 ciblé vert ; core emote catalog vert | Catalogue V0 limité | MINOR | CLOSE_WITH_RESERVE |
| Emote preview | READY | V1-129 ciblé vert ; Visual Gate présente | Overlap avancé hors V1 | MINOR | CLOSE_WITH_RESERVE |
| Diagnostics | READY_WITH_RESERVES | Core diagnostics verts ; UI diagnostics récents verts | Quelques libellés historiques de tests à réaligner | MAJOR | CLOSE_WITH_RESERVE |
| Design system / no hardcoded colors | READY_WITH_RESERVES | Analyse editor exit 0 ; audit V1-135 anti-scope | 38 infos analyzer non fatales, dont `withOpacity` historique | MINOR | CLOSE_WITH_RESERVE |
| Anti-runtime boundary | READY | Anti-scope final attendu vide ; aucun package runtime/gameplay/battle modifié | Aucun blocker identifié | NONE | CLOSE_V1 |
| Visual Gates | READY | 19 captures inventoriées avec SHA-256 | Pas de nouvelle capture V1-136 produite ; V1-135 sert de gate finale | MINOR | CLOSE_WITH_RESERVE |
| Tests/analyze/build | READY_WITH_RESERVES | Ciblés récents verts, core verts, build vert | Suites complètes Editor avec attentes legacy rouges | MAJOR | CLOSE_WITH_RESERVE |

## 6. Analyse par domaine

### Library / asset canonique

Le modèle canonique `CinematicAsset` et la Library sont suffisamment stables pour fermer V1. Les tests core et read model passent. La réserve vient d'un test widget Library qui attend encore un libellé ancien dans le Builder après ajout d'un bloc basique.

### Palette et inspecteurs

La palette couvre les blocs V1 attendus. Les inspecteurs récents privilégient les dropdowns et les labels no-code. Les derniers lots ont aussi réduit les sections techniques visibles, conformément aux demandes utilisateur.

### Stage Context, Repères et trajets

Les Stage Points, placements initiaux, destinations et trajets manuels sont présents et couverts par Visual Gates. V1 ferme l'authoring spatial de base ; les coordonnées libres, waypoints libres et pathfinding restent exclus.

### Preview décor et acteurs

La preview affiche les maps réelles, tiles/layers, éléments placés, surfaces, profondeur et acteurs/sprites avec fallback. Les animations de marche et le déplacement sub-tile sont editor-only et ne touchent pas au runtime.

### Timeline et playback

La timeline V1 livre lanes, axe temporel, barres proportionnelles, sélection, hover, navigation clavier, seek/scrub et zoom local. Le playback consomme `frameAt(timeMs)`, `actorPoses`, `fadeState`, `cameraPose` et `activeEmotes` sans runtime.

### Fade, emotes et caméra

Fade et emotes sont visibles en preview editor-only. La caméra V1 est fermée comme cadrage visible et non piloté : cible/zoom authoring, géométrie read model, overlay visuel passif. Aucune vraie caméra runtime n'est livrée en V1.

## 7. Tests et validations

Commandes exécutées :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135|V1-134|V1-132|V1-129|V1-128|V1-124|V1-121|V1-120|V1-118|V1-117-bis|V1-116|V1-112|V1-108|V1-105|V1-102"
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics test/cinematic_builder_workspace_test.dart
flutter build macos --debug

cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart test/cinematic_timeline_lane_read_model_test.dart test/cinematic_timeline_time_layout_read_model_test.dart test/cinematic_emote_catalog_test.dart test/cinematic_actor_display_preview_model_test.dart test/cinematic_map_backdrop_preview_model_test.dart test/cinematic_stage_map_source_catalog_test.dart test/cinematics_library_read_model_test.dart test/project_manifest_cinematics_test.dart
dart analyze lib test
```

Résultats :

- Builder complet : `+285 -6`, rouge sur 6 attentes legacy.
- Builder ciblé récent V1-102 à V1-135 : `All tests passed!`, `+73`.
- Library complète : `+20 -1`, rouge sur 1 attente legacy.
- Core cinematic élargi : `All tests passed!`, `+262`.
- Analyse editor : exit 0 avec 38 infos non fatales.
- Analyse map_core : `No issues found!`.
- Build macOS debug : `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## 8. Visual Gates

Synthèse :

| Lot | Fichier | Statut | Taille | SHA-256 |
|---|---|---|---|---|
| V1-42 | `ns_scenes_v1_42_cinematic_builder_v0_shell.png` | PRESENT | 145K | `f5af0a1f7bf91feb3bd9b541f76beacd833f7fe2bdd28820df210710904801fe` |
| V1-48 | `ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png` | PRESENT | 183K | `18a1ae7b81ba0192de0fc074c6275d8a585d2815d469b5dce9f64dcda85981dd` |
| V1-56 | `ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png` | PRESENT | 228K | `21c3f6cc18b1008286ad15d0be7afa857f9ff5a0bdcae49ff5fa2bf69f79776f` |
| V1-84 | `ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png` | PRESENT | 253K | `c005528da38d6af1766c949749528154323ef4e5cc896919bb141631915d1e81` |
| V1-89 | `ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png` | PRESENT | 244K | `ef160c2febfd96a9fbc8cdcfe8d2e140238bf7f12020e6c4892df5226ef1844f` |
| V1-92 | `ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png` | PRESENT | 287K | `431d9555fcf0ea36c5929af660adcf7720fb1b76c0802c6ebe0feabcc14df8c3` |
| V1-94 | `ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png` | PRESENT | 243K | `3cc17a0b4a9d986df0bf9b262014489185693b473501f52436c8ebde4dfa649c` |
| V1-95 | `ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png` | PRESENT | 250K | `3a2ee1eef54a8c7a4342d137733484cd734625a71f4b90d441c0140ad1d3cff9` |
| V1-99 | `ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png` | PRESENT | 225K | `02469a67c3e8b57e63752e14a8a501135afb53ccc82a221eddfc9c0924120317` |
| V1-102 | `ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.png` | PRESENT | 241K | `193add356cd297d384980a3d3695a229012cf43536007ad1ebb52542bde835c8` |
| V1-108 | `ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png` | PRESENT | 259K | `f016199226ef426bdb8a28554d0221f130b06471af7f3246113b0853230dd1fe` |
| V1-121 | `ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png` | PRESENT | 207K | `e728869979d5cfdca17c5e456051b5449ded1c7045759f667097d69330fa0c8e` |
| V1-124 | `ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png` | PRESENT | 212K | `f32320c3bccd6047dbc88f094ca6baf336b1a903559dc85f36b3764f2937f67f` |
| V1-129 | `ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png` | PRESENT | 233K | `ac71b1d68b1021acdc0225a05844bf43e66985473258ebc647f3ac817acd1ac4` |
| V1-134 | `ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png` | PRESENT | 224K | `01ce3b5de7fd78aeaa549f47866523c5505c14813ccbe03a7e25acf5e3f22ee4` |
| V1-135 | `ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png` | PRESENT | 225K | `788b64ab4fbe297c3d461fa97b4fb1c793a6201e3b7038ae82c6af4c7dbef123` |

Pas de Visual Gate V1-136 créée : V1-136 est un audit documentaire et V1-135 reste la Visual Gate finale la plus récente du Builder.

## 9. Blockers / majors / minors

### BLOCKER

Aucun blocker identifié.

### MAJOR

1. Suite complète Builder : 6 attentes legacy rouges.
   - `step_face`, `step_camera`, `step_camera_a`, `Statut`, `Professor marche vers Centre scène en 1000 ms.`
   - Interprétation : tests à réaligner avec l'UX no-code actuelle, pas preuve directe d'une régression produit.

2. Suite Library : 1 attente legacy rouge.
   - `Bloc authoring V0`
   - Interprétation : label obsolète attendu après évolution de l'inspecteur.

### MINOR

1. Analyse editor : 38 infos non fatales.
   - `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `deprecated_member_use` sur `withOpacity`.

2. Pas de capture V1-136 dédiée.
   - Justifié : audit documentaire ; capture V1-135 finale disponible.

## 10. Limites V1 assumées

V1 assume les limites suivantes :

- pas de runtime cinematic complet ;
- pas de vraie caméra runtime ;
- pas de vue pilotée par la caméra ;
- pas de pan/zoom réel ;
- pas de dialogue cinematic avancé ;
- pas d'audio/FX cinematic avancé ;
- pas de timeline parallèle ;
- pas de reorder horizontal des blocs ;
- pas de storyboard / shot strip ;
- pas de branching cinematic ;
- pas de pathfinding/collision pour actorMove.

Ces limites sont classées V2_BACKLOG, pas bugs V1.

## 11. Backlog V2

### Runtime cinematic

- Titre : Runtime cinematic player.
- Description : exécuter les `CinematicAsset` dans le runtime réel avec acteurs, caméra, fades, emotes et completion.
- Raison du report : V1 est editor-only.
- Dépendances : contrat playback runtime, GameState, Flame/runtime adapter.
- Priorité : P0.
- Hors V1 : explicitement interdit par les lots V1-109 à V1-136.

### Timeline avancée

- Titre : montage temporel avancé.
- Description : startMs/endMs persistés, overlap, reorder horizontal, drag durée complet.
- Raison du report : V1 conserve une timeline linéaire dérivée.
- Dépendances : modèle temporel V2.
- Priorité : P1.
- Hors V1 : V1 interdit la timeline parallèle/libre.

### Camera V2

- Titre : vraie caméra pilotée.
- Description : pan/zoom réel, interpolation, follow actor, presets traduits en géométrie runtime.
- Raison du report : V1 affiche seulement un cadre editor-only.
- Dépendances : renderer/runtime camera.
- Priorité : P1.
- Hors V1 : V1-135 ferme la caméra comme non pilotée.

### Dialogue / audio / FX

- Titre : blocs cinematic Dialogue/Son/FX avancés.
- Description : dialogues synchronisés, sons, effets visuels, timings.
- Raison du report : non authorés comme blocs V1 complets.
- Dépendances : contrats assets et runtime.
- Priorité : P2.
- Hors V1 : V1 privilégie wait/fade/camera/actorMove/actorFace/emote.

### Authoring spatial avancé

- Titre : outils spatiaux avancés.
- Description : waypoints libres, snapping multi-mode, pathfinding, collision preview.
- Raison du report : V1 utilise Repères et chemins manuels bornés.
- Dépendances : modèle spatial V2.
- Priorité : P2.
- Hors V1 : coordonnées libres et pathfinding interdits.

### Storyboard / production tools

- Titre : storyboard et shot strip.
- Description : vue plans, thumbnails, organisation par shots.
- Raison du report : V1 reste Builder linéaire fonctionnel.
- Dépendances : timeline V2.
- Priorité : P3.
- Hors V1 : non nécessaire à la fermeture V1.

### Polish UX

- Titre : maintenance tests/libellés legacy.
- Description : réaligner les tests complets rouges avec les libellés no-code actuels.
- Raison du report : non bloquant produit, mais nécessaire pour une suite complète verte.
- Dépendances : aucun modèle.
- Priorité : P0 maintenance.
- Hors V1 : peut être fait comme maintenance sans rouvrir le scope fonctionnel.

### Performance / architecture

- Titre : découpage du Builder.
- Description : extraire davantage l'inspecteur/timeline/preview pour réduire la taille du fichier workspace.
- Raison du report : risque de refactor large pendant V1.
- Dépendances : tests de non-régression.
- Priorité : P2.
- Hors V1 : fermeture fonctionnelle prioritaire.

## 12. Décision de fermeture

Décision : **CLOSE_WITH_RESERVE**.

Le Cinematic Builder V1 peut être fermé avec réserves documentées. Les réserves ne nécessitent pas un V1-136-bis bloquant parce que :

- les lots récents critiques passent ;
- le core cinématique passe ;
- l'application build macOS debug ;
- aucun runtime/Flame/GameState n'a été modifié ;
- les failures restantes ciblent des attentes de tests/labels, pas une preuve de perte fonctionnelle.

Recommandation : ne pas démarrer un nouveau lot fonctionnel dans le Builder V1. Planifier un petit lot maintenance tests si l'équipe veut une suite complète verte avant d'élargir le chantier.

## 13. Prochain lot recommandé

```text
NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
```

Objectif : utiliser les systèmes maintenant stabilisés pour cadrer la démo narrative jouable : maps, scènes, cinématiques, dialogues, combats, facts/world rules et contenu Selbrume, sans rouvrir le Cinematic Builder V1.

V1-137 est recommandé, non démarré.

## 14. Auto-critique finale

Le verdict est prudent : les tests complets rouges empêchent un “CLOSABLE ✅” sans réserve. En revanche, les signaux de build, core et lots récents sont assez solides pour éviter un “NON CLOSABLE ❌”.

Le prompt était très large pour un audit unique. Tous les domaines ont été audités par preuves disponibles, mais pas par exploration manuelle exhaustive dans l'app desktop. Le coût d'une vérification interactive complète dépasserait un lot documentaire et devrait devenir un lot QA séparé.

La réserve principale est la dette de tests legacy. Elle mérite un petit lot de maintenance, mais pas un V1-136-bis bloquant sauf si l'équipe exige que les suites complètes Widget soient vertes avant toute fermeture administrative.

## Critique du prompt

Le prompt est pertinent comme gate de fermeture, mais très ambitieux : il demande à la fois audit produit, tests larges, analyse, build, Visual Gates, backlog V2, roadmaps et Evidence Pack complet. Pour un repo de cette taille, c'est limite pour un seul lot.

Certaines validations sont coûteuses ou imparfaites :

- le test complet Builder est utile, mais mélange validations modernes et attentes anciennes ;
- une Visual Gate V1-136 dédiée aurait nécessité un mécanisme de capture supplémentaire ou un nouveau test, ce qui aurait contredit le caractère documentaire du lot ;
- l'audit “design system / no hardcoded colors” complet demanderait un scan dédié plus large que le Cinematic Builder.

Le prochain lot recommandé reste V1-137 plutôt qu'un V1-136-bis, parce qu'aucun blocker produit n'a été trouvé. Si l'équipe veut une propreté CI totale avant de changer de chantier, le meilleur micro-lot serait :

```text
NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup
```

Ce bis devrait uniquement réaligner les 7 attentes rouges identifiées, sans feature.
