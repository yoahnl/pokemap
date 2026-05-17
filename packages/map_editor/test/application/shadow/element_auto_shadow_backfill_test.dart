import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' hide ElementAutoShadowSuggestionKind;
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('applyElementAutoShadowSuggestionsToProject', () {
    test('applies suggestions to elements without shadow configs', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(id: 'house', name: 'House', width: 4, height: 3),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 2);
      expect(result.skippedCount, 0);
      expect(result.hasChanges, isTrue);
      expect(result.addedDefaultProfiles, isFalse);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.appliedMissing,
        ElementAutoShadowBackfillStatus.appliedMissing,
      ]);
      expect(result.entries.map((entry) => entry.suggestionKind), [
        ElementAutoShadowSuggestionKind.tallThin,
        ElementAutoShadowSuggestionKind.buildingLarge,
      ]);
      expect(
        result.project.elements[0].shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
      expect(
        result.project.elements[0].shadow!.family,
        StaticShadowFamily.tallProp,
      );
      expect(
        result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
        0.28,
      );
      expect(
        result.project.elements[1].shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
      expect(
        result.project.elements[1].shadow!.family,
        StaticShadowFamily.building,
      );
      expect(
        result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
        0.60,
      );
    });

    test('replaces generic pre-footprint active shadows', () {
      final project = _project(
        elements: [
          _element(
            id: 'stand',
            name: 'Stand',
            width: 4,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-soft-ellipse',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(result.project.elements.single.shadow!.footprint, isNotNull);
      expect(
        result.project.elements.single.shadow!.footprint!.footprintWidthRatio,
        0.58,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
    });

    test('preserves disabled shadows', () {
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final project = _project(
        elements: [
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 1,
            height: 4,
            shadow: disabled,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      );
      expect(result.project.elements.single.shadow, disabled);
    });

    test('preserves manual footprints and numeric overrides', () {
      final manualFootprint = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-contact-blob',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.31),
      );
      final manualNumbers = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-wide-ellipse',
        offsetX: 4,
        scaleY: 0.6,
        opacity: 0.18,
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-footprint',
            name: 'Manual footprint',
            width: 1,
            height: 4,
            shadow: manualFootprint,
          ),
          _element(
            id: 'manual-numbers',
            name: 'Manual numbers',
            width: 4,
            height: 3,
            shadow: manualNumbers,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 2);
      expect(
        result.entries.map((entry) => entry.status),
        everyElement(ElementAutoShadowBackfillStatus.skippedManual),
      );
      expect(result.project.elements[0].shadow, manualFootprint);
      expect(result.project.elements[1].shadow, manualNumbers);
    });

    test(
        'clears recognized auto small square shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'small-square',
            name: 'Small square',
            width: 2,
            height: 2,
            shadow: _oldAutoSmallSquareShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears genericProjection auto shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'default-prop',
            name: 'Default prop',
            width: 2,
            height: 3,
            shadow: _oldAutoDefaultPropShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears recognized auto wide low shadow below safe threshold', () {
      final project = _project(
        elements: [
          _element(
            id: 'small-stand',
            name: 'Small stand',
            width: 3,
            height: 2,
            shadow: _oldAutoWideLowShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves manual footprint even if no suggestion exists', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-soft-ellipse',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.33),
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-small',
            name: 'Manual small',
            width: 2,
            height: 2,
            shadow: manual,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, manual);
    });

    test('preserves non-default existing profile ids present in catalog', () {
      final customShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final project = _project(
        elements: [
          _element(
            id: 'custom-profile',
            name: 'Custom profile',
            width: 4,
            height: 3,
            shadow: customShadow,
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, customShadow);
    });

    test('replaces generic shadows with missing profile ids', () {
      final project = _project(
        elements: [
          _element(
            id: 'missing-profile',
            name: 'Missing profile',
            width: 1,
            height: 4,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing-profile-id',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('adds default profiles when the catalog has no compatible profile',
        () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
          result.project.shadowCatalog.profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('records skippedNoSuggestion for invalid element frames', () {
      final project = _project(
        elements: [
          _elementWithFrames(
            id: 'invalid',
            name: 'Invalid',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0, height: 2),
              ),
            ],
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves element order and non-shadow fields', () {
      final project = _project(
        elements: [
          _element(
            id: 'first',
            name: 'First',
            width: 1,
            height: 4,
            presetKind: ElementPresetKind.tree,
            tags: const ['nature', 'tall'],
            sortOrder: 7,
          ),
          _element(
            id: 'second',
            name: 'Second',
            width: 4,
            height: 3,
            recommendedLayerId: 'decor_layer',
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.project.elements.map((element) => element.id), [
        'first',
        'second',
      ]);
      expect(result.project.elements[0].presetKind, ElementPresetKind.tree);
      expect(result.project.elements[0].tags, ['nature', 'tall']);
      expect(result.project.elements[0].sortOrder, 7);
      expect(result.project.elements[1].recommendedLayerId, 'decor_layer');
      expect(result.project.elements[0].shadow, isNotNull);
      expect(result.project.elements[1].shadow, isNotNull);
    });

    test('editor wrapper stays in parity with core backfill operation', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(
            id: 'house',
            name: 'House',
            width: 4,
            height: 3,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-wide-ellipse',
            ),
          ),
          _element(id: 'small', name: 'Small', width: 2, height: 2),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final editorResult = applyElementAutoShadowSuggestionsToProject(project);
      final coreResult = applyElementAutoShadowPolicyToProject(project);

      expect(editorResult.project, coreResult.project);
      expect(editorResult.entries, coreResult.entries);
      expect(
          editorResult.addedDefaultProfiles, coreResult.addedDefaultProfiles);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Backfill test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return _elementWithFrames(
    id: id,
    name: name,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
    presetKind: presetKind,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

ProjectElementEntry _elementWithFrames({
  required String id,
  required String name,
  required List<TilesetVisualFrame> frames,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: frames,
    presetKind: presetKind,
    shadow: shadow,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}
