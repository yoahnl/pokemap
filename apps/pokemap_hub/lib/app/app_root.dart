import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/app/di/hub_composition_provider.dart';
import 'package:pokemap_hub/core/config/public_product_identity.dart';

/// Root of the Hub application.
///
/// Reads the composition from [hubCompositionProvider] rather than owning a
/// Future itself: retry is now `ref.invalidate`, and disposal is the provider's
/// job, which removes the manual _ownedComposition bookkeeping this widget used
/// to carry.
class PokeMapHubBootstrap extends ConsumerWidget {
  const PokeMapHubBootstrap({
    super.key,
    this.showTechnicalDetails = kDebugMode,
  });

  final bool showTechnicalDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(hubCompositionProvider).when(
          data: (composition) => composition.buildApp(),
          error: (error, stackTrace) => _HubBootstrapFailureApp(
            error: error,
            stackTrace: stackTrace,
            showTechnicalDetails: showTechnicalDetails,
            onRetry: () => ref.invalidate(hubCompositionProvider),
          ),
          loading: () => const _HubBootstrapLoadingApp(),
        );
  }
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
