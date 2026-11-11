import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/ledge_border_metadata_test.dart'
    show NativeLedgeResourceFixture;
import '../support/map_workspace_fixture.dart';

Future<_Editor> _open({
  ProjectManifest Function(ProjectManifest)? changeProject,
  bool persistProject = true,
  bool partialOnce = false,
  bool animatedFirst = false,
}) async {
  final fixture = await NativeLedgeResourceFixture.create(
    animatedFirst: animatedFirst,
  );
  final project = changeProject?.call(fixture.project) ?? fixture.project;
  if (changeProject != null && persistProject) {
    await fixture.base.manifestFile.writeAsString(jsonEncode(project.toJson()));
    await fixture.maps.loadProject(fixture.session);
  }
  final visuals = WorkspaceTestVisuals();
  final controller = MapWorkspaceController(fixture.session, fixture.maps)
    ..project = project;
  final port = _NativePort(fixture, partialOnce: partialOnce);
  final navigation = ResourceNavigation(
    workspace: controller,
    port: port,
    visuals: visuals,
    onUse: (_) {},
  );
  final draft = BorderCreationDraft(
    project: project,
    initialRecord: project.borderCatalog.records.single,
    unavailableResourceIds: () => {
      for (final diagnostic in visuals.diagnostics) diagnostic.resourceId,
    },
  );
  final workflow = BorderCreationWorkflow(
    navigation: navigation,
    draft: draft,
    isActive: () => true,
    confirmDiscard: () async => false,
    confirmRepublication: (_) async => true,
  );
  addTearDown(() async {
    workflow.dispose();
    navigation.dispose();
    controller.dispose();
    visuals.dispose();
    await fixture.dispose();
  });
  return _Editor(fixture, navigation, port, project, draft, workflow);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native ledge publication does not require generic pattern roles',
    () async {
      final editor = await _open();
      expect(editor.draft.nativeLedge, isTrue);
      expect(editor.draft.complete, isTrue);
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      expect(await editor.workflow.save(publish: true), isTrue);
      expect(editor.port.requests, hasLength(1));
      expect(editor.port.requests.single.expectedRecord, editor.fixture.record);
      expect(editor.port.requests.single.capElementId, isNull);
      expect(editor.port.requests.single.straightElementId, isNull);
      expect(editor.port.requests.single.cornerElementId, isNull);
      expect(
        editor
            .navigation
            .workspace
            .project!
            .borderCatalog
            .records
            .single
            .latestPublished!
            .revision,
        2,
      );
    },
  );

  test(
    'native variants retain their source identity orientation and anchor',
    () async {
      final editor = await _open();
      final record = editor.draft.expectedRecord!;
      expect(record.draft.definition.primitives, hasLength(3));
      for (final primitive in record.draft.definition.primitives) {
        final source = editor.project.elements.singleWhere(
          (element) => element.id == primitive.sourceElementId,
        );
        expect(source.frames, isNotEmpty);
        expect(primitive.authoredOrientation, BorderPrimitiveOrientation.south);
        expect(primitive.anchorPx, const BorderPixelPos(x: 16, y: 31));
        expect(primitive.transforms.allowedQuarterTurns, [0]);
        expect(primitive.transforms.allowFlipX, isFalse);
      }
      expect(editor.draft.jumpSide, BorderLineSide.primary);
      expect(BorderLineSide.values, [
        BorderLineSide.primary,
        BorderLineSide.inverted,
      ]);
      expect(
        editor.draft.buildRequest(publish: true).expectedRecord,
        editor.fixture.record,
      );
    },
  );

  test(
    'native name and jump side publish without replacing any source primitive',
    () async {
      final editor = await _open();
      editor.draft.name = 'Rebords renommés';
      editor.draft.jumpSide = BorderLineSide.inverted;
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isTrue);
      expect(await editor.workflow.save(publish: true), isTrue);
      final request = editor.port.requests.single;
      expect(request.jumpSide, BorderLineSide.inverted);
      expect(request.expectedRecord, editor.fixture.record);
      expect(request.primitiveModelIds, isEmpty);
      expect(request.primitiveModelSettings, isEmpty);
      expect(request.straightOnly, isNull);
      final saved =
          editor.navigation.workspace.project!.borderCatalog.records.single;
      expect(saved.latestPublished!.definition.name, 'Rebords renommés');
      expect(
        saved.draft.definition.primitives,
        editor.fixture.record.draft.definition.primitives,
      );
      expect(
        saved.latestPublished!.definition.primitives,
        editor.fixture.record.latestPublished!.definition.primitives,
      );
      expect(
        saved.latestPublished!.definition.jumpBehavior!.side,
        BorderLineSide.inverted,
      );
      expect(saved.latestPublished!.definition.jumpBehavior!.durationMs, 500);
      expect(saved.latestPublished!.definition.jumpBehavior!.peakHeightPx, 24);
      expect(
        await editor.fixture.mapFile.readAsBytes(),
        editor.fixture.mapBefore,
      );
      for (final entry in editor.fixture.mediaBefore.entries) {
        expect(
          await File('${editor.fixture.root.path}/${entry.key}').readAsBytes(),
          entry.value,
        );
      }
      final reopened = await editor.fixture.maps.loadProject(
        editor.fixture.session,
      );
      expect(reopened.borderCatalog.records.single, saved);
    },
  );

  test(
    'native animation frames survive name and jump side publication',
    () async {
      final editor = await _open(animatedFirst: true);
      final source = editor.project.elements.first;
      expect(source.frames, hasLength(2));
      editor.draft.name = 'Rebord animé renommé';
      editor.draft.jumpSide = BorderLineSide.inverted;
      expect(await editor.workflow.save(publish: true), isTrue);
      final saved = editor.navigation.workspace.project!;
      expect(saved.elements, editor.project.elements);
      expect(
        saved
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition
            .primitives,
        editor.fixture.record.latestPublished!.definition.primitives,
      );
      expect(
        saved.borderCatalog.visualSnapshots,
        unorderedEquals(editor.project.borderCatalog.visualSnapshots),
      );
      final reopened = await editor.fixture.maps.loadProject(
        editor.fixture.session,
      );
      expect(reopened.elements, saved.elements);
      for (final entry in editor.fixture.mediaBefore.entries) {
        expect(
          await File('${editor.fixture.root.path}/${entry.key}').readAsBytes(),
          entry.value,
        );
      }
      expect(
        await editor.fixture.mapFile.readAsBytes(),
        editor.fixture.mapBefore,
      );
    },
  );

  test('stale native editor cannot overwrite a newer native draft', () async {
    final editor = await _open();
    final changed = await editor.fixture.resources.createBorder(
      BorderCreationRequest(
        blueprintId: editor.fixture.record.id,
        name: 'Nom écrit ailleurs',
        expectedRecord: editor.fixture.record,
        publish: false,
      ),
    );
    final manifestBefore = await editor.fixture.base.manifestFile.readAsBytes();
    editor.draft.jumpSide = BorderLineSide.inverted;
    expect(await editor.workflow.save(publish: true), isFalse);
    expect(editor.port.requests.single.expectedRecord, editor.fixture.record);
    expect(editor.draft.error, contains('changé depuis l’ouverture'));
    expect(editor.navigation.borderEditorOwners['native-ledges'], isNotNull);
    expect(
      await editor.fixture.base.manifestFile.readAsBytes(),
      manifestBefore,
    );
    final reopened = await editor.fixture.maps.loadProject(
      editor.fixture.session,
    );
    expect(reopened.borderCatalog, changed.manifest.borderCatalog);
    expect(
      await editor.fixture.mapFile.readAsBytes(),
      editor.fixture.mapBefore,
    );
  });

  test(
    'a native ledge without jump stays without jump after publication',
    () async {
      final editor = await _open(
        changeProject: (project) {
          final json = encodeBorderBlueprintRecordJson(
            project.borderCatalog.records.single,
            formatVersion: 7,
          );
          ((json['draft'] as Map)['definition'] as Map).remove('jumpBehavior');
          ((json['latestPublished'] as Map)['definition'] as Map).remove(
            'jumpBehavior',
          );
          return project.copyWith(
            borderCatalog: ProjectBorderCatalog(
              formatVersion: 7,
              records: [
                decodeBorderBlueprintRecordJson(json, formatVersion: 7),
              ],
              visualSnapshots: project.borderCatalog.visualSnapshots,
            ),
          );
        },
      );
      expect(editor.draft.jumpSide, isNull);
      expect(editor.draft.complete, isTrue);
      expect(await editor.workflow.save(publish: true), isTrue);
      expect(editor.port.requests.single.jumpSide, isNull);
      expect(
        editor
            .navigation
            .workspace
            .project!
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition
            .jumpBehavior,
        isNull,
      );
    },
  );

  test('missing native source refuses publication without a write', () async {
    final editor = await _open(
      persistProject: false,
      changeProject: (project) =>
          project.copyWith(elements: project.elements.skip(1).toList()),
    );
    expect(
      nativeLedgeSourcesAvailable(
        editor.draft.expectedRecord!,
        editor.project,
        unavailableResourceIds: const {},
      ),
      isFalse,
    );
    expect(editor.draft.complete, isFalse);
    expect(await editor.workflow.save(publish: true), isFalse);
    expect(editor.port.requests, isEmpty);
  });

  test(
    'jump side alone owns a dirty draft and can be restored without changes',
    () async {
      final editor = await _open();
      editor.draft.jumpSide = BorderLineSide.inverted;
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isTrue);
      expect(await editor.workflow.requestClose(), isFalse);
      expect(editor.draft.jumpSide, BorderLineSide.inverted);
      expect(editor.port.requests, isEmpty);
      editor.draft.jumpSide = BorderLineSide.primary;
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      expect(editor.port.requests, isEmpty);
    },
  );

  test(
    'a partial native receipt refreshes the expected record before retry',
    () async {
      final editor = await _open(partialOnce: true);
      editor.draft.name = 'Rebords repris';
      editor.draft.jumpSide = BorderLineSide.inverted;
      expect(await editor.workflow.save(publish: true), isFalse);
      expect(editor.draft.error, 'Publication interrompue après le brouillon.');
      final partialRecord =
          editor.navigation.workspace.project!.borderCatalog.records.single;
      expect(partialRecord, isNot(editor.fixture.record));
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      expect(await editor.workflow.save(publish: true), isTrue);
      expect(editor.port.requests, hasLength(2));
      expect(editor.port.requests[0].expectedRecord, editor.fixture.record);
      expect(editor.port.requests[1].expectedRecord, partialRecord);
      expect(
        editor
            .navigation
            .workspace
            .project!
            .borderCatalog
            .records
            .single
            .latestPublished!
            .revision,
        2,
      );
    },
  );
}

final class _Editor {
  _Editor(
    this.fixture,
    this.navigation,
    this.port,
    this.project,
    this.draft,
    this.workflow,
  );
  final NativeLedgeResourceFixture fixture;
  final ResourceNavigation navigation;
  final _NativePort port;
  final ProjectManifest project;
  final BorderCreationDraft draft;
  final BorderCreationWorkflow workflow;
}

final class _NativePort implements ResourcePort {
  _NativePort(this.fixture, {this.partialOnce = false});
  final NativeLedgeResourceFixture fixture;
  bool partialOnce;
  final requests = <BorderCreationRequest>[];

  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest request,
  ) async {
    requests.add(request);
    if (partialOnce) {
      partialOnce = false;
      final partial = await fixture.resources.createBorder(
        BorderCreationRequest(
          name: request.name,
          blueprintId: request.blueprintId,
          jumpSide: request.jumpSide,
          expectedRecord: request.expectedRecord,
          publish: false,
        ),
      );
      throw ResourceFailure(
        'Publication interrompue après le brouillon.',
        partialReceipt: partial,
        borderId: request.blueprintId,
      );
    }
    return fixture.resources.createBorder(request);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
