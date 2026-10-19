import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/border_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/border_pattern_panel.dart';
import 'package:avelune_studio/presentation/features/resources/border_source_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  testWidgets(
    'a new straight border sends all six configured steps from the guided editor',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = spatialBorderVariantProject();
      final workspace = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      )..project = project;
      final port = _SequencePort();
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: port,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      addTearDown(workspace.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: BorderCreationDialog(
            navigation: navigation,
            project: project,
            visuals: WorkspaceTestVisuals(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('border-name')),
        'Motif créé',
      );
      tester
          .widget<StudioToggleRow>(
            find.byKey(const ValueKey('border-straight-only')),
          )
          .onChanged!(true);
      await tester.pumpAndSettle();
      final model = resourceCatalog(project)
          .firstWhere((item) => item.id == 'oak' && item.model3d != null);
      tester
          .widget<BorderPatternPanel>(find.byType(BorderPatternPanel))
          .onAssign('lineStraight', model);
      tester
          .widget<BorderPatternPanel>(find.byType(BorderPatternPanel))
          .onAssign('lineCap', model);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudioCommitField>(
              find.byKey(const ValueKey('border-sequence-length')),
            )
            .tryCommit!('6'),
        isTrue,
      );
      await tester.pumpAndSettle();
      tester
          .widget<BorderSourcePanel>(find.byType(BorderSourcePanel))
          .onActive(
            resourceCatalog(project).firstWhere(
              (item) => item.id == 'replacement' && item.model3d != null,
            ),
          );
      await tester.pumpAndSettle();
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('border-sequence-model-lineStraight')),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      tester
          .widget<StudioButton>(
            find.byKey(
              const ValueKey('border-sequence-model-lineStraight_step_5'),
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('border-publish')));
      await tester.pumpAndSettle();
      expect(port.request!.sequenceLength, 6);
      expect(port.request!.straightModelId, 'oak');
      expect(port.request!.capModelId, 'oak');
      expect(port.request!.primitiveModelIds['lineStraight'], 'replacement');
      expect(
        port.request!.primitiveModelIds['lineStraight_step_5'],
        'replacement',
      );
      expect(port.request!.publish, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final incomplete in [false, true]) {
    testWidgets(
      incomplete
          ? 'an incomplete sequence explains why publication is disabled'
          : 'six sequence steps remain editable and survive export draft capture',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final base = spatialBorderVariantProject();
        final raw = encodeBorderBlueprintRecordJson(
          base.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        );
        final definition = (raw['draft'] as Map)['definition'] as Map;
        definition['sequenceLength'] = 6;
        final primitives = (definition['primitives'] as List).cast<Map>();
        definition['primitives'] = [
          for (var step = 0; step < (incomplete ? 5 : 6); step++)
            for (final p in primitives)
              {...p, 'id': '${p['id']}-$step', 'sequenceIndex': step},
        ];
        final record = decodeBorderBlueprintRecordJson(
          raw,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        );
        final project = base.copyWith(
          borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [record],
          ),
        );
        final workspace = MapWorkspaceController(
          workspaceSession,
          WorkspaceMemoryPort(),
        )..project = project;
        final navigation = ResourceNavigation(
          workspace: workspace,
          port: _SequencePort(),
          visuals: WorkspaceTestVisuals(),
          onUse: (_) {},
        );
        addTearDown(navigation.dispose);
        addTearDown(workspace.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: BorderCreationDialog(
              navigation: navigation,
              project: project,
              visuals: WorkspaceTestVisuals(),
              initialRecord: record,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('border-sequence-length')),
          findsOneWidget,
        );
        expect(find.text('Étape 6 / 6'), findsOneWidget);
        if (incomplete) {
          expect(
            find.text(
              'Chaque étape doit contenir un corps et des extrémités avant publication.',
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<StudioButton>(
                  find.byKey(const ValueKey('border-publish')),
                )
                .onPressed,
            isNull,
          );
          expect(tester.takeException(), isNull);
          return;
        }
        tester
            .widget<BorderSourcePanel>(find.byType(BorderSourcePanel))
            .onActive(
              resourceCatalog(project).firstWhere(
                (item) => item.id == 'replacement' && item.model3d != null,
              ),
            );
        await tester.pumpAndSettle();
        final selector = tester.widget<StudioButton>(
          find.byKey(const ValueKey('border-sequence-model-south-cap-5')),
        );
        selector.onPressed!();
        await tester.pumpAndSettle();
        final captured = navigation.packBorderDraftOwners['fence']!();
        expect(
          captured.request.primitiveModelIds['south-cap-5'],
          'replacement',
        );
        expect((jsonDecode(captured.signature) as Map)['sequenceLength'], 6);
        final length = tester.widget<StudioCommitField>(
          find.byKey(const ValueKey('border-sequence-length')),
        );
        expect(length.tryCommit!('0'), isFalse);
        expect(length.tryCommit!('3'), isTrue);
        await tester.pumpAndSettle();
        expect(
          (jsonDecode(navigation.packBorderDraftOwners['fence']!().signature)
              as Map)['sequenceLength'],
          3,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _SequencePort implements ResourcePort {
  BorderCreationRequest? request;
  @override
  Future<ResourceMutationReceipt> createBorder(
    BorderCreationRequest value,
  ) async {
    request = value;
    throw const ResourceFailure('Requête reçue par le port de test.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
