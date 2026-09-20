import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import '../support/event_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBackendFixture f;
  late _DelayedPort port;
  late DialogueWorkspaceController c;
  setUp(() async {
    f = await EventBackendFixture.create();
    port = _DelayedPort(
      LocalDialogueAdapter(
        session: f.source.session,
        mapAdapter: f.source.maps,
      ),
    );
    c = DialogueWorkspaceController(f.narrative, port, changed: () {});
  });
  tearDown(() async {
    c.dispose();
    await f.dispose();
  });
  test(
    'late A read cannot replace B; cached selections perform no extra reads',
    () async {
      port.readGate = Completer();
      port.delayedId = 'station_welcome';
      final a = c.open('station_welcome');
      expect(await c.open('station_refusal'), true);
      final b = c.active;
      port.readGate!.complete();
      expect(await a, false);
      expect(c.active, same(b));
      expect(c.activeId, 'station_refusal');
      expect(c.busy, false);
      final reads = c.sourceReads;
      await c.open('station_refusal');
      expect(c.sourceReads, reads);
    },
  );
  test(
    'publication snapshot stays dirty for later edits and new source can be resaved',
    () async {
      await c.open('station_welcome');
      final line = c.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single
          .id;
      c.updateLine(line, text: 'Snapshot publié');
      port.writeGate = Completer();
      final save = c.save();
      await port.started.future;
      c.updateLine(line, text: 'Saisie pendant publication');
      expect(c.accessProblem('station_welcome'), isNotNull);
      port.writeGate!.complete();
      expect(await save, true, reason: c.error);
      expect(c.active!.dirty, true);
      expect(c.active!.source, contains('Saisie pendant'));
      final disk = await port.delegate.load('station_welcome');
      expect(disk.source, contains('Snapshot publié'));
      port.writeGate = null;
      expect(await c.save(), true, reason: c.error);
      expect(c.active!.dirty, false);
    },
  );
  test(
    'source conflict preserves unsaved work and file; explicit reload alone replaces draft',
    () async {
      await c.open('station_welcome');
      final entry = c.active!.entry;
      final line = c.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single
          .id;
      c.updateLine(line, text: 'Brouillon local');
      final file = File('${f.source.directory.path}/${entry.relativePath}');
      const external = 'title: Start\n---\nVersion externe\n===\n';
      await file.writeAsString(external);
      expect(await c.save(), false);
      expect(c.active!.dirty, true);
      expect(c.active!.source, contains('Brouillon local'));
      expect(await file.readAsString(), external);
      expect(await c.reload(), true);
      expect(c.active!.source, external);
      expect(c.active!.dirty, false);
    },
  );
  test(
    'missing and unsupported sources never materialize an editable blank recovery',
    () async {
      final entry = f.workspace.project!.dialogues.first;
      final file = File('${f.source.directory.path}/${entry.relativePath}');
      const source = 'title: Start\n---\n<<set secret>>\nBonjour\n===\n';
      await file.writeAsString(source);
      expect(await c.open(entry.id), true);
      expect(c.active!.readOnlyReason, isNotNull);
      expect(c.active!.source, source);
      expect(c.addNode('Ne pas créer'), isNull);
      expect(await c.save(), false);
      expect(await file.readAsString(), source);
      await file.delete();
      expect(await c.reload(), false);
      expect(c.active!.source, source);
      expect(await c.open('absent'), false);
      expect(c.active, isNull);
    },
  );
  test(
    'opaque source preamble is preserved and cannot be normalized away',
    () async {
      final entry = f.workspace.project!.dialogues.first;
      final file = File('${f.source.directory.path}/${entry.relativePath}');
      const source =
          '// note auteur à préserver\ntitle: Start\n---\nBonjour\n===\n';
      await file.writeAsString(source);
      expect(await c.open(entry.id), true);
      expect(c.active!.readOnlyReason, contains('fragments'));
      expect(c.active!.source, source);
      expect(c.addNode('Perte refusée'), isNull);
      expect(await file.readAsString(), source);
    },
  );
  test('late delete protects A against edits and never deselects B', () async {
    await c.create('À supprimer');
    final line = c.active!.document.nodes.single.steps
        .whereType<DeLineStep>()
        .single
        .id;
    c.updateLine(line, text: 'Source autonome');
    expect(await c.save(), true, reason: c.error);
    final id = c.activeId!;
    port.started = Completer();
    port.writeGate = Completer();
    final deletion = c.delete(id);
    await port.started.future;
    expect(c.updateLine(line, text: 'Ne pas perdre'), false);
    c.undo();
    expect(await c.open('station_refusal'), true);
    port.writeGate!.complete();
    expect(await deletion, true, reason: c.error);
    expect(c.activeId, 'station_refusal');
    expect(c.entries.any((e) => e.id == id), false);
  });
  test(
    'catalog deletion invalidates a clean full document without opening a namesake',
    () async {
      await c.open('station_welcome');
      final before = f.workspace.project!;
      f.workspace.acceptResources(
        before,
        before.copyWith(
          dialogues: before.dialogues
              .where((e) => e.id != 'station_welcome')
              .toList(),
        ),
      );
      expect(c.activeId, 'station_welcome');
      expect(c.active, isNull);
      expect(c.sourceForDialogue('station_welcome'), isNull);
      expect(c.entries.any((e) => e.id == 'station_welcome'), false);
    },
  );
}

class _DelayedPort implements DialoguePort {
  _DelayedPort(this.delegate);
  final DialoguePort delegate;
  Completer<void>? readGate, writeGate;
  var started = Completer<void>();
  String? delayedId;
  @override
  Future<DialogueSourceSnapshot> load(String id) async {
    if (id == delayedId) await readGate?.future;
    return delegate.load(id);
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  }) async {
    if (!started.isCompleted) started.complete();
    await writeGate?.future;
    return delegate.publish(id: id, base: base, entry: entry, source: source);
  }
}
