import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_view_state.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui09_dialogue_harness.dart';
import 'support/ui09_runtime_fixture.dart';

class _VolumePort implements DialoguePort {
  _VolumePort(this.entry);
  final ProjectDialogueEntry entry;
  int reads = 0;
  @override
  Future<DialogueSourceSnapshot> load(String id) async {
    reads++;
    final source = StringBuffer();
    for (var n = 0; n < 40; n++) {
      source.writeln('title: Suite$n\n---');
      for (var line = 0; line < 5; line++) {
        source.writeln('Voyageur: Réplique $line de la suite $n.');
      }
      if (n < 25) {
        for (var choice = 0; choice < 2; choice++) {
          source.writeln(
            '-> Réponse $choice\n    <<jump Suite${n + choice + 1}>>',
          );
        }
      }
      source.writeln('===');
    }
    return DialogueSourceSnapshot(
      entry: entry.copyWith(defaultStartNode: 'Suite0', declaredOutcomes: []),
      source: source.toString(),
      revision: 'volume',
    );
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  }) => throw StateError('Consultation only');
}

void main() {
  testWidgets(
    'UI09 40 suites 200 lines 50 links navigation does not reread or compile',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = (await tester.runAsync(
        () => Ui09DialogueHarness.create(tester),
      ))!;
      final port = _VolumePort(
        h.narrative.project.dialogues.firstWhere((e) => e.id == ui09DialogueId),
      );
      final notifier = ChangeNotifier();
      final controller = DialogueWorkspaceController(
        h.narrative,
        port,
        changed: notifier.notifyListeners,
      );
      final views = DialogueViewStore();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        views.dispose();
        notifier.dispose();
        await tester.runAsync(h.dispose);
      });
      expect(await controller.open(ui09DialogueId), isTrue);
      expect(controller.active!.readOnlyReason, isNull);
      final snapshot = controller.active;
      final compilations = controller.compilationCount;
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: notifier,
              builder: (context, _) {
                builds++;
                return DialogueWorkspacePage(
                  controller: controller,
                  views: views,
                  onBack: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = views.forDialogue(ui09DialogueId);
      final before = state.viewport.pan;
      for (var i = 0; i < 8; i++) {
        state.viewport.translate(const Offset(20, 10));
        state.viewport.zoomAt(i.isEven ? .8 : .9, const Offset(250, 200));
        state.select(snapshot!.document.nodes[i].id);
        notifier.notifyListeners();
        await tester.pump();
      }
      expect(find.byType(DialogueGraphCanvas), findsOneWidget);
      expect(state.viewport.pan, isNot(before));
      expect(controller.active, same(snapshot));
      expect(controller.active!.dirty, isFalse);
      expect(port.reads, 1);
      expect(controller.compilationCount, compilations);
      expect(builds, 9);
      expect(tester.takeException(), isNull);
      debugPrint(
        'UI09 volume: 40 suites, 200 lines, 50 links; 8 gestures; 1 source read; '
        '0 additional compilations; 9 page builds (initial + 8 selection updates).',
      );
    },
  );
}
