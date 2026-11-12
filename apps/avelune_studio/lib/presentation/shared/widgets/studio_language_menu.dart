import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/language_providers.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StudioLanguageMenu extends ConsumerWidget {
  const StudioLanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(studioLanguagePreferencesProvider);
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) {
        final selected = preferences.languageCode;
        Widget? mark(bool active) =>
            active ? const Icon(Icons.check, size: 16) : null;
        return MenuAnchor(
          menuChildren: [
            MenuItemButton(
              key: const ValueKey('studio-language-system'),
              leadingIcon: mark(selected == null),
              onPressed: () => unawaited(preferences.select(null)),
              child: Text(context.l10n.languageSystem),
            ),
            for (final locale in AppLocalizations.supportedLocales)
              MenuItemButton(
                key: ValueKey('studio-language-${locale.languageCode}'),
                leadingIcon: mark(selected == locale.languageCode),
                onPressed: () =>
                    unawaited(preferences.select(locale.languageCode)),
                child: Text(lookupAppLocalizations(locale).languageName),
              ),
          ],
          builder: (context, controller, _) => IconButton(
            key: const ValueKey('studio-language'),
            tooltip: context.l10n.languageMenu,
            icon: const Icon(Icons.translate, size: 18),
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        );
      },
    );
  }
}
