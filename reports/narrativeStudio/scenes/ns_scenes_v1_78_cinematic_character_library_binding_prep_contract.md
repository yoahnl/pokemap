# NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract

## 1. Résumé exécutif

Demandeur : Karim, via le prompt du lot V1-78.

V1-78 est un lot documentaire uniquement. Il répond au point produit : `cinematicOnly` ne doit pas vouloir dire acteur abstrait sans apparence. Il doit vouloir dire acteur propre à la cinématique, non placé sur la map, mais capable de référencer un personnage de la Character Library pour son apparence authoring.

Verdict :

- la Character Library existe déjà dans l’éditeur ;
- le modèle canonique d’un personnage est `ProjectCharacterEntry` dans `ProjectManifest.characters` ;
- les IDs de personnages sont stables et générés côté editor ;
- le label no-code est `ProjectCharacterEntry.name` ;
- l’apparence est décrite par `tilesetId`, `frameWidth`, `frameHeight`, `CharacterAnimation`, `EntityFacing` et `CharacterAnimationFrame` ;
- les portraits ne sont pas dans `ProjectCharacterEntry`; ils existent côté dresseur via `ProjectTrainerEntry.portraitElementId` ;
- `CinematicActorBinding.cinematicOnly` existe déjà, mais ne porte aucun `characterId` ;
- aucun modèle de liaison apparence cinématique vers Character Library n’existe encore.

Option recommandée : créer au lot suivant une couche séparée d’apparence, conceptuellement `CinematicActorAppearanceBinding`, stockée dans `CinematicStageContext.actorAppearanceBindings`, limitée aux acteurs `cinematicOnly` en V0. Ne pas ajouter `characterId` directement dans `CinematicActorBinding` en V0.

Prochain lot exact recommandé : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.

## 2. Gate 0

Commande exécutée avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
 M selbrume/maps/Selbrume.json
 M selbrume/project.json
 selbrume/maps/Selbrume.json | 130 ++++++++++++++++++++++++++++----------------
 selbrume/project.json       |  40 +++++++++++++-
 2 files changed, 123 insertions(+), 47 deletions(-)
selbrume/maps/Selbrume.json
selbrume/project.json
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
```

Interprétation :

- `selbrume/maps/Selbrume.json` et `selbrume/project.json` étaient déjà modifiés avant V1-78 ;
- V1-78 ne les modifie pas ;
- V1-78 distingue ses modifications documentaires des changements Selbrume préexistants.

## 3. Fichiers lus

Instructions et workflow :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/writing-plans/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- prompt V1-78 fourni par Karim

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_77_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md`

Core en audit uniquement :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/validation/validators.dart`

Editor/runtime en audit uniquement :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/character_library_panel.dart`
- `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_runtime/lib/src/application/runtime_character_refs.dart`

## 4. Pourquoi ce lot existe maintenant

Après V1-77, le Builder sait sélectionner de vraies sources `mapEntity` et `mapEvent` depuis la map de scène. Le cas restant est différent : un acteur `cinematicOnly` ne vient pas d’une map. Il ne doit pas créer une `MapEntity`, ni modifier `MapData`, ni dépendre du runtime. Il a besoin d’une apparence authoring réutilisable.

La Character Library est la source produit existante pour les personnages de monde. Il faut donc cadrer le lien avant de coder un champ au mauvais endroit.

## 5. Pourquoi ce lot est documentaire

Ce lot ne modifie aucun modèle produit. Il évite de coder trop vite :

- un `characterId` dans le mauvais objet ;
- un picker qui afficherait de faux choix ;
- une preview qui ferait croire à un rendu réel ;
- une dépendance runtime ou map inutile.

Modifications autorisées et réalisées :

- création du rapport V1-78 ;
- mise à jour des deux roadmaps Narrative Studio.

## 6. État actuel après V1-77

Acquis :

- `CinematicAsset.mapId` reste l’unique ancre Stage Map ;
- `CinematicStageContext.actorBindings` existe ;
- `CinematicActorBindingKind` contient `player`, `mapEntity`, `cinematicOnly`, `unbound` ;
- `mapEntity` peut choisir une vraie entité de map via le catalogue V1-76/V1-77 ;
- `mapEvent` est disponible pour les movement targets ;
- la preview reste une readiness/sandbox, pas un rendu réel.

Gaps :

- `cinematicOnly` n’a pas de personnage choisi ;
- aucun `CinematicActorAppearanceBinding` n’existe ;
- aucun `actorAppearanceBindings` n’existe ;
- aucun diagnostic `characterId` cinématique n’existe ;
- aucun picker Character Library n’est branché au Builder.

## 7. Pass A — Audit actor binding cinematicOnly actuel

Dans `packages/map_core/lib/src/models/cinematic_asset.dart`, `CinematicActorBindingKind` contient bien `cinematicOnly`.

Le modèle persistant actuel :

```text
CinematicActorBinding:
  actorId
  kind
  mapEntityId?
```

Conclusion : `cinematicOnly` est seulement une catégorie de binding logique. Il ne décrit aucune apparence.

## 8. Pass B — Audit Character Library / modèles character

La Character Library vit dans le Project Explorer :

```text
ProjectExplorerModuleCard title: Character Library
child: CharacterLibraryPanel(embedded: true)
```

Le modèle canonique est `ProjectCharacterEntry`.

Champs utiles :

```text
ProjectCharacterEntry:
  id
  name
  tilesetId
  frameWidth
  frameHeight
  animations
  tags
  sortOrder
```

Animations :

```text
CharacterAnimation:
  state: idle | walk | run
  direction: EntityFacing north | south | east | west
  frames: CharacterAnimationFrame[]

CharacterAnimationFrame:
  source: TilesetSourceRect
  durationMs
```

Conclusion : le character porte une apparence tileset animable et directionnelle, pas une entité de map.

## 9. Pass C — Audit ProjectManifest / stockage characters

`ProjectManifest.characters` stocke la Character Library :

```text
ProjectManifest.characters: List<ProjectCharacterEntry>
```

Le joueur référence un character via :

```text
ProjectSettings.defaultPlayerCharacterId
```

Les dresseurs peuvent référencer :

```text
ProjectTrainerEntry.characterId
ProjectTrainerEntry.portraitElementId
```

Les PNJ de map peuvent référencer :

```text
MapEntityNpcData.characterId
MapEntityNpcData.trainerId
```

Conclusion : la Character Library est projet-level, donc utilisable sans map si le modèle cinématique persiste une ref vers `ProjectManifest.characters`.

## 10. Pass D — Audit labels no-code / IDs stables / assets visuels

IDs stables :

- `ProjectCharacterEntry.id` est la clé stable ;
- `_generateCharacterId` normalise le nom, puis suffixe les collisions ;
- `SetPlayerCharacterUseCase` vérifie que le character existe.

Labels no-code :

- label principal : `ProjectCharacterEntry.name` ;
- label secondaire actuel dans la Library : `tilesetId · frameWidth×frameHeight`.

Assets visuels :

- source principale : `tilesetId` ;
- découpe : `frameWidth`, `frameHeight`, `TilesetSourceRect` ;
- animation : `CharacterAnimationFrame.durationMs` ;
- états : `idle`, `walk`, `run` ;
- directions : `north`, `south`, `east`, `west`.

Portraits :

- absence de portrait dans `ProjectCharacterEntry` ;
- portrait existant côté dresseur avec `ProjectTrainerEntry.portraitElementId`.

## 11. Pass E — Audit usages runtime/editor existants des characters

Runtime :

- `resolveDefaultPlayerCharacter(ProjectManifest)` résout `settings.defaultPlayerCharacterId` ;
- `resolveNpcCharacterId(MapEntity, ProjectManifest)` priorise `entity.npc.characterId`, puis fallback via `trainer.characterId` ;
- `resolveNpcCharacterEntry` retourne le `ProjectCharacterEntry`.

Editor :

- `CharacterLibraryPanel` crée, édite, supprime et anime les characters ;
- `EditorNotifier` expose `createCharacter`, `updateCharacter`, `deleteCharacter`, `upsertCharacterAnimation`, `setPlayerCharacter` ;
- les panels PNJ/dresseur ont déjà des usages de `characterId`, mais ils ne sont pas des bindings cinématiques.

Conclusion : les usages existants sont utiles comme précédents de validation/résolution, mais ne remplacent pas un contrat cinématique dédié.

## 12. Design Gate — Cinematic Character Library Binding Prep Contract

1. `cinematicOnly` aujourd’hui : un binding logique sans `mapEntityId`, sans `characterId`, sans apparence.
2. Character Library : elle vit dans `ProjectManifest.characters` et dans `CharacterLibraryPanel` côté editor.
3. Modèle canonique : oui, `ProjectCharacterEntry`.
4. IDs stables : oui, `ProjectCharacterEntry.id`.
5. Labels no-code : oui, `ProjectCharacterEntry.name`.
6. Portraits/sprites/spritesheets : sprites via `tilesetId` + frames ; portraits non portés par `ProjectCharacterEntry`.
7. Variantes directionnelles : oui, via `CharacterAnimation.direction: EntityFacing`.
8. Liens NPC ou indépendants : les characters sont indépendants ; PNJ/dresseurs peuvent les référencer.
9. Utilisable sans map : oui, parce que stocké au niveau `ProjectManifest`.
10. Réutilisable par plusieurs acteurs `cinematicOnly` : oui, recommandé ; une même apparence peut servir à plusieurs acteurs si l’auteur le veut.
11. Future ref character : dans une couche séparée d’apparence sous `stageContext`.
12. Étendre `CinematicActorBinding.cinematicOnly` : non recommandé en V0.
13. Créer `CinematicActorAppearanceBinding` : oui, recommandé.
14. Créer `actorAppearanceBindings` dans `stageContext` : oui, recommandé.
15. Éviter de mélanger identité d’acteur et apparence : oui, c’est la raison principale de l’Option B.
16. `characterId` inconnu : futur diagnostic error `actorCharacterBindingUnknownCharacter`.
17. Character Library absente : warning/readiness si aucun character disponible pour le picker.
18. `cinematicOnly` sans character : authorable, warning/readiness, fallback visuel futur.
19. Préserver `unbound` : oui, `unbound` reste absence volontaire de binding stage.
20. Préserver `mapEntity` : oui, il garde l’apparence de l’entité de map en V0.
21. Préserver `player` : oui, il garde l’apparence joueur en V0.
22. Préparer preview future : exposer un contrat résolvable vers `ProjectCharacterEntry`.
23. Ne pas créer d’entité de map : parce que `cinematicOnly` ne doit pas modifier `MapData`.
24. Ne pas modifier runtime : parce que ce lot cadre l’authoring, pas l’exécution.
25. Ne pas coder le picker maintenant : parce que le modèle persistant n’existe pas.
26. Prochain lot exact : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.

## 13. Problèmes identifiés

- `cinematicOnly` est aujourd’hui trop abstrait.
- La Character Library existe, mais n’est pas exposée au Stage Context.
- Le modèle character est tileset/animation centré, pas portrait centré.
- Les diagnostics cinématiques ne connaissent pas les characters.
- Ajouter `characterId` directement à `CinematicActorBinding` mélangerait source logique et apparence.

## 14. Options de stockage character binding comparées

Option A — dans `CinematicActorBinding` :

- avantage : simple ;
- inconvénient : mélange binding logique et apparence ;
- verdict : rejetée en V0.

Option B — dans `stageContext.actorAppearanceBindings` :

- avantage : séparation propre identité/binding/apparence ;
- avantage : extensible si un jour on autorise des overrides visuels ;
- inconvénient : modèle un peu plus riche ;
- verdict : retenue.

Option C — dans `requiredActors` :

- avantage : acteur et apparence au même endroit ;
- inconvénient : `requiredActors` deviendrait autre chose qu’une déclaration d’acteur ;
- verdict : rejetée.

Option D — ne rien stocker :

- avantage : aucun modèle ;
- inconvénient : ne répond pas au besoin Character Library ;
- verdict : rejetée.

## 15. Option recommandée

Retenir l’Option B.

Contrat conceptuel :

```text
CinematicStageContext.actorAppearanceBindings:
  - actorId
  - characterId?
```

En V0, l’apparence Character Library est autorisée seulement quand l’acteur a un binding `cinematicOnly`.

## 16. Contrat recommandé Character Binding V0

Nom recommandé :

```text
CinematicActorAppearanceBinding
```

Champs recommandés :

```text
actorId: String
characterId: String?
```

Règles :

- `actorId` référence `CinematicAsset.requiredActors.actorId` ;
- `characterId` référence `ProjectManifest.characters.id` ;
- `characterId` absent signifie apparence non choisie ;
- uniquement `cinematicOnly` en V0 ;
- `player`, `mapEntity` et `unbound` restent inchangés.

## 17. Contrat recommandé futur picker Character Library

Le futur picker doit :

- afficher `ProjectCharacterEntry.name` en label principal ;
- afficher `tilesetId`, dimensions et éventuellement tags en secondaire ;
- ne pas exposer de champ libre `characterId` comme workflow normal ;
- proposer `Aucun personnage choisi` pour garder un draft authorable ;
- filtrer ou signaler les characters invalides selon diagnostics ;
- ne pas créer, supprimer ou modifier de character depuis le Builder V0.

## 18. Diagnostics futurs recommandés

Codes recommandés :

- `actorCharacterBindingUnknownActor` : error ;
- `actorCharacterBindingUnknownCharacter` : error ;
- `actorCharacterBindingRequiresCinematicOnly` : warning ou error selon sévérité choisie au modèle ;
- `cinematicOnlyCharacterMissing` : warning/readiness ;
- `characterLibraryUnavailable` : warning/readiness ;
- `characterAssetMissingSprite` : warning/readiness ;
- `characterAssetMissingPreviewData` : warning/readiness.

Règle produit : un acteur `cinematicOnly` sans character doit rester authorable.

## 19. Relation avec Stage Context V1-72/V1-77

V1-72 a créé `CinematicStageContext` avec `actorBindings`, `initialPlacements`, `movementTargetBindings`.

V1-77 a branché les vrais pickers map-aware pour `mapEntity` et `mapEvent`.

V1-78 ne remplace rien de cela. Il ajoute un contrat futur complémentaire : l’apparence d’un acteur cinématique qui ne vient pas de la map.

## 20. Relation avec preview future

Le binding Character Library prépare :

- affichage d’un acteur `cinematicOnly` dans la future preview ;
- choix de sprite/animation idle ;
- fallback visuel si aucun character ;
- affichage futur de `actorMove` / `actorFace`.

V1-78 ne code aucune preview réelle.

## 21. Relation avec runtime

V1-78 ne modifie pas le runtime.

Le futur modèle doit rester authoring-first. Le runtime ne doit être concerné que lorsqu’un lot futur décidera explicitement comment lire et afficher une cinématique en jeu.

## 22. Tests futurs V1-79

V1-79 Core Model V0 devra tester :

- JSON ancien sans `actorAppearanceBindings` lisible ;
- JSON nouveau avec un binding character sérialisé ;
- upsert/remove de binding d’apparence ;
- diagnostic actor inconnu ;
- diagnostic character inconnu ;
- diagnostic character manquant pour `cinematicOnly` ;
- refus ou diagnostic si un binding d’apparence vise `player` ou `mapEntity` en V0 ;
- non-mutation timeline/map/runtime.

## 23. Tests futurs V1-80

Si le lot suivant après V1-79 devient le picker Character Library, il devra tester :

- affichage de characters réels depuis `ProjectManifest.characters` ;
- labels no-code ;
- absence de saisie ID brute ;
- choix `Aucun personnage choisi` ;
- sauvegarde via l’opération V1-79 ;
- readiness mise à jour ;
- proportions timeline préservées.

Note de roadmap : `NS-SCENES-V1-80` est déjà utilisé comme backlog scroll/visibility. Le lot picker devra donc être numéroté explicitement dans le prochain prompt si V1-80 reste réservé.

## 24. Non-objectifs confirmés

V1-78 n’a pas fait :

- code Dart produit ;
- package modification ;
- test modification ;
- modification `ProjectManifest` ;
- modification `CinematicAsset` ;
- modification Character Library ;
- picker actif ;
- migration JSON ;
- preview réelle ;
- rendu acteur ;
- modification runtime ;
- modification Selbrume ;
- image IA ou `gpt-image-2`.

## 25. Roadmap post V1-78

Statut proposé et appliqué :

```text
NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract: DONE
```

Prochain lot exact recommandé :

```text
NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0
```

Le drift diagnostics précédemment prévu en V1-78 est repoussé après la séquence Character Library Binding.

## 26. Commandes exécutées

Commandes principales :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
sed -n '1,220p' /Users/karim/.codex/attachments/24fa294b-8548-4759-90d6-9b22e63554d7/pasted-text.txt
sed -n '220,520p' /Users/karim/.codex/attachments/24fa294b-8548-4759-90d6-9b22e63554d7/pasted-text.txt
sed -n '520,980p' /Users/karim/.codex/attachments/24fa294b-8548-4759-90d6-9b22e63554d7/pasted-text.txt
sed -n '1,220p' AGENTS.md
sed -n '1,220p' agent_rules.md
sed -n '1,220p' reports/narrativeStudio/scenes/road_map_scenes.md
sed -n '1,260p' reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
rg -n "CinematicActorBindingKind|CinematicActorBinding|actorBindings|cinematicOnly|mapEntityId" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
rg -n "ProjectCharacterEntry|CharacterAnimation|CharacterAnimationFrame|defaultPlayerCharacterId|characters" packages/map_core/lib/src/models/project_manifest.dart
rg -n "Character Library|CharacterLibraryPanel" packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart packages/map_editor/lib/src/ui/panels/character_library_panel.dart
rg -n "defaultPlayerCharacterId|characterId|portraitElementId" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/models/project_trainer.dart packages/map_runtime/lib/src/application/runtime_character_refs.dart
rg -n "CinematicActorAppearanceBinding|CinematicActorCharacterBinding|actorAppearanceBindings|characterId.*cinematic|cinematicOnly.*characterId" packages/map_core packages/map_editor || true
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 27. Checks anti-scope

Les checks anti-scope attendus sont documentés en section 28. Aucun fichier `packages/` n’est modifié par V1-78.

## 28. Evidence Pack

### 28.1 Gate 0 complet

Voir section 2. Les deux changements Selbrume étaient préexistants.

### 28.2 Recherches rg structurantes

Commande :

```bash
rg -n "ProjectCharacterEntry|CharacterAnimation|CharacterAnimationFrame|defaultPlayerCharacterId|characters" packages/map_core/lib/src/models/project_manifest.dart
```

Sortie :

```text
271:  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
381:    @Default([]) List<ProjectCharacterEntry> characters,
436:      name: 'defaultPlayerCharacterId',
439:    String? defaultPlayerCharacterId,
827:class ProjectCharacterEntry with _$ProjectCharacterEntry {
829:  const factory ProjectCharacterEntry({
835:    @Default([]) List<CharacterAnimation> animations,
838:  }) = _ProjectCharacterEntry;
840:  factory ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =>
841:      _$ProjectCharacterEntryFromJson(json);
845:class CharacterAnimation with _$CharacterAnimation {
847:  const factory CharacterAnimation({
848:    required CharacterAnimationState state,
850:    @Default([]) List<CharacterAnimationFrame> frames,
851:  }) = _CharacterAnimation;
853:  factory CharacterAnimation.fromJson(Map<String, dynamic> json) =>
854:      _$CharacterAnimationFromJson(json);
858:class CharacterAnimationFrame with _$CharacterAnimationFrame {
860:  const factory CharacterAnimationFrame({
863:  }) = _CharacterAnimationFrame;
865:  factory CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =>
866:      _$CharacterAnimationFrameFromJson(json);
```

Commande :

```bash
rg -n "Character Library|CharacterLibraryPanel" packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart packages/map_editor/lib/src/ui/panels/character_library_panel.dart
```

Sortie :

```text
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart:460:          title: 'Character Library',
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart:470:          child: const CharacterLibraryPanel(embedded: true),
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:917:class CharacterLibraryPanel extends ConsumerStatefulWidget {
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:918:  const CharacterLibraryPanel({super.key, this.embedded = false});
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:923:  ConsumerState<CharacterLibraryPanel> createState() =>
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:924:      _CharacterLibraryPanelState();
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:927:class _CharacterLibraryPanelState
packages/map_editor/lib/src/ui/panels/character_library_panel.dart:928:    extends ConsumerState<CharacterLibraryPanel> {
```

Commande :

```bash
rg -n "defaultPlayerCharacterId|characterId|portraitElementId" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/models/project_trainer.dart packages/map_runtime/lib/src/application/runtime_character_refs.dart
```

Sortie :

```text
packages/map_core/lib/src/models/project_manifest.dart:271:  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
packages/map_core/lib/src/models/project_manifest.dart:436:      name: 'defaultPlayerCharacterId',
packages/map_core/lib/src/models/project_manifest.dart:439:    String? defaultPlayerCharacterId,
packages/map_runtime/lib/src/application/runtime_character_refs.dart:4:  final charId = manifest.settings.defaultPlayerCharacterId?.trim();
packages/map_runtime/lib/src/application/runtime_character_refs.dart:23:  final directCharacterId = entity.npc?.characterId?.trim();
packages/map_runtime/lib/src/application/runtime_character_refs.dart:33:      final trainerCharacterId = trainer.characterId?.trim();
packages/map_core/lib/src/models/project_trainer.dart:65:    String? characterId,
packages/map_core/lib/src/models/project_trainer.dart:66:    String? portraitElementId,
packages/map_core/lib/src/models/map_entity_payloads.dart:124:    String? characterId,
packages/map_core/lib/src/models/map_entity_payloads.dart:256:          'characterId',
packages/map_core/lib/src/models/map_entity_payloads.dart:261:        if (charId != null) npc['characterId'] = charId;
```

Commande :

```bash
rg -n "CinematicActorAppearanceBinding|CinematicActorCharacterBinding|actorAppearanceBindings|characterId.*cinematic|cinematicOnly.*characterId" packages/map_core packages/map_editor || true
```

Sortie :

```text
<vide>
```

### 28.3 Hunks complets des roadmaps modifiées

Commande :

```bash
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index cb95fc6b..e15daeab 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0
+NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0
 ```

 ## Principes
@@ -111,7 +111,8 @@ NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0
 | NS-SCENES-V1-75 | Cinematic Map Entity/Event Source Audit / Picker Prep Contract | doc / architecture-review | Auditer les donnees map accessibles cote editor pour preparer de futurs pickers `mapEntity` / `mapEvent` honnetes. | Pas de picker actif, pas de runtime preview, pas de free coordinates, pas de `sourceId` tape a la main, pas de donnees Selbrume. | Rapport V1-75, roadmaps, audit MapData/editor services. | DONE : `ProjectManifest.maps` audite comme metadata/relativePath, `MapData.entities/events` identifies comme sources reelles, snapshot editor non destructive reperee, Option E retenue, contrat `CinematicStageMapSourceCatalog` et tests futurs cadres. | Brancher des IDs bruts ou une source incomplete ; confondre map authoring et runtime state. | DONE : contrat pret avant implementation map-aware, sans package ni picker actif. | V1-74. |
 | NS-SCENES-V1-76 | Cinematic Stage Map Source Catalog V0 | core / read-model | Creer le catalogue pur des sources map-aware depuis `ProjectMapEntry` et `MapData`, avant tout picker. | Pas de UI, pas de picker actif, pas de preview reelle, pas de runtime, pas de pathfinding, pas de donnees Selbrume, pas de chargement MapData. | `cinematic_stage_map_source_catalog.dart`, export `map_core.dart`, test catalogue, rapports. | DONE : TDD RED/GREEN, statuts missing/unavailable/mismatch/available, entities/events reels, labels no-code, ids secondaires, `canBindActor`, `canBeMovementTarget`, tests/analyze core verts, tests editor cibles verts. | Lier le Builder trop tot ; charger la map depuis core ; exposer IDs bruts comme workflow. | DONE : catalogue consommable par V1-77, sans UI ni runtime. | V1-75. |
 | NS-SCENES-V1-77 | Cinematic Stage Map Entity/Event Pickers V0 | editor / authoring | Brancher le catalogue V1-76 au Builder pour choisir de vraies sources `MapData.entities/events` dans les bindings stage. | Pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de coordonnees libres, pas de JSON/ID brut saisi, pas de donnees Selbrume. | Builder/Library cinematics, readiness preview, tests widget, rapport, screenshot. | DONE : actor binding -> vraie `mapEntity`, movement target -> vraie `mapEntity` ou vrai `mapEvent`, snapshot MapData non destructive, labels no-code, readiness alignee, Visual Gate 1663x926. | Charger la map au mauvais niveau ; exposer les ids bruts ; casser timeline/proportions ; faire croire a une preview reelle. | DONE : pickers map-aware honnetes actifs, sans runtime ni preview reelle. | V1-76. |
-| NS-SCENES-V1-78 | Cinematic Stage Source Drift Diagnostics Polish V0 | editor / ui-polish | Polir les diagnostics/resumes quand une source map-aware deja liee disparait, change de map ou devient indisponible. | Pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de rechargement destructif, pas de changement de modele core si non requis. | Builder/Library cinematics, readiness, tests widget, rapport, screenshot si UI. | TODO : sources cassees expliquees sans ID libre, recovery via pickers V1-77, timeline/proportions preserves. | Diagnostiquer trop tard ; masquer les refs cassees ; surcharger l'inspecteur. | TODO : source drift lisible et corrigeable no-code. | V1-77. |
+| NS-SCENES-V1-78 | Cinematic Character Library Binding Prep Contract | doc / architecture-review | Cadrer comment un acteur `cinematicOnly` choisira un personnage depuis la Character Library. | Pas de code produit, pas de modèle, pas de widget, pas de picker, pas de preview réelle, pas de runtime, pas de package, pas de test, pas de screenshot, pas de donnée Selbrume. | Rapport V1-78, roadmaps, audit Character Library / Stage Context / usages characters. | DONE : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables, labels no-code, assets tileset/animations/directions cadrés, options comparées, Option B retenue, contrat V0/diagnostics/tests futurs définis. | Mélanger identité d'acteur et apparence ; coder un picker avant le modèle ; faire croire à une preview réelle. | DONE : contrat prêt pour modèle Core V0, sans modifier le produit. | V1-77. |
+| NS-SCENES-V1-79 | Cinematic Character Library Binding Core Model V0 | core / authoring | Implémenter le modèle authoring minimal permettant de lier un actor `cinematicOnly` à un personnage de la Character Library, avec JSON backward-compatible, opérations pures et diagnostics. | Pas d'UI picker, pas de preview réelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity en V0, pas de donnée Selbrume. | `cinematic_asset.dart`, authoring operations, diagnostics cinematic, tests JSON/operations/diagnostics, rapport. | TODO : `actorAppearanceBindings` ou équivalent séparé, validation actor/character, diagnostics refs cassées et backward compatibility. | Trop alourdir `CinematicActorBinding` ; autoriser les overrides visuels trop tôt ; casser les anciens JSON. | TODO : modèle minimal stable avant le picker Character Library. | V1-78. |
 | NS-SCENES-V1-80 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post stage/map context. |

 ## Mise a jour V1-74
@@ -168,7 +169,21 @@ Preuve : rapport V1-77, evidence pack V1-77, tests Builder/Library, tests/analyz

 Limites confirmees : preview reelle eteinte, runtime intouché, timeline/duree/resize/probe/transports preserves, aucun ID libre, aucun JSON brut, aucun `stageContext.mapId`, aucune image IA ou `gpt-image-2`.

-Prochain lot exact recommande : `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0`.
+Prochain lot exact recommande : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.
+
+## Mise a jour V1-78
+
+Statut : `NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract` est DONE.
+
+Decision : le besoin formule par Karim remplace temporairement le drift diagnostics. `cinematicOnly` doit signifier acteur propre a la cinematique, non place sur la map, mais capable de referencer un personnage de la Character Library pour son apparence authoring.
+
+Option recommandee : ne pas ajouter `characterId` directement dans `CinematicActorBinding` en V0. Creer plutot une couche separee d'apparence, conceptuellement `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings`, afin de ne pas melanger binding logique et apparence. En V0, ce binding est recommande seulement pour les acteurs `cinematicOnly`.
+
+Preuve : rapport V1-78, audit `ProjectManifest.characters`, `ProjectCharacterEntry`, Character Library editor, refs joueur/PNJ/dresseur/runtime et Stage Context V1-72/V1-77. Aucune modification de package, test, runtime, preview, screenshot, image IA ou donnee Selbrume n'est ajoutee.
+
+Limites confirmees : V1-78 est doc-only ; aucun modele core, aucune migration JSON, aucun picker Character Library, aucune preview acteur et aucun runtime ne sont codes.
+
+Prochain lot exact recommande : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.

 ## Mise a jour V1-66

diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 6f1789e7..0435ddb7 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -132,16 +132,19 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract | DONE | Audit documentaire des vraies sources map-aware : `ProjectManifest.maps` fournit metadata/relativePath, `MapData.entities` et `MapData.events` portent les sources reelles, `EditorNotifier.loadMapSnapshotById` est le point d'entree editor non destructif recommande, Option E retenue avec contrat `CinematicStageMapSourceCatalog`, diagnostics/tests futurs cadres, sans picker actif, runtime, preview, package, test, screenshot ou donnees Selbrume. |
 | NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0 | DONE | Read model pur `CinematicStageMapSourceCatalog` dans `map_core` : construit depuis `ProjectMapEntry` + `MapData`, projette entites/events reels, labels no-code, ids secondaires discrets, positionSummary secondaire, diagnostics locaux, statuses missing/unavailable/mismatch/available et capabilities `canBindActor` / `canBeMovementTarget`, avec tests core et analyze verts, sans picker actif, UI, preview reelle, runtime, pathfinding ou donnees Selbrume. |
 | NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0 | DONE | Catalogue V1-76 branche au Cinematic Builder via snapshot `MapData` editor non destructive : actor binding -> vraie `mapEntity`, movement target -> vraie `mapEntity` ou vrai `mapEvent`, labels no-code, ids secondaires, readiness map-aware mise a jour, Visual Gate 1663x926, sans ID libre, JSON brut, preview reelle, runtime, playback, pathfinding ou donnees Selbrume. |
-| NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0 | TODO | Recommandation future : polir les diagnostics et resumes quand une entite/event lie disparait, change de map ou devient indisponible, en preservant les pickers V1-77, la timeline et la preview sandbox. |
+| NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract | DONE | Lot documentaire demande par Karim : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables/labels no-code/assets directionnels cadrés, options de stockage comparées, Option B recommandée avec `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings` futur, diagnostics/tests futurs définis, sans modèle, UI, picker, preview, runtime, package, test ou donnée Selbrume. |
+| NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0 | TODO | Prochain lot recommandé : implémenter le modèle authoring minimal permettant de lier un acteur `cinematicOnly` à un personnage de la Character Library, avec JSON backward-compatible, opérations pures et diagnostics, sans UI picker ni preview réelle. |
 | NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur : polir le scroll automatique et la visibilite des blocs/selection/probe apres le cadrage stage/map, en preservant les proportions de timeline demandees par Karim. |

 ## Prochain lot recommande

-`NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0`
+`NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`

-Raison : V1-77 active les vrais pickers map-aware. Le prochain verrou produit recommande est de polir les diagnostics et resumes quand une source deja liee disparait, change de map ou devient indisponible, sans activer de preview reelle ni toucher au runtime.
+Raison : V1-78 confirme que `cinematicOnly` ne doit pas rester un acteur abstrait sans apparence. Le prochain verrou produit recommande est de matérialiser un binding authoring minimal vers `ProjectManifest.characters`, limité aux acteurs `cinematicOnly` en V0, avant de coder le picker ou la preview.

-Ordre apres V1-77 : `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0`.
+Ordre apres V1-78 : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.
+
+Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.

 Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context, et le polish scroll/visibility est deplace explicitement en `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0`.
```

### 28.4 Checks documentaires finaux

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     |  21 +++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  11 +-
 selbrume/maps/Selbrume.json                        | 130 +++++++++++++--------
 selbrume/project.json                              |  40 ++++++-
 4 files changed, 148 insertions(+), 54 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/maps/Selbrume.json
selbrume/project.json
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/maps/Selbrume.json
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_78_cinematic_character_library_binding_prep_contract.md
```

### 28.5 Checks anti-scope

Commande :

```bash
git diff --name-only -- packages
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "CinematicActorAppearanceBinding|CinematicActorCharacterBinding|actorAppearanceBindings|characterId.*cinematic|cinematicOnly.*characterId" packages/map_core packages/map_editor || true
```

Sortie :

```text
<vide>
```

Interprétation : aucune occurrence n’existe dans les packages ; V1-78 ne crée aucun modèle ou picker.

Commande ciblée lignes ajoutées V1-78 :

```bash
git diff -U0 -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" || true
```

Sortie :

```text
<vide>
```

Interprétation : les lignes ajoutées aux roadmaps par V1-78 n’introduisent pas de termes runtime/playback actifs. Les roadmaps historiques contiennent déjà de nombreuses mentions de lots runtime passés ; elles ne sont pas des modifications V1-78.

Commande ciblée lignes ajoutées V1-78 :

```bash
git diff -U0 -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -n "gpt-image-2|image_generation|generate image|AI image|image model" || true
```

Sortie :

```text
<vide>
```

Interprétation : les lignes ajoutées aux roadmaps par V1-78 ne créent aucune demande ou usage d’image IA. La mention `gpt-image-2` dans les fichiers est uniquement historique ou anti-scope.

Commande ciblée lignes ajoutées V1-78 :

```bash
git diff -U0 -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" || true
```

Sortie :

```text
10:+| NS-SCENES-V1-78 | Cinematic Character Library Binding Prep Contract | doc / architecture-review | Cadrer comment un acteur `cinematicOnly` choisira un personnage depuis la Character Library. | Pas de code produit, pas de modèle, pas de widget, pas de picker, pas de preview réelle, pas de runtime, pas de package, pas de test, pas de screenshot, pas de donnée Selbrume. | Rapport V1-78, roadmaps, audit Character Library / Stage Context / usages characters. | DONE : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables, labels no-code, assets tileset/animations/directions cadrés, options comparées, Option B retenue, contrat V0/diagnostics/tests futurs définis. | Mélanger identité d'acteur et apparence ; coder un picker avant le modèle ; faire croire à une preview réelle. | DONE : contrat prêt pour modèle Core V0, sans modifier le produit. | V1-77. |
11:+| NS-SCENES-V1-79 | Cinematic Character Library Binding Core Model V0 | core / authoring | Implémenter le modèle authoring minimal permettant de lier un actor `cinematicOnly` à un personnage de la Character Library, avec JSON backward-compatible, opérations pures et diagnostics. | Pas d'UI picker, pas de preview réelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity en V0, pas de donnée Selbrume. | `cinematic_asset.dart`, authoring operations, diagnostics cinematic, tests JSON/operations/diagnostics, rapport. | TODO : `actorAppearanceBindings` ou équivalent séparé, validation actor/character, diagnostics refs cassées et backward compatibility. | Trop alourdir `CinematicActorBinding` ; autoriser les overrides visuels trop tôt ; casser les anciens JSON. | TODO : modèle minimal stable avant le picker Character Library. | V1-78. |
24:+Preuve : rapport V1-78, audit `ProjectManifest.characters`, `ProjectCharacterEntry`, Character Library editor, refs joueur/PNJ/dresseur/runtime et Stage Context V1-72/V1-77. Aucune modification de package, test, runtime, preview, screenshot, image IA ou donnee Selbrume n'est ajoutee.
35:+| NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract | DONE | Lot documentaire demande par Karim : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables/labels no-code/assets directionnels cadrés, options de stockage comparées, Option B recommandée avec `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings` futur, diagnostics/tests futurs définis, sans modèle, UI, picker, preview, runtime, package, test ou donnée Selbrume. |
```

Interprétation : les seules mentions Selbrume ajoutées sont des limites anti-scope explicites. Aucun seed, hardcode ou donnée produit Selbrume n’est ajouté.

## 29. Auto-review critique

1. Code produit modifié ? Non.
2. Package modifié ? Non.
3. Test modifié ? Non.
4. `CinematicAsset` modifié ? Non.
5. Character Library modifiée ? Non.
6. Picker character codé ? Non.
7. `characterId` ajouté ? Non.
8. Runtime modifié ? Non.
9. Preview réelle ajoutée ? Non.
10. Données Selbrume ajoutées ? Non ; les changements Selbrume étaient préexistants.
11. Character Library auditée ? Oui.
12. Modèles character identifiés ? Oui.
13. IDs stables identifiés ? Oui.
14. Labels no-code identifiés ? Oui.
15. Assets visuels audités ? Oui.
16. Options de stockage comparées ? Oui.
17. Option recommandée claire ? Oui, Option B.
18. Contrat Character Binding V0 défini ? Oui.
19. Diagnostics futurs listés ? Oui.
20. Tests futurs listés ? Oui.
21. Prochain lot exact recommandé ? Oui, V1-79 Core Model V0.
22. Evidence Pack complet sans valeurs factices ? Oui.

Limite volontaire : les checks Dart/Flutter ne sont pas lancés, car le lot est documentaire et le prompt interdit les modifications de packages/tests.

## 30. Verdict final

V1-78 est DONE côté documentation et roadmap.

Décision produit : `cinematicOnly` doit pouvoir recevoir une apparence depuis la Character Library, mais cette ref doit vivre dans une couche séparée d’apparence plutôt que dans le binding logique.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0
```
