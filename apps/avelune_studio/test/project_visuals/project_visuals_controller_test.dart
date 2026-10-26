import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

void main() {
  const session = ProjectSession(sessionId: 'test', name: 'Generic', directoryPath: '/fixture');
  test('first save and each inherited state use only the targeted port and reopen exactly', () async {
    final port = _Port();
    for (final value in [true, false, null]) {
      final owner = ProjectVisualsController(session: session, port: port);
      await owner.open();
      final patch = owner.preview.value.set(SpatialVisualParameter.depthOfFieldEnabled, value)
        .set(SpatialVisualParameter.timeMode, value == null ? null : value ? 'real' : 'cycle')
        .set(SpatialVisualParameter.weatherMode, value == null ? null : value ? 'automatic' : 'fixed')
        .set(SpatialVisualParameter.weatherSequence, value == null ? null : ['clear', 'rain']);
      owner.edit(patch);
      expect(owner.preview.value, patch);
      expect(port.reads, port.writes + 1);
      expect(await owner.save(), isTrue);
      expect(port.profile, patch);
      expect(owner.dirty, isFalse);
      expect(owner.saving, isFalse);
      owner.dispose();
    }
    expect(port.writes, 3);
    expect(port.reads, 3);
  });
  test('a slider gesture is one undo and failure preserves the draft', () async {
    final port = _Port();
    final owner = ProjectVisualsController(session: session, port: port);
    addTearDown(owner.dispose);
    await owner.open();
    owner.beginGesture();
    for (var index = 1; index <= 100; index++) {
      owner.edit(SpatialVisualPatch.fromJson({'depthOfFieldStrength': index / 100}));
    }
    owner.endGesture();
    owner.undo();
    expect(owner.preview.value.isEmpty, isTrue);
    expect(owner.canUndo, isFalse);
    owner.redo();
    expect(owner.preview.value.number(SpatialVisualParameter.depthOfFieldStrength), 1);
    port.fail = true;
    expect(await owner.save(), isFalse);
    expect(owner.dirty, isTrue);
    expect(owner.saving, isFalse);
    port.fail = false;
    expect(await owner.save(), isTrue);
    expect(owner.dirty, isFalse);
  });
  test('durability is not acknowledged while the write is pending', () async {
    final port = _Port()..pending = Completer<void>();
    final owner = ProjectVisualsController(session: session, port: port);
    addTearDown(owner.dispose);
    await owner.open();
    owner.edit(SpatialVisualPatch.fromJson({'pitchDegrees':34}));
    final saved = owner.save();
    expect(owner.saving, isTrue);
    expect(owner.dirty, isTrue);
    port.pending!.complete();
    expect(await saved, isTrue);
    expect(owner.saving, isFalse);
    expect(owner.dirty, isFalse);
  });
}
class _Port implements ProjectVisualsPort {
  SpatialVisualPatch profile = SpatialVisualPatch();
  int reads = 0, writes = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<ProjectVisualsState> loadVisuals(ProjectSession session, {ProjectMapEntry? map}) async {
    reads++;
    return ProjectVisualsState(profile: profile, revision: '$writes');
  }
  @override
  Future<ProjectVisualsState> saveVisuals(ProjectSession session, SpatialVisualPatch profile, String expectedRevision, {ProjectMapEntry? map}) async {
    if (fail) throw StateError('conflict');
    await pending?.future;
    if (expectedRevision != '$writes') throw StateError('stale');
    writes++;
    this.profile = profile;
    return ProjectVisualsState(profile: profile, revision: '$writes');
  }
  @override
  Future<ProjectVisualsState> undoVisuals(ProjectSession session, String receiptId, String expectedRevision, {ProjectMapEntry? map}) => throw UnimplementedError();
}
