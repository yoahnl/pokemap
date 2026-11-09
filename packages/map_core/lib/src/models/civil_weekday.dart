enum CivilWeekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  static CivilWeekday fromJson(Object? value) {
    for (final weekday in values) {
      if (value == weekday.name) return weekday;
    }
    throw const FormatException(
      'A civil weekday requires monday through sunday.',
    );
  }

  String get label => switch (this) {
    monday => 'Lundi',
    tuesday => 'Mardi',
    wednesday => 'Mercredi',
    thursday => 'Jeudi',
    friday => 'Vendredi',
    saturday => 'Samedi',
    sunday => 'Dimanche',
  };
}
