# NSC-73 — Accessibilité, clavier et localisation du Narrative Studio

Date : 2026-07-21

Statut proposé : **DONE**

## Audit initial et verdict

L'audit a confirmé que le shell possédait déjà ses breakpoints, ses focus
anchors et un premier contrat FR/EN, mais que les surfaces ajoutées en phase 7
(palette globale et centre de migration) contenaient encore leur chrome en dur.
Le graphe de Scene rendait ses ports utilisables à la souris sans nom accessible,
et aucun test ne prouvait un parcours clavier complet entre toutes les routes du
produit. Enfin, la matrice responsive ne couvrait pas l'état de migration chargé
à 200 % de zoom texte.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles Audit/Architecture, Accessibilité sémantique, Clavier, Localisation,
Responsive, Design System, Tests et Critique sont **GO**. La passe Build globale
reste **INCONCLUSIVE ENVIRONNEMENT** : Flutter local 3.41.6, alors que la branche
emploie déjà des API Flutter 3.44 dans des workspaces historiques hors de ce lot.

## Critères et preuves

| Critère NSC-73 | Preuve | Verdict |
|---|---|---|
| Parcours clavier complet | test de tabulation sur les 9 destinations, les 3 routes Event, `Cmd/Ctrl+K`, recherche, ouverture et restauration du focus | GO |
| Navigation annoncée et activable | `PokeMapSidebarItem` expose état, libellé et action sémantique `tap` | GO |
| Ports de graphe nommés | libellés localisés entrée/sortie avec nœud et sortie métier | GO |
| État chargé à 200 % | centre de migration complet testé à 800 × 650 sans overflow | GO |
| Chrome Phase 7 localisable | palette, migration, tooltip global et ports présents dans les ARB FR/EN | GO |
| Parité FR/EN | test exact des clés et lookups des nouveaux domaines | GO |
| Zéro couleur directe | les deux guardrails Design System restent à leur baseline zéro | GO |
| Réduction des animations | test historique `disableAnimations` toujours vert | GO |
| Contraste/focus | focus ring renforcé en contraste élevé et régression du composant sidebar verte | GO |

## Fichiers modifiés

- `packages/map_editor/lib/l10n/app_en.arb`
- `packages/map_editor/lib/l10n/app_fr.arb`
- `packages/map_editor/lib/l10n/app_localizations.dart`
- `packages/map_editor/lib/l10n/app_localizations_en.dart`
- `packages/map_editor/lib/l10n/app_localizations_fr.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart`
- `packages/map_editor/test/narrative_studio_localization_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_responsive_accessibility_test.dart`

## Fichiers créés

- `packages/map_editor/test/ui/canvas/narrative_studio_full_keyboard_journey_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_semantics_test.dart`
- `reports/narrativeStudio/completion/nsc_73_accessibility_localization_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot.
Aucun cache, lockfile ou artefact machine n'est inclus.

## Zones précises et décisions

### Localisation

- Les ARB possèdent désormais le vocabulaire partagé de la palette, des types
  de résultat, des actions, du centre de migration et des ports Scene.
- Les fichiers `app_localizations*.dart` ont été régénérés par `flutter gen-l10n` ;
  ils ne sont pas édités à la main.
- Les labels métier fournis dynamiquement par les read models restent la
  responsabilité de leur domaine ; seul le chrome partagé est traduit ici.

### Clavier et sémantique

- Le parcours prouve l'accès à chaque destination et sous-route Event sans
  souris, puis l'ouverture et l'utilisation de la palette globale.
- `PokeMapSidebarItem` porte directement son callback sémantique afin que les
  technologies d'assistance annoncent une action, indépendamment du geste.
- Les ports du graphe exposent des labels localisés sans changer le format du
  modèle ou son layout.

### Responsive et Design System

- `PokeMapStatusLabel` autorise maintenant son texte à se contracter dans la
  rangée partagée, ce qui supprime l'overflow réel observé à 200 %.
- Aucun widget feature-local, couleur directe ou primitive parallèle n'a été
  introduit ; le correctif reste dans le composant partagé.
- `pubspec.yaml` a été audité : `generate: true`, `flutter_localizations` et
  `intl` étaient déjà correctement configurés, donc aucun changement artificiel
  n'a été ajouté.

## TDD, commandes et résultats exacts

### Rouge observé

```text
flutter test --no-pub test/ui/canvas/narrative_studio_semantics_test.dart
Expected SemanticsAction.tap: true, actual: false.

flutter test --no-pub test/ui/canvas/narrative_studio_responsive_accessibility_test.dart
RenderFlex overflow dans PokeMapStatusLabel à 200 %.
```

Ces deux défauts ont été corrigés dans les primitives partagées, sans retirer
les assertions.

### Génération et verts ciblés

```text
cd packages/map_editor
flutter gen-l10n
Exit code 0

flutter test --no-pub \
  test/narrative_studio_localization_test.dart \
  test/ui/canvas/narrative_studio_full_keyboard_journey_test.dart
+6: All tests passed!

flutter test --no-pub test/ui/canvas/narrative_studio_semantics_test.dart
+2: All tests passed!

flutter test --no-pub \
  test/ui/canvas/narrative_studio_responsive_accessibility_test.dart
+9: All tests passed!

flutter test --no-pub \
  test/ui/canvas/narrative_command_palette_test.dart \
  test/ui/design_system/pokemap_sidebar_item_test.dart \
  test/design_system_guardrail_test.dart \
  test/ui/design_system/narrative_design_system_guardrail_test.dart
+16: All tests passed!
```

### Analyse statique ciblée

```text
cd packages/map_editor
flutter analyze --no-pub \
  lib/l10n \
  lib/src/ui/design_system/pokemap_dashboard_primitives.dart \
  lib/src/ui/design_system/pokemap_sidebar_item.dart \
  lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart \
  lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart \
  lib/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart \
  lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart \
  test/narrative_studio_localization_test.dart \
  test/ui/canvas/narrative_studio_full_keyboard_journey_test.dart \
  test/ui/canvas/narrative_studio_semantics_test.dart \
  test/ui/canvas/narrative_studio_responsive_accessibility_test.dart
No issues found! (ran in 3.2s)
```

## Risques, limites et auto-critique

- Le lot garantit la localisation du shell partagé et des surfaces Phase 7 ;
  il ne prétend pas traduire rétroactivement chaque libellé historique interne
  de tous les builders.
- Les lecteurs d'écran natifs macOS/Windows ne sont pas automatisés ici ; les
  preuves portent sur l'arbre Semantics Flutter et les actions exposées.
- Le zoom testé est le zoom texte Flutter à 200 %, pas le zoom système de chaque
  OS ni toutes les combinaisons de polices de remplacement.
- La suite Flutter globale n'est pas déclarée verte avec le SDK local ancien ;
  aucune réussite non exécutée n'est inventée.

État Git initial : propre après `2f0e70502`. État avant commit : uniquement les
fichiers NSC-73 listés ci-dessus. `git diff --check` est propre.
