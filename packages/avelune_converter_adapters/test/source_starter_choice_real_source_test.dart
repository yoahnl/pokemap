import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test(
      'original Kanto starter choices preserve all three native gifts and branch keys',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final source = fixture.source;
    final sourceProfile = SourceEventProfile.forProject(source);
    for (final expected in [
      (4, 'BULBASAUR', 1, 2),
      (5, 'SQUIRTLE', 3, 1),
      (6, 'CHARMANDER', 2, 3)
    ]) {
      final event = source.maps.single.map.events
          .singleWhere((event) => event.sourceEventId == expected.$1);
      final program = SourceStarterChoiceProgram.read(
          source: source, profile: sourceProfile, sourceMapId: 9, event: event);
      expect(program, isNotNull, reason: 'source9/${expected.$1}');
      expect(program!.sourceSpeciesSymbol, expected.$2);
      expect(program.level, 5);
      expect(program.choiceVariableId, 29);
      expect(program.choiceValue, expected.$3);
      expect(program.remainingChoiceValue, expected.$4);
      expect(program.offerSwitchId, 75);
      expect(
          program.isBoundTo(
              source: source, profile: sourceProfile, event: event),
          isTrue);
    }
  },
      skip: root == null || snapshot == null || profile == null
          ? 'Requires explicit source witnesses and profile.'
          : false);
}
