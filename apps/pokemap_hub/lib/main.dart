import 'package:flutter/material.dart';

import 'src/platform/macos_hub_composition.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _PokeMapHubBootstrap());
}

class _PokeMapHubBootstrap extends StatefulWidget {
  const _PokeMapHubBootstrap();

  @override
  State<_PokeMapHubBootstrap> createState() => _PokeMapHubBootstrapState();
}

class _PokeMapHubBootstrapState extends State<_PokeMapHubBootstrap> {
  late final Future<MacOSHubComposition> _composition =
      MacOSHubComposition.create();
  MacOSHubComposition? _ownedComposition;

  @override
  void dispose() {
    _ownedComposition?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MacOSHubComposition>(
        future: _composition,
        builder: (context, snapshot) {
          final composition = snapshot.data;
          if (composition != null) {
            _ownedComposition ??= composition;
            return composition.buildApp();
          }
          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: const Text(
                      'PokeMap Hub ne peut pas ouvrir ses données. '
                      'Aucun jeu ni sauvegarde n’a été modifié.',
                    ),
                  ),
                ),
              ),
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Semantics(
                  liveRegion: true,
                  label: 'Ouverture de PokeMap Hub',
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
          );
        },
      );
}
