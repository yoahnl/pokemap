import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/features/editor_updates/presentation/editor_update_banner.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('renders the localized release actions and routes callbacks',
      (tester) async {
    var notes = 0;
    var update = 0;
    var dismiss = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: EditorUpdateBanner(
            versionLabel: '0.3.1',
            onReadNotes: () => notes += 1,
            onUpdate: () => update += 1,
            onDismiss: () => dismiss += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Une nouvelle aventure t’attend ✨'), findsOneWidget);
    expect(
      find.text('PokeMap 0.3.1 est prêt à rejoindre ton équipe.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Lire les notes'));
    await tester.tap(find.text('Mettre à jour'));
    await tester.tap(find.byKey(editorUpdateBannerDismissKey));
    expect((notes, update, dismiss), (1, 1, 1));
  });

  testWidgets('uses natural English copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EditorUpdateBanner(
            versionLabel: '0.3.1',
            onReadNotes: () {},
            onUpdate: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A new adventure awaits ✨'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });
}
