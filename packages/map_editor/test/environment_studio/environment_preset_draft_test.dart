import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';

void main() {
  group('EnvironmentGenerationParamsDraft', () {
    test('standard s’aligne sur EnvironmentGenerationParams.standard()', () {
      final d = EnvironmentGenerationParamsDraft.standard();
      final c = EnvironmentGenerationParams.standard();
      expect(d.density, c.density);
      expect(d.variation, c.variation);
      expect(d.edgeDensity, c.edgeDensity);
      expect(d.minSpacingCells, c.minSpacingCells);
    });

    test('copyWith modifie chaque champ', () {
      const base = EnvironmentGenerationParamsDraft(
        density: 0.1,
        variation: 0.2,
        edgeDensity: 0.3,
        minSpacingCells: 1,
      );
      expect(base.copyWith(density: 0.9).density, 0.9);
      expect(base.copyWith(variation: 0.8).variation, 0.8);
      expect(base.copyWith(edgeDensity: 0.7).edgeDensity, 0.7);
      expect(base.copyWith(minSpacingCells: 42).minSpacingCells, 42);
    });

    test('égalité de valeur', () {
      const a = EnvironmentGenerationParamsDraft(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      const b = EnvironmentGenerationParamsDraft(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentPaletteItemDraft', () {
    test('accepte elementId vide sans throw', () {
      expect(
        () => EnvironmentPaletteItemDraft(elementId: '', weight: 0),
        returnsNormally,
      );
    });

    test('accepte weight <= 0 sans throw', () {
      expect(
        () => EnvironmentPaletteItemDraft(elementId: 'a', weight: 0),
        returnsNormally,
      );
    });

    test('collisionMode par défaut', () {
      final d = EnvironmentPaletteItemDraft(elementId: 'x', weight: 1);
      expect(d.collisionMode, EnvironmentCollisionMode.useElementDefault);
    });

    test('copie défensive tags et exposés immuables', () {
      final raw = {'a', 'b'};
      final d = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: raw,
      );
      raw.add('c');
      expect(d.tags, {'a', 'b'});
      expect(() => (d.tags as dynamic).add('z'), throwsA(anything));
    });

    test('copyWith modifie les champs', () {
      final d = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'t'},
      );
      final n = d.copyWith(
        elementId: 'f',
        weight: 2,
        collisionMode: EnvironmentCollisionMode.forceDisabled,
        tags: {'u'},
      );
      expect(n.elementId, 'f');
      expect(n.weight, 2);
      expect(n.collisionMode, EnvironmentCollisionMode.forceDisabled);
      expect(n.tags, {'u'});
    });

    test('égalité indépendante de l’ordre des tags source', () {
      final a = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'z', 'a'},
      );
      final b = EnvironmentPaletteItemDraft(
        elementId: 'e',
        weight: 1,
        tags: {'a', 'z'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentPresetDraft', () {
    test('empty crée un brouillon formulaire', () {
      final d = EnvironmentPresetDraft.empty();
      expect(d.id, '');
      expect(d.name, '');
      expect(d.templateId, '');
      expect(d.palette, isEmpty);
      expect(d.categoryId, isNull);
      expect(d.sortOrder, 0);
      expect(
        d.defaultParams,
        EnvironmentGenerationParamsDraft.standard(),
      );
    });

    test('fromPreset conserve champs et convertit palette / params', () {
      final preset = EnvironmentPreset(
        id: 'p1',
        name: 'N',
        templateId: 'tpl',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'oak',
            weight: 2,
            collisionMode: EnvironmentCollisionMode.forceEnabled,
            tags: {'a', 'b'},
          ),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 0.2,
          variation: 0.3,
          edgeDensity: 0.4,
          minSpacingCells: 3,
        ),
        categoryId: 'cat',
        sortOrder: 7,
      );
      final d = EnvironmentPresetDraft.fromPreset(preset);
      expect(d.id, 'p1');
      expect(d.name, 'N');
      expect(d.templateId, 'tpl');
      expect(d.categoryId, 'cat');
      expect(d.sortOrder, 7);
      expect(d.palette.length, 1);
      expect(d.palette.single.elementId, 'oak');
      expect(d.palette.single.weight, 2);
      expect(d.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(d.palette.single.tags, {'a', 'b'});
      expect(d.defaultParams.density, 0.2);
      expect(d.defaultParams.minSpacingCells, 3);
    });

    test('palette copiée défensivement et immuable', () {
      final item = EnvironmentPaletteItemDraft(elementId: 'e', weight: 1);
      final list = [item];
      final d = EnvironmentPresetDraft(
        id: 'a',
        name: 'b',
        templateId: 'c',
        palette: list,
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
      );
      list.add(EnvironmentPaletteItemDraft(elementId: 'x', weight: 1));
      expect(d.palette.length, 1);
      expect(() => (d.palette as dynamic).add(item), throwsA(anything));
    });

    test('copyWith et clearCategoryId', () {
      final d = EnvironmentPresetDraft(
        id: 'i',
        name: 'n',
        templateId: 't',
        palette: [
          EnvironmentPaletteItemDraft(elementId: 'e', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
        categoryId: 'old',
      );
      final cleared = d.copyWith(clearCategoryId: true);
      expect(cleared.categoryId, isNull);
      final updated = d.copyWith(categoryId: 'new');
      expect(updated.categoryId, 'new');
    });

    test('égalité de valeur', () {
      final a = _validDraft();
      final b = _validDraft();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('validateEnvironmentPresetDraft', () {
    test('draft valide => aucune issue', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
      );
      expect(r.hasIssues, isFalse);
      expect(r.issueCount, 0);
    });

    test('emptyId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: '  '),
        manifest: _manifest(),
      );
      expect(
          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId), isNotEmpty);
    });

    test('duplicateId en création', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('duplicateId ignoré si existingPresetId identique', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: 'existing',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isEmpty,
      );
    });

    test('duplicateId en édition avec renommage vers id occupé', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: 'other',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('existingPresetId whitespace traité comme absent', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(id: 'existing'),
        manifest: _manifest(),
        existingPresetId: '   ',
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.duplicateId),
        isNotEmpty,
      );
    });

    test('emptyName', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(name: ''),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyName),
        isNotEmpty,
      );
    });

    test('emptyTemplateId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(templateId: '  '),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyTemplateId),
        isNotEmpty,
      );
    });

    test('unknownTemplateId warning si knownTemplateIds non vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
        knownTemplateIds: const {'other'},
      );
      final w =
          r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId);
      expect(w, isNotEmpty);
      expect(w.single.severity, EnvironmentPresetDraftIssueSeverity.warning);
    });

    test('unknownTemplateId absent si knownTemplateIds vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft(),
        manifest: _manifest(),
        knownTemplateIds: const {},
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.unknownTemplateId),
        isEmpty,
      );
    });

    test('emptyCategoryId si categoryId whitespace', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(categoryId: '  \t'),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyCategoryId),
        isNotEmpty,
      );
    });

    test('invalidDensity / variation / edgeDensity / minSpacingCells', () {
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: -0.01,
              variation: 0.5,
              edgeDensity: 0.5,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidDensity),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 2,
              edgeDensity: 0.5,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidVariation),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 0.5,
              edgeDensity: -1,
              minSpacingCells: 0,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidEdgeDensity),
        isNotEmpty,
      );
      expect(
        validateEnvironmentPresetDraft(
          _validDraft().copyWith(
            defaultParams: const EnvironmentGenerationParamsDraft(
              density: 0.5,
              variation: 0.5,
              edgeDensity: 0.5,
              minSpacingCells: -1,
            ),
          ),
          manifest: _manifest(),
        ).issuesForKind(EnvironmentPresetDraftIssueKind.invalidMinSpacingCells),
        isNotEmpty,
      );
    });

    test('emptyPalette', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(palette: []),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPalette),
        isNotEmpty,
      );
    });

    test('emptyPaletteElementId', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: '  ', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
        isNotEmpty,
      );
    });

    test('duplicatePaletteElementId sur le second item', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      final dup = r.issuesForKind(
        EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
      );
      expect(dup, isNotEmpty);
      expect(dup.single.paletteIndex, 1);
    });

    test('missingPaletteElement', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'ghost', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
        isNotEmpty,
      );
    });

    test('missingPaletteElement non produit si elementId vide', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: '', weight: 1),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.missingPaletteElement),
        isEmpty,
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteElementId),
        isNotEmpty,
      );
    });

    test('mixedPaletteTilesets bloque un brouillon qui mélange deux tilesets',
        () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'element_a', weight: 1),
            EnvironmentPaletteItemDraft(elementId: 'element_b', weight: 1),
          ],
        ),
        manifest: _manifest(
          elements: [
            _element(id: 'element_a', tilesetId: 'tileset_a'),
            _element(id: 'element_b', tilesetId: 'tileset_b'),
          ],
        ),
      );

      final issues =
          r.issuesForKind(EnvironmentPresetDraftIssueKind.mixedPaletteTilesets);
      expect(issues, hasLength(1));
      expect(issues.single.severity, EnvironmentPresetDraftIssueSeverity.error);
      expect(issues.single.elementId, 'element_b');
      expect(issues.single.message, contains('mélange plusieurs tilesets'));
    });

    test('invalidPaletteWeight', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
          ],
        ),
        manifest: _manifest(),
      );
      expect(
        r.issuesForKind(EnvironmentPresetDraftIssueKind.invalidPaletteWeight),
        isNotEmpty,
      );
    });

    test('emptyPaletteTag', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(
              elementId: 'oak',
              weight: 1,
              tags: {'ok', '  '},
            ),
          ],
        ),
        manifest: _manifest(),
      );
      final tags =
          r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyPaletteTag);
      expect(tags, isNotEmpty);
      expect(tags.single.paletteIndex, 0);
    });

    test('issuesForPaletteIndex et index négatif', () {
      final r = validateEnvironmentPresetDraft(
        _validDraft().copyWith(
          palette: [
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
            EnvironmentPaletteItemDraft(elementId: 'oak', weight: 0),
          ],
        ),
        manifest: _manifest(),
      );
      expect(r.issuesForPaletteIndex(0), isNotEmpty);
      expect(r.issuesForPaletteIndex(1), isNotEmpty);
      expect(r.issuesForPaletteIndex(-1), isEmpty);
    });

    test('ordre stable des kinds (extrait)', () {
      final r = validateEnvironmentPresetDraft(
        EnvironmentPresetDraft(
          id: '',
          name: '',
          templateId: '',
          palette: [],
          defaultParams: const EnvironmentGenerationParamsDraft(
            density: -1,
            variation: -1,
            edgeDensity: -1,
            minSpacingCells: -1,
          ),
          categoryId: '  ',
        ),
        manifest: _manifest(),
        knownTemplateIds: const {'x'},
      );
      final kinds = [for (final i in r.issues) i.kind];
      expect(kinds.first, EnvironmentPresetDraftIssueKind.emptyId);
      expect(kinds[1], EnvironmentPresetDraftIssueKind.emptyName);
      expect(kinds[2], EnvironmentPresetDraftIssueKind.emptyTemplateId);
      expect(kinds[3], EnvironmentPresetDraftIssueKind.emptyCategoryId);
      expect(kinds[4], EnvironmentPresetDraftIssueKind.invalidDensity);
      expect(kinds[5], EnvironmentPresetDraftIssueKind.invalidVariation);
      expect(kinds[6], EnvironmentPresetDraftIssueKind.invalidEdgeDensity);
      expect(kinds[7], EnvironmentPresetDraftIssueKind.invalidMinSpacingCells);
      expect(kinds[8], EnvironmentPresetDraftIssueKind.emptyPalette);
    });
  });

  group('buildEnvironmentPresetFromDraft', () {
    test('convertit un draft valide', () {
      final draft = _validDraft();
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'newPreset');
      expect(p.name, 'New');
      expect(p.templateId, 'forest_dense');
      expect(p.palette.single.elementId, 'oak');
    });

    test('trim id / name / templateId / categoryId / elementId / tags', () {
      final draft = EnvironmentPresetDraft(
        id: '  id1  ',
        name: '  N  ',
        templateId: '  tpl  ',
        palette: [
          EnvironmentPaletteItemDraft(
            elementId: '  oak  ',
            weight: 1,
            tags: {'  canopy  '},
          ),
        ],
        defaultParams: EnvironmentGenerationParamsDraft.standard(),
        categoryId: '  bio  ',
      );
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'id1');
      expect(p.name, 'N');
      expect(p.templateId, 'tpl');
      expect(p.categoryId, 'bio');
      expect(p.palette.single.elementId, 'oak');
      expect(p.palette.single.tags, {'canopy'});
    });

    test('lève si id vide après trim', () {
      expect(
        () => buildEnvironmentPresetFromDraft(
          _validDraft().copyWith(id: '   '),
        ),
        throwsArgumentError,
      );
    });

    test('lève si tag vide après trim', () {
      expect(
        () => buildEnvironmentPresetFromDraft(
          _validDraft().copyWith(
            palette: [
              EnvironmentPaletteItemDraft(
                elementId: 'oak',
                weight: 1,
                tags: {' '},
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('ne vérifie pas le manifest (duplicate accepté si map_core OK)', () {
      final draft = _validDraft().copyWith(id: 'existing');
      final p = buildEnvironmentPresetFromDraft(draft);
      expect(p.id, 'existing');
    });
  });

  group('EnvironmentPresetDraftValidationReport', () {
    test('issues défensives / immuables / compteurs / égalité', () {
      final raw = <EnvironmentPresetDraftIssue>[
        const EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.emptyId,
          message: 'm',
        ),
      ];
      final a = EnvironmentPresetDraftValidationReport(issues: raw);
      raw.add(
        const EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.warning,
          kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
          message: 'w',
        ),
      );
      expect(a.issueCount, 1);
      expect(() => a.issues.add(raw.first), throwsA(anything));

      final b = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'm',
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('hasErrors / hasWarnings', () {
      final onlyErr = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'e',
          ),
        ],
      );
      expect(onlyErr.hasErrors, isTrue);
      expect(onlyErr.hasWarnings, isFalse);
      final onlyWarn = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.warning,
            kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
            message: 'w',
          ),
        ],
      );
      expect(onlyWarn.hasErrors, isFalse);
      expect(onlyWarn.hasWarnings, isTrue);
    });

    test('issuesForKind retourne non modifiable', () {
      final r = EnvironmentPresetDraftValidationReport(
        issues: [
          const EnvironmentPresetDraftIssue(
            severity: EnvironmentPresetDraftIssueSeverity.error,
            kind: EnvironmentPresetDraftIssueKind.emptyId,
            message: 'm',
          ),
        ],
      );
      final list = r.issuesForKind(EnvironmentPresetDraftIssueKind.emptyId);
      expect(() => list.clear(), throwsA(anything));
    });
  });
}

// --- helpers ---

ProjectManifest _manifest({
  List<ProjectElementEntry>? elements,
}) {
  return ProjectManifest(
    name: 'draft-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: [
      EnvironmentPreset(
        id: 'existing',
        name: 'E',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
      EnvironmentPreset(
        id: 'other',
        name: 'O',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'oak', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 1,
      ),
    ],
    elements: elements ?? [_element(id: 'oak')],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({
  required String id,
  String tilesetId = 'ts',
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}

EnvironmentPresetDraft _validDraft() {
  return EnvironmentPresetDraft(
    id: 'newPreset',
    name: 'New',
    templateId: 'forest_dense',
    palette: [
      EnvironmentPaletteItemDraft(elementId: 'oak', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParamsDraft.standard(),
    sortOrder: 0,
  );
}
