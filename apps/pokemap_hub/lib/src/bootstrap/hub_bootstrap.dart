import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../platform/hub_composition.dart';
import '../platform/public_product_identity.dart';

typedef HubCompositionFactory = Future<HubAppComposition> Function();

class PokeMapHubBootstrap extends StatefulWidget {
  const PokeMapHubBootstrap({
    super.key,
    this.compositionFactory,
    this.showTechnicalDetails = kDebugMode,
  });

  final HubCompositionFactory? compositionFactory;
  final bool showTechnicalDetails;

  @override
  State<PokeMapHubBootstrap> createState() => _PokeMapHubBootstrapState();
}

class _PokeMapHubBootstrapState extends State<PokeMapHubBootstrap> {
  late Future<HubAppComposition> _composition;
  HubAppComposition? _ownedComposition;

  HubCompositionFactory get _compositionFactory =>
      widget.compositionFactory ?? HubComposition.create;

  @override
  void initState() {
    super.initState();
    _composition = _createComposition();
  }

  Future<HubAppComposition> _createComposition() async {
    final composition = await _compositionFactory();
    if (!mounted) {
      composition.dispose();
    }
    return composition;
  }

  void _retry() {
    _ownedComposition?.dispose();
    _ownedComposition = null;
    final nextComposition = _createComposition();
    setState(() {
      _composition = nextComposition;
    });
  }

  @override
  void dispose() {
    _ownedComposition?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HubAppComposition>(
        future: _composition,
        builder: (context, snapshot) {
          final composition = snapshot.data;
          if (composition != null) {
            _ownedComposition ??= composition;
            return composition.buildApp();
          }
          if (snapshot.hasError) {
            return _HubBootstrapFailureApp(
              error: snapshot.error!,
              stackTrace: snapshot.stackTrace,
              showTechnicalDetails: widget.showTechnicalDetails,
              onRetry: _retry,
            );
          }
          return const _HubBootstrapLoadingApp();
        },
      );
}

class _HubBootstrapLoadingApp extends StatelessWidget {
  const _HubBootstrapLoadingApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: publicProductName,
        debugShowCheckedModeBanner: false,
        theme: PokeMapPlayerTheme.light(),
        darkTheme: PokeMapPlayerTheme.dark(),
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Semantics(
              liveRegion: true,
              label: 'Ouverture de $publicProductName',
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      );
}

class _HubBootstrapFailureApp extends StatelessWidget {
  const _HubBootstrapFailureApp({
    required this.error,
    required this.stackTrace,
    required this.showTechnicalDetails,
    required this.onRetry,
  });

  final Object error;
  final StackTrace? stackTrace;
  final bool showTechnicalDetails;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: publicProductName,
        debugShowCheckedModeBanner: false,
        theme: PokeMapPlayerTheme.light(),
        darkTheme: PokeMapPlayerTheme.dark(),
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(PlayerSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (PlayerSpacing.lg * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Semantics(
                        liveRegion: true,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(PlayerSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: context.playerColors.danger,
                                ),
                                const SizedBox(height: PlayerSpacing.md),
                                Text(
                                  'Impossible d’ouvrir $publicProductName',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: PlayerSpacing.sm),
                                Text(
                                  'Le Hub n’a pas pu préparer son espace de '
                                  'données. Aucun jeu ni aucune sauvegarde '
                                  'n’a été modifié.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color:
                                            context.playerColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: PlayerSpacing.lg),
                                SelectableText(
                                  'Code : hub.bootstrap.failed',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                if (showTechnicalDetails) ...[
                                  const SizedBox(height: PlayerSpacing.md),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color:
                                          context.playerColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(
                                        PlayerRadii.sm,
                                      ),
                                      border: Border.all(
                                        color: context.playerColors.outline,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        PlayerSpacing.md,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 180,
                                        ),
                                        child: SingleChildScrollView(
                                          child: SelectableText(
                                            _diagnosticText(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: PlayerSpacing.lg),
                                FilledButton.icon(
                                  onPressed: onRetry,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String _diagnosticText() {
    final trace = stackTrace?.toString().trim();
    if (trace == null || trace.isEmpty) return error.toString();
    return '$error\n\n$trace';
  }
}
