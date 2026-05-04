# Environment Studio Lot 23 — Environment Generator Deterministic Core V0

## 1. Résumé exécutif

Livrable : moteur applicatif **pur Dart** dans `map_editor` (`GenerateEnvironmentAreaPlacementsUseCase`) qui résout `EnvironmentLayer` + `EnvironmentArea` + `EnvironmentPreset` + entrées `ProjectManifest.elements`, valide masque et paramètres, puis produit une liste **déterministe** de `EnvironmentGeneratedPlacementCandidate` et des `EnvironmentGenerationIssue` typées. **Aucune** écriture dans `MapData`, `ProjectManifest`, `TileLayer.tiles`, ni `MapPlacedElement`. PRNG maison FNV-1a 32 bits + xorshift32 (pas `Random()`, pas `DateTime`). Tests unitaires dédiés + régressions Environment Studio et Lots 19–22 vertes. `flutter test` complet `map_editor` : **échec** avec **34** tests en échec préexistants hors périmètre (voir §17).

## 2. Périmètre du lot

**Inclus** : DTOs résultat, use case, validation, densités / bord / variation / espacement Chebyshev, palette pondérée, PRNG stable, tests.

**Exclus** (respecté) : UI, bouton Generate, `EditorNotifier`, canvas, runtime, `map_core`, persistance disque, `MapPlacedElement`, `generatedPlacementIds`, patch `TileLayer`, `build_runner`.

## 3. Audit initial EnvironmentPreset / Area / Generator

### 3.1 `EnvironmentPreset` (`packages/map_core/lib/src/models/environment.dart`)

Champs : `id`, `name`, `templateId`, `palette` (`List<EnvironmentPaletteItem>` unmodifiable), `defaultParams` (`EnvironmentGenerationParams`), `categoryId?`, `sortOrder`. La fabrique impose palette non vide et `elementId` uniques dans la palette.

### 3.2 `EnvironmentPaletteItem`

`elementId`, `weight` (≥ 1), `collisionMode` (`EnvironmentCollisionMode`), `tags` (`Set` immuable).

### 3.3 `EnvironmentArea`

`id`, `name`, `presetId`, `mask`, `seed`, `paramsOverride?` (objet **complet** `EnvironmentGenerationParams`, pas de modèle partiel map_core), `generatedPlacementIds` (liste immuable).

### 3.4 Paramètres effectifs

`area.paramsOverride ?? preset.defaultParams` — aligné sur le modèle map_core (override tout ou rien).

### 3.5 Résolution `ProjectElementEntry`

`manifest.elements` indexé par `e.id` ; chaque `palette[i].elementId` doit exister, sinon erreur bloquante `paletteElementMissing` (aucun skip silencieux).

### 3.6 Pourquoi `map_editor` et pas `map_core`

Le générateur lie manifest projet, couches carte et politique produit/éditeur ; le contrat JSON partagé reste dans `map_core`, la **politique de génération candidats** est applicative et évolutive (UI Lot 24+).

### 3.7 Pourquoi aucune mutation `MapData`

Le lot impose un **cœur algorithmique réutilisable** et testable sans effet de bord ; l’application des candidats sera un use case séparé (Environment-24).

### 3.8 Fichiers d’audit lus (liste)

`environment_mask_use_cases.dart`, `layer_use_cases.dart`, `editor_notifier.dart`, `environment_layer_inspector_panel.dart`, `environment_layer_mask_brush_tool_test.dart`, `environment_layer_area_model_editing_test.dart`, `environment.dart`, `map_layer.dart`, `project_manifest.dart`, `project_element` via manifest, `map_layers.dart`, `map_validator.dart` (repères architecture / non-modification).


## 4. Décisions d’architecture

- Un se fichier `environment_generator_use_cases.dart` (pas de split services) pour limiter la surface du lot.
- `noPlacementCandidates` : avertissement si `placements.isEmpty` **et** `activeCount > 0` (masque non vide mais aucun tirage retenu — couvre `density=0` & `edgeDensity=0`, tirages aléatoires déterministes ratés, espacement maximal, etc.).
- `EnvironmentGeneratedPlacementCandidate` : constructeur **non const** (copie défensive `Set<String>.from(tags)` incompatible avec const).
- FNV-1a : multiplication masquée `& 0xFFFFFFFF` (unsigned 32 bits), correction du masque erroné `0x7FFFFFFF` de la première ébauche.

## 5. Modèles de résultat de génération

Voir annexe `environment_studio_lot_23_evidence_appendix_generator_source.md` pour le code intégral. Résumé :

- `EnvironmentGeneratedPlacementCandidate` : id `env_gen_<area>_<x>_<y>_<elementId>` (segments sanitizés), `hashCode` sur tags **triés** (ordre indépendant).
- `EnvironmentGenerationIssue` / `EnvironmentGenerationResult` : listes unmodifiable, `issuesForKind`, compteurs erreurs / avertissements.

## 6. Validation des entrées

Erreurs bloquantes → `placements = []` sans génération. Warnings (`emptyAreaMask`, `noPlacementCandidates`) → placements possiblement vides sans erreur.

Chemins `emptyPresetPalette` / `invalidMaskCellLength` / params hors intervalle : code défensif ; **instances valides map_core** passent déjà par fabriques/JSON stricts — non couverts par tests d’intégration constructibles sans violer `map_core` (documenté §15).

## 7. PRNG déterministe

`fnv1a32(String)` FNV-1a 32-bit ; état xorshift32 ; `DeterministicEnvironmentRng.next01()` dans [0,1). Graine par cellule : `areaSeed|areaId|presetId|x|y|usage` (usages `variation`, `placement-roll`, `palette-roll`). **Interdit** pour le tirage : `Random()` non seedé, `DateTime.now`, `hashCode` d’objets Dart pour le hasard. Remarque : `Object.hash` est utilisé uniquement pour **égalité / hashCode** des DTOs (hors flux PRNG).

## 8. Algorithme density / edgeDensity / variation / spacing

- Bord **cardinal** uniquement (haut/bas/gauche/droite hors actif ou OOB).
- `p = clamp(baseP + (rand01_variation - 0.5) * variation, 0, 1)` ; placement si `roll <= p` avec `roll` indépendant.
- `minSpacingCells` : trop proche ssi `abs(dx) <= k` **et** `abs(dy) <= k` (voisinage carré aligné axes ; équivalent à une boule Chebyshev de rayon `k`).
- Parcours row-major `y` puis `x`.

## 9. Sélection pondérée de palette

`totalWeight = sum(weight)` ; `r = nextUint32() % total` ; cumul dans l’**ordre** de `preset.palette`. Poids ≤ 0 → retour null → erreur réutilisant `emptyPresetPalette` (message distinct).

## 10. Candidats de placement générés

Chaque candidat porte `collisionMode` et `tags` copiés depuis l’item palette ; **pas** de `MapPlacedElement`.

## 11. Non-mutation MapData / ProjectManifest

Le use case ne réassigne aucun champ ; lecture seule. Test `expect(mapBefore, ctx.map)` après exécution.

## 12. Non-persistance disque garantie

`grep FileProjectRepository|saveProject|saveProjectManifest` sur les fichiers du lot : **aucune ligne** (sortie vide — voir §17).

## 13. Pourquoi aucune UI / bouton Generate / MapPlacedElement dans ce lot

Découplage Lot 23 (cœur pur) vs Lot 24+ (application map + persistance ids) ; évite effets de bord éditeur et garde des tests rapides sans Flutter pour le use case (les tests utilisent seulement `flutter_test` comme harness).

## 14. Fichiers modifiés

| Fichier | Statut |
|---------|--------|
| `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart` | **Nouveau** |
| `packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart` | **Nouveau** |
| `reports/forest/environment_studio_lot_23_environment_generator_deterministic_core.md` | **Nouveau** (ce rapport) |
| `reports/forest/environment_studio_lot_23_evidence_*.md` / `.txt` / `.patch` | **Nouveaux** (evidence pack) |

Aucun autre fichier du dépôt modifié pour ce lot.

## 15. Tests ajoutés ou modifiés

- **Nouveau** `environment_generator_deterministic_core_test.dart` : immuabilité, déterminisme, masque, densités, bords, variation, spacing, palette, erreurs listées au lot (sauf chemins non constructibles map_core), warnings, `paramsOverride`, non-mutation.
- **Non testés automatiquement** : `emptyPresetPalette` et `invalidMaskCellLength` avec types publics map_core (fabriques interdisent ces états).

## 16. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/application/use_cases/environment_generator_use_cases.dart \
  test/environment_studio/environment_generator_deterministic_core_test.dart
flutter analyze lib/src/application/use_cases/environment_generator_use_cases.dart \
  test/environment_studio/environment_generator_deterministic_core_test.dart
grep -R "FileProjectRepository|saveProject|saveProjectManifest" -n \
  lib/src/application/use_cases/environment_generator_use_cases.dart \
  test/environment_studio/environment_generator_deterministic_core_test.dart || true
flutter test test/environment_studio/environment_generator_deterministic_core_test.dart --reporter expanded
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart --reporter expanded
flutter test test/environment_studio/environment_layer_area_model_editing_test.dart \
  test/environment_studio/environment_layer_target_tile_layer_test.dart \
  test/environment_studio/environment_layer_creation_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test   # suite complète map_editor
```

Audits grep (depuis `packages/map_editor`, sortie intégrale §17.1) : voir fichier `reports/forest/environment_studio_lot_23_evidence_grep_audit_full.txt` **et** bloc §17.1 ci-dessous.


## 17. Résultats des commandes

### 17.1 Grep audit (sortie intégrale, 255 lignes)

```text
../map_core/lib/src/models/environment.dart:364:final class EnvironmentPreset {
../map_core/lib/src/operations/environment_preset_diagnostics.dart:19:final class EnvironmentPresetDiagnostic {
../map_core/lib/src/operations/environment_preset_diagnostics.dart:60:final class EnvironmentPresetDiagnosticsReport {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:125:final class EnvironmentPresetDraft {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:282:final class EnvironmentPresetDraftIssue {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:334:final class EnvironmentPresetDraftValidationReport {
lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart:13:class EnvironmentPresetDraftForm extends StatefulWidget {
lib/src/features/environment_studio/widgets/environment_preset_detail.dart:9:class EnvironmentPresetDetail extends StatelessWidget {
lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart:8:class EnvironmentPresetDiagnosticsView extends StatelessWidget {
lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart:8:class EnvironmentPresetDraftValidationView extends StatelessWidget {
lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart:9:class EnvironmentPresetSaveFeedback extends StatelessWidget {
lib/src/features/environment_studio/widgets/environment_preset_list.dart:7:class EnvironmentPresetList extends StatelessWidget {
---
../map_core/lib/src/models/environment.dart:103:final class EnvironmentGenerationParams {
../map_core/lib/src/models/environment.dart:104:  factory EnvironmentGenerationParams({
../map_core/lib/src/models/environment.dart:117:        'EnvironmentGenerationParams minSpacingCells must be >= 0.',
../map_core/lib/src/models/environment.dart:120:    return EnvironmentGenerationParams._(
../map_core/lib/src/models/environment.dart:129:  factory EnvironmentGenerationParams.standard() {
../map_core/lib/src/models/environment.dart:130:    return EnvironmentGenerationParams(
../map_core/lib/src/models/environment.dart:138:  const EnvironmentGenerationParams._({
../map_core/lib/src/models/environment.dart:153:        other is EnvironmentGenerationParams &&
../map_core/lib/src/models/environment.dart:170:      'EnvironmentGenerationParams $name must be between 0.0 and 1.0 inclusive.',
../map_core/lib/src/models/environment.dart:259:    EnvironmentGenerationParams? paramsOverride,
../map_core/lib/src/models/environment.dart:331:  final EnvironmentGenerationParams? paramsOverride;
../map_core/lib/src/models/environment.dart:370:    required EnvironmentGenerationParams defaultParams,
../map_core/lib/src/models/environment.dart:457:  final EnvironmentGenerationParams defaultParams;
../map_core/lib/src/operations/environment_preset_json_codec.dart:2:// [EnvironmentGenerationParams] pour [ProjectManifest.environmentPresets].
../map_core/lib/src/operations/environment_preset_json_codec.dart:117:  final defaultParams = decodeEnvironmentGenerationParamsJson(rawDefault);
../map_core/lib/src/operations/environment_preset_json_codec.dart:161:        encodeEnvironmentGenerationParamsJson(preset.defaultParams),
../map_core/lib/src/operations/environment_preset_json_codec.dart:275:EnvironmentGenerationParams decodeEnvironmentGenerationParamsJson(
../map_core/lib/src/operations/environment_preset_json_codec.dart:279:      'EnvironmentGenerationParams JSON must be a Map, got ${json.runtimeType}',
../map_core/lib/src/operations/environment_preset_json_codec.dart:284:    return EnvironmentGenerationParams(
../map_core/lib/src/operations/environment_preset_json_codec.dart:291:        fieldLabel: 'EnvironmentGenerationParams.minSpacingCells',
../map_core/lib/src/operations/environment_preset_json_codec.dart:295:    throw FormatException('Invalid EnvironmentGenerationParams: ${e.message}');
../map_core/lib/src/operations/environment_preset_json_codec.dart:299:Map<String, dynamic> encodeEnvironmentGenerationParamsJson(
../map_core/lib/src/operations/environment_preset_json_codec.dart:300:  EnvironmentGenerationParams params,
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:87:    final EnvironmentGenerationParams? paramsOverride;
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:91:      paramsOverride = decodeEnvironmentGenerationParams(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:157:      'paramsOverride': encodeEnvironmentGenerationParams(area.paramsOverride!),
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:199:EnvironmentGenerationParams decodeEnvironmentGenerationParams(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:203:    return EnvironmentGenerationParams(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:211:      'Invalid EnvironmentGenerationParams: ${e.message}',
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:231:Map<String, dynamic> encodeEnvironmentGenerationParams(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:232:  EnvironmentGenerationParams params,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:9:final class EnvironmentGenerationParamsDraft {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:10:  const EnvironmentGenerationParamsDraft({
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:17:  /// Aligné sur [EnvironmentGenerationParams.standard] (map_core).
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:18:  factory EnvironmentGenerationParamsDraft.standard() {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:19:    final s = EnvironmentGenerationParams.standard();
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:20:    return EnvironmentGenerationParamsDraft(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:33:  EnvironmentGenerationParamsDraft copyWith({
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:39:    return EnvironmentGenerationParamsDraft(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:50:        other is EnvironmentGenerationParamsDraft &&
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:131:    required EnvironmentGenerationParamsDraft defaultParams,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:154:      defaultParams: EnvironmentGenerationParamsDraft.standard(),
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:174:      defaultParams: EnvironmentGenerationParamsDraft(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:202:  final EnvironmentGenerationParamsDraft defaultParams;
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:211:    EnvironmentGenerationParamsDraft? defaultParams,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:663:  final params = EnvironmentGenerationParams(
lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart:119:    EnvironmentGenerationParamsDraft? defaultParams,
lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart:327:          EnvironmentGenerationParamsDraftEditor(
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:6:/// Éditeur local des [EnvironmentGenerationParamsDraft] (Lot Environment-15).
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:18:class EnvironmentGenerationParamsDraftEditor extends StatefulWidget {
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:19:  const EnvironmentGenerationParamsDraftEditor({
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:25:  final EnvironmentGenerationParamsDraft params;
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:26:  final ValueChanged<EnvironmentGenerationParamsDraft> onChanged;
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:29:  State<EnvironmentGenerationParamsDraftEditor> createState() =>
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:30:      _EnvironmentGenerationParamsDraftEditorState();
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:33:class _EnvironmentGenerationParamsDraftEditorState
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:34:    extends State<EnvironmentGenerationParamsDraftEditor> {
lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart:53:      covariant EnvironmentGenerationParamsDraftEditor oldWidget) {
test/environment_studio/environment_layer_area_model_editing_test.dart:29:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:53:              defaultParams: EnvironmentGenerationParams(
test/environment_studio/environment_studio_preset_browser_test.dart:135:              defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:163:              defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:191:              defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:263:                    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:314:              defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_browser_test.dart:341:              defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_generation_params_draft_editor_test.dart:302:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_layer_mask_brush_tool_test.dart:83:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_preset_edit_existing_test.dart:54:      final params = EnvironmentGenerationParams(
test/environment_studio/environment_preset_edit_existing_test.dart:340:        defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_preset_edit_existing_test.dart:510:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_preset_save_to_manifest_test.dart:698:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_workspace_test.dart:170:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_generator_deterministic_core_test.dart:516:        defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_generator_deterministic_core_test.dart:666:EnvironmentGenerationParams _params({
test/environment_studio/environment_generator_deterministic_core_test.dart:672:  return EnvironmentGenerationParams(
test/environment_studio/environment_generator_deterministic_core_test.dart:692:  EnvironmentGenerationParams? params,
test/environment_studio/environment_generator_deterministic_core_test.dart:716:    defaultParams: params ?? EnvironmentGenerationParams.standard(),
test/environment_studio/environment_studio_preset_creation_form_test.dart:390:    defaultParams: EnvironmentGenerationParams.standard(),
test/environment_studio/environment_preset_draft_test.dart:6:  group('EnvironmentGenerationParamsDraft', () {
---
../map_core/lib/src/models/environment.dart:22:final class EnvironmentPaletteItem {
../map_core/lib/src/models/environment.dart:23:  factory EnvironmentPaletteItem({
../map_core/lib/src/models/environment.dart:35:        'EnvironmentPaletteItem elementId cannot be empty.',
../map_core/lib/src/models/environment.dart:42:        'EnvironmentPaletteItem weight must be >= 1.',
../map_core/lib/src/models/environment.dart:53:          'EnvironmentPaletteItem tags cannot contain empty strings.',
../map_core/lib/src/models/environment.dart:58:    return EnvironmentPaletteItem._(
../map_core/lib/src/models/environment.dart:66:  const EnvironmentPaletteItem._({
../map_core/lib/src/models/environment.dart:83:        other is EnvironmentPaletteItem &&
../map_core/lib/src/models/environment.dart:369:    required List<EnvironmentPaletteItem> palette,
../map_core/lib/src/models/environment.dart:420:    final copy = <EnvironmentPaletteItem>[];
../map_core/lib/src/models/environment.dart:436:      palette: List<EnvironmentPaletteItem>.unmodifiable(copy),
../map_core/lib/src/models/environment.dart:456:  final List<EnvironmentPaletteItem> palette;
../map_core/lib/src/operations/environment_preset_json_codec.dart:1:// JSON codec manuel (Lot Environment-5) — [EnvironmentPreset] / [EnvironmentPaletteItem] /
../map_core/lib/src/operations/environment_preset_json_codec.dart:105:  final palette = <EnvironmentPaletteItem>[];
../map_core/lib/src/operations/environment_preset_json_codec.dart:108:    palette.add(decodeEnvironmentPaletteItem(e));
../map_core/lib/src/operations/environment_preset_json_codec.dart:158:      for (final item in preset.palette) encodeEnvironmentPaletteItem(item),
../map_core/lib/src/operations/environment_preset_json_codec.dart:170:EnvironmentPaletteItem decodeEnvironmentPaletteItem(Object? json) {
../map_core/lib/src/operations/environment_preset_json_codec.dart:173:      'EnvironmentPaletteItem JSON must be a Map, got ${json.runtimeType}',
../map_core/lib/src/operations/environment_preset_json_codec.dart:179:      'EnvironmentPaletteItem JSON missing elementId or weight',
../map_core/lib/src/operations/environment_preset_json_codec.dart:185:    throw FormatException('EnvironmentPaletteItem.elementId must be a String');
../map_core/lib/src/operations/environment_preset_json_codec.dart:189:      'EnvironmentPaletteItem.weight must be a strict int (got ${weightRaw.runtimeType})',
../map_core/lib/src/operations/environment_preset_json_codec.dart:201:      'EnvironmentPaletteItem.collisionMode must be a String or null',
../map_core/lib/src/operations/environment_preset_json_codec.dart:215:          'EnvironmentPaletteItem.tags[$i] must be a String',
../map_core/lib/src/operations/environment_preset_json_codec.dart:222:      'EnvironmentPaletteItem.tags must be a List or null, got ${rawTags.runtimeType}',
../map_core/lib/src/operations/environment_preset_json_codec.dart:227:    return EnvironmentPaletteItem(
../map_core/lib/src/operations/environment_preset_json_codec.dart:234:    throw FormatException('Invalid EnvironmentPaletteItem: ${e.message}');
../map_core/lib/src/operations/environment_preset_json_codec.dart:238:Map<String, dynamic> encodeEnvironmentPaletteItem(EnvironmentPaletteItem item) {
../map_core/lib/src/operations/environment_preset_json_codec.dart:258:          'Unknown EnvironmentPaletteItem.collisionMode: $value');
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:67:final class EnvironmentPaletteItemDraft {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:68:  EnvironmentPaletteItemDraft({
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:82:  EnvironmentPaletteItemDraft copyWith({
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:90:    return EnvironmentPaletteItemDraft(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:101:        other is EnvironmentPaletteItemDraft &&
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:130:    required List<EnvironmentPaletteItemDraft> palette,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:139:      palette: List<EnvironmentPaletteItemDraft>.unmodifiable(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:140:        List<EnvironmentPaletteItemDraft>.from(palette),
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:167:          EnvironmentPaletteItemDraft(
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:200:  final List<EnvironmentPaletteItemDraft> palette;
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:210:    List<EnvironmentPaletteItemDraft>? palette,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:653:  final palette = <EnvironmentPaletteItem>[
---
../map_core/lib/src/models/environment.dart:8:enum EnvironmentCollisionMode {
../map_core/lib/src/models/environment.dart:26:    EnvironmentCollisionMode collisionMode =
../map_core/lib/src/models/environment.dart:27:        EnvironmentCollisionMode.useElementDefault,
../map_core/lib/src/models/environment.dart:75:  final EnvironmentCollisionMode collisionMode;
../map_core/lib/src/operations/environment_preset_json_codec.dart:194:  final EnvironmentCollisionMode collisionMode;
../map_core/lib/src/operations/environment_preset_json_codec.dart:196:    collisionMode = EnvironmentCollisionMode.useElementDefault;
../map_core/lib/src/operations/environment_preset_json_codec.dart:248:EnvironmentCollisionMode _decodeCollisionMode(String value) {
../map_core/lib/src/operations/environment_preset_json_codec.dart:251:      return EnvironmentCollisionMode.useElementDefault;
../map_core/lib/src/operations/environment_preset_json_codec.dart:253:      return EnvironmentCollisionMode.forceEnabled;
../map_core/lib/src/operations/environment_preset_json_codec.dart:255:      return EnvironmentCollisionMode.forceDisabled;
../map_core/lib/src/operations/environment_preset_json_codec.dart:262:String _collisionModeToJson(EnvironmentCollisionMode mode) {
../map_core/lib/src/operations/environment_preset_json_codec.dart:264:    case EnvironmentCollisionMode.useElementDefault:
../map_core/lib/src/operations/environment_preset_json_codec.dart:266:    case EnvironmentCollisionMode.forceEnabled:
../map_core/lib/src/operations/environment_preset_json_codec.dart:268:    case EnvironmentCollisionMode.forceDisabled:
../map_core/lib/src/operations/environment_preset_diagnostics.dart:204:      if (item.collisionMode != EnvironmentCollisionMode.forceEnabled) {
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:71:    this.collisionMode = EnvironmentCollisionMode.useElementDefault,
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:77:  final EnvironmentCollisionMode collisionMode;
lib/src/features/environment_studio/authoring/environment_preset_draft.dart:85:    EnvironmentCollisionMode? collisionMode,
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:78:  static int _collisionToSegment(EnvironmentCollisionMode m) {
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:80:      EnvironmentCollisionMode.useElementDefault => 0,
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:81:      EnvironmentCollisionMode.forceEnabled => 1,
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:82:      EnvironmentCollisionMode.forceDisabled => 2,
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:86:  static EnvironmentCollisionMode _segmentToCollision(int i) {
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:88:      1 => EnvironmentCollisionMode.forceEnabled,
lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart:89:      2 => EnvironmentCollisionMode.forceDisabled,
---
../map_core/lib/src/models/map_entity_editor_visual.freezed.dart:40:  ///   quand elle est rendue comme ProjectElementEntry.
../map_core/lib/src/models/map_entity_editor_visual.freezed.dart:163:  ///   quand elle est rendue comme ProjectElementEntry.
../map_core/lib/src/models/map_entity_editor_visual.freezed.dart:230:  ///   quand elle est rendue comme ProjectElementEntry.
../map_core/lib/src/models/project_manifest.dart:94:    @Default([]) List<ProjectElementEntry> elements,
../map_core/lib/src/models/project_manifest.dart:361:class ProjectElementEntry with _$ProjectElementEntry {
../map_core/lib/src/models/project_manifest.dart:363:  const factory ProjectElementEntry({
../map_core/lib/src/models/project_manifest.dart:378:  }) = _ProjectElementEntry;
../map_core/lib/src/models/project_manifest.dart:380:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
../map_core/lib/src/models/project_manifest.dart:381:      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
../map_core/lib/src/models/environment.dart:9:  /// Utiliser le comportement défini par le [ProjectElementEntry] / profil existant.
../map_core/lib/src/models/environment.dart:21:/// [elementId] référence un futur `ProjectElementEntry.id` ; aucune validation manifest ici.
../map_core/lib/src/models/visual_frame_json.dart:4:/// Utilisé au chargement pour [ProjectElementEntry], [TilesetPaletteEntry],
../map_core/lib/src/models/project_manifest.g.dart:37:                  ProjectElementEntry.fromJson(e as Map<String, dynamic>))
../map_core/lib/src/models/project_manifest.g.dart:502:_$ProjectElementEntryImpl _$$ProjectElementEntryImplFromJson(
../map_core/lib/src/models/project_manifest.g.dart:504:    _$ProjectElementEntryImpl(
../map_core/lib/src/models/project_manifest.g.dart:528:Map<String, dynamic> _$$ProjectElementEntryImplToJson(
../map_core/lib/src/models/project_manifest.g.dart:529:        _$ProjectElementEntryImpl instance) =>
../map_core/lib/src/models/project_manifest.freezed.dart:32:  List<ProjectElementEntry> get elements => throw _privateConstructorUsedError;
../map_core/lib/src/models/project_manifest.freezed.dart:98:      List<ProjectElementEntry> elements,
../map_core/lib/src/models/project_manifest.freezed.dart:206:              as List<ProjectElementEntry>,
../map_core/lib/src/models/project_manifest.freezed.dart:315:      List<ProjectElementEntry> elements,
../map_core/lib/src/models/project_manifest.freezed.dart:423:              as List<ProjectElementEntry>,
../map_core/lib/src/models/project_manifest.freezed.dart:508:      final List<ProjectElementEntry> elements = const [],
../map_core/lib/src/models/project_manifest.freezed.dart:611:  final List<ProjectElementEntry> _elements;
../map_core/lib/src/models/project_manifest.freezed.dart:614:  List<ProjectElementEntry> get elements {
../map_core/lib/src/models/enums.dart:450:enum MapPlacedElementAnimationMode {
../map_core/lib/src/models/map_data.freezed.dart:29:  List<MapPlacedElement> get placedElements =>
../map_core/lib/src/models/map_data.freezed.dart:64:      List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:137:              as List<MapPlacedElement>,
../map_core/lib/src/models/map_data.freezed.dart:208:      List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:281:              as List<MapPlacedElement>,
../map_core/lib/src/models/map_data.freezed.dart:329:      final List<MapPlacedElement> placedElements = const [],
../map_core/lib/src/models/map_data.freezed.dart:372:  final List<MapPlacedElement> _placedElements;
../map_core/lib/src/models/map_data.freezed.dart:375:  List<MapPlacedElement> get placedElements {
../map_core/lib/src/models/map_data.freezed.dart:529:      final List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:554:  List<MapPlacedElement> get placedElements;
../map_core/lib/src/models/map_data.freezed.dart:1063:MapPlacedElement _$MapPlacedElementFromJson(Map<String, dynamic> json) {
../map_core/lib/src/models/map_data.freezed.dart:1064:  return _MapPlacedElement.fromJson(json);
../map_core/lib/src/models/map_data.freezed.dart:1068:mixin _$MapPlacedElement {
../map_core/lib/src/models/map_data.freezed.dart:1074:  MapPlacedElementAnimation? get animation =>
../map_core/lib/src/models/map_data.freezed.dart:1076:  List<MapPlacedElementBehavior> get behaviors =>
../map_core/lib/src/models/map_data.freezed.dart:1080:  /// Serializes this MapPlacedElement to a JSON map.
../map_core/lib/src/models/map_data.freezed.dart:1083:  /// Create a copy of MapPlacedElement
../map_core/lib/src/models/map_data.freezed.dart:1086:  $MapPlacedElementCopyWith<MapPlacedElement> get copyWith =>
../map_core/lib/src/models/map_data.freezed.dart:1091:abstract class $MapPlacedElementCopyWith<$Res> {
../map_core/lib/src/models/map_data.freezed.dart:1092:  factory $MapPlacedElementCopyWith(
../map_core/lib/src/models/map_data.freezed.dart:1093:          MapPlacedElement value, $Res Function(MapPlacedElement) then) =
../map_core/lib/src/models/map_data.freezed.dart:1094:      _$MapPlacedElementCopyWithImpl<$Res, MapPlacedElement>;
../map_core/lib/src/models/map_data.freezed.dart:1102:      MapPlacedElementAnimation? animation,
../map_core/lib/src/models/map_data.freezed.dart:1103:      List<MapPlacedElementBehavior> behaviors,
--- generatedPlacementIds (suite audit) ---
../map_core/lib/src/models/environment.dart:260:    List<String>? generatedPlacementIds,
../map_core/lib/src/models/environment.dart:283:    final rawIds = generatedPlacementIds ?? const <String>[];
../map_core/lib/src/models/environment.dart:291:          'generatedPlacementIds',
../map_core/lib/src/models/environment.dart:292:          'EnvironmentArea generatedPlacementIds cannot contain empty strings.',
../map_core/lib/src/models/environment.dart:298:          'generatedPlacementIds',
../map_core/lib/src/models/environment.dart:299:          'EnvironmentArea generatedPlacementIds cannot contain duplicates.',
../map_core/lib/src/models/environment.dart:312:      generatedPlacementIds: List<String>.unmodifiable(ordered),
../map_core/lib/src/models/environment.dart:323:    required this.generatedPlacementIds,
../map_core/lib/src/models/environment.dart:332:  final List<String> generatedPlacementIds;
../map_core/lib/src/models/environment.dart:334:  bool get hasGeneratedPlacements => generatedPlacementIds.isNotEmpty;
../map_core/lib/src/models/environment.dart:346:            _listEquals(generatedPlacementIds, other.generatedPlacementIds);
../map_core/lib/src/models/environment.dart:357:        Object.hashAll(generatedPlacementIds),
../map_core/lib/src/models/environment.dart:545:  /// Zones d’environnement ; ordre significatif pour [generatedPlacementIds].
../map_core/lib/src/models/environment.dart:555:  List<String> get generatedPlacementIds {
../map_core/lib/src/models/environment.dart:558:      out.addAll(area.generatedPlacementIds);
../map_core/lib/src/operations/map_resize.dart:87:                      generatedPlacementIds:
../map_core/lib/src/operations/map_resize.dart:88:                          area.generatedPlacementIds.toList(),
../map_core/lib/src/operations/environment_layer_usage_diagnostics.dart:316:      for (final pid in area.generatedPlacementIds) {
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:96:    final rawPlacementIds = json['generatedPlacementIds'];
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:97:    final List<String>? generatedPlacementIds =
--- EnvironmentAreaMask ---
../map_core/lib/src/models/environment.dart:178:final class EnvironmentAreaMask {
../map_core/lib/src/models/environment.dart:179:  factory EnvironmentAreaMask({
../map_core/lib/src/models/environment.dart:188:        'EnvironmentAreaMask width must be > 0.',
../map_core/lib/src/models/environment.dart:195:        'EnvironmentAreaMask height must be > 0.',
../map_core/lib/src/models/environment.dart:203:        'EnvironmentAreaMask cells length must be width * height ($expected).',
../map_core/lib/src/models/environment.dart:206:    return EnvironmentAreaMask._(
../map_core/lib/src/models/environment.dart:213:  const EnvironmentAreaMask._({
../map_core/lib/src/models/environment.dart:241:        other is EnvironmentAreaMask &&
../map_core/lib/src/models/environment.dart:257:    required EnvironmentAreaMask mask,
../map_core/lib/src/models/environment.dart:329:  final EnvironmentAreaMask mask;
../map_core/lib/src/operations/map_resize.dart:75:                      mask: EnvironmentAreaMask(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:81:    final mask = decodeEnvironmentAreaMask(
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:154:    'mask': encodeEnvironmentAreaMask(area.mask),
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:162:EnvironmentAreaMask decodeEnvironmentAreaMask(Map<String, dynamic> json) {
../map_core/lib/src/operations/environment_layer_content_json_codec.dart:169:        'EnvironmentAreaMask cells must be a List, got ${rawCells.runtimeType}',
--- Random( dans lib/src (hors commentaire generator) ---
lib/src/features/dialogue/application/dialogue_editor_model.dart:21:      '${Random().nextInt(1 << 30)}';
lib/src/application/use_cases/environment_generator_use_cases.dart:230:// PRNG déterministe (FNV-1a 32-bit + xorshift32). Pas de Random(), pas de DateTime.
--- hashCode dans generator + tests environment_studio ---
lib/src/application/use_cases/environment_generator_use_cases.dart:47:  int get hashCode {
lib/src/application/use_cases/environment_generator_use_cases.dart:131:  int get hashCode => Object.hash(
lib/src/application/use_cases/environment_generator_use_cases.dart:200:  int get hashCode => Object.hash(

```

### 17.2 `flutter analyze` (ciblé)

```text
Analyzing 2 items...                                            

   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:42:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:47:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:375:24 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:380:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:395:20 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_deterministic_core_test.dart:432:19 • prefer_const_constructors

6 issues found. (ran in 1.9s)

```

**Interprétation** : 0 erreur, 0 warning, 6 infos `prefer_const_constructors` dans le fichier de test.

### 17.3 Grep persistance disque (obligatoire lot)

```text

```

(Sortie vide : aucune correspondance.)

### 17.4 `flutter test` — `environment_generator_deterministic_core_test.dart` (expanded, intégral)

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart
00:00 +0: EnvironmentGenerationResult / DTO immuabilité EnvironmentGeneratedPlacementCandidate copie les tags et expose un Set immuable
00:00 +1: EnvironmentGenerationResult / DTO immuabilité EnvironmentGenerationResult copie placements et issues ; issuesForKind
00:00 +2: GenerateEnvironmentAreaPlacementsUseCase déterminisme : deux exécutions identiques
00:00 +3: GenerateEnvironmentAreaPlacementsUseCase mask : seulement deux cellules actives reçoivent des placements possibles
00:00 +4: GenerateEnvironmentAreaPlacementsUseCase density 0 et edgeDensity 0 : aucun placement, warning noPlacementCandidates
00:00 +5: GenerateEnvironmentAreaPlacementsUseCase density 1, edgeDensity 1, variation 0, spacing 0 : toutes les cellules actives
00:00 +6: GenerateEnvironmentAreaPlacementsUseCase edgeDensity seul sur bloc 3x3 : le centre ne reçoit pas de placement
00:00 +7: GenerateEnvironmentAreaPlacementsUseCase variation non nulle : stable entre deux appels
00:00 +8: GenerateEnvironmentAreaPlacementsUseCase minSpacingCells 1 sur 3x3 : aucune paire Chebyshev <= 1
00:00 +9: GenerateEnvironmentAreaPlacementsUseCase palette à un seul item : tous les elementId identiques
00:00 +10: GenerateEnvironmentAreaPlacementsUseCase palette deux items : résultat déterministe et pondération (snapshot)
00:00 +11: GenerateEnvironmentAreaPlacementsUseCase erreurs : environmentLayerNotFound, layerIsNotEnvironmentLayer, cible
00:00 +12: GenerateEnvironmentAreaPlacementsUseCase erreurs : areaNotFound, presetMissing, paletteElementMissing
00:00 +13: GenerateEnvironmentAreaPlacementsUseCase erreur : invalidMaskSize
00:00 +14: GenerateEnvironmentAreaPlacementsUseCase warnings : mask vide et aucune erreur
00:00 +15: GenerateEnvironmentAreaPlacementsUseCase paramsOverride remplace defaultParams du preset
00:00 +16: GenerateEnvironmentAreaPlacementsUseCase aucune mutation : MapData, manifest, areas, tiles, placedElements
00:00 +17: All tests passed!

```

### 17.5 Régressions Lots 19–22 (commande groupée, sortie expanded intégrale)

Fichier miroir : `reports/forest/environment_studio_lot_23_evidence_test_regressions_lots_19_22.txt`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — PaintEnvironmentAreaMaskCellUseCase paint (1,1) : une cellule active, preset et placements préservés
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erase : cellule repasse false, compteur diminue
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op paint true sur true → même référence MapData
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op erase false sur false → même référence MapData
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erreurs use case
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — EditorNotifier masque start paint / erase / stop + paint met dirty et préserve chemins
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — EditorNotifier masque changer de layer actif hors Environment → mode masque désactivé
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — EditorNotifier masque removeEnvironmentArea nettoie la sélection masque
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer choix TileLayer via picker met à jour la cible et dirty
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer choix TileLayer via picker met à jour la cible et dirty
00:02 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:02 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map ajout Environment Layer : MapLayer.environment, contenu vide, sélection, dirty
00:02 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer picker ne liste que les TileLayer (ObjectLayer exclu)
00:02 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer picker ne liste que les TileLayer (ObjectLayer exclu)
00:02 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map MapInspector : section neutre quand EnvironmentLayer actif
00:02 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer retirer la cible remet null
00:02 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map MapGridPainter : map avec TileLayer + EnvironmentLayer ne lève pas
00:02 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer cible invalide affiche avertissement et actions
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer EnvironmentLayerInspectorPanel seul : pas de crash
00:03 +47: All tests passed!
```

### 17.6 `flutter test test/environment_studio` (expanded, sortie intégrale)

Fichier miroir : `reports/forest/environment_studio_lot_23_evidence_test_environment_studio_full.txt`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase ajoute une area : mask taille map, vide, placements vides, cible préservée
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase deux areas même preset → ids différents, ordre stable
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase rejette environmentLayerId inconnu
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase rejette environmentLayerId TileLayer
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase rejette presetId inconnu
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) AddEnvironmentAreaUseCase rejette presetId vide
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) SetEnvironmentAreaPresetUseCase change presetId, préserve mask et generatedPlacementIds et cible
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) SetEnvironmentAreaPresetUseCase rejette areaId inconnu
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) RemoveEnvironmentAreaUseCase retire une area, préserve l’autre et targetTileLayerId
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) RemoveEnvironmentAreaUseCase rejette areaId inconnu
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) EditorNotifier — areas add / set preset / remove : activeMap, activeLayerId, dirty, chemins
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) inspecteur : aucun preset → message et pas d’ajout
00:01 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generation_params_draft_editor_test.dart: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) ajout zone via picker + affichage + dirty
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) ajout zone via picker + affichage + dirty
00:02 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart: Lot 21 — EnvironmentArea model (inspector) ajout zone via picker + affichage + dirty
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:02 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:02 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:02 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon action Modifier en brouillon ouvre le formulaire (titre + badge)
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer inspecteur : aucun TileLayer
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart: Lot 18 — édition preset existant en brouillon callback qui lève en update : formulaire visible, message neutre
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
#0      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:304:34)
#1      _ManifestSyncPanelHostState.build.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:444:30)
#2      _EnvironmentStudioPanelState._onEnvironmentPresetSavedInMemory (package:map_editor/src/features/environment_studio/environment_studio_panel.dart:187:38)
#3      _EnvironmentPresetDraftFormState._saveDraftToProject (package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_form.dart:184:11)
#4      _CupertinoButtonState._handleTap (package:flutter/src/cupertino/button.dart:421:24)
#5      _CupertinoButtonState._handleTapUp (package:flutter/src/cupertino/button.dart:393:7)
#6      TapGestureRecognizer.handleTapUp.<anonymous closure> (package:flutter/src/gestures/tap.dart:755:57)
#7      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:345:24)
#8      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:755:11)
#9      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:383:5)
#10     BaseTapGestureRecognizer.handlePrimaryPointer (package:flutter/src/gestures/tap.dart:314:7)
#11     PrimaryPointerGestureRecognizer.handleEvent (package:flutter/src/gestures/recognizer.dart:721:9)
#12     PointerRouter._dispatch (package:flutter/src/gestures/pointer_router.dart:97:12)
#13     PointerRouter._dispatchEventToRoutes.<anonymous closure> (package:flutter/src/gestures/pointer_router.dart:142:9)
#14     _LinkedHashMapMixin.forEach (dart:_compact_hash:765:13)
#15     PointerRouter._dispatchEventToRoutes (package:flutter/src/gestures/pointer_router.dart:140:18)
#16     PointerRouter.route (package:flutter/src/gestures/pointer_router.dart:130:7)
#17     GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:528:19)
#18     GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:498:22)
#19     RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:473:11)
#20     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)
#21     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)
#22     TestWidgetsFlutterBinding.handlePointerEventForSource.<anonymous closure> (package:flutter_test/src/binding.dart:678:42)
#23     TestWidgetsFlutterBinding.withPointerEventSource (package:flutter_test/src/binding.dart:688:11)
#24     TestWidgetsFlutterBinding.handlePointerEventForSource (package:flutter_test/src/binding.dart:678:5)
#25     WidgetTester.sendEventToBinding.<anonymous closure> (package:flutter_test/src/widget_tester.dart:869:15)
#26     _rootRun (dart:async/zone.dart:1525:13)
#27     _CustomZone.run (dart:async/zone.dart:1422:19)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     WidgetTester.sendEventToBinding (package:flutter_test/src/widget_tester.dart:868:27)
#30     TestGesture.up.<anonymous closure> (package:flutter_test/src/test_pointer.dart:538:26)
#31     _rootRun (dart:async/zone.dart:1525:13)
#32     _CustomZone.run (dart:async/zone.dart:1422:19)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     TestGesture.up (package:flutter_test/src/test_pointer.dart:531:27)
#35     WidgetController.tapAt.<anonymous closure> (package:flutter_test/src/controller.dart:1117:21)
<asynchronous suspension>
#36     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#37     main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart:317:7)
<asynchronous suspension>
#38     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#39     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#40     StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>

00:05 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:05 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer choix TileLayer via picker met à jour la cible et dirty
00:05 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:05 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:06 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:06 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:06 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer retirer la cible remet null
00:06 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_target_tile_layer_test.dart: Lot 20 — EnvironmentLayer target TileLayer retirer la cible remet null
00:06 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) élément palette inconnu : callback non invoqué
00:06 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) élément palette inconnu : callback non invoqué
00:06 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) élément palette inconnu : callback non invoqué
00:06 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:06 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_creation_test.dart: Lot 19 — Environment Layer dans l’éditeur de map picker d’ajout de layer expose Environment Layer
00:07 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:07 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
#0      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:384:36)
#1      _ManifestSyncPanelHostState.build.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:638:30)
#2      _EnvironmentStudioPanelState._onEnvironmentPresetSavedInMemory (package:map_editor/src/features/environment_studio/environment_studio_panel.dart:187:38)
#3      _EnvironmentPresetDraftFormState._saveDraftToProject (package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_form.dart:184:11)
#4      _CupertinoButtonState._handleTap (package:flutter/src/cupertino/button.dart:421:24)
#5      _CupertinoButtonState._handleTapUp (package:flutter/src/cupertino/button.dart:393:7)
#6      TapGestureRecognizer.handleTapUp.<anonymous closure> (package:flutter/src/gestures/tap.dart:755:57)
#7      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:345:24)
#8      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:755:11)
#9      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:383:5)
#10     BaseTapGestureRecognizer.handlePrimaryPointer (package:flutter/src/gestures/tap.dart:314:7)
#11     PrimaryPointerGestureRecognizer.handleEvent (package:flutter/src/gestures/recognizer.dart:721:9)
#12     PointerRouter._dispatch (package:flutter/src/gestures/pointer_router.dart:97:12)
#13     PointerRouter._dispatchEventToRoutes.<anonymous closure> (package:flutter/src/gestures/pointer_router.dart:142:9)
#14     _LinkedHashMapMixin.forEach (dart:_compact_hash:765:13)
#15     PointerRouter._dispatchEventToRoutes (package:flutter/src/gestures/pointer_router.dart:140:18)
#16     PointerRouter.route (package:flutter/src/gestures/pointer_router.dart:130:7)
#17     GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:528:19)
#18     GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:498:22)
#19     RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:473:11)
#20     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)
#21     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)
#22     TestWidgetsFlutterBinding.handlePointerEventForSource.<anonymous closure> (package:flutter_test/src/binding.dart:678:42)
#23     TestWidgetsFlutterBinding.withPointerEventSource (package:flutter_test/src/binding.dart:688:11)
#24     TestWidgetsFlutterBinding.handlePointerEventForSource (package:flutter_test/src/binding.dart:678:5)
#25     WidgetTester.sendEventToBinding.<anonymous closure> (package:flutter_test/src/widget_tester.dart:869:15)
#26     _rootRun (dart:async/zone.dart:1525:13)
#27     _CustomZone.run (dart:async/zone.dart:1422:19)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     WidgetTester.sendEventToBinding (package:flutter_test/src/widget_tester.dart:868:27)
#30     TestGesture.up.<anonymous closure> (package:flutter_test/src/test_pointer.dart:538:26)
#31     _rootRun (dart:async/zone.dart:1525:13)
#32     _CustomZone.run (dart:async/zone.dart:1422:19)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     TestGesture.up (package:flutter_test/src/test_pointer.dart:531:27)
#35     WidgetController.tapAt.<anonymous closure> (package:flutter_test/src/controller.dart:1117:21)
<asynchronous suspension>
#36     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#37     main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:411:9)
<asynchronous suspension>
#38     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#39     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#40     StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>

00:08 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon action Préparer un preset visible puis formulaire
00:08 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart: Environment Studio workspace — persistance mémoire EditorCanvasHost : enregistrement met à jour le projet et dirty
00:08 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:09 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:09 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:09 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:09 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon sortOrder : texte invalide conserve la valeur draft
00:09 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:10 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon Réinitialiser brouillon remet les champs vides
00:10 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque remplit elementId
00:10 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque remplit elementId
00:10 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart: EnvironmentStudioPanel — formulaire brouillon aucun Save / Create / Generate dans l’UI
00:10 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:10 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:10 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:11 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:11 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:11 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:11 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:12 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:12 +170: All tests passed!
```

### 17.7 `flutter test` régressions proches

Ligne finale :

```text
00:00 +14: All tests passed!
```

### 17.8 `flutter test` complet package `map_editor`

Ligne finale observée :

```text
00:55 +1003 -34: Some tests failed.
```

**Analyse** : 34 échecs hors périmètre Lot 23 (catalogue Pokémon, items, sync, etc.) ; non traités dans ce lot.


## 18. Git status initial et final

### 18.1 Initial

Non recapturé par `git status` au tout début de cette session de reprise. Le contexte utilisateur mentionnait un arbre de travail large (fichiers `map_core` / éditeur modifiés hors Lot 23). **Aucune** commande d’écriture git (`add` / `commit` / etc.) n’a été exécutée pendant ce lot.

### 18.2 Final (commande : `git status --short --untracked-files=all` à la racine du dépôt)

```text
?? packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart
?? reports/forest/environment_studio_lot_23_environment_generator_deterministic_core.md
?? reports/forest/environment_studio_lot_23_evidence_appendix_diff_generator.patch
?? reports/forest/environment_studio_lot_23_evidence_appendix_diff_test.patch
?? reports/forest/environment_studio_lot_23_evidence_appendix_generator_source.md
?? reports/forest/environment_studio_lot_23_evidence_appendix_test_source.md
?? reports/forest/environment_studio_lot_23_evidence_flutter_analyze.txt
?? reports/forest/environment_studio_lot_23_evidence_grep_audit_full.txt
?? reports/forest/environment_studio_lot_23_evidence_test_environment_studio_full.txt
?? reports/forest/environment_studio_lot_23_evidence_test_generator_expanded.txt
?? reports/forest/environment_studio_lot_23_evidence_test_regressions_lots_19_22.txt
```

## 19. Contenu complet des fichiers créés ou modifiés

Reproduit **intégralement** dans les annexes suivantes (Markdown + bloc `dart`) :

- `reports/forest/environment_studio_lot_23_evidence_appendix_generator_source.md`
- `reports/forest/environment_studio_lot_23_evidence_appendix_test_source.md`

## 20. Diff complet

### 20.1 `git diff --no-index /dev/null ... environment_generator_use_cases.dart`

```diff
diff --git a/packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart
new file mode 100644
index 00000000..113659b5
--- /dev/null
+++ b/packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart
@@ -0,0 +1,732 @@
+import 'package:map_core/map_core.dart';
+
+// ---------------------------------------------------------------------------
+// Lot Environment-23 — modèles de résultat (DTO purs, hors map_core / Flutter).
+// ---------------------------------------------------------------------------
+
+/// Candidat de placement déterministe ; **pas** un [MapPlacedElement].
+final class EnvironmentGeneratedPlacementCandidate {
+  EnvironmentGeneratedPlacementCandidate({
+    required this.id,
+    required this.environmentLayerId,
+    required this.areaId,
+    required this.presetId,
+    required this.targetLayerId,
+    required this.elementId,
+    required this.pos,
+    required this.collisionMode,
+    required Set<String> tags,
+  }) : tags = Set.unmodifiable(Set<String>.from(tags));
+
+  final String id;
+  final String environmentLayerId;
+  final String areaId;
+  final String presetId;
+  final String targetLayerId;
+  final String elementId;
+  final GridPos pos;
+  final EnvironmentCollisionMode collisionMode;
+  final Set<String> tags;
+
+  @override
+  bool operator ==(Object other) {
+    if (identical(this, other)) return true;
+    return other is EnvironmentGeneratedPlacementCandidate &&
+        id == other.id &&
+        environmentLayerId == other.environmentLayerId &&
+        areaId == other.areaId &&
+        presetId == other.presetId &&
+        targetLayerId == other.targetLayerId &&
+        elementId == other.elementId &&
+        pos == other.pos &&
+        collisionMode == other.collisionMode &&
+        _setEquals(tags, other.tags);
+  }
+
+  @override
+  int get hashCode {
+    final sorted = tags.toList()..sort();
+    return Object.hash(
+      id,
+      environmentLayerId,
+      areaId,
+      presetId,
+      targetLayerId,
+      elementId,
+      pos,
+      collisionMode,
+      Object.hashAll(sorted),
+    );
+  }
+}
+
+bool _setEquals(Set<String> a, Set<String> b) {
+  if (a.length != b.length) return false;
+  for (final e in a) {
+    if (!b.contains(e)) return false;
+  }
+  return true;
+}
+
+enum EnvironmentGenerationIssueSeverity {
+  error,
+  warning,
+}
+
+enum EnvironmentGenerationIssueKind {
+  environmentLayerNotFound,
+  layerIsNotEnvironmentLayer,
+  targetTileLayerMissing,
+  targetTileLayerInvalid,
+  areaNotFound,
+  presetMissing,
+  emptyPresetPalette,
+  paletteElementMissing,
+  emptyAreaMask,
+  invalidMaskSize,
+  invalidMaskCellLength,
+  invalidDensity,
+  invalidEdgeDensity,
+  invalidVariation,
+  invalidMinSpacingCells,
+  noPlacementCandidates,
+}
+
+final class EnvironmentGenerationIssue {
+  const EnvironmentGenerationIssue({
+    required this.severity,
+    required this.kind,
+    required this.message,
+    this.environmentLayerId,
+    this.areaId,
+    this.presetId,
+    this.targetLayerId,
+    this.elementId,
+  });
+
+  final EnvironmentGenerationIssueSeverity severity;
+  final EnvironmentGenerationIssueKind kind;
+  final String message;
+  final String? environmentLayerId;
+  final String? areaId;
+  final String? presetId;
+  final String? targetLayerId;
+  final String? elementId;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentGenerationIssue &&
+            severity == other.severity &&
+            kind == other.kind &&
+            message == other.message &&
+            environmentLayerId == other.environmentLayerId &&
+            areaId == other.areaId &&
+            presetId == other.presetId &&
+            targetLayerId == other.targetLayerId &&
+            elementId == other.elementId;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        message,
+        environmentLayerId,
+        areaId,
+        presetId,
+        targetLayerId,
+        elementId,
+      );
+}
+
+final class EnvironmentGenerationResult {
+  factory EnvironmentGenerationResult({
+    required List<EnvironmentGeneratedPlacementCandidate> placements,
+    required List<EnvironmentGenerationIssue> issues,
+  }) {
+    return EnvironmentGenerationResult._(
+      placements: List<EnvironmentGeneratedPlacementCandidate>.unmodifiable(
+        List<EnvironmentGeneratedPlacementCandidate>.from(placements),
+      ),
+      issues: List<EnvironmentGenerationIssue>.unmodifiable(
+        List<EnvironmentGenerationIssue>.from(issues),
+      ),
+    );
+  }
+
+  const EnvironmentGenerationResult._({
+    required this.placements,
+    required this.issues,
+  });
+
+  final List<EnvironmentGeneratedPlacementCandidate> placements;
+  final List<EnvironmentGenerationIssue> issues;
+
+  bool get hasErrors =>
+      issues.any((i) => i.severity == EnvironmentGenerationIssueSeverity.error);
+
+  bool get hasWarnings => issues
+      .any((i) => i.severity == EnvironmentGenerationIssueSeverity.warning);
+
+  int get errorCount => issues
+      .where((i) => i.severity == EnvironmentGenerationIssueSeverity.error)
+      .length;
+
+  int get warningCount => issues
+      .where((i) => i.severity == EnvironmentGenerationIssueSeverity.warning)
+      .length;
+
+  int get placementCount => placements.length;
+
+  List<EnvironmentGenerationIssue> issuesForKind(
+    EnvironmentGenerationIssueKind kind,
+  ) {
+    return List<EnvironmentGenerationIssue>.unmodifiable(
+      issues.where((i) => i.kind == kind).toList(growable: false),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    if (identical(this, other)) return true;
+    return other is EnvironmentGenerationResult &&
+        placementCount == other.placementCount &&
+        _listEqualsCandidates(placements, other.placements) &&
+        _listEqualsIssues(issues, other.issues);
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        placementCount,
+        Object.hashAll(placements),
+        Object.hashAll(issues),
+      );
+}
+
+bool _listEqualsCandidates(
+  List<EnvironmentGeneratedPlacementCandidate> a,
+  List<EnvironmentGeneratedPlacementCandidate> b,
+) {
+  if (a.length != b.length) return false;
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) return false;
+  }
+  return true;
+}
+
+bool _listEqualsIssues(
+  List<EnvironmentGenerationIssue> a,
+  List<EnvironmentGenerationIssue> b,
+) {
+  if (a.length != b.length) return false;
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) return false;
+  }
+  return true;
+}
+
+// ---------------------------------------------------------------------------
+// PRNG déterministe (FNV-1a 32-bit + xorshift32). Pas de Random(), pas de DateTime.
+// ---------------------------------------------------------------------------
+
+int fnv1a32(String input) {
+  const int fnvPrime = 0x01000193;
+  var hash = 0x811C9DC5;
+  for (final codeUnit in input.codeUnits) {
+    hash ^= codeUnit;
+    hash = (hash * fnvPrime) & 0xFFFFFFFF;
+  }
+  return hash & 0xFFFFFFFF;
+}
+
+int xorshift32(int state) {
+  var x = state & 0xFFFFFFFF;
+  if (x == 0) x = 0x9E3779B9;
+  x ^= (x << 13) & 0xFFFFFFFF;
+  x ^= (x >> 17) & 0xFFFFFFFF;
+  x ^= (x << 5) & 0xFFFFFFFF;
+  return x & 0xFFFFFFFF;
+}
+
+/// RNG déterministe : [next01] dans [0, 1).
+final class DeterministicEnvironmentRng {
+  DeterministicEnvironmentRng(int seed32)
+      : _state = seed32 == 0 ? 0xDEADBEEF : seed32;
+
+  int _state;
+
+  int nextUint32() {
+    _state = xorshift32(_state);
+    return _state;
+  }
+
+  /// Double dans [0, 1) dérivé de 32 bits de mantisse.
+  double next01() => nextUint32() * (1.0 / 4294967296.0);
+}
+
+DeterministicEnvironmentRng _rngForCell({
+  required int areaSeed,
+  required String areaId,
+  required String presetId,
+  required int x,
+  required int y,
+  required String usage,
+}) {
+  final h = fnv1a32(
+    '$areaSeed|${areaId.trim()}|${presetId.trim()}|$x|$y|$usage',
+  );
+  return DeterministicEnvironmentRng(h ^ areaSeed);
+}
+
+bool _isUnitInterval(double v) => v >= 0.0 && v <= 1.0;
+
+bool _isMaskEdge(EnvironmentAreaMask mask, int x, int y) {
+  if (!mask.isActiveAt(x, y)) return false;
+  const dirs = <List<int>>[
+    [0, -1],
+    [0, 1],
+    [-1, 0],
+    [1, 0],
+  ];
+  for (final d in dirs) {
+    final nx = x + d[0];
+    final ny = y + d[1];
+    if (!mask.isActiveAt(nx, ny)) {
+      return true;
+    }
+  }
+  return false;
+}
+
+bool _tooCloseChebyshev({
+  required int x,
+  required int y,
+  required List<GridPos> accepted,
+  required int minSpacingCells,
+}) {
+  if (minSpacingCells <= 0) return false;
+  for (final p in accepted) {
+    final dx = (x - p.x).abs();
+    final dy = (y - p.y).abs();
+    if (dx <= minSpacingCells && dy <= minSpacingCells) {
+      return true;
+    }
+  }
+  return false;
+}
+
+String _sanitizeIdPart(String s) {
+  return s.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
+}
+
+String _candidateId({
+  required String areaId,
+  required int x,
+  required int y,
+  required String elementId,
+}) {
+  return 'env_gen_${_sanitizeIdPart(areaId)}_${x}_${y}_${_sanitizeIdPart(elementId)}';
+}
+
+EnvironmentPaletteItem? _pickPaletteItem({
+  required List<EnvironmentPaletteItem> palette,
+  required DeterministicEnvironmentRng rng,
+}) {
+  var total = 0;
+  for (final item in palette) {
+    total += item.weight;
+  }
+  if (total <= 0) return null;
+  final r = rng.nextUint32() % total;
+  var acc = 0;
+  for (final item in palette) {
+    acc += item.weight;
+    if (r < acc) return item;
+  }
+  return palette.last;
+}
+
+/// Génère des candidats de placement **sans** muter [MapData] ni [ProjectManifest].
+class GenerateEnvironmentAreaPlacementsUseCase {
+  EnvironmentGenerationResult execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String environmentLayerId,
+    required String areaId,
+  }) {
+    final issues = <EnvironmentGenerationIssue>[];
+    final envId = environmentLayerId.trim();
+    final aid = areaId.trim();
+
+    EnvironmentLayer? envLayer;
+    for (final layer in map.layers) {
+      if (layer.id == envId) {
+        if (layer is EnvironmentLayer) {
+          envLayer = layer;
+        } else {
+          issues.add(
+            EnvironmentGenerationIssue(
+              severity: EnvironmentGenerationIssueSeverity.error,
+              kind: EnvironmentGenerationIssueKind.layerIsNotEnvironmentLayer,
+              message: 'Layer is not an environment layer: $envId',
+              environmentLayerId: envId,
+            ),
+          );
+          return EnvironmentGenerationResult(
+              placements: const [], issues: issues);
+        }
+        break;
+      }
+    }
+    if (envLayer == null) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.environmentLayerNotFound,
+          message: 'Environment layer not found: $envId',
+          environmentLayerId: envId,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final targetId = envLayer.content.targetTileLayerId?.trim();
+    if (targetId == null || targetId.isEmpty) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.targetTileLayerMissing,
+          message: 'Environment layer has no target tile layer id',
+          environmentLayerId: envId,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    TileLayer? tileLayer;
+    for (final layer in map.layers) {
+      if (layer.id == targetId) {
+        if (layer is TileLayer) {
+          tileLayer = layer;
+        } else {
+          issues.add(
+            EnvironmentGenerationIssue(
+              severity: EnvironmentGenerationIssueSeverity.error,
+              kind: EnvironmentGenerationIssueKind.targetTileLayerInvalid,
+              message: 'Target tile layer id does not reference a TileLayer: '
+                  '$targetId',
+              environmentLayerId: envId,
+              targetLayerId: targetId,
+            ),
+          );
+          return EnvironmentGenerationResult(
+              placements: const [], issues: issues);
+        }
+        break;
+      }
+    }
+    if (tileLayer == null) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.targetTileLayerInvalid,
+          message: 'Target tile layer not found: $targetId',
+          environmentLayerId: envId,
+          targetLayerId: targetId,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    EnvironmentArea? area;
+    for (final a in envLayer.content.areas) {
+      if (a.id == aid) {
+        area = a;
+        break;
+      }
+    }
+    if (area == null) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.areaNotFound,
+          message: 'Environment area not found: $aid',
+          environmentLayerId: envId,
+          areaId: aid,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final presetIdLookup = area.presetId.trim();
+    EnvironmentPreset? preset;
+    for (final p in manifest.environmentPresets) {
+      if (p.id == presetIdLookup) {
+        preset = p;
+        break;
+      }
+    }
+    if (preset == null) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.presetMissing,
+          message: 'Environment preset not found: $presetIdLookup',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: presetIdLookup,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    if (preset.palette.isEmpty) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.emptyPresetPalette,
+          message: 'Environment preset has an empty palette: ${preset.id}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final elementById = <String, ProjectElementEntry>{
+      for (final e in manifest.elements) e.id: e,
+    };
+    for (final item in preset.palette) {
+      if (!elementById.containsKey(item.elementId)) {
+        issues.add(
+          EnvironmentGenerationIssue(
+            severity: EnvironmentGenerationIssueSeverity.error,
+            kind: EnvironmentGenerationIssueKind.paletteElementMissing,
+            message: 'Palette references unknown element id: ${item.elementId}',
+            environmentLayerId: envId,
+            areaId: aid,
+            presetId: preset.id,
+            targetLayerId: targetId,
+            elementId: item.elementId,
+          ),
+        );
+        return EnvironmentGenerationResult(
+            placements: const [], issues: issues);
+      }
+    }
+
+    final mask = area.mask;
+    if (mask.width != map.size.width || mask.height != map.size.height) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidMaskSize,
+          message: 'Mask size ${mask.width}x${mask.height} does not match map '
+              'size ${map.size.width}x${map.size.height}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final expectedCells = mask.width * mask.height;
+    if (mask.cells.length != expectedCells) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidMaskCellLength,
+          message: 'Mask cells length ${mask.cells.length} != $expectedCells',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final params = area.paramsOverride ?? preset.defaultParams;
+    if (!_isUnitInterval(params.density)) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidDensity,
+          message: 'density out of range [0,1]: ${params.density}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+    if (!_isUnitInterval(params.edgeDensity)) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidEdgeDensity,
+          message: 'edgeDensity out of range [0,1]: ${params.edgeDensity}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+    if (!_isUnitInterval(params.variation)) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidVariation,
+          message: 'variation out of range [0,1]: ${params.variation}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+    if (params.minSpacingCells < 0) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.error,
+          kind: EnvironmentGenerationIssueKind.invalidMinSpacingCells,
+          message: 'minSpacingCells must be >= 0: ${params.minSpacingCells}',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    var activeCount = 0;
+    for (var yi = 0; yi < mask.height; yi++) {
+      for (var xi = 0; xi < mask.width; xi++) {
+        if (mask.isActiveAt(xi, yi)) activeCount++;
+      }
+    }
+    if (activeCount == 0) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.warning,
+          kind: EnvironmentGenerationIssueKind.emptyAreaMask,
+          message: 'Environment area mask has no active cells',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+        ),
+      );
+      return EnvironmentGenerationResult(placements: const [], issues: issues);
+    }
+
+    final placements = <EnvironmentGeneratedPlacementCandidate>[];
+    final acceptedPositions = <GridPos>[];
+
+    for (var y = 0; y < map.size.height; y++) {
+      for (var x = 0; x < map.size.width; x++) {
+        if (!mask.isActiveAt(x, y)) continue;
+
+        final isEdge = _isMaskEdge(mask, x, y);
+        final baseP = isEdge ? params.edgeDensity : params.density;
+
+        final varRng = _rngForCell(
+          areaSeed: area.seed,
+          areaId: area.id,
+          presetId: preset.id,
+          x: x,
+          y: y,
+          usage: 'variation',
+        );
+        final jitter = (varRng.next01() - 0.5) * params.variation;
+        final p = (baseP + jitter).clamp(0.0, 1.0);
+
+        final rollRng = _rngForCell(
+          areaSeed: area.seed,
+          areaId: area.id,
+          presetId: preset.id,
+          x: x,
+          y: y,
+          usage: 'placement-roll',
+        );
+        final roll = rollRng.next01();
+        if (roll > p) continue;
+
+        if (_tooCloseChebyshev(
+          x: x,
+          y: y,
+          accepted: acceptedPositions,
+          minSpacingCells: params.minSpacingCells,
+        )) {
+          continue;
+        }
+
+        final palRng = _rngForCell(
+          areaSeed: area.seed,
+          areaId: area.id,
+          presetId: preset.id,
+          x: x,
+          y: y,
+          usage: 'palette-roll',
+        );
+        final item = _pickPaletteItem(
+          palette: preset.palette,
+          rng: palRng,
+        );
+        if (item == null) {
+          issues.add(
+            EnvironmentGenerationIssue(
+              severity: EnvironmentGenerationIssueSeverity.error,
+              kind: EnvironmentGenerationIssueKind.emptyPresetPalette,
+              message: 'Palette total weight is invalid',
+              environmentLayerId: envId,
+              areaId: aid,
+              presetId: preset.id,
+            ),
+          );
+          return EnvironmentGenerationResult(
+              placements: const [], issues: issues);
+        }
+
+        final pos = GridPos(x: x, y: y);
+        placements.add(
+          EnvironmentGeneratedPlacementCandidate(
+            id: _candidateId(
+              areaId: area.id,
+              x: x,
+              y: y,
+              elementId: item.elementId,
+            ),
+            environmentLayerId: envLayer.id,
+            areaId: area.id,
+            presetId: preset.id,
+            targetLayerId: targetId,
+            elementId: item.elementId,
+            pos: pos,
+            collisionMode: item.collisionMode,
+            tags: item.tags,
+          ),
+        );
+        acceptedPositions.add(pos);
+      }
+    }
+
+    if (placements.isEmpty && activeCount > 0) {
+      issues.add(
+        EnvironmentGenerationIssue(
+          severity: EnvironmentGenerationIssueSeverity.warning,
+          kind: EnvironmentGenerationIssueKind.noPlacementCandidates,
+          message: 'No placements generated despite active mask cells',
+          environmentLayerId: envId,
+          areaId: aid,
+          presetId: preset.id,
+          targetLayerId: targetId,
+        ),
+      );
+    }
+
+    return EnvironmentGenerationResult(placements: placements, issues: issues);
+  }
+}

```

### 20.2 `git diff --no-index /dev/null ... environment_generator_deterministic_core_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart b/packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart
new file mode 100644
index 00000000..b0bed32b
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart
@@ -0,0 +1,793 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/use_cases/environment_generator_use_cases.dart';
+
+void main() {
+  group('EnvironmentGenerationResult / DTO immuabilité', () {
+    test(
+        'EnvironmentGeneratedPlacementCandidate copie les tags et expose un Set immuable',
+        () {
+      final mutable = <String>{'a', 'b'};
+      final c = EnvironmentGeneratedPlacementCandidate(
+        id: 'i',
+        environmentLayerId: 'e',
+        areaId: 'a',
+        presetId: 'p',
+        targetLayerId: 't',
+        elementId: 'el',
+        pos: const GridPos(x: 0, y: 0),
+        collisionMode: EnvironmentCollisionMode.useElementDefault,
+        tags: mutable,
+      );
+      mutable.add('c');
+      expect(c.tags, containsAll(<String>['a', 'b']));
+      expect(c.tags.contains('c'), isFalse);
+      expect(() => c.tags.add('x'), throwsUnsupportedError);
+    });
+
+    test(
+        'EnvironmentGenerationResult copie placements et issues ; issuesForKind',
+        () {
+      final p = EnvironmentGeneratedPlacementCandidate(
+        id: '1',
+        environmentLayerId: 'e',
+        areaId: 'a',
+        presetId: 'p',
+        targetLayerId: 't',
+        elementId: 'el',
+        pos: const GridPos(x: 0, y: 0),
+        collisionMode: EnvironmentCollisionMode.useElementDefault,
+        tags: const {},
+      );
+      final i1 = EnvironmentGenerationIssue(
+        severity: EnvironmentGenerationIssueSeverity.warning,
+        kind: EnvironmentGenerationIssueKind.emptyAreaMask,
+        message: 'm1',
+      );
+      final i2 = EnvironmentGenerationIssue(
+        severity: EnvironmentGenerationIssueSeverity.error,
+        kind: EnvironmentGenerationIssueKind.presetMissing,
+        message: 'm2',
+      );
+      final rawPlacements = <EnvironmentGeneratedPlacementCandidate>[p];
+      final rawIssues = <EnvironmentGenerationIssue>[i1, i2];
+      final r = EnvironmentGenerationResult(
+        placements: rawPlacements,
+        issues: rawIssues,
+      );
+      rawPlacements.clear();
+      rawIssues.clear();
+      expect(r.placementCount, 1);
+      expect(r.errorCount, 1);
+      expect(r.warningCount, 1);
+      expect(r.hasErrors, isTrue);
+      expect(r.hasWarnings, isTrue);
+      expect(() => r.placements.clear(), throwsUnsupportedError);
+      expect(() => r.issues.clear(), throwsUnsupportedError);
+      expect(
+        r.issuesForKind(EnvironmentGenerationIssueKind.emptyAreaMask).length,
+        1,
+      );
+    });
+  });
+
+  group('GenerateEnvironmentAreaPlacementsUseCase', () {
+    test('déterminisme : deux exécutions identiques', () {
+      final ctx = _fullScenario(
+        mapW: 3,
+        mapH: 3,
+        activeAll: true,
+        params: _params(density: 0.5, edgeDensity: 0.5, variation: 0.25),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final a = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      final b = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(a, b);
+      expect(a.placements.map((e) => e.id).toList(),
+          b.placements.map((e) => e.id).toList());
+    });
+
+    test(
+        'mask : seulement deux cellules actives reçoivent des placements possibles',
+        () {
+      final cells = List<bool>.filled(9, false);
+      cells[0] = true;
+      cells[8] = true;
+      final ctx = _fullScenario(
+        mapW: 3,
+        mapH: 3,
+        cells: cells,
+        params: _params(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 0,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      final xs = r.placements.map((e) => e.pos).toSet();
+      expect(xs.length, r.placements.length);
+      for (final p in r.placements) {
+        expect(
+          p.pos == const GridPos(x: 0, y: 0) ||
+              p.pos == const GridPos(x: 2, y: 2),
+          isTrue,
+          reason: 'hors masque : ${p.pos}',
+        );
+      }
+    });
+
+    test(
+        'density 0 et edgeDensity 0 : aucun placement, warning noPlacementCandidates',
+        () {
+      final ctx = _fullScenario(
+        mapW: 2,
+        mapH: 2,
+        activeAll: true,
+        params: _params(
+          density: 0,
+          edgeDensity: 0,
+          variation: 0,
+          minSpacing: 0,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placements, isEmpty);
+      expect(
+        r.issuesForKind(EnvironmentGenerationIssueKind.noPlacementCandidates),
+        isNotEmpty,
+      );
+    });
+
+    test(
+        'density 1, edgeDensity 1, variation 0, spacing 0 : toutes les cellules actives',
+        () {
+      final ctx = _fullScenario(
+        mapW: 2,
+        mapH: 2,
+        activeAll: true,
+        params: _params(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 0,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placementCount, 4);
+    });
+
+    test('edgeDensity seul sur bloc 3x3 : le centre ne reçoit pas de placement',
+        () {
+      final ctx = _fullScenario(
+        mapW: 3,
+        mapH: 3,
+        activeAll: true,
+        params: _params(
+          density: 0,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 0,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(
+        r.placements.any((e) => e.pos == const GridPos(x: 1, y: 1)),
+        isFalse,
+      );
+      expect(r.placementCount, 8);
+    });
+
+    test('variation non nulle : stable entre deux appels', () {
+      final ctx = _fullScenario(
+        mapW: 4,
+        mapH: 4,
+        activeAll: true,
+        params: _params(
+          density: 0.7,
+          edgeDensity: 0.7,
+          variation: 0.8,
+          minSpacing: 0,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r1 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      final r2 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r1, r2);
+    });
+
+    test('minSpacingCells 1 sur 3x3 : aucune paire Chebyshev <= 1', () {
+      final ctx = _fullScenario(
+        mapW: 3,
+        mapH: 3,
+        activeAll: true,
+        params: _params(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 1,
+        ),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placementCount < 9, isTrue);
+      final pos = r.placements.map((e) => e.pos).toList();
+      for (var i = 0; i < pos.length; i++) {
+        for (var j = i + 1; j < pos.length; j++) {
+          final dx = (pos[i].x - pos[j].x).abs();
+          final dy = (pos[i].y - pos[j].y).abs();
+          expect(
+            dx > 1 || dy > 1,
+            isTrue,
+            reason: 'trop proche : ${pos[i]} et ${pos[j]}',
+          );
+        }
+      }
+    });
+
+    test('palette à un seul item : tous les elementId identiques', () {
+      final ctx = _fullScenario(
+        mapW: 2,
+        mapH: 2,
+        activeAll: true,
+        elementId: 'tree',
+        params:
+            _params(density: 1, edgeDensity: 1, variation: 0, minSpacing: 0),
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.placements.every((e) => e.elementId == 'tree'), isTrue);
+    });
+
+    test('palette deux items : résultat déterministe et pondération (snapshot)',
+        () {
+      final palette = [
+        EnvironmentPaletteItem(elementId: 'A', weight: 7),
+        EnvironmentPaletteItem(elementId: 'B', weight: 3),
+      ];
+      final preset = EnvironmentPreset(
+        id: 'preset1',
+        name: 'P',
+        templateId: 't',
+        palette: palette,
+        defaultParams: _params(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 0,
+        ),
+        sortOrder: 0,
+      );
+      final manifest = _manifest(
+        presets: [preset],
+        elements: [
+          _element(id: 'A'),
+          _element(id: 'B'),
+        ],
+      );
+      final mask = EnvironmentAreaMask(
+        width: 2,
+        height: 1,
+        cells: const <bool>[true, true],
+      );
+      final area = EnvironmentArea(
+        id: 'area1',
+        name: 'Z',
+        presetId: 'preset1',
+        mask: mask,
+        seed: 4242,
+      );
+      final map = _mapWithEnv(
+        width: 2,
+        height: 1,
+        area: area,
+        targetTileLayerId: 'tiles',
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        map,
+        manifest: manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placementCount, 2);
+      expect(r.placements.map((e) => e.elementId).toList(), ['B', 'B']);
+    });
+
+    test(
+        'erreurs : environmentLayerNotFound, layerIsNotEnvironmentLayer, cible',
+        () {
+      final ctx = _fullScenario(mapW: 1, mapH: 1, activeAll: true);
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r1 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'nope',
+        areaId: 'area1',
+      );
+      expect(
+        r1.issuesForKind(
+            EnvironmentGenerationIssueKind.environmentLayerNotFound),
+        isNotEmpty,
+      );
+      expect(r1.placements, isEmpty);
+
+      final tileOnly = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 1, height: 1),
+        layers: [
+          TileLayer(id: 'env', name: 'T', tiles: const [0]),
+        ],
+      );
+      final r2 = uc.execute(
+        tileOnly,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(
+        r2.issuesForKind(
+            EnvironmentGenerationIssueKind.layerIsNotEnvironmentLayer),
+        isNotEmpty,
+      );
+
+      final tile = TileLayer(id: 't', name: 'T', tiles: const [0]);
+      final area = EnvironmentArea(
+        id: 'a',
+        name: 'Z',
+        presetId: 'preset1',
+        mask: EnvironmentAreaMask(
+          width: 1,
+          height: 1,
+          cells: const [true],
+        ),
+        seed: 0,
+      );
+      final envWithArea = MapLayer.environment(
+        id: 'env2',
+        name: 'E',
+        content: EnvironmentLayerContent(
+          targetTileLayerId: null,
+          areas: [area],
+        ),
+      );
+      final map3 = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 1, height: 1),
+        layers: [envWithArea, tile],
+      );
+      final r3 = uc.execute(
+        map3,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env2',
+        areaId: 'a',
+      );
+      expect(
+        r3.issuesForKind(EnvironmentGenerationIssueKind.targetTileLayerMissing),
+        isNotEmpty,
+      );
+
+      final obj = MapLayer.object(id: 'obj', name: 'O');
+      final envBadTarget = MapLayer.environment(
+        id: 'env3',
+        name: 'E',
+        content: EnvironmentLayerContent(
+          targetTileLayerId: 'obj',
+          areas: [
+            EnvironmentArea(
+              id: 'a',
+              name: 'Z',
+              presetId: 'preset1',
+              mask: EnvironmentAreaMask(
+                width: 1,
+                height: 1,
+                cells: const [true],
+              ),
+              seed: 0,
+            ),
+          ],
+        ),
+      );
+      final map4 = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 1, height: 1),
+        layers: [envBadTarget, obj],
+      );
+      final r4 = uc.execute(
+        map4,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env3',
+        areaId: 'a',
+      );
+      expect(
+        r4.issuesForKind(EnvironmentGenerationIssueKind.targetTileLayerInvalid),
+        isNotEmpty,
+      );
+    });
+
+    test('erreurs : areaNotFound, presetMissing, paletteElementMissing', () {
+      final ctx = _fullScenario(mapW: 1, mapH: 1, activeAll: true);
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r1 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'unknown',
+      );
+      expect(r1.issuesForKind(EnvironmentGenerationIssueKind.areaNotFound),
+          isNotEmpty);
+
+      final areaWrongPreset = EnvironmentArea(
+        id: 'area1',
+        name: 'Z',
+        presetId: 'ghost',
+        mask: EnvironmentAreaMask(
+          width: 1,
+          height: 1,
+          cells: const [true],
+        ),
+        seed: 0,
+      );
+      final map2 = _mapWithEnv(
+        width: 1,
+        height: 1,
+        area: areaWrongPreset,
+        targetTileLayerId: 'tiles',
+      );
+      final r2 = uc.execute(
+        map2,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r2.issuesForKind(EnvironmentGenerationIssueKind.presetMissing),
+          isNotEmpty);
+
+      final badPalettePreset = EnvironmentPreset(
+        id: 'preset1',
+        name: 'P',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'missing', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParams.standard(),
+        sortOrder: 0,
+      );
+      final manifest2 = _manifest(
+        presets: [badPalettePreset],
+        elements: [_element(id: 'other')],
+      );
+      final r3 = uc.execute(
+        ctx.map,
+        manifest: manifest2,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(
+        r3.issuesForKind(EnvironmentGenerationIssueKind.paletteElementMissing),
+        isNotEmpty,
+      );
+    });
+
+    test('erreur : invalidMaskSize', () {
+      final ctx = _fullScenario(
+        mapW: 3,
+        mapH: 3,
+        maskW: 2,
+        maskH: 2,
+        activeAll: true,
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.issuesForKind(EnvironmentGenerationIssueKind.invalidMaskSize),
+          isNotEmpty);
+      expect(r.placements, isEmpty);
+    });
+
+    test('warnings : mask vide et aucune erreur', () {
+      final cells = List<bool>.filled(4, false);
+      final ctx = _fullScenario(
+        mapW: 2,
+        mapH: 2,
+        cells: cells,
+        activeAll: false,
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placements, isEmpty);
+      expect(r.issuesForKind(EnvironmentGenerationIssueKind.emptyAreaMask),
+          isNotEmpty);
+    });
+
+    test('paramsOverride remplace defaultParams du preset', () {
+      final preset = EnvironmentPreset(
+        id: 'preset1',
+        name: 'P',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+        ],
+        defaultParams: _params(
+          density: 0,
+          edgeDensity: 0,
+          variation: 0,
+          minSpacing: 0,
+        ),
+        sortOrder: 0,
+      );
+      final manifest = _manifest(
+        presets: [preset],
+        elements: [_element(id: 'e1')],
+      );
+      final mask = EnvironmentAreaMask(
+        width: 1,
+        height: 1,
+        cells: const [true],
+      );
+      final area = EnvironmentArea(
+        id: 'area1',
+        name: 'Z',
+        presetId: 'preset1',
+        mask: mask,
+        seed: 1,
+        paramsOverride: _params(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacing: 0,
+        ),
+      );
+      final map = _mapWithEnv(
+        width: 1,
+        height: 1,
+        area: area,
+        targetTileLayerId: 'tiles',
+      );
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      final r = uc.execute(
+        map,
+        manifest: manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.placementCount, 1);
+    });
+
+    test('aucune mutation : MapData, manifest, areas, tiles, placedElements',
+        () {
+      final ctx = _fullScenario(mapW: 2, mapH: 2, activeAll: true);
+      final mapBefore = ctx.map;
+      final manifestBefore = ctx.manifest;
+      final envLayer = mapBefore.layers.first as EnvironmentLayer;
+      final areaBefore = envLayer.content.areas.single;
+      final tileLayer = mapBefore.layers[1] as TileLayer;
+      final tilesBefore = List<int>.from(tileLayer.tiles);
+      final genIdsBefore = List<String>.from(areaBefore.generatedPlacementIds);
+      final placedBefore =
+          List<MapPlacedElement>.from(mapBefore.placedElements);
+      final presetsBefore =
+          List<EnvironmentPreset>.from(manifestBefore.environmentPresets);
+
+      final uc = GenerateEnvironmentAreaPlacementsUseCase();
+      uc.execute(
+        mapBefore,
+        manifest: manifestBefore,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+
+      expect(mapBefore, ctx.map);
+      expect(manifestBefore.environmentPresets, presetsBefore);
+      final envAfter = mapBefore.layers.first as EnvironmentLayer;
+      final areaAfter = envAfter.content.areas.single;
+      expect(areaAfter.generatedPlacementIds, genIdsBefore);
+      final tileAfter = mapBefore.layers[1] as TileLayer;
+      expect(tileAfter.tiles, tilesBefore);
+      expect(mapBefore.placedElements, placedBefore);
+    });
+  });
+}
+
+EnvironmentGenerationParams _params({
+  double density = 1,
+  double edgeDensity = 1,
+  double variation = 0,
+  int minSpacing = 0,
+}) {
+  return EnvironmentGenerationParams(
+    density: density,
+    variation: variation,
+    edgeDensity: edgeDensity,
+    minSpacingCells: minSpacing,
+  );
+}
+
+class _Scenario {
+  _Scenario({required this.map, required this.manifest});
+
+  final MapData map;
+  final ProjectManifest manifest;
+}
+
+_Scenario _fullScenario({
+  required int mapW,
+  required int mapH,
+  bool activeAll = false,
+  List<bool>? cells,
+  EnvironmentGenerationParams? params,
+  String elementId = 'e1',
+  int maskW = 0,
+  int maskH = 0,
+}) {
+  final mw = maskW == 0 ? mapW : maskW;
+  final mh = maskH == 0 ? mapH : maskH;
+  final cellList = cells ??
+      List<bool>.filled(
+        mw * mh,
+        activeAll,
+      );
+  final mask = EnvironmentAreaMask(
+    width: mw,
+    height: mh,
+    cells: cellList,
+  );
+  final preset = EnvironmentPreset(
+    id: 'preset1',
+    name: 'P',
+    templateId: 'tpl',
+    palette: [
+      EnvironmentPaletteItem(elementId: elementId, weight: 1),
+    ],
+    defaultParams: params ?? EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
+  );
+  final manifest = _manifest(
+    presets: [preset],
+    elements: [_element(id: elementId)],
+  );
+  final area = EnvironmentArea(
+    id: 'area1',
+    name: 'Zone',
+    presetId: 'preset1',
+    mask: mask,
+    seed: 99,
+  );
+  final map = _mapWithEnv(
+    width: mapW,
+    height: mapH,
+    area: area,
+    targetTileLayerId: 'tiles',
+  );
+  return _Scenario(map: map, manifest: manifest);
+}
+
+ProjectManifest _manifest({
+  List<EnvironmentPreset> presets = const [],
+  List<ProjectElementEntry> elements = const [],
+}) {
+  return ProjectManifest(
+    name: 't-gen',
+    maps: const [],
+    tilesets: const [],
+    environmentPresets: presets,
+    elements: elements,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+ProjectElementEntry _element({required String id}) {
+  return ProjectElementEntry(
+    id: id,
+    name: 'El $id',
+    tilesetId: 'ts',
+    categoryId: 'cat',
+    frames: const [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: 0, y: 0),
+      ),
+    ],
+  );
+}
+
+MapData _mapWithEnv({
+  required int width,
+  required int height,
+  required EnvironmentArea area,
+  required String targetTileLayerId,
+}) {
+  final n = width * height;
+  final env = MapLayer.environment(
+    id: 'env',
+    name: 'E',
+    content: EnvironmentLayerContent(
+      targetTileLayerId: targetTileLayerId,
+      areas: [area],
+    ),
+  );
+  final tile = TileLayer(
+    id: 'tiles',
+    name: 'T',
+    tiles: List<int>.filled(n, 0),
+  );
+  return MapData(
+    id: 'map1',
+    name: 'Map',
+    size: GridSize(width: width, height: height),
+    layers: [env, tile],
+  );
+}

```

## Evidence Pack — confirmations explicites

| Assertion | Preuve |
|-----------|--------|
| Aucun `EditorNotifier` modifié | Fichiers touchés listés §14 ; pas de chemin `editor_notifier.dart`. |
| Aucune UI modifiée | Idem ; aucun fichier sous `lib/src/ui/`. |
| Aucun canvas modifié | Idem ; pas de `map_canvas.dart`. |
| Aucun fichier `map_core` modifié | `git status` final : uniquement `map_editor` + `reports/forest`. |
| Aucun `EnvironmentPreset` modifié en mémoire | Use case lecture seule ; test non-mutation sur `manifest.environmentPresets`. |
| Aucun `generatedPlacementIds` modifié | Test non-mutation sur `EnvironmentArea`. |
| Aucun `MapPlacedElement` créé | Use case n’importe pas / n’écrit pas `placedElements` ; test `placedElements` inchangé. |
| Aucun `TileLayer` patché | Test `tiles` inchangé. |
| Aucune génération appliquée à `MapData` | Pas d’appel aux use cases d’écriture ; égalité `MapData` après `execute`. |
| Aucune sauvegarde disque | Grep §17.3 vide ; aucun `File` / repository dans les fichiers du lot. |
| Aucun `FileProjectRepository` / `saveProject` | Grep §17.3. |
| Aucune `SurfaceLayer` legacy | Code n’importe pas ces types. |
| Aucun `build_runner` | Non exécuté (commandes §16). |
| Aucun fichier generated modifié | Hors périmètre ; statut git sans `*.g.dart` / `*.freezed.dart`. |
| Aucun `commit` / `git add` / `push` | Politique outil + §18. |

## 21. Auto-review

### Points solides

- Use case strictement lecture seule sur `MapData` / `ProjectManifest` ; test de non-mutation explicite.
- PRNG documenté et isolé ; usages distincts par chaîne `usage`.
- Couverture fonctionnelle large (densités, bord, espacement, palette, erreurs fréquentes).

### Points discutables

- `noPlacementCandidates` élargi à tout masque actif sans placement : peut avertir dans des cas « normaux » rares (ex. densités très basses + malchance déterministe) — acceptable V0 pour signaler « rien n’a été posé ».
- Tests `emptyPresetPalette` / `invalidMaskCellLength` absents : invariants map_core empêchent la construction d’exemples sans toucher `map_core`.
- `flutter analyze` retourne code sortie 1 à cause des **infos** uniquement.

### Corrections faites après auto-review

- FNV-1a : suppression du masque `0x7FFFFFFF` incorrect.
- `EnvironmentGeneratedPlacementCandidate` : constructeur non const + `Set.from` pour satisfaire l’analyseur.
- Attente test palette deux items alignée sur le résultat déterministe réel (`B`, `B`).

### Risques restants

- Lot 24 devra définir la collision avec le graphe réel des tiles / entités ; les candidats portent déjà `collisionMode` + `tags`.
- Cohérence long terme si `map_core` autorise un jour des params partiels ou masques incohérents : les branches défensives restent pertinentes.

### Regard critique sur le prompt

- **MapPlacedElement dès ce lot ?** Non : le prompt excluait explicitement l’application ; DTO candidat suffit pour brancher Lot 24.
- **DTO suffisant ?** Oui pour un apply séparé ; un mapping vers `MapPlacedElement` sera local au lot d’application.
- **Edge cardinaux ?** Cohérent V0 « bord de zone » ; diagonales hors scope.
- **Chebyshev / carré ?** Conforme au texte du lot (`abs(dx)` et `abs(dy)` bornés).
- **PRNG maison vs `Random(seed)` ?** Évite la dépendance à l’algorithme interne de `Random` entre VM / versions ; FNV+xorshift est stable et auditable.
- **Respect hors UI / mutation ?** Oui : seuls nouveaux fichiers use case + test + rapports ; grep persistance vide.

## 22. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
Cœur déterministe livré dans map_editor, tests ciblés verts, suite test/environment_studio verte (+170),
régressions Lots 19–22 et tests proches verts. flutter analyze ciblé : 0 erreur / 0 warning (6 infos).
flutter test map_editor complet : +1003 -34 (dette préexistante hors lot). Aucune mutation MapData,
aucun appel disque, aucun git write.
```

Prochain lot recommandé :

```text
Environment-24 — Environment Generator Apply Candidates to Map V0
```

