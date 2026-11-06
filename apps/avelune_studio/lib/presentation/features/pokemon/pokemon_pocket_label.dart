String pokemonPocketLabel(String pocketId) =>
    switch (pocketId.replaceAll('_', '-')) {
      'medicine' => 'Soins',
      'items' => 'Objets',
      'balls' => 'Balls',
      'held-items' => 'Objets tenus',
      'evolution-items' => 'Objets d’évolution',
      'machines' => 'CT/CS',
      'key-items' => 'Objets clés',
      'battle-items' || 'battle' => 'Objets de combat',
      'berries' => 'Baies',
      'mail' => 'Lettres',
      'noigrumes' || 'apricorns' => 'Noigrumes',
      _ => pocketId,
    };
