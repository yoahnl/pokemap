import 'package:flutter/material.dart';

abstract final class PokeMapPlayerPokemonTypeTheme {
  static Color color(String type) => switch (type.toLowerCase()) {
        'normal' => const Color(0xFF777B70),
        'fire' => const Color(0xFFBA4530),
        'water' => const Color(0xFF286AB6),
        'electric' => const Color(0xFFE0AD26),
        'grass' => const Color(0xFF427B39),
        'ice' => const Color(0xFF55A5B0),
        'fighting' => const Color(0xFFA84641),
        'poison' => const Color(0xFF85519D),
        'ground' => const Color(0xFFA68043),
        'flying' => const Color(0xFF687FB9),
        'psychic' => const Color(0xFFB94370),
        'bug' => const Color(0xFF6B7D2B),
        'rock' => const Color(0xFF8D7C41),
        'ghost' => const Color(0xFF615A91),
        'dragon' => const Color(0xFF5755B6),
        'dark' => const Color(0xFF60534D),
        'steel' => const Color(0xFF697D90),
        'fairy' => const Color(0xFFB05F91),
        _ => const Color(0xFF617386),
      };

  static IconData icon(String type) => switch (type.toLowerCase()) {
        'normal' => Icons.circle_outlined,
        'fire' => Icons.local_fire_department_rounded,
        'water' => Icons.water_drop_rounded,
        'electric' => Icons.bolt_rounded,
        'grass' => Icons.eco_rounded,
        'ice' => Icons.ac_unit_rounded,
        'fighting' => Icons.sports_mma_rounded,
        'poison' => Icons.science_rounded,
        'ground' => Icons.landscape_rounded,
        'flying' => Icons.air_rounded,
        'psychic' => Icons.visibility_rounded,
        'bug' => Icons.bug_report_rounded,
        'rock' => Icons.terrain_rounded,
        'ghost' => Icons.nightlight_round,
        'dragon' => Icons.auto_awesome_rounded,
        'dark' => Icons.dark_mode_rounded,
        'steel' => Icons.hexagon_outlined,
        'fairy' => Icons.stars_rounded,
        _ => Icons.help_outline_rounded,
      };
}
