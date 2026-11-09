import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/civil_weekday_picker.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'guided civil weekday picker preserves selection and inverted expectation',
    (tester) async {
      (CivilWeekday, bool)? result;
      Widget picker(CivilWeekday weekday, bool expected) => MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: CivilWeekdayPicker(
            initial: weekday,
            expectedValue: expected,
            onApply: (day, value) => result = (day, value),
          ),
        ),
      );
      await tester.pumpWidget(picker(CivilWeekday.friday, false));
      expect(find.text('Vendredi'), findsWidgets);
      expect(find.text('Nous ne sommes pas ce jour'), findsWidgets);
      final weekday = tester.widget<PokeMapDropdownField<CivilWeekday>>(
        find.byKey(const ValueKey('civil-weekday-picker')),
      );
      expect(weekday.items.map((item) => item.label), [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ]);
      weekday.onChanged(CivilWeekday.monday);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('civil-weekday-apply')));
      await tester.pump();
      expect(result, (CivilWeekday.monday, false));
      await tester.pumpWidget(picker(CivilWeekday.sunday, true));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('civil-weekday-apply')));
      await tester.pump();
      expect(result, (CivilWeekday.sunday, true));
      expect(tester.takeException(), isNull);
    },
  );
}
