import 'package:avelune_studio/features/map_workspace/application/spatial_ledge_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

void main() {
  test('native ledges use unique identifiers and one undo per mutation', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map);
    final commands = SpatialLedgeEditingCommands(
      document,
      spatialEnvironmentProject(),
    );
    final ledge = commands.next();
    expect(ledge.id, 'ledge-1');
    expect(commands.configure([ledge]), isTrue);
    expect(commands.next().id, 'ledge-2');
    expect(document.current.spatialScene!.navigation.ledges.single, ledge);
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    expect(document.undoCount, 1);
    expect(commands.configure([]), isTrue);
    document.restore(redo: false);
    expect(document.current.spatialScene!.navigation.ledges.single, ledge);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test(
    'ledge editing retains validation and the current map after rejection',
    () {
      final document = rampDocument(spatialEnvironmentMap());
      final commands = SpatialLedgeEditingCommands(
        document,
        spatialEnvironmentProject(),
      );
      final ledge = commands.next();
      expect(commands.configure([ledge]), isTrue);
      expect(commands.edit(ledge, [ledge], 'durationMs', 600), isTrue);
      final current = document.current;
      final changed = current.spatialScene!.navigation.ledges.single;
      expect(changed.durationMs, 600);
      final history = document.undoCount;
      expect(commands.edit(changed, [changed], 'durationMs', 1), isFalse);
      expect(document.error, isNotNull);
      expect(document.current, same(current));
      expect(document.undoCount, history);
    },
  );

  test('saving map cannot configure a new ledge', () {
    final map = spatialEnvironmentMap();
    final document = rampDocument(map)..saving = true;
    final commands = SpatialLedgeEditingCommands(
      document,
      spatialEnvironmentProject(),
    );
    expect(commands.configure([commands.next()]), isFalse);
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });
}
