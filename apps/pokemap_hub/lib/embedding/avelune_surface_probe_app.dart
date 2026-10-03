import 'dart:async';

import 'package:flutter/material.dart';

import 'avelune_surface_probe.dart';

class AvelunePrimaryProbeSurface extends StatelessWidget {
  const AvelunePrimaryProbeSurface({
    required this.controller,
    required this.bridge,
    super.key,
  });

  final AveluneSurfaceProbeController controller;
  final AveluneSurfaceProbeBridge bridge;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AveluneSurfaceProbeSnapshot?>(
      valueListenable: controller,
      builder: (context, snapshot, _) {
        return _ProbeSurface(
          snapshot: snapshot,
          companion: false,
          onIncrement: () async {
            final current = controller.value;
            if (current == null) return;
            controller.applyIntent({
              'sessionId': current.sessionId,
              'sourceId': 'primary',
              'sequence': current.revision + 1,
              'action': 'increment',
            });
          },
          onToggleCompanion:
              () => bridge.setCompanionEnabled(
                !(snapshot?.companionAttached ?? false),
              ),
          onExit: bridge.exit,
        );
      },
    );
  }
}

class AveluneCompanionProbeApp extends StatefulWidget {
  const AveluneCompanionProbeApp({super.key});

  @override
  State<AveluneCompanionProbeApp> createState() =>
      _AveluneCompanionProbeAppState();
}

class _AveluneCompanionProbeAppState extends State<AveluneCompanionProbeApp> {
  final _bridge = AveluneCompanionProbeBridge();

  @override
  void initState() {
    super.initState();
    unawaited(_bridge.attach());
  }

  @override
  void dispose() {
    _bridge.detach();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: ValueListenableBuilder<AveluneSurfaceProbeSnapshot?>(
        valueListenable: _bridge,
        builder: (context, snapshot, _) {
          return _ProbeSurface(
            snapshot: snapshot,
            companion: true,
            onIncrement: _bridge.increment,
          );
        },
      ),
    );
  }
}

class _ProbeSurface extends StatefulWidget {
  const _ProbeSurface({
    required this.snapshot,
    required this.companion,
    required this.onIncrement,
    this.onToggleCompanion,
    this.onExit,
  });

  final AveluneSurfaceProbeSnapshot? snapshot;
  final bool companion;
  final Future<void> Function() onIncrement;
  final Future<void> Function()? onToggleCompanion;
  final Future<void> Function()? onExit;

  @override
  State<_ProbeSurface> createState() => _ProbeSurfaceState();
}

class _ProbeSurfaceState extends State<_ProbeSurface> {
  bool _busy = false;

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action impossible : $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AVELUNE · TEST DEUX ÉCRANS',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.companion ? 'Écran compagnon' : 'Écran principal',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot == null ? 'Connexion…' : '${snapshot.value}',
                    key: const ValueKey('probe-counter'),
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot?.companionAttached == true
                        ? 'Deux écrans · même état'
                        : 'Un écran · état conservé',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('probe-increment'),
                    onPressed:
                        snapshot == null || _busy
                            ? null
                            : () => _perform(widget.onIncrement),
                    child: Text(widget.companion ? 'Envoyer +1' : 'Ajouter +1'),
                  ),
                  if (widget.onToggleCompanion != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed:
                          _busy
                              ? null
                              : () => _perform(widget.onToggleCompanion!),
                      child: Text(
                        snapshot?.companionAttached == true
                            ? 'Passer à un écran'
                            : 'Reconnecter le deuxième écran',
                      ),
                    ),
                  ],
                  if (widget.onExit != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => _perform(widget.onExit!),
                      child: const Text('Terminer le test'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.companion
                        ? 'Chaque pression envoie une intention au propriétaire.'
                        : 'Le compteur appartient à cette session Dart.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Session ${snapshot.sessionId}\nRévision ${snapshot.revision}',
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
