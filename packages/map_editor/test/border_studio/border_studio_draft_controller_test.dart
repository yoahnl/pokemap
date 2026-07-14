import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft_controller.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';

void main() {
  group('BorderStudioDraftController', () {
    test('loads a catalog and selects its first draft without an open map', () {
      final record = _record(id: 'coast', name: 'Cote rocheuse');
      final manifest = _manifest(records: <BorderBlueprintRecord>[record]);
      final controller = BorderStudioDraftController();

      controller.loadFromManifest(manifest);

      expect(controller.state.catalogRecords, <BorderBlueprintRecord>[record]);
      expect(controller.state.selectedBlueprintId, 'coast');
      expect(controller.state.workingDraft?.blueprint, record.draft);
      expect(controller.state.isDirty, isFalse);
    });

    test('reloads the selected draft and clears state when no project is open',
        () {
      final controller = BorderStudioDraftController();
      controller.loadFromManifest(
        _manifest(
          records: <BorderBlueprintRecord>[
            _record(id: 'coast', name: 'Cote'),
            _record(id: 'wall', name: 'Mur'),
          ],
        ),
      );
      controller.selectBlueprint('wall');

      controller.reloadFromManifest(
        _manifest(
          records: <BorderBlueprintRecord>[
            _record(id: 'coast', name: 'Cote modifiee'),
            _record(id: 'wall', name: 'Mur recharge'),
          ],
        ),
      );

      expect(controller.state.selectedBlueprintId, 'wall');
      expect(
        controller.state.workingDraft?.blueprint.definition.name,
        'Mur recharge',
      );
      expect(controller.state.isDirty, isFalse);

      controller.reloadFromManifest(null);
      expect(controller.state.catalogRecords, isEmpty);
      expect(controller.state.selectedBlueprintId, isNull);
      expect(controller.state.workingDraft, isNull);
    });

    test('creates and edits every V1 template through the public role matrix',
        () {
      final controller = BorderStudioDraftController();
      controller.loadFromManifest(_manifest());
      final masonryRules = _rules(depthRows: 2);

      controller.createBlueprint(
        id: 'wall',
        name: 'Muret',
        template: BorderBlueprintTemplate.masonryLine,
      );
      controller.setGenerationParams(masonryRules);
      controller.setGround(
        BorderGroundDraft(
          sourceSurfacePresetId: 'ground-stone',
          edgeBandCells: 2,
        ),
      );
      controller.replacePrimitives(<BorderPrimitiveDraft>[
        _primitive(
          id: 'stone',
          role: BorderPrimitiveRole.structureLarge,
        ),
      ]);

      expect(controller.state.workingDraft?.blueprint.definition.defaults,
          masonryRules);
      expect(
        controller.state.allowedPrimitiveRoles,
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.masonryLine,
        ),
      );
      expect(
        () => controller.replacePrimitives(<BorderPrimitiveDraft>[
          _primitive(id: 'post', role: BorderPrimitiveRole.post),
        ]),
        throwsArgumentError,
      );

      controller.replacePrimitives(const <BorderPrimitiveDraft>[]);
      controller.setTemplate(BorderBlueprintTemplate.postAndRailLine);
      controller.replacePrimitives(<BorderPrimitiveDraft>[
        _primitive(id: 'post', role: BorderPrimitiveRole.post),
        _primitive(id: 'span', role: BorderPrimitiveRole.span),
      ]);
      expect(
        controller.state.allowedPrimitiveRoles,
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.postAndRailLine,
        ),
      );

      controller.replacePrimitives(const <BorderPrimitiveDraft>[]);
      controller.setTemplate(BorderBlueprintTemplate.organicEdge);
      controller.replacePrimitives(<BorderPrimitiveDraft>[
        _primitive(id: 'accent', role: BorderPrimitiveRole.outerAccent),
      ]);
      expect(
        controller.state.allowedPrimitiveRoles,
        borderAllowedPrimitiveRolesForTemplate(
          BorderBlueprintTemplate.organicEdge,
        ),
      );
      expect(controller.state.isDirty, isTrue);
    });

    test('saves by replacing only the draft and preserving publication data',
        () {
      final published = _publishedRevision(name: 'Cote publiee');
      final snapshot = _snapshot('a');
      final record = _record(
        id: 'coast',
        name: 'Cote brouillon',
        latestPublished: published,
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[record],
        visualSnapshots: <BorderVisualSnapshot>[snapshot],
      );
      final controller = BorderStudioDraftController();
      controller.loadFromManifest(manifest);
      controller.renameBlueprint('Cote retouchee');

      final updated = controller.saveDraft();

      final saved = updated.borderCatalog.records.single;
      expect(saved.draft.definition.name, 'Cote retouchee');
      expect(saved.latestPublished, same(published));
      expect(updated.borderCatalog.visualSnapshots.single, same(snapshot));
      expect(updated.maps, manifest.maps);
      expect(manifest.borderCatalog.records.single, same(record));
      expect(controller.state.isDirty, isFalse);
    });

    test('copies a draft as a new unpublished identity and adds it on save',
        () {
      final source = _record(
        id: 'coast',
        name: 'Cote',
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'rock', role: BorderPrimitiveRole.structureLarge),
        ],
        ground: BorderGroundDraft(
          sourceSurfacePresetId: 'ground-sand',
          edgeBandCells: 1,
        ),
      );
      final controller = BorderStudioDraftController();
      controller.loadFromManifest(
        _manifest(records: <BorderBlueprintRecord>[source]),
      );

      controller.copyBlueprint(
        sourceBlueprintId: 'coast',
        newBlueprintId: 'coast-copy',
        name: 'Cote copie',
      );

      final copy = controller.state.workingDraft!;
      expect(copy.id, 'coast-copy');
      expect(copy.blueprint.baseRevision, 0);
      expect(copy.blueprint.definition.name, 'Cote copie');
      expect(
          copy.blueprint.definition.template, source.draft.definition.template);
      expect(copy.blueprint.definition.primitives,
          source.draft.definition.primitives);
      expect(
          copy.blueprint.definition.defaults, source.draft.definition.defaults);
      expect(copy.blueprint.definition.ground, source.draft.definition.ground);
      expect(controller.state.selectedHasPublishedRevision, isFalse);
      expect(controller.state.isDirty, isTrue);

      final updated = controller.saveDraft();
      expect(
        updated.borderCatalog.records.map((record) => record.id),
        <String>['coast', 'coast-copy'],
      );
      expect(
        updated.borderCatalog.recordById('coast-copy')?.latestPublished,
        isNull,
      );
    });

    test('deletes only a selected never-published draft', () {
      final draft = _record(id: 'draft', name: 'Brouillon');
      final published = _record(
        id: 'published',
        name: 'Publie',
        latestPublished: _publishedRevision(name: 'Publie'),
      );
      final controller = BorderStudioDraftController();
      controller.loadFromManifest(
        _manifest(records: <BorderBlueprintRecord>[draft, published]),
      );

      final updated = controller.deleteSelectedDraft();

      expect(
        updated.borderCatalog.records.map((record) => record.id),
        <String>['published'],
      );
      expect(controller.state.selectedBlueprintId, 'published');
      expect(controller.state.canDeleteSelectedDraft, isFalse);
      expect(controller.deleteSelectedDraft, throwsStateError);
    });

    test('creates deterministic preview seeds and varies only the working seed',
        () {
      final record = _record(
        id: 'coast',
        name: 'Cote',
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'rock', role: BorderPrimitiveRole.structureLarge),
        ],
        ground: BorderGroundDraft(
          sourceSurfacePresetId: 'ground-sand',
          edgeBandCells: 1,
        ),
      );
      final manifest = _manifest(records: <BorderBlueprintRecord>[record]);
      final first = BorderStudioDraftController()..loadFromManifest(manifest);
      final second = BorderStudioDraftController()..loadFromManifest(manifest);
      final before = first.state.workingDraft!.blueprint;
      first.setDiagnostics(const BorderDiagnosticsReport.empty());
      second.setDiagnostics(const BorderDiagnosticsReport.empty());
      expect(first.state.diagnosticsAreCurrent, isTrue);

      first.newPreviewVariation();
      second.newPreviewVariation();

      final after = first.state.workingDraft!.blueprint;
      expect(
          after.definition.previewSeed, isNot(before.definition.previewSeed));
      expect(
        after.definition.previewSeed,
        second.state.workingDraft!.blueprint.definition.previewSeed,
      );
      expect(after.baseRevision, before.baseRevision);
      expect(after.definition.name, before.definition.name);
      expect(after.definition.template, before.definition.template);
      expect(after.definition.primitives, before.definition.primitives);
      expect(after.definition.defaults, before.definition.defaults);
      expect(after.definition.ground, before.definition.ground);
      expect(after.definition.categoryId, before.definition.categoryId);
      expect(after.definition.sortOrder, before.definition.sortOrder);
      expect(first.state.isDirty, isTrue);
      expect(first.state.diagnosticsAreCurrent, isFalse);
      expect(first.state.canPublish, isFalse);

      final createdFirst = BorderStudioDraftController()
        ..loadFromManifest(_manifest())
        ..createBlueprint(
          id: 'generated',
          name: 'Genere',
          template: BorderBlueprintTemplate.organicEdge,
        );
      final createdSecond = BorderStudioDraftController()
        ..loadFromManifest(_manifest())
        ..createBlueprint(
          id: 'generated',
          name: 'Genere',
          template: BorderBlueprintTemplate.organicEdge,
        );
      expect(
        createdFirst.state.previewSeed,
        createdSecond.state.previewSeed,
      );
    });

    test('enables only organic edges for the BORD-03 publication lot', () {
      final controller = BorderStudioDraftController()
        ..loadFromManifest(
          _manifest(records: <BorderBlueprintRecord>[
            _record(id: 'edge', name: 'Bord'),
          ]),
        );

      controller.setDiagnostics(const BorderDiagnosticsReport.empty());

      expect(controller.state.publicationAvailability.isAllowed, isTrue);
      expect(controller.state.publicationAvailability.disabledReason, isNull);
      expect(controller.state.canPublish, isTrue);

      controller.setTemplate(BorderBlueprintTemplate.masonryLine);
      expect(controller.state.canPublish, isFalse);
      expect(
        controller.state.publicationAvailability.disabledReason,
        contains('BORD-06'),
      );

      controller.setTemplate(BorderBlueprintTemplate.postAndRailLine);
      expect(controller.state.canPublish, isFalse);
      expect(
        controller.state.publicationAvailability.disabledReason,
        contains('BORD-06'),
      );
    });

    test('requires explicit acknowledgement of every warning code', () {
      final controller = BorderStudioDraftController()
        ..loadFromManifest(
          _manifest(records: <BorderBlueprintRecord>[
            _record(id: 'edge', name: 'Bord'),
          ]),
        )
        ..setDiagnostics(
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.overlap_warning',
              severity: BorderDiagnosticSeverity.warning,
            ),
            _diagnostic(
              code: 'border.publication.gap_warning',
              severity: BorderDiagnosticSeverity.warning,
            ),
          ]),
        );

      expect(
        controller.state.unacknowledgedWarningCodes,
        <String>{
          'border.publication.gap_warning',
          'border.publication.overlap_warning',
        },
      );
      expect(controller.state.canPublish, isFalse);

      controller
        ..acknowledgeWarningCode('border.publication.overlap_warning')
        ..acknowledgeWarningCode('border.publication.gap_warning');

      expect(
        controller.state.acknowledgedWarningCodes,
        <String>{
          'border.publication.gap_warning',
          'border.publication.overlap_warning',
        },
      );
      expect(controller.state.unacknowledgedWarningCodes, isEmpty);
      expect(controller.state.canPublish, isTrue);
      expect(
        () => controller.acknowledgeWarningCode('border.unknown.warning'),
        throwsArgumentError,
      );
      expect(
        () => controller.state.acknowledgedWarningCodes.add('mutate'),
        throwsUnsupportedError,
      );
    });

    test('detects source divergence and requires reanalysis then republication',
        () {
      final published = _publishedRevision(name: 'Cote publiee');
      final record = _record(
        id: 'coast',
        name: 'Cote',
        primitives: <BorderPrimitiveDraft>[
          _primitive(
            id: 'rock',
            role: BorderPrimitiveRole.structureLarge,
            fingerprint: 'fingerprint-loaded',
          ),
        ],
        latestPublished: published,
      );
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[
          record,
          _record(id: 'other', name: 'Autre'),
        ],
        elements: <ProjectElementEntry>[_element('element-rock')],
      );
      final controller = BorderStudioDraftController()
        ..loadFromManifest(manifest);

      controller.replacePrimitives(<BorderPrimitiveDraft>[
        _primitive(
          id: 'rock',
          role: BorderPrimitiveRole.structureLarge,
          fingerprint: 'fingerprint-current',
        ),
      ]);

      expect(
        controller.state.loadedAssetFingerprints,
        <String, String>{'rock': 'fingerprint-loaded'},
      );
      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});
      expect(controller.state.requiresSourceReanalysis, isTrue);
      expect(controller.state.requiresRepublish, isTrue);
      expect(controller.state.canPublish, isFalse);
      expect(
        controller.state.diagnostics.diagnostics.map((item) => item.code),
        contains(borderStudioSourceReanalysisRequiredDiagnosticCode),
      );

      controller.markPrimitiveReanalyzed('rock');
      controller.setDiagnostics(const BorderDiagnosticsReport.empty());

      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});
      expect(controller.state.requiresSourceReanalysis, isFalse);
      expect(controller.state.requiresRepublish, isTrue);
      expect(controller.state.canPublish, isTrue);
      expect(
        controller.state.diagnostics.diagnostics.map((item) => item.code),
        contains(borderStudioSourceRepublishRequiredDiagnosticCode),
      );

      final updated = controller.saveDraft();
      expect(updated.maps, manifest.maps);
      expect(manifest.borderCatalog.recordById('coast'), same(record));
      expect(
        updated.borderCatalog.recordById('coast')?.latestPublished,
        same(published),
      );
      expect(controller.state.requiresRepublish, isTrue);

      controller.reloadFromManifest(updated);

      expect(controller.state.requiresRepublish, isTrue);
      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});

      controller
        ..selectBlueprint('other')
        ..selectBlueprint('coast');

      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});
      expect(controller.state.requiresSourceReanalysis, isFalse);
      expect(controller.state.requiresRepublish, isTrue);

      controller.selectBlueprint('other');
      controller.synchronizeFromManifest(
        updated.copyWith(globalProperties: <String, dynamic>{'external': true}),
      );
      controller.selectBlueprint('coast');

      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});
      expect(controller.state.requiresRepublish, isTrue);

      controller.selectBlueprint('other');
      controller.deleteSelectedDraft();

      expect(controller.state.selectedBlueprintId, 'coast');
      expect(controller.state.sourceDivergedPrimitiveIds, <String>{'rock'});
      expect(controller.state.requiresSourceReanalysis, isFalse);
      expect(controller.state.requiresRepublish, isTrue);
    });

    test('exposes defensive immutable state collections', () {
      final controller = BorderStudioDraftController()
        ..loadFromManifest(
          _manifest(records: <BorderBlueprintRecord>[
            _record(
              id: 'coast',
              name: 'Cote',
              primitives: <BorderPrimitiveDraft>[
                _primitive(
                  id: 'rock',
                  role: BorderPrimitiveRole.structureLarge,
                ),
              ],
            ),
          ]),
        );

      expect(
        () => controller.state.catalogRecords.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => controller.state.loadedAssetFingerprints['other'] = 'changed',
        throwsUnsupportedError,
      );
      expect(
        () => controller.state.sourceDivergedPrimitiveIds.add('other'),
        throwsUnsupportedError,
      );
      expect(
        () => controller.state.allowedPrimitiveRoles
            .add(BorderPrimitiveRole.post),
        throwsUnsupportedError,
      );
    });

    test('Riverpod provider follows the project manifest, not an active map',
        () {
      final record = _record(id: 'coast', name: 'Cote');
      final container = ProviderContainer(
        overrides: <Override>[
          editorProjectManifestProvider.overrideWithValue(
            _manifest(records: <BorderBlueprintRecord>[record]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(borderStudioDraftControllerProvider);

      expect(state.selectedBlueprintId, 'coast');
      expect(state.workingDraft?.blueprint, record.draft);
    });

    test('Riverpod provider reloads in place and preserves a valid selection',
        () async {
      final source = StateProvider<ProjectManifest?>((ref) {
        return _manifest(
          records: <BorderBlueprintRecord>[
            _record(id: 'coast', name: 'Cote'),
            _record(id: 'wall', name: 'Mur'),
          ],
        );
      });
      final container = ProviderContainer(
        overrides: <Override>[
          editorProjectManifestProvider.overrideWith(
            (ref) => ref.watch(source),
          ),
        ],
      );
      final subscription = container.listen(
        borderStudioDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(
        borderStudioDraftControllerProvider.notifier,
      );
      controller.selectBlueprint('wall');

      container.read(source.notifier).state = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'coast', name: 'Cote rechargee'),
          _record(id: 'wall', name: 'Mur recharge'),
        ],
      );
      await container.pump();

      expect(
        container.read(borderStudioDraftControllerProvider.notifier),
        same(controller),
      );
      expect(
        container.read(borderStudioDraftControllerProvider).selectedBlueprintId,
        'wall',
      );
      expect(
        container
            .read(borderStudioDraftControllerProvider)
            .workingDraft
            ?.blueprint
            .definition
            .name,
        'Mur recharge',
      );
    });

    test('Riverpod manifest updates preserve dirty work and merge on save',
        () async {
      final source = StateProvider<ProjectManifest?>((ref) {
        return _manifest(
          records: <BorderBlueprintRecord>[
            _record(id: 'coast', name: 'Cote'),
            _record(id: 'wall', name: 'Mur'),
          ],
        );
      });
      final container = ProviderContainer(
        overrides: <Override>[
          editorProjectManifestProvider.overrideWith(
            (ref) => ref.watch(source),
          ),
        ],
      );
      final subscription = container.listen(
        borderStudioDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final controller = container.read(
        borderStudioDraftControllerProvider.notifier,
      )
        ..selectBlueprint('wall')
        ..renameBlueprint('Mur local');

      container.read(source.notifier).state = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'coast', name: 'Cote externe'),
          _record(id: 'wall', name: 'Mur externe'),
        ],
      );
      await container.pump();

      expect(controller.state.selectedBlueprintId, 'wall');
      expect(
        controller.state.workingDraft?.blueprint.definition.name,
        'Mur local',
      );
      expect(controller.state.isDirty, isTrue);
      expect(
        controller.state.catalogRecords.first.draft.definition.name,
        'Cote externe',
      );

      final merged = controller.saveDraft();
      expect(
        merged.borderCatalog.recordById('coast')?.draft.definition.name,
        'Cote externe',
      );
      expect(
        merged.borderCatalog.recordById('wall')?.draft.definition.name,
        'Mur local',
      );
    });

    test('same-project rename preserves dirty work during synchronization', () {
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'wall', name: 'Mur'),
        ],
      );
      final controller = BorderStudioDraftController()
        ..loadFromManifest(manifest)
        ..renameBlueprint('Mur local');

      controller.synchronizeFromManifest(
        manifest.copyWith(name: 'Border test renomme'),
      );

      expect(
        controller.state.workingDraft?.blueprint.definition.name,
        'Mur local',
      );
      expect(controller.state.isDirty, isTrue);
    });

    test('project identity change resets dirty work even when names match', () {
      final firstProject = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'wall', name: 'Mur projet A'),
        ],
      );
      final secondProject = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'wall', name: 'Mur projet B'),
        ],
      );
      final controller = BorderStudioDraftController();
      controller.synchronizeFromManifest(
        firstProject,
        projectIdentity: '/projects/a',
      );
      controller.renameBlueprint('Mur local');

      controller.synchronizeFromManifest(
        secondProject,
        projectIdentity: '/projects/b',
      );

      expect(
        controller.state.workingDraft?.blueprint.definition.name,
        'Mur projet B',
      );
      expect(controller.state.isDirty, isFalse);
    });

    test('Riverpod listener gaps keep project-scoped unsaved state', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          editorProjectManifestProvider.overrideWithValue(
            _manifest(
              records: <BorderBlueprintRecord>[
                _record(id: 'wall', name: 'Mur'),
              ],
            ),
          ),
          editorProjectRootPathProvider.overrideWithValue('/projects/test'),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        borderStudioDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final controller = container.read(
        borderStudioDraftControllerProvider.notifier,
      )..renameBlueprint('Mur non enregistre');

      subscription.close();
      await container.pump();

      expect(
        container.read(borderStudioDraftControllerProvider.notifier),
        same(controller),
      );
      expect(
        container
            .read(borderStudioDraftControllerProvider)
            .workingDraft
            ?.blueprint
            .definition
            .name,
        'Mur non enregistre',
      );
      expect(
        container.read(borderStudioDraftControllerProvider).isDirty,
        isTrue,
      );
    });

    test('draft edits recompute diagnostics and clear warning acknowledgements',
        () {
      final controller = BorderStudioDraftController()
        ..loadFromManifest(
          _manifest(
            records: <BorderBlueprintRecord>[
              _record(id: 'edge', name: 'Bord'),
            ],
          ),
        )
        ..setDiagnostics(
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.review_warning',
              severity: BorderDiagnosticSeverity.warning,
            ),
          ]),
        )
        ..acknowledgeWarningCode('border.publication.review_warning');

      expect(controller.state.diagnosticsAreCurrent, isTrue);
      expect(controller.state.canPublish, isTrue);

      controller.renameBlueprint('Bord retouche');

      expect(controller.state.diagnosticsAreCurrent, isFalse);
      expect(controller.state.acknowledgedWarningCodes, isEmpty);
      expect(controller.state.canPublish, isFalse);
    });

    test('recomputes authoring diagnostics automatically after draft edits',
        () {
      final controller = BorderStudioDraftController()
        ..loadFromManifest(
          _manifest(
            records: <BorderBlueprintRecord>[
              _record(id: 'edge', name: 'Bord'),
            ],
          ),
        );

      expect(controller.state.diagnosticsAreCurrent, isFalse);
      expect(controller.state.diagnostics.diagnostics, isEmpty);

      controller.replacePrimitives(<BorderPrimitiveDraft>[
        _primitive(
          id: 'missing-rock',
          role: BorderPrimitiveRole.structureLarge,
        ),
      ]);

      expect(controller.state.diagnosticsAreCurrent, isFalse);
      expect(
        controller.state.diagnostics.diagnostics.map((item) => item.code),
        contains('border.blueprint.source_element_missing'),
      );
      expect(controller.state.diagnostics.hasErrors, isTrue);

      controller.replacePrimitives(const <BorderPrimitiveDraft>[]);

      expect(controller.state.diagnosticsAreCurrent, isFalse);
      expect(
        controller.state.diagnostics.diagnostics.map((item) => item.code),
        isNot(contains('border.blueprint.source_element_missing')),
      );

      controller.setDiagnostics(const BorderDiagnosticsReport.empty());
      expect(controller.state.diagnosticsAreCurrent, isTrue);
      expect(controller.state.canPublish, isTrue);
    });

    test('clean manifest sync cannot turn a validation error into publishable',
        () {
      final manifest = _manifest(
        records: <BorderBlueprintRecord>[
          _record(id: 'edge', name: 'Bord'),
        ],
      );
      final controller = BorderStudioDraftController()
        ..loadFromManifest(manifest)
        ..setDiagnostics(
          BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
            _diagnostic(
              code: 'border.publication.blocking',
              severity: BorderDiagnosticSeverity.error,
            ),
          ]),
        );
      expect(controller.state.canPublish, isFalse);

      controller.synchronizeFromManifest(
        manifest.copyWith(globalProperties: <String, dynamic>{'other': true}),
      );

      expect(controller.state.diagnosticsAreCurrent, isFalse);
      expect(controller.state.canPublish, isFalse);
      expect(
        controller.state.diagnostics.diagnostics.map((item) => item.code),
        contains('border.publication.blocking'),
      );
    });
  });
}

ProjectManifest _manifest({
  List<BorderBlueprintRecord> records = const <BorderBlueprintRecord>[],
  List<BorderVisualSnapshot> visualSnapshots = const <BorderVisualSnapshot>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return ProjectManifest(
    name: 'Border test',
    version: ProjectVersion.v2,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map-1',
        name: 'Carte temoin',
        relativePath: 'maps/map-1.json',
      ),
    ],
    tilesets: const [],
    elements: elements,
    borderCatalog: ProjectBorderCatalog(
      records: records,
      visualSnapshots: visualSnapshots,
    ),
  );
}

ProjectElementEntry _element(String id) => ProjectElementEntry(
      id: id,
      name: id,
      tilesetId: 'tileset',
      categoryId: 'border',
      frames: const <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    );

BorderBlueprintRecord _record({
  required String id,
  required String name,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
  BorderGroundDraft? ground,
  BorderBlueprintRevision? latestPublished,
}) {
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: name,
        previewSeed: BorderSignedInt64.fromInt(1),
        template: template,
        primitives: primitives,
        defaults: _rules(),
        ground: ground,
        sortOrder: 0,
      ),
    ),
    latestPublished: latestPublished,
  );
}

BorderGenerationParams _rules({int depthRows = 1}) {
  return BorderGenerationParams(
    irregularityPermille: 250,
    detailDensityPermille: 500,
    variationPermille: 300,
    maxOverlapPx: 4,
    gapTolerancePx: 1,
    depthRows: depthRows,
  );
}

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
  String fingerprint = 'fingerprint-current',
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: 'element-$id',
    role: role,
    weight: 100,
    anchorPx: const BorderPixelPos(x: 4, y: 8),
    transforms: BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: const <int>[0],
    ),
    currentMetrics: _metrics(fingerprint),
  );
}

BorderPrimitiveAssetMetrics _metrics(String fingerprint) {
  return BorderPrimitiveAssetMetrics(
    assetFingerprint: fingerprint,
    pixelSize: const GridSize(width: 16, height: 16),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
    defaultAnchorPx: const BorderPixelPos(x: 4, y: 8),
    occupancyMaskRle: encodeBorderRleMask(
      List<bool>.filled(16 * 16, true),
    ),
  );
}

BorderBlueprintRevision _publishedRevision({required String name}) {
  return BorderBlueprintRevision(
    revision: 1,
    definition: BorderBlueprintPublishedDefinition(
      name: name,
      previewSeed: BorderSignedInt64.fromInt(1),
      template: BorderBlueprintTemplate.organicEdge,
      primitives: const <BorderPublishedPrimitive>[],
      defaults: _rules(),
      sortOrder: 0,
    ),
  );
}

BorderVisualSnapshot _snapshot(String hexDigit) {
  final fingerprint = List<String>.filled(64, hexDigit).join();
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$fingerprint',
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$hexDigit.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        durationMs: 100,
      ),
    ],
  );
}

BorderDiagnostic _diagnostic({
  required String code,
  required BorderDiagnosticSeverity severity,
}) {
  return BorderDiagnostic(
    code: code,
    severity: severity,
    phase: BorderDiagnosticPhase.publication,
    scope: BorderDiagnosticScope.blueprint,
    blueprintId: 'edge',
    suggestedAction: 'border.action.review',
  );
}
