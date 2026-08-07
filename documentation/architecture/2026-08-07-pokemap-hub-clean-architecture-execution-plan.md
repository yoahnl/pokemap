# Plan d'exécution — Bascule `pokemap_hub` sur l'architecture Grimaldi

> **Pour les agents exécutants** : ce plan se déroule lot par lot. Chaque lot se termine par une
> vérification exécutable et un commit. Les étapes utilisent des cases à cocher (`- [ ]`).

**Spec de référence** : [`2026-08-07-pokemap-hub-clean-architecture-plan.md`](./2026-08-07-pokemap-hub-clean-architecture-plan.md)

**Objectif** : remplacer le découpage par couche technique de `apps/pokemap_hub/lib/src/` par
l'architecture feature-first de Grimaldi (`app/` · `core/` · `platform/` · `features/<f>/{domain,application,data}` · `presentation/`),
avec DI Riverpod et garde-fous automatiques.

**Approche** : big-bang en 25 lots regroupés en 6 phases. La phase 2 déplace les 109 fichiers sans
toucher au contenu — **l'app ne compile pas pendant cette phase**. Elle recompile au lot 8, qui est le
point de non-retour utile : à partir de là, chaque lot se termine sur `flutter analyze` + `flutter test` verts.

**Stack** : Flutter 3.46 · Dart 3.13 · `flutter_riverpod ^3.0.3` — **runtime seul, sans codegen**.

> ⚠️ **Contrainte découverte au lot 2, vérifiée par le solveur de `pub`.** Aucune chaîne de génération
> de code n'est installable dans ce monorepo :
>
> | Chaîne | Exige | Bloqué par |
> |---|---|---|
> | `riverpod_generator` 4.x · `riverpod_lint` 3.x · `freezed` 3.x | `freezed_annotation ^3.0.0` | `map_core` épingle `^2.4.1` (dépendance `path`, hors périmètre) |
> | `riverpod_generator` 2.x · `riverpod_lint` 2.x · `freezed` 2.x | `analyzer ^6/^7` | Dart 3.13 impose `analyzer >=13` |
>
> Le monorepo est pris en tenaille entre `map_core` (qui tire vers le bas) et le SDK Flutter beta
> (qui tire vers le haut). **Décision prise** : Riverpod en runtime seul.
>
> **Conséquences sur ce plan** : les providers des lots 17 à 21 s'écrivent **à la main**
> (`final xProvider = Provider<X>((ref) => …)`) au lieu de `@Riverpod`. Les états restent des classes
> Dart avec `copyWith` — ce que `HubDashboardSnapshot` est déjà aujourd'hui — au lieu de `@freezed`.
> Aucun `.g.dart`, aucun `.freezed.dart`, aucun `build.yaml`, aucune étape de génération nulle part.
> **L'architecture Grimaldi n'est pas affectée** : couches, interfaces, frontières de DI et garde-fous
> sont identiques. Le codegen est une commodité d'écriture, pas une propriété structurelle.

---

## Contraintes globales

Elles s'appliquent implicitement à **tous** les lots.

- **Répertoire de travail** : toutes les commandes se lancent depuis `apps/pokemap_hub/`.
- **Aucun changement de comportement.** Mêmes écrans, mêmes formats de fichiers sur disque, mêmes chemins
  de `supportRoot`. Toute divergence est un bug, pas une amélioration.
- **`packages/` est hors périmètre.** `map_core`, `map_runtime`, `map_player_ui`, `map_distribution`,
  `map_editor` ne sont jamais modifiés.
- **Les 3 barrels publics conservent leur API à l'identique** : `pokemap_hub.dart` (pur, sans Flutter),
  `pokemap_hub_ui.dart`, `pokemap_hub_player.dart`. Seuls leurs chemins internes changent.
- **Ne jamais affaiblir un test pour le faire passer.** Les 88 fichiers de test existants sont le seul
  filet du chantier. Un test qui casse signale une régression, pas un test à corriger.
- **Imports absolus uniquement** à partir du lot 8 : `package:pokemap_hub/...`, jamais `../`.
- **Travail sur `main`**, sans branche feature (convention du dépôt).
- **Commits** : préfixe `refactor(hub):`, un commit par lot.
- **Aucun `git push`** pendant tout le chantier. Le push se décide après le lot 25.

### Les 8 règles de dépendance à faire respecter

1. `domain/` est pur : ni `flutter`, ni `riverpod`, ni `dart:io`, ni `data/`, ni `application/`.
2. `presentation/` n'importe jamais `features/*/data/`.
3. `application/` n'importe jamais une implémentation concrète (`*Impl`, `*Store`).
4. `data/` n'importe jamais `presentation/`.
5. `design_system/` n'importe jamais une feature.
6. Le câblage interface ↔ implémentation vit uniquement dans `app/di/` et `features/*/application/*_providers.dart`.
7. `app/di/providers.dart` ne contient que des `export`.
8. `presentation/` n'importe jamais `dart:io`, sauf `presentation/shared/artwork/local_artwork_image.dart`.

---

## Vue d'ensemble des phases

| Phase | Lots | Objet | App compile ? |
|---|---|---|:---:|
| **1 — Socle** | 1-2 | Working tree propre, dépendances, codegen | ✅ |
| **2 — Translation** | 3-8 | Déplacement des 109 fichiers, réécriture des imports | ❌ puis ✅ au lot 8 |
| **3 — Décomposition** | 9-13 | Éclatement des 5 monolithes (4 645 l.) | ✅ |
| **4 — Inversion** | 14-16 | 3 ports + 8 interfaces + substitution | ✅ |
| **5 — Riverpod** | 17-21 | `app/di`, providers, `ProviderScope`, Notifiers | ✅ |
| **6 — Verrouillage** | 22-25 | Purge `dart:io` UI, garde-fous, tests, recette | ✅ |

---

# PHASE 1 — Socle

*L'app reste verte du début à la fin de cette phase.*

## Lot 1 — Working tree propre

**Fichiers**
- Modifier : aucun fichier de `lib/`
- Nettoyer : `packages/map_editor/test/tmp_export_probe_test.dart`, `packages/map_editor/test/tmp_scenario_seed_test.dart`

**Produit** : un point de départ bisectable. Sans ça, une régression du chantier sera confondue avec le
travail avelune en cours.

- [x] **Étape 1.1 — Inventorier ce qui traîne**

```bash
git status --short
```

**Résultat (7 août 2026)** : sortie vide, branche `main`. Le travail avelune a été livré entre-temps
par les commits `32b87b70f` et `81e801940`.

- [x] **Étape 1.2 — Vérifier que le travail avelune en cours est vert**

**Résultat** : sans objet, le travail est déjà commité. Couvert par la suite complète de l'étape 1.6.

- [x] **Étape 1.3 — Committer le travail avelune en cours**

**Résultat** : déjà fait — `81e801940 feat(avelune): Cupertino glyphs, no Scaffold, and a glass details screen`.
Ce commit **ajoute** `presentation/design_system/foundation/avelune_icon_tokens.dart` (53 l.), d'où le
passage de 108 à 109 fichiers.

- [x] **Étape 1.4 — Supprimer les deux sondes temporaires**

**Résultat** : déjà supprimées. `find packages/map_editor/test -name 'tmp_*'` renvoie 0.

- [x] **Étape 1.5 — Confirmer le point de départ**

**Résultat** : `git status --short` vide. ✅

- [x] **Étape 1.6 — Prendre la référence de test**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

**Référence mesurée le 7 août 2026 — à retrouver à l'identique au lot 25 :**

| Mesure | Valeur |
|---|---|
| `flutter analyze` | **0 issue** (`No issues found!`) |
| `flutter test` | **+361 −1** |
| Fichiers Dart dans `lib/` | **109** |
| Lignes dans `lib/` | **19 942** |
| Fichiers de test | **88** |

> ⚠️ **La référence n'est pas entièrement verte, et c'est assumé.**
> `test/support/runtime_owned_player_package_fixture_test.dart` →
> *« installed Golden fixture keeps the canonical Selbrume ending contract »* échoue sur
> `Bad state: Repository root containing Selbrume was not found.`
>
> Cause : le test remonte l'arborescence à la recherche de `<repo>/selbrume/project.json`. Ce dossier
> **n'est pas tracké par git** (0 fichier) et **n'est pas listé dans `.gitignore`** — c'est un projet de
> jeu local, présent sur la machine où le test a été écrit (`b05149005`), absent de ce checkout.
>
> **Conséquence pour tout le chantier** : chaque gate de lot qui demande « les mêmes chiffres qu'à
> l'étape 1.6 » attend **`+361 −1`**, pas « tout vert ». Cet unique échec est indépendant de
> l'architecture — il ne doit **ni être corrigé ici, ni servir d'excuse** si un second test rougit.
> Un deuxième échec, quel qu'il soit, est une régression du chantier.

---

## Lot 2 — Dépendance Riverpod

**Fichiers**
- Modifier : `apps/pokemap_hub/pubspec.yaml`, `apps/pokemap_hub/pubspec.lock`

`analysis_options.yaml` et `build.yaml` ne sont **pas** touchés : sans codegen il n'y a ni fichier
généré à exclure, ni plugin `custom_lint` installable.

**Produit** : le runtime Riverpod, `ProviderContainer` et les overrides de test.

- [x] **Étape 2.1 — Établir ce qui est installable**

Avant d'écrire quoi que ce soit, faire trancher le solveur plutôt que de deviner :

```bash
cd apps/pokemap_hub && cp pubspec.yaml /tmp/pubspec.bak && cp pubspec.lock /tmp/pubspec.lock.bak
flutter pub add "freezed_annotation:^3.1.0"     # échoue : map_core épingle ^2.4.1
flutter pub add "dev:riverpod_generator:^4.0.0" # échoue : exige freezed_annotation ^3.0.0
flutter pub add "dev:riverpod_generator:^2.6.3" # échoue : exige analyzer ^6/^7, SDK impose >=13
flutter pub add "dev:freezed:^2.5.7"            # échoue : exige analyzer ^6/^7
cp /tmp/pubspec.bak pubspec.yaml && cp /tmp/pubspec.lock.bak pubspec.lock
```

**Résultat (7 août 2026)** : les 4 tentatives échouent. `flutter pub add` est atomique — le `pubspec.yaml`
est intact après chaque échec (vérifié par `diff`). Voir le bandeau du § Stack pour la matrice complète.

- [x] **Étape 2.2 — Ajouter la seule dépendance viable**

```bash
cd apps/pokemap_hub && flutter pub add "flutter_riverpod:^3.0.3"
```

**Résultat** : `+ flutter_riverpod 3.4.2`, `+ riverpod 3.4.2`, `+ listen 1.0.1`, `+ state_notifier 1.0.0`.
Une seule ligne ajoutée au `pubspec.yaml`, à sa place alphabétique. 32 lignes dans le `pubspec.lock`.

Ne **pas** ajouter `riverpod_annotation` : sans générateur, ses annotations sont inertes (YAGNI).
Ne **pas** ajouter `freezed_annotation` en dépendance directe : il arrive déjà transitivement par
`map_core` et `map_runtime`, et rien ne le consomme ici.

- [x] **Étape 2.3 — Prouver que le runtime fonctionne**

C'est le remplaçant du `build_runner build` à vide : une sonde jetable qui vérifie ce dont les lots
17-21 et 24 dépendent réellement — la résolution de providers et les overrides de test.

```dart
// test/tmp_riverpod_smoke_test.dart — à supprimer juste après
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider container resolves and honours overrides', () {
    final greeting = Provider<String>((ref) => 'hub');

    final plain = ProviderContainer();
    addTearDown(plain.dispose);
    expect(plain.read(greeting), 'hub');

    final overridden = ProviderContainer(
      overrides: [greeting.overrideWithValue('avelune')],
    );
    addTearDown(overridden.dispose);
    expect(overridden.read(greeting), 'avelune');
  });
}
```

```bash
cd apps/pokemap_hub && flutter test test/tmp_riverpod_smoke_test.dart && rm test/tmp_riverpod_smoke_test.dart
```

**Résultat** : `+1: All tests passed!`, sonde supprimée.

- [x] **Étape 2.4 — Vérifier la non-régression**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

**Résultat** : `No issues found!` et `+361 −1` — **strictement la référence de l'étape 1.6**.
L'unique échec reste celui de `selbrume`, documenté au lot 1.

- [x] **Étape 2.5 — Committer**

```bash
git add apps/pokemap_hub/pubspec.yaml apps/pokemap_hub/pubspec.lock && git commit -m "refactor(hub): add the riverpod runtime ahead of the layer migration"
```

---

# PHASE 2 — Translation structurelle

> ⚠️ **L'app ne compile pas entre le lot 3 et le lot 8.** Les commits des lots 3 à 7 sont des points de
> reprise, pas des états livrables. `flutter test` est inutilisable pendant cette phase : la vérification
> de chaque lot est **structurelle** (présence des fichiers, nature des erreurs d'analyse).
>
> Ne pas pousser. Ne pas interrompre la phase en cours de route sans avoir noté le lot atteint.

**Règle unique de la phase 2** : `git mv` seulement. **Aucun contenu de fichier n'est modifié**, sauf
les imports au lot 8. Un `git mv` conserve l'historique et rend le diff lisible.

## Lot 3 — `core/`

**Fichiers**

| Déplacement | Lignes |
|---|---:|
| `src/platform/hub_platform_adapter.dart` → `core/ports/hub_platform_port.dart` | 34 |
| `src/install/game_installation_ports.dart` → `core/ports/game_installation_ports.dart` | 30 |
| `src/platform/public_product_identity.dart` → `core/config/public_product_identity.dart` | 12 |
| `src/platform/avelune_host_compatibility.dart` → `core/config/avelune_host_compatibility.dart` | 18 |
| `src/ui/avelune/home/avelune_relative_time.dart` → `core/utils/relative_time.dart` | 30 |

- [x] **Étape 3.1 — Créer l'arborescence**

```bash
cd apps/pokemap_hub/lib && mkdir -p core/ports core/error core/diagnostics core/config core/utils
```

- [x] **Étape 3.2 — Déplacer**

```bash
cd apps/pokemap_hub/lib && git mv src/platform/hub_platform_adapter.dart core/ports/hub_platform_port.dart && git mv src/install/game_installation_ports.dart core/ports/game_installation_ports.dart && git mv src/platform/public_product_identity.dart core/config/public_product_identity.dart && git mv src/platform/avelune_host_compatibility.dart core/config/avelune_host_compatibility.dart && git mv src/ui/avelune/home/avelune_relative_time.dart core/utils/relative_time.dart
```

- [x] **Étape 3.3 — Vérifier**

```bash
cd apps/pokemap_hub/lib && ls core/ports core/config core/utils
```

Attendu : `hub_platform_port.dart` et `game_installation_ports.dart` dans `core/ports/`,
`public_product_identity.dart` et `avelune_host_compatibility.dart` dans `core/config/`,
`relative_time.dart` dans `core/utils/`. Les dossiers `core/error/` et `core/diagnostics/` sont vides —
c'est normal : `core/diagnostics/` se remplit au lot 9, `core/error/` au lot 14.

- [x] **Étape 3.4 — Committer**

```bash
git add -A apps/pokemap_hub/lib && git commit -m "refactor(hub): move cross-cutting ports and config to core (wip, does not compile)"
```

---

## Lot 4 — `platform/`

**Fichiers**

| Déplacement | Lignes |
|---|---:|
| `src/platform/android_hub_platform_adapter.dart` → `platform/android_hub_platform_adapter.dart` | 67 |
| `src/platform/ios_hub_platform_adapter.dart` → `platform/ios_hub_platform_adapter.dart` | 36 |
| `src/platform/macos_hub_platform_adapter.dart` → `platform/macos_hub_platform_adapter.dart` | 83 |
| `src/platform/hub_platform_adapter_factory.dart` → `platform/hub_platform_adapter_factory.dart` | 15 |

`src/platform/hub_composition.dart` (247 l.) **reste sur place** — il est traité au lot 19.

- [x] **Étape 4.1 — Déplacer**

```bash
cd apps/pokemap_hub/lib && mkdir -p platform && git mv src/platform/android_hub_platform_adapter.dart src/platform/ios_hub_platform_adapter.dart src/platform/macos_hub_platform_adapter.dart src/platform/hub_platform_adapter_factory.dart platform/
```

- [x] **Étape 4.2 — Vérifier ce qui reste**

```bash
cd apps/pokemap_hub/lib && ls src/platform/
```

Attendu : `hub_composition.dart` **seul**.

- [x] **Étape 4.3 — Committer**

```bash
git add -A apps/pokemap_hub/lib && git commit -m "refactor(hub): move native adapters to platform (wip, does not compile)"
```

---

## Lot 5 — `features/`

C'est le plus gros lot de la phase : 40 fichiers, 7 features.

- [x] **Étape 5.1 — Créer l'arborescence des 7 features**

```bash
cd apps/pokemap_hub/lib && mkdir -p features/library/{domain/{entities,repositories},application/use_cases,data/{codecs,repositories}} features/installation/{domain/{entities,repositories,services},application/use_cases,data/{repositories,sources}} features/saves/{domain/{entities,repositories},application/services,data/repositories} features/session/{domain/{entities,repositories},application/{services,gateways},data/repositories} features/preferences/{domain/repositories,data/repositories} features/appearance/{domain/{entities,repositories},application/notifiers,data/repositories} features/dashboard/application/{notifiers,services}
```

- [x] **Étape 5.2 — `library` (3 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/library/game_library.dart features/library/domain/entities/game_library.dart && git mv src/library/game_library_codec.dart features/library/data/codecs/game_library_codec.dart && git mv src/library/game_library_store.dart features/library/data/repositories/game_library_repository_impl.dart
```

- [x] **Étape 5.3 — `installation` (7 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/install/game_installation_transaction.dart features/installation/domain/entities/game_installation_transaction.dart && git mv src/install/game_installation_diagnostic.dart features/installation/domain/entities/game_installation_diagnostic.dart && git mv src/install/game_package_installer.dart features/installation/data/repositories/game_package_installer.dart && git mv src/install/installed_game_verifier.dart features/installation/data/repositories/installed_game_verifier.dart && git mv src/install/game_maintenance_service.dart features/installation/data/repositories/game_maintenance_service.dart && git mv src/install/editor_export_install_inbox.dart features/installation/data/repositories/editor_export_install_inbox.dart && git mv src/install/file_package_source.dart features/installation/data/sources/file_package_source.dart
```

- [x] **Étape 5.4 — `saves` (7 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/saves/save_profile.dart features/saves/domain/entities/save_profile.dart && git mv src/saves/save_slot_metadata.dart features/saves/domain/entities/save_slot_metadata.dart && git mv src/saves/save_storage_diagnostic.dart features/saves/domain/entities/save_storage_diagnostic.dart && git mv src/saves/hub_save_profile_manager.dart features/saves/application/services/hub_save_profile_manager.dart && git mv src/lifecycle/hub_save_lifecycle_coordinator.dart features/saves/application/services/hub_save_lifecycle_coordinator.dart && git mv src/saves/hub_save_store.dart features/saves/data/repositories/hub_save_repository_impl.dart && git mv src/saves/legacy_global_save_importer.dart features/saves/data/repositories/legacy_global_save_importer.dart
```

- [x] **Étape 5.5 — `session` (12 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/session/save_read_handle.dart features/session/domain/entities/save_read_handle.dart && git mv src/ui/player/hub_player_launch_intent.dart features/session/domain/entities/hub_player_launch_intent.dart && git mv src/player/hub_runtime_external_exit.dart features/session/domain/entities/hub_runtime_external_exit.dart && git mv src/session/hub_in_process_session_factory.dart features/session/application/services/hub_in_process_session_factory.dart && git mv src/player/hub_session_checkpoint_committer.dart features/session/application/services/hub_session_checkpoint_committer.dart && git mv src/player/hub_runtime_game_source.dart features/session/application/services/hub_runtime_game_source.dart && git mv src/player/hub_player_save_gateway.dart features/session/application/gateways/hub_player_save_gateway.dart && git mv src/player/hub_player_preferences_gateway.dart features/session/application/gateways/hub_player_preferences_gateway.dart && git mv src/session/installed_game_launch_resolver.dart features/session/data/repositories/installed_game_launch_resolver.dart && git mv src/session/package_asset_resolver.dart features/session/data/repositories/package_asset_resolver.dart && git mv src/player/hub_control_profile_store.dart features/session/data/repositories/control_profile_repository_impl.dart
```

- [x] **Étape 5.6 — `preferences` et `appearance` (7 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/preferences/hub_preferences_store.dart features/preferences/data/repositories/hub_preferences_repository_impl.dart && git mv src/ui/avelune/appearance/avelune_appearance_preferences.dart features/appearance/domain/entities/avelune_appearance_preferences.dart && git mv src/ui/avelune/appearance/avelune_appearance_catalog.dart features/appearance/domain/entities/avelune_appearance_catalog.dart && git mv src/ui/avelune/appearance/avelune_appearance_controller.dart features/appearance/application/notifiers/avelune_appearance_notifier.dart && git mv src/ui/avelune/appearance/avelune_appearance_store.dart features/appearance/data/repositories/avelune_appearance_repository_impl.dart && git mv src/ui/avelune/appearance/avelune_custom_background_importer.dart features/appearance/data/repositories/custom_background_repository_impl.dart
```

- [x] **Étape 5.7 — `dashboard` (1 fichier, éclaté plus tard)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/hub_dashboard_controller.dart features/dashboard/application/notifiers/hub_dashboard_notifier.dart
```

- [x] **Étape 5.8 — Vérifier que les dossiers sources sont vides**

`git mv` **ne supprime pas** les répertoires qu'il vide. Les retirer explicitement :

```bash
cd apps/pokemap_hub/lib && find src -type d -empty -delete && ls src/library src/install src/saves src/session src/lifecycle src/player src/ui/preferences 2>&1
```

Attendu : `No such file or directory` pour les 7 chemins, et 35 fichiers répartis dans `features/`.

- [x] **Étape 5.9 — Committer**

```bash
git add -A apps/pokemap_hub/lib && git commit -m "refactor(hub): slice business code into seven features (wip, does not compile)"
```

---

## Lot 6 — `presentation/`

**Fichiers** : 47 fichiers UI.

- [x] **Étape 6.1 — Créer l'arborescence**

```bash
cd apps/pokemap_hub/lib && mkdir -p presentation/design_system/{foundation,components,theme,assets,motion} presentation/{theme,shell,startup,shared/artwork} presentation/features/home/{pages,widgets,state} presentation/features/player/{pages,state} presentation/features/settings/{pages,widgets} presentation/features/installation/widgets
```

- [x] **Étape 6.2 — Design system (déplacement sec, 27 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/avelune/design_system/foundation/* presentation/design_system/foundation/ && git mv src/ui/avelune/design_system/components/* presentation/design_system/components/ && git mv src/ui/avelune/design_system/theme/* presentation/design_system/theme/ && git mv src/ui/avelune/design_system/avelune_design_system.dart presentation/design_system/avelune_design_system.dart && git mv src/ui/avelune/assets/* presentation/design_system/assets/ && git mv src/ui/avelune/motion/avelune_feedback.dart src/ui/avelune/motion/avelune_interaction_state.dart src/ui/avelune/motion/avelune_motion.dart presentation/design_system/motion/ && git mv src/ui/avelune/motion/avelune_exchange_controller.dart src/ui/avelune/motion/avelune_insertion_controller.dart presentation/features/home/state/
```

> ⚠️ **`motion/` se scinde en deux.** `avelune_exchange_controller` et `avelune_insertion_controller`
> ne vont **pas** dans le design system : ce sont des contrôleurs d'animation consommés uniquement par
> `presentation/features/home/`, et `exchange` utilise des `Duration(` bruts. Le test existant
> `avelune_design_system_test.dart` (« component layer cannot introduce raw visual primitives ») les
> refuse, à juste titre. Seuls `avelune_feedback`, `avelune_interaction_state` et le barrel
> `avelune_motion` sont des primitives d'interaction génériques.
>
> Le barrel `avelune_motion.dart` doit donc perdre les deux `export` correspondants, et
> `pokemap_hub_ui.dart` les ré-exporter explicitement depuis leur nouvel emplacement — l'API publique
> du barrel ne change pas (contrainte globale).

> Le design system est **le seul bloc dont le contenu ne doit pas bouger d'un octet**. Ses tests golden
> (`avelune_components_golden_test.dart`, `avelune_material_catalog_golden_test.dart`) doivent rester
> bit-à-bit identiques au lot 24. Toute différence de golden signale une erreur de déplacement.

- [x] **Étape 6.3 — Thème et suppression du ré-export mort**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/avelune/avelune_theme.dart presentation/theme/avelune_theme.dart && git rm src/ui/avelune/avelune_navigation.dart
```

`avelune_navigation.dart` ne contient qu'une ligne : `export 'design_system/components/avelune_bottom_navigation.dart';`.
Le barrel `avelune_design_system.dart` couvre déjà ce ré-export. Son entrée dans `pokemap_hub_ui.dart`
est retirée au lot 8.

- [x] **Étape 6.4 — Shell, startup, installation**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/hub_shell.dart presentation/shell/hub_shell.dart && git mv src/ui/hub_game_views.dart presentation/shell/hub_game_views.dart && git mv src/ui/hub_install_progress.dart presentation/features/installation/widgets/hub_install_progress.dart
```

- [x] **Étape 6.5 — Feature UI `home` (16 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/avelune/home/avelune_home_screen.dart presentation/features/home/pages/avelune_home_screen.dart && git mv src/ui/avelune/home/avelune_room_scene.dart src/ui/avelune/home/avelune_game_shelf.dart src/ui/avelune/home/avelune_hero_details_panel.dart src/ui/avelune/home/avelune_home_header.dart src/ui/avelune/home/avelune_insertion_hint.dart src/ui/avelune/home/avelune_cartridge_insertion_overlay.dart src/ui/avelune/home/avelune_cartridge_exchange_overlay.dart presentation/features/home/widgets/ && git mv src/ui/avelune/avelune_cartridge.dart src/ui/avelune/avelune_console.dart src/ui/avelune/avelune_game_details.dart src/ui/avelune/avelune_game_presentation.dart presentation/features/home/widgets/ && git mv src/ui/avelune/home/avelune_home_controller.dart src/ui/avelune/home/avelune_home_geometry.dart src/ui/avelune/home/avelune_home_view_data.dart src/ui/avelune/home/avelune_home_view_data_mapper.dart presentation/features/home/state/
```

- [x] **Étape 6.6 — Feature UI `player` (5 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/player/hub_installed_game_player.dart src/ui/player/hub_intro_video_player.dart src/ui/player/hub_save_profiles_screen.dart src/ui/player/hub_installed_player_strings.dart presentation/features/player/pages/ && git mv src/ui/player/hub_title_presentation_loader.dart presentation/features/player/state/hub_title_presentation_loader.dart
```

- [x] **Étape 6.7 — Feature UI `settings` (4 fichiers)**

```bash
cd apps/pokemap_hub/lib && git mv src/ui/avelune/settings/avelune_settings_menu.dart presentation/features/settings/pages/avelune_settings_menu.dart && git mv src/ui/avelune/appearance/avelune_appearance_settings.dart presentation/features/settings/pages/avelune_appearance_settings_page.dart && git mv src/ui/avelune/settings/avelune_storage_panel.dart src/ui/avelune/settings/avelune_motion_panel.dart presentation/features/settings/widgets/
```

- [x] **Étape 6.8 — Vérifier**

```bash
cd apps/pokemap_hub/lib && find src -type d -empty -delete && find src -type f | sort
```

Attendu : exactement **3 fichiers**, ceux du lot 7 — `src/bootstrap/hub_bootstrap.dart`,
`src/platform/hub_composition.dart`, `src/ui/hub_app.dart`. Total de `lib/` : 108 (109 moins
`avelune_navigation.dart`).

- [x] **Étape 6.9 — Committer**

```bash
git add -A apps/pokemap_hub/lib && git commit -m "refactor(hub): move ui to a feature-first presentation layer (wip, does not compile)"
```

---

## Lot 7 — `app/` et disparition de `lib/src/`

**Fichiers**

| Déplacement | Lignes |
|---|---:|
| `src/bootstrap/hub_bootstrap.dart` → `app/app_root.dart` | 235 |
| `src/ui/hub_app.dart` → `app/ui/app_widget.dart` | 252 |
| `src/platform/hub_composition.dart` → `app/di/hub_composition.dart` *(éclaté au lot 19)* | 247 |

- [x] **Étape 7.1 — Déplacer**

```bash
cd apps/pokemap_hub/lib && mkdir -p app/di app/ui && git mv src/bootstrap/hub_bootstrap.dart app/app_root.dart && git mv src/ui/hub_app.dart app/ui/app_widget.dart && git mv src/platform/hub_composition.dart app/di/hub_composition.dart
```

- [x] **Étape 7.2 — Supprimer `lib/src/`**

```bash
cd apps/pokemap_hub/lib && find src -type f | sort
```

Attendu : **sortie vide**. Puis seulement :

```bash
cd apps/pokemap_hub/lib && rm -rf src
```

- [x] **Étape 7.3 — Vérifier le compte**

```bash
cd apps/pokemap_hub/lib && find . -name '*.dart' | wc -l
```

Attendu : **108** (109 mesurés à l'étape 1.6, moins `avelune_navigation.dart` supprimé au lot 6).

- [x] **Étape 7.4 — Committer**

```bash
git add -A apps/pokemap_hub/lib && git commit -m "refactor(hub): promote composition root to app/ and drop lib/src (wip, does not compile)"
```

---

## Lot 8 — Réécriture des imports · **GATE DE PHASE**

C'est le lot qui remet l'app debout. Il touche les 107 fichiers de `lib/` et les 3 barrels.

**Produit** : l'app compile et les 88 fichiers de test passent — avec la nouvelle arborescence mais
encore l'ancienne sémantique (pas d'interfaces, pas de Riverpod).

- [x] **Étape 8.1 — Recenser les imports relatifs à traiter**

```bash
cd apps/pokemap_hub/lib && grep -rn "^import '\.\./\|^import '\./" --include="*.dart" . | wc -l
```

Noter le chiffre. Il devra tomber à 0 à l'étape 8.5.

- [x] **Étape 8.2 — Réécrire tous les imports en absolus**

Chaque `import '../install/game_package_installer.dart';` devient
`import 'package:pokemap_hub/features/installation/data/repositories/game_package_installer.dart';`.

Procéder fichier par fichier en s'appuyant sur l'analyseur plutôt qu'à l'aveugle :

```bash
cd apps/pokemap_hub && flutter analyze 2>&1 | grep "uri_does_not_exist" | head -40
```

Corriger le lot d'erreurs affiché, relancer, recommencer jusqu'à ce que `uri_does_not_exist` disparaisse.
La table de correspondance complète est le § 5 de la spec.

- [x] **Étape 8.3 — Mettre à jour `pokemap_hub.dart`**

Le barrel pur. **Les mêmes 19 symboles sont exportés**, seuls les chemins changent :

```dart
/// PokeMap Hub application composition contracts.
library;

export 'package:pokemap_hub/core/ports/game_installation_ports.dart';
export 'package:pokemap_hub/features/installation/data/repositories/editor_export_install_inbox.dart';
export 'package:pokemap_hub/features/installation/data/repositories/game_maintenance_service.dart';
export 'package:pokemap_hub/features/installation/data/repositories/game_package_installer.dart';
export 'package:pokemap_hub/features/installation/data/repositories/installed_game_verifier.dart';
export 'package:pokemap_hub/features/installation/data/sources/file_package_source.dart';
export 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
export 'package:pokemap_hub/features/library/data/codecs/game_library_codec.dart';
export 'package:pokemap_hub/features/library/data/repositories/game_library_repository_impl.dart';
export 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
export 'package:pokemap_hub/features/saves/application/services/hub_save_lifecycle_coordinator.dart';
export 'package:pokemap_hub/features/saves/application/services/hub_save_profile_manager.dart';
export 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
export 'package:pokemap_hub/features/saves/data/repositories/legacy_global_save_importer.dart';
export 'package:pokemap_hub/features/saves/domain/entities/save_profile.dart';
export 'package:pokemap_hub/features/saves/domain/entities/save_slot_metadata.dart';
export 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
```

- [x] **Étape 8.4 — Mettre à jour `pokemap_hub_ui.dart` et `pokemap_hub_player.dart`**

Mêmes symboles, nouveaux chemins. **Retirer** la ligne `export 'src/ui/avelune/avelune_navigation.dart';`
(fichier supprimé au lot 6 ; `avelune_design_system.dart` couvre déjà `AveluneBottomNavigation`).

- [x] **Étape 8.4 bis — Repointer les imports et les chemins codés en dur des tests**

> ⚠️ **Correction du plan.** Le repointage des tests était initialement prévu au lot 24. C'est trop
> tard : la suite est le **seul filet** des phases 3 à 5, elle ne peut pas rester incompilable jusqu'à
> la fin. Elle est donc repointée ici. Le lot 24 ne garde que la réorganisation des répertoires.

Deux passes distinctes :

1. **URI de package** — 77 occurrences de `package:pokemap_hub/src/...` dans `test/`, à résoudre avec
   la même table de renommage que l'étape 8.2.
2. **Chemins codés en dur** — 15 littéraux `'lib/src/...'` dans `test/platform/`, `test/release/` et
   `test/player/hub_player_architecture_boundary_test.dart`. Ces tests **lisent des fichiers source par
   chemin** ; ils cassent silencieusement sinon.

Trois assertions sont à corriger à la main, parce qu'elles portent sur le *contenu* et pas sur le chemin :

- `ios_distribution_contract_test.dart` attend `contains("../platform/public_product_identity.dart")` —
  devient `contains('package:pokemap_hub/core/config/public_product_identity.dart')`, et l'assertion
  jumelle sur `composition` de même.
- `avelune_design_system_test.dart` liste `Directory('lib/src/ui/avelune/design_system')` — devient
  `Directory('lib/presentation/design_system')`.
- `hub_player_architecture_boundary_test.dart` nomme 3 fichiers **dont il vérifie l'absence** ; les
  pointer vers leur emplacement dans la nouvelle arborescence pour que le garde-fou garde son sens.

- [x] **Étape 8.5 — Vérifier qu'il ne reste aucun import relatif**

```bash
cd apps/pokemap_hub/lib && grep -rn "^import '\.\./\|^import '\./" --include="*.dart" . | wc -l
```

Attendu : `0`.

- [x] **Étape 8.6 — Vérifier que le barrel pur reste pur**

```bash
cd apps/pokemap_hub && flutter test test/architecture/hub_architecture_boundary_test.dart
```

Attendu : vert. Ce test garantit que `pokemap_hub.dart` n'exporte ni `src/ui/`, ni le player, ni `map_player_ui`.
Il vérifie littéralement l'absence de la chaîne `src/ui/` — après le lot 7 ce chemin n'existe plus,
donc **remplacer les 3 assertions** par leurs équivalents sur la nouvelle arborescence :

```dart
  test('pure recovery barrel does not export Flutter player UI', () async {
    final source = await File('lib/pokemap_hub.dart').readAsString();

    expect(source, isNot(contains('presentation/')));
    expect(source, isNot(contains('pokemap_hub_player.dart')));
    expect(source, isNot(contains('map_player_ui')));
  });
```

- [x] **Étape 8.7 — GATE : analyse et tests complets**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

Attendu : **exactement les mêmes chiffres qu'à l'étape 1.6**. C'est la validation que la phase 2 n'a
rien changé d'autre que des chemins.

Si un test échoue ici, la cause est un déplacement erroné, pas une régression fonctionnelle :
comparer avec `git log --diff-filter=R --name-status` pour retrouver le fichier mal placé.

- [x] **Étape 8.8 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): rewrite imports onto the new layer tree"
```

---

# PHASE 3 — Décomposition des monolithes

*Cinq fichiers concentrent 4 645 lignes, soit 23 % de l'app. Chaque lot de cette phase se termine sur
`flutter analyze` + `flutter test` verts.*

**Cible de la phase** : aucun fichier de `lib/` au-dessus de 450 lignes.

## Lot 9 — Éclatement de `hub_dashboard_notifier.dart` (800 l.)

C'est le fichier le plus symptomatique : il porte des entités métier, de l'orchestration et du `dart:io`,
sous ce qui était `src/ui/`.

**Fichiers**
- Créer : `core/diagnostics/hub_diagnostic.dart`
- Créer : `features/dashboard/application/notifiers/hub_dashboard_state.dart`
- Créer : `features/dashboard/application/services/installed_game_activity_reader.dart`
- Modifier : `features/dashboard/application/notifiers/hub_dashboard_notifier.dart`

**Produit** (noms sur lesquels les lots 15, 18 et 20 s'appuient) :
- `HubDiagnostic`, `HubDiagnosticSeverity` — dans `core/diagnostics/`
- `HubDashboardStatus`, `HubSection`, `HubStorageSnapshot`, `HubGameActivity`, `HubGameView`, `HubDashboardSnapshot` — dans `hub_dashboard_state.dart`
- `InstalledHubGameActivityReader` — dans `installed_game_activity_reader.dart`
- `HubDashboardController` — reste dans `hub_dashboard_notifier.dart`, renommé en `HubDashboardNotifier` **au lot 20 seulement**

- [x] **Étape 9.1 — Extraire le contrat de diagnostic transverse**

Créer `lib/core/diagnostics/hub_diagnostic.dart` avec `HubDiagnosticSeverity` et `HubDiagnostic`,
copiés **sans modification** depuis les lignes 20-39 de `hub_dashboard_notifier.dart` :

```dart
enum HubDiagnosticSeverity { information, warning, error }

final class HubDiagnostic {
  const HubDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.recommendation,
    this.gameId,
    this.technicalDetails,
    this.logPath,
  });

  final String code;
  final HubDiagnosticSeverity severity;
  final String message;
  final String recommendation;
  final String? gameId;
  final String? technicalDetails;
  final String? logPath;
}
```

- [x] **Étape 9.2 — Extraire l'état de vue**

Créer `lib/features/dashboard/application/notifiers/hub_dashboard_state.dart` et y déplacer
`HubDashboardStatus`, `HubSection`, `HubStorageSnapshot`, `HubGameActivity`, `HubGameView`,
`HubDashboardSnapshot`. Ces classes restent en Dart brut — définitivement, pas seulement à ce lot :
la décision du lot 2 écarte freezed. Elles sont déjà immuables avec un `copyWith` manuel, ce qui est
exactement ce que freezed aurait produit.

- [x] **Étape 9.3 — Extraire le lecteur d'activité**

Déplacer `InstalledHubGameActivityReader` vers
`lib/features/dashboard/application/services/installed_game_activity_reader.dart`.

- [x] **Étape 9.4 — Vérifier la taille du reste**

```bash
cd apps/pokemap_hub && wc -l lib/features/dashboard/application/notifiers/hub_dashboard_notifier.dart
```

Attendu : **< 450**. Si c'est encore au-dessus, extraire aussi la gestion du journal de diagnostic
vers `features/dashboard/application/services/diagnostic_log_writer.dart`.

- [x] **Étape 9.5 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

Attendu : mêmes chiffres qu'à l'étape 1.6.

- [x] **Étape 9.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): split the dashboard controller into state, services and core diagnostics"
```

---

## Lot 10 — Éclatement de `game_package_installer.dart` (1 344 l.)

⚠️ **Le fichier le plus risqué du chantier.** Il porte les transactions d'installation, le staging, le
commit atomique et le rollback. **Ne modifier aucune règle métier**, uniquement déplacer des méthodes privées.

**Fichiers**
- Modifier : `features/installation/data/repositories/game_package_installer.dart` → ne garde que l'orchestration (`install`, `readCurrent`, `rebuildLibrary`, `_installLocked`)
- Créer : `features/installation/data/repositories/install_staging.dart` → `_createTransactionRoot`, `_copyPackageSnapshot`, `_extractSnapshot`, `_inspect`
- Créer : `features/installation/data/repositories/install_commit.dart` → `_publishLibrary`, `_writeJournal`, `_writeFlushed`, `_quarantineTransaction`, `_rebuildLibraryLocked`
- Créer : `features/installation/data/repositories/install_failures.dart` → `_formatFailure`, `_releaseFailure`, `_failure`, `_throwIfCancelled`, `_fault`
- Créer : `features/installation/domain/services/install_compatibility_rules.dart` → `_sameInspection`, `_branding`, `_verifyStaged` (partie pure)

- [x] **Étape 10.1 — Établir la référence des tests d'installation**

```bash
cd apps/pokemap_hub && flutter test test/install/
```

Noter le nombre de tests. Ces 6 fichiers (`game_install_recovery_test`, `game_package_installer_test`,
`game_package_branding_installation_test`, `installed_game_verifier_concurrency_test`,
`game_maintenance_service_test`, `editor_export_install_inbox_test`) sont la **référence de non-régression**
de ce lot. Ils doivent rester verts après **chaque** étape ci-dessous.

- [x] **Étape 10.2 — Extraire les règles pures vers `domain/services/`**

Sortir `_sameInspection` et `_branding` vers `install_compatibility_rules.dart` en fonctions publiques
sans état. Ce fichier atterrit dans `domain/` : il ne doit importer ni `dart:io`, ni `flutter`.

```bash
cd apps/pokemap_hub && grep -cE "^import 'dart:io'|^import 'package:flutter/" lib/features/installation/domain/services/install_compatibility_rules.dart
```

Attendu : `0`.

- [x] **Étape 10.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/install/
```

Attendu : même nombre de tests verts qu'à l'étape 10.1.

- [x] **Étape 10.4 — Extraire le staging**

Déplacer `_createTransactionRoot`, `_copyPackageSnapshot`, `_extractSnapshot`, `_inspect` vers
`install_staging.dart`, sous une classe `InstallStaging` prenant `supportRoot` et `inspector` au constructeur.

- [x] **Étape 10.5 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/install/
```

- [x] **Étape 10.6 — Extraire le commit et le rollback**

Déplacer `_publishLibrary`, `_writeJournal`, `_writeFlushed`, `_quarantineTransaction`,
`_rebuildLibraryLocked` vers `install_commit.dart`, sous une classe `InstallCommit`.

- [x] **Étape 10.7 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/install/
```

- [x] **Étape 10.8 — Extraire la fabrique d'erreurs**

Déplacer `_formatFailure`, `_releaseFailure`, `_failure`, `_throwIfCancelled`, `_fault` vers
`install_failures.dart`. **Les codes et messages d'erreur ne changent pas** — ils sont assertés par les tests.

- [x] **Étape 10.9 — Vérifier les tailles**

```bash
cd apps/pokemap_hub && wc -l lib/features/installation/data/repositories/*.dart lib/features/installation/domain/services/*.dart | sort -rn
```

Attendu : aucun fichier > 450 l.

- [x] **Étape 10.10 — Vérifier la suite complète**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 10.11 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): split the package installer into staging, commit, failures and pure rules"
```

---

## Lot 11 — Éclatement de `hub_save_repository_impl.dart` (926 l.)

Même prudence qu'au lot 10 : atomicité d'écriture, quarantaine, migration. Aucune règle ne bouge.

**Fichiers**
- Modifier : `features/saves/data/repositories/hub_save_repository_impl.dart` → façade publique (`write`, `writeVerified`, `read`, `saveProfile`, `deleteProfile`, `saveSlotMetadata`, `findContinue`, `deleteSlot`, `migrate`, `restoreMigrationSnapshot`)
- Créer : `features/saves/data/repositories/save_slot_reader.dart` → `_readLocked`, `_decodeCandidate`, `_isValid`, `_restoreAnyValidCurrent`
- Créer : `features/saves/data/repositories/save_atomic_writer.dart` → `_writeLocked`, `_quarantine`, `_fault`
- Créer : `features/saves/data/repositories/save_path_guard.dart` → `_assertAddressScope`, `_safeSlotDirectory`, `_safeProfileDirectory`, `_safeGameDirectory`, `_safeSupportRoot`, `_safeChildDirectory`, `_rejectLink`
- Créer : `features/saves/data/repositories/save_migration_runner.dart` → `_createMigrationSnapshot` + corps de `migrate` et `restoreMigrationSnapshot`

- [x] **Étape 11.1 — Établir la référence**

```bash
cd apps/pokemap_hub && flutter test test/saves/
```

Noter le compte. Les 5 fichiers de test (`hub_save_store_atomic_test`, `hub_save_store_isolation_test`,
`hub_save_migration_test`, `hub_save_profile_manager_test`, `legacy_global_save_importer_test`) sont
la référence de non-régression.

- [x] **Étape 11.2 — Extraire le garde-fou de chemins**

`save_path_guard.dart` d'abord : c'est la brique dont les trois autres dépendent. Elle porte les
protections anti-symlink et anti-évasion de répertoire — **ne pas les assouplir**.

- [x] **Étape 11.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/saves/
```

- [x] **Étape 11.4 — Extraire lecture, écriture, migration**

Dans cet ordre : `save_slot_reader.dart`, puis `save_atomic_writer.dart`, puis `save_migration_runner.dart`.
**Vérifier avec `flutter test test/saves/` après chacune des trois extractions**, pas seulement à la fin.

- [x] **Étape 11.5 — Vérifier les tailles**

```bash
cd apps/pokemap_hub && wc -l lib/features/saves/data/repositories/*.dart | sort -rn
```

Attendu : aucun fichier > 450 l.

- [x] **Étape 11.6 — Vérifier la suite complète**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 11.7 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): split the save store into reader, writer, path guard and migration runner"
```

---

## Lot 12 — Éclatement de `hub_shell.dart` (927 l.)

Le fichier contient **9 classes de widgets**. La découpe suit leurs frontières existantes, il n'y a
aucune méthode à réécrire.

**Fichiers**

| Fichier | Classes | Lignes actuelles | ≈ après |
|---|---|---|---:|
| `presentation/shell/hub_shell.dart` *(modifié)* | `HubShell` | 30-376 | ~350 |
| `presentation/shell/hub_shell_layout.dart` *(créé)* | `AveluneLetterboxBackdrop`, `HubViewportTooSmall` | 377-490 | ~115 |
| `presentation/shell/hub_shell_sections.dart` *(créé)* | `AveluneHomeContent`, `AvelunePreferencesContent`, `HubHeader` | 491-649 · 913-927 | ~175 |
| `presentation/shell/hub_shell_diagnostics.dart` *(créé)* | `HubStatusBanner`, `HubDiagnostics`, `DiagnosticCard` | 650-912 | ~265 |

> ⚠️ **Ces 8 classes sont aujourd'hui privées** (`_AveluneHomeContent`, `_DiagnosticCard`, …).
> Le privé Dart est à portée de **bibliothèque**, donc un widget privé ne peut pas traverser un fichier.
> Les rendre publiques en retirant le `_` (convention Grimaldi : les widgets d'un dossier `widgets/`
> ou `shell/` sont publics). Ne pas contourner avec `part` / `part of` : ça masquerait la découpe
> aux garde-fous du lot 23.

- [x] **Étape 12.1 — Établir la référence**

```bash
cd apps/pokemap_hub && flutter test test/ui/
```

Noter le compte. `avelune_home_chrome_test.dart` et `avelune_home_layout_ownership_test.dart` sont
les plus sensibles à ce lot.

- [x] **Étape 12.2 — Extraire les diagnostics**

Déplacer `_HubStatusBanner`, `_HubDiagnostics` et `_DiagnosticCard` vers `hub_shell_diagnostics.dart`,
en retirant le `_` de leurs trois noms et de toutes leurs références dans `HubShell`.

- [x] **Étape 12.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/ui/
```

- [x] **Étape 12.4 — Extraire le layout puis les sections**

Dans cet ordre : `_AveluneLetterboxBackdrop` + `_HubViewportTooSmall` vers `hub_shell_layout.dart`,
puis `_AveluneHomeContent` + `_AvelunePreferencesContent` + `_HubHeader` vers `hub_shell_sections.dart`.
**Vérifier avec `flutter test test/ui/` après chacune des deux extractions.**

- [x] **Étape 12.5 — Vérifier**

```bash
cd apps/pokemap_hub && wc -l lib/presentation/shell/*.dart && flutter analyze && flutter test
```

Attendu : aucun fichier > 450 l., suites vertes.

- [x] **Étape 12.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): split the shell into scaffold, layout, sections and diagnostics"
```

---

## Lot 13 — Éclatement de `hub_installed_game_player.dart` (648 l.)

Tout tient dans `_HubInstalledGamePlayerState` (lignes 60-637), qui mélange le cycle de vie de session,
le chargement de typographie et l'arbre de widgets.

**Fichiers**

| Fichier | Contenu | Lignes actuelles | ≈ après |
|---|---|---|---:|
| `presentation/features/player/pages/hub_installed_game_player.dart` *(modifié)* | `HubInstalledGamePlayer`, `build`, `_finishIntro`, `dispose` | 37-59 · 450-637 | ~230 |
| `presentation/features/player/state/installed_game_player_controller.dart` *(créé)* | `_initialize`, `_mountGame`, `_unmountGame`, `_handleSystemBack`, `didChangeAppLifecycleState`, `_recordFailure`, `_updateControlProfile`, `PlayerLaunchFailure` | 90-232 · 319-449 · 608-615 · 638-648 | ~300 |
| `presentation/features/player/state/player_typography_loader.dart` *(créé)* | `_loadTypography` | 233-318 | ~90 |

> `_PlayerLaunchFailure` devient `PlayerLaunchFailure` (public) : il traverse un fichier. Même raison
> qu'au lot 12.

- [x] **Étape 13.1 — Établir la référence**

```bash
cd apps/pokemap_hub && flutter test test/player/ test/session/
```

- [x] **Étape 13.2 — Extraire le chargeur de typographie**

`_loadTypography` (86 l.) est autonome et sans état : c'est l'extraction la moins risquée, à faire
en premier pour valider la mécanique.

- [x] **Étape 13.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test test/player/ test/session/
```

- [x] **Étape 13.4 — Extraire le contrôleur de session**

Déplacer le cycle de vie (`_initialize`, `_mountGame`, `_unmountGame`, `_handleSystemBack`,
`didChangeAppLifecycleState`, `_recordFailure`, `_updateControlProfile`) et `PlayerLaunchFailure`.
La page ne garde que `build`, `_finishIntro` et `dispose`.

- [x] **Étape 13.5 — Vérifier**

```bash
cd apps/pokemap_hub && wc -l lib/presentation/features/player/pages/*.dart lib/presentation/features/player/state/*.dart && flutter analyze && flutter test
```

- [x] **Étape 13.6 — Vérification de fin de phase 3**

```bash
cd apps/pokemap_hub && find lib -name '*.dart' -exec wc -l {} + | sort -rn | head -12
```

Attendu : **aucun fichier au-dessus de 450 lignes**. Si un fichier dépasse encore, l'inscrire au
« Journal des décisions » en fin de plan avec sa justification écrite, plutôt que de le laisser passer
en silence.

- [x] **Étape 13.7 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): extract the installed game player view controller"
```

---

# PHASE 4 — Inversion de dépendance

*C'est la phase qui apporte la valeur architecturale réelle : jusqu'ici on a rangé, maintenant on découple.*

## Lot 14 — Ports manquants, erreurs et adaptateurs natifs

**Fichiers**
- Créer : `core/ports/support_root_port.dart`
- Créer : `core/ports/diagnostic_log_port.dart`
- Créer : `core/ports/clock_port.dart`
- Créer : `core/error/hub_failure.dart`
- Créer : `platform/path_provider_support_root_adapter.dart`
- Créer : `platform/file_picker_background_picker.dart`
- Créer : `platform/isolate_background_image_processor.dart`
- Modifier : `core/ports/hub_platform_port.dart` (sortie de `HubPackagePickerFailure`)
- Modifier : `features/appearance/data/repositories/custom_background_repository_impl.dart`
- Modifier : `app/di/hub_composition.dart` (retrait de `_defaultSupportRoot`)

**Produit** : `SupportRootPort`, `DiagnosticLogPort`, `ClockPort`, `SystemClock`,
`PathProviderSupportRootAdapter`, et `HubPackagePickerFailure` relocalisé.

- [x] **Étape 14.1 — Écrire `support_root_port.dart`**

```dart
import 'dart:io';

/// Resolves the writable root the Hub owns on the host filesystem.
abstract interface class SupportRootPort {
  Future<Directory> resolve();
}
```

- [x] **Étape 14.2 — Écrire `diagnostic_log_port.dart`**

```dart
/// Appends Hub diagnostics to durable storage, outside the widget tree.
abstract interface class DiagnosticLogPort {
  Future<void> append(String line);
}
```

- [x] **Étape 14.3 — Écrire `clock_port.dart`**

```dart
/// Injectable clock so play-time and save recency stay testable.
abstract interface class ClockPort {
  DateTime now();
}

final class SystemClock implements ClockPort {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
```

- [x] **Étape 14.4 — Écrire l'adaptateur `path_provider`**

Créer `lib/platform/path_provider_support_root_adapter.dart` en y déplaçant le corps de
`HubComposition._defaultSupportRoot` :

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pokemap_hub/core/ports/support_root_port.dart';

final class PathProviderSupportRootAdapter implements SupportRootPort {
  const PathProviderSupportRootAdapter();

  @override
  Future<Directory> resolve() async {
    final platformRoot = await getApplicationSupportDirectory();
    return Directory(p.join(platformRoot.path, 'PokeMap'));
  }
}
```

- [x] **Étape 14.5 — Brancher l'adaptateur**

Dans `app/di/hub_composition.dart`, remplacer l'appel à `_defaultSupportRoot()` par
`const PathProviderSupportRootAdapter().resolve()` et supprimer la méthode privée.

- [x] **Étape 14.6 — Sortir l'exception du port**

`HubPackagePickerFailure` vit aujourd'hui dans `core/ports/hub_platform_port.dart`, à côté de l'interface.
C'est un type d'erreur, pas un contrat de port. Le déplacer vers `lib/core/error/hub_failure.dart`,
**sans modifier son corps** — ses `code`, `message` et `recommendation` sont assertés par
`test/platform/hub_platform_adapter_test.dart` :

```dart
/// Raised when the host file picker cannot deliver a package.
final class HubPackagePickerFailure implements Exception {
  const HubPackagePickerFailure({
    required this.code,
    required this.message,
    required this.recommendation,
    this.cause,
  });

  final String code;
  final String message;
  final String recommendation;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message Cause: $cause';
}
```

Trois adaptateurs la lèvent (`android_hub_platform_adapter.dart`, `macos_hub_platform_adapter.dart`)
et `app/di/hub_composition.dart` la rattrape : ajouter l'import `package:pokemap_hub/core/error/hub_failure.dart`
dans ces fichiers.

- [x] **Étape 14.7 — Extraire les deux adaptateurs natifs de l'importeur de fond**

`custom_background_repository_impl.dart` (482 l.) contient deux implémentations qui sont de
l'infrastructure de plateforme, pas de la donnée métier. Les déplacer vers `platform/` :

```bash
cd apps/pokemap_hub/lib && touch platform/file_picker_background_picker.dart platform/isolate_background_image_processor.dart
```

- `AveluneFilePickerBackgroundPicker` (implémente `AveluneBackgroundPicker`, utilise `file_picker`)
  → `platform/file_picker_background_picker.dart`
- `AveluneIsolateBackgroundImageProcessor` (implémente `AveluneBackgroundImageProcessor`, utilise `compute`)
  → `platform/isolate_background_image_processor.dart`

`AveluneLocalCustomBackgroundStorage` **reste** dans `data/repositories/` : c'est bien de la persistance.

- [x] **Étape 14.8 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 14.9 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): introduce core ports, move the picker failure to core/error and extract native background adapters"
```

---

## Lot 15 — Les 8 interfaces de repository

**Fichiers** — 7 à créer, 1 à déplacer.

> `AveluneCustomBackgroundGateway` **existe déjà** comme `abstract interface class` dans
> `custom_background_repository_impl.dart`. Ce n'est donc pas une écriture mais un déplacement vers
> `domain/repositories/`. Idem pour `AveluneBackgroundPicker`, `AveluneBackgroundImageProcessor` et
> `AveluneCustomBackgroundStorage`, déjà des interfaces.

**Produit** : les 8 noms sur lesquels les lots 16, 17 et 18 s'appuient.

- [x] **Étape 15.1 — `library`**

Créer `lib/features/library/domain/repositories/game_library_repository_interface.dart` :

```dart
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

abstract interface class GameLibraryRepositoryInterface {
  Future<GameLibraryRead> load();

  Future<void> save(GameLibrary library);
}
```

`GameLibraryRead`, `GameLibraryDiagnostic`, `GameLibraryStorageException` et l'enum `GameLibrarySource`
migrent de `data/repositories/game_library_repository_impl.dart` vers
`domain/entities/game_library.dart` : ce sont des types de retour du contrat, donc du domaine.

- [x] **Étape 15.2 — `installation`**

Créer `lib/features/installation/domain/repositories/game_installation_repository_interface.dart` :

```dart
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

abstract interface class GameInstallationRepositoryInterface {
  Future<GameInstallationResult> install(
    File package, {
    required GamePackageInstallSource source,
    GameInstallCancellationToken? cancellationToken,
    void Function(GameInstallProgress progress)? onProgress,
  });

  Future<InstalledGamePointer> readCurrent(String gameId);

  Future<GameLibrary> rebuildLibrary();
}
```

> ⚠️ `dart:io` dans un `domain/` viole la règle 1. **C'est une exception assumée** : `File` est le type
> d'entrée réel de l'installation d'un package local, et l'abstraire derrière un port de bytes changerait
> le comportement — ce que la contrainte globale interdit. L'inscrire dans l'allowlist du lot 23 avec
> ce motif, comme Grimaldi allowliste ses imports `Locale` en couche `application`.

- [x] **Étape 15.3 — `saves`**

Créer `lib/features/saves/domain/repositories/save_repository_interface.dart` :

```dart
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_profile.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_slot_metadata.dart';

abstract interface class SaveRepositoryInterface {
  Future<void> write(SaveEnvelope envelope);

  Future<SaveEnvelope> writeVerified(SaveEnvelope envelope);

  Future<SaveSlotRead> read(SaveSlotAddress address);

  Future<SaveSlotRead?> findContinue({String? profileId});

  Future<void> deleteSlot(SaveSlotAddress address);

  Future<void> saveProfile(SaveProfile profile);

  Future<void> deleteProfile(String profileId);

  Future<void> saveSlotMetadata({
    required SaveSlotAddress address,
    required SaveSlotMetadata metadata,
  });

  Future<SaveMigrationResult> migrate({required int targetVersion});

  Future<void> restoreMigrationSnapshot(SaveMigrationSnapshot snapshot);
}
```

Reprendre les signatures exactes de `hub_save_repository_impl.dart` — les paramètres nommés de `read`,
`saveSlotMetadata` et `migrate` doivent correspondre **au caractère près**, sinon les 5 fichiers de test
`test/saves/` ne compileront plus.

- [x] **Étape 15.4 — `session` (2 interfaces)**

Créer `lib/features/session/domain/repositories/session_launch_repository_interface.dart` :

```dart
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';

abstract interface class SessionLaunchRepositoryInterface {
  Future<InstalledGameLaunchContext> resolve(InstalledGame game);
}
```

`InstalledGameLaunchContext` et `InstalledGameLaunchException` migrent vers
`domain/entities/installed_game_launch_context.dart`.

Créer `lib/features/session/domain/repositories/control_profile_repository_interface.dart` :

```dart
import 'package:map_player_ui/map_player_ui.dart';

abstract interface class ControlProfileRepositoryInterface {
  Future<PlayerControlProfile> load();

  Future<void> save(PlayerControlProfile profile);
}
```

- [x] **Étape 15.5 — `preferences`**

Créer `lib/features/preferences/domain/repositories/player_preferences_repository_interface.dart` :

```dart
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';

abstract interface class PlayerPreferencesRepositoryInterface {
  Future<HubPreferencesRead> load();

  Future<void> save(PlayerPreferences preferences);
}
```

`HubPreferencesRead`, `HubPreferencesSource` et `HubPreferencesStorageException` migrent vers
`domain/entities/hub_preferences_read.dart`. Créer le dossier :

```bash
cd apps/pokemap_hub/lib && mkdir -p features/preferences/domain/entities
```

- [x] **Étape 15.6 — `appearance` (2 interfaces)**

Créer `lib/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart` :

```dart
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_read.dart';

abstract interface class AveluneAppearanceRepositoryInterface {
  Future<AveluneAppearanceRead> load();

  Future<void> save(AveluneAppearancePreferences preferences);
}
```

Puis **déplacer** les 4 interfaces déjà écrites — `AveluneCustomBackgroundGateway`,
`AveluneBackgroundPicker`, `AveluneBackgroundImageProcessor`, `AveluneCustomBackgroundStorage` —
de `data/repositories/custom_background_repository_impl.dart` vers
`domain/repositories/custom_background_repository_interface.dart`, **sans modifier une ligne de leur corps**.

- [x] **Étape 15.7 — Renommer les implémentations**

Chaque classe concrète prend le suffixe `Impl` et déclare `implements` :

| Classe actuelle | Nouveau nom | Implémente |
|---|---|---|
| `GameLibraryStore` | `GameLibraryRepositoryImpl` | `GameLibraryRepositoryInterface` |
| `GamePackageInstaller` | `GamePackageInstaller` *(inchangé, nom métier)* | `GameInstallationRepositoryInterface` |
| `HubSaveStore` | `HubSaveRepositoryImpl` | `SaveRepositoryInterface` |
| `InstalledGameLaunchResolver` | `InstalledGameLaunchResolver` *(inchangé)* | `SessionLaunchRepositoryInterface` |
| `HubControlProfileStore` | `ControlProfileRepositoryImpl` | `ControlProfileRepositoryInterface` |
| `HubPreferencesStore` | `HubPreferencesRepositoryImpl` | `PlayerPreferencesRepositoryInterface` |
| `AveluneAppearanceStore` | `AveluneAppearanceRepositoryImpl` | `AveluneAppearanceRepositoryInterface` |
| `AveluneLocalCustomBackgroundStorage` | *(inchangé)* | `AveluneCustomBackgroundStorage` *(déjà le cas)* |

Les renommages cassent les 88 fichiers de test — c'est attendu, ils sont repris au lot 24. Pour ce lot,
les corriger mécaniquement au fur et à mesure que `flutter analyze` les signale.

- [x] **Étape 15.8 — Vérifier la pureté du domaine**

```bash
cd apps/pokemap_hub && grep -rlE "^import 'package:flutter/|^import 'package:(flutter_)?riverpod" lib/features/*/domain/
```

Attendu : **sortie vide**. Puis, pour `dart:io` :

```bash
cd apps/pokemap_hub && grep -rl "dart:io" lib/features/*/domain/
```

Attendu : uniquement `features/installation/domain/repositories/game_installation_repository_interface.dart`
(exception documentée à l'étape 15.2).

- [x] **Étape 15.9 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 15.10 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): introduce eight repository interfaces and invert the data dependencies"
```

---

## Lot 16 — Substitution des types concrets par les interfaces

**Fichiers** — tous les fichiers de `features/*/application/` et `presentation/`.

**Produit** : plus aucune couche `application` ni `presentation` ne connaît une implémentation.

- [x] **Étape 16.1 — Recenser les violations**

```bash
cd apps/pokemap_hub && grep -rnE "RepositoryImpl|GameLibraryStore|HubSaveStore|HubPreferencesStore|AveluneAppearanceStore|HubControlProfileStore" lib/features/*/application lib/presentation
```

Noter chaque occurrence : c'est la liste de travail du lot.

- [x] **Étape 16.2 — Substituer, fichier par fichier**

Dans chaque fichier listé, remplacer le type concret par son interface (colonne de droite du tableau 15.7)
dans les champs, paramètres de constructeur et types de retour. **Ne changer aucun appel de méthode** :
les signatures sont identiques par construction.

- [x] **Étape 16.3 — Vérifier qu'il ne reste rien**

```bash
cd apps/pokemap_hub && grep -rnE "RepositoryImpl|GameLibraryStore|HubSaveStore|HubPreferencesStore|AveluneAppearanceStore|HubControlProfileStore" lib/features/*/application lib/presentation | wc -l
```

Attendu : `0`.

- [x] **Étape 16.4 — Vérifier que `presentation` ignore `data`**

```bash
cd apps/pokemap_hub && grep -rn "features/[a-z_]*/data/" lib/presentation | wc -l
```

Attendu : `0`.

- [x] **Étape 16.5 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 16.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): make application and presentation depend on interfaces only"
```

---

# PHASE 5 — Riverpod

*La DI manuelle de `hub_composition.dart` devient un graphe de providers. `hub_composition.dart`
disparaît au lot 19.*

## Lot 17 — `app/di/` : infrastructure et repositories

**Fichiers**
- Créer : `app/di/infrastructure_providers.dart`
- Créer : `app/di/library_repository_provider.dart`
- Créer : `app/di/installation_repository_provider.dart`
- Créer : `app/di/save_repository_provider.dart`
- Créer : `app/di/session_repository_provider.dart`
- Créer : `app/di/preferences_repository_provider.dart`
- Créer : `app/di/appearance_repository_provider.dart`
- Créer : `app/di/providers.dart`

**Produit** : `supportRootProvider`, `hubPlatformAdapterProvider`, `clockProvider`,
`gameLibraryRepositoryProvider`, `gameInstallationRepositoryProvider`, `saveRepositoryProvider`,
`sessionLaunchRepositoryProvider`, `controlProfileRepositoryProvider`,
`playerPreferencesRepositoryProvider`, `aveluneAppearanceRepositoryProvider`,
`customBackgroundRepositoryProvider`.

- [x] **Étape 17.1 — Écrire `infrastructure_providers.dart`**

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/core/ports/clock_port.dart';
import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/core/ports/support_root_port.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';

final supportRootPortProvider = Provider<SupportRootPort>(
  (ref) => const PathProviderSupportRootAdapter(),
);

/// Resolved once at startup and overridden in tests with a temporary directory.
final supportRootProvider = FutureProvider<Directory>((ref) async {
  final root = await ref.read(supportRootPortProvider).resolve();
  await root.create(recursive: true);
  return root;
});

final hubPlatformAdapterProvider = Provider<HubPlatformAdapter>((ref) {
  final adapter = createHubPlatformAdapter();
  ref.onDispose(adapter.dispose);
  return adapter;
});

final clockProvider = Provider<ClockPort>((ref) => const SystemClock());

final hostCompatibilityProvider = Provider<GamePackageHostCompatibility>(
  (ref) => aveluneHostCompatibility(),
);
```

> Pas de `part` ni de `@Riverpod` : décision du lot 2. Riverpod 3 garde les providers vivants par défaut
> tant qu'ils sont observés ; l'équivalent du `keepAlive: true` de Grimaldi s'obtient en les lisant
> depuis le `ProviderScope` racine, ce que fait `app_root.dart` au lot 19.

- [x] **Étape 17.2 — Écrire un provider par repository**

Modèle, à décliner pour les 6 fichiers `*_repository_provider.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/library/data/repositories/game_library_repository_impl.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';

/// Infrastructure wiring for the game library (outside the application layer).
final gameLibraryRepositoryProvider =
    FutureProvider<GameLibraryRepositoryInterface>((ref) async {
  return GameLibraryRepositoryImpl(
    supportRoot: await ref.watch(supportRootProvider.future),
  );
});
```

**C'est le seul endroit du code où une interface et son implémentation se rencontrent** (règle 6).

- [x] **Étape 17.3 — Écrire le barrel**

Créer `lib/app/di/providers.dart`. **Uniquement des `export`** (règle 7) :

```dart
/// Dependency injection barrel. Never declare a provider here.
library;

export 'package:pokemap_hub/app/di/appearance_repository_provider.dart';
export 'package:pokemap_hub/app/di/infrastructure_providers.dart';
export 'package:pokemap_hub/app/di/installation_repository_provider.dart';
export 'package:pokemap_hub/app/di/library_repository_provider.dart';
export 'package:pokemap_hub/app/di/preferences_repository_provider.dart';
export 'package:pokemap_hub/app/di/save_repository_provider.dart';
export 'package:pokemap_hub/app/di/session_repository_provider.dart';
```

- [x] **Étape 17.4 — Vérifier qu'aucun générateur n'a été réintroduit**

```bash
cd apps/pokemap_hub && grep -rn "@Riverpod\|\.g\.dart" lib/app/di/ | wc -l
```

Attendu : `0` — décision du lot 2.

- [x] **Étape 17.5 — Vérifier que le barrel ne déclare rien**

```bash
cd apps/pokemap_hub && grep -cE "^(final|const|class )" lib/app/di/providers.dart
```

Attendu : `0`.

- [x] **Étape 17.6 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 17.7 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): wire repositories through riverpod providers under app/di"
```

---

## Lot 18 — Providers applicatifs et use cases

**Fichiers**
- Créer : `features/library/application/use_cases/load_game_library_use_case.dart`
- Créer : `features/installation/application/use_cases/{install_game_package,verify_installed_game,run_game_maintenance,consume_editor_exports}_use_case.dart`
- Créer : `features/<f>/application/<f>_providers.dart` pour `library`, `installation`, `saves`, `session`, `appearance`, `dashboard`

**Produit** : `LoadGameLibraryUseCase`, `InstallGamePackageUseCase`, `VerifyInstalledGameUseCase`,
`RunGameMaintenanceUseCase`, `ConsumeEditorExportsUseCase` et leurs providers.

- [x] **Étape 18.1 — Écrire les use cases d'installation**

Modèle, calqué sur `LoadConsumptionPeriodUseCase` de Grimaldi — un use case = une classe, un `call()`,
des dépendances passées au constructeur :

```dart
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';

final class InstallGamePackageUseCase {
  const InstallGamePackageUseCase(this._repository);

  final GameInstallationRepositoryInterface _repository;

  Future<GameInstallationResult> call(
    File package, {
    GameInstallCancellationToken? cancellationToken,
    void Function(GameInstallProgress progress)? onProgress,
  }) {
    return _repository.install(
      package,
      source: GamePackageInstallSource.localFile,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }
}
```

- [x] **Étape 18.2 — Écrire les `<f>_providers.dart`**

Modèle :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';

final installGamePackageUseCaseProvider =
    FutureProvider<InstallGamePackageUseCase>((ref) async {
  return InstallGamePackageUseCase(
    await ref.watch(gameInstallationRepositoryProvider.future),
  );
});
```

- [x] **Étape 18.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 18.4 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): add application use cases and per-feature providers"
```

---

## Lot 19 — `ProviderScope` et suppression de `hub_composition.dart`

**Fichiers**
- Modifier : `main.dart`
- Modifier : `app/app_root.dart`
- Supprimer : `app/di/hub_composition.dart`

- [x] **Étape 19.1 — Envelopper l'app**

`main.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/app/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PokeMapHubApp()));
}
```

- [x] **Étape 19.2 — Réécrire `app_root.dart`**

`PokeMapHubBootstrap` porte aujourd'hui un `Future<HubAppComposition>` et un `StatefulWidget`.
Le remplacer par un `ConsumerWidget` qui observe `supportRootProvider` et rend les 3 états
(chargement, erreur, prêt) via les widgets de `presentation/startup/`. La logique d'ouverture de
package externe (`_pickAndImport`, `_importExternalPackage`) part dans
`features/dashboard/application/notifiers/hub_dashboard_notifier.dart`.

- [x] **Étape 19.3 — Supprimer la composition manuelle**

```bash
cd apps/pokemap_hub && git rm lib/app/di/hub_composition.dart
```

- [x] **Étape 19.4 — Vérifier qu'il n'en reste aucune trace**

```bash
cd apps/pokemap_hub && grep -rn "HubComposition\|HubAppComposition" lib/ test/ | wc -l
```

Attendu : `0`. Les tests qui construisaient une `HubComposition` passent par un `ProviderContainer`
avec overrides — ils sont repris au lot 24.

- [x] **Étape 19.5 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [x] **Étape 19.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): replace the manual composition root with a provider scope"
```

---

## Lot 20 — `HubDashboardNotifier`

**Fichiers**
- Modifier : `features/dashboard/application/notifiers/hub_dashboard_notifier.dart`
- Modifier : `features/dashboard/application/notifiers/hub_dashboard_state.dart`
- Créer : `features/dashboard/application/dashboard_providers.dart`

**Produit** : `HubDashboardNotifier`, `hubDashboardNotifierProvider`.

> ### 🔬 Reconnaissance du 7 août 2026 — tentative annulée
>
> Une première conversion a été menée jusqu'au bout côté `lib/` (analyse verte) puis **annulée**,
> faute de marge pour reprendre les tests. Ce qu'elle a établi, à reprendre tel quel :
>
> **La conversion elle-même fonctionne.** `HubDashboardNotifier extends Notifier<HubDashboardSnapshot>`,
> `build()` renvoie `HubDashboardSnapshot.initial()`, `_publish()` affecte `state`, `dispose()` devient
> `ref.onDispose`. `hub_composition.dart` tombe de 252 à **214 lignes** : elle reçoit le notifier au
> lieu d'assembler ses sept dépendances à la main.
>
> **Le point dur est l'asynchronisme.** Les dépendances pendent toutes à `supportRootProvider`, donc
> elles sont asynchrones, alors que l'état est synchrone. `build()` ne peut pas les attendre. Solution
> retenue : une méthode `_wire()` qui résout le graphe **une seule fois**, appelée en tête des trois
> entrées asynchrones publiques (`initialize`, `refresh`, `importPackage`). Aucune méthode ne peut
> alors tourner sur un notifier à moitié construit.
>
> **Côté UI, l'accroche est minuscule** : un seul fichier, `app_widget.dart`. `addListener` devient
> `ref.listenManual(hubDashboardNotifierProvider, ...)`, `ListenableBuilder` devient `ref.watch`, et le
> `removeListener` de `didUpdateWidget` disparaît — l'abonnement porte sur le provider, plus sur le
> champ du widget.
>
> **Le vrai coût est dans les tests.** `test/ui/hub_dashboard_controller_test.dart` construit le
> contrôleur sur **10 sites indépendants**, chacun avec ses propres fakes, sans helper partagé. Chaque
> site doit devenir un `ProviderContainer` surchargeant 6 à 7 providers. **Écrire d'abord un helper
> unique** qui construit ce conteneur, puis réécrire les 10 sites — c'est ce lot, et il ne tient pas
> dans la fin d'un autre.

- [ ] **Étape 20.1 — Laisser l'état en Dart brut**

Pas de `@freezed` (décision du lot 2). `HubDashboardSnapshot` est **déjà** une classe immuable avec
un `copyWith` manuel et des `factory` `.initial()` / `.ready(...)` — c'est exactement ce que freezed
aurait généré. **Ne rien changer à ce fichier** au-delà du déplacement fait au lot 9.

Vérifier simplement que l'immuabilité tient :

```bash
cd apps/pokemap_hub && grep -nE "^\s+(final|const)" lib/features/dashboard/application/notifiers/hub_dashboard_state.dart | wc -l
```

Attendu : tous les champs sont `final`. Un champ mutable serait à corriger ici.

- [ ] **Étape 20.2 — Convertir le `ChangeNotifier` en `Notifier`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HubDashboardNotifier extends Notifier<HubDashboardSnapshot> {
  @override
  HubDashboardSnapshot build() {
    // ...initialisation identique au constructeur actuel
    return HubDashboardSnapshot.initial();
  }
}

final hubDashboardNotifierProvider =
    NotifierProvider<HubDashboardNotifier, HubDashboardSnapshot>(
  HubDashboardNotifier.new,
);
```

Chaque `notifyListeners()` devient une affectation de `state`. Les méthodes publiques
(`importPackage`, `reportImportPickerFailure`, `selectGame`, `search`, `changeSection`, …) gardent
**exactement leurs noms et signatures** : elles sont appelées depuis `presentation/shell/` et testées.

Les dépendances lues dans le constructeur actuel (`libraryStore`, `preferencesStore`, `importer`, …)
se lisent désormais via `ref.read(...)` dans `build()`, sur les providers du lot 17.

- [ ] **Étape 20.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [ ] **Étape 20.4 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): turn the dashboard controller into a riverpod notifier with a freezed state"
```

---

## Lot 21 — `AveluneAppearanceNotifier` et `AveluneHomeController`

**Fichiers**
- Modifier : `features/appearance/application/notifiers/avelune_appearance_notifier.dart`
- Créer : `features/appearance/application/notifiers/avelune_appearance_state.dart`
- Créer : `features/appearance/application/appearance_providers.dart`
- Modifier : `presentation/features/home/state/avelune_home_controller.dart`

> **Décision posée dans la spec** : `avelune_exchange_controller` et `avelune_insertion_controller`
> **restent des `ChangeNotifier`**. Ils ne pilotent que de l'animation dans un seul widget, n'ont aucune
> dépendance métier et ne sortent jamais de `presentation/features/home/`. Ne pas les convertir.

- [ ] **Étape 21.1 — Convertir `AveluneAppearanceController`**

Même méthode qu'à l'étape 20.2. `initialize()` devient le corps de `build()`.

- [ ] **Étape 21.2 — Convertir `AveluneHomeController`**

Il vit en `presentation/features/home/state/` : il reste où il est, mais devient un `Notifier`
consommant `aveluneAppearanceNotifierProvider` et `hubDashboardNotifierProvider`.

- [ ] **Étape 21.3 — Vérifier**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [ ] **Étape 21.4 — Vérifier qu'il ne reste que les 2 ChangeNotifier d'animation**

```bash
cd apps/pokemap_hub && grep -rl "extends ChangeNotifier" lib/
```

Attendu : exactement `avelune_exchange_controller.dart` et `avelune_insertion_controller.dart`.

- [ ] **Étape 21.5 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): convert appearance and home controllers to riverpod notifiers"
```

---

# PHASE 6 — Verrouillage

*Sans cette phase, l'architecture se dégradera au premier ajout de feature. C'est elle qui rend le
chantier durable.*

## Lot 22 — Purge du `dart:io` en couche présentation

**Fichiers**
- Créer : `presentation/shared/artwork/local_artwork_image.dart`
- Modifier : les 13 fichiers de `presentation/` important encore `dart:io`

**Produit** : `localArtworkImage(String path)`.

- [ ] **Étape 22.1 — Recenser**

```bash
cd apps/pokemap_hub && grep -rl "dart:io" lib/presentation/
```

Attendu : 13 fichiers environ (les 15 d'origine moins ceux partis en `features/`).

- [ ] **Étape 22.2 — Écrire l'adaptateur unique**

```dart
import 'dart:io';

import 'package:flutter/widgets.dart';

/// The single presentation-layer bridge to the filesystem.
///
/// Read models expose artwork as `String` paths; this turns one into an
/// [ImageProvider] without leaking `dart:io` into the widget tree. Every other
/// file under `presentation/` must stay filesystem-free — enforced by
/// `test/architecture/dependency_rules_test.dart`.
ImageProvider<Object>? localArtworkImage(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}
```

- [ ] **Étape 22.3 — Substituer**

Dans les 13 fichiers, remplacer chaque `FileImage(File(...))` par `localArtworkImage(...)` et retirer
l'import `dart:io`.

Pour `hub_intro_video_player.dart` et `hub_title_presentation_loader.dart`, la dépendance n'est pas de
l'image : ils résolvent des chemins. Leur faire **recevoir** les chemins déjà résolus par
`features/session/data/repositories/package_asset_resolver.dart` au lieu de les calculer.

- [ ] **Étape 22.4 — Vérifier**

```bash
cd apps/pokemap_hub && grep -rl "dart:io" lib/presentation/
```

Attendu : **une seule ligne**, `lib/presentation/shared/artwork/local_artwork_image.dart`.

- [ ] **Étape 22.5 — Vérifier les tests**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

- [ ] **Étape 22.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "refactor(hub): confine filesystem access to a single presentation adapter"
```

---

## Lot 23 — Garde-fous automatiques

**Fichiers**
- Créer : `test/architecture/dependency_rules_test.dart`
- Conserver : `test/architecture/hub_architecture_boundary_test.dart` et `test/player/hub_player_architecture_boundary_test.dart` — ils gardent les frontières **inter-packages**, un sujet distinct

**Produit** : les 8 règles du § « Contraintes globales » deviennent exécutables.

- [ ] **Étape 23.1 — Écrire le test**

Créer `test/architecture/dependency_rules_test.dart` :

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Documented exceptions. Every entry needs a written reason.
const _allowlist = <String, String>{
  // `File` is the real input type of a local package install; abstracting it
  // behind a bytes port would change behaviour.
  'lib/features/installation/domain/repositories/game_installation_repository_interface.dart':
      'dart:io',
  // The single presentation bridge from artwork paths to ImageProvider.
  'lib/presentation/shared/artwork/local_artwork_image.dart': 'dart:io',
};

Future<List<({String path, String source})>> _dartFiles(String root) async {
  final files = <({String path, String source})>[];
  final directory = Directory(root);
  if (!directory.existsSync()) return files;
  await for (final entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }
    files.add((
      path: p.relative(entity.path),
      source: await entity.readAsString(),
    ));
  }
  return files;
}

bool _allowed(String path, String needle) => _allowlist[path] == needle;

void main() {
  test('rule 1 — domain layers are pure', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/domain/')) continue;
      for (final forbidden in <String>[
        "package:flutter/",
        "package:flutter_riverpod/",
        "package:riverpod_annotation/",
        "dart:io",
        "/data/",
        "/application/",
      ]) {
        if (file.source.contains(forbidden) && !_allowed(file.path, forbidden)) {
          violations.add('${file.path} imports $forbidden');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 2 — presentation never reaches into data', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation'))
        if (RegExp(r'features/[a-z_]+/data/').hasMatch(file.source))
          '${file.path} imports a data layer',
    ];
    expect(violations, isEmpty);
  });

  test('rule 3 — application never names an implementation', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/application/')) continue;
      for (final forbidden in <String>['RepositoryImpl', '/data/']) {
        if (file.source.contains(forbidden)) {
          violations.add('${file.path} references $forbidden');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 4 — data never reaches into presentation', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib/features')) {
      if (!file.path.contains('/data/')) continue;
      if (file.source.contains('pokemap_hub/presentation/')) {
        violations.add('${file.path} imports presentation');
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 5 — the design system is feature agnostic', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation/design_system'))
        if (file.source.contains('pokemap_hub/features/') ||
            file.source.contains('pokemap_hub/presentation/features/'))
          '${file.path} depends on a feature',
    ];
    expect(violations, isEmpty);
  });

  test('rule 6 — impl meets interface only in the di layer', () async {
    final violations = <String>[];
    for (final file in await _dartFiles('lib')) {
      if (file.path.startsWith('lib/app/di/')) continue;
      if (file.path.contains('/data/repositories/')) continue;
      if (RegExp(r'\bnew? ?[A-Za-z]*RepositoryImpl\(').hasMatch(file.source)) {
        violations.add('${file.path} instantiates an implementation');
      }
    }
    expect(violations, isEmpty);
  });

  test('rule 7 — the di barrel only re-exports', () async {
    final source = await File('lib/app/di/providers.dart').readAsString();
    final offending = source
        .split('\n')
        .where((line) => RegExp(r'^\s*(final|const|class|@Riverpod)').hasMatch(line))
        .toList();
    expect(offending, isEmpty);
  });

  test('rule 8 — presentation stays filesystem free', () async {
    final violations = <String>[
      for (final file in await _dartFiles('lib/presentation'))
        if (file.source.contains('dart:io') && !_allowed(file.path, 'dart:io'))
          '${file.path} imports dart:io',
    ];
    expect(violations, isEmpty);
  });
}
```

- [ ] **Étape 23.2 — Lancer les 8 sondes**

```bash
cd apps/pokemap_hub && flutter test test/architecture/dependency_rules_test.dart
```

Attendu : **8 tests verts**. Une sonde rouge n'est pas un test à assouplir : c'est une violation
introduite dans les phases 3 à 5, à corriger dans le code.

- [ ] **Étape 23.3 — Vérifier que les 2 tests de frontières historiques passent toujours**

```bash
cd apps/pokemap_hub && flutter test test/architecture/ test/player/hub_player_architecture_boundary_test.dart
```

- [ ] **Étape 23.4 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "test(hub): lock the eight layer dependency rules with automated probes"
```

---

## Lot 24 — Réalignement de `test/`

**Fichiers** — les 88 fichiers de `test/`.

**Produit** : l'arborescence de `test/` reflète celle de `lib/`, comme chez Grimaldi.

| Actuel | Cible |
|---|---|
| `test/library/` | `test/features/library/` |
| `test/install/` | `test/features/installation/` |
| `test/saves/` · `test/lifecycle/` | `test/features/saves/` |
| `test/session/` · `test/player/` | `test/features/session/` |
| `test/ui/avelune/appearance/` | `test/features/appearance/` |
| `test/ui/avelune/design_system/` · `assets/` | `test/presentation/design_system/` |
| `test/ui/avelune/home/` | `test/presentation/features/home/` |
| `test/platform/` | `test/platform/` *(inchangé)* |
| `test/architecture/` · `test/release/` · `test/support/` · `test/fixtures/` | *(inchangés)* |

- [ ] **Étape 24.1 — Déplacer**

```bash
cd apps/pokemap_hub/test && mkdir -p features/{library,installation,saves,session,appearance} presentation/{design_system,features/home} && git mv library/* features/library/ && git mv install/* features/installation/ && git mv saves/* lifecycle/* features/saves/ && git mv session/* features/session/ && git mv player/hub_control_profile_store_test.dart player/hub_player_preferences_gateway_test.dart player/hub_player_save_gateway_test.dart player/hub_runtime_game_source_test.dart features/session/ && git mv ui/avelune/appearance/* features/appearance/ && git mv ui/avelune/design_system/* ui/avelune/assets/* presentation/design_system/ && git mv ui/avelune/home/* presentation/features/home/
```

`test/player/hub_player_architecture_boundary_test.dart` **reste sur place** : c'est un test de
frontière inter-packages, pas un test de la feature `session`.

Puis supprimer les dossiers vidés :

```bash
cd apps/pokemap_hub/test && rmdir -p library install saves lifecycle session ui/avelune/appearance ui/avelune/design_system ui/avelune/assets ui/avelune/home 2>/dev/null; find . -type d -empty -delete
```

- [ ] **Étape 24.2 — Repointer les imports relatifs entre fichiers de test**

Les imports vers `lib/` ont déjà été traités à l'**étape 8.4 bis** — il ne reste ici que les imports
relatifs *entre* fichiers de test (`import '../support/game_package_fixture.dart'`), cassés par le
déplacement des répertoires, plus les chemins relatifs vers les goldens et les polices
(`'../../goldens/avelune/…'`, `'../../packages/map_editor/assets/fonts/…'`) dont la profondeur change.

```bash
cd apps/pokemap_hub && flutter analyze test 2>&1 | grep uri_does_not_exist | head -40
```

- [ ] **Étape 24.3 — Convertir les tests qui construisaient une composition**

Les tests qui appelaient `HubComposition.create(...)` passent par un `ProviderContainer` :

```dart
final container = ProviderContainer(
  overrides: [
    supportRootProvider.overrideWith((ref) async => temporaryDirectory),
    hubPlatformAdapterProvider.overrideWithValue(FakeHubPlatformAdapter()),
  ],
);
addTearDown(container.dispose);
```

- [ ] **Étape 24.4 — Vérifier les goldens du design system**

```bash
cd apps/pokemap_hub && flutter test test/presentation/design_system/
```

Attendu : verts **sans régénération**. Le design system a subi un déplacement sec (lot 6) — un golden
qui bouge signale une modification involontaire de son contenu, à investiguer et non à re-baseliner.

- [ ] **Étape 24.5 — Vérifier**

```bash
cd apps/pokemap_hub && flutter test
```

- [ ] **Étape 24.6 — Committer**

```bash
git add -A apps/pokemap_hub && git commit -m "test(hub): mirror the lib layer tree in the test tree"
```

---

## Lot 25 — Recette finale

- [ ] **Étape 25.1 — Analyse et tests**

```bash
cd apps/pokemap_hub && flutter analyze && flutter test
```

Attendu : 0 erreur, et **le même nombre de tests passants qu'à l'étape 1.6** — pas moins.
Un test disparu est une régression de couverture, pas une simplification.

- [ ] **Étape 25.2 — Vérifier qu'aucun code généré ne s'est glissé dans l'arbre**

```bash
cd apps/pokemap_hub && find lib -name '*.g.dart' -o -name '*.freezed.dart' | wc -l
```

Attendu : `0`. Le chantier n'utilise aucun générateur (décision du lot 2) ; un fichier généré signalerait
qu'une chaîne de codegen a été réintroduite en cours de route sans passer par le journal des décisions.

- [ ] **Étape 25.3 — Vérifier les 8 règles**

```bash
cd apps/pokemap_hub && flutter test test/architecture/
```

- [ ] **Étape 25.4 — Vérifier qu'aucun fichier n'a dérivé**

```bash
cd apps/pokemap_hub && find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' -exec wc -l {} + | sort -rn | head -6
```

Attendu : aucun fichier > 450 l.

- [ ] **Étape 25.5 — Lancer l'app pour de vrai**

```bash
cd apps/pokemap_hub && flutter run -d macos
```

Vérifier à la main : la home Avelune s'affiche, l'insertion de cartouche s'anime, l'import de package
s'ouvre, les réglages d'apparence persistent après redémarrage. **Les tests ne couvrent pas la
persistance réelle sur disque** — c'est le seul moyen de valider que `supportRoot` n'a pas bougé.

- [ ] **Étape 25.6 — Vérifier les frontières inter-packages**

```bash
cd apps/pokemap_hub && flutter test test/architecture/hub_architecture_boundary_test.dart && cd ../../packages/map_editor && flutter test
```

Le Hub ne doit toujours pas dépendre de l'éditeur, et l'éditeur ne doit pas dépendre du Hub.

- [ ] **Étape 25.7 — État final**

```bash
git status --short && git log --oneline -25
```

Attendu : working tree propre, 25 commits `refactor(hub):` / `test(hub):` lisibles.

---

## Journal des décisions

À tenir à jour pendant l'exécution. Toute dérogation à ce plan s'inscrit ici, avec son motif.

| Lot | Décision | Motif |
|---|---|---|
| 2 | Riverpod en runtime seul, providers écrits à la main, états en Dart brut | Aucune chaîne de codegen n'est installable : `map_core` épingle `freezed_annotation ^2.4.1` (hors périmètre) tandis que Dart 3.13 impose `analyzer >=13`. Vérifié par 4 échecs du solveur `pub` |
| 2 | `riverpod_annotation` et `freezed_annotation` non ajoutés en dépendances directes | Le premier est inerte sans générateur ; le second arrive déjà transitivement par `map_core` et n'est consommé par rien ici |
| 6 | `avelune_exchange_controller` et `avelune_insertion_controller` vont dans `presentation/features/home/state/`, pas dans `design_system/motion/` | Contredit la spec §5.11, mais confirmé par le test `avelune_design_system_test` : `exchange` utilise des `Duration(` bruts et les deux ne sont consommés que par la feature home. Le lot 21 le disait déjà |
| 8 | Repointage des tests avancé du lot 24 au lot 8 | La suite est le seul filet des phases 3 à 5 ; la laisser incompilable jusqu'au lot 24 aurait supprimé toute détection de régression pendant 16 lots |
| 9 | `hub_dashboard_notifier.dart` reste à 468 l., 18 au-dessus de la cible | Ce qui reste **est** l'orchestrateur. La seule coupe possible serait de déplacer 12 littéraux de diagnostic en français : ça déplace de la copie sans séparer de responsabilité. Renvoyé au chantier l10n déjà hors périmètre |
| 10 | `game_package_installer.dart` reste à 1 072 l. ; la cible de 450 est inatteignable par cette approche | Le plan supposait que la masse était dans les helpers. Elle est dans **deux méthodes** : `_installLocked` (478 l.) et `_recoverLocked` (172 l.). Extraire tous les helpers restants mènerait à ~870. Découper `_installLocked` — staging, vérification, commit et rollback d'une transaction atomique — mérite **son propre lot**, pas une coupe précipitée |
| 11 | `hub_save_repository_impl.dart` reste à 746 l. | Même cause qu'au lot 10 : `_readLocked` (100 l.) et `_writeLocked` (97 l.) portent le chemin d'écriture atomique. Les gardes de chemins, l'intégrité de slot et le mapper de compatibilité sont sortis ; le cœur transactionnel mérite son propre lot |
| 11 | Découpe par **nom de méthode**, plus par plage de lignes | Une première coupe 698-798 a emporté `_withFileLock` et `_queueSlot` avec les primitives d'intégrité. Ce sont des primitives de concurrence adossées au champ statique `_slotQueues` du store — remises en place |
| 13 | `hub_installed_game_player.dart` reste à 501 l. | Ce qui reste est le widget : `build` (143 l.) et `_initialize` (143 l.), tous deux liés à `setState` et au cycle de vie du `State`. Le lot 21 rouvrira ce fichier pour la bascule en `Notifier` — à traiter là plutôt qu'ici |
| 15 | **9e contrat non prévu** : `PackageAssetPort` | `InstalledGameLaunchContext` portait un `PackageAssetResolver` concret ; le passer en `domain/` aurait créé une dépendance domain → data. Le port est la couture |
| 15 | Le garde-fou de pureté du barrel testait le **texte**, pas le graphe | Exporter `hub_preferences_read.dart` a tiré `map_player_ui` (Flutter) dans le barrel pur : les tests de crash-recovery en sous-processus Dart ont cessé de compiler. Sonde ajoutée qui **compile** le barrel en Dart pur |
| 15 | Nouvelle référence de test : **+362 −1** | La sonde de pureté est le test supplémentaire |
| 16 | `hub_installed_game_player.dart` garde 3 imports vers `data/` | Même forme que le lecteur d'activité : la page construit ses dépendances. Le lot 19 la fait lire depuis les providers et supprime le problème. Corriger ici imposerait une factory temporaire que le lot 19 effacerait |
| 17 | Tout le graphe de repositories est en `FutureProvider` | `supportRoot` est résolu de façon asynchrone au démarrage ; c'est la forme honnête, et surcharger ce seul provider relocalise toute l'app en test |
| 18 | Les use cases `verify` et `maintenance` ne sont **pas** créés | Rien ne les appelle, et les méthodes de repository qu'ils envelopperaient ne portent aucune décision supplémentaire. Ils viendront avec la feature qui en aura besoin |
| 19 | **Ordre corrigé** : `hub_composition.dart` n'est pas supprimé au lot 19 | Le plan le supprimait avant que les lots 20-21 aient converti les `ChangeNotifier` qu'il construit — il aurait fallu recâbler deux fois. La composition est désormais **alimentée** par les providers ; sa suppression suit la conversion |
| 12-13 | 11 widgets et `_PlayerLaunchFailure` passent de privés à publics | Le privé Dart est à portée de bibliothèque : un symbole privé ne peut pas traverser un fichier. `part`/`part of` est écarté car il masquerait la découpe aux garde-fous du lot 23 |
| 15 | `dart:io` autorisé dans `game_installation_repository_interface.dart` | `File` est le type d'entrée réel d'une installation locale ; l'abstraire changerait le comportement, ce que la contrainte globale interdit |
| 21 | `avelune_exchange_controller` et `avelune_insertion_controller` restent des `ChangeNotifier` | Animation pure, sans dépendance métier, confinée à un seul widget |
| 22 | `local_artwork_image.dart` est le seul fichier de `presentation/` autorisé à importer `dart:io` | Pont unique entre les chemins d'artwork des read models et `ImageProvider` |
| | | |

---

## Hors périmètre

Signalé pour plus tard, **à ne pas traiter dans ce chantier** :

- Extraction des chaînes UI vers un `l10n/` — le Hub est monolingue français en dur.
- Un `scripts/check_presentation_boundaries.sh` en complément du test Dart, comme chez Grimaldi.
- L'objectif de 100 % de couverture que Grimaldi s'impose : le Hub n'a pas de `coverage.sh`.
- Le découpage de `installation` en `installation` + `maintenance`, écarté au moment du design.
