import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_launch_options.dart';

void main() {
  testWidgets('shows the demo pokemon launch option enabled by default',
      (tester) async {
    var value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RuntimeDemoSeedToggle(
                value: value,
                onChanged: (nextValue) {
                  setState(() => value = nextValue);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('seed-demo-pokemon-switch')), findsOneWidget);
    expect(find.text('Démarrer avec un Pokémon de démo'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('seed-demo-pokemon-switch')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('seed-demo-pokemon-switch')));
    await tester.pump();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('seed-demo-pokemon-switch')),
          )
          .value,
      isFalse,
    );
  });
}
