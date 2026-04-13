import 'package:flutter/material.dart';

class RuntimeDemoSeedToggle extends StatelessWidget {
  const RuntimeDemoSeedToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: const Key('seed-demo-pokemon-switch'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Démarrer avec un Pokémon de démo'),
      subtitle: const Text(
        'Ajoute un Pokémon jouable dans l’équipe initiale.',
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
