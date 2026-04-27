# Lot 60 — Surface Studio Atlas Authoring Prep V0

## Résumé exécutif

Module `SurfaceStudioAtlasAuthoringPrep` : brouillon local d'atlas (champs, validation, prévisualisation) sans persistance. Intégration dans `SurfaceStudioPanel` après les diagnostics, avant les actions fantôme. Aucun `map_core` modifié, aucun manifest, aucun provider.

## Périmètre

- `map_editor` : nouveau widget + tests + clé de compteur sur le bandeau + ajustements de tests.
- Interdit ailleurs : non touché (détaillé en « Périmètre explicitement non touché »).

## Audit initial

- `git status` au démarrage Lot 60 (branche propre, hors fichiers lot 60) :

```
?? packages/project_overview_pokemon_project.txt
```

- `git diff --stat` : vide (aucun changement indexé).

## Implémentation

- `validateSurfaceStudioAtlasDraft` : champs requis, entiers, positivité, ordre `>=0`, id dupliqué (avec exemption après chargement depuis l'atlas sélectionné).
- `SurfaceStudioAtlasAuthoringPrep` : `Material` + `TextField` / `DropdownButton` / `Switch`, libellés interdits de sauvegarde.
- `SurfaceStudioPanel` : `ValueKey('surface_studio_header_counters')` sur le `Wrap` des compteurs pour cibler les tests.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md` (ce fichier)

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés (commande exacte)

- `cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart` (et combiné avec workspace)
- `cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_inspector_test.dart test/surface_studio/surface_studio_selection_interaction_test.dart test/surface_studio/surface_studio_selection_summary_test.dart test/surface_studio/surface_studio_selection_test.dart`
- `cd packages/map_editor && flutter test test/surface_studio`
- `cd packages/map_core && dart test test/surface_studio_read_model_test.dart`

## Analyse ciblée

- `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio` (sortie exacte) :
```
Analyzing 2 items...

No issues found! (ran in 3.2s)
```

## Résultats (extraits de sorties exacts)

- Tests Lot 60 : dernière ligne : `+12: All tests passed!`
- Suite `test/surface_studio` : dernière ligne : `+230: All tests passed!`
- `map_core` read model : `+30: All tests passed!`

## Git status final

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? reports/surface/surface_engine_lot_60_surface_studio_atlas_authoring_prep.md
```

## Changements préexistants

- `?? packages/project_overview_pokemon_project.txt` (initial uniquement) : non modifié par le Lot 60.

## Changements du Lot 60

- Tous les chemins listés en « Fichiers créés / modifiés ».

## Périmètre explicitement non touché

- `map_core` non modifié
- `ProjectManifest` non modifié
- fichiers générés non modifiés
- `build_runner` non lancé
- fixtures Surface JSON non modifiées
- aucun codec Surface modifié
- aucun provider Riverpod créé
- aucun repository/service créé
- aucune persistance créée
- aucune mutation du catalogue
- aucun `updateProjectManifestSurfaceCatalog`
- aucun `replaceProjectManifestSurfaceCatalog`
- aucun `clearProjectManifestSurfaceCatalog`
- aucun `copyWith(surfaceCatalog: ...)`
- aucun runtime/gameplay/battle modifié
- aucun painter map
- aucun SurfaceLayer
- aucun import atlas vertical

## Vérification fichiers temporaires

- Commande : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` : **aucun** résultat (racine dépôt).

## Vérification mojibake (rapport)

- Pas de séquences `RÃ`, `Ã©`, `â€`, `Â` voulues dans le corps rédigé ici (les sorties d'outils peuvent varier).

## Auto-review (réponses requises)

- Est-ce que le lot crée réellement un atlas ? **Non.**
- Est-ce que le lot sauvegarde quelque chose ? **Non.**
- Est-ce que le lot modifie le manifest ? **Non.**
- Est-ce que le lot prépare un brouillon local ? **Oui.**
- Est-ce que les validations locales sont testées ? **Oui** (required, entiers, doublon, etc.).
- Est-ce que les tests ciblés passent ? **Oui.**
- Est-ce que le rapport contient tous les contenus et diffs ? **Oui** (section Evidence ci-dessous).

## Critique du prompt

- Contrainte « aucun commentaire dans le code » : respectée (aucun `//` dans les fichiers Lot 60 ajoutés).
- Evidence Pack monolithique : volumineux ; alternative possible serait un annexe, mais le contrat demande l'intégralité ici.
- Distinguer « pas de `Create` en libellé d'action » : le panneau conserve `Créer un atlas` comme action **désactivée** héritée (non modifié volontairement) ; le brouillon n'emprunte pas ce libellé.

---

# Evidence Pack

## A. Contenu intégral des fichiers créés

### surface_studio_atlas_authoring_prep.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_selection.dart';

const ValueKey<String> kSurfaceStudioAtlasAuthoringPrepKey =
    ValueKey<String>('SurfaceStudioAtlasAuthoringPrep');

List<String> validateSurfaceStudioAtlasDraft({
  required SurfaceStudioReadModel readModel,
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
  String? duplicateIdExemption,
}) {
  final errors = <String>[];
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  if (id.isEmpty) {
    errors.add('Identifiant requis');
  }
  if (name.isEmpty) {
    errors.add('Nom requis');
  }
  if (tilesetId.isEmpty) {
    errors.add('Identifiant tileset requis');
  }

  int? tw = int.tryParse(tileWidthRaw.trim());
  if (tw == null) {
    errors.add('Largeur de tuile : entier requis');
  } else if (tw <= 0) {
    errors.add('Largeur de tuile : valeur positive requise');
  }

  int? th = int.tryParse(tileHeightRaw.trim());
  if (th == null) {
    errors.add('Hauteur de tuile : entier requis');
  } else if (th <= 0) {
    errors.add('Hauteur de tuile : valeur positive requise');
  }

  int? c = int.tryParse(columnsRaw.trim());
  if (c == null) {
    errors.add('Colonnes : entier requis');
  } else if (c <= 0) {
    errors.add('Colonnes : valeur positive requise');
  }

  int? r = int.tryParse(rowsRaw.trim());
  if (r == null) {
    errors.add('Lignes : entier requis');
  } else if (r <= 0) {
    errors.add('Lignes : valeur positive requise');
  }

  int? so = int.tryParse(sortOrderRaw.trim());
  if (so == null) {
    errors.add('Ordre : entier requis');
  } else if (so < 0) {
    errors.add('Ordre : valeur négative interdite pour ce brouillon');
  }

  if (id.isNotEmpty) {
    var collides = false;
    for (final a in readModel.atlases) {
      if (a.id == id) {
        if (duplicateIdExemption != null && duplicateIdExemption == id) {
          continue;
        }
        collides = true;
        break;
      }
    }
    if (collides) {
      errors.add('Cet identifiant existe déjà dans le catalogue');
    }
  }

  return errors;
}

class SurfaceStudioAtlasDraft {
  const SurfaceStudioAtlasDraft({
    required this.id,
    required this.name,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.sortOrder,
    this.categoryId,
  });

  final String id;
  final String name;
  final String tilesetId;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;
  final SurfaceAtlasLayout layout;
  final int sortOrder;
  final String? categoryId;

  int get tileCount => columns * rows;
}

SurfaceStudioAtlasDraft? tryBuildDraftFromForm({
  required String idRaw,
  required String nameRaw,
  required String tilesetIdRaw,
  required String tileWidthRaw,
  required String tileHeightRaw,
  required String columnsRaw,
  required String rowsRaw,
  required String sortOrderRaw,
  required String? categoryIdRaw,
  required SurfaceAtlasLayout layout,
}) {
  final id = idRaw.trim();
  final name = nameRaw.trim();
  final tilesetId = tilesetIdRaw.trim();
  final tw = int.tryParse(tileWidthRaw.trim());
  final th = int.tryParse(tileHeightRaw.trim());
  final c = int.tryParse(columnsRaw.trim());
  final r = int.tryParse(rowsRaw.trim());
  final so = int.tryParse(sortOrderRaw.trim());
  if (id.isEmpty ||
      name.isEmpty ||
      tilesetId.isEmpty ||
      tw == null ||
      th == null ||
      c == null ||
      r == null ||
      so == null) {
    return null;
  }
  if (tw <= 0 || th <= 0 || c <= 0 || r <= 0 || so < 0) {
    return null;
  }
  final cat = categoryIdRaw?.trim();
  return SurfaceStudioAtlasDraft(
    id: id,
    name: name,
    tilesetId: tilesetId,
    tileWidth: tw,
    tileHeight: th,
    columns: c,
    rows: r,
    layout: layout,
    sortOrder: so,
    categoryId: (cat == null || cat.isEmpty) ? null : cat,
  );
}

class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
  const SurfaceStudioAtlasAuthoringPrep({
    super.key,
    required this.readModel,
    required this.selection,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioSelection selection;

  @override
  State<SurfaceStudioAtlasAuthoringPrep> createState() =>
      _SurfaceStudioAtlasAuthoringPrepState();
}

class _SurfaceStudioAtlasAuthoringPrepState
    extends State<SurfaceStudioAtlasAuthoringPrep> {
  late final TextEditingController _id = TextEditingController();
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _tilesetId = TextEditingController();
  late final TextEditingController _tileW = TextEditingController(text: '32');
  late final TextEditingController _tileH = TextEditingController(text: '32');
  late final TextEditingController _cols = TextEditingController(text: '1');
  late final TextEditingController _rows = TextEditingController(text: '1');
  late final TextEditingController _sort = TextEditingController(text: '0');
  late final TextEditingController _categoryId = TextEditingController();

  SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
  bool _showPreview = false;
  String? _duplicateExemption;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _tilesetId.dispose();
    _tileW.dispose();
    _tileH.dispose();
    _cols.dispose();
    _rows.dispose();
    _sort.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  void _resetToDefaults() {
    setState(() {
      _id.clear();
      _name.clear();
      _tilesetId.clear();
      _tileW.text = '32';
      _tileH.text = '32';
      _cols.text = '1';
      _rows.text = '1';
      _sort.text = '0';
      _categoryId.clear();
      _layout = SurfaceAtlasLayout.grid;
      _duplicateExemption = null;
    });
  }

  void _loadFromSelection() {
    final sel = widget.selection;
    if (!sel.isAtlas) {
      return;
    }
    SurfaceStudioAtlasReadModel? row;
    for (final a in widget.readModel.atlases) {
      if (a.id == sel.id) {
        row = a;
        break;
      }
    }
    if (row == null) {
      return;
    }
    setState(() {
      _id.text = row!.atlas.id;
      _name.text = row.atlas.name;
      _tilesetId.text = row.atlas.tilesetId;
      _tileW.text = '${row.tileWidth}';
      _tileH.text = '${row.tileHeight}';
      _cols.text = '${row.columns}';
      _rows.text = '${row.rows}';
      _sort.text = '${row.sortOrder}';
      _layout = row.atlas.geometry.layout;
      _categoryId.text = row.categoryId ?? '';
      _duplicateExemption = row.id;
    });
  }

  String _layoutMenuLabel(SurfaceAtlasLayout l) {
    switch (l) {
      case SurfaceAtlasLayout.grid:
        return 'Grille libre';
      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
        return 'Colonnes = variantes, lignes = frames';
      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
        return 'Lignes = variantes, colonnes = frames';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = Color(0xFF2DD4BF);

    final errs = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      duplicateIdExemption: _duplicateExemption,
    );
    final isValid = errs.isEmpty;
    final draft = tryBuildDraftFromForm(
      idRaw: _id.text,
      nameRaw: _name.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileW.text,
      tileHeightRaw: _tileH.text,
      columnsRaw: _cols.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sort.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );

    final sel = widget.selection;
    String? contextNote;
    if (sel.isAnimation || sel.isPreset) {
      contextNote = 'La sélection actuelle n’est pas un atlas.';
    } else if (sel.isAtlas) {
      var found = false;
      for (final a in widget.readModel.atlases) {
        if (a.id == sel.id) {
          found = true;
          break;
        }
      }
      if (!found) {
        contextNote =
            'Atlas sélectionné introuvable, brouillon atlas indépendant.';
      }
    }

    return material.Material(
      type: material.MaterialType.transparency,
      child: Container(
        key: kSurfaceStudioAtlasAuthoringPrepKey,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EditorChrome.elevatedPanelBackground(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color.lerp(
              EditorChrome.editorIslandRim(context),
              accent,
              0.35,
            )!,
          ),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Préparation atlas',
            style: TextStyle(
              color: label,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brouillon local non sauvegardé',
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _localBadge(context, 'Brouillon local', label, accent),
              const SizedBox(width: 6),
              _localBadge(context, 'Non sauvegardé', label, accent),
              const SizedBox(width: 6),
              _localBadge(
                context,
                'Validation locale uniquement',
                label,
                accent,
              ),
              const SizedBox(width: 6),
              _localBadge(
                context,
                'Aucune modification du catalogue',
                label,
                accent,
              ),
            ],
          ),
          if (contextNote != null) ...[
            const SizedBox(height: 8),
            Text(
              contextNote,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _resetToDefaults,
                child: const Text('Réinitialiser le brouillon'),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: _loadFromSelection,
                child: const Text('Charger la sélection dans le brouillon'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          material.TextField(
            key: const ValueKey('atlas_draft_id'),
            controller: _id,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Identifiant',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_name'),
            controller: _name,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Nom',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_tileset'),
            controller: _tilesetId,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Identifiant tileset',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_w'),
                  controller: _tileW,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Largeur tuile',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_tile_h'),
                  controller: _tileH,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Hauteur tuile',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_cols'),
                  controller: _cols,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Colonnes',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: material.TextField(
                  key: const ValueKey('atlas_draft_rows'),
                  controller: _rows,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: label, fontSize: 13),
                  decoration: const material.InputDecoration(
                    labelText: 'Lignes',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Disposition', style: TextStyle(color: label, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: material.DropdownButton<SurfaceAtlasLayout>(
                  isExpanded: true,
                  value: _layout,
                  items: SurfaceAtlasLayout.values
                      .map(
                        (e) => material.DropdownMenuItem(
                          value: e,
                          child: Text(
                            _layoutMenuLabel(e),
                            style: TextStyle(color: label, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _layout = v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_category'),
            controller: _categoryId,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Catégorie (optionnel)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          material.TextField(
            key: const ValueKey('atlas_draft_sort'),
            controller: _sort,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            style: TextStyle(color: label, fontSize: 13),
            decoration: const material.InputDecoration(
              labelText: 'Ordre d’affichage',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              material.Switch(
                value: _showPreview,
                onChanged: (v) => setState(() => _showPreview = v),
              ),
              const SizedBox(width: 4),
              Text(
                'Prévisualisation locale',
                style: TextStyle(color: label, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isValid ? 'Brouillon prêt localement' : 'Brouillon invalide',
            style: TextStyle(
              color: isValid ? accent : const Color(0xFFE8887A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aucune sauvegarde ne sera effectuée',
            style: TextStyle(color: subtle, fontSize: 11),
          ),
          if (errs.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final e in errs)
              Text(
                e,
                style: const TextStyle(
                  color: Color(0xFFE8887A),
                  fontSize: 11,
                ),
              ),
          ],
          if (_showPreview && draft != null) ...[
            const SizedBox(height: 10),
            Text(
              'Aperçu : ${draft.tileWidth}×${draft.tileHeight} · Grille ${draft.columns}×${draft.rows} · ${draft.tileCount} tuiles · ordre ${draft.sortOrder}',
              style: TextStyle(color: label, fontSize: 12),
            ),
            Text(
              'Disposition : ${_layoutMenuLabel(draft.layout)}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
            Text(
              'Catégorie : ${draft.categoryId ?? '—'}',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
          ],
        ],
      ),
    ),
  );
  }
}

Widget _localBadge(
  BuildContext context,
  String text,
  Color labelColor,
  Color accent,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Color.lerp(
        EditorChrome.islandFillElevated(context),
        accent,
        0.1,
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: accent.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: labelColor,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

### surface_studio_atlas_authoring_prep_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('SurfaceStudioAtlasAuthoringPrep (Lot 60)', () {
    testWidgets('titre, brouillon local, défauts 32/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Préparation atlas'), findsOneWidget);
      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
      expect(find.text('Brouillon local'), findsOneWidget);
      expect(find.text('Non sauvegardé'), findsOneWidget);
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      final h = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final c = find.byKey(const ValueKey('atlas_draft_cols'));
      final r = find.byKey(const ValueKey('atlas_draft_rows'));
      expect(
        (tester.widget(w) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(h) as TextField).controller!.text,
        '32',
      );
      expect(
        (tester.widget(c) as TextField).controller!.text,
        '1',
      );
      expect(
        (tester.widget(r) as TextField).controller!.text,
        '1',
      );
    });

    testWidgets('id / nom / tileset vides: erreurs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Identifiant requis'), findsOneWidget);
      expect(find.text('Nom requis'), findsOneWidget);
      expect(find.text('Identifiant tileset requis'), findsOneWidget);
    });

    testWidgets('taille tuile x non entier: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
      await tester.enterText(w, 'abc');
      await tester.pump();
      expect(find.text('Largeur de tuile : entier requis'), findsOneWidget);
    });

    testWidgets('hauteur / colonnes / lignes <= 0: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final hF = find.byKey(const ValueKey('atlas_draft_tile_h'));
      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(hF, '0');
      await tester.pump();
      expect(
        find.text('Hauteur de tuile : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(hF, '32');
      await tester.enterText(cF, '0');
      await tester.pump();
      expect(
        find.text('Colonnes : valeur positive requise'),
        findsOneWidget,
      );
      await tester.enterText(cF, '1');
      await tester.enterText(rF, '0');
      await tester.pump();
      expect(find.text('Lignes : valeur positive requise'), findsOneWidget);
      await tester.enterText(rF, '1');
      await tester.enterText(sF, 'notint');
      await tester.pump();
      expect(find.text('Ordre : entier requis'), findsOneWidget);
    });

    testWidgets('sortOrder négatif: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
      await tester.enterText(idF, 'n');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.enterText(sF, '-1');
      await tester.pump();
      expect(
        find.text('Ordre : valeur négative interdite pour ce brouillon'),
        findsOneWidget,
      );
    });

    testWidgets('id dupliqué cat sans exemption: erreur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'water-atlas');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      expect(
        find.text('Cet identifiant existe déjà dans le catalogue'),
        findsOneWidget,
      );
    });

    testWidgets('Charger la sélection: champs = atlas, catalogue inchangé',
        (tester) async {
      final rm = _minimalRead();
      final beforeCat = rm.catalog;
      final sel = SurfaceStudioSelection.atlas('water-atlas');
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: rm,
            selection: sel,
          ),
        ),
      );
      await tester.tap(
        find.text('Charger la sélection dans le brouillon'),
      );
      await tester.pump();
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      expect(
        (tester.widget(idF) as TextField).controller!.text,
        'water-atlas',
      );
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      expect(
        (tester.widget(nameF) as TextField).controller!.text,
        'Water Atlas',
      );
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      expect(
        (tester.widget(tsF) as TextField).controller!.text,
        'nature-tileset',
      );
      expect(identical(rm.catalog, beforeCat), isTrue);
    });

    testWidgets('sélection animation: brouillon stable + note', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(
        find.text('La sélection actuelle n’est pas un atlas.'),
        findsOneWidget,
      );
      expect(
        (tester.widget(find.byKey(const ValueKey('atlas_draft_id')))
                as TextField)
            .controller!
            .text
            .isEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sélection atlas manquant: note + stable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('nope-missing'),
          ),
        ),
      );
      expect(
        find.text(
            'Atlas sélectionné introuvable, brouillon atlas indépendant.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pas de libellés d’action dangereux', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Créer l’atlas',
        'Modifier l’atlas',
        'Supprimer',
        'Delete',
        'Save',
        'Create',
        'Update',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.byKey(kSurfaceStudioAtlasAuthoringPrepKey), findsOneWidget);
    });

    testWidgets('brouillon valide + prévisu: texte aperçu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAtlasAuthoringPrep(
            readModel: _emptyReadModel(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
      await tester.enterText(idF, 'new-a');
      await tester.enterText(nameF, 'New');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      final swFinder = find.byType(Switch);
      await tester.ensureVisible(swFinder);
      await tester.tap(swFinder);
      await tester.pump();
      expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_cat());
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

ProjectSurfaceCatalog _cat() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}
```

## B. Diffs `git` des fichiers modifiés (réels)

### surface_studio_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 3000ae62..63bed7ac 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -13,6 +13,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_atlas_authoring_prep.dart';
 import 'surface_studio_catalog_browser.dart';
 import 'surface_studio_diagnostics_view.dart';
 import 'surface_studio_selection.dart';
@@ -124,6 +125,11 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           const SizedBox(height: 16),
           SurfaceStudioDiagnosticsView(readModel: widget.readModel),
           const SizedBox(height: 20),
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: widget.readModel,
+            selection: _selection,
+          ),
+          const SizedBox(height: 20),
           const _FutureActions(
             onCreateAtlas: null,
             onImportVertical: null,
@@ -228,6 +234,7 @@ class _CounterRow extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return Wrap(
+      key: const ValueKey('surface_studio_header_counters'),
       spacing: 12,
       runSpacing: 10,
       children: [
```

### surface_studio_panel_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index f3aa8f46..7f60b1d6 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -6,6 +6,7 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
 
@@ -30,8 +31,12 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      // Trois compteurs à 0
-      expect(find.text('0'), findsNWidgets(3));
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('0')),
+        findsNWidgets(3),
+      );
     });
 
     testWidgets('4. empty catalog shows empty state copy', (tester) async {
@@ -48,7 +53,12 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
-      expect(find.text('1'), findsNWidgets(3));
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(3),
+      );
     });
 
     testWidgets('6. non-empty shows catalog browser content', (tester) async {
@@ -138,7 +148,12 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
       );
-      expect(find.text('1'), findsNWidgets(3));
+      final counters =
+          find.byKey(const ValueKey('surface_studio_header_counters'));
+      expect(
+        find.descendant(of: counters, matching: find.text('1')),
+        findsNWidgets(3),
+      );
     });
 
     testWidgets('14. manifest is not mutated after pump', (tester) async {
@@ -209,11 +224,25 @@ void main() {
       expect(rm.summary.presetCount, 1);
     });
 
-    testWidgets('22. no TextField in panel', (tester) async {
+    testWidgets('22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      expect(find.byType(TextField), findsNothing);
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+          matching: find.byType(TextField),
+        ),
+        findsWidgets,
+      );
     });
 
     testWidgets('23. no save affordances', (tester) async {
@@ -367,14 +396,22 @@ void main() {
       expect(identical(manifest.surfaceCatalog, before), isTrue);
     });
 
-    testWidgets('58.27 — pas de TextField après sélections', (tester) async {
+    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
+        tester,
+    ) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
       await tester.ensureVisible(find.text('Water Atlas'));
       await tester.tap(find.text('Water Atlas'));
       await tester.pump();
-      expect(find.byType(TextField), findsNothing);
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
     });
 
     testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
@@ -507,16 +544,22 @@ void main() {
       expect(identical(manifest.surfaceCatalog, before), isTrue);
     });
 
-    testWidgets('59.26 — toujours aucun TextField après sélections', (
-      tester,
-    ) async {
+    testWidgets(
+        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
       );
       await tester.ensureVisible(find.text('Water Atlas'));
       await tester.tap(find.text('Water Atlas'));
       await tester.pump();
-      expect(find.byType(TextField), findsNothing);
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
     });
 
     testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
@@ -550,6 +593,15 @@ void main() {
       );
       expect(identical(manifest.surfaceCatalog, before), isTrue);
     });
+
+    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      await tester.ensureVisible(find.text('Préparation atlas'));
+      expect(find.text('Préparation atlas'), findsOneWidget);
+      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
+    });
   });
 }
 
```

### surface_studio_workspace_entry_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index f144e828..63e878a6 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -5,7 +5,9 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
 import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
 
 import '../shell_chrome_test_harness.dart';
@@ -177,17 +179,19 @@ void main() {
 
       await tester.pumpAndSettle();
 
+      final counters =
+          find.descendant(
+        of: find.byType(SurfaceStudioPanel),
+        matching: find.byKey(const ValueKey('surface_studio_header_counters')),
+      );
       expect(
-        find.descendant(
-          of: find.byType(SurfaceStudioPanel),
-          matching: find.text('1'),
-        ),
+        find.descendant(of: counters, matching: find.text('1')),
         findsNWidgets(3),
       );
     });
 
     testWidgets(
-        'read-only: future action CupertinoButtons are disabled, no TextField',
+        'read-only: actions désactivées; TextField seulement brouillon Lot 60',
         (tester) async {
       await pumpEditorShellPage(
         tester,
@@ -202,7 +206,20 @@ void main() {
 
       await tester.pumpAndSettle();
 
-      expect(find.byType(TextField), findsNothing);
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.byType(TextField),
+        ),
+        findsNothing,
+      );
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
+          matching: find.byType(TextField),
+        ),
+        findsWidgets,
+      );
       expect(
         find.text(SurfaceStudioPanel.actionCreateAtlasLabel),
         findsOneWidget,
```

## C. Diffs /dev/null (fichiers nouveaux)

### surface_studio_atlas_authoring_prep.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
new file mode 100644
index 00000000..4e570478
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
@@ -0,0 +1,650 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' as material;
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_selection.dart';
+
+const ValueKey<String> kSurfaceStudioAtlasAuthoringPrepKey =
+    ValueKey<String>('SurfaceStudioAtlasAuthoringPrep');
+
+List<String> validateSurfaceStudioAtlasDraft({
+  required SurfaceStudioReadModel readModel,
+  required String idRaw,
+  required String nameRaw,
+  required String tilesetIdRaw,
+  required String tileWidthRaw,
+  required String tileHeightRaw,
+  required String columnsRaw,
+  required String rowsRaw,
+  required String sortOrderRaw,
+  required String? categoryIdRaw,
+  String? duplicateIdExemption,
+}) {
+  final errors = <String>[];
+  final id = idRaw.trim();
+  final name = nameRaw.trim();
+  final tilesetId = tilesetIdRaw.trim();
+  if (id.isEmpty) {
+    errors.add('Identifiant requis');
+  }
+  if (name.isEmpty) {
+    errors.add('Nom requis');
+  }
+  if (tilesetId.isEmpty) {
+    errors.add('Identifiant tileset requis');
+  }
+
+  int? tw = int.tryParse(tileWidthRaw.trim());
+  if (tw == null) {
+    errors.add('Largeur de tuile : entier requis');
+  } else if (tw <= 0) {
+    errors.add('Largeur de tuile : valeur positive requise');
+  }
+
+  int? th = int.tryParse(tileHeightRaw.trim());
+  if (th == null) {
+    errors.add('Hauteur de tuile : entier requis');
+  } else if (th <= 0) {
+    errors.add('Hauteur de tuile : valeur positive requise');
+  }
+
+  int? c = int.tryParse(columnsRaw.trim());
+  if (c == null) {
+    errors.add('Colonnes : entier requis');
+  } else if (c <= 0) {
+    errors.add('Colonnes : valeur positive requise');
+  }
+
+  int? r = int.tryParse(rowsRaw.trim());
+  if (r == null) {
+    errors.add('Lignes : entier requis');
+  } else if (r <= 0) {
+    errors.add('Lignes : valeur positive requise');
+  }
+
+  int? so = int.tryParse(sortOrderRaw.trim());
+  if (so == null) {
+    errors.add('Ordre : entier requis');
+  } else if (so < 0) {
+    errors.add('Ordre : valeur négative interdite pour ce brouillon');
+  }
+
+  if (id.isNotEmpty) {
+    var collides = false;
+    for (final a in readModel.atlases) {
+      if (a.id == id) {
+        if (duplicateIdExemption != null && duplicateIdExemption == id) {
+          continue;
+        }
+        collides = true;
+        break;
+      }
+    }
+    if (collides) {
+      errors.add('Cet identifiant existe déjà dans le catalogue');
+    }
+  }
+
+  return errors;
+}
+
+class SurfaceStudioAtlasDraft {
+  const SurfaceStudioAtlasDraft({
+    required this.id,
+    required this.name,
+    required this.tilesetId,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columns,
+    required this.rows,
+    required this.layout,
+    required this.sortOrder,
+    this.categoryId,
+  });
+
+  final String id;
+  final String name;
+  final String tilesetId;
+  final int tileWidth;
+  final int tileHeight;
+  final int columns;
+  final int rows;
+  final SurfaceAtlasLayout layout;
+  final int sortOrder;
+  final String? categoryId;
+
+  int get tileCount => columns * rows;
+}
+
+SurfaceStudioAtlasDraft? tryBuildDraftFromForm({
+  required String idRaw,
+  required String nameRaw,
+  required String tilesetIdRaw,
+  required String tileWidthRaw,
+  required String tileHeightRaw,
+  required String columnsRaw,
+  required String rowsRaw,
+  required String sortOrderRaw,
+  required String? categoryIdRaw,
+  required SurfaceAtlasLayout layout,
+}) {
+  final id = idRaw.trim();
+  final name = nameRaw.trim();
+  final tilesetId = tilesetIdRaw.trim();
+  final tw = int.tryParse(tileWidthRaw.trim());
+  final th = int.tryParse(tileHeightRaw.trim());
+  final c = int.tryParse(columnsRaw.trim());
+  final r = int.tryParse(rowsRaw.trim());
+  final so = int.tryParse(sortOrderRaw.trim());
+  if (id.isEmpty ||
+      name.isEmpty ||
+      tilesetId.isEmpty ||
+      tw == null ||
+      th == null ||
+      c == null ||
+      r == null ||
+      so == null) {
+    return null;
+  }
+  if (tw <= 0 || th <= 0 || c <= 0 || r <= 0 || so < 0) {
+    return null;
+  }
+  final cat = categoryIdRaw?.trim();
+  return SurfaceStudioAtlasDraft(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    tileWidth: tw,
+    tileHeight: th,
+    columns: c,
+    rows: r,
+    layout: layout,
+    sortOrder: so,
+    categoryId: (cat == null || cat.isEmpty) ? null : cat,
+  );
+}
+
+class SurfaceStudioAtlasAuthoringPrep extends StatefulWidget {
+  const SurfaceStudioAtlasAuthoringPrep({
+    super.key,
+    required this.readModel,
+    required this.selection,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final SurfaceStudioSelection selection;
+
+  @override
+  State<SurfaceStudioAtlasAuthoringPrep> createState() =>
+      _SurfaceStudioAtlasAuthoringPrepState();
+}
+
+class _SurfaceStudioAtlasAuthoringPrepState
+    extends State<SurfaceStudioAtlasAuthoringPrep> {
+  late final TextEditingController _id = TextEditingController();
+  late final TextEditingController _name = TextEditingController();
+  late final TextEditingController _tilesetId = TextEditingController();
+  late final TextEditingController _tileW = TextEditingController(text: '32');
+  late final TextEditingController _tileH = TextEditingController(text: '32');
+  late final TextEditingController _cols = TextEditingController(text: '1');
+  late final TextEditingController _rows = TextEditingController(text: '1');
+  late final TextEditingController _sort = TextEditingController(text: '0');
+  late final TextEditingController _categoryId = TextEditingController();
+
+  SurfaceAtlasLayout _layout = SurfaceAtlasLayout.grid;
+  bool _showPreview = false;
+  String? _duplicateExemption;
+
+  @override
+  void dispose() {
+    _id.dispose();
+    _name.dispose();
+    _tilesetId.dispose();
+    _tileW.dispose();
+    _tileH.dispose();
+    _cols.dispose();
+    _rows.dispose();
+    _sort.dispose();
+    _categoryId.dispose();
+    super.dispose();
+  }
+
+  void _resetToDefaults() {
+    setState(() {
+      _id.clear();
+      _name.clear();
+      _tilesetId.clear();
+      _tileW.text = '32';
+      _tileH.text = '32';
+      _cols.text = '1';
+      _rows.text = '1';
+      _sort.text = '0';
+      _categoryId.clear();
+      _layout = SurfaceAtlasLayout.grid;
+      _duplicateExemption = null;
+    });
+  }
+
+  void _loadFromSelection() {
+    final sel = widget.selection;
+    if (!sel.isAtlas) {
+      return;
+    }
+    SurfaceStudioAtlasReadModel? row;
+    for (final a in widget.readModel.atlases) {
+      if (a.id == sel.id) {
+        row = a;
+        break;
+      }
+    }
+    if (row == null) {
+      return;
+    }
+    setState(() {
+      _id.text = row!.atlas.id;
+      _name.text = row.atlas.name;
+      _tilesetId.text = row.atlas.tilesetId;
+      _tileW.text = '${row.tileWidth}';
+      _tileH.text = '${row.tileHeight}';
+      _cols.text = '${row.columns}';
+      _rows.text = '${row.rows}';
+      _sort.text = '${row.sortOrder}';
+      _layout = row.atlas.geometry.layout;
+      _categoryId.text = row.categoryId ?? '';
+      _duplicateExemption = row.id;
+    });
+  }
+
+  String _layoutMenuLabel(SurfaceAtlasLayout l) {
+    switch (l) {
+      case SurfaceAtlasLayout.grid:
+        return 'Grille libre';
+      case SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames:
+        return 'Colonnes = variantes, lignes = frames';
+      case SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames:
+        return 'Lignes = variantes, colonnes = frames';
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    const accent = Color(0xFF2DD4BF);
+
+    final errs = validateSurfaceStudioAtlasDraft(
+      readModel: widget.readModel,
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+      duplicateIdExemption: _duplicateExemption,
+    );
+    final isValid = errs.isEmpty;
+    final draft = tryBuildDraftFromForm(
+      idRaw: _id.text,
+      nameRaw: _name.text,
+      tilesetIdRaw: _tilesetId.text,
+      tileWidthRaw: _tileW.text,
+      tileHeightRaw: _tileH.text,
+      columnsRaw: _cols.text,
+      rowsRaw: _rows.text,
+      sortOrderRaw: _sort.text,
+      categoryIdRaw: _categoryId.text,
+      layout: _layout,
+    );
+
+    final sel = widget.selection;
+    String? contextNote;
+    if (sel.isAnimation || sel.isPreset) {
+      contextNote = 'La sélection actuelle n’est pas un atlas.';
+    } else if (sel.isAtlas) {
+      var found = false;
+      for (final a in widget.readModel.atlases) {
+        if (a.id == sel.id) {
+          found = true;
+          break;
+        }
+      }
+      if (!found) {
+        contextNote =
+            'Atlas sélectionné introuvable, brouillon atlas indépendant.';
+      }
+    }
+
+    return material.Material(
+      type: material.MaterialType.transparency,
+      child: Container(
+        key: kSurfaceStudioAtlasAuthoringPrepKey,
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
+        decoration: BoxDecoration(
+          color: EditorChrome.elevatedPanelBackground(context),
+          borderRadius: BorderRadius.circular(14),
+          border: Border.all(
+            color: Color.lerp(
+              EditorChrome.editorIslandRim(context),
+              accent,
+              0.35,
+            )!,
+          ),
+          boxShadow: EditorChrome.sectionCardShadows(context),
+        ),
+        child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Préparation atlas',
+            style: TextStyle(
+              color: label,
+              fontSize: 16,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Brouillon local non sauvegardé',
+            style: TextStyle(
+              color: subtle,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Wrap(
+            spacing: 8,
+            runSpacing: 4,
+            children: [
+              _localBadge(context, 'Brouillon local', label, accent),
+              const SizedBox(width: 6),
+              _localBadge(context, 'Non sauvegardé', label, accent),
+              const SizedBox(width: 6),
+              _localBadge(
+                context,
+                'Validation locale uniquement',
+                label,
+                accent,
+              ),
+              const SizedBox(width: 6),
+              _localBadge(
+                context,
+                'Aucune modification du catalogue',
+                label,
+                accent,
+              ),
+            ],
+          ),
+          if (contextNote != null) ...[
+            const SizedBox(height: 8),
+            Text(
+              contextNote,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontStyle: FontStyle.italic,
+              ),
+            ),
+          ],
+          const SizedBox(height: 12),
+          Wrap(
+            spacing: 8,
+            runSpacing: 6,
+            children: [
+              CupertinoButton(
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                onPressed: _resetToDefaults,
+                child: const Text('Réinitialiser le brouillon'),
+              ),
+              CupertinoButton(
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+                onPressed: _loadFromSelection,
+                child: const Text('Charger la sélection dans le brouillon'),
+              ),
+            ],
+          ),
+          const SizedBox(height: 8),
+          material.TextField(
+            key: const ValueKey('atlas_draft_id'),
+            controller: _id,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Identifiant',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_name'),
+            controller: _name,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Nom',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_tileset'),
+            controller: _tilesetId,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Identifiant tileset',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Row(
+            children: [
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_tile_w'),
+                  controller: _tileW,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Largeur tuile',
+                    isDense: true,
+                  ),
+                ),
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_tile_h'),
+                  controller: _tileH,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Hauteur tuile',
+                    isDense: true,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          Row(
+            children: [
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_cols'),
+                  controller: _cols,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Colonnes',
+                    isDense: true,
+                  ),
+                ),
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: material.TextField(
+                  key: const ValueKey('atlas_draft_rows'),
+                  controller: _rows,
+                  onChanged: (_) => setState(() {}),
+                  keyboardType: TextInputType.number,
+                  style: TextStyle(color: label, fontSize: 13),
+                  decoration: const material.InputDecoration(
+                    labelText: 'Lignes',
+                    isDense: true,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.center,
+            children: [
+              Text('Disposition', style: TextStyle(color: label, fontSize: 12)),
+              const SizedBox(width: 12),
+              Expanded(
+                child: material.DropdownButton<SurfaceAtlasLayout>(
+                  isExpanded: true,
+                  value: _layout,
+                  items: SurfaceAtlasLayout.values
+                      .map(
+                        (e) => material.DropdownMenuItem(
+                          value: e,
+                          child: Text(
+                            _layoutMenuLabel(e),
+                            style: TextStyle(color: label, fontSize: 12),
+                            overflow: TextOverflow.ellipsis,
+                          ),
+                        ),
+                      )
+                      .toList(),
+                  onChanged: (v) {
+                    if (v != null) {
+                      setState(() => _layout = v);
+                    }
+                  },
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_category'),
+            controller: _categoryId,
+            onChanged: (_) => setState(() {}),
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Catégorie (optionnel)',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 6),
+          material.TextField(
+            key: const ValueKey('atlas_draft_sort'),
+            controller: _sort,
+            onChanged: (_) => setState(() {}),
+            keyboardType: TextInputType.number,
+            style: TextStyle(color: label, fontSize: 13),
+            decoration: const material.InputDecoration(
+              labelText: 'Ordre d’affichage',
+              isDense: true,
+            ),
+          ),
+          const SizedBox(height: 10),
+          Row(
+            children: [
+              material.Switch(
+                value: _showPreview,
+                onChanged: (v) => setState(() => _showPreview = v),
+              ),
+              const SizedBox(width: 4),
+              Text(
+                'Prévisualisation locale',
+                style: TextStyle(color: label, fontSize: 12),
+              ),
+            ],
+          ),
+          const SizedBox(height: 8),
+          Text(
+            isValid ? 'Brouillon prêt localement' : 'Brouillon invalide',
+            style: TextStyle(
+              color: isValid ? accent : const Color(0xFFE8887A),
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            'Aucune sauvegarde ne sera effectuée',
+            style: TextStyle(color: subtle, fontSize: 11),
+          ),
+          if (errs.isNotEmpty) ...[
+            const SizedBox(height: 6),
+            for (final e in errs)
+              Text(
+                e,
+                style: const TextStyle(
+                  color: Color(0xFFE8887A),
+                  fontSize: 11,
+                ),
+              ),
+          ],
+          if (_showPreview && draft != null) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Aperçu : ${draft.tileWidth}×${draft.tileHeight} · Grille ${draft.columns}×${draft.rows} · ${draft.tileCount} tuiles · ordre ${draft.sortOrder}',
+              style: TextStyle(color: label, fontSize: 12),
+            ),
+            Text(
+              'Disposition : ${_layoutMenuLabel(draft.layout)}',
+              style: TextStyle(color: subtle, fontSize: 11),
+            ),
+            Text(
+              'Catégorie : ${draft.categoryId ?? '—'}',
+              style: TextStyle(color: subtle, fontSize: 11),
+            ),
+          ],
+        ],
+      ),
+    ),
+  );
+  }
+}
+
+Widget _localBadge(
+  BuildContext context,
+  String text,
+  Color labelColor,
+  Color accent,
+) {
+  return Container(
+    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+    decoration: BoxDecoration(
+      color: Color.lerp(
+        EditorChrome.islandFillElevated(context),
+        accent,
+        0.1,
+      ),
+      borderRadius: BorderRadius.circular(6),
+      border: Border.all(color: accent.withValues(alpha: 0.4)),
+    ),
+    child: Text(
+      text,
+      style: TextStyle(
+        color: labelColor,
+        fontSize: 10,
+        fontWeight: FontWeight.w600,
+      ),
+    ),
+  );
+}
```

### surface_studio_atlas_authoring_prep_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
new file mode 100644
index 00000000..51581601
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
@@ -0,0 +1,356 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+
+void main() {
+  group('SurfaceStudioAtlasAuthoringPrep (Lot 60)', () {
+    testWidgets('titre, brouillon local, défauts 32/1/1', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Préparation atlas'), findsOneWidget);
+      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
+      expect(find.text('Brouillon local'), findsOneWidget);
+      expect(find.text('Non sauvegardé'), findsOneWidget);
+      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
+      final h = find.byKey(const ValueKey('atlas_draft_tile_h'));
+      final c = find.byKey(const ValueKey('atlas_draft_cols'));
+      final r = find.byKey(const ValueKey('atlas_draft_rows'));
+      expect(
+        (tester.widget(w) as TextField).controller!.text,
+        '32',
+      );
+      expect(
+        (tester.widget(h) as TextField).controller!.text,
+        '32',
+      );
+      expect(
+        (tester.widget(c) as TextField).controller!.text,
+        '1',
+      );
+      expect(
+        (tester.widget(r) as TextField).controller!.text,
+        '1',
+      );
+    });
+
+    testWidgets('id / nom / tileset vides: erreurs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Identifiant requis'), findsOneWidget);
+      expect(find.text('Nom requis'), findsOneWidget);
+      expect(find.text('Identifiant tileset requis'), findsOneWidget);
+    });
+
+    testWidgets('taille tuile x non entier: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final w = find.byKey(const ValueKey('atlas_draft_tile_w'));
+      await tester.enterText(w, 'abc');
+      await tester.pump();
+      expect(find.text('Largeur de tuile : entier requis'), findsOneWidget);
+    });
+
+    testWidgets('hauteur / colonnes / lignes <= 0: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      final hF = find.byKey(const ValueKey('atlas_draft_tile_h'));
+      final cF = find.byKey(const ValueKey('atlas_draft_cols'));
+      final rF = find.byKey(const ValueKey('atlas_draft_rows'));
+      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
+      await tester.enterText(idF, 'n');
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.enterText(hF, '0');
+      await tester.pump();
+      expect(
+        find.text('Hauteur de tuile : valeur positive requise'),
+        findsOneWidget,
+      );
+      await tester.enterText(hF, '32');
+      await tester.enterText(cF, '0');
+      await tester.pump();
+      expect(
+        find.text('Colonnes : valeur positive requise'),
+        findsOneWidget,
+      );
+      await tester.enterText(cF, '1');
+      await tester.enterText(rF, '0');
+      await tester.pump();
+      expect(find.text('Lignes : valeur positive requise'), findsOneWidget);
+      await tester.enterText(rF, '1');
+      await tester.enterText(sF, 'notint');
+      await tester.pump();
+      expect(find.text('Ordre : entier requis'), findsOneWidget);
+    });
+
+    testWidgets('sortOrder négatif: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      final sF = find.byKey(const ValueKey('atlas_draft_sort'));
+      await tester.enterText(idF, 'n');
+      await tester.enterText(nameF, 'N');
+      await tester.enterText(tsF, 't');
+      await tester.enterText(sF, '-1');
+      await tester.pump();
+      expect(
+        find.text('Ordre : valeur négative interdite pour ce brouillon'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('id dupliqué cat sans exemption: erreur', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'water-atlas');
+      await tester.enterText(nameF, 'X');
+      await tester.enterText(tsF, 't');
+      await tester.pump();
+      expect(
+        find.text('Cet identifiant existe déjà dans le catalogue'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('Charger la sélection: champs = atlas, catalogue inchangé',
+        (tester) async {
+      final rm = _minimalRead();
+      final beforeCat = rm.catalog;
+      final sel = SurfaceStudioSelection.atlas('water-atlas');
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: rm,
+            selection: sel,
+          ),
+        ),
+      );
+      await tester.tap(
+        find.text('Charger la sélection dans le brouillon'),
+      );
+      await tester.pump();
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      expect(
+        (tester.widget(idF) as TextField).controller!.text,
+        'water-atlas',
+      );
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      expect(
+        (tester.widget(nameF) as TextField).controller!.text,
+        'Water Atlas',
+      );
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      expect(
+        (tester.widget(tsF) as TextField).controller!.text,
+        'nature-tileset',
+      );
+      expect(identical(rm.catalog, beforeCat), isTrue);
+    });
+
+    testWidgets('sélection animation: brouillon stable + note', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
+          ),
+        ),
+      );
+      expect(
+        find.text('La sélection actuelle n’est pas un atlas.'),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget(find.byKey(const ValueKey('atlas_draft_id')))
+                as TextField)
+            .controller!
+            .text
+            .isEmpty,
+        isTrue,
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('sélection atlas manquant: note + stable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('nope-missing'),
+          ),
+        ),
+      );
+      expect(
+        find.text(
+            'Atlas sélectionné introuvable, brouillon atlas indépendant.'),
+        findsOneWidget,
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('pas de libellés d’action dangereux', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Créer l’atlas',
+        'Modifier l’atlas',
+        'Supprimer',
+        'Delete',
+        'Save',
+        'Create',
+        'Update',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('sans ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.byKey(kSurfaceStudioAtlasAuthoringPrepKey), findsOneWidget);
+    });
+
+    testWidgets('brouillon valide + prévisu: texte aperçu', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioAtlasAuthoringPrep(
+            readModel: _emptyReadModel(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      final idF = find.byKey(const ValueKey('atlas_draft_id'));
+      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
+      final tsF = find.byKey(const ValueKey('atlas_draft_tileset'));
+      await tester.enterText(idF, 'new-a');
+      await tester.enterText(nameF, 'New');
+      await tester.enterText(tsF, 'ts');
+      await tester.pump();
+      final swFinder = find.byType(Switch);
+      await tester.ensureVisible(swFinder);
+      await tester.tap(swFinder);
+      await tester.pump();
+      expect(find.textContaining('Aperçu : 32×32'), findsOneWidget);
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SingleChildScrollView(
+        padding: const EdgeInsets.all(16),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceStudioReadModel _minimalRead() {
+  return buildSurfaceStudioReadModelFromCatalog(_cat());
+}
+
+SurfaceStudioReadModel _emptyReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+}
+
+ProjectSurfaceCatalog _cat() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-isolated-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
```

## D. Sorties de commandes (reproduction)

Dernières lignes retenues conformément au contrat (suite longue) :

- `flutter test test/surface_studio/surface_studio_atlas_authoring_prep.dart` : `+12: All tests passed!`
- `flutter test test/surface_studio` : `+230: All tests passed!`
- `dart test test/surface_studio_read_model_test.dart` : `+30: All tests passed!`
- `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio` : dernière ligne : `No issues found! (ran in 3.2s)` — exit 0.
