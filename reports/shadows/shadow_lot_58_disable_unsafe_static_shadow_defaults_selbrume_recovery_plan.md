# Shadow-58 — Disable Unsafe Static Shadow Defaults / Selbrume Recovery Plan V0

## 1. Résumé exécutif

Shadow-58 est arrêté au design gate imposé par `AGENTS.md`.

Le lot demandé touche une policy d’authoring visuelle et produit-facing. Le fichier `AGENTS.md` applicable indique :

```text
Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Donc ce rapport ne modifie aucun fichier de production. Il fournit le design précis du durcissement de policy, le plan de récupération Selbrume, et le dry-run chiffré à appliquer après validation.

Décision principale proposée :

```text
La policy auto-shadow ne doit plus produire d’ombre automatique pour tallThin, wideLow, smallSquare, defaultProp ou unknown/family null.
Le seul chemin automatique encore acceptable en V0 est buildingLarge vers family building, car le runtime/editor utilisent déjà le contact ledge minimal pour StaticShadowFamily.building.
Les anciennes auto-shadows reconnues qui n’ont plus de suggestion doivent être nettoyées vers shadow: null par le backfill explicite editor/core.
```

Cette décision respecte la règle produit :

```text
Mieux vaut aucune ombre qu’une mauvaise ombre.
```

## 2. Rappel Shadow-57

Shadow-57 a établi l’état réel après suppression du runtime auto-apply :

```text
Selbrume contient 63 éléments.
25 éléments ont une config Shadow authorée.
Selbrume contient 2105 placements.
112 placements référencent un élément source avec config Shadow.
0 placement a un shadowOverride non-null.
Le runtime produit 111 instructions statiques groundStatic.
111 / 111 instructions statiques sont en shapeKind projectedPolygon.
101 instructions sont des projections diagonales réelles.
10 instructions sont des contact ledges building rendues via projectedPolygon.
97 instructions sont en genericProjection.
95 instructions viennent de arbre_pixellab_1 et arbre_pixellab_2.
panneau produit 1 projection dangereuse.
lampadaire produit 4 projections conceptuellement mauvaises.
```

Diagnostic repris :

```text
Le runtime n’invente plus les ombres.
Il affiche fidèlement des configs authorées dangereuses.
```

## 3. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

Interprétation :

```text
Worktree propre au démarrage de Shadow-58.
```

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie exacte :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Le `AGENTS.md` applicable pour ce repo est :

```text
/Users/karim/Project/pokemonProject/AGENTS.md
```

## 4. Décision AGENTS / design gate

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|Do not invoke implementation" AGENTS.md
```

Sortie exacte :

```text
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

```text
Shadow-58 est un changement de policy / authoring / comportement produit.
Le design gate s’applique.
Aucun fichier de production n’est modifié dans ce rapport.
L’implémentation doit attendre validation explicite du design Shadow-58.
```

## 5. Audit de la policy auto-shadow actuelle

Fichier audité :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

État réel observé :

```text
buildElementAutoShadowSuggestion(...)
-> lit les dimensions de la première frame
-> ignore micro decor <= 1x2
-> classifie par heuristique dimensionnelle
-> accepte tallThin, buildingLarge, certains wideLow
-> produit une ProjectElementShadowConfig avec family, footprint, scale, opacity
```

Classification actuelle :

```text
1x4 ou 3x5 vertical -> tallThin
4x3, 6x7, grands éléments -> buildingLarge
4x2 ou certains wideLow -> wideLow
2x2 -> smallSquare, mais refusé par _autoShadowKindIsArtisticallySafe
2x3 -> defaultProp, mais refusé par _autoShadowKindIsArtisticallySafe
```

Risque principal :

```text
tallThin et wideLow restent considérés comme artistiquement safe.
Dans Selbrume, cela couvre justement lampadaire et panneaux/barrières/props bas, qui produisent des projections visibles non désirées.
```

Second risque :

```text
Les configs legacy reconnues sont remplacées par la suggestion actuelle si une suggestion existe.
Donc un vieux shadow large de lampadaire peut être remplacé par tallProp au lieu d’être retiré.
```

Troisième risque :

```text
La famille null reste dangereuse au rendu lorsqu’elle arrive depuis un manifest authoré, car la résolution de projection peut tomber vers genericProjection.
Shadow-58 ne doit pas changer le runtime, mais la policy/backfill ne doit plus créer ni renouveler ce type de config.
```

## 6. Preuve que runtime auto-apply reste absent

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Sortie exacte :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:451:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:142:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:144:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:169:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:194:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:221:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:256:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:293:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion :

```text
map_runtime : aucun appel.
map_core : définition + tests.
map_editor : backfill explicite côté authoring.
```

## 7. Résultat exact de l’audit policy rg

Commande :

```bash
rg -n "genericProjection|tallThin|wideLow|buildingLarge|appliedGeneric|clearedAutoNoSuggestion|lampadaire|panneau|arbre|tree|foliage|wide low|tall thin" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart packages/map_core/test/shadow/element_auto_shadow_policy_test.dart packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Sortie exacte :

```text
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:23:    test('wide low needs enough surface', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:36:      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:40:    test('tall thin and building elements receive suggestions', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:50:      expect(tall!.kind, ElementAutoShadowSuggestionKind.tallThin);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:52:      expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:56:    test('Selbrume lamp proportions receive calibrated tall thin config', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:58:        element: _element(id: 'lampadaire', width: 3, height: 5),
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:62:      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.tallThin);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:77:    test('Selbrume wide barriers stay wide low instead of building', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:83:      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:104:      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:163:        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:225:              id: 'lampadaire',
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:239:        ElementAutoShadowBackfillStatus.appliedGeneric,
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:276:        ElementAutoShadowBackfillStatus.appliedGeneric,
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:297:              id: 'lampadaire',
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:323:        everyElement(ElementAutoShadowBackfillStatus.appliedGeneric),
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:543:          family: shadow.family ?? StaticShadowFamily.genericProjection,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:28:        ElementAutoShadowSuggestionKind.tallThin,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:29:        ElementAutoShadowSuggestionKind.buildingLarge,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:79:        ElementAutoShadowBackfillStatus.appliedGeneric,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:186:        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:191:    test('clears genericProjection auto shadow when policy has no suggestion',
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:212:        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:217:    test('clears recognized auto wide low shadow below safe threshold', () {
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:237:        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:333:        ElementAutoShadowBackfillStatus.appliedGeneric,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:402:            presetKind: ElementPresetKind.tree,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:423:      expect(result.project.elements[0].presetKind, ElementPresetKind.tree);
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:518:    family: StaticShadowFamily.genericProjection,
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:67:    test('classifies tall thin elements as tallThin', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:73:      expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:83:    test('classifies large buildings as buildingLarge', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:89:      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:100:    test('wide low needs enough surface to receive an automatic shadow', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:111:      expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:140:    test('prefers default compact profile for tallThin', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:156:      final tallThin = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:170:      final wideLow = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:177:      expect(tallThin.config.shadowProfileId, 'custom-contact');
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:179:      expect(wideLow.config.shadowProfileId, 'custom-wide');
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:7:  tallThin,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:8:  buildingLarge,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:9:  wideLow,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:28:  appliedGeneric,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:32:  clearedAutoNoSuggestion,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:82:            entry.status == ElementAutoShadowBackfillStatus.appliedGeneric,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:90:            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:174:            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:205:        : ElementAutoShadowBackfillStatus.appliedGeneric;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:241:    return ElementAutoShadowSuggestionKind.tallThin;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:244:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:247:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:250:    return ElementAutoShadowSuggestionKind.buildingLarge;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:253:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:267:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:268:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:270:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:283:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:286:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:287:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:349:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:366:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:383:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:426:        family: StaticShadowFamily.genericProjection,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:439:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:440:      return 'lampadaire fin';
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:441:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:443:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:454:      entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:455:      entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:541:    family: StaticShadowFamily.genericProjection,
```

## 8. Changement exact de policy proposé

À implémenter après validation explicite.

### 8.1 Production

Fichier à modifier :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

Changement minimal proposé :

```dart
bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.wideLow:
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}
```

Effet :

```text
tallThin -> plus de suggestion auto.
wideLow -> plus de suggestion auto.
smallSquare -> reste sans suggestion.
defaultProp -> reste sans suggestion.
buildingLarge -> seul chemin auto conservé.
```

Justification :

```text
La policy actuelle utilise seulement dimensions/forme générale.
Elle ne sait pas distinguer proprement panneau, lampadaire, arbre, barrière, petit prop, stand ou bâtiment stylisé.
Le seul cas encore suffisamment défendable en V0 est le bâtiment large, car family building est rendu par contact ledge minimal dans runtime/editor, pas par longue dalle diagonale.
```

### 8.2 Backfill legacy

Comportement attendu après ce changement :

```text
Un vieux shadow auto reconnu sur un tallThin ou wideLow n’aura plus de suggestion.
applyElementAutoShadowPolicyToProject(...) doit donc le classer clearedAutoNoSuggestion et écrire shadow: null.
Une shadow manuelle reste préservée.
Une shadow disabled reste préservée.
Une shadow avec footprint ou overrides numériques non reconnus reste préservée comme manuelle.
```

Point à vérifier pendant implémentation :

```text
_isRecognizedAutoShadow(...) reconnaît déjà _shadow53TallThinShadow(), _shadow53WideLowShadow(), _oldAutoWideLowShadow(), _oldAutoDefaultPropShadow() et les broad legacy Selbrume.
Il faudra vérifier que ces configs sont bien nettoyées quand la nouvelle policy ne produit plus de suggestion.
```

### 8.3 Building safe path

À conserver :

```text
buildingLarge -> ProjectElementShadowConfig family: StaticShadowFamily.building
```

Pourquoi :

```text
Le runtime/editor ont déjà un traitement spécial building contact ledge.
Shadow-57 a séparé les 10 contact ledges building des 101 vraies projections diagonales dangereuses.
```

À ne pas faire dans Shadow-58 :

```text
Ne pas changer static_shadow_contact_ledge_geometry.dart.
Ne pas changer static_shadow_family_projection.dart.
Ne pas changer shadow_config_resolver.dart.
Ne pas changer renderer.
```

## 9. Tests ajoutés/modifiés à prévoir

À implémenter après validation explicite.

### 9.1 `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`

Modifier les attentes existantes :

```text
- "tall thin and building elements receive suggestions"
  -> doit devenir "tall thin returns null while building receives suggestion".

- "Selbrume lamp proportions receive calibrated tall thin config"
  -> doit devenir "Selbrume lamp proportions receive no automatic shadow".

- "Selbrume wide barriers stay wide low instead of building"
  -> doit devenir "Selbrume wide barriers receive no automatic shadow".

- "backfill replaces broad legacy Selbrume shadow without family"
  -> pour lampadaire ou family null dangereux, attendre clearedAutoNoSuggestion + shadow null.

- "backfill upgrades Shadow-53 auto shadows to Shadow-54 tuning"
  -> tallThin et wideLow doivent être clearedAutoNoSuggestion ; building reste appliedGeneric.
```

Ajouter des tests explicites :

```text
- panneau 3x3 -> buildElementAutoShadowSuggestion(...) == null.
- lampadaire 3x5 -> buildElementAutoShadowSuggestion(...) == null.
- arbre 7x7 ou 5x8 unknown -> buildElementAutoShadowSuggestion(...) == null ou building si la classification actuelle le force ; si building est encore produit, ne pas utiliser ce test par nom tant que la policy ne lit pas les noms.
- large unknown family null legacy broad -> backfill clearedAutoNoSuggestion si reconnu legacy et sans family building.
- building 6x7 -> family building conservée.
```

Point important :

```text
Ne pas introduire de logique hardcodée panneau/lampadaire/arbre dans map_core.
Les noms servent aux tests lisibles, pas aux règles de production.
```

### 9.2 `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

Modifier :

```text
- "classifies tall thin elements as tallThin" -> attendre null.
- "wide low needs enough surface to receive an automatic shadow" -> attendre null pour 4x2 aussi.
- "prefers default compact profile for tallThin" -> supprimer ou remplacer par building profile fallback.
- "falls back to custom compatible profile ids" -> enlever tallThin/wideLow de ce test ; garder building.
- _allSuggestionKinds() -> ne doit plus inclure que buildingLarge, sauf décision contraire validée.
```

### 9.3 `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

Modifier :

```text
- "applies suggestions to elements without shadow configs"
  -> lamp ne doit plus être appliedMissing ; house reste appliedMissing.

- "replaces generic pre-footprint active shadows"
  -> si l’élément testé est stand 4x2, attendre clearedAutoNoSuggestion ou skippedManual selon reconnaissance.

- "replaces generic shadows with missing profile ids"
  -> lamp devient clearedAutoNoSuggestion si reconnu auto ; sinon skippedManual si non reconnu.

- "adds default profiles when the catalog has no compatible profile"
  -> utiliser un building, pas un lamp.

- "preserves element order and non-shadow fields"
  -> premier élément tree/lamp ne doit plus avoir shadow ; second building peut rester.
```

## 10. Commandes de tests à lancer après validation

Après implémentation, lancer :

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart analyze lib/src/operations/element_auto_shadow_policy.dart
```

Tests non lancés dans ce rapport :

```text
Aucun test de régression n’a été lancé, car le design gate empêche l’implémentation dans ce tour.
Le rapport ne prétend donc pas que la nouvelle policy passe les tests.
```

## 11. Plan de récupération Selbrume

Selbrume est audité en lecture seule. Aucun fichier original n’est modifié.

Commandes :

```bash
jq -r '.elements | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow != null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow == null)] | length' /Users/karim/Desktop/selbrume/project.json
```

Sortie exacte :

```text
63
25
38
```

Commande :

```bash
jq -r '.elements[] | select(.id=="panneau" or .id=="lampadaire" or .id=="arbre_pixellab_1" or .id=="arbre_pixellab_2" or .id=="selbrume_maison_5") | [.id, .name, (.frames[0].source.width // "?"), (.frames[0].source.height // "?"), (.shadow.castsShadow // "null"), (.shadow.shadowProfileId // "null"), (.shadow.family // "null"), (.shadow.opacity // "null"), (.shadow.scaleX // "null"), (.shadow.scaleY // "null"), (.shadow.footprint.anchorXRatio // "null"), (.shadow.footprint.anchorYRatio // "null"), (.shadow.footprint.footprintWidthRatio // "null"), (.shadow.footprint.footprintHeightRatio // "null")] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Sortie exacte :

```text
selbrume_maison_5	selbrume maison 5	7	6	true	default-ground-soft-ellipse	null	0.22	null	null	0.5	0.96	0.68	0.08
lampadaire	lampadaire	3	5	true	default-ground-contact-blob	tallProp	0.2	0.8	0.55	0.5	1.0	0.28	0.05
arbre_pixellab_1	arbre  pixelLab 1	7	7	true	default-ground-soft-ellipse	null	0.25	null	null	0.5	0.92	0.58	0.1
arbre_pixellab_2	arbre  pixelLab 2	5	8	true	default-ground-soft-ellipse	null	0.25	null	null	0.5	0.92	0.5	0.1
panneau	panneau	3	3	true	default-ground-wide-ellipse	null	0.27	0.92	0.75	0.5	0.95	0.72	0.1
```

Commande :

```bash
jq -r '[.. | objects | select(has("elementId"))] as $placed | [$placed|length, ($placed|map(select(.elementId=="panneau"))|length), ($placed|map(select(.elementId=="lampadaire"))|length), ($placed|map(select(.elementId=="arbre_pixellab_1"))|length), ($placed|map(select(.elementId=="arbre_pixellab_2"))|length), ($placed|map(select(.elementId=="selbrume_maison_5"))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie exacte :

```text
2105	1	4	46	49	1
```

Commande :

```bash
jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie exacte :

```text
2105	0	2105
```

Plan V0 proposé :

| elementId | placements | action | raison | effet attendu |
|---|---:|---|---|---|
| `panneau` | 1 | `shadow: null` | petit prop/panneau, projection visible inutile | retire 1 projection dangereuse |
| `lampadaire` | 4 | `shadow: null` | tall prop vertical, ombre statique projetée incohérente ; actor/contact suffit si un jour asset-driven | retire 4 projections dangereuses |
| `arbre_pixellab_1` | 46 | `shadow: null` | arbre/foliage sans asset-driven strategy ; gros contributeur visuel | retire 46 projections dangereuses |
| `arbre_pixellab_2` | 49 | `shadow: null` | arbre/foliage sans asset-driven strategy ; gros contributeur visuel | retire 49 projections dangereuses |
| `selbrume_maison_5` | 1 | `shadow: null` en V0 ou `manual-review` | family null, genericProjection probable ; bâtiment atypique à revoir manuellement | retire 1 projection generic dangereuse si désactivé |

Note :

```text
Ces actions ne doivent pas être appliquées dans Shadow-58 tant que l’utilisateur n’a pas validé le nettoyage.
Le plan peut être transformé ensuite en patch Selbrume ou en outil d’audit dry-run.
```

## 12. Dry-run Selbrume before/after

Le before reprend les instructions runtime inventoriées dans Shadow-57.

Before :

```text
static instructions total: 111
projectedPolygon total: 111
real diagonal projections: 101
building contact ledge rendered as projectedPolygon: 10
genericProjection total: 97
instructions from arbre_pixellab_1: 46
instructions from arbre_pixellab_2: 49
instructions from trees total: 95
instructions from panneau: 1
instructions from lampadaire: 4
instructions from selbrume_maison_5: 1
```

Dry-run action V0 :

```text
Disable panneau.
Disable lampadaire.
Disable arbre_pixellab_1.
Disable arbre_pixellab_2.
Disable selbrume_maison_5.
```

After dry-run attendu :

```text
static instructions total: 10
projectedPolygon total: 10
real diagonal projections: 0
building contact ledge rendered as projectedPolygon: 10
genericProjection total: 0
instructions from arbre_pixellab_1: 0
instructions from arbre_pixellab_2: 0
instructions from trees total: 0
instructions from panneau: 0
instructions from lampadaire: 0
instructions from selbrume_maison_5: 0
```

Calcul :

```text
111 - 46 - 49 - 1 - 4 - 1 = 10
97 genericProjection - 46 - 49 - 1 - 1 = 0
```

Limite :

```text
Ce dry-run est arithmétique à partir de l’inventaire Shadow-57 et des placements Selbrume vérifiés ci-dessus.
Aucune copie Selbrume n’a été écrite dans ce tour, car le design gate bloque l’implémentation.
```

## 13. Ce qui est volontairement non modifié

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
packages/map_core/lib/src/operations/shadow_config_resolver.dart
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Non-objectifs respectés dans ce rapport :

```text
Aucun renderer.
Aucune nouvelle shape.
Aucun profil global.
Aucune nouvelle family.
Aucun shader.
Aucun blur.
Aucun screenshot harness.
Aucune UI.
Aucun provider.
Aucun repository.
Aucune migration JSON.
Aucun build_runner.
Aucun generated file.
```

## 14. Risques / réserves

1. Le changement de policy proposé va rendre l’auto-shadow beaucoup plus conservatrice. C’est volontaire.
2. Certains assets qui recevaient une suggestion automatique n’en recevront plus. C’est cohérent avec “mieux vaut aucune ombre”.
3. Les éléments déjà authorés dans Selbrume resteront visibles tant qu’un nettoyage de données n’est pas explicitement appliqué.
4. `genericProjection` reste dans le modèle et le renderer pour compatibilité ; Shadow-58 ne doit pas le supprimer.
5. `buildingLarge` reste une heuristique dimensionnelle. Elle peut encore mal classer certains arbres ou gros props si utilisée aveuglément. C’est acceptable seulement parce que Shadow-58 recommande un nettoyage Selbrume séparé et une future approche asset-driven.

## 15. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat au moment de rédaction du rapport :

```text

```

Note :

```text
Le rapport est un fichier non suivi tant qu’il n’est pas ajouté à Git ; git diff --stat ne liste pas les fichiers non suivis.
```

## 16. git diff --name-status

Commande :

```bash
git diff --name-status
```

Résultat au moment de rédaction du rapport :

```text

```

## 17. git diff --check

Commande :

```bash
git diff --check
```

Résultat au moment de rédaction du rapport :

```text

```

## 18. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
?? reports/shadows/shadow_lot_58_disable_unsafe_static_shadow_defaults_selbrume_recovery_plan.md
```

Interprétation :

```text
Le seul changement permanent du lot est le rapport Shadow-58.
Aucun fichier de production n’est modifié.
Aucun fichier Selbrume original n’est modifié.
```

## 19. Auto-critique

Ce rapport respecte le design gate, mais il ne livre pas encore le durcissement de policy. C’est frustrant mais nécessaire : le prompt demandait explicitement de s’arrêter si `AGENTS.md` imposait une étape design.

Le plan proposé est volontairement plus radical que les lots précédents : il ne tente pas de rendre les plaques plus jolies, il empêche la policy d’en recréer pour les familles dangereuses.

Le point le plus discutable est la conservation de `buildingLarge` comme seule suggestion automatique. Si les bâtiments continuent à poser problème visuellement, le lot suivant devra aussi rendre les bâtiments opt-in ou passer à un workflow 100 % manuel/asset-driven.

## 20. Regard critique sur le prompt

Le prompt demande à la fois :

```text
- implémenter la policy hardening ;
- respecter le design gate AGENTS ;
- produire le dry-run.
```

Ces exigences sont compatibles uniquement si le design gate ne bloque pas. Ici il bloque, donc la réponse correcte est de produire le rapport de design et de demander validation avant production.

Le prompt a raison sur le fond produit : continuer à calibrer des projections visibles serait une fuite en avant.

## 21. Prochain lot recommandé

Après validation de ce design :

```text
Shadow-58 Implementation — Disable Unsafe Static Shadow Defaults
```

Scope recommandé :

```text
1. Modifier _autoShadowKindIsArtisticallySafe pour ne garder que buildingLarge.
2. Adapter les tests core.
3. Adapter les tests editor application shadow.
4. Relancer les tests ciblés.
5. Créer un rapport d’implémentation avec fichiers complets.
```

Puis :

```text
Shadow-59 — Selbrume Authored Shadow Cleanup Patch / Explicit Data Review
```

Scope recommandé :

```text
1. Appliquer explicitement le plan de nettoyage aux cinq elementId validés.
2. Ne pas toucher aux autres éléments.
3. Comparer before/after runtime instruction inventory.
4. Vérifier visuellement que les grandes plaques ont disparu.
```

## 22. Inventaire des fichiers créés / modifiés / supprimés

Fichiers créés :

```text
reports/shadows/shadow_lot_58_disable_unsafe_static_shadow_defaults_selbrume_recovery_plan.md
```

Fichiers modifiés :

```text
Aucun fichier existant modifié.
```

Fichiers supprimés :

```text
Aucun.
```

Fichiers de production modifiés :

```text
Aucun.
```

Fichiers Selbrume modifiés :

```text
Aucun.
```

Fichiers générés :

```text
Aucun.
```

Fichiers non suivis préexistants :

```text
Aucun au démarrage.
```

Code complet des fichiers créés/modifiés :

```text
Le seul fichier créé est ce rapport Markdown. Conformément aux règles repo, le rapport ne s’auto-embarque pas récursivement ; son contenu complet est le présent fichier.
```
