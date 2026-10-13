import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/border_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:avelune_studio/presentation/features/resources/border_source_panel.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/ledge_border_metadata_test.dart'
    show NativeLedgeResourceFixture;
import '../support/map_workspace_fixture.dart';

Future<_Editor> _open(
  WidgetTester tester, {
  ProjectManifest Function(ProjectManifest)? changeProject,
  bool persistProject = true,
  bool partialOnce = false,
  bool animatedFirst = false,
}) async {
  tester.view.physicalSize = const Size(1320, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = (await tester.runAsync(
    () => NativeLedgeResourceFixture.create(animatedFirst: animatedFirst),
  ))!;
  final project = changeProject?.call(fixture.project) ?? fixture.project;
  if (changeProject != null && persistProject) {
    await tester.runAsync(() async {
      await fixture.base.manifestFile.writeAsString(
        jsonEncode(project.toJson()),
      );
      await fixture.maps.loadProject(fixture.session);
    });
  }
  final visuals = _NativeVisuals();
  final controller = MapWorkspaceController(fixture.session, fixture.maps)
    ..project = project;
  final port = _NativePort(fixture, tester, partialOnce: partialOnce);
  final navigation = ResourceNavigation(
    workspace: controller,
    port: port,
    visuals: visuals,
    onUse: (_) {},
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    navigation.dispose();
    controller.dispose();
    await tester.runAsync(fixture.dispose);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => StudioButton(
            label: 'Modifier',
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => BorderCreationDialog(
                navigation: navigation,
                project: project,
                visuals: visuals,
                initialRecord: project.borderCatalog.records.single,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Modifier'));
  await tester.pumpAndSettle();
  return _Editor(fixture, navigation, port, visuals, project);
}

Future<void> _publish(WidgetTester tester, _Editor editor) async {
  await tester.tap(find.byKey(const ValueKey('border-publish')));
  if (editor.port.pending != null) await editor.port.pending;
  await tester.pumpAndSettle();
}

Future<void> _chooseSide(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('native-ledge-jump-side')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'native ledge publication is enabled without generic pattern roles',
    (tester) async {
      final editor = await _open(tester);
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('border-publish')))
            .onPressed,
        isNotNull,
      );
      expect(find.byType(BorderPatternPanel), findsNothing);
      expect(find.byType(BorderSourcePanel), findsNothing);
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      await _publish(tester, editor);
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

  testWidgets(
    'all native variants preview their unchanged source orientation and anchor',
    (tester) async {
      final editor = await _open(tester);
      for (final primitive
          in editor.fixture.record.draft.definition.primitives) {
        expect(
          find.byKey(ValueKey('native-ledge-preview-${primitive.id}')),
          findsOneWidget,
        );
        final source = editor.project.elements.singleWhere(
          (e) => e.id == primitive.sourceElementId,
        );
        expect(editor.visuals.previewed, contains(source));
      }
      expect(find.byType(RotatedBox), findsNothing);
      expect(find.text('vers le sud'), findsNWidgets(3));
      final side = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('native-ledge-jump-side')),
      );
      expect(side.value, BorderLineSide.primary.name);
      expect(side.options.keys, unorderedEquals(['primary', 'inverted']));
    },
  );

  testWidgets(
    'native name and jump side publish without replacing any source primitive',
    (tester) async {
      final editor = await _open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('border-name')),
        'Rebords renommés',
      );
      await _chooseSide(tester, 'Côté opposé');
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isTrue);
      await _publish(tester, editor);
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
      await tester.runAsync(() async {
        expect(
          await editor.fixture.mapFile.readAsBytes(),
          editor.fixture.mapBefore,
        );
        for (final entry in editor.fixture.mediaBefore.entries) {
          expect(
            await File('${editor.fixture.root.path}/${entry.key}')
                .readAsBytes(),
            entry.value,
          );
        }
        final reopened = await editor.fixture.maps.loadProject(
          editor.fixture.session,
        );
        expect(reopened.borderCatalog.records.single, saved);
      });
    },
  );

  testWidgets(
    'native animation frames survive name and jump side publication',
    (tester) async {
      final editor = await _open(tester, animatedFirst: true);
      final source = editor.project.elements.first;
      expect(source.frames, hasLength(2));
      expect(editor.visuals.previewed, contains(source));
      await tester.enterText(
        find.byKey(const ValueKey('border-name')),
        'Rebord animé renommé',
      );
      await _chooseSide(tester, 'Côté opposé');
      await _publish(tester, editor);
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
      await tester.runAsync(() async {
        final reopened = await editor.fixture.maps.loadProject(
          editor.fixture.session,
        );
        expect(reopened.elements, saved.elements);
        for (final entry in editor.fixture.mediaBefore.entries) {
          expect(
            await File('${editor.fixture.root.path}/${entry.key}')
                .readAsBytes(),
            entry.value,
          );
        }
        expect(
          await editor.fixture.mapFile.readAsBytes(),
          editor.fixture.mapBefore,
        );
      });
    },
  );

  testWidgets('stale native editor cannot overwrite a newer native draft', (
    tester,
  ) async {
    final editor = await _open(tester);
    final changed = await tester.runAsync(() async {
      return editor.fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: editor.fixture.record.id,
          name: 'Nom écrit ailleurs',
          expectedRecord: editor.fixture.record,
          publish: false,
        ),
      );
    });
    final manifestBefore = (await tester.runAsync(
      editor.fixture.base.manifestFile.readAsBytes,
    ))!;
    await _chooseSide(tester, 'Côté opposé');
    await _publish(tester, editor);
    expect(editor.port.requests.single.expectedRecord, editor.fixture.record);
    expect(find.textContaining('changé depuis l’ouverture'), findsOneWidget);
    expect(find.byType(BorderCreationDialog), findsOneWidget);
    await tester.runAsync(() async {
      expect(
        await editor.fixture.base.manifestFile.readAsBytes(),
        manifestBefore,
      );
      final reopened = await editor.fixture.maps.loadProject(
        editor.fixture.session,
      );
      expect(reopened.borderCatalog, changed!.manifest.borderCatalog);
      expect(
        await editor.fixture.mapFile.readAsBytes(),
        editor.fixture.mapBefore,
      );
    });
  });

  testWidgets(
    'a native ledge without jump stays without jump after publication',
    (tester) async {
      final editor = await _open(
        tester,
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
      expect(
        find.byKey(const ValueKey('native-ledge-jump-side')),
        findsNothing,
      );
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('border-publish')))
            .onPressed,
        isNotNull,
      );
      await _publish(tester, editor);
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

  testWidgets(
    'missing native source disables publication with a visible reason',
    (tester) async {
      final editor = await _open(
        tester,
        persistProject: false,
        changeProject: (project) =>
            project.copyWith(elements: project.elements.skip(1).toList()),
      );
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('border-publish')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('source indisponible'), findsOneWidget);
      expect(editor.port.requests, isEmpty);
    },
  );

  testWidgets(
    'jump side alone owns a dirty draft and can be restored without changes',
    (tester) async {
      final editor = await _open(tester);
      await _chooseSide(tester, 'Côté opposé');
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isTrue);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Abandonner les modifications de la bordure ?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Conserver'));
      await tester.pumpAndSettle();
      await _chooseSide(tester, 'Côté principal');
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      expect(editor.port.requests, isEmpty);
    },
  );

  testWidgets(
    'a partial native receipt refreshes the expected record before retry',
    (tester) async {
      final editor = await _open(tester, partialOnce: true);
      await tester.enterText(
        find.byKey(const ValueKey('border-name')),
        'Rebords repris',
      );
      await _chooseSide(tester, 'Côté opposé');
      await _publish(tester, editor);
      expect(
        find.text('Publication interrompue après le brouillon.'),
        findsOneWidget,
      );
      final partialRecord =
          editor.navigation.workspace.project!.borderCatalog.records.single;
      expect(partialRecord, isNot(editor.fixture.record));
      expect(editor.navigation.borderEditorOwners['native-ledges']!(), isFalse);
      await _publish(tester, editor);
      expect(editor.port.requests, hasLength(2));
      expect(editor.port.requests[0].expectedRecord, editor.fixture.record);
      expect(editor.port.requests[1].expectedRecord, partialRecord);
      expect(find.byType(BorderCreationDialog), findsNothing);
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
  _Editor(this.fixture, this.navigation, this.port, this.visuals, this.project);
  final NativeLedgeResourceFixture fixture;
  final ResourceNavigation navigation;
  final _NativePort port;
  final _NativeVisuals visuals;
  final ProjectManifest project;
}

final class _NativeVisuals extends WorkspaceTestVisuals {
  final previewed = <ProjectElementEntry>[];
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) {
    previewed.add(element);
    return SizedBox.square(dimension: size);
  }
}

final class _NativePort implements ResourcePort {
  _NativePort(this.fixture, this.tester, {this.partialOnce = false});
  final NativeLedgeResourceFixture fixture;
  final WidgetTester tester;
  bool partialOnce;
  final requests = <BorderCreationRequest>[];
  Future<void>? pending;

  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest request,
  ) async {
    requests.add(request);
    ResourceMutationReceipt? result;
    Object? failure;
    StackTrace? trace;
    final operation = tester.runAsync(() async {
      try {
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
        result = await fixture.resources.createBorder(request);
      } catch (error, stack) {
        failure = error;
        trace = stack;
      }
    });
    pending = operation;
    await operation;
    pending = null;
    if (failure != null) Error.throwWithStackTrace(failure!, trace!);
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
