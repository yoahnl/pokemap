# ShadowV2-1 — Projected Building Shadows Product Spec / Art Direction

## 1. Résumé exécutif

ShadowV2-1 définit la future V2 des ombres projetées de bâtiments.

Ce lot ne change rien au code, aux données, au renderer, à Selbrume, au harness ou à la baseline.

Décision principale:

- V2 doit viser des ombres projetées Pokémon-like pour bâtiments.
- Les grandes ombres doivent être authorées, asset-driven ou preset-driven, previewées et validées.
- Le runtime reste consommateur de données authorées.
- `genericProjection` automatique reste interdit.
- Time-of-day doit influencer le design, mais ne doit pas être implémenté maintenant.

Modèle recommandé: Option D, hybrid authoring.

Interprétation:

- Presets paramétriques simples pour la majorité des bâtiments.
- Possibilité future d'asset shadow override pour cas artistiques.
- Aucun retour à une inférence runtime par taille d'asset.

## 2. Objectif du lot

Définir la future V2 avant toute implémentation.

Question centrale:

```text
Comment obtenir des ombres projetées de bâtiments Pokémon-like,
sans retomber dans les erreurs de genericProjection automatique ?
```

## 3. Rappel de l’état stable Shadow V1

État stabilisé après Shadow-55 -> Shadow-68:

- runtime auto-apply supprimé;
- policy auto-shadow durcie;
- `genericProjection` non généré par défaut;
- Selbrume nettoyée;
- `genericProjection = 0`;
- `contactLedge = 10`;
- contact ledge max depth = `14.0`;
- screenshots reproductibles;
- baseline visuelle Selbrume V1 créée;
- comparaison baseline informative;
- invariants structurels bloquants.

V1 stable n'est pas le système final d'ombres projetées. V1 protège le rendu propre actuel.

## 4. North Star artistique

Objectif final:

- ombres projetées Pokémon-like;
- simples;
- stylisées;
- propres;
- lisibles;
- principalement pour bâtiments;
- contrôlées artistiquement;
- compatibles plus tard avec cycle jour/nuit.

La référence utilisateur n'est pas disponible localement.

Recherche locale:

```text
(no output)
```

Interprétation documentée:

```text
Image Pokémon-like de bâtiments avec ombres projetées grises,
simples, larges mais propres, directionnelles, visuellement attachées au bâtiment.
```

Recommandation future: si utile, ajouter manuellement une référence sous:

```text
reports/shadows/references/projected_building_shadow_reference.png
```

Ne pas créer ce fichier dans ShadowV2-1.

## 5. Ce que V2 doit permettre

V2 doit permettre:

- activer une ombre projetée sur un asset bâtiment;
- choisir un preset lisible;
- ajuster direction;
- ajuster longueur;
- ajuster largeur;
- ajuster opacité;
- ajuster couleur / tint;
- ajuster offset / anchor;
- preview immédiate dans l'éditeur;
- option d'override par instance;
- compatibility hooks pour time-of-day;
- visual gate avant validation.

V2 doit rester no-code.

Le vocabulaire doit parler à l'utilisateur:

- "Ombre projetée de bâtiment";
- "Courte";
- "Moyenne";
- "Longue";
- "Direction";
- "Intensité";
- "Décalage";
- "Prévisualiser matin / midi / soir" plus tard.

Pas de vocabulaire brut:

- `genericProjection`;
- `projectedPolygon`;
- ID technique obligatoire;
- JSON manuel.

## 6. Ce que V2 doit interdire

Interdictions:

- plaques polygonales génériques partout;
- longues projections sur petits props;
- ombres sur panneaux par défaut;
- ombres sur lampadaires par défaut;
- ombres sur arbres par défaut;
- ombres qui traversent agressivement les chemins;
- formes debug;
- auto-mutation runtime;
- backfill global non validé;
- runtime auto-apply;
- runtime inference par taille d'asset;
- migration JSON large sans lot dédié;
- baseline update silencieuse.

Phrase canonique future:

```text
Les grandes ombres projetées doivent être asset-driven, authorées, previewées et validées.
Jamais réintroduites par genericProjection automatique.
```

## 7. Relation avec contact ledges V1

Les contact ledges actuels restent le système V1 stable.

Ils:

- donnent un contact discret au pied des bâtiments;
- ne remplacent pas les futures grandes ombres projetées;
- peuvent coexister avec V2 si le rendu ne double pas visuellement l'ombre;
- doivent rester contrôlés par la baseline V1 tant que V2 n'est pas validée.

Règle de coexistence:

```text
Si une ombre projetée V2 est authorée sur un bâtiment,
le design doit décider si la contact ledge reste, est réduite ou est masquée.
```

Cette décision doit être prise dans un futur lot de design ou POC, pas maintenant.

## 8. Modèle d’authoring attendu

Capacités classées:

| Capacité | Classement | Note |
|---|---|---|
| Activer/désactiver ombre projetée par asset bâtiment | V2 required | Base du système. |
| Choisir un preset d'ombre | V2 required | Workflow no-code. |
| Preview immédiate éditeur | V2 required | Pas de validation aveugle. |
| Ajuster anchor/origin | V2 required | Attacher l'ombre au bâtiment. |
| Ajuster longueur | V2 required | Forme principale. |
| Ajuster largeur | V2 required | Adaptation façade / asset. |
| Ajuster direction | V2 required | Direction artistique. |
| Ajuster opacité | V2 required | Contrôle lisibilité. |
| Ajuster couleur/tint | V2 optional | Utile mais peut attendre. |
| Ajuster offset | V2 required | Alignement précis. |
| Override par instance | V2 optional | Nécessaire pour cartes spécifiques, pas premier POC. |
| Suivre cycle jour/nuit | future time-of-day | Préparer les champs, ne pas brancher maintenant. |
| Courbes horaires | future time-of-day | Après V2 stable. |
| Asset shadow mask | V2 optional / future | Très artistique, plus coûteux. |
| Auto-application par taille d'asset | out-of-scope | Interdit. |
| Backfill global automatique | out-of-scope | Interdit. |

## 9. Options de données / modèles

### Option A — Extension de `ProjectElementShadowConfig`

Description:

```text
Ajouter un mode/projectedBuilding config directement dans ProjectElementShadowConfig.
```

Avantages:

- réutilise le système existant;
- moins de types;
- moins de surface initiale.

Risques:

- gonfle un modèle sensible;
- mélange contact ledge V1 et projection V2;
- compat JSON délicate;
- peut rendre la frontière V1/V2 confuse.

### Option B — Nouveau modèle `ProjectBuildingShadowPreset`

Description:

```text
Créer des presets dédiés aux ombres projetées de bâtiments.
```

Avantages:

- clair artistiquement;
- réutilisable;
- plus lisible côté editor;
- évite de tout cacher dans une config générale.

Risques:

- nouveau catalogue;
- nouveaux codecs;
- nouvelle surface produit;
- demande design de compat.

### Option C — Shadow asset / sprite mask

Description:

```text
Utiliser un asset d'ombre dessiné ou une silhouette simplifiée.
```

Avantages:

- contrôle artistique maximal;
- résultat potentiellement très Pokémon-like;
- moins de géométrie arbitraire.

Risques:

- gestion asset plus lourde;
- moins dynamique pour time-of-day;
- pipeline artiste nécessaire;
- difficile à généraliser au début.

### Option D — Hybrid authoring

Description:

```text
Preset paramétrique + possibilité future d'asset shadow override.
```

Avantages:

- flexible;
- évolutif;
- compatible jour/nuit;
- no-code si bien présenté;
- permet POC paramétrique rapide sans fermer la porte à assets.

Risques:

- plus long à cadrer;
- risque d'usine à gaz si tout est livré en même temps.

## 10. Recommandation modèle V2

Recommandation: Option D, hybrid authoring, livrée par micro-lots.

Décision précise:

1. Commencer par presets paramétriques authorés pour bâtiments.
2. Ne pas ajouter d'asset shadow mask dans le premier POC.
3. Garder une extension future pour asset override.
4. Séparer clairement V1 contact ledge et V2 projected building shadow.
5. Ne jamais déclencher V2 par heuristique runtime.

Pourquoi:

- Les presets donnent un premier chemin no-code.
- L'authoring évite la rechute `genericProjection`.
- L'extension asset garde la North Star artistique ouverte.
- Time-of-day peut être conçu autour de paramètres direction/length/opacity.

## 11. Workflow éditeur no-code

Workflow cible:

1. L'utilisateur sélectionne un élément bâtiment.
2. Il ouvre la section Ombre.
3. Il choisit "Ombre projetée de bâtiment".
4. L'éditeur affiche une preview immédiate.
5. L'utilisateur choisit un preset: courte / moyenne / longue / façade large.
6. Il ajuste quelques contrôles simples.
7. Plus tard, il teste matin / midi / soir si time-of-day activé.
8. Il valide.
9. Le runtime ne devine rien.

Contraintes UI:

- vocabulaire métier lisible;
- pas de JSON manuel;
- pas d'IDs techniques si évitable;
- preview avant validation;
- actions guidées;
- undo/redo à préserver si l'éditeur le supporte;
- batch apply seulement après review visuelle;
- aucun concept `genericProjection` exposé à l'utilisateur.

Contrôles probables:

- preset dropdown;
- toggle "Ombre projetée";
- slider longueur;
- slider intensité;
- contrôle direction simple;
- offset X/Y avancé;
- swatch/tint optionnel;
- preview time-of-day future.

## 12. Comportement runtime attendu

Runtime futur:

- lit données authorées;
- résout direction / longueur / opacité;
- dessine l'ombre dans le bon render pass;
- respecte time-of-day si activé;
- reste compatible contact ledges;
- reste compatible actor contact shadows;
- ne mute pas le manifest;
- ne crée aucune ombre non authorée.

Interdits runtime:

- auto-apply;
- backfill;
- inference par taille d'asset;
- mutation du manifest en mémoire pour décision artistique;
- fallback vers `genericProjection` automatique;
- création silencieuse d'ombres sur petits props.

Le runtime reste consommateur.

L'editor propose.

L'utilisateur valide.

## 13. Compatibilité cycle jour/nuit

Paramètres futurs à prévoir conceptuellement:

- `lightDirection`;
- `lengthMultiplier`;
- `opacityMultiplier`;
- `colorTint`;
- `timeCurve`;
- `enabledTimeRange`;
- `nightBehavior`.

Comportement artistique futur:

- matin: ombre plus longue dans une direction;
- midi: ombre courte / très discrète;
- soir: ombre plus longue dans direction opposée;
- nuit: ombre désactivée ou remplacée plus tard par lumières artificielles.

Décision:

Time-of-day ne doit pas être implémenté dans ShadowV2-1.

Il doit seulement influencer la forme des futurs modèles pour éviter de refaire la V2 plus tard.

## 14. Visual gates obligatoires

Règles:

- Chaque lot qui touche le rendu produit des screenshots.
- Chaque lot qui modifie les ombres Selbrume relance le harness.
- Chaque POC V2 a before/after.
- Toute baseline update est explicite.
- Une différence pixel/hash en V0 reste informative sauf lot dédié.
- Toute validation artistique doit citer les captures.

Captures futures à prévoir:

- bâtiment bleu classique;
- maison orange;
- centre Pokémon;
- grand bâtiment si disponible;
- cas sur herbe;
- cas sur chemin clair;
- matin / midi / soir plus tard.

Baseline:

- V1 protège l'état actuel contact ledge.
- V2 devra créer sa propre baseline ou versionner explicitement une V2.

## 15. Roadmap micro-lots ShadowV2

### ShadowV2-1 — Product Spec / Art Direction

Objectif: définir North Star, interdits, workflow, roadmap.

Fichiers probablement touchés:

- `reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md`

Ce qui est interdit:

- code;
- données;
- renderer;
- modèles;
- baseline.

Tests attendus:

- git status;
- rg invariants V1;
- baseline V1 présente.

Visual gate attendu:

- Aucun nouveau screenshot; audit baseline V1 seulement.

Critère de validation:

- spec V2 claire.

Risque:

- rester trop abstrait.

Pourquoi maintenant:

- clôture Shadow terminée; V2 doit être cadrée avant code.

### ShadowV2-2 — Data Model Design for Projected Building Shadows

Objectif: concevoir les futurs objets et compat JSON.

Fichiers probablement touchés:

- rapport design sous `reports/shadows/v2/`

Ce qui est interdit:

- ajouter modèle;
- migration;
- codec;
- runtime.

Tests attendus:

- aucun test code requis.

Visual gate attendu:

- références / maquettes conceptuelles si disponibles.

Critère de validation:

- choix modèle validé: preset paramétrique, extension asset future, compat time-of-day.

Risque:

- modèle trop large.

Pourquoi maintenant:

- avant toute modification `map_core`.

### ShadowV2-3 — JSON Characterization / Compatibility Prep

Objectif: caractériser JSON shadow existant avant ajout modèle.

Fichiers probablement touchés:

- tests `packages/map_core/test/shadow`
- rapport.

Ce qui est interdit:

- schema change;
- migration;
- runtime renderer.

Tests attendus:

- `cd packages/map_core && dart test test/shadow`

Visual gate attendu:

- Aucun.

Critère de validation:

- legacy JSON stable avant V2.

Risque:

- découvrir compat fragile.

Pourquoi maintenant:

- sécuriser le contrat avant d'étendre.

### ShadowV2-4 — Projected Building Shadow Value Objects

Objectif: ajouter objets Dart purs si design validé.

Fichiers probablement touchés:

- `packages/map_core/lib/src/models/**`
- tests map_core.

Ce qui est interdit:

- runtime;
- editor;
- Selbrume;
- renderer.

Tests attendus:

- tests value equality / validation.

Visual gate attendu:

- Aucun.

Critère de validation:

- objets purs, validation claire, pas de comportement runtime.

Risque:

- surface modèle trop grande.

Pourquoi maintenant:

- base de données authorées.

### ShadowV2-5 — Projected Building Shadow Codec

Objectif: JSON codec V2.

Fichiers probablement touchés:

- `map_core` codecs/models/tests.

Ce qui est interdit:

- migration globale;
- auto backfill;
- runtime inference.

Tests attendus:

- encode/decode;
- unknown/legacy compatibility;
- no regression shadow catalog.

Visual gate attendu:

- Aucun.

Critère de validation:

- JSON stable et explicitement authoré.

Risque:

- churn fixtures.

Pourquoi maintenant:

- préparer editor/runtime sans casser legacy.

### ShadowV2-6 — Editor Preview Design Gate

Objectif: designer preview no-code avant code editor.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- UI code;
- runtime;
- renderer.

Tests attendus:

- Aucun code.

Visual gate attendu:

- wireframe textuel ou capture référence.

Critère de validation:

- workflow utilisateur validé.

Risque:

- trop technique pour no-code.

Pourquoi maintenant:

- l'authoring doit être preview-first.

### ShadowV2-7 — Editor Preview POC for One Building

Objectif: preview éditeur pour un bâtiment sans runtime.

Fichiers probablement touchés:

- `packages/map_editor/**`
- tests application shadow.

Ce qui est interdit:

- runtime renderer;
- Selbrume data;
- auto apply.

Tests attendus:

- `cd packages/map_editor && flutter test test/application/shadow`

Visual gate attendu:

- screenshot editor preview si possible.

Critère de validation:

- l'utilisateur peut preview une ombre V2 authorée.

Risque:

- couplage editor/runtime.

Pourquoi maintenant:

- valider authoring avant runtime.

### ShadowV2-8 — Runtime Render Instruction V2 Design

Objectif: designer instruction runtime V2.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- code runtime;
- renderer;
- Selbrume.

Tests attendus:

- Aucun code.

Visual gate attendu:

- critères screenshots définis.

Critère de validation:

- render instruction V2 séparée de `genericProjection` auto.

Risque:

- réutiliser trop vite `projectedPolygon` sans garde-fou.

Pourquoi maintenant:

- éviter confusion V2 vs legacy projection.

### ShadowV2-9 — Runtime Render POC for One Building

Objectif: runtime consomme une donnée authorée V2 pour un bâtiment test.

Fichiers probablement touchés:

- `packages/map_runtime/**`
- tests runtime shadow.

Ce qui est interdit:

- auto-apply;
- runtime backfill;
- Selbrume global;
- generic default.

Tests attendus:

- `cd packages/map_runtime && flutter test test/shadow`
- harness screenshot POC.

Visual gate attendu:

- before/after sur un bâtiment.

Critère de validation:

- une ombre V2 authorée rendue sans nouvelle ombre implicite.

Risque:

- render pass ou ordre visuel.

Pourquoi maintenant:

- après modèles + preview.

### ShadowV2-10 — Selbrume 3 Buildings Authoring POC

Objectif: appliquer V2 à trois bâtiments ciblés.

Fichiers probablement touchés:

- données Selbrume uniquement si autorisation explicite;
- rapport;
- screenshots.

Ce qui est interdit:

- global backfill;
- petits props;
- arbres;
- migration large.

Tests attendus:

- harness Selbrume;
- runtime bundle policy.

Visual gate attendu:

- before/after 3 bâtiments + overview.

Critère de validation:

- rendu Pokémon-like validé sur cas réels.

Risque:

- données trop spécifiques.

Pourquoi maintenant:

- POC réel après pipeline prêt.

### ShadowV2-11 — Screenshot Harness Extension for V2

Objectif: étendre harness pour captures V2.

Fichiers probablement touchés:

- `packages/map_runtime/tool/shadow/**`
- baseline V2 sous rapports.

Ce qui est interdit:

- renderer;
- data mutation;
- CI fragile.

Tests attendus:

- harness command;
- analyze tool/shadow.

Visual gate attendu:

- captures V2 indexées.

Critère de validation:

- visual gate V2 reproductible.

Risque:

- baseline trop tôt.

Pourquoi maintenant:

- après POC visuel validé.

### ShadowV2-12 — Time-of-Day Parameter Design

Objectif: design des paramètres horaires.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- intégration runtime;
- cycle global;
- renderer.

Tests attendus:

- Aucun code.

Visual gate attendu:

- scénarios matin/midi/soir définis.

Critère de validation:

- time-of-day compatible V2 sans réécrire le modèle.

Risque:

- sur-concevoir avant besoin.

Pourquoi maintenant:

- après V2 visuelle POC, avant cycle jour/nuit réel.

## 16. Décision de priorité

Recommandation: garder la spec et ne pas lancer V2 tout de suite, sauf priorité produit immédiate.

Justification:

- V1 est stable.
- La crise Shadow est close.
- V2 nécessite direction artistique et design modèle avant code.
- D'autres priorités PokeMap peuvent reprendre sans risque immédiat.

Si on continue Shadow:

```text
ShadowV2-2 — Data Model Design for Projected Building Shadows
```

## 17. Tests / commandes lancées

Commandes:

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
rg -n "_autoShadowKindIsArtisticallySafe|ElementAutoShadowSuggestionKind" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
test -d reports/shadows/baselines/selbrume_shadow_v1
test -f reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
find reports/shadows/baselines/selbrume_shadow_v1 -maxdepth 1 -type f -name "*.png" | sort
```

Optional harness non lancé: documentation-only, minimum light checks suffisants.

## 18. Résultats

### git status initial

```text
(no output)
```

### AGENTS / design gate

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation: ce lot respecte le design gate, car il produit une spec/design uniquement.

### Fichiers audités

```text
present	reports/shadows/shadow_lot_68_shadow_recovery_closure_projected_building_shadows_v2_roadmap.md
present	reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
present	reports/shadows/shadow_lot_66_selbrume_shadow_golden_baseline_design.md
present	reports/shadows/shadow_lot_65_selbrume_shadow_screenshot_harness.md
present	reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
present	packages/map_runtime/tool/shadow/README.md
present	packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
present	packages/map_core/lib/src/models/shadow.dart
present	packages/map_core/lib/src/models/shadow_catalog.dart
present	packages/map_core/lib/src/operations/static_shadow_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_family_projection.dart
present	packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
present	packages/map_core/lib/src/operations/shadow_config_resolver.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

### Runtime auto-apply

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion: aucun appel dans `packages/map_runtime`.

### Policy Shadow V1

```text
6:enum ElementAutoShadowSuggestionKind {
21:  final ElementAutoShadowSuggestionKind kind;
46:  final ElementAutoShadowSuggestionKind? suggestionKind;
124:  if (!_autoShadowKindIsArtisticallySafe(
232:ElementAutoShadowSuggestionKind _classifyElement({
241:    return ElementAutoShadowSuggestionKind.tallThin;
244:    return ElementAutoShadowSuggestionKind.wideLow;
247:    return ElementAutoShadowSuggestionKind.wideLow;
250:    return ElementAutoShadowSuggestionKind.buildingLarge;
253:    return ElementAutoShadowSuggestionKind.wideLow;
256:    return ElementAutoShadowSuggestionKind.smallSquare;
258:  return ElementAutoShadowSuggestionKind.defaultProp;
261:bool _autoShadowKindIsArtisticallySafe(
262:  ElementAutoShadowSuggestionKind kind, {
267:    case ElementAutoShadowSuggestionKind.buildingLarge:
269:    case ElementAutoShadowSuggestionKind.tallThin:
270:    case ElementAutoShadowSuggestionKind.wideLow:
271:    case ElementAutoShadowSuggestionKind.smallSquare:
272:    case ElementAutoShadowSuggestionKind.defaultProp:
279:  ElementAutoShadowSuggestionKind kind,
282:    case ElementAutoShadowSuggestionKind.tallThin:
283:    case ElementAutoShadowSuggestionKind.smallSquare:
285:    case ElementAutoShadowSuggestionKind.buildingLarge:
286:    case ElementAutoShadowSuggestionKind.wideLow:
288:    case ElementAutoShadowSuggestionKind.defaultProp:
344:  ElementAutoShadowSuggestionKind kind,
348:    case ElementAutoShadowSuggestionKind.tallThin:
365:    case ElementAutoShadowSuggestionKind.buildingLarge:
382:    case ElementAutoShadowSuggestionKind.wideLow:
399:    case ElementAutoShadowSuggestionKind.smallSquare:
416:    case ElementAutoShadowSuggestionKind.defaultProp:
436:String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
438:    case ElementAutoShadowSuggestionKind.tallThin:
440:    case ElementAutoShadowSuggestionKind.buildingLarge:
442:    case ElementAutoShadowSuggestionKind.wideLow:
444:    case ElementAutoShadowSuggestionKind.smallSquare:
446:    case ElementAutoShadowSuggestionKind.defaultProp:
460:  ElementAutoShadowSuggestionKind? suggestionKind,
```

Conclusion: `buildingLarge` seul auto-safe; autres kinds non-safe.

### Baseline Selbrume V1

```text
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
```

Manifest:

```text
baselineId selbrume_shadow_v1
sourceLot Shadow-65
mapId Selbrume
counts {'staticInstructions': 10, 'contactLedge': 10, 'genericProjection': 0, 'captures': 11}
captures 11
```

## 19. git diff --stat

Après création de ce rapport, `git diff --stat` ne montre pas les fichiers non suivis.

```text
(no output)
```

## 20. git diff --name-status

Après création de ce rapport:

```text
(no output)
```

## 21. git diff --check

Après création de ce rapport:

```text
(no output)
```

## 22. git status final

Après création de ce rapport attendu:

```text
?? reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md
```

## 23. Risques / réserves

- Sans image de référence locale, la spec s'appuie sur la description utilisateur.
- Option D peut devenir trop large si elle est implémentée en une fois.
- Time-of-day doit rester futur; l'intégrer trop tôt fragiliserait V2.
- Reprendre `projectedPolygon` sans nouveau modèle authoré risquerait de recréer le problème V1.

## 24. Auto-critique

La spec protège bien contre le retour de `genericProjection`, mais elle demande une discipline forte en micro-lots. Le vrai risque n'est pas technique: c'est de vouloir aller directement au renderer sans passer par modèle, preview, POC limité et visual gate.

## 25. Regard critique sur le prompt

Le prompt est strict dans le bon sens: il réouvre l'ambition artistique sans autoriser de code. Il force la séparation entre V1 stable et V2 future, ce qui évite de dégrader Selbrume pendant la conception.

## 26. Prochain lot recommandé

Si ShadowV2 continue:

```text
ShadowV2-2 — Data Model Design for Projected Building Shadows
```

Objectif:

- choisir précisément les objets V2;
- définir compat JSON;
- définir séparation V1 contact ledge / V2 projected building;
- préparer time-of-day sans implémenter.

Sinon:

```text
Pause Shadow / reprendre autre chantier PokeMap.
```

## 27. Inventaire des fichiers

Créé:

- `reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md`

Modifié:

- Aucun.

Supprimé:

- Aucun.

Code modifié:

- Aucun.

Fichiers Selbrume modifiés:

- Aucun.

Commit:

- Aucun.
