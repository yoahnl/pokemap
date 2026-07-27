import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('previews every player surface and dispatches guided token edits',
      (tester) async {
    String? selectedToken;

    await tester.pumpWidget(
      _app(
        ProjectSemanticThemeEditor(
          profile: safeProjectSemanticTheme,
          onEditToken: (token) => selectedToken = token,
          onUseSafeFallback: () {},
        ),
      ),
    );

    expect(find.text('Contrastes validés'), findsOneWidget);
    expect(find.text('Écran titre'), findsOneWidget);
    expect(find.text('Dialogues'), findsOneWidget);
    expect(find.text('Menus'), findsOneWidget);
    expect(find.text('HUD exploration'), findsOneWidget);
    expect(find.text('HUD combat'), findsOneWidget);

    final titleSurfaceButton =
        find.byKey(const ValueKey<String>('theme-edit-titleSurface'));
    await tester.ensureVisible(titleSurfaceButton);
    await tester.tap(titleSurfaceButton);
    expect(selectedToken, 'titleSurface');
  });

  testWidgets('blocks publication feedback and offers the safe fallback',
      (tester) async {
    var usedFallback = false;
    final invalid = safeProjectSemanticTheme.copyWith(
      primary: '#EEEEEE',
      onPrimary: '#FFFFFF',
    );

    await tester.pumpWidget(
      _app(
        ProjectSemanticThemeEditor(
          profile: invalid,
          onEditToken: (_) {},
          onUseSafeFallback: () => usedFallback = true,
        ),
      ),
    );

    expect(find.text('Publication bloquée'), findsOneWidget);
    expect(find.textContaining('4.5:1'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey<String>('theme-safe-fallback')),
    );
    expect(usedFallback, isTrue);
  });
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
