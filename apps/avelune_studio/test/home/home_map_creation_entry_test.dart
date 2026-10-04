import 'package:avelune_studio/presentation/features/home/studio_home_all_maps.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all maps offers the shared creation entry even when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StudioHomeAllMaps(
            maps: const [],
            groups: const [],
            busy: false,
            onMap: (_) {},
            onBack: () {},
          ),
        ),
      ),
    );
    expect(find.text('Nouvelle carte'), findsOneWidget);
  });
}
