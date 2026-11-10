class BorderPatternAssociations {
  BorderPatternAssociations({
    required Iterable<String> assigned,
    this.straightOnly = false,
    this.followContourDirection = false,
  }) : assigned = Set.unmodifiable(assigned);

  final Set<String> assigned;
  final bool straightOnly;
  final bool followContourDirection;

  List<String> get roles => [
    'lineStraight',
    'lineCap',
    if (!straightOnly) 'lineCorner',
    if (!straightOnly && followContourDirection) 'lineCornerLeft',
  ];

  List<String> get missing => [
    for (final role in roles)
      if (!assigned.contains(role)) _label(role),
  ];

  String _label(String role) => switch (role) {
    'lineStraight' when straightOnly || followContourDirection => 'corps',
    'lineStraight' => 'bords',
    'lineCap' => 'extrémités',
    'lineCorner' when followContourDirection => 'angle sortant',
    'lineCorner' => 'angles',
    _ => 'angle rentrant',
  };

  String get countLabel =>
      '${roles.where(assigned.contains).length} / ${roles.length} familles de pièces associées';
  String get statusLabel => missing.isEmpty
      ? 'Associations complètes. Les raccords restent à valider avant publication.'
      : 'Pièces manquantes avant publication : ${missing.join(', ')}.';
}
