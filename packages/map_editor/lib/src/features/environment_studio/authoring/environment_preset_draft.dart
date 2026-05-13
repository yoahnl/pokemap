import 'package:map_core/map_core.dart';

import 'environment_preset_tileset_compatibility.dart';

// ---------------------------------------------------------------------------
// Generation params draft
// ---------------------------------------------------------------------------

/// Brouillon des paramètres de génération : valeurs hors bornes autorisées
/// jusqu’à [validateEnvironmentPresetDraft].
final class EnvironmentGenerationParamsDraft {
  const EnvironmentGenerationParamsDraft({
    required this.density,
    required this.variation,
    required this.edgeDensity,
    required this.minSpacingCells,
  });

  /// Aligné sur [EnvironmentGenerationParams.standard] (map_core).
  factory EnvironmentGenerationParamsDraft.standard() {
    final s = EnvironmentGenerationParams.standard();
    return EnvironmentGenerationParamsDraft(
      density: s.density,
      variation: s.variation,
      edgeDensity: s.edgeDensity,
      minSpacingCells: s.minSpacingCells,
    );
  }

  final double density;
  final double variation;
  final double edgeDensity;
  final int minSpacingCells;

  EnvironmentGenerationParamsDraft copyWith({
    double? density,
    double? variation,
    double? edgeDensity,
    int? minSpacingCells,
  }) {
    return EnvironmentGenerationParamsDraft(
      density: density ?? this.density,
      variation: variation ?? this.variation,
      edgeDensity: edgeDensity ?? this.edgeDensity,
      minSpacingCells: minSpacingCells ?? this.minSpacingCells,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentGenerationParamsDraft &&
            density == other.density &&
            variation == other.variation &&
            edgeDensity == other.edgeDensity &&
            minSpacingCells == other.minSpacingCells;
  }

  @override
  int get hashCode =>
      Object.hash(density, variation, edgeDensity, minSpacingCells);
}

// ---------------------------------------------------------------------------
// Palette item draft
// ---------------------------------------------------------------------------

/// Item de palette en cours de saisie (états invalides permis).
final class EnvironmentPaletteItemDraft {
  EnvironmentPaletteItemDraft({
    required this.elementId,
    required this.weight,
    this.collisionMode = EnvironmentCollisionMode.useElementDefault,
    Set<String> tags = const <String>{},
  }) : tags = Set.unmodifiable(Set<String>.from(tags));

  final String elementId;
  final int weight;
  final EnvironmentCollisionMode collisionMode;

  /// Copie défensive à la construction ; exposé immuable.
  final Set<String> tags;

  EnvironmentPaletteItemDraft copyWith({
    String? elementId,
    int? weight,
    EnvironmentCollisionMode? collisionMode,
    Set<String>? tags,
  }) {
    final nextTags =
        tags != null ? Set<String>.from(tags) : Set<String>.from(this.tags);
    return EnvironmentPaletteItemDraft(
      elementId: elementId ?? this.elementId,
      weight: weight ?? this.weight,
      collisionMode: collisionMode ?? this.collisionMode,
      tags: nextTags,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPaletteItemDraft &&
            elementId == other.elementId &&
            weight == other.weight &&
            collisionMode == other.collisionMode &&
            _setEquals(tags, other.tags);
  }

  @override
  int get hashCode {
    final sorted = tags.toList()..sort();
    return Object.hash(
      elementId,
      weight,
      collisionMode,
      Object.hashAll(sorted),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset draft
// ---------------------------------------------------------------------------

/// Brouillon complet de preset Environment (création / future édition).
final class EnvironmentPresetDraft {
  factory EnvironmentPresetDraft({
    required String id,
    required String name,
    required String templateId,
    required List<EnvironmentPaletteItemDraft> palette,
    required EnvironmentGenerationParamsDraft defaultParams,
    String? categoryId,
    int sortOrder = 0,
  }) {
    return EnvironmentPresetDraft._(
      id: id,
      name: name,
      templateId: templateId,
      palette: List<EnvironmentPaletteItemDraft>.unmodifiable(
        List<EnvironmentPaletteItemDraft>.from(palette),
      ),
      defaultParams: defaultParams,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  factory EnvironmentPresetDraft.empty() {
    return EnvironmentPresetDraft(
      id: '',
      name: '',
      templateId: '',
      palette: const [],
      defaultParams: EnvironmentGenerationParamsDraft.standard(),
      categoryId: null,
      sortOrder: 0,
    );
  }

  factory EnvironmentPresetDraft.fromPreset(EnvironmentPreset preset) {
    return EnvironmentPresetDraft(
      id: preset.id,
      name: preset.name,
      templateId: preset.templateId,
      palette: [
        for (final item in preset.palette)
          EnvironmentPaletteItemDraft(
            elementId: item.elementId,
            weight: item.weight,
            collisionMode: item.collisionMode,
            tags: item.tags,
          ),
      ],
      defaultParams: EnvironmentGenerationParamsDraft(
        density: preset.defaultParams.density,
        variation: preset.defaultParams.variation,
        edgeDensity: preset.defaultParams.edgeDensity,
        minSpacingCells: preset.defaultParams.minSpacingCells,
      ),
      categoryId: preset.categoryId,
      sortOrder: preset.sortOrder,
    );
  }

  const EnvironmentPresetDraft._({
    required this.id,
    required this.name,
    required this.templateId,
    required this.palette,
    required this.defaultParams,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String templateId;

  /// Copie défensive ; liste immuable.
  final List<EnvironmentPaletteItemDraft> palette;

  final EnvironmentGenerationParamsDraft defaultParams;
  final String? categoryId;
  final int sortOrder;

  EnvironmentPresetDraft copyWith({
    String? id,
    String? name,
    String? templateId,
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
    String? categoryId,
    bool clearCategoryId = false,
    int? sortOrder,
  }) {
    final nextCategory =
        clearCategoryId ? null : (categoryId ?? this.categoryId);
    return EnvironmentPresetDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      palette: palette ?? this.palette,
      defaultParams: defaultParams ?? this.defaultParams,
      categoryId: nextCategory,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraft &&
            id == other.id &&
            name == other.name &&
            templateId == other.templateId &&
            _listEquals(palette, other.palette) &&
            defaultParams == other.defaultParams &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        templateId,
        Object.hashAll(palette),
        defaultParams,
        categoryId,
        sortOrder,
      );
}

// ---------------------------------------------------------------------------
// Validation — issues
// ---------------------------------------------------------------------------

enum EnvironmentPresetDraftIssueSeverity {
  error,
  warning,
}

enum EnvironmentPresetDraftIssueKind {
  emptyId,
  duplicateId,
  emptyName,
  emptyTemplateId,
  unknownTemplateId,
  emptyPalette,
  emptyPaletteElementId,
  duplicatePaletteElementId,
  missingPaletteElement,
  mixedPaletteTilesets,
  invalidPaletteWeight,
  emptyPaletteTag,
  invalidDensity,
  invalidVariation,
  invalidEdgeDensity,
  invalidMinSpacingCells,
  emptyCategoryId,
}

final class EnvironmentPresetDraftIssue {
  const EnvironmentPresetDraftIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.presetId,
    this.elementId,
    this.templateId,
    this.paletteIndex,
    this.tag,
  });

  final EnvironmentPresetDraftIssueSeverity severity;
  final EnvironmentPresetDraftIssueKind kind;
  final String message;
  final String? presetId;
  final String? elementId;
  final String? templateId;
  final int? paletteIndex;
  final String? tag;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraftIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            paletteIndex == other.paletteIndex &&
            tag == other.tag;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        presetId,
        elementId,
        templateId,
        paletteIndex,
        tag,
      );
}

// ---------------------------------------------------------------------------
// Validation — report
// ---------------------------------------------------------------------------

final class EnvironmentPresetDraftValidationReport {
  factory EnvironmentPresetDraftValidationReport({
    required List<EnvironmentPresetDraftIssue> issues,
  }) {
    return EnvironmentPresetDraftValidationReport._(
      issues: List<EnvironmentPresetDraftIssue>.unmodifiable(
        List<EnvironmentPresetDraftIssue>.from(issues),
      ),
    );
  }

  const EnvironmentPresetDraftValidationReport._({required this.issues});

  final List<EnvironmentPresetDraftIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  bool get hasErrors => issues
      .any((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error);

  bool get hasWarnings => issues.any(
        (i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning,
      );

  int get issueCount => issues.length;

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.error)
      .length;

  int get warningCount => issues
      .where((i) => i.severity == EnvironmentPresetDraftIssueSeverity.warning)
      .length;

  List<EnvironmentPresetDraftIssue> issuesForKind(
    EnvironmentPresetDraftIssueKind kind,
  ) {
    return List<EnvironmentPresetDraftIssue>.unmodifiable(
      [
        for (final i in issues)
          if (i.kind == kind) i
      ],
    );
  }

  List<EnvironmentPresetDraftIssue> issuesForPaletteIndex(int index) {
    if (index < 0) {
      return const [];
    }
    return List<EnvironmentPresetDraftIssue>.unmodifiable(
      [
        for (final i in issues)
          if (i.paletteIndex == index) i
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDraftValidationReport &&
            _listEquals(issues, other.issues);
  }

  @override
  int get hashCode => Object.hashAll(issues);
}

// ---------------------------------------------------------------------------
// validateEnvironmentPresetDraft
// ---------------------------------------------------------------------------

/// Valide un [EnvironmentPresetDraft] contre un manifest et options auteur.
///
/// [existingPresetId] trimé : en édition, le preset portant cet id ne provoque
/// pas [EnvironmentPresetDraftIssueKind.duplicateId] pour lui-même.
EnvironmentPresetDraftValidationReport validateEnvironmentPresetDraft(
  EnvironmentPresetDraft draft, {
  required ProjectManifest manifest,
  Set<String> knownTemplateIds = const <String>{},
  String? existingPresetId,
}) {
  final issues = <EnvironmentPresetDraftIssue>[];
  final trimmedExisting = existingPresetId?.trim();

  void add(EnvironmentPresetDraftIssue issue) {
    issues.add(issue);
  }

  // --- 1. Champs globaux (ordre stable) ---
  final tid = draft.id.trim();
  if (tid.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyId,
      message: 'Environment preset draft id is empty.',
    ));
  }

  final tname = draft.name.trim();
  if (tname.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyName,
      message: 'Environment preset draft name is empty.',
    ));
  }

  final ttemplate = draft.templateId.trim();
  if (ttemplate.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyTemplateId,
      message: 'Environment preset draft templateId is empty.',
    ));
  }

  if (draft.categoryId != null) {
    final c = draft.categoryId!.trim();
    if (c.isEmpty) {
      add(const EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.emptyCategoryId,
        message: 'Environment preset draft categoryId is empty.',
      ));
    }
  }

  final p = draft.defaultParams;
  if (p.density < 0.0 || p.density > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidDensity,
      message: 'Environment preset draft density must be between 0.0 and 1.0.',
    ));
  }
  if (p.variation < 0.0 || p.variation > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidVariation,
      message:
          'Environment preset draft variation must be between 0.0 and 1.0.',
    ));
  }
  if (p.edgeDensity < 0.0 || p.edgeDensity > 1.0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidEdgeDensity,
      message:
          'Environment preset draft edgeDensity must be between 0.0 and 1.0.',
    ));
  }
  if (p.minSpacingCells < 0) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.invalidMinSpacingCells,
      message: 'Environment preset draft minSpacingCells must be >= 0.',
    ));
  }

  // --- 2. duplicateId ---
  final existingKey = (trimmedExisting != null && trimmedExisting.isNotEmpty)
      ? trimmedExisting
      : null;
  if (tid.isNotEmpty) {
    var duplicate = false;
    for (final preset in manifest.environmentPresets) {
      if (preset.id != tid) {
        continue;
      }
      if (existingKey != null && preset.id == existingKey) {
        continue;
      }
      duplicate = true;
      break;
    }
    if (duplicate) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.duplicateId,
        message:
            'Environment preset draft id duplicates existing preset "$tid".',
        presetId: tid,
      ));
    }
  }

  // --- 3. unknownTemplateId (warning) ---
  if (knownTemplateIds.isNotEmpty && ttemplate.isNotEmpty) {
    if (!knownTemplateIds.contains(ttemplate)) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.warning,
        kind: EnvironmentPresetDraftIssueKind.unknownTemplateId,
        message:
            'Environment preset draft templateId "$ttemplate" is not in knownTemplateIds.',
        templateId: ttemplate,
      ));
    }
  }

  // --- 4. emptyPalette ---
  if (draft.palette.isEmpty) {
    add(const EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.emptyPalette,
      message: 'Environment preset draft palette is empty.',
    ));
  }

  // --- 5. Items palette (ordre des index) ---
  final elementsById = <String, ProjectElementEntry>{
    for (final e in manifest.elements) e.id: e,
  };

  final seenElementIds = <String, int>{};
  for (var i = 0; i < draft.palette.length; i++) {
    final item = draft.palette[i];
    final eid = item.elementId.trim();

    if (eid.isEmpty) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.emptyPaletteElementId,
        message: 'Environment preset draft palette item has empty elementId.',
        paletteIndex: i,
      ));
    } else {
      if (seenElementIds.containsKey(eid)) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.duplicatePaletteElementId,
          message:
              'Environment preset draft palette duplicate elementId "$eid" at index $i.',
          elementId: eid,
          paletteIndex: i,
        ));
      } else {
        seenElementIds[eid] = i;
      }

      if (!elementsById.containsKey(eid)) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.missingPaletteElement,
          message:
              'Environment preset draft palette references missing element "$eid".',
          elementId: eid,
          paletteIndex: i,
        ));
      }
    }

    if (item.weight <= 0) {
      add(EnvironmentPresetDraftIssue(
        severity: EnvironmentPresetDraftIssueSeverity.error,
        kind: EnvironmentPresetDraftIssueKind.invalidPaletteWeight,
        message:
            'Environment preset draft palette item weight must be >= 1 (index $i).',
        elementId: eid.isEmpty ? null : eid,
        paletteIndex: i,
      ));
    }

    for (final rawTag in item.tags) {
      if (rawTag.trim().isEmpty) {
        add(EnvironmentPresetDraftIssue(
          severity: EnvironmentPresetDraftIssueSeverity.error,
          kind: EnvironmentPresetDraftIssueKind.emptyPaletteTag,
          message:
              'Environment preset draft palette item has empty tag (index $i).',
          elementId: eid.isEmpty ? null : eid,
          paletteIndex: i,
          tag: rawTag,
        ));
      }
    }
  }

  final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
    paletteElementIds: [
      for (final item in draft.palette) item.elementId,
    ],
    projectElements: manifest.elements,
  );
  for (final elementId in tilesetCompatibility.incompatiblePaletteElementIds) {
    add(EnvironmentPresetDraftIssue(
      severity: EnvironmentPresetDraftIssueSeverity.error,
      kind: EnvironmentPresetDraftIssueKind.mixedPaletteTilesets,
      message:
          'Le brouillon mélange plusieurs tilesets. Gardez une palette compatible avec le tileset source "${tilesetCompatibility.sourceTilesetId}".',
      elementId: elementId,
    ));
  }

  return EnvironmentPresetDraftValidationReport(issues: issues);
}

// ---------------------------------------------------------------------------
// buildEnvironmentPresetFromDraft
// ---------------------------------------------------------------------------

/// Construit un [EnvironmentPreset] map_core à partir d’un brouillon valide.
///
/// Ne consulte pas le manifest : appeler [validateEnvironmentPresetDraft]
/// avant une persistance. Lève [ArgumentError] si les constructeurs map_core
/// rejettent les données (id vide, tag vide, etc.) — pas de filtrage silencieux
/// des tags vides.
EnvironmentPreset buildEnvironmentPresetFromDraft(
  EnvironmentPresetDraft draft,
) {
  final nid = draft.id.trim();
  if (nid.isEmpty) {
    throw ArgumentError.value(
      draft.id,
      'draft.id',
      'buildEnvironmentPresetFromDraft: id cannot be empty after trim.',
    );
  }
  final nname = draft.name.trim();
  final ntemplate = draft.templateId.trim();
  final String? cat;
  if (draft.categoryId == null) {
    cat = null;
  } else {
    final c = draft.categoryId!.trim();
    if (c.isEmpty) {
      throw ArgumentError.value(
        draft.categoryId,
        'draft.categoryId',
        'buildEnvironmentPresetFromDraft: categoryId cannot be empty after trim.',
      );
    }
    cat = c;
  }

  final palette = <EnvironmentPaletteItem>[
    for (final d in draft.palette)
      EnvironmentPaletteItem(
        elementId: d.elementId.trim(),
        weight: d.weight,
        collisionMode: d.collisionMode,
        tags: d.tags.map((t) => t.trim()).toSet(),
      ),
  ];

  final params = EnvironmentGenerationParams(
    density: draft.defaultParams.density,
    variation: draft.defaultParams.variation,
    edgeDensity: draft.defaultParams.edgeDensity,
    minSpacingCells: draft.defaultParams.minSpacingCells,
  );

  return EnvironmentPreset(
    id: nid,
    name: nname,
    templateId: ntemplate,
    palette: palette,
    defaultParams: params,
    categoryId: cat,
    sortOrder: draft.sortOrder,
  );
}

// --- helpers ---

bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final x in a) {
    if (!b.contains(x)) {
      return false;
    }
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
