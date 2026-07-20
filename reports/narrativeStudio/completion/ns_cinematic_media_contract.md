# NSC-65 — Contrat projet Media/FX et ports de playback

Date : 2026-07-20

Statut proposé : **DONE**

## Audit initial

Selbrume demande des cinématiques linéaires pour le port, la panique, la brume, le phare et la dissipation finale. Le modèle possédait déjà les kinds `sound`, `music` et `fx`, mais uniquement sous forme de références libres dans les steps : aucun catalogue projet, aucune résolution sûre, aucun port neutre de lecture et aucune dépendance canonique.

État Git initial : propre après NSC-64 (`42fb7319`). Aucun sub-agent n'a été lancé conformément à l'instruction active.

## ADR — Backend audio retenu

### Contexte vérifié

- Runtime installé : Flutter `3.46.0-0.3.pre`, Dart `3.13.0`.
- Runtime PokeMap : `flame: ^1.35.0`, résolution actuelle autorisant Flame 1.x récent.
- Le serveur de documentation Flame configuré a été interrogé mais n'a renvoyé aucun résultat audio.
- La documentation officielle Flame recommande `flame_audio`, `Bgm` pour le cycle pause/reprise, le cache pour le préchargement et `AudioPool` pour les effets courts répétés.
- `flutter pub add flame_audio:^2.12.1 --dry-run` résout correctement avec le graphe du runtime : Flame 1.37.0, `flame_audio` 2.12.1 et `audioplayers` 6.8.1, sans écriture.

Sources :

- https://docs.flame-engine.org/latest/bridge_packages/flame_audio/audio.html
- https://pub.dev/packages/flame_audio/versions/2.12.1

### Décision

NSC-67 utilisera `flame_audio ^2.12.1` comme adapter concret runtime/editor. `map_core` ne dépendra jamais de Flame, Flutter, audioplayers ni flame_audio. Le domaine publie uniquement des commandes et checkpoints neutres ; les adapters possèdent lifecycle, cache, pool, fade et restauration.

### Alternatives rejetées

- `audioplayers` direct : possible mais duplique l'intégration lifecycle déjà fournie par l'écosystème Flame.
- BattleFxCatalog comme vérité : rejeté, car il appartient à `map_runtime` et ne peut pas définir le schéma projet.
- Chemins absolus libres : rejetés pour portabilité, sécurité et packaging.

## Contrat livré

- `CinematicMediaAsset` typé : sound, music, cinematicFx ; ID, label, chemin relatif, durée, loop, canal et metadata.
- `ProjectManifest.cinematicMediaAssets` backward-compatible, absent/null → liste vide.
- `CinematicMediaCatalog` pur : doublons, chemins absolus, traversal, fichier absent/interdit, référence absente et type incompatible.
- `CinematicMediaPlaybackCommand` et `CinematicMediaPlaybackCheckpoint` sans dépendance UI/runtime.
- `CinematicMediaPlaybackPort` pour capture, execute et restore.
- `NarrativeDependencyIndex` définit les médias/FX dans le graphe canonique.
- Resolver editor injecté, limité à la racine projet.
- Marker explicitement absent des kinds de playback.

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/src/read_models/narrative_dependency_index.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/test/narrative_dependency_index_test.dart`
- `packages/map_core/test/project_manifest_cinematics_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/models/cinematic_media_asset.dart`
- `packages/map_core/lib/src/read_models/cinematic_media_catalog.dart`
- `packages/map_core/lib/src/runtime/cinematic_media_playback_contract.dart`
- `packages/map_core/test/cinematic_media_asset_test.dart`
- `packages/map_core/test/cinematic_media_catalog_test.dart`
- `packages/map_core/test/cinematic_media_playback_contract_test.dart`
- `packages/map_editor/lib/src/application/services/cinematic_media_asset_resolver.dart`
- `packages/map_editor/test/cinematic_media_asset_resolver_test.dart`
- ce rapport.

Le contenu complet des fichiers créés est versionné dans le commit du lot. Les fichiers Freezed/JSON sont les seuls artefacts régénérés et appartiennent au package modifié.

## TDD, commandes et résultats

```text
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
Built with build_runner in 20s; wrote 12 outputs.
Warnings existants : analyzer language 3.9 < SDK 3.12 et contrainte json_annotation historique.

dart test test/cinematic_media_asset_test.dart test/cinematic_media_catalog_test.dart test/cinematic_media_playback_contract_test.dart test/project_manifest_cinematics_test.dart
+15: All tests passed!

dart test test/narrative_dependency_index_test.dart --plain-name 'indexes project media and FX definitions'
+1: All tests passed!

dart analyze
No issues found!

cd packages/map_editor
flutter test test/cinematic_media_asset_resolver_test.dart
+1: All tests passed!

flutter analyze lib/src/application/services/cinematic_media_asset_resolver.dart test/cinematic_media_asset_resolver_test.dart
No issues found!
```

## Auto-critique et risques

Le catalogue sait si un fichier existe, mais ne décode pas encore ses métadonnées réelles : durée et format restent déclaratifs jusqu'au preflight NSC-67. Le contrat de fade est présent dans l'enum mais ses constructeurs guidés arrivent avec l'authoring NSC-66/adapter NSC-67. Les IDs media deviennent une nouvelle namespace canonique ; les steps ne les consomment dans le dependency walker qu'à partir de NSC-66. Aucune dépendance audio n'a été ajoutée dans ce lot, conformément à l'ordre de la roadmap.

Verdict des passes domaine/schéma/résolution/compatibilité : **GO**.
