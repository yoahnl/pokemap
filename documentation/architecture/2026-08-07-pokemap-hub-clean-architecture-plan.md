# Plan — Bascule de `pokemap_hub` sur l'architecture Grimaldi

**Date** : 7 août 2026
**Périmètre** : `apps/pokemap_hub/` uniquement (109 fichiers, 19 942 lignes, 88 fichiers de test)
**Référence cible** : `grimaldi-mobile/lib` (647 fichiers, règle de dépendance à 0 violation)
**Stratégie retenue** : big-bang — un seul chantier, l'app est cassée pendant l'exécution
**Décision DI** : Riverpod, **runtime seul** — aucune chaîne de codegen n'est installable dans ce
monorepo (voir § 10)

---

## 1. Constat

`pokemap_hub` est découpé **par couche technique** (`install/`, `saves/`, `library/`, `session/`, `ui/`)
et non par feature. Aucune séparation domaine / application / data. Symptômes mesurés :

| Symptôme | Mesure |
|---|---|
| L'UI fait de l'I/O disque | **15 fichiers** sous `src/ui/` importent `dart:io` |
| Des stores de persistance vivent sous `ui/` | `ui/preferences/hub_preferences_store.dart`, `ui/avelune/appearance/avelune_appearance_store.dart` |
| God controller | `ui/hub_dashboard_controller.dart` — 800 l. : entités métier + orchestration + `File`/`Directory` |
| Zéro inversion de dépendance | **0 interface de repository** ; les controllers dépendent des classes concrètes |
| Fichiers monolithiques | `game_package_installer.dart` 1 344 l. · `hub_shell.dart` 927 l. · `hub_save_store.dart` 926 l. |

**À conserver tel quel** — ces briques sont déjà saines :

- `src/ui/avelune/design_system/` — foundation tokenisée (couleurs, espacements, typo, motion, formes, profondeur) + 8 composants. C'est déjà l'équivalent du `design_system/` de Grimaldi.
- `pokemap_hub.dart` — barrel pur, sans Flutter, garanti par un test existant. Contrat public à préserver.
- `src/platform/hub_composition.dart` — déjà un vrai composition root, à éclater en providers plutôt qu'à jeter.
- `src/install/game_installation_ports.dart` et `src/platform/hub_platform_adapter.dart` — déjà des ports hexagonaux, il leur manque juste leur place en `core/ports/`.

---

## 2. Différence structurante avec Grimaldi

Grimaldi est une app **réseau** : `core/network/` (dio, intercepteurs, SSE), `data/dtos/`, repositories HTTP.
`pokemap_hub` est **local-first** : filesystem, archives, `path_provider`, `file_picker`.

Correspondance retenue :

| Grimaldi | pokemap_hub |
|---|---|
| `core/network/` (dio, api_client) | `core/ports/` + `platform/` (adaptateurs `dart:io`) |
| `data/dtos/` | `data/codecs/` (JSON sur disque) |
| `ApiClient` injecté dans les repos | `Directory supportRoot` + ports injectés dans les repos |
| `core/error/app_failure.dart` | `core/error/hub_failure.dart` |

Le reste — arborescence, règle de dépendance, `app/di` + barrel, présentation feature-first, garde-fous
automatiques — est repris **à l'identique**.

---

## 3. Arborescence cible

```
apps/pokemap_hub/lib/
├── main.dart
├── pokemap_hub.dart · pokemap_hub_player.dart · pokemap_hub_ui.dart   ← barrels publics inchangés
├── app/
│   ├── app_root.dart
│   ├── di/
│   │   ├── providers.dart                    ← barrel d'exports UNIQUEMENT
│   │   ├── infrastructure_providers.dart
│   │   ├── library_repository_provider.dart
│   │   ├── installation_repository_provider.dart
│   │   ├── save_repository_provider.dart
│   │   ├── session_repository_provider.dart
│   │   ├── preferences_repository_provider.dart
│   │   └── appearance_repository_provider.dart
│   └── ui/app_widget.dart
├── core/
│   ├── ports/          hub_platform_port · game_installation_ports · support_root_port
│   │                   diagnostic_log_port · clock_port
│   ├── error/          hub_failure · error_mapper
│   ├── diagnostics/    hub_diagnostic · hub_diagnostic_severity
│   ├── config/         public_product_identity · avelune_host_compatibility
│   └── utils/          relative_time
├── platform/           android/ios/macos_hub_platform_adapter · hub_platform_adapter_factory
│                       path_provider_support_root_adapter
│                       file_picker_background_picker · isolate_background_image_processor
├── features/
│   ├── library/        {domain,application,data}
│   ├── installation/   {domain,application,data}
│   ├── saves/          {domain,application,data}
│   ├── session/        {domain,application,data}
│   ├── preferences/    {domain,data}
│   ├── appearance/     {domain,application,data}
│   └── dashboard/      {application}
└── presentation/
    ├── design_system/  {foundation,components,theme,assets,motion}
    ├── theme/ · shell/ · startup/ · shared/
    └── features/       home/ · player/ · settings/ · installation/   → {pages,widgets,state}
```

### Règle de dépendance (reprise de Grimaldi, sans adaptation)

1. `domain/` est **pur** : aucun import de `flutter`, `riverpod`, `dart:io`, ni de `data/`, ni de `application/`.
2. `presentation/` → **jamais** `features/*/data/`. L'UI passe par `domain/` et `application/`.
3. `application/` → **jamais** une implémentation concrète (`*_impl`, `*Store`). Uniquement des interfaces.
4. `data/` → **jamais** `presentation/`.
5. `design_system/` → **jamais** une feature. Il est agnostique.
6. Le câblage interface ↔ implémentation vit **exclusivement** dans `app/di/` et `features/*/application/*_providers.dart`.
7. `app/di/providers.dart` est un **barrel d'exports**. On n'y définit jamais de provider.
8. `presentation/` → **jamais** `dart:io`, à une exception allowlistée près (§ 7).

---

## 4. Découpage en 7 features

| Feature | domain | application | data | Source | Volume |
|---|:---:|:---:|:---:|---|---:|
| `library` | ✅ | ✅ | ✅ | `src/library/` | 811 l. |
| `installation` | ✅ | ✅ | ✅ | `src/install/` | 2 886 l. |
| `saves` | ✅ | ✅ | ✅ | `src/saves/` + `src/lifecycle/` | 1 696 l. |
| `session` | ✅ | ✅ | ✅ | `src/session/` + `src/player/` | 857 l. |
| `preferences` | ⚠️ interface seule | ❌ | ✅ | `src/ui/preferences/` | 175 l. |
| `appearance` | ✅ | ✅ | ✅ | `src/ui/avelune/appearance/` | 1 571 l. |
| `dashboard` | ❌ | ✅ | ❌ | `hub_dashboard_controller.dart` | 800 l. |

Deux features incomplètes, **assumées et documentées**, exactement comme Grimaldi les assume :

- `preferences` n'a qu'une interface de repository, sans entité — c'est le cas `notifications` de Grimaldi.
- `dashboard` est une **façade agrégatrice** `application`-only, sans `domain` ni `data` — c'est le cas `home`
  de Grimaldi, documenté dans `docs/refacto/home-dashboard-facade.md`.

`HubDiagnostic` part en `core/diagnostics/` et non dans une feature, parce qu'il est déjà consommé par
`install/game_installation_diagnostic.dart` **et** `saves/save_storage_diagnostic.dart`.

---

## 5. Mapping des 109 fichiers

### 5.1 `app/`

| Actuel | Cible |
|---|---|
| `src/bootstrap/hub_bootstrap.dart` (235) | `app/app_root.dart` + états UI → `presentation/startup/` |
| `src/ui/hub_app.dart` (252) | `app/ui/app_widget.dart` |
| `src/platform/hub_composition.dart` (247) | **éclaté** en `app/di/*_provider.dart` + `app/di/providers.dart` |

### 5.2 `core/`

| Actuel | Cible |
|---|---|
| `src/platform/hub_platform_adapter.dart` (34) | `core/ports/hub_platform_port.dart` ; `HubPackagePickerFailure` → `core/error/hub_failure.dart` |
| `src/install/game_installation_ports.dart` (30) | `core/ports/game_installation_ports.dart` |
| `src/platform/public_product_identity.dart` (12) | `core/config/public_product_identity.dart` |
| `src/platform/avelune_host_compatibility.dart` (18) | `core/config/avelune_host_compatibility.dart` |
| `src/ui/avelune/home/avelune_relative_time.dart` (30) | `core/utils/relative_time.dart` |
| *(extrait de `hub_dashboard_controller.dart`)* | `core/diagnostics/hub_diagnostic.dart` |
| *(nouveau)* | `core/ports/support_root_port.dart` · `diagnostic_log_port.dart` · `clock_port.dart` |

### 5.3 `platform/`

| Actuel | Cible |
|---|---|
| `src/platform/{android,ios,macos}_hub_platform_adapter.dart` (186) | `platform/` — inchangés |
| `src/platform/hub_platform_adapter_factory.dart` (15) | `platform/` — inchangé |
| *(extrait de `hub_composition.dart` : `_defaultSupportRoot`)* | `platform/path_provider_support_root_adapter.dart` |
| *(extrait de `avelune_custom_background_importer.dart`)* | `platform/file_picker_background_picker.dart` · `platform/isolate_background_image_processor.dart` |

### 5.4 `features/library/`

| Actuel | Cible |
|---|---|
| `src/library/game_library.dart` (224) | `domain/entities/game_library.dart` + `domain/entities/installed_game.dart` |
| *(nouveau)* | `domain/repositories/game_library_repository_interface.dart` |
| `src/library/game_library_codec.dart` (409) | `data/codecs/game_library_codec.dart` |
| `src/library/game_library_store.dart` (178) | `data/repositories/game_library_repository_impl.dart` |
| *(extrait du dashboard controller)* | `application/use_cases/load_game_library_use_case.dart` |

### 5.5 `features/installation/`

| Actuel | Cible |
|---|---|
| `src/install/game_installation_transaction.dart` (150, pur) | `domain/entities/game_installation_transaction.dart` |
| `src/install/game_installation_diagnostic.dart` (129, pur) | `domain/entities/game_installation_diagnostic.dart` |
| *(nouveau)* | `domain/repositories/game_installation_repository_interface.dart` |
| *(règles pures extraites de l'installer)* | `domain/services/` — compatibilité hôte, quota disque, arbitrage de version |
| `src/install/game_package_installer.dart` (1 344) | `data/repositories/` — **à éclater** (§ 6) |
| `src/install/installed_game_verifier.dart` (572) | `data/repositories/installed_game_verifier.dart` |
| `src/install/game_maintenance_service.dart` (403) | `data/repositories/game_maintenance_service.dart` |
| `src/install/editor_export_install_inbox.dart` (215) | `data/repositories/editor_export_install_inbox.dart` |
| `src/install/file_package_source.dart` (43) | `data/sources/file_package_source.dart` |
| *(nouveaux)* | `application/use_cases/` — `install_game_package` · `verify_installed_game` · `run_game_maintenance` · `consume_editor_exports` |

### 5.6 `features/saves/`

| Actuel | Cible |
|---|---|
| `src/saves/save_profile.dart` (53) | `domain/entities/save_profile.dart` |
| `src/saves/save_slot_metadata.dart` (59) | `domain/entities/save_slot_metadata.dart` |
| `src/saves/save_storage_diagnostic.dart` (84) | `domain/entities/save_storage_diagnostic.dart` |
| *(nouveau)* | `domain/repositories/save_repository_interface.dart` |
| `src/saves/hub_save_profile_manager.dart` (238) | `application/services/hub_save_profile_manager.dart` |
| `src/lifecycle/hub_save_lifecycle_coordinator.dart` (177) | `application/services/hub_save_lifecycle_coordinator.dart` |
| `src/saves/hub_save_store.dart` (926) | `data/repositories/` — **à éclater** (§ 6) |
| `src/saves/legacy_global_save_importer.dart` (159) | `data/repositories/legacy_global_save_importer.dart` |

### 5.7 `features/session/`

| Actuel | Cible |
|---|---|
| `src/session/save_read_handle.dart` (18) | `domain/entities/save_read_handle.dart` |
| `src/ui/player/hub_player_launch_intent.dart` (26) | `domain/entities/hub_player_launch_intent.dart` |
| `src/player/hub_runtime_external_exit.dart` (17) | `domain/entities/hub_runtime_external_exit.dart` |
| *(nouveaux)* | `domain/repositories/session_launch_repository_interface.dart` · `control_profile_repository_interface.dart` |
| `src/session/hub_in_process_session_factory.dart` (78) | `application/services/hub_in_process_session_factory.dart` |
| `src/player/hub_session_checkpoint_committer.dart` (92) | `application/services/hub_session_checkpoint_committer.dart` |
| `src/player/hub_runtime_game_source.dart` (74) | `application/services/hub_runtime_game_source.dart` |
| `src/player/hub_player_save_gateway.dart` (115) | `application/gateways/hub_player_save_gateway.dart` |
| `src/player/hub_player_preferences_gateway.dart` (81) | `application/gateways/hub_player_preferences_gateway.dart` |
| `src/session/installed_game_launch_resolver.dart` (154) | `data/repositories/installed_game_launch_resolver.dart` |
| `src/session/package_asset_resolver.dart` (186) | `data/repositories/package_asset_resolver.dart` |
| `src/player/hub_control_profile_store.dart` (42) | `data/repositories/hub_control_profile_repository_impl.dart` |

### 5.8 `features/preferences/`

| Actuel | Cible |
|---|---|
| *(nouveau)* | `domain/repositories/player_preferences_repository_interface.dart` |
| `src/ui/preferences/hub_preferences_store.dart` (175) | `data/repositories/hub_preferences_repository_impl.dart` |

### 5.9 `features/appearance/`

| Actuel | Cible |
|---|---|
| `src/ui/avelune/appearance/avelune_appearance_preferences.dart` (66) | `domain/entities/avelune_appearance_preferences.dart` |
| `src/ui/avelune/appearance/avelune_appearance_catalog.dart` (105) | `domain/entities/avelune_appearance_catalog.dart` |
| *(nouveaux)* | `domain/repositories/avelune_appearance_repository_interface.dart` · `custom_background_repository_interface.dart` |
| `src/ui/avelune/appearance/avelune_appearance_controller.dart` (285) | `application/notifiers/avelune_appearance_notifier.dart` + `_state.dart` |
| `src/ui/avelune/appearance/avelune_appearance_store.dart` (240) | `data/repositories/avelune_appearance_repository_impl.dart` |
| `src/ui/avelune/appearance/avelune_custom_background_importer.dart` (482) | `data/repositories/custom_background_repository_impl.dart` ; picker + processor → `platform/` |
| `src/ui/avelune/appearance/avelune_appearance_settings.dart` (393) | **UI** → `presentation/features/settings/pages/` |

### 5.10 `features/dashboard/`

`src/ui/hub_dashboard_controller.dart` (800 l.) est éclaté en quatre destinations :

| Contenu actuel | Cible |
|---|---|
| `HubDiagnostic`, `HubDiagnosticSeverity` | `core/diagnostics/hub_diagnostic.dart` |
| `HubDashboardStatus`, `HubSection`, `HubStorageSnapshot`, `HubGameActivity`, `HubGameView`, `HubDashboardSnapshot` | `features/dashboard/application/notifiers/hub_dashboard_state.dart` |
| Orchestration (import, sélection, section, requête, rafraîchissement) | `features/dashboard/application/notifiers/hub_dashboard_notifier.dart` |
| `InstalledHubGameActivityReader` | `features/dashboard/application/services/installed_game_activity_reader.dart` |
| *(nouveau)* | `features/dashboard/application/dashboard_providers.dart` |

### 5.11 `presentation/`

| Actuel | Cible |
|---|---|
| `src/ui/avelune/design_system/**` (21 fichiers, 1 817 l.) | `presentation/design_system/{foundation,components,theme}` — **déplacement sec** |
| `src/ui/avelune/assets/**` (2 fichiers, 292 l.) | `presentation/design_system/assets/` |
| `src/ui/avelune/motion/{avelune_feedback,avelune_interaction_state,avelune_motion}.dart` (3 fichiers) | `presentation/design_system/motion/` |
| `src/ui/avelune/motion/avelune_{exchange,insertion}_controller.dart` (2 fichiers, 313 l.) | `presentation/features/home/state/` — contrôleurs d'animation de la feature, pas des primitives du design system |
| `src/ui/avelune/avelune_theme.dart` (23) | `presentation/theme/avelune_theme.dart` |
| `src/ui/avelune/avelune_navigation.dart` (1) | **supprimé** — ré-export absorbé par le barrel `design_system` |
| `src/ui/hub_shell.dart` (927) | `presentation/shell/` — **à éclater** (§ 6) |
| `src/ui/hub_game_views.dart` (88) | `presentation/shell/hub_game_views.dart` |
| `src/ui/hub_install_progress.dart` (286) | `presentation/features/installation/widgets/` |
| `avelune_home_screen.dart` (611) | `presentation/features/home/pages/` |
| `avelune_room_scene` (481) · `avelune_cartridge` (628) · `avelune_console` (352) · `avelune_game_shelf` (218) · `avelune_game_details` (261) · `avelune_hero_details_panel` (143) · `avelune_home_header` (96) · `avelune_insertion_hint` (59) · `avelune_cartridge_insertion_overlay` (155) · `avelune_cartridge_exchange_overlay` (116) · `avelune_game_presentation` (81) | `presentation/features/home/widgets/` |
| `avelune_home_controller` (120) · `avelune_home_geometry` (467) · `avelune_home_view_data` (136) · `avelune_home_view_data_mapper` (176) | `presentation/features/home/state/` |
| `hub_installed_game_player` (648) · `hub_intro_video_player` (306) · `hub_save_profiles_screen` (457) · `hub_installed_player_strings` (31) | `presentation/features/player/pages/` |
| `hub_title_presentation_loader` (226) | `presentation/features/player/state/` |
| `avelune_settings_menu` (137) · `avelune_storage_panel` (105) · `avelune_motion_panel` (76) · `avelune_appearance_settings` (393) | `presentation/features/settings/{pages,widgets}` |

---

## 6. Les 5 fichiers monolithiques à éclater

Le déplacement seul ne suffit pas : cinq fichiers concentrent 4 645 lignes, soit **23 % de l'app**.

| Fichier | Découpe proposée |
|---|---|
| `game_package_installer.dart` (1 344) | `game_package_installer.dart` (orchestration) · `install_staging.dart` (extraction, staging) · `install_commit.dart` (commit atomique, rollback) · `install_quota_guard.dart` (disque) · `domain/services/install_compatibility_rules.dart` (règles pures) |
| `hub_shell.dart` (927) | `hub_shell.dart` (scaffold) · `hub_shell_routing.dart` (sections) · `hub_shell_sections.dart` (rendu par section) |
| `hub_save_store.dart` (926) | `hub_save_repository_impl.dart` (façade) · `save_slot_reader.dart` · `save_atomic_writer.dart` · `save_migration_runner.dart` |
| `hub_dashboard_controller.dart` (800) | 4 destinations, voir § 5.10 |
| `hub_installed_game_player.dart` (648) | `hub_installed_game_player_page.dart` (UI) · `state/installed_game_player_controller.dart` (état de vue) |

Cible : **aucun fichier au-dessus de ~450 lignes** après le chantier, sauf justification explicite.

---

## 7. Purge du `dart:io` en couche présentation

15 fichiers UI importent `dart:io`, presque tous pour la même raison : construire un `FileImage`
à partir d'un chemin d'artwork (icône, jaquette, hero, fond personnalisé).

Traitement :

- Les read models (`HubGameView`, `AveluneHomeViewData`) exposent des **chemins `String`**, jamais de `File`.
- Un adaptateur unique, `presentation/shared/artwork/local_artwork_image.dart`, convertit un chemin en
  `ImageProvider`. C'est le **seul** fichier de `presentation/` autorisé à importer `dart:io`.
- Cette exception est **allowlistée nominativement** dans le test de garde-fous, comme Grimaldi allowliste
  ses 2 arêtes UI vers `consent_modal.dart`.
- `hub_intro_video_player.dart` et `hub_title_presentation_loader.dart` reçoivent leurs chemins résolus
  par `features/session/` au lieu de les résoudre eux-mêmes.

---

## 8. Étapes du chantier (big-bang)

Ordre imposé : chaque étape dépend de la précédente. L'app ne compile pas entre l'étape 2 et l'étape 9.

### Étape 0 — Point de départ propre
- Committer ou remiser les 5 fichiers `avelune` en cours de modification (`avelune_cartridge.dart`,
  `avelune_glass_surface.dart`, `avelune_icon_control.dart`, `avelune_pressable.dart`, `avelune_glass_tokens.dart`).
- Supprimer les 2 fichiers de test temporaires non suivis dans `packages/map_editor/test/`.
- **Fait quand** : `git status` sur `apps/pokemap_hub/` est vide.

### Étape 1 — Dépendances et outillage
- `pubspec.yaml` : ajouter `flutter_riverpod: ^3.0.3`. **Rien d'autre.**
- `analysis_options.yaml` : inchangé — sans codegen, il n'y a ni fichier généré à exclure, ni plugin
  `custom_lint` installable.
- **Fait quand** : `flutter pub get` passe et un `ProviderContainer` résout un provider avec override.

### Étape 2 — Arborescence et déplacements
- Créer l'arborescence du § 3 (dossiers vides).
- `git mv` des 109 fichiers selon le § 5, **sans toucher au contenu**.
- **Fait quand** : `find lib/src -name '*.dart'` ne retourne plus rien et `lib/src/` est supprimé.

### Étape 3 — Réécriture des imports
- Passer tous les imports relatifs (`../install/...`) en absolus (`package:pokemap_hub/features/...`),
  comme Grimaldi qui n'utilise que `package:grimaldi/...`.
- Mettre à jour les 3 barrels publics (`pokemap_hub.dart`, `pokemap_hub_ui.dart`, `pokemap_hub_player.dart`)
  vers les nouveaux chemins. **Leur API publique ne change pas.**
- **Fait quand** : `flutter analyze` ne remonte plus d'erreur `uri_does_not_exist`.

### Étape 4 — Éclatement des monolithes
- Appliquer les 5 découpes du § 6.
- **Fait quand** : aucun fichier de `lib/` ne dépasse 450 lignes hors justification écrite.

### Étape 5 — Inversion de dépendance
- Créer les **8 interfaces** de `domain/repositories/` listées au § 5 : `game_library` · `game_installation` ·
  `save` · `session_launch` · `control_profile` · `player_preferences` · `avelune_appearance` · `custom_background`.
- Créer les **3 ports** manquants de `core/ports/` : `support_root` · `diagnostic_log` · `clock`.
- Renommer les classes concrètes en `*RepositoryImpl` et les faire `implements` l'interface.
- Remplacer tous les types concrets par les interfaces dans `application/`.
- **Fait quand** : `grep -r "RepositoryImpl\|Store(" lib/features/*/application lib/presentation` ne renvoie rien.

### Étape 6 — DI Riverpod
- Éclater `hub_composition.dart` en `app/di/*_provider.dart` (un fichier par repository).
- Créer `app/di/providers.dart` — **exports uniquement**, zéro définition.
- Créer les `features/<f>/application/<f>_providers.dart` pour les use cases et notifiers.
- Envelopper `app_root.dart` dans un `ProviderScope`.
- **Fait quand** : `hub_composition.dart` n'existe plus et `providers.dart` ne contient que des `export`.

### Étape 7 — Notifiers
- Convertir en `Notifier` Riverpod les 3 `ChangeNotifier` porteurs d'état applicatif :
  `hub_dashboard_controller` · `avelune_home_controller` · `avelune_appearance_controller`.
- Les états (`HubDashboardSnapshot`, `AveluneHomeViewData`, …) **restent des classes Dart immuables
  avec `copyWith` manuel** — c'est déjà le cas aujourd'hui, et c'est ce que freezed aurait produit.
- **Décision posée** : `avelune_exchange_controller` et `avelune_insertion_controller` **restent des
  `ChangeNotifier` locaux**. Ils ne pilotent que de l'animation à l'intérieur d'un seul widget, n'ont
  aucune dépendance métier et ne sortent jamais de `presentation/features/home/`. Seuls les 3 autres
  sont convertis.
- **Fait quand** : `flutter analyze` et `flutter test` sont à la référence, et `grep -rl "extends ChangeNotifier" lib/` ne renvoie que les 2 controllers d'animation.

### Étape 8 — Purge `dart:io` en présentation
- Appliquer le § 7.
- **Fait quand** : `grep -rl "dart:io" lib/presentation` ne renvoie que `local_artwork_image.dart`.

### Étape 9 — Garde-fous automatiques
- Créer `test/architecture/dependency_rules_test.dart` sur le modèle de Grimaldi, avec une sonde par règle
  du § 3 (8 sondes), allowlist explicite pour l'exception du § 7.
- **Conserver** `test/architecture/hub_architecture_boundary_test.dart` (frontières inter-packages) et
  `test/player/hub_player_architecture_boundary_test.dart` — ils testent autre chose et restent valides.
- **Fait quand** : les 8 sondes sont vertes.

### Étape 10 — Reprise des tests
- Repointer les imports des 88 fichiers de test.
- Réaligner l'arborescence de `test/` sur celle de `lib/` (`test/features/<f>/...`, `test/presentation/...`).
- Les tests qui instanciaient un composition root passent par un `ProviderContainer` avec overrides.
- **Fait quand** : `flutter test` est vert sur les 88 fichiers.

### Étape 11 — Vérification finale
```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```
- **Fait quand** : `flutter analyze` = 0 erreur, `flutter test` = 100 % vert, et l'app démarre
  sur au moins une plateforme de bureau.

---

## 9. Volumétrie

| Opération | Volume |
|---|---|
| Fichiers déplacés | 108 |
| Fichiers supprimés | 2 (`avelune_navigation.dart`, `hub_composition.dart`) |
| Interfaces de repository créées | 8 |
| Ports `core/ports/` créés | 3 |
| Fichiers issus de l'éclatement des monolithes | ~18 (à partir de 5) |
| Fichiers de providers créés | ~14 |
| Fichiers de test repointés | 88 |
| Nouvelles dépendances | **1** (`flutter_riverpod`) |

---

## 10. Hypothèses et limites

**Hypothèses posées** :

1. **Aucun changement de comportement.** Le chantier est un refactor pur : mêmes écrans, mêmes formats
   de fichiers sur disque, mêmes chemins de `supportRoot`. Toute divergence de comportement est un bug.
2. **`packages/` est hors périmètre.** `map_core`, `map_runtime`, `map_player_ui`, `map_distribution`
   ne sont pas touchés. Leurs API consommées par le Hub restent identiques.
3. **Les 3 barrels publics conservent leur API.** Un consommateur externe de `package:pokemap_hub/pokemap_hub.dart`
   ne voit aucune différence — c'est ce qui permet de ne pas casser `test/architecture/hub_architecture_boundary_test.dart`.
4. **Pas de localisation.** Grimaldi a `l10n/` ; le Hub a ses chaînes en dur, en français, dans le code.
   Sortir les chaînes est un chantier distinct, non inclus ici.

**Risques identifiés** :

| Risque | Mitigation |
|---|---|
| Big-bang = l'app est cassée pendant tout le chantier, aucune bisection possible en cas de régression | Les 88 tests existants sont le seul filet. Ne pas les affaiblir à l'étape 10 pour « faire passer » : les corriger. |
| Le chantier se déroule sur `main` (workflow du projet, pas de branche feature) | Étape 0 obligatoire : partir d'un working tree propre, et livrer le refactor en un commit unique et identifiable. |
| Le codegen Riverpod/freezed est **impossible** ici : `map_core` épingle `freezed_annotation ^2.4.1` (hors périmètre) et Dart 3.13 impose `analyzer >=13`. Aucune version ne satisfait les deux. | Vérifié par 4 échecs du solveur `pub` au lot 2. Providers écrits à la main, états en Dart brut. L'architecture n'en dépend pas — le codegen est une commodité d'écriture. Corollaire : `map_core` ne peut pas non plus régénérer ses propres `.freezed.dart` sur ce SDK ; ça compile parce qu'ils sont commités. Dette pré-existante du monorepo, à traiter à part. |
| Les tests golden de `design_system` peuvent bouger si les chemins d'assets changent | Le design_system est un **déplacement sec**, sans modification de contenu — les goldens doivent rester bit-à-bit identiques. Toute différence signale une erreur de déplacement. |
| `game_package_installer.dart` (1 344 l.) est le cœur de l'installation, avec des transactions et du rollback | L'éclater en dernier dans l'étape 4, et ne pas modifier une seule règle métier au passage. Les tests d'install (`game_install_recovery_test`, `game_package_installer_test`) sont la référence. |

**Hors périmètre, à signaler pour plus tard** :

- Extraction des chaînes UI vers un `l10n/` (le Hub est monolingue français en dur).
- Un `scripts/check_presentation_boundaries.sh` équivalent à celui de Grimaldi, en complément du test Dart.
- L'objectif de 100 % de couverture que Grimaldi s'impose n'est pas repris ici : le Hub n'a pas de
  `coverage.sh` et ce serait un chantier à part entière.
