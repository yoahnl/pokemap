import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  testWidgets('settings render the three sections and all built-in presets',
      (tester) async {
    await tester.pumpWidget(_app(_settings(state: _readyState())));
    await tester.pump();

    expect(find.text('Fond'), findsOneWidget);
    expect(find.text('Commode'), findsOneWidget);
    expect(find.text('Mon image'), findsOneWidget);

    for (final label in const <String>[
      'Ambre',
      'Aube',
      'Lin',
      'Crépuscule',
      'Ardoise',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in const <String>[
      'Noyer',
      'Ivoire',
      'Chêne clair',
      'Frêne',
      'Acajou',
      'Ébène',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('tapping a background preset forwards its id', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _app(
        _settings(
          state: _readyState(),
          onBackgroundSelected: (id) => chosen = id,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Crépuscule'));
    await tester.pump();

    expect(chosen, 'violet');
  });

  testWidgets('tapping a furniture preset forwards its id', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _app(
        _settings(
          state: _readyState(),
          onFurnitureSelected: (id) => chosen = id,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ivoire'));
    await tester.pump();

    expect(chosen, 'ivory');
  });

  testWidgets('import and remove controls reflect custom image presence',
      (tester) async {
    await tester.pumpWidget(
      _app(_settings(state: _readyState())),
    );
    await tester.pump();
    await _scrollToCustomImage(tester);

    expect(find.text('Choisir une image'), findsOneWidget);
    expect(find.text('Supprimer'), findsNothing);

    await tester.pumpWidget(
      _app(
        _settings(
          state: _readyState(
            customBackgroundPath: '/tmp/custom-background.jpg',
            customBackgroundThumbnailPath:
                '/tmp/custom-background.thumbnail.jpg',
            backgroundId: AveluneAppearanceCatalog.customBackgroundId,
          ),
        ),
      ),
    );
    await tester.pump();
    await _scrollToCustomImage(tester);

    expect(find.text('Remplacer'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('remove button forwards the removal callback', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      _app(
        _settings(
          state: _readyState(
            customBackgroundPath: '/tmp/custom-background.jpg',
            customBackgroundThumbnailPath:
                '/tmp/custom-background.thumbnail.jpg',
            backgroundId: AveluneAppearanceCatalog.customBackgroundId,
          ),
          onRemoveCustomBackground: () => removed = true,
        ),
      ),
    );
    await tester.pump();
    await _scrollToCustomImage(tester);

    await tester.tap(find.text('Supprimer'));
    await tester.pump();

    expect(removed, isTrue);
  });

  testWidgets('controller message surfaces as a state message', (tester) async {
    await tester.pumpWidget(
      _app(
        _settings(
          state: _readyState(
            message: 'Les préférences ont été restaurées.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Les préférences ont été restaurées.'), findsOneWidget);
  });

  testWidgets('saving status disables preset interactions', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _app(
        _settings(
          state: const AveluneAppearanceState(
            status: AveluneAppearanceControllerStatus.saving,
            preferences: AveluneAppearancePreferences(),
          ),
          onBackgroundSelected: (id) => chosen = id,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Crépuscule'), warnIfMissed: false);
    await tester.pump();

    expect(chosen, isNull);
  });
}

Future<void> _scrollToCustomImage(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
  await tester.pump();
}

AveluneAppearanceSettings _settings({
  required AveluneAppearanceState state,
  ValueChanged<String>? onBackgroundSelected,
  ValueChanged<String>? onFurnitureSelected,
  VoidCallback? onImportCustomBackground,
  VoidCallback? onRemoveCustomBackground,
}) =>
    AveluneAppearanceSettings(
      state: state,
      onBackgroundSelected: onBackgroundSelected ?? (_) {},
      onFurnitureSelected: onFurnitureSelected ?? (_) {},
      onImportCustomBackground: onImportCustomBackground ?? () {},
      onRemoveCustomBackground: onRemoveCustomBackground ?? () {},
    );

AveluneAppearanceState _readyState({
  String backgroundId = AveluneAppearanceCatalog.defaultBackgroundId,
  String furnitureId = AveluneAppearanceCatalog.defaultFurnitureId,
  String? customBackgroundPath,
  String? customBackgroundThumbnailPath,
  String? message,
}) =>
    AveluneAppearanceState(
      status: AveluneAppearanceControllerStatus.ready,
      preferences: AveluneAppearancePreferences(
        backgroundId: backgroundId,
        furnitureId: furnitureId,
      ),
      customBackgroundPath: customBackgroundPath,
      customBackgroundThumbnailPath: customBackgroundThumbnailPath,
      message: message,
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: AveluneThemeData.standard.applyTo(ThemeData.dark()),
      home: Scaffold(body: child),
    );
