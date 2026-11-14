import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  test(
    'compatibility rejects loss in rules, transforms, materials and atlas',
    () {
      final controller = terrainDraft();
      assignAll(controller);
      final draft = controller.draft;
      final rule = draft.rules.first;
      final candidate = rule.candidates.single;
      final part = candidate.parts.single;
      final advanced = <ProjectSmartTileAuthoringDraft>[
        draft.copyWith(rules: draft.rules.reversed.toList()),
        draft.copyWith(
          transformPolicy: const SmartTileTransformPolicy(allowHFlip: true),
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(centerMatch: const SmartTileSlotMatch.any()),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(
              candidates: [
                candidate,
                candidate.copyWith(id: 'variant'),
              ],
            ),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(
              candidates: [
                candidate.copyWith(parts: [part.copyWith(offsetX: 1)]),
              ],
            ),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          materials: [
            ...draft.materials,
            draft.materials.single.copyWith(id: 'other'),
          ],
        ),
        draft.copyWith(atlases: [draft.atlases.single.copyWith(originX: 1)]),
        draft.copyWith(fallbackRuleId: rule.id),
      ];
      expect(
        terrainDraftCompatibilityProblem(controller.manifest, draft),
        isNull,
      );
      for (final value in advanced) {
        expect(
          terrainDraftCompatibilityProblem(controller.manifest, value),
          isNotNull,
        );
        expect(
          () => TerrainDraftController.resume(
            manifest: controller.manifest,
            draft: value,
          ),
          throwsStateError,
        );
      }
      expect(controller.draft, draft);
    },
  );

  test(
    'saved and published states survive resume without metadata loss',
    () async {
      final controller = terrainDraft();
      assignAll(controller);
      controller.draft = controller.draft.copyWith(
        tags: ['rivière'],
        sortOrder: 7,
        seedSalt: 31,
      );
      final snapshot = controller.draft;
      final manifest = publishFixture(controller);
      final resumed = TerrainDraftController.resume(
        manifest: manifest,
        draft: snapshot,
      );
      expect(resumed.statusLabel, 'Version publiée');
      expect(resumed.hasUnpublishedChanges, isFalse);
      resumed.assign(0, 1);
      expect(resumed.statusLabel, 'Modifications non enregistrées');
      await resumed.save((_, _) async => manifest);
      expect(resumed.statusLabel, 'Modifications non publiées');
      expect(resumed.draft.tags, snapshot.tags);
      expect(resumed.draft.sortOrder, 7);
      expect(resumed.draft.seedSalt, 31);
      expect(
        resumed.previewPreset.id,
        manifest.smartTileCatalog.presets.single.id,
      );
    },
  );

  test('published reconstruction never bypasses an advanced pending draft', () {
    final controller = terrainDraft();
    assignAll(controller);
    final manifest = publishFixture(controller);
    final preset = manifest.smartTileCatalog.presets.single;
    final reconstructed = terrainDraftForPreset(manifest, preset)!;
    expect(reconstructed.targetPresetId, preset.id);
    expect(reconstructed.sourcePresetId, preset.id);
    expect(
      terrainDraftForPreset(
        manifest,
        preset.copyWith(
          transformPolicy: const SmartTileTransformPolicy(allowHFlip: true),
        ),
      ),
      isNull,
    );
    final advanced = reconstructed.copyWith(
      rules: reconstructed.rules.reversed.toList(),
    );
    expect(
      editableTerrainDraft(manifest, preset, localDrafts: [advanced]),
      isNull,
    );
    expect(
      editableTerrainDraft(manifest, preset, localDrafts: [reconstructed]),
      same(reconstructed),
    );
  });

  test(
    'failed publication keeps saved draft and retries publication only',
    () async {
      final controller = terrainDraft();
      assignAll(controller);
      final published = publishFixture(controller);
      controller.manifest = published;
      controller.assign(0, 1);
      final actions = <String>[];
      var fail = true;
      Future<ProjectManifest> mutate(
        String action,
        Map<String, Object?> args,
      ) async {
        actions.add(action);
        if (action.endsWith('publish') && fail) throw StateError('conflit');
        if (action.endsWith('publish')) return publishFixture(controller);
        final catalog = published.smartTileCatalog;
        return published.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: catalog.atlases,
            materials: catalog.materials,
            presets: catalog.presets,
            drafts: [controller.draft],
          ),
        );
      }

      expect(await controller.save(mutate, publish: true), isFalse);
      expect(controller.dirty, isFalse);
      expect(controller.publicationFailedAfterSave, isTrue);
      expect(
        controller.statusLabel,
        'Brouillon enregistré ; publication non effectuée',
      );
      expect(controller.error, contains('conflit'));
      expect(
        controller.publishedPreset,
        published.smartTileCatalog.presets.single,
      );
      fail = false;
      actions.clear();
      expect(await controller.save(mutate, publish: true), isTrue);
      expect(actions, ['smart_tile.preset.publish']);
      expect(controller.statusLabel, 'Version publiée');
    },
  );

  test('reconstruction refuses another target owning the derived draft ID', () {
    final controller = terrainDraft();
    assignAll(controller);
    final manifest = publishFixture(controller);
    final preset = manifest.smartTileCatalog.presets.single;
    final thirdParty = controller.draft.copyWith(
      targetPresetId: 'another-terrain',
    );
    final original = thirdParty.toJson();
    expect(
      editableTerrainDraft(manifest, preset, localDrafts: [thirdParty]),
      isNull,
    );
    final catalog = manifest.smartTileCatalog;
    final stored = manifest.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: catalog.atlases,
        materials: catalog.materials,
        presets: catalog.presets,
        drafts: [thirdParty],
      ),
    );
    expect(terrainDraftForPreset(stored, preset), isNull);
    expect(editableTerrainDraft(stored, preset), isNull);
    final candidate = controller.draft.copyWith(id: 'shared-draft');
    expect(
      editableTerrainDraft(
        manifest,
        preset,
        localDrafts: [
          candidate,
          thirdParty.copyWith(id: candidate.id),
        ],
      ),
      isNull,
    );
    expect(stored.smartTileCatalog.drafts.single, same(thirdParty));
    expect(thirdParty.toJson(), original);
    expect(manifest.smartTileCatalog.drafts, isEmpty);
  });
}
