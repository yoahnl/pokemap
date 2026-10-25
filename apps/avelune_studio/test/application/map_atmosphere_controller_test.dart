import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('edits stay local and first save persists only the atmosphere draft', () async {
    final port = _Port();
    final controller = await MapAtmosphereController.open(_session, 'river', port);
    addTearDown(controller.dispose);
    var notices = 0;
    controller.addListener(() => notices++);
    controller.edit(controller.current.copyWith(waterAnimated: true));
    expect(controller.dirty, isTrue);
    expect(port.loads, 1);
    expect(port.saves, isEmpty);
    expect(notices, 1);
    expect(await controller.save(), isTrue);
    expect(controller.dirty, isFalse);
    expect(port.loads, 1);
    expect(port.saves.single.waterAnimated, isTrue);
    expect(port.revisions, ['r0']);
    controller.edit(controller.current.copyWith(windowsLit: true));
    controller.undo();
    expect(controller.current.windowsLit, isFalse);
    controller.redo();
    expect(controller.current.windowsLit, isTrue);
    expect(await controller.save(), isTrue);
    expect(port.revisions, ['r0', 'r1']);
  });

  test('an edit during persistence remains dirty and a failed save stays editable', () async {
    final port = _Port();
    final controller = await MapAtmosphereController.open(_session, 'river', port);
    addTearDown(controller.dispose);
    controller.edit(controller.current.copyWith(fireflies: true));
    port.pending = Completer<void>();
    final saving = controller.save();
    expect(controller.saving, isTrue);
    controller.edit(controller.current.copyWith(fireflyDensity: .5));
    port.pending!.complete();
    expect(await saving, isTrue);
    expect(controller.dirty, isTrue);
    expect(controller.current.fireflyDensity, .5);
    port.failure = StateError('Conflit concurrent');
    expect(await controller.save(), isFalse);
    expect(controller.saving, isFalse);
    expect(controller.dirty, isTrue);
    expect(controller.error, contains('Conflit concurrent'));
    controller.edit(controller.current.copyWith(fireflyDensity: .7));
    expect(controller.error, isNull);
  });
}

const _session = ProjectSession(sessionId: 's', name: 'Test', directoryPath: '/copy');

class _Port implements MapAtmospherePort {
  var loads = 0;
  final saves = <SpatialAtmosphereSettings>[];
  final revisions = <String>[];
  Completer<void>? pending;
  Object? failure;
  @override
  Future<MapAtmosphereState> loadAtmosphere(ProjectSession session, String mapId) async {
    loads++;
    return MapAtmosphereState(settings: SpatialAtmosphereSettings(), revision: 'r0');
  }
  @override
  Future<MapAtmosphereState> saveAtmosphere(ProjectSession session, String mapId, SpatialAtmosphereSettings settings, String expectedRevision) async {
    saves.add(settings);
    revisions.add(expectedRevision);
    await pending?.future;
    if (failure != null) throw failure!;
    return MapAtmosphereState(settings: settings, revision: 'r${saves.length}');
  }
}
