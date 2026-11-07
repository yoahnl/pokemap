enum TestLaunchScope { map, game }

final class TestLaunchBlocker {
  const TestLaunchBlocker(this.label, this.where);
  final String label;
  final String where;
}

final class TestLaunchPreflight {
  const TestLaunchPreflight({
    required this.scope,
    required this.mapName,
    required this.saves,
    required this.blockers,
  });

  final TestLaunchScope scope;
  final String mapName;
  final List<String> saves;
  final List<TestLaunchBlocker> blockers;

  bool get canLaunch => blockers.isEmpty;

  String get title => switch (scope) {
    TestLaunchScope.map => 'Tester cette carte',
    TestLaunchScope.game => 'Tester le jeu',
  };

  String get scopeNote => switch (scope) {
    TestLaunchScope.map =>
      'Seule la carte « $mapName » est lancée. Les sauvegardes du test restent '
          'en mémoire et disparaissent à sa fermeture.',
    TestLaunchScope.game =>
      'Le jeu complet démarre une nouvelle partie. Les sauvegardes du test '
          'restent en mémoire, dans un emplacement de test : celles des '
          'joueurs ne sont pas touchées.',
  };
}
