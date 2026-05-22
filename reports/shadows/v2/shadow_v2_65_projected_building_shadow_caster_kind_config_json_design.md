# ShadowV2-65 — Projected Building Shadow Caster Kind Config JSON Design Gate

## 1. Résumé exécutif

ShadowV2-65 est un design gate JSON uniquement.

Décision recommandée :

- persister `ProjectElementProjectedBuildingShadowConfig.casterKind` sous la clé JSON `casterKind` ;
- encoder les valeurs comme strings stables `building` et `largeVolume` ;
- omettre la clé quand `casterKind == null` ;
- décoder les anciens JSON sans `casterKind` en `casterKind == null` ;
- accepter `"casterKind": null` au décodage comme `null` ;
- rejeter les valeurs inconnues et les types non string non null ;
- créer au Lot 66 un codec dédié `encodeProjectedBuildingShadowCasterKind(...)` / `decodeProjectedBuildingShadowCasterKind(...)` dans `projected_shadow_value_object_json_codecs.dart` ;
- intégrer ce codec au codec JSON de `ProjectElementProjectedBuildingShadowConfig` uniquement.

Le rapport ne modifie aucun fichier Dart, aucun test, aucun codec, aucun diagnostic et aucun resolver.

## 2. Objectif du lot

Objectif exact :

```text
Définir comment persister casterKind dans ProjectElementProjectedBuildingShadowConfig JSON,
sans implémenter encore,
en gardant la compatibilité avec les anciens JSON sans casterKind,
sans modifier le codec,
sans modifier le modèle,
sans modifier les diagnostics,
sans modifier le resolver,
sans modifier runtime/editor,
sans screenshot/baseline.
```

## 3. Rappel ShadowV2-64

Le Lot 64 a ajouté dans `ProjectElementProjectedBuildingShadowConfig` :

```text
casterKind: ProjectedBuildingShadowCasterKind?
```

Comportement validé au Lot 64 :

- `casterKind` vaut `null` par défaut ;
- `building` est stocké ;
- `largeVolume` est stocké ;
- une config disabled conserve `casterKind` ;
- equality/hashCode incluent `casterKind` ;
- `presetId` blank reste rejeté même avec `casterKind`.

Non fait au Lot 64 :

- JSON ;
- diagnostics ;
- resolver ;
- operation effective tuning integration ;
- runtime/editor.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Inventaire initial :

- fichiers préexistants non liés au Lot 65 : aucun ;
- fichiers modifiés préexistants : aucun ;
- fichiers non suivis préexistants : aucun.

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Preuve de lecture `AGENTS.md` :

```text
PokeMap is a Dart/Flutter monorepo for a Pokemon-like no-code fangame editor/runtime/battle stack.
Keep work practical: small scoped changes, package boundaries, explicit roadmap lots, tests, and evidence.
Never run Git write operations unless the user explicitly asks.
Reports under reports/ are tracked engineering artifacts.
```

Méthode réellement suivie :

- Pass 1 — Audit modèle casterKind ;
- Pass 2 — Audit codec JSON config existant ;
- Pass 3 — Design options JSON ;
- Pass 4 — Evidence/report.

Skills utilisés :

- `using-superpowers` ;
- `karpathy-guidelines` ;
- `writing-plans`, adapté au rapport imposé par le prompt ;
- `verification-before-completion`.

## 6. Fichiers créés / modifiés / supprimés

Fichier créé par ShadowV2-65 :

```text
reports/shadows/v2/shadow_v2_65_projected_building_shadow_caster_kind_config_json_design.md
```

Fichiers modifiés par ShadowV2-65 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-65 :

```text
Aucun
```

Fichiers Dart créés/modifiés :

```text
Aucun
```

Confirmation :

```text
Un seul rapport Markdown est créé par le Lot 65.
```

## 7. Audit modèle casterKind

Commande :

```bash
rg -n "ProjectElementProjectedBuildingShadowConfig|casterKind|ProjectedBuildingShadowCasterKind|building|largeVolume|enabled|presetId|anchor|localOffset|operator ==|hashCode" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
```

Constats utiles :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:21:enum ProjectedBuildingShadowCasterKind {
packages/map_core/lib/src/models/projected_building_shadow.dart:22:  building,
packages/map_core/lib/src/models/projected_building_shadow.dart:23:  largeVolume,
packages/map_core/lib/src/models/projected_building_shadow.dart:642:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/projected_building_shadow.dart:648:    ProjectedBuildingShadowCasterKind? casterKind,
packages/map_core/lib/src/models/projected_building_shadow.dart:659:      casterKind: casterKind,
packages/map_core/lib/src/models/projected_building_shadow.dart:668:    required this.casterKind,
packages/map_core/lib/src/models/projected_building_shadow.dart:675:  final ProjectedBuildingShadowCasterKind? casterKind;
packages/map_core/lib/src/models/projected_building_shadow.dart:685:          other.casterKind == casterKind;
packages/map_core/lib/src/models/projected_building_shadow.dart:693:        casterKind,
```

Résumé :

- la config porte `enabled`, `presetId`, `anchor`, `localOffset`, `casterKind` ;
- `casterKind` est optionnel ;
- les valeurs possibles sont `building` et `largeVolume` ;
- equality/hashCode incluent déjà `casterKind` ;
- le modèle ne sait pas si le preset référencé est fixed ou adaptive ;
- le modèle ne garantit pas encore la présence de `casterKind` pour un preset adaptive.

Tests modèle Lot 64 audités :

```text
ProjectElementProjectedBuildingShadowConfig casterKind defaults to null
ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind
ProjectElementProjectedBuildingShadowConfig casterKind stores largeVolume casterKind
ProjectElementProjectedBuildingShadowConfig casterKind disabled config preserves casterKind
ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind
ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind
ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind
```

## 8. Audit codec config actuel

Commande :

```bash
rg -n "encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|ProjectElementProjectedBuildingShadowConfig JSON|enabled|presetId|anchor|localOffset|casterKind|unknown|round-trips|re-emitting|missing|required|invalid" packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Extrait audité :

```dart
Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return <String, dynamic>{
    'enabled': config.enabled,
    'presetId': config.presetId,
    'anchor': encodeProjectedShadowAnchor(config.anchor),
    'localOffset': encodeProjectedShadowOffset(config.localOffset),
  };
}
```

Extrait decode audité :

```dart
return ProjectElementProjectedBuildingShadowConfig(
  enabled: _requiredBool(...),
  presetId: _requiredString(...),
  anchor: decodeProjectedShadowAnchor(...),
  localOffset: decodeProjectedShadowOffset(...),
);
```

Résumé :

- champs actuellement encodés : `enabled`, `presetId`, `anchor`, `localOffset` ;
- champs actuellement décodés : `enabled`, `presetId`, `anchor`, `localOffset` ;
- les clés inconnues sont ignorées ;
- les quatre champs actuels sont requis ;
- les tests couvrent round-trip et non réémission de clés inconnues ;
- `casterKind` est absent du codec actuel ;
- un futur champ optionnel peut préserver la compat en le décodant comme `null` quand absent.

## 9. Audit value object codecs actuels

Commande :

```bash
rg -n "ProjectedShadow|JSON codec|encodeProjected|decodeProjected|TimeOfDayMode|Appearance|colorHexRgb|opacity|unknown|invalid|non-string|string" packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Style enum existant audité :

```dart
String encodeProjectedShadowTimeOfDayMode(
  ProjectedShadowTimeOfDayMode mode,
) {
  return switch (mode) {
    ProjectedShadowTimeOfDayMode.fixed => 'fixed',
    ProjectedShadowTimeOfDayMode.followsSun => 'followsSun',
  };
}

ProjectedShadowTimeOfDayMode decodeProjectedShadowTimeOfDayMode(Object? json) {
  if (json is! String) {
    throw ValidationException(
      'ProjectedShadowTimeOfDayMode must be a String, got ${json.runtimeType}',
    );
  }
  return switch (json) {
    'fixed' => ProjectedShadowTimeOfDayMode.fixed,
    'followsSun' => ProjectedShadowTimeOfDayMode.followsSun,
    _ => throw ValidationException(
        'ProjectedShadowTimeOfDayMode has unknown value "$json"',
      ),
  };
}
```

Résumé :

- les enum-like codecs utilisent des strings ;
- les valeurs inconnues sont rejetées ;
- pas de case folding ;
- les types non string sont rejetés ;
- un codec dédié `ProjectedBuildingShadowCasterKind` est cohérent avec ce style.

## 10. Audit preset JSON actuel

Commande :

```bash
rg -n "ProjectBuildingShadowPreset JSON|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset|geometryMode|footprint|footprintStrategy|appearance|opacity|colorHexRgb|unknown|round-trips|re-emitting" packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Résumé :

- le codec preset encode `id`, `name`, `direction`, `shape`, `appearance`, `timeOfDayMode`, `categoryId`, `sortOrder` ;
- `footprintStrategy` n'est pas persisté aujourd'hui ;
- le Lot 65 ne doit pas traiter `footprintStrategy` parce qu'il concerne le preset et une stratégie adaptive complète, pas le guard élément/config ;
- `casterKind` config JSON peut être traité séparément car il appartient à `ProjectElementProjectedBuildingShadowConfig`.

## 11. Problème à résoudre

Le modèle sait maintenant porter :

```text
casterKind: ProjectedBuildingShadowCasterKind.building
```

Mais le JSON de `ProjectElementProjectedBuildingShadowConfig` ne le persiste pas.

Conséquence actuelle :

```text
config in-memory avec casterKind building
→ encodeProjectElementProjectedBuildingShadowConfig(...)
→ decodeProjectElementProjectedBuildingShadowConfig(...)
→ casterKind redevient null
```

Le prochain lot doit rendre cette donnée durable sans casser les anciens JSON.

## 12. Options clé JSON

Option A — `casterKind`

- Avantages : correspond au modèle, explicite, court, diagnosticable.
- Inconvénient : vocabulaire technique, acceptable dans une config ShadowV2.
- Verdict : recommandé.

Option B — `shadowCasterKind`

- Avantage : plus explicite hors contexte.
- Inconvénient : redondant dans une config déjà projetée shadow.
- Verdict : rejeté.

Option C — `buildingShadowCasterKind`

- Avantage : très explicite.
- Inconvénient : trop long et lourd.
- Verdict : rejeté.

Option D — `allowAdaptiveDepth`

- Avantage : booléen simple.
- Inconvénients : perd `building` vs `largeVolume`, contredit le Lot 63, affaiblit les diagnostics.
- Verdict : rejeté.

## 13. Options valeurs JSON

Option A — strings stables Dart-like :

```text
building
largeVolume
```

- Avantages : lisible, stable, direct avec les noms enum Dart.
- Verdict : recommandé.

Option B — snake_case :

```text
building
large_volume
```

- Avantage : style JSON fréquent.
- Inconvénient : mapping divergent de `largeVolume`.
- Verdict : rejeté.

Option C — enum index :

```text
0
1
```

- Inconvénients : fragile, illisible, dépend de l'ordre enum.
- Verdict : rejeté.

Option D — objet riche :

```json
{ "kind": "building" }
```

- Inconvénient : trop lourd pour deux valeurs.
- Verdict : rejeté.

## 14. Décision null / absence

Décision :

- encoder `casterKind == null` en omettant la clé ;
- décoder une clé absente comme `null` ;
- accepter `"casterKind": null` comme `null` au décodage ;
- ne jamais encoder `"casterKind": "none"`.

Pourquoi :

- l'omission garde les anciens JSON compacts ;
- `null` explicite est tolérable en entrée ;
- une pseudo-valeur `none` créerait une troisième valeur métier inutile.

## 15. Décision anciens JSON

Ancien JSON :

```json
{
  "enabled": true,
  "presetId": "some-preset",
  "anchor": { "xRatio": 0.5, "yRatio": 1 },
  "localOffset": { "x": 0, "y": 0 }
}
```

Décision :

```text
decode ancien JSON => casterKind == null
encode config avec casterKind null => casterKind omis
round-trip ancien JSON => ne réémet pas casterKind
```

Cela préserve les fichiers existants et évite une migration obligatoire.

## 16. Décision valeur inconnue

Exemple :

```json
{ "casterKind": "lampPost" }
```

Décision :

```text
rejeter avec ValidationException
```

Pourquoi :

- `casterKind` est un enum stable ;
- ignorer une valeur inconnue masquerait une erreur de données ;
- préserver les inconnus serait un modèle plus lourd qui n'existe pas dans les codecs ShadowV2 actuels.

## 17. Décision type non string

Exemples :

```json
{ "casterKind": 1 }
{ "casterKind": true }
{ "casterKind": {} }
```

Décision :

```text
rejeter les types non string non null avec ValidationException
```

Exception volontaire :

```text
casterKind absent ou null explicite => null
```

## 18. Codec dédié ou inline

Option A — fonctions dédiées :

```text
encodeProjectedBuildingShadowCasterKind(...)
decodeProjectedBuildingShadowCasterKind(...)
```

Avantages :

- testable isolément ;
- cohérent avec `ProjectedShadowTimeOfDayMode` ;
- réutilisable si diagnostics/presets/futures opérations lisent le même enum ;
- évite un mapping inline dispersé.

Option B — mapping inline dans le codec config :

- Avantage : plus court immédiatement.
- Inconvénients : moins testable, moins réutilisable, mélange enum codec et config codec.

Décision :

```text
Créer un codec dédié.
```

## 19. Emplacement codec futur

Option A — `projected_shadow_value_object_json_codecs.dart`

- Avantages : cohérent avec Direction / Anchor / Offset / Appearance / TimeOfDayMode ; centralise les petits codecs ShadowV2.
- Verdict : recommandé.

Option B — `project_element_projected_building_shadow_config_json_codec.dart`

- Avantage : local à la config.
- Inconvénient : moins réutilisable.
- Verdict : rejeté.

Option C — nouveau fichier dédié

- Avantage : isolation maximale.
- Inconvénient : fichier trop petit pour un enum à deux valeurs.
- Verdict : rejeté.

Décision :

```text
Ajouter encode/decode ProjectedBuildingShadowCasterKind dans projected_shadow_value_object_json_codecs.dart,
puis l'utiliser depuis project_element_projected_building_shadow_config_json_codec.dart.
```

## 20. Tests futurs Lot 66

Tests codec enum à créer :

```text
ProjectedBuildingShadowCasterKind JSON codec encodes building
ProjectedBuildingShadowCasterKind JSON codec encodes largeVolume
ProjectedBuildingShadowCasterKind JSON codec decodes building
ProjectedBuildingShadowCasterKind JSON codec decodes largeVolume
ProjectedBuildingShadowCasterKind JSON codec rejects unknown string
ProjectedBuildingShadowCasterKind JSON codec rejects non-string
```

Tests codec config à créer :

```text
ProjectElementProjectedBuildingShadowConfig JSON codec omits casterKind when null
ProjectElementProjectedBuildingShadowConfig JSON codec encodes building casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec encodes largeVolume casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec decodes missing casterKind as null
ProjectElementProjectedBuildingShadowConfig JSON codec decodes explicit null casterKind as null
ProjectElementProjectedBuildingShadowConfig JSON codec decodes building casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec decodes largeVolume casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec rejects unknown casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec rejects non-string casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config with casterKind
ProjectElementProjectedBuildingShadowConfig JSON codec round-trips legacy JSON without re-emitting casterKind
```

## 21. Ordre JSON vs diagnostics

Décision :

```text
Lot 66 = JSON V0 avant diagnostics.
```

Pourquoi :

- le champ modèle deviendra durable ;
- les diagnostics futurs pourront s'appuyer sur une donnée persistée ;
- un diagnostic sur un champ non persisté aurait moins de valeur pour les fixtures/imports/round-trips ;
- le scope JSON config est petit et isolé.

## 22. Option recommandée

Option recommandée :

```text
casterKind JSON V0 avec clé "casterKind", valeurs string "building" / "largeVolume",
omission quand null, decode legacy vers null, rejet strict des valeurs invalides.
```

Design recommandé :

- clé JSON : `casterKind` ;
- valeurs : `building`, `largeVolume` ;
- comportement null : omettre à l'encodage, accepter absent/null au décodage ;
- comportement ancien JSON : decode `null`, round-trip sans réémission ;
- comportement valeur inconnue : `ValidationException` ;
- comportement type invalide : `ValidationException` pour non string non null ;
- codec dédié ou inline : codec dédié ;
- emplacement codec futur : `projected_shadow_value_object_json_codecs.dart` ;
- tests futurs : enum codec + config codec listés en section 20 ;
- ordre JSON/diagnostics : JSON d'abord, diagnostics ensuite.

Pourquoi :

- design compatible avec les anciens JSON ;
- design explicite, sans inférence depuis `categoryId` ou `presetKind` ;
- design aligné avec `ProjectedShadowTimeOfDayMode` ;
- scope assez petit pour un Lot 66 V0.

Pourquoi les autres options sont rejetées :

- noms de clé plus longs : redondants ;
- bool `allowAdaptiveDepth` : perd la sémantique guard ;
- enum index : fragile ;
- objet riche : surdimensionné ;
- inline codec : moins testable ;
- diagnostics avant JSON : moins utile tant que la donnée n'est pas persistée.

Lot 66 doit faire :

- ajouter le codec enum dédié ;
- intégrer `casterKind` au codec config ;
- ajouter les tests JSON ciblés ;
- préserver la compat des JSON sans `casterKind`.

Lot 66 ne doit pas faire :

- diagnostics ;
- resolver ;
- runtime/editor ;
- `footprintStrategy` JSON ;
- `ProjectBuildingShadowPreset` JSON ;
- generated files ;
- screenshots/baselines.

## 23. Plan précis du Lot 66

Nom recommandé :

```text
ShadowV2-66 — Projected Building Shadow Caster Kind Config JSON V0
```

Objectif :

```text
Persister casterKind dans ProjectElementProjectedBuildingShadowConfig JSON,
avec compat anciens JSON,
sans diagnostics,
sans resolver,
sans runtime/editor.
```

Périmètre :

Modifier :

```text
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Créer :

```text
reports/shadows/v2/shadow_v2_66_projected_building_shadow_caster_kind_config_json_v0.md
```

Tests à lancer au Lot 66 :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
cd packages/map_core && dart test test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
cd packages/map_core && dart test test/shadow_v2
cd packages/map_core && dart analyze lib/src/operations/projected_shadow_value_object_json_codecs.dart lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

## 24. Fichiers explicitement interdits au Lot 66

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
project.json
```

À ne pas créer au Lot 66 :

```text
*.g.dart
*.freezed.dart
*.golden
baseline_manifest.json
renderer
painter
migration
fixture Selbrume
screenshot
image
```

## 25. Risques / réserves

- `footprintStrategy` JSON reste non traité ; c'est volontaire, mais il faudra un design gate séparé.
- `casterKind` JSON rendra durable un guard, mais les diagnostics adaptive seront encore à faire après Lot 66.
- Accepter `null` explicite au décodage est compatible mais doit être testé pour éviter une future ambiguïté.
- Le rejet strict des valeurs inconnues est bon pour la qualité de données, mais il rend les extensions futures dépendantes d'une mise à jour de codec.

## 26. Auto-critique

- Le lot est-il bien design-only ? Oui, seul ce rapport est créé.
- Le rapport évite-t-il de coder dans un design gate ? Oui, aucune modification Dart/test.
- Le rapport garde-t-il diagnostics hors implémentation ? Oui.
- Le rapport garde-t-il resolver/runtime/editor hors scope ? Oui.
- Le rapport garde-t-il `footprintStrategy` JSON hors scope ? Oui.
- Le rapport garantit-il la compat anciens JSON ? Oui : absence => null, null omitted à l'encodage.
- Le rapport évite-t-il une valeur par défaut dangereuse ? Oui : aucun default `building` ou `largeVolume`.
- Le plan Lot 66 est-il assez petit ? Oui : deux codecs, deux tests, un rapport.
- Le rapport contient-il les preuves ? Oui : status initial/final, AGENTS, audits, git diff.

## 27. Regard critique sur le prompt

Le prompt est bien borné : il impose un design gate avant de modifier le codec, ce qui évite de mélanger persistance, diagnostics et resolver. La seule tension est la quantité d'audit sur `reports/shadows/v2`, qui produit beaucoup de bruit historique ; le signal utile reste clair : persister le guard config avant diagnostics.

## 28. Commandes lancées

```bash
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/writing-plans/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/verification-before-completion/SKILL.md
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
rg -n "ProjectElementProjectedBuildingShadowConfig|casterKind|ProjectedBuildingShadowCasterKind|building|largeVolume|enabled|presetId|anchor|localOffset|operator ==|hashCode" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
rg -n "encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|ProjectElementProjectedBuildingShadowConfig JSON|enabled|presetId|anchor|localOffset|casterKind|unknown|round-trips|re-emitting|missing|required|invalid" packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
rg -n "ProjectedShadow|JSON codec|encodeProjected|decodeProjected|TimeOfDayMode|Appearance|colorHexRgb|opacity|unknown|invalid|non-string|string" packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
rg -n "ProjectBuildingShadowPreset JSON|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset|geometryMode|footprint|footprintStrategy|appearance|opacity|colorHexRgb|unknown|round-trips|re-emitting" packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
rg -n "adaptivePresetRequiresCasterKind|adaptiveDepthRequiresCasterKind|casterKind|diagnoseProjectedBuildingShadows|resolveProjectedShadowFootprintEffectiveTuning|ProjectElementProjectedBuildingShadowConfig" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2 reports/shadows/v2
sed -n '630,700p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,130p' packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
sed -n '190,220p' packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
sed -n '80,130p' packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
sed -n '1,150p' packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
sed -n '150,210p' packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
sed -n '130,180p' packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
sed -n '401,440p' packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
sed -n '1,130p' reports/shadows/v2/shadow_v2_64_projected_building_shadow_caster_kind_config_model_v0.md
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests :

```text
Aucun test lancé. Le lot est design-only et le prompt demande explicitement de ne pas lancer les tests.
```

## 29. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie finale :

```text
```

## 30. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie finale :

```text
```

## 31. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie finale :

```text
```

## 32. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale complète :

```text
?? reports/shadows/v2/shadow_v2_65_projected_building_shadow_caster_kind_config_json_design.md
```

Checklist finale :
- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] AGENTS.md lu
- [x] Modèle casterKind actuel audité
- [x] Codec config actuel audité
- [x] Value object codecs actuels audités
- [x] Preset JSON actuel audité
- [x] Clé JSON tranchée
- [x] Valeurs JSON tranchées
- [x] Null / absence tranché
- [x] Anciens JSON tranchés
- [x] Valeur inconnue tranchée
- [x] Type non string tranché
- [x] Codec dédié vs inline tranché
- [x] Emplacement codec futur tranché
- [x] Tests futurs Lot 66 listés
- [x] Ordre JSON vs diagnostics tranché
- [x] Option recommandée unique
- [x] Plan ShadowV2-66 précis
- [x] Fichiers interdits au Lot 66 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
