# NS-EVENT-19 - Event Builder Central Blocks Layout V0

## 1. Resume executif

NS-EVENT-19 est DONE.

Le lot installe un builder central vertical en blocs pour l'Event Builder, sans ajouter de nouvelle capacite metier. L'ecran passe d'une fiche detail monolithique a un flow plus proche de l'image cible :

```text
Quand  -> Declencheur
Si     -> Conditions
Alors  -> Action principale
Puis   -> Comportement
Puis   -> Changements du monde
Statut -> Diagnostics
```

Les controles existants restent branches :

- type de declencheur ;
- conditions Fact ;
- conditions Event consumed ;
- action principale Scene ;
- behavior oneShot / reusable ;
- diagnostics.

Non-objectifs respectes :

- pas de bibliotheque d'elements ;
- pas de drag/drop ;
- pas de Resultats/Reactions authorables ;
- pas de bloc terminal Fin dans ce lot apres revue ;
- pas de modification core/runtime/gameplay/battle/Selbrume.

## 2. Contexte et decision produit

NS-EVENT-18 a rendu la creation compacte. NS-EVENT-19 peut donc donner plus de poids visuel a l'evenement selectionne.

Decision :

- creer un conteneur central `EventBuilderCentralFlow` ;
- creer un bloc reutilisable `EventBuilderFlowBlock` ;
- garder l'identite de l'event en entete de flow ;
- laisser les informations techniques en bas, encore dans le meme panneau, car le split inspecteur est le lot suivant ;
- ne pas ouvrir la bibliotheque, les slots ou le drag/drop.

Le premier reviewer sub-agent a signale que le bloc `Fin de l'événement` ajoutait un element hors scope strict. Il a ete retire avant validation finale.

## 3. Fichiers crees

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
```

## 4. Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Note worktree : NS-EVENT-17 et NS-EVENT-18 etaient deja presents en fichiers non suivis dans le meme worktree. Le diff stat Git ne liste que les fichiers suivis modifies ; les nouveaux fichiers NS-EVENT-18/19 apparaissent dans `git status`.

## 5. Code complet des nouveaux fichiers

### event_builder_central_flow.dart

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderCentralFlow extends StatelessWidget {
  const EventBuilderCentralFlow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eventHeader,
    required this.blocks,
  });

  final String title;
  final String subtitle;
  final Widget eventHeader;
  final List<Widget> blocks;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-central-flow'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.flowchart,
                  tone: PokeMapTone.quest,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            eventHeader,
            const SizedBox(height: 12),
            for (final block in blocks) ...[
              block,
              if (block != blocks.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
```

### event_builder_flow_blocks.dart

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderFlowBlock extends StatelessWidget {
  const EventBuilderFlowBlock({
    super.key,
    required this.phaseLabel,
    required this.title,
    required this.icon,
    required this.tone,
    required this.children,
    this.summary,
    this.diagnosticCount,
    this.hasBlockingDiagnostic = false,
  });

  final String phaseLabel;
  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final String? summary;
  final int? diagnosticCount;
  final bool hasBlockingDiagnostic;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 8,
      padding: const EdgeInsets.all(0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: toneColors.border,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PokeMapIconTile(
                          icon: icon,
                          tone: tone,
                          size: 34,
                          iconSize: 17,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phaseLabel,
                                style: TextStyle(
                                  color: toneColors.icon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (diagnosticCount != null) ...[
                          const SizedBox(width: 8),
                          PokeMapBadge(
                            label: diagnosticCount == 0
                                ? '0 diagnostic'
                                : '$diagnosticCount diagnostic${diagnosticCount! > 1 ? 's' : ''}',
                            variant: diagnosticCount == 0
                                ? PokeMapBadgeVariant.success
                                : hasBlockingDiagnostic
                                    ? PokeMapBadgeVariant.error
                                    : PokeMapBadgeVariant.warning,
                          ),
                          if (hasBlockingDiagnostic) ...[
                            const SizedBox(width: 6),
                            const PokeMapBadge(
                              label: 'Bloquant',
                              variant: PokeMapBadgeVariant.error,
                            ),
                          ],
                        ],
                      ],
                    ),
                    if (summary != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        summary!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 6. Hunk fonctionnel principal

`_EventDetailsPanel` rend maintenant `EventBuilderCentralFlow` :

```text
EventBuilderCentralFlow
  eventHeader: identité + statut
  blocks:
    event-builder-flow-block-trigger
    event-builder-flow-block-conditions
    event-builder-flow-block-actions
    event-builder-flow-block-behavior
    event-builder-flow-block-world
    event-builder-flow-block-diagnostics
    informations techniques
```

Les anciens `_DetailSection` ont ete retires. Les blocs internes `_buildTriggerBlock`, `_buildConditionsBlock`, `_buildSceneActionBlock`, `_buildBehaviorBlock` restent les sources des controles existants.

## 7. TDD

RED initial :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-19"
```

Sorties RED utiles exactes :

```text
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'event-builder-central-flow'>]: []>
```

```text
Expected: exactly one matching candidate
Actual: _DescendantWidgetFinder:<Found 0 widgets with key [<'event-builder-trigger-object-button'>] descending from widgets with key [<'event-builder-flow-block-trigger'>]: []>
```

GREEN final :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-19"
```

Sortie utile exacte :

```text
All tests passed!
```

## 8. Tests ajoutes

Tests NS-EVENT-19 ajoutes dans `packages/map_editor/test/event_builder_workspace_test.dart` :

- `NS-EVENT-19 shows central flow blocks in canonical order`
- `NS-EVENT-19 keeps trigger authoring working from the block`
- `NS-EVENT-19 keeps condition authoring working from the block`
- `NS-EVENT-19 keeps scene action authoring working from the block`
- `NS-EVENT-19 still hides results and reactions authoring`
- `captures NS-EVENT-19 central blocks layout visual gate`

Le test NS-EVENT-16 a ete realigne : il ne cherche plus l'ancienne section `Identité`, il verifie le nouvel en-tete d'event et la presence de `event-builder-central-flow`.

## 9. Visual Gate

Capture :

```text
reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_19_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-19"
```

Sortie utile exacte :

```text
All tests passed!
```

Fichier :

```text
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
sha256 edb6d225bac4bebb7d006797aaea92c4a8e2d83fa81e91a71a75ba692f763418
```

Observation visuelle :

- liste a gauche ;
- panneau creation compact ;
- builder central visible ;
- blocs `Quand / Si / Alors` visibles dans la premiere hauteur ;
- pas de bibliotheque ;
- pas d'inspecteur droit ;
- pas de drag/drop.

## 10. Validations executees

Format :

```bash
cd packages/map_editor
dart format lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_central_flow.dart lib/src/ui/canvas/events/event_builder_flow_blocks.dart test/event_builder_workspace_test.dart
```

Sortie utile exacte :

```text
Formatted 4 files (0 changed) in 0.05 seconds.
```

Tests NS-EVENT-19 :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-19"
```

Sortie utile exacte :

```text
All tests passed!
```

Suite complete Event Builder workspace :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie utile exacte :

```text
All tests passed!
```

Analyse ciblee :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_central_flow.dart lib/src/ui/canvas/events/event_builder_flow_blocks.dart test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
No issues found! (ran in 1.8s)
```

Build macOS debug :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie utile exacte :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Note tooling : deux commandes Flutter lancees en parallele ont provoque des erreurs de verrou/ephemeral. Les commandes ont ete relancees seules ensuite et sont passees.

## 11. Sub-agent reviews

Reviewer 1 :

```text
ISSUES
```

Point utile :

```text
Le builder ajoute un bloc terminal supplémentaire `Fin de l’événement` après `Diagnostics`.
Si la liste de blocs exigée est exhaustive, ce bloc sort du périmètre V0 demandé.
```

Action prise :

- retrait du bloc terminal ;
- retrait de `EventBuilderFlowTerminalBlock`.

Reviewer 2 :

```text
APPROVED
```

Sortie utile exacte :

```text
Aucun écart NS-EVENT-19 relevé dans les fichiers vérifiés.
Pas de bloc terminal `Fin`, pas de bibliothèque, pas de drag/drop, pas d’ajout runtime/map_core/gameplay/battle/Selbrume imputable à NS-EVENT-19.
```

## 12. Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
```

## 13. Gate final

Etat final :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
?? reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
```

`event_builder_creation_panel.dart`, `ns_event_17...`, `ns_event_18...`, `ns_event_v1_drag_drop...` et la screenshot NS-EVENT-18 sont des artefacts des lots precedents dans le meme worktree non commit. Ils sont documentes ici pour ne pas les confondre avec le scope NS-EVENT-19.

Diff stat final des fichiers suivis :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 445 ++++++++++-----------
 .../test/event_builder_workspace_test.dart         | 290 +++++++++++++-
 2 files changed, 490 insertions(+), 245 deletions(-)
```

Diff name-only final des fichiers suivis :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` :

```text
```

## 14. Impact sur NS-EVENT-20

NS-EVENT-20 peut maintenant separer l'inspecteur droit :

- les blocs centraux existent ;
- les controles sont encore dans les blocs ;
- les informations techniques restent en bas du flow, ce qui donne une cible claire a deplacer vers l'inspecteur ;
- la bibliotheque et le drag/drop restent non demarres.

Prochain lot recommande :

```text
NS-EVENT-20 - Event Inspector Split V0
```

## 15. Limites restantes

- Le flow central est encore dans une seule colonne large.
- Les controles d'edition restent dans les blocs ; l'inspecteur droit n'existe pas encore.
- La bibliotheque d'elements n'existe pas.
- Les blocs Resultats/Reactions ne sont pas authorables.
- Les changements du monde restent derives/placeholder via consequences de scene.
- Le drag/drop n'est pas ouvert.

## 16. Auto-review critique

Checklist :

- UI consomme toujours le read model existant : oui.
- Aucun nouveau modele core : oui.
- Aucun runtime : oui.
- Pas de drag/drop : oui.
- Pas de bibliotheque : oui.
- Pas de Resultats/Reactions authorables : oui.
- Tests d'ordre des blocs : oui.
- Tests de non-regression trigger/conditions/scene : oui.
- Visual Gate : oui.
- Revue sub-agent : oui, avec correction du scope apres le premier retour.

Reserve :

Le worktree contient plusieurs lots non commits. Les rapports distinguent les artefacts NS-EVENT-17/18/19, mais une integration Git propre devrait regrouper ou committer ces lots intentionnellement avant de continuer longtemps.
