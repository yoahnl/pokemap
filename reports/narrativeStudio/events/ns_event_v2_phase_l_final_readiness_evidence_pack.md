# NS-EVENT-V2 Phase L — Final Readiness Gate — Evidence Pack

> **Réconciliation terminale L6 — 2026-07-17.** Cette section supersède L5 et
> tous les constats historiques d’analyzers ou suites rouges. Elle décrit les
> octets courants après la campagne corrective complète.

## L6.1 Verdict terminal

- Feature Event Builder V2 : **terminée**.
- Matrice technique L2 : **verte**.
- L2 formel : **BLOCKED** pour deux prérequis de publication : les octets
  validés ne disposent pas encore d’un checkpoint Git nouvellement autorisé et
  le corpus graphique approuvé n’est pas reproductible depuis un checkout nu.
- L3 : **DONE — décision NO-GO publication**.
- V1 : conservé ; aucune suppression ou dépréciation implicite.

Il ne reste aucun lot fonctionnel. L2 pourra être requalifié en `DONE` après un
checkpoint explicite **et** après versionnement/archivage restauré du corpus, ou
après une waiver release explicite acceptant ces deux tests externes.

## L6.2 Audit final et verdicts indépendants

| Passe | Verdict | Action |
|---|---|---|
| Audit / Architecture | PASS source-first ; NO-GO publication | séparation Map/source/Event/Scene confirmée |
| Implémentation | PASS après correction | trois callbacks vides du shell remplacés par des contrôles désactivés |
| Tests | PASS technique | six packages verts ; pipelines externes rejoués avec le corpus approuvé |
| Build / Validation | PASS | analyzes propres ; builds macOS editor et host verts |
| Critique UX/visuelle | GO K | aucun P0/P1/P2 actionnable à 1672 × 941 |
| Critique release | BLOCKERS opérationnels | checkpoint final absent et corpus hors checkout |

La revue a correctement refusé un GO prématuré pour trois raisons. Deux sont
fermées dans cette passe :

1. recherche, notifications et réglages étaient visuellement actifs avec
   `onPressed: () {}` ; ils sont maintenant honnêtement désactivés et couverts
   par le test route produit ;
2. deux pipelines Selbrume apparaissaient `skipped` faute du corpus non
   versionné dans le checkout ; la source approuvée a été retrouvée sous
   `/Users/karim/Documents/playable_projects/selbrume/assets/sources/v2`, ses
   `68/68` hashes correspondent au manifeste, puis les deux pipelines ont été
   exécutés avec succès via une liaison temporaire retirée après le test.

Les deux prérequis restants ne peuvent pas être fermés sans élargir l’autorité :
la DoD exige un commit autorisé ou une archive autonome approuvée, tandis que
le corpus doit être versionné/archivé ou faire l’objet d’une waiver release.
Aucune de ces décisions ne peut être créée implicitement.

## L6.3 Matrice complète fraîche

| Package | Tests | Analyse | Build / smoke |
|---|---|---|---|
| `map_core` | `+3000`, all passed | no issues | N/A Dart pur |
| `map_gameplay` | `+283`, all passed | no issues | N/A Dart pur |
| `map_battle` | `+1720`, all passed | no issues | N/A Dart pur |
| `map_runtime` | `+1778 ~1`, aucun échec | no issues | smoke Phase A `+3` |
| `map_editor` | `3162` succès, `0` échec, `2` skips dans la passe globale ; skips rejoués ci-dessous | no issues | macOS debug built |
| host jouable | `+55`, all passed | no issues | macOS debug built ; smoke `+1` |

Fermeture des deux skips de corpus :

```text
matched=68 mismatched_or_missing=0

flutter test --no-pub --concurrency=1 \
  test/selbrume_visual_kit_builder_test.dart \
  test/selbrume_port_props_pack_builder_test.dart

+3: All tests passed!
```

### L6.3.1 Commandes littérales de la matrice fraîche

| Répertoire | Commande | Résultat exact |
|---|---|---|
| `packages/map_core` | `dart test` | exit `0`, `+3000`, all passed |
| `packages/map_core` | `dart analyze` | exit `0`, no issues |
| `packages/map_gameplay` | `dart test` | exit `0`, `+283`, all passed |
| `packages/map_gameplay` | `dart analyze` | exit `0`, no issues |
| `packages/map_battle` | `dart test` | exit `0`, `+1720`, all passed |
| `packages/map_battle` | `dart analyze` | exit `0`, no issues |
| `packages/map_runtime` | `flutter test --no-pub` | exit `0`, `+1778 ~1`, aucun échec |
| `packages/map_runtime` | `flutter analyze --no-pub` | exit `0`, no issues |
| `packages/map_runtime` | `flutter test test/phase_a_golden_battle_slice_smoke_test.dart` | exit `0`, `+3`, all passed |
| `packages/map_editor` | `flutter test --no-pub --reporter=json` | exit `0`, `3162` succès, `0` échec, `2` skips externes ensuite rejoués |
| `packages/map_editor` | `flutter analyze --no-pub` | exit `0`, no issues |
| `packages/map_editor` | `flutter build macos --debug --no-pub` | exit `0`, app built |
| `examples/playable_runtime_host` | `flutter test --no-pub` | exit `0`, `+55`, all passed |
| `examples/playable_runtime_host` | `flutter analyze --no-pub` | exit `0`, no issues |
| `examples/playable_runtime_host` | `flutter test test/phase_a_golden_slice_launch_test.dart` | exit `0`, `+1`, all passed |
| `examples/playable_runtime_host` | `flutter build macos --debug --no-pub` | exit `0`, app built |

Les commandes sont package-scoped. Les résultats historiques rouges plus bas
sont conservés uniquement pour expliquer les lots correctifs et ne décrivent
plus le checkout courant.


## Annexe terminale L6 — contenu complet des fichiers texte créés

### `packages/map_editor/lib/src/application/models/pokemon_sdk_studio_project_payload.dart`

```dart
final class PokemonSdkStudioProjectPayload {
  PokemonSdkStudioProjectPayload({
    required List<Map<String, dynamic>> moves,
    required List<Map<String, dynamic>> abilities,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> types,
    required List<Map<String, dynamic>> pokemon,
  })  : moves = _freezeJsonMaps(moves),
        abilities = _freezeJsonMaps(abilities),
        items = _freezeJsonMaps(items),
        types = _freezeJsonMaps(types),
        pokemon = _freezeJsonMaps(pokemon);

  final List<Map<String, dynamic>> moves;
  final List<Map<String, dynamic>> abilities;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> types;
  final List<Map<String, dynamic>> pokemon;
}

List<Map<String, dynamic>> _freezeJsonMaps(
  List<Map<String, dynamic>> entries,
) {
  return List<Map<String, dynamic>>.unmodifiable(
    entries.map(
      (entry) => Map<String, dynamic>.unmodifiable(_copyJsonMap(entry)),
    ),
  );
}

Map<String, dynamic> _copyJsonMap(Map<String, dynamic> source) {
  return source.map((key, value) => MapEntry(key, _copyJsonValue(value)));
}

Object? _copyJsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_copyJsonValue));
  }
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.cast<String, dynamic>().map(
            (key, nestedValue) => MapEntry(key, _copyJsonValue(nestedValue)),
          ),
    );
  }
  return value;
}
```

### `packages/map_editor/lib/src/application/ports/pokemon_sdk_studio_project_source.dart`

```dart
import '../models/pokemon_sdk_studio_project_payload.dart';

abstract interface class PokemonSdkStudioProjectSource {
  Future<PokemonSdkStudioProjectPayload> loadProject(String projectRootPath);
}
```

### `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_shell.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

/// Geometry keys shared by the production route and its pixel-contract tests.
///
/// Keeping them here prevents the visual harness from proving a shell that the
/// shipped route never mounts — the exact regression K2-R is meant to avoid.
const eventBuilderV2ProductShellKey =
    ValueKey<String>('event-builder-v2-product-shell');
const eventBuilderV2ProductShellHeaderKey =
    ValueKey<String>('event-builder-v2-product-shell-header');
const eventBuilderV2ProductShellContextBarKey =
    ValueKey<String>('event-builder-v2-product-shell-context-bar');
const eventBuilderV2ProductShellProjectKey =
    ValueKey<String>('event-builder-v2-product-shell-project');
const eventBuilderV2ProductShellNavigationKey =
    ValueKey<String>('event-builder-v2-product-shell-navigation');
const eventBuilderV2ProductShellWorkspaceKey =
    ValueKey<String>('event-builder-v2-product-shell-workspace');

/// Reference-aligned desktop shell used only by Event Builder V2.
///
/// The generic map-authoring chrome remains the correct home for every other
/// workspace. Event V2 needs a project-wide canvas, however, so nesting it in
/// the map toolbar, collapsed explorer and a second Narrative sidebar both
/// misrepresents ownership and removes roughly 400 px from its graph. This
/// shell restores the single navigation hierarchy visible in the north-star
/// while leaving Event data, Map-owned sources and Scene-owned projections to
/// the existing product route below it.
class EventBuilderV2ProductShell extends StatelessWidget {
  const EventBuilderV2ProductShell({
    super.key,
    required this.projectName,
    required this.workspace,
    required this.onOpenOverview,
    required this.onOpenStorylines,
    required this.onOpenMaps,
    required this.onOpenScenes,
    required this.onOpenEvents,
    required this.onOpenCinematics,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onValidate,
    this.onPreview,
    this.appMark,
    this.projectIsDirty = false,
  });

  final String projectName;
  final Widget workspace;
  final VoidCallback onOpenOverview;
  final VoidCallback onOpenStorylines;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenScenes;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenCinematics;
  final VoidCallback onOpenDialogues;
  final VoidCallback onOpenFacts;
  final VoidCallback onOpenWorldRules;
  final VoidCallback onValidate;
  final VoidCallback? onPreview;
  final Widget? appMark;
  final bool projectIsDirty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final navigationWidth = _navigationWidth(viewportWidth);
        final businessStart = 8 + navigationWidth + 8;
        final rightMargin = viewportWidth == 1672 ? 9.0 : 8.0;

        return Semantics(
          key: eventBuilderV2ProductShellKey,
          container: true,
          label: 'PokeMap, Narrative Studio, Event Builder',
          child: ColoredBox(
            color: colors.chromeBackground,
            child: Column(
              children: [
                _ProductHeader(appMark: appMark),
                SizedBox(
                  height: 52,
                  child: ColoredBox(
                    color: colors.chromeBackground,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: businessStart,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 9, 8),
                            child: PokeMapCard(
                              key: eventBuilderV2ProductShellProjectKey,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'assets/branding/'
                                      'pokemap_event_builder_project_thumb.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      projectName.trim().isEmpty
                                          ? 'Projet PokeMap'
                                          : projectName.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 11,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            key: eventBuilderV2ProductShellContextBarKey,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: colors.topBarBackground,
                              border: Border(
                                bottom: BorderSide(color: colors.divider),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.house,
                                  size: 14,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Narrative Studio  /  Event Builder',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.brandPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (viewportWidth >= 1480) ...[
                                  PokeMapButton(
                                    key: const ValueKey(
                                      'event-builder-v2-new-storyline',
                                    ),
                                    onPressed: onOpenStorylines,
                                    // Match the reference toolbar's quiet
                                    // success treatment. A solid fill here
                                    // made the primary navigation compete with
                                    // the editor's actual save/validation cues.
                                    size: PokeMapButtonSize.compact,
                                    variant:
                                        PokeMapButtonVariant.successOutline,
                                    leading: const Icon(CupertinoIcons.add),
                                    child: const Text('Nouvelle storyline'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                PokeMapButton(
                                  key: const ValueKey(
                                    'event-builder-v2-preview-project',
                                  ),
                                  onPressed: onPreview,
                                  size: PokeMapButtonSize.compact,
                                  variant: PokeMapButtonVariant.secondary,
                                  leading: const Icon(CupertinoIcons.eye),
                                  child: const Text('Aperçu'),
                                ),
                                const SizedBox(width: 8),
                                PokeMapButton(
                                  key: const ValueKey(
                                    'event-builder-v2-validate-project',
                                  ),
                                  onPressed: onValidate,
                                  size: PokeMapButtonSize.compact,
                                  variant: PokeMapButtonVariant.successOutline,
                                  leading: const Icon(
                                    CupertinoIcons.checkmark_shield,
                                  ),
                                  child: const Text('Valider'),
                                ),
                                const SizedBox(width: 8),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-search-project',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Recherche bientôt disponible',
                                  icon: Icon(CupertinoIcons.search),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                                const SizedBox(width: 5),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-project-notifications',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Notifications bientôt disponibles',
                                  icon: Icon(CupertinoIcons.bell),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                                const SizedBox(width: 5),
                                const PokeMapIconButton(
                                  key: ValueKey(
                                    'event-builder-v2-project-settings',
                                  ),
                                  onPressed: null,
                                  tooltip: 'Réglages bientôt disponibles',
                                  icon: Icon(CupertinoIcons.gear),
                                  variant: PokeMapIconButtonVariant.soft,
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: rightMargin,
                      bottom: 22,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          key: eventBuilderV2ProductShellNavigationKey,
                          width: navigationWidth,
                          child: _ProductNavigation(
                            onOpenOverview: onOpenOverview,
                            onOpenStorylines: onOpenStorylines,
                            onOpenMaps: onOpenMaps,
                            onOpenScenes: onOpenScenes,
                            onOpenEvents: onOpenEvents,
                            onOpenCinematics: onOpenCinematics,
                            onOpenDialogues: onOpenDialogues,
                            onOpenFacts: onOpenFacts,
                            onOpenWorldRules: onOpenWorldRules,
                            onValidate: onValidate,
                            projectIsDirty: projectIsDirty,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            key: eventBuilderV2ProductShellWorkspaceKey,
                            child: workspace,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({this.appMark});

  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      key: eventBuilderV2ProductShellHeaderKey,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.topBarBackground,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: appMark ??
                Image.asset(
                  'assets/branding/pokemap_event_builder_mark.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
          ),
          const SizedBox(width: 10),
          Text(
            'PokeMap',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          const PokeMapBadge(
            label: 'beta',
            variant: PokeMapBadgeVariant.info,
          ),
        ],
      ),
    );
  }
}

class _ProductNavigation extends StatelessWidget {
  const _ProductNavigation({
    required this.onOpenOverview,
    required this.onOpenStorylines,
    required this.onOpenMaps,
    required this.onOpenScenes,
    required this.onOpenEvents,
    required this.onOpenCinematics,
    required this.onOpenDialogues,
    required this.onOpenFacts,
    required this.onOpenWorldRules,
    required this.onValidate,
    required this.projectIsDirty,
  });

  final VoidCallback onOpenOverview;
  final VoidCallback onOpenStorylines;
  final VoidCallback onOpenMaps;
  final VoidCallback onOpenScenes;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenCinematics;
  final VoidCallback onOpenDialogues;
  final VoidCallback onOpenFacts;
  final VoidCallback onOpenWorldRules;
  final VoidCallback onValidate;
  final bool projectIsDirty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-overview'),
            icon: CupertinoIcons.house,
            label: 'Aperçu',
            onTap: onOpenOverview,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-storylines'),
            icon: CupertinoIcons.rectangle_grid_1x2,
            label: 'Storylines',
            onTap: onOpenStorylines,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-maps'),
            icon: CupertinoIcons.map,
            label: 'Maps',
            onTap: onOpenMaps,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-scenes'),
            icon: CupertinoIcons.photo,
            label: 'Scenes',
            onTap: onOpenScenes,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-events'),
            icon: CupertinoIcons.bolt_horizontal_circle,
            label: 'Événements',
            selected: true,
            onTap: onOpenEvents,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-cinematics'),
            icon: CupertinoIcons.film,
            label: 'Cinématiques',
            onTap: onOpenCinematics,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-dialogues'),
            icon: CupertinoIcons.text_bubble,
            label: 'Dialogues',
            onTap: onOpenDialogues,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-facts'),
            icon: CupertinoIcons.doc_text,
            label: 'Facts',
            onTap: onOpenFacts,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-world-rules'),
            icon: CupertinoIcons.checkmark_shield,
            label: 'World Rules',
            onTap: onOpenWorldRules,
          ),
          _NavigationItem(
            key: const ValueKey('event-builder-v2-product-nav-validator'),
            icon: CupertinoIcons.shield,
            label: 'Validateur',
            onTap: onValidate,
            trailing: const PokeMapBadge(
              label: '3',
              variant: PokeMapBadgeVariant.success,
            ),
          ),
          const Spacer(),
          const PokeMapCard(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(CupertinoIcons.chart_bar, size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Project Health',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
                PokeMapStatusLabel(
                  label: 'Bon',
                  tone: PokeMapTone.success,
                  icon: CupertinoIcons.circle_fill,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.circle_fill,
                size: 7,
                color: projectIsDirty ? colors.warning : colors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  projectIsDirty
                      ? 'Modifications non enregistrées'
                      : 'Tous les changements enregistrés',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: PokeMapSidebarItem(
        icon: Icon(icon),
        label: label,
        compact: true,
        trailing: trailing,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

double _navigationWidth(double viewportWidth) {
  if (viewportWidth >= 1672) return 191;
  if (viewportWidth >= 1480) return 176;
  return 168;
}
```

### `reports/narrativeStudio/events/ns_event_v2_s0_stabilization_baseline.md`

```markdown
# NS-EVENT-V2 — S0 Stabilization Baseline

Date d'ouverture : 2026-07-17

Lot exact : `S0 — Stabiliser et sécuriser l'état courant`

Statut courant : `DONE`

## Résumé exécutif

Le checkpoint de départ Event Builder V2 est récupérable dans le commit
`11c956ac2c37be15fe07c708443ecf7a39b1663b`
(`feat(events): complete Event Builder V2 workflow`). Le commit porte 240
fichiers, 270489 insertions et 733 suppressions. Les neuf éléments initiaux ont
été attribués ; les failure artifacts et le lock orphelin ont été supprimés.
S0 est donc fermé. Le checkpoint final et la reproductibilité du corpus
graphique relèvent de L2 et restent les deux conditions opérationnelles ouvertes.

## Scope et non-objectifs

S0 attribue le checkout, élimine les artefacts orphelins, réconcilie la
documentation avec le checkpoint et enregistre les baselines. Il n'ajoute
aucun comportement Event, Scene, Map ou runtime. Les corrections visuelles et
release appartiennent respectivement à K2 et aux lots correctifs précédant L2.

## Audit initial

État observé au début de la campagne cinq lots :

- branche : `main` ;
- HEAD : `11c956ac2c37be15fe07c708443ecf7a39b1663b` ;
- modifications suivies : aucune ;
- éléments non suivis : neuf ;
- `git diff --check` : exit `0` ;
- le plan d'exécution local sous `docs/superpowers/plans/` est ignoré par la
  règle historique `.gitignore:7:/docs/*` et n'est pas un livrable Git S0.

## Attribution des neuf éléments initiaux

| Élément | Attribution | Décision |
|---|---|---|
| 4 PNG `test/failures/ns_scenes_v1_39_*` | artefacts golden Scene étrangers à Event V2 | supprimés, non publiables |
| 4 PNG `test/ui/canvas/failures/event_builder_v2_product_route_1672x941_*` | comparaison golden RED K2 | conservés pendant l'itération K2, à supprimer après GREEN |
| `selbrume/.pokemap-project-1f1a60297a27b0b0.lock` | lock éditeur local vide et orphelin | `lsof` sans propriétaire, supprimé |

## Références visuelles gelées

| Fichier | SHA-256 |
|---|---|
| North star `1 - événements.png` | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |
| Produit avant nouvelle itération K2 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |

## Commandes initiales et résultats exacts

```text
git show --shortstat --oneline HEAD
11c956ac feat(events): complete Event Builder V2 workflow
240 files changed, 270489 insertions(+), 733 deletions(-)

lsof selbrume/.pokemap-project-1f1a60297a27b0b0.lock
exit 1, aucun processus propriétaire

git diff --check
exit 0, aucune sortie
```

Après attribution et nettoyage des cinq artefacts immédiatement sûrs, seuls
les quatre PNG RED K2 restent non suivis.

## Risques conservés

- le checkpoint unique de 240 fichiers reste grossier pour un rollback par
  phase, mais il est restaurable ;
- les documents K/L contiennent un historique exact sur l'ancien HEAD
  `2f68328…` qui ne doit pas être réécrit ; une section terminale post-commit
  doit le superséder ;
- le checkpoint S0 protège l’état initial, pas les octets de la campagne
  courante ;
- aucune opération Git d'écriture n'a été autorisée pendant cette campagne ;
- L2 reste par conséquent `BLOCKED` jusqu'au checkpoint final explicite et à
  une décision reproductible sur le corpus externe.

## Clôture S0

- K2 : `DONE`, route produit 1672 × 941 inspectée et Design QA `passed` ;
- matrice technique : verte sur les six packages ;
- corpus graphique approuvé retrouvé sous
  `/Users/karim/Documents/playable_projects/selbrume/assets/sources/v2`, avec
  `68/68` hashes conformes au manifeste ;
- pipelines initialement skippés : rejoués, `+3`, `All tests passed!` ;
- hygiène : aucun fichier sous les dossiers `test/failures`, aucun lock
  Selbrume, `git diff --check` vert.

Verdict : **S0 DONE**. Le rapport ne confond pas ce checkpoint initial avec le
checkpoint de publication encore requis par L2.
```


Dernier gate K après correction du shell :

```text
six fichiers Phase K : +48, All tests passed!
route produit seule : +15, All tests passed!
flutter analyze --no-pub : No issues found! (ran in 5.0s)
flutter build macos --debug --no-pub :
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## L6.4 Fichiers et zones terminales

L’inventaire complet historique reste dans L4/L5. Les ajouts de la campagne
corrective finale sont :

| Zone | Changements |
|---|---|
| shell produit Event | vraie grille cinq zones, branding, contrôles DS, callbacks honnêtes |
| Pokémon SDK Moves | payload/port projet, conversion et synchronisation réconciliés |
| Selbrume | anchors, layers, placements et bateau corrigés ; fixtures/hashes alignés |
| runtime et host | migration API/lints et attentes de tests réconciliées |
| editor | analyzer ramené à zéro, harnesses/attentes obsolètes corrigés |
| visuels | trois Event goldens, preuve produit, côte-à-côte, overlay et crops focus |
| documentation | S0, roadmaps, Evidence Packs K/L et Design QA réconciliés |


### L6.4.1 Inventaire Git exact des fichiers modifiés ou créés

```text
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M "MVP Selbrume/road_map_event_builder_v2_execution.md"
 M design-qa.md
 M examples/playable_runtime_host/event_builder_v2_selbrume_slice/fixture_manifest.json
 M examples/playable_runtime_host/event_builder_v2_selbrume_slice/maps/map_port_brisants.json
 M examples/playable_runtime_host/event_builder_v2_selbrume_slice/promotion_manifest.json
 M examples/playable_runtime_host/event_builder_v2_selbrume_slice/promotion_payload/maps/map_port_brisants.json
 M examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
 M packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
 M packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
 M packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_templates.dart
 M packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_editor.dart
 M packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_payload.dart
 M packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_source.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart
 M packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/lib/src/ui/canvas/step_studio/step_flow_palette.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/character_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
 M packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/lib/src/ui/shared/pokemap_macos_ui_shim.dart
 M packages/map_editor/pubspec.yaml
 M packages/map_editor/test/application/services/pokemon_sdk_move_catalog_converter_test.dart
 M packages/map_editor/test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart
 M packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
 M packages/map_editor/test/collision_generation/element_ground_blocking_analyzer_test.dart
 M packages/map_editor/test/cutscene_studio_authoring_test.dart
 M packages/map_editor/test/cutscene_studio_map_context_test.dart
 M packages/map_editor/test/dialogue_disk_hierarchy_v13_test.dart
 M packages/map_editor/test/dialogue_preview_runner_test.dart
 M packages/map_editor/test/dialogue_studio_explorer_dialogue_widgets_test.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/editor_notifier_trainer_update_test.dart
 M packages/map_editor/test/editor_project_session_controller_test.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_state_groups_test.dart
 M packages/map_editor/test/encounter_tables_panel_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
 M packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
 M packages/map_editor/test/file_pokemon_read_repository_test.dart
 M packages/map_editor/test/global_story_studio_behavior_test.dart
 M packages/map_editor/test/global_story_studio_ux_test.dart
 M packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png
 M packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png
 M packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart
 M packages/map_editor/test/narrative_event_v2_mode_activation_test.dart
 M packages/map_editor/test/npc_runtime_rules_authoring_catalog_test.dart
 M packages/map_editor/test/npc_runtime_rules_editor_mapping_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_asset_diagnostics_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
 M packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart
 M packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart
 M packages/map_editor/test/pokedex_external_batch_execute_ui_test.dart
 M packages/map_editor/test/pokedex_learnset_moves_assist_ui_test.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
 M packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart
 M packages/map_editor/test/project_content_controller_test.dart
 M packages/map_editor/test/project_dialogue_import_and_folder_use_case_test.dart
 M packages/map_editor/test/project_element_collision_persistence_test.dart
 M packages/map_editor/test/project_tileset_use_cases_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
 M packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart
 M packages/map_editor/test/selbrume_port_props_pack_builder_test.dart
 M packages/map_editor/test/selbrume_project_roundtrip_test.dart
 M packages/map_editor/test/selbrume_visual_kit_builder_test.dart
 M packages/map_editor/test/step_flow_canvas_test.dart
 M packages/map_editor/test/step_studio_authoring_test.dart
 M packages/map_editor/test/step_studio_workspace_regression_test.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/support/selbrume_event_v2_fixture.dart
 M packages/map_editor/test/terrain_preset_selection_coordinator_test.dart
 M packages/map_editor/test/tileset_palette_placed_instance_opacity_test.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_project_list_test.dart
 M packages/map_editor/test/ui/design_system/pokemap_button_test.dart
 M packages/map_editor/test/ui/shell/pokemap_topbar_migration_test.dart
 M packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart
 M packages/map_editor/tool/generate_selbrume_canonical_maps.dart
 M packages/map_runtime/lib/src/application/script_command_executor.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_move_visual_recipe_library.dart
 M packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_turn_animation_planner_test.dart
 M packages/map_runtime/test/global_story_chapter_runtime_test.dart
 M packages/map_runtime/test/map_entity_runtime_predicate_evaluator_test.dart
 M packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
 M packages/map_runtime/test/playable_map_game_public_getters_test.dart
 M packages/map_runtime/test/player_component_test.dart
 M packages/map_runtime/test/runtime_story_branching_test.dart
 M packages/map_runtime/test/script_runtime_mvp_test.dart
 M packages/map_runtime/test/script_system_integration_test.dart
 M packages/map_runtime/test/scripted_npc_anchor_passability_test.dart
 M packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart
 M packages/map_runtime/test/step_studio_completion_runtime_test.dart
 M packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart
 M packages/map_runtime/test/step_studio_world_presence_runtime_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/trainer_defeated_test.dart
 M reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md
 M reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md
 M reports/narrativeStudio/events/phase_k_product_route_evidence/product_after_1672x941.png
 M reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_1672x941.png
 M reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_overlay_50.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png
 M selbrume/maps/map_bourg_selbrume.json
 M selbrume/maps/map_port_brisants.json
?? packages/map_editor/assets/branding/pokemap_event_builder_mark.png
?? packages/map_editor/assets/branding/pokemap_event_builder_project_thumb.png
?? packages/map_editor/lib/src/application/models/pokemon_sdk_studio_project_payload.dart
?? packages/map_editor/lib/src/application/ports/pokemon_sdk_studio_project_source.dart
?? packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_shell.dart
?? reports/narrativeStudio/events/ns_event_v2_s0_stabilization_baseline.md
?? reports/narrativeStudio/events/phase_k_product_route_evidence/focus_editor.png
?? reports/narrativeStudio/events/phase_k_product_route_evidence/focus_header_navigation_list.png
?? reports/narrativeStudio/events/phase_k_product_route_evidence/focus_inspector.png
```


Fichiers texte créés pendant cette campagne :

- `pokemon_sdk_studio_project_payload.dart` ;
- `pokemon_sdk_studio_project_source.dart` ;
- `event_builder_v2_product_shell.dart` ;
- `ns_event_v2_s0_stabilization_baseline.md`.

Leur contenu complet est reproduit dans l’annexe terminale L6 située à la fin
de ce rapport. Les binaires créés sont identifiés par chemin, dimensions et
hashes dans K8. Aucun fichier source temporaire ni copie du corpus utilisateur
n’est conservé dans le dépôt.

## L6.5 Git, limites et auto-critique

État initial : branche `main`, HEAD
`11c956ac2c37be15fe07c708443ecf7a39b1663b`, `0` entrée suivie modifiée et `9`
éléments non suivis. État avant rédaction documentaire terminale : même HEAD,
`162` entrées suivies/indexées et `9` non suivies, soit `171`; aucune écriture
Git, aucun lock Selbrume, aucun failure artifact, `git diff --check` vert.

Limites non bloquantes pour la feature : le corpus source reste volontairement
hors dépôt ; son emplacement local est donc requis pour rejouer ces deux tests.
Le shell vise une fidélité produit et structurelle, pas une copie décorative
pixel à pixel. La transition Event → Scene gagnera à être observée en test
utilisateur réel.

Auto-critique : la campagne a élargi son diff pour restaurer une matrice globale
verte, notamment via des corrections analyzer et des attentes historiques. Ces
changements ont été validés package par package, mais rendent le checkpoint
final volumineux. Les deux pipelines de corpus sont verts localement, mais leur
dépendance machine-spécifique n’est pas une preuve CI reproductible. C’est
précisément pourquoi ce rapport maintient un NO-GO publication jusqu’au
checkpoint et à une décision explicite sur le corpus.


### Correctif annexe L6 — contenu S0 courant après revue release

La reproduction S0 précédente a été capturée avant le correctif de formulation
sur les deux prérequis L2. La version courante complète est :

```markdown
# NS-EVENT-V2 — S0 Stabilization Baseline

Date d'ouverture : 2026-07-17

Lot exact : `S0 — Stabiliser et sécuriser l'état courant`

Statut courant : `DONE`

## Résumé exécutif

Le checkpoint de départ Event Builder V2 est récupérable dans le commit
`11c956ac2c37be15fe07c708443ecf7a39b1663b`
(`feat(events): complete Event Builder V2 workflow`). Le commit porte 240
fichiers, 270489 insertions et 733 suppressions. Les neuf éléments initiaux ont
été attribués ; les failure artifacts et le lock orphelin ont été supprimés.
S0 est donc fermé. Le checkpoint final et la reproductibilité du corpus
graphique relèvent de L2 et restent les deux conditions opérationnelles ouvertes.

## Scope et non-objectifs

S0 attribue le checkout, élimine les artefacts orphelins, réconcilie la
documentation avec le checkpoint et enregistre les baselines. Il n'ajoute
aucun comportement Event, Scene, Map ou runtime. Les corrections visuelles et
release appartiennent respectivement à K2 et aux lots correctifs précédant L2.

## Audit initial

État observé au début de la campagne cinq lots :

- branche : `main` ;
- HEAD : `11c956ac2c37be15fe07c708443ecf7a39b1663b` ;
- modifications suivies : aucune ;
- éléments non suivis : neuf ;
- `git diff --check` : exit `0` ;
- le plan d'exécution local sous `docs/superpowers/plans/` est ignoré par la
  règle historique `.gitignore:7:/docs/*` et n'est pas un livrable Git S0.

## Attribution des neuf éléments initiaux

| Élément | Attribution | Décision |
|---|---|---|
| 4 PNG `test/failures/ns_scenes_v1_39_*` | artefacts golden Scene étrangers à Event V2 | supprimés, non publiables |
| 4 PNG `test/ui/canvas/failures/event_builder_v2_product_route_1672x941_*` | comparaison golden RED K2 | conservés pendant l'itération K2, à supprimer après GREEN |
| `selbrume/.pokemap-project-1f1a60297a27b0b0.lock` | lock éditeur local vide et orphelin | `lsof` sans propriétaire, supprimé |

## Références visuelles gelées

| Fichier | SHA-256 |
|---|---|
| North star `1 - événements.png` | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |
| Produit avant nouvelle itération K2 | `eda012eafc3ecbdafd17396c2b7810005f1687a9796f7cf58d93ae34dde1d673` |

## Commandes initiales et résultats exacts

```text
git show --shortstat --oneline HEAD
11c956ac feat(events): complete Event Builder V2 workflow
240 files changed, 270489 insertions(+), 733 deletions(-)

lsof selbrume/.pokemap-project-1f1a60297a27b0b0.lock
exit 1, aucun processus propriétaire

git diff --check
exit 0, aucune sortie
```

Après attribution et nettoyage des cinq artefacts immédiatement sûrs, seuls
les quatre PNG RED K2 restent non suivis.

## Risques conservés

- le checkpoint unique de 240 fichiers reste grossier pour un rollback par
  phase, mais il est restaurable ;
- les documents K/L contiennent un historique exact sur l'ancien HEAD
  `2f68328…` qui ne doit pas être réécrit ; une section terminale post-commit
  doit le superséder ;
- le checkpoint S0 protège l’état initial, pas les octets de la campagne
  courante ;
- aucune opération Git d'écriture n'a été autorisée pendant cette campagne ;
- L2 reste par conséquent `BLOCKED` jusqu'au checkpoint final explicite et à
  une décision reproductible sur le corpus externe.

## Clôture S0

- K2 : `DONE`, route produit 1672 × 941 inspectée et Design QA `passed` ;
- matrice technique : verte sur les six packages ;
- corpus graphique approuvé retrouvé sous
  `/Users/karim/Documents/playable_projects/selbrume/assets/sources/v2`, avec
  `68/68` hashes conformes au manifeste ;
- pipelines initialement skippés : rejoués, `+3`, `All tests passed!` ;
- hygiène : aucun fichier sous les dossiers `test/failures`, aucun lock
  Selbrume, `git diff --check` vert.

Verdict : **S0 DONE**. Le rapport ne confond pas ce checkpoint initial avec le
checkpoint de publication encore requis par L2.
```

> **Réconciliation finale L5 — 2026-07-17.** Cette section remplace L4 pour le
> statut, le périmètre des guards, la matrice et les nombres d’analyse. Les
> sections historiques restent conservées uniquement comme audit trail.

## L5.1 Décision terminale honnête

- Campagne technique `V2-41…V2-43` : **exécutée**.
- Statut mission Phase L : **PLANNED** (`NOT STARTED` au tableau maître), car la séquence stricte et l’entry
  gate B→K ne sont pas fermées dans le tableau maître.
- Verdict release observé : **NO-GO**.
- Event Builder V2 ciblé : **aucun P1 code restant après revue finale**.
- V1 : conservé ; aucun changement de défaut, dépréciation ou suppression.

L4 affirmait à tort que tous les `ScenarioAsset` devaient être bloqués en
`v2Only`. Les mêmes use cases servent Global Story et Cutscene. La correction
finale applique donc la frontière réelle :

- les mutateurs legacy `MapEvent` sont bloqués par mode en `v2Only` ;
- les `ScenarioAsset` revendiqués par les claims de migration restent gelés par
  `evaluateScenarioAuthoringClaimGuard` ;
- les Global Stories et Cutscenes sans claim restent créables, modifiables et
  supprimables en `v2Only`.

## L5.2 Verdict des cinq passes et revue contradictoire

| Passe | Verdict final | Signal |
|---|---|---|
| Audit / Architecture | PASS Event / NO-GO release | frontières MapEvent/Scenario et largeur réelle corrigées |
| Implémentation | PASS ciblé | aucun sur-blocage Scenario, gate shell exact, indexation linéaire |
| Tests | PASS Event / FAIL global | K `+48`, fermeture `+61`, perf `+6`; suites globales Selbrume rouges |
| Build / Validation | PASS editor build / FAIL global analyze | 23 fichiers ciblés verts ; editor global `451 issues` |
| Critique finale | PASS sans blocker | follow-up code et Evidence toutes deux vertes après corrections |

La revue code read-only a trouvé les deux P1 ci-dessus ; ils ont été reproduits
avant correction puis fermés. La revue Evidence read-only a trouvé : statuts
roadmap contradictoires, omission `map_battle`, bilan analyzer périmé,
acceptation P2 non autorisée et plan non suivi. L5, K7, les deux roadmaps,
`design-qa.md` et le plan corrigent ces points sans transformer le NO-GO en GO.
Les deux follow-up reviews finales concluent ensuite `aucun blocker restant`.

## L5.3 Fichiers et zones de la correction post-revue

L’inventaire K6/L4 reste applicable pour les changements antérieurs. Les zones
post-revue sont :

| Chemin | Zone | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/application/services/narrative_event_legacy_authoring_guard.dart` | enum/message | garde central limité aux vrais `MapEvent` legacy |
| `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` | `_ensureScenarioAuthoringAllowed` | conserver seulement le guard précis par claim |
| `packages/map_editor/test/project_scenario_use_cases_test.dart` | scénario `v2Only` | non-régression Global Story/Cutscene positive |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | route Events | fournir largeur fenêtre + largeur métier |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | contrat/gate | refuser le workspace si la zone utile est < 1280 |
| `packages/map_editor/lib/src/ui/shared/status_bar.dart` | responsive wide | éviter l’overflow avec map active à 1280 |
| `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` | full-shell 1280 | prouver zéro overflow/loader |
| `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart` | helper | capture déterministe sans fausse affirmation d’auto-collapse |
| `packages/map_editor/test/support/event_builder_v2_visual_harness.dart` | fixture K | conditions/lifecycle réels |
| `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart` | conflit | test lié à une concurrence effective |
| `packages/map_editor/test/goldens/event_builder_v2/phase_k/event_builder_v2_1672x941.png` | raster | golden K inspecté et rafraîchi |
| `docs/superpowers/plans/2026-07-17-event-builder-v2-final-closure.md` | suivi | étapes exécutées cochées, écarts P2 laissés ouverts |
| `MVP Selbrume/road_map_event_builder_v2.md` | K/L + synthèse | séparer preuve technique et statut formel |
| `MVP Selbrume/road_map_event_builder_v2_execution.md` | dashboard/état réel | réconcilier ledger technique et tableau maître |
| `design-qa.md` | verdict | K technique PASS, mission `PLANNED` |
| Evidence Packs K et L | K7/L5 | commandes, revues, matrice et auto-critique courantes |

## L5.4 TDD et commandes finales

RED Scenario : une Global Story en `v2Only` levait à tort
`Les anciens scénarios doivent être modifiés...`. GREEN : création Global Story,
mise à jour Cutscene et suppression Global Story persistent normalement ; les
scénarios claimed restent bloqués par la suite de claims.

RED responsive : au shell 1280, Event recevait `996 px`, débordait de `40 px`
et la status bar de `144 px`. GREEN : narrow gate présent, workspace absent,
loaders `0`, aucune exception.

```bash
cd packages/map_editor
flutter test --no-pub \
  test/project_scenario_use_cases_test.dart \
  test/scenario_authoring_claim_guard_test.dart \
  test/event_builder_draft_creation_notifier_test.dart \
  test/status_bar_test.dart \
  test/ui/shell/pokemap_bottom_bar_redesign_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart
```

Résultat : exit `0`, `+61`, `All tests passed!`.

```bash
flutter test --no-pub --concurrency=1 \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_validation_coordinator_test.dart
```

Résultat : exit `0`, `+6`, `All tests passed!`; p50 `11624 µs`, p95
`13410 µs`, budget p95 `36000 µs`.

Matrice K normative complète : exit `0`, `+48`, `All tests passed!`.
Analyse ciblée des 23 fichiers de fermeture : exit `0`, `No issues found!`.
Build editor macOS debug : exit `0`,
`✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## L5.5 Matrice release réconciliée

| Package | Tests | Analyse | Build/smoke |
|---|---|---|---|
| `map_core` | exit `0`, `+3000` | exit `0`, no issues | N/A pure Dart |
| `map_gameplay` | exit `0`, `+283` | exit `0`, no issues | N/A pure Dart |
| `map_battle` | exit `0`, `+1720` | exit `0`, no issues | N/A pure Dart |
| `map_runtime` | exit `1`, `+1776 ~1 -2` | exit `1`, `347 infos` | smoke Phase A exit `0`, `+3` |
| `map_editor` | exit `1`, `+3043 -107` sur la campagne globale précédente | **frais final : exit `1`, 81 errors + 10 warnings + 360 infos = 451** | build macOS debug frais exit `0` |
| host jouable | exit `0`, `+55` | exit `1`, `1 info` | build macOS debug exit `0`, smoke `+1` |

`map_battle` était absent de L4 : il a été exécuté en revue read-only et est
vert (`+1720`, analyze sans issue). Les suites globales longues ont été lancées
avant les deux correctifs P1 finaux ; elles restent un contexte d’attribution,
pas une prétendue matrice verte sur les octets finaux. L’analyse editor finale,
sur les octets finaux, suffit à maintenir L2 en NO-GO avec 81 hard errors.

Les blockers release restent : PSDK Moves (81 errors), cohérence Selbrume
runtime/editor, politique analyzer/lints, budgets non ratifiés, politique V1 et
checkpoint récupérable explicitement autorisé. Aucun n’est masqué.

## L5.6 Git, fichiers créés et auto-critique

État initial : HEAD `2f68328a38bf218c843e497940f8dd24a7a9c194`, `64`
entrées suivies/indexées + `171` non suivies = `235`. État final : même HEAD,
`69` entrées suivies/indexées + `180` non suivies = `249`; `git diff --check`
exit `0`. Ces nombres remplacent les snapshots historiques plus bas. Aucune
commande Git d’écriture n’a été utilisée.

Les deux fichiers texte créés pendant la clôture restent le guard et le plan.
Le contenu complet courant du guard figure en L5.7 et celui du plan en L5.8.
L4.10 et L4.11 restent les snapshots historiques antérieurs à la revue et ne
doivent plus être utilisés pour vérifier l’égalité octet à octet.

Hashes courants : guard
`45b7e074dc41c4caeb51727c291a545be1a187004f74a0ef03b943bad198f515` ;
plan
`770d7d78260da28264857a3c3741a08e4c3cab50c018771551bad0af3f90b74f`.

Auto-critique : la fermeture Event ciblée est solide, mais le dépôt entier n’est
pas une release candidate. K attend encore une décision utilisateur sur les P2
visuels et la séquence formelle attend S0. Le benchmark wall-clock garde un
risque de variance malgré une marge actuelle d’environ 2,7×. Le NO-GO est donc
la seule décision release défendable.

## L5.7 Contenu complet courant du guard créé

```dart
import 'package:map_core/map_core.dart';

enum NarrativeEventLegacyAuthoringKind { mapEvent }

/// Returns a user-facing reason when a legacy authoring entry point must be
/// closed for the project's authoritative Event Builder mode.
String? narrativeEventLegacyAuthoringBlockReason(
  ProjectManifest? project, {
  required NarrativeEventLegacyAuthoringKind kind,
}) {
  if (project?.eventRegistry?.mode != EventSystemMode.v2Only) return null;
  return 'Le projet est en mode Event Builder V2 uniquement. '
      'Les anciens MapEvents doivent être modifiés depuis la migration '
      'ou l’Event Builder V2.';
}
```

## L5.8 Contenu complet courant du plan créé

```markdown
# Event Builder V2 Final Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining Event Builder V2 visual and release-readiness work with a real 1672 × 941 product-route proof grounded in the supplied north star, focused regression coverage, and an honest final GO/NO-GO decision.

**Architecture:** Keep `map_core` as the source of Event V2 data and projections, `map_editor` as the no-code authoring surface, and the existing Narrative Studio route as the production UI. The final visual fixture must exercise the on-disk authoring session and the real `EditorShellPage`/Events route; the Phase K visual harness remains a focused component baseline, not release proof. Phase L remains validation-first: only attributable release blockers may be fixed, and V1 remains available unless every V2 gate passes.

**Tech Stack:** Dart, Flutter desktop, Riverpod, PokeMap design-system widgets/tokens, Flutter widget/golden tests, package-scoped `dart test`/`flutter test`/`analyze`, macOS debug builds, raster comparison at 1672 × 941.

---

## Task 1 — Freeze the current baseline and define truthful closure evidence

**Files:**

- Read: `MVP Selbrume/road_map_event_builder_v2.md`
- Read: `MVP Selbrume/road_map_event_builder_v2_execution.md`
- Read: `reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md`
- Read: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`
- Read: `design-qa.md`
- Modify: this plan only for checkbox progress

- [x] **Step 1:** Record read-only Git baseline (`HEAD`, tracked/untracked counts, relevant file inventory) without modifying Git state.
- [x] **Step 2:** Classify existing Phase K/L changes as pre-existing versus attributable to this closure pass.
- [x] **Step 3:** Confirm relevant mechanics lots (`FG-080`, `FG-081`, `FG-082`, `FG-093`, `FG-183`, `FG-185`) and keep their status truthful unless their own done criteria receive fresh proof.
- [x] **Step 4:** Pin the supplied 1672 × 941 reference and current product-route screenshot hashes.

## Task 2 — Add a real full-shell product capture contract

**Files:**

- Modify: `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
- Create/refresh: `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`

- [x] **Step 1:** Add a widget test that pumps the on-disk fixture through `EditorShellPage`, selects the canonical port event, and asserts that the full surface is exactly 1672 × 941.
- [x] **Step 2:** Run that test before adding the helper and observe the expected RED failure.
- [x] **Step 3:** Add the smallest reusable full-shell pump helper, preserving the real read-model/validation/provider seams already used by the product-route fixture.
- [x] **Step 4:** Switch the visual capture fixture to `EventSystemMode.v2Only` so the final-state proof is not obscured by migration UI.
- [x] **Step 5:** Run the focused product-route test and retain the first real full-shell screenshot as the visual before-state.

## Task 3 — Make the on-disk Selbrume fixture representative of the north star

**Files:**

- Modify: `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
- Test: `packages/map_editor/test/narrative_event_builder_v2_state_test.dart`
- Test: `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`

- [x] **Step 1:** Add RED assertions that the selected real product event exposes two resolved conditions, a linked scene with outcomes/consequences/world changes, one-shot lifecycle, and the expected Port Selbrume source.
- [x] **Step 2:** Extend only the test project data needed to produce those summaries through the production read-model builder; do not inject a synthetic `NarrativeEventBuilderProjectReadModel`.
- [x] **Step 3:** Add enough realistic map groups/events to exercise the target density while keeping every source backed by a real entity or zone already present in a fixture map.
- [x] **Step 4:** Re-run the fixture/read-model tests and verify the selected event is stable and no unsupported authoring is implied.

## Task 4 — Close responsive diagnostics and supported Phase K P1 gaps with TDD

**Files:**

- Modify only as proven necessary: `packages/map_editor/lib/src/ui/canvas/events_v2/`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`

- [x] **Step 1:** Add a RED test reproducing the real 800 × 632 diagnostics/migration bottom overflow.
- [x] **Step 2:** Fix the overflow with existing PokeMap layout primitives/tokens and verify 800, 1280, 1440, 1480, 1672 and wide desktop sizes.
- [x] **Step 3:** Add focused RED contracts for only the target details supported by current domain data: condition summary visibility, outcome-to-projection continuity, reuse policy and priority visibility.
- [x] **Step 4:** Implement the smallest truthful UI/read-model presentation needed; keep Scene-owned branches and consequences read-only and do not create fake draggable authoring.
- [x] **Step 5:** Run focused Event Builder V2 tests after each change and stop if a requested reference detail requires a new gameplay model outside Phase K.

## Task 5 — Compare the real product route and iterate through Design QA

**Files:**

- Refresh: `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`
- Reuse: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_before_1672x941.png`
- Reuse: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_before_overlay_50.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/product_after_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_overlay_50.png`
- Modify: `design-qa.md`

- [x] **Step 1:** Capture the reference and real product at the same 1672 × 941 viewport and selected-event state.
- [x] **Step 2:** Build a side-by-side and 50% overlay from those exact images.
- [x] **Step 3:** Review layout, density, type, colors, icons, surfaces, interaction states, text scaling and responsiveness against the QA rubric.
- [ ] **Step 4:** Fix every attributable P0/P1/P2 using design-system components/tokens, then capture and compare again.
- [ ] **Step 5:** Mark Design QA `passed` only if no actionable P0/P1/P2 remains; otherwise record the exact blocker and keep Phase K non-DONE.

## Task 6 — Execute the Phase K and L verification gates

**Files:**

- Test: all Event Builder V2/core/runtime/host surfaces named by the Phase K/L plans
- Modify only for attributable blockers: impacted tests/production files

- [x] **Step 1:** Run formatting checks for every changed Dart file.
- [x] **Step 2:** Run the focused Phase K/V2/design-system widget matrix and all V1 regression groups.
- [x] **Step 3:** Run the V2-41 legacy corpus, migration/recovery, no-fallback and performance-evidence suites.
- [x] **Step 4:** Run package tests and analyzes for `map_core`, `map_gameplay`, `map_battle`, `map_runtime`, `map_editor`, and `examples/playable_runtime_host`.
- [x] **Step 5:** Run the macOS editor build and the required runtime/host smoke tests.
- [x] **Step 6:** For failures, prove attribution before editing. Fix only a small shared root that blocks Event Builder release; classify unrelated baseline failures explicitly.

## Task 7 — Update roadmaps and Evidence Packs with final, reviewable truth

**Files:**

- Modify: `MVP Selbrume/road_map_event_builder_v2_execution.md`
- Modify only when evidence permits: `MVP Selbrume/road_map_event_builder_v2.md`
- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md`
- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`
- Modify: `design-qa.md`

- [x] **Step 1:** Re-read `codex_rule.md` immediately before writing the closure reports.
- [x] **Step 2:** Record initial audit and the independent Audit/Architecture, Implementation, Tests, Build/Validation and Final Critique verdicts.
- [x] **Step 3:** Include exact file inventory, precise changed zones, full content for newly created text files, exact commands/results, hashes, initial/final Git status, limits and self-critique.
- [x] **Step 4:** Update K/L and execution-roadmap statuses strictly from fresh evidence; never turn a targeted green suite into a global GO.
- [x] **Step 5:** Keep V1 deprecation inactive unless V2-41 and V2-42 both pass and V2-43 has zero blockers.
- [x] **Step 6:** Request final specification and code-quality reviews, address blockers, and rerun affected checks.
- [x] **Step 7:** Propose the final Git checkpoint but perform no `git add`, commit, push, branch, stash, reset or worktree operation without new explicit authorization.
```

> **Décision terminale L4 — 2026-07-17.** Cette section remplace le verdict et
> les constats périmés situés plus bas. L’historique reste conservé.

## L4.1 Résumé exécutif et décision

- `NS-EVENT-V2-41` : **PASS technique Event V2**.
- `NS-EVENT-V2-42` : **BLOCKED global**.
- `NS-EVENT-V2-43` : **DONE — décision NO-GO**.
- Phase L : **CLOSED avec décision release NO-GO**.

La fermeture fonctionnelle Event Builder demandée est implémentée et ses gates
ciblés sont verts. Deux blockers Event spécifiques ont été fermés pendant L4 :

1. tous les entrypoints legacy `MapEvent` et `Scenario` refusent désormais les
   écritures quand le registre est en `v2Only` ;
2. le validateur incrémental n’effectue plus des scans O(records × catalog) pour
   chaque fingerprint. Son p95 mesuré passe de `38065 µs` en RED à `17255 µs`
   en GREEN pour un budget gelé de `36000 µs`.

La release globale reste **NO-GO** parce que la matrice complète du monorepo est
rouge sur des chantiers étrangers à Event V2 : intégration Pokémon SDK Moves,
contrats de maps/assets Selbrume et dette lint package. Aucune activation par
défaut, conversion forcée de Selbrume ou dépréciation V1 n’est autorisée.

Cette conclusion est terminale et non ambiguë : le travail de la Phase L est
fini, mais son résultat est un refus de release documenté, pas un faux GO.

## L4.2 Scope, audit initial et remise en cause

Le prompt « finir tout » a été interprété comme : fermer tous les défauts
attribuables à l’Event Builder, exécuter la matrice complète et rendre une
décision L3. Il n’autorise pas à réparer silencieusement les 81 erreurs du
convertisseur Pokémon SDK, les données Selbrume modifiées par un autre chantier,
ni les centaines d’infos lint historiques.

Audit initial :

- HEAD : `2f68328a38bf218c843e497940f8dd24a7a9c194` ;
- arbre partagé très sale, 64 entrées suivies/indexées et 171 non suivies ;
- route produit V2 désormais réelle, contrairement à l’ancien rapport ;
- migration UI/disque et tests de recovery présents ;
- absence d’un verrou central `v2Only` sur les mutateurs legacy ;
- benchmark incrémental non hermétique et au-dessus du budget dans une exécution
  fraîche ;
- erreurs analyzer globales concentrées dans Pokémon SDK Moves ;
- politiques de release non ratifiées : défaut de mode, calendrier V1,
  allowlist lint et budgets des surfaces encore `threshold=unconfigured`.

Limites préservées : pas de changement `map_battle`, pas de refonte PSDK, pas de
réécriture des maps Selbrume, pas d’opération Git d’écriture, pas de promesse de
rollback après publication de données V2-only non représentables en V1.

## L4.3 Verdict des cinq passes obligatoires

| Passe | Verdict | Signal final |
|---|---|---|
| Audit / Architecture | PASS avec blockers globaux | les deux vrais gaps Event ont été isolés |
| Implémentation | PASS | guard central et indexation fingerprints minimaux |
| Tests | PASS Event / FAIL global | toutes les suites ciblées vertes ; matrices Selbrume rouges |
| Build / Validation | PASS builds / FAIL analyzes globaux | editor et host buildent, analyses package non nulles |
| Critique finale | NO-GO confirmé | aucun blocker Event ciblé, blockers release externes et politiques ouverts |

## L4.4 Modifications attribuables à L4

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/application/services/narrative_event_legacy_authoring_guard.dart` | fichier créé | décision centrale par mode et type d’artefact legacy |
| `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` | `_ensureScenarioAuthoringAllowed` | fail-closed avant le garde par claim |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | mutateurs MapEvent + helper privé | aucun create/update/delete legacy en `v2Only` |
| `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart` | groupe Phase L guard | create/update/delete négatifs, map inchangée |
| `packages/map_editor/test/project_scenario_use_cases_test.dart` | test v2Only | create/update/delete refusés, aucun save |
| `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` | préparation des fingerprints | index diagnostics/events/claims une fois par rebuild |
| `docs/superpowers/plans/2026-07-17-event-builder-v2-final-closure.md` | fichier créé | plan de clôture K/L |
| les fichiers K listés dans l’Evidence Pack K6 | full-shell, responsive, projections | prérequis visuel de L |
| ce rapport et les deux roadmaps | verdict final | état courant non périmé |

Diff fonctionnel précis :

- le guard retourne `null` hors `v2Only` et un message spécifique pour
  `MapEvent` ou `Scenario` en `v2Only` ;
- les scénarios legacy vérifient le mode avant l’index des claims ;
- les onze surfaces MapEvent mutantes et les deux mutateurs génériques appellent
  le même helper avant toute construction ou application de map ;
- le coordinateur construit trois index linéaires puis conserve l’ordre des
  diagnostics, entrées et claims dans le hash canonique ;
- aucun codec, schéma persistant, autorité runtime ou comportement `dualRead`
  n’est modifié.

## L4.5 TDD et validation ciblée

RED guard observé :

```text
Scenario create returned a modified ProjectManifest instead of throwing.
MapEvent draft creation returned evt_nouvel_evenement instead of null.
```

GREEN guard :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact \
  test/event_builder_draft_creation_notifier_test.dart \
  test/project_scenario_use_cases_test.dart \
  test/scenario_authoring_claim_guard_test.dart
```

Résultat : exit `0`, `+38`, `All tests passed!`.

RED performance hermétique :

```text
p50_us=15932 p95_us=38065 recalculated=3
budget_p95_us=36000
Expected <= 36000, Actual 38065
```

GREEN après indexation :

```bash
cd packages/map_editor
flutter test --no-pub --concurrency=1 --reporter=compact \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_validation_coordinator_test.dart
```

Résultat : exit `0`, `+6`, `All tests passed!` :

```text
p50_us=12057 p95_us=17255 recalculated=3
budget_p95_us=36000 threshold=frozen
```

Gates ciblés L :

| Surface | Commande abrégée | Résultat exact |
|---|---|---|
| Core corpus/migration/claims/perf | 8 fichiers ciblés | exit `0`, `+134`, all passed |
| Gameplay authority/runtime/perf | 3 fichiers ciblés | exit `0`, `+10`, all passed |
| Runtime legacy/boot/snapshot | 3 fichiers ciblés | exit `0`, `+8`, all passed |
| Editor registry/recovery/perf | 6 fichiers ciblés | exit `0`, `+49`, all passed |
| Core read model final | 1 fichier ciblé | exit `0`, `+16`, all passed |
| Editor K/L final | 6 fichiers ciblés | exit `0`, `+66`, all passed |

## L4.6 Matrice complète fraîche

| Package | Tests | Analyse | Build/smoke |
|---|---|---|---|
| `map_core` | exit `0`, `+3000`, all passed | exit `0`, no issues | N/A pure Dart |
| `map_gameplay` | exit `0`, `+283`, all passed | exit `0`, no issues | N/A pure Dart |
| `map_runtime` | exit `1`, `+1776 ~1 -2` | exit `1`, `347 issues` (infos) | smoke Phase A exit `0`, `+3` |
| `map_editor` | exit `1`, `+3043 -107` | exit `3`, `81 errors, 10 warnings, 366 infos` | macOS debug exit `0` |
| host jouable | exit `0`, `+55`, all passed | exit `1`, `1 issue` info | macOS debug exit `0`, smoke `+1` |

Échecs runtime exacts, hors Event Builder :

1. `selbrume_map_catalog_integrity_test.dart` attend deux entités dans le marais
   mais trouve aussi `clue_glass_object` ;
2. `selbrume_asset_integrity_contract_test.dart` détecte
   `npc_lysa ... references unknown element: grant`.

La suite editor termine avec 107 échecs. Les erreurs terminales observées dans
`selbrume_project_roundtrip_test.dart` proviennent du contrat
`map_bourg_selbrume is missing required layer l_terrain with its canonical
type`, qui masque ensuite les assertions landmark/connection. Les suites Event
Builder ciblées, y compris route produit, guards, migration/recovery et
performance, restent vertes.

Analyse editor exacte : `457 issues` = `81 errors`, `10 warnings`, `366 infos`.
Les hard errors se regroupent dans :

- `pokemon_sdk_move_catalog_converter.dart` : API `PokemonMove`/flags/targets
  absente ou désynchronisée ;
- `sync_pokemon_sdk_moves_catalog_use_case.dart` : méthode repository absente.

Commandes de build :

```bash
cd packages/map_editor && flutter build macos --debug --no-pub
```

Résultat : exit `0`,
`✓ Built build/macos/Build/Products/Debug/map_editor.app`.

```bash
cd examples/playable_runtime_host && flutter build macos --debug --no-pub
```

Résultat : exit `0`,
`✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app`.

## L4.7 Décision de support et blockers restants

Décision immédiate :

- conserver `legacyOnly | dualRead | v2Only` ;
- ne pas basculer le défaut en `v2Only` ;
- conserver readers/importeurs et route legacy selon le mode ;
- interdire tout nouvel authoring legacy dès qu’un projet est explicitement
  `v2Only` — désormais prouvé par test ;
- ne pas annoncer de fenêtre de dépréciation V1 avant une matrice globale verte.

Blockers de release restants, tous hors correctif Event ciblé :

1. lot séparé Pokémon SDK Moves pour les 81 hard errors ;
2. réconciliation des maps/assets Selbrume et des 107 échecs editor ;
3. politique analyzer : zéro issue ou allowlist versionnée ;
4. budgets numériques à ratifier pour les surfaces encore
   `threshold=unconfigured` ;
5. décision produit sur mode par défaut, calendrier V1 et point de non-retour ;
6. checkpoint récupérable de l’arbre courant, nécessitant une autorisation Git
   ou une archive autonome approuvée.

## L4.8 Roadmap mécaniques fangame

Les lots suivants restent inchangés faute de preuve de leurs DoD propres :

| Lot | Statut |
|---|---|
| FG-080 Event Command Model V0 | `TODO` |
| FG-081 Condition Builder No-code V0 | `TODO` |
| FG-082 Runtime Command Executor V0 | `TODO` |
| FG-093 Action Builder UI V0 | `TODO` |
| FG-183 Regression Matrix V0 | `TODO` |
| FG-185 MVP Release Gate V0 | `TODO` |

## L4.9 Auto-critique et risques

La passe ferme les deux gaps Event V2 identifiés, mais ne transforme pas une
branche de travail très sale en release candidate. Le benchmark p95 est
nettement sous le seuil après optimisation, mais reste sensible à la machine ;
le test conserve donc environnement et volume dans sa sortie. Le guard central
protège les entrypoints editor connus, sans prétendre empêcher une écriture
manuelle de JSON ou une future API qui oublierait de l’appeler. Toute nouvelle
surface legacy devra réutiliser ce service et ajouter son test négatif.

Enfin, la build macOS verte ne compense ni les suites complètes rouges, ni les
analyses non nulles. Le verdict NO-GO est maintenu sans maquillage.

### État Git final de L4

```text
HEAD 2f68328a38bf218c843e497940f8dd24a7a9c194
tracked/indexed entries: 69
untracked entries: 180
total dirty entries: 249
git diff --check: exit 0
```

Les failure artifacts générés par la suite globale editor pendant cette passe
ont été supprimés après collecte des erreurs. Les quatre artefacts
`ns_scenes_v1_39_*` et les quatre artefacts
`event_builder_v2_product_route_1672x941_*` déjà présents avant la passe ont été
préservés. Le lock Selbrume déjà présent n’a pas été supprimé ni réattribué.
Aucune commande `git add`, commit, push, branch, stash, reset, restore ou
worktree n’a été exécutée.

## L4.10 Contenu complet des fichiers texte créés

### `narrative_event_legacy_authoring_guard.dart`

```dart
import 'package:map_core/map_core.dart';

enum NarrativeEventLegacyAuthoringKind { mapEvent, scenario }

/// Returns a user-facing reason when a legacy authoring entry point must be
/// closed for the project's authoritative Event Builder mode.
String? narrativeEventLegacyAuthoringBlockReason(
  ProjectManifest? project, {
  required NarrativeEventLegacyAuthoringKind kind,
}) {
  if (project?.eventRegistry?.mode != EventSystemMode.v2Only) return null;
  return switch (kind) {
    NarrativeEventLegacyAuthoringKind.mapEvent =>
      'Le projet est en mode Event Builder V2 uniquement. '
          'Les anciens MapEvents doivent être modifiés depuis la migration '
          'ou l’Event Builder V2.',
    NarrativeEventLegacyAuthoringKind.scenario =>
      'Le projet est en mode Event Builder V2 uniquement. '
          'Les anciens scénarios doivent être modifiés depuis la migration '
          'ou l’Event Builder V2.',
  };
}
```

### `2026-07-17-event-builder-v2-final-closure.md`

```markdown
# Event Builder V2 Final Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining Event Builder V2 visual and release-readiness work with a real 1672 × 941 product-route proof grounded in the supplied north star, focused regression coverage, and an honest final GO/NO-GO decision.

**Architecture:** Keep `map_core` as the source of Event V2 data and projections, `map_editor` as the no-code authoring surface, and the existing Narrative Studio route as the production UI. The final visual fixture must exercise the on-disk authoring session and the real `EditorShellPage`/Events route; the Phase K visual harness remains a focused component baseline, not release proof. Phase L remains validation-first: only attributable release blockers may be fixed, and V1 remains available unless every V2 gate passes.

**Tech Stack:** Dart, Flutter desktop, Riverpod, PokeMap design-system widgets/tokens, Flutter widget/golden tests, package-scoped `dart test`/`flutter test`/`analyze`, macOS debug builds, raster comparison at 1672 × 941.

---

## Task 1 — Freeze the current baseline and define truthful closure evidence

**Files:** roadmaps K/L, Evidence Packs K/L, `design-qa.md`, and this plan.

- [ ] Record the read-only Git baseline and classify pre-existing changes.
- [ ] Preserve the relevant FG lot statuses without inventing completion.
- [ ] Pin the supplied reference and product-route screenshot hashes.

## Task 2 — Add a real full-shell product capture contract

**Files:** product fixture, product-route test and full-shell golden.

- [ ] Pump the on-disk fixture through `EditorShellPage` at 1672 × 941.
- [ ] Observe RED before adding the helper, then implement the smallest seam.
- [ ] Capture a V2-only final state without migration UI obscuring the proof.

## Task 3 — Make the on-disk fixture representative of the north star

- [ ] Prove two conditions, Scene outcomes/consequences/world changes,
  one-shot lifecycle and Port Selbrume source through production projections.
- [ ] Keep every source backed by real fixture data and avoid synthetic read
  model injection.

## Task 4 — Close responsive diagnostics and supported P1 gaps with TDD

- [ ] Reproduce and fix the real 800 × 632 overflow.
- [ ] Verify 800, 1280, 1440, 1480, 1672 and wide desktop sizes.
- [ ] Expose only condition, consequence, reuse and priority details supported
  by current domain data; do not invent Scene authoring or reset semantics.

## Task 5 — Compare the real product route and iterate through Design QA

- [ ] Compare reference and product at the same 1672 × 941 viewport.
- [ ] Produce side-by-side and 50% overlay evidence.
- [ ] Close every attributable P0/P1/P2 and record intentional deviations.

## Task 6 — Execute the Phase K and L verification gates

- [ ] Run focused K/V2/V1 tests, corpus/migration/recovery/performance suites,
  package tests/analyzes, macOS builds and required smokes.
- [ ] Fix only attributable blockers and classify unrelated baseline failures.

## Task 7 — Update roadmaps and Evidence Packs with final truth

- [ ] Re-read `codex_rule.md`, record five pass verdicts, exact files,
  commands/results, hashes, Git states, limits and self-critique.
- [ ] Keep V1 deprecation inactive unless every release gate is green.
- [ ] Propose, but do not execute, a Git checkpoint without authorization.
```

Le bloc précédent est un résumé de lecture. La reproduction exacte et complète
du plan sur disque figure en annexe L4.11 à la fin de ce rapport. Les PNG créés
sont des binaires documentés par leurs dimensions/hashes dans l’Evidence Pack K6.

Date de validation : 2026-07-16
Révision auditée : `2f68328a38bf218c843e497940f8dd24a7a9c194`
Jalons : `NS-EVENT-V2-41`, `NS-EVENT-V2-42`, `NS-EVENT-V2-43`
Verdict final : **PHASE L BLOCKED — RELEASE NO-GO**

## 1. Résumé exécutif

La Phase L n'atteint ni son entry gate ni son exit gate. La décision de release
est donc explicitement **NO-GO** :

- ne pas activer Event Builder V2 par défaut ;
- ne pas passer Selbrume ni un projet existant en `v2Only` ;
- ne pas démarrer la dépréciation V1 ;
- conserver les readers/importeurs legacy et le mode courant ;
- ne pas présenter le workspace V2 de test comme la route produit.

Le lot a néanmoins produit des preuves fraîches et utiles :

- quatre surfaces de performance émettent désormais explicitement `p50_us` et
  `p95_us`, sans faux seuil ;
- le cas combiné `dualRead + claim valide + cible oneShot consommée` prouve une
  décision `claimedButIneligible` et interdit exactement le fallback legacy ;
- le corpus V2-41 ciblé passe avec **201 tests** ;
- les suites complètes `map_core` (`+2987`), `map_gameplay` (`+283`),
  `map_runtime` (`+1769`) et host (`50/50`) passent ;
- la matrice visuelle K (`54/54`), sa capture (`3/3`) et les deux builds macOS
  debug passent.

Ces succès ne ferment pas le gate. Les blockers restent structurels :

1. G n'est que `READY`, H/I/J ne sont pas validées et K est `BLOCKED / NO-GO` ;
2. la route Events produit instancie encore `EventBuilderWorkspace` V1 ;
3. aucun projet JSON versionné ne contient un `eventRegistry` V2 ;
4. aucune migration V2 appliquée sur disque et aucun rollback multi-artifacts
   réel ne sont disponibles ;
5. aucun budget performance numérique n'est ratifié ;
6. les captures « état legacy » et « migration » exigées par le Visual Gate
   V2-41 n'existent pas ; les captures K ne remplacent pas cette preuve ;
7. aucun garde central n'interdit tous les writes MapEvent/Scenario legacy en
   `v2Only` ;
8. la suite complète editor échoue `+2961 -96` ;
9. les analyses runtime, editor et host sortent non nulles.

## 2. Droit de remise en cause du prompt

La demande « faire la Phase L » entre en tension avec le contrat du repository.
La Phase L exige explicitement : phases B à K validées, corpus stable et zéro
blocker. Le dépôt prouve l'inverse : G est `READY`, H/I/J restent non validées,
et le rapport K conclut `BLOCKED / NO-GO`.

L'interprétation retenue a donc été volontairement plus petite et plus sûre :

- compléter uniquement les preuves de validation manquantes qui ne changent
  aucun comportement produit ;
- exécuter V2-41 et V2-42 comme campagnes de preuve diagnostiques ;
- rendre V2-43 sous forme d'une décision NO-GO explicite ;
- ne pas absorber H, I, J ou K dans L ;
- ne pas corriger les domaines étrangers révélés par la régression complète.

Cette interprétation respecte le livrable final de la roadmap : « prêt ou
explicitement refusé avec blockers nommés ».

## 3. Scope exact et non-objectifs

### Inclus

- mesures p50/p95 dans les tests existants ;
- preuve directe no-fallback après consommation sous claim valide ;
- corpus, claims, migration planner/receipt, recovery et undo ciblés ;
- suites et analyses complètes des cinq surfaces explicitement V2-42 ;
- smokes runtime/host, matrice/capture K et builds macOS debug ;
- hashes, audit de route, décision de mode et de support V1 ;
- Evidence Pack et critique indépendante.

### Exclus et conservés

- aucune modification de production ;
- aucune activation de `EventBuilderV2Workspace` dans la route produit ;
- aucun modèle, codec ou schéma nouveau ;
- aucune migration ou mutation de Selbrume ;
- aucun budget temporel inventé ;
- aucune correction Pokémon SDK, Scenes/Storylines golden ou lint historique ;
- aucun changement `map_battle`, hors packages explicitement V2-42 ;
- aucune modification de roadmap par ce lot ;
- aucune opération Git d'écriture.

## 4. Roadmaps et statuts connexes

### Event Builder V2

| Jalon | Résultat technique frais | Statut formel proposé |
|---|---|---|
| V2-41 | corpus ciblé `201/201`, p50/p95 et no-fallback prouvés | **BLOCKED** |
| V2-42 | core/gameplay/runtime/host tests et builds partiellement verts ; editor/analyzes rouges | **BLOCKED** |
| V2-43 | décision explicite, mais blockers non nuls | **BLOCKED / NO-GO** |

V2-41 reste bloqué malgré ses tests ciblés : V2-33, V2-37 et V2-40 ne sont
pas acceptés, la migration disque n'existe pas et aucun budget ratifié ne peut
être comparé aux mesures. Son Visual Gate est également incomplet : aucune
capture dédiée de l'état legacy ou de la migration n'a été produite.

### Roadmap mécaniques fangame

Le lot recoupe les événements no-code et la release readiness, sans fermer ces
lots gameplay :

| Lot | Statut conservé | Raison |
|---|---|---|
| FG-080 Event Command Model V0 | `TODO` | Phase L n'ajoute aucun command model |
| FG-081 Condition Builder No-code V0 | `TODO` | aucune UI/evaluator étendu ici |
| FG-082 Runtime Command Executor V0 | `TODO` | aucun executor ajouté ici |
| FG-093 Action Builder UI V0 | `TODO` | workspace produit V2 non activé |
| FG-183 Regression Matrix V0 | `TODO` | campagne Event V2 utile mais matrice fangame globale non livrée |
| FG-185 MVP Release Gate V0 | `TODO` | golden slice fangame global non certifié |

## 5. Audit initial

### 5.1 État Git initial

```text
HEAD 2f68328a38bf218c843e497940f8dd24a7a9c194
tracked modified: 37
untracked: 80
total: 117
git diff --check: exit 0
packages/map_editor/test/failures: absent
selbrume/*.lock: absent
```

Le worktree était déjà fortement sale à cause des lots précédents. Toutes ces
modifications ont été préservées. Les cinq fichiers de test de la section 8
étaient propres au début de L.

### 5.2 Continuité de lots

- G est indiqué `READY`, pas `CLOSED` ;
- H est non validée et la route produit reste V1 ;
- I ne possède pas le coordinateur validator/migration UX V2-31/32/33 attendu ;
- J ne possède pas le Golden Selbrume V2 attendu ;
- K est explicitement `BLOCKED / NO-GO` dans son Evidence Pack ;
- L exige pourtant B à K validées et aucun blocker.

### 5.3 Route produit

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:553`
branche `EditorWorkspaceMode.events` sur :

```dart
Expanded(
  child: EventBuilderWorkspace(
```

`EventBuilderV2Workspace` n'est instancié que dans son harnais et ses tests.
Aucun branchement production n'a été trouvé.

### 5.4 Autorité et writes legacy editor

Les entrypoints legacy `EditorNotifier.addMapEventAt`,
`createEventBuilderDraftEventAt`, `updateMapEvent` et `deleteMapEvent` ne
consultent pas `EventSystemMode`. Le garde Scenario existant ne bloque que les
sources couvertes par des claims ; il ne constitue pas un verrou global
`v2Only`.

Masquer un CTA dans le workspace V2 ne prouve donc pas « aucun write legacy
depuis les entrypoints editor ».

### 5.5 Corpus disque

La recherche suivante ne retourne aucun fichier :

```text
rg -l '"eventRegistry"' --glob '*.json' packages examples selbrume
<none>
```

`selbrume/project.json`, le fixture runtime P3 et le fixture host P3 ont tous un
registry absent, donc un mode effectif legacy. Les registries V2 des tests sont
construits en mémoire.

### 5.6 Migration/rollback

Le planner, les receipts, les preconditions de révision/hash, le journal, la
recovery et l'undo sont bien testés séparément. Aucun consumer production du
planner de migration n'existe dans `map_editor` ou `map_runtime`. Il n'existe
donc aucun chemin prouvable : projet legacy disque → preview → confirmation →
write multi-artifacts → reload V2 → rollback de migration.

L'undo du seul registry n'est pas présenté comme un rollback de migration
multi-fichiers.

### 5.7 Performance et allowlist

Aucun budget temporel Event V2 numérique n'est défini. Les anciennes preuves
disent explicitement « informative only » ou « sans seuil ». Aucune allowlist
versionnée de warnings Event V2 n'existe ; seule la roadmap mentionne le mot.

### 5.8 Visual Gate V2-41

La roadmap exige des captures de l'état legacy et de la migration. Aucune de ces
captures n'est présente. Les baselines et captures de Phase K couvrent le
workspace V2 et sa stabilité visuelle ; elles ne démontrent ni l'ouverture V1
sans write, ni la preview, ni l'application ou le rollback d'une migration.

## 6. Hashes de corpus et références

| Fichier | SHA-256 |
|---|---|
| `packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json` | `6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c` |
| `packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.sha256` | `3b663ef48a710a009c57357aeda643b8427d2d3f96c1157877c6420f88fddbd9` |
| `packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json` | `5261faa8d45514197113f87cd3e59be26b7a1d3026c889435ba8efaced137a77` |
| `packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json` | `830736cbc64eae658e331ce114a368cce67e3249db1bf079af1a411e1af0f912` |
| `examples/playable_runtime_host/p3_narrative_smoke_slice/project.json` | `a8e768bdb9d40a51ff71783c9b13ab2ed75f4c9502c52620097728aaa8e8f2c3` |
| `examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json` | `21f9c3b97a3497ddae06fe689ecc65bd41f3dabcdea85ae992d4e8c5aab3e110` |
| `selbrume/project.json` | `e7a799b7dda8a5967323c1548e87c96a27d9f8b70d3c908ee721e6a19dd4f9a8` |
| candidat K `event_builder_v2_1672x941.png` | `d4632207b8db61670acefe0d3e3a347f978405d3fe519e0beeb1bed6d7bc9f1d` |
| north star externe 1672×941 | `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` |

Le candidat K et la north star ont des hashes différents. La matrice golden K
prouve la stabilité du candidat enregistré, pas l'acceptation visuelle finale
de la route produit.

## 7. Environnement

```text
Dart CLI: 3.12.1 stable, macos_arm64
Flutter: 3.46.0-0.3.pre, channel beta
Flutter tool Dart: 3.13.0-167.1.beta
Mode des benchmarks: JIT
```

La différence Dart CLI / Dart Flutter est documentée. Aucun `pub get` n'a été
lancé pour éviter de modifier des lockfiles ignorés ; les commandes Flutter ont
utilisé `--no-pub`.

## 8. Fichiers modifiés par Phase L

### 8.1 `packages/map_core/test/narrative_event_authoring_performance_test.dart`

- zone : helper `_measure`, lignes finales autour de 204–219 ;
- changement : conserve le p50 comme médiane existante et calcule le p95 par
  nearest-rank sur les samples triés ;
- impact : sortie explicite `p50_us`/`p95_us` ;
- diff : `+6/-1` ;
- non-impact : aucun seuil, aucune logique de production.

### 8.2 `packages/map_gameplay/test/narrative_event_runtime_performance_test.dart`

- zone : `_emitStats`, autour de 466–474 ;
- changement : expose `p50_us` comme alias explicite de la médiane existante ;
- impact : vocabulaire Phase L homogène ;
- diff : `+1/-0` ;
- compatibilité : `median_us` est conservé.

### 8.3 `packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart`

- zone : groupe principal après le test claim valide, autour de 117–152 ;
- changement : nouveau cas claim valide + oneShot consommé ;
- impact : verrouille `claimedButIneligible`, fallback faux et la liste ordonnée
  exacte `eventConsumed`, `claimTargetsIneligible`, `noEligibleCandidate` ;
- diff : `+37/-0` ;
- review : l'assertion initiale `containsAll` a été refusée puis durcie.

### 8.4 `packages/map_editor/test/event_registry_persistence_performance_test.dart`

- zone : `_emitMeasurement`, autour de 91–108 ;
- changement : p50/p95 + commentaire de frontière +
  `threshold=unconfigured` ;
- impact : mesure lisible sans faux PASS ;
- diff : `+9/-2`.

### 8.5 `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`

- zone : `_emitMeasurement`, autour de 223–244 ;
- changement : p50/p95 + commentaire « informative evidence » ;
- impact : mesures session/revalidation/recovery homogènes ;
- diff : `+7/-1`.

### 8.6 Fichiers documentaires créés

- `docs/superpowers/plans/2026-07-16-event-builder-phase-l-readiness.md` :
  plan local ignoré par Git ; contenu complet en annexe B ;
- `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md` :
  présent Evidence Pack. Il ne s'auto-recopie pas récursivement.

## 9. Diff exact des zones Phase L

```diff
diff --git a/packages/map_core/test/narrative_event_authoring_performance_test.dart b/packages/map_core/test/narrative_event_authoring_performance_test.dart
@@
   final median = samples.length.isOdd
       ? samples[samples.length ~/ 2].toDouble()
       : (samples[samples.length ~/ 2 - 1] + samples[samples.length ~/ 2]) / 2;
+  final p50 = median;
+  final p95Index = (samples.length * 0.95).ceil() - 1;
+  final p95 = samples[p95Index];
   stdout.writeln(
@@
-    'median_us=${median.toStringAsFixed(1)} mode=jit '
+    'median_us=${median.toStringAsFixed(1)} '
+    'p50_us=${p50.toStringAsFixed(1)} '
+    'p95_us=${p95.toStringAsFixed(1)} mode=jit '

diff --git a/packages/map_gameplay/test/narrative_event_runtime_performance_test.dart b/packages/map_gameplay/test/narrative_event_runtime_performance_test.dart
@@
     'mean_us=${stats.meanMicroseconds.toStringAsFixed(2)} '
     'median_us=${stats.medianMicroseconds.toStringAsFixed(2)} '
+    'p50_us=${stats.medianMicroseconds.toStringAsFixed(2)} '
     'p95_us=${stats.p95Microseconds.toStringAsFixed(2)} '

diff --git a/packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart b/packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart
@@
+  test('valid claim blocks fallback when its oneShot target is consumed', () {
+    final source = NarrativeEventSourceRef.mapEnter('map');
+    final provenance = LegacySourceRef.mapEvent('map', 'legacy');
+    final claim = _claim(source, provenance, [_eventA]);
+    final registry = _registry(
+      EventSystemMode.dualRead,
+      records: [_record(_eventA, source)],
+      claims: [claim],
+    );
+
+    final decision = NarrativeEventDispatchPlanner().plan(
+      authority: _prepare(
+        registry,
+        source,
+        provenance: provenance,
+        claimIndex: _runtimeIndex(registry, source, provenance),
+      ),
+      gameState: GameState(
+        saveId: 'save',
+        narrativeEventProgress: NarrativeEventProgress(
+          consumedNarrativeEventIds: {_eventA},
+        ),
+      ),
+    );
+
+    expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
+    expect(decision.legacyFallbackAllowed, isFalse);
+    expect(
+      decision.reasons,
+      orderedEquals([
+        NarrativeEventDispatchReason.eventConsumed,
+        NarrativeEventDispatchReason.claimTargetsIneligible,
+        NarrativeEventDispatchReason.noEligibleCandidate,
+      ]),
+    );
+  });

diff --git a/packages/map_editor/test/event_registry_persistence_performance_test.dart b/packages/map_editor/test/event_registry_persistence_performance_test.dart
@@
+  final p50 = median;
+  final p95Index = (sorted.length * 0.95).ceil() - 1;
+  final p95 = sorted[p95Index];
+  // Phase L records measurements here; no performance budget is configured.
@@
+    'p50_us=${p50.toStringAsFixed(1)} '
+    'p95_us=${p95.toStringAsFixed(1)} mode=jit '
@@
-    'complexity=linear_in_scanned_bytes_and_artifacts aot=not_measured',
+    'complexity=linear_in_scanned_bytes_and_artifacts aot=not_measured '
+    'threshold=unconfigured',

diff --git a/packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart b/packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
@@
+  final p50 = median;
+  final p95Index = (sorted.length * 0.95).ceil() - 1;
+  final p95 = sorted[p95Index];
+  // Phase L observations are informative evidence, not a budget PASS.
@@
+    'p50_us=${p50.toStringAsFixed(1)} '
+    'p95_us=${p95.toStringAsFixed(1)} bytes_read=$bytesRead '
```

## 10. Tests ciblés V2-41

### 10.1 Core

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test --reporter=compact test/narrative_event_legacy_corpus_test.dart test/narrative_event_migration_planner_test.dart test/narrative_event_migration_integrity_closure_test.dart test/narrative_event_migration_receipt_test.dart test/narrative_event_migration_receipt_codec_test.dart test/narrative_event_dispatch_authority_test.dart test/validated_legacy_claim_index_runtime_readiness_test.dart test/narrative_event_authoring_performance_test.dart
```

Résultat : exit `0`, `+134`, `All tests passed!`.

### 10.2 Gameplay

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart test --reporter=compact test/narrative_event_dispatch_truth_table_test.dart test/narrative_event_execution_coordinator_test.dart test/narrative_event_runtime_performance_test.dart
```

Résultat : exit `0`, `+10`, `All tests passed!`.

### 10.3 Runtime

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test --no-pub --reporter=compact test/narrative_event_legacy_runtime_characterization_test.dart test/playable_map_game_event_v2_boot_integration_test.dart test/narrative_event_runtime_snapshot_test.dart
```

Résultat : exit `0`, `+8`, `All tests passed!`.

### 10.4 Editor persistence/recovery

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test --no-pub --reporter=compact test/event_registry_repository_test.dart test/event_registry_recovery_test.dart test/event_registry_recovery_gate_test.dart test/event_registry_undo_test.dart test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_snapshot_performance_test.dart
```

Résultat : exit `0`, `+49`, `All tests passed!`.

Total ciblé : **201 tests passants**.

### 10.5 Revalidation finale des cinq fichiers Phase L

Après les corrections documentaires demandées par la critique, les cinq fichiers
de test ont été reformatés, relancés et analysés sans modifier le code :

```bash
cd /Users/karim/Project/pokemonProject && dart format --output=none --set-exit-if-changed packages/map_core/test/narrative_event_authoring_performance_test.dart packages/map_gameplay/test/narrative_event_runtime_performance_test.dart packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart packages/map_editor/test/event_registry_persistence_performance_test.dart packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_core && /usr/bin/time -p dart test --reporter=compact test/narrative_event_authoring_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && /usr/bin/time -p dart test --reporter=compact test/narrative_event_dispatch_truth_table_test.dart test/narrative_event_runtime_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter test --no-pub --reporter=compact test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_snapshot_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze test/narrative_event_authoring_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart analyze test/narrative_event_dispatch_truth_table_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart analyze test/narrative_event_runtime_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub test/event_registry_persistence_performance_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub test/narrative_event_authoring_snapshot_performance_test.dart
```

Résultats exacts : format exit `0`, `5 files (0 changed)` ; core exit `0`,
`+1`, `All tests passed!` ; gameplay exit `0`, `+6`, `All tests passed!` ;
editor exit `0`, `+2`, `All tests passed!` ; cinq analyses ciblées exit `0`,
`No issues found!`. Cette relance ciblée complète, sans remplacer, la campagne
V2-41 de `201/201`.

## 11. Métriques V2-41

### Core authoring, 10 000 records

```text
draft_create                         p50_us=236730.0 p95_us=252657.0
source_replace                       p50_us=239877.0 p95_us=242897.0
condition_graph_cycle_validation     p50_us=170570.0 p95_us=180367.0
publication                          p50_us=254983.0 p95_us=261595.0
activation_conflict_lookup           p50_us=279095.0 p95_us=280206.0
registry_json_patch                  p50_us=92531.0  p95_us=94334.0
```

### Gameplay runtime, volume 10 000

```text
planner/one_source                   p50_us=244.00   p95_us=393.00
planner/multiple_sources             p50_us=181.00   p95_us=259.00
planner/conditions_all_true          p50_us=162.00   p95_us=207.00
planner/first_condition_false        p50_us=4730.00  p95_us=5678.00
planner/one_shot_consumed            p50_us=3002.00  p95_us=6295.00
planner/claim_valid                  p50_us=156.00   p95_us=1936.00
planner/tombstone_local              p50_us=0.00     p95_us=0.00
progress_codec/consumed              p50_us=11389.00 p95_us=12067.00
progress_codec/pending               p50_us=35549.00 p95_us=44718.00
outbox_processor/one_fifo_head       p50_us=16864.00 p95_us=19718.00
```

### Editor

```text
journaled_write volume=1             p50_us=16267.0  p95_us=43938.0 threshold=unconfigured
recovery_scan volume=1               p50_us=9337.0   p95_us=15268.0 threshold=unconfigured
recovery_scan volume=100             p50_us=238549.0 p95_us=257946.0 threshold=unconfigured
session_prepare volume=500           p50_us=296245.0 p95_us=321720.0 threshold=informative_only
final_map_revalidation_workload volume=500 p50_us=168205.0 p95_us=199251.0 threshold=informative_only
recovery_gate_scan volume=100        p50_us=86546.0  p95_us=100111.0 threshold=informative_only
```

Ces nombres sont des observations JIT. Avec 3, 5, 7, 9 ou 15 samples, le p95
nearest-rank est souvent le maximum observé. Il est donc sensible au scheduling.
Le champ `iterations` est conservé et aucune mesure n'est convertie en PASS.
Augmenter les samples ne remplacerait pas la ratification manquante de la
machine, du toolchain, du mode JIT/AOT et des budgets.

## 12. Matrice complète V2-42

| Commande | Exit | Résultat exact |
|---|---:|---|
| `packages/map_core: dart test --reporter=compact` | 0 | `+2987`, all passed |
| `packages/map_core: dart analyze` | 0 | `No issues found!` |
| `packages/map_gameplay: dart test --reporter=compact` | 0 | `+283`, all passed |
| `packages/map_gameplay: dart analyze` | 0 | `No issues found!` |
| `packages/map_runtime: flutter test --no-pub --reporter=compact` | 0 | `+1769`, un skip indiqué, 0 failure |
| `packages/map_runtime: flutter analyze --no-pub` | 1 | `347 issues found` |
| runtime smoke battle | 0 | `3/3` |
| `packages/map_editor: flutter test --no-pub --reporter=compact` | 1 | terminal `+2961 -96` |
| `packages/map_editor: flutter analyze --no-pub` | 1 | `451 issues found` |
| matrice fonctionnelle/visuelle K | 0 | `54/54` |
| capture K sans update golden | 0 | `3/3` |
| build editor macOS debug | 0 | app construite |
| host full test | 0 | `50/50` |
| host analyze | 1 | `1 issue found` |
| host smoke | 0 | `1/1` |
| build host macOS debug | 0 | app construite |

### 12.1 Commandes littérales exécutées

Les commandes ci-dessous sont celles remontées par les validateurs, avec leur
répertoire de travail rendu explicite. Les logs bruts complets n'ont pas été
persistés dans le dépôt ; les codes de sortie et résumés terminaux exacts sont
conservés dans la matrice ci-dessus.

Core :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test --reporter=compact
cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze
```

Gameplay :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart test --reporter=compact
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart analyze
```

Runtime :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /usr/bin/time -p flutter test --no-pub --reporter=compact
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /usr/bin/time -p flutter analyze --no-pub
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /usr/bin/time -p flutter test --no-pub --reporter=compact test/phase_a_golden_battle_slice_smoke_test.dart
```

Editor :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter test --no-pub --reporter=compact
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter test --no-pub --reporter=expanded test/scene_cinematic_picker_test.dart --plain-name 'writes V1-39 cinematic Scene Builder picker screenshot'
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter analyze --no-pub
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter test --no-pub --concurrency=1 test/ui/canvas/event_builder_v2_phase_k_visual_test.dart test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/narrative_event_builder_v2_state_test.dart test/narrative_event_builder_v2_session_snapshot_test.dart test/ui/design_system/pokemap_button_test.dart test/ui/design_system/pokemap_search_field_test.dart test/ui/design_system/pokemap_diagnostic_callout_test.dart test/ui/design_system/pokemap_desktop_side_sheet_test.dart test/ui/design_system/pokemap_card_panel_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter test --no-pub --concurrency=1 --dart-define=NS_EVENT_V2_PHASE_K_CAPTURE=true test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && /usr/bin/time -p flutter build macos --debug --no-pub
```

Host :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /usr/bin/time -p flutter test --no-pub --reporter=compact
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /usr/bin/time -p flutter analyze --no-pub
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /usr/bin/time -p flutter test --no-pub --reporter=compact test/phase_a_golden_slice_launch_test.dart
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /usr/bin/time -p flutter build macos --debug --no-pub
```

### 12.2 Premiers diagnostics rouges

- runtime analyze :
  `lib/src/application/script_command_executor.dart:59:14 — prefer_const_constructors` ;
- editor full :
  `scene_cinematic_picker_test.dart`, test
  `writes V1-39 cinematic Scene Builder picker screenshot`, golden diff
  `1.09% / 22593px` ; relance isolée exit `1`, `0/1` ;
- editor analyze :
  `pokemon_sdk_move_catalog_converter.dart:58:7 — undefined_named_parameter`,
  paramètre `dbSymbol` ;
- host analyze :
  `test/runtime_pokedex_loader_test.dart:31:9 — prefer_const_constructors`.

Ces sources ne sont pas causées par les cinq tests Phase L, mais V2-42 exige
zéro failure. Elles ne peuvent pas être neutralisées implicitement.

### 12.3 Builds

```text
packages/map_editor/build/macos/Build/Products/Debug/map_editor.app
examples/playable_runtime_host/build/macos/Build/Products/Debug/playable_runtime_host.app
```

Les deux builds passent. Un build vert ne compense pas un test ou une analyse
rouge.

### 12.4 Artefacts transitoires

Le full editor a créé 92 fichiers sous `packages/map_editor/test/failures` et un
lock `selbrume/.pokemap-project-1f1a60297a27b0b0.lock`. La relance isolée a
créé quatre fichiers de failure supplémentaires. Tous ont été inventoriés puis
supprimés, exclusivement parce qu'ils provenaient de cette campagne.

Contrôle final :

```text
packages/map_editor/test/failures: absent
selbrume/*.lock: 0
git diff --check: exit 0, aucune sortie
```

## 13. Décision V2-43

```text
EVENT BUILDER V2 RELEASE: NO-GO
DEFAULT V2 ACTIVATION: INTERDITE
PASSAGE PROJET EN v2Only: INTERDIT
V1 DEPRECATION: NON DÉMARRÉE
LEGACY READERS/IMPORTERS: CONSERVÉS
CURRENT MODE / ROLLBACK PATH: CONSERVÉS
```

### Raisons déterminantes

- entry criteria L faux ;
- V2-41 sans budget ratifié, migration disque réelle ou captures legacy/migration ;
- V2-42 avec quatre commandes obligatoires non nulles ;
- route Events produit V1 ;
- aucun corpus JSON V2 disque ;
- absence de guard central contre tout authoring legacy en `v2Only` ;
- K encore NO-GO visuel et fonctionnel.

Le rollback n'est promis que tant que les preconditions de receipt/révision
restent vraies et qu'aucune donnée V2-only non représentable n'a été publiée.
Aucun projet réel n'a été basculé par ce lot.

## 14. Verdicts des sub-agents et reviews

| Passe | Verdict | Signal utile |
|---|---|---|
| Audit / Architecture | NO-GO | G non close, H/I/J non validées, K bloquée, route V1 |
| Tests / inventaire | NO-GO entry | budgets, migration E2E et guard v2Only manquants |
| Build / validation audit | NO-GO entry | V2-42 ne doit pas être confondu avec un diagnostic |
| Implémentation | DONE | cinq tests seulement, ciblés verts |
| Spec review initiale | CHANGES REQUESTED | assertion `containsAll` trop faible |
| Spec re-review | PASS | raisons ordonnées exactes |
| Code quality parent | APPROVED | aucun finding actionnable |
| Review perf contradictoire | RISK ACCEPTED, pas PASS budget | p95 petit sample = maximum ; alias p50=median documenté |
| Tests frais V2-41 | PASS ciblé | `201/201` |
| Full Dart validation | PASS limité | core/gameplay tests et analyses verts |
| Full Flutter validation | NO-GO V2-42 | editor full/analyzes non nuls |
| Critique finale initiale | CHANGES REQUESTED | commandes exactes, Visual Gate et libellés demandés |
| Critique finale re-review | APPROVED | corrections vérifiées ; aucun finding substantiel restant |

Le finding performance n'est pas masqué. Il n'a pas été « corrigé » par une
hausse arbitraire d'itérations : sans environnement et budget ratifiés, cela
aurait seulement produit une mesure plus coûteuse, toujours non contractuelle.

## 15. Auto-critique

### Ce qui est solide

- le lot ne prétend pas fermer L ;
- aucune production n'a été modifiée ;
- le test no-fallback combine enfin claim valide et oneShot consommé ;
- les sorties p50/p95 restent compatibles et explicitement informatives ;
- les commandes rouges ont été conservées comme blockers ;
- les artefacts de tests ont été nettoyés sans toucher aux changements user ;
- aucune roadmap ni donnée projet n'a été réécrite.

### Limites et risques

- le corpus V2 disque manque complètement ;
- le worktree sale rend la notion de release candidate faible, même avec un
  snapshot initial/final précis ;
- p95 est statistiquement fragile aux petits nombres de samples ;
- aucune preuve AOT ;
- les analyses Flutter non nulles ne disposent d'aucune allowlist ratifiée ;
- les captures legacy/migration exigées par V2-41 sont absentes ;
- les 96 failures editor ne sont pas toutes isolées ; la première a été
  reproduite, ce qui suffit déjà à bloquer le gate ;
- la stabilité du candidat K n'est pas la fidélité de la route produit ;
- les builds debug ne prouvent pas un package release distribué.

### Risque de mensonge produit évité

Le plus grand risque aurait été de déclarer L terminée parce que les tests Event
V2 ciblés passent. Cela aurait masqué une route produit V1, un corpus V2 absent,
une migration inexistante et un gate editor rouge. Ce rapport interdit
explicitement cette conclusion.

## 16. Prochain lot recommandé — sans l'implémenter ici

Revenir séquentiellement au premier gate non fermé :

1. clôturer G avec ses preuves Map Editor bridge ;
2. terminer H et brancher honnêtement la route V2 avec mode/authoring guards ;
3. livrer I, dont migration UX et guard central `v2Only` ;
4. créer et exercer le corpus Golden Selbrume de J ;
5. fermer K sur la route produit, états/accessibilité et comparaison north star ;
6. ratifier ensuite budgets/environnement/allowlist ;
7. seulement alors rejouer L depuis un candidat stable.

## 17. État Git final

Après création du présent rapport, le statut attendu et vérifié doit être :

```text
HEAD 2f68328a38bf218c843e497940f8dd24a7a9c194
tracked modified: 42
untracked: 81
total: 123
```

Diff Phase L attribuable : cinq fichiers de test modifiés et un Evidence Pack
non suivi. Le plan local est ignoré. Tous les autres changements sont
préexistants à Phase L et restent intacts.

Aucune commande `git add`, `commit`, `push`, `checkout`, `switch`, `stash`,
`reset`, `restore`, `merge`, `rebase`, `tag`, `branch` ou `worktree` n'a été
exécutée.

## Annexe A — Commandes de contrôle final

```text
git rev-parse HEAD
git status --short --untracked-files=all
git diff --check
find packages/map_editor/test -maxdepth 2 -type d -name failures -print
find selbrume -maxdepth 1 -type f -name '*.lock' -print
```

## Annexe B — Contenu complet du plan créé

```markdown
# Event Builder V2 Phase L Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to execute this plan task-by-task, then `verification-before-completion`. The repository forbids Git writes without explicit user permission, so every commit/worktree step from the generic workflow is intentionally omitted.

**Goal:** Produce the honest NS-EVENT-V2-41…43 readiness evidence, fill only the missing measurement/no-fallback test coverage, execute the release-candidate matrix, and return an explicit GO or NO-GO without activating V2 or deprecating V1.

**Architecture:** Phase L remains a validation-only lot. Production models, runtime dispatch, Selbrume content, and the editor route are not changed here; test surfaces gain explicit p50/p95 output and a consumed-one-shot no-fallback guard, while the final report records upstream blockers and fresh command evidence.

**Tech Stack:** Dart `package:test`, Flutter test runner, existing Event V2 core/gameplay/editor/runtime contracts, Markdown Evidence Pack.

---

### Task 1: Normalize Phase L performance evidence

**Files:**

- Modify: `packages/map_core/test/narrative_event_authoring_performance_test.dart`
- Modify: `packages/map_gameplay/test/narrative_event_runtime_performance_test.dart`
- Modify: `packages/map_editor/test/event_registry_persistence_performance_test.dart`
- Modify: `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart`

- [ ] **Step 1: Add explicit p50 and p95 calculation to the core authoring measurement helper**

  Keep the existing warmup and samples. After sorting, derive p50 from the current median formula and p95 with `(samples.length * 0.95).ceil() - 1`; emit both `p50_us` and `p95_us`. Preserve `median_us` only if an existing report/parser may consume it.

- [ ] **Step 2: Expose the existing gameplay median as p50**

  In `_emitStats`, add `p50_us=${stats.medianMicroseconds.toStringAsFixed(2)}` alongside the existing `median_us` and `p95_us` fields. Do not add a timing threshold.

- [ ] **Step 3: Add p50/p95 to editor persistence and snapshot measurements**

  Use the same sorted-sample percentile rule in both test helpers. Emit `threshold=unconfigured` or preserve `threshold=informative_only`; never claim a budget passes because no release budget exists in the roadmap or ADR.

- [ ] **Step 4: Format and run the four focused performance tests**

  Run:

  ```bash
  cd packages/map_core && dart format test/narrative_event_authoring_performance_test.dart && dart test test/narrative_event_authoring_performance_test.dart
  cd packages/map_gameplay && dart format test/narrative_event_runtime_performance_test.dart && dart test test/narrative_event_runtime_performance_test.dart
  cd packages/map_editor && dart format test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_snapshot_performance_test.dart && flutter test test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_snapshot_performance_test.dart
  ```

  Expected: every test passes and every relevant measurement line contains explicit `p50_us` and `p95_us` fields. The result remains a measurement, not a budget PASS.

### Task 2: Close the consumed-event no-fallback proof

**Files:**

- Modify: `packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart`

- [ ] **Step 1: Add the missing guard case**

  Add a test that prepares a `dualRead` registry containing one enabled one-shot Event and a validated legacy claim for the occurrence source, supplies `NarrativeEventProgress(consumedNarrativeEventIds: {_eventA})`, and asserts:

  ```dart
  expect(decision, isA<NarrativeEventDispatchClaimedButIneligible>());
  expect(decision.legacyFallbackAllowed, isFalse);
  expect(
    decision.reasons,
    orderedEquals([
      NarrativeEventDispatchReason.eventConsumed,
      NarrativeEventDispatchReason.claimTargetsIneligible,
      NarrativeEventDispatchReason.noEligibleCandidate,
    ]),
  );
  ```

  Use the actual enum member exposed by the current contract if its spelling differs; do not change production code just to match this plan prose.

- [ ] **Step 2: Run the truth-table regression**

  Run:

  ```bash
  cd packages/map_gameplay && dart format test/narrative_event_dispatch_truth_table_test.dart && dart test test/narrative_event_dispatch_truth_table_test.dart
  ```

  Expected: legacyOnly still allows fallback, unclaimed dualRead behaves as before, and a valid claim whose target is already consumed returns claimed-but-ineligible with fallback forbidden.

### Task 3: Execute NS-EVENT-V2-41 evidence

**Files:**

- Create: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`

- [ ] **Step 1: Pin the corpus and project hashes**

  Record SHA-256 for the legacy corpus, its checksum file, the V2 runtime bridge fixture, the host narrative fixture, `selbrume/project.json`, the Phase K reference capture, and the Phase K candidate capture.

- [ ] **Step 2: Run the core corpus/migration/receipt/authority suites**

  ```bash
  cd packages/map_core && dart test test/narrative_event_legacy_corpus_test.dart test/narrative_event_migration_planner_test.dart test/narrative_event_migration_integrity_closure_test.dart test/narrative_event_migration_receipt_test.dart test/narrative_event_migration_receipt_codec_test.dart test/narrative_event_dispatch_authority_test.dart test/validated_legacy_claim_index_runtime_readiness_test.dart test/narrative_event_authoring_performance_test.dart
  ```

- [ ] **Step 3: Run gameplay/runtime authority and no-fallback suites**

  ```bash
  cd packages/map_gameplay && dart test test/narrative_event_dispatch_truth_table_test.dart test/narrative_event_execution_coordinator_test.dart test/narrative_event_runtime_performance_test.dart
  cd packages/map_runtime && flutter test test/narrative_event_legacy_runtime_characterization_test.dart test/playable_map_game_event_v2_boot_integration_test.dart test/narrative_event_runtime_snapshot_test.dart
  ```

- [ ] **Step 4: Run editor persistence/recovery/rollback suites**

  ```bash
  cd packages/map_editor && flutter test test/event_registry_repository_test.dart test/event_registry_recovery_test.dart test/event_registry_recovery_gate_test.dart test/event_registry_undo_test.dart test/event_registry_persistence_performance_test.dart test/narrative_event_authoring_snapshot_performance_test.dart
  ```

- [ ] **Step 5: Decide V2-41 strictly**

  Mark V2-41 `BLOCKED` unless dependencies V2-08/V2-33/V2-37/V2-40 are all accepted, an actual zero-loss migration and revision-gated rollback have been exercised on the required corpus, and explicit release budgets exist and pass. Passing component tests alone is not sufficient.

### Task 4: Execute NS-EVENT-V2-42 release-candidate matrix

**Files:**

- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`

- [ ] **Step 1: Run every package test and analyze command from its package directory**

  ```bash
  cd packages/map_core && dart test && dart analyze
  cd packages/map_gameplay && dart test && dart analyze
  cd packages/map_runtime && flutter test && flutter analyze
  cd packages/map_editor && flutter test && flutter analyze
  cd examples/playable_runtime_host && flutter test && flutter analyze
  ```

- [ ] **Step 2: Run host/runtime smokes and visual baselines**

  ```bash
  cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
  cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
  cd packages/map_editor && flutter test test/ui/canvas/event_builder_v2_phase_k_visual_test.dart test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart
  ```

- [ ] **Step 3: Build both desktop applications**

  ```bash
  cd packages/map_editor && flutter build macos --debug
  cd examples/playable_runtime_host && flutter build macos --debug
  ```

- [ ] **Step 4: Check for unexpected generated diffs and isolate failures**

  Run `git diff --check`, record `git status --short --untracked-files=all`, and rerun any newly suspicious failing test in isolation. Remove only transient artifacts created by these commands, never user changes.

- [ ] **Step 5: Decide V2-42 strictly**

  Any test/analyze/build/visual failure or V2-41 non-PASS keeps V2-42 `BLOCKED`; do not fix unrelated domains inside this gate.

### Task 5: Issue NS-EVENT-V2-43 decision and final review

**Files:**

- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`

- [ ] **Step 1: Record the production-route and content proofs**

  Cite the exact Events route widget, every production use of `EventBuilderV2Workspace`, current Selbrume `eventRegistry` state, open H/I/J/K blockers, and V1/V2 reader/authoring behavior.

- [ ] **Step 2: Make one explicit decision**

  Emit `GO` only if blockers are zero and V2-41/V2-42 pass. Otherwise emit `NO-GO`, keep the current mode/readers, forbid default `v2Only`, and state that V1 deprecation has not started.

- [ ] **Step 3: Run independent spec and quality reviews**

  Review the changed tests first against V2-41, then review code quality and the entire Evidence Pack for false claims, missing command evidence, accidental scope expansion, and user-visible dishonesty.

- [ ] **Step 4: Complete the report required by `codex_rule.md`**

  Include initial/final Git states, audit, all sub-agent verdicts, every changed file and precise diff zone, complete contents of each created text file, exact command/result lines, known limits, self-critique, and recommended upstream next lot. Do not edit the roadmap unless the user explicitly asks.
```

## Annexe C — Diff attribuable à Phase L

Le statut complet est conservé dans la sortie de validation de cette phase. Les
six entrées attribuables à L sont :

```text
 M packages/map_core/test/narrative_event_authoring_performance_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart
 M packages/map_gameplay/test/narrative_event_runtime_performance_test.dart
?? reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md
```

Les 117 autres entrées du snapshot final sont préexistantes à Phase L et sont
listées par `git status --short --untracked-files=all`; aucune n'a été cachée,
restaurée ou nettoyée par ce lot.

## Annexe L4.11 — Reproduction exacte du plan créé

```markdown
# Event Builder V2 Final Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining Event Builder V2 visual and release-readiness work with a real 1672 × 941 product-route proof grounded in the supplied north star, focused regression coverage, and an honest final GO/NO-GO decision.

**Architecture:** Keep `map_core` as the source of Event V2 data and projections, `map_editor` as the no-code authoring surface, and the existing Narrative Studio route as the production UI. The final visual fixture must exercise the on-disk authoring session and the real `EditorShellPage`/Events route; the Phase K visual harness remains a focused component baseline, not release proof. Phase L remains validation-first: only attributable release blockers may be fixed, and V1 remains available unless every V2 gate passes.

**Tech Stack:** Dart, Flutter desktop, Riverpod, PokeMap design-system widgets/tokens, Flutter widget/golden tests, package-scoped `dart test`/`flutter test`/`analyze`, macOS debug builds, raster comparison at 1672 × 941.

---

## Task 1 — Freeze the current baseline and define truthful closure evidence

**Files:**

- Read: `MVP Selbrume/road_map_event_builder_v2.md`
- Read: `MVP Selbrume/road_map_event_builder_v2_execution.md`
- Read: `reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md`
- Read: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`
- Read: `design-qa.md`
- Modify: this plan only for checkbox progress

- [ ] **Step 1:** Record read-only Git baseline (`HEAD`, tracked/untracked counts, relevant file inventory) without modifying Git state.
- [ ] **Step 2:** Classify existing Phase K/L changes as pre-existing versus attributable to this closure pass.
- [ ] **Step 3:** Confirm relevant mechanics lots (`FG-080`, `FG-081`, `FG-082`, `FG-093`, `FG-183`, `FG-185`) and keep their status truthful unless their own done criteria receive fresh proof.
- [ ] **Step 4:** Pin the supplied 1672 × 941 reference and current product-route screenshot hashes.

## Task 2 — Add a real full-shell product capture contract

**Files:**

- Modify: `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
- Create/refresh: `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`

- [ ] **Step 1:** Add a widget test that pumps the on-disk fixture through `EditorShellPage`, selects the canonical port event, and asserts that the full surface is exactly 1672 × 941.
- [ ] **Step 2:** Run that test before adding the helper and observe the expected RED failure.
- [ ] **Step 3:** Add the smallest reusable full-shell pump helper, preserving the real read-model/validation/provider seams already used by the product-route fixture.
- [ ] **Step 4:** Switch the visual capture fixture to `EventSystemMode.v2Only` so the final-state proof is not obscured by migration UI.
- [ ] **Step 5:** Run the focused product-route test and retain the first real full-shell screenshot as the visual before-state.

## Task 3 — Make the on-disk Selbrume fixture representative of the north star

**Files:**

- Modify: `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
- Test: `packages/map_editor/test/narrative_event_builder_v2_state_test.dart`
- Test: `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`

- [ ] **Step 1:** Add RED assertions that the selected real product event exposes two resolved conditions, a linked scene with outcomes/consequences/world changes, one-shot lifecycle, and the expected Port Selbrume source.
- [ ] **Step 2:** Extend only the test project data needed to produce those summaries through the production read-model builder; do not inject a synthetic `NarrativeEventBuilderProjectReadModel`.
- [ ] **Step 3:** Add enough realistic map groups/events to exercise the target density while keeping every source backed by a real entity or zone already present in a fixture map.
- [ ] **Step 4:** Re-run the fixture/read-model tests and verify the selected event is stable and no unsupported authoring is implied.

## Task 4 — Close responsive diagnostics and supported Phase K P1 gaps with TDD

**Files:**

- Modify only as proven necessary: `packages/map_editor/lib/src/ui/canvas/events_v2/`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`
- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`

- [ ] **Step 1:** Add a RED test reproducing the real 800 × 632 diagnostics/migration bottom overflow.
- [ ] **Step 2:** Fix the overflow with existing PokeMap layout primitives/tokens and verify 800, 1280, 1440, 1480, 1672 and wide desktop sizes.
- [ ] **Step 3:** Add focused RED contracts for only the target details supported by current domain data: condition summary visibility, outcome-to-projection continuity, reuse policy and priority visibility.
- [ ] **Step 4:** Implement the smallest truthful UI/read-model presentation needed; keep Scene-owned branches and consequences read-only and do not create fake draggable authoring.
- [ ] **Step 5:** Run focused Event Builder V2 tests after each change and stop if a requested reference detail requires a new gameplay model outside Phase K.

## Task 5 — Compare the real product route and iterate through Design QA

**Files:**

- Refresh: `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/product_before_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/product_after_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_1672x941.png`
- Create/refresh: `reports/narrativeStudio/events/phase_k_product_route_evidence/reference_vs_product_after_overlay_50.png`
- Modify: `design-qa.md`

- [ ] **Step 1:** Capture the reference and real product at the same 1672 × 941 viewport and selected-event state.
- [ ] **Step 2:** Build a side-by-side and 50% overlay from those exact images.
- [ ] **Step 3:** Review layout, density, type, colors, icons, surfaces, interaction states, text scaling and responsiveness against the QA rubric.
- [ ] **Step 4:** Fix every attributable P0/P1/P2 using design-system components/tokens, then capture and compare again.
- [ ] **Step 5:** Mark Design QA `passed` only if no actionable P0/P1/P2 remains; otherwise record the exact blocker and keep Phase K non-DONE.

## Task 6 — Execute the Phase K and L verification gates

**Files:**

- Test: all Event Builder V2/core/runtime/host surfaces named by the Phase K/L plans
- Modify only for attributable blockers: impacted tests/production files

- [ ] **Step 1:** Run formatting checks for every changed Dart file.
- [ ] **Step 2:** Run the focused Phase K/V2/design-system widget matrix and all V1 regression groups.
- [ ] **Step 3:** Run the V2-41 legacy corpus, migration/recovery, no-fallback and performance-evidence suites.
- [ ] **Step 4:** Run package tests and analyzes for `map_core`, `map_gameplay`, `map_runtime`, `map_editor`, and `examples/playable_runtime_host`.
- [ ] **Step 5:** Run the macOS editor build and the required runtime/host smoke tests.
- [ ] **Step 6:** For failures, prove attribution before editing. Fix only a small shared root that blocks Event Builder release; classify unrelated baseline failures explicitly.

## Task 7 — Update roadmaps and Evidence Packs with final, reviewable truth

**Files:**

- Modify: `MVP Selbrume/road_map_event_builder_v2_execution.md`
- Modify only when evidence permits: `MVP Selbrume/road_map_event_builder_v2.md`
- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_k_pixel_closure_evidence_pack.md`
- Modify: `reports/narrativeStudio/events/ns_event_v2_phase_l_final_readiness_evidence_pack.md`
- Modify: `design-qa.md`

- [ ] **Step 1:** Re-read `codex_rule.md` immediately before writing the closure reports.
- [ ] **Step 2:** Record initial audit and the independent Audit/Architecture, Implementation, Tests, Build/Validation and Final Critique verdicts.
- [ ] **Step 3:** Include exact file inventory, precise changed zones, full content for newly created text files, exact commands/results, hashes, initial/final Git status, limits and self-critique.
- [ ] **Step 4:** Update K/L and execution-roadmap statuses strictly from fresh evidence; never turn a targeted green suite into a global GO.
- [ ] **Step 5:** Keep V1 deprecation inactive unless V2-41 and V2-42 both pass and V2-43 has zero blockers.
- [ ] **Step 6:** Request final specification and code-quality reviews, address blockers, and rerun affected checks.
- [ ] **Step 7:** Propose the final Git checkpoint but perform no `git add`, commit, push, branch, stash, reset or worktree operation without new explicit authorization.
```
