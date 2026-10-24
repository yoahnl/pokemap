import 'package:flutter/material.dart';

import 'studio_select.dart';

class StudioTimeWindow extends StatelessWidget {
  const StudioTimeWindow({
    super.key,
    required this.startMinute,
    required this.endMinute,
    required this.onChanged,
    required this.fieldKeyPrefix,
  });

  final int startMinute;
  final int endMinute;
  final void Function(int startMinute, int endMinute) onChanged;
  final String fieldKeyPrefix;

  @override
  Widget build(BuildContext context) {
    Widget select(
      String label,
      String suffix,
      int value,
      int count,
      ValueChanged<int>? update,
      int? excludedValue,
    ) => SizedBox(
      width: 150,
      child: StudioSelect(
        key: ValueKey('$fieldKeyPrefix-$suffix'),
        label: label,
        value: '$value',
        options: {
          for (var i = 0; i < count; i++)
            if (i != excludedValue) '$i': '$i'.padLeft(2, '0'),
        },
        onChanged: update == null ? null : (value) => update(int.parse(value)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            select(
              'Début · heure',
              'start-hour',
              startMinute ~/ 60,
              24,
              (hour) => onChanged(hour * 60 + startMinute % 60, endMinute),
              endMinute % 60 == startMinute % 60 ? endMinute ~/ 60 : null,
            ),
            select(
              'Début · minute',
              'start-minute',
              startMinute % 60,
              60,
              (minute) => onChanged(startMinute ~/ 60 * 60 + minute, endMinute),
              startMinute ~/ 60 == endMinute ~/ 60 ? endMinute % 60 : null,
            ),
            select(
              'Fin · heure',
              'end-hour',
              endMinute ~/ 60,
              25,
              (hour) => onChanged(
                startMinute,
                hour == 24 ? 1440 : hour * 60 + endMinute % 60,
              ),
              startMinute % 60 == endMinute % 60 ? startMinute ~/ 60 : null,
            ),
            select(
              'Fin · minute',
              'end-minute',
              endMinute % 60,
              60,
              endMinute == 1440
                  ? null
                  : (minute) =>
                        onChanged(startMinute, endMinute ~/ 60 * 60 + minute),
              startMinute ~/ 60 == endMinute ~/ 60 ? startMinute % 60 : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (startMinute == endMinute)
          const Text('Choisissez deux horaires différents.')
        else if (startMinute > endMinute)
          const Text(
            'Cette plage traverse minuit. Le début est inclus et la fin est exclue.',
          )
        else
          const Text('Le début est inclus et la fin est exclue.'),
      ],
    );
  }
}
