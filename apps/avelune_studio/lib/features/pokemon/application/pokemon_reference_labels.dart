String pokemonTypeLabel(String type) => switch (type.toLowerCase()) {
  'grass' => 'Plante',
  'poison' => 'Poison',
  'fire' => 'Feu',
  'water' => 'Eau',
  'electric' => 'Électrik',
  'ice' => 'Glace',
  'ground' => 'Sol',
  'rock' => 'Roche',
  'flying' => 'Vol',
  'psychic' => 'Psy',
  'bug' => 'Insecte',
  'ghost' => 'Spectre',
  'dragon' => 'Dragon',
  'dark' => 'Ténèbres',
  'steel' => 'Acier',
  'fairy' => 'Fée',
  'fighting' => 'Combat',
  'normal' => 'Normal',
  _ => type,
};

String pokemonMoveCategoryLabel(String? category) =>
    switch (category?.toLowerCase()) {
      'physical' => 'Physique',
      'special' => 'Spéciale',
      'status' => 'Statut',
      null => 'Catégorie inconnue',
      final String other => other,
    };
