import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/application/authoring_api/battle_savings_authoring_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/new_game/project_battle_savings_configuration_sheet.dart';

void main() {
  ProjectManifest project() => ProjectManifest(
    name: 'Savings',
    maps: [],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(id: 'enabled', label: 'Mettre de côté'),
      NarrativeFactDefinition(
        id: 'balance',
        label: 'Réserve',
        initialValue: NarrativeValue.integer(0),
      ),
    ],
  );
  test(
    'section adoption preserves a newer local savings draft and its dirty flag',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initial = project();
      const persisted = ProjectBattleSavingsConfig(
        enabledFactId: 'enabled',
        balanceFactId: 'balance',
        percentage: 25,
        maximumBalance: 999999,
      );
      const concurrent = ProjectBattleSavingsConfig(
        enabledFactId: 'enabled',
        balanceFactId: 'balance',
        percentage: 50,
        maximumBalance: 999999,
      );
      notifier.state = notifier.state.copyWith(
        project: initial,
        projectRootPath: '/qa/savings',
      );
      notifier.applyInMemoryProjectManifest(
        initial.copyWith(battleSavings: concurrent),
      );
      expect(
        notifier.acceptCanonicalBattleSavingsConfiguration(
          persisted,
          projectRootPath: '/qa/savings',
          previousConfiguration: null,
        ),
        isFalse,
      );
      expect(notifier.state.project!.battleSavings, concurrent);
      expect(notifier.state.isProjectDirty, isTrue);
    },
  );
  for (final preexistingDirty in [false, true]) {
    testWidgets(
      'real savings sheet retains project debt preexisting=$preexistingDirty and concurrent edits',
      (tester) async {
        final initial = project().copyWith(
          battleSavings: const ProjectBattleSavingsConfig(
            enabledFactId: 'enabled',
            balanceFactId: 'balance',
            percentage: 25,
            maximumBalance: 999999,
          ),
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        notifier.state = notifier.state.copyWith(
          project: initial,
          projectRootPath: '/qa/savings',
        );
        if (preexistingDirty) {
          notifier.applyInMemoryProjectManifest(
            initial.copyWith(name: 'Pending name'),
          );
        }
        final persisted = Completer<ProjectManifest>();
        ProjectBattleSavingsConfig? submitted;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: PokeMapTheme.dark(),
              home: Scaffold(
                body: ProjectBattleSavingsConfigurationSheet(
                  saveConfiguration: (root, current, configuration) {
                    submitted = configuration;
                    return persisted.future;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField).first, '26');
        await tester.ensureVisible(
          find.byKey(const ValueKey('battle-savings-save')),
        );
        await tester.tap(find.byKey(const ValueKey('battle-savings-save')));
        await tester.pump();
        expect(submitted!.percentage, 26);
        notifier.applyInMemoryProjectManifest(
          notifier.state.project!.copyWith(globalProperties: {'pending': true}),
        );
        persisted.complete(initial.copyWith(battleSavings: submitted));
        await tester.pumpAndSettle();
        expect(notifier.state.project!.battleSavings!.percentage, 26);
        expect(
          notifier.state.project!.name,
          preexistingDirty ? 'Pending name' : initial.name,
        );
        expect(notifier.state.project!.globalProperties, {'pending': true});
        expect(notifier.state.isProjectDirty, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test(
    'editor canonical gateway persists first and repeated saves without foreign map reads',
    () async {
      final taskRoot = Directory(
        '/Users/karim/Library/Caches/AveluneQA/battle-savings',
      );
      await taskRoot.create(recursive: true);
      final root = await taskRoot.createTemp('editor-');
      addTearDown(() => root.delete(recursive: true));
      final initial = project();
      final raw = {
        ...initial.toJson(),
        'maps': [
          for (var i = 0; i < 900; i++)
            {
              'id': 'foreign_$i',
              'name': 'Foreign',
              'relativePath': 'missing/$i.json',
            },
        ],
        'unknownFuture': {'preserve': true},
      };
      final file = File('${root.path}/project.json');
      await file.writeAsString(jsonEncode(raw));
      var current = initial;
      final reader = _CountingReader();
      final gateway = BattleSavingsAuthoringGateway(fileReader: reader);
      int? firstReadCount;
      for (var i = 0; i < 2; i++) {
        reader.reads.clear();
        final watch = Stopwatch()..start();
        current = await gateway.save(
          root.path,
          project: current,
          configuration: ProjectBattleSavingsConfig(
            enabledFactId: 'enabled',
            balanceFactId: 'balance',
            percentage: 25 + i,
            maximumBalance: 999999,
          ),
        );
        watch.stop();
        expect(reader.reads.every((path) => path == 'project.json'), isTrue);
        if (i == 0) firstReadCount = reader.reads.length;
        expect(reader.reads.length, firstReadCount);
        debugPrint('Savings canonical project reads: ${reader.reads.length}');
        debugPrint(
          'Savings canonical editor ${i == 0 ? 'first' : 'repeat'}: ${watch.elapsedMilliseconds}ms',
        );
        final saved = jsonDecode(await file.readAsString()) as Map;
        expect((saved['battleSavings'] as Map)['percentage'], 25 + i);
        expect(saved['maps'], raw['maps']);
        expect(saved['unknownFuture'], raw['unknownFuture']);
      }
      current = await gateway.save(
        root.path,
        project: current,
        configuration: null,
      );
      expect(current.battleSavings, isNull);
      expect(
        (jsonDecode(await file.readAsString()) as Map).containsKey(
          'battleSavings',
        ),
        isFalse,
      );
    },
  );
  testWidgets(
    'guided savings form uses typed Fact labels and can disable policy',
    (tester) async {
      ProjectBattleSavingsConfig? saved;
      final initial = project().copyWith(
        battleSavings: const ProjectBattleSavingsConfig(
          enabledFactId: 'enabled',
          balanceFactId: 'balance',
          percentage: 25,
          maximumBalance: 999999,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: ProjectBattleSavingsConfigurationForm(
              project: initial,
              onSave: (value) async {
                saved = value;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('battle-savings-save')));
      await tester.pumpAndSettle();
      expect(saved, initial.battleSavings);
      await tester.tap(
        find.byKey(const ValueKey('battle-savings-enabled-picker')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aucune épargne').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-savings-save')));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _CountingReader implements ProjectFileReader {
  final reads = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    reads.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
