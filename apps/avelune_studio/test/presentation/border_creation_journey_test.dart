import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Studio publishes a border and offers it to the native map tool',
    () async {
      final host = await ResourceReplacementFixture.create();
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
      BorderCreationDraft draftFor([BorderBlueprintRecord? record]) =>
          BorderCreationDraft(
            project: host.workspace.project!,
            initialRecord: record,
            unavailableResourceIds: () => const {},
          );
      BorderCreationWorkflow workflowFor(
        BorderCreationDraft draft, {
        bool discard = false,
      }) {
        final workflow = BorderCreationWorkflow(
          navigation: host.navigation,
          draft: draft,
          isActive: () => true,
          confirmDiscard: () async => discard,
          confirmRepublication: (_) async => true,
        );
        addTearDown(workflow.dispose);
        return workflow;
      }

      final draft = draftFor()..name = 'Clôture du jardin';
      final workflow = workflowFor(draft);
      void assign(String role, String id) => draft.assignRole(
        role,
        resourceCatalog(host.workspace.project!)
            .firstWhere((item) => item.element?.id == id),
      );
      assign('lineCorner', 'corner');
      expect(draft.complete, isFalse);
      expect(await workflow.save(publish: true), isFalse);
      expect(
        (await LocalMapWorkspaceAdapter().loadProject(host.fixture.session))
            .borderCatalog
            .records,
        isEmpty,
      );
      assign('lineCap', 'cap');
      assign('lineStraight', 'straight');
      expect(draft.complete, isTrue);
      expect(await workflow.save(publish: true), isTrue, reason: draft.error);
      final record = host.workspace.project!.borderCatalog.records.single;
      final borderId = record.id;
      expect(record.latestPublished, isNotNull);
      expect(
        MapBorderEditingCommands.publishedLines(host.workspace.project!)
            .map((entry) => entry.id),
        contains(borderId),
      );
      workflow.dispose();

      final edited = draftFor(record)..name = 'Clôture du jardin ajustée';
      final editing = workflowFor(edited);
      final beforeExportRead = host.workspace.project!.toJson();
      final owner = host.navigation.packBorderDraftOwners[borderId]!;
      final export = owner();
      expect(export.dirty, isTrue);
      expect(export.saving, isFalse);
      expect(export.request.name, 'Clôture du jardin ajustée');
      expect(export.request.publish, isFalse);
      expect(
        () => export.request.primitiveModelIds.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => export.request.acceptedWarningCodes.clear(),
        throwsUnsupportedError,
      );
      expect(owner().signature, export.signature);
      expect(host.workspace.project!.toJson(), beforeExportRead);
      expect(await editing.requestClose(), isFalse);
      expect(edited.name, 'Clôture du jardin ajustée');
      expect(await editing.save(publish: false), isTrue, reason: edited.error);
      final pending = (await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      )).borderCatalog.recordById(borderId)!;
      expect(pending.latestPublished!.revision, 1);
      expect(pending.draft.definition.name, 'Clôture du jardin ajustée');
      editing.dispose();

      final republishing = workflowFor(draftFor(pending));
      expect(await republishing.save(publish: true), isTrue);
      expect(
        host.workspace.project!.borderCatalog
            .recordById(borderId)!
            .latestPublished!
            .revision,
        2,
      );
      republishing.dispose();
      final beforeDiscard = await host.fixture.manifestFile.readAsBytes();
      final abandoned = draftFor(
        host.workspace.project!.borderCatalog.recordById(borderId),
      )..name = 'Nom abandonné';
      final abandoning = workflowFor(abandoned, discard: true);
      expect(await abandoning.requestClose(), isTrue);
      abandoning.dispose();
      expect(await host.fixture.manifestFile.readAsBytes(), beforeDiscard);

      final document = host.workspace.active!;
      final tracing = MapBorderDrawingDraft.start(
        mapId: document.current.id,
        mapSize: document.current.size,
        blueprintId: borderId,
        origin: const GridPos(x: 1, y: 1),
        sourceMap: document.current,
        sourceProject: host.workspace.project!,
      ).addAngle(const GridPos(x: 3, y: 1)).addAngle(const GridPos(x: 3, y: 3));
      MapBorderEditingCommands(
        document,
        host.workspace.project!,
      ).finish(tracing);
      expect(document.current.layers.whereType<BorderLayer>(), isNotEmpty);
      expect(
        await host.workspace.save(document),
        isTrue,
        reason: document.error,
      );
      final reopened = await host.fixture.loadMap();
      final features = reopened.map.layers.whereType<BorderLayer>().expand(
        (layer) => layer.content.features,
      );
      expect(features.single.blueprintId, borderId);
      expect(features.single.name, 'Clôture du jardin ajustée');
    },
  );
}
