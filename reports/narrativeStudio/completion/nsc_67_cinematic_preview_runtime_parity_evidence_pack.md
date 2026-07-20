# NSC-67 — Parité preview/runtime, preflight et rollback Cinematic

Date : 2026-07-20

Statut proposé : **DONE**

## Audit initial et verdict

La baseline NSC-60 savait prévisualiser et jouer les commandes visuelles V1,
mais `dialogueLine`, `shake`, `sound`, `music` et `fx` n'avaient pas de chaîne
commune entre le Builder et le runtime. Les médias définis par NSC-65 et les
commandes authorables NSC-66 restaient donc bloqués à la publication. Le
scrub ne reconstruisait aucun état audio/FX et le rollback ne couvrait pas les
canaux ou effets actifs.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles architecture, contrat Core, preview Editor, runtime Flame, rollback,
fixture commune, UI design system, régression et build sont **GO**. La passe
finale a détecté puis fermé un écart : la carte était encore contrôlée par deux
chemins distincts ; elle fait maintenant partie du preflight partagé.

## Gate et critères du lot

| Critère NSC-67 | Preuve | Verdict |
|---|---|---|
| Backend audio dans Editor et Runtime, sans couplage entre eux | `flame_audio` est une dépendance directe des deux packages ; chacun implémente le port neutre `map_core` | GO |
| Preflight partagé acteurs, carte, points et médias | `preflightCinematicPlayback`, utilisé par le plan Editor et le sink Runtime | GO |
| `dialogueLine`, `shake`, `sound`, `music`, `fx` | cues typés, stage de preview et exécution runtime couverts | GO |
| Marker éditorial non exécutable | durée éditoriale conservée, absence des cues/steps runtime testée | GO |
| Seek/scrub déterministe | horloge injectable et reconstruction depuis checkpoint | GO |
| Interruption, volume/fade, boucle et restauration | canaux nommés, remplacement par canal, volumes/boucles capturés et restaurés | GO V1 |
| Erreur/cancel sans état résiduel | rollback input, Dialogue, overlay, caméra, acteurs, audio et FX | GO |
| Même fixture preview/runtime | `project.json` est chargé par Core, Editor et Runtime | GO |
| Gate Selbrume | création/reload déjà prouvés par NSC-62/66 ; preview et runtime complets dans ce lot | GO |

La Phase 6 peut donc être proposée **DONE** : une Cinematic Selbrume avec
acteurs, caméra, Dialogue, son, musique et FX peut être créée, rechargée,
prévisualisée et jouée au runtime.

## Fichiers modifiés

- `examples/playable_runtime_host/macos/Flutter/GeneratedPluginRegistrant.swift`
- `examples/playable_runtime_host/pubspec.lock`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/cinematic_command_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/runtime/cinematic_media_playback_contract.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_media_playback_contract_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/linux/flutter/generated_plugin_registrant.cc`
- `packages/map_editor/linux/flutter/generated_plugins.cmake`
- `packages/map_editor/macos/Flutter/GeneratedPluginRegistrant.swift`
- `packages/map_editor/pubspec.lock`
- `packages/map_editor/pubspec.yaml`
- `packages/map_editor/test/goldens/narrative_studio/cinematics/cinematics_builder_full_product_route_1672x941.png`
- `packages/map_editor/windows/flutter/generated_plugin_registrant.cc`
- `packages/map_editor/windows/flutter/generated_plugins.cmake`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/pubspec.yaml`
- `packages/map_runtime/test/cinematic_runtime_playback_controller_test.dart`
- `packages/map_runtime/test/flame_cinematic_runtime_playback_sink_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/runtime/cinematic_playback_preflight.dart`
- `packages/map_core/test/cinematic_media_contract_fixture_test.dart`
- `packages/map_core/test/cinematic_playback_preflight_test.dart`
- `packages/map_core/test/fixtures/cinematic_media_contract/project.json`
- `packages/map_editor/lib/src/ui/canvas/cinematics/preview/cinematic_media_preview_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/preview/flutter_cinematic_media_preview_adapter.dart`
- `packages/map_editor/test/cinematic_media_preview_contract_test.dart`
- `packages/map_editor/test/cinematic_media_preview_controller_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_stage_panel_preview_test.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/cinematic_media_playback_port.dart`
- `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_fx_playback_adapter.dart`
- `packages/map_runtime/lib/src/presentation/flame/flame_cinematic_media_playback_adapter.dart`
- `packages/map_runtime/test/cinematic_audio_fx_runtime_integration_test.dart`
- `packages/map_runtime/test/cinematic_media_playback_contract_test.dart`
- `reports/narrativeStudio/completion/nsc_67_cinematic_preview_runtime_parity_evidence_pack.md`

Le contenu complet de chaque fichier créé est versionné dans le commit du lot.
Les registrants Flutter et lockfiles suivis sont inclus volontairement afin que
les builds Editor et hôte runtime reproduisent le backend audio validé. Aucun
répertoire `build/`, `.dart_tool/` ou artefact local n'est versionné.

## Zones précises et comportement livré

### Core et contrat commun

- Preflight immuable commun aux deux consommateurs : bindings acteurs,
  références carte, map active, points de scène, cibles de mouvement,
  Dialogues, médias et compatibilité de kind.
- Plan de preview enrichi de cues `dialogue`, `shake`, `sound`, `music` et
  `fx`, avec timing, référence lisible, canal, volume, fondu, boucle et
  intensité.
- `marker` contribue à la durée éditoriale mais jamais à
  `executableDurationMs`, aux cues ou aux commandes runtime.
- Contrat neutre de playback avec commandes play/stop/fade/spawn/cancel et
  checkpoint des canaux, volumes, boucles et FX.
- Les commandes avancées ne sont plus marquées `draftUntilNsc67` : diagnostics
  et publication reflètent désormais les capacités réellement livrées.

### Preview Editor

- Contrôleur déterministe avec horloge injectable, `prepare`, avance, seek,
  cancel et rollback après échec.
- Adapter Flutter audio indépendant de `map_runtime`, résolution de chemins
  sous la racine projet et driver injectable pour les tests.
- Reconstruction au scrub des musiques en boucle et FX actifs depuis le
  checkpoint capturé.
- Stage token-driven : carte Dialogue, secousse déterministe et badges
  son/musique/FX. Aucun primitive ou coloris ad hoc n'a été ajouté.
- Le Builder transmet les cartes projet au preflight partagé et synchronise
  transport, playhead et restauration média.
- Golden Builder mis à jour uniquement pour les commandes avancées devenues
  réellement disponibles.

### Runtime Flame

- Traduction pure d'une step en commande média typée ; le marker retourne
  explicitement `null` puis est filtré avant le sink.
- Adapters distincts audio et FX. Un nouveau média interrompt le canal de même
  nom ; boucle, volume et état antérieur sont restaurés.
- Le sink joue un Dialogue canonique via le runtime Dialogue existant, anime
  la secousse caméra, exécute audio/musique/FX et attend les opérations async.
- `PlayableMapGame` compose les adapters avec des chemins relatifs au projet et
  fournit un overlay FX viewport V1.
- Fin normale, erreur et annulation restaurent caméra, taille visible, acteurs,
  emote, fade, Dialogue, input, canaux audio et FX avant de résoudre le Future.

## TDD, commandes et résultats exacts

### Vérification complète avant la micro-correction carte partagée

```text
cd packages/map_core
dart test
exit 0 — All tests passed!
dart analyze
No issues found!

cd packages/map_runtime
flutter test
exit 0 — All tests passed!
flutter analyze
No issues found! (ran in 16.8s)

cd packages/map_editor
flutter test [tous les fichiers cinematic/cinematics]
exit 0 — All tests passed!
flutter test test/design_system_guardrail_test.dart \
  test/narrative_studio_cinematics_route_test.dart
+13: All tests passed!
flutter test test/narrative_studio_cinematics_golden_test.dart
+1: All tests passed!
flutter analyze [fichiers NSC-67]
No issues found! (ran in 11.7s)
flutter analyze
11 warnings préexistants, tous dans
lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ;
aucun warning NSC-67.
```

### Vérification finale après partage du contrôle de carte

```text
cd packages/map_core
dart test test/cinematic_playback_preflight_test.dart \
  test/cinematic_preview_playback_plan_test.dart \
  test/cinematic_media_contract_fixture_test.dart
+37: All tests passed!
dart analyze
No issues found!

cd packages/map_editor
flutter test test/cinematic_media_preview_controller_test.dart \
  test/cinematic_media_preview_contract_test.dart \
  test/ui/canvas/cinematics/cinematic_stage_panel_preview_test.dart
+6: All tests passed!
flutter analyze [3 fichiers preview/builder NSC-67]
No issues found! (ran in 13.3s)

cd packages/map_runtime
flutter test test/cinematic_audio_fx_runtime_integration_test.dart \
  test/cinematic_media_playback_contract_test.dart
+5: All tests passed!
flutter analyze [5 fichiers playback NSC-67]
No issues found! (ran in 12.1s)
```

Deux commandes groupées ont initialement référencé des chemins de tests
obsolètes (`cinematic_command_authoring_test.dart` et
`narrative_studio_navigation_rail_test.dart`). Elles ont échoué au chargement
de ces chemins inexistants, puis les suites valides ont été relancées avec
succès. Ce n'était pas une défaillance produit.

Après les builds, le PATH du runner a perdu le SDK Flutter 3.44. Une tentative
avec le SDK local 3.41 a logiquement rencontré l'API préexistante
`ScrollCacheExtent` réservée à Flutter 3.44 et un cache shader 3.44. Les tests
finaux ci-dessus ont donc été isolés sur les fichiers du lot ; les lockfiles
3.44 issus des builds verts ont été conservés, sans downgrade parasite.

## Builds

```text
cd packages/map_editor
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

cd examples/playable_runtime_host
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

Le build de l'hôte émet trois warnings Swift provenant de
`audioplayers_darwin 6.5.0` sur l'isolation d'acteur ; le build termine avec le
code 0. Aucun warning n'est issu du code PokeMap.

## Décisions, non-objectifs, risques et auto-critique

- Le backend audio est caché derrière un driver testable ; `map_core` reste
  pur Dart et l'Editor ne dépend pas du Runtime.
- Le fondu V1 applique immédiatement le volume cible après le démarrage à
  volume nul. Le contrat transporte bien sa durée et permet une rampe backend
  ultérieure, mais ce lot ne prétend pas offrir un mixeur DAW ni une courbe de
  crossfade échantillonnée.
- Le renderer FX runtime V1 est un overlay viewport déterministe identifié par
  l'asset catalogue. L'authoring de particules, shaders ou graphes FX reste un
  futur enrichissement et n'est pas nécessaire au Gate Phase 6.
- Les tests valident le driver audio, les chemins, commandes, checkpoints et
  builds plugin, mais pas la perception sonore sur du matériel physique.
- La suppression d'un Dialogue ou média entre preflight et exécution produit
  une erreur contrôlée et le rollback, sans laisser le jeu verrouillé.
- La micro-correction finale de carte a été revalidée par tests Core, tests
  d'intégration Runtime et analyses ciblées. Le build complet immédiatement
  antérieur couvre la même configuration de dépendances et de plugins.

État Git initial : propre après `72b41e079`. État avant commit : uniquement les
fichiers NSC-67 listés ci-dessus, y compris les deux fichiers de l'hôte générés
par l'ajout transitif du plugin audio.
