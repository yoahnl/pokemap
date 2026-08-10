import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/state/editor_selectors.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

class CharacterStudioWorkspace extends ConsumerWidget {
  const CharacterStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(editorProjectManifestProvider);
    return ColoredBox(
      key: const ValueKey<String>('character-studio-workspace'),
      color: context.pokeMapColors.contentSurface,
      child: project == null
          ? const PokeMapEmptyState(
              title: 'Aucun projet ouvert',
              description:
                  'Ouvrez un projet pour accéder au Character Studio.',
              icon: Icon(CupertinoIcons.person_2_fill),
            )
          : const PokeMapEmptyState(
              title: 'Character Studio',
              description:
                  'Le workspace personnages est prêt à accueillir son interface.',
              icon: Icon(CupertinoIcons.person_2_fill),
            ),
    );
  }
}
