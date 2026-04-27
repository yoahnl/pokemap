# Phase R1 — Lot 8 Corrective Pass Report

## 1. Résumé exécutif honnête

Cette passe corrective a confirmé, à partir du **code réel du worktree**, que le lot 8 était déjà **fonctionnellement livré**. La surface encounter permet bien de créer/éditer/supprimer des tables et des entrées, avec assistance locale `species`, validation inline, sauvegarde via le pipeline existant, et états dégradés honnêtes quand les données locales ne sont pas disponibles.

Les problèmes réellement confirmés étaient limités et locaux :

- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart` restait trop monolithique à **1718 lignes**, sans `part` files voisins, malgré l’objectif du corrective pass ;
- l’édition d’une table encounter **ne se fermait pas après un save réussi**, contrairement au reste de la surface ;
- `ROADMAP_FANGAME_RECALEE.md` contenait encore une contradiction explicite : une section disait encore que le lot 8 restait à faire alors que d’autres sections le marquaient déjà livré.

Ce corrective pass a donc fait exactement trois choses :

1. split local de `EncounterTablesPanel` en `part` files voisins, dans la même bibliothèque Dart, sans nouvelle architecture ;
2. correction du micro-bug de fermeture sur succès pour l’édition de table ;
3. correction de la contradiction roadmap sur `Lot 8 / M2`.

Rien d’autre n’a été rouvert :

- pas de nouveau notifier/use case/repository/provider ;
- pas de changement de contrat encounter ;
- pas de retouche des messages `résolu / absent / vérification impossible`, déjà honnêtes ;
- pas d’ouverture du lot 9.

Conclusion honnête : **le corrective pass du lot 8 est terminé**, le lot 8 reste **clôturé proprement**, et il n’y a plus de point bloquant détecté dans ce périmètre avant de passer au lot 9.

## 2. État initial audité réel

Source de vérité utilisée :

- le code réel du repo ;
- le worktree actuel ;
- les tests réels ;
- la roadmap actuelle.

Le report précédent a été utilisé uniquement comme contexte d’intention, jamais comme preuve.

Constats réels avant modification :

- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart` faisait **1718 lignes** ;
- aucun `part` file encounter voisin n’existait ;
- `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart` était déjà proprement borné au métier encounter ;
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` restait un orchestrateur de mutation encounter, sans dérive supplémentaire ;
- les tests encounter existaient déjà et couvraient :
  - le use case create/update/delete table ;
  - le use case add/update/delete entry ;
  - le rejet métier des données invalides ;
  - le happy path UI encounter ;
  - la validation inline UI ;
  - le fallback honnête quand l’index local species est indisponible ;
  - le maintien ouvert du formulaire create sur erreur de persistance ;
- la roadmap contenait encore une contradiction réelle :
  - `Phase C` disait encore `lot 8 reste à faire` ;
  - d’autres sections et le milestone M2 le donnaient déjà `livré`.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés

- `EncounterTablesPanel` était encore trop gros pour un corrective pass crédible.
- Le split en `part` files demandé n’avait pas encore été fait dans le code.
- Le formulaire d’édition de table encounter ne se fermait pas après un save réussi.
- La roadmap restait contradictoire sur le statut du lot 8.

### Problèmes non confirmés

- pas de bug confirmé dans `EditorNotifier` côté encounter ;
- pas de bug confirmé dans `encounter_table_use_cases.dart` ;
- pas de problème confirmé dans la logique `species résolu / absent / vérification impossible` ;
- pas de problème confirmé dans le fallback local species déjà livré ;
- pas de bug confirmé sur create/delete table ;
- pas de bug confirmé sur add/edit/delete entry ;
- pas de fuite d’état locale confirmée dans les drafts encounter ;
- pas de besoin confirmé de toucher aux lots 5/6/7.

### Churn cosmétique explicitement rejeté

- extractions supplémentaires en micro-fichiers ;
- nouvelle couche encounter locale ;
- retouche massive de wording ;
- généralisation prématurée du pattern trainer ;
- refactor du notifier ou des use cases “pour faire propre”.

## 4. Conclusions détaillées des 5 sous-agents / reviewers

### Reviewer A — Architecture / scope

Conclusion :

- le corrective pass devait rester local ;
- `EditorNotifier` et `encounter_table_use_cases.dart` ne devaient pas être touchés sans bug réel ;
- un split local du panel était acceptable, mais aucune nouvelle stack encounter n’était justifiée.

Retenu :

- aucun changement notifier/use cases ;
- split dans la même bibliothèque avec `part`.

Rejeté :

- tout ajout de couche encounter dédiée ;
- toute évolution de contrat du pipeline encounter.

### Reviewer B — UI maintainability

Conclusion :

- `encounter_tables_panel.dart` restait trop volumineux et bruyant ;
- le plus petit split utile était :
  - support pur ;
  - widgets de table ;
  - widgets d’entry ;
- le fichier principal devait redevenir orchestrateur.

Retenu :

- split en trois `part` files voisins ;
- conservation du state local et des handlers dans le fichier principal.

Rejeté :

- éclatement en nombreux micro-widgets ;
- refonte structurelle plus ambitieuse.

### Reviewer C — State / behavior

Conclusion :

- create table : fermeture correcte sur succès, maintien ouvert sur erreur ;
- add/edit entry : fermeture correcte sur succès, maintien ouvert sur erreur ;
- delete entry : recalage d’index correct ;
- delete table : fermeture correcte des éditeurs liés ;
- **un seul bug réel** : save réussi d’une table encounter ne fermait pas l’éditeur de table.

Retenu :

- correction de la fermeture sur succès pour l’édition de table ;
- ajout d’un test widget ciblé.

Rejeté :

- tout changement des autres flows encounter non prouvés.

### Reviewer D — Product honesty

Conclusion :

- les messages `species résolu / absent / vérification impossible` étaient déjà honnêtes ;
- la surface encounter restait utilisable quand l’assistance locale était indisponible ;
- en revanche, la roadmap n’était pas pleinement cohérente sur `Lot 8 / M2`.

Retenu :

- correction roadmap uniquement ;
- pas de réécriture de messages UI encounter.

Rejeté :

- retouche produit non prouvée dans la surface encounter.

### Reviewer E — Test matrix reviewer

Conclusion :

- la matrice existante était déjà solide pour un corrective pass ;
- un seul test additionnel était justifié :
  - fermeture de l’éditeur de table après update réussi.

Retenu :

- un seul test widget additionnel ;
- réexécution des non-régressions utiles trainer/species/batch.

Rejeté :

- inflation artificielle de tests décoratifs.

## 5. Vérification de la véracité du report précédent

### Ce qui était vrai

- le lot 8 était bien fonctionnellement livré ;
- la surface encounter était bien exploitable ;
- les tests encounter existants étaient réels et utiles ;
- le fallback species indisponible était bien présent ;
- `EditorNotifier` et les use cases encounter n’avaient pas besoin d’être retouchés.

### Ce qui était incomplet

- le report précédent laissait entendre que le corrective pass encounter était déjà essentiellement fait côté maintenabilité ;
- en réalité, `encounter_tables_panel.dart` était encore un vrai monolithe sans part files.

### Ce qui était faux ou devenu faux

- l’idée implicite que la cohérence documentaire était complètement réglée ;
- la roadmap gardait encore une contradiction explicite sur `lot 8 reste à faire`.

## 6. Décisions retenues / rejetées

### Retenues

- split local du panel encounter avec `part` files ;
- maintien du fichier principal comme orchestrateur ;
- correction du save table -> fermeture sur succès ;
- correction stricte de la contradiction roadmap.

### Rejetées

- modification de `EditorNotifier` ;
- modification de `encounter_table_use_cases.dart` ;
- ajout d’un nouveau service encounter ;
- ajout d’un reorder ;
- retouches produit hors bug prouvé ;
- refonte plus large des surfaces trainers/encounters ;
- tout démarrage du lot 9.

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `ROADMAP_FANGAME_RECALEE.md`
- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart`
- `packages/map_editor/test/encounter_tables_panel_test.dart`

### Créés

- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart`
- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart`
- `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart`
- `reports/phase-r1-lot-8-corrective-pass-report.md`

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart`

- réduit de **1718 lignes** à **575 lignes** ;
- conserve le rôle d’orchestrateur ;
- garde l’état local, le chargement des références, les handlers CRUD et les helpers de fermeture ;
- corrige le bug de fermeture de l’éditeur de table sur succès ;
- ajoute un petit helper `_runLocalStateMutation` pour permettre aux `part` files d’exprimer des mutations de draft sans toucher au notifier.

### `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart`

- centralise les modèles privés de références/validation/statut ;
- centralise les helpers purs encounter ;
- évite de laisser la validation et les calculs noyer le flux principal.

### `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart`

- extrait les widgets et builders liés aux tables et aux banners ;
- enlève le bruit UI principal du panel ;
- garde la même bibliothèque et les mêmes privates.

### `packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart`

- extrait la ligne d’entry et le formulaire d’entry ;
- garde l’assistance species et la validation inline inchangées ;
- réduit fortement le bruit de rendu dans le panel principal.

### `packages/map_editor/test/encounter_tables_panel_test.dart`

- ajoute le seul test supplémentaire nécessaire :
  - fermeture de l’éditeur de table après save réussi ;
- garde intacte la matrice existante encounter.

### `ROADMAP_FANGAME_RECALEE.md`

- supprime la contradiction restante disant encore que le lot 8 restait à faire ;
- aligne `Phase C` avec les sections qui disent déjà que `Lot 8` et `M2` sont livrés.

## 9. Commandes réellement exécutées

### Audit initial

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
find . -name AGENTS.md -print
wc -l packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart \
      packages/map_editor/test/encounter_tables_panel_test.dart \
      packages/map_editor/test/encounter_table_use_cases_test.dart \
      ROADMAP_FANGAME_RECALEE.md
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
sed -n '261,620p' packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
sed -n '621,1180p' packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
sed -n '1181,1718p' packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
rg -n "Lot 8|lot 8|M2|encounter" ROADMAP_FANGAME_RECALEE.md
sed -n '1,9999p' packages/map_editor/test/encounter_tables_panel_test.dart
sed -n '1,9999p' packages/map_editor/test/encounter_table_use_cases_test.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart
sed -n '260,520p' packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart
sed -n '5010,5365p' packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
```

### Validation

```bash
/opt/homebrew/bin/dart format \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart \
  packages/map_editor/test/encounter_tables_panel_test.dart \
  ROADMAP_FANGAME_RECALEE.md

/opt/homebrew/bin/dart format \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart \
  packages/map_editor/test/encounter_tables_panel_test.dart

/opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/ui/panels/encounter_tables_panel.dart \
  lib/src/ui/panels/encounter_tables_panel_support.dart \
  lib/src/ui/panels/encounter_tables_panel_table_widgets.dart \
  lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart \
  test/encounter_table_use_cases_test.dart \
  test/encounter_tables_panel_test.dart

/opt/homebrew/bin/flutter test test/encounter_table_use_cases_test.dart
/opt/homebrew/bin/flutter test test/encounter_tables_panel_test.dart
/opt/homebrew/bin/flutter test \
  test/trainer_library_panel_test.dart \
  test/pokemon_species_lookup_service_test.dart \
  test/pokedex_external_batch_execute_ui_test.dart
```

### Audit final

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
wc -l \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart \
  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart \
  ROADMAP_FANGAME_RECALEE.md \
  packages/map_editor/test/encounter_tables_panel_test.dart
rg -n "lot 8 reste à faire|Lot 8 reste à faire|M2.*partiel|encounter tables minimales mais propres|lot 8 livré" ROADMAP_FANGAME_RECALEE.md
```

## 10. Résultats réels

### `dart format`

Première tentative :

```text
Formatted packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart
Formatted packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart
Formatted packages/map_editor/test/encounter_tables_panel_test.dart
Could not format because the source could not be parsed:

line 1, column 13 of ROADMAP_FANGAME_RECALEE.md: Illegal character '238'.
...
Formatted 5 files (3 changed) in 0.05 seconds.
```

Conclusion honnête :

- le formatter Dart ne peut pas formater un fichier markdown ;
- les fichiers Dart ont bien été formatés ;
- la roadmap reste un fichier texte modifié, non formattable par `dart format`.

Deuxième passe ciblée Dart seulement :

```text
Formatted 5 files (0 changed) in 0.02 seconds.
```

### `flutter analyze --no-pub`

Première passe après split :

```text
warning • The member 'setState' can only be used within instance members of subclasses of 'State' • ...
15 issues found. (ran in 1.8s)
```

Correctif local appliqué :

- ajout du helper `_runLocalStateMutation(...)` dans le panel principal ;
- remplacement des appels `setState(...)` dans les `part` files par ce helper.

Deuxième passe :

```text
No issues found! (ran in 2.1s)
```

### `flutter test test/encounter_table_use_cases_test.dart`

```text
00:01 +3: All tests passed!
```

### `flutter test test/encounter_tables_panel_test.dart`

```text
00:03 +5: All tests passed!
```

Le nouveau test ajouté passe bien :

- `closes the table editor after a successful table update`

### `flutter test test/trainer_library_panel_test.dart test/pokemon_species_lookup_service_test.dart test/pokedex_external_batch_execute_ui_test.dart`

```text
00:05 +13: All tests passed!
```

## 11. Incidents rencontrés

### Incident 1 — `dart format` appliqué au markdown

Incident réel :

- la commande initiale incluait `ROADMAP_FANGAME_RECALEE.md` ;
- `dart format` a refusé ce fichier car ce n’est pas du Dart.

Résolution :

- relance immédiate sur les seuls fichiers Dart touchés ;
- report documenté honnêtement.

### Incident 2 — warnings analyzer après extraction en `extension`

Incident réel :

- les `extension` methods dans les `part` files appelaient directement `setState` ;
- l’analyzer a remonté `invalid_use_of_protected_member`.

Résolution :

- ajout d’un helper local `_runLocalStateMutation(...)` dans le panel principal ;
- remplacement des appels `setState(...)` extraits ;
- aucune nouvelle couche ni aucun changement de contrat encounter.

## 12. État git utile

État final utile après cette passe :

```text
 M ROADMAP_FANGAME_RECALEE.md
 M packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
 M packages/map_editor/test/encounter_tables_panel_test.dart
?? packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart
?? packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart
?? packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart
?? reports/phase-r1-lot-8-corrective-pass-report.md
```

Résumé `git diff --stat` avant ajout du report :

```text
 ROADMAP_FANGAME_RECALEE.md                         |    7 +-
 .../lib/src/ui/panels/encounter_tables_panel.dart  | 1191 +-------------------
 .../test/encounter_tables_panel_test.dart          |   68 ++
 3 files changed, 97 insertions(+), 1169 deletions(-)
```

Fichiers non suivis à la fin :

```text
packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart
packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart
packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart
reports/phase-r1-lot-8-corrective-pass-report.md
```

Mesure de taille après corrective pass :

```text
575  packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
247  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart
602  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart
345  packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart
607  packages/map_editor/test/encounter_tables_panel_test.dart
1387 ROADMAP_FANGAME_RECALEE.md
```

## 13. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports comme source de vérité
- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas ouvert le lot 9
- [x] j’ai réutilisé le pipeline encounter existant au maximum
- [x] la surface encounter est réellement plus exploitable pour un auteur
- [x] l’assistance species réutilise les données locales existantes
- [x] les niveaux / poids sont validés lisiblement
- [x] les probabilités / poids sont lisibles
- [x] la saisie brute reste possible seulement là où c’est nécessaire
- [x] j’ai distingué correctement les états “résolu / absent / vérification impossible”
- [x] les micro-correctifs 5/6/7 éventuels sont restés strictement locaux
- [x] je n’ai touché `EditorNotifier` / use cases que si nécessaire
- [x] j’ai exécuté `dart format`
- [x] j’ai exécuté `flutter analyze --no-pub`
- [x] j’ai exécuté les tests ciblés utiles
- [x] je n’ai fait aucun commit / merge / rebase / push / tag / stash / amend / reset / checkout / switch / restore
- [x] le rapport markdown final a bien été créé
- [x] le rapport contient le contenu complet de tous les fichiers texte modifiés / créés / supprimés
- [x] je conclus honnêtement si le lot 8 est livré ou non
- [x] je conclus honnêtement si M2 est livré ou non

## 14. Conclusion honnête

Conclusion de cette passe corrective :

- **le lot 8 était déjà fonctionnellement livré** ;
- le corrective pass a **réellement amélioré la maintenabilité locale** en ramenant le fichier principal encounter à un rôle d’orchestrateur ;
- la roadmap ne se contredit plus sur le statut `Lot 8 / M2` ;
- le seul bug comportemental confirmé a été corrigé ;
- aucune architecture parallèle n’a été introduite ;
- aucune dette masquée n’a été créée côté notifier ou use cases.

Verdict final :

- **le lot 8 corrective pass est terminé**
- **le lot 8 est confirmé comme clôturé**
- **on peut passer au lot 9**

## 15. Annexe — contenu complet des fichiers touchés

Note :

- le report s’exclut lui-même de sa propre annexe pour éviter une récursion infinie ;
- tous les autres fichiers texte modifiés/créés sont inclus intégralement ci-dessous ;
- aucun fichier n’a été supprimé pendant cette passe.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

// Keep the encounters panel in one Dart library so the corrective pass can
// split the noise into neighboring `part` files without changing visibility,
// notifier contracts, or the existing encounter authoring pipeline.
part 'encounter_tables_panel_support.dart';
part 'encounter_tables_panel_table_widgets.dart';
part 'encounter_tables_panel_entry_widgets.dart';

const PokemonSpeciesLookupService _encounterSpeciesLookupService =
    PokemonSpeciesLookupService();

class EncounterTablesPanel extends ConsumerStatefulWidget {
  const EncounterTablesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<EncounterTablesPanel> createState() =>
      _EncounterTablesPanelState();
}

class _EncounterTablesPanelState extends ConsumerState<EncounterTablesPanel> {
  // -------------------------------------------------------------------------
  // Create table draft
  // -------------------------------------------------------------------------

  final _newTableNameController = TextEditingController();
  EncounterKind _newTableKind = EncounterKind.walk;
  bool _showCreateForm = false;
  String? _createTableValidationMessage;

  // -------------------------------------------------------------------------
  // Edit table draft
  // -------------------------------------------------------------------------

  String? _editingTableId;
  final _editTableNameController = TextEditingController();
  EncounterKind _editTableKind = EncounterKind.walk;
  String? _editTableValidationMessage;

  // -------------------------------------------------------------------------
  // Shared encounter entry draft
  // -------------------------------------------------------------------------
  //
  // Add and edit intentionally share the same local draft surface:
  // - the validation path stays identical for add vs edit;
  // - notifier/use cases stay focused on persistence, not draft state;
  // - the panel remains the single owner of this authoring UX state.

  String? _editingEntryTableId;
  int? _editingEntryIndex;
  final _entrySpeciesController = TextEditingController();
  final _entryMinLevelController = TextEditingController(text: '1');
  final _entryMaxLevelController = TextEditingController(text: '5');
  final _entryWeightController = TextEditingController(text: '1');
  String? _entryValidationMessage;

  // -------------------------------------------------------------------------
  // Local Pokédex references used only for encounter authoring assistance
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_EncounterReferenceData>? _referenceDataFuture;

  @override
  void dispose() {
    _newTableNameController.dispose();
    _editTableNameController.dispose();
    _entrySpeciesController.dispose();
    _entryMinLevelController.dispose();
    _entryMaxLevelController.dispose();
    _entryWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyCyan;
    final tables = project?.encounterTables ?? const <ProjectEncounterTable>[];

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_EncounterReferenceData>(
            future: _referenceDataFuture,
            initialData: const _EncounterReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _EncounterReferenceData.loading();
              return ListView(
                padding: widget.embedded
                    ? kInspectorTileBodyPadding
                    : const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  _buildReferencesBanner(
                    context,
                    references,
                    accent: accent,
                    onRefresh: () => _refreshReferenceData(state),
                  ),
                  if ((state.errorMessage ?? '').trim().isNotEmpty ||
                      (state.statusMessage ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildOperationBanner(
                        context,
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
                    ),
                  if (!_showCreateForm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget.embedded
                          ? InspectorEmbeddedPrimaryCapsule(
                              key: const Key(
                                'encounter-tables-new-table-button',
                              ),
                              accent: accent,
                              icon: CupertinoIcons.add_circled,
                              label: 'Nouvelle table',
                              prominent: false,
                              onPressed: () => setState(() {
                                _showCreateForm = true;
                                _editingTableId = null;
                                _closeEntryEditor();
                                _createTableValidationMessage = null;
                              }),
                            )
                          : CupertinoButton(
                              key: const Key(
                                'encounter-tables-new-table-button',
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              onPressed: () => setState(() {
                                _showCreateForm = true;
                                _editingTableId = null;
                                _closeEntryEditor();
                                _createTableValidationMessage = null;
                              }),
                              child: const Row(
                                children: [
                                  Icon(CupertinoIcons.add_circled, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'New Table',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                    )
                  else
                    _buildCreateTableForm(
                      context,
                      notifier,
                      accent,
                    ),
                  if (tables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'No encounter tables. Create one above.',
                        style: TextStyle(
                          color: CupertinoColors.placeholderText
                              .resolveFrom(context),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...tables.map(
                      (table) => _buildTableCard(
                        context: context,
                        notifier: notifier,
                        table: table,
                        references: references,
                        accent: accent,
                        subtle: subtle,
                      ),
                    ),
                ],
              );
            },
          );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ENCOUNTER TABLES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  '${tables.length}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Local reference loading
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_EncounterReferenceData>.value(
            const _EncounterReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_EncounterReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);

    try {
      final speciesEntries = await speciesLoader(workspace);
      return speciesEntries.isEmpty
          ? const _EncounterReferenceData(
              speciesEntries: <PokemonDatabaseIndexEntry>[],
              isSpeciesAvailable: false,
              speciesMessage:
                  'No local species are indexed yet. Raw species IDs are still allowed.',
            )
          : _EncounterReferenceData(
              speciesEntries: speciesEntries,
              isSpeciesAvailable: true,
              speciesMessage:
                  'Local species assist active on ${speciesEntries.length} indexed species.',
            );
    } catch (error) {
      return _EncounterReferenceData(
        speciesEntries: const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable: false,
        speciesMessage:
            'Unable to load local species data. Raw species IDs are still allowed.\n$error',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Table CRUD
  // -------------------------------------------------------------------------

  Future<void> _createTable(EditorNotifier notifier) async {
    final inlineValidation =
        _validateEncounterTableName(_newTableNameController.text);
    setState(() {
      _createTableValidationMessage = inlineValidation;
    });
    if (inlineValidation != null) {
      return;
    }

    final beforeState = ref.read(editorNotifierProvider);
    await notifier.createEncounterTable(
      name: _newTableNameController.text,
      encounterKind: _newTableKind,
    );
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      setState(_resetCreateTableDraft);
      return;
    }

    setState(() {
      _createTableValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create encounter table.';
    });
  }

  Future<void> _updateTable(
    EditorNotifier notifier,
    String tableId,
  ) async {
    final inlineValidation =
        _validateEncounterTableName(_editTableNameController.text);
    setState(() {
      _editTableValidationMessage = inlineValidation;
    });
    if (inlineValidation != null) {
      return;
    }

    final beforeState = ref.read(editorNotifierProvider);
    await notifier.updateEncounterTable(
      tableId: tableId,
      name: _editTableNameController.text,
      encounterKind: _editTableKind,
    );
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      // Match the rest of the surface: a successful mutation closes the active
      // draft instead of leaving the user inside an editor that already saved.
      setState(_closeTableEditor);
      return;
    }

    setState(() {
      _editTableValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update encounter table.';
    });
  }

  Future<void> _deleteTable(
    EditorNotifier notifier,
    String tableId,
  ) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterTable(tableId);
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_editingTableId == tableId) {
        _closeTableEditor();
      }
      if (_editingEntryTableId == tableId) {
        _closeEntryEditor();
      }
    });
  }

  Future<void> _saveEntry(
    EditorNotifier notifier,
    String tableId,
    _EncounterReferenceData references,
  ) async {
    final validation = _validateEntryDraft(references: references);
    setState(() {
      _entryValidationMessage = validation.firstMessage;
    });
    if (validation.firstMessage != null) {
      return;
    }

    final minLevel = int.parse(_entryMinLevelController.text.trim());
    final maxLevel = int.parse(_entryMaxLevelController.text.trim());
    final weight = int.parse(_entryWeightController.text.trim());

    final beforeState = ref.read(editorNotifierProvider);
    final index = _editingEntryIndex;
    if (index == null) {
      await notifier.addEncounterEntry(
        tableId: tableId,
        speciesId: _entrySpeciesController.text.trim(),
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    } else {
      await notifier.updateEncounterEntry(
        tableId: tableId,
        entryIndex: index,
        speciesId: _entrySpeciesController.text.trim(),
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
    }
    if (!mounted) {
      return;
    }

    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (success) {
      setState(_closeEntryEditor);
      return;
    }

    setState(() {
      _entryValidationMessage = ref.read(editorNotifierProvider).errorMessage ??
          'Failed to save encounter entry.';
    });
  }

  Future<void> _deleteEntry(
    EditorNotifier notifier,
    String tableId,
    int index,
  ) async {
    final beforeState = ref.read(editorNotifierProvider);
    await notifier.deleteEncounterEntry(
      tableId: tableId,
      entryIndex: index,
    );
    final success = _didEncounterMutationSucceed(
      beforeState: beforeState,
      afterState: ref.read(editorNotifierProvider),
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_editingEntryTableId != tableId) {
        return;
      }
      if (_editingEntryIndex == index) {
        _closeEntryEditor();
        return;
      }
      if (_editingEntryIndex != null && _editingEntryIndex! > index) {
        _editingEntryIndex = _editingEntryIndex! - 1;
      }
    });
  }

  // We deliberately keep this success heuristic local to the encounter panel.
  // Why here instead of changing the notifier contract:
  // - the encounter pipeline already exists and already reports failures by
  //   mutating `errorMessage`;
  // - the panel only needs one local answer: did the project snapshot change;
  // - widening the notifier API just for this surface would be needless scope.
  bool _didEncounterMutationSucceed({
    required EditorState beforeState,
    required EditorState afterState,
  }) {
    if ((afterState.errorMessage?.trim().isNotEmpty ?? false)) {
      return false;
    }
    return !identical(beforeState.project, afterState.project);
  }

  void _selectSuggestedSpecies(String speciesId) {
    _entrySpeciesController
      ..text = speciesId
      ..selection = TextSelection.collapsed(offset: speciesId.length);
    setState(() {
      _entryValidationMessage = null;
    });
  }

  // Extracted widget builders live in `part` files, but we still want the
  // panel state itself to stay the single owner of draft mutations. This tiny
  // bridge lets those local builders trigger state updates without adding a
  // new controller layer or changing the encounter pipeline contract.
  void _runLocalStateMutation(VoidCallback mutation) {
    setState(mutation);
  }

  void _resetCreateTableDraft() {
    _showCreateForm = false;
    _createTableValidationMessage = null;
    _newTableNameController.clear();
    _newTableKind = EncounterKind.walk;
  }

  void _closeTableEditor() {
    _editingTableId = null;
    _editTableValidationMessage = null;
  }

  void _closeEntryEditor() {
    _editingEntryTableId = null;
    _editingEntryIndex = null;
    _entryValidationMessage = null;
    _entrySpeciesController.clear();
    _entryMinLevelController.text = '1';
    _entryMaxLevelController.text = '5';
    _entryWeightController.text = '1';
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/encounter_tables_panel_support.dart`

```dart
part of 'encounter_tables_panel.dart';

// ---------------------------------------------------------------------------
// Local encounter references and draft validation
// ---------------------------------------------------------------------------

class _EncounterReferenceData {
  const _EncounterReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
  });

  const _EncounterReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Loading local species data… Raw species IDs are still allowed during this load.';

  const _EncounterReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'No usable Pokémon workspace detected. Raw species IDs are still allowed, but without local assistance.';

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
}

class _EncounterEntryDraftValidation {
  const _EncounterEntryDraftValidation({
    this.speciesMessage,
    this.minLevelMessage,
    this.maxLevelMessage,
    this.weightMessage,
  });

  final String? speciesMessage;
  final String? minLevelMessage;
  final String? maxLevelMessage;
  final String? weightMessage;

  String? get firstMessage =>
      speciesMessage ?? minLevelMessage ?? maxLevelMessage ?? weightMessage;
}

class _EncounterSpeciesStatus {
  const _EncounterSpeciesStatus({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;
}

// ---------------------------------------------------------------------------
// Pure helpers
// ---------------------------------------------------------------------------
//
// These stay outside the state class on purpose:
// - they do not mutate draft state;
// - they are reused by both the main orchestrator and the extracted widgets;
// - keeping them local to this library avoids creating any new encounter
//   service or shared abstraction layer.

String? _validateEncounterTableName(String rawName) {
  if (rawName.trim().isEmpty) {
    return 'Table name cannot be empty.';
  }
  return null;
}

PokemonDatabaseIndexEntry? _resolveEncounterSpecies(
  _EncounterReferenceData references,
  String rawSpeciesId,
) {
  if (!references.isSpeciesAvailable) {
    return null;
  }
  return _encounterSpeciesLookupService.findById(
    references.speciesEntries,
    rawSpeciesId,
  );
}

_EncounterSpeciesStatus _resolveEncounterSpeciesStatus({
  required _EncounterReferenceData references,
  required String rawSpeciesId,
}) {
  final speciesId = rawSpeciesId.trim();
  if (speciesId.isEmpty) {
    return const _EncounterSpeciesStatus(
      message:
          'Search by species id, local name or Pokédex number when local data is available.',
      isError: false,
    );
  }

  if (!references.isSpeciesAvailable) {
    return const _EncounterSpeciesStatus(
      message:
          'Unable to verify against local species data. Raw species IDs are still allowed.',
      isError: false,
    );
  }

  final resolved = _resolveEncounterSpecies(references, speciesId);
  if (resolved == null) {
    return const _EncounterSpeciesStatus(
      message: 'Species not present in the local Pokédex.',
      isError: true,
    );
  }

  final dexLabel = resolved.nationalDex > 0
      ? '#${resolved.nationalDex.toString().padLeft(4, '0')}'
      : 'No dex number';
  return _EncounterSpeciesStatus(
    message:
        'Local species match: ${resolved.primaryName} • $dexLabel • ${resolved.id}',
    isError: false,
  );
}

List<PokemonDatabaseIndexEntry> _buildEncounterSpeciesSuggestions({
  required _EncounterReferenceData references,
  required String rawQuery,
}) {
  if (!references.isSpeciesAvailable) {
    return const <PokemonDatabaseIndexEntry>[];
  }
  final query = rawQuery.trim();
  if (query.isEmpty) {
    return const <PokemonDatabaseIndexEntry>[];
  }
  return _encounterSpeciesLookupService.search(
    references.speciesEntries,
    query,
    limit: 8,
  );
}

int _tableTotalWeight(ProjectEncounterTable table) {
  return table.entries.fold<int>(
    0,
    (sum, entry) => sum + (entry.weight > 0 ? entry.weight : 0),
  );
}

double? _entryChance({
  required ProjectEncounterTable table,
  required int weight,
}) {
  final totalWeight = _tableTotalWeight(table);
  if (weight <= 0 || totalWeight <= 0) {
    return null;
  }
  return weight / totalWeight;
}

String? _formatEncounterShare(double? share) {
  if (share == null) {
    return null;
  }
  return '${(share * 100).toStringAsFixed(1)}%';
}

String _kindLabel(EncounterKind kind) {
  return switch (kind) {
    EncounterKind.walk => 'Walk',
    EncounterKind.surf => 'Surf',
    EncounterKind.headbutt => 'Headbutt',
    EncounterKind.oldRod => 'Old Rod',
    EncounterKind.goodRod => 'Good Rod',
    EncounterKind.superRod => 'Super Rod',
    EncounterKind.gift => 'Gift',
    EncounterKind.special => 'Special',
  };
}

extension _EncounterTablesPanelSupport on _EncounterTablesPanelState {
  _EncounterEntryDraftValidation _validateEntryDraft({
    required _EncounterReferenceData references,
  }) {
    final speciesId = _entrySpeciesController.text.trim();
    final minLevel = int.tryParse(_entryMinLevelController.text.trim());
    final maxLevel = int.tryParse(_entryMaxLevelController.text.trim());
    final weight = int.tryParse(_entryWeightController.text.trim());

    String? speciesMessage;
    if (speciesId.isEmpty) {
      speciesMessage = 'Species ID cannot be empty.';
    } else if (references.isSpeciesAvailable &&
        _resolveEncounterSpecies(references, speciesId) == null) {
      speciesMessage =
          'Species "$speciesId" is not present in the local Pokédex.';
    }

    String? minLevelMessage;
    if (minLevel == null || minLevel <= 0) {
      minLevelMessage = 'Min level must be a positive integer.';
    }

    String? maxLevelMessage;
    if (maxLevel == null || maxLevel <= 0) {
      maxLevelMessage = 'Max level must be a positive integer.';
    } else if (minLevel != null && minLevel > 0 && minLevel > maxLevel) {
      maxLevelMessage = 'Max level must be greater than or equal to min level.';
    }

    String? weightMessage;
    if (weight == null || weight <= 0) {
      weightMessage = 'Weight must be a positive integer.';
    }

    return _EncounterEntryDraftValidation(
      speciesMessage: speciesMessage,
      minLevelMessage: minLevelMessage,
      maxLevelMessage: maxLevelMessage,
      weightMessage: weightMessage,
    );
  }

  String? _draftEncounterChance({
    required ProjectEncounterTable table,
  }) {
    final draftWeight = int.tryParse(_entryWeightController.text.trim());
    if (draftWeight == null || draftWeight <= 0) {
      return null;
    }

    var totalWeight = _tableTotalWeight(table);
    if (_editingEntryTableId == table.id && _editingEntryIndex != null) {
      final current = table.entries[_editingEntryIndex!];
      totalWeight = totalWeight - current.weight + draftWeight;
    } else {
      totalWeight += draftWeight;
    }

    if (totalWeight <= 0) {
      return null;
    }
    return _formatEncounterShare(draftWeight / totalWeight);
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart`

```dart
part of 'encounter_tables_panel.dart';

// ---------------------------------------------------------------------------
// Shared panel widgets
// ---------------------------------------------------------------------------
//
// These stay local to the encounter library. The corrective pass intentionally
// stops at presentational extraction: no new public widgets, no new panel
// architecture, and no new encounter-specific controller layer.

Widget _buildReferencesBanner(
  BuildContext context,
  _EncounterReferenceData references, {
  required Color accent,
  required VoidCallback onRefresh,
}) {
  final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
  final isAvailable = references.isSpeciesAvailable;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable
              ? accent.withValues(alpha: 0.25)
              : CupertinoColors.systemYellow.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.search_circle,
              size: 16,
              color: isAvailable
                  ? accent
                  : CupertinoColors.systemYellow.resolveFrom(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local species assist',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    references.speciesMessage,
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(1, 22),
              onPressed: onRefresh,
              child: const Icon(
                CupertinoIcons.refresh,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildOperationBanner(
  BuildContext context, {
  required String message,
  required bool isError,
}) {
  final color =
      isError ? EditorChrome.inspectorJoyCoral : EditorChrome.inspectorJoyCyan;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.38)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    ),
  );
}

Widget _buildInlineMessage(
  BuildContext context,
  String message, {
  required bool isError,
  Key? key,
}) {
  final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
  return Text(
    message,
    key: key,
    style: TextStyle(
      color: isError ? EditorChrome.inspectorJoyCoral : subtle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.35,
    ),
  );
}

Widget _labeledField(
  BuildContext context, {
  Key? fieldKey,
  required String label,
  required TextEditingController controller,
  required String placeholder,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  String? validationMessage,
}) {
  final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      ),
      const SizedBox(height: 4),
      CupertinoTextField(
        key: fieldKey,
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
      ),
      if (validationMessage != null) ...[
        const SizedBox(height: 4),
        _buildInlineMessage(
          context,
          validationMessage,
          isError: true,
        ),
      ],
    ],
  );
}

extension _EncounterTablesPanelTableWidgets on _EncounterTablesPanelState {
  Widget _buildCreateTableForm(
    BuildContext context,
    EditorNotifier notifier,
    Color accent,
  ) {
    final inlineValidation =
        _validateEncounterTableName(_newTableNameController.text);
    final message = _createTableValidationMessage ?? inlineValidation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded)
                const InspectorEmbeddedSectionLabel('Nouvelle table')
              else
                Text(
                  'New Table',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              _labeledField(
                context,
                fieldKey: const Key('encounter-tables-create-name-field'),
                label: 'Name',
                placeholder: 'Grass Patch',
                controller: _newTableNameController,
                onChanged: (_) => _runLocalStateMutation(() {
                  _createTableValidationMessage = null;
                }),
                validationMessage: inlineValidation,
              ),
              const SizedBox(height: 8),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: 'Kind',
                  valueLabel: _kindLabel(_newTableKind),
                  orderedIds: EncounterKind.values.map((k) => k.name).toList(),
                  selectedMenuValue: _newTableKind.name,
                  selectedIdForCheck: _newTableKind.name,
                  idToLabel: (id) => _kindLabel(
                    EncounterKind.values.firstWhere((k) => k.name == id),
                  ),
                  onSelected: (id) => _runLocalStateMutation(() {
                    _newTableKind =
                        EncounterKind.values.firstWhere((k) => k.name == id);
                  }),
                  tooltip: 'Encounter kind',
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<EncounterKind>(
                      context: context,
                      title: 'Encounter Kind',
                      items: EncounterKind.values,
                      labelOf: _kindLabel,
                    );
                    if (picked != null) {
                      _runLocalStateMutation(() => _newTableKind = picked);
                    }
                  },
                  child: Text('Kind: ${_kindLabel(_newTableKind)}'),
                ),
              if (message != null && inlineValidation == null) ...[
                const SizedBox(height: 8),
                _buildInlineMessage(
                  context,
                  message,
                  isError: true,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      key: const Key(
                        'encounter-tables-create-submit-button',
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onPressed: inlineValidation == null
                          ? () => _createTable(notifier)
                          : null,
                      child: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _runLocalStateMutation(
                      _resetCreateTableDraft,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard({
    required BuildContext context,
    required EditorNotifier notifier,
    required ProjectEncounterTable table,
    required _EncounterReferenceData references,
    required Color accent,
    required Color subtle,
  }) {
    final isEditingThis = _editingTableId == table.id;
    final totalWeight = _tableTotalWeight(table);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEditingThis
                ? accent.withValues(alpha: 0.7)
                : EditorChrome.editorIslandRim(context),
            width: 1,
          ),
          boxShadow: EditorChrome.inspectorTileHardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoButton(
              key: Key('encounter-tables-table-toggle-${table.id}'),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              alignment: Alignment.centerLeft,
              onPressed: () {
                _runLocalStateMutation(() {
                  if (_editingTableId == table.id) {
                    _closeTableEditor();
                  } else {
                    _editingTableId = table.id;
                    _editTableNameController.text = table.name;
                    _editTableKind = table.encounterKind;
                    _editTableValidationMessage = null;
                    _showCreateForm = false;
                    _closeEntryEditor();
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.list_bullet,
                    size: 15,
                    color: isEditingThis ? accent : subtle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: isEditingThis
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_kindLabel(table.encounterKind)} · ${table.entries.length} entr${table.entries.length == 1 ? 'y' : 'ies'} · total weight $totalWeight · ${table.id}',
                          style: TextStyle(fontSize: 11, color: subtle),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isEditingThis
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: subtle,
                  ),
                ],
              ),
            ),
            if (isEditingThis) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: EditorHorizontalDivider(),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _buildTableEditor(
                  context,
                  notifier,
                  table,
                  references,
                  accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableEditor(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    _EncounterReferenceData references,
    Color accent,
  ) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditingEntry = _editingEntryTableId == table.id;
    final inlineValidation =
        _validateEncounterTableName(_editTableNameController.text);
    final totalWeight = _tableTotalWeight(table);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeledField(
          context,
          fieldKey: Key('encounter-tables-edit-name-field-${table.id}'),
          label: 'Name',
          placeholder: 'Grass Patch',
          controller: _editTableNameController,
          onChanged: (_) => _runLocalStateMutation(() {
            _editTableValidationMessage = null;
          }),
          validationMessage: inlineValidation,
        ),
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: 'Kind',
            valueLabel: _kindLabel(_editTableKind),
            orderedIds: EncounterKind.values.map((k) => k.name).toList(),
            selectedMenuValue: _editTableKind.name,
            selectedIdForCheck: _editTableKind.name,
            idToLabel: (id) => _kindLabel(
              EncounterKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) => _runLocalStateMutation(() {
              _editTableKind =
                  EncounterKind.values.firstWhere((k) => k.name == id);
            }),
            tooltip: 'Encounter kind',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<EncounterKind>(
                context: context,
                title: 'Encounter Kind',
                items: EncounterKind.values,
                labelOf: _kindLabel,
              );
              if (picked != null) {
                _runLocalStateMutation(() => _editTableKind = picked);
              }
            },
            child: Text('Kind: ${_kindLabel(_editTableKind)}'),
          ),
        if (_editTableValidationMessage != null &&
            inlineValidation == null) ...[
          const SizedBox(height: 8),
          _buildInlineMessage(
            context,
            _editTableValidationMessage!,
            isError: true,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                key: Key('encounter-tables-save-table-button-${table.id}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                onPressed: inlineValidation == null
                    ? () => _updateTable(notifier, table.id)
                    : null,
                child: const Text('Save Table'),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              key: Key('encounter-tables-delete-table-button-${table.id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: () => _deleteTable(notifier, table.id),
              child: const Text('Delete Table'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const EditorHorizontalDivider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Entries (${table.entries.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtle,
                ),
              ),
            ),
            Text(
              'Total weight: $totalWeight',
              style: TextStyle(fontSize: 11, color: subtle),
            ),
            const SizedBox(width: 8),
            EditorToolbarIconButton(
              key: Key('encounter-tables-add-entry-button-${table.id}'),
              onPressed: () {
                _runLocalStateMutation(() {
                  _editingEntryTableId = table.id;
                  _editingEntryIndex = null;
                  _entryValidationMessage = null;
                  _entrySpeciesController.clear();
                  _entryMinLevelController.text = '1';
                  _entryMaxLevelController.text = '5';
                  _entryWeightController.text = '1';
                });
              },
              icon: CupertinoIcons.add,
              tooltip: 'Add entry',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Higher weight means the entry appears more often. Percentages below are derived from the current table.',
          style: TextStyle(fontSize: 11, color: subtle, height: 1.35),
        ),
        if (table.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No entries yet.',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ...List.generate(table.entries.length, (index) {
            final entry = table.entries[index];
            final isEditingThisEntry =
                isEditingEntry && _editingEntryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildEntryRow(
                context: context,
                table: table,
                entry: entry,
                entryIndex: index,
                references: references,
                isEditingThisEntry: isEditingThisEntry,
                accent: accent,
                onToggleEdit: () {
                  _runLocalStateMutation(() {
                    if (isEditingThisEntry) {
                      _closeEntryEditor();
                    } else {
                      _editingEntryTableId = table.id;
                      _editingEntryIndex = index;
                      _entryValidationMessage = null;
                      _entrySpeciesController.text = entry.speciesId;
                      _entryMinLevelController.text = entry.minLevel.toString();
                      _entryMaxLevelController.text = entry.maxLevel.toString();
                      _entryWeightController.text = entry.weight.toString();
                    }
                  });
                },
                onDelete: () => _deleteEntry(notifier, table.id, index),
              ),
            );
          }),
        if (isEditingEntry) ...[
          const SizedBox(height: 8),
          _buildEntryForm(
            context,
            notifier,
            table,
            references,
            accent,
          ),
        ],
      ],
    );
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart`

```dart
part of 'encounter_tables_panel.dart';

extension _EncounterTablesPanelEntryWidgets on _EncounterTablesPanelState {
  Widget _buildEntryRow({
    required BuildContext context,
    required ProjectEncounterTable table,
    required ProjectEncounterEntry entry,
    required int entryIndex,
    required _EncounterReferenceData references,
    required bool isEditingThisEntry,
    required Color accent,
    required VoidCallback onToggleEdit,
    required VoidCallback onDelete,
  }) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies =
        _resolveEncounterSpecies(references, entry.speciesId);
    final chanceLabel = _formatEncounterShare(
      _entryChance(table: table, weight: entry.weight),
    );

    return DecoratedBox(
      key: Key('encounter-tables-entry-row-${table.id}-$entryIndex'),
      decoration: BoxDecoration(
        color: isEditingThisEntry
            ? Color.lerp(
                EditorChrome.islandFillElevated(context),
                accent,
                0.18,
              )!
            : EditorChrome.islandFill(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEditingThisEntry
              ? accent.withValues(alpha: 0.6)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        alignment: Alignment.centerLeft,
        onPressed: onToggleEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedSpecies == null
                        ? '${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}'
                        : '${resolvedSpecies.primaryName} • ${entry.speciesId} • Lv.${entry.minLevel}-${entry.maxLevel}',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weight ${entry.weight}${chanceLabel == null ? '' : ' • $chanceLabel'}',
                    style: TextStyle(fontSize: 11, color: subtle),
                  ),
                  if (resolvedSpecies == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      references.isSpeciesAvailable
                          ? 'Species not present in the local Pokédex.'
                          : 'Local species verification unavailable. The raw species ID is preserved.',
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            EditorToolbarIconButton(
              onPressed: onDelete,
              icon: CupertinoIcons.trash,
              tooltip: 'Delete entry',
              iconSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm(
    BuildContext context,
    EditorNotifier notifier,
    ProjectEncounterTable table,
    _EncounterReferenceData references,
    Color accent,
  ) {
    final isNew = _editingEntryIndex == null;
    final validation = _validateEntryDraft(references: references);
    final speciesStatus = _resolveEncounterSpeciesStatus(
      references: references,
      rawSpeciesId: _entrySpeciesController.text,
    );
    final suggestions = _buildEncounterSpeciesSuggestions(
      references: references,
      rawQuery: _entrySpeciesController.text,
    );
    final previewShare = _draftEncounterChance(table: table);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'New Entry' : 'Edit Entry',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              fieldKey: const Key('encounter-tables-entry-species-field'),
              label: 'Species ID',
              placeholder: 'bulbasaur',
              controller: _entrySpeciesController,
              onChanged: (_) => _runLocalStateMutation(() {
                _entryValidationMessage = null;
              }),
              validationMessage: validation.speciesMessage,
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              speciesStatus.message,
              isError: speciesStatus.isError,
            ),
            if (_entrySpeciesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              if (!references.isSpeciesAvailable)
                _buildInlineMessage(
                  context,
                  'Local species suggestions are unavailable right now.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-unavailable',
                  ),
                )
              else if (suggestions.isEmpty)
                _buildInlineMessage(
                  context,
                  'No local species suggestion matches this query.',
                  isError: true,
                  key: const Key(
                    'encounter-tables-entry-species-search-empty',
                  ),
                )
              else
                Container(
                  key: const Key(
                    'encounter-tables-entry-species-suggestions',
                  ),
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = suggestions[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: EditorChrome.islandFill(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          key: Key(
                            'encounter-tables-entry-species-suggestion-${entry.id}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onPressed: () => _selectSuggestedSpecies(entry.id),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.primaryName} • ${entry.id}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.types.join(' / ')}',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Use',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-min-level-field'),
                    label: 'Min Lv',
                    placeholder: '1',
                    controller: _entryMinLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.minLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey:
                        const Key('encounter-tables-entry-max-level-field'),
                    label: 'Max Lv',
                    placeholder: '5',
                    controller: _entryMaxLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.maxLevelMessage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _labeledField(
                    context,
                    fieldKey: const Key('encounter-tables-entry-weight-field'),
                    label: 'Weight',
                    placeholder: '1',
                    controller: _entryWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _runLocalStateMutation(() {
                      _entryValidationMessage = null;
                    }),
                    validationMessage: validation.weightMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildInlineMessage(
              context,
              previewShare == null
                  ? 'Higher weight means the entry appears more often.'
                  : 'With the current draft, this entry would represent $previewShare of the table.',
              isError: false,
            ),
            if (_entryValidationMessage != null &&
                validation.firstMessage == null) ...[
              const SizedBox(height: 8),
              _buildInlineMessage(
                context,
                _entryValidationMessage!,
                isError: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    key: const Key('encounter-tables-entry-save-button'),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onPressed: validation.firstMessage == null
                        ? () => _saveEntry(notifier, table.id, references)
                        : null,
                    child: Text(isNew ? 'Add' : 'Save'),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  onPressed: () => _runLocalStateMutation(_closeEntryEditor),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/encounter_tables_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/encounter_tables_panel.dart';

void main() {
  Future<void> pumpEncounterPanel(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 1800,
                child: EncounterTablesPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'creates a table and a valid encounter entry with local species assist',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-new-table-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-create-name-field')),
      'Grass Patch',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-create-submit-button')),
    );
    await tester.pumpAndSettle();

    final table =
        container.read(editorNotifierProvider).project!.encounterTables.single;
    expect(table.id, 'grass_patch');
    expect(table.name, 'Grass Patch');

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('encounter-tables-entry-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '4',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '3',
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-entry-save-button')),
    );
    await tester.pumpAndSettle();

    final savedEntry = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables
        .single
        .entries
        .single;
    expect(savedEntry.speciesId, 'bulbasaur');
    expect(savedEntry.minLevel, 2);
    expect(savedEntry.maxLevel, 4);
    expect(savedEntry.weight, 3);
    expect(
        find.textContaining('Bulbasaur • bulbasaur • Lv.2-4'), findsOneWidget);
    expect(find.textContaining('100.0%'), findsOneWidget);
  });

  testWidgets(
      'shows inline validation and blocks save when local species or levels are invalid',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'missingno',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '0',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Species "missingno" is not present in the local Pokédex.'),
      findsOneWidget,
    );
    expect(
      find.text('Max level must be greater than or equal to min level.'),
      findsOneWidget,
    );
    expect(
      find.text('Weight must be a positive integer.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('encounter-tables-entry-save-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .single
          .entries,
      isEmpty,
    );
  });

  testWidgets('closes the table editor after a successful table update',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      'Tall Grass',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('encounter-tables-save-table-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    final savedTable =
        container.read(editorNotifierProvider).project!.encounterTables.single;
    expect(savedTable.name, 'Tall Grass');
    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
      findsNothing,
    );
    expect(find.text('Tall Grass'), findsOneWidget);
  });

  testWidgets(
      'keeps the panel usable when the local species index is unavailable',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
          'Unable to load local species data. Raw species IDs are still allowed.'),
      findsOneWidget,
    );

    await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'missingno',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '7',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to verify against local species data. Raw species IDs are still allowed.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Local species suggestions are unavailable right now.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-entry-save-button')),
    );
    await tester.pumpAndSettle();

    final savedEntry = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables
        .single
        .entries
        .single;
    expect(savedEntry.speciesId, 'missingno');
    expect(
      find.text(
        'Local species verification unavailable. The raw species ID is preserved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps the create form open and surfaces the error when persistence fails',
      (tester) async {
    final repository = _FakeProjectRepository(
      saveError: StateError('disk exploded'),
    );
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-new-table-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-create-name-field')),
      'Grass Patch',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-create-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('encounter-tables-create-name-field')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          'Failed to create encounter table: Bad state: disk exploded'),
      findsWidgets,
    );
    expect(
      container.read(editorNotifierProvider).project!.encounterTables,
      isEmpty,
    );
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'pikachu',
    nationalDex: 25,
    primaryName: 'Pikachu',
    genIntroduced: 1,
    types: <String>['electric'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'pikachu',
      evolution: 'pikachu',
      media: 'pikachu',
    ),
  ),
];

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    this.saveError,
  });

  final Object? saveError;
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    if (saveError != null) {
      throw saveError!;
    }
    savedProjects.add(project);
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRootPath) => workspace;
}
```

### `/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md`

````markdown
# Roadmap Maître Recalée — pokemonProject

## 1. But du document

Ce document sert de **roadmap maître recalée** pour la suite du projet.

Il ne repart pas de zéro.
Il part de l'état réel actuel du repo et d'un principe central qui ne doit pas bouger :

**on améliore l'existant, on ne crée aucune stack parallèle.**

Cela implique explicitement :

- pas de nouveau runtime Pokémon parallèle ;
- pas de nouveau save system parallèle ;
- pas de nouveau modèle concurrent à `PlayerPokemon` ;
- pas de nouveau moteur de combat parallèle à `map_battle` ;
- pas de second pipeline Pokédex ;
- pas de logique métier poussée dans les widgets UI ;
- pas de grand refactor transversal "propre" si une extension locale honnête suffit.

Ce document remplace une roadmap trop "domain-first" par une roadmap plus **réaliste, verticale et pilotable**.

## 2. Résumé exécutif

Le projet a déjà dépassé le stade du prototype vide.

Aujourd'hui, le repo dispose déjà de fondations réelles pour :

- la persistance de partie ;
- le Pokédex local et ses imports externes ;
- le catalogue local des moves ;
- l'édition minimale des learnsets ;
- les trainers et les encounter tables ;
- les battle requests runtime ;
- un moteur de combat pur Dart encore minimal ;
- un pattern réel de field move avec Surf.

Le vrai enjeu n'est donc plus de "construire un système Pokémon from scratch".
Le vrai enjeu est de **faire converger les briques existantes vers une boucle fangame complète**.

Le point le plus important de cette version recalée est le suivant :

**le bridge runtime -> battle réel doit arriver tôt**.

On ne doit pas repousser indéfiniment la preuve de la boucle de jeu pendant qu'on peaufine l'authoring.
La bonne stratégie est :

1. rendre le Pokédex auteur vraiment productif ;
2. brancher les références assistées là où elles ont déjà un retour immédiat ;
3. rendre trainers et encounters suffisamment propres pour produire de vraies données ;
4. supprimer le placeholder du handoff runtime -> battle ;
5. obtenir un combat sauvage réel ;
6. obtenir capture + persistance minimale ;
7. seulement ensuite approfondir le moteur de combat et élargir la boucle RPG.

## 3. Ce qui est déjà acquis dans le repo

Cette section ne décrit pas des intentions.
Elle décrit les éléments déjà présents dans l'état actuel du repo et du worktree.

### 3.1. Save et modèle de partie

Le repo a déjà une vraie base persistée :

- `GameState`
- `SaveData`
- `PlayerPokemon`
- `PlayerParty`
- `TrainerProfile`
- `Bag`
- `PlayerProgression`
- migration legacy et persistance runtime

Conclusion :

- on ne crée surtout pas de modèle `OwnedPokemon` concurrent ;
- on ne crée surtout pas un second format de save.

### 3.2. Pokédex et import Pokémon

La phase 11A est considérée comme clôturée.
Le repo a déjà :

- une config Pokémon projet légère dans `ProjectManifest` ;
- un `dataRoot`, des sous-dossiers dédiés (`species`, `learnsets`, `evolutions`, `media`) et des `catalogFiles` explicites ;
- un bootstrap local via `InitializePokemonProjectStorageUseCase` ;
- un pipeline d'import externe Pokémon ;
- un `dryRun` et une preview ;
- une source produit unique côté UI ;
- des mini-fix de cohérence média ;
- une preuve de clôture 11A documentée.

Conclusion :

- on ne rouvre pas artificiellement 11A ;
- on n'écrit pas un deuxième pipeline d'import externe.

### 3.2.1. Avancement réel de la phase R1 déjà livré dans le worktree

Les sept premiers lots de la phase R1 ont maintenant été livrés dans le
worktree courant. Ils ne sont plus à considérer comme du travail à démarrer,
mais comme du socle acquis à prolonger proprement.

#### Lot 1 — Résolveur de requête externe Pokédex

Ce lot existe maintenant côté application avec :

- un modèle de résolution structuré pour :
  - mono-espèce ;
  - liste explicite ;
  - plage dex ;
  - génération ;
  - requête invalide / ambiguë ;
- un résolveur pur, sans réseau et sans UI ;
- un provider DI dédié dans `map_editor`.

Le contrat déjà livré couvre au minimum :

- `bulbasaur`
- `1`
- `001`
- `0001`
- `1-151`
- `gen 1`
- `generation 2`
- `pikachu, eevee, abra`
- refus explicite des cas ambigus de type `pikachu eevee abra`

#### Lot 2 — Auto-complétion mono-espèce dans le wizard

Ce lot existe maintenant dans la branche `API externe` du wizard Pokédex avec :

- un use case de recherche mono-espèce réutilisant le résolveur du lot 1 ;
- une vraie surface de suggestions ;
- une sélection explicite obligatoire ;
- un blocage de la preview/import tant qu'aucune suggestion réelle n'a été
  choisie ;
- des états propres :
  - vide ;
  - loading ;
  - aucun résultat ;
  - hors-scope ;
  - invalide ;
  - erreur.

Le point important à conserver pour la suite :

- le widget ne parse pas la requête lui-même ;
- la preview/import mono-espèce ne repose pas sur une simple string tapée ;
- seule une suggestion explicitement sélectionnée débloque la suite.

#### Lot 3 — Sélection batch + dry-run batch

Ce lot existe maintenant dans la même branche `API externe` du wizard avec :

- un mode explicite `Mono-espèce` / `Batch dry-run` ;
- un use case dédié de résolution batch, réutilisant le résolveur du lot 1 ;
- la compréhension de trois formes batch :
  - liste explicite ;
  - plage dex ;
  - génération ;
- une liste finale résolue visible avant toute preview ;
- un dry-run batch branché sur le pipeline batch applicatif existant avec
  `dryRun: true` ;
- une preview batch lisible ;
- un blocage explicite de tout import batch réel.

Règles déjà en place à ne pas casser :

- une liste explicite partiellement résolue reste visible mais bloque le
  dry-run ;
- les requêtes par plage dex et génération ne ciblent volontairement que les
  espèces de base ;
- une liste explicite peut encore conserver une forme si elle a été demandée
  explicitement ;
- le dry-run batch n'écrit rien et ne constitue pas encore une exécution lot 4.

Artefacts de preuve déjà présents :

- `reports/phase-r1-lot-1-pokedex-query-resolver-report.md`
- `reports/phase-r1-lot-2-pokedex-external-autocomplete-report.md`
- `reports/phase-r1-lot-3-batch-selection-dry-run-report.md`

#### Lot 4 — Exécution batch + progression + rapport

Ce lot existe maintenant dans le même flow `API externe`, sans réécrire le
pipeline batch applicatif existant.

Ce qui est désormais livré :

- une action explicite d'exécution batch réelle distincte du dry-run ;
- une progression honnête alimentée par les callbacks réels du use case batch ;
- un écran de résultat séparé du dry-run preview ;
- des compteurs visibles :
  - succès ;
  - conflits ;
  - erreurs ;
  - skips ;
  - espèces terminées ;
- un rapport final détaillé par espèce ;
- un refresh du workspace si au moins une espèce a réellement été écrite ;
- une règle stable de sélection post-import :
  - première espèce réellement écrite dans l'ordre visible de la sélection batch
    ;
- conservation stricte du flow mono-espèce et du dry-run du lot 3.

Décisions d'implémentation désormais en place :

- aucun pipeline batch parallèle n'a été créé ;
- `BatchImportExternalPokemonSpeciesUseCase` reste le cœur d'exécution ;
- une extension minimale du use case expose une progression honnête par espèce
  terminée ;
- l'UI ne simule aucun faux pourcentage interne ;
- le rapport final réutilise directement `PokemonExternalBatchImportResult`.

Limites assumées à ce stade :

- pas de retry sélectif ;
- pas de relance partielle depuis le rapport ;
- pas d'import en arrière-plan ;
- pas de cancellation complexe ;
- pas de pagination du rapport final.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-4-batch-execution-progress-report.md`
- `reports/phase-r1-lot-4-mini-fix-no-write-feedback-report.md`

Mini-fix déjà livré à conserver :

- le feedback final batch est maintenant aligné sur les écritures réelles ;
- un batch avec `0` écriture réelle ne remonte plus comme un succès silencieux ;
- le critère produit global s'aligne sur `hasWritesApplied`, exactement comme le
  refresh du workspace.

#### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Ce lot existe maintenant dans le learnset editor du Pokédex, sans créer de
deuxième éditeur ni de deuxième contrat de learnset.

Ce qui est désormais livré :

- une recherche locale assistée dans le catalogue `moves` par :
  - `id` ;
  - `name` ;
  - alias pertinents quand ils sont présents dans les données déjà chargées ;
- une sélection explicite de move depuis l'éditeur au lieu d'une saisie brute
  systématique d'ids ;
- une assistance concrète pour les sections de learnset existantes :
  - `startingMoves` ;
  - `relearnMoves` ;
  - `levelUp` ;
  - `tm` ;
  - `tutor` ;
  - `egg` ;
  - `event` ;
  - `transfer` ;
- un affichage honnête des ids legacy / inconnus :
  - l'entrée reste visible ;
  - elle n'est pas détruite silencieusement ;
  - elle est signalée comme absente du catalogue local quand c'est le cas ;
- une validation plus lisible autour des moves manquants et des incohérences
  évidentes, sans déplacer le cœur métier dans l'UI.

Décision importante déjà en place :

- le texte brut reste le contrat d'édition réel du learnset ;
- l'assistance moves-first vient au-dessus pour sécuriser et accélérer la
  saisie, mais ne masque pas les données ni ne crée une UI concurrente.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-5-moves-first-learnset-report.md`

#### Lot 6 — Service de recherche catalogue progressif

Ce lot existe maintenant côté `map_editor/application/services` et ne recrée
pas de deuxième système de lookup `moves`.

Ce qui est désormais livré :

- un petit contrat stable de recherche locale en mémoire pour les catalogues ;
- une base concrète réutilisable :
  - `ProgressiveLocalCatalogLookupService<TEntry>` ;
- une convergence du service lot 5 vers ce socle au lieu de dupliquer la
  logique ;
- une implémentation réellement branchée sur `moves` via
  `PokemonMovesCatalogLookupService` ;
- des tests dédiés du contrat progressif et de la non-régression côté moves.

Décisions d'architecture désormais en place :

- pas d'interface "enterprise" supplémentaire ;
- pas de provider décoratif ajouté juste pour la forme ;
- pas de moteur multi-catalogues théorique ;
- un petit socle concret, utilisé tout de suite par `moves`, et crédible pour
  les futurs besoins trainers / encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-6-progressive-catalog-search-report.md`

#### Lot 7 — Trainers : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface trainers existante, sans réécrire le
CRUD trainer déjà présent ni introduire de système parallèle.

Ce qui est désormais livré :

- création / édition / suppression trainer depuis l'UI sans passer par le JSON
  ;
- édition d'une team trainer réellement exploitable ;
- ajout et édition de Pokémon de team avec les champs déjà présents côté métier
  :
  - species ;
  - level ;
  - moves ;
  - held item ;
  - form ;
  - gender ;
  - shiny ;
- assistance locale branchée là où elle existe honnêtement :
  - species via l'index Pokédex local ;
  - moves via le catalogue local `moves` ;
  - items via le catalogue local `items` quand il est disponible ;
  - forms via les données locales de l'espèce sélectionnée ;
- conservation explicite de la saisie brute quand une source locale n'existe
  pas ou n'est pas prête ;
- validation inline plus lisible avant save ;
- sauvegarde stable via les use cases trainers existants.

Micro-vérification lot 6 intégrée dans ce lot :

- le socle `ProgressiveLocalCatalogLookupService<TEntry>` a été conservé tel
  quel ;
- aucun renommage cosmétique n'a été fait ;
- la réutilisation est restée locale et progressive via :
  - `PokemonSpeciesLookupService` ;
  - `PokemonItemsCatalogLookupService` ;
  - `PokemonMovesCatalogLookupService` existant.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-7-trainers-minimal-authoring-report.md`

#### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Ce lot existe maintenant dans la surface `EncounterTablesPanel` déjà présente,
sans créer de deuxième éditeur, de deuxième pipeline encounter ni de nouvelle
stack de persistance.

Ce qui est désormais livré :

- création / édition / suppression de tables de rencontres depuis l'UI ;
- ajout / édition / suppression d'entrées de rencontre depuis la même surface ;
- assistance locale `species` réutilisant l'index Pokédex déjà présent ;
- validation inline lisible sur :
  - `species` ;
  - `minLevel` ;
  - `maxLevel` ;
  - `weight` ;
- distinction honnête entre trois états auteur :
  - espèce résolue localement ;
  - espèce absente du Pokédex local ;
  - vérification impossible parce que les données locales sont indisponibles ;
- conservation de la saisie brute quand la vérification locale n'est pas
  possible ;
- lisibilité réelle des poids avec part relative dérivée de la table courante ;
- fermeture des formulaires uniquement sur succès réel du pipeline existant ;
- sauvegarde stable via les use cases encounter déjà présents.

Décisions explicitement retenues :

- aucun reorder n'a été ajouté :
  - le runtime sélectionne déjà par poids, pas par ordre ;
  - ce n'était donc pas un prérequis honnête pour franchir le seuil auteur M2 ;
- aucun provider/use case/repository encounter parallèle n'a été créé ;
- `EditorNotifier` a seulement été réaligné sur le contrat de succès/échec
  déjà utilisé côté trainers pour garder les formulaires ouverts en cas d'échec
  ;
- le support local reste strictement `species-first` pour les encounters.

Artefact de preuve ajouté :

- `reports/phase-r1-lot-8-encounters-m2-report.md`

### 3.3. Catalogues locaux et moves catalog

Le repo n'est plus dans un état "catalogues à inventer".
Il a déjà :

- un scaffold local de catalogues dans l'arborescence Pokémon du projet ;
- des clés catalogue explicites dans la config Pokémon ;
- un import JSON catalogue local ;
- des validations croisées déjà branchées sur certains catalogues ;
- des seeds et jeux de démonstration pour plusieurs familles.

La phase 11B a ensuite fait exister un vrai premier jalon moves dans le worktree courant :

- catalogue local des moves ;
- sync/import depuis source externe ;
- surface minimale côté éditeur ;
- première intégration utile avec le learnset editor.

Le repo valide déjà concrètement :

- `learnset -> moves catalog`
- `species -> types catalog`

et sait déjà basculer certains catalogues manquants vers des warnings explicites plutôt que des comportements opaques.

Conclusion :

- la partie "catalogues" ne repart pas de zéro ;
- la stratégie réaliste est bien **moves-first**, déjà amorcée puis renforcée ;
- le prochain travail doit réutiliser ce socle et son contrat progressif au
  lieu de les réécrire.

### 3.4. Trainers et encounter tables

Le repo contient déjà :

- `ProjectTrainerEntry` et ses variantes associées ;
- des use cases trainers ;
- des use cases encounter tables ;
- un wiring applicatif déjà exposé dans l'éditeur ;
- des panneaux éditeur existants ;
- la résolution de rencontres côté `map_gameplay`.

Conclusion :

- la surface trainers a maintenant franchi le seuil "vraiment exploitable" pour
  un auteur ;
- la surface encounters a maintenant rejoint ce même seuil minimal
  d'exploitabilité ;
- on ne crée pas un second système de trainers ou de rencontres.

### 3.5. Runtime et battle skeleton

Le runtime sait déjà :

- déclencher une demande de combat sauvage ;
- déclencher une demande de combat trainer ;
- produire de vrais `BattleStartRequest` sauvages et trainers ;
- ouvrir un overlay de combat ;
- relayer un flux de retour combat vers l'overworld.

Le moteur `map_battle` existe déjà, mais il reste un MVP.

Le vrai trou actuel est bien le dernier maillon :

- le mapping final vers `BattleSetup` reste encore placeholder ;
- `_toBattleSetup()` injecte encore des espèces, niveaux et moves simplifiés au lieu de consommer complètement les vraies données projet/save.

Conclusion :

- le vrai point critique n'est pas "faire apparaître un combat" ;
- le vrai point critique est de **faire cesser les placeholders métier** entre runtime, données projet et moteur battle.

### 3.6. Field moves

Surf existe déjà comme pattern réel.

Conclusion :

- les futures capacités terrain doivent généraliser ce pattern ;
- elles ne doivent pas le dupliquer en plusieurs sous-systèmes hardcodés.

## 4. Ce qui reste partiel

Cette section couvre les zones déjà entamées mais pas encore suffisamment solides pour être considérées comme "terminées".

### 4.1. Pokédex auteur

Le Pokédex existe, et la phase R1 a déjà fortement avancé dans le worktree :

- la résolution de requête externe existe ;
- l'auto-complétion mono-espèce existe ;
- le flow batch existe maintenant jusqu'à l'exécution réelle avec rapport ;
- l'assistance moves-first du learnset editor est réellement branchée ;
- un socle progressif de recherche catalogue locale existe maintenant pour
  préparer la suite sans recréer de deuxième système.

Ce qui manque encore côté Pokédex auteur :

- la maintenance bulk ergonomique plus riche ;
- les outils de revalidation / resync / maintenance globale ;
- l'extension du socle moves-first aux surfaces futures qui en ont réellement
  besoin ;
- le confort auteur sur gros volumes de données.

### 4.2. Catalogues et références assistées

Le catalogue moves n'est plus seulement présent au niveau technique ; il est
maintenant réellement exploité au niveau produit dans le learnset editor, et il
dispose désormais d'un premier contrat progressif de recherche locale.

Ce qui reste encore partiel :

- les trainers bénéficient maintenant d'une première exploitation réelle du
  socle progressif pour species / moves / items ;
- les autres écrans n'en profitent pas encore suffisamment ;
- moves reste la priorité avant toute généralisation plus large ;
- abilities / items / types / egg groups / growth rates sont encore à traiter
  de manière progressive.

### 4.3. Trainers et encounters

Le socle n'est plus au même stade des deux côtés :

- trainers :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut créer un trainer complet sans JSON ;
  - il reste du confort plus tardif, mais le seuil produit du lot 7 est atteint
    ;
- encounters :
  - la surface minimale exploitable est maintenant livrée ;
  - un auteur peut configurer une table wild valide sans JSON manuel fragile ;
  - il reste du confort plus tardif, mais le seuil produit du lot 8 est
    atteint.

### 4.4. Bridge runtime -> battle

C'est aujourd'hui le plus gros point de vérité technique restant :

- le runtime sait lancer le combat ;
- mais le mapping final vers `BattleSetup` reste encore trop placeholder ;
- tant que ça n'est pas traité, la boucle de jeu Pokémon n'est pas vraiment prouvée.

### 4.5. Combat system

Le moteur battle existe, mais la profondeur système reste limitée :

- dégâts encore trop simplifiés ;
- pas encore toute la chaîne type chart / PP / accuracy / switch / statuts ;
- pas encore une boucle Pokémon crédible de bout en bout.

## 5. Ce qui reste réellement à construire

Voici les grands blocs qui restent réellement à construire, en distinguant bien le cœur de boucle du confort plus tardif.

### 5.1. Must-have avant toute ambition "fangame complet"

- maintenance Pokédex bulk plus riche
- extension progressive du socle moves-first aux surfaces suivantes utiles
- bridge runtime -> battle réel
- combat sauvage réel
- seen/caught persistant
- capture minimale
- trainer battle minimal complet
- heal / whiteout-lite

### 5.2. Should-have après preuve de boucle

- catalogues additionnels progressifs
- battle depth stage 1 puis stage 2
- starter / gifts / static encounters
- shop minimal
- centre Pokémon plus propre
- field abilities généralisées

### 5.3. Later

- tooling auteur plus riche
- recherche globale projet
- dashboard santé étendu
- UX runtime joueur plus ambitieuse
- documentation complète
- projet démo de référence
- packaging / build guide final

## 6. Roadmap maître recalée

La roadmap ci-dessous est le nouveau document de pilotage global.
Elle est volontairement plus compacte que la première version.

### Phase A — Pokédex auteur productif

But :

- rendre l'import, la recherche, le batch et la maintenance Pokédex réellement exploitables à l'échelle.

Contenu :

- résolveur de requête externe ;
- auto-complétion mono-espèce ;
- batch selection ;
- dry-run batch ;
- exécution batch ;
- rapport final ;
- revalidate / reimport / delete / maintenance bulk.

### Phase B — Références assistées progressives, moves-first

But :

- faire disparaître les champs texte bruts là où ils créent le plus de dette.

Ordre recommandé :

1. moves partout où ils débloquent une vraie valeur ;
2. species/forms/items dans trainers et encounters ;
3. autres catalogues seulement quand un écran ou une boucle les exige réellement.

Important :

- cette phase part d'un socle déjà présent ;
- elle ne recrée ni le moves catalog, ni son import, ni sa première surface éditeur ;
- elle prolonge ce qui est déjà livré en 11B.

Avancement réel à date :

- lot 5 livré :
  - learnset editor moves-first réellement assisté ;
- lot 6 livré :
  - contrat progressif de recherche catalogue locale branché sur `moves`.
- lot 7 livré :
  - trainers branchés sur ce socle de manière locale et non parallèle pour
    species / moves / items / forms quand ces données sont réellement
    disponibles.

### Phase C — Authoring trainers / encounters convergent

But :

- permettre à un auteur de produire sans JSON manuel des données directement combatables.

Contenu :

- trainer library minimal mais propre ;
- encounter tables minimales mais propres ;
- validation inline ;
- preview auteur simple.

Avancement réel à date :

- lot 7 livré :
  - la partie trainers du milestone est atteinte ;
- lot 8 livré :
  - encounter tables minimales mais propres ;
  - assistance locale `species` branchée sur le Pokédex local ;
  - validation inline lisible sur species / niveaux / poids ;
  - surface suffisante pour authorer une table wild sans texte libre fragile.

### Phase D — Bridge runtime -> battle réel

But :

- faire sauter le placeholder entre les données projet/save et le moteur battle.

Contenu :

- mapper la vraie party joueur ;
- mapper les wild encounters réels ;
- mapper les vraies teams trainers ;
- appliquer proprement le résultat de combat au `GameState`.

### Phase E — Boucle Pokémon minimale jouable

But :

- prouver une vraie boucle Pokémon verticale.

Contenu :

- combat sauvage réel ;
- seen/caught ;
- capture minimale ;
- save/load cohérent ;
- combat trainer minimal ;
- heal / whiteout-lite.

### Phase F — Battle depth progressive

But :

- rendre le combat crédible sans bloquer la preuve de boucle.

Découpage recommandé :

- F1 : stats et payloads enrichis
- F2 : dégâts + STAB + type chart
- F3 : accuracy + crit + priorité + PP
- F4 : switch et parties complètes
- F5 : statuts majeurs
- F6 : abilities / items / forms progressifs
- F7 : rewards / IA / hooks de progression

### Phase G — Boucle fangame minimale complète

But :

- dépasser la simple preuve de combat pour obtenir un mini jeu Pokémon jouable.

Contenu :

- starter / gift / static encounter ;
- centre Pokémon ;
- shop minimal ;
- progression terrain généralisée ;
- économie et boucle de survie plus propre.

### Phase H — Tooling auteur, UX runtime et docs

But :

- transformer le repo en vrai produit interne confortable.

Contenu :

- validation actionnable ;
- health dashboard ;
- recherche globale ;
- playtest rapide ;
- rapports exportables ;
- UX runtime joueur enrichie ;
- documentation ;
- projet démo.

## 7. Milestones verticaux recalés

Ces milestones sont les vrais jalons de preuve.
Ils servent à éviter l'effet "beaucoup de lots terminés, peu de boucle réellement jouable".

### M1 — Pokédex auteur utilisable

Ce que ce milestone prouve :

- un auteur peut importer et maintenir des espèces à grande échelle sans bricoler.

Statut actuel :

- livré ;
- lots 1, 2, 3 et 4 livrés ;
- la base Pokédex auteur productif du cycle R1 est maintenant réellement
  atteinte.

Gate de sortie :

- mono-espèce avec auto-complétion ;
- batch sélectionnable ;
- dry-run batch ;
- exécution batch ;
- rapport lisible ;
- pas de parsing batch caché dans l'UI.

### M2 — Données combat authorables correctement

Ce que ce milestone prouve :

- les données qui alimentent le gameplay combatable peuvent être produites proprement dans l'éditeur.

Statut actuel :

- livré ;
- lot 5 livré :
  - learnsets profitent réellement du catalogue moves local ;
- lot 6 livré :
  - le socle de recherche catalogue locale est maintenant prêt pour être
    réutilisé ;
- lot 7 livré :
  - trainers authorables sans JSON manuel ;
  - édition de team assistée là où les données locales existent ;
- lot 8 livré :
  - encounter tables authorables sans texte libre fragile ;
  - validation inline lisible sur species / niveaux / poids ;
  - poids et parts relatives lisibles pour l'auteur ;
  - états dégradés honnêtes quand le Pokédex local est indisponible.

Gate de sortie :

- learnsets profitent réellement du catalogue moves local ;
- trainers authorables sans JSON manuel ;
- encounter tables authorables sans texte libre fragile ;
- erreurs de refs visibles immédiatement ;
- preview auteur minimale disponible là où utile.

### M3 — Handoff combat réel

Ce que ce milestone prouve :

- le runtime ne triche plus entre ses requests, les données projet et `BattleSetup`.

Gate de sortie :

- plus de placeholder métier dans le handoff ;
- vraie party joueur mappée ;
- vraies species wild mappées ;
- vraies teams trainers mappées ;
- tests runtime dédiés.

### M4 — Combat sauvage jouable

Ce que ce milestone prouve :

- la première vraie boucle Pokémon verticale existe.

Gate de sortie :

- déplacement ;
- rencontre sauvage ;
- handoff réel ;
- combat jouable ;
- retour overworld propre ;
- état runtime resynchronisé.

### M5 — Capture et persistance minimale

Ce que ce milestone prouve :

- la boucle de jeu commence à "tenir" comme jeu Pokémon, pas seulement comme démo de combat.

Gate de sortie :

- seen/caught persiste ;
- capture minimale fonctionne ;
- l'équipe ou un fallback minimal est mis à jour proprement ;
- save/load relit correctement ce nouvel état.

### M6 — Combat trainer minimal complet

Ce que ce milestone prouve :

- la seconde grande boucle du RPG Pokémon est présente.

Gate de sortie :

- trainer battle réel ;
- victoire/défaite mappées ;
- anti-retrigger ;
- reward minimal ;
- flags de progression cohérents.

### M7 — Boucle fangame minimale complète

Ce que ce milestone prouve :

- on a un mini fangame Pokémon jouable du début à une petite boucle de progression.

Gate de sortie :

- starter ou gift minimal ;
- wild battle ;
- capture ;
- trainer battle ;
- heal ;
- whiteout-lite ;
- save/load toujours cohérent.

### M8 — Combat crédible v2

Ce que ce milestone prouve :

- le système de combat devient défendable comme vrai combat Pokémon simplifié.

Gate de sortie :

- dégâts crédibles ;
- type chart ;
- précision ;
- PP ;
- switch ;
- statuts stage 1.

### M9 — Tooling auteur de production

Ce que ce milestone prouve :

- le repo est tenable pour une production plus longue sans dette explosive.

Gate de sortie :

- validation actionnable ;
- recherche projet ;
- bulk maintenance ;
- playtest rapide ;
- rapports exploitables.

## 8. Backlog prioritaire recalé

Cette section décrit les **15 lots prioritaires** du plan recalé et leur statut
courant.
Ils sont ordonnés pour maximiser la convergence produit, pas seulement la
pureté par domaine.

### Lot 1 — Résolveur de requête externe Pokédex

Priorité : `must-have`
Statut : `livré`

But :

- transformer une requête utilisateur en intention structurée :
  - mono-espèce ;
  - liste ;
  - plage dex ;
  - génération.

Pourquoi maintenant :

- c'est la base de toute l'UX Pokédex moderne.

Done :

- `bulbasaur`, `1-151`, `gen 1`, `pikachu,eevee,abra` sont reconnus correctement ;
- la sortie est structurée et réutilisable en UI ;
- aucun parsing batch métier dans les widgets.

Livré concrètement :

- modèles de résolution structurés dans `map_editor/application/models` ;
- résolveur pur dans `map_editor/application/services` ;
- provider DI dédié ;
- tests unitaires du résolveur ;
- report de lot déjà présent dans `reports/`.

### Lot 2 — Auto-complétion mono-espèce dans le wizard

Priorité : `must-have`
Statut : `livré`

But :

- remplacer la saisie libre fragile par une sélection assistée explicite.

Pourquoi maintenant :

- c'est le plus petit gain produit immédiatement visible.

Done :

- impossible de prévisualiser/importer sans espèce réellement résolue ;
- suggestions clavier/souris ;
- états loading / error / introuvable propres.

Livré concrètement :

- recherche mono-espèce branchée sur le résolveur du lot 1 ;
- sélection explicite obligatoire ;
- blocage de la preview/import sans suggestion choisie ;
- états UI hors-scope / invalide / aucun résultat ;
- tests UI et non-régression du flow mono-espèce ;
- report de lot déjà présent dans `reports/`.

### Lot 3 — Sélection batch + dry-run batch

Priorité : `must-have`
Statut : `livré`

But :

- exposer le batch de manière lisible avant écriture.

Pourquoi maintenant :

- le batch existe déjà côté métier ; il manque surtout le vrai flow auteur.

Done :

- liste finale ciblée visible ;
- doublons supprimés ;
- dry-run sans écriture ;
- preview stable et lisible même sur gros lot.

Livré concrètement :

- mode batch explicite dans le wizard `API externe` ;
- use case de résolution batch dédié ;
- support liste explicite / plage dex / génération ;
- affichage de la liste finale résolue avant preview ;
- blocage du dry-run si la sélection n'est pas propre ;
- dry-run branché sur le batch applicatif existant avec `dryRun: true` ;
- preview batch dédiée ;
- aucun import batch réel ;
- tests application, wiring, UI batch et non-régression mono ;
- report de lot déjà présent dans `reports/`.

Limites connues à garder visibles :

- la preview batch devient dense sur très gros lots ;
- le wizard reste encore raisonnablement maintenable, mais il faudra surveiller
  sa taille sur les lots suivants ;
- la preuve de non-écriture batch est forte, mais pas encore exhaustive
  artefact par artefact côté learnset/evolution/media/assets.

### Lot 4 — Exécution batch + progression + rapport

Priorité : `must-have`
Statut : `livré`

But :

- rendre le batch réellement productif.

Done :

- progression ;
- compteurs succès / conflit / skip / erreur ;
- rapport final clair.

Livré concrètement :

- bouton d'exécution batch réelle séparé du dry-run ;
- progression honnête branchée sur les callbacks du batch applicatif ;
- résultat final distinct de la preview dry-run ;
- compteurs visibles pendant et après exécution ;
- refresh du workspace si des écritures réelles ont eu lieu ;
- règle stable de sélection post-batch :
  - première espèce réellement écrite dans l'ordre de la sélection résolue ;
- tests application, wiring, UI et non-régression lot 2 / lot 3 ;
- report de lot présent dans `reports/`.

Non-objectifs explicitement conservés :

- pas de retry ;
- pas de relance partielle ;
- pas d'exécution en arrière-plan ;
- pas de cancellation avancée ;
- pas de refonte du wizard complet.

### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Priorité : `must-have`
Statut : `livré`

But :

- faire passer le learnset editor d'une simple garde minimale à une vraie saisie assistée moves-first.

Pourquoi maintenant :

- le socle moves catalog local existe déjà ;
- il faut maintenant l'utiliser davantage.

Done :

- recherche locale de moves dans le learnset editor ;
- sélection assistée ;
- validation plus lisible ;
- affichage honnête des ids legacy hors catalogue.

Livré concrètement :

- assistance locale branchée sur le catalogue `moves` déjà présent ;
- ajout assisté pour les sections de learnset existantes ;
- conservation explicite des ids legacy / inconnus ;
- amélioration de la lisibilité de validation sans créer un deuxième éditeur ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 6 — Service de recherche catalogue progressif

Priorité : `must-have`
Statut : `livré`

But :

- créer le contrat commun réutilisable pour les catalogues locaux.

Important :

- le service doit partir du moves catalog déjà présent ;
- il ne doit pas forcer d'emblée abilities/items/types si ces catalogues ne sont pas encore prêts à être productisés.

Done :

- recherche par id/libellé ;
- contrat stable ;
- réutilisable par Pokédex, trainers et encounters.

Livré concrètement :

- petit socle générique en mémoire pour la recherche catalogue locale ;
- convergence de `PokemonMovesCatalogLookupService` sur ce socle ;
- aucun second système concurrent de lookup `moves` ;
- réutilisation immédiate par le travail moves-first déjà livré ;
- tests dédiés et report de lot présents dans `reports/`.

### Lot 7 — Trainers : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de créer un trainer complet sans JSON.

Done :

- création/édition/suppression trainer ;
- édition propre de la team ;
- species/moves/items/forms assistés là où c'est disponible ;
- erreurs visibles immédiatement ;
- sauvegarde stable ;
- un auteur peut créer un trainer complet sans JSON.

Livré concrètement :

- surface `TrainerLibraryPanel` enrichie sans second éditeur ;
- refs assistées pour :
  - species ;
  - moves ;
  - items quand le catalogue local existe ;
  - forms via les données locales d'espèce ;
- champs bruts conservés honnêtement quand une aide locale n'existe pas encore
  ;
- validation inline lisible avant save ;
- use cases trainers étendus minimalement pour normaliser tags / moves / champs
  optionnels ;
- `EditorNotifier` mis à jour pour garder les formulaires ouverts seulement en
  cas d'échec et fermer proprement sur succès ;
- tests applicatifs, widget et wiring dédiés ;
- report de lot présent dans `reports/`.

### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Priorité : `must-have`
Statut : `livré`

But :

- permettre à un auteur de configurer une table wild valide sans texte libre fragile.

Done :

- add/edit/delete d'entrées ;
- species assistée ;
- validation niveau/poids ;
- lisibilité des probabilités ;
- preview auteur simple si le coût reste faible ;
- un auteur peut configurer une table wild valide sans texte libre fragile.

Livré concrètement :

- surface `EncounterTablesPanel` enrichie sans second éditeur ;
- recherche locale `species` par id / nom / numéro Pokédex via l'index local ;
- distinction explicite :
  - résolu localement ;
  - absent du Pokédex local ;
  - vérification impossible ;
- validation inline lisible avant save ;
- fermeture des formulaires uniquement sur succès réel ;
- poids totaux et pourcentages dérivés visibles dans la table ;
- tests applicatifs + widget + non-régressions dédiés ;
- report de lot présent dans `reports/`.

### Lot 9 — Mappers runtime réels vers `BattleSetup`

Priorité : `must-have`

But :

- supprimer les placeholders métier du handoff combat.

Done :

- player party -> `BattleSetup`
- wild encounter -> `BattleSetup`
- trainer team -> `BattleSetup`
- plus aucune espèce/move hardcodée dans le mapping final.

### Lot 10 — Application du résultat de combat au `GameState`

Priorité : `must-have`

But :

- resynchroniser réellement le runtime après combat.

Done :

- HP post-combat appliqués ;
- issues victory/defeat/runaway mappées ;
- trainer defeated flag cohérent ;
- retour overworld propre.

### Lot 11 — Combat sauvage end-to-end jouable

Priorité : `must-have`

But :

- obtenir la première vraie preuve verticale de boucle Pokémon.

Done :

- déplacement -> rencontre -> combat -> retour overworld ;
- plus aucun placeholder métier visible ;
- tests runtime de non-régression.

### Lot 12 — Seen / caught persistants

Priorité : `must-have`

But :

- préparer la boucle Pokémon persistée sans encore ouvrir un chantier capture trop gros d'un seul bloc.

Done :

- état seen/caught sérialisé ;
- save/load cohérent ;
- runtime capable d'en tirer parti.

### Lot 13 — Capture runtime minimale

Priorité : `must-have`

But :

- ajouter la capture comme premier vrai enrichissement de la boucle sauvage.

Done :

- consommation d'une ball ;
- résolution minimale de capture ;
- mise à jour seen/caught ;
- insertion contrôlée dans l'équipe ou fallback minimal.

### Lot 14 — Combat trainer minimal complet

Priorité : `must-have`

But :

- prouver la seconde grande boucle de jeu.

Done :

- trainer battle réel ;
- victoire/défaite stables ;
- anti-retrigger ;
- reward minimal ;
- flags cohérents.

### Lot 15 — Heal / center / whiteout-lite

Priorité : `must-have`

But :

- fermer la boucle de survie minimale du jeu.

Done :

- soin complet ;
- point de reprise minimal ;
- whiteout-lite ;
- save/load toujours cohérent.

## 9. Lots redécoupés / reformulés

Cette section capture explicitement les corrections de forme appliquées à la roadmap précédente.

### 9.1. Catalogues

Ancienne erreur :

- traiter d'un bloc moves + abilities + items + types + egg groups + growth rates.

Décision recalée :

- **moves d'abord** ;
- ensuite seulement les autres catalogues quand un écran ou un workflow les exige réellement.

### 9.2. Trainers

Ancienne erreur :

- "upgrade panel trainer" restait trop abstrait.

Nouvelle définition :

- **un auteur peut créer un trainer complet sans JSON**
- **la team est éditable proprement**
- **les refs invalides sont visibles immédiatement**

### 9.3. Encounter tables

Ancienne erreur :

- "upgrade encounter tables" restait trop vague.

Nouvelle définition :

- **un auteur peut configurer une table wild valide sans texte libre fragile**
- **les probabilités sont lisibles**
- **les erreurs sont visibles avant runtime**

### 9.4. Capture / seen-caught / save-load

Ancienne erreur :

- tout mélanger dans un seul lot trop gros.

Nouvelle décision :

- d'abord seen/caught persistants ;
- ensuite capture runtime minimale ;
- ensuite seulement les raffinements de party overflow, boxes complètes et UX avancée.

### 9.5. Combat depth

Ancienne erreur :

- compacter trop de profondeur battle dans une seule phase.

Nouvelle décision :

- prouver d'abord la boucle verticale avec un moteur encore simple ;
- approfondir ensuite en plusieurs étages clairement séparés.

## 10. Registre de risques mis à jour

### 10.1. Risques techniques

- `PlayableMapGame` peut continuer à grossir trop vite si l'on ne sort pas assez tôt les mappers et l'outcome applier.
- le contrat entre données locales Pokémon, battle setup et moteur combat peut rester incomplet.
- le moteur `map_battle` peut devenir le nouveau goulet si on lui demande trop tôt toute la profondeur système.

### 10.2. Risques de migration

- toute extension de `GameState` / `PlayerPokemon` a un coût réel de migration ;
- si on ouvre trop vite boxes + progression dex + capture + UI runtime complète, le risque de dette de save augmente fortement.

### 10.3. Risques d'UX auteur

- si les champs texte libres restent trop longtemps dans learnsets/trainers/encounters, la dette de données continuera à s'accumuler ;
- si le batch Pokédex devient trop complexe trop tôt, l'outil peut devenir impressionnant mais peu fiable.

### 10.4. Risques produit

- trop de polish auteur avant preuve de boucle de jeu ;
- faux sentiment de progrès si beaucoup d'UI avancent alors que le handoff runtime -> battle reste placeholder ;
- faux sentiment de profondeur si `map_battle` grossit avant d'avoir prouvé la boucle verticale minimale.

### 10.5. Stratégie de mitigation

- garder le bridge runtime très haut dans l'ordre ;
- imposer des gates de sortie par milestone ;
- découper les lots save/capture/combat plus finement ;
- ne productiser les autres catalogues qu'au moment opportun ;
- préférer des tranches verticales prouvées à des lots "impressionnants" mais partiellement intégrés.

## 11. Ordre réaliste recommandé à partir d'aujourd'hui

L'ordre recommandé est le suivant :

1. Lots 1 à 4
   - rendre le Pokédex auteur vraiment productif
2. Lots 5 à 8
   - supprimer la dette de référence là où elle gêne déjà concrètement
3. Lots 9 à 11
   - supprimer les placeholders runtime -> battle et prouver le combat sauvage réel
4. Lots 12 à 15
   - transformer cette première boucle en mini boucle Pokémon persistée
5. Battle depth par étapes
6. Boucle fangame élargie
7. Tooling riche / UX runtime / docs

## 12. Verdict final

La roadmap initiale était **bonne comme vision**.

La version recalée de ce document est meilleure pour trois raisons :

- elle tient compte de ce qui est déjà acquis dans le repo, notamment la clôture 11A et le socle moves catalog 11B ;
- elle reconnaît plus explicitement que les catalogues locaux et une partie de la validation croisée existent déjà ;
- elle remonte le bridge runtime -> battle à la bonne hauteur de priorité ;
- elle remplace une progression trop "par domaine" par une progression plus **verticale, prouvable et jouable**.

La bonne suite réaliste n'est donc pas :

- de réouvrir 11A ;
- de réinventer la stack Pokémon ;
- de lancer immédiatement toute la profondeur battle ;
- ou de multiplier les catalogues d'un coup.

La bonne suite réaliste est :

1. finaliser un **poste de travail Pokédex productif** ;
2. fiabiliser les **références assistées moves-first** ;
3. rendre **trainers et encounters** vraiment authorables ;
4. supprimer les **placeholders runtime -> battle** ;
5. obtenir une **boucle sauvage réelle** ;
6. ajouter **capture + persistance minimale** ;
7. puis seulement approfondir le combat, la progression, l'économie et le tooling.
````
