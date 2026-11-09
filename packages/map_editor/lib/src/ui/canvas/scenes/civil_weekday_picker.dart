import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';
import '../../design_system/design_system.dart';

class CivilWeekdayPicker extends StatefulWidget {
  const CivilWeekdayPicker({
    super.key,
    this.initial,
    this.expectedValue = true,
    required this.onApply,
  });
  final CivilWeekday? initial;
  final bool expectedValue;
  final FutureOr<void> Function(CivilWeekday weekday, bool expectedValue)
  onApply;

  @override
  State<CivilWeekdayPicker> createState() => _CivilWeekdayPickerState();
}

class _CivilWeekdayPickerState extends State<CivilWeekdayPicker> {
  late CivilWeekday _weekday = widget.initial ?? CivilWeekday.friday;
  late bool _expected = widget.expectedValue;
  bool _saving = false;

  @override
  void didUpdateWidget(CivilWeekdayPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial ||
        oldWidget.expectedValue != widget.expectedValue) {
      _weekday = widget.initial ?? CivilWeekday.friday;
      _expected = widget.expectedValue;
    }
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      await widget.onApply(_weekday, _expected);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PokeMapDropdownField<CivilWeekday>(
        key: const ValueKey('civil-weekday-picker'),
        label: 'Jour de la semaine (calendrier civil)',
        value: _weekday,
        enabled: !_saving,
        items: [
          for (final weekday in CivilWeekday.values)
            PokeMapDropdownItem(value: weekday, label: weekday.label),
        ],
        onChanged: (value) => setState(() => _weekday = value),
      ),
      const SizedBox(height: 8),
      PokeMapDropdownField<bool>(
        key: const ValueKey('civil-weekday-expected'),
        label: 'Condition',
        value: _expected,
        enabled: !_saving,
        items: const [
          PokeMapDropdownItem(value: true, label: 'Nous sommes ce jour'),
          PokeMapDropdownItem(
            value: false,
            label: 'Nous ne sommes pas ce jour',
          ),
        ],
        onChanged: (value) => setState(() => _expected = value),
      ),
      const SizedBox(height: 8),
      PokeMapButton(
        key: const ValueKey('civil-weekday-apply'),
        onPressed: _saving ? null : _apply,
        isLoading: _saving,
        child: const Text('Utiliser ce jour civil'),
      ),
    ],
  );
}
