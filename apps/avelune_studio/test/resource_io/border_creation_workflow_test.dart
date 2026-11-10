import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/resource_replacement_fixture.dart';

Future<ResourceReplacementFixture> _open({
  Future<void> Function()? beforeReconciliation,
  bool published = false,
}) async {
  final host = await ResourceReplacementFixture.create(
    beforeReconciliation: beforeReconciliation,
  );
  for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
    await host.navigation.accept(
      await host.fixture.resources.saveElement(
        host.fixture
            .element(host.item.id, id: id)
            .copyWith(
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
      ),
    );
  }
  if (published) {
    await host.navigation.accept(
      await host.fixture.resources.createBorder(
        const BorderCreationRequest(
          blueprintId: 'fence',
          name: 'Clôture',
          capElementId: 'cap',
          straightElementId: 'straight',
          cornerElementId: 'corner',
        ),
      ),
    );
  }
  return host;
}

BorderCreationDraft _draft(ResourceReplacementFixture host) {
  final project = host.workspace.project!;
  final draft = BorderCreationDraft(
    project: project,
    initialRecord: project.borderCatalog.records.firstOrNull,
    unavailableResourceIds: () => const {},
  )..name = 'Clôture révisée';
  for (final (role, id) in [
    ('lineCap', 'cap'),
    ('lineStraight', 'straight'),
    ('lineCorner', 'corner'),
  ]) {
    draft.assignRole(
      role,
      resourceCatalog(project).firstWhere((item) => item.element?.id == id),
    );
  }
  return draft;
}

BorderCreationWorkflow _workflow(
  ResourceReplacementFixture host,
  BorderCreationDraft draft, {
  bool Function()? isActive,
  Future<bool> Function()? confirmDiscard,
  Future<bool> Function(Map<String, int>)? confirmRepublication,
}) {
  final workflow = BorderCreationWorkflow(
    navigation: host.navigation,
    draft: draft,
    isActive: isActive ?? () => true,
    confirmDiscard: confirmDiscard ?? () async => false,
    confirmRepublication: confirmRepublication ?? (_) async => false,
  );
  addTearDown(workflow.dispose);
  return workflow;
}

void _trace(ResourceReplacementFixture host) {
  host.workspace.documents['route'] = EditableMapDocument(
    MapWorkspaceDocument(
      mapId: 'route',
      revision: 'r0',
      map: workspaceMap('route').copyWith(
        name: 'Route 30',
        layers: [
          BorderLayer(
            id: 'border',
            name: 'Clôtures',
            content: BorderLayerContent(
              features: [
                for (final id in ['a', 'b'])
                  BorderFeature(
                    id: id,
                    name: id,
                    blueprintId: 'fence',
                    seed: BorderSignedInt64.zero,
                    geometry: BorderRegionGeometry(
                      width: 1,
                      height: 1,
                      cells: [true],
                    ),
                    overrides: const [],
                    keepOutRegions: const [],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeping a dirty pattern preserves every input and refuses publication while closing', () async {
    final host = await _open();
    final draft = _draft(host);
    final consent = Completer<bool>();
    final workflow = _workflow(
      host,
      draft,
      confirmDiscard: () => consent.future,
    );
    final closing = workflow.requestClose();
    expect(workflow.working, isTrue);
    expect(await workflow.save(publish: false), isFalse);
    consent.complete(false);
    expect(await closing, isFalse);
    expect(draft.name, 'Clôture révisée');
    expect(draft.complete, isTrue);
    expect((await host.reopen()).borderCatalog.records, isEmpty);
  });

  test('discard consent belongs to the active editor only', () async {
    final host = await _open();
    final draft = _draft(host);
    var active = true;
    final consent = Completer<bool>();
    final workflow = _workflow(
      host,
      draft,
      isActive: () => active,
      confirmDiscard: () => consent.future,
    );
    final closing = workflow.requestClose();
    active = false;
    consent.complete(true);
    expect(await closing, isFalse);
    expect(draft.name, 'Clôture révisée');
  });

  test(
    'republishing traced borders requires the open map scope consent',
    () async {
      final host = await _open(published: true);
      _trace(host);
      final before = await host.fixture.manifestFile.readAsBytes();
      Map<String, int>? scope;
      final workflow = _workflow(
        host,
        _draft(host),
        confirmRepublication: (value) async {
          scope = value;
          return false;
        },
      );
      expect(await workflow.save(publish: true), isFalse);
      expect(scope, {'Route 30': 2});
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test('late republication consent cannot publish a replaced editor', () async {
    final host = await _open(published: true);
    _trace(host);
    var active = true;
    final consent = Completer<bool>();
    final before = await host.fixture.manifestFile.readAsBytes();
    final workflow = _workflow(
      host,
      _draft(host),
      isActive: () => active,
      confirmRepublication: (_) => consent.future,
    );
    final saving = workflow.save(publish: true);
    active = false;
    consent.complete(true);
    expect(await saving, isFalse);
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test(
    'publication without traced contours does not request scope consent',
    () async {
      final host = await _open(published: true);
      var confirmations = 0;
      final workflow = _workflow(
        host,
        _draft(host),
        confirmRepublication: (_) async {
          confirmations++;
          return false;
        },
      );
      expect(await workflow.save(publish: true), isTrue);
      expect(confirmations, 0);
      expect(
        (await host.reopen())
            .borderCatalog
            .records
            .single
            .latestPublished!
            .revision,
        2,
      );
    },
  );

  test('a saved partial draft keeps one owner and refreshes the expected record before retry', () async {
    final host = await _open();
    final draft = _draft(host)..warningCodes = ['unknown-warning'];
    final workflow = _workflow(host, draft);
    expect(await workflow.save(publish: true), isFalse);
    expect(draft.error, isNotNull);
    final partial = (await host.reopen()).borderCatalog.records.single;
    expect(partial.latestPublished, isNull);
    expect(draft.expectedRecord, partial);
    expect(draft.pendingId, partial.id);
    expect(host.navigation.borderEditorOwners[partial.id]!(), isTrue);
    final export = host.navigation.packBorderDraftOwners[partial.id]!();
    expect(export.request.name, 'Clôture révisée');
    expect(export.saving, isFalse);
    expect(await workflow.save(publish: true), isTrue);
    final records = (await host.reopen()).borderCatalog.records;
    expect(records, hasLength(1));
    expect(records.single.id, partial.id);
    expect(records.single.latestPublished!.revision, 1);
  });

  test('a committed partial publication is reconciled without a second publication', () async {
    var reconciliations = 0;
    final host = await _open(
      published: true,
      beforeReconciliation: () async {
        if (++reconciliations == 2) {
          throw StateError('reconciliation unavailable');
        }
      },
    );
    final workflow = _workflow(host, _draft(host));
    expect(await workflow.save(publish: true), isFalse);
    final disk = ProjectManifest.fromJson(
      jsonDecode(await host.fixture.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    expect(disk.borderCatalog.records.single.latestPublished!.revision, 2);
    expect(await workflow.save(publish: true), isTrue);
    expect(reconciliations, 2);
    expect(
      (await host.reopen())
          .borderCatalog
          .records
          .single
          .latestPublished!
          .revision,
      2,
    );
  });

  test(
    'saving blocks duplicate writes and close until its receipt settles',
    () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      final host = await _open(
        beforeReconciliation: () async {
          started.complete();
          await gate.future;
        },
      );
      final workflow = _workflow(host, _draft(host));
      final saving = workflow.save(publish: false);
      await started.future;
      final duplicate = await workflow.save(publish: false);
      final closing = await workflow.requestClose();
      gate.complete();
      expect(await saving, isTrue);
      expect(duplicate, isFalse);
      expect(closing, isFalse);
      expect((await host.reopen()).borderCatalog.records, hasLength(1));
    },
  );

  test(
    'disposing an old editor preserves a replacement owner registration',
    () async {
      final host = await _open(published: true);
      final old = _workflow(host, _draft(host));
      final replacement = _workflow(host, _draft(host));
      final owner = host.navigation.borderEditorOwners['fence'];
      final export = host.navigation.packBorderDraftOwners['fence'];
      old.dispose();
      expect(host.navigation.borderEditorOwners['fence'], same(owner));
      expect(host.navigation.packBorderDraftOwners['fence'], same(export));
      expect(await old.save(publish: false), isFalse);
      replacement.dispose();
      expect(host.navigation.borderEditorOwners, isEmpty);
      expect(host.navigation.packBorderDraftOwners, isEmpty);
    },
  );

  test('a late new-border receipt preserves the owners registered while publication settles', () async {
    var reconciliations = 0;
    final started = Completer<void>();
    final gate = Completer<void>();
    final host = await _open(
      beforeReconciliation: () async {
        if (++reconciliations == 2) {
          started.complete();
          await gate.future;
          throw StateError('publication settled after opening another editor');
        }
      },
    );
    final first = _workflow(host, _draft(host));
    final saving = first.save(publish: true);
    await started.future;
    final current = ProjectManifest.fromJson(
      jsonDecode(await host.fixture.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    final record = current.borderCatalog.records.single;
    final replacementDraft = BorderCreationDraft(
      project: current,
      initialRecord: record,
      unavailableResourceIds: () => const {},
    );
    _workflow(host, replacementDraft);
    final owner = host.navigation.borderEditorOwners[record.id];
    final export = host.navigation.packBorderDraftOwners[record.id];
    gate.complete();
    expect(await saving, isFalse);
    expect(host.navigation.borderEditorOwners[record.id], same(owner));
    expect(host.navigation.packBorderDraftOwners[record.id], same(export));
    expect(host.workspace.project!.borderCatalog.recordById(record.id), record);
  });
}
