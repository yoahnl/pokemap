# Personalization Studio V3 — Objectif réel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan lot by lot. Each lot ends with its own tests, evidence and commit.

**Goal:** Livrer le Personalization Studio réellement attendu : une interface immédiatement compréhensible, une preview contextualisée avec les données du projet, des contrôles complets pour les six scènes et une consommation identique dans l’éditeur, les players Hub/standalone et les transports PokeMap.

**Architecture:** Les surfaces visibles restent possédées par `map_player_ui`. `map_editor` possède le scénario de preview et sélectionne des données réelles via des read models canoniques sans importer les types de `map_runtime`. Chaque champ persisté traverse verticalement `map_core`, `map_authoring`, `map_distribution`, `map_player_ui`, l’éditeur et MCP dans le même lot ; aucun champ uniquement sérialisé et aucun contrôle uniquement décoratif ne peuvent être déclarés terminés.

**Tech Stack:** Dart 3, Flutter, Riverpod, Freezed/JSON, PokeMap design system, `map_authoring`, JSONL/CLI, PokeMap MCP, widget/golden/integration tests.

---

## 0. Décision produit

La V2 reste la preuve historique du socle livré. Elle a installé :

- six scènes navigables ;
- les surfaces partagées `map_player_ui` ;
- la sauvegarde canonique, l’export, le Hub et le standalone ;
- les premiers profils de couleurs, fenêtres, layouts, polices, intro et Combat ;
- les matrices responsive, clavier, tactile, manette et mouvement réduit.

La V3 ne refait pas ce socle. Elle ferme l’écart entre ce socle et la proposition produit validée.

Une fonction n’est considérée comme livrée que si les quatre preuves suivantes existent :

1. le contrôle modifie une donnée projet canonique, ou porte explicitement le badge `Preview uniquement` ;
2. la preview montre le changement sur la même surface visible que le player ;
3. le Hub et le standalone consomment la valeur exportée ;
4. API directe, JSONL/CLI, éditeur et MCP exposent la même sémantique lorsqu’elle est persistée.

Le terme `Preview réelle` est réservé à une surface runtime alimentée par des données et assets du projet ouvert. Une fixture générique doit être annoncée `Scène de démonstration`.

## 1. Audit initial du checkout

### 1.1 État observé

- Branche auditée : `main`.
- Commit de départ : `19f8bc4f7`.
- État Git initial : propre et aligné sur `origin/main`.
- Profil de présentation courant : `ProjectPresentationProfile.supportedSchemaVersion == 5`.
- La preview emploie bien `PlayerTitleSurface`, `PlayerIntroVideoSurface`, `RuntimePlayerPauseShell`, `PlayerDialogueSurface` et `PlayerBattleSurface`.
- Les contenus Dialogue et Combat sont encore construits dans `PersonalizationPreviewFixtures` avec des valeurs fixes.
- `PersonalizationCharacterPreviewSource` utilise encore `PersonalizationCharacterPreviewFixtureSource` et un personnage sans portrait réel.
- `ProjectTypographyRoleProfile` ne possède aucune métrique de taille, graisse, hauteur de ligne ou espacement.
- `ProjectBrandingProfile` ne possède ni copie d’écran titre ni configuration des actions du menu titre.
- les options Portrait, Nom et Choix du Dialogue sont explicitement limitées à la preview.

### 1.2 Matrice d’écart

| Domaine | État V2 | Objectif V3 | Propriétaire |
|---|---|---|---|
| Contexte de preview | Fixtures fixes | Carte, personnage, dialogue et rencontre sélectionnés dans le projet | `map_editor` + read models authoring |
| Widgets visibles | Partagés | Conservés, sans renderer alternatif | `map_player_ui` |
| Couleurs | Tokens globaux, édition indirecte | Contrôles contextualisés par élément avec héritage visible | `map_core` + `map_player_ui` |
| Fenêtres | Rayon, contour, padding, ombre | Forme nommée, opacité, style par rôle et aperçu direct | `map_core` + `map_player_ui` |
| Typographie | Famille/asset uniquement | Famille, taille, graisse, interligne et espacement par rôle | `map_core` + `map_player_ui` |
| Écran titre | Assets, accent, musique, layout | Copie, actions, ordre, visibilité, icônes, boutons et motion réel | `map_player_ui` |
| Intro | Import et poster | Lecture réelle, captions, focal, replay et reduced motion | `map_player_ui` |
| Menu Pause | Labels, fenêtre, layout | Labels, icônes, ordre, visibilité, entrées et panneau détail | `map_player_ui` |
| Dialogue | Placement, fenêtre, police, toggles de démo | Bulle, portrait, cartouche nom, indicateur, choix et motion | Character Studio + `map_player_ui` |
| Combat | Layout, largeur, fenêtre, police | Commandes, HUD, PV, états, panneaux, labels, icônes et palettes | `map_player_ui` |
| Manipulation directe | Clic de ciblage | Drag/snap borné, resize sémantique et réglages responsive | `map_editor` |
| Propagation | Verticale V5 certifiée | Toute capacité V3 certifiée champ par champ | authoring/distribution/Hub/MCP |

### 1.3 Frontières conservées

- Personalization Studio ne crée ni personnages, ni portraits, ni sprites Pokémon, ni fonds de combat.
- Character Studio reste propriétaire des personnages, portraits et expressions.
- Encounter Studio reste propriétaire du contenu des rencontres.
- World Maps reste propriétaire des cartes et du décor d’overworld.
- Personalization Studio choisit un contexte de preview et personnalise sa présentation.
- Le Hub conserve une seule autorité de démarrage : `HubRuntimeStartupAdapter` applique `RuntimePlayerPresentation`; aucun `HubTitlePresentationLoader` parallèle n’est réintroduit.
- Aucune règle de combat, de dialogue ou de gameplay n’est modifiée ici.
- Aucun HUD d’exploration n’est inventé.
- Aucun positionnement pixel absolu fragile n’entre dans le projet : les gestes produisent des ancres, tailles, marges, ordres et contraintes responsive bornés.

## 2. Contrats cibles

### 2.1 Effet explicite de chaque contrôle

Créer un registre application-owned :

```dart
enum PersonalizationControlEffect { project, previewOnly, navigation }

final class PersonalizationCapabilityDescriptor {
  const PersonalizationCapabilityDescriptor({
    required this.id,
    required this.scene,
    required this.label,
    required this.effect,
    required this.inspectorTarget,
    this.projectPath,
    this.runtimeSurface,
  });

  final String id;
  final PersonalizationStudioScene scene;
  final String label;
  final PersonalizationControlEffect effect;
  final PersonalizationInspectorTarget inspectorTarget;
  final String? projectPath;
  final Type? runtimeSurface;
}
```

Règles :

- `project` exige `projectPath`, une mutation canonique et un test runtime ;
- `previewOnly` affiche ce statut à côté du contrôle ;
- `navigation` ne peut pas déclencher de sauvegarde ;
- un descriptor orphelin ou une clé UI sans descriptor fait échouer le test de registre.

### 2.2 Contexte réel, non persisté

```dart
final class PersonalizationPreviewContext {
  const PersonalizationPreviewContext({
    required this.mapId,
    required this.dialogueId,
    required this.characterId,
    required this.portraitStateId,
    required this.encounterTableId,
    required this.playerCreatureId,
    required this.enemyCreatureId,
  });

  final String? mapId;
  final String? dialogueId;
  final String? characterId;
  final String? portraitStateId;
  final String? encounterTableId;
  final String? playerCreatureId;
  final String? enemyCreatureId;
}
```

Ce contexte vit dans la session éditeur. Il ne doit apparaître ni dans `project.json`, ni dans un preset de présentation, ni dans un package joueur.

### 2.3 Évolution versionnée du profil

| Version présentation | Capacité ajoutée | Phase |
|---|---|---|
| V6 | métriques typo, forme/opacité des fenêtres | V3-B |
| V7 | copie et actions Écran titre | V3-C |
| V8 | actions et composition Menu Pause | V3-D |
| V9 | styles Dialogue : portrait, nom, choix, indicateur | V3-E |
| V10 | styles Combat : commandes, HUD, PV et panneaux d’état | V3-F |

Chaque migration conserve littéralement le rendu précédent lorsque le nouveau profil est absent. Une clé d’une version future placée dans un document ancien est rejetée ; elle n’est jamais promue silencieusement.

### 2.4 Types V6

```dart
enum ProjectWindowShape { rectangle, rounded, capsule, cutCorner, speech }

@freezed
abstract class ProjectTypographyMetricsProfile {
  const factory ProjectTypographyMetricsProfile({
    @Default(1) double sizeScale,
    @Default(400) int weight,
    @Default(1.25) double lineHeight,
    @Default(0) double letterSpacing,
  }) = _ProjectTypographyMetricsProfile;
}

@freezed
abstract class ProjectSurfacePaletteProfile {
  const factory ProjectSurfacePaletteProfile({
    String? background,
    String? surface,
    String? border,
    String? text,
    String? accent,
    String? selection,
  }) = _ProjectSurfacePaletteProfile;
}

@freezed
abstract class ProjectPresentationSurfacePalettesProfile {
  const factory ProjectPresentationSurfacePalettesProfile({
    ProjectSurfacePaletteProfile? title,
    ProjectSurfacePaletteProfile? pauseMenu,
    ProjectSurfacePaletteProfile? dialogue,
    ProjectSurfacePaletteProfile? battle,
  }) = _ProjectPresentationSurfacePalettesProfile;
}
```

`ProjectTypographyRoleProfile` reçoit `metrics`. `ProjectWindowStyleProfile` reçoit `shape` et `fillOpacity`. `ProjectPresentationProfile` reçoit `surfacePalettes`; chaque valeur nulle hérite du token sémantique global correspondant. Les bornes et couleurs sont validées dans `map_core` et prouvées à leurs valeurs minimales, maximales et juste hors limite.

### 2.5 Types V7

```dart
@freezed
abstract class ProjectMenuEntryPresentationProfile {
  const factory ProjectMenuEntryPresentationProfile({
    required String actionId,
    required String label,
    required String iconId,
    required int order,
    @Default(true) bool visible,
  }) = _ProjectMenuEntryPresentationProfile;
}

@freezed
abstract class ProjectTitlePresentationProfile {
  const factory ProjectTitlePresentationProfile({
    String? titleOverride,
    String? subtitle,
    String? prompt,
    @Default([]) List<ProjectMenuEntryPresentationProfile> actions,
  }) = _ProjectTitlePresentationProfile;
}

```

`newGame` reste visible. Les actions conditionnelles gardent leur disponibilité runtime ; la présentation ne contourne jamais les règles de sauvegarde ou de session.

### 2.6 Types V8

```dart
@freezed
abstract class ProjectPausePresentationProfile {
  const factory ProjectPausePresentationProfile({
    @Default([]) List<ProjectMenuEntryPresentationProfile> actions,
    @Default(true) bool showGameTitle,
    @Default(true) bool showInputHint,
  }) = _ProjectPausePresentationProfile;
}
```

`resume` reste visible. Les actions cachées ne peuvent ni recevoir le focus ni être déclenchées par un index historique.

### 2.7 Types V9

```dart
enum ProjectPortraitSide { start, end }
enum ProjectPortraitShape { square, rounded, circle, cutCorner }

@freezed
abstract class ProjectDialoguePresentationProfile {
  const factory ProjectDialoguePresentationProfile({
    @Default(ProjectPortraitSide.start) ProjectPortraitSide portraitSide,
    @Default(ProjectPortraitShape.rounded) ProjectPortraitShape portraitShape,
    @Default(ProjectPresentationContentWidth.compact)
    ProjectPresentationContentWidth portraitSize,
    @Default(true) bool showNameplate,
    @Default(true) bool showProgressIndicator,
    @Default(ProjectPresentationSpacing.normal)
    ProjectPresentationSpacing choiceSpacing,
  }) = _ProjectDialoguePresentationProfile;
}
```

Le contenu décide si un portrait, un nom ou des choix existent. Le profil décide uniquement comment ces éléments sont présentés lorsqu’ils existent.

### 2.8 Types V10

```dart
enum ProjectBattleCommandLayout { grid, list, radial }
enum ProjectBattleHpBarShape { flat, rounded, segmented }

@freezed
abstract class ProjectBattlePresentationProfile {
  const factory ProjectBattlePresentationProfile({
    @Default(ProjectBattleCommandLayout.grid)
    ProjectBattleCommandLayout commandLayout,
    @Default(2) int commandColumns,
    @Default(true) bool showCommandIcons,
    @Default(ProjectBattleHpBarShape.rounded)
    ProjectBattleHpBarShape hpBarShape,
    @Default(true) bool showOwnerLabel,
    @Default(true) bool showLevel,
    @Default(true) bool showExactHp,
    required String hpHealthyColor,
    required String hpWarningColor,
    required String hpDangerColor,
    required String statusColor,
  }) = _ProjectBattlePresentationProfile;
}
```

Les labels des commandes vivent dans les données de présentation versionnées et gardent les identifiants runtime stables. Le style ne change jamais l’action exécutée.

## 3. Vue d’ensemble des phases

| Phase | Lots | Résultat utilisable | Dépend de |
|---|---|---|---|
| V3-A — Vérité et contexte | PERS3-00 à PERS3-04 | Preview honnête alimentée par le projet | V2 |
| V3-B — Langage visuel complet | PERS3-05 à PERS3-08 | Couleurs, fenêtres et typo réellement complètes | V3-A |
| V3-C — Écran titre et Intro | PERS3-09 à PERS3-12 | Accueil et vidéo totalement éditables | V3-B |
| V3-D — Menu Pause | PERS3-13 à PERS3-15 | Actions, icônes, ordre et panneaux éditables | V3-B |
| V3-E — Dialogue et Character Studio | PERS3-16 à PERS3-20 | Portraits réels et bulle complète | CHS-010, CHS-023, CHS-035, CHS-036 |
| V3-F — Combat complet | PERS3-21 à PERS3-25 | Commandes, HUD, PV et quatre états éditables | V3-B |
| V3-G — Manipulation directe | PERS3-26 à PERS3-29 | Cliquer, déplacer et redimensionner sans casser le responsive | V3-C à V3-F |
| V3-H — Certification produit | PERS3-30 à PERS3-34 | Save/export/Hub/MCP/accessibilité et acceptation visuelle | toutes les phases |

## 4. Phase V3-A — Vérité et contexte projet

### Statut de clôture au 12 août 2026

Le tableau suivant est l'état autoritatif après la Phase R5. Les cases des spécifications détaillées plus bas décrivent les gates historiques du plan ; elles ne remplacent pas ce verdict fondé sur les preuves fraîches du rapport de clôture.

| Lot | Statut | Preuve principale |
|---|---|---|
| PERS3-00 | DONE | Registre canonique et correspondance exacte avec les contrôles visibles. |
| PERS3-01 | DONE | Fixture V10 déterministe avec les six scènes, assets et preflight réel. |
| PERS3-02 | DONE | `presentationPreviewContext` V2 révisionné et paginé. |
| PERS3-03 | DONE | Décor, dialogues, portraits et rencontre projetés depuis le projet ouvert. |
| PERS3-04 | DONE | Pickers lisibles, session-only et sans ID brut imposé. |
| PERS3-05 | DONE | Contrat V6 vertical pour typo, palettes et fenêtres. |
| PERS3-06 | DONE | Couleurs contextualisées reliées aux tokens canoniques. |
| PERS3-07 | DONE | Formes et opacité consommées par les surfaces player. |
| PERS3-08 | DONE | Inspecteur Style global et aperçu multi-surfaces. |
| PERS3-09 | DONE | Copie de titre V7 persistée avec fallbacks explicites. |
| PERS3-10 | DONE | Actions de titre configurables sans modifier la disponibilité gameplay. |
| PERS3-11 | DONE | Médias, motion et musique du titre projetés par le player. |
| PERS3-12 | DONE | Intro responsive, captions, focal point et reduced motion. |
| PERS3-13 | DONE | Neuf actions Pause configurables. |
| PERS3-14 | DONE | Composition, entrées, titre, hint et détail Pause. |
| PERS3-15 | DONE | Preview Pause fondée sur le shell runtime partagé. |
| PERS3-16 | DONE | Bridge Character Studio canonique, sans second catalogue. |
| PERS3-17 | DONE | Géométrie Dialogue V9 verticale. |
| PERS3-18 | DONE | Portrait et cartouche du nom configurables. |
| PERS3-19 | DONE | Choix, indicateur et motion Dialogue configurables. |
| PERS3-20 | DONE | Scénarios Dialogue réels et états dégradés honnêtes. |
| PERS3-21 | DONE | Commandes Combat V10 verticales. |
| PERS3-22 | DONE | HUD de combat, PV et statuts configurables. |
| PERS3-23 | DONE | Capacités, cible et message configurables. |
| PERS3-24 | DONE | Rencontre, acteurs et sprites résolus depuis le projet. |
| PERS3-25 | DONE | Inspecteur Combat ciblé par sous-section. |
| PERS3-26 | DONE | Graphe stable de cibles visuelles. |
| PERS3-27 | DONE | Drag, snap, resize et alternative clavier bornés. |
| PERS3-28 | DONE | Presets par scène, héritage et reset local. |
| PERS3-29 | DONE | Historique atomique et sauvegarde canonique déterministe. |
| PERS3-30 | DONE technique | Authoring `37/37`, MCP Presentation `3/3` et catalogue exact du worktree V10/V2 sur quatre transports. |
| PERS3-31 | DONE | Restart, export, installation Hub, standalone et parité de view-data V10. |
| PERS3-32 | DONE | Matrices Editor et Player, texte 200 %, clavier et manette vertes. |
| PERS3-33 | PARTIAL | Les 36 goldens et six contact sheets sont générés ; l'acceptation humaine de l'implémentation actuelle manque. |
| PERS3-34 | PARTIAL | Le nettoyage technique est vert ; son gate exige aussi l'approbation produit liée à PERS3-33. |

Verdict produit V3 : `PARTIAL`. Il ne reste pas une capacité technique cachée à implémenter dans cette roadmap ; il reste la revue visuelle humaine de l'interface actuelle et, si elle révèle des écarts, leur correction ciblée.

### PERS3-00 — Registre de capacités et interdiction des faux contrôles

- [ ] **Résultat :** chaque contrôle du Studio déclare s’il modifie le projet, uniquement la preview ou la navigation.
- **Fichiers :** créer `packages/map_editor/lib/src/features/personalization/application/personalization_capability_descriptor.dart` et `personalization_capability_registry.dart`; modifier les six inspecteurs et `personalization_scene_inspector.dart`.
- **Tests :** créer `packages/map_editor/test/personalization/personalization_capability_registry_test.dart`.
- **Cas négatifs :** `project` sans chemin, surface runtime sans test key, identifiant dupliqué, contrôle UI absent du registre.
- **Gate :** le texte `Preview réelle` disparaît lorsque le contexte est une fixture ; chaque option preview-only affiche un badge accessible.
- **Commit :** `refactor(personalization): make every studio control honest`.

### PERS3-01 — Projet d’acceptation visuelle déterministe

- [ ] **Résultat :** un seul projet fixture contient carte, titre, intro, personnage, dialogue, menu Pause et rencontre de combat ; PERS3-16 l’enrichit avec les portraits Character Studio lorsqu’ils deviennent canoniques.
- **Fichiers :** créer `examples/playable_runtime_host/golden_personalization_v3/`; modifier les tests Editor, Player, Hub et standalone pour charger cette racine.
- **Assets :** utiliser uniquement des assets versionnés du fixture ; charger une fonte de test réelle avec `FontLoader` pour que les goldens affichent du texte lisible.
- **Tests :** créer `packages/map_editor/test/personalization/personalization_v3_fixture_contract_test.dart` et `packages/map_player_ui/test/player/player_v3_fixture_contract_test.dart`.
- **Gate :** aucun texte n’apparaît sous forme de blocs Ahem dans les captures d’acceptation ; un asset absent produit un diagnostic nommé.
- **Commit :** `test(personalization): add the truthful v3 acceptance project`.

### PERS3-02 — Read models de contexte de preview

- [ ] **Résultat :** l’éditeur liste les cartes, dialogues, personnages/portraits et rencontres du projet ouvert.
- **Fichiers :** créer `packages/map_authoring/lib/src/domains/assets/presentation_preview_resources.dart`, enregistrer `presentation.previewContexts`; créer l’adapter Editor `personalization_preview_context_source.dart`.
- **Contrat :** lecture seule, paginée, révisionnée ; aucune sélection de preview n’est persistée.
- **Tests :** `packages/map_authoring/test/domains/assets/presentation_preview_resources_test.dart` et `packages/map_editor/test/personalization/personalization_preview_context_source_test.dart`.
- **MCP :** la ressource est découvrable car elle agrège des données projet ; la sélection locale de l’éditeur reste N/A et ce N/A est testé/documenté.
- **Gate :** une référence supprimée retombe sur le premier choix valide avec un message, jamais sur une ancienne valeur stale.
- **Commit :** `feat(authoring): expose personalization preview contexts`.

### PERS3-03 — Décors et acteurs réels dans la preview

- [ ] **Résultat :** Dialogue affiche une carte réelle en arrière-plan et Combat affiche le décor et les acteurs sélectionnés.
- **Fichiers :** créer `personalization_scene_stage.dart` dans Editor ; extraire `PlayerBattleScene` et ses view-data dans `packages/map_player_ui/lib/src/player/player_battle_scene.dart`; adapter `PlayerBattleOverlay` runtime et `PersonalizationPlayerSurfaceAdapter`.
- **Règle :** Dialogue superpose `PlayerDialogueSurface` à un `MapCanvas` read-only ; Combat partage `PlayerBattleScene` entre runtime et Editor.
- **Tests :** type identity Editor/runtime, asset manquant, portrait absent, map vide, encounter incomplet, deux orientations.
- **Gate :** aucun décor ou sprite n’est codé en dur dans `PersonalizationPreviewFixtures`.
- **Commit :** `feat(personalization): preview real project scenes`.

### PERS3-04 — Sélecteur de contexte compréhensible

- [ ] **Résultat :** une barre `Scène de test` permet de choisir carte, dialogue/personnage/expression et rencontre sans ID brut.
- **Fichiers :** créer `personalization_preview_context_picker.dart`; modifier `personalization_live_preview.dart`, `personalization_preview_controls.dart` et le workspace.
- **États :** chargement, aucun élément, élément invalide, contexte réel, démonstration de secours.
- **Tests :** clavier, lecteur d’écran, 720×900 à 200 %, changement rapide sans contenu stale.
- **Gate :** le badge annonce `Projet réel` ou `Démonstration`; la sélection ne marque pas le projet dirty.
- **Commit :** `feat(personalization): add real preview context selection`.

**Gate V3-A :** les six scènes s’ouvrent avec le projet d’acceptation ; Dialogue et Combat utilisent ses données ; le JSON du projet ne change pas quand seul le contexte de preview change.

## 5. Phase V3-B — Langage visuel complet

### PERS3-05 — Contrat visuel V6 et typographie verticale

- [ ] **Résultat :** V6 transporte et consomme métriques typographiques, palettes par surface, formes et opacité de fenêtre ; famille, taille, graisse, interligne et espacement sont déjà éditables pour Display, Corps, Dialogue, Combat et Nombres.
- **Fichiers :** modèles et génération `map_core`; validation/migration V5→V6; `presentation.update`; distribution; `RuntimePlayerPresentation`; `PokeMapPlayerTheme`; `PlayerPanel`; `ProjectTypographyEditor`.
- **Bornes :** `sizeScale 0.75..1.75`, graisses `300/400/500/600/700/800`, `lineHeight 1.0..1.8`, `letterSpacing -1..4`.
- **Tests :** chaque borne, valeurs non finies, fallback ancien projet, texte long, 200 %, séparation Dialogue/Combat/Nombres.
- **MCP :** preuves direct API, JSONL, Editor et live catalog V6 dans le même lot ; les palettes et formes sont consommées par le player avant que leurs inspecteurs spécialisés arrivent dans PERS3-06/07.
- **Gate :** chaque métrique produit une différence mesurable dans le widget player et reste stable après export/reload.
- **Commit :** `feat(personalization): author complete typography metrics`.

### PERS3-06 — Couleurs contextualisées sans duplication

- [ ] **Résultat :** chaque inspecteur montre les couleurs des éléments visibles de sa scène, tout en éditant les tokens sémantiques canoniques.
- **Fichiers :** créer `personalization_surface_color_editor.dart`; modifier les inspecteurs Global, Titre, Pause, Dialogue et Combat ; brancher les champs sur `surfacePalettes` V6.
- **Règle :** le contrôle affiche `Hérité de Style global` ou `Surcharge de scène`; une modification montre les surfaces impactées avant application.
- **Tests :** contraste texte/fond, sélection/bouton, héritage, reset, palette sûre, interdiction des couleurs invalides.
- **Gate :** aucune couleur d’interface feature n’est codée avec `Color(...)` ou `Colors.*` ; les hex projets restent dans les modèles validés.
- **Commit :** `feat(personalization): expose contextual surface colors`.

### PERS3-07 — Formes et opacité de fenêtre V6 verticales

- [ ] **Résultat :** rectangle, arrondie, capsule, angle coupé et bulle sont visibles dans les rôles autorisés, avec opacité de fond.
- **Fichiers :** compléter `ProjectWindowStudio` et les inspecteurs contextualisés sur le contrat V6 déjà consommé par `PlayerPanel`.
- **Règles :** `speech` autorisée pour Dialogue uniquement ; `capsule` refusée quand le contenu multi-ligne ne peut pas tenir ; absence V6 garde le rendu V5.
- **Tests :** chaque forme, opacité min/max, contraste composite, runtime Pause/Dialogue/Combat, vieux projet.
- **Gate :** aucun style accepté par le modèle n’est ignoré par `PlayerPanel`.
- **Commit :** `feat(personalization): add authored player window shapes`.

### PERS3-08 — Inspecteur Style global final

- [ ] **Résultat :** trois onglets simples `Couleurs`, `Fenêtres`, `Typographie` pilotent un collage des surfaces avec impact immédiat.
- **Fichiers :** modifier `personalization_global_style_inspector.dart`, `personalization_live_preview.dart`, `personalization_player_surface_adapter.dart` et le design system seulement si un primitive manque.
- **Tests :** navigation, reset par section, annuler/rétablir, erreurs de contraste, responsive et semantics.
- **Gate :** aucun ancien éditeur générique n’apparaît sans contexte ; les options avancées restent derrière `Plus de réglages`.
- **Commit :** `feat(personalization): finish the global style experience`.

## 6. Phase V3-C — Écran titre et Intro

### PERS3-09 — Copie d’écran titre V7 verticale

- [ ] **Résultat :** titre affiché, sous-titre et invitation sont éditables avec fallback explicite sur le nom du projet.
- **Fichiers :** ajouter `ProjectTitlePresentationProfile`; migrer V6→V7; propager authoring/distribution/MCP; consommer dans `PlayerTitleSurface`; ajouter les champs no-code à `PersonalizationTitleInspector`.
- **Validation :** longueurs, lignes, caractères de contrôle, chaîne vide versus fallback.
- **Tests :** ancien projet, overrides, reset, export/reload, Hub/standalone.
- **Gate :** la preview et le player affichent exactement la même copie.
- **Commit :** `feat(personalization): author title screen copy`.

### PERS3-10 — Actions et boutons du menu titre

- [ ] **Résultat :** labels, icônes, ordre et visibilité des actions du titre sont configurables sans changer leur disponibilité gameplay.
- **Fichiers :** modèle V7, `PlayerTitleSurfaceData`, `PlayerTitleSurface`, runtime title adapter, inspecteur Titre.
- **Règles :** `newGame` obligatoire ; action inconnue rejetée ; `continue/load` restent désactivées sans sauvegarde même si visibles.
- **Tests :** reorder, hide, duplicate, required action, clavier/manette, long labels, portrait.
- **Gate :** l’action déclenchée conserve son enum runtime après reorder.
- **Commit :** `feat(personalization): customize title menu actions`.

### PERS3-11 — Médias et motion du titre réellement lus

- [ ] **Résultat :** logo, fond, boucle prompt/menu et musique sont prévisualisés avec les mêmes fallbacks et reduced motion que le player.
- **Fichiers :** unifier `PlayerTitleMotion`, preview controller et player title runtime ; retirer le poster-only lorsque la vidéo est valide.
- **Tests :** play/pause, boucle, asset absent, portrait/landscape, reduced motion, musique concurrente, dispose.
- **Gate :** un seul contrôleur média actif ; changer de scène libère vidéo et audio.
- **Commit :** `feat(personalization): run real title media previews`.

### PERS3-12 — Intro réellement lisible et accessible

- [ ] **Résultat :** vidéo, poster, sous-titres, point focal, rejouer, passer et reduced motion sont testables dans la preview.
- **Fichiers :** `PlayerIntroVideoSurface`, lecteur partagé, `PersonalizationIntroInspector`, adapter.
- **Tests :** captions visibles, lecture/fin/replay/skip, vidéo invalide, poster absent, deux orientations, clavier/manette.
- **Gate :** Editor et player partagent le lecteur visible ou le même adapter public ; aucun faux bouton de lecture.
- **Commit :** `feat(personalization): preview the real intro lifecycle`.

## 7. Phase V3-D — Menu Pause complet

### PERS3-13 — Actions Pause V8 verticales

- [ ] **Résultat :** les neuf actions possèdent label, icône, ordre et visibilité configurables.
- **Fichiers :** remplacer progressivement `ProjectMenuLabelsProfile` par `ProjectPausePresentationProfile`; migration V7→V8, authoring, distribution, MCP, `RuntimePlayerPauseShell` et inspecteur Pause.
- **Règles :** `resume` obligatoire ; IDs et icônes fermés ; doublons interdits ; action cachée reste inaccessible au focus.
- **Tests :** Pokédex→Bestiaire, reorder, hide, required, enabled/disabled, export/reload.
- **Gate :** la navigation clavier/manette suit l’ordre visible et non l’ordre enum historique.
- **Commit :** `feat(personalization): customize pause actions end to end`.

### PERS3-14 — Entrées, panneaux et détail Pause

- [ ] **Résultat :** taille des entrées, espacement, disposition, titre, hint et panneau détail sont configurables avec presets responsive.
- **Fichiers :** étendre le profil Pause et `PlayerPauseSurface`; adapter `RuntimePlayerPauseShell`; compléter `PersonalizationPauseInspector`.
- **Tests :** gauche/centre/droite, compact/normal/grand, detail visible/masqué, safe area, labels longs.
- **Gate :** aucune configuration ne masque Resume ou sort le focus de l’écran.
- **Commit :** `feat(personalization): author the complete pause composition`.

### PERS3-15 — Preview Pause interactive fidèle

- [ ] **Résultat :** cliquer chaque entrée ouvre son vrai état de détail de démonstration et cible son réglage.
- **Fichiers :** fixtures de détail data-only, adapter, live preview et tests.
- **Règle :** les données de détail sont explicitement `Preview uniquement`; le menu, ses styles et sa navigation sont réels.
- **Tests :** toutes les actions, retour root, focus restore, tactile/clavier/manette.
- **Gate :** `RuntimePlayerPauseShell` reste l’unique shell visible.
- **Commit :** `test(personalization): certify the interactive pause preview`.

## 8. Phase V3-E — Dialogue et Character Studio

### PERS3-16 — Bridge Character Studio réel

- [ ] **Résultat :** le picker Dialogue liste les personnages, états de portrait et assets du projet.
- **Fichiers :** remplacer `PersonalizationCharacterPreviewFixtureSource` par un adapter sur `characterStudio.characters` et `characterStudio.character`; conserver une fixture seulement dans les tests.
- **Dépendances :** CHS-010, CHS-023 et CHS-031.
- **Tests :** aucun personnage, portrait manquant, expression supprimée, changement rapide, cache par révision.
- **Gate :** aucune valeur `character-studio-placeholder` ne subsiste en production.
- **Commit :** `feat(personalization): connect real character portraits`.

### PERS3-17 — Géométrie de bulle Dialogue V9 verticale

- [ ] **Résultat :** placement, largeur, marge, padding, forme, contour, opacité et couleurs sont éditables.
- **Fichiers :** `ProjectDialoguePresentationProfile`, migration V8→V9, authoring/distribution/MCP, theme/player dialogue et inspecteur. `PlayerDialogueSurface` consomme dès ce lot toutes les propriétés V9 explicites ; PERS3-18/19 ajoutent ensuite leurs contrôles spécialisés.
- **Tests :** top/bottom/center, narrow/wide, speech shape, texte long, safe area, ancien profil.
- **Gate :** chaque propriété acceptée modifie une mesure ou un pixel du `PlayerDialogueSurface`.
- **Commit :** `feat(personalization): author complete dialogue geometry`.

### PERS3-18 — Portrait et cartouche du nom

- [ ] **Résultat :** côté, taille, forme et cadre du portrait ainsi que le cartouche du nom sont personnalisables.
- **Dépendances :** CHS-035 et CHS-036 pour la résolution runtime réelle.
- **Fichiers :** profil V9, `PlayerDialogueSurface`, runtime snapshot adapter, inspecteur Dialogue.
- **Tests :** portrait présent/absent, start/end, quatre formes, nom long, choix, portrait étroit, semantics décorative/informative.
- **Gate :** une référence Character valide donne le même asset dans Dialogue Studio, Personalization et runtime.
- **Commit :** `feat(personalization): style dialogue portraits and names`.

### PERS3-19 — Choix, indicateur et motion Dialogue

- [ ] **Résultat :** espacement/forme des choix, sélection, indicateur de progression et transition de portrait sont configurables.
- **Fichiers :** profil V9, `PlayerDialogueSurface`, thème, inspecteur.
- **Tests :** 2/4/8 choix, label long, disabled/selected, reduced motion, changement d’expression.
- **Gate :** le mouvement réduit retire les transitions sans retirer le changement d’état.
- **Commit :** `feat(personalization): customize dialogue choices and motion`.

### PERS3-20 — Scénarios Dialogue réels

- [ ] **Résultat :** le contexte choisit une ligne réelle avec personnage/expression, une ligne texte-only et un nœud de choix.
- **Fichiers :** preview context resources, adapter et picker.
- **Tests :** round-trip dialogue, référence orpheline, branche de choix, fallback legacy.
- **Gate :** les toggles de démo restent disponibles mais clairement séparés des réglages persistés.
- **Commit :** `test(personalization): certify real dialogue scenarios`.

## 9. Phase V3-F — Combat complet

### PERS3-21 — Menu de commandes Combat V10 vertical

- [ ] **Résultat :** grille/liste/radial, colonnes, icônes, labels, forme, padding, couleurs et sélection sont personnalisables.
- **Fichiers :** `ProjectBattlePresentationProfile`, migration V9→V10, authoring/distribution/MCP, `PlayerBattleSurface`, inspecteur Combat. La surface consomme dès ce lot toutes les propriétés V10 explicites ; PERS3-22/23 ajoutent ensuite les contrôles HUD et états.
- **Règles :** action IDs stables ; labels et icônes ne changent pas les commandes ; radial retombe sur grille en compact portrait si les cibles tactiles ne tiennent pas.
- **Tests :** quatre actions, labels longs, actions indisponibles, clavier/tactile/manette, responsive.
- **Gate :** chaque commande déclenche le même index avant et après reorder/style.
- **Commit :** `feat(personalization): customize battle commands end to end`.

### PERS3-22 — HUD, PV et statuts Combat

- [ ] **Résultat :** forme des panneaux, positions, informations visibles, forme/couleurs de PV et badge de statut sont configurables.
- **Fichiers :** profil V10, `PlayerBattleHud`, thèmes player, inspecteur Combat.
- **Tests :** healthy/warning/danger, 0/max HP, niveau/owner masqué, statut long, contraste, portrait.
- **Gate :** les seuils gameplay de PV restent runtime-owned ; Personalization ne définit que leurs couleurs et présentation.
- **Commit :** `feat(personalization): style battle hud and hp states`.

### PERS3-23 — Capacités, cible et message

- [ ] **Résultat :** les panneaux Capacités, Cible et Message possèdent leurs propres dispositions et styles héritables.
- **Fichiers :** profil V10, surface Combat, inspecteur et fixtures/read models.
- **Tests :** quatre capacités avec PP, indisponible, deux cibles, message long, retour, focus.
- **Gate :** aucun état réutilise silencieusement un style non présenté à l’utilisateur.
- **Commit :** `feat(personalization): customize every battle menu state`.

### PERS3-24 — Contexte de rencontre réel

- [ ] **Résultat :** le picker sélectionne une rencontre et deux créatures réelles, avec sprites et noms résolus depuis le projet.
- **Fichiers :** `presentation.previewContexts`, Encounter/Character/Pokémon read models, `PlayerBattleScene`.
- **Tests :** encounter vide, asset absent, espèce inconnue, shiny/genre si disponible, fallback explicite.
- **Gate :** Roucool et Brindibou ne sont plus des constantes de production.
- **Commit :** `feat(personalization): preview real project battles`.

### PERS3-25 — Inspecteur Combat final

- [ ] **Résultat :** sous-sections `Commandes`, `HUD et PV`, `Capacités`, `Cible`, `Message` ciblées depuis la preview.
- **Fichiers :** scinder `personalization_battle_inspector.dart` en widgets de section sous `inspectors/battle/`; conserver un orchestrateur court.
- **Tests :** ciblage direct, reset section, undo/redo, propagation instantanée dans quatre états et deux orientations.
- **Gate :** aucun écran de l’inspecteur n’expose plus de huit décisions simultanées ; les options avancées sont progressives.
- **Commit :** `feat(personalization): finish the battle customization workflow`.

## 10. Phase V3-G — Manipulation directe et presets

### PERS3-26 — Graphe de cibles visuelles

- [ ] **Résultat :** chaque élément cliquable de chaque surface possède une cible d’inspecteur stable.
- **Fichiers :** étendre `PersonalizationInspectorTarget`, surfaces player avec callbacks sémantiques et registre de capacités.
- **Tests :** toutes les cibles des six scènes, ordre de hit-test, éléments superposés, zones non éditables.
- **Gate :** cliquer un élément ne sélectionne jamais une section sans rapport.
- **Commit :** `feat(personalization): target every editable player element`.

### PERS3-27 — Drag, snap et resize responsive

- [ ] **Résultat :** déplacer ou redimensionner un élément convertit le geste en slot, largeur, marge et breakpoint bornés.
- **Fichiers :** créer `personalization_layout_gesture_planner.dart`, `personalization_layout_overlay.dart` et commandes accessibles équivalentes.
- **Règles :** preview fantôme avant commit, Escape annule, clavier propose déplacer/agrandir/réduire, aucune coordonnée pixel persistée.
- **Tests :** seuils snap, no-op, annulation, overflow refusé, compact/regular/expanded, 200 %.
- **Gate :** le JSON résultant contient uniquement les enums et valeurs bornées du profil.
- **Commit :** `feat(personalization): add bounded direct layout editing`.

### PERS3-28 — Presets par scène et héritage visible

- [ ] **Résultat :** chaque scène propose trois presets complets, copie depuis Style global et reset local.
- **Fichiers :** étendre `ProjectPresentationPreset`, bibliothèque Editor, codec distribution et tests d’assets.
- **Règles :** un preset annonce les sections remplacées ; application transactionnelle ; preview avant confirmation lorsqu’il écrase des réglages.
- **Tests :** assets, migration, undo, export/import, preset incomplet, ancien preset V5.
- **Gate :** aucun reset ne supprime un asset encore référencé sans plan.
- **Commit :** `feat(personalization): add complete scene presets`.

### PERS3-29 — Historique et sauvegarde UX

- [ ] **Résultat :** gestes, presets et changements de contexte ont des règles d’historique compréhensibles.
- **Règles :** un drag complet = une entrée undo ; contexte preview = aucune entrée ; preset = une entrée atomique ; autosave seulement après mutation projet valide.
- **Fichiers :** session controller, workspace, feedback et tests.
- **Tests :** undo/redo répété, autosave, erreur durable, changement de scène, fermeture/reopen.
- **Gate :** aucun succès UI avant confirmation de la mutation canonique et du document durable.
- **Commit :** `fix(personalization): make studio history and saves deterministic`.

## 11. Phase V3-H — Certification produit

### PERS3-30 — Parité authoring et MCP finale

- [ ] **Résultat :** le catalogue décrit V10 et chaque nouveau champ est prouvé sur quatre transports.
- **Fichiers :** tests parity, descriptors, MCP server tests et catalogue généré si nécessaire.
- **Scénario :** lire profil → appliquer Style global → modifier Titre/Pause/Dialogue/Combat → relire → exporter preset → importer → valider.
- **Gate :** PMCP-085 zéro ressource/action bloquée ou manquante ; `pokemap_describe` live provient du checkout testé.
- **Commit :** `test(personalization): certify full v3 authoring parity`.

### PERS3-31 — Save, export, Hub et standalone

- [ ] **Résultat :** un profil V10 complet survit au redémarrage Editor, package, installation Hub et lancement standalone.
- **Tests :** étendre Phase 6 avec les nouvelles propriétés et assets du projet d’acceptation.
- **Gate :** un seul loader de présentation ; package hashé ; aucun chemin absolu ; Hub et standalone produisent les mêmes view-data.
- **Commit :** `test(personalization): certify v3 delivery to every player`.

### PERS3-32 — Accessibilité, inputs et responsive

- [ ] **Résultat :** toutes les fonctions sont disponibles souris, clavier, tactile et manette lorsque pertinente.
- **Matrice :** 720×900, 1024×768, 1440×900, 1600×1000 ; text scale 1×, 1.5×, 2× ; reduced motion actif/inactif.
- **Tests :** focus visible, ordre de lecture, noms/états semantics, 48 px, contrastes, drag alternatif clavier, erreurs.
- **Gate :** aucun overflow, contrôle masqué, action couleur-only ou geste sans alternative.
- **Commit :** `test(personalization): certify v3 accessible authoring`.

### PERS3-33 — Acceptation visuelle lisible

- [ ] **Résultat :** contact sheets Editor et Player montrent du vrai texte, les vrais assets du fixture et les variantes qui changent réellement la géométrie.
- **Captures minimales :** six scènes × paysage/portrait ; plus formes de fenêtre, typo 2×, Dialogue portrait/choix et quatre états Combat.
- **Règle :** les captures Editor et Player utilisent le même JSON et les mêmes assets mais des harness séparés.
- **Gate :** inspection visuelle humaine explicite ; une différence acceptée est documentée, jamais masquée par une tolérance arbitraire.
- **Commit :** `test(personalization): accept the complete v3 experience`.

### PERS3-34 — Suppression des fixtures et fallbacks mensongers

- [ ] **Résultat :** aucune fixture de production, faux portrait, ancien shell ou label `Preview réelle` incorrect ne subsiste.
- **Fichiers :** supprimer `PersonalizationCharacterPreviewFixtureSource` de production, constantes Roucool/Brindibou/Professeure Saule de production et adaptateurs V2 devenus inutiles.
- **Tests :** scans de source, package boundaries, anciens projets V1→V10 et absence de régression pixel quand V10 est absent.
- **Gate :** suite ciblée complète, builds Editor/Hub/standalone, approbation produit et état Git propre.
- **Commit :** `feat(personalization): ship the complete studio experience`.

## 12. Ordonnancement recommandé des sessions

| Session | Lots groupés | Résultat de la session |
|---|---|---|
| S1 | PERS3-00 et PERS3-01 | Vérité produit et fixture visuelle stable |
| S2 | PERS3-02 à PERS3-04 | Preview contextualisée avec le projet |
| S3 | PERS3-05 à PERS3-08 | Style global complet V6 |
| S4 | PERS3-09 à PERS3-12 | Écran titre et Intro complets V7 |
| S5 | PERS3-13 à PERS3-15 | Menu Pause complet |
| S6 | PERS3-16 à PERS3-20 | Dialogue complet après les gates Character Studio |
| S7 | PERS3-21 à PERS3-25 | Combat complet V10 |
| S8 | PERS3-26 à PERS3-29 | Manipulation directe, presets et historique |
| S9 | PERS3-30 à PERS3-34 | Certification, acceptation et suppression du faux |

Chaque lot produit son propre commit. Une session peut grouper plusieurs lots uniquement si leurs tests restent identifiables séparément.

## 13. Commandes de validation

### Modèles et authoring

```bash
cd packages/map_core
dart test
dart analyze

cd ../map_authoring
dart run tool/pmcp085_conformance.dart
dart test
dart analyze

cd ../map_distribution
dart test
dart analyze
```

### Player et runtime

```bash
cd packages/map_player_ui
flutter test
flutter analyze

cd ../map_runtime
flutter test
flutter analyze
```

### Editor, Hub et standalone

```bash
cd packages/map_editor
flutter test test/personalization
flutter analyze
flutter build macos --debug

cd ../../apps/pokemap_hub
flutter test
flutter analyze
flutter build macos --debug
flutter build apk --debug

cd ../../examples/playable_runtime_host
flutter test
flutter analyze
flutter build macos --debug
```

### MCP et documentation

```bash
cd tools/pokemap_mcp
npm run check
npm test

cd ../..
bash tools/scripts/check_markdown_hygiene.sh
```

Les suites globales déjà rouges ne peuvent pas être ignorées : le lot doit relancer l’échec isolé, classifier son lien avec le diff et conserver le statut global `PARTIAL` tant qu’il n’est ni corrigé ni explicitement dérogé.

## 14. Definition of Done

### Lot terminé

- [ ] Test RED observé avant l’implémentation pour tout comportement nouveau testable.
- [ ] Modèle, migration et validation couvrent succès, erreurs, bornes et ancien format.
- [ ] Le runtime consomme chaque champ persisté.
- [ ] L’éditeur passe par l’adapter canonique et ne réécrit pas le JSON directement.
- [ ] API directe, JSONL/CLI, éditeur et MCP sont prouvés ou N/A justifié.
- [ ] Preview et player utilisent la même surface visible.
- [ ] Contrôles preview-only identifiés explicitement.
- [ ] Responsive, clavier, semantics et mouvement réduit couverts selon le lot.
- [ ] Tests ciblés et analyses concernés exécutés avec résultats exacts.
- [ ] État Git final contrôlé ; commit dédié au lot.

### Phase terminée

- [ ] Tous les lots de la phase ont leur commit et leur verdict.
- [ ] La tranche produit une fonction utilisateur complète et démontrable.
- [ ] Contact sheet ou parcours visible inspecté par Yoahn.
- [ ] Aucun champ schema-only, contrôle décoratif ou renderer alternatif n’est introduit.
- [ ] La roadmap indique `DONE`, `PARTIAL` ou `BLOCKED` avec preuves fraîches.

### Produit V3 terminé

- [ ] Les six scènes utilisent des données du projet ou annoncent clairement la démonstration.
- [ ] Toutes les fonctions de la matrice cible sont persistées et consommées.
- [ ] Character Studio alimente réellement les portraits Dialogue.
- [ ] Combat couvre Commandes, Capacités, Cible et Message avec décor/acteurs projet.
- [ ] Save, restart, export, Hub et standalone sont certifiés.
- [ ] PMCP-085, MCP local et catalogue live sont cohérents.
- [ ] Matrices responsive/accessibilité vertes.
- [ ] Goldens lisibles et approbation visuelle humaine obtenue.
- [ ] Aucun ancien shell ou fixture de production mensongère ne subsiste.

## 15. Passes d’audit de la roadmap

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : conserve `map_player_ui` comme autorité visuelle et sépare contexte preview de la donnée persistée |
| Implémentation | PASS WITH DEPENDENCIES : Dialogue attend les lots Character Studio nommés ; les autres phases restent exécutables indépendamment |
| Tests | PASS : chaque lot possède tests positifs, négatifs, non-régression et gate verticale |
| Build / Validation | N/A pour cette rédaction documentaire ; aucun code de production n’est modifié |
| Critique finale | PASS WITH RISK : la V3 est volontairement large ; l’ordonnancement par tranches et les commits lot par lot empêchent un chantier monolithique |

Les vrais sub-agents ne sont pas utilisés pour cette rédaction conformément à la restriction d’orchestration active. Les cinq passes ci-dessus sont menées séparément dans le même audit.

## 16. Risques et auto-critique

1. **Portée importante.** Le plan couvre l’objectif produit entier, pas un simple polish. Les sessions S1 à S9 doivent être acceptées visuellement l’une après l’autre.
2. **Dépendance Character Studio.** PERS3-16 à PERS3-20 ne doivent pas inventer un second catalogue. Ils attendent les ressources et resolvers CHS explicitement nommés.
3. **Explosion des combinaisons visuelles.** Les widget tests couvrent les états ; les goldens ne gardent que les variantes géométriquement distinctes.
4. **Migrations successives.** V6 à V10 multiplient les tests de compatibilité mais évitent un énorme profil futur rempli de champs non consommés.
5. **Manipulation directe.** Le drag est une façade sur des contraintes responsive, pas une sauvegarde de pixels. C’est moins libre qu’un outil de dessin, mais beaucoup plus fiable dans le player.
6. **Preview de carte.** Le fond Dialogue réutilise un rendu editor read-only ; seule la surface Dialogue est pixel-identique au player. Le badge de contexte doit le dire clairement.
7. **Acceptation humaine.** Une suite golden verte ne prouve pas que l’interface est agréable. Chaque phase garde une validation visuelle de Yoahn comme gate produit.
