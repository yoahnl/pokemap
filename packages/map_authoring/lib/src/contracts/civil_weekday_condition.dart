const civilWeekdayConditionContract = <String, Object?>{
  'kind': 'civilWeekday',
  'sourceKind': 'civilWeekday',
  'sourceId': 'civilWeekday',
  'weekday': [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ],
  'expectedValue': 'boolean',
  'operators': ['isTrue', 'isFalse'],
  'predicates': ['isTrue', 'isFalse'],
  'clock': 'hostCivilLocalDay',
  'unavailableCalendar': 'unknownForBothExpectationsAndNegation',
  'capability': 'gameplay.civil-weekday-condition@1',
  'projectDimensions': ['twoD', 'threeD'],
  'effects': 'none',
};
