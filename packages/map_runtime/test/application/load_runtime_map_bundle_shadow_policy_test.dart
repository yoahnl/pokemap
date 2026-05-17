import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  group('loadProjectManifestFromFile authored shadow manifest', () {
    test('keeps missing shadow configs absent at runtime load', () async {
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
          _project(
            elements: [
              _element(id: 'lamp', width: 1, height: 4),
            ],
            shadowCatalog: const ProjectShadowCatalog.empty(),
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements.single.shadow, isNull);
    });

    test('preserves recognized old auto shadows as authored data', () async {
      final oldAutoShadow = _oldAutoSmallSquareShadow();
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
          _project(
            elements: [
              _element(
                id: 'small',
                width: 2,
                height: 2,
                shadow: oldAutoShadow,
              ),
            ],
            shadowCatalog: _defaultCatalog(),
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements.single.shadow, oldAutoShadow);
    });

    test('preserves manual and disabled shadows', () async {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final root =
          await Directory.systemTemp.createTemp('runtime_shadow_manifest_');
      addTearDown(() => root.delete(recursive: true));
      final manifestPath = p.join(root.path, 'project.json');
      await File(manifestPath).writeAsString(
        jsonEncode(
          _project(
            elements: [
              _element(id: 'manual', width: 2, height: 2, shadow: manual),
              _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
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
          ).toJson(),
        ),
      );

      final manifest = await loadProjectManifestFromFile(manifestPath);

      expect(manifest.elements[0].shadow, manual);
      expect(manifest.elements[1].shadow, disabled);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Runtime shadow manifest test',
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

ProjectElementEntry _element({
  required String id,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
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
