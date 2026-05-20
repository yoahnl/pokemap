# ShadowV2-16 — Projected Building Shadow Semantic Diagnostics V0

## 1. Résumé exécutif

ShadowV2-16 implémente une opération pure de diagnostics sémantiques pour les ombres projetées de bâtiments V2.

Le lot ajoute :

- `ProjectedBuildingShadowDiagnosticSeverity`
- `ProjectedBuildingShadowDiagnosticKind`
- `ProjectedBuildingShadowDiagnostic`
- `diagnoseProjectedBuildingShadows(ProjectManifest manifest)`

L'opération détecte :

- `missingPreset` -> `error`
- `missingPresetForDisabledConfig` -> `warning`
- `unusedPreset` -> `warning`
- `v1AndV2Coexistence` -> `warning`
- `followsSunWithoutTimeOfDay` -> `info`

Aucun modèle persistant, codec JSON, validator, runtime, editor, fichier Selbrume, fichier generated ou baseline screenshot n'a été modifié.

## 2. Objectif du lot

Créer le contrôle sémantique ShadowV2 en mémoire, sans muter le projet et sans rendre le chargement invalide.

Objectifs couverts :

- créer les enums severity/kind ;
- créer un diagnostic à égalité de valeur ;
- créer l'API `diagnoseProjectedBuildingShadows(ProjectManifest manifest)` ;
- produire des diagnostics stables dans un ordre déterministe ;
- tester tous les cas retenus par ShadowV2-15 ;
- ne pas intégrer ces diagnostics à `ProjectValidator` ou `MapValidator`.

## 3. Rappel ShadowV2-15

ShadowV2-15 a validé le design suivant :

- API V0 : `List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(ProjectManifest manifest)`
- pas de report object en V0 ;
- pas d'intégration aux validators ;
- diagnostics authoring dédiés ;
- ordre stable : diagnostics par élément, puis diagnostics par preset ;
- aucune correction automatique ;
- aucun rendu ;
- aucune UI.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md
```

Le fichier `reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md` était déjà non suivi au démarrage du lot. Il n'a pas été modifié par ShadowV2-16.

## 5. Décision AGENTS / design gate satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- ShadowV2-15 a déjà présenté et validé le design diagnostics.
- ShadowV2-16 est l'implémentation bornée de ce design.
- Le lot reste `map_core` pur, sans runtime, sans editor et sans rendu.

## 6. Fichiers créés / modifiés

Créés :

- `packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart`
- `reports/shadows/v2/shadow_v2_16_projected_building_shadow_semantic_diagnostics.md`

Modifiés :

- `packages/map_core/lib/map_core.dart`

Supprimés :

- Aucun.

Generated files :

- Aucun.

Fichier non suivi préexistant et non modifié :

- `reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md`

## 7. Types créés

Types ajoutés dans `projected_building_shadow_diagnostics.dart` :

- `ProjectedBuildingShadowDiagnosticSeverity`
- `ProjectedBuildingShadowDiagnosticKind`
- `ProjectedBuildingShadowDiagnostic`

Le diagnostic contient :

- `severity`
- `kind`
- `message`
- `elementId`
- `elementName`
- `presetId`
- `presetName`

L'égalité de valeur et `hashCode` incluent tous ces champs.

## 8. API créée

API ajoutée :

```dart
List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
  ProjectManifest manifest,
)
```

Propriétés :

- pure ;
- ne modifie pas `manifest` ;
- ne crée aucun preset ;
- ne corrige aucune donnée ;
- ne dépend pas de Flutter ;
- ne dépend pas du runtime ou de l'éditeur ;
- retourne une liste non modifiable.

## 9. Diagnostics implémentés

### missingPreset

Cas :

- `element.projectedBuildingShadow != null`
- `enabled == true`
- `presetId` absent du catalogue V2

Sortie :

- `kind: missingPreset`
- `severity: error`
- `elementId`
- `elementName`
- `presetId`
- `presetName: null`

### missingPresetForDisabledConfig

Cas :

- `element.projectedBuildingShadow != null`
- `enabled == false`
- `presetId` absent du catalogue V2

Sortie :

- `kind: missingPresetForDisabledConfig`
- `severity: warning`

### unusedPreset

Cas :

- preset présent dans `projectedBuildingShadowCatalog`
- aucun élément ne référence son `id`

Sortie :

- `kind: unusedPreset`
- `severity: warning`
- `presetId`
- `presetName`

Une config disabled qui référence un preset compte comme usage.

### v1AndV2Coexistence

Cas :

- `element.shadow != null`
- `element.projectedBuildingShadow != null`
- `projectedBuildingShadow.enabled == true`

Sortie :

- `kind: v1AndV2Coexistence`
- `severity: warning`
- `elementId`
- `elementName`
- `presetId`
- `presetName` si le preset existe

Le prompt ShadowV2-16 demande explicitement `element.shadow != null`. Le diagnostic est donc produit pour toute config V1 présente, même si `castsShadow == false`.

### followsSunWithoutTimeOfDay

Cas :

- preset `timeOfDayMode == followsSun`
- preset référencé par au moins une config enabled true

Sortie :

- `kind: followsSunWithoutTimeOfDay`
- `severity: info`
- `presetId`
- `presetName`

Le diagnostic n'est pas produit si le preset est inutilisé ou référencé uniquement par des configs disabled.

## 10. Severities

Décisions appliquées :

| Diagnostic | Severity |
| --- | --- |
| `missingPreset` | `error` |
| `missingPresetForDisabledConfig` | `warning` |
| `unusedPreset` | `warning` |
| `v1AndV2Coexistence` | `warning` |
| `followsSunWithoutTimeOfDay` | `info` |

## 11. Ordre stable

Ordre implémenté :

1. Parcours des éléments dans l'ordre `manifest.elements`.
2. Pour chaque élément :
   - `missingPreset` ou `missingPresetForDisabledConfig` ;
   - puis `v1AndV2Coexistence`.
3. Parcours des presets dans l'ordre `manifest.projectedBuildingShadowCatalog.presets`.
4. Pour chaque preset :
   - `unusedPreset` ;
   - sinon `followsSunWithoutTimeOfDay` si activement référencé.

Cet ordre est testé explicitement.

## 12. Relation avec validators

`ProjectValidator` et `MapValidator` ne sont pas modifiés.

Les diagnostics ShadowV2 restent une opération authoring dédiée :

- aucun échec de chargement ajouté ;
- aucun blocage validator ;
- aucun autofix ;
- aucune mutation du projet.

## 13. Tests ajoutés

Fichier créé :

- `packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart`

Cas couverts :

- aucun diagnostic sur preset existant actif ;
- missing preset actif -> error ;
- missing preset disabled -> warning ;
- preset inutilisé -> warning ;
- config disabled compte comme usage ;
- V1 + V2 enabled -> warning ;
- toute config V1 non-null + V2 enabled -> coexistence ;
- V1 + V2 disabled -> pas de coexistence ;
- followsSun actif -> info ;
- followsSun inutilisé -> seulement unusedPreset ;
- followsSun disabled-only -> pas d'info ;
- ordre stable ;
- égalité de valeur ;
- liste retournée non modifiable.

## 14. Résultats des tests

### Test ciblé

Commande :

```bash
cd packages/map_core && dart test --reporter expanded test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Sortie complète du test ciblé, avec codes couleur retirés :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_diagnostics_test.dart
00:00 +0: Projected building shadow diagnostics returns no diagnostics for active element referencing existing preset
00:00 +1: Projected building shadow diagnostics reports active missing preset as error
00:00 +2: Projected building shadow diagnostics reports disabled missing preset as warning
00:00 +3: Projected building shadow diagnostics reports unused preset as warning
00:00 +4: Projected building shadow diagnostics disabled config counts as preset usage without extra noise
00:00 +5: Projected building shadow diagnostics reports V1 and enabled V2 coexistence as warning
00:00 +6: Projected building shadow diagnostics reports coexistence for any non-null V1 shadow config
00:00 +7: Projected building shadow diagnostics does not report V1 and V2 coexistence when V2 is disabled
00:00 +8: Projected building shadow diagnostics reports active followsSun preset as info
00:00 +9: Projected building shadow diagnostics reports followsSun unused preset only as unused warning
00:00 +10: Projected building shadow diagnostics does not report followsSun when referenced only by disabled configs
00:00 +11: Projected building shadow diagnostics keeps stable element diagnostics then catalog diagnostics order
00:00 +12: Projected building shadow diagnostics diagnostic equality includes all fields
00:00 +13: Projected building shadow diagnostics returned diagnostics list is unmodifiable
00:00 +14: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +138: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:01 +284: All tests passed!
```

## 15. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/projected_building_shadow_diagnostics.dart test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Sortie :

```text
Analyzing projected_building_shadow_diagnostics.dart, projected_building_shadow_diagnostics_test.dart...
No issues found!
```

## 16. Export public

Export ajouté : oui.

Raison :

- les diagnostics authoring existants de `map_core` sont exportés via `packages/map_core/lib/map_core.dart` ;
- les tests et futurs consommateurs doivent pouvoir utiliser l'API publique `diagnoseProjectedBuildingShadows`.

Diff de `map_core.dart` :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 78feeccd..8f4ed1a3 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -100,6 +100,7 @@ export 'src/operations/environment_preset_diagnostics.dart';
 export 'src/operations/environment_layer_usage_diagnostics.dart';
 export 'src/operations/environment_authoring_diagnostics.dart';
 export 'src/operations/shadow_authoring_diagnostics.dart';
+export 'src/operations/projected_building_shadow_diagnostics.dart';
 export 'src/operations/shadow_config_resolver.dart';
 export 'src/operations/surface_layer_placements.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
```

## 17. Ce qui n'a volontairement pas été créé

Non créés / non modifiés :

- aucun codec JSON ;
- aucune intégration `ProjectManifest` ;
- aucune intégration `ProjectElementEntry` ;
- aucun changement `ProjectValidator` ;
- aucun changement `MapValidator` ;
- aucune migration ;
- aucun resolver runtime ;
- aucun rendu ;
- aucune UI editor ;
- aucun autofix ;
- aucun preset par défaut ;
- aucun fichier generated ;
- aucune baseline screenshot ;
- aucun fichier Selbrume.

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les fichiers créés non suivis sont listés dans l'inventaire et le statut final.

## 19. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

## 20. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 21. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
?? reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md
?? reports/shadows/v2/shadow_v2_16_projected_building_shadow_semantic_diagnostics.md
```

## 22. Risques / réserves

- `v1AndV2Coexistence` suit la formulation stricte du prompt V2-16 : `element.shadow != null`. Cela inclut une config V1 avec `castsShadow == false`. Le test dédié verrouille cette décision.
- `followsSunWithoutTimeOfDay` est volontairement informatif et ne tente pas de détecter un vrai système jour/nuit, puisqu'il n'existe pas encore dans le runtime V2.
- Le lot ne valide pas que l'élément est réellement un bâtiment. Ce contrôle reste hors scope V0.
- Le lot ne résout pas visuellement les doubles ombres ; il signale seulement le risque authoring.

## 23. Auto-critique

Le changement est volontairement petit et borné. L'API simple `List<ProjectedBuildingShadowDiagnostic>` reste adaptée au V0 et évite de créer un report object avant d'avoir un besoin réel.

Le principal choix discutable est la coexistence V1/V2 sur toute config V1 non-null. Un filtre `castsShadow == true` aurait pu réduire le bruit, mais il aurait contredit le prompt d'implémentation le plus récent.

## 24. Regard critique sur le prompt

Le prompt est suffisamment strict pour empêcher les dérives vers runtime/editor/autofix. Il donne aussi les severities, l'ordre et les cas de test, ce qui rend le lot vérifiable.

Point de vigilance : la règle `element.shadow != null` pour la coexistence V1/V2 est plus large que certaines formulations précédentes de ShadowV2-15. L'implémentation privilégie la consigne ShadowV2-16.

## 25. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-17 — Projected Building Shadow Resolver / Runtime Preview Design Gate
```

Objectif recommandé :

- concevoir le resolver V2 sans encore rendre ;
- décider comment une config élément + un preset produiront une forme projetée résolue ;
- préserver la règle asset-driven / authorée ;
- décider les garde-fous runtime/editor avant tout rendu visible.

## Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart

```dart
import '../models/project_manifest.dart';
import '../models/projected_building_shadow.dart';

enum ProjectedBuildingShadowDiagnosticSeverity {
  info,
  warning,
  error,
}

enum ProjectedBuildingShadowDiagnosticKind {
  missingPreset,
  missingPresetForDisabledConfig,
  unusedPreset,
  v1AndV2Coexistence,
  followsSunWithoutTimeOfDay,
}

final class ProjectedBuildingShadowDiagnostic {
  const ProjectedBuildingShadowDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    this.elementId,
    this.elementName,
    this.presetId,
    this.presetName,
  });

  final ProjectedBuildingShadowDiagnosticSeverity severity;
  final ProjectedBuildingShadowDiagnosticKind kind;
  final String message;
  final String? elementId;
  final String? elementName;
  final String? presetId;
  final String? presetName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProjectedBuildingShadowDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            presetId == other.presetId &&
            presetName == other.presetName;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        elementId,
        elementName,
        presetId,
        presetName,
      );
}

/// Diagnoses authored projected building shadow V2 data in memory.
///
/// This is intentionally not a resolver, renderer, validator, migration, or
/// autofix: it reports semantic authoring issues without mutating [manifest].
List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
  ProjectManifest manifest,
) {
  final diagnostics = <ProjectedBuildingShadowDiagnostic>[];
  final catalog = manifest.projectedBuildingShadowCatalog;
  final referencedPresetIds = <String>{};
  final activelyReferencedPresetIds = <String>{};

  for (final element in manifest.elements) {
    final config = element.projectedBuildingShadow;
    if (config == null) {
      continue;
    }

    referencedPresetIds.add(config.presetId);
    if (config.enabled) {
      activelyReferencedPresetIds.add(config.presetId);
    }

    final preset = catalog.presetById(config.presetId);
    if (preset == null) {
      diagnostics.add(
        config.enabled
            ? _missingPresetDiagnostic(element, config)
            : _missingPresetForDisabledConfigDiagnostic(element, config),
      );
    }

    if (config.enabled && element.shadow != null) {
      diagnostics.add(
        _v1AndV2CoexistenceDiagnostic(element, config, preset),
      );
    }
  }

  for (final preset in catalog.presets) {
    if (!referencedPresetIds.contains(preset.id)) {
      diagnostics.add(_unusedPresetDiagnostic(preset));
      continue;
    }

    if (activelyReferencedPresetIds.contains(preset.id) &&
        preset.timeOfDayMode == ProjectedShadowTimeOfDayMode.followsSun) {
      diagnostics.add(_followsSunWithoutTimeOfDayDiagnostic(preset));
    }
  }

  return List<ProjectedBuildingShadowDiagnostic>.unmodifiable(diagnostics);
}

ProjectedBuildingShadowDiagnostic _missingPresetDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.error,
    kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
    message:
        'Element "${element.id}" references missing projected building shadow preset "${config.presetId}".',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
  );
}

ProjectedBuildingShadowDiagnostic _missingPresetForDisabledConfigDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.missingPresetForDisabledConfig,
    message:
        'Element "${element.id}" has disabled projected building shadow config referencing missing preset "${config.presetId}".',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
  );
}

ProjectedBuildingShadowDiagnostic _unusedPresetDiagnostic(
  ProjectBuildingShadowPreset preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
    message:
        'Projected building shadow preset "${preset.id}" is not referenced by any element.',
    presetId: preset.id,
    presetName: preset.name,
  );
}

ProjectedBuildingShadowDiagnostic _v1AndV2CoexistenceDiagnostic(
  ProjectElementEntry element,
  ProjectElementProjectedBuildingShadowConfig config,
  ProjectBuildingShadowPreset? preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
    kind: ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
    message:
        'Element "${element.id}" has both Shadow V1 and enabled projected building shadow V2.',
    elementId: element.id,
    elementName: element.name,
    presetId: config.presetId,
    presetName: preset?.name,
  );
}

ProjectedBuildingShadowDiagnostic _followsSunWithoutTimeOfDayDiagnostic(
  ProjectBuildingShadowPreset preset,
) {
  return ProjectedBuildingShadowDiagnostic(
    severity: ProjectedBuildingShadowDiagnosticSeverity.info,
    kind: ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
    message:
        'Projected building shadow preset "${preset.id}" follows the sun, but no time-of-day system is active yet.',
    presetId: preset.id,
    presetName: preset.name,
  );
}
```

### packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Projected building shadow diagnostics', () {
    test(
        'returns no diagnostics for active element referencing existing preset',
        () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('reports active missing preset as error', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog(),
          elements: [
            _element(
              id: 'house',
              name: 'Blue Roof House',
              projectedBuildingShadow: _config(presetId: 'missing-preset'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.error,
          kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
          message:
              'Element "house" references missing projected building shadow preset "missing-preset".',
          elementId: 'house',
          elementName: 'Blue Roof House',
          presetId: 'missing-preset',
        ),
      );
    });

    test('reports disabled missing preset as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog(),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'missing-preset',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind
              .missingPresetForDisabledConfig,
          message:
              'Element "house" has disabled projected building shadow config referencing missing preset "missing-preset".',
          elementId: 'house',
          elementName: 'House',
          presetId: 'missing-preset',
        ),
      );
    });

    test('reports unused preset as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'unused', name: 'Unused shadow'),
          ]),
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message:
              'Projected building shadow preset "unused" is not referenced by any element.',
          presetId: 'unused',
          presetName: 'Unused shadow',
        ),
      );
    });

    test('disabled config counts as preset usage without extra noise', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'kept-disabled'),
          ]),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'kept-disabled',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('reports V1 and enabled V2 coexistence as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west', name: 'Short west'),
          ]),
          elements: [
            _element(
              id: 'house',
              name: 'Blue Roof House',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
          message:
              'Element "house" has both Shadow V1 and enabled projected building shadow V2.',
          elementId: 'house',
          elementName: 'Blue Roof House',
          presetId: 'short-west',
          presetName: 'Short west',
        ),
      );
    });

    test('reports coexistence for any non-null V1 shadow config', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              shadow: _v1Shadow(castsShadow: false),
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.kind),
        contains(ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence),
      );
    });

    test('does not report V1 and V2 coexistence when V2 is disabled', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'short-west',
              ),
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.kind ==
                  ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
            )
            .toList(),
        isEmpty,
      );
    });

    test('reports active followsSun preset as info', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              name: 'Sun following shadow',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
          elements: [
            _element(
              id: 'tower',
              projectedBuildingShadow: _config(presetId: 'sun-following'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.info,
          kind:
              ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
          message:
              'Projected building shadow preset "sun-following" follows the sun, but no time-of-day system is active yet.',
          presetId: 'sun-following',
          presetName: 'Sun following shadow',
        ),
      );
    });

    test('reports followsSun unused preset only as unused warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.kind,
        ProjectedBuildingShadowDiagnosticKind.unusedPreset,
      );
    });

    test('does not report followsSun when referenced only by disabled configs',
        () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
          elements: [
            _element(
              id: 'tower',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'sun-following',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('keeps stable element diagnostics then catalog diagnostics order', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'used'),
            _preset(id: 'unused-a'),
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
            _preset(id: 'unused-b'),
          ]),
          elements: [
            _element(
              id: 'missing-active',
              projectedBuildingShadow: _config(presetId: 'missing-a'),
            ),
            _element(
              id: 'coexisting',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(presetId: 'used'),
            ),
            _element(
              id: 'missing-disabled',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'missing-b',
              ),
            ),
            _element(
              id: 'sun-user',
              projectedBuildingShadow: _config(presetId: 'sun-following'),
            ),
          ],
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.kind).toList(),
        [
          ProjectedBuildingShadowDiagnosticKind.missingPreset,
          ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
          ProjectedBuildingShadowDiagnosticKind.missingPresetForDisabledConfig,
          ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
          ProjectedBuildingShadowDiagnosticKind.unusedPreset,
        ],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.elementId).toList(),
        [
          'missing-active',
          'coexisting',
          'missing-disabled',
          null,
          null,
          null,
        ],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.presetId).toList(),
        [
          'missing-a',
          'used',
          'missing-b',
          'unused-a',
          'sun-following',
          'unused-b',
        ],
      );
    });

    test('diagnostic equality includes all fields', () {
      const base = ProjectedBuildingShadowDiagnostic(
        severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
        kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
        message: 'message',
        elementId: 'element',
        elementName: 'Element',
        presetId: 'preset',
        presetName: 'Preset',
      );

      expect(
        base,
        const ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message: 'message',
          elementId: 'element',
          elementName: 'Element',
          presetId: 'preset',
          presetName: 'Preset',
        ),
      );
      expect(
        base.hashCode,
        const ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message: 'message',
          elementId: 'element',
          elementName: 'Element',
          presetId: 'preset',
          presetName: 'Preset',
        ).hashCode,
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.error,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'different',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'different',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Different',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'different',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Different',
          ),
        ),
      );
    });

    test('returned diagnostics list is unmodifiable', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'unused'),
          ]),
        ),
      );

      expect(
        () => diagnostics.add(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.info,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'extra',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

ProjectBuildingShadowPresetCatalog _catalog([
  List<ProjectBuildingShadowPreset> presets = const [],
]) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  required String id,
  String? name,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name ?? 'Shadow $id',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: timeOfDayMode,
  );
}

ProjectElementEntry _element({
  required String id,
  String? name,
  ProjectElementShadowConfig? shadow,
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: name ?? _title(id),
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    shadow: shadow,
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  required String presetId,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectElementShadowConfig _v1Shadow({bool castsShadow = true}) {
  return ProjectElementShadowConfig(
    castsShadow: castsShadow,
    shadowProfileId: 'default-shadow',
  );
}

String _title(String id) {
  final words = id.split('-');
  return words
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
```
