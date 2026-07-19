# NSC-11 — Pickers de références et inspecteur de dépendances partagés — Evidence Pack

Date : 2026-07-19  
Branche : `main`  
Base initiale : `de808502 feat(narrative): add reversible child navigation`  
Statut proposé : **DONE**

> Ce fichier est l'Evidence Pack créé par le lot. Il est explicitement exclu de l'exigence récursive de reproduire son propre contenu ; tous les autres fichiers créés sont reproduits intégralement en annexe.

## 1. Résumé exécutif

NSC-11 fournit deux primitives partagées du design system et leurs contrats Core : un picker de références narratives no-code, accessible et explicatif, ainsi qu'un inspecteur de dépendances. Le label lisible précède toujours l'identifiant technique, les collisions sont résolues par la `NarrativeDependencyKey` complète, les références incompatibles ou cassées restent visibles et expliquées, et aucune création de PNJ, objet, zone ou trigger n'est inventée hors Map Editor.

Le remplacement global n'est proposé que pour le chemin cinématique réellement prouvé atomique. Une capability opaque Core couvre une paire source/remplacement et l'ensemble exact de ses chemins consommateurs ; elle est revalidée sur le projet courant avant suppression. Le widget ne décide jamais seul de la sûreté.

Toutes les validations ciblées et complètes sont vertes. Le premier contrôle strict de signature a détecté des frameworks incrémentaux périmés ; un `flutter clean`, `flutter pub get` et un build neuf ont produit une application valide sur disque et conforme à sa Designated Requirement.

## 2. Confirmation et audit du scope

### 2.1 Audit du prompt et continuité

La demande est cohérente avec la phase 1 de la roadmap : NSC-11 dépend de l'index NSC-01 et de la navigation NSC-10 déjà présents. La liste de fichiers indicative de la roadmap était toutefois insuffisante pour prouver une opération « remplacer partout » sûre et publier les composants : le scope a donc été étendu de façon minimale à `narrative_asset_mutation.dart`, `narrative_dependency_index.dart`, leurs tests, le barrel du design system et un guardrail narratif ciblé.

Aucun schéma JSON, runtime, donnée Selbrume, écran métier existant ou source physique de map n'a été modifié. L'adoption des composants par tous les futurs workspaces reste le travail des lots fonctionnels suivants.

### 2.2 Contrats existants audités

- `NarrativeDependencyIndex` est conservé comme seule vérité des définitions, usages, diagnostics et intents de navigation.
- Les read models historiques restent compatibles ; le modèle canonique s'ajoute sans les remplacer brutalement.
- `NarrativeAssetMutation.deleteCinematic` était le seul chemin de remplacement atomique déjà réel ; aucun faux support générique n'a été exposé.
- Les primitives PokeMap et les tokens sémantiques restent obligatoires dans `map_editor`.
- Les sources physiques continuent d'appartenir au Map Editor ; le picker ne reçoit aucun callback de création.

### 2.3 Risques identifiés avant implémentation

- collision d'un même ID enfant sur deux maps ;
- confusion entre sélection filtrée/incompatible et référence réellement manquante ;
- choix arbitraire lorsqu'une clé possède plusieurs définitions ;
- remplacement global proposé malgré une couverture partielle ou périmée ;
- disparition silencieuse d'une référence cassée ;
- overflow dans un parent borné ou non borné ;
- perte de focus après recherche ;
- dérive vers des couleurs directes ou du chrome legacy ;
- inclusion accidentelle des changements Selbrume préexistants.

## 3. État Git initial

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

Le test `selbrume_lighthouse_retry_integration_test.dart` était déjà indexé. Tous ces changements appartiennent à un autre chantier et sont exclus du lot et du commit NSC-11.

## 4. Inventaire complet et zones modifiées

| Fichier | Zone / contrat | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/authoring/narrative_asset_mutation.dart` | `NarrativeReferenceReplacementCapability`, résultats typed validé/refusé, validation et suppression revalidée | Rend le remplacement cinématique exact, opaque, immutable et résistant à une capability périmée. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | inspection d'une clé, métadonnées `entityKind` et statut Event | Fournit définitions, usages et issues dédupliquées/déterministes, et distingue les vraies sources physiques. |
| `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart` | enums disponibilité/publication, option/groupe/picker canoniques, recherche et projection | Centralise labels, breadcrumbs, diagnostics, usages, navigation et état cassé/incompatible. |
| `packages/map_core/test/narrative_asset_mutation_test.dart` | tests capability et revalidation | Couvre validé, missing, self, ambigu, couverture immutable/exacte et projet devenu stale. |
| `packages/map_core/test/narrative_dependency_index_test.dart` | inspection, statuts Event et identités physiques | Couvre déduplication, ordre, missing/ambiguous et metadata publiée/draft/inactive. |
| `packages/map_core/test/narrative_reference_picker_read_models_test.dart` | projection, recherche, groupes, collisions, incompatibilités | Couvre positif, négatif, casse, scopes non physiques et non-régression des modèles historiques. |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | exports des deux primitives narratives | Publie le picker et l'inspecteur comme composants partagés. |
| `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart` | nouveau widget | Rend recherche, groupes, états, copie, ouverture, clavier, semantics et layouts borné/non borné. |
| `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_dependency_inspector.dart` | nouveau widget | Rend définitions, consommateurs, diagnostics et actions exactes ; remplace partout seulement avec capability correspondante. |
| `packages/map_editor/test/ui/design_system/pokemap_narrative_reference_picker_test.dart` | nouveaux widget tests | Couvre empty, broken, filtered, copy/open, collisions, clavier, focus, semantics, disabled et contraintes. |
| `packages/map_editor/test/ui/design_system/pokemap_dependency_inspector_test.dart` | nouveaux widget tests | Couvre missing/ambiguous, consumers, diagnostics, replace gate et contrat picker→inspecteur→intent. |
| `packages/map_editor/test/ui/design_system/narrative_design_system_guardrail_test.dart` | nouveau ratchet | Refuse couleurs directes, constructeurs multiline et chrome Cupertino/Macos legacy dans ce périmètre. |
| `reports/narrativeStudio/completion/nsc_11_shared_reference_tools_evidence_pack.md` | présent document | Conserve audit, preuves, risques, diffs par zones et contenu intégral des fichiers créés. |

### Décisions et non-objectifs

- `sourceMap` n'est sélectionnable que si `isPhysicalMapSource` est vrai.
- Une sélection existante filtrée est `incompatibleSelection`, pas `missingSelection`.
- Une référence manquante permet seulement de copier son ID ; une référence incompatible existante peut aussi être ouverte si son intent est réel.
- Une définition ambiguë devient une seule option incompatible expliquée.
- Aucun bouton « créer » n'existe dans ces composants.
- Aucun remplacement non cinématique n'est prétendu sûr.
- Aucun workspace métier n'est migré dans ce lot ; NSC-11 fournit le contrat partagé.

## 5. Tests et cycle TDD

### 5.1 RED constaté

Les premiers tests Core ont échoué à compiler faute de contrats canoniques, inspection et capability. Les premiers tests Editor ont échoué faute de widgets. Les passes de revue ont ensuite produit des RED ciblés pour : `incompatibleSelection`, les metadata `entityKind`, les clés stables d'inspecteur, la détection de couleurs multiline, le layout borné/non borné et l'action Ouvrir d'une référence filtrée existante.

### 5.2 Commandes ciblées finales

```bash
cd packages/map_core
dart test test/narrative_reference_picker_read_models_test.dart test/narrative_dependency_index_test.dart test/narrative_asset_mutation_test.dart
```

Résultat exact : `+76: All tests passed!`

```bash
cd packages/map_editor
flutter test test/ui/design_system/pokemap_narrative_reference_picker_test.dart test/ui/design_system/pokemap_dependency_inspector_test.dart test/ui/design_system/narrative_design_system_guardrail_test.dart
```

Résultat exact : `+21: All tests passed!`

Les tests couvrent les chemins positifs, les refus, les garde-fous, le clavier seul, les collisions de clés complètes, les sélections cassées, la non-création physique et une intégration picker→inspecteur→intent.

### 5.3 Suites complètes et analyses

```bash
cd packages/map_core
dart test
dart analyze
```

Résultats exacts :

- `+3134: All tests passed!`
- `No issues found!`

```bash
cd packages/map_editor
flutter test --concurrency=1
flutter analyze
```

Résultats exacts :

- `+3486: All tests passed!`
- `No issues found! (ran in 4.8s)`

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Résultat exact : aucune sortie, code 0.

## 6. Build et validation native

Premier build incrémental :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat : `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

Le premier `codesign --verify --deep --strict` a honnêtement échoué avec `nested code is modified or invalid` sur `App.framework` et `objective_c.framework`. Le diagnostic indiquait des artefacts incrémentaux modifiés, pas une erreur Dart.

Reconstruction propre :

```bash
flutter clean
flutter pub get
flutter build macos --debug
codesign --verify --deep --strict --verbose=2 build/macos/Build/Products/Debug/map_editor.app
file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
```

Résultats exacts :

- `✓ Built build/macos/Build/Products/Debug/map_editor.app`
- `map_editor.app: valid on disk`
- `map_editor.app: satisfies its Designated Requirement`
- `Mach-O 64-bit executable arm64`

Avertissements conservés : AppIcon possède un child non assigné ; le script Flutter Assemble n'annonce pas d'outputs et tourne à chaque build. Ils sont hors scope NSC-11 et ne bloquent ni le build ni la signature.

## 7. Verdict des passes et sub-agents

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | Continuité NSC-01/02/10 confirmée, un seul index, capability opaque limitée aux cinématiques. |
| Implémentation Core | PASS | Modèles immuables, ordre déterministe, vraie identité physique, couverture exacte et revalidation stale. |
| Implémentation Picker | PASS | Label-first, ID secondaire, recherche, clavier, focus, semantics, états cassés/incompatibles, layouts borné/non borné. |
| Implémentation Inspector | PASS | Définitions/usages/issues exacts, intents stables, replace gate double et aucune création physique. |
| Tests | PASS | 76 Core ciblés, 21 Editor ciblés, 3134 Core complets, 3486 Editor complets. |
| Build / Validation | PASS après nettoyage | Build macOS neuf valide sur disque, Designated Requirement satisfaite, arm64. |
| Critique finale | PASS | Aucun finding bloquant après corrections ; analyses et diff check propres. |

Corrections issues des revues : exclusion stricte des sources non physiques, fallback de raison incompatible vide, clés d'actions inspecteur stables, guardrail renforcé, distinction filtered/missing, copie d'un ID cassé, compatibilité parent borné/non borné et action Ouvrir pour une incompatibilité navigable.

## 8. Gates G1–G8

| Gate | Verdict | Preuve |
|---|---|---|
| G1 — vérité canonique | PASS | Le picker et l'inspection dérivent exclusivement de `NarrativeDependencyIndex`. |
| G2 — compréhension no-code | PASS | Label, type, groupe, breadcrumb, publication, diagnostic et ID copiable. |
| G3 — honnêteté des états | PASS | available/incompatible/missing séparés ; ambiguïté et raison visibles. |
| G4 — identité/navigation | PASS | Clé complète et intent NSC-10 conservés de bout en bout malgré deux enfants homonymes. |
| G5 — sûreté de mutation | PASS | Capability opaque, couverture exacte, callback typé et revalidation contre le projet courant. |
| G6 — frontière Map Editor | PASS | Sources non physiques exclues et aucun callback de création PNJ/objet/zone/trigger. |
| G7 — accessibilité/design system | PASS | Clavier, focus, semantics, contraintes, tokens sémantiques et ratchet anti-legacy. |
| G8 — validation/intégrité | PASS | Ciblés, suites complètes, analyses, build/signature et `git diff --check` verts. |

## 9. État Git final avant commit isolé

À la clôture technique, les seuls changements NSC-11 sont les treize chemins de l'inventaire. Les changements Selbrume initiaux restent présents et le test lighthouse reste indexé indépendamment. Le commit doit utiliser `git commit --only` avec la liste exacte afin de préserver cette séparation.

```text
NSC-11: 7 fichiers Core/Editor existants modifiés, 5 fichiers Dart créés, 1 Evidence Pack créé.
Hors scope préservé: 8 fichiers Selbrume modifiés/indexés et 1 rapport gameplay non suivi.
git diff --check: code 0, aucune sortie.
```

## 10. Auto-critique, limites et risques restants

- Le lot fournit les primitives mais ne remplace pas encore les dropdowns locaux : cette adoption appartient aux lots fonctionnels suivants.
- Le remplacement global reste volontairement cinématique. Étendre cette capacité exige une opération Core atomique propre à chaque famille, pas un booléen UI.
- Les libellés de ces primitives sont actuellement en français ; l'infrastructure l10n commune relève de NSC-12.
- La suite Editor complète dure environ douze minutes, mais elle est utile car elle couvre les migrations et round-trips Selbrume.
- Les warnings Xcode AppIcon/script phase sont réels, préexistants et hors scope.
- L'Evidence Pack est volumineux parce que `codex_rule.md` exige le contenu intégral des fichiers créés.
- Aucun pourcentage de couverture n'est inventé ; seules les commandes et assertions observées sont rapportées.

Prochaine étape proposée, non implémentée ici : NSC-12 — durcissement responsive du shell, design system, accessibilité et infrastructure Flutter gen-l10n.

## 11. Annexe — contenu intégral des fichiers créés

### `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_dependency_inspector.dart`

```dart
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_card.dart';
import '../pokemap_diagnostic_callout.dart';
import '../pokemap_empty_state.dart';
import '../pokemap_section_header.dart';

/// Read-only dependency details shared by Narrative Studio authoring surfaces.
///
/// Navigation is expressed exclusively through canonical Core intents. A bulk
/// replacement is offered only when Core supplied an unforgeable capability
/// whose covered paths still match this exact inspection model.
class PokeMapDependencyInspector extends StatelessWidget {
  const PokeMapDependencyInspector({
    super.key,
    required this.model,
    this.onOpen,
    this.replacementCapability,
    this.onReplaceEverywhere,
  });

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;
  final NarrativeReferenceReplacementCapability? replacementCapability;
  final ValueChanged<NarrativeReferenceReplacementCapability>?
      onReplaceEverywhere;

  @override
  Widget build(BuildContext context) {
    final capability = _usableReplacementCapability;
    final targetTitle = switch (model.definitions.length) {
      0 => 'Référence introuvable',
      > 1 => 'Référence ambiguë',
      _ => model.definitions.single.label,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeMapSectionHeader(
            title: targetTitle,
            description: model.target.id,
            trailing: capability == null
                ? null
                : PokeMapButton(
                    key: const ValueKey(
                      'dependency-inspector-replace-all',
                    ),
                    onPressed: () => onReplaceEverywhere!(capability),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(Icons.find_replace_rounded),
                    child: const Text('Remplacer partout'),
                  ),
          ),
          if (model.definitions.isEmpty) ...[
            const PokeMapCard(
              child: PokeMapEmptyState(
                title: 'Référence introuvable',
                description:
                    'Aucune définition canonique ne correspond à cette cible.',
                icon: Icon(Icons.link_off_rounded),
              ),
            ),
          ] else ...[
            _DefinitionsSection(model: model, onOpen: onOpen),
          ],
          const SizedBox(height: 12),
          _ConsumersSection(model: model, onOpen: onOpen),
          const SizedBox(height: 12),
          _DiagnosticsSection(model: model),
        ],
      ),
    );
  }

  NarrativeReferenceReplacementCapability? get _usableReplacementCapability {
    final capability = replacementCapability;
    if (capability == null || onReplaceEverywhere == null) return null;
    if (model.definitions.length != 1 ||
        model.definitions.single.key != model.target ||
        model.usages.any((usage) => usage.target != model.target) ||
        model.target.kind != NarrativeDependencyTargetKind.cinematic ||
        capability.source.kind != NarrativeDependencyTargetKind.cinematic ||
        capability.replacement.kind !=
            NarrativeDependencyTargetKind.cinematic ||
        capability.source != model.target) {
      return null;
    }

    final inspectedPaths = model.usages.map((usage) => usage.path).toList();
    if (!_hasExactPathCoverage(
      capability.coveredReferencePaths,
      inspectedPaths,
    )) {
      return null;
    }
    return capability;
  }
}

class _DefinitionsSection extends StatelessWidget {
  const _DefinitionsSection({required this.model, required this.onOpen});

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Définitions',
          description: _countLabel(
            model.definitions.length,
            singular: 'définition',
            plural: 'définitions',
          ),
        ),
        for (var index = 0; index < model.definitions.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _DefinitionCard(
            definition: model.definitions[index],
            index: index,
            onOpen: onOpen,
          ),
        ],
      ],
    );
  }
}

class _DefinitionCard extends StatelessWidget {
  const _DefinitionCard({
    required this.definition,
    required this.index,
    required this.onOpen,
  });

  final NarrativeDependencyDefinition definition;
  final int index;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = definition.navigationIntent;
    final canOpen = intent != null && onOpen != null;

    return PokeMapCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  definition.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (definition.owner != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Propriétaire : ${definition.owner!.id}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (definition.path case final path?) ...[
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canOpen) ...[
            const SizedBox(width: 8),
            PokeMapButton(
              key: ValueKey<Object>(
                (
                  'dependency-inspector-definition-open',
                  definition.key,
                  definition.path,
                ),
              ),
              onPressed: () => onOpen!(intent),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(Icons.open_in_new_rounded),
              child: const Text('Ouvrir'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsumersSection extends StatelessWidget {
  const _ConsumersSection({required this.model, required this.onOpen});

  final NarrativeDependencyInspectionReadModel model;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Consommateurs',
          description: _countLabel(
            model.usages.length,
            singular: 'consommateur',
            plural: 'consommateurs',
          ),
        ),
        if (model.usages.isEmpty)
          const PokeMapCard(
            child: PokeMapEmptyState(
              title: 'Aucun consommateur',
              description: 'Cette référence n’est utilisée par aucun contenu.',
              icon: Icon(Icons.hub_outlined),
            ),
          )
        else
          for (var index = 0; index < model.usages.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _ConsumerCard(
              usage: model.usages[index],
              index: index,
              onOpen: onOpen,
            ),
          ],
      ],
    );
  }
}

class _ConsumerCard extends StatelessWidget {
  const _ConsumerCard({
    required this.usage,
    required this.index,
    required this.onOpen,
  });

  final NarrativeDependencyUsage usage;
  final int index;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = usage.navigationIntent;
    final canOpen = intent != null && onOpen != null;

    return PokeMapCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        usage.owner.id,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PokeMapBadge(
                      label: _criticalityLabel(usage.criticality),
                      variant: _criticalityBadge(usage.criticality),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_kindLabel(usage.owner.kind)} · ${usage.path}',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (canOpen) ...[
            const SizedBox(width: 8),
            PokeMapButton(
              key: ValueKey<Object>(
                (
                  'dependency-inspector-consumer-open',
                  usage.target,
                  usage.owner,
                  usage.path,
                ),
              ),
              onPressed: () => onOpen!(intent),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(Icons.open_in_new_rounded),
              child: const Text('Ouvrir'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({required this.model});

  final NarrativeDependencyInspectionReadModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapSectionHeader(
          title: 'Diagnostics',
          description: _countLabel(
            model.issues.length,
            singular: 'diagnostic',
            plural: 'diagnostics',
          ),
        ),
        if (model.issues.isEmpty)
          const PokeMapCard(
            child: PokeMapEmptyState(
              title: 'Aucun diagnostic',
              description: 'Aucun problème de dépendance n’est détecté.',
              icon: Icon(Icons.check_circle_outline_rounded),
            ),
          )
        else
          for (var index = 0; index < model.issues.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: _diagnosticSeverity(model.issues[index].criticality),
              title: _issueTitle(model.issues[index].kind),
              message: model.issues[index].message,
            ),
          ],
      ],
    );
  }
}

bool _hasExactPathCoverage(List<String> covered, List<String> inspected) {
  if (covered.length != inspected.length) return false;
  final remaining = <String, int>{};
  for (final path in covered) {
    remaining.update(path, (count) => count + 1, ifAbsent: () => 1);
  }
  for (final path in inspected) {
    final count = remaining[path];
    if (count == null) return false;
    if (count == 1) {
      remaining.remove(path);
    } else {
      remaining[path] = count - 1;
    }
  }
  return remaining.isEmpty;
}

String _countLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  return '$count ${count == 1 ? singular : plural}';
}

String _criticalityLabel(NarrativeDependencyCriticality criticality) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational => 'Information',
    NarrativeDependencyCriticality.authoringWarning =>
      'Avertissement de création',
    NarrativeDependencyCriticality.runtimeBlocking =>
      'Bloquant pour l’exécution',
  };
}

PokeMapBadgeVariant _criticalityBadge(
  NarrativeDependencyCriticality criticality,
) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational => PokeMapBadgeVariant.info,
    NarrativeDependencyCriticality.authoringWarning =>
      PokeMapBadgeVariant.warning,
    NarrativeDependencyCriticality.runtimeBlocking => PokeMapBadgeVariant.error,
  };
}

PokeMapDiagnosticSeverity _diagnosticSeverity(
  NarrativeDependencyCriticality criticality,
) {
  return switch (criticality) {
    NarrativeDependencyCriticality.informational =>
      PokeMapDiagnosticSeverity.info,
    NarrativeDependencyCriticality.authoringWarning =>
      PokeMapDiagnosticSeverity.warning,
    NarrativeDependencyCriticality.runtimeBlocking =>
      PokeMapDiagnosticSeverity.error,
  };
}

String _issueTitle(NarrativeDependencyIssueKind kind) {
  return switch (kind) {
    NarrativeDependencyIssueKind.missingReference => 'Référence introuvable',
    NarrativeDependencyIssueKind.ambiguousReference => 'Référence ambiguë',
    NarrativeDependencyIssueKind.unavailableReference =>
      'Référence indisponible',
    NarrativeDependencyIssueKind.duplicateId => 'Identifiant dupliqué',
    NarrativeDependencyIssueKind.forbiddenCycle => 'Cycle interdit',
  };
}

String _kindLabel(NarrativeDependencyTargetKind kind) {
  return switch (kind) {
    NarrativeDependencyTargetKind.fact => 'Fact',
    NarrativeDependencyTargetKind.eventV2 => 'Événement',
    NarrativeDependencyTargetKind.scene => 'Scène',
    NarrativeDependencyTargetKind.dialogue => 'Dialogue',
    NarrativeDependencyTargetKind.cinematic => 'Cinématique',
    NarrativeDependencyTargetKind.storyline => 'Storyline',
    NarrativeDependencyTargetKind.chapter => 'Chapitre',
    NarrativeDependencyTargetKind.step => 'Étape',
    NarrativeDependencyTargetKind.worldRule => 'Règle du monde',
    NarrativeDependencyTargetKind.sourceMap => 'Source de map',
  };
}
```

### `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_card.dart';
import '../pokemap_empty_state.dart';
import '../pokemap_icon_button.dart';
import '../pokemap_search_field.dart';

/// Shared no-code picker for references exposed by the canonical dependency
/// index.
///
/// It deliberately selects existing project assets only. Physical map sources
/// continue to be authored in Map Editor and are never created from here.
class PokeMapNarrativeReferencePicker extends StatefulWidget {
  const PokeMapNarrativeReferencePicker({
    super.key,
    required this.label,
    required this.readModel,
    required this.selectedKey,
    required this.onSelected,
    this.onOpen,
    this.enabled = true,
    this.maxListHeight = 360,
  }) : assert(maxListHeight > 0);

  final String label;
  final CanonicalNarrativeReferencePickerReadModel readModel;
  final NarrativeDependencyKey? selectedKey;
  final ValueChanged<CanonicalNarrativeReferenceOption> onSelected;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;
  final bool enabled;
  final double maxListHeight;

  @override
  State<PokeMapNarrativeReferencePicker> createState() =>
      _PokeMapNarrativeReferencePickerState();
}

class _PokeMapNarrativeReferencePickerState
    extends State<PokeMapNarrativeReferencePicker> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'narrative-reference-search',
  );
  final Map<NarrativeDependencyKey, FocusNode> _optionFocusNodes =
      <NarrativeDependencyKey, FocusNode>{};
  String _query = '';

  CanonicalNarrativeReferencePickerReadModel get _visibleModel =>
      widget.readModel.search(_query);

  List<CanonicalNarrativeReferenceOption> get _visibleOptions =>
      _visibleModel.options.toList(growable: false);

  List<CanonicalNarrativeReferenceOption> get _availableVisibleOptions =>
      _visibleOptions
          .where(
            (option) =>
                option.availability == NarrativeReferenceAvailability.available,
          )
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _synchronizeFocusNodes(_visibleOptions.map((option) => option.key).toSet());
  }

  @override
  void didUpdateWidget(covariant PokeMapNarrativeReferencePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = _visibleOptions.map((option) => option.key).toSet();
    final focusedKey = _focusedOptionKey();
    if (!widget.enabled || (focusedKey != null && !keys.contains(focusedKey))) {
      _searchFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    _synchronizeFocusNodes(keys);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final node in _optionFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _synchronizeFocusNodes(Set<NarrativeDependencyKey> visibleKeys) {
    for (final key in visibleKeys) {
      _optionFocusNodes.putIfAbsent(
        key,
        () => FocusNode(debugLabel: 'narrative-reference-$key'),
      );
    }
    final removedKeys = _optionFocusNodes.keys
        .where((key) => !visibleKeys.contains(key))
        .toList(growable: false);
    for (final key in removedKeys) {
      _optionFocusNodes.remove(key)?.dispose();
    }
  }

  NarrativeDependencyKey? _focusedOptionKey() {
    for (final entry in _optionFocusNodes.entries) {
      if (entry.value.hasFocus) return entry.key;
    }
    return null;
  }

  void _handleQueryChanged(String value) {
    if (!widget.enabled) return;
    final focusedKey = _focusedOptionKey();
    final nextModel = widget.readModel.search(value);
    final nextKeys = nextModel.options.map((option) => option.key).toSet();
    if (focusedKey != null && !nextKeys.contains(focusedKey)) {
      _searchFocusNode.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    }
    setState(() {
      _query = value;
      _synchronizeFocusNodes(nextKeys);
    });
  }

  void _moveOptionFocus(int delta) {
    if (!widget.enabled) return;
    final options = _availableVisibleOptions;
    if (options.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }

    final currentKey = _focusedOptionKey();
    var currentIndex = options.indexWhere((option) => option.key == currentKey);
    if (currentIndex < 0) {
      currentIndex = delta > 0 ? -1 : 0;
    }
    final nextIndex = (currentIndex + delta) % options.length;
    _optionFocusNodes[options[nextIndex].key]?.requestFocus();
  }

  void _select(CanonicalNarrativeReferenceOption option) {
    if (!widget.enabled ||
        option.availability != NarrativeReferenceAvailability.available) {
      return;
    }
    widget.onSelected(option);
  }

  Future<void> _copy(CanonicalNarrativeReferenceOption option) async {
    if (!widget.enabled) return;
    await Clipboard.setData(ClipboardData(text: option.technicalId));
  }

  void _open(CanonicalNarrativeReferenceOption option) {
    if (!widget.enabled) return;
    final intent = option.navigationIntent;
    if (intent != null) widget.onOpen?.call(intent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final model = _visibleModel;
    final hasAnyResult = model.options.isNotEmpty ||
        model.missingSelection != null ||
        model.incompatibleSelection != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final referenceList = hasAnyResult
            ? ListView(
                shrinkWrap: !constraints.hasBoundedHeight,
                children: <Widget>[
                  if (model.incompatibleSelection
                      case final incompatible?) ...<Widget>[
                    _ExceptionalReferenceCard(
                      option: incompatible,
                      enabled: widget.enabled,
                      onCopy: () => _copy(incompatible),
                      onOpen: incompatible.navigationIntent != null &&
                              widget.onOpen != null
                          ? () => _open(incompatible)
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (model.missingSelection case final missing?) ...<Widget>[
                    _ExceptionalReferenceCard(
                      option: missing,
                      enabled: widget.enabled,
                      onCopy: () => _copy(missing),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final group in model.groups) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        group.label,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final option in group.options) ...<Widget>[
                      _buildOptionRow(context, option),
                      const SizedBox(height: 7),
                    ],
                    const SizedBox(height: 3),
                  ],
                ],
              )
            : const PokeMapEmptyState(
                title: 'Aucune référence disponible',
                description: 'Créez ou publiez une référence compatible.',
                icon: Icon(Icons.link_off_rounded),
              );
        final listRegion = constraints.hasBoundedHeight
            ? Expanded(child: referenceList)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxListHeight),
                child: referenceList,
              );

        return FocusTraversalGroup(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _moveOptionFocus(1),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _moveOptionFocus(-1),
              const SingleActivator(LogicalKeyboardKey.escape):
                  _searchFocusNode.requestFocus,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.enabled
                        ? colors.textPrimary
                        : colors.textDisabled,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                PokeMapSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  semanticLabel: 'Rechercher dans ${widget.label}',
                  hintText: 'Rechercher une référence…',
                  enabled: widget.enabled,
                  onChanged: _handleQueryChanged,
                  onClear: () => _handleQueryChanged(''),
                ),
                const SizedBox(height: 10),
                listRegion,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    CanonicalNarrativeReferenceOption option,
  ) {
    final focusNode = _optionFocusNodes[option.key]!;
    final isAvailable =
        option.availability == NarrativeReferenceAvailability.available;
    final canSelect = widget.enabled && isAvailable;
    focusNode
      ..canRequestFocus = canSelect
      ..skipTraversal = !canSelect;

    return FocusableActionDetector(
      key: ValueKey<NarrativeDependencyKey>(option.key),
      focusNode: focusNode,
      enabled: canSelect,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _select(option);
            return null;
          },
        ),
      },
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      child: ExcludeFocus(
        excluding: !widget.enabled,
        child: PokeMapCard(
          focused: focusNode.hasFocus,
          selected: widget.selectedKey == option.key,
          onTap: canSelect ? () => _select(option) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                container: true,
                enabled: widget.enabled && isAvailable,
                button: isAvailable,
                label: _semanticLabel(option),
                excludeSemantics: true,
                child: _OptionSummary(option: option),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  PokeMapBadge(
                    label: option.kindLabel,
                    variant: PokeMapBadgeVariant.narrative,
                  ),
                  PokeMapBadge(
                    label: _publicationLabel(option.publicationStatus),
                    variant: _publicationVariant(option.publicationStatus),
                  ),
                  if (option.usageCount > 0)
                    PokeMapBadge(label: '${option.usageCount} usages'),
                  PokeMapIconButton(
                    key: ValueKey<String>(_actionKey('copy', option.key)),
                    onPressed: widget.enabled ? () => _copy(option) : null,
                    tooltip: 'Copier l’identifiant ${option.technicalId}',
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  if (option.navigationIntent != null && widget.onOpen != null)
                    PokeMapIconButton(
                      key: ValueKey<String>(_actionKey('open', option.key)),
                      onPressed: widget.enabled ? () => _open(option) : null,
                      tooltip: 'Ouvrir ${option.label}',
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  PokeMapButton(
                    key: ValueKey<String>(_actionKey('select', option.key)),
                    onPressed: widget.enabled && isAvailable
                        ? () => _select(option)
                        : null,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    child: const Text('Choisir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSummary extends StatelessWidget {
  const _OptionSummary({required this.option});

  final CanonicalNarrativeReferenceOption option;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final breadcrumb = option.breadcrumbLabels.join(' › ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          option.label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          option.technicalId,
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        if (breadcrumb.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            breadcrumb,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
        if (option.diagnostic case final diagnostic?) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            diagnostic,
            style: TextStyle(
              color: option.availability ==
                      NarrativeReferenceAvailability.incompatible
                  ? colors.warning
                  : colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExceptionalReferenceCard extends StatelessWidget {
  const _ExceptionalReferenceCard({
    required this.option,
    required this.enabled,
    required this.onCopy,
    this.onOpen,
  });

  final CanonicalNarrativeReferenceOption option;
  final bool enabled;
  final VoidCallback onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isMissing =
        option.availability == NarrativeReferenceAvailability.missing;
    final statusLabel = isMissing ? 'Référence manquante' : 'Incompatible';
    return PokeMapCard(
      key: ValueKey<String>(isMissing
          ? 'narrative-reference-missing'
          : 'narrative-reference-incompatible-selection'),
      child: Semantics(
        container: true,
        label: '${option.label}, ${option.technicalId}, '
            '${isMissing ? 'manquante' : 'incompatible'}'
            '${option.diagnostic == null ? '' : ', ${option.diagnostic}'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isMissing ? Icons.link_off_rounded : Icons.block_rounded,
                  size: 16,
                  color: isMissing ? colors.error : colors.warning,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PokeMapBadge(
                  label: statusLabel,
                  variant: isMissing
                      ? PokeMapBadgeVariant.error
                      : PokeMapBadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    option.technicalId,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ),
                PokeMapIconButton(
                  key: ValueKey<String>(_actionKey('copy', option.key)),
                  onPressed: enabled ? onCopy : null,
                  tooltip: 'Copier l’identifiant ${option.technicalId}',
                  icon: const Icon(Icons.copy_rounded),
                ),
                if (onOpen != null)
                  PokeMapIconButton(
                    key: ValueKey<String>(_actionKey('open', option.key)),
                    onPressed: enabled ? onOpen : null,
                    tooltip: 'Ouvrir ${option.label}',
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
              ],
            ),
            if (option.diagnostic case final diagnostic?) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                diagnostic,
                style: TextStyle(
                  color: isMissing ? colors.error : colors.warning,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _semanticLabel(CanonicalNarrativeReferenceOption option) {
  final parts = <String>[
    option.label,
    option.technicalId,
    switch (option.availability) {
      NarrativeReferenceAvailability.available => 'disponible',
      NarrativeReferenceAvailability.incompatible => 'incompatible',
      NarrativeReferenceAvailability.missing => 'manquante',
    },
    if (option.breadcrumbLabels.isNotEmpty) option.breadcrumbLabels.join(' › '),
    if (option.diagnostic case final diagnostic?) diagnostic,
  ];
  return parts.join(', ');
}

String _publicationLabel(NarrativeReferencePublicationStatus status) {
  return switch (status) {
    NarrativeReferencePublicationStatus.published => 'Publié',
    NarrativeReferencePublicationStatus.draft => 'Brouillon',
    NarrativeReferencePublicationStatus.inactive => 'Inactif',
    NarrativeReferencePublicationStatus.legacy => 'Ancien format',
    NarrativeReferencePublicationStatus.unknown => 'Statut inconnu',
  };
}

PokeMapBadgeVariant _publicationVariant(
  NarrativeReferencePublicationStatus status,
) {
  return switch (status) {
    NarrativeReferencePublicationStatus.published =>
      PokeMapBadgeVariant.success,
    NarrativeReferencePublicationStatus.draft => PokeMapBadgeVariant.warning,
    NarrativeReferencePublicationStatus.inactive => PokeMapBadgeVariant.neutral,
    NarrativeReferencePublicationStatus.legacy => PokeMapBadgeVariant.warning,
    NarrativeReferencePublicationStatus.unknown => PokeMapBadgeVariant.error,
  };
}

String _actionKey(String action, NarrativeDependencyKey key) =>
    'narrative-reference-$action-${key.kind.name}-${key.id}-'
    '${key.scope ?? ''}-${key.parentId ?? ''}-${key.sourceKind ?? ''}';
```

### `packages/map_editor/test/ui/design_system/narrative_design_system_guardrail_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('direct color detector covers numeric and multiline constructors', () {
    for (final source in <String>[
      'Color(0xFF112233)',
      'Color.fromARGB(255, 1, 2, 3)',
      'Color.fromRGBO(1, 2, 3, 1)',
      'Color\n  .from(alpha: 1, red: 1, green: 1, blue: 1)',
      'Colors.red',
      'CupertinoColors.systemBlue',
      'MacosColors.controlAccentColor',
    ]) {
      expect(_directColorPattern.hasMatch(source), isTrue, reason: source);
    }
    expect(
        _directColorPattern.hasMatch('Color.lerp(left, right, 0.5)'), isFalse);
  });

  test('narrative design-system sources use semantic tokens and modern chrome',
      () {
    final root = Directory(
      p.join(Directory.current.path, 'lib', 'src', 'ui', 'design_system',
          'narrative'),
    );
    expect(root.existsSync(), isTrue,
        reason: 'The narrative design-system folder must exist.');

    final regressions = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath =
          p.relative(entity.path, from: Directory.current.path);
      final source = entity.readAsStringSync();
      for (final match in _directColorPattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        regressions.add('$relativePath:$line: ${match.group(0)}');
      }
      for (final match in _legacyChromePattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        regressions.add('$relativePath:$line: legacy chrome import');
      }
    }

    expect(
      regressions,
      isEmpty,
      reason: <String>[
        'Narrative design-system widgets must use context.pokeMapColors.',
        'They must not import legacy editor chrome.',
        ...regressions,
      ].join('\n'),
    );
  });
}

final _directColorPattern = RegExp(
  r'\bColor\s*(?:\(|\.\s*from[A-Za-z]*\s*\()|'
  r'\b(?:Colors|CupertinoColors|MacosColors)\s*\.',
  multiLine: true,
);

final _legacyChromePattern = RegExp(r'cupertino_editor_widgets\.dart');
```

### `packages/map_editor/test/ui/design_system/pokemap_dependency_inspector_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_dependency_inspector.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart';

void main() {
  const target = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.cinematic,
    'cinematic_intro',
  );
  const definitionIntent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.cinematic,
    assetId: 'cinematic_intro',
  );
  const firstConsumerIntent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.scene,
    assetId: 'scene_port',
    context: 'graph.nodes[cinematic_0]',
  );

  testWidgets(
    'shows target definitions consumers diagnostics and opens exact intents',
    (tester) async {
      final opened = <NarrativeDependencyNavigationIntent>[];
      final model = NarrativeDependencyInspectionReadModel(
        target: target,
        definitions: [
          NarrativeDependencyDefinition(
            key: target,
            label: 'Introduction du port',
            path: 'cinematics[cinematic_intro]',
            navigationIntent: definitionIntent,
          ),
        ],
        usages: const [
          NarrativeDependencyUsage(
            target: target,
            owner: NarrativeDependencyKey.scene('scene_port'),
            path:
                'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
            navigationIntent: firstConsumerIntent,
          ),
          NarrativeDependencyUsage(
            target: target,
            owner: NarrativeDependencyKey.scene('scene_market'),
            path:
                'scenes[scene_market].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          ),
        ],
        issues: const [
          NarrativeDependencyIssue(
            kind: NarrativeDependencyIssueKind.missingReference,
            target: target,
            owner: NarrativeDependencyKey.scene('scene_port'),
            path:
                'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
            message: 'La cinématique est requise par la scène du port.',
          ),
        ],
      );

      await _pumpInspector(
        tester,
        model: model,
        onOpen: opened.add,
      );

      expect(find.text('Introduction du port'), findsNWidgets(2));
      expect(find.text('cinematic_intro'), findsOneWidget);
      expect(find.text('1 définition'), findsOneWidget);
      expect(find.text('2 consommateurs'), findsOneWidget);
      expect(find.text('scene_port'), findsOneWidget);
      expect(find.text('scene_market'), findsOneWidget);
      expect(
        find.textContaining(
          'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
        ),
        findsOneWidget,
      );
      expect(find.text('Bloquant pour l’exécution'), findsWidgets);
      expect(find.text('Avertissement de création'), findsOneWidget);
      expect(
        find.text('La cinématique est requise par la scène du port.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-definition-open',
              target,
              'cinematics[cinematic_intro]',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-consumer-open',
              target,
              NarrativeDependencyKey.scene('scene_port'),
              'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(opened, [definitionIntent, firstConsumerIntent]);
      expect(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-consumer-open',
              target,
              NarrativeDependencyKey.scene('scene_market'),
              'scenes[scene_market].graph.nodes[cinematic_0].payload.cinematicId',
            ),
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders honest missing and ambiguous target states',
      (tester) async {
    final missing = NarrativeDependencyInspectionReadModel(
      target: const NarrativeDependencyKey.scene('scene_missing'),
      definitions: const [],
      usages: const [],
      issues: const [
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: NarrativeDependencyKey.scene('scene_missing'),
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'La scène ciblée n’existe pas.',
        ),
      ],
    );

    await _pumpInspector(tester, model: missing);

    expect(find.text('Référence introuvable'), findsWidgets);
    expect(find.text('scene_missing'), findsOneWidget);
    expect(find.text('La scène ciblée n’existe pas.'), findsOneWidget);

    final ambiguous = NarrativeDependencyInspectionReadModel(
      target: target,
      definitions: [
        NarrativeDependencyDefinition(
          key: target,
          label: 'Introduction du port',
          path: 'cinematics[0]',
        ),
        NarrativeDependencyDefinition(
          key: target,
          label: 'Introduction du phare',
          path: 'cinematics[1]',
        ),
      ],
      usages: const [],
      issues: const [
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.ambiguousReference,
          target: target,
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'Deux cinématiques utilisent le même identifiant.',
        ),
      ],
    );

    await _pumpInspector(tester, model: ambiguous);

    expect(find.text('Référence ambiguë'), findsWidgets);
    expect(find.text('Introduction du port'), findsOneWidget);
    expect(find.text('Introduction du phare'), findsOneWidget);
    expect(find.text('cinematics[0]'), findsOneWidget);
    expect(find.text('cinematics[1]'), findsOneWidget);
    expect(
      find.text('Deux cinématiques utilisent le même identifiant.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offers replace everywhere only for a genuine exactly-covered capability',
    (tester) async {
      final project = _referencedProject();
      final validation = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      );
      expect(validation, isA<NarrativeReferenceReplacementValidated>());
      final capability =
          (validation as NarrativeReferenceReplacementValidated).capability;
      final model = inspectNarrativeDependency(
        buildNarrativeDependencyIndex(project: project),
        capability.source,
      );
      NarrativeReferenceReplacementCapability? received;

      await _pumpInspector(tester, model: model);
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: model,
        replacementCapability: capability,
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: model,
        replacementCapability: capability,
        onReplaceEverywhere: (value) => received = value,
      );
      final action =
          find.byKey(const ValueKey('dependency-inspector-replace-all'));
      expect(action, findsOneWidget);

      await tester.tap(action);
      await tester.pump();

      expect(received, same(capability));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hides replace everywhere for another target or incomplete coverage',
    (tester) async {
      final project = _referencedProject();
      final validation = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      ) as NarrativeReferenceReplacementValidated;
      final capability = validation.capability;
      final inspected = inspectNarrativeDependency(
        buildNarrativeDependencyIndex(project: project),
        capability.source,
      );
      final incomplete = NarrativeDependencyInspectionReadModel(
        target: inspected.target,
        definitions: inspected.definitions,
        usages: inspected.usages.take(1).toList(),
        issues: inspected.issues,
      );
      final otherKind = NarrativeDependencyInspectionReadModel(
        target: const NarrativeDependencyKey.scene('cinematic_intro'),
        definitions: const [],
        usages: const [],
        issues: const [],
      );

      await _pumpInspector(
        tester,
        model: incomplete,
        replacementCapability: capability,
        onReplaceEverywhere: (_) {},
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: otherKind,
        replacementCapability: capability,
        onReplaceEverywhere: (_) {},
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'picker and inspector preserve a complete map child identity and intent',
    (tester) async {
      const portMap = NarrativeDependencyKey.map('map_port');
      const forestMap = NarrativeDependencyKey.map('map_forest');
      const portGuide = NarrativeDependencyKey.mapSource(
        mapId: 'map_port',
        sourceKind: 'entity',
        sourceId: 'guide',
      );
      const forestGuide = NarrativeDependencyKey.mapSource(
        mapId: 'map_forest',
        sourceKind: 'entity',
        sourceId: 'guide',
      );
      const forestIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'guide',
        parentId: 'map_forest',
        scope: 'map',
        sourceKind: 'entity',
        mapId: 'map_forest',
      );
      final index = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: portMap, label: 'Port'),
          NarrativeDependencyDefinition(key: forestMap, label: 'Forêt'),
          NarrativeDependencyDefinition(
            key: portGuide,
            label: 'Guide',
            owner: portMap,
            navigationIntent:
                NarrativeDependencyNavigationIntent.fromKey(portGuide),
          ),
          NarrativeDependencyDefinition(
            key: forestGuide,
            label: 'Guide',
            owner: forestMap,
            navigationIntent: forestIntent,
          ),
        ],
      );
      final pickerModel = buildCanonicalNarrativeReferencePickerReadModel(
        index: index,
        allowedKinds: const {NarrativeDependencyTargetKind.sourceMap},
      );
      CanonicalNarrativeReferenceOption? selected;

      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 540,
              height: 760,
              child: PokeMapNarrativeReferencePicker(
                label: 'PNJ déclencheur',
                readModel: pickerModel,
                selectedKey: null,
                onSelected: (option) => selected = option,
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey<NarrativeDependencyKey>(forestGuide),
        ),
      );
      await tester.pump();

      expect(selected?.key, forestGuide);
      expect(selected?.navigationIntent, forestIntent);
      expect(
        find.byKey(const ValueKey<NarrativeDependencyKey>(portGuide)),
        findsOneWidget,
      );
      expect(find.text('Créer'), findsNothing);

      final inspection = inspectNarrativeDependency(index, selected!.key);
      NarrativeDependencyNavigationIntent? opened;
      await _pumpInspector(
        tester,
        model: inspection,
        onOpen: (intent) => opened = intent,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-definition-open',
              forestGuide,
              null,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(opened, forestIntent);
      expect(opened, selected!.navigationIntent);
      expect(find.text('Créer'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpInspector(
  WidgetTester tester, {
  required NarrativeDependencyInspectionReadModel model,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
  NarrativeReferenceReplacementCapability? replacementCapability,
  ValueChanged<NarrativeReferenceReplacementCapability>? onReplaceEverywhere,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 680,
            child: PokeMapDependencyInspector(
              model: model,
              onOpen: onOpen,
              replacementCapability: replacementCapability,
              onReplaceEverywhere: onReplaceEverywhere,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _referencedProject() {
  return ProjectManifest(
    name: 'Dependency inspector test',
    maps: const [],
    tilesets: const [],
    cinematics: [
      _cinematic('cinematic_intro', 'Introduction du port'),
      _cinematic('cinematic_replacement', 'Introduction alternative'),
    ],
    scenes: [
      _sceneWithCinematic('scene_port', 'cinematic_intro'),
      _sceneWithCinematic('scene_market', 'cinematic_intro'),
    ],
  );
}

CinematicAsset _cinematic(String id, String title) {
  return CinematicAsset(
    id: id,
    title: title,
    timeline: CinematicTimeline(),
  );
}

SceneAsset _sceneWithCinematic(String id, String cinematicId) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start, title: 'Début'),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Cinématique',
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
    ),
  );
}
```

### `packages/map_editor/test/ui/design_system/pokemap_narrative_reference_picker_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart';
import 'package:map_editor/src/ui/design_system/pokemap_search_field.dart';

void main() {
  const sceneKey = NarrativeDependencyKey.scene('scene_port_a');
  const secondSceneKey = NarrativeDependencyKey.scene('scene_port_b');
  const incompatibleKey = NarrativeDependencyKey.scene('scene_other_scope');
  const missingKey = NarrativeDependencyKey.scene('scene_missing');
  const mapChildA = NarrativeDependencyKey.mapSource(
    mapId: 'map_port',
    sourceKind: 'entity',
    sourceId: 'shared_npc',
  );
  const mapChildB = NarrativeDependencyKey.mapSource(
    mapId: 'map_forest',
    sourceKind: 'entity',
    sourceId: 'shared_npc',
  );

  testWidgets('shows an honest empty state', (tester) async {
    await _pumpPicker(
      tester,
      readModel: CanonicalNarrativeReferencePickerReadModel(
        groups: const <CanonicalNarrativeReferenceGroup>[],
        missingSelection: null,
      ),
    );

    expect(find.text('Aucune référence disponible'), findsOneWidget);
    expect(find.text('Créez ou publiez une référence compatible.'),
        findsOneWidget);
  });

  testWidgets('shows readable labels, technical IDs and a broken selection',
      (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: secondSceneKey,
            label: 'Rencontre',
            publicationStatus: NarrativeReferencePublicationStatus.draft,
          ),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
        missingSelection: _option(
          key: missingKey,
          label: 'Référence introuvable',
          availability: NarrativeReferenceAvailability.missing,
          diagnostic: 'La scène sélectionnée n’existe plus.',
        ),
      ),
      selectedKey: missingKey,
    );

    expect(find.text('Rencontre'), findsNWidgets(2));
    expect(find.text('scene_port_a'), findsOneWidget);
    expect(find.text('Port Selbrume'), findsWidgets);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('narrative-reference-missing')),
      findsOneWidget,
    );
    expect(find.text('scene_missing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Disponible dans une autre portée'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Disponible dans une autre portée'), findsOneWidget);
  });

  testWidgets('search delegates to the canonical read model', (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: secondSceneKey,
            label: 'Embuscade',
            diagnostic: 'Combat optionnel',
          ),
        ],
      ),
    );

    await tester.enterText(find.byType(TextField), 'scene_port_a');
    await tester.pump();

    expect(find.text('Rencontre'), findsOneWidget);
    expect(find.text('Embuscade'), findsNothing);

    await tester.enterText(find.byType(TextField), 'combat optionnel');
    await tester.pump();

    expect(find.text('Rencontre'), findsNothing);
    expect(find.text('Embuscade'), findsOneWidget);
  });

  testWidgets('selects available rows but never incompatible rows',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    await tester
        .tap(find.byKey(const ValueKey<NarrativeDependencyKey>(sceneKey)));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<NarrativeDependencyKey>(incompatibleKey)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, <NarrativeDependencyKey>[sceneKey]);
    expect(_hasFocus(tester, incompatibleKey), isFalse);
  });

  testWidgets('copies the technical ID of a broken reference', (tester) async {
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: const <CanonicalNarrativeReferenceOption>[],
        missingSelection: _option(
          key: missingKey,
          label: 'Référence introuvable',
          availability: NarrativeReferenceAvailability.missing,
          diagnostic: 'La scène sélectionnée n’existe plus.',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Copier l’identifiant scene_missing'));
    await tester.pump();

    expect(
      platformCalls
          .singleWhere((call) => call.method == 'Clipboard.setData')
          .arguments,
      <String, dynamic>{'text': 'scene_missing'},
    );
  });

  testWidgets('opens a navigable existing selection filtered as incompatible',
      (tester) async {
    const intent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_other_scope',
    );
    final opened = <NarrativeDependencyNavigationIntent>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: const <CanonicalNarrativeReferenceOption>[],
        incompatibleSelection: _option(
          key: incompatibleKey,
          label: 'Rencontre lointaine',
          availability: NarrativeReferenceAvailability.incompatible,
          diagnostic: 'Ce type n’est pas autorisé ici.',
          navigationIntent: intent,
        ),
      ),
      onOpen: opened.add,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'narrative-reference-incompatible-selection',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Ouvrir Rencontre lointaine'));
    await tester.pump();

    expect(opened, const <NarrativeDependencyNavigationIntent>[intent]);
  });

  testWidgets('copies technical IDs and opens only navigable options',
      (tester) async {
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final opened = <NarrativeDependencyNavigationIntent>[];
    const navigationIntent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_port_a',
    );

    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: sceneKey,
            label: 'Rencontre',
            navigationIntent: navigationIntent,
          ),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
      onOpen: opened.add,
    );

    await tester.tap(find.byTooltip('Copier l’identifiant scene_port_a'));
    await tester.pump();
    await tester.tap(find.byTooltip('Ouvrir Rencontre'));
    await tester.pump();

    expect(
      platformCalls.where((call) => call.method == 'Clipboard.setData'),
      hasLength(1),
    );
    expect(
      platformCalls
          .singleWhere((call) => call.method == 'Clipboard.setData')
          .arguments,
      <String, dynamic>{'text': 'scene_port_a'},
    );
    expect(opened, <NarrativeDependencyNavigationIntent>[navigationIntent]);
    expect(find.byTooltip('Ouvrir Embuscade'), findsNothing);
  });

  testWidgets(
      'Arrow keys cycle available options, Enter selects and Escape returns to search',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Hors portée',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, secondSceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_hasFocus(tester, secondSceneKey), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, <NarrativeDependencyKey>[secondSceneKey]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
  });

  testWidgets('full dependency keys avoid map-child key and focus collisions',
      (tester) async {
    final selected = <NarrativeDependencyKey>[];
    await _pumpPicker(
      tester,
      readModel: _readModel(
        groupLabel: 'Éléments de map',
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: mapChildA,
            label: 'Guide',
            kindLabel: 'PNJ',
            breadcrumbLabels: const <String>['Port Selbrume'],
          ),
          _option(
            key: mapChildB,
            label: 'Guide',
            kindLabel: 'PNJ',
            breadcrumbLabels: const <String>['Forêt Brumeuse'],
          ),
        ],
      ),
      onSelected: (option) => selected.add(option.key),
    );

    final portFinder =
        find.byKey(const ValueKey<NarrativeDependencyKey>(mapChildA));
    final forestFinder =
        find.byKey(const ValueKey<NarrativeDependencyKey>(mapChildB));
    expect(portFinder, findsOneWidget);
    expect(forestFinder, findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, mapChildA), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, mapChildB), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, <NarrativeDependencyKey>[mapChildB]);
  });

  testWidgets(
      'filtering retains a surviving full-key focus or returns to search',
      (tester) async {
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(key: secondSceneKey, label: 'Embuscade'),
        ],
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    tester
        .widget<PokeMapSearchField>(find.byType(PokeMapSearchField))
        .onChanged(
          'scene_port_a',
        );
    await tester.pump();
    expect(_hasFocus(tester, sceneKey), isTrue);

    tester
        .widget<PokeMapSearchField>(find.byType(PokeMapSearchField))
        .onChanged(
          'absent',
        );
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
  });

  testWidgets('disabled picker blocks search, focus, selection, copy and open',
      (tester) async {
    final selected = <CanonicalNarrativeReferenceOption>[];
    final opened = <NarrativeDependencyNavigationIntent>[];
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    const intent = NarrativeDependencyNavigationIntent(
      kind: NarrativeDependencyTargetKind.scene,
      assetId: 'scene_port_a',
    );
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(
            key: sceneKey,
            label: 'Rencontre',
            navigationIntent: intent,
          ),
        ],
      ),
      enabled: false,
      onSelected: selected.add,
      onOpen: opened.add,
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester
        .tap(find.byKey(const ValueKey<NarrativeDependencyKey>(sceneKey)));
    await tester.tap(find.byTooltip('Copier l’identifiant scene_port_a'));
    await tester.tap(find.byTooltip('Ouvrir Rencontre'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, isEmpty);
    expect(opened, isEmpty);
    expect(
      platformCalls.where((call) => call.method == 'Clipboard.setData'),
      isEmpty,
    );
    expect(_hasFocus(tester, sceneKey), isFalse);
  });

  testWidgets('semantics announce label, ID, availability and exact reason',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpPicker(
      tester,
      readModel: _readModel(
        options: <CanonicalNarrativeReferenceOption>[
          _option(key: sceneKey, label: 'Rencontre'),
          _option(
            key: incompatibleKey,
            label: 'Rencontre lointaine',
            availability: NarrativeReferenceAvailability.incompatible,
            diagnostic: 'Disponible dans une autre portée',
          ),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Rencontre, scene_port_a, disponible, Port Selbrume',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Rencontre lointaine, scene_other_scope, incompatible, '
        'Port Selbrume, Disponible dans une autre portée',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('supports an unbounded scrolling parent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PokeMapNarrativeReferencePicker(
              label: 'Référence narrative',
              readModel: _readModel(
                options: <CanonicalNarrativeReferenceOption>[
                  _option(key: sceneKey, label: 'Rencontre'),
                ],
              ),
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Rencontre'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a compact bounded height with a scrollable long list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 220,
            child: PokeMapNarrativeReferencePicker(
              label: 'Référence narrative',
              readModel: _readModel(
                options: <CanonicalNarrativeReferenceOption>[
                  for (var index = 0; index < 8; index++)
                    _option(
                      key: NarrativeDependencyKey.scene('scene_$index'),
                      label: 'Scène $index',
                    ),
                ],
              ),
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

bool _hasFocus(WidgetTester tester, NarrativeDependencyKey key) {
  return tester
          .widget<FocusableActionDetector>(
            find.byKey(ValueKey<NarrativeDependencyKey>(key)),
          )
          .focusNode
          ?.hasFocus ??
      false;
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required CanonicalNarrativeReferencePickerReadModel readModel,
  NarrativeDependencyKey? selectedKey,
  ValueChanged<CanonicalNarrativeReferenceOption>? onSelected,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
  bool enabled = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 520,
          height: 720,
          child: PokeMapNarrativeReferencePicker(
            label: 'Référence narrative',
            readModel: readModel,
            selectedKey: selectedKey,
            enabled: enabled,
            onSelected: onSelected ?? (_) {},
            onOpen: onOpen,
          ),
        ),
      ),
    ),
  );
}

CanonicalNarrativeReferencePickerReadModel _readModel({
  required List<CanonicalNarrativeReferenceOption> options,
  String groupLabel = 'Scenes',
  CanonicalNarrativeReferenceOption? missingSelection,
  CanonicalNarrativeReferenceOption? incompatibleSelection,
}) {
  return CanonicalNarrativeReferencePickerReadModel(
    groups: <CanonicalNarrativeReferenceGroup>[
      CanonicalNarrativeReferenceGroup(label: groupLabel, options: options),
    ],
    missingSelection: missingSelection,
    incompatibleSelection: incompatibleSelection,
  );
}

CanonicalNarrativeReferenceOption _option({
  required NarrativeDependencyKey key,
  required String label,
  String kindLabel = 'Scene',
  List<String> breadcrumbLabels = const <String>['Port Selbrume'],
  NarrativeReferencePublicationStatus publicationStatus =
      NarrativeReferencePublicationStatus.published,
  NarrativeReferenceAvailability availability =
      NarrativeReferenceAvailability.available,
  String? diagnostic,
  NarrativeDependencyNavigationIntent? navigationIntent,
}) {
  return CanonicalNarrativeReferenceOption(
    key: key,
    label: label,
    technicalId: key.id,
    kindLabel: kindLabel,
    groupLabel: 'Scenes',
    breadcrumbLabels: breadcrumbLabels,
    publicationStatus: publicationStatus,
    availability: availability,
    diagnostic: diagnostic,
    navigationIntent: navigationIntent,
    usageCount: 0,
  );
}
```


