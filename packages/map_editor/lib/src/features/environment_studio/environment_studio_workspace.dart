import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/state/editor_selectors.dart';
import 'environment_studio_panel.dart';

/// Point d’entrée Riverpod pour le workspace Environment Studio.
///
/// Lit uniquement le manifest courant via [editorProjectManifestProvider] ;
/// aucun repository, provider métier ni accès disque.
class EnvironmentStudioWorkspace extends ConsumerWidget {
  const EnvironmentStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    if (manifest == null) {
      return const _EnvironmentStudioProjectMissingState();
    }
    return EnvironmentStudioPanel(manifest: manifest);
  }
}

class _EnvironmentStudioProjectMissingState extends StatelessWidget {
  const _EnvironmentStudioProjectMissingState();

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);
    return ColoredBox(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Center(
        child: Text(
          'Charger un projet pour ouvrir Environment Studio.',
          key: const Key('environment-studio-missing-project'),
          style: TextStyle(
            color: subtle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
