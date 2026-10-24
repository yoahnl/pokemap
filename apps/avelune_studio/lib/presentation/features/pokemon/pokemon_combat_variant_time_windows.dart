part of 'pokemon_combat_table_detail.dart';

Widget _buildCombatVariantTimeWindows(
  PokemonCombatController combat,
  ProjectEncounterVariant variant,
  String prefix,
) {
  void change(List<LocalTimeWindow> Function(List<LocalTimeWindow>) edit) =>
      _changeCombatVariant(
        combat,
        variant.id,
        (current) => current.copyWith(timeWindows: edit(current.timeWindows)),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Horaires locaux'),
      const SizedBox(height: 6),
      Text(
        variant.timeWindows.isEmpty
            ? 'Toute la journée. Ajoutez une plage pour limiter les rencontres à certains horaires.'
            : 'Une seule plage active suffit. Le début est inclus et la fin est exclue.',
      ),
      for (var i = 0; i < variant.timeWindows.length; i++) ...[
        const SizedBox(height: 12),
        _buildCombatVariantTimeWindow(
          variant.timeWindows[i],
          '$prefix:window:$i',
          (window) => change(
            (current) => [
              for (var j = 0; j < current.length; j++)
                if (i == j) window else current[j],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            label: 'Retirer cette plage',
            secondary: true,
            onPressed: () => change(
              (current) => [
                for (var j = 0; j < current.length; j++)
                  if (i != j) current[j],
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: StudioButton(
          key: ValueKey('$prefix:add-time-window'),
          label: 'Ajouter une plage horaire',
          secondary: true,
          icon: Icons.add,
          onPressed: () => change(
            (current) => [
              ...current,
              const LocalTimeWindow(startMinute: 480, endMinute: 1200),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildCombatVariantTimeWindow(
  LocalTimeWindow window,
  String prefix,
  ValueChanged<LocalTimeWindow> change,
) => StudioTimeWindow(
  fieldKeyPrefix: prefix,
  startMinute: window.startMinute,
  endMinute: window.endMinute,
  onChanged: (start, end) =>
      change(LocalTimeWindow(startMinute: start, endMinute: end)),
);
